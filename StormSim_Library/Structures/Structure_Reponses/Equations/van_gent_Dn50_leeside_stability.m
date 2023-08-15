% Program to
%     compute cross-section incremental damage
% Written by Jeff Melby May 2012
%
% Modified Dec 2020 Abigail Stehno to compare Melby eqs with low-crested
% breakwater and Van Gent LC-BW equations
%       - added CrestEle to inputs for low-crested eqs
%       - changed function output to include Low Crested Eqs and Burcharth RoT
% Modified Nov 2021 Abigail Stehno - change Crest elevation input to Rc
%
% Input:
%     Tm............Mean Wave Period (sec)
%     Hsig..........Hm0 Significant Wave height(m or ft)
%     Sslp..........cot of Structure Slope
%     grav..........Acceleration of Gravity (m./s.^2 or ft./s.^2)
%     Nz............Number of Waves = duration./Tm
%     depth.........Water Depth near Toe (m or ft)
%     P.............Structure Notional Permeability
%     S.............Damage Limit State
%     delta.........Armor Immersed Relative Denstity
%
%       CrestEel .... Crest elevation (depth + freeboard)
%
% Output:
%     Dn50..........Armor Stone Nominal Size (m or ft)
%
%
%
%============================================================
function [S,u1p] = van_gent_Dn50_leeside_stability(S_ls, Hsig, Tm10, Tm, Rc, crest_width, Sslp, duration, delta, K_ls1, K_ls2)

%% VECTORIZE INPUTS
data_dims = size(Hsig);
Hsig = Hsig(:);
Tm10 = Tm10(:);
Tm = Tm(:);
Rc = Rc(:);
Nz = duration./Tm;

%% DEFINE CONSTANTS
% Gravitational acceleration (m/s^2)
grav = 9.80665;
% Define
r = 6; % Constant Wave Conditions

% Compute Run-up Exceeded By 1% Of The Incident Waves
[z1p] = z1p_calc(Hsig, Tm10, Rc, Sslp, grav);
% Compute Crest Velocity Exceeded By 1% Of The Incident Waves
u1p = u1p_calc(crest_width, Rc, z1p, Tm10, Hsig, Sslp, grav);
% Compute First Term
a_ls = Sslp.^(-2.5/r) .* (1 + exp(-1 * Rc_rear/Hsig)).^(1/r);
% Compute Second Term
aux1 = (S_ls./(K_ls2 .* sqrt(Nz)))^(-1/r);
% compute Third Term
aux2 = (u1p .* Tm10)./(K_ls1 .* sqrt(delta));
% Compute Leeside Stone Size
Dn50_Lee = a_ls .* aux1 .* aux2;
% Remove Invalid Entries
Dn50_Lee(Ru<abs(Rc)) = NaN;
Dn50_Lee(u1p<=0) = NaN;
% Reshape
Dn50_Lee = reshape(Dn50_Melby, data_dims);
end


