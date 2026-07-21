function [y,fir_valid] = FIR_Filter_Fixed(x,cic_valid)

%==============================================================
% 45-Tap Symmetric Fixed-Point FIR
%
% Architecture
% ------------
% 45 Delay Registers
% 22 Pair Adders
% 23 Multipliers
% Wide Accumulator
%
%==============================================================

%% ==========================================================
% Fixed Point Math
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
% Word Lengths
%% ==========================================================

% FIR Input

WL_IN     = 31;
FL_IN     = 14;

% Pair Sum

WL_PAIR   = 32;
FL_PAIR   = 14;

% Coefficient

WL_COEFF  = 18;
FL_COEFF  = 16;

% Product

WL_PROD   = 50;
FL_PROD   = 30;

% Accumulator

WL_ACC    = 55;
FL_ACC    = 30;

% FIR Output

WL_OUT    = 31;
FL_OUT    = 14;

%% ==========================================================
% Numerictype
%% ==========================================================

T_IN      = numerictype(1,WL_IN,FL_IN);

T_PAIR    = numerictype(1,WL_PAIR,FL_PAIR);

T_COEFF   = numerictype(1,WL_COEFF,FL_COEFF);

T_PROD    = numerictype(1,WL_PROD,FL_PROD);

T_ACC     = numerictype(1,WL_ACC,FL_ACC);

T_OUT     = numerictype(1,WL_OUT,FL_OUT);

%% ==========================================================
% Persistent Variables
%% ==========================================================

persistent delayLine

persistent coeff0 coeff1 coeff2 coeff3 coeff4
persistent coeff5 coeff6 coeff7 coeff8 coeff9
persistent coeff10 coeff11 coeff12 coeff13 coeff14
persistent coeff15 coeff16 coeff17 coeff18 coeff19
persistent coeff20 coeff21 coeff22

%% ==========================================================
% Range Tracking
%% ==========================================================

persistent min_in max_in
persistent min_out max_out

persistent min_nz_in
persistent min_nz_out
persistent last_output

if isempty(last_output)

    last_output = 0;

end

%% ==========================================================
% Initialization
%% ==========================================================

if isempty(delayLine)

    %-----------------------------------------
    % Delay Line
    %-----------------------------------------

    delayLine = fi(zeros(45,1),T_IN,F);

    %-----------------------------------------
    % Quantized FIR Coefficients (Q2.16)
    %-----------------------------------------

    coeff0  = fi(-4    /2^16,T_COEFF,F);
    coeff1  = fi(12    /2^16,T_COEFF,F);
    coeff2  = fi(54    /2^16,T_COEFF,F);
    coeff3  = fi(116   /2^16,T_COEFF,F);
    coeff4  = fi(155   /2^16,T_COEFF,F);

    coeff5  = fi(104   /2^16,T_COEFF,F);
    coeff6  = fi(-79   /2^16,T_COEFF,F);
    coeff7  = fi(-341  /2^16,T_COEFF,F);
    coeff8  = fi(-519  /2^16,T_COEFF,F);
    coeff9  = fi(-404  /2^16,T_COEFF,F);

    coeff10 = fi(98    /2^16,T_COEFF,F);
    coeff11 = fi(825   /2^16,T_COEFF,F);
    coeff12 = fi(1334  /2^16,T_COEFF,F);
    coeff13 = fi(1114  /2^16,T_COEFF,F);
    coeff14 = fi(-63   /2^16,T_COEFF,F);

    coeff15 = fi(-1827 /2^16,T_COEFF,F);
    coeff16 = fi(-3190 /2^16,T_COEFF,F);
    coeff17 = fi(-2930 /2^16,T_COEFF,F);
    coeff18 = fi(-250  /2^16,T_COEFF,F);
    coeff19 = fi(4650  /2^16,T_COEFF,F);

    coeff20 = fi(10437 /2^16,T_COEFF,F);
    coeff21 = fi(15115 /2^16,T_COEFF,F);
    coeff22 = fi(16910 /2^16,T_COEFF,F);

    %-----------------------------------------
    % Range Tracking
    %-----------------------------------------

    min_in = inf;
    max_in = -inf;

    min_out = inf;
    max_out = -inf;

    min_nz_in = inf;
    min_nz_out = inf;

end

%% ==========================================================
% Input Quantization
%% ==========================================================

x_fix = fi(x,T_IN,F);

%% ==========================================================
% Shift Register
%% ==========================================================


if ~cic_valid

    fir_valid = false;
    y = last_output;
    return;

end

delayLine(2:45)=delayLine(1:44);

delayLine(1)=x_fix;

%% ==========================================================
% Delay Line Mapping
%% ==========================================================

x0  = delayLine(1);
x1  = delayLine(2);
x2  = delayLine(3);
x3  = delayLine(4);
x4  = delayLine(5);
x5  = delayLine(6);
x6  = delayLine(7);
x7  = delayLine(8);
x8  = delayLine(9);
x9  = delayLine(10);

x10 = delayLine(11);
x11 = delayLine(12);
x12 = delayLine(13);
x13 = delayLine(14);
x14 = delayLine(15);
x15 = delayLine(16);
x16 = delayLine(17);
x17 = delayLine(18);
x18 = delayLine(19);
x19 = delayLine(20);

x20 = delayLine(21);
x21 = delayLine(22);
x22 = delayLine(23);

x23 = delayLine(24);
x24 = delayLine(25);
x25 = delayLine(26);
x26 = delayLine(27);
x27 = delayLine(28);
x28 = delayLine(29);
x29 = delayLine(30);

x30 = delayLine(31);
x31 = delayLine(32);
x32 = delayLine(33);
x33 = delayLine(34);
x34 = delayLine(35);
x35 = delayLine(36);
x36 = delayLine(37);
x37 = delayLine(38);
x38 = delayLine(39);
x39 = delayLine(40);

x40 = delayLine(41);
x41 = delayLine(42);
x42 = delayLine(43);
x43 = delayLine(44);
x44 = delayLine(45);

%% ==========================================================
% Symmetric Pair Addition
%% ==========================================================

pair0_full  = x0  + x44;
pair0       = fi(pair0_full,T_PAIR,F);

pair1_full  = x1  + x43;
pair1       = fi(pair1_full,T_PAIR,F);

pair2_full  = x2  + x42;
pair2       = fi(pair2_full,T_PAIR,F);

pair3_full  = x3  + x41;
pair3       = fi(pair3_full,T_PAIR,F);

pair4_full  = x4  + x40;
pair4       = fi(pair4_full,T_PAIR,F);

pair5_full  = x5  + x39;
pair5       = fi(pair5_full,T_PAIR,F);

pair6_full  = x6  + x38;
pair6       = fi(pair6_full,T_PAIR,F);

pair7_full  = x7  + x37;
pair7       = fi(pair7_full,T_PAIR,F);

pair8_full  = x8  + x36;
pair8       = fi(pair8_full,T_PAIR,F);

pair9_full  = x9  + x35;
pair9       = fi(pair9_full,T_PAIR,F);

pair10_full = x10 + x34;
pair10      = fi(pair10_full,T_PAIR,F);

pair11_full = x11 + x33;
pair11      = fi(pair11_full,T_PAIR,F);

pair12_full = x12 + x32;
pair12      = fi(pair12_full,T_PAIR,F);

pair13_full = x13 + x31;
pair13      = fi(pair13_full,T_PAIR,F);

pair14_full = x14 + x30;
pair14      = fi(pair14_full,T_PAIR,F);

pair15_full = x15 + x29;
pair15      = fi(pair15_full,T_PAIR,F);

pair16_full = x16 + x28;
pair16      = fi(pair16_full,T_PAIR,F);

pair17_full = x17 + x27;
pair17      = fi(pair17_full,T_PAIR,F);

pair18_full = x18 + x26;
pair18      = fi(pair18_full,T_PAIR,F);

pair19_full = x19 + x25;
pair19      = fi(pair19_full,T_PAIR,F);

pair20_full = x20 + x24;
pair20      = fi(pair20_full,T_PAIR,F);

pair21_full = x21 + x23;
pair21      = fi(pair21_full,T_PAIR,F);

%% ==========================================================
% Centre Tap
%% ==========================================================

centre = x22;

%% ==========================================================
% Multiplication
%% ==========================================================

prod0_full  = pair0  * coeff0;
prod0       = fi(prod0_full,T_PROD,F);

prod1_full  = pair1  * coeff1;
prod1       = fi(prod1_full,T_PROD,F);

prod2_full  = pair2  * coeff2;
prod2       = fi(prod2_full,T_PROD,F);

prod3_full  = pair3  * coeff3;
prod3       = fi(prod3_full,T_PROD,F);

prod4_full  = pair4  * coeff4;
prod4       = fi(prod4_full,T_PROD,F);

prod5_full  = pair5  * coeff5;
prod5       = fi(prod5_full,T_PROD,F);

prod6_full  = pair6  * coeff6;
prod6       = fi(prod6_full,T_PROD,F);

prod7_full  = pair7  * coeff7;
prod7       = fi(prod7_full,T_PROD,F);

prod8_full  = pair8  * coeff8;
prod8       = fi(prod8_full,T_PROD,F);

prod9_full  = pair9  * coeff9;
prod9       = fi(prod9_full,T_PROD,F);

prod10_full = pair10 * coeff10;
prod10      = fi(prod10_full,T_PROD,F);

prod11_full = pair11 * coeff11;
prod11      = fi(prod11_full,T_PROD,F);

prod12_full = pair12 * coeff12;
prod12      = fi(prod12_full,T_PROD,F);

prod13_full = pair13 * coeff13;
prod13      = fi(prod13_full,T_PROD,F);

prod14_full = pair14 * coeff14;
prod14      = fi(prod14_full,T_PROD,F);

prod15_full = pair15 * coeff15;
prod15      = fi(prod15_full,T_PROD,F);

prod16_full = pair16 * coeff16;
prod16      = fi(prod16_full,T_PROD,F);

prod17_full = pair17 * coeff17;
prod17      = fi(prod17_full,T_PROD,F);

prod18_full = pair18 * coeff18;
prod18      = fi(prod18_full,T_PROD,F);

prod19_full = pair19 * coeff19;
prod19      = fi(prod19_full,T_PROD,F);

prod20_full = pair20 * coeff20;
prod20      = fi(prod20_full,T_PROD,F);

prod21_full = pair21 * coeff21;
prod21      = fi(prod21_full,T_PROD,F);

centre_full = centre * coeff22;
centre_prod = fi(centre_full,T_PROD,F);

%% ==========================================================
% Wide Accumulator
%% ==========================================================

acc0_full = prod0 + prod1;
acc0 = fi(acc0_full,T_ACC,F);

acc1_full = acc0 + prod2;
acc1 = fi(acc1_full,T_ACC,F);

acc2_full = acc1 + prod3;
acc2 = fi(acc2_full,T_ACC,F);

acc3_full = acc2 + prod4;
acc3 = fi(acc3_full,T_ACC,F);

acc4_full = acc3 + prod5;
acc4 = fi(acc4_full,T_ACC,F);

acc5_full = acc4 + prod6;
acc5 = fi(acc5_full,T_ACC,F);

acc6_full = acc5 + prod7;
acc6 = fi(acc6_full,T_ACC,F);

acc7_full = acc6 + prod8;
acc7 = fi(acc7_full,T_ACC,F);

acc8_full = acc7 + prod9;
acc8 = fi(acc8_full,T_ACC,F);

acc9_full = acc8 + prod10;
acc9 = fi(acc9_full,T_ACC,F);

acc10_full = acc9 + prod11;
acc10 = fi(acc10_full,T_ACC,F);

acc11_full = acc10 + prod12;
acc11 = fi(acc11_full,T_ACC,F);

acc12_full = acc11 + prod13;
acc12 = fi(acc12_full,T_ACC,F);

acc13_full = acc12 + prod14;
acc13 = fi(acc13_full,T_ACC,F);

acc14_full = acc13 + prod15;
acc14 = fi(acc14_full,T_ACC,F);

acc15_full = acc14 + prod16;
acc15 = fi(acc15_full,T_ACC,F);

acc16_full = acc15 + prod17;
acc16 = fi(acc16_full,T_ACC,F);

acc17_full = acc16 + prod18;
acc17 = fi(acc17_full,T_ACC,F);

acc18_full = acc17 + prod19;
acc18 = fi(acc18_full,T_ACC,F);

acc19_full = acc18 + prod20;
acc19 = fi(acc19_full,T_ACC,F);

acc20_full = acc19 + prod21;
acc20 = fi(acc20_full,T_ACC,F);

acc21_full = acc20 + centre_prod;
acc21 = fi(acc21_full,T_ACC,F);

%% ==========================================================
% Output Quantization
%% ==========================================================

y = fi(acc21,T_OUT,F);

last_output = y;

fir_valid = true;

%% ==========================================================
% Range Tracking
%% ==========================================================

% Input

min_in = min(min_in,double(x_fix));
max_in = max(max_in,double(x_fix));

if double(x_fix)~=0
    min_nz_in = min(min_nz_in,abs(double(x_fix)));
end

% Output

min_out = min(min_out,double(y));
max_out = max(max_out,double(y));

if double(y)~=0
    min_nz_out = min(min_nz_out,abs(double(y)));
end

%% ==========================================================
% Print Once
%% ==========================================================

if evalin('base','exist(''PRINT_FIR_FIXED_RANGE'',''var'')')

    fprintf('\n');

    disp('================ FIXED FIR ANALYSIS ================');

    fprintf('%-18s %-10s %15s %15s %18s\n',...
        'Variable','Q Format','Minimum','Maximum','Min Non-Zero');

    disp('--------------------------------------------------------------------------');

    fprintf('%-18s %-10s %15.6f %15.6f %18.12f\n',...
        'Input',...
        'Q16.14',...
        min_in,...
        max_in,...
        min_nz_in);

    fprintf('%-18s %-10s %15.6f %15.6f %18.12f\n',...
        'Output',...
        'Q16.14',...
        min_out,...
        max_out,...
        min_nz_out);

    disp('==========================================================================');

    fprintf('\n');

    disp('=========== FIR FIXED-POINT SPECIFICATION ===========');

    fprintf('Input            : Q16.14\n');
    fprintf('Pair Sum         : Q17.14\n');
    fprintf('Coefficient      : Q2.16\n');
    fprintf('Product          : Q19.30\n');
    fprintf('Accumulator      : Q24.30\n');
    fprintf('Output           : Q16.14\n');

    disp('=====================================================');

    evalin('base','clear PRINT_FIR_FIXED_RANGE');

end

%% ==========================================================
% Return Double
%% ==========================================================

y = double(y);

end