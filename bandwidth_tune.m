clc
clear
close all

%% Sampling

Fs = 0.975238e6;
Ts = 1/Fs;

%% Plant

b = [0 ...
     0.00504359440518940 ...
     0.00484086584166143];

a = [1 ...
    -1.87433774280118 ...
     0.884222203048027];

G = tf(b,a,Ts);

%% Equivalent DSP

load Heq.mat

idx = find(abs(heq)>1e-10);
heq = heq(1:idx(end));

Heq = tf(heq,1,Ts);

%% Initial Guess

x0 = [5 1000 20e-6];

%% Bounds

lb = [0.01 1000 0];
ub = [10 300000 5e-5];

%% Pattern Search Options

opts = optimoptions('patternsearch',...
    'Display','iter',...
    'UseCompletePoll',true,...
    'UseCompleteSearch',true,...
    'MeshTolerance',1e-5,...
    'StepTolerance',1e-6,...
    'FunctionTolerance',1e-6,...
    'MaxIterations',500,...
    'MaxFunctionEvaluations',5000);

%% Optimization

[xbest,fval] = patternsearch( ...
    @(x)PID_Objective(x,G,Heq,Ts),...
    x0,...
    [],[],[],[],...
    lb,ub,...
    [],...
    opts);

%% Results

Kp = xbest(1);
Ki = xbest(2);
Kd = xbest(3);

fprintf('\n====================================\n');
fprintf('Optimal PID\n');
fprintf('====================================\n');

fprintf('Kp = %.6f\n',Kp);
fprintf('Ki = %.6f\n',Ki);
fprintf('Kd = %.8f\n',Kd);

fprintf('Objective = %.4f\n',fval);

%% Final Margins

z = tf('z',Ts);

C = Kp ...
    + Ki*Ts/(1-z^-1) ...
    + (Kd/Ts)*(1-z^-1);

L = minreal(C*G*Heq);

margin(L)
grid on

[GM,PM,Wcg,Wcp] = margin(L);

fprintf('\nGain Margin  = %.2f dB\n',20*log10(GM));
fprintf('Phase Margin = %.2f deg\n',PM);
fprintf('Gain Cross   = %.2f Hz\n',Wcp/(2*pi));
fprintf('Phase Cross  = %.2f Hz\n',Wcg/(2*pi));