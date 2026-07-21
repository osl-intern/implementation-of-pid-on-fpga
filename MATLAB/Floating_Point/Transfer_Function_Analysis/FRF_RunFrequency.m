clc
clear
close all

%% ==========================================================
% Clear Persistent Variables
%% ==========================================================

clear ADC_Model
clear CIC_Integrator
clear CIC_Comb
clear CIC_Normalize
clear FIR_Filter

%% ==========================================================
% Parameters
%% ==========================================================

R = 21;

Fs_ctrl = 0.975238e6;
Ts = 1/Fs_ctrl;

Fs_adc = Fs_ctrl*R;

%% ==========================================================
% Choose ONE test frequency
%% ==========================================================

f = 10000;          % 10 kHz

%% ==========================================================
% Signal Amplitude
%% ==========================================================

A = 3;              % 3 Volt Peak

%% ==========================================================
% Simulation Length
%% ==========================================================

controller_cycles = 1000;

%% ==========================================================
% Plant
%% ==========================================================

b0 = 0.0;
b1 = 0.00504359440518940;
b2 = 0.00484086584166143;

a1 = -1.87433774280118;
a2 = 0.884222203048027;

%% ==========================================================
% Plant States
%% ==========================================================

y = 0;

y_prev1 = 0;
y_prev2 = 0;

u_prev1 = 0;
u_prev2 = 0;

%% ==========================================================
% Main Simulation
%% ==========================================================

for cycle = 1:controller_cycles

    %% Controller time

    t = (cycle-1)*Ts;

    %% Sine excitation (Voltage)

    u = A*sin(2*pi*f*t);

    %% DAC

    dac_voltage = u;

    %% Plant

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

    %% ADC + Decimation

    for sample = 1:R

        adc_code = ADC_Model(y);

        integ = CIC_Integrator(adc_code);

    end

    cic = CIC_Comb(integ);

    cic_norm = CIC_Normalize(cic);

    fir = FIR_Filter(cic_norm);

    %% Store

    Input(cycle) = u;

    Output(cycle) = fir;

    Plant(cycle) = y;

end

%% ==========================================================
% Time Vector
%% ==========================================================

time = (0:controller_cycles-1)*Ts;

%% ==========================================================
% Plot
%% ==========================================================

figure

plot(time*1e3,Input,'LineWidth',2)

hold on

plot(time*1e3,Output,'LineWidth',2)

grid on

xlabel('Time (ms)')

ylabel('Amplitude')

legend('Input','Output')

title(['Frequency = ' num2str(f/1000) ' kHz'])