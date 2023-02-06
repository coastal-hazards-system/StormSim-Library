function  [Param, TC_SRR, TC_Freq, dist, TotalFreq, smpl0, smpl1] = csh_probability_mass_loader(region,Nsvpt)
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
    
    %% LOAD FILES BASED ON REGION
    if exist('MCSim_Inputs','dir')
        if contains(region,{'NACCS','CHS-NA'}) % NACCS
            % Listing of closest (CRL) to each save point.
            load(['MCSim_Inputs' filesep 'NACCS' filesep,'NACCS_CRL_ic.mat']);
            % Low intensity (LI) storm recurrence rate (SRR) at each CRL (storms/year/km).
            SRR_LI = load(['MCSim_Inputs' filesep 'NACCS' filesep,'SRR_TC_LI.mat']);SRR_LI = SRR_LI.SRR;
            % High intensity (HI) storm SRR at each CRL.
            SRR_HI = load(['MCSim_Inputs' filesep 'NACCS' filesep,'SRR_TC_HI.mat']);SRR_HI = SRR_HI.SRR;
            % Storms relative probability at each save point.
            load(['MCSim_Inputs' filesep 'NACCS' filesep,'NACCS_TC_Freq_CRL.mat']);
            % NACCS Synthetic Storm Parameters
            load(['MCSim_Inputs' filesep 'NACCS' filesep,'NACCS_TC_Param.mat']);
            % Distance from region save points to region TCs' landfall or bypassing reference locations.
            load(['MCSim_Inputs' filesep 'NACCS' filesep,'NACCS_TROP_dist.mat']);
            
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
        else
            Param = [];
            TC_SRR = [];
            TC_Freq = [];
            dist = [];
            TotalFreq=[];
        end
    else
        Param = [];
        TC_SRR = [];
        TC_Freq = [];
        dist = [];
        TotalFreq=[];
    end
end