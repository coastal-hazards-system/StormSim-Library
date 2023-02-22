function [storm, CHS_Data, prob_mass, config] = call_chs_data_formater(config)
        %{
    %% DESCRIPTION
        This function is responsible for reading, formatting and screening
        Coastal Hazards System (CHS) .h5 storm "Peaks" & "Timeseries"
        files. Additionally, it loads and formats TC's probability masses
        if supported by library. 
    
    %% INPUTS
        config.
            chs_files_2_convert: CHS files to convert. | cell | 1 x number_of_files (max 8)
            chs_files_2_convert_path: CHS files to convert path. | cell | 1 x number_of_files (max 8)
            use_timeseries: Enables the use of timeseries files. (0/1) | double | 1 x 1 
            storm_sampling: Storm sampling type.('TC','XC' or 'CC') | char | 1 x 2 
            wlp_switch: Enables the creation of Water Level Priority | double | 1 x 1
                        (WLP) dataset. Reuqires timeseries files. (0/1)
            whp_switch: Enables the creation of Wave Height Priority | double | 1 x 1
                        (WHP) dataset. Reuqires timeseries files. (0/1)
            project_name: CAST project name.(No spaces) | char | 1 x any_length 
            struc_id: CAST project structure/transect ID.(No spaces) | char | 1 x any_length 
        
    %% OUTPUTS
        Additional to data outputs 2 files are exported from this function.
        *_CHS_raw_files.mat: MAT-file containing converted CHS files 
                             with no screening applied to them.
        *_CHS_"region"_SP####.mat: MAT-file containing formated and  
                                   screened CHS peaks data.
        
        config.      
            sp_depth: CHS savepoint depth extracted from .h5 attributes. | double | 1 x 1
            sp_ID: CHS ADCIRC savepoint ID. | double | 1 x 1
            region: CHS file region. | char | 1 x 1
    
        storm: Data structure containing formated and screened CHS storm  | struc | size_varies
               peaks data. First level of data structure can have 'XC'
               and/or 'TC'. This depends on user provided CHS data files.
               Storm peaks datasets provided (Maxima, WLP, WHP) have the
               same format 4x1 matrix with cols: SWL,Hm0,Tp, wave dir. 
               Additional field labeled "removed_storms" is a structure
               containing removed storm IDs fore ach dataset. WHP and WLP
               datasets are optional and require the use_timeseries switch
               to be enabled in conjunction with WLP_switch/WHP_switch.
    
        "storm" Fields:
            storm.(storm_type).
                Maxima: Dataset is built using only CHS "Peaks"files.    | double | 1 x 4
                         ADCIRC (SWL) peak and STWAVE (Hm0,TP,wave dir)   
                         are matched together for each storm ID.  
 
                WLP: Dataset is built using ADCIRC "Peaks" file and 
                      STWAVE timeseries file to match peak water level
                      with its corresponding wave. A time window of +/- 3
                      hours is used to find nearest STWAVE data point. In
                      the case that ADCIRC peak resides outside the
                      temporal range of STWAVE timeseries output then a
                      "new" peak water level is computed from ADCIRC's
                      timeseries output by matching timesteps with STWAVE
                      and finding the maximum of the resulting water level
                      timeseries.
    
                WHP: Dataset is built using STWAVE "Peaks" file and 
                      ADCIRC timeseries file to match peak wave height
                      with its corresponding water level. A time window of +/- 3
                      hours is used to find nearest ADCIRC data point. In
                      the case that STWAVE model output offers water level
                      output, then that will be used instead.
 
                removed_storms - Structure containing removed storm IDs for | struc | size_varies
                                 each dataset in "storm". 
      
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
        %}
    %% GRAB INPUT FROM "config"
    %{
        This section meant to provide an easy way to make changes to config
        variable calls without having to alter core code.
    %}
    % Define CHS Files
    chs_files_2_convert = config.chs_files_2_convert(:,2);
    % Define CHS Paths
    chs_files_2_convert_paths = config.chs_files_2_convert_path;
    
    % Use Timeseries Switch
    use_timeseries = config.use_timeseries;
    % Storm Sampling
    storm_sampling = config.storm_sampling;
    % Water Level Priority Switch
    wlp_switch = config.mcs_create_wlp;
    % Wave Height Priority Switch
    whp_switch = config.mcs_create_whp;
    % Project Name 
    project_name = config.project_name;
    % Transect Id 
    struc_id = config.struc_id;
    % Structure Transect ID

    %% FILTER OUT FILES (IF NEEDED) BASED ON USER INPUT
    % Filter Out Timeseries Files (If Any)
    if use_timeseries == 0
        % Remove Timeseries
        chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'Peaks'}));
        chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'Peaks'}));
    end
    % Filter Out Files According To Sampling Scheme
    switch storm_sampling
        case 'XC'
            % Remove TCs
            chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'XC','XH'}));
            chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'XC','XH'}));
            % Keep Track Of File Requirement
            if use_timeseries == 1
                min_file_req = 4;
            else
                min_file_req = 2;
            end
        case 'TC'
            % Remove XCs
            chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'TC','TS'}));
            chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'TC','TS'}));
            % Keep Track Of File Requirement
            if use_timeseries == 1
                min_file_req = 4;
            else
                min_file_req = 2;
            end
        case 'CC'
            % Keep Track Of File Requirement
            if use_timeseries == 1
                min_file_req = 8;
            else
                min_file_req = 4;
            end
    end
    
    %% VERIFY FOR MINIMUM FILE REQUIREMENTS
    %{
    PROS
        2 XC Peaks and/or 2 TC Peaks Files (ADCIRC + STWAVE/WAM/SWAN)
    MCS/CSR
        2 XC Peaks and/or 2 TC Peaks Files (ADCIRC + STWAVE/WAM/SWAN)
        Optional
        Corresponding timeseries files (4 or 8 total files)
    %}
    if length(chs_files_2_convert)~=min_file_req
        error('Error ID: 001 | call_chs_data_parser.missing_dependency | Minimum CHS storm data requirements not met for specified inputs.');
    end
    
    %% EXTRACT SAVEPOINT ATTRIBUTES
    %{
        Grab savepoint dependant attributes such as: depth, regional study
        , ID, etc.
    %}
    % Grab ADCIRC Files
    CHS_file_ref = chs_files_2_convert(contains(chs_files_2_convert,{'ADCIRC'}));
    % Keep Only One File For Attributes
    CHS_file_ref = CHS_file_ref{1};
    try
        % Get H5 Info
        sp_depth = h5info(CHS_file_ref);
        % Need To Access Attributes Of First Storm
        sp_depth = sp_depth.Groups.Attributes;
        % Grab Save Point Depth
        config.sp_depth = str2double(sp_depth(strcmp({sp_depth.Name},{'Save Point Depth'})).Value);
    catch
        % Use Write In Value
        config.sp_depth = NaN;
    end
    % Extract Filename
    [~,CHS_file_ref,~] = fileparts(CHS_file_ref);
    % Split Into CHS Identifiers
    CHS_file_ref = strsplit(CHS_file_ref,'_');
    % Grab Savepoint ID
    config.sp_ID = str2double(CHS_file_ref{5}(3:end));
    % Grab CHS Region
    config.region = CHS_file_ref{1};
    % Correct For NACCS
    if strcmp(config.region,'CHS-NA')
        config.region = 'NACCS';
    end

    %% CONVERT CHS DATA
    %{
        Run provided CHS h5 files through h5 to MATLAB converter.
        Additionally, extract ADCIRC save point: depth, region, ID.
        Converted CHS data gets exported as .mats in CHS_Data folder.
        Exported .mat file naming convetion is tied to ADCIRC file region
        and save point ID. 
    %}
    % Append Filenames With Paths
    full_file_path = cellfun(@(x,y) [x filesep y],chs_files_2_convert_paths,chs_files_2_convert,'un',false);
    % 
    disp('Begin CHS h5 file conversion....');
    % Convert CHS Data
    CHS_Data = call_chs_h5_converter(full_file_path);
    % Export Data 
    save([project_name filesep struc_id filesep project_name '_'...
        struc_id '_CHS_' config.region '_SP' num2str(config.sp_ID) '_raw_files.mat'],'CHS_Data');
    
    %% FORMAT AND INSPECT CHS TROPICALS CYCLONES PEAKS DATA
    %{
    Extracts SWL, Hm0, Tp And wave direction from CHS "Peaks" storm files.
    %}
    if contains(config.storm_sampling,{'TC','CC','TS'})
        % Load Storm Probability Massess
        [prob_mass.Param, prob_mass.TC_SRR,...
            prob_mass.TC_Freq, prob_mass.dist, prob_mass.TotalFreq,...
            prob_mass.smpl0, prob_mass.smpl1] = csh_probability_mass_loader(config.region,config.sp_ID);
        % Format And Inspect Storm Peaks Files
        [config, storm.('TC'), storm.('TC').removed_storms, ~, ~, prob_mass] = call_chs_storm_quality_check(config, CHS_Data, prob_mass, 'TC',...
            use_timeseries, wlp_switch, whp_switch);
    end
    
    %% FORMAT CHS EXRTATROPICALS CYCLONES DATA
    %{
    Extracts SWL, Hm0, Tp And wave direction from CHS "Peaks" storm files.
   
    %}
    if contains(config.storm_sampling,{'XC','CC'})
        % Format And Inspect Storm Peaks Files
        [config, storm.('XC'), storm.('XC').removed_storms, config.Nyrs_XC, config.Nstm_XC, ~] = call_chs_storm_quality_check(config, CHS_Data, [], 'XC',...
            use_timeseries, wlp_switch, whp_switch);
    end
    
    %% TIMESERIES SWL PEAK REPLACER 
    storm = chs_timeseries_peak_replacer(storm);

    %% EXPORT PROJECT CONFIGURATION FILE & FORMATTED CHS DATA
    % Export Project Forcing 
    save([project_name filesep struc_id filesep project_name '_' struc_id '_CHS_' config.region '_SP' num2str(config.sp_ID) '.mat'],...
        'storm', 'prob_mass','config');
end