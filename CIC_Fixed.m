function [comb_out,y,cic_valid] = CIC_Fixed(x,adc_valid)

%===========================================================
%
% CIC_Fixed.m
%
% 5-Stage CIC
%
% Integrator
% Decimation
% Comb
% Normalization
%
% Fixed-Point FPGA Model
%
%===========================================================

%% ==========================================================
% Fixed-Point Math
%% ==========================================================

persistent F

if isempty(F)

    F = fimath( ...
        'RoundingMethod','Nearest', ...
        'OverflowAction','Saturate', ...
        'ProductMode','FullPrecision', ...
        'SumMode','FullPrecision');

end

%% ==========================================================
% CIC Parameters
%% ==========================================================

R = 21;

GAIN = 21^5;

%% ==========================================================
% Word Lengths
%% ==========================================================

% ADC Input

WL_ADC = 16;

% Integrators

WL_INT1 = 27+2;
WL_INT2 = 40+2;
WL_INT3 = 53+2;
WL_INT4 = 66+2;
WL_INT5 = 77+2;

% Comb Registers

WL_COMB1 = 69+2;
WL_COMB2 = 61+2;
WL_COMB3 = 53+2;
WL_COMB4 = 44+2;
WL_COMB5 = 38+2;

% Gain Inverse

WL_GAIN = 32;
FL_GAIN = 30;

% Normalized Output

WL_OUT = 31;
FL_OUT = 14;

%% ==========================================================
% Numeric Types
%% ==========================================================

T_ADC = numerictype(1,WL_ADC,0);

T_INT1 = numerictype(1,WL_INT1,0);
T_INT2 = numerictype(1,WL_INT2,0);
T_INT3 = numerictype(1,WL_INT3,0);
T_INT4 = numerictype(1,WL_INT4,0);
T_INT5 = numerictype(1,WL_INT5,0);

T_COMB1 = numerictype(1,WL_COMB1,0);
T_COMB2 = numerictype(1,WL_COMB2,0);
T_COMB3 = numerictype(1,WL_COMB3,0);
T_COMB4 = numerictype(1,WL_COMB4,0);
T_COMB5 = numerictype(1,WL_COMB5,0);

T_GAIN = numerictype(1,WL_GAIN,FL_GAIN);

T_OUT = numerictype(1,WL_OUT,FL_OUT);

%% ==========================================================
% Registers
%% ==========================================================

persistent int1 int2 int3 int4 int5

persistent d1 d2 d3 d4 d5

persistent dec_counter

persistent norm_out

persistent gain_inv

persistent int1_hist int2_hist int3_hist int4_hist int5_hist
persistent comb1_hist comb2_hist comb3_hist comb4_hist comb5_hist

persistent int_idx
persistent comb_idx
%% ==========================================================
% Initialization
%% ==========================================================

if isempty(int1)

    int1 = fi(0,T_INT1,F);
    int2 = fi(0,T_INT2,F);
    int3 = fi(0,T_INT3,F);
    int4 = fi(0,T_INT4,F);
    int5 = fi(0,T_INT5,F);

    d1 = fi(0,T_COMB1,F);
    d2 = fi(0,T_COMB2,F);
    d3 = fi(0,T_COMB3,F);
    d4 = fi(0,T_COMB4,F);
    d5 = fi(0,T_COMB5,F);

    dec_counter = 0;

    norm_out = fi(0,T_OUT,F);

    gain_inv = fi(1/GAIN,T_GAIN,F);

    fprintf('\n');
    fprintf('Ideal Gain Inverse      = %.15f\n',1/GAIN);
    fprintf('Quantized Gain Inverse  = %.15f\n',double(gain_inv));
    fprintf('Gain Error             = %.15e\n',double(gain_inv)-1/GAIN);
    fprintf('\n');

    int1_hist = [];
    int2_hist = [];
    int3_hist = [];
    int4_hist = [];
    int5_hist = [];

    comb1_hist = [];
    comb2_hist = [];
    comb3_hist = [];
    comb4_hist = [];
    comb5_hist = [];

    int_idx = 0;
    comb_idx = 0;

end

if ~adc_valid

    cic_valid = false;

    comb_out = 0;

    y = double(norm_out);

    return;

end

%% ==========================================================
% ADC Input
%% ==========================================================

adc_in = fi(double(x),T_ADC,F);

%% ==========================================================
% Integrator 1
%% ==========================================================

int1_full = int1 + adc_in;
int1 = fi(int1_full,T_INT1,F);

%% ==========================================================
% Integrator 2
%% ==========================================================

int2_full = int2 + int1;
int2 = fi(int2_full,T_INT2,F);

%% ==========================================================
% Integrator 3
%% ==========================================================

int3_full = int3 + int2;
int3 = fi(int3_full,T_INT3,F);

%% ==========================================================
% Integrator 4
%% ==========================================================

int4_full = int4 + int3;
int4 = fi(int4_full,T_INT4,F);

%% ==========================================================
% Integrator 5
%% ==========================================================

int5_full = int5 + int4;
int5 = fi(int5_full,T_INT5,F);

int_idx = int_idx + 1;

int1_hist(int_idx) = double(int1);
int2_hist(int_idx) = double(int2);
int3_hist(int_idx) = double(int3);
int4_hist(int_idx) = double(int4);
int5_hist(int_idx) = double(int5);

%% ==========================================================
% Decimation
%% ==========================================================

dec_counter = dec_counter + 1;

if dec_counter < R

    cic_valid = false;

    comb_out = 0;

    y = double(norm_out);

    return;

end

%----------------------------------------------------------
% Generate One Output Sample
%----------------------------------------------------------

dec_counter = 0;

decimated_sample = int5;

%% ==========================================================
% Comb 1
%% ==========================================================

comb1_full = decimated_sample - d1;

comb1 = fi(comb1_full,T_COMB1,F);

d1 = fi(decimated_sample,T_COMB1,F);

%% ==========================================================
% Comb 2
%% ==========================================================

comb2_full = comb1 - d2;

comb2 = fi(comb2_full,T_COMB2,F);

d2 = fi(comb1,T_COMB2,F);

%% ==========================================================
% Comb 3
%% ==========================================================

comb3_full = comb2 - d3;

comb3 = fi(comb3_full,T_COMB3,F);

d3 = fi(comb2,T_COMB3,F);

%% ==========================================================
% Comb 4
%% ==========================================================

comb4_full = comb3 - d4;

comb4 = fi(comb4_full,T_COMB4,F);

d4 = fi(comb3,T_COMB4,F);

%% ==========================================================
% Comb 5
%% ==========================================================

comb5_full = comb4 - d5;

comb5 = fi(comb5_full,T_COMB5,F);

comb_idx = comb_idx + 1;

comb1_hist(comb_idx) = double(comb1_full);
comb2_hist(comb_idx) = double(comb2_full);
comb3_hist(comb_idx) = double(comb3_full);
comb4_hist(comb_idx) = double(comb4_full);
comb5_hist(comb_idx) = double(comb5_full);

d5 = fi(comb4,T_COMB5,F);

comb_out = double(comb5_full);

%% ==========================================================
% Normalization
%% ==========================================================

norm_full = comb5 * gain_inv;

norm_out = fi(norm_full,T_OUT,F);

cic_valid = true;

%% ==========================================================
% Print Fixed-Point Specification
%% ==========================================================

if evalin('base','exist(''PRINT_CIC_FIXED_SPEC'',''var'')')

    fprintf('\n');

    disp('=============== CIC FIXED-POINT SPECIFICATION ===============');

    fprintf('%-28s Q15.0 (16 bits)\n','ADC Output');

fprintf('%-28s Q28.0 (29 bits)\n','Integrator 1 Register');
fprintf('%-28s Q41.0 (42 bits)\n','Integrator 2 Register');
fprintf('%-28s Q54.0 (55 bits)\n','Integrator 3 Register');
fprintf('%-28s Q67.0 (68 bits)\n','Integrator 4 Register');
fprintf('%-28s Q78.0 (79 bits)\n','Integrator 5 Register');

fprintf('%-28s Q78.0 (79 bits)\n','Decimation Register');

fprintf('%-28s Q70.0 (71 bits)\n','Comb 1 Register');
fprintf('%-28s Q62.0 (63 bits)\n','Comb 2 Register');
fprintf('%-28s Q54.0 (55 bits)\n','Comb 3 Register');
fprintf('%-28s Q45.0 (46 bits)\n','Comb 4 Register');
fprintf('%-28s Q39.0 (40 bits)\n','Comb 5 Register');

    fprintf('%-28s Q16.14 (31 bits)\n','Normalization Output');

    disp('============================================================');

    figure;
    plot(int1_hist,'LineWidth',1); hold on;
    plot(int2_hist,'LineWidth',1);
    plot(int3_hist,'LineWidth',1);
    plot(int4_hist,'LineWidth',1);
    plot(int5_hist,'LineWidth',1);
    grid on;
    legend('Int1','Int2','Int3','Int4','Int5');
    title('Integrator Outputs');

    figure;
    plot(comb1_hist,'LineWidth',1); hold on;
    plot(comb2_hist,'LineWidth',1);
    plot(comb3_hist,'LineWidth',1);
    plot(comb4_hist,'LineWidth',1);
    plot(comb5_hist,'LineWidth',1);
    grid on;
    legend('Comb1','Comb2','Comb3','Comb4','Comb5');
    title('Comb Outputs');

    evalin('base','clear PRINT_CIC_FIXED_SPEC');

end

%% ==========================================================
% Return Output
%% ==========================================================

y = double(norm_out);

end