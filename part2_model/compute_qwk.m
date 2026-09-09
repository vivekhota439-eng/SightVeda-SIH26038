function qwk = compute_qwk(yTrue, yPred, numClasses)
% COMPUTE_QWK Computes the Quadratic Weighted Kappa (QWK) metric between
% ground truth Diabetic Retinopathy severity grades and model predictions.
%
% Syntax:
%   qwk = compute_qwk(yTrue, yPred, numClasses)
%
% Inputs:
%   yTrue      - Vector or categorical array of ground truth labels (0 to 4)
%   yPred      - Vector or categorical array of predicted labels (0 to 4)
%   numClasses - Total number of classes (default: 5)
%
% Output:
%   qwk        - Scalar Quadratic Weighted Kappa score in [-1.0, 1.0]

    if nargin < 3 || isempty(numClasses)
        numClasses = 5;
    end

    % Convert categorical to 0-indexed numeric
    if iscategorical(yTrue)
        yTrue = double(yTrue) - 1;
    else
        yTrue = double(yTrue(:));
    end

    if iscategorical(yPred)
        yPred = double(yPred) - 1;
    else
        yPred = double(yPred(:));
    end

    n = length(yTrue);
    if n == 0
        qwk = 0.0;
        return;
    end

    % 1. Observed Confusion Matrix O (numClasses x numClasses)
    O = zeros(numClasses, numClasses);
    for k = 1:n
        r = yTrue(k) + 1;
        c = yPred(k) + 1;
        if r >= 1 && r <= numClasses && c >= 1 && c <= numClasses
            O(r, c) = O(r, c) + 1;
        end
    end

    % 2. Expected Matrix E based on marginal distributions
    rowSums = sum(O, 2);
    colSums = sum(O, 1);
    total = sum(O(:));
    if total == 0
        qwk = 0.0;
        return;
    end

    E = (rowSums * colSums) / total;

    % 3. Quadratic Weight Matrix W
    W = zeros(numClasses, numClasses);
    denom = (numClasses - 1)^2;
    for i = 1:numClasses
        for j = 1:numClasses
            W(i, j) = ((i - j)^2) / denom;
        end
    end

    % 4. Quadratic Weighted Kappa Calculation
    num = sum(sum(W .* O));
    den = sum(sum(W .* E));

    if den == 0
        qwk = 1.0;
    else
        qwk = 1.0 - (num / den);
    end
end
