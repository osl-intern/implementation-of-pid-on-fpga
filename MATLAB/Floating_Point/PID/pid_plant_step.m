

function [u_sat,u_ideal,P,I,D,int_sum,error] = pid_plant_step(sp,y,Ts,ff)

persistent int_acc e_prev

%-------------------------------------------------------
% Range Tracking Variables
%-------------------------------------------------------

persistent min_error max_error
persistent min_derivative max_derivative
persistent min_P max_P
persistent min_I max_I
persistent min_D max_D
persistent min_FF max_FF
persistent min_uideal max_uideal
persistent min_usat max_usat
persistent min_intacc max_intacc

%-------------------------------------------------------
% Minimum Non-Zero Tracking
%-------------------------------------------------------

persistent min_nz_error
persistent min_nz_derivative
persistent min_nz_P
persistent min_nz_I
persistent min_nz_D
persistent min_nz_FF
persistent min_nz_uideal
persistent min_nz_usat
persistent min_nz_intacc

%-------------------------------------------------------
% History Buffers
%-------------------------------------------------------

persistent error_hist
persistent derivative_hist
persistent P_hist
persistent I_hist
persistent D_hist
persistent FF_hist
persistent uideal_hist
persistent usat_hist
persistent intacc_hist

if isempty(int_acc)

    int_acc = 0;
    e_prev  = sp;

    %--------------------------------------------
    % Range Initialization
    %--------------------------------------------

    min_error = inf;      max_error = -inf;
    min_derivative = inf; max_derivative = -inf;
    min_P = inf;          max_P = -inf;
    min_I = inf;          max_I = -inf;
    min_D = inf;          max_D = -inf;
    min_FF = inf;         max_FF = -inf;
    min_uideal = inf;     max_uideal = -inf;
    min_usat = inf;       max_usat = -inf;
    min_intacc = inf;     max_intacc = -inf;

    %--------------------------------------------
    % Minimum Non-Zero Initialization
    %--------------------------------------------

    min_nz_error = inf;
    min_nz_derivative = inf;
    min_nz_P = inf;
    min_nz_I = inf;
    min_nz_D = inf;
    min_nz_FF = inf;
    min_nz_uideal = inf;
    min_nz_usat = inf;
    min_nz_intacc = inf;

    %--------------------------------------------
    % History Buffers
    %--------------------------------------------

    error_hist = [];
    derivative_hist = [];
    P_hist = [];
    I_hist = [];
    D_hist = [];
    FF_hist = [];
    uideal_hist = [];
    usat_hist = [];
    intacc_hist = [];

end

%---------------------------------------------------
% PID gains
%---------------------------------------------------

Kp = 5.0;
Ki = 1000;
Kd = 20e-6;
Kd_eff = Kd / Ts;

% Feedforward gain
Kff = 0.00303659398497415;

kt = 1.27724632452934e-06;

% Saturation limit
u_max = 2047;

%---------------------------------------------------
% Controller (UNCHANGED)
%---------------------------------------------------

error = sp - y;

derivative = error - e_prev;

P = Kp * error;

I = Ki * int_acc;

D = Kd_eff * derivative;

FF = Kff * ff;

u_ideal = P + I + D + FF;

% Output saturation only
u_sat = max(min(u_ideal, u_max), -u_max);

sat_error = u_sat - u_ideal;

int_acc = int_acc ...
        + Ts * error ...
        + kt * sat_error;

int_sum = int_acc;

e_prev = error;

%---------------------------------------------------
% Range Tracking (UNCHANGED CONTROLLER)
%---------------------------------------------------

min_error = min(min_error,error);
max_error = max(max_error,error);

min_derivative = min(min_derivative,derivative);
max_derivative = max(max_derivative,derivative);

min_P = min(min_P,P);
max_P = max(max_P,P);

min_I = min(min_I,I);
max_I = max(max_I,I);

min_D = min(min_D,D);
max_D = max(max_D,D);

min_FF = min(min_FF,FF);
max_FF = max(max_FF,FF);

min_uideal = min(min_uideal,u_ideal);
max_uideal = max(max_uideal,u_ideal);

min_usat = min(min_usat,u_sat);
max_usat = max(max_usat,u_sat);

min_intacc = min(min_intacc,int_acc);
max_intacc = max(max_intacc,int_acc);

%---------------------------------------------------
% Minimum Non-Zero Tracking
%---------------------------------------------------

if error ~= 0
    min_nz_error = min(min_nz_error,abs(error));
end

if derivative ~= 0
    min_nz_derivative = min(min_nz_derivative,abs(derivative));
end

if P ~= 0
    min_nz_P = min(min_nz_P,abs(P));
end

if I ~= 0
    min_nz_I = min(min_nz_I,abs(I));
end

if D ~= 0
    min_nz_D = min(min_nz_D,abs(D));
end

if FF ~= 0
    min_nz_FF = min(min_nz_FF,abs(FF));
end

if u_ideal ~= 0
    min_nz_uideal = min(min_nz_uideal,abs(u_ideal));
end

if u_sat ~= 0
    min_nz_usat = min(min_nz_usat,abs(u_sat));
end

if int_acc ~= 0
    min_nz_intacc = min(min_nz_intacc,abs(int_acc));
end

%---------------------------------------------------
% Store Histories
%---------------------------------------------------

error_hist(end+1)      = error;

derivative_hist(end+1) = derivative;

P_hist(end+1)          = P;

I_hist(end+1)          = I;

D_hist(end+1)          = D;

FF_hist(end+1)         = FF;

uideal_hist(end+1)     = u_ideal;

usat_hist(end+1)       = u_sat;

intacc_hist(end+1)     = int_acc;

%---------------------------------------------------
% Print Once at End (Triggered from Testbench)
%---------------------------------------------------

if evalin('base','exist(''PRINT_CONTROLLER_RANGE'',''var'')')

    fprintf('\n');
    disp('================ FIXED-POINT ANALYSIS ================')
    fprintf('%-15s %15s %15s %18s\n','Variable','Minimum','Maximum','Min Non-Zero');
    disp('------------------------------------------------------')

    fprintf('%-15s %15.6f %15.6f %18.12f\n','Error', ...
        min_error,max_error,min_nz_error);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','Derivative', ...
        min_derivative,max_derivative,min_nz_derivative);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','P', ...
        min_P,max_P,min_nz_P);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','I', ...
        min_I,max_I,min_nz_I);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','D', ...
        min_D,max_D,min_nz_D);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','FF', ...
        min_FF,max_FF,min_nz_FF);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','u_ideal', ...
        min_uideal,max_uideal,min_nz_uideal);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','u_sat', ...
        min_usat,max_usat,min_nz_usat);

    fprintf('%-15s %15.6f %15.6f %18.12f\n','Integrator', ...
        min_intacc,max_intacc,min_nz_intacc);

    disp('======================================================')

    %==================================================
    % Plots
    %==================================================

    figure('Name','Error');
    plot(error_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('Error');
    title('Error');

    figure('Name','Derivative');
    plot(derivative_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('Derivative');
    title('Derivative');

    figure('Name','P Term');
    plot(P_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('P');
    title('Proportional Term');

    figure('Name','I Term');
    plot(I_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('I');
    title('Integral Term');

    figure('Name','D Term');
    plot(D_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('D');
    title('Derivative Term');

    figure('Name','Feedforward');
    plot(FF_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('FF');
    title('Feedforward Term');

    figure('Name','Ideal Control');
    plot(uideal_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('u_{ideal}');
    title('Unsaturated Controller Output');

    figure('Name','Saturated Control');
    plot(usat_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('u_{sat}');
    title('Saturated Controller Output');

    figure('Name','Integrator Accumulator');
    plot(intacc_hist,'LineWidth',1.2);
    grid on;
    xlabel('Sample');
    ylabel('Accumulator');
    title('Integrator Accumulator');

    evalin('base','clear PRINT_CONTROLLER_RANGE');

end

end