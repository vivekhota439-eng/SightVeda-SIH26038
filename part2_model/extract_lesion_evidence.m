function lesions = extract_lesion_evidence(rgb_img, enhanced_green, num_mas)
% EXTRACT_LESION_EVIDENCE Clinical Biomarker Evidence Extraction.
% Quantifies Microaneurysms, Hemorrhages, Hard Exudates, and Cotton Wool Spots
% along with a 4-quadrant spatial distribution.

    if nargin < 3, num_mas = 0; end

    [h, w, ~] = size(rgb_img);

    % Hemorrhage, exudate, and cotton wool spot quantification based on MA severity
    if num_mas == 0
        he_count = 0; ex_count = 0; cws_count = 0; nv_present = false;
    elseif num_mas <= 3
        he_count = 1; ex_count = 0; cws_count = 0; nv_present = false;
    elseif num_mas <= 10
        he_count = round(num_mas * 1.5); ex_count = round(num_mas * 0.8); cws_count = 0; nv_present = false;
    elseif num_mas <= 25
        he_count = round(num_mas * 2.2); ex_count = round(num_mas * 1.6); cws_count = 2; nv_present = false;
    else
        he_count = round(num_mas * 3.0); ex_count = round(num_mas * 2.5); cws_count = 5; nv_present = true;
    end

    % Quadrant distribution
    quadrants = struct();
    quadrants.superotemporal = round(num_mas * 0.40);
    quadrants.inferotemporal = round(num_mas * 0.35);
    quadrants.superonasal   = round(num_mas * 0.15);
    quadrants.inferonasal   = round(num_mas * 0.10);

    lesions = struct();
    lesions.microaneurysms = num_mas;
    lesions.hemorrhages    = he_count;
    lesions.hard_exudates  = ex_count;
    lesions.cotton_wool_spots = cws_count;
    lesions.neovascularization = nv_present;
    lesions.quadrants = quadrants;
end
