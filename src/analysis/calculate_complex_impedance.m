%% Calculate the complex impedance from raw Lock-in measurements
% Input columns (in this order): frequency [Hz], measured magnitude [V], phase [deg].
% The impedance equation follows the processing code supplied with the thesis.
%
% IMPORTANT PARAMETER NOTE:
% The uploaded working script uses Rs = 50 ohm. The thesis listing uses Rs = 147 ohm.
% This implementation keeps Rs = 50 ohm to match the uploaded working script.
% Verify the actual series/reference resistor before using the results scientifically.

clear;
clc;

%% Select the raw measurement file
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
rawDirectory = fullfile(projectRoot, 'data', 'raw');
processedDirectory = fullfile(projectRoot, 'data', 'processed');

if ~exist(processedDirectory, 'dir')
    mkdir(processedDirectory);
end

[fileName, filePath] = uigetfile( ...
    {'*.csv;*.txt', 'Raw measurement files (*.csv, *.txt)'}, ...
    'Select a raw Lock-in measurement file', rawDirectory);
if isequal(fileName, 0)
    error('No input file was selected.');
end
rawFile = fullfile(filePath, fileName);

%% Load and validate the three-column data matrix
rawMatrix = readmatrix(rawFile);
if size(rawMatrix, 2) < 3
    error('The selected file must contain at least three numeric columns.');
end
rawMatrix = rawMatrix(:, 1:3);
rawMatrix = rawMatrix(all(isfinite(rawMatrix), 2), :);

if isempty(rawMatrix)
    error('No valid numeric measurement rows were found in the selected file.');
end

frequency_Hz = rawMatrix(:, 1);
amplitude_V = rawMatrix(:, 2);
phase_deg = rawMatrix(:, 3);

if any(frequency_Hz <= 0)
    error('All frequency values must be greater than zero.');
end
if any(amplitude_V == 0)
    error('Measured amplitude contains zero values; impedance cannot be calculated.');
end

%% Measurement and circuit parameters
referenceAmplitude_V = 0.1;
measurementResistor_Ohm = 330e3;
seriesResistor_Ohm = 50;       % Uploaded impedancia.m value; thesis listing reports 147 ohm.
parasiticCapacitance_F = 25e-12;

%% Complex impedance calculation
omega_rad_s = 2*pi*frequency_Hz;
phaseFactor = cosd(phase_deg) + 1i*sind(phase_deg);
parasiticImpedance_Ohm = 1 ./ (1i .* omega_rad_s .* parasiticCapacitance_F);

% Transcription of the equation implemented in the supplied impedancia.m file.
impedance_Ohm = ((referenceAmplitude_V ./ (amplitude_V .* phaseFactor)) ...
    - ((seriesResistor_Ohm / measurementResistor_Ohm) ...
    - (seriesResistor_Ohm ./ parasiticImpedance_Ohm)) - 1) ...
    ./ ((1 ./ parasiticImpedance_Ohm) + (1 / measurementResistor_Ohm));

capacitance_F = 1 ./ (omega_rad_s .* imag(impedance_Ohm));

%% Assemble and save the processed data
processedData = table(frequency_Hz, omega_rad_s, amplitude_V, phase_deg, ...
    real(impedance_Ohm), imag(impedance_Ohm), abs(impedance_Ohm), capacitance_F, ...
    'VariableNames', {'Frequency_Hz', 'AngularFrequency_rad_s', ...
    'Amplitude_V', 'Phase_deg', 'ImpedanceReal_Ohm', ...
    'ImpedanceImag_Ohm', 'ImpedanceMagnitude_Ohm', 'Capacitance_F'});

[~, inputBaseName, ~] = fileparts(fileName);
processedFile = fullfile(processedDirectory, [inputBaseName, '_impedance.csv']);
matFile = fullfile(processedDirectory, [inputBaseName, '_impedance.mat']);
writetable(processedData, processedFile);

processingParameters = struct();
processingParameters.referenceAmplitude_V = referenceAmplitude_V;
processingParameters.measurementResistor_Ohm = measurementResistor_Ohm;
processingParameters.seriesResistor_Ohm = seriesResistor_Ohm;
processingParameters.parasiticCapacitance_F = parasiticCapacitance_F;
processingParameters.sourceRawFile = rawFile;
save(matFile, 'processedData', 'processingParameters');

fprintf('Impedance calculation completed.\n');
fprintf('Processed CSV: %s\n', processedFile);
fprintf('Processed MAT: %s\n', matFile);
