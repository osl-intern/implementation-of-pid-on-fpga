clc
clear
close all

%% ==========================================================
% Fixed Parameters
%% ==========================================================

Fs = 975238.095;          % Output sample rate

R = 21;
N = 5;
M = 1;

Passband = 85e3;

%% ==========================================================
% Sweep Parameters
%% ==========================================================

StopbandList = 110e3:10e3:220e3;

RippleList = [0.05 0.1];

AttenList = [80 70 60 50 40];

fprintf('\n');
fprintf('-------------------------------------------------------------\n');
fprintf(' Pass    Stop    Ripple   Atten    Taps    Delay(us)\n');
fprintf('-------------------------------------------------------------\n');

Result = [];

%% ==========================================================
% Search
%% ==========================================================

for Rp = RippleList

    for As = AttenList

        for Fstop = StopbandList

            try

                comp = dsp.CICCompensationDecimator( ...
                    CICRateChangeFactor      = R,...
                    CICNumSections           = N,...
                    CICDifferentialDelay     = M,...
                    SampleRate               = Fs,...
                    PassbandFrequency        = Passband,...
                    StopbandFrequency        = Fstop,...
                    PassbandRipple           = Rp,...
                    StopbandAttenuation      = As);

                C = coeffs(comp);

b = C.Numerator;

taps = length(b);

delay_us = ((taps-1)/2)/Fs*1e6;

                fprintf('%5dk   %5dk    %5.2f     %2d      %3d      %6.2f\n',...
                    round(Passband/1000),...
                    round(Fstop/1000),...
                    Rp,...
                    As,...
                    taps,...
                    delay_us);

                Result = [Result;
                    Passband ...
                    Fstop ...
                    Rp ...
                    As ...
                    taps ...
                    delay_us];

            catch

            end

        end

    end

end

%% ==========================================================
% Sort by FIR length
%% ==========================================================

Result = sortrows(Result,5);

fprintf('\n');
fprintf('================ BEST CANDIDATES ================\n');

disp(array2table(Result,...
    'VariableNames',...
    {'Passband_Hz',...
     'Stopband_Hz',...
     'Ripple_dB',...
     'Attenuation_dB',...
     'Taps',...
     'Delay_us'}));