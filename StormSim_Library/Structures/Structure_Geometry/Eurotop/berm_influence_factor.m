function [gamma_b] = berm_influence_factor(berm_width,berm_elevation,Hm0,SWL,slope)
% berm influence
if berm_width~=0
    B = berm_width; % Berm width
    Lberm = B + 2*Hm0.*slope;
    dBerm = SWL+berm_elevation;

    rB = B ./ Lberm;
    R2p_Est = 2*Hm0; % Esimated per EurOtop for runup - could be refined more using r2p eq

    rDB = zeros(size(dBerm));
    rDB(dBerm>0)=0.5-0.5*cos(pi.*dBerm(dBerm>0)./R2p_Est(dBerm>0));
    rDB(dBerm<0)=0.5-0.5*cos(pi.*dBerm(dBerm<0)./(2*Hm0(dBerm<0)));
    rDB(dBerm>R2p_Est | dBerm<(-2*Hm0))=1;

    gamma_b = 1-rB.*(1-rDB); % EurOtop eq 5.40
    gamma_b(gamma_b<0.6)=0.6;
    gamma_b(gamma_b>1)=1;

else
    gamma_b = ones(size(Hm0));
end
end