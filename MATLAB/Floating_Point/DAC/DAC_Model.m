function analog_voltage = DAC_Model(digital_code)

% ============================================================
% DAC MODEL
%
% Signed 12-bit DAC
%
% Digital Input : -2048 ... +2047
% Analog Output : -10V ... +10V
%
% ============================================================

DAC_BITS = 12;

DAC_MAX = 2^(DAC_BITS-1)-1;    % 2047
DAC_MIN = -2^(DAC_BITS-1);     % -2048

VREF = 10;

%% Saturation

digital_code = max(min(digital_code,DAC_MAX),DAC_MIN);

%% Digital -> Analog

analog_voltage = double(digital_code)/DAC_MAX*VREF;

end