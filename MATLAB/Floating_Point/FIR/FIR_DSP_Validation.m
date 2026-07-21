%% ============================================================
% 10_FIR_DSP_Validation.m
% Compare CIC + FIR Responses
% =============================================================

clear;
clc;
close all;

%% CIC Parameters

Fs_in = 20.48e6;

R = 21;
M = 1;
N = 5;

Fs_out = Fs_in/R;

%% CIC Response

cic = dsp.CICDecimator(R,M,N);

Nfft = 65536;

[Hcic,fcic] = freqz(cic,Nfft,Fs_in);

Hcic = Hcic/max(abs(Hcic));

fcic = fcic/R;

%% FIR Specifications

Passband = 85000;

Ripple = 0.05;

Attenuation = 80;

Stopband = [120000 140000 170000 200000];

Colors = {'b','r','g','k'};

Legend = {};

figure;
hold on;
grid on;

%% Loop

for k = 1:length(Stopband)

    comp = dsp.CICCompensationDecimator;

    comp.CICRateChangeFactor = R;
    comp.CICNumSections = N;
    comp.CICDifferentialDelay = M;

    comp.SampleRate = Fs_out;

    comp.PassbandFrequency = Passband;
    comp.StopbandFrequency = Stopband(k);

    comp.PassbandRipple = Ripple;
    comp.StopbandAttenuation = Attenuation;

    comp.DesignForMinimumOrder = true;

    coeff = coeffs(comp);

    [Hfir,f] = freqz(coeff.Numerator,1,Nfft,Fs_out);

    Hcic_interp = interp1(fcic,abs(Hcic),f,'linear');

    Htotal = abs(Hfir).*Hcic_interp;

    Htotal = Htotal/max(Htotal);

    plot(f/1e3,20*log10(Htotal),...
        'LineWidth',2,...
        'Color',Colors{k});

    Legend{end+1} = sprintf('%d kHz (%d taps)',...
        Stopband(k)/1000,...
        length(coeff.Numerator));

end

xlim([0 250]);

ylim([-5 1]);

xlabel('Frequency (kHz)');
ylabel('Magnitude (dB)');

title('Combined CIC + FIR Response');

legend(Legend,'Location','SouthWest');