function lesions = detect_lesions(imageInput)
% DETECT_LESIONS Classical Computer Vision Heuristic Lesion & Landmark Detector.
%
% Implements a rule-based heuristic detector using classical morphological
% operations to identify microaneurysms, hemorrhages, and hard exudates.
%
% Inputs:
%   imageInput - File path string or RGB image matrix (uint8)
%
% Output:
%   lesions    - Cell array of strings, e.g. {'microaneurysm', 'hemorrhage'}

    lesions = {};

    if ischar(imageInput) || isstring(imageInput)
        imagePath = char(imageInput);
        if ~exist(imagePath, 'file'), return; end
        try
            img = imread(imagePath);
        catch
            return;
        end
    elseif isnumeric(imageInput)
        img = imageInput;
    else
        return;
    end

    if ndims(img) == 2
        img = cat(3, img, img, img);
    end

    [h, w, ~] = size(img);
    gray = rgb2gray(img);
    green = img(:, :, 2);

    % 1. Retinal FOV Segmentation
    retinalMask = gray > 15;
    seClose = strel('disk', 15);
    retinalMask = imclose(retinalMask, seClose);
    ccRetina = bwconncomp(retinalMask);
    if ccRetina.NumObjects == 0, return; end
    statsRetina = regionprops(ccRetina, 'Area');
    [~, maxIdx] = max([statsRetina.Area]);
    retinalMask = false(h, w);
    retinalMask(ccRetina.PixelIdxList{maxIdx}) = true;
    retinalMask = imfill(retinalMask, 'holes');
    retinalMask = imerode(retinalMask, strel('disk', 8));

    if sum(retinalMask(:)) < (h * w * 0.10), return; end

    % 2. Optic Disc Masking
    discMask = false(h, w);
    labImg = rgb2lab(img);
    lChannel = uint8(labImg(:, :, 1) * 2.55);
    brightCombined = imlincomb(0.5, lChannel, 0.5, img(:, :, 1));
    brightCombined(~retinalMask) = 0;

    minRadius = round(min(h, w) * 0.04);
    maxRadius = round(min(h, w) * 0.14);

    try
        [centers, radii] = imfindcircles(brightCombined, [minRadius, maxRadius], ...
            'ObjectPolarity', 'bright', 'Sensitivity', 0.88);
    catch
        centers = []; radii = [];
    end

    if ~isempty(centers)
        cx = round(centers(1, 1));
        cy = round(centers(1, 2));
        r = round(radii(1) * 1.35);
        [X, Y] = meshgrid(1:w, 1:h);
        discMask = ((X - cx).^2 + (Y - cy).^2) <= r^2;
    end

    analysisMask = retinalMask & (~discMask);

    % 3. Red Lesions (Microaneurysms & Hemorrhages via Green Channel Bottom-Hat)
    seRed = strel('disk', 10);
    bottomHat = imbothat(green, seRed);
    bottomHat(~analysisMask) = 0;

    redThresh = bottomHat > 18;
    ccRed = bwconncomp(redThresh);

    if ccRed.NumObjects > 0
        propsRed = regionprops(ccRed, 'Area', 'Eccentricity');
        maFound = false;
        hemFound = false;
        for i = 1:ccRed.NumObjects
            a = propsRed(i).Area;
            if a >= 2 && a <= 30
                maFound = true;
            elseif a > 30 && a <= 2000
                hemFound = true;
            end
        end
        if maFound, lesions{end+1} = 'microaneurysm'; end
        if hemFound, lesions{end+1} = 'hemorrhage'; end
    end

    % 4. Bright Lesions (Hard Exudates via Luminance Top-Hat)
    seBright = strel('disk', 12);
    topHat = imtophat(lChannel, seBright);
    topHat(~analysisMask) = 0;

    brightThresh = topHat > 24;
    ccBright = bwconncomp(brightThresh);

    if ccBright.NumObjects > 0
        propsBright = regionprops(ccBright, 'Area');
        exFound = false;
        for i = 1:ccBright.NumObjects
            if propsBright(i).Area >= 5 && propsBright(i).Area <= 1500
                exFound = true;
                break;
            end
        end
        if exFound, lesions{end+1} = 'hard_exudate'; end
    end

    lesions = unique(lesions);
end
