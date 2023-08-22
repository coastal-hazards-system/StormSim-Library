function  [Param, TC_SRR, TC_Freq, dist, TotalFreq, smpl0, smpl1, smpl2] = csh_probability_mass_loader(pm_path, region, Nsvpt)
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
    if contains(pm_version,'v2') % NACCS
        % Low intensity (LI) storm recurrence rate (SRR) at each CRL (storms/year/km).
        SRR_LI = load(fullfile(pm_path,'SRR_TC_LI_600km.mat'), 'SRR');SRR_LI = SRR_LI.SRR;
        % High intensity (HI) storm SRR at each CRL.
        SRR_HI = load(fullfile(pm_path,'SRR_TC_HI_600km.mat'), 'SRR');SRR_HI = SRR_HI.SRR;
        % Medium intensity (MI) storm SRR at each CRL.
        SRR_MI = load(fullfile(pm_path,'SRR_TC_MI_600km.mat'), 'SRR');SRR_MI = SRR_MI.SRR;
        % Compute Total SRR
        TC_SRR = [SRR_LI*600, SRR_MI*600, SRR_HI*600];
        TC_SRR(:, 4) = sum(TC_SRR,2);
        % Storms relative probability at each save point.
        Freq = load(fullfile(pm_path,[region '_TC_ProbMass_600km.mat']),'ProbMass');Freq = Freq.ProbMass;
        % NACCS Synthetic Storm Parameters
        Param = load(fullfile(pm_path,[region '_TC_Param_MasterTable.mat']),'Param_MT');Param = Param.Param_MT;
        % Low Intensity Storm Population
        smpl0 = Param(Param(:,7)<28,1); % Low Intensity
        % Mid Intensity Storm Population
        smpl1 = Param(Param(:,7)>=28 & Param(:,7)<48,1); % Mid Intensity
        % Low Intensity Storm Population
        smpl2 = Param(Param(:,7)>=48,1); % Low Intensity
    else
        try
            % Listing of closest (CRL) to each save point.
            load(fullfile(pm_path,[region '_CRL_ic.mat']),'ic');% nNodes x 1 (double)
            % Low intensity (LI) storm recurrence rate (SRR) at each CRL (storms/year/km).
            SRR_LI = load(fullfile(pm_path,'SRR_TC_LI.mat'), 'SRR');SRR_LI = SRR_LI.SRR;
            % High intensity (HI) storm SRR at each CRL.
            SRR_HI = load(fullfile(pm_path,'SRR_TC_HI.mat'), 'SRR');SRR_HI = SRR_HI.SRR;
            % Storms relative probability at each save point.
            load(fullfile(pm_path,[region '_TC_Freq_CRL.mat']),'Freq');
            % NACCS Synthetic Storm Parameters
            load(fullfile(pm_path,[region '_TC_Param.mat']),'Param');
            % Distance from region save points to region TCs' landfall or bypassing reference locations.
            load(fullfile(pm_path,[region '_TROP_dist.mat']),'TROP_dist');

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
            % Convert HI SRR to storms/year using a 400 km diameter.
            TC_SRR(1,2) = SRR_HI(ic(Nsvpt))*400;
            % SRR for all TC intensities.
            TC_SRR(1,3) = TC_SRR(1,1) + TC_SRR(1,2);
            % Get Frequency Vector
            TC_Freq = Freq(Nsvpt).TC;
            % Extract Distance Vector For Specified Save Point
            dist = TROP_dist(Nsvpt,:);
            % Get Total Frequency
            TotalFreq=sum(TC_Freq);
            % Find Storms Within 200 km radius
            dist200 = find(dist<=200);
            % Low Intensity Storm Population
            smpl0 = dist200(Param(dist200,5)<48);
            % High Intensity Storm Population
            smpl1 = dist200(Param(dist200,5)>=48);
            smpl2 = [];
        catch
            Param = [];
            TC_SRR = [];
            TC_Freq = [];
            dist = [];
            TotalFreq=[];
            smpl0 = [];
            smpl1 = [];
            smpl2 = [];
        end
    end
else
    Param = [];
    TC_SRR = [];
    TC_Freq = [];
    dist = [];
    TotalFreq=[];
    smpl0 = [];
    smpl1 = [];
    smpl2 = [];
end
end