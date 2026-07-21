clc
clear

%% Sampling

Fs = 0.975238e6;
Ts = 1/Fs;

%% Load impulse response

load Heq.mat

%% Remove trailing zeros

last = find(abs(heq)>1e-8,1,'last');

heq = heq(1:last);

fprintf("Equivalent FIR Length = %d\n",length(heq));

fprintf("Group Delay = %.2f samples\n",(length(heq)-1)/2);

fprintf("Group Delay = %.2f us\n",...
    ((length(heq)-1)/2)/Fs*1e6);

%% Build Transfer Function

Heq = tf(heq,1,Ts);

disp(Heq)