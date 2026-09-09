function cfg = config_params()
% CONFIG_PARAMS Centralized configuration parameters for Diabetic Retinopathy AI System.
% Dynamically establishes project-relative paths, hyperparameters, quality
% thresholds, and hardware execution preferences.

    cfg = struct();

    % -------------------------------------------------------------------------
    % 1. Dynamic Root Directory Resolution (Never hardcoded)
    % -------------------------------------------------------------------------
    configDir = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(configDir);
    cfg.PROJECT_ROOT = projectRoot;

    % Directory Paths
    cfg.CONFIG_DIR        = fullfile(projectRoot, 'config');
    cfg.PREPROCESSING_DIR = fullfile(projectRoot, 'part1_preprocessing');
    cfg.MODEL_DIR         = fullfile(projectRoot, 'part2_model');
    cfg.REPORT_DIR        = fullfile(projectRoot, 'part3_report');
    cfg.SIMULATION_DIR    = fullfile(projectRoot, 'simulation');
    cfg.APP_DIR           = fullfile(projectRoot, 'app');

    cfg.DATASET_DIR       = fullfile(projectRoot, 'dataset');
    cfg.DATASET_IMAGES    = fullfile(projectRoot, 'dataset', 'images');
    cfg.DATASET_LABELS    = fullfile(projectRoot, 'dataset', 'labels.csv');

    cfg.MODELS_DIR        = fullfile(projectRoot, 'models');
    cfg.MODEL_WEIGHTS_PATH= fullfile(projectRoot, 'models', 'model_weights.mat');

    cfg.INPUT_DIR         = fullfile(projectRoot, 'input');
    cfg.OUTPUT_DIR        = fullfile(projectRoot, 'output');
    cfg.OUTPUT_ENHANCED   = fullfile(projectRoot, 'output', 'enhanced');
    cfg.OUTPUT_EVIDENCE   = fullfile(projectRoot, 'output', 'evidence');
    cfg.OUTPUT_EXPLAIN    = fullfile(projectRoot, 'output', 'explainability');
    cfg.OUTPUT_REPORTS    = fullfile(projectRoot, 'output', 'reports');

    % Auto-create essential folders if missing
    essentialDirs = {cfg.DATASET_DIR, cfg.MODELS_DIR, cfg.INPUT_DIR, ...
                     cfg.OUTPUT_DIR, cfg.OUTPUT_ENHANCED, cfg.OUTPUT_EVIDENCE, ...
                     cfg.OUTPUT_EXPLAIN, cfg.OUTPUT_REPORTS};
    for d = 1:length(essentialDirs)
        if ~exist(essentialDirs{d}, 'dir')
            mkdir(essentialDirs{d});
        end
    end

    % -------------------------------------------------------------------------
    % 2. Retinal Quality Screening Thresholds
    % -------------------------------------------------------------------------
    cfg.QUALITY = struct();
    cfg.QUALITY.BLUR_HARD_FAIL       = 8.0;     % Hard failure Laplacian variance
    cfg.QUALITY.FOCUS_MIN_ACCEPTABLE = 12.0;    % Minimum acceptable focus variance
    cfg.QUALITY.FOCUS_OPTIMAL        = 180.0;   % Baseline variance for crystal sharp retina
    cfg.QUALITY.MIN_BRIGHTNESS       = 35.0;    % Minimum mean retinal intensity
    cfg.QUALITY.MAX_BRIGHTNESS       = 195.0;   % Maximum mean retinal intensity
    cfg.QUALITY.MAX_LIGHTING_STD     = 42.0;    % Max inter-quadrant illumination std dev
    cfg.QUALITY.MIN_FOV_COVERAGE     = 0.18;    % Minimum retinal frame area coverage
    cfg.QUALITY.MIN_CIRCULARITY      = 0.30;    % Minimum circularity index
    cfg.QUALITY.BORDERLINE_THRESHOLD = 0.30;    % Scores in [0.30, 0.49] trigger adaptive enhancement
    cfg.QUALITY.OPTIMAL_THRESHOLD    = 0.50;    % Scores >= 0.50 are optimal diagnostic grade

    % -------------------------------------------------------------------------
    % 3. Deep Learning Model & Network Parameters
    % -------------------------------------------------------------------------
    cfg.IMAGE_SIZE = [224, 224]; % [height, width]
    cfg.NUM_CLASSES = 5;

    % ICDR 5-class severity labels mapping (0 to 4)
    cfg.GRADE_LABELS = containers.Map(...
        {0, 1, 2, 3, 4}, ...
        {'No DR (Normal)', ...
         'Mild Non-Proliferative DR', ...
         'Moderate Non-Proliferative DR', ...
         'Severe Non-Proliferative DR', ...
         'Proliferative Diabetic Retinopathy (PDR)'} ...
    );

    % ImageNet channel normalization constants
    cfg.IMAGE_NET_MEAN = [0.485, 0.456, 0.406];
    cfg.IMAGE_NET_STD  = [0.229, 0.224, 0.225];

    % Training defaults
    cfg.DEFAULT_BACKBONE       = 'efficientnet_b0'; % 'efficientnet_b0', 'resnet50', 'custom_cnn'
    cfg.DEFAULT_BATCH_SIZE     = 16;                % Safe default for 6GB RTX 3050 Laptop GPU
    cfg.DEFAULT_LEARNING_RATE  = 3e-4;
    cfg.DEFAULT_EPOCHS         = 15;
    cfg.VAL_SPLIT_RATIO        = 0.20;
    cfg.RANDOM_SEED            = 42;
    cfg.PREFER_GPU             = true;

    % -------------------------------------------------------------------------
    % 4. Clinical Calibration & Triage Parameters
    % -------------------------------------------------------------------------
    cfg.CONFIDENCE_THRESHOLD   = 0.70;  % Threshold for confident vs uncertain
    cfg.TEMPERATURE_SCALING    = 1.25;  % Softmax calibration temperature T
    cfg.MARGIN_DELTA_THRESHOLD = 12.0;  % Margin between Top-1 and Top-2 probabilities (%)
    cfg.DEFAULT_LANGUAGE       = 'en';  % Default report language ('en', 'hi', 'ta', 'te', 'mr', 'bn', 'tcy')
end
