function [net, trainInfo] = train_model(datasetDir, outputModelPath, epochs, batchSize, lr, backbone, useGpu)
% TRAIN_MODEL Trains the 5-class Diabetic Retinopathy CNN classifier in MATLAB.
% Includes:
% 1. GPU acceleration with NVIDIA RTX 3050 6GB optimization & automatic CPU fallback.
% 2. Mathematical handling of class imbalance using weighted cross-entropy loss.
% 3. Tracking of validation accuracy and Quadratic Weighted Kappa (QWK).
% 4. Checkpoint saving to models/model_weights.mat.
%
% Syntax:
%   [net, trainInfo] = train_model(datasetDir, outputModelPath, epochs, batchSize, lr, backbone, useGpu)

    cfg = config_params();

    if nargin < 1 || isempty(datasetDir)
        datasetDir = cfg.DATASET_DIR;
    end
    if nargin < 2 || isempty(outputModelPath)
        outputModelPath = cfg.MODEL_WEIGHTS_PATH;
    end
    if nargin < 3 || isempty(epochs)
        epochs = cfg.DEFAULT_EPOCHS;
    end
    if nargin < 4 || isempty(batchSize)
        batchSize = cfg.DEFAULT_BATCH_SIZE;
    end
    if nargin < 5 || isempty(lr)
        lr = cfg.DEFAULT_LEARNING_RATE;
    end
    if nargin < 6 || isempty(backbone)
        backbone = cfg.DEFAULT_BACKBONE;
    end
    if nargin < 7 || isempty(useGpu)
        useGpu = cfg.PREFER_GPU;
    end

    fprintf('======================================================================\n');
    fprintf('DIABETIC RETINOPATHY SEVERITY GRADING — MATLAB TRAINING ENGINE\n');
    fprintf('======================================================================\n');
    fprintf('Dataset Directory : %s\n', datasetDir);
    fprintf('Target Model Path : %s\n', outputModelPath);
    fprintf('Backbone          : %s\n', backbone);
    fprintf('Epochs            : %d\n', epochs);
    fprintf('Batch Size        : %d (configured for 6GB GPU)\n', batchSize);
    fprintf('Learning Rate     : %.4e\n', lr);

    % -------------------------------------------------------------------------
    % 1. Hardware Detection & Execution Environment (RTX 3050 6GB Support)
    % -------------------------------------------------------------------------
    execEnv = 'cpu';
    if useGpu
        try
            if gpuDeviceCount > 0
                g = gpuDevice();
                execEnv = 'gpu';
                fprintf('[Hardware] GPU Detected: %s (Total Memory: %.2f GB)\n', ...
                    g.Name, g.TotalMemory / (1024^3));
                fprintf('[Hardware] ExecutionEnvironment set to ''gpu''.\n');
            else
                fprintf('[Hardware] No compatible GPU detected. Falling back to CPU.\n');
            end
        catch ME
            fprintf('[Hardware] GPU query error (%s). Falling back to CPU.\n', ME.message);
            execEnv = 'cpu';
        end
    else
        fprintf('[Hardware] ExecutionEnvironment set to ''cpu'' by configuration.\n');
    end
    fprintf('----------------------------------------------------------------------\n');

    % -------------------------------------------------------------------------
    % 2. Dataset Loading & Class Imbalance Weights
    % -------------------------------------------------------------------------
    fprintf('Loading retinal dataset and configuring stratified splits...\n');
    [trainDS, valDS, classWeights, metadata] = load_retinal_dataset(datasetDir, cfg.VAL_SPLIT_RATIO, cfg.IMAGE_SIZE);

    fprintf('Dataset Split     : %d Training Images | %d Validation Images\n', ...
        metadata.trainCount, metadata.valCount);
    fprintf('Train Distribution: [0: %d, 1: %d, 2: %d, 3: %d, 4: %d]\n', ...
        metadata.trainDistribution(1), metadata.trainDistribution(2), ...
        metadata.trainDistribution(3), metadata.trainDistribution(4), ...
        metadata.trainDistribution(5));
    fprintf('Class Weights     : [%.3f, %.3f, %.3f, %.3f, %.3f] (Active in Loss)\n', classWeights);
    fprintf('----------------------------------------------------------------------\n');

    % -------------------------------------------------------------------------
    % 3. Model Architecture Construction with Weighted Loss Layer
    % -------------------------------------------------------------------------
    fprintf('Building CNN Architecture (%s) with weighted classification layer...\n', backbone);
    lgraph = build_network(backbone, cfg.NUM_CLASSES, classWeights);

    % -------------------------------------------------------------------------
    % 4. Training Options Configuration
    % -------------------------------------------------------------------------
    valFreq = max(1, floor(metadata.trainCount / batchSize));
    effectiveBatchSize = min(batchSize, metadata.trainCount);

    options = trainingOptions('adam', ...
        'InitialLearnRate', lr, ...
        'MaxEpochs', epochs, ...
        'MiniBatchSize', effectiveBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', valDS, ...
        'ValidationFrequency', valFreq, ...
        'ExecutionEnvironment', execEnv, ...
        'Verbose', true, ...
        'Plots', 'none');

    % -------------------------------------------------------------------------
    % 5. Execute Training Loop
    % -------------------------------------------------------------------------
    fprintf('Starting model training...\n');
    t0 = tic;
    [net, info] = trainNetwork(trainDS, lgraph, options);
    elapsedTime = toc(t0);

    % -------------------------------------------------------------------------
    % 6. Model Evaluation (Validation Accuracy & QWK)
    % -------------------------------------------------------------------------
    fprintf('\nEvaluating trained model on validation partition...\n');
    [valPreds, valScores] = classify(net, valDS);

    valTrue = valDS.UnderlyingDatastores{1}.Labels;
    valAccuracy = mean(valPreds == valTrue);
    valQWK = compute_qwk(valTrue, valPreds, cfg.NUM_CLASSES);

    fprintf('======================================================================\n');
    fprintf('Training Completed Successfully in %.1f seconds.\n', elapsedTime);
    fprintf('Final Validation Accuracy : %.2f%%\n', valAccuracy * 100);
    fprintf('Final Validation QWK      : %.4f\n', valQWK);

    % -------------------------------------------------------------------------
    % 7. Save Model Weights Checkpoint
    % -------------------------------------------------------------------------
    outputDir = fileparts(outputModelPath);
    if ~isempty(outputDir) && ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    save(outputModelPath, 'net', 'valAccuracy', 'valQWK', 'metadata', 'backbone', 'cfg', 'classWeights');
    fprintf('Trained Model Saved To    : %s\n', outputModelPath);
    fprintf('======================================================================\n');

    trainInfo = struct();
    trainInfo.valAccuracy = valAccuracy;
    trainInfo.valQWK = valQWK;
    trainInfo.elapsedTime = elapsedTime;
    trainInfo.trainingHistory = info;
    trainInfo.modelPath = outputModelPath;
    trainInfo.execEnv = execEnv;
end
