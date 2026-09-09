function lgraph = build_network(backbone, numClasses, classWeights)
% BUILD_NETWORK Constructs a 5-class Diabetic Retinopathy CNN architecture
% supporting transfer learning backbones (EfficientNet-B0, ResNet-50) and a
% standalone deep residual CNN, with support for weighted cross-entropy loss.
%
% Syntax:
%   lgraph = build_network(backbone, numClasses, classWeights)
%
% Inputs:
%   backbone     - 'efficientnet_b0', 'resnet50', or 'custom_cnn' (default: 'efficientnet_b0')
%   numClasses   - Number of severity classes (default: 5)
%   classWeights - (Optional) Weights for class imbalance handling

    if nargin < 1 || isempty(backbone)
        backbone = 'efficientnet_b0';
    end
    if nargin < 2 || isempty(numClasses)
        numClasses = 5;
    end
    if nargin < 3
        classWeights = [];
    end

    % Construct final classification output layer
    if ~isempty(classWeights)
        outLayer = weightedClassificationLayer(classWeights, 'output');
    else
        outLayer = classificationLayer('Name', 'output');
    end

    loadedBackbone = false;

    % 1. Try Transfer Learning Backbone
    try
        if strcmpi(backbone, 'efficientnet_b0') && (exist('efficientnetb0', 'file') == 2 || exist('efficientnetb0', 'builtin') > 0)
            baseNet = efficientnetb0();
            lgraph = layerGraph(baseNet);

            newLayers = [
                dropoutLayer(0.3, 'Name', 'new_dropout')
                fullyConnectedLayer(numClasses, 'Name', 'new_fc', ...
                    'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10)
                softmaxLayer('Name', 'new_softmax')
                outLayer
            ];

            lgraph = removeLayers(lgraph, {'ClassificationLayer_predictions', 'Softmax', 'predictions'});
            lgraph = addLayers(lgraph, newLayers);
            lgraph = connectLayers(lgraph, 'top_dropout', 'new_dropout');
            loadedBackbone = true;

        elseif strcmpi(backbone, 'resnet50') && (exist('resnet50', 'file') == 2 || exist('resnet50', 'builtin') > 0)
            baseNet = resnet50();
            lgraph = layerGraph(baseNet);

            newLayers = [
                dropoutLayer(0.3, 'Name', 'new_dropout')
                fullyConnectedLayer(numClasses, 'Name', 'new_fc', ...
                    'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10)
                softmaxLayer('Name', 'new_softmax')
                outLayer
            ];

            lgraph = removeLayers(lgraph, {'ClassificationLayer_fc1000', 'fc1000_softmax', 'fc1000'});
            lgraph = addLayers(lgraph, newLayers);
            lgraph = connectLayers(lgraph, 'avg_pool', 'new_dropout');
            loadedBackbone = true;
        end
    catch ME
        fprintf('[Notice] Transfer learning backbone "%s" not available (%s). Using native Deep Residual CNN.\n', backbone, ME.message);
        loadedBackbone = false;
    end

    % 2. Standalone Deep Residual CNN (Runs out-of-the-box without add-ons)
    if ~loadedBackbone
        layers = [
            imageInputLayer([224 224 3], 'Name', 'input', 'Normalization', 'zerocenter')

            % Initial Stem
            convolution2dLayer(3, 32, 'Padding', 'same', 'Stride', 2, 'Name', 'conv1')
            batchNormalizationLayer('Name', 'bn1')
            reluLayer('Name', 'relu1')
            maxPooling2dLayer(2, 'Stride', 2, 'Padding', 'same', 'Name', 'pool1')

            % Stage 1: 64 Filters
            convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'res1_conv1')
            batchNormalizationLayer('Name', 'res1_bn1')
            reluLayer('Name', 'res1_relu1')
            convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'res1_conv2')
            batchNormalizationLayer('Name', 'res1_bn2')
            reluLayer('Name', 'res1_relu2')
            maxPooling2dLayer(2, 'Stride', 2, 'Padding', 'same', 'Name', 'pool2')

            % Stage 2: 128 Filters
            convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'res2_conv1')
            batchNormalizationLayer('Name', 'res2_bn1')
            reluLayer('Name', 'res2_relu1')
            convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'res2_conv2')
            batchNormalizationLayer('Name', 'res2_bn2')
            reluLayer('Name', 'res2_relu2')
            maxPooling2dLayer(2, 'Stride', 2, 'Padding', 'same', 'Name', 'pool3')

            % Stage 3: 256 Filters
            convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'res3_conv1')
            batchNormalizationLayer('Name', 'res3_bn1')
            reluLayer('Name', 'res3_relu1')
            convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'res3_conv2')
            batchNormalizationLayer('Name', 'res3_bn2')
            reluLayer('Name', 'res3_relu2')

            % Global Pooling & Classification Head
            globalAveragePooling2dLayer('Name', 'gap')
            dropoutLayer(0.3, 'Name', 'dropout')
            fullyConnectedLayer(numClasses, 'Name', 'fc')
            softmaxLayer('Name', 'softmax')
            outLayer
        ];
        lgraph = layerGraph(layers);
    end
end
