% ============================================================
%{
Program to compute stone size for low-crested rubble mound breakwater
Written by Jeff Melby August 2023

Approach is based on environmental design of low crested coastal defense structures (DELOS) project 
(Kamer and Burcharth 2003a). Application ranges 9.1 ≤ H/Dn50  ≤ 19.1, normalized crest widths 
within the range 3.0 ≤ B/Dn50 ≤ 7.6, and normalized freeboards within the range -3.0 ≤ Rc/Dn50 ≤ 2.4. 

DELOS equation was reformulated because it was unstable and converged to 
non-physical solutions. Data were refit with a linear relation. Note that 
there are no physics in this equation. It is
simply an empirical fit to lab data.

Input:
    Hsig..........Hm0 Significant Wave height(m or ft)
    delta.........Armor Immersed Relative Denstity
    Rc............Freeboard

Output:
    Dn50_LCBW.....Armor Stone Nominal Size (m or ft)

%============================================================
%}
function [LCBW_FS] = melby_low_crested_LCS(Hsig,Rc,delta,Dn50_LCBW)
%mean fit coefficients
a = 0.567; 
b = 1.5;

Hsig(Hsig<0.1)=nan; % had to do this on 8/3/23 to avoid errant Dn50 spikes for very small Hs

% equation for Dn50
% Compute normalized freeboard
NFB = Rc./Dn50_LCBW;
Ns = Hsig/delta./Dn50_LCBW;
% constrain stability number
Ns(NFB>=0)=b;
LCBW_FS = Dn50_LCBW / (Hsig./Ns/delta);
% Constrain to range of application
end
