function teleophthalmology_app(initialImagePath)
% TELEOPHTHALMOLOGY_APP Interactive MATLAB Clinical Examination Desktop Portal.
%
% Complete 4-Axes Graphical Interface for Retinal AI Screening (SIH26038).
% Features:
% - Interactive Image Browser & Preview
% - 4 Visualization Axes: Raw, CLAHE Enhanced, Grad-CAM Heatmap, Evidence Overlay
% - Biomarker Quantification & Quadrant Breakdown
% - Multilingual Clinical CDS Recommendations & Dietary Parhez
% - One-click buttons to run pipeline and 100k telemedicine simulation.

    cfg = config_params();

    if nargin < 1 || isempty(initialImagePath)
        initialImagePath = fullfile(cfg.INPUT_DIR, 'test_image.png');
        if ~exist(initialImagePath, 'file')
            % Check sample candidates
            candidates = {
                fullfile(cfg.PROJECT_ROOT, 'good_retina_image.png'), ...
                fullfile(cfg.PROJECT_ROOT, 'matlab', 'good_retina_image.png')
            };
            for c = 1:length(candidates)
                if exist(candidates{c}, 'file')
                    initialImagePath = candidates{c};
                    break;
                end
            end
        end
    end

    fig = figure('Name', 'PHC Tele-Ophthalmology AI Diagnostic Portal (SIH26038)', ...
                 'Color', [0.96, 0.98, 1.0], 'Position', [80, 60, 1260, 800], ...
                 'NumberTitle', 'off', 'MenuBar', 'none');

    % Header Title Banner
    uicontrol('Style', 'text', 'String', '  PHC TELE-OPHTHALMOLOGY AI CLINICAL CDS SUITE (SIH26038)', ...
              'Position', [20, 740, 1220, 42], 'FontSize', 15, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.05, 0.45, 0.75], 'ForegroundColor', [1, 1, 1], ...
              'HorizontalAlignment', 'left');

    % 4 Image Display Axes
    ax1 = axes('Units', 'pixels', 'Position', [40, 440, 275, 260]);
    title(ax1, '1. Raw Retinal Fundus', 'FontSize', 11, 'FontWeight', 'bold');
    axis(ax1, 'off');

    ax2 = axes('Units', 'pixels', 'Position', [345, 440, 275, 260]);
    title(ax2, '2. Task 1 CLAHE Enhanced', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.01, 0.52, 0.78]);
    axis(ax2, 'off');

    ax3 = axes('Units', 'pixels', 'Position', [650, 440, 275, 260]);
    title(ax3, '3. Grad-CAM Heatmap', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.85, 0.15, 0.15]);
    axis(ax3, 'off');

    ax4 = axes('Units', 'pixels', 'Position', [955, 440, 275, 260]);
    title(ax4, '4. Retinal Evidence Overlay', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.45, 0.20, 0.85]);
    axis(ax4, 'off');

    % Clinical Verdict Panel (Bottom Left)
    uicontrol('Style', 'text', 'String', '  CLINICAL DIAGNOSTIC RESULTS & BIOMARKERS', ...
              'Position', [40, 395, 580, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.15, 0.23, 0.35], 'ForegroundColor', [1, 1, 1], ...
              'HorizontalAlignment', 'left');

    lbl_result = uicontrol('Style', 'text', ...
                           'String', 'Ready for Screening. Select a retinal image and click "Run Complete Analysis".', ...
                           'Position', [40, 130, 580, 260], 'FontSize', 10, ...
                           'BackgroundColor', [1, 1, 1], 'HorizontalAlignment', 'left');

    % Clinical Precautions & Parhez Panel (Bottom Right)
    uicontrol('Style', 'text', 'String', '  GRADE-SPECIFIC ETIOLOGY & DIETARY PARHEZ', ...
              'Position', [650, 395, 580, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.15, 0.23, 0.35], 'ForegroundColor', [1, 1, 1], ...
              'HorizontalAlignment', 'left');

    lbl_parhez = uicontrol('Style', 'text', ...
                           'String', 'Clinical precautions, etiology root-cause, and dietary parhez instructions will display here.', ...
                           'Position', [650, 130, 580, 260], 'FontSize', 10, ...
                           'BackgroundColor', [1, 1, 1], 'HorizontalAlignment', 'left');

    % Controls Panel (Bottom Row)
    uicontrol('Style', 'pushbutton', 'String', '📂 Browse Retinal Image...', ...
              'Position', [40, 50, 200, 48], 'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.25, 0.35, 0.50], 'ForegroundColor', [1, 1, 1], ...
              'Callback', @browse_callback);

    uicontrol('Style', 'pushbutton', 'String', '⚡ Run Complete Analysis', ...
              'Position', [255, 50, 240, 48], 'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.08, 0.65, 0.25], 'ForegroundColor', [1, 1, 1], ...
              'Callback', @run_callback);

    uicontrol('Style', 'pushbutton', 'String', '📊 100k Patient Simulation', ...
              'Position', [510, 50, 220, 48], 'FontSize', 11, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.01, 0.52, 0.78], 'ForegroundColor', [1, 1, 1], ...
              'Callback', @(s, e) district_simulation(120000, 30, 2.0));

    uicontrol('Style', 'text', 'String', 'Report Language:', ...
              'Position', [750, 62, 120, 25], 'FontSize', 10, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.96, 0.98, 1.0], 'HorizontalAlignment', 'right');

    dropdown_lang = uicontrol('Style', 'popupmenu', ...
                              'String', {'English (en)', 'Hindi (hi)', 'Tamil (ta)', 'Telugu (te)', 'Marathi (mr)', 'Bengali (bn)', 'Tulu (tcy)'}, ...
                              'Position', [880, 65, 140, 25], 'FontSize', 10);

    selectedImagePath = initialImagePath;
    if exist(selectedImagePath, 'file')
        try
            axes(ax1); imshow(imread(selectedImagePath)); title(ax1, '1. Raw Retinal Fundus', 'FontWeight', 'bold');
        catch
        end
    end

    function browse_callback(~, ~)
        [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Retinal Images (*.png, *.jpg, *.jpeg, *.bmp, *.tif)'}, 'Select Retinal Fundus Image');
        if file ~= 0
            selectedImagePath = fullfile(path, file);
            axes(ax1); imshow(imread(selectedImagePath)); title(ax1, '1. Raw Retinal Fundus', 'FontWeight', 'bold');
            set(lbl_result, 'String', sprintf('Loaded Image: %s\nClick "Run Complete Analysis" to proceed.', selectedImagePath));
        end
    end

    function run_callback(~, ~)
        langList = {'en', 'hi', 'ta', 'te', 'mr', 'bn', 'tcy'};
        langIdx = get(dropdown_lang, 'Value');
        chosenLang = langList{langIdx};

        set(lbl_result, 'String', 'Running Quality Assessment & Complete Diagnostic Pipeline...');
        drawnow;

        try
            reportOut = main_pipeline(selectedImagePath, chosenLang);

            % Update displays
            if isfield(reportOut, 'task1_preprocessing') && isfield(reportOut.task1_preprocessing, 'image_path')
                enhP = char(reportOut.task1_preprocessing.image_path);
                if exist(enhP, 'file'), axes(ax2); imshow(imread(enhP)); title(ax2, '2. Task 1 CLAHE Enhanced', 'FontWeight', 'bold', 'Color', [0.01, 0.52, 0.78]); end
            end

            if isfield(reportOut, 'task2_grading') && ~isempty(reportOut.task2_grading)
                gRes = reportOut.task2_grading;

                if isfield(gRes, 'heatmap_image_path') && exist(char(gRes.heatmap_image_path), 'file')
                    axes(ax3); imshow(imread(char(gRes.heatmap_image_path))); title(ax3, '3. Grad-CAM Heatmap', 'FontWeight', 'bold', 'Color', [0.85, 0.15, 0.15]);
                end
                if isfield(gRes, 'annotated_evidence_image') && exist(char(gRes.annotated_evidence_image), 'file')
                    axes(ax4); imshow(imread(char(gRes.annotated_evidence_image))); title(ax4, '4. Retinal Evidence Overlay', 'FontWeight', 'bold', 'Color', [0.45, 0.20, 0.85]);
                end

                resText = sprintf(['  VERDICT: Grade %d (%s)\n', ...
                                   '  Calibrated Confidence: %.1f%% (%s)\n', ...
                                   '  Referable DR (L2+): %s | Triage: %s\n', ...
                                   '  Timeline: %s\n\n', ...
                                   '  OBJECTIVE BIOMARKERS:\n', ...
                                   '  - Sub-Pixel Microaneurysms: %d spots (precision +/-0.15 px)\n', ...
                                   '  - Hard Exudate Area: %.3f Disc Diameters (CSME risk: %s)\n', ...
                                   '  - Neovascularization: %s\n', ...
                                   '  - Peak Lesion Quadrant: %s\n', ...
                                   '  - Doctor Review Est.: %.1f seconds (<30s target)\n\n', ...
                                   '  Clinical Report Saved: %s'], ...
                    gRes.grade, gRes.grade_label, gRes.confidence * 100, gRes.status, ...
                    ternary(gRes.is_referable, 'YES (Referral Required)', 'NO (Routine)'), ...
                    gRes.urgency_label, gRes.follow_up_timeline, ...
                    gRes.subpixel_microaneurysm_count, gRes.exudate_area_disc_diameters, ...
                    ternary(gRes.has_csme_macular_risk, 'YES', 'NO'), ...
                    ternary(gRes.has_neovascularization, 'YES', 'NO'), ...
                    gRes.peak_quadrant, gRes.estimated_doctor_review_seconds, ...
                    reportOut.clinical_report.report_text_file);
                set(lbl_result, 'String', resText);

                if isfield(gRes, 'recommendations')
                    r = gRes.recommendations;
                    pLines = sprintf('  [%d] %s\n', 1:length(r.parhez), r.parhez{:});
                    parhezText = sprintf(['  ETIOLOGY / ROOT CAUSE:\n  %s\n\n', ...
                                          '  DIETARY PARHEZ & PRECAUTIONS:\n%s\n', ...
                                          '  LIFTING / PHYSICAL RESTRICTION:\n  %s\n\n', ...
                                          '  RECOMMENDED FACILITY:\n  %s'], ...
                        r.etiology, pLines, r.lifting_restriction, r.referral_facility);
                    set(lbl_parhez, 'String', parhezText);
                end
            else
                % Ungradable rejection
                set(lbl_result, 'String', sprintf(['  QUALITY ASSESSMENT FAILED:\n\n', ...
                                                   '  Status: UNGRADABLE\n', ...
                                                   '  Score : %.2f / 1.00\n', ...
                                                   '  Reason: %s\n\n', ...
                                                   '  ACTION REQUIRED:\n  Please capture/upload another retinal image.'], ...
                    reportOut.task1_preprocessing.quality_score, reportOut.task1_preprocessing.message));
                set(lbl_parhez, 'String', 'No diagnostic recommendations generated because image quality is ungradable.');
            end
        catch ME
            set(lbl_result, 'String', sprintf('Error during analysis:\n%s', ME.message));
        end
    end
end

function out = ternary(cond, valTrue, valFalse)
    if cond, out = valTrue; else, out = valFalse; end
end
