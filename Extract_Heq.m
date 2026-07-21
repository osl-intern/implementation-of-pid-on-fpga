clc
clear
close all

%% ==========================================================
% Clear Persistent Variables
%% ==========================================================

clear CIC_Integrator
clear CIC_Comb
clear FIR_Filter

%% ==========================================================
% Parameters
%% ==========================================================

R = 21;

controller_outputs = 120;
adc_samples = controller_outputs * R;

%% ==========================================================
% Impulse Input
%
% One ADC-count impulse followed by zeros
%% ==========================================================

impulse = zeros(1,adc_samples);

impulse(1:R)=1;

%% ==========================================================
% Storage
%% ==========================================================

heq = zeros(1,controller_outputs);

idx = 1;

%% ==========================================================
% Run Through DSP Chain
%% ==========================================================

for n = 1:adc_samples

    %% ADC sample

    x = impulse(n);

    %% CIC Integrator

    integ = CIC_Integrator(x);

    %% Every R samples produce one output

    if mod(n,R)==0

        cic = CIC_Comb(integ);

        cic_norm = CIC_Normalize(cic);

        y = FIR_Filter(cic_norm);

        heq(idx) = y;

        idx = idx + 1;

    end

end

%% ==========================================================
% Plot
%% ==========================================================

figure

stem(heq,'filled')

grid on

xlabel('Output Sample')

ylabel('Amplitude')

title('Equivalent Impulse Response')


%% ==========================================================
% Save
%% ==========================================================

save Heq.mat heq

writematrix(heq','Heq.csv')

disp('Equivalent impulse response saved.')