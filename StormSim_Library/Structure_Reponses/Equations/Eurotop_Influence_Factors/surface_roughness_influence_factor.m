function [gamma_f] = surface_roughness_influence_factor(gamma_f,Hm0)
% Surface roughness coefficient
% Not used in floodwall overtopping equations
% Coefficients are found in CEM and in Eurotop. For levees with grass, the
% surface roughness influence increses for small wave heights.
if gamma_f>1 % 2 denotes grass in input file
    % Use Eurotop equation 5.23 if grass and Hm0 < 0.75 m, otherwise set
    % gamma_f to 1 for grass
    gamma_f = ones(size(Hm0));
    gamma_f(Hm0 < 0.75)= 1.15*Hm0(Hm0 < 0.75).^0.5;
    gamma_f(Hm0 >= 0.75) = 1;
else
    gamma_f = repmat(gamma_f, size(Hm0));
end
end