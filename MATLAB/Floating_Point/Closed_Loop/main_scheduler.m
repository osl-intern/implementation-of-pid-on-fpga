clc;
clear;

%%=========================================================
% Scheduler
%==========================================================

R = 21;

Fs_adc = 20.48e6;
Fs_pid = Fs_adc/R;

Ts_adc = 1/Fs_adc;
Ts_pid = 1/Fs_pid;

controller_cycles = 5;

disp("Simulation Started")
disp(" ")

for cycle = 1:controller_cycles

    fprintf("\n");
    fprintf("=====================================\n");
    fprintf("Controller Cycle %d\n",cycle);
    fprintf("=====================================\n");

    %% High-speed section

    for sample = 1:R

        fprintf(" ADC Sample %2d  --->  CIC Integrator\n",sample);

    end

    %% Low-speed section

    fprintf(" CIC Comb\n");
    fprintf(" FIR\n");
    fprintf(" PID\n");
    fprintf(" DAC\n");
    fprintf(" Plant\n");

end

disp(" ")
disp("Simulation Finished")