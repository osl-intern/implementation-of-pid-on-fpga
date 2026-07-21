function cost = PID_Objective(x,G,Heq,Ts)

Kp = x(1);
Ki = x(2);
Kd = x(3);

z = tf('z',Ts);

C = Kp ...
    + Ki*Ts/(1-z^-1) ...
    + (Kd/Ts)*(1-z^-1);

C = minreal(C);

L = minreal(C*G*Heq);

T = feedback(L,1);

%% Closed-loop stability

p = pole(T);

if any(abs(p)>=1)

    cost = 1e12;
    return

end

%% Margins

try

    [GM,PM] = margin(L);

catch

    cost = 1e12;
    return

end

GMdB = 20*log10(GM);

if isnan(GMdB) || isnan(PM) || ...
        isinf(GMdB) || isinf(PM)

    cost = 1e12;
    return

end

if GMdB <= 0 || PM <= 0

    cost = 1e12;
    return

end

%% Maximize both margins

cost = -(GMdB + PM);

end