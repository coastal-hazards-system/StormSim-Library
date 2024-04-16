function  [Param, TC_SRR, TC_Freq, TotalFreq, smpl1, smpl2, smpl3] = csh_probability_mass_loader(pm_path, region, Nsvpt)
%{
    %% DESCRIPTION
        This function is responsible for leading CHS TC storm probability
        masses. Files loaded are controlled by the CHS region being 
        requested. These files are necessary if performing any kind of TC 
        storm sampling method.
        
    %% INPUTS
        region: CHS region being requested. | char | 1 x size_varies
        Nsvpt: CHS ADCIRC savepoint ID. | double | 1 x 1

    %% OUTPUTS
        Param:
        TC_SRR:
        TC_Freq:
        dist:
        TotalFreq:
      
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
% Get Versioning From Path (Temporary)
pm_version = strsplit(pm_path, filesep);
pm_version = pm_version{end};

%% LOAD FILES BASED ON REGION

% Load According To Region (this will be replaced with PM v2)
if exist(pm_path,'dir')
    switch pm_version
        case {'CHS-NA', 'NACCS'}
            % Make Sure TO Correct NACCS
            pm_version = 'CHS-NA';
            try
                % Listing of closest (CRL) to each save point.
                load(fullfile(pm_path,[pm_version '_CRL_ic.mat']),'ic');% nNodes x 1 (double)
                % Low intensity (LI) storm recurrence rate (SRR) at each CRL (storms/year/km).
                SRR_LI = load(fullfile(pm_path,'SRR_TC_LI.mat'), 'SRR');SRR_LI = SRR_LI.SRR;
                % High intensity (HI) storm SRR at each CRL.
                SRR_HI = load(fullfile(pm_path,'SRR_TC_HI.mat'), 'SRR');SRR_HI = SRR_HI.SRR;
                % Storms relative probability at each save point.
                load(fullfile(pm_path,[pm_version '_TC_Freq_CRL.mat']),'Freq');
                % NACCS Synthetic Storm Parameters
                load(fullfile(pm_path,[pm_version '_TC_Param.mat']),'Param');
                % Distance from region save points to region TCs' landfall or bypassing reference locations.
                load(fullfile(pm_path,[pm_version '_TROP_dist.mat']),'TROP_dist');

                %{
                Load storm recurrence rate (SRR) associated with project save point. The
                SRR was computed at 200 coastal reference locations (CRL) and the SRR from the closest CRL to the
                savepoint is used.

                            The SRR was converted to storms per year by
                multiplying by 400 km to represent the recurrence rate associated with
                storms passing within 200 km of the coastal reference location (CRL)
                closest to save point
                %}
                %%%% NEED TO ADD CASES WITH MORE INTENSITY LEVELS (400 km diameter might change)
                % Convert LI SRR to storms/year using a 400 km diameter.
                TC_SRR = SRR_LI(ic(Nsvpt))*400;
                % Mid Intensity
                TC_SRR(1,2) = 0; % No Mid Intensity Storms
                % Convert HI SRR to storms/year using a 400 km diameter.
                TC_SRR(1,3) = SRR_HI(ic(Nsvpt))*400;
                % SRR for all TC intensities.
                TC_SRR(1,4) = sum(TC_SRR);
                % Get Frequency Vector
                TC_Freq = Freq(Nsvpt).TC;
                % Extract Distance Vector For Specified Save Point
                dist = TROP_dist(Nsvpt,:);
                % Get Total Frequency
                TotalFreq=sum(TC_Freq);
                % Find Storms Within 200 km radius
                dist200 = find(dist<=200);
                % Low Intensity Storm Population
                smpl1 = dist200(Param(dist200,5)<48);
                % High Intensity Storm Population
                smpl3 = dist200(Param(dist200,5)>=48);
                %
                smpl2 =  [];% Mid Intensity
            catch
                Param = [];
                TC_SRR = [];
                TC_Freq = [];
                dist = [];
                TotalFreq=[];
                smpl1 = [];
                smpl3 = [];
                smpl2 = [];
            end
        otherwise %{'CHS-NA','CHS-SA','CHS-GoM','CHS-PR','CHS-TX','CHS-LA'}
            % CRL location info
            CRL = dload([pm_path filesep '..' filesep,'CHS_Atl_CRLs_v1.6.mat']);
            % Low intensity (LI) storm recurrence rate (SRR) at each CRL (storms/year/km).
            SRR_LI = dload([pm_path filesep '..' filesep,'SRR_TC_LI_600km.mat']);%SRR_LI = SRR_LI.SRR;
            % High intensity (MI) storm SRR at each CRL.
            SRR_MI = dload([pm_path filesep '..' filesep,'SRR_TC_MI_600km.mat']);%SRR_MI = SRR_MI.SRR;
            % High intensity (HI) storm SRR at each CRL.
            SRR_HI = dload([pm_path filesep '..' filesep,'SRR_TC_HI_600km.mat']);%SRR_HI = SRR_HI.SRR;
            % All storm SRR at each CRL.
            SRR_All = dload([pm_path filesep '..' filesep,'SRR_TC_All_600km.mat']);%SRR_HI = SRR_HI.SRR;
            %             % Storms relative probability at each save point.
            %             ProbMass = dload([pm_path filesep,[region,'_TC_ProbMass_600km.mat']]);
            %             % NACCS Synthetic Storm Parameters
            %             Param = dload([pm_path filesep,[region,'_TC_Param_MasterTable.mat']]);
            % Storms relative probability at each save point.
            ProbMass = dload([pm_path filesep,[region,'_ITCS_DSW_600km.mat']]);
            % NACCS Synthetic Storm Parameters
            Param = dload([pm_path filesep,[region,'_ITCS_Param.mat']]);
            %{
                Load storm recurrence rate (SRR) associated with project save point. The
                SRR was computed at 1050 coastal reference locations (CRL) and the SRR from the closest CRL to the
                savepoint is used.

                            The SRR was converted to storms per year by
                multiplying by 600 km to represent the recurrence rate associated with
                storms passing within 200 km of the coastal reference location (CRL)
                closest to save point
            %}
            switch pm_version
                case 'CHS-LA'
                    % Load Grid Files
                    load(fullfile(pm_path, 'CHS-LA_ADCIRC_SPs.mat'), 'SPs');  % SPs
                    % Load Selected Nodes List
                    load(fullfile(pm_path, 'CHS-LA_staID.mat'), 'staID');
                    % Get Row
                    adcirc_node_id = SPs(SPs(:,1) == Nsvpt, 2);
                    % Find Correct Row ID For DSWs
                    bias_indx = find(staID(:,2) == adcirc_node_id); % Row INdex For Bias And Uncertainty
                    % Define Latitude Column
                    col_indx = 3;
                case 'CHS-SA'
                    % Load Grid Files
%                     nodeID = dload(fullfile(pm_path, 'CHS-SA_nodeID.mat'), 'nodeID');  % Nodes
%                     %
%                     staID = dload(fullfile(pm_path, 'SACS_NCSFL_staID.mat'), 'staID');  % SPs
%                     % Find Nearest Node
%                     [~, ~, ~, ~, bias_indx] = find_nearest_latlon(staID(staID(:,1) == Nsvpt, 2), staID(staID(:,1) == Nsvpt, 3), nodeID(:, 3), nodeID(:, 4), []);
%                     % 
%                     col_indx = 3;
%                     % Rename Variable To Search CRLs
%                     staID = nodeID;
                   % Load Grid Files
                    staID = dload(fullfile(pm_path, 'SACS_NCSFL_staID.mat'), 'staID');  % SPs
                    % Find Correct Row ID For DSWs
                    bias_indx = find(staID(:,1) == Nsvpt); % Row INdex For Bias And Uncertainty
                    % Define Latitude Column
                    col_indx = 2;  
                otherwise
                    % Savepoint location info
                    staID = dload([pm_path filesep,[region,'_staID.mat']]); % staID -> [SP_ID Node_ID Lon Lat Depth]
                    % Define Row Index
                    bias_indx = find(staID(:, 1) == Nsvpt);
                    % Define Latitude Column
                    col_indx = 2;
            end
            % Find CRL closest to savepoint
            [nearest_lat, nearest_lon, ~, dist, ~] = find_nearest_latlon(staID(bias_indx, col_indx), staID(bias_indx, col_indx+1), CRL(:,1), CRL(:,2), []);
            [~, ic] = min(dist); % km

            % Convert LI SRR to storms/year using a 600 km diameter.
            TC_SRR = SRR_LI(ic)*600;
            % Convert MI SRR to storms/year using a 600 km diameter.
            TC_SRR(1,2) = SRR_MI(ic)*600;
            % Convert HI SRR to storms/year using a 600 km diameter.
            TC_SRR(1,3) = SRR_HI(ic)*600;
            % SRR for all TC intensities.
            TC_SRR(1,4) = SRR_All(ic)*600;
            % Get Frequency Vector
            TC_Freq = ProbMass;
            % Get Total Frequency
            TotalFreq=sum(TC_Freq);

            % Find storms within 200 km of savepoint
            trk_dist=200;
            trk_lat=Param(:,4); trk_lon=Param(:,5);
            dist200=find(dist<=trk_dist);

            % Low Intensity Storm Population
            smpl1 = dist200(Param(dist200,7)<28);
            % Medium Intensity Storm Population
            smpl2 = dist200((Param(dist200,7)>=28) & (Param(dist200,7)<48));
            % High Intensity Storm Population
            smpl3 = dist200(Param(dist200,7)>=48);
            % Make DP Col Be The 5
            Param = [Param(:,1:4), Param(:,7), Param(:,5:6)];
    end
else
    Param = [];
    TC_SRR = [];
    TC_Freq = [];
    dist = [];
    TotalFreq=[];
    smpl1 = [];
    smpl3 = [];
    smpl2 = [];
end
end