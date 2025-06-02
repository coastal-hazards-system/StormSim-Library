function [var_out] = melby_low_crested_stability(Hsig, Rc, delta, Dn50)
%% VECTORIZE INPUTS
data_dims = size(Hsig);
Hsig = Hsig(:);
delta = delta(:);
Rc = Rc(:);
Dn50 = Dn50(:);
Hsig(Hsig<0.1)=nan; % had to do this on 8/3/23 to avoid errant Dn50 spikes for very small Hs

%% EQUATION EMPIRICAL COEFFICIENTS
% mean fit coefficients
a = 0.567;
b = 1.5;

%% COMPUTE Dn50 OR STABILITY NUMBER ACCORDING TO INPUTS
% If No Stone Size Provided, Estimate It
if isempty(Dn50)
    % equation for Dn50
    Dn50_LCBW = (Hsig/delta + a * Rc)/b;
else % Dn50 Was Given , Compute Stability Number
    % equation for Dn50
    Dn50_LCBW = Dn50;
end
% Compute normalized freeboard
NFB = Rc./Dn50_LCBW;
Ns = Hsig/delta./Dn50_LCBW;
% constrain stability number
Ns(NFB>=0)=b;
% Compute Output Varaible According To Input
if isempty(Dn50) % Want To Get Dn50 for LCBW
    var_out = Hsig./Ns./delta; % Update Values As f(Ns)
    % Constrain to range of application
    var_out(NFB<-3 | NFB>=2.4) = NaN;
    var_out(Hsig<=0.1) = NaN;
else
    % Compute LCBW Stability Number (LCS)
    var_out = Dn50./(Hsig./Ns./delta);
end
% Reshape
var_out = reshape(var_out, data_dims);
end