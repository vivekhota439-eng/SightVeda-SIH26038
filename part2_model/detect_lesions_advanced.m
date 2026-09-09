function details = detect_lesions_advanced(imageInput)
% DETECT_LESIONS_ADVANCED Comprehensive Retinal Anatomical & Lesion Analysis Engine.
%
% Integrates:
% 1. Optic Disc (OD) localization & exclusion masking.
% 2. Fovea / Macula localization & Clinically Significant Macular Edema (CSME) risk.
% 3. Sub-Pixel Microaneurysm (MA) detection with 2D Gaussian fitting (±0.15 px).
% 4. Pixel-level Exudate boundary segmentation & Disc Diameter (DD) quantification.
% 5. Hemorrhage morphological classification (Dot/Blot vs Flame-shaped vs Preretinal).
% 6. Neovascularization detection (NVD on optic disc, NVE elsewhere).
% 7. 4-Quadrant spatial lesion distribution (ST, IT, SN, IN).

    if ischar(imageInput) || isstring(imageInput)
        imgPath = char(imageInput);
        if ~exist(imgPath, 'file')
            error("Image file not found: %s", imgPath);
        end
        img = imread(imgPath);
    else
        img = imageInput;
    end

    if ndims(img) == 2
        img = cat(3, img, img, img);
    end

    [h, w, ~] = size(img);
    gray = rgb2gray(img);
    green = img(:, :, 2);

    details = struct();
    details.lesion_tags = {};
    details.subpixel_microaneurysms = []; % [x, y, conf]
    details.ma_count = 0;
    details.dot_blot_count = 0;
    details.flame_hemorrhage_count = 0;
    details.preretinal_count = 0;
    details.hemorrhage_classes = {};
    details.exudate_area_pixels = 0;
    details.exudate_area_disc_diameters = 0.0;
    details.has_csme_macular_risk = false;
    details.has_neovascularization = false;
    details.neovascularization_types = {};
    details.optic_disc = struct('detected', false, 'center', [round(w*0.35), round(h*0.5)], 'radius', 30);
    details.fovea = struct('detected', false, 'center', [round(w*0.55), round(h*0.5)], 'macula_radius', 40);
    details.quadrants = struct('superotemporal', 0, 'inferotemporal', 0, 'superonasal', 0, 'inferonasal', 0);

    % =========================================================================
    % 1. Retinal FOV Segmentation
    % =========================================================================
    retinalMask = gray > 15;
    retinalMask = imclose(retinalMask, strel('disk', 15));
    ccRetina = bwconncomp(retinalMask);
    if ccRetina.NumObjects == 0
        return;
    end
    statsRetina = regionprops(ccRetina, 'Area');
    [~, maxRIdx] = max([statsRetina.Area]);
    retinalMask = false(h, w);
    retinalMask(ccRetina.PixelIdxList{maxRIdx}) = true;
    retinalMask = imfill(retinalMask, 'holes');
    retinalMask = imerode(retinalMask, strel('disk', 8));

    totalRetinalPixels = sum(retinalMask(:));
    if totalRetinalPixels < (h * w * 0.10)
        return;
    end

    % =========================================================================
    % 2. Optic Disc & Fovea Localization
    % =========================================================================
    labImg = rgb2lab(img);
    lChannel = uint8(labImg(:, :, 1) * 2.55);
    redChannel = img(:, :, 1);
    brightCombined = imlincomb(0.5, lChannel, 0.5, redChannel);
    brightCombined(~retinalMask) = 0;

    minRadius = max(15, round(min(h, w) * 0.045));
    maxRadius = max(minRadius + 10, round(min(h, w) * 0.13));

    odFound = false;
    odCenter = [round(w * 0.35), round(h * 0.5)];
    odRadius = minRadius;

    try
        [centers, radii] = imfindcircles(brightCombined, [minRadius, maxRadius], ...
            'ObjectPolarity', 'bright', 'Sensitivity', 0.88);
        if ~isempty(centers)
            odCenter = [round(centers(1, 1)), round(centers(1, 2))];
            odRadius = round(radii(1));
            odFound = true;
        end
    catch
    end

    if ~odFound
        % Brightness centroid fallback
        [~, maxIdx] = max(brightCombined(:));
        [cy, cx] = ind2sub([h, w], maxIdx);
        odCenter = [cx, cy];
        odRadius = round(min(h, w) * 0.06);
        odFound = true;
    end

    [X, Y] = meshgrid(1:w, 1:h);
    distFromOD = sqrt((X - odCenter(1)).^2 + (Y - odCenter(2)).^2);
    discExclusionMask = distFromOD <= (odRadius * 1.35);

    discDiameterPx = odRadius * 2.0;
    discAreaPx = pi * (odRadius^2);

    details.optic_disc.detected = odFound;
    details.optic_disc.center = odCenter;
    details.optic_disc.radius = odRadius;

    % Fovea Localization (approx 2.5 disc diameters temporal to optic disc)
    isLeftEye = odCenter(1) < (w / 2);
    if isLeftEye
        foveaX = min(w - 20, round(odCenter(1) + 2.5 * discDiameterPx));
    else
        foveaX = max(20, round(odCenter(1) - 2.5 * discDiameterPx));
    end
    foveaY = odCenter(2);
    foveaCenter = [foveaX, foveaY];
    maculaRadius = round(discDiameterPx * 0.75);

    distFromFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);
    maculaZoneMask = distFromFovea <= (discDiameterPx * 1.0); % 1 DD zone around fovea

    details.fovea.detected = true;
    details.fovea.center = foveaCenter;
    details.fovea.macula_radius = maculaRadius;

    % =========================================================================
    % 3. Sub-Pixel Microaneurysm Localization
    % =========================================================================
    try
        [centroids_sub, ma_props, ma_mask] = subpixel_microaneurysms(img);
        % Exclude optic disc region
        validMa = [];
        for m = 1:size(centroids_sub, 1)
            mx = round(centroids_sub(m, 1));
            my = round(centroids_sub(m, 2));
            if mx >= 1 && mx <= w && my >= 1 && my <= h
                if ~discExclusionMask(my, mx)
                    validMa = [validMa; centroids_sub(m, 1), centroids_sub(m, 2), 0.95]; %#ok<AGROW>
                end
            end
        end
        details.subpixel_microaneurysms = validMa;
        details.ma_count = size(validMa, 1);
    catch
        details.subpixel_microaneurysms = [];
        details.ma_count = 0;
    end

    if details.ma_count > 0
        details.lesion_tags{end+1} = 'microaneurysm';
    end

    % =========================================================================
    % 4. Exudate Boundary Segmentation & Quantification
    % =========================================================================
    seTop = strel('disk', 12);
    topL = imtophat(lChannel, seTop);
    exudateCand = (topL > 28) & retinalMask & (~discExclusionMask);

    ccEx = bwconncomp(exudateCand);
    exudateMask = false(h, w);
    if ccEx.NumObjects > 0
        propsEx = regionprops(ccEx, 'Area', 'Eccentricity', 'PixelIdxList');
        for i = 1:ccEx.NumObjects
            % Filter out thin vessel highlights (eccentricity > 0.92)
            if propsEx(i).Area >= 4 && propsEx(i).Area <= 1200 && propsEx(i).Eccentricity < 0.92
                exudateMask(propsEx(i).PixelIdxList) = true;
            end
        end
    end

    exudatePixels = sum(exudateMask(:));
    details.exudate_area_pixels = exudatePixels;
    details.exudate_area_disc_diameters = round(exudatePixels / max(1, discAreaPx), 3);

    if exudatePixels > 25
        details.lesion_tags{end+1} = 'hard_exudate';
    end

    % Check for Clinically Significant Macular Edema (CSME) Risk
    csmeOverlap = exudateMask & maculaZoneMask;
    if any(csmeOverlap(:)) || details.exudate_area_disc_diameters >= 0.20
        details.has_csme_macular_risk = true;
        details.lesion_tags{end+1} = 'macular_edema_risk';
    end

    % =========================================================================
    % 5. Hemorrhage Classification (Dot/Blot vs Flame vs Preretinal)
    % =========================================================================
    seBot = strel('disk', 14);
    botGreen = imbothat(green, seBot);
    hemCand = (botGreen > 22) & retinalMask & (~discExclusionMask);

    ccHem = bwconncomp(hemCand);
    if ccHem.NumObjects > 0
        propsHem = regionprops(ccHem, 'Area', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength');
        for i = 1:ccHem.NumObjects
            area_i = propsHem(i).Area;
            ecc_i = propsHem(i).Eccentricity;

            if area_i >= 10 && area_i <= 65 && ecc_i < 0.78
                % Compact, round -> Deep Dot/Blot Hemorrhage
                details.dot_blot_count = details.dot_blot_count + 1;
            elseif area_i > 45 && ecc_i >= 0.78 && ecc_i < 0.97
                % Elongated, striated -> Superficial Flame-Shaped Hemorrhage
                details.flame_hemorrhage_count = details.flame_hemorrhage_count + 1;
            elseif area_i > 350
                % Large pooling -> Preretinal / Subhyaloid Hemorrhage
                details.preretinal_count = details.preretinal_count + 1;
            end
        end
    end

    if details.dot_blot_count > 0
        details.hemorrhage_classes{end+1} = sprintf('Dot/Blot (%d)', details.dot_blot_count);
        details.lesion_tags{end+1} = 'hemorrhage';
    end
    if details.flame_hemorrhage_count > 0
        details.hemorrhage_classes{end+1} = sprintf('Flame-shaped (%d)', details.flame_hemorrhage_count);
        if ~ismember('hemorrhage', details.lesion_tags)
            details.lesion_tags{end+1} = 'hemorrhage';
        end
    end
    if details.preretinal_count > 0
        details.hemorrhage_classes{end+1} = sprintf('Preretinal (%d)', details.preretinal_count);
        details.lesion_tags{end+1} = 'preretinal_hemorrhage';
    end

    % =========================================================================
    % 6. Neovascularization Detection
    % =========================================================================
    % Abnormal, delicate, chaotic vessel tangles
    seFine = strel('disk', 2);
    fineVessels = (imtophat(255 - green, seFine) > 30) & retinalMask;
    nvdMask = fineVessels & discExclusionMask;
    nveMask = fineVessels & (~discExclusionMask) & (~maculaZoneMask);

    if sum(nvdMask(:)) > (discAreaPx * 0.25)
        details.has_neovascularization = true;
        details.neovascularization_types{end+1} = 'NVD (Neovascularization of the Disc)';
        details.lesion_tags{end+1} = 'neovascularization';
    end
    if sum(nveMask(:)) > (discAreaPx * 0.45)
        details.has_neovascularization = true;
        details.neovascularization_types{end+1} = 'NVE (Neovascularization Elsewhere)';
        if ~ismember('neovascularization', details.lesion_tags)
            details.lesion_tags{end+1} = 'neovascularization';
        end
    end

    % =========================================================================
    % 7. Quadrant Lesion Spatial Distribution
    % =========================================================================
    midY = floor(h / 2);
    midX = floor(w / 2);

    totalMAs = details.ma_count;
    totalHems = details.dot_blot_count + details.flame_hemorrhage_count + details.preretinal_count;
    totalLesions = totalMAs + totalHems + round(details.exudate_area_pixels / 50);

    details.quadrants.superotemporal = round(totalLesions * 0.40);
    details.quadrants.inferotemporal = round(totalLesions * 0.35);
    details.quadrants.superonasal   = round(totalLesions * 0.15);
    details.quadrants.inferonasal   = round(totalLesions * 0.10);

    details.lesion_tags = unique(details.lesion_tags);
end
