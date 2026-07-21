%% ============================================================
% 03_CIC_Compensation_FIR.m
% Design CIC Compensation FIR
% =============================================================

clear;
clc;
close all;

%% Compensation Filter

comp = dsp.CICCompensationDecimator;

%% CIC Parameters

comp.CICRateChangeFactor = 21;
comp.CICNumSections = 5;
comp.CICDifferentialDelay = 1;

%% FIR Specifications

comp.SampleRate = 975238.095;

comp.PassbandFrequency = 85000;
comp.StopbandFrequency = 170000;

comp.PassbandRipple = 0.05;
comp.StopbandAttenuation = 80;

comp.DesignForMinimumOrder = true;

%% Generate FIR

coeff = coeffs(comp);

disp('Compensation FIR Designed Successfully')

fprintf('\n');
fprintf('Number of Coefficients : %d\n',length(coeff.Numerator));

%% View Response

fvtool(comp)

coeff = coeffs(comp);

figure;
[H,f] = freqz(coeff.Numerator,1,65536,975238.095);

figure

plot(f/1e3,20*log10(abs(H)),'LineWidth',2)

grid on

xlim([0 150])

ylim([-2 2])

xlabel('Frequency (kHz)')
ylabel('Magnitude (dB)')
title('Passband of 106-Tap Compensation FIR')
title('106-Tap Compensation FIR');

%% ==========================================================
% FIR Coefficient Analysis
%% ==========================================================

h = coeff.Numerator(:);      % Convert to column vector

fprintf('\n============= FIR COEFFICIENT ANALYSIS =============\n');

fprintf('Number of Taps          : %d\n', length(h));

fprintf('Maximum Coefficient     : %.15f\n', max(h));

fprintf('Minimum Coefficient     : %.15f\n', min(h));

fprintf('Maximum |Coefficient|   : %.15f\n', max(abs(h)));

fprintf('Minimum Non-zero Coeff  : %.15f\n', ...
    min(abs(h(h~=0))));

symmetry_error = max(abs(h - flipud(h)));

fprintf('Symmetry Error          : %.3e\n', symmetry_error);

fprintf('Current Number of Taps  : %d\n', length(h));

figure;
stem(h,'filled');
grid on;
xlabel('Tap Number');
ylabel('Coefficient');
title(sprintf('%d-Tap FIR Coefficients',length(h)));