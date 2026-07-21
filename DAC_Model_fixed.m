function analog_voltage = DAC_Model_fixed(digital_code,pid_valid)

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

persistent last_voltage

if isempty(last_voltage)

    last_voltage = 0;

end

%% ==========================================================
% Valid Enable
%% ==========================================================

if ~pid_valid

    analog_voltage = last_voltage;

    return;

end

%% Saturation

digital_code = max(min(digital_code,DAC_MAX),DAC_MIN);

%% Digital -> Analog

analog_voltage = double(digital_code)/DAC_MAX*VREF;

last_voltage = analog_voltage;

end