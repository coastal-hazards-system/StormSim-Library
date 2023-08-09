%% ecdf_boot.m
%{
DESCRIPTION:
   This script performs the bootstrap simulation.

INPUT ARGUMENTS:
  - empHC = empirical HC; as a matrix with format:
     col(01): Response vector sorted in descending order
     col(02): Rank or Weibull's plotting position
     col(03): Complementary cumulative distribution function (CCDF)
     col(04): hazard as AEF or AEP
     col(05): annual recurrence interval (ARI)
  - Nsim: number of simulations or bootstrap iterations
 
OUTPUT ARGUMENTS:
  - boot: results from bootstrap process

AUTHORS:
    Norberto C. Nadal-Caraballo, PhD (NCNC)

CONTRIBUTORS:
    Efrain Ramos-Santiago (ERS)

HISTORY OF REVISIONS:
20201015-ERS: revised. Updated documentation.

***************  ALPHA  VERSION  **  FOR INTERNAL TESTING ONLY ************
%}
function boot = ecdf_boot(empHC,Nsim)
%     rng('default');
Nstrm = size(empHC,1);
dlt = abs(diff(empHC)); dlt = [dlt;dlt(end)];
boot=zeros(Nsim,Nstrm);
for i = 1:Nsim
    [x,idx] = datasample(empHC,Nstrm);
    y = x + randn(Nstrm,1).*dlt(idx);
    boot(i,:) = sort(y,'descend')';
end
end