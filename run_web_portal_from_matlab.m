function run_web_portal_from_matlab()
% RUN_WEB_PORTAL_FROM_MATLAB
% Launch the SIH26038 website whose diagnostic backend is this CLEAN
% RETINAL_AI_PROJECT MATLAB pipeline.
    projectRoot = fileparts(mfilename('fullpath'));
    fprintf('\nStarting SIH26038 Web Portal...\n');
    fprintf('Backend: %s\n', fullfile(projectRoot, 'main_pipeline.m'));
    fprintf('Browser: http://127.0.0.1:5000\n\n');
    if ispc
        cmd = sprintf('start "" cmd /c "cd /d "%s" && python app.py"', projectRoot);
        system(cmd);
    else
        system(sprintf('cd "%s" && python3 app.py &', projectRoot));
    end
end
