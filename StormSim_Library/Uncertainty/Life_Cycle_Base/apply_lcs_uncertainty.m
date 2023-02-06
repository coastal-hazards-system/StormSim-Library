function [project_forcing, structure2, emp_coeff2] = apply_lcs_uncertainty(config, project_forcing, structure, emp_coeff, data_type, u_struc, u_emp_coeff)
%% GRAB INFORMATION FROM "config"
nLC = config.mcs_nLC;
swl_u_a = config.chs_swl_u_a;
hm0_u_a = config.chs_hm0_u_a;
swl_u_r = config.chs_swl_u_r;
hm0_u_r = config.chs_hm0_u_r;
storm_sampling = config.storm_sampling;

%% GRAB INFORMATION FROM "structure"


%% APPLY UNCERTAINTY TO FORCING PARAMETERS
switch data_type
    case 'Peaks'
        %{
Need to zvals to cover dynamic UCLS not hardcoded
Do we want to mimic RB uncertainty to forcing given that its the latest
PCHA method?
     % Upper Confidence Limit
            %     UCL = 0; % Set upper confidence limit (percentage) UCL = '84', '90', '95', '98', or '0' (mean)
            % Z Scores
            % zval = [84,1;90,1.282;95,1.645;98,2];INPUT{4,7},INPUT{4,8},[nSim 1]); %Breakwater crest width
            % Apply Uncertainty Based On UCL
            %             if (UCL == 84 || UCL == 90 || UCL == 95 || UCL == 98)
            %                 % Water Level At UCL
            %                 Wucl = MCSimOUT(:,1) + WLe*zval(zval(:,1)==UCL,2);
            %                 % Shift WL To Specified Confidence Limit
            %                 Pt = (UCL/100)-(1-UCL/100) + 2*rand([nSim 1])*(1-UCL/100);
            %                 % Compute New Water Level With Uncertainty
            %                 WL = max(0.01,Wucl +(norminv(Pt,0,WLe)-norminv(UCL/100,0,WLe)));
            %             else
            % Compute New Water Level With Uncertainty
        %}
        % Apply Uncertainty
        for jj = 1:nLC
            % Water Level
            project_forcing(jj).LCNUM(:,4) = max(0.01,project_forcing(jj).LCNUM(:,4) + normrnd(0, swl_u_a, [length(project_forcing(jj).LCNUM(:,4)) 1]));
            % Wave Height
            project_forcing(jj).LCNUM(:,5) = max(0.01,project_forcing(jj).LCNUM(:,5) + normrnd(0, hm0_u_a, [length(project_forcing(jj).LCNUM(:,5)) 1]));
            % Apply Uncertainty To Empirical Coefficients
            if u_emp_coeff == 1
                % Get Empirical Coefficients Std
                std_val = struct2cell(emp_coeff.std);
                % Define structure fieldnames
                helperVar = fieldnames(emp_coeff);
                % Remove Std From List
                helperVar(~contains(helperVar,fieldnames(emp_coeff.std))) = [];
                % Build Var Table
                emp_coeff_std_vars = [helperVar,...
                    std_val];
                % For Each Coefficient
                for kk = 1:length(helperVar)
                    emp_coeff2(jj).(emp_coeff_std_vars{kk,1}) = normrnd(emp_coeff.(helperVar{kk}), emp_coeff_std_vars{kk,2}, size(project_forcing(jj).LCNUM(:,4)));
                end
            end
        end
    case 'Timeseries'
        % Apply Uncertainty
        for jj = 1:nLC
            % ---------- WATER LEVEL ----------
            % Create Proportional SWL Vector
            sigPropWL = project_forcing(jj).LCNUM(:,5).*swl_u_r;
            % Cap Values THat Exceed Absolute Uncertainty
            sigPropWL(sigPropWL>swl_u_a) = swl_u_a;
            % Apply Uncertainty To Water Level @ LC jj
            project_forcing(jj).LCNUM(:,5) = normrnd(project_forcing(jj).LCNUM(:,5),...
                abs(sigPropWL));
            % ---------- WAVE PARAMETERS ----------
            % Create Proportional Hm0 Vector
            sigPropHm0 = project_forcing(jj).LCNUM(:,6).*hm0_u_r;
            % Cap Values THat Exceed Absolute Uncertainty
            sigPropHm0(sigPropHm0>hm0_u_a) = hm0_u_a;
            % Apply Uncertainty To Hm0 @ LC jj
            project_forcing(jj).LCNUM(:,6) = abs(normrnd(project_forcing(jj).LCNUM(:,6),...
                sigPropHm0)); % Ensure Positive Wave heights
            % Apply Uncertainty To Tp @ LC jj\
            % No Tp UNcertainty In LAtest PCHA Need to Discuss
            % with Jeff For Equivalent
            % Apply Uncertainty To Empirical Coefficients
            if u_emp_coeff == 1
                % Get Empirical Coefficients Std
                std_val = struct2cell(emp_coeff.std);
                % Define structure fieldnames
                helperVar = fieldnames(emp_coeff);
                % Remove Std From List
                helperVar(~contains(helperVar,fieldnames(emp_coeff.std))) = [];
                % Build Var Table
                emp_coeff_std_vars = [helperVar,...
                    std_val];
                % For Each Coefficient
                for kk = 1:length(helperVar)
                    if ~ischar(emp_coeff_std_vars{kk, 2})
                        emp_coeff2(jj).(helperVar{kk}) = normrnd(emp_coeff.(helperVar{kk}), emp_coeff_std_vars{kk,2}, size(project_forcing(jj).LCNUM(:,6)));
                    end
                end
            end
        end
end

%% APPLY UNCERTAINTY TO STRUCTURAL PARAMETERS
if u_struc == 1
    % Define Crest Elevation Cap
    crest_elevation = config.crest_elevation.mean;
    % Get Empirical Coefficients Std
    std_val = struct2cell(structure.std);
    % Define structure fieldnames
    helperVar = fieldnames(structure);
    % Remove Std From List
    helperVar(~contains(helperVar,fieldnames(structure.std))) = [];
    %
    struc_std_vars = [helperVar,...
        std_val];
    % Get LC Sizes
    nSize = cellfun(@length, {project_forcing.LCNUM});
    % Apply Uncertainty To Each Parameter
    for ii = 1:length(struc_std_vars)
        % Assign Uncertain Values
        for jj = 1:nLC
            if ~ischar(struc_std_vars{ii, 2})
                % Apply Normal Random Uncertainty
                u_data = cell2mat(cellfun(@(x) normrnd(x,...
                    struc_std_vars{ii, 2},nSize(jj),1),...
                    {structure.(struc_std_vars{ii, 1})},...
                    'un', false));
                % Cap Crest Elevation
                if strcmp(struc_std_vars{ii, 1},'crest_elevation')
                    u_data(u_data>crest_elevation) = crest_elevation;
                end
                % Overwrite Data
                structure2(jj).(struc_std_vars{ii, 1}) = u_data;
            else
                structure2(jj).(struc_std_vars{ii, 1}) = structure.(struc_std_vars{ii, 1});
            end
        end

    end
end






end