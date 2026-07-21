function result = PID_RunSimulation(Kp,Ki,Kd)
% ==========================================================
% PID_RunSimulation.m
%
% Runs one closed-loop simulation for a given PID gain set.
% Used by the auto-tuning framework.
% ==========================================================

%% Clear persistent states
clear ADC_Model
clear CIC_Integrator
clear CIC_Comb
clear FIR_Filter
clear pid_plant_step_tune

%% Parameters
R = 21;
Fs_ctrl = 0.975238e6;
Ts = 1/Fs_ctrl;
controller_cycles = 400;

%% Plant
b0 = 0.0;
b1 = 0.00504359440518940;
b2 = 0.00484086584166143;

a1 = -1.87433774280118;
a2 =  0.884222203048027;

%% States
y = 0;
y_prev1 = 0; y_prev2 = 0;
u_prev1 = 0; u_prev2 = 0;

%% Set Point

sp_voltage = 3.5;

% Convert the analog setpoint using the SAME ADC representation
% that is used for the plant feedback.

sp = double(ADC_Model(sp_voltage));

ff = sp;

%% Configuration
USE_DECIMATION = true;

%% Storage
Y   = zeros(1,controller_cycles);
PID = zeros(1,controller_cycles);
DAC = zeros(1,controller_cycles);

%% Main Loop
for cycle = 1:controller_cycles

    if USE_DECIMATION

        for sample = 1:R
            adc_code = ADC_Model(y);
            integ_out = CIC_Integrator(adc_code);
        end

        cic_out  = CIC_Comb(integ_out);
        cic_norm = CIC_Normalize(cic_out);
        feedback = FIR_Filter(cic_norm);

    else

        adc_code = ADC_Model(y);
        feedback = double(adc_code);

    end

    [u_sat,~,~,~,~,~,~] = ...
        pid_plant_step_tune(sp,feedback,Ts,ff,Kp,Ki,Kd);

    dac_voltage = DAC_Model(u_sat);

    y_new = ...
        -a1*y_prev1 ...
        -a2*y_prev2 ...
        +b0*dac_voltage ...
        +b1*u_prev1 ...
        +b2*u_prev2;

    u_prev2 = u_prev1;
    u_prev1 = dac_voltage;

    y_prev2 = y_prev1;
    y_prev1 = y_new;

    y = y_new;

    Y(cycle)   = y;
    PID(cycle) = u_sat;
    DAC(cycle) = dac_voltage;

end





result.SatSamples = sum(abs(PID) >= 2047);
fprintf('Saturated Samples = %d\n', result.SatSamples);
%% Performance
t = (0:length(Y)-1)*Ts;
info = stepinfo(Y,t,sp_voltage);

result.Kp = Kp;
result.Ki = Ki;
result.Kd = Kd;

result.RiseTime = info.RiseTime;
result.SettlingTime = info.SettlingTime;
result.Overshoot = info.Overshoot;
result.Peak = info.Peak;
result.PeakTime = info.PeakTime;

result.FinalValue = Y(end);
result.SSE = abs(sp_voltage - Y(end));

result.PID = PID;
result.MaxPID = max(abs(PID));
result.MaxDAC = max(abs(DAC));

result.Response = Y;
result.Last20 = Y(end-19:end);
result.Time = t;


if isnan(info.SettlingTime) || any(isnan(Y)) || any(isinf(Y))
    result.Stable = false;
else
    result.Stable = true;
end

end
