function [u_sat,u_ideal,P,I,D,int_sum,error] = pid_plant_step(sp,feedback,Ts,ff,Kp,Ki,Kd)

persistent int_acc e_prev

%-------------------------------
% Range Tracking Variables
%-------------------------------
persistent min_error max_error
persistent min_derivative max_derivative
persistent min_P max_P
persistent min_I max_I
persistent min_D max_D
persistent min_FF max_FF
persistent min_uideal max_uideal
persistent min_usat max_usat
persistent min_intacc max_intacc

if isempty(int_acc)

    int_acc = 0;
    e_prev  = sp;

    min_error = inf;      max_error = -inf;
    min_derivative = inf; max_derivative = -inf;
    min_P = inf;          max_P = -inf;
    min_I = inf;          max_I = -inf;
    min_D = inf;          max_D = -inf;
    min_FF = inf;         max_FF = -inf;
    min_uideal = inf;     max_uideal = -inf;
    min_usat = inf;       max_usat = -inf;
    min_intacc = inf;     max_intacc = -inf;

end

% PID gains
%Kp =  4.63389579434015;
%Ki = 138775.135537483;
%Kd = 2.21641414185509e-05;
Kd_eff = Kd / Ts;

% Feedforward gain
Kff = 0.00303659398497415;

kt= 1.27724632452934e-06;

% Saturation limit
u_max = 2047;

%---------------------------------------------------
% Controller
%---------------------------------------------------

error = sp - feedback;

derivative = error - e_prev;

P = Kp * error;
I = Ki * int_acc;
D = Kd_eff * derivative;
FF = Kff * ff;

u_ideal = P + I + D + FF;

% Output saturation only
u_sat = max(min(u_ideal, u_max), -u_max);

sat_error = u_sat - u_ideal;

int_acc = int_acc  ...
        + Ts * error ...
        + kt * sat_error;
int_sum = int_acc;

e_prev = error;

%---------------------------------------------------
% Range Tracking
%---------------------------------------------------

min_error = min(min_error, error);
max_error = max(max_error, error);

min_derivative = min(min_derivative, derivative);
max_derivative = max(max_derivative, derivative);

min_P = min(min_P, P);
max_P = max(max_P, P);

min_I = min(min_I, I);
max_I = max(max_I, I);

min_D = min(min_D, D);
max_D = max(max_D, D);

min_FF = min(min_FF, FF);
max_FF = max(max_FF, FF);

min_uideal = min(min_uideal, u_ideal);
max_uideal = max(max_uideal, u_ideal);

min_usat = min(min_usat, u_sat);
max_usat = max(max_usat, u_sat);

min_intacc = min(min_intacc, int_acc);
max_intacc = max(max_intacc, int_acc);

%---------------------------------------------------
% Print once at end (triggered from testbench)
%---------------------------------------------------

if evalin('base','exist(''PRINT_CONTROLLER_RANGE'',''var'')')

    disp(' ')
    disp('============= CONTROLLER RANGES =============')
    fprintf('%-14s %12s   %12s\n','Variable','MIN','MAX')
    disp('---------------------------------------------')
    fprintf('Error        : %12.6f   %12.6f\n', min_error,      max_error);
    fprintf('Derivative   : %12.6f   %12.6f\n', min_derivative, max_derivative);
    fprintf('P            : %12.6f   %12.6f\n', min_P,          max_P);
    fprintf('I            : %12.6f   %12.6f\n', min_I,          max_I);
    fprintf('D            : %12.6f   %12.6f\n', min_D,          max_D);
    fprintf('FF           : %12.6f   %12.6f\n', min_FF,         max_FF);
    fprintf('u_ideal      : %12.6f   %12.6f\n', min_uideal,     max_uideal);
    fprintf('u_sat        : %12.6f   %12.6f\n', min_usat,       max_usat);
    fprintf('Integrator   : %12.6f   %12.6f\n', min_intacc,     max_intacc);
    disp('=============================================')

    evalin('base','clear PRINT_CONTROLLER_RANGE');

end

end