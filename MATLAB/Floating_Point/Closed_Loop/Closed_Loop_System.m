clc
clear
%close all

%% ==========================================================
% Clear Persistent Variables
% ===========================================================

clear ADC_Model
clear CIC_Integrator
clear CIC_Comb
clear FIR_Filter
clear pid_plant_step

%% ==========================================================
% Parameters
% ===========================================================

R = 21;

Fs_ctrl = 0.975238e6;
Ts = 1/Fs_ctrl;

controller_cycles = 1000;

%% ==========================================================
% Plant
% (Same coefficients as your validated testbench)
% ===========================================================

b0 = 0.0;
b1 = 0.00504359440518940;
b2 = 0.00484086584166143;

a1 = -1.87433774280118;
a2 =  0.884222203048027;

%% Plant States

y = 0;

y_prev1 = 0;
y_prev2 = 0;

u_prev1 = 0;
u_prev2 = 0;

%% ==========================================================
% Analog Set Point
% ===========================================================

sp_voltage = 3.5;              % Analog Set Point (V)

% Convert Analog SP using the SAME ADC model
% that is used for the feedback signal.

sp = double(ADC_Model(sp_voltage));

% selection of decimation 
USE_DECIMATION = true;

%% Main Simulation

for cycle = 1:controller_cycles

   %% ----------------------------------------------
% Feedback Acquisition
%% ----------------------------------------------


global CURRENT_CYCLE
CURRENT_CYCLE = cycle;

if cycle == controller_cycles
    assignin('base','PRINT_CIC_RANGE',true);
    assignin('base','PRINT_FIR_RANGE',true);
    assignin('base','PRINT_ADC_RANGE',true);
    assignin('base','PRINT_CIC_INT_RANGE',true);
    assignin('base','PRINT_CIC_COMB_RANGE',true);
    assignin('base','PRINT_CIC_INT_PLOT',true);
    assignin('base','PRINT_CIC_COMB_PLOT',true);
end

if USE_DECIMATION

    % ADC samples at 20.48 MSPS

    for sample = 1:R

        adc_code = ADC_Model(y);

        integ_out = CIC_Integrator(adc_code);

        if cycle == controller_cycles && sample == R
            fprintf('\nLast Integrator Output = %.0f\n', integ_out);
        end

    end

    cic_out  = CIC_Comb(integ_out);

    cic_norm = CIC_Normalize(cic_out);

    feedback = FIR_Filter(cic_norm);

    

else

    % ADC samples directly at controller rate
    % No CIC
    % No FIR

    adc_code = ADC_Model(y);

    feedback = double(adc_code);

    cic_out = 0;
    cic_norm = 0;

end

    %% ----------------------------------------------
    % PID
    %% ----------------------------------------------

    ff = sp;

    [u_sat,u_ideal,P,I,D,int_sum,error] = ...
        pid_plant_step(sp,feedback,Ts,ff);

    if USE_DECIMATION && mod(cycle,2)==0
%{
        fprintf("\nCycle %3d\n",cycle);
        fprintf("SP         = %.2f\n",sp);
        fprintf("ADC        = %.2f\n",double(adc_code));
        fprintf("CIC Norm   = %.2f\n",cic_norm);
        fprintf("FIR Output = %.2f\n",feedback);
        fprintf("Error      = %.2f\n",error);
%}
    end

    %% ----------------------------------------------
    % DAC
    %% ----------------------------------------------

    dac_voltage = DAC_Model(u_sat);

    %% ----------------------------------------------
    % Plant
    %% ----------------------------------------------

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

    %% ----------------------------------------------
    % Store Data
    %% ----------------------------------------------

    Y(cycle) = y;

    ADC(cycle) = adc_code;

    CIC(cycle) = cic_out;

    if USE_DECIMATION
    FIR(cycle) = feedback;
else
    FIR(cycle) = NaN;   % FIR not used
end

    DAC(cycle) = dac_voltage;

    PID(cycle) = u_sat;

    Error_History(cycle) = error;
    P_History(cycle) = P;
    I_History(cycle) = I;
    D_History(cycle) = D;


end

%% ==========================================================
% Plots
% ===========================================================

figure

subplot(3,2,1)
plot(Y,'LineWidth',2)
grid on
title('Plant Output')

subplot(3,2,2)
plot(ADC,'LineWidth',2)
grid on
title('ADC')

subplot(3,2,3)
plot(CIC,'LineWidth',2)
grid on
title('CIC')

subplot(3,2,4)
plot(FIR,'LineWidth',2)
grid on
title('FIR')

subplot(3,2,5)
plot(PID,'LineWidth',2)
grid on
title('PID Output')

subplot(3,2,6)
plot(DAC,'LineWidth',2)
grid on
title('DAC Output')

%% Trigger Controller Analysis

assignin('base','PRINT_CONTROLLER_RANGE',true);

pid_plant_step(sp,feedback,Ts,ff);



%% ==========================================================
% Closed-Loop Performance
%% ==========================================================

t = (0:length(Y)-1)*Ts;

info = stepinfo(Y, t, sp_voltage);

fprintf('\n');
fprintf('============= CLOSED LOOP PERFORMANCE =============\n');
fprintf('Rise Time          : %.6e s\n', info.RiseTime);
fprintf('Settling Time      : %.6e s\n', info.SettlingTime);
fprintf('Overshoot          : %.3f %%\n', info.Overshoot);
fprintf('Peak               : %.6f V\n', info.Peak);
fprintf('Peak Time          : %.6e s\n', info.PeakTime);
fprintf('Steady-State Value : %.6f V\n', Y(end));
fprintf('Steady-State Error : %.6e V\n', sp_voltage - Y(end));
fprintf('===================================================\n');

fprintf('\n');
fprintf('============= CONTROL EFFORT =============\n');
fprintf('Maximum PID Output : %.3f\n', max(PID));
fprintf('Minimum PID Output : %.3f\n', min(PID));
fprintf('Maximum DAC Output : %.3f V\n', max(DAC));
fprintf('Minimum DAC Output : %.3f V\n', min(DAC));
fprintf('==========================================\n');

fprintf('\n');
fprintf('Maximum Error      : %.2f\n', max(Error_History));
fprintf('Minimum Error      : %.2f\n', min(Error_History));
fprintf('Maximum P Term     : %.2f\n', max(P_History));
fprintf('Maximum I Term     : %.2f\n', max(I_History));
fprintf('Maximum D Term     : %.2f\n', max(D_History));