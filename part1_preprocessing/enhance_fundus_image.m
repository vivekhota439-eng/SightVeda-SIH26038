function [enhancedPath, enhancedUint8] = enhance_fundus_image(image, originalPath, outputDir, isBorderline)
% ENHANCE_FUNDUS_IMAGE AI-Assisted Retinal Enhancement Pipeline:
% 1. Retinal FOV Mask & Background Preservation
% 2. Homomorphic Illumination Normalization (suppresses slow vignetting & flash gradients)
% 3. Edge-Preserving Bilateral Denoising (suppresses sensor grain while preserving microvessels)
% 4. Adaptive Dual-Channel CLAHE (Luminance in LAB + Vascular Green Channel)
% 5. Adaptive Sharpening for Borderline (30%-49%) quality images
%
% Syntax:
%   [enhancedPath, enhancedUint8] = enhance_fundus_image(image, originalPath, outputDir, isBorderline)

    if nargin < 3 || isempty(outputDir)
        cfg = config_params();
        outputDir = cfg.OUTPUT_ENHANCED;
    end
    if nargin < 4 || isempty(isBorderline)
        isBorderline = false;
    end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    if ischar(image) || isstring(image)
        originalPath = char(image);
        image = imread(originalPath);
    end

    if ndims(image) == 2
        image = repmat(image, [1, 1, 3]);
    end

    imgDbl = im2double(image);
    [h, w, ~] = size(imgDbl);

    % Extract FOV mask to retain clear background
    grayImg = rgb2gray(uint8(imgDbl * 255.0));
    [retinalMask, ~, ~, ~] = extract_retinal_mask(grayImg);
    if ~any(retinalMask(:))
        retinalMask = grayImg > 12;
    end

    % =========================================================================
    % 1. Homomorphic Illumination Normalization (Log Domain High-Pass Filter)
    % =========================================================================
    imgNorm = zeros(size(imgDbl));
    sigmaIllum = max(15, round(min(h, w) * 0.08));

    for c = 1:3
        channel = imgDbl(:, :, c);
        logCh = log(channel + 0.01);
        illumEst = imgaussfilt(logCh, sigmaIllum);
        reflectance = logCh - illumEst;
        reconstructed = exp(reflectance);

        pMin = prctile(reconstructed(retinalMask), 1);
        pMax = prctile(reconstructed(retinalMask), 99);
        if isempty(pMin) || isnan(pMin), pMin = 0.0; end
        if isempty(pMax) || isnan(pMax), pMax = 1.0; end

        if pMax > pMin
            imgNorm(:, :, c) = (reconstructed - pMin) / (pMax - pMin);
        else
            imgNorm(:, :, c) = channel;
        end
    end
    imgNorm = max(0.0, min(1.0, imgNorm));

    % =========================================================================
    % 2. Edge-Preserving Bilateral Denoising
    % =========================================================================
    try
        imgDenoised = imbilatfilt(imgNorm, 0.04, 3);
    catch
        imgDenoised = imgNorm;
        for c = 1:3
            imgDenoised(:, :, c) = medfilt2(imgNorm(:, :, c), [3, 3]);
        end
    end

    % =========================================================================
    % 3. Dual-Channel CLAHE (Luminance & Green Channel)
    % =========================================================================
    labImg = rgb2lab(imgDenoised);
    lChannel = labImg(:, :, 1) / 100.0; % Normalize L to [0, 1]

    if isBorderline
        % Adaptive boost for borderline quality (30% - 49%)
        lClahe = adapthisteq(lChannel, 'ClipLimit', 0.035, 'NumTiles', [8, 8], 'Distribution', 'uniform');
        try
            lSharp = imsharpen(lClahe, 'Radius', 2, 'Amount', 1.25);
        catch
            lSharp = lClahe;
        end
        lAdj = min(1.0, max(0.0, lSharp + (12.0 / 255.0)));
        clipGreen = 0.028;
    else
        % Standard clinical CLAHE for clear images (>= 50%)
        lClahe = adapthisteq(lChannel, 'ClipLimit', 0.020, 'NumTiles', [8, 8], 'Distribution', 'uniform');
        lAdj = min(1.0, max(0.0, lClahe + (8.0 / 255.0)));
        clipGreen = 0.018;
    end

    labImg(:, :, 1) = lAdj * 100.0;
    enhancedRgb = lab2rgb(labImg);

    % Vascular enhancement in Green channel
    greenCh = imgDenoised(:, :, 2);
    try
        enhancedGreen = adapthisteq(greenCh, 'ClipLimit', clipGreen, 'NumTiles', [8, 8]);
        enhancedRgb(:, :, 2) = 0.5 * enhancedRgb(:, :, 2) + 0.5 * enhancedGreen;
    catch
    end

    enhancedUint8 = uint8(max(0.0, min(1.0, enhancedRgb)) * 255.0);

    % Clean black background outside retina
    for c = 1:3
        ch = enhancedUint8(:, :, c);
        ch(~retinalMask) = 0;
        enhancedUint8(:, :, c) = ch;
    end

    % Build output filename
    if nargin >= 2 && ~isempty(originalPath)
        [~, name, ext] = fileparts(originalPath);
    else
        name = sprintf('retina_%s', char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')));
        ext = '.png';
    end
    if isempty(ext), ext = '.png'; end

    if startsWith(name, 'enhanced_')
        outFilename = [name, ext];
    else
        outFilename = ['enhanced_', name, ext];
    end

    enhancedPath = fullfile(outputDir, outFilename);
    enhancedPath = strrep(enhancedPath, '\', '/');

    imwrite(enhancedUint8, enhancedPath);
end
