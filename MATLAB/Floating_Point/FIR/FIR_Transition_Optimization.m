%% ============================================================
% 09_FIR_Transition_Optimization.m
% Effect of Transition Width on FIR Order
% =============================================================

clear;
clc;
close all;

%% CIC Parameters

R = 21;
N = 5;
M = 1;

Fs = 975238.095;

%% Fixed Specifications

Passband = 85000;

Ripple = 0.05;
Attenuation = 80;

%% Sweep Stopband Edge

Stopband = [120000 130000 140000 150000 170000 200000];

Order = zeros(size(Stopband));
Delay = zeros(size(Stopband));

fprintf('\n');
fprintf('========================================================\n');
fprintf('      Transition Width Optimization\n');
fprintf('========================================================\n');

for k = 1:length(Stopband)

    comp = dsp.CICCompensationDecimator;

    comp.CICRateChangeFactor = R;
    comp.CICNumSections = N;
    comp.CICDifferentialDelay = M;

    comp.SampleRate = Fs;

    comp.PassbandFrequency = Passband;
    comp.StopbandFrequency = Stopband(k);

    comp.PassbandRipple = Ripple;
    comp.StopbandAttenuation = Attenuation;

    comp.DesignForMinimumOrder = true;

    coeff = coeffs(comp);

    Order(k) = length(coeff.Numerator);

    Delay(k) = (Order(k)-1)/2/Fs*1e6;

    fprintf('Stopband = %3d kHz --> %3d taps --> %6.2f us\n',...
        Stopband(k)/1000,...
        Order(k),...
        Delay(k));

end

%% Plot

figure;

yyaxis left

plot(Stopband/1000,Order,'o-','LineWidth',2);

ylabel('Number of Taps');

yyaxis right

plot(Stopband/1000,Delay,'s-','LineWidth',2);

ylabel('Group Delay (us)');

xlabel('Stopband Edge (kHz)');

grid on;

title('Transition Width Optimization');