 function [gamma_f_XC] = surface_roughness_influence_factor(gamma_f_XC,Hm0_XC)
     % Surface roughness coefficient
     % Not used in floodwall overtopping equations
     % Coefficients are found in CEM and in Eurotop. For levees with grass, the
     % surface roughness influence increses for small wave heights.
     if gamma_f_XC>1 % 2 denotes grass in input file
         % Use Eurotop equation 5.23 if grass and Hm0 < 0.75 m, otherwise set
         % gamma_f to 1 for grass
         gamma_f_XC(Hm0_XC < 0.75)= 1.15*Hm0(Hm0_XC < 0.75).^0.5;
         gamma_f_XC(Hm0_XC >= 0.75) = 1;
     end
 end