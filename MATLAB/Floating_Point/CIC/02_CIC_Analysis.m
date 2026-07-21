%% ============================================================
% 02_CIC_Analysis.m
% Frequency Response Analysis of CIC Filter
% =============================================================

clear;
clc;
close all;

%% Specifications

Fs_in = 20.48e6;

R = 21;
M = 1;
N = 5;

%% Create CIC

cic = dsp.CICDecimator(R,M,N);

%% Frequency Response

Nfft = 65536;

[H,f] = freqz(cic,Nfft,Fs_in);

%% Normalize

H = H/max(abs(H));

%% Complete Frequency Response

figure;

plot(f/1e6,20*log10(abs(H)),'LineWidth',2);

grid on;

xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
title('Normalized CIC Frequency Response');

%% Passband

figure;

plot(f/1e3,20*log10(abs(H)),'LineWidth',2);

grid on;

xlim([0 150]);

xlabel('Frequency (kHz)');
ylabel('Magnitude (dB)');
title('CIC Passband');

%% Droop at Controller Bandwidth

BW = 70.56e3;

Gain = interp1(f,20*log10(abs(H)),BW);

fprintf('\n');
fprintf('Controller Bandwidth : %.2f kHz\n',BW/1e3);
fprintf('Gain at Bandwidth    : %.3f dB\n',Gain);

%% First Null

fprintf('\n');
fprintf('Expected First Null : %.3f kHz\n',Fs_in/R/1e3);

%% ============================================================
% CIC Gain at Important Frequencies
% =============================================================

Freqs = [85e3 120e3 150e3 200e3 250e3 300e3 400e3];

fprintf('\n');
fprintf('===========================================\n');
fprintf('     CIC Gain at Important Frequencies\n');
fprintf('===========================================\n');

for k = 1:length(Freqs)

    G = interp1(f,20*log10(abs(H)),Freqs(k));

    fprintf('%6.0f kHz  --->  %8.3f dB\n',...
        Freqs(k)/1e3,G);

end