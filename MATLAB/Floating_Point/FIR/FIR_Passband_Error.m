%% ============================================================
% 11_FIR_Passband_Error.m
% Compare Candidate FIRs with Baseline FIR
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

%% CIC

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

%% Passband Index

f_pass = linspace(0,Passband,500);

Response = zeros(length(Stopband),length(f_pass));

%% Calculate Responses

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

    Hdb = 20*log10(Htotal);

    Response(k,:) = interp1(f,Hdb,f_pass);

    Taps(k) = length(coeff.Numerator);

end

%% Baseline

Baseline = Response(1,:);

fprintf('\n');
fprintf('===========================================================\n');
fprintf('          PASSBAND ERROR COMPARED TO BASELINE\n');
fprintf('===========================================================\n');

for k = 2:length(Stopband)

    Error = Response(k,:) - Baseline;

    MaxError = max(abs(Error));

    RMSError = sqrt(mean(Error.^2));

    fprintf('\n');

    fprintf('%3d taps\n',Taps(k));

    fprintf('Maximum Error : %.4f dB\n',MaxError);

    fprintf('RMS Error     : %.4f dB\n',RMSError);

end