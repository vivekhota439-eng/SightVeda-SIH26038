function [net, trainInfo] = train_retinal_model(datasetDir, epochs, batchSize, lr, backbone, useGpu)
% TRAIN_RETINAL_MODEL Standalone One-Click Training Entry Point for Retinal AI System.
%
% Complete Training Workflow:
% 1. Dataset loading from dataset/ (images/ and labels.csv).
% 2. Stratified 80/20 train/validation split.
% 3. Class balancing via mathematical inverse-frequency class weights:
%    w_c = N_total / (C * N_c)
% 4. Data augmentation (random rotations [-180, 180], horizontal/vertical reflections).
% 5. CNN architecture (EfficientNet-B0 default, ResNet-50, or Deep Residual CNN).
% 6. Custom weighted cross-entropy loss layer (weightedClassificationLayer).
% 7. GPU Acceleration for NVIDIA RTX 3050 6GB Laptop GPU ('ExecutionEnvironment', 'gpu').
% 8. MiniBatchSize = 16 (default, safe for 6GB VRAM) with automatic CPU fallback.
% 9. Tracking of validation accuracy and Quadratic Weighted Kappa (QWK).
% 10. Automatic checkpoint saving to models/model_weights.mat.
%
% Syntax:
%   train_retinal_model()
%   train_retinal_model(datasetDir, epochs, batchSize, lr, backbone, useGpu)

    % Add project paths
    scriptDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(scriptDir, 'config'));
    addpath(fullfile(scriptDir, 'part1_preprocessing'));
    addpath(fullfile(scriptDir, 'part2_model'));
    addpath(fullfile(scriptDir, 'part3_report'));
    addpath(fullfile(scriptDir, 'simulation'));

    cfg = config_params();

    if nargin < 1 || isempty(datasetDir)
        datasetDir = cfg.DATASET_DIR;
    end
    if nargin < 2 || isempty(epochs)
        epochs = cfg.DEFAULT_EPOCHS;
    end
    if nargin < 3 || isempty(batchSize)
        batchSize = cfg.DEFAULT_BATCH_SIZE;
    end
    if nargin < 4 || isempty(lr)
        lr = cfg.DEFAULT_LEARNING_RATE;
    end
    if nargin < 5 || isempty(backbone)
        backbone = cfg.DEFAULT_BACKBONE;
    end
    if nargin < 6 || isempty(useGpu)
        useGpu = cfg.PREFER_GPU;
    end

    % Verify dataset directory exists
    labelsPath = fullfile(datasetDir, 'labels.csv');
    imagesPath = fullfile(datasetDir, 'images');

    if ~exist(datasetDir, 'dir') || ~exist(labelsPath, 'file') || ~exist(imagesPath, 'dir')
        fprintf('======================================================================\n');
        fprintf('[Notice] No dataset found at: %s\n', datasetDir);
        fprintf('Expected structure:\n');
        fprintf('  dataset/\n');
        fprintf('  ├── images/\n');
        fprintf('  └── labels.csv\n\n');
        fprintf('Would you like to generate a synthetic 5-class mock dataset for testing?\n');
        fprintf('Generating synthetic mock dataset...\n');
        create_mock_dataset(datasetDir, 6);
        fprintf('Synthetic dataset generated successfully. Proceeding with training...\n');
        fprintf('======================================================================\n\n');
    end

    targetModelPath = cfg.MODEL_WEIGHTS_PATH;

    % Call core training engine
    [net, trainInfo] = train_model(datasetDir, targetModelPath, epochs, batchSize, lr, backbone, useGpu);

    fprintf('\nModel training workflow completed.\n');
    fprintf('The trained model checkpoint is stored at:\n  %s\n', targetModelPath);
    fprintf('You can now run inference using: main_pipeline\n\n');
end
