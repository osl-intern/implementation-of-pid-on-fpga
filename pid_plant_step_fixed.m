function [u_sat,u_ideal,P,I,D,int_sum,error,pid_valid] = ...
            pid_plant_step_fixed(sp,y,Ts,ff,fir_valid)

%% ==========================================================
% Fixed-Point PID Controller
% Version 1.0
%% ==========================================================

persistent int_acc
persistent e_prev
%% ==========================================================
% Range Tracking Variables
%% ==========================================================

persistent min_error max_error
persistent min_derivative max_derivative
persistent min_P max_P
persistent min_I max_I
persistent min_D max_D
persistent min_FF max_FF
persistent min_uideal max_uideal
persistent min_usat max_usat
persistent min_intacc max_intacc

persistent min_nz_error
persistent min_nz_derivative
persistent min_nz_P
persistent min_nz_I
persistent min_nz_D
persistent min_nz_FF
persistent min_nz_uideal
persistent min_nz_usat
persistent min_nz_intacc

%% ==========================================================
% History Buffers
%% ==========================================================

persistent error_hist
persistent derivative_hist
persistent P_hist
persistent I_hist
persistent D_hist
persistent FF_hist
persistent uideal_hist
persistent usat_hist
persistent intacc_hist



%% ==========================================================
% Fixed-Point Math
%% ==========================================================

F = fimath( ...
    'RoundingMethod','Nearest', ...
    'OverflowAction','Saturate', ...
    'ProductMode','FullPrecision', ...
    'SumMode','FullPrecision');

%% ==========================================================
% Word Length Definitions
%% ==========================================================

%-----------------------------
% Controller Signals
%-----------------------------

WL_ERR      = 23;     FL_ERR      = 6;

WL_DER      = 27;     FL_DER      = 14;

WL_P         = 26;    FL_P         = 7;

WL_INTACC    = 26;    FL_INTACC    = 20;

WL_I         = 25;    FL_I         = 8;

WL_D         = 27;    FL_D         = 10;

WL_FF        = 20;    FL_FF        = 14;

WL_CTRL      = 27;    FL_CTRL      = 8;

WL_USAT      = 20;    FL_USAT      = 8;

%% ==========================================================
% Intermediate Adders
%% ==========================================================

WL_SUM1      = 31;    FL_SUM1      = 10;

WL_SUM2      = 32;    FL_SUM2      = 10;

WL_SUM3      = 32;    FL_SUM3      = 10;

WL_ISUM1     = 27;    FL_ISUM1     = 20;

WL_ISUM2     = 27;    FL_ISUM2     = 20;

%% ==========================================================
% Constants
%% ==========================================================

WL_KP        = 18;    FL_KP        = 14;

WL_KI        = 21;    FL_KI        = 10;

WL_KD        = 20;    FL_KD        = 14;

WL_KFF       = 22;    FL_KFF       = 20;

WL_KT        = 31;    FL_KT        = 30;

WL_TS        = 32;    FL_TS        = 30;

%% ==========================================================
% Fixed-Point Constants
%% ==========================================================

persistent Kp_fix
persistent Ki_fix
persistent Kd_fix
persistent Kff_fix
persistent kt_fix
persistent Ts_fix
persistent u_max_fix

%% ==========================================================
% Initialization
%% ==========================================================

if isempty(int_acc)

    
    %----------------------------------
    % Controller States
    %----------------------------------

    int_acc = fi(0,1,WL_INTACC,FL_INTACC,F);

    e_prev  = fi(sp,1,WL_ERR,FL_ERR,F);

    %----------------------------------
    % Quantized Constants
    %----------------------------------

    Kp_fix = fi(5.0,...
        1,...
        WL_KP,...
        FL_KP,...
        F);

    Ki_fix = fi(1000,...
        1,...
        WL_KI,...
        FL_KI,...
        F);

    Kd_fix = fi(20e-6/Ts,...
        1,...
        WL_KD,...
        FL_KD,...
        F);

    Kff_fix = fi(0.00303659398497415,...
        1,...
        WL_KFF,...
        FL_KFF,...
        F);

    kt_fix = fi(1.27724632452934e-06,...
        1,...
        WL_KT,...
        FL_KT,...
        F);

    Ts_fix = fi(Ts,...
        1,...
        WL_TS,...
        FL_TS,...
        F);

   u_max_fix = fi(2047,1,WL_USAT,FL_USAT,F);
   %% ==========================================================
   % Range Initialization
   %% ==========================================================

   min_error = inf;      max_error = -inf;
   min_derivative = inf; max_derivative = -inf;
   min_P = inf;          max_P = -inf;
   min_I = inf;          max_I = -inf;
   min_D = inf;          max_D = -inf;
   min_FF = inf;         max_FF = -inf;
   min_uideal = inf;     max_uideal = -inf;
   min_usat = inf;       max_usat = -inf;
   min_intacc = inf;     max_intacc = -inf;

   %% ==========================================================
   % Minimum Non-Zero Initialization
   %% ==========================================================

   min_nz_error = inf;
   min_nz_derivative = inf;
   min_nz_P = inf;
   min_nz_I = inf;
   min_nz_D = inf;
   min_nz_FF = inf;
   min_nz_uideal = inf;
   min_nz_usat = inf;
   min_nz_intacc = inf;

   %% ==========================================================
   % History Buffers
   %% ==========================================================

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

%% ==========================================================
% Input Quantization
%% ==========================================================


sp_fix = fi(sp,...
    1,...
    WL_ERR,...
    FL_ERR,...
    F);

y_fix = fi(y,...
    1,...
    WL_ERR,...
    FL_ERR,...
    F);

ff_fix = fi(ff,...
    1,...
    WL_ERR,...
    FL_ERR,...
    F);

persistent last_u_sat
persistent last_u_ideal
persistent last_P
persistent last_I
persistent last_D
persistent last_error
persistent last_int

if isempty(last_u_sat)

last_u_sat   = fi(0,1,WL_USAT,FL_USAT,F);
last_u_ideal = fi(0,1,WL_CTRL,FL_CTRL,F);
last_P       = fi(0,1,WL_P,FL_P,F);
last_I       = fi(0,1,WL_I,FL_I,F);
last_D       = fi(0,1,WL_D,FL_D,F);
last_error   = fi(0,1,WL_ERR,FL_ERR,F);
last_int     = fi(0,1,WL_INTACC,FL_INTACC,F);

end

if ~fir_valid

    u_sat   = last_u_sat;
    u_ideal = last_u_ideal;
    P       = last_P;
    I       = last_I;
    D       = last_D;
    error   = last_error;
    int_sum = last_int;

    pid_valid = false;

    return;

end

pid_valid = true;

%% ==========================================================
% Error
%% ==========================================================

error_full = sp_fix - y_fix;

error = fi(error_full,...
    1,...
    WL_ERR,...
    FL_ERR,...
    F);

%% ==========================================================
% Derivative
%% ==========================================================

derivative_full = error - e_prev;

derivative = fi(derivative_full,...
    1,...
    WL_DER,...
    FL_DER,...
    F);

%% ==========================================================
% Proportional Path
%% ==========================================================

P_full = Kp_fix * error;

P = fi(P_full,...
    1,...
    WL_P,...
    FL_P,...
    F);

%% ==========================================================
% Integral Path
%% ==========================================================

I_full = Ki_fix * int_acc;

I = fi(I_full,...
    1,...
    WL_I,...
    FL_I,...
    F);

%% ==========================================================
% Derivative Path
%% ==========================================================

D_full = Kd_fix * derivative;

D = fi(D_full,...
    1,...
    WL_D,...
    FL_D,...
    F);

%% ==========================================================
% Feedforward Path
%% ==========================================================

FF_full = Kff_fix * ff_fix;

FF = fi(FF_full,...
    1,...
    WL_FF,...
    FL_FF,...
    F);

%% ==========================================================
% Controller Summation
%% ==========================================================

%--------------------------
% P + I
%--------------------------

sum1_full = P + I;

sum1 = fi(sum1_full,...
    1,...
    WL_SUM1,...
    FL_SUM1,...
    F);

%--------------------------
% (P+I) + D
%--------------------------

sum2_full = sum1 + D;

sum2 = fi(sum2_full,...
    1,...
    WL_SUM2,...
    FL_SUM2,...
    F);

%--------------------------
% ((P+I)+D) + FF
%--------------------------

sum3_full = sum2 + FF;

sum3 = fi(sum3_full,...
    1,...
    WL_SUM3,...
    FL_SUM3,...
    F);

%% ==========================================================
% Unsaturated Controller Output
%% ==========================================================

u_ideal = fi(sum3,...
    1,...
    WL_CTRL,...
    FL_CTRL,...
    F);

%% ==========================================================
% Output Saturation
%% ==========================================================

if u_ideal > u_max_fix

    u_sat = fi(u_max_fix,...
        1,...
        WL_USAT,...
        FL_USAT,...
        F);

elseif u_ideal < -u_max_fix

    u_sat = fi(-u_max_fix,...
        1,...
        WL_USAT,...
        FL_USAT,...
        F);

else

    u_sat = fi(u_ideal,...
        1,...
        WL_USAT,...
        FL_USAT,...
        F);

end

%% ==========================================================
% Anti-Windup Error
%% ==========================================================

sat_error_full = u_sat - u_ideal;

sat_error = fi(sat_error_full,...
    1,...
    WL_CTRL,...
    FL_CTRL,...
    F);

%% ==========================================================
% Integrator Update
%% ==========================================================

%--------------------------
% Ts × Error
%--------------------------

prod1_full = Ts_fix * error;

prod1 = fi(prod1_full,...
    1,...
    WL_INTACC,...
    FL_INTACC,...
    F);

%--------------------------
% kt × sat_error
%--------------------------

prod2_full = kt_fix * sat_error;

prod2 = fi(prod2_full,...
    1,...
    WL_INTACC,...
    FL_INTACC,...
    F);

%--------------------------
% int_acc + prod1
%--------------------------

sumI1_full = int_acc + prod1;

sumI1 = fi(sumI1_full,...
    1,...
    WL_ISUM1,...
    FL_ISUM1,...
    F);

%--------------------------
% sumI1 + prod2
%--------------------------

sumI2_full = sumI1 + prod2;

int_acc = fi(sumI2_full,...
    1,...
    WL_INTACC,...
    FL_INTACC,...
    F);

%% ==========================================================
% Outputs
%% ==========================================================

int_sum = int_acc;
last_u_sat   = u_sat;
last_u_ideal = u_ideal;
last_P       = P;
last_I       = I;
last_D       = D;
last_error   = error;
last_int     = int_sum;

e_prev = error;
%% ==========================================================
% Range Tracking
%% ==========================================================

min_error = min(min_error,double(error));
max_error = max(max_error,double(error));

min_derivative = min(min_derivative,double(derivative));
max_derivative = max(max_derivative,double(derivative));

min_P = min(min_P,double(P));
max_P = max(max_P,double(P));

min_I = min(min_I,double(I));
max_I = max(max_I,double(I));

min_D = min(min_D,double(D));
max_D = max(max_D,double(D));

min_FF = min(min_FF,double(FF));
max_FF = max(max_FF,double(FF));

min_uideal = min(min_uideal,double(u_ideal));
max_uideal = max(max_uideal,double(u_ideal));

min_usat = min(min_usat,double(u_sat));
max_usat = max(max_usat,double(u_sat));

min_intacc = min(min_intacc,double(int_acc));
max_intacc = max(max_intacc,double(int_acc));

%% ==========================================================
% Minimum Non-Zero Tracking
%% ==========================================================

if double(error)~=0
    min_nz_error=min(min_nz_error,abs(double(error)));
end

if double(derivative)~=0
    min_nz_derivative=min(min_nz_derivative,abs(double(derivative)));
end

if double(P)~=0
    min_nz_P=min(min_nz_P,abs(double(P)));
end

if double(I)~=0
    min_nz_I=min(min_nz_I,abs(double(I)));
end

if double(D)~=0
    min_nz_D=min(min_nz_D,abs(double(D)));
end

if double(FF)~=0
    min_nz_FF=min(min_nz_FF,abs(double(FF)));
end

if double(u_ideal)~=0
    min_nz_uideal=min(min_nz_uideal,abs(double(u_ideal)));
end

if double(u_sat)~=0
    min_nz_usat=min(min_nz_usat,abs(double(u_sat)));
end

if double(int_acc)~=0
    min_nz_intacc=min(min_nz_intacc,abs(double(int_acc)));
end

%% ==========================================================
% History Buffers
%% ==========================================================

error_hist(end+1)=double(error);

derivative_hist(end+1)=double(derivative);

P_hist(end+1)=double(P);

I_hist(end+1)=double(I);

D_hist(end+1)=double(D);

FF_hist(end+1)=double(FF);

uideal_hist(end+1)=double(u_ideal);

usat_hist(end+1)=double(u_sat);

intacc_hist(end+1)=double(int_acc);

%% ==========================================================
% Print Once at End
%% ==========================================================

if evalin('base','exist(''PRINT_CONTROLLER_RANGE'',''var'')')

    fprintf('\n');

    disp('================ FIXED-POINT ANALYSIS ================')
    fprintf('%-15s %-10s %15s %15s %18s\n',...
        'Variable','Q Format','Minimum','Maximum','Min Non-Zero');
    disp('--------------------------------------------------------------------------')

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'Error','Q17.6',...
        min_error,max_error,min_nz_error);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'Derivative','Q13.14',...
        min_derivative,max_derivative,min_nz_derivative);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'P','Q19.7',...
        min_P,max_P,min_nz_P);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'I','Q17.8',...
        min_I,max_I,min_nz_I);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'D','Q17.10',...
        min_D,max_D,min_nz_D);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'FF','Q6.14',...
        min_FF,max_FF,min_nz_FF);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'u_ideal','Q19.8',...
        min_uideal,max_uideal,min_nz_uideal);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'u_sat','Q12.8',...
        min_usat,max_usat,min_nz_usat);

    fprintf('%-15s %-10s %15.6f %15.6f %18.12f\n',...
        'Integrator','Q6.20',...
        min_intacc,max_intacc,min_nz_intacc);

    disp('==========================================================================')

    fprintf('\n');
    disp('============== FIXED-POINT SPECIFICATION =================')

    fprintf('Error               : Q17.6\n');
    fprintf('Derivative          : Q13.14\n');
    fprintf('P Term              : Q19.7\n');
    fprintf('Integrator Acc      : Q6.20\n');
    fprintf('Integral Term       : Q17.8\n');
    fprintf('Derivative Term     : Q17.10\n');
    fprintf('Feedforward         : Q6.14\n');
    fprintf('Unsaturated Output  : Q19.8\n');
    fprintf('Saturated Output    : Q12.8\n');

    disp('==========================================================')

    %% ==========================================================
    % Plots
    %% ==========================================================

    figure('Name','Fixed Point : Error');
    plot(error_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('Error');
    title('Error');

    figure('Name','Fixed Point : Derivative');
    plot(derivative_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('Derivative');
    title('Derivative');

    figure('Name','Fixed Point : P Term');
    plot(P_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('P');
    title('Proportional Term');

    figure('Name','Fixed Point : I Term');
    plot(I_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('I');
    title('Integral Term');

    figure('Name','Fixed Point : D Term');
    plot(D_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('D');
    title('Derivative Term');

    figure('Name','Fixed Point : Feedforward');
    plot(FF_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('FF');
    title('Feedforward');

    figure('Name','Fixed Point : Unsaturated Output');
    plot(uideal_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('u_{ideal}');
    title('Unsaturated Controller Output');

    figure('Name','Fixed Point : Saturated Output');
    plot(usat_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('u_{sat}');
    title('Saturated Controller Output');

    figure('Name','Fixed Point : Integrator');
    plot(intacc_hist,'LineWidth',1.5);
    grid on;
    xlabel('Sample');
    ylabel('Integrator');
    title('Integrator Accumulator');

    %% ==========================================================
    % Clear Trigger Variable
    %% ==========================================================

    evalin('base','clear PRINT_CONTROLLER_RANGE');

end

u_sat_out   = double(u_sat);
u_ideal_out = double(u_ideal);
P_out       = double(P);
I_out       = double(I);
D_out       = double(D);
int_sum_out = double(int_sum);
error_out   = double(error);

u_sat   = u_sat_out;
u_ideal = u_ideal_out;
P       = P_out;
I       = I_out;
D       = D_out;
int_sum = int_sum_out;
error   = error_out;