function varargout = run_pipeline(rawImagePath, language, patientInfo)
% RUN_PIPELINE Standardized Execution Wrapper for Diabetic Retinopathy AI System.
% Directly invokes the master main_pipeline.
%
% Syntax:
%   run_pipeline
%   report = run_pipeline('input/test_image.png')
%   report = run_pipeline('input/test_image.png', 'hi')

    if nargin < 1
        rawImagePath = [];
    end
    if nargin < 2
        language = [];
    end
    if nargin < 3
        patientInfo = [];
    end

    if nargout > 0
        varargout{1} = main_pipeline(rawImagePath, language, patientInfo);
    else
        main_pipeline(rawImagePath, language, patientInfo);
    end
end
