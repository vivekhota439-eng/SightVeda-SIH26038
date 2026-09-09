function datasetDir = create_mock_dataset(targetDir, samplesPerGrade)
% CREATE_MOCK_DATASET Generates a synthetic 5-class Diabetic Retinopathy
% fundus dataset in MATLAB (images/ folder + labels.csv) for training
% verification and pipeline testing.
%
% Syntax:
%   datasetDir = create_mock_dataset(targetDir, samplesPerGrade)

    cfg = config_params();

    if nargin < 1 || isempty(targetDir)
        targetDir = cfg.DATASET_DIR;
    end
    if nargin < 2 || isempty(samplesPerGrade)
        samplesPerGrade = 4;
    end

    imagesDir = fullfile(targetDir, 'images');
    if ~exist(imagesDir, 'dir')
        mkdir(imagesDir);
    end

    fprintf('Generating synthetic fundus dataset in: %s\n', targetDir);

    imageIds = {};
    diagnoses = [];
    descriptions = {};

    imgSize = 512;
    center = [imgSize / 2, imgSize / 2];
    radius = round(imgSize * 0.44);

    for grade = 0:4
        if grade == 0
            numSamples = samplesPerGrade * 2;
        else
            numSamples = samplesPerGrade;
        end

        for k = 1:numSamples
            imgId = sprintf('fundus_%d_%02d', grade, k);
            fileName = sprintf('%s.png', imgId);
            filePath = fullfile(imagesDir, fileName);

            img = zeros(imgSize, imgSize, 3, 'uint8');
            [xx, yy] = meshgrid(1:imgSize, 1:imgSize);
            distFromCenter = sqrt((xx - center(1)).^2 + (yy - center(2)).^2);
            retinaMask = distFromCenter <= radius;

            % 1. Retinal fundus orange-red base
            rPlane = zeros(imgSize, imgSize, 'uint8');
            gPlane = zeros(imgSize, imgSize, 'uint8');
            bPlane = zeros(imgSize, imgSize, 'uint8');

            rPlane(retinaMask) = 185;
            gPlane(retinaMask) = 60;
            bPlane(retinaMask) = 20;

            % 2. Optic disc
            odCenter = [center(1) - round(imgSize * 0.22), center(2) - round(imgSize * 0.02)];
            odRadius = round(imgSize * 0.06);
            distFromOD = sqrt((xx - odCenter(1)).^2 + (yy - odCenter(2)).^2);
            odMask = distFromOD <= odRadius;

            rPlane(odMask) = 255;
            gPlane(odMask) = 210;
            bPlane(odMask) = 130;

            % 3. Retinal blood vessels
            rng(grade * 100 + k);
            vesselMask = false(imgSize, imgSize);
            for angle = linspace(-pi/2, pi/2, 8)
                curX = odCenter(1);
                curY = odCenter(2);
                for step = 1:15
                    curX = curX + cos(angle) * (imgSize * 0.03) + (rand() - 0.5) * 4;
                    curY = curY + sin(angle) * (imgSize * 0.03) + (rand() - 0.5) * 4;
                    ix = round(curX); iy = round(curY);
                    if ix >= 2 && ix <= imgSize-1 && iy >= 2 && iy <= imgSize-1
                        vesselMask(iy-1:iy+1, ix-1:ix+1) = true;
                    end
                end
            end
            vesselMask = vesselMask & retinaMask & (~odMask);
            rPlane(vesselMask) = 90;
            gPlane(vesselMask) = 25;
            bPlane(vesselMask) = 10;

            % 4. Grade-specific lesions
            if grade >= 1
                numMAs = 6 * grade;
                for m = 1:numMAs
                    mx = round(center(1) + (rand() - 0.5) * (radius * 1.3));
                    my = round(center(2) + (rand() - 0.5) * (radius * 1.3));
                    if sqrt((mx - center(1))^2 + (my - center(2))^2) < (radius * 0.8)
                        rPlane(max(1, my-1):min(imgSize, my+1), max(1, mx-1):min(imgSize, mx+1)) = 60;
                        gPlane(max(1, my-1):min(imgSize, my+1), max(1, mx-1):min(imgSize, mx+1)) = 10;
                        bPlane(max(1, my-1):min(imgSize, my+1), max(1, mx-1):min(imgSize, mx+1)) = 5;
                    end
                end
            end

            if grade >= 2
                numEx = 4 * (grade - 1);
                for e = 1:numEx
                    exX = round(center(1) + (rand() - 0.5) * (radius * 1.1));
                    exY = round(center(2) + (rand() - 0.5) * (radius * 1.1));
                    if sqrt((exX - center(1))^2 + (exY - center(2))^2) < (radius * 0.75) && ...
                       sqrt((exX - odCenter(1))^2 + (exY - odCenter(2))^2) > (odRadius * 1.5)
                        rPlane(max(1, exY-3):min(imgSize, exY+3), max(1, exX-3):min(imgSize, exX+3)) = 240;
                        gPlane(max(1, exY-3):min(imgSize, exY+3), max(1, exX-3):min(imgSize, exX+3)) = 230;
                        bPlane(max(1, exY-3):min(imgSize, exY+3), max(1, exX-3):min(imgSize, exX+3)) = 140;
                    end
                end
            end

            if grade >= 3
                numHems = 6 * (grade - 2);
                for h_idx = 1:numHems
                    hx = round(center(1) + (rand() - 0.5) * (radius * 1.2));
                    hy = round(center(2) + (rand() - 0.5) * (radius * 1.2));
                    if sqrt((hx - center(1))^2 + (hy - center(2))^2) < (radius * 0.8)
                        rPlane(max(1, hy-5):min(imgSize, hy+5), max(1, hx-5):min(imgSize, hx+5)) = 70;
                        gPlane(max(1, hy-5):min(imgSize, hy+5), max(1, hx-5):min(imgSize, hx+5)) = 12;
                        bPlane(max(1, hy-5):min(imgSize, hy+5), max(1, hx-5):min(imgSize, hx+5)) = 5;
                    end
                end
            end

            img(:, :, 1) = rPlane;
            img(:, :, 2) = gPlane;
            img(:, :, 3) = bPlane;

            imwrite(img, filePath);

            imageIds{end+1, 1} = fileName; %#ok<AGROW>
            diagnoses(end+1, 1) = grade;   %#ok<AGROW>
            descriptions{end+1, 1} = cfg.GRADE_LABELS(grade); %#ok<AGROW>
        end
    end

    % Save labels.csv
    labelsTable = table(imageIds, diagnoses, descriptions, ...
        'VariableNames', {'image_id', 'diagnosis', 'grade_label'});
    csvPath = fullfile(targetDir, 'labels.csv');
    writetable(labelsTable, csvPath);

    fprintf('Generated %d synthetic images and saved catalog to: %s\n', height(labelsTable), csvPath);
end
