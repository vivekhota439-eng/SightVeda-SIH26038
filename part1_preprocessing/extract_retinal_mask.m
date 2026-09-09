function [mask, coverage, circularity, aspectRatio] = extract_retinal_mask(image)
% EXTRACT_RETINAL_MASK Segments the circular retinal Field of View (FOV)
% and computes geometric framing quality metrics.
%
% Syntax:
%   [mask, coverage, circularity, aspectRatio] = extract_retinal_mask(image)
%
% Inputs:
%   image       - RGB color or grayscale retinal fundus image (uint8)
%
% Outputs:
%   mask        - Binary logical mask (HxW) where true indicates retina
%   coverage    - Proportion of image area covered by retina (0.0 to 1.0)
%   circularity - Isoperimetric circularity quotient (4*pi*area / perimeter^2)
%   aspectRatio - Bounding box width / height of retinal aperture

    if ndims(image) == 3
        gray = rgb2gray(image);
    else
        gray = image;
    end
    [h, w] = size(gray);
    totalArea = double(h * w);

    % Threshold camera background aperture (aperture border is near zero)
    binaryThresh = gray > 15;

    % Morphological closing to bridge dark vessel branches and foveal depression
    seClose = strel('disk', 15);
    closed = imclose(binaryThresh, seClose);

    % Find connected components and extract largest region (retinal disc)
    cc = bwconncomp(closed);
    if cc.NumObjects == 0
        mask = false(h, w);
        coverage = 0.0;
        circularity = 0.0;
        aspectRatio = 0.0;
        return;
    end

    stats = regionprops(cc, 'Area', 'Perimeter', 'BoundingBox', 'PixelIdxList');
    areas = [stats.Area];
    [maxArea, largestIdx] = max(areas);

    mask = false(h, w);
    mask(stats(largestIdx).PixelIdxList) = true;
    mask = imfill(mask, 'holes');

    coverage = maxArea / totalArea;

    perimeter = stats(largestIdx).Perimeter;
    if perimeter > 0
        circularity = (4.0 * pi * maxArea) / (perimeter^2);
    else
        circularity = 0.0;
    end

    bbox = stats(largestIdx).BoundingBox; % [x, y, width, height]
    if bbox(4) > 0
        aspectRatio = bbox(3) / bbox(4);
    else
        aspectRatio = 0.0;
    end
end
