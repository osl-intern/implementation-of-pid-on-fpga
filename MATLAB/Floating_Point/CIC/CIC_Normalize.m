function y = CIC_Normalize(cic_out)

GAIN = 21^5;

%-------------------------------------------------------
% Range Tracking
%-------------------------------------------------------

persistent min_in max_in
persistent min_out max_out
persistent min_nz_in
persistent min_nz_out

if isempty(min_in)

    min_in = inf;
    max_in = -inf;

    min_out = inf;
    max_out = -inf;

    min_nz_in = inf;
    min_nz_out = inf;

end

%-------------------------------------------------------
% Normalization
%-------------------------------------------------------

y = double(cic_out)/GAIN;

%-------------------------------------------------------
% Range Update
%-------------------------------------------------------

min_in = min(min_in,double(cic_out));
max_in = max(max_in,double(cic_out));

min_out = min(min_out,y);
max_out = max(max_out,y);

if cic_out~=0
    min_nz_in = min(min_nz_in,abs(double(cic_out)));
end

if y~=0
    min_nz_out = min(min_nz_out,abs(y));
end

%-------------------------------------------------------
% Print Once
%-------------------------------------------------------

if evalin('base','exist(''PRINT_CIC_RANGE'',''var'')') ...
        && evalin('base','PRINT_CIC_RANGE')

    fprintf('\n');
    disp('============= CIC NORMALIZATION =============');

    fprintf('%-18s %15s %15s %18s\n',...
        'Variable','Minimum','Maximum','Min Non-Zero');

    disp('---------------------------------------------------------------');

    fprintf('%-18s %15.6f %15.6f %18.12f\n',...
        'CIC Input',...
        min_in,...
        max_in,...
        min_nz_in);

    fprintf('%-18s %15.6f %15.6f %18.12f\n',...
        'Normalized',...
        min_out,...
        max_out,...
        min_nz_out);

    disp('===============================================================');

    evalin('base','clear PRINT_CIC_RANGE');

end

end