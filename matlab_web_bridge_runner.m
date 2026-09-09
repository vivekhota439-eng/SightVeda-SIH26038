function matlab_web_bridge_runner(requestJsonPath, outputJsonPath)
% MATLAB_WEB_BRIDGE_RUNNER
% Adapter used by the SIH26038 Flask website to execute the CLEAN
% RETINAL_AI_PROJECT MATLAB pipeline and return a JSON-safe result.

    try
        thisFile = mfilename('fullpath');
        projectRoot = fileparts(thisFile);
        addpath(fullfile(projectRoot, 'config'));
        addpath(fullfile(projectRoot, 'part1_preprocessing'));
        addpath(fullfile(projectRoot, 'part2_model'));
        addpath(fullfile(projectRoot, 'part3_report'));
        addpath(fullfile(projectRoot, 'simulation'));
        addpath(fullfile(projectRoot, 'app'));

        raw = fileread(requestJsonPath);
        req = jsondecode(raw);

        imagePath = char(req.image_path);
        language = 'hi';
        if isfield(req, 'language') && ~isempty(req.language)
            language = char(req.language);
        end

        p = struct();
        if isfield(req, 'patient_info') && ~isempty(req.patient_info)
            src = req.patient_info;
            p.id = get_field(src, 'patient_id', 'PAT-WEB-001');
            p.age = get_numeric_field(src, 'age', 54);
            p.gender = get_field(src, 'gender', 'Male');
            p.date = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            if isfield(src, 'name'), p.name = get_field(src, 'name', 'Anonymous Patient'); end
            if isfield(src, 'laterality'), p.laterality = get_field(src, 'laterality', 'OD (Right Eye)'); end
            if isfield(src, 'hba1c'), p.hba1c = get_field(src, 'hba1c', '8.4%'); end
            if isfield(src, 'bp'), p.bp = get_field(src, 'bp', '140/90 mmHg'); end
            if isfield(src, 'dm_duration'), p.dm_duration = get_field(src, 'dm_duration', 'Type 2 DM'); end
            if isfield(src, 'visual_acuity'), p.visual_acuity = get_field(src, 'visual_acuity', 'OD: 6/9, OS: 6/12'); end
        else
            p.id = 'PAT-WEB-001';
            p.age = 54;
            p.gender = 'Male';
            p.date = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        end

        result = main_pipeline(imagePath, language, p);
        result.bridge_status = 'success';
        result.bridge_backend = 'RETINAL_AI_PROJECT/main_pipeline.m';
        result.bridge_project_root = projectRoot;

        fid = fopen(outputJsonPath, 'w');
        if fid < 0, error('Could not open output JSON file: %s', outputJsonPath); end
        cleaner = onCleanup(@() fclose(fid));
        fprintf(fid, '%s', jsonencode(result));

    catch ME
        err = struct();
        err.bridge_status = 'error';
        err.error_identifier = ME.identifier;
        err.error_message = ME.message;
        err.stack = ME.stack;
        try
            fid = fopen(outputJsonPath, 'w');
            if fid >= 0
                fprintf(fid, '%s', jsonencode(err));
                fclose(fid);
            end
        catch
        end
        rethrow(ME);
    end
end

function value = get_field(s, name, defaultValue)
    if isfield(s, name) && ~isempty(s.(name))
        value = char(string(s.(name)));
    else
        value = defaultValue;
    end
end

function value = get_numeric_field(s, name, defaultValue)
    if isfield(s, name) && ~isempty(s.(name))
        value = double(s.(name));
    else
        value = defaultValue;
    end
end
