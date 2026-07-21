function adc_code = SP_ADC_Model(vin)
% ============================================================
% SP_ADC_Model.m
%
% Models the LTC2314-14 ADC used for Set Point acquisition.
%
% Input:
%   vin      -> Analog input voltage (Volts)
%
% Output:
%   adc_code -> Unsigned 14-bit ADC code (0 to 16383)
%
% Specifications:
%   Resolution : 14 bits
%   Input Range: 0 to 4.096 V
%   Reference  : 4.096 V
%   Output Code: 0 to 16383 (Straight Binary)
% ============================================================

%% ADC Specifications

Vref  = 4.096;          % Reference Voltage (V)
Nbits = 14;

MAX_CODE = 2^Nbits - 1;     % 16383
MIN_CODE = 0;

%% Saturate Input Voltage

vin = max(min(vin, Vref), 0);

%% Convert Voltage to ADC Code

adc_code = round(vin * MAX_CODE / Vref);

%% Saturate Digital Code

adc_code = max(min(adc_code, MAX_CODE), MIN_CODE);

%% Return as unsigned integer

adc_code = uint16(adc_code);

end