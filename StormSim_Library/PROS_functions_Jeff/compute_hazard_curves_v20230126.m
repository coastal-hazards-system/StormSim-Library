function  [OUTPUT]= compute_hazard_curves_v20230126(config,Resp)
% J Melby edited 1/11/2023 to be consistent with latests PCHA
%% DEFINE VARIABLE OF INTEREST
% Grab Structure Responses Based On Structure Type
switch config.strucType
    case 1 % Levee
        staID ={'q';'R2p';'R2pPlusSWL'};
        u_sym = {'q_uncert','r2p_uncert','r2p_uncert'};

    case 2 % Floodwall
        staID ={'q';'p1'};
        u_sym = {'q_uncert','p1_uncert'};
    case 3 % Rubblemound
        staID ={'q';'R2p';'R2pPlusSWL';'Dn50';'Dn50_LCBW'};
        % Define Uncertainty Symbols In Config
        u_sym = {'q_uncert','r2p_uncert','r2p_uncert','dn50_uncert','dn50_uncert'};
end
% Add Forcing Variables If User Request's It
if config.compute_forcing_HC == 1
    staID = [staID;{'SWL';'Hm0';'Tp'}];
    u_sym = [u_sym {'swl','hm0','Tp'}];
end
% Grab Percentiles
prc = [cellfun(@str2double,strsplit(config.resp_CL(2:end-1),{' '}))];

%% COMPUTE EXTRATROPICALS HAZARDS
if contains(config.storm_sampling,{'XC','XH','CC'})
    clear input_data
    % Print Status
    disp('    Calculating hazard for extra-tropical responses')
    % Generate SST Input Data
    for kk = 1:length(staID)
        % Define POT Sample Data
        if config.strucType == 2 %wall, pressures
            % P1 Needs To Be Adjusted
%            input_data(kk).data_values = Resp.([staID{kk} '_XC'])/1000;
        % Define Dummy Time Values
           input_data.time_values = zeros(length(Resp.([staID{kk} '_XC'])),1);
           input_data.data_values = Resp.([staID{kk} '_XC'])/1000;
            U_a=[];
            uncert_treatment = 'relative';
            U_r = 1; % there is no uncertainty treatment for P1 here
        else
            if strcmp(staID{kk},'R2pPlusSWL')
%                input_data(kk).data_values = Resp.('R2pPlusSWL_XC');
                input_data.time_values = zeros(length(Resp.R2pPlusSWL_XC),1);
                input_data.data_values = Resp.R2pPlusSWL_XC;
                U_a=[];
                uncert_treatment = 'relative';
                U_r = config.(u_sym{kk});
            elseif contains(u_sym(kk),{'hm0','swl','Tp'}) % use raw values for SST
%                 input_data(kk).data_values = Resp.([staID{kk} '_XC']);
                if contains(u_sym(kk),{'swl'}) 
                  input_data.time_values = zeros(length(Resp.SWL_XC_noreps),1);
                  input_data.data_values = Resp.SWL_XC_noreps;
                  U_a=config.U_a_SWL;
                  U_r=config.U_r_SWL;
                  uncert_treatment = 'combined';
                elseif contains(u_sym(kk),{'hm0'})
                  input_data.time_values = zeros(length(Resp.Hm0_XC_noreps),1);
                  input_data.data_values = Resp.Hm0_XC_noreps;
                  U_a=config.U_a_hm0;
                  U_r=config.U_r_hm0;
                  uncert_treatment = 'combined';
                else %Tp
                 input_data.time_values = zeros(length(Resp.Tp_XC_noreps),1);
                 input_data.data_values = Resp.Tp_XC_noreps;
                 U_a=[];
                 U_r=sqrt(1+config.U_r_hm0)-1;
                 uncert_treatment = 'relative';
                end
            else
                input_data.time_values = zeros(length(Resp.([staID{kk} '_XC'])),1);
                input_data.data_values = Resp.([staID{kk} '_XC']); % such as q, Hn50, R2p
                U_a=[];
                uncert_treatment = 'relative';
                U_r = config.(u_sym{kk});
            end
        end %if config.strucType == 2
        % JAM 1/6/23:  Moved call to inside of loop
        % in SST, staID cannot be a cell string
        staID_new=staID{kk};
        [SST_output(kk)] = call_SST_toolv0p1_JAM2023(input_data,staID_new,config.Nyrs_XC,prc,U_a,U_r,uncert_treatment);
    end %for kk = 1:length(staID)
    OUTPUT.XC.SST_output = SST_output;
end %if contains(config.storm_sampling,{'XC','XH','CC'})
%% COMPUTE TROPICALS HAZARDS
if contains(config.storm_sampling,{'TC','TS','CC'})
    % Print Status
    disp('    Calculating hazard for tropical responses');
    % For Each Response
    for kk = 1:length(staID)
        clear input_data
        % Choose Uncertainty
        if config.strucType == 2 %wall, pressures
            input_data = Resp.([staID{kk} '_TC'])/1000;
            U_a=[];
            uncert_treatment = 'relative';
            U_r = 1; % there is no uncertainty treatment for P1 here
        else
           if strcmp(staID{kk},'R2pPlusSWL')
                input_data = Resp.R2pPlusSWL_TC;
                U_a=[];
                uncert_treatment = 'relative';
                U_r = config.(u_sym{kk});
           elseif contains(u_sym(kk),{'hm0','swl','Tp'}) % use raw values for SST
              if contains(u_sym(kk),{'swl'}) 
                 input_data = Resp.SWL_TC_reps;
                 U_a=config.U_a_SWL;
                 U_r=config.U_r_SWL;
                 uncert_treatment = 'combined';
              elseif contains(u_sym(kk),{'hm0'})
                 input_data = Resp.Hm0_TC_reps;
                 U_a=config.U_a_hm0;
                 U_r=config.U_r_hm0;
                 uncert_treatment = 'combined';
              else %Tp
                 input_data = Resp.Tp_TC_reps;
                 U_a=[];
                 U_r=sqrt(1+config.U_r_hm0)-1;
                 uncert_treatment = 'relative';
              end
           else
              input_data = Resp.([staID{kk} '_TC']); % such as q, Hn50, R2p
              U_a=[];
              uncert_treatment = 'relative';
              U_r = config.(u_sym{kk});
           end
        end
        % Call JPM Fucntion

        [JPM_output(kk)] = call_JPM_tool_1_26_23(staID{kk},prc,U_a,U_r,input_data,Resp.Prob_TC,uncert_treatment);
    end
    % Add To Output Var
    OUTPUT.TC.JPM_output = JPM_output;
end
end