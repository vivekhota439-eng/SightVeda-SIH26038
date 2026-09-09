function [qualityStatus, qualityScore, failureReason, metrics] = check_quality(image, cfg)
% CHECK_QUALITY Comprehensive multi-stage retinal fundus image quality screening.
% Evaluates focus/sharpness, illumination uniformity, FOV geometry, and vessel contrast.
%
% Syntax:
%   [qualityStatus, qualityScore, failureReason, metrics] = check_quality(image, cfg)
%
% Outputs:
%   qualityStatus - "acceptable" or "ungradable"
%   qualityScore  - Quality score normalized to [0.0, 1.0]
%   failureReason - Clear explanation if quality check failed (empty string if acceptable)
%   metrics       - Struct containing all quantitative quality measurements

    if nargin < 2 || isempty(cfg)
        cfg = config_params();
    end

    qualityStatus = "acceptable";
    failureReason = "";

    if ischar(image) || isstring(image)
        imgPath = char(image);
        if exist(imgPath, 'file') ~= 2
            qualityStatus = "ungradable";
            qualityScore = 0.0;
            failureReason = sprintf("Image file does not exist: '%s'", imgPath);
            metrics = struct();
            return;
        end
        try
            image = imread(imgPath);
        catch ME
            qualityStatus = "ungradable";
            qualityScore = 0.0;
            failureReason = sprintf("Failed to decode image file: %s", ME.message);
            metrics = struct();
            return;
        end
    end

    if ndims(image) == 3
        gray = double(rgb2gray(image));
        green = double(image(:, :, 2));
    else
        gray = double(image);
        green = gray;
    end
    [h, w] = size(gray);

    % 1. Extract Retinal Mask & Framing Geometry
    [mask, coverage, circularity, aspectRatio] = extract_retinal_mask(uint8(gray));

    if ~any(mask(:)) || coverage < 0.08
        qualityStatus = "ungradable";
        qualityScore = 0.05;
        failureReason = "No retinal structure detected or severely obstructed Field of View (FOV)";
        metrics = struct('coverage', coverage, 'circularity', circularity, 'aspectRatio', aspectRatio, 'focusScore', 0);
        return;
    end

    % 2. Focus / Sharpness Assessment (Laplacian variance inside eroded mask)
    seErode = strel('disk', 15);
    erodedMask = imerode(mask, seErode);
    if ~any(erodedMask(:))
        erodedMask = mask;
    end

    lapFilter = [0, 1, 0; 1, -4, 1; 0, 1, 0];
    lapImg = conv2(gray, lapFilter, 'same');
    lapPixels = lapImg(erodedMask);
    focusScore = var(lapPixels);

    % 3. Illumination & Uniformity
    retinaGray = gray(mask);
    meanBrightness = mean(retinaGray);
    contrastStd = std(retinaGray);

    % Quadrant-based intensity consistency
    midY = floor(h / 2);
    midX = floor(w / 2);
    q1 = gray(1:midY, 1:midX); q1Mask = mask(1:midY, 1:midX);
    q2 = gray(1:midY, (midX+1):w); q2Mask = mask(1:midY, (midX+1):w);
    q3 = gray((midY+1):h, 1:midX); q3Mask = mask((midY+1):h, 1:midX);
    q4 = gray((midY+1):h, (midX+1):w); q4Mask = mask((midY+1):h, (midX+1):w);

    quadMeans = [];
    if any(q1Mask(:)), quadMeans(end+1) = mean(q1(q1Mask)); end %#ok<AGROW>
    if any(q2Mask(:)), quadMeans(end+1) = mean(q2(q2Mask)); end %#ok<AGROW>
    if any(q3Mask(:)), quadMeans(end+1) = mean(q3(q3Mask)); end %#ok<AGROW>
    if any(q4Mask(:)), quadMeans(end+1) = mean(q4(q4Mask)); end %#ok<AGROW>

    if length(quadMeans) >= 2
        lightingStd = std(quadMeans);
    else
        lightingStd = 0.0;
    end

    % 4. Field of View (FOV) Checks
    fovPass = (coverage >= cfg.QUALITY.MIN_FOV_COVERAGE) && ...
              (circularity >= cfg.QUALITY.MIN_CIRCULARITY) && ...
              (aspectRatio >= 0.55 && aspectRatio <= 1.80);

    % 5. Vessel Visibility / Contrast
    seVessel = strel('disk', 3);
    dilatedGreen = imdilate(green, seVessel);
    erodedGreen = imerode(green, seVessel);
    morphGrad = dilatedGreen - erodedGreen;
    retinaGrad = morphGrad(erodedMask);
    if ~isempty(retinaGrad)
        vesselContrast = prctile(retinaGrad, 95);
    else
        vesselContrast = 0.0;
    end

    % 6. Sub-Scores (0.0 to 1.0)
    sFocus = min(1.0, focusScore / cfg.QUALITY.FOCUS_OPTIMAL);

    if meanBrightness >= cfg.QUALITY.MIN_BRIGHTNESS && meanBrightness <= cfg.QUALITY.MAX_BRIGHTNESS
        sExposure = max(0.35, 1.0 - abs(meanBrightness - 115.0) / 80.0);
    elseif meanBrightness < cfg.QUALITY.MIN_BRIGHTNESS
        sExposure = max(0.02, (meanBrightness / cfg.QUALITY.MIN_BRIGHTNESS) * 0.30);
    else
        sExposure = max(0.02, ((255.0 - meanBrightness) / (255.0 - cfg.QUALITY.MAX_BRIGHTNESS)) * 0.30);
    end

    sUniformity = max(0.0, 1.0 - min(1.0, lightingStd / cfg.QUALITY.MAX_LIGHTING_STD));
    sFov = min(1.0, (coverage / 0.50)) * min(1.0, (circularity / 0.65));
    sVessel = min(1.0, vesselContrast / 35.0);

    % Sharpness penalty for severe blur
    sharpnessPenalty = 1.0;
    if focusScore < cfg.QUALITY.BLUR_HARD_FAIL
        sharpnessPenalty = max(0.15, focusScore / cfg.QUALITY.BLUR_HARD_FAIL);
    end

    composite = ((0.35 * sFocus) + ...
                 (0.25 * sExposure) + ...
                 (0.15 * sUniformity) + ...
                 (0.13 * sFov) + ...
                 (0.12 * sVessel)) * sharpnessPenalty;

    qualityScore = round(max(0.05, min(0.99, composite)), 2);

    % 7. Threshold Evaluation
    if focusScore < cfg.QUALITY.BLUR_HARD_FAIL
        qualityStatus = "ungradable";
        failureReason = sprintf("Severe defocus / blur (focus variance %.1f < %.1f)", focusScore, cfg.QUALITY.BLUR_HARD_FAIL);
    elseif meanBrightness < cfg.QUALITY.MIN_BRIGHTNESS
        qualityStatus = "ungradable";
        failureReason = sprintf("Severe underexposure / too dark (mean intensity %.1f < %.1f)", meanBrightness, cfg.QUALITY.MIN_BRIGHTNESS);
    elseif meanBrightness > cfg.QUALITY.MAX_BRIGHTNESS
        qualityStatus = "ungradable";
        failureReason = sprintf("Severe overexposure / too bright (mean intensity %.1f > %.1f)", meanBrightness, cfg.QUALITY.MAX_BRIGHTNESS);
    elseif ~fovPass
        qualityStatus = "ungradable";
        failureReason = sprintf("Inadequate retinal FOV framing (coverage %.2f, circularity %.2f)", coverage, circularity);
    elseif qualityScore < cfg.QUALITY.BORDERLINE_THRESHOLD
        qualityStatus = "ungradable";
        failureReason = sprintf("Overall image quality too degraded (Score: %.2f < %.2f)", qualityScore, cfg.QUALITY.BORDERLINE_THRESHOLD);
    else
        qualityStatus = "acceptable";
        failureReason = "";
    end

    metrics = struct();
    metrics.qualityStatus = qualityStatus;
    metrics.qualityScore = qualityScore;
    metrics.focusScore = focusScore;
    metrics.meanBrightness = meanBrightness;
    metrics.lightingStd = lightingStd;
    metrics.contrastStd = contrastStd;
    metrics.coverage = coverage;
    metrics.circularity = circularity;
    metrics.aspectRatio = aspectRatio;
    metrics.vesselContrast = vesselContrast;
    metrics.isBorderline = (qualityScore >= cfg.QUALITY.BORDERLINE_THRESHOLD && qualityScore < cfg.QUALITY.OPTIMAL_THRESHOLD);
    metrics.retinalMask = mask;
end
