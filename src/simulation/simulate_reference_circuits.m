%% Simulate RC, RCR, and measurement-cell equivalent circuits
% This consolidated script contains:
%   1) The RC reference circuit (thesis Chapter 4, Listing 4.1)
%   2) The RCR reference circuit (thesis Chapter 4, Listing 4.2)
%   3) Four measurement-cell model configurations (thesis Appendix A, Listings A.1-A.4)
%
% The sweep is explicitly defined in Hz from 10 Hz to 100 kHz. Angular frequency
% is calculated as omega = 2*pi*f before evaluating the transfer functions.
%
% The numerator/denominator coefficients used below follow the coefficient arrays
% passed to FREQuency response evaluation in the thesis listings. See
% docs/electrical_models.md for the source-equation notes and known transcription issue.

clear;
clc;

%% Shared frequency sweep
startFrequency_Hz = 10;
stopFrequency_Hz = 100e3;       % 100 kHz
numberOfPoints = 200;
frequency_Hz = logspace(log10(startFrequency_Hz), ...
    log10(stopFrequency_Hz), numberOfPoints).';
omega_rad_s = 2*pi*frequency_Hz;
s = 1i*omega_rad_s;
referenceAmplitude_V = 0.1;

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
figureDirectory = fullfile(projectRoot, 'results', 'figures', 'simulations');
dataDirectory = fullfile(projectRoot, 'results', 'simulation_data');
if ~exist(figureDirectory, 'dir'), mkdir(figureDirectory); end
if ~exist(dataDirectory, 'dir'), mkdir(dataDirectory); end

%% 1. RC reference circuit
% Values reported in the thesis: R = 100 ohm, C = 20 uF, Vref = 0.1 V.
R_RC_Ohm = 100;
C_RC_F = 20e-6;

% Active numerator and denominator arrays from Listing 4.1.
% The output represented by these coefficients is the response measured across R.
numerator_RC = [referenceAmplitude_V, 0];
denominator_RC = [1, 1/(R_RC_Ohm*C_RC_F)];
H_RC = polyval(numerator_RC, s) ./ polyval(denominator_RC, s);

rcResults = table(frequency_Hz, abs(H_RC), angle(H_RC)*180/pi, ...
    real(H_RC), imag(H_RC), ...
    'VariableNames', {'Frequency_Hz','Magnitude_V','Phase_deg', ...
    'ResponseReal','ResponseImag'});
writetable(rcResults, fullfile(dataDirectory, 'rc_simulation.csv'));

figRC = createMagnitudePhaseFigure(frequency_Hz, H_RC, ...
    'RC reference circuit', 'Simulated response (V)');
saveSimulationFigure(figRC, figureDirectory, 'rc_simulation');

%% 2. RCR reference circuit
% Values reported in the thesis: R = 100 ohm, R2 = 10 ohm, C = 20 uF.
R_RCR_Ohm = 100;
R2_RCR_Ohm = 10;
C_RCR_F = 20e-6;

% Active numerator and denominator arrays from Listing 4.2.
% The expression H1 in the thesis listing is not the expression passed to FREQUENCY
% response evaluation; these arrays reproduce the active a/b coefficient arrays.
numerator_RCR = [referenceAmplitude_V, ...
    referenceAmplitude_V*(R2_RCR_Ohm/(C_RCR_F*R_RCR_Ohm*R2_RCR_Ohm))];
denominator_RCR = [1, (R_RCR_Ohm+R2_RCR_Ohm)/(R2_RCR_Ohm*R_RCR_Ohm*C_RCR_F)];
H_RCR = polyval(numerator_RCR, s) ./ polyval(denominator_RCR, s);

rcrResults = table(frequency_Hz, abs(H_RCR), angle(H_RCR)*180/pi, ...
    real(H_RCR), imag(H_RCR), ...
    'VariableNames', {'Frequency_Hz','Magnitude_V','Phase_deg', ...
    'ResponseReal','ResponseImag'});
writetable(rcrResults, fullfile(dataDirectory, 'rcr_simulation.csv'));

figRCR = createMagnitudePhaseFigure(frequency_Hz, H_RCR, ...
    'RCR reference circuit', 'Simulated response (V)');
saveSimulationFigure(figRCR, figureDirectory, 'rcr_simulation');

%% 3. Four configurations of the measurement-cell equivalent model
% Parameters transcribed from Appendix A of the thesis.
cellConfigurations = struct( ...
    'name', {'Configuration 1','Configuration 2','Configuration 3','Configuration 4'}, ...
    'R_Ohm', {100e3, 100e3, 100e3, 100e3}, ...
    'C1_F', {1e-9, 8.2e-9, 100e-9, 100e-9}, ...
    'C2_F', {10e-9, 10e-9, 10e-9, 10e-9}, ...
    'C3_F', {1e-9, 8.2e-9, 100e-9, 100e-9}, ...
    'R2_Ohm', {1e3, 178, 178, 1e3});

cellMagnitude = zeros(numberOfPoints, numel(cellConfigurations));
cellPhase_deg = zeros(numberOfPoints, numel(cellConfigurations));

for k = 1:numel(cellConfigurations)
    cfg = cellConfigurations(k);
    R = cfg.R_Ohm;
    C1 = cfg.C1_F;
    C2 = cfg.C2_F;
    C3 = cfg.C3_F;
    R2 = cfg.R2_Ohm;

    % Coefficient arrays from Appendix A (Listings A.1-A.4).
    denominator = [1, ...
        (1/(C2*R2) + (C2*C1 + C2*C3 + C1*C3)/(C2*R*C1*C3)), ...
        (1/(R*C2*R2))*(1/C3 + 1/C1)];

    numerator = [0, ...
        referenceAmplitude_V*(C2*C1 + C3*C2 + C1*C3)/(R*C2*C1*C3), ...
        referenceAmplitude_V*(1/(R*C2*R2*C3) + 1/(R*C2*R2*C1))];

    H_cell = polyval(numerator, s) ./ polyval(denominator, s);
    cellMagnitude(:,k) = abs(H_cell);
    cellPhase_deg(:,k) = angle(H_cell)*180/pi;

    scenarioResults = table(frequency_Hz, abs(H_cell), angle(H_cell)*180/pi, ...
        real(H_cell), imag(H_cell), ...
        'VariableNames', {'Frequency_Hz','Magnitude_V','Phase_deg', ...
        'ResponseReal','ResponseImag'});
    writetable(scenarioResults, fullfile(dataDirectory, ...
        sprintf('measurement_cell_configuration_%d.csv', k)));
end

% Combined amplitude and phase comparison for the four cell configurations.
figCell = figure('Name', 'Measurement-cell model configurations', 'Color', 'w');
subplot(2,1,1);
loglog(frequency_Hz, cellMagnitude, 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Magnitude (V)');
title('Measurement-cell model: amplitude response');
legend({cellConfigurations.name}, 'Location', 'best');

subplot(2,1,2);
semilogx(frequency_Hz, cellPhase_deg, 'LineWidth', 1.5);
grid on;
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
title('Measurement-cell model: phase response');
legend({cellConfigurations.name}, 'Location', 'best');
saveSimulationFigure(figCell, figureDirectory, 'measurement_cell_configurations');

% Save the parameter set used for all four model configurations.
configurationTable = table((1:4).', ...
    [cellConfigurations.R_Ohm].', [cellConfigurations.C1_F].', ...
    [cellConfigurations.C2_F].', [cellConfigurations.C3_F].', ...
    [cellConfigurations.R2_Ohm].', ...
    'VariableNames', {'Configuration','R_Ohm','C1_F','C2_F','C3_F','R2_Ohm'});
writetable(configurationTable, fullfile(dataDirectory, ...
    'measurement_cell_configuration_parameters.csv'));

fprintf('All simulations completed.\n');
fprintf('Frequency range: %.3g Hz to %.3g Hz (%d points).\n', ...
    frequency_Hz(1), frequency_Hz(end), numberOfPoints);
fprintf('Figures: %s\n', figureDirectory);
fprintf('Simulation data: %s\n', dataDirectory);

%% Local functions
function figHandle = createMagnitudePhaseFigure(frequency_Hz, response, figureTitle, magnitudeLabel)
    figHandle = figure('Name', figureTitle, 'Color', 'w');
    subplot(2,1,1);
    loglog(frequency_Hz, abs(response), 'LineWidth', 1.6);
    grid on;
    xlabel('Frequency (Hz)');
    ylabel(magnitudeLabel);
    title([figureTitle, ': amplitude response']);

    subplot(2,1,2);
    semilogx(frequency_Hz, angle(response)*180/pi, 'LineWidth', 1.6);
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Phase (degrees)');
    title([figureTitle, ': phase response']);
end

function saveSimulationFigure(figHandle, outputDirectory, baseName)
    savefig(figHandle, fullfile(outputDirectory, [baseName, '.fig']));
    print(figHandle, fullfile(outputDirectory, [baseName, '.png']), '-dpng', '-r300');
end
