function decision = clinical_rule_engine(cnnScores, lesionDetails, confThreshold)
% CLINICAL_RULE_ENGINE Hybrid AI Clinical Rule Engine for Diabetic Retinopathy.
%
% Synthesizes Deep Learning CNN predictions with objective lesion evidence,
% evaluates the Level 2+ Referable DR criterion, calculates calibrated confidence,
% and determines referral urgency and clinical follow-up intervals.
%
% Inputs:
%   cnnScores     - 1x5 vector of CNN softmax probabilities [p0, p1, p2, p3, p4]
%   lesionDetails - Struct from detect_lesions_advanced.m
%   confThreshold - Confidence threshold (default: 0.70)
%
% Output:
%   decision      - Struct with final grade, referable flag, urgency, and clinical recommendations

    cfg = config_params();

    if nargin < 3 || isempty(confThreshold)
        confThreshold = cfg.CONFIDENCE_THRESHOLD;
    end

    % 1. Raw CNN Argmax
    [rawConfidence, maxIdx] = max(cnnScores);
    cnnGrade = maxIdx - 1;

    % 2. Confidence Calibration (Temperature Scaling & Margin Delta)
    calib = calibrate_confidence(cnnScores, cfg.TEMPERATURE_SCALING);
    calibConfidence = calib.confidence;

    % 3. Clinical Rule Fusion with Lesion Evidence
    finalGrade = cnnGrade;
    ruleOverrides = {};

    % Safety Override 1: CNN predicted Grade 0 (No DR), but lesions are detected
    if finalGrade == 0
        if lesionDetails.has_neovascularization || lesionDetails.preretinal_count > 0
            finalGrade = 4;
            ruleOverrides{end+1} = "Elevated 0->4: Neovascularization / preretinal blood detected.";
        elseif lesionDetails.has_csme_macular_risk || (lesionDetails.flame_hemorrhage_count + lesionDetails.dot_blot_count >= 4)
            finalGrade = 3;
            ruleOverrides{end+1} = "Elevated 0->3: Macular exudate risk or extensive hemorrhages detected.";
        elseif (lesionDetails.exudate_area_pixels > 20) || (lesionDetails.dot_blot_count >= 1)
            finalGrade = 2;
            ruleOverrides{end+1} = "Elevated 0->2: Hard exudates or intraretinal hemorrhages confirmed.";
        elseif lesionDetails.ma_count >= 1
            finalGrade = 1;
            ruleOverrides{end+1} = "Elevated 0->1: Microaneurysms confirmed via sub-pixel analysis.";
        end
    end

    % Safety Override 2: Proliferative DR check
    if lesionDetails.has_neovascularization && finalGrade < 4
        finalGrade = 4;
        ruleOverrides{end+1} = "Elevated to Grade 4: Active neovascularization identified.";
    end

    % 4. Referable Diabetic Retinopathy (RDR) Level 2+ Criterion
    % Referable DR = ICDR Grade >= 2 OR Clinically Significant Macular Edema (CSME) OR Neovascularization
    isReferable = (finalGrade >= 2) || lesionDetails.has_csme_macular_risk || lesionDetails.has_neovascularization;

    % 5. Clinical Referral Urgency & Follow-Up Triage
    switch finalGrade
        case 0
            referralUrgency = "routine";
            urgencyLabel = "Routine Annual Screening";
            followUpTimeline = "12 months";
            actionPlan = "Continue regular glycemic and blood pressure control. Annual retinal fundus screening recommended.";

        case 1
            if lesionDetails.has_csme_macular_risk
                referralUrgency = "referable_standard";
                urgencyLabel = "Referable DR (Macular Edema Risk)";
                followUpTimeline = "Within 1 month";
                actionPlan = "Foveal exudates noted. Refer to ophthalmologist for optical coherence tomography (OCT) evaluation.";
            else
                referralUrgency = "mild_followup";
                urgencyLabel = "Non-Referable Mild DR";
                followUpTimeline = "6 to 12 months";
                actionPlan = "Early microaneurysms detected. Optimize HbA1c control and repeat retinal screening in 6-12 months.";
            end

        case 2
            referralUrgency = "referable_standard";
            urgencyLabel = "Referable Moderate NPDR";
            followUpTimeline = "Within 1 to 3 months";
            actionPlan = "Refer to comprehensive ophthalmologist for dilated fundus exam and potential macular edema management.";

        case 3
            referralUrgency = "referable_urgent";
            urgencyLabel = "Referable Severe NPDR (High Risk of Progression)";
            followUpTimeline = "Within 2 to 4 weeks";
            actionPlan = "High risk of rapid progression to Proliferative DR. Urgent ophthalmology evaluation recommended.";

        case 4
            referralUrgency = "immediate_emergency";
            urgencyLabel = "Vision-Threatening Proliferative DR (Urgent)";
            followUpTimeline = "Within 24 to 48 hours";
            actionPlan = "Active neovascularization/preretinal hemorrhage. Immediate referral for panretinal photocoagulation or anti-VEGF therapy.";
    end

    % 6. Certainty Status
    status = "confident";
    if calibConfidence < confThreshold || calib.is_narrow || ~isempty(ruleOverrides)
        status = "uncertain";
    end

    decision = struct();
    decision.grade = int32(finalGrade);
    decision.grade_label = cfg.GRADE_LABELS(double(finalGrade));
    decision.raw_confidence = rawConfidence;
    decision.calibrated_confidence = calibConfidence;
    decision.calibration_info = calib;
    decision.status = status;
    decision.is_referable = isReferable;
    decision.referral_urgency = referralUrgency;
    decision.urgency_label = urgencyLabel;
    decision.follow_up_timeline = followUpTimeline;
    decision.action_plan = actionPlan;
    decision.rule_overrides = ruleOverrides;
end
