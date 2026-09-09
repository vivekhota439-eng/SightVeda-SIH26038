function calib = calibrate_confidence(rawProbs, temperature)
% CALIBRATE_CONFIDENCE Softmax Confidence Calibration & Margin Delta Analysis.
% Uses Temperature Scaling to calibrate raw deep learning probabilities and
% checks for narrow decision boundaries between Top-1 and Top-2 predictions.
%
% Syntax:
%   calib = calibrate_confidence(rawProbs, temperature)

    if nargin < 2 || isempty(temperature)
        cfg = config_params();
        temperature = cfg.TEMPERATURE_SCALING;
    end

    rawProbs = double(rawProbs(:)');
    epsVal = 1e-7;
    clamped = max(rawProbs, epsVal);
    logits = log(clamped);

    % Temperature scaling: z_i / T
    scaledLogits = logits / temperature;

    % Softmax computation
    exps = exp(scaledLogits - max(scaledLogits));
    calibratedProbs = exps / sum(exps);

    [sortedP, ~] = sort(calibratedProbs, 'descend');
    top1 = sortedP(1);
    if length(sortedP) >= 2
        top2 = sortedP(2);
    else
        top2 = 0.0;
    end

    marginDelta = (top1 - top2) * 100.0;
    isNarrow = marginDelta < 12.0;

    calib = struct();
    calib.calibrated_probs = round(calibratedProbs, 4);
    calib.confidence = round(top1, 4);
    calib.confidence_pct = round(top1 * 100, 1);
    calib.margin_delta_pct = round(marginDelta, 1);
    calib.is_narrow = isNarrow;
    if isNarrow
        calib.reliability = 'BORDERLINE / ACTIVE OPHTHALMIC CONFIRMATION ADVISED';
    else
        calib.reliability = 'CONFIDENT CLINICAL PREDICTION';
    end
end
