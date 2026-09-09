function result = preprocessing(image_path)
% =========================================================================
% Diabetic Retinopathy Detection System - Task 1: Image Preprocessing Module
% =========================================================================
% This module implements the first stage of the Diabetic Retinopathy (DR)
% detection pipeline in MATLAB: Retinal Fundus Preprocessing & Quality Check.
%
% Key Features:
% 1. check_quality(image_path):
%    - Assesses sharpness (Laplacian variance), brightness, FOV, and contrast.
%    - Continuous quality score from 0.0 to 1.0 (0% to 100%).
% 2. enhance_image(image_path, is_borderline):
%    - Contrast enhancement via CLAHE (adapthisteq) on L channel in LAB space.
%    - 30%-40% Borderline images get adaptive CLAHE + unsharp sharpening.
% 3. process_image(image_path):
%    - Returns struct & clean JSON output with Recapture guidance if < 30%.
%
% Usage:
%   result = preprocessing('good_retina_image.png');
%   preprocessing();  % Runs demo test suite if no argument is passed
% =========================================================================

    % Agar user ne koi argument nahi diya, toh demo test chalayein
    if nargin < 1 || isempty(image_path)
        fprintf('======================================================================\n');
        fprintf('DIABETIC RETINOPATHY PREPROCESSING TEST RUN (MATLAB)\n');
        fprintf('======================================================================\n\n');
        run_demo_test_suite();
        result = [];
        return;
    end

    % Diye gaye image path ko process karein
    result = process_image(image_path);
    
    % Pretty JSON format me print karein
    try
        json_output = jsonencode(result, 'PrettyPrint', true);
    catch
        % Older MATLAB versions fallback
        json_output = jsonencode(result);
    end
    fprintf('%s\n', json_output);
end


% =========================================================================
% Threshold Configuration Constants
% =========================================================================
function cfg = get_config()
    cfg.BLUR_HARD_FAIL       = 8.0;     % Extreme blur hard threshold (< 8.0)
    cfg.BLUR_OPTIMAL         = 180.0;   % Baseline Laplacian variance for sharp retina
    cfg.MIN_BRIGHTNESS       = 35.0;    % Minimum mean retinal intensity
    cfg.MAX_BRIGHTNESS       = 190.0;   % Maximum mean retinal intensity
    cfg.MIN_FOV_COVERAGE     = 0.18;    % Minimum retinal coverage ratio
    cfg.MIN_CIRCULARITY      = 0.30;    % Minimum circularity index
    cfg.BORDERLINE_THRESHOLD = 0.30;    % 30%: Images at or above 30% are ENHANCED!
    cfg.OPTIMAL_THRESHOLD    = 0.50;    % 50%: Optimal diagnostic quality
    cfg.OUTPUT_DIR           = 'output';
end


% =========================================================================
% Main Pipeline Orchestrator: process_image
% =========================================================================
function output = process_image(image_path)
    cfg = get_config();
    [quality_status, quality_score, reason] = check_quality(image_path);
    
    output = struct();
    output.image_path = char(image_path);
    output.quality_status = char(quality_status);
    output.quality_score = quality_score;

    % Case 1: Quality is poor / ungradable (< 30% or severe error)
    if strcmp(quality_status, 'ungradable')
        output.reason = char(reason);
        output.action = 'Recapture image';
        output.recapture_required = true;
        output.recommendation = sprintf('Image quality is too poor (%s). Please recapture the retinal fundus image.', reason);
        return;
    end

    % Case 2: Quality is acceptable (>= 30%)
    % Check if image falls into 30% - 40% (Borderline) category
    is_borderline = quality_score < cfg.OPTIMAL_THRESHOLD;

    try
        enhanced_path = enhance_image(image_path, is_borderline);
        output.image_path = char(enhanced_path);
        
        if is_borderline
            output.quality_grade = sprintf('borderline (%d%% quality - enhanced)', round(quality_score * 100));
            output.action = 'enhanced';
            output.recapture_required = false;
            output.recommendation = sprintf('Image quality is borderline (%d%%). Adaptive enhancement applied to recover vessel/lesion details. Clinical review advised.', round(quality_score * 100));
        else
            output.quality_grade = sprintf('optimal (%d%% quality)', round(quality_score * 100));
            output.action = 'proceed';
            output.recapture_required = false;
            output.recommendation = 'Image quality is good. Ready for diabetic retinopathy grading.';
        end
    catch ME
        output.quality_status = 'ungradable';
        output.reason = sprintf('enhancement failure: %s', ME.message);
        output.action = 'Recapture image';
        output.recapture_required = true;
        output.recommendation = 'Internal error during enhancement. Please re-upload or recapture image.';
    end
end


% =========================================================================
% Quality Checking Function: check_quality
% =========================================================================
function [quality_status, quality_score, reason] = check_quality(image_path)
    cfg = get_config();

    % 1. Verify file exists
    if exist(image_path, 'file') ~= 2
        quality_status = 'ungradable';
        quality_score = 0.0;
        reason = 'file does not exist';
        return;
    end

    % 2. Read image
    try
        img = imread(image_path);
    catch
        quality_status = 'ungradable';
        quality_score = 0.0;
        reason = 'failed to load image';
        return;
    end

    if size(img, 3) == 3
        gray = rgb2gray(img);
    else
        gray = img;
    end

    % 3. Extract Retinal Mask and evaluate FOV
    [retinal_mask, coverage, circularity, aspect_ratio] = extract_retinal_mask(gray);

    if coverage < 0.10
        quality_status = 'ungradable';
        quality_score = 0.05;
        reason = 'poor FOV (no retinal disc detected)';
        return;
    end

    if ~any(retinal_mask(:))
        quality_status = 'ungradable';
        quality_score = 0.05;
        reason = 'poor FOV';
        return;
    end

    if aspect_ratio < 0.45 || aspect_ratio > 2.2
        quality_status = 'ungradable';
        quality_score = 0.10;
        reason = 'poor FOV';
        return;
    end

    % 4. Brightness & Contrast inside Retinal Mask
    mask_pixels = double(gray(retinal_mask));
    mean_brightness = mean(mask_pixels);
    contrast = std(mask_pixels);

    % 5. Sharpness (Laplacian variance inside eroded retinal region)
    se_erode = strel('disk', 3);
    eroded_mask = imerode(retinal_mask, se_erode);

    % Standard 3x3 Laplacian filter (same as cv2.Laplacian)
    lap_kernel = [0, 1, 0; 1, -4, 1; 0, 1, 0];
    lap = imfilter(double(gray), lap_kernel, 'replicate');

    if any(eroded_mask(:))
        retinal_lap_var = var(lap(eroded_mask));
    else
        retinal_lap_var = var(lap(:));
    end

    % 6. Continuous Sub-Scores Calculation (0.0 to 1.0)
    sharpness_score = min(1.0, retinal_lap_var / cfg.BLUR_OPTIMAL);

    if mean_brightness >= cfg.MIN_BRIGHTNESS && mean_brightness <= cfg.MAX_BRIGHTNESS
        brightness_score = max(0.35, 1.0 - abs(mean_brightness - 120.0) / 95.0);
    elseif mean_brightness < cfg.MIN_BRIGHTNESS
        brightness_score = max(0.02, (mean_brightness / cfg.MIN_BRIGHTNESS) * 0.30);
    else
        brightness_score = max(0.02, ((255.0 - mean_brightness) / (255.0 - cfg.MAX_BRIGHTNESS)) * 0.30);
    end

    fov_score = min(1.0, coverage / 0.50) * min(1.0, circularity / 0.65);
    contrast_score = min(1.0, contrast / 35.0);

    % Severe blur penalty factor
    sharpness_penalty = 1.0;
    if retinal_lap_var < cfg.BLUR_HARD_FAIL
        sharpness_penalty = max(0.15, retinal_lap_var / cfg.BLUR_HARD_FAIL);
    end

    composite = ((0.38 * sharpness_score) + ...
                 (0.28 * brightness_score) + ...
                 (0.20 * fov_score) + ...
                 (0.14 * contrast_score)) * sharpness_penalty;

    quality_score = round(max(0.05, min(0.99, composite)), 2);

    % Decision Rule:
    % Agar score 30% ya upar hai aur severe defocus nahi hai -> acceptable!
    if quality_score >= cfg.BORDERLINE_THRESHOLD && retinal_lap_var >= cfg.BLUR_HARD_FAIL
        quality_status = 'acceptable';
        reason = '';
        return;
    end

    % Below 30% -> Ungradable
    quality_status = 'ungradable';
    if retinal_lap_var < cfg.BLUR_HARD_FAIL || sharpness_score < 0.20
        reason = 'blurry';
    elseif mean_brightness < cfg.MIN_BRIGHTNESS
        reason = 'too dark';
    elseif mean_brightness > cfg.MAX_BRIGHTNESS
        reason = 'too bright';
    elseif fov_score < 0.25 || coverage < cfg.MIN_FOV_COVERAGE
        reason = 'poor FOV';
    else
        reason = 'overall quality too degraded (< 30%)';
    end
end


% =========================================================================
% Helper: Retinal Mask & Geometric Extraction
% =========================================================================
function [mask, coverage, circularity, aspect_ratio] = extract_retinal_mask(gray_image)
    [rows, cols] = size(gray_image);
    total_area = double(rows * cols);

    % Threshold foreground from camera border
    thresh = gray_image > 15;

    % Morphological closing to bridge dark vessels and fovea
    se = strel('disk', 7);
    closed = imclose(thresh, se);

    % Find connected components
    cc = bwconncomp(closed);
    if cc.NumObjects == 0
        mask = false(rows, cols);
        coverage = 0.0;
        circularity = 0.0;
        aspect_ratio = 0.0;
        return;
    end

    props = regionprops(cc, 'Area', 'Perimeter', 'BoundingBox', 'PixelIdxList');
    [area, max_idx] = max([props.Area]);

    coverage = area / total_area;
    perimeter = props(max_idx).Perimeter;
    if perimeter > 0
        circularity = (4.0 * pi * area) / (perimeter^2);
    else
        circularity = 0.0;
    end

    bbox = props(max_idx).BoundingBox; % [x, y, width, height]
    if bbox(4) > 0
        aspect_ratio = bbox(3) / bbox(4);
    else
        aspect_ratio = 0.0;
    end

    mask = false(rows, cols);
    mask(props(max_idx).PixelIdxList) = true;
end


% =========================================================================
% Image Enhancement Function: enhance_image
% =========================================================================
function output_path = enhance_image(image_path, is_borderline)
    cfg = get_config();

    img = imread(image_path);
    if size(img, 3) ~= 3
        img = repmat(img, [1 1 3]);
    end

    gray = rgb2gray(img);
    bg_mask = gray > 10;

    % Convert to LAB Color Space
    lab = rgb2lab(img);
    L = lab(:,:,1) / 100.0; % Normalize L to [0, 1] for adapthisteq

    if is_borderline
        % Adaptive enhancement for 30% - 40% borderline images:
        % 1. Stronger CLAHE (ClipLimit = 0.035)
        L_clahe = adapthisteq(L, 'ClipLimit', 0.035, 'NumTiles', [8 8]);

        % 2. Unsharp masking to boost faint vessel boundaries
        L_sharp = imsharpen(L_clahe, 'Radius', 2, 'Amount', 1.25);

        % 3. Illumination compensation (+12/255)
        L_adj = min(1.0, max(0.0, L_sharp + (12.0 / 255.0)));
    else
        % Standard CLAHE for clear images
        L_clahe = adapthisteq(L, 'ClipLimit', 0.020, 'NumTiles', [8 8]);
        L_adj = min(1.0, max(0.0, L_clahe + (8.0 / 255.0)));
    end

    lab(:,:,1) = L_adj * 100.0;
    enhanced_rgb = lab2rgb(lab);
    enhanced_rgb = uint8(round(enhanced_rgb * 255));

    % Restore clean background outside retinal mask
    for c = 1:3
        channel = enhanced_rgb(:,:,c);
        channel(~bg_mask) = 0;
        enhanced_rgb(:,:,c) = channel;
    end

    if ~exist(cfg.OUTPUT_DIR, 'dir')
        mkdir(cfg.OUTPUT_DIR);
    end

    [~, name, ext] = fileparts(image_path);
    if isempty(ext)
        ext = '.png';
    end
    if startsWith(name, 'enhanced_')
        out_name = [name ext];
    else
        out_name = ['enhanced_' name ext];
    end

    output_path = fullfile(cfg.OUTPUT_DIR, out_name);
    output_path = strrep(output_path, '\', '/');
    imwrite(enhanced_rgb, output_path);
end


% =========================================================================
% Synthetic Test Generator & Demo Test Suite
% =========================================================================
function run_demo_test_suite()
    cfg = get_config();
    test_cases = {
        'test_normal.png',        'normal';
        'test_borderline_35.png',  'borderline_35_percent';
        'test_severe_blur.png',    'blurry_severe';
        'test_severe_dark.png',    'too_dark_severe';
        'test_poor_fov.png',       'poor_fov'
    };

    for i = 1:size(test_cases, 1)
        filename = test_cases{i, 1};
        cond = test_cases{i, 2};
        filepath = fullfile(cfg.OUTPUT_DIR, filename);

        create_synthetic_fundus(filepath, cond);
        res = process_image(filepath);

        fprintf('Condition: [%s]\n', upper(cond));
        try
            disp(jsonencode(res, 'PrettyPrint', true));
        catch
            disp(jsonencode(res));
        end
        fprintf('\n');
    end
end

function create_synthetic_fundus(filepath, condition)
    h = 512; w = 512;
    img = zeros(h, w, 3, 'uint8');
    [X, Y] = meshgrid(1:w, 1:h);
    center = [256, 256];

    if strcmp(condition, 'poor_fov')
        dist = sqrt((X - (center(1)-120)).^2 + (Y - center(2)).^2);
        mask = dist <= 35;
        for c = 1:3
            channel = img(:,:,c);
            vals = [180, 60, 20];
            channel(mask) = vals(c);
            img(:,:,c) = channel;
        end
        [fdir, ~, ~] = fileparts(filepath);
        if ~exist(fdir, 'dir') && ~isempty(fdir), mkdir(fdir); end
        imwrite(img, filepath);
        return;
    end

    % Base Retina Disc
    dist_retina = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
    retina_mask = dist_retina <= 210;
    img(:,:,1) = uint8(retina_mask * 180);
    img(:,:,2) = uint8(retina_mask * 60);
    img(:,:,3) = uint8(retina_mask * 20);

    % Optic Disc
    od_center = [center(1) - 80, center(2)];
    dist_od = sqrt((X - od_center(1)).^2 + (Y - od_center(2)).^2);
    od_mask = dist_od <= 26;
    img(:,:,1) = img(:,:,1) + uint8(od_mask * 75);
    img(:,:,2) = img(:,:,2) + uint8(od_mask * 140);
    img(:,:,3) = img(:,:,3) + uint8(od_mask * 100);

    % Draw vessel branches
    for a = 0:11
        theta = a * (pi / 6);
        for r = 10:2:150
            px = round(od_center(1) + r * cos(theta));
            py = round(od_center(2) + r * sin(theta));
            if px >= 1 && px <= w && py >= 1 && py <= h && retina_mask(py, px)
                img(max(1, py-1):min(h, py+1), max(1, px-1):min(w, px+1), :) = 20;
            end
        end
    end

    % Add natural retinal texture
    rng(42);
    noise = randn(h, w, 3) * 4;
    img_d = double(img) + noise;
    img = uint8(max(0, min(255, img_d)));
    for c = 1:3
        ch = img(:,:,c);
        ch(~retina_mask) = 0;
        img(:,:,c) = ch;
    end

    % Apply test conditions
    if strcmp(condition, 'blurry_severe')
        img = imgaussfilt(img, 15);
    elseif strcmp(condition, 'borderline_35_percent')
        img = imgaussfilt(img, 1.2);
        img = uint8(double(img) * 0.55);
    elseif strcmp(condition, 'too_dark_severe')
        img = uint8(double(img) * 0.12);
    end

    [fdir, ~, ~] = fileparts(filepath);
    if ~exist(fdir, 'dir') && ~isempty(fdir), mkdir(fdir); end
    imwrite(img, filepath);
end