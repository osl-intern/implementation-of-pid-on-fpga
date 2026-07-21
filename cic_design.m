%% ============================================================
% 01_CIC_Design.m
% Designs the CIC Decimator
% =============================================================

clear;
clc;
close all;

%% Specifications

Fs_in = 20.48e6;      % Input Sampling Frequency

R = 21;               % Decimation Factor
M = 1;                % Differential Delay
N = 5;                % Number of Stages

Fs_out = Fs_in/R;

%% Create CIC Decimator

cic = dsp.CICDecimator(R,M,N);

disp('CIC Decimator Created Successfully')
disp(cic)