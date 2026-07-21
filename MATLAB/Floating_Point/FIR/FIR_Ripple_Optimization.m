%% ============================================================
% 08_FIR_Ripple_Optimization.m
% FIR Order vs Passband Ripple
% =============================================================

clear;
clc;
close all;

%% Fixed CIC Parameters

R = 21;
N = 5;
M = 1;

Fs = 975238.095;

%% Fixed FIR Specifications

Passband = 85000;
Stopband = 120000;

Attenuation = 80;

%% Sweep Ripple

Ripple = [0.05 0.10 0.15 0.20 0.30 0.40 0.50];

Order = zeros(size(Ripple));

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Passband Ripple Sweep\n');
fprintf('=============================================\n');

for k = 1:length(Ripple)

    comp = dsp.CICCompensationDecimator;

    comp.CICRateChangeFactor = R;
    comp.CICNumSections = N;
    comp.CICDifferentialDelay = M;

    comp.SampleRate = Fs;

    comp.PassbandFrequency = Passband;
    comp.StopbandFrequency = Stopband;

    comp.PassbandRipple = Ripple(k);
    comp.StopbandAttenuation = Attenuation;

    comp.DesignForMinimumOrder = true;

    coeff = coeffs(comp);

    Order(k) = length(coeff.Numerator);

    fprintf('Ripple = %.2f dB   -->   %3d taps\n', ...
        Ripple(k),Order(k));

end

%% Plot

figure;

plot(Ripple,Order,'o-','LineWidth',2);

grid on;

xlabel('Passband Ripple (dB)');
ylabel('Number of FIR Taps');

title('Effect of Passband Ripple');