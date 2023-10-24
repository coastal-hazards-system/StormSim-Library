function [Resp, project_forcing] = compute_structure_response(config, structure, project_forcing,  emp_coeff, storm_type)
%% DEFINE AUX VARIABLES ON SCRIPT
q_lim = 10^-6;

%% GRAB DETAILS FROM "config"
% Strucutre Type
struc_type = config.struc_type;
% Storm Duration [s]
duration = config.storm_duration*3600; % Convert hr to s
% Compute Forcing HC
compute_HC = config.pros_compute_forcing_HC;
% Define Requested Workflow
workflow = config.workflow;
% Grab Structure Response Switches
calc_dn50_ss = config.pros_dn50_seaside;
calc_dn50_ls = config.pros_dn50_leeside;
calc_dn50_lcbw = config.pros_dn50_lcbw;
calc_r2p = config.pros_r2p;
calc_q = config.pros_q;
calc_q_vol = config.pros_q_vol;
calc_p1 = config.pros_p1;
calc_p2_p3 = config.pros_p2_p3;
calc_Nappe = config.pros_nappe;
% No Structural Response Computed
no_resp = sum([calc_dn50_ss,calc_dn50_ls,calc_dn50_lcbw,calc_r2p,calc_q,calc_q_vol,calc_p1,calc_p2_p3,calc_Nappe]);
% Remove Responses Based On Structure Type
switch struc_type
    case 1 % Levee (R2p & OT)
        calc_p1 = 0;
        calc_p2_p3 = 0;
        calc_Nappe = 0;
        calc_dn50_ss = 0;
        calc_dn50_ls = 0;
        calc_dn50_lcbw = 0;
    case 2 % Floodwall (q, P1, P2, P3, Nappe)
        calc_dn50_ss = 0;
        calc_dn50_ls = 0;
        calc_dn50_lcbw = 0;
        calc_r2p = 0;
    case 3 % Rubblemound (R2p, q, Dn50)
        calc_p1 = 0;
        calc_p2_p3 = 0;
        calc_Nappe = 0;
end


%% GRAB DETAILS FROM "structure"
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Define Structure Crest Width
crest_width = structure.crest_width;
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation; % Flip convention
% Berm Elevation (<0 Below Datum Zero)
berm_elev = structure.berm_elevation; %
% Berm Width
berm_width = structure.berm_width;
% Berm Slope
berm_slope = structure.berm_slope;
% Seaside Slope (cot(alpha))
slope = structure.seaside_slope;
% Leeside Slope
slope_lee = structure.leeside_slope;
% Rubblemound Fields
if struc_type == 3
    % Delta
    delta = structure.armor_delta;
    % Seaside Limit State
    S = structure.seaside_limit_S;
    S_ls = structure.leeside_limit_S;
    % CEM P
    P = structure.cem_P;
elseif struc_type == 2
    wall_bottom_elev = structure.wall_bottom_elevation;
end
% Water Density kg/m^3
rho_w = structure.water_density;

%% DEFINE CONSTANTS
g = 9.81; % Gravity
% Grab Workflow Specific Fields
switch workflow
    case {1,2,4} % RB
        % Create Forcing Variables For Simplicity
        if ~iscell(project_forcing.(storm_type).SWL)
            SWL = {project_forcing.(storm_type).SWL}; % SWL
            Hm0 = {project_forcing.(storm_type).Hm0}; % Hm0
            Tp = {project_forcing.(storm_type).Tp}; % Tp
            h = {project_forcing.(storm_type).SWL - toe_elev};
            Rc = {crest_elev - project_forcing.(storm_type).SWL};
            Rc_LC = {berm_elev - project_forcing.(storm_type).SWL}; % Low Crested Breakwater
            dflat = 1;
        else
            SWL = project_forcing.(storm_type).SWL; % SWL
            Hm0 = project_forcing.(storm_type).Hm0; % Hm0
            Tp = project_forcing.(storm_type).Tp; % Tp
            h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
            Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
            Rc_LC = cellfun(@(x) berm_elev - x, SWL, 'un', false); % Low Crested Breakwater
            dflat = 3;
        end
    case 3 % LCS
        % Create Forcing Variables For Simplicity
        if size(project_forcing(1).LCNUM,2)==8  % Peaks
            swl_indx = 4;
        else
            swl_indx = 5;
        end
        SWL = cellfun(@(x) x(:,swl_indx),{project_forcing.LCNUM},'un',false); % SWL
        Hm0 = cellfun(@(x) x(:,swl_indx+1),{project_forcing.LCNUM},'un',false); % Hm0
        Tp = cellfun(@(x) x(:,swl_indx+2),{project_forcing.LCNUM},'un',false); % Tp
        h = cellfun(@(x) x - toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
        Rc_LC = cellfun(@(x) berm_elev - x, SWL, 'un', false); % Low Crested Breakwater
        dflat = 2;
end

%% COMPUTE STRUCTURE RESPONSE
if ~ismember(workflow,[2,4]) && no_resp~=0
    % Call Eurotop Influence Factors
    gammas = cellfun(@(x,y) call_eurotop_ifactors(config, structure, x, y),SWL,Hm0,'un',false);
    % Compute Structure Type Dependant Responses
    switch struc_type
        case 2 % Floodwall
            % Compute runup & Overtopping
            if calc_q == 1
                [~,~, q, q_overflow, q_wave_ot]=cellfun(@(a, b, c, d, e) Eurotop_r2p_q_Final(a, b, c, d,...
                    berm_slope, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
                    wall_bottom_elev, berm_width, struc_type),...
                    Hm0, Tp, SWL, Rc, gammas,'un',false);
            end
            % Compute Tm1_0
            Tm10 = cellfun(@(x) x./1.1,Tp,'un',false);
            % Compute Water Depth @ Berm
            hb = cellfun(@(x) x - abs(berm_elev), SWL,'un',false);
            % Compute P1 Only
            if calc_p1 == 1 || calc_p2_p3 == 1
                p1 = cellfun(@(a, b, c, d) goda_forces_on_vertical_p1(a, b, 1.8,...
                    zeros(size(a)), c, d, berm_width, slope, rho_w, [1, 1]),Hm0,Tm10,h,hb,'un',false);
            end
        case {1,3} % Levees & Rubblemound
            % Compute runup & Overtopping
            if calc_r2p == 1 || calc_q == 1 || calc_q_vol == 1
                [R2p, R2p_SWL, q, q_overflow, q_wave_ot]=cellfun(@(a, b, c, d, e) Eurotop_r2p_q_Final(a, b, c, d,...
                    slope, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
                    toe_elev, berm_width, struc_type),...
                    Hm0, Tp, SWL, Rc, gammas,'un',false);
            end
            % Remove Unwanted Fields
            if calc_r2p == 0
                clearvars('R2p','R2p_SWL');
            end
            if calc_q == 0 && calc_q_vol == 0
                clearvars('q');
            end
            % Compute Mean Period
            Tm = cellfun(@(x) x./1.2,Tp,'un',false); % This should be removed
            % Compute Zeroth Moment Spectral Wave Period
            Tm10 = cellfun(@(x) x./1.1,Tp,'un',false); % This should be removed
            % Compute Stone SIze Using S Limit State
            if struc_type == 3
                % Dn50 Seaside (Melby - Momentum Flux)
                if calc_dn50_ss == 1
                    [Dn50] = cellfun(@(a, b, c, d) melby_Dn50_seaside_stability(a, b, c,...
                        duration, slope, delta, P, S, g, emp_coeff.km1, emp_coeff.km2, d),...
                        Hm0, Tm, h, Rc,'un',false);
                end
                % Dn50 Seaside Low Crested Breakwater
                if calc_dn50_lcbw == 1
                    %{
                    Melby addition for LCBW. This is a temporary fix for Midbay. Ultimately we will have a branch whether  
                    breakwater is normal or low-crested.  In that case, there will not be a separate crest elevation for low-crested structure.  
                    However, for Midbay, we have both normal structure and low crested because toe berm is at MLLW. 
                    So we have both normal and LC (toe berm) stability computed in same sim.
                    %}
                    [Dn50_LCBW] = cellfun(@(a,b) melby_low_crested_Dn50(a,b,delta), Hm0,Rc_LC,'un',false);
                end
                % Leeside
                if calc_dn50_ls == 1
                    [Dn50_Lee] = cellfun(@(a,b,c,d) van_gent_Dn50_leeside_stability(S_ls, a, b, c, d, crest_width, slope, slope_lee, duration, delta, emp_coeff.k_ls1, emp_coeff.k_ls2),...
                        Hm0, Tm10, Tm, Rc,'un',false);
                end
            end
    end
else % StormSim:EVA was called, no structure responses
    Resp = [];
end

%% FLATTEN DATA & STORE RESPONSES
% Evaluate According To Workflow
switch dflat
    case 1 % RB1
        % Store Responses In Response Var
        if exist('R2p','var') && struc_type~=2
            Resp.('R2p') = R2p{:}; % Run-up
            Resp.('R2p_SWL') = R2p_SWL{:}; % Run-up + SWL
        end
        if exist('q','var')
            Resp.('q') = q{:}; % Overtopping (Combined)
            Resp.('q_overflow') = q_overflow{:}; % Overtopping by overflow
            Resp.('q_wave_ot') = q_wave_ot{:}; % Overtopping By Waves
        end
        if exist('p1','var')
            Resp.('p1') = p1{:}; % Goda Wall Pressure
        end
        if exist('Dn50','var')
            if calc_dn50_ss == 1
                Resp.('Dn50') = Dn50{:}; % Median Stone Size
            end
            if calc_dn50_lcbw == 1
                Resp.('Dn50_LCBW') = Dn50_LCBW{:}; % Median Stone Size - Low Crested Break Water
            end
            if calc_dn50_ls == 1
                Resp.('Dn50_Lee') = Dn50_Lee{:}; % Median Stone Size - Van Gent Leeside Stability
            end
        end
        % Replace Forcing Fields With No Rep For HC Calcs
        if workflow == 1
            % Remove Forcing Fields With Replicates
            if any(contains(fieldnames(project_forcing.(storm_type)),{'_no_rep'})) && contains(storm_type,{'XC'})
                % Rename Forcing Fields
                project_forcing.(storm_type).('SWL') = project_forcing.(storm_type).('SWL_no_rep');% SWL
                project_forcing.(storm_type).('Hm0') = project_forcing.(storm_type).('Hm0_no_rep');% Hm0
                project_forcing.(storm_type).('Tp') = project_forcing.(storm_type).('Tp_no_rep');% Tp
                % Remove Fields
                project_forcing.(storm_type) = rmfield(project_forcing.(storm_type),{'SWL_no_rep','Hm0_no_rep','Tp_no_rep'});
            elseif any(contains(fieldnames(project_forcing.(storm_type)),{'_no_rep'})) && contains(storm_type,{'TC'})
                % Get Reshape Size
                dSize = size(project_forcing.(storm_type).('SWL'),2);
                % Rename Forcing Fields
                project_forcing.(storm_type).('SWL') = repmat(project_forcing.(storm_type).('SWL_no_rep'),1,dSize);% SWL
                project_forcing.(storm_type).('Hm0') = repmat(project_forcing.(storm_type).('Hm0_no_rep'),1,dSize);% Hm0
                project_forcing.(storm_type).('Tp') = repmat(project_forcing.(storm_type).('Tp_no_rep'),1,dSize);% Tp
                % Remove Fields
                project_forcing.(storm_type) = rmfield(project_forcing.(storm_type),{'SWL_no_rep','Hm0_no_rep','Tp_no_rep'});
            end
        end
    case 2 % LCS
        %---- INSERT SECONDARY RESPONSES COMPUTATIONS HERE -------%
        % P2, P3, Nappe (if p1 exist -> floodwall)
        if exist('R2p','var') && struc_type~=2
            Resp.('R2p') = cell2struct(R2p,'LCNUM');
            Resp.('R2p_SWL') = cell2struct(R2p_SWL,'LCNUM');
        end
        if exist('q','var')
            Resp.('q') = cell2struct(q,'LCNUM');
            Resp.('q_overflow') = cell2struct(q_overflow,'LCNUM');
            Resp.('q_wave_ot') = cell2struct(q_wave_ot,'LCNUM');
        end
        if exist('p1','var')
            Resp.('p1') = cell2struct(p1,'LCNUM');
        end
        if exist('Dn50','var')
            if calc_dn50_ss == 1
                Resp.('Dn50') = cell2struct(Dn50,'LCNUM'); % Median Stone Size
            end
            if calc_dn50_lcbw == 1
                Resp.('Dn50_LCBW') = cell2struct(Dn50_LCBW,'LCNUM'); % Median Stone Size - Low Crested Break Water
            end
            if calc_dn50_ls == 1
                Resp.('Dn50_Lee') = cell2struct(Dn50_Lee,'LCNUM');% Median Stone Size - Van Gent Leeside Stability
            end
        end
    case 3 % Find Max Responses For Timeseries (RB3)
        if exist('R2p','var') && struc_type~=2
            Resp.('R2p') = cell2mat(cellfun(@(x) max(x,[],1),R2p,'un',false));
            Resp.('R2p_SWL') = cell2mat(cellfun(@(x) max(x,[],1),R2p_SWL,'un',false));
        end
        if exist('q','var')
            Resp.('q') = cell2mat(cellfun(@(x) max(x,[],1),q,'un',false));
            Resp.('q_overflow') = cell2mat(cellfun(@(x) max(x,[],1),q_overflow,'un',false));
            Resp.('q_wave_ot') = cell2mat(cellfun(@(x) max(x,[],1),q_wave_ot,'un',false));

            for mm = 1:length(q)
                q{mm}(q{mm}<q_lim) = NaN;
                q_wave_ot{mm}(q_wave_ot{mm}<q_lim) = NaN;
            end
            if calc_q_vol == 1
                Resp.('Q_vol') = cell2mat(cellfun(@(x) sum(x,1,"omitnan"),q,'un',false));
                Resp.('Q_vol_overflow') = cell2mat(cellfun(@(x) sum(x,1,"omitnan"),q_overflow,'un',false));
                Resp.('Q_vol_wave_ot') = cell2mat(cellfun(@(x) sum(x,1,"omitnan"),q_wave_ot,'un',false));
            end
        end
        if exist('p1','var')
            Resp.('p1') = cell2mat(cellfun(@(x) max(x,[],1),p1,'un',false));
        end
        if exist('Dn50','var')
            Resp.('Dn50') = cell2mat(cellfun(@(x) max(x,[],1),Dn50,'un',false));
        end
        if exist('Dn50_LCBW','var')
            Resp.('Dn50_LCBW') = cell2mat(cellfun(@(x) max(x,[],1),Dn50_LCBW,'un',false));
        end
        if exist('Dn50_Lee','var')
            Resp.('Dn50_Lee') = cell2mat(cellfun(@(x) max(x,[],1),Dn50_Lee,'un',false));
        end

        % Replace Forcing Fields With No Rep For HC Calcs
        if workflow == 1
            if any(contains(fieldnames(project_forcing.(storm_type)),{'_no_rep'})) && contains(storm_type,{'XC'})
                %
                dSize = size(project_forcing.(storm_type).('SWL_no_rep'){1},2);
                % Grab Values With No Uncertainty For HC Calculations
                SWL = project_forcing.(storm_type).('SWL_no_rep');
                Hm0 = project_forcing.(storm_type).('Hm0_no_rep');
                Tp = project_forcing.(storm_type).('Tp_no_rep');
                % Replace Forcing Fields Before Going Into SST/JPM
                project_forcing.(storm_type).('SWL') = SWL;
                project_forcing.(storm_type).('Hm0') = Hm0;
                project_forcing.(storm_type).('Tp') = Tp;
                % Remove Fields
                project_forcing.(storm_type) = rmfield(project_forcing.(storm_type),{'SWL_no_rep','Hm0_no_rep','Tp_no_rep'});
            elseif any(contains(fieldnames(project_forcing.(storm_type)),{'_no_rep'})) && contains(storm_type,{'TC'})
                %
                dSize = size(project_forcing.(storm_type).('SWL'){1},2);
                % Grab Values With No Uncertainty For HC Calculations
                SWL = project_forcing.(storm_type).('SWL_no_rep');
                Hm0 = project_forcing.(storm_type).('Hm0_no_rep');
                Tp = project_forcing.(storm_type).('Tp_no_rep');
                % Replace Forcing Fields Before Going Into SST/JPM
                project_forcing.(storm_type).('SWL') = SWL;
                project_forcing.(storm_type).('Hm0') = Hm0;
                project_forcing.(storm_type).('Tp') = Tp;
                % Remove Fields
                project_forcing.(storm_type) = rmfield(project_forcing.(storm_type),{'SWL_no_rep','Hm0_no_rep','Tp_no_rep'});
            end
        else
            % No Need To Create replicates Here
            dSize = 1;
        end
        if compute_HC == 1
            % Find SWL Max For Each Storm
            project_forcing.(storm_type).('SWL') = repmat(cell2mat(cellfun(@(x) max(x,[],1),SWL,'un',false)),1,dSize);
            % Find Hm0 Max For Each Storm
            [Hm0_2,Hm0_indx] = cellfun(@(x) max(x,[],1),Hm0,'un',false);
            % Store Back Into Project Forcing
            project_forcing.(storm_type).('Hm0') = repmat(cell2mat(Hm0_2),1,dSize);
            %
            project_forcing.(storm_type).('Tp') = repmat(cell2mat(cellfun(@(x,y) x(y), Tp, Hm0_indx, 'un', false)),1,dSize);
        end
end

%% IMPLEMENT FAILSAFES
switch dflat
    case {1,3} %
        if exist('q','var')
            % q Imaginary Numbers
            if any(~arrayfun(@isreal,Resp.('q')),'all')
                nReal = real(Resp.('q'));
                nReal_2 = real(Resp.('q_overflow'));
                nReal_3 = real(Resp.('q_wave_ot'));
                nImag = imag(Resp.('q'));
                % Set Entries With Imaginary Component ~= 0 to NaNs
                nReal(nImag~=0) = NaN;
                nReal_2(nImag~=0) = NaN;
                nReal_3(nImag~=0) = NaN;
                % Store Back As Double
                Resp.('q') = nReal;
                Resp.('q_overflow') = nReal_2;
                Resp.('q_wave_ot') = nReal_3;
            end
            % q <10^-4
            Resp.('q')(Resp.('q')<q_lim) = NaN;
            Resp.('q_wave_ot')(Resp.('q_wave_ot')<q_lim) = NaN;

        end
    case 2 % LCS
        if exist('q','var')
            for kk = 1:length(Resp.('q'))
                % Check For Comples Response
                nReal = real(Resp.('q')(kk).LCNUM);
                nReal_2 = real(Resp.('q_overflow')(kk).LCNUM);
                nReal_3 = real(Resp.('q_wave_ot')(kk).LCNUM);
                nImag = imag(Resp.('q')(kk).LCNUM);
                % Set Entries With Imaginary Component = 0 to NaNs
                nReal(nImag~=0) = NaN;
                nReal_2(nImag~=0) = NaN;
                nReal_3(nImag~=0) = NaN;
                % Store Back As Double
                Resp.('q')(kk).LCNUM = nReal;
                Resp.('q_overflow')(kk).LCNUM = nReal_2;
                Resp.('q_wave_ot')(kk).LCNUM = nReal_3;
                % q <10^-4
                Resp.('q')(kk).LCNUM(Resp.('q')(kk).LCNUM<q_lim) = NaN;
                Resp.('q_wave_ot')(kk).LCNUM(Resp.('q_wave_ot')(kk).LCNUM<q_lim) = NaN;
            end
        end
end