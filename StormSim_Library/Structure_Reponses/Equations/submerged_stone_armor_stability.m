function [Dn50, Dn50_tag] = submerged_stone_armor_stability(Hs,Tp,h,Rc,Dn50,hc,S,delta,g)
% JAM Updated on 2/11/26
% New approach in this routine follows the vdM and Daemen 1994 paper and 
% intends a spatially continuous computational approach for leeside and 
% low-crested-submerged armor.
% 1. Fully emergent crest: seaside and leeside separately using present version of SS
% 3. Submerged Rc<0: this is for entire structure
%
% JAM revision on 2/18/26 and updated 4/9/26
% removed vdM low crested equation that is in CEM Table VI-5-24 because it
% produced large discontinuity at SWL because submerged armor are much
% larger.

%% VECTORIZE INPUTS
data_dims = size(Hs);
Hs = Hs(:);
Tp = Tp(:);
h = h(:); %depth
hc = hc(:); %crest height
delta = delta(:); %why do this, should be constant
Rc = Rc(:);
% hc is structure height from sea bottom
Dn50 = Dn50(:);
Hs(Hs<0.1)=nan; % had to do this on 8/3/23 to avoid errant Dn50 spikes for very small Hs
%sop=g*Hs.*Tp.^2/2/pi; %deep water wave steepness based on Tp
[kp,kpest,ERROR] = wavnum1_VG(Tp,h,g);
Lp=2*pi./kp; %local wavelength based on Tp
sp=Hs./Lp; %local wave steepness based on Tp

%% Emergent but low-crested adjustment 
% This didn't work well so it is not implemented
%Rp_star=Rc./Hs.*sqrt(sop/2/pi); %Equation 8 in v&D paper
% Rp_star varies from 0.52 at transition to 0 when crest is at SWL
%fi=1./(1.25-4.8.*Rp_star); % Equation 10 in v&D paper
%fi(fi<0.8) = 0.8; % crest at SWL
%fi(fi>1.0) = 1.0; % crest at transition where Dn50 is unaltered
%Dn50 = fi.*Dn50; % reduce if low-crested

%% Submerged
% The following computes armor size based on rearranged Equation 11 in paper
% and CEM Table VI-5-25 Dn50 comes from the so-called spectral stability number (Ahrens)
% Ns_star = Hs^2/3*Lp^1/3/Delta/Dn50 = H/Delta/Dn50/(sp^1/3)=Ns/(sp^1/3)
aux1 = hc./h./(2.1 + 0.1*S);
aux1 = min(aux1,1); % if aux1>1 then ln(aux1)>0 and Dn50 will be negative
Dn50_sub = -0.14.*Hs/delta./sp.^(1/3)./log(aux1);
Dn50(Rc<0) = Dn50_sub(Rc<0);
Dn50_tag = Rc<0;

%% Output
Dn50 = reshape(Dn50, data_dims);
Dn50_tag = reshape(Dn50_tag, data_dims);
end