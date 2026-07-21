clc
clear
close all

%% ==========================================================
% Sampling
%% ==========================================================

Fs = 0.975238e6;
Ts = 1/Fs;

%% ==========================================================
% PID
%% ==========================================================

Kp = 5.0;
Ki = 100000;
Kd = 10e-8;

z = tf('z',Ts);

C = Kp ...
    + Ki*Ts/(1-z^-1) ...
    + (Kd/Ts)*(1-z^-1);

C = minreal(C);

%% ==========================================================
% Plant
%% ==========================================================

b = [0 ...
     0.00504359440518940 ...
     0.00484086584166143];

a = [1 ...
    -1.87433774280118 ...
     0.884222203048027];

G = tf(b,a,Ts);

%% ==========================================================
% Equivalent DSP (CIC + FIR + Decimation)
%% ==========================================================

load Heq.mat

last = find(abs(heq)>1e-8,1,'last');

heq = heq(1:last);

Heq = tf(heq,1,Ts);

%% ==========================================================
% OPEN LOOP
%% ==========================================================

L_noDSP = minreal(C*G);

L_DSP = minreal(C*G*Heq);

%% ==========================================================
% CLOSED LOOP
%% ==========================================================

T_noDSP = feedback(L_noDSP,1);

T_DSP = feedback(L_DSP,1);

%% ==========================================================
% 1. CLOSED LOOP STABILITY (WITH DECIMATION)
%% ==========================================================

fprintf('\n');
fprintf('=============================================\n');
fprintf('1. CLOSED LOOP STABILITY (WITH DECIMATION)\n');
fprintf('=============================================\n');

p = pole(T_DSP);

disp('Closed-loop poles :')

disp(p)

if all(abs(p)<1)

    fprintf('\nSTATUS : STABLE\n');

else

    fprintf('\nSTATUS : UNSTABLE\n');

end

%% ==========================================================
% 2. CLOSED LOOP BANDWIDTH (WITHOUT DECIMATION)
%% ==========================================================

fprintf('\n');
fprintf('=============================================\n');
fprintf('2. CLOSED LOOP BANDWIDTH (WITHOUT DECIMATION)\n');
fprintf('=============================================\n');

try

    BW = bandwidth(T_noDSP);

    fprintf('Bandwidth = %.2f Hz\n',BW/(2*pi));

catch

    fprintf('Bandwidth could not be computed.\n');

end

%% ==========================================================
% 3. GAIN / PHASE MARGIN (WITH DECIMATION)
%% ==========================================================

fprintf('\n');
fprintf('=============================================\n');
fprintf('3. GAIN & PHASE MARGIN (WITH DECIMATION)\n');
fprintf('=============================================\n');

[GM,PM,Wcg,Wcp] = margin(L_DSP);

fprintf('Gain Margin        = %.3f dB\n',20*log10(GM));
fprintf('Phase Margin       = %.3f deg\n',PM);
fprintf('Gain Crossover     = %.3f Hz\n',Wcp/(2*pi));
fprintf('Phase Crossover    = %.3f Hz\n',Wcg/(2*pi));

AM = allmargin(L_DSP);

disp(AM)

%% ==========================================================
% OPEN LOOP BODE (WITH DECIMATION)
%% ==========================================================

figure
margin(L_DSP)
grid on
title('Open Loop with CIC + FIR + Decimation')

%% ==========================================================
% CLOSED LOOP BODE (WITHOUT DECIMATION)
%% ==========================================================

figure
bode(T_noDSP)
grid on
title('Closed Loop (Without Decimation)')

%% ==========================================================
% CLOSED LOOP BODE (WITH DECIMATION)
%% ==========================================================

figure
bode(T_DSP)
grid on
title('Closed Loop (With CIC + FIR + Decimation)')

%% ==========================================================
% OPEN LOOP MANUAL BODE (WITH DECIMATION)
%% ==========================================================

w = logspace(2,6,3000);

[mag,phase] = bode(L_DSP,w);

mag = squeeze(mag);

phase = squeeze(phase);

phase = unwrap(deg2rad(phase));

phase = rad2deg(phase);

freq = w/(2*pi);

figure
semilogx(freq,20*log10(mag),'LineWidth',1.5)
grid on
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('Open Loop Magnitude (With Decimation)')

figure
semilogx(freq,phase,'LineWidth',1.5)
grid on
xlabel('Frequency (Hz)')
ylabel('Phase (deg)')
title('Open Loop Phase (With Decimation)')