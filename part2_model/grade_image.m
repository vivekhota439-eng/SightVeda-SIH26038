function [res, jsonStr] = grade_image(imagePath, modelPath, confThreshold)
% GRADE_IMAGE Advanced Diagnostic Inference Function for Diabetic Retinopathy.
% Integrates Deep CNN classifier, Sub-Pixel Lesion Detection, Hybrid Clinical
% Rule Engine (Level 2+ Referable DR), Calibrated Confidence, and Visual Explainability.
%
% Syntax:
%   [res, jsonStr] = grade_image(imagePath, modelPath, confThreshold)
%
% Enforces:
%   If trained model weights do not exist, does NOT use an untrained/fake network.
%   Halts with a clear instruction to train the model first.

    persistent cachedNet cachedPath
    cfg = config_params();

    if nargin < 2 || isempty(modelPath)
        modelPath = cfg.MODEL_WEIGHTS_PATH;
    end
    if nargin < 3 || isempty(confThreshold)
        confThreshold = cfg.CONFIDENCE_THRESHOLD;
    end

    % 1. Validate Input Image
    if ~exist(imagePath, 'file')
        error("Input image file not found: '%s'", imagePath);
    end

    try
        img = imread(imagePath);
    catch ME
        error("Failed to decode image at '%s': %s", imagePath, ME.message);
    end

    if ndims(img) == 2
        img = cat(3, img, img, img);
    end

    % 2. Enforce Trained Model Existence (NO FAKE / UNTRAINED WEIGHTS)
    if ~exist(modelPath, 'file')
        error("Trained model not found at '%s'.\nPlease train the model using 'train_retinal_model' before running inference.", modelPath);
    end

    % Load trained model (with persistent caching for high-speed inference)
    if isempty(cachedNet) || ~strcmp(cachedPath, modelPath)
        savedData = load(modelPath, 'net');
        if ~isfield(savedData, 'net')
            error("Invalid model file '%s'. Expected variable 'net'.", modelPath);
        end
        cachedNet = savedData.net;
        cachedPath = modelPath;
    end

    % 3. Preprocess for CNN Input (224x224x3)
    imgResized = imresize(img, cfg.IMAGE_SIZE);

    % 4. Model Inference & Softmax Probabilities
    [~, scores] = classify(cachedNet, imgResized);
    scores = double(scores(:)');

    % 5. Advanced Sub-Pixel Lesion Detection & Landmark Analysis
    lesionDetails = detect_lesions_advanced(img);

    % 6. Hybrid Clinical Rule Engine (Referable DR Level 2+ & Calibration)
    decision = clinical_rule_engine(scores, lesionDetails, confThreshold);

    % 7. Grade-Specific Recommendations (Etiology, Parhez, Lifting restrictions)
    recs = get_clinical_recommendations(double(decision.grade));

    % 8. Visual Explainability & Clinician Dashboard Metadata (<30s review)
    explainData = generate_explainability(img, cachedNet, lesionDetails);

    % 9. Assemble Structured Diagnostic Result
    normalizedPath = string(strrep(imagePath, '\', '/'));

    res = struct();
    res.image_path = normalizedPath;
    res.grade = int32(decision.grade);
    res.grade_label = string(decision.grade_label);
    res.confidence = double(decision.calibrated_confidence);
    res.raw_confidence = double(decision.raw_confidence);
    res.status = string(decision.status);
    res.lesions = lesionDetails.lesion_tags;

    % Advanced Clinical Triage & Biomarkers
    res.is_referable = logical(decision.is_referable);
    res.referral_urgency = string(decision.referral_urgency);
    res.urgency_label = string(decision.urgency_label);
    res.follow_up_timeline = string(decision.follow_up_timeline);
    res.action_plan = string(decision.action_plan);
    res.rule_overrides = decision.rule_overrides;

    res.subpixel_microaneurysm_count = int32(lesionDetails.ma_count);
    res.hemorrhage_classification = lesionDetails.hemorrhage_classes;
    res.exudate_area_disc_diameters = double(lesionDetails.exudate_area_disc_diameters);
    res.has_csme_macular_risk = logical(lesionDetails.has_csme_macular_risk);
    res.has_neovascularization = logical(lesionDetails.has_neovascularization);
    res.quadrants = lesionDetails.quadrants;
    res.peak_quadrant = explainData.peak_quadrant;

    % Explainability & Review Metadata
    res.annotated_evidence_image = explainData.annotated_image_path;
    res.heatmap_image_path = explainData.heatmap_image_path;
    res.estimated_doctor_review_seconds = explainData.estimated_doctor_review_time_seconds;

    % Clinical CDS Guidelines
    res.recommendations = recs;

    jsonStr = jsonencode(res, 'PrettyPrint', true);
end
