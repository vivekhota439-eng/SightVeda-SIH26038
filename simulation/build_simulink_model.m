function build_simulink_model()
% BUILD_SIMULINK_MODEL Programmatically builds the SIH26038 Telemedicine
% Discrete-Event Model (.slx) in Simulink / SimEvents.

    model_name = 'telemed_district_model';

    hasSimulink = false;
    try
        if exist('simulink', 'file') || exist('new_system', 'file')
            hasSimulink = true;
        end
    catch
        hasSimulink = false;
    end

    if ~hasSimulink
        fprintf('Simulink license/toolbox not active. Numerical discrete-event simulation available via district_simulation.m\n');
        return;
    end

    try
        if bdIsLoaded(model_name)
            close_system(model_name, 0);
        end
        new_system(model_name);
        open_system(model_name);

        fprintf('Building Simulink Telemedicine Model: %s.slx...\n', model_name);

        set_param(model_name, 'Solver', 'VariableStepDiscrete');
        set_param(model_name, 'StopTime', '360');

        % Subsystem 1: Patient Acquisition (PHC Network)
        add_block('simulink/Ports & Subsystems/Subsystem', [model_name, '/PHC_Patient_Acquisition'], ...
                  'Position', [50, 100, 200, 180]);

        % Subsystem 2: Rural Bandwidth Throttling Channel
        add_block('simulink/Ports & Subsystems/Subsystem', [model_name, '/Rural_Bandwidth_Channel'], ...
                  'Position', [260, 100, 420, 180]);

        % Subsystem 3: Cloud AI Grading Engine
        add_block('simulink/Ports & Subsystems/Subsystem', [model_name, '/Cloud_AI_Inference_Engine'], ...
                  'Position', [480, 100, 640, 180]);

        % Subsystem 4: Triage & Routing Matrix
        add_block('simulink/Ports & Subsystems/Subsystem', [model_name, '/Clinical_Triage_Router'], ...
                  'Position', [700, 100, 860, 180]);

        % Subsystem 5: Ophthalmologist Review Desk (< 30s review)
        add_block('simulink/Ports & Subsystems/Subsystem', [model_name, '/Doctor_Validation_Desk'], ...
                  'Position', [920, 100, 1080, 180]);

        % Connect Subsystems sequentially
        add_line(model_name, 'PHC_Patient_Acquisition/1', 'Rural_Bandwidth_Channel/1');
        add_line(model_name, 'Rural_Bandwidth_Channel/1', 'Cloud_AI_Inference_Engine/1');
        add_line(model_name, 'Cloud_AI_Inference_Engine/1', 'Clinical_Triage_Router/1');
        add_line(model_name, 'Clinical_Triage_Router/1', 'Doctor_Validation_Desk/1');

        % Save Simulink model
        save_system(model_name, [model_name, '.slx']);
        fprintf('Simulink Model saved successfully as %s.slx!\n', model_name);
    catch ME
        fprintf('Notice: %s\n', ME.message);
    end
end
