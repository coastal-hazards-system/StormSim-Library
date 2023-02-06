function  [OUTPUT]= compute_hazard_curves_v20230109(config,Resp)
% J Melby edited 1/11/2023 to be consistent with latests PCHA
%% DEFINE VARIABLE OF INTEREST
% Grab Structure Responses Based On Structure Type
switch config.strucType
    case 1 % Levee
        staID ={'q';'R2p';'R2p+SWL'};
        u_sym = {'q_uncert','r2p_uncert','r2p_uncert'};

    case 2 % Floodwall
        staID ={'q';'p1'};
        u_sym = {'q_uncert','p1_uncert'};
    case 3 % Rubblemound
        staID ={'q';'R2p';'R2p+SWL';'Dn50';'Dn50_LCBW'};
        % Define Uncertainty Symbols In Config
        u_sym = {'q_uncert','r2p_uncert','r2p_uncert','dn50_uncert','dn50_uncert'};
end
% Add Forcing Variables If User Request's It
if config.compute_forcing_HC == 1
    staID = [staID;{'SWL';'Hm0';'Tp'}];
    u_sym = {'q_uncert','r2p_uncert','r2p_uncert','dn50_uncert','dn50_uncert','swl','hm0','Tp'};

end
% Grab Percentiles
prc = [cellfun(@str2double,strsplit(config.resp_CL(2:end-1),{' '}))];

%% COMPUTE EXTRATROPICALS HAZARDS
if contains(config.storm_sampling,{'XC','XH','CC'})
    % Print Status
    disp('    Calculating hazard for extra-tropical responses')
    % Generate SST Input Data
    for kk = 1:length(staID)
        % Define Dummy Time Values
%        input_data(kk).time_values = zeros(length(Resp.([staID{1} '_XC'])),1);
        input_data.time_values = zeros(length(Resp.([staID{1} '_XC'])),1);
        % Define POT Sample Data
        if config.strucType == 2 %wall, pressures
            % P1 Needs To Be Adjusted
%            input_data(kk).data_values = Resp.([staID{kk} '_XC'])/1000;
            input_data.data_values = Resp.([staID{kk} '_XC'])/1000;
            U_a=[];
            uncert_treatment = 'relative';
            U_r = 1; % there is no uncertainty treatment for P1 here
        else
            if strcmp(staID{kk},'R2p+SWL')
%                input_data(kk).data_values = Resp.('R2pPlusSWL_XC');
                input_data.data_values = Resp.('R2pPlusSWL_XC');
                U_a=[];
                uncert_treatment = 'relative';
                U_r = config.(u_sym{kk});
            elseif contains(u_sym(kk),{'hm0','swl','Tp'}) % use raw values for SST
%                 input_data(kk).data_values = Resp.([staID{kk} '_XC']);
                if contains(u_sym(kk),{'swl'}) 
                  input_data.data_values = Resp.SWL_XC_noreps;
                  U_a=config.U_a_SWL;
                  U_r=config.U_r_SWL;
                  uncert_treatment = 'combined';
                elseif contains(u_sym(kk),{'hm0'})
                  input_data.data_values = Resp.Hm0_XC_noreps;
                  U_a=config.U_a_hm0;
                  U_r=config.U_r_hm0;
                  uncert_treatment = 'combined';
                else %Tp
                 input_data.data_values = Resp.Tp_XC_noreps;
                 U_a=[];
                 U_r=sqrt(1+config.U_r_hm0)-1;
                 uncert_treatment = 'relative';
                end
            else
                 input_data.data_values = Resp.([staID{kk} '_XC']); % such as q, Hn50, R2p
                 U_a=[];
                 uncert_treatment = 'relative';
                 U_r = config.(u_sym{kk});
            end
        end %if config.strucType == 2
        % JAM 1/6/23:  Moved call to inside of loop
        % in SST, staID cannot be a cell string
        staID_new=staID{kk};
        [OUTPUT.XC.SST_output] = call_SST_toolv0p1_JAM2023(input_data,staID_new,config.Nyrs_XC,prc,U_a,U_r,uncert_treatment);
    end %for kk = 1:length(staID)
%        [OUTPUT.XC.SST_output] = call_SST_toolv0p1(input_data,staID,config.Nyrs_XC,prc,U_r);
end %if contains(config.storm_sampling,{'XC','XH','CC'})
%% COMPUTE TROPICALS HAZARDS
if contains(config.storm_sampling,{'TC','TS','CC'})
    % Print Status
    disp('    Calculating hazard for tropical responses');
    % For Each Response
    for kk = 1:length(staID)
        % Choose Uncertainty
        if contains(u_sym(kk),{'hm0','swl','Tp'}) % use raw values for SST
%          input_data(kk).data_values = Resp.([staID{kk} '_XC']);
           if contains(u_sym(kk),{'swl'}) 
              input_data.data_values = Resp.SWL_TC_reps;
              U_a=config.U_a_SWL;
              U_r=config.U_r_SWL;
              uncert_treatment = 'combined';
           elseif contains(u_sym(kk),{'hm0'})
              input_data.data_values = Resp.Hm0_TC_reps;
              U_a=config.U_a_hm0;
              U_r=config.U_r_hm0;
              uncert_treatment = 'combined';
           else %Tp
              input_data.data_values = Resp.Tp_TC_reps;
              U_a=[];
              U_r=sqrt(1+config.U_r_hm0)-1;
              uncert_treatment = 'relative';
           end
            % Compute Uncertainty For SWL Or Hm0
        else
            % Choose Uncertainty From Config
            U_r = config.(u_sym{kk});
        end
        % Naming Special Case
        if strcmp(staID{kk},'R2p+SWL')
            input_data = Resp.('R2pPlusSWL_TC');
        else
            input_data = Resp.([staID{kk} '_TC']);
        end
        % Call JPM Fucntion
        [JPM_output(kk)] = call_JPM_tool_JAM2023(staID{kk},prc,U_r,input_data,Resp.Prob_TC);
    end
    % Add To Output Var
    OUTPUT.TC.JPM_output = JPM_output;
end
end