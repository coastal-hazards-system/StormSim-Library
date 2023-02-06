function [STWAVE_headers_location,Tp_special] = chs_wave_model_header_locator(STWAVE)
    %{
    %% DESCRIPTION
        This function identifies the location and name of Hm0, Tp, wave dir columns
        in converted CHS wave model peaks file. This function was developed
        in order to account for the different wave models (STWAVE/WAM/SWAN)
        hosted in CHS. Additionally, this routine identifies if provided
        file provides Tp or Tm as output. Tp_special (0 -> Tp, 1 -> Tm)
        serves as the flag value. Conversion must be performed through the
        use of "chs_h5_converter.m" or "call_chs_h5_converter.m".
        
    %% INPUTS
        STWAVE: Converted CHS wave model XC/TC storm peaks. | struc | 1 x size_varies
        
        "STWAVE" Fields:
            STWAVE.
                Filename: Converted CHS filename. | char | 1 x size_varies
                Conv_Data: Converted CHS data. | struc | 1 x size_varies
    %% OUTPUTS
        STWAVE_headers_location: Table column name of Hm0, Tp and wave direction | struc | 1 x 3
                                 of provided CHS file.
        
        Tp_special: Flag value indicating that provided CHS file has Tm (1) | double | 1 x 1
                    instead of Tp (0).
      
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
    %}
    
    %% DETERMINE Hm0 DATA COLUMN LOCATION
    % Determine What Header To Call For Hm0
    headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
        {'Zero Moment Wave Height','Significant Wave Height','Significant Wave Height Total Sea'})==1),...
        STWAVE.Conv_Data.headers,'un',false));
    if isempty(headerIndx)
        % Throw Error
        error('Hm0 not found.');
    end
    % Define Posible Header Values
    headerName = {'Zero Moment Wave Height','Significant Wave Height','Significant Wave Height Total Sea'};
    % Store Header To Use
    STWAVE_headers_location.Hm0 = headerName{headerIndx};
    
    %% DETERMINE Tp DATA COLUMN LOCATION
    % Determine What Header To Call For Tp
    headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
        {'Peak Spectral Wave Period Total Sea','Peak Period','Smoothed Peak Period','Peak Wave Period'})==1),...
        STWAVE.Conv_Data.headers,'un',false));
    % Define Possible Header Values
    if isempty(headerIndx) % Final Option Try For Tm
        % Determine What Header To Call For Tm
        headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
            {'Mean Wave Period'})==1),...
            STWAVE.Conv_Data.headers,'un',false));
        % Flag For Special Case
        Tp_special = 1;
        % Unrecognized Header
        if isempty(headerIndx)
            % Throw Error
            error('Tp not found.');
        end
        % Define Posible Header Values
        headerName = {'Mean Wave Period'};
    else
        % Dataset Offers Tp
        Tp_special = 0;
        % Define Posible Header Values
        headerName = {'Peak Spectral Wave Period Total Sea','Peak Period','Mean Absolute Wave Period TM01','Peak Wave Period'};
    end
    % Store Header To Use
    STWAVE_headers_location.Tp = headerName{headerIndx};
    
    %% DETERMINE WAVE DIRECTION DATA COLUMN LOCATION
    % Determine What Header To Call For Hm0
    headerIndx = cell2mat(cellfun(@(x) find(strcmp(x,...
        {'Mean Wave Direction Total Sea','Mean Wave Direction'})==1),...
        STWAVE.Conv_Data.headers,'un',false));
    % Unrecognized Header
    if isempty(headerIndx)
        % Throw Error
        error('Mean Wave Direction not found.');
    end
    % Define Posible Header Values
    headerName = {'Mean Wave Direction Total Sea','Mean Wave Direction'};
    % Store Header To Use
    STWAVE_headers_location.wDir = headerName{headerIndx};
    
end