function [trainDS, valDS, classWeights, metadata] = load_retinal_dataset(datasetDir, valSplit, inputSize)
% LOAD_RETINAL_DATASET Loads retinal fundus images and labels, performs
% stratified train/validation split, computes inverse class frequency weights,
% and returns augmented image datastores for deep learning training.
%
% Syntax:
%   [trainDS, valDS, classWeights, metadata] = load_retinal_dataset(datasetDir, valSplit, inputSize)
%
% Outputs:
%   trainDS      - augmentedImageDatastore for training
%   valDS        - augmentedImageDatastore for validation
%   classWeights - Vector of computed weights to counteract class imbalance
%   metadata     - Struct containing dataset split statistics

    cfg = config_params();

    if nargin < 1 || isempty(datasetDir)
        datasetDir = cfg.DATASET_DIR;
    end
    if nargin < 2 || isempty(valSplit)
        valSplit = cfg.VAL_SPLIT_RATIO;
    end
    if nargin < 3 || isempty(inputSize)
        inputSize = cfg.IMAGE_SIZE;
    end

    if ~exist(datasetDir, 'dir')
        error("Dataset directory not found: '%s'. Expected directory containing 'images/' subfolder and 'labels.csv'.", datasetDir);
    end

    imagesDir = fullfile(datasetDir, 'images');
    if ~exist(imagesDir, 'dir')
        error("Missing 'images' subfolder in '%s'.", datasetDir);
    end

    % Locate CSV file
    csvCandidates = {
        fullfile(datasetDir, 'labels.csv'), ...
        fullfile(datasetDir, 'train.csv'), ...
        fullfile(datasetDir, 'dataset.csv')
    };
    csvPath = '';
    for i = 1:length(csvCandidates)
        if exist(csvCandidates{i}, 'file')
            csvPath = csvCandidates{i};
            break;
        end
    end

    if isempty(csvPath)
        csvFiles = dir(fullfile(datasetDir, '*.csv'));
        if ~isempty(csvFiles)
            csvPath = fullfile(datasetDir, csvFiles(1).name);
        else
            error("No CSV labels file found in '%s'. Expected 'labels.csv'.", datasetDir);
        end
    end

    T = readtable(csvPath, 'PreserveVariableNames', true);
    colNames = lower(T.Properties.VariableNames);

    % Find Image ID column
    idCandidates = {'image_id', 'id_code', 'image', 'filename', 'img_id', 'name', 'id'};
    idColIdx = find(ismember(colNames, idCandidates), 1);
    if isempty(idColIdx)
        error("Could not find image ID column in '%s'. Available columns: %s", csvPath, strjoin(colNames, ', '));
    end

    % Find Diagnosis column
    diagCandidates = {'diagnosis', 'grade', 'level', 'dr_level', 'target', 'label', 'class'};
    diagColIdx = find(ismember(colNames, diagCandidates), 1);
    if isempty(diagColIdx)
        error("Could not find diagnosis column in '%s'. Available columns: %s", csvPath, strjoin(colNames, ', '));
    end

    rawIds = T.(idColIdx);
    rawDiags = T.(diagColIdx);

    % Match image paths on disk
    n = height(T);
    filePaths = cell(n, 1);
    validMask = true(n, 1);
    extensions = {'.png', '.jpg', '.jpeg', '.bmp', '.tif'};

    for i = 1:n
        idStr = char(string(rawIds(i)));
        [~, ~, ext] = fileparts(idStr);
        found = false;

        if ~isempty(ext)
            p = fullfile(imagesDir, idStr);
            if exist(p, 'file')
                filePaths{i} = p;
                found = true;
            end
        else
            for e = 1:length(extensions)
                p = fullfile(imagesDir, [idStr, extensions{e}]);
                if exist(p, 'file')
                    filePaths{i} = p;
                    found = true;
                    break;
                end
            end
        end

        if ~found
            validMask(i) = false;
        end
    end

    if any(~validMask)
        missingCount = sum(~validMask);
        fprintf('[Warning] %d images listed in CSV were not found in %s/\n', missingCount, imagesDir);
        filePaths = filePaths(validMask);
        rawDiags = rawDiags(validMask);
    end

    if isempty(filePaths)
        error("Zero valid images found matching labels in '%s'. Please check file paths and extensions.", imagesDir);
    end

    % Standardize labels to categorical '0', '1', '2', '3', '4'
    labels = categorical(rawDiags, 0:4, {'0', '1', '2', '3', '4'});

    % Stratified Train/Validation split
    rng(cfg.RANDOM_SEED);
    try
        cv = cvpartition(labels, 'HoldOut', valSplit);
        trainIdx = cv.training;
        valIdx = cv.test;
    catch
        numTotal = length(labels);
        perm = randperm(numTotal);
        numVal = max(1, round(numTotal * valSplit));
        valIdx = false(numTotal, 1);
        valIdx(perm(1:numVal)) = true;
        trainIdx = ~valIdx;
    end

    trainFiles = filePaths(trainIdx);
    trainLabels = labels(trainIdx);
    valFiles = filePaths(valIdx);
    valLabels = labels(valIdx);

    % Compute inverse-frequency class weights for class imbalance
    trainCounts = countcats(trainLabels);
    totalTrain = sum(trainCounts);
    numClasses = cfg.NUM_CLASSES;
    classWeights = zeros(numClasses, 1);

    for c = 1:numClasses
        if trainCounts(c) > 0
            classWeights(c) = totalTrain / (numClasses * trainCounts(c));
        else
            classWeights(c) = 1.0;
        end
    end
    % Normalize weights so mean weight is 1.0
    classWeights = classWeights / mean(classWeights);

    % Build ImageDatastores
    imdsTrain = imageDatastore(trainFiles, 'Labels', trainLabels);
    imdsVal   = imageDatastore(valFiles, 'Labels', valLabels);

    % Data Augmentation
    augmenter = imageDataAugmenter(...
        'RandRotation', [-180, 180], ...
        'RandXReflection', true, ...
        'RandYReflection', true, ...
        'RandXScale', [0.9, 1.1], ...
        'RandYScale', [0.9, 1.1] ...
    );

    trainDS = augmentedImageDatastore(inputSize, imdsTrain, 'DataAugmentation', augmenter);
    valDS   = augmentedImageDatastore(inputSize, imdsVal);

    metadata = struct();
    metadata.datasetDir = datasetDir;
    metadata.totalImages = length(filePaths);
    metadata.trainCount = length(trainFiles);
    metadata.valCount = length(valFiles);
    metadata.classWeights = classWeights;
    metadata.trainDistribution = trainCounts;
    metadata.valDistribution = countcats(valLabels);
end
