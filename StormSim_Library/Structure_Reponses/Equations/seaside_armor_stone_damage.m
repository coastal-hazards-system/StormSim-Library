function [S,Szero] = seaside_armor_stone_damage(depth,SLast,...
    Hsig,Tm,crest_elevation,Sslp,SDn,SG,grav,P,Nz,Rc,Szerolim,cutoff,WL,cutoff_switch,km1,km2,Ks,dS)

%% DEFINE DAMAGE PROGRESSION INCREMENT AND EMPIRICAL FACTOR
Eq_range = Rc/SDn>=1 & Rc/SDn<=Inf;

%% DAMAGE (S) COMPUTATION
if (Hsig>0.1) && (depth>0)
    %% DEFINE WATER COLUM AND WAVE PARAMETERS
    % Define Water Column
    h = depth;
    % Estimate Wave Number
    [km,kmest,error] = wavnum1_VG(Tm,h,grav);
    % Compute Wave Length
    Lm = 2*pi/km;
    % Compute Wave Steepness
    sm = Hsig/Lm;
    % Determine Critical Wave Steepness Continous
    smc = Sslp^-3;

    %% MOMENTUM FLUX COMPUTATIONS
    A0 = 0.639*(Hsig/h)^2.026;
    A1 = 0.180*(Hsig/h)^-0.391;
    Mf = A0*(h/grav/Tm^2)^-A1;

    %% DETERMINE am RELATIONSHIP TO USE BASED ON WAVE STEEPNESS
    if sm>=smc
        am = 1/(km1*P^0.18*sqrt(Sslp)); %plunging
    else
        am = 1/(km2*P^0.18*Sslp^(0.5-P)*sm^(-P/3)); %surging
    end

    %% COMPUTE Nm & Nze
    Nm = sqrt(Mf/(SG-1)) * h/SDn;
    Nze = (SLast/Ks/(am*Nm)^5)^2;

    %% COMPUTE Szero
    Szero = Ks*sqrt(Nz)*(am*Nm)^5;

    %% CUTOFF ANALYSIS FOR STRUCTURE SUBMERGENCE
    if Szero > Szerolim
        if Eq_range
            % Verify Validity Range
            if cutoff_switch == 0
                % Compute Damage Accumulation
                S=dS + Ks*sqrt(Nze+Nz)*(am*Nm)^5;
            else
                if  WL<=crest_elevation+cutoff % Boolean Checks For Equation Validity Range
                    % Compute Damage Accumulation
                    S=dS + Ks*sqrt(Nze+Nz)*(am*Nm)^5;
                else
                    % If No New Damage Carry Previous Damage Level
                    S=SLast;
                end
            end
        else
            S=SLast;
        end
    else
        S=SLast;
    end
else
    % If No New Damage Carry Previous Damage Level
    S= SLast;
    Szero = 0;
end
end