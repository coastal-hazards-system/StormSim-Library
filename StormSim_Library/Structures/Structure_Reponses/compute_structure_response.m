function [Resp, project_forcing] = compute_structure_response(config, structure, project_forcing,  emp_coeff, storm_type)
%% GRAB DETAILS FROM "config"
% Strucutre Type
struc_type = config.struc_type;
% Storm Duration [s]
Nz = config.storm_duration*3600; % Convert hr to s
% Compute Forcing HC
compute_HC = config.pros_compute_forcing_HC;
% Define Requested Workflow
workflow = config.workflow;

%% GRAB DETAILS FROM "structure"
% Define Structure Crest Elevation
crest_elev = structure.crest_elevation;
% Define Structure Toe Elevation (<0 below datum zero)
toe_elev = structure.toe_elevation*-1; % Flip convention
% Berm Elevation (<0 Below Datum Zero)
berm_elev = structure.berm_elevation*-1; %
% Berm Width
berm_width = structure.berm_width;
% Seaside Slope (cot(alpha))
slope = structure.seaside_slope;
% Rubblemound Fields
if struc_type == 3
    % Delta
    delta = structure.armor_delta;
    % Seaside Limit State
    S = structure.seaside_limit_S;
    % CEM P
    P = structure.cem_P;
end
% Water Density kg/m^3
rho_w = structure.water_density;

%% DEFINE CONSTANTS
g = 9.81; % Gravity
% Grab Workflow Specific Fields
switch workflow
    case {1,2} % RB
        % Create Forcing Variables For Simplicity
        if ~iscell(project_forcing.(storm_type).SWL)
            SWL = {project_forcing.(storm_type).SWL}; % SWL
            Hm0 = {project_forcing.(storm_type).Hm0}; % Hm0
            Tp = {project_forcing.(storm_type).Tp}; % Tp
            h = {project_forcing.(storm_type).SWL + toe_elev};
            Rc = {crest_elev - project_forcing.(storm_type).SWL};
            dflat = 1;
        else
            SWL = project_forcing.(storm_type).SWL; % SWL
            Hm0 = project_forcing.(storm_type).Hm0; % Hm0
            Tp = project_forcing.(storm_type).Tp; % Tp
            h = cellfun(@(x) x + toe_elev, SWL, 'un', false);
            Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
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
        h = cellfun(@(x) x + toe_elev, SWL, 'un', false);
        Rc = cellfun(@(x) crest_elev - x, SWL, 'un', false);
        dflat = 2;
end

%% COMPUTE STRUCTURE RESPONSE
if workflow ~= 2
    % Call Eurotop Influence Factors
    gammas = cellfun(@(x,y) call_eurotop_ifactors(config, structure, x, y),SWL,Hm0,'un',false);
    % Compute runup & Overtopping
    [R2p,R2p_SWL,q]=cellfun(@(a, b, c, d, e) Eurotop_r2p_q_Final(a, b, c, d,...
        slope, e.gamma_f, e.gamma_beta_r2p, e.gamma_beta_q, e.gamma_star, e.gamma_v, e.gamma_b,...
        toe_elev,berm_width, struc_type),...
        Hm0, Tp, SWL, Rc, gammas,'un',false);
    % Compute Structure Type Dependant Responses
    switch struc_type
        case 2 % Floodwall
            % Compute Tm1_0
            Tm10 = cellfun(@(x) x./1.1,Tp,'un',false);
            % Compute Water Depth @ Berm
            hb = cellfun(@(x) berm_elev + x, SWL,'un',false);
            % Compute P1 Only
            p1 = cellfun(@(a, b, c, d) goda_forces_on_vertical_p1(a, b, 1.8,...
                zeros(size(a)), c, d, berm_width, slope, rho_w, [1, 1]),Hm0,Tm10,h,hb,'un',false);
        case {1,3} % Levees & Rubblemound
            % Compute Mean Period
            Tm = cellfun(@(x) x./1.2,Tp,'un',false); % This should be removed
            % Compute Stone SIze Using S Limit State
            if struc_type == 3
                [Dn50, Dn50_LCBW] = cellfun(@(a, b, c, d) Seaside_stability_Melby_lowCrested(a, b, c,...
                    Nz, slope, delta, P, S, g, emp_coeff.km1, emp_coeff.km2, d),...
                    Hm0, Tm, h, Rc,'un',false);
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
            Resp.('q') = q{:}; % Overtopping
        end
        if exist('p1','var')
            Resp.('p1') = p1{:}; % Goda Wall Pressure
        end
        if exist('Dn50','var')
            Resp.('Dn50') = Dn50{:}; % Median Stone Size
            Resp.('Dn50_LCBW') = Dn50_LCBW{:}; % Median Stone Size - Low Crested Break Water
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
        end
        if exist('p1','var')
            Resp.('p1') = cell2struct(p1,'LCNUM');
        end
        if exist('Dn50','var')
            Resp.('Dn50') = cell2struct(Dn50,'LCNUM');
            Resp.('Dn50_LCBW') = cell2struct(Dn50_LCBW,'LCNUM');
        end
    case 3 % Find Max Responses For Timeseries (RB3)
        if exist('R2p','var') && struc_type~=2
            Resp.('R2p') = cell2mat(cellfun(@(x) max(x,[],1),R2p,'un',false));
            Resp.('R2p_SWL') = cell2mat(cellfun(@(x) max(x,[],1),R2p_SWL,'un',false));
        end
        if exist('q','var')
            Resp.('q') = cell2mat(cellfun(@(x) max(x,[],1),q,'un',false));
        end
        if exist('p1','var')
            Resp.('p1') = cell2mat(cellfun(@(x) max(x,[],1),p1,'un',false));
        end
        if exist('Dn50','var')
            Resp.('Dn50') = cell2mat(cellfun(@(x) max(x,[],1),Dn50,'un',false));
            Resp.('Dn50_LCBW') = cell2mat(cellfun(@(x) max(x,[],1),Dn50_LCBW,'un',false));
        end
        % Replace Forcing Fields With No Rep For HC Calcs
        if workflow == 1
            if any(contains(fieldnames(project_forcing.(storm_type)),{'_no_rep'})) && contains(storm_type,{'XC'})
                SWL = project_forcing.(storm_type).('SWL_no_rep');
                Hm0 = project_forcing.(storm_type).('Hm0_no_rep');
                Tp = project_forcing.(storm_type).('Tp_no_rep');
                project_forcing.(storm_type).('SWL') = SWL;
                project_forcing.(storm_type).('Hm0') = Hm0;
                project_forcing.(storm_type).('Tp') = Tp;
                % Remove Fields
                project_forcing.(storm_type) = rmfield(project_forcing.(storm_type),{'SWL_no_rep','Hm0_no_rep','Tp_no_rep'});
            else
                % Remove Fields
                project_forcing.(storm_type) = rmfield(project_forcing.(storm_type),{'SWL_no_rep','Hm0_no_rep','Tp_no_rep'});
            end
        end
        if compute_HC == 1
            % Find SWL Max For Each Storm
            project_forcing.(storm_type).('SWL') = cell2mat(cellfun(@(x) max(x,[],1),SWL,'un',false));
            % Find Hm0 Max For Each Storm
            [Hm0_2,Hm0_indx] = cellfun(@(x) max(x,[],1),Hm0,'un',false);
            % Create Col index For Max
            cc = repmat({1:length(Hm0_2{1})},length(Hm0_2),1);
            % Store Back Into Project Forcing
            project_forcing.(storm_type).('Hm0') = cell2mat(Hm0_2);
            % Initialize Tp Var
            dummy = zeros(size(project_forcing.(storm_type).('Hm0')));
            % Tp as a f(Hm0)
            for ll = 1:length(Hm0)
                dummy(ll,:) = cell2mat(arrayfun(@(x,y) Tp{ll}(x,y),Hm0_indx{ll},cc{ll},'un',false));
            end
            % Assign Back To Project Forcing
            project_forcing.(storm_type).('Tp') = dummy;
        end
end

%% IMPLEMENT FAILSAFES
switch dflat
    case {1,3} %
        if exist('q','var')
            % q <10^-4
            Resp.('q')(Resp.('q')<10^-4) = NaN;
            % q Imaginary Numbers
            if ~isreal(Resp.('q'))
                nReal = real(Resp.('q'));
                nImag = imag(Resp.('q'));
                % Set Entries With Imaginary Component = 0 to NaNs
                nReal(nImag~=0) = NaN;
                % Store Back As Double
                Resp.('q') = nReal;
            end
        end
    case 2 % LCS
        if exist('q','var')
            for kk = 1:length(Resp.('q'))
                % Extract Response LC
                dummy = Resp.('q')(kk).LCNUM;
                % Apply q < 10^-4 Failsafe
                dummy(dummy<10^-4) = NaN;
                % Check For Comples Response
                if ~isreal(dummy)
                    nReal = real(dummy);
                    nImag = imag(dummy);
                    % Set Entries With Imaginary Component = 0 to NaNs
                    nReal(nImag~=0) = NaN;
                    % Store Back As Double
                    Resp.('q')(kk).LCNUM = nReal;
                else
                    % Store Back
                    Resp.('q')(kk).LCNUM = dummy;
                end
            end
        end
end