function modelName = create_simulink_model()
% CREATE_SIMULINK_MODEL Programmatically generates a Simulink block diagram
% representing the End-to-End Retinal Fundus Screening Workflow:
% 1. Patient Acquisition Source Block
% 2. Telemedicine Bandwidth Transmission Delay Block
% 3. Automated AI Processing Queue Block (<1.5s)
% 4. Triage Branch: 78% Auto-Clearance vs 22% Specialist Queue
% 5. Doctor Review Station Block (<30s review)
% 6. Dashboard Scopes: Queue lengths, latency, and throughput.

    modelName = 'simulink_retinal_screening';

    fprintf('Checking Simulink environment...\n');
    hasSimulink = false;
    try
        if exist('simulink', 'file') || exist('new_system', 'file')
            hasSimulink = true;
        end
    catch
        hasSimulink = false;
    end

    if hasSimulink
        try
            if bdIsLoaded(modelName)
                close_system(modelName, 0);
            end

            new_system(modelName);
            open_system(modelName);

            set_param(modelName, 'StopTime', '25200');

            % 1. Patient Arrival Pulse Generator
            add_block('simulink/Sources/Pulse Generator', [modelName, '/Patient_Acquisition_PHC'], ...
                'Period', '150', 'PulseWidth', '50', 'Position', [50, 100, 100, 140]);

            % 2. Telemedicine Bandwidth Delay
            add_block('simulink/Continuous/Transport Delay', [modelName, '/Telemedicine_Bandwidth_Delay'], ...
                'DelayTime', '2.8', 'Position', [160, 100, 220, 140]);

            % 3. Automated AI Processing Delay
            add_block('simulink/Continuous/Transport Delay', [modelName, '/AI_Analysis_Pipeline_Delay'], ...
                'DelayTime', '1.1', 'Position', [280, 100, 350, 140]);

            % 4. AI Triage Splitter
            add_block('simulink/Math Operations/Gain', [modelName, '/Triage_Doctor_Queue_22Pct'], ...
                'Gain', '0.22', 'Position', [420, 70, 470, 110]);

            add_block('simulink/Math Operations/Gain', [modelName, '/Triage_Auto_Clearance_78Pct'], ...
                'Gain', '0.78', 'Position', [420, 150, 470, 190]);

            % 5. Doctor Review Station Delay
            add_block('simulink/Continuous/Transport Delay', [modelName, '/Doctor_Review_Station_Delay'], ...
                'DelayTime', '22.0', 'Position', [530, 70, 600, 110]);

            % 6. Scopes / Sinks
            add_block('simulink/Sinks/Scope', [modelName, '/Scope_Doctor_Queue'], ...
                'Position', [660, 70, 700, 110]);

            add_block('simulink/Sinks/Scope', [modelName, '/Scope_Auto_Cleared'], ...
                'Position', [660, 150, 700, 190]);

            % Connect signal lines
            add_line(modelName, 'Patient_Acquisition_PHC/1', 'Telemedicine_Bandwidth_Delay/1');
            add_line(modelName, 'Telemedicine_Bandwidth_Delay/1', 'AI_Analysis_Pipeline_Delay/1');
            add_line(modelName, 'AI_Analysis_Pipeline_Delay/1', 'Triage_Doctor_Queue_22Pct/1');
            add_line(modelName, 'AI_Analysis_Pipeline_Delay/1', 'Triage_Auto_Clearance_78Pct/1');
            add_line(modelName, 'Triage_Doctor_Queue_22Pct/1', 'Doctor_Review_Station_Delay/1');
            add_line(modelName, 'Doctor_Review_Station_Delay/1', 'Scope_Doctor_Queue/1');
            add_line(modelName, 'Triage_Auto_Clearance_78Pct/1', 'Scope_Auto_Cleared/1');

            save_system(modelName);
            fprintf('Successfully generated Simulink model: %s.slx\n', modelName);
        catch ME
            fprintf('Simulink block diagram generation note: %s\n', ME.message);
        end
    else
        fprintf('Simulink not available in current environment. Workflow modeling available via district_simulation.m\n');
    end
end
