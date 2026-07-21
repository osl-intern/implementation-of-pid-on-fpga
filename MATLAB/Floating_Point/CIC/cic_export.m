%% ============================================================
% 04_Coefficient_Export.m
% Export FIR Coefficients
% ============================================================

clear;
clc;
close all;

%% Design Compensation FIR

comp = dsp.CICCompensationDecimator;

comp.CICRateChangeFactor      = 21;
comp.CICNumSections           = 5;
comp.CICDifferentialDelay     = 1;

comp.SampleRate               = 975238.095;

comp.PassbandFrequency        = 85000;
comp.StopbandFrequency        = 170000;

comp.PassbandRipple           = 0.05;
comp.StopbandAttenuation      = 80;

%% Obtain coefficients

C = coeffs(comp);

h = C.Numerator;

%% Information

fprintf("\n");
fprintf("Number of coefficients : %d\n",length(h));

center = ceil(length(h)/2);

fprintf("First coefficient      : %.12f\n",h(1));
fprintf("Center coefficient     : %.12f\n",h(center));
fprintf("Last coefficient       : %.12f\n",h(end));

fprintf("Group Delay            : %.2f samples\n",(length(h)-1)/2);
fprintf("Group Delay            : %.2f us\n",...
        ((length(h)-1)/2)/975238.095*1e6);

%% Export

save('FIR_Coefficients.mat','h');

writematrix(h','FIR_Coefficients.csv');

disp("Coefficient Export Successful");