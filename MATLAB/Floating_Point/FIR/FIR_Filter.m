function y = FIR_Filter(x)
% ============================================================
% FIR_Filter.m
%
% Sample-by-sample FIR implementation
%
% Input :
%   x -> One normalized CIC sample
%
% Output:
%   y -> FIR output
%
% ============================================================

persistent coeff delayLine

persistent min_in max_in
persistent min_out max_out
persistent min_nz_in
persistent min_nz_out

if isempty(coeff)

    % Read FIR coefficients (only once)
    T = readtable('FIR_Coefficients.csv');
    coeff = T.Var1;

    % Initialize delay line
    delayLine = zeros(length(coeff),1);

    min_in = inf;
    max_in = -inf;

    min_out = inf;
    max_out = -inf;

    min_nz_in = inf;
    min_nz_out = inf;

    

end

%% Shift Register

delayLine(2:end) = delayLine(1:end-1);

delayLine(1) = x;

%% Multiply and Accumulate

y = sum(delayLine .* coeff);

%-------------------------------------------------------
% Range Tracking
%-------------------------------------------------------

min_in = min(min_in,x);
max_in = max(max_in,x);

min_out = min(min_out,y);
max_out = max(max_out,y);

if x~=0
    min_nz_in = min(min_nz_in,abs(x));
end

if y~=0
    min_nz_out = min(min_nz_out,abs(y));
end



%-------------------------------------------------------
% Print Once
%-------------------------------------------------------

if evalin('base','exist(''PRINT_FIR_RANGE'',''var'')') ...
        && evalin('base','PRINT_FIR_RANGE')

    fprintf('\n');
    disp('================ FIR FILTER =================');

    fprintf('%-18s %15s %15s %18s\n',...
        'Variable','Minimum','Maximum','Min Non-Zero');

    disp('---------------------------------------------------------------');

    fprintf('%-18s %15.6f %15.6f %18.12f\n',...
        'FIR Input',...
        min_in,...
        max_in,...
        min_nz_in);

    fprintf('%-18s %15.6f %15.6f %18.12f\n',...
        'FIR Output',...
        min_out,...
        max_out,...
        min_nz_out);

    disp('===============================================================');

    evalin('base','clear PRINT_FIR_RANGE');

end
