function adc_code = ADC_Model(vin)
% ============================================================
% ADC_Model.m
%
% Models the LTC2314 ADC
%
% Input :
%   vin      -> Analog input voltage (Volts)
%
% Output:
%   adc_code -> Signed 14-bit ADC code
%
% Specifications:
%   Resolution : 14 bits
%   Input Range: ±10 V
%   Output Code: -8192 to +8191
% ============================================================

persistent min_vin max_vin
persistent min_adc max_adc

persistent min_nz_vin
persistent min_nz_adc

%% ADC Specifications

Vref  = 15;          % ±10 V
Nbits = 16;

%% ----------------------------------------------------------
% Range Initialization
%-----------------------------------------------------------

if isempty(min_vin)

    min_vin = inf;
    max_vin = -inf;

    min_adc = inf;
    max_adc = -inf;

    min_nz_vin = inf;
    min_nz_adc = inf;

end

MAX_CODE =  2^(Nbits-1) - 1;   % +8191
MIN_CODE = -2^(Nbits-1);       % -8192

%% Saturate Input Voltage

vin = max(min(vin, Vref), -Vref);

%% Convert Voltage to Signed ADC Code

adc_code = round(vin * (2^(Nbits-1)) / Vref);

%% Saturate Digital Code

adc_code = max(min(adc_code, MAX_CODE), MIN_CODE);

%% Return as int16

adc_code = int16(adc_code);

%% ----------------------------------------------------------
% Range Tracking
%-----------------------------------------------------------

min_vin = min(min_vin,double(vin));
max_vin = max(max_vin,double(vin));

min_adc = min(min_adc,double(adc_code));
max_adc = max(max_adc,double(adc_code));

if vin~=0
    min_nz_vin = min(min_nz_vin,abs(double(vin)));
end

if adc_code~=0
    min_nz_adc = min(min_nz_adc,abs(double(adc_code)));
end

%% ----------------------------------------------------------
% Print Once
%-----------------------------------------------------------

if evalin('base','exist(''PRINT_ADC_RANGE'',''var'')')

    fprintf('\n');
    disp('================ ADC MODEL =================');

    fprintf('%-18s %15s %15s %18s\n',...
        'Variable','Minimum','Maximum','Min Non-Zero');

    disp('---------------------------------------------------------------');

    fprintf('%-18s %15.6f %15.6f %18.12f\n',...
        'Input Voltage',...
        min_vin,...
        max_vin,...
        min_nz_vin);

    fprintf('%-18s %15.6f %15.6f %18.12f\n',...
        'ADC Code',...
        min_adc,...
        max_adc,...
        min_nz_adc);

    disp('===============================================================');

    evalin('base','clear PRINT_ADC_RANGE');

end

end