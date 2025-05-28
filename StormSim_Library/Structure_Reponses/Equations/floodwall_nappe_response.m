function [Nappe] = floodwall_nappe_response(SWL, Hm0, q, h_wall, rho_w)
%% VECTORIZE INPUTS 
data_dims = size(SWL);
SWL = SWL(:);
Hm0 = Hm0(:);
q = q(:);

%% CONVERT q FROM [L/s per m] to [m^3/s per m]
% 1 m^3 = 1 Liter 
conv_factor = 1000;
% Convert 
q = q/conv_factor;

%% COMPUTE WALL NAPPE RESPONSE (AS PER TR-21-15)
% Define Total Water Column
h1 = SWL+Hm0-h_wall;
% Define Equation Empirical Coefficients
A = -0.425; B = 0.055; C = 0.150; D = 0.559;
% Compute Nappe Lower Wave Impact Region (Is this Right)
Nappe.X_low = abs(h1).*((-B-sqrt(B.^(2)-4*A*(C+(h_wall./abs(h1)))))./(2*A)); % m
% Compute Overtopping Jet Angle Lower Geometry Angle
Nappe.theta_low= atan((2*A.*Nappe.X_low./abs(h1))+B); % deg
% Compute Nappe Upper Wave Impact Region
Nappe.X_up = abs(h1).*((-B-sqrt(B.^(2)-4*A*(C+D+(h_wall./abs(h1)))))./(2*A)); % m
% Compute Overtopping Jet Angle Upper Geometry Angle
Nappe.theta_up = atan((2*A.*Nappe.X_up./abs(h1))+B); % deg
% Compute Impact Range Difference
Nappe.Bx = Nappe.X_up  - Nappe.X_low; % m
% Compute Distance From Floodside Of Wall To Jet Center
Nappe.X_c_surge = (Nappe.X_up+Nappe.X_low)./2; % m
% Did Not Find This In TR 12-15
Nappe.theta_center = (Nappe.theta_low + Nappe.theta_up)./2; % deg
% Compute The Width Of Impinging Jet
Nappe.Bjet  = Nappe.Bx.*sin(-Nappe.theta_center); % m
% Compute Jet Entry Velocity
Nappe.Vjet  = q./Nappe.Bjet; % m/s
% Compute Total Force Excerted
Nappe.Fjet  = rho_w.*Nappe.Bjet.*(Nappe.Vjet).^2; % N/m\
% Get Fieldnames 
fnames = fieldnames(Nappe);
% Reshape Fields 
for ii = 1:length(fnames)
    Nappe.(fnames{ii}) = reshape(Nappe.(fnames{ii}), data_dims);
end

%% PARAMETERS NOT FOUND IN TR-21-15 Appendix F
%     v1 = 3*sqrt(9.81*toe); % v1 is 2-4 times cg - split the difference as 3?
%     H = h1 + (v1^2 / (2*9.81));
%     Nappe.X_c_wave = sqrt(2*(toe+SWL.*(h_wall+0.7.*Hm0+h1)));
%         Nappe.X_low = abs(h1)./2/A.*(-B-4*B*(C+h_wall./abs(h1))); Where did this come from
%         Nappe.X_up = abs(h1)./2/A.*(-B-4*B.*(C+D+h_wall./abs(h1)));
end
