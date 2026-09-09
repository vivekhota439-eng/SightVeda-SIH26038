classdef weightedClassificationLayer < nnet.layer.ClassificationLayer
% WEIGHTEDCLASSIFICATIONLAYER Custom classification layer for handling class imbalance.
% Computes weighted cross-entropy loss using inverse-frequency class weights:
%   Loss = - 1/N * sum_i sum_c w_c * T_ic * log(Y_ic + eps)
%
% Fully compatible with MATLAB Deep Learning Toolbox, trainNetwork,
% GPU execution (RTX 3050 6GB), dlarray, and CPU fallback.

    properties
        ClassWeights
    end

    methods
        function layer = weightedClassificationLayer(classWeights, name)
            % Layer constructor
            if nargin < 1 || isempty(classWeights)
                classWeights = ones(5, 1);
            end
            if nargin < 2 || isempty(name)
                name = 'weighted_output';
            end

            layer.Name = name;
            layer.Description = 'Weighted Cross-Entropy Loss Layer for Class Imbalance';
            layer.ClassWeights = double(classWeights(:));
        end

        function loss = forwardLoss(layer, Y, T)
            % FORWARDLOSS Computes the weighted cross-entropy loss.
            % Y: Softmax predictions (numClasses x batchSize)
            % T: Ground truth categorical targets (numClasses x batchSize) or 1-hot matrix
            epsVal = 1e-7;
            Y = max(Y, epsVal);

            % Ensure weights are on the same execution environment (GPU/CPU) as Y
            W = layer.ClassWeights;
            if isa(Y, 'gpuArray') && ~isa(W, 'gpuArray')
                W = gpuArray(W);
            end

            % If T is 1-hot encoded:
            if size(T, 1) == size(Y, 1)
                weightedLogY = (W .* T) .* log(Y);
                loss = -sum(weightedLogY(:)) / size(Y, 2);
            else
                % Categorical vector fallback
                loss = -sum(W(T) .* log(Y(sub2ind(size(Y), double(T), 1:length(T))))) / length(T);
            end
        end

        function dLdY = backwardLoss(layer, Y, T)
            % BACKWARDLOSS Computes the derivative of loss with respect to predictions Y.
            epsVal = 1e-7;
            Y = max(Y, epsVal);
            batchSize = size(Y, 2);

            W = layer.ClassWeights;
            if isa(Y, 'gpuArray') && ~isa(W, 'gpuArray')
                W = gpuArray(W);
            end

            if size(T, 1) == size(Y, 1)
                dLdY = - (W .* T) ./ (Y * batchSize);
            else
                dLdY = zeros(size(Y), 'like', Y);
                for i = 1:batchSize
                    c = double(T(i));
                    dLdY(c, i) = - W(c) / (Y(c, i) * batchSize);
                end
            end
        end
    end
end
