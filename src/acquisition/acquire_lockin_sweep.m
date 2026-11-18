%% Acquire a logarithmic frequency sweep from a Lock-in amplifier
% The acquisition range is 10 Hz to 100 kHz (200 logarithmically spaced points).
% The command sequence is based on the original thesis code:
%   FREQ <frequency>  -> set the Lock-in reference frequency
%   SNAP? 3,4         -> read magnitude (R) and phase (theta)
%
% IMPORTANT:
% - Set the Lock-in output/reference amplitude to 0.1 V before running.
% - Confirm the VISA resource string and instrument command set for your unit.
% - This script uses MATLAB's legacy VISA interface (visa/fopen/fprintf/fscanf).

clear;
clc;

%% User settings
visaVendor = 'ni';
visaResource = 'GPIB0::8::0::INSTR';

startFrequency_Hz = 10;
stopFrequency_Hz = 100e3;       % 100 kHz - keep this upper limit
numberOfPoints = 200;
referenceAmplitude_V = 0.1;     % Set on the instrument; recorded as metadata only
settlingTime_s = 0.5;
initialPause_s = 2.0;

sampleID = 'sample';            % Replace with a short sample identifier
outputDirectory = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
    'data', 'raw');

%% Validate settings
assert(startFrequency_Hz > 0, 'Start frequency must be positive.');
assert(stopFrequency_Hz > startFrequency_Hz, ...
    'Stop frequency must be greater than start frequency.');
assert(numberOfPoints >= 2, 'At least two frequency points are required.');

if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end

frequency_Hz = logspace(log10(startFrequency_Hz), ...
    log10(stopFrequency_Hz), numberOfPoints).';
amplitude_V = nan(numberOfPoints, 1);
phase_deg = nan(numberOfPoints, 1);

%% Connect to the instrument
lockin = visa(visaVendor, visaResource);
lockin.Timeout = 15;
cleanupObject = onCleanup(@() closeVisaConnection(lockin)); %#ok<NASGU>

fopen(lockin);
pause(initialPause_s);

% Initialize the instrument at the first frequency, as in the original script.
fprintf(lockin, 'FREQ %.12g', startFrequency_Hz);
pause(initialPause_s);

%% Acquire magnitude and phase
fprintf('Starting sweep: %.3g Hz to %.3g Hz (%d points)\n', ...
    startFrequency_Hz, stopFrequency_Hz, numberOfPoints);

sweepTimer = tic;
for k = 1:numberOfPoints
    fprintf(lockin, 'FREQ %.12g', frequency_Hz(k));
    pause(settlingTime_s);

    fprintf(lockin, 'SNAP? 3,4');
    response = strtrim(fscanf(lockin));
    values = sscanf(response, '%f,%f');

    % Some instrument configurations return values separated by whitespace.
    if numel(values) ~= 2
        values = sscanf(response, '%f %f');
    end

    if numel(values) ~= 2 || any(~isfinite(values))
        error('Unexpected Lock-in response at %.6g Hz: "%s"', ...
            frequency_Hz(k), response);
    end

    amplitude_V(k) = values(1);
    phase_deg(k) = values(2);

    fprintf('Point %3d/%3d | %10.4g Hz | %12.5g V | %9.4f deg\n', ...
        k, numberOfPoints, frequency_Hz(k), amplitude_V(k), phase_deg(k));
end
elapsedTime_s = toc(sweepTimer);

%% Save raw data and acquisition metadata
acquisitionDateTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
rawData = table(frequency_Hz, amplitude_V, phase_deg, ...
    'VariableNames', {'Frequency_Hz', 'Amplitude_V', 'Phase_deg'});

fileTimestamp = datestr(now, 'yyyymmdd_HHMMSS');
baseFileName = sprintf('%s_%s_raw', sampleID, fileTimestamp);
csvFile = fullfile(outputDirectory, [baseFileName, '.csv']);
matFile = fullfile(outputDirectory, [baseFileName, '.mat']);

writetable(rawData, csvFile);
metadata = struct();
metadata.sampleID = sampleID;
metadata.acquisitionDateTime = char(acquisitionDateTime);
metadata.visaVendor = visaVendor;
metadata.visaResource = visaResource;
metadata.startFrequency_Hz = startFrequency_Hz;
metadata.stopFrequency_Hz = stopFrequency_Hz;
metadata.numberOfPoints = numberOfPoints;
metadata.referenceAmplitude_V = referenceAmplitude_V;
metadata.settlingTime_s = settlingTime_s;
metadata.elapsedTime_s = elapsedTime_s;
metadata.columnDescription = ...
    {'Frequency_Hz', 'Amplitude_V (Lock-in magnitude R)', 'Phase_deg (Lock-in theta)'};
save(matFile, 'rawData', 'metadata');

fprintf('\nAcquisition completed in %.1f s.\n', elapsedTime_s);
fprintf('CSV file: %s\n', csvFile);
fprintf('MAT file: %s\n', matFile);

%% Local cleanup function
function closeVisaConnection(instrumentObject)
% Close and delete the VISA object even if acquisition stops with an error.
    try
        if strcmpi(instrumentObject.Status, 'open')
            fclose(instrumentObject);
        end
    catch
        % Continue cleanup if the instrument is already disconnected.
    end
    try
        delete(instrumentObject);
    catch
        % The object may already have been deleted by MATLAB.
    end
end
