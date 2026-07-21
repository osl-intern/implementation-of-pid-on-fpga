%% ============================================================
% 07_FIR_Order_Optimization.m
% FIR Order Optimization Study
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

Ripple = 0.05;

%% Sweep Stopband Attenuation

Attenuation = [80 70 60 50 40];

Order = zeros(size(Attenuation));

fprintf('\n');
fprintf('=============================================\n');
fprintf(' Stopband Attenuation Sweep\n');
fprintf('=============================================\n');

for k = 1:length(Attenuation)

    comp = dsp.CICCompensationDecimator;

    comp.CICRateChangeFactor = R;
    comp.CICNumSections = N;
    comp.CICDifferentialDelay = M;

    comp.SampleRate = Fs;

    comp.PassbandFrequency = Passband;
    comp.StopbandFrequency = Stopband;

    comp.PassbandRipple = Ripple;
    comp.StopbandAttenuation = Attenuation(k);

    comp.DesignForMinimumOrder = true;

    coeff = coeffs(comp);

    Order(k) = length(coeff.Numerator);

    fprintf('Attenuation = %2d dB   -->   %3d taps\n',...
        Attenuation(k),Order(k));

end

%% Plot

figure;

plot(Attenuation,Order,'o-','LineWidth',2);

grid on;

xlabel('Stopband Attenuation (dB)');
ylabel('Number of FIR Taps');

title('Effect of Stopband Attenuation');