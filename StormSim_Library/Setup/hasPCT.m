%% hasPCT.m
%{
By: E. Ramos
Description: Function to determine if MATLAB has the Parallel Computing
   Toolbox (PCT) and if a pool is active.
   Inputs: None.
   Outputs: id_PCT = 1 when the PCT is found.
            id_PCT = 0 otherwise.

            id_act = 1 when the parallel pool is not active.
            id_act = 0 otherwise

History of revisions:
20201201-ERS: created.
20210113-ERS: now initially assuming id_act=1, to avoid evaluating gcp()
    when id_PCT=0.
%}
function [id_PCT,id_act]=hasPCT()
ver2=ver;
ver2={ver2.Name};
id_PCT=sum(ver2=="Parallel Computing Toolbox");
id_act=1;%initially assume pool is inactive
if id_PCT
    id_act=isempty(gcp('nocreate'));
end
end
