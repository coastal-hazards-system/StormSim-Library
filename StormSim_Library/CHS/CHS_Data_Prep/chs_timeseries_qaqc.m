function [storm2rm,WLP_matrix,WHP_matrix,storm2rm_WHP,storm2rm_WLP] = chs_timeseries_qaqc(storm2rm,...
        swl_peaks,hm0_peaks, swl_timeseries, hm0_timeseries,...
        has_WaterElevation, STWAVE_headers_location, WLP_switch, WHP_switch, Tp_special, sample_type)
    %{
    %% DESCRIPTION
        This function verifies if wave model timeseries outputs for all storms reside
        withing ADCIRC's model outputs temporal range. Storms that don't match
        this criterion will be listed and removed from dataset. Additionally,
        this function creates Water Level Priority (WLP) and Wave Height
        Priority (WHP) alternate datasets. Details as to how this is achieved
        are described in the sections below.
    
    %% INPUTS
        storm2rm: Identified NaN's in "Maxima" peaks dataset. (row id) | double | number_of_bad_storms x 1
        swl_peaks: CHS ADCIRC Peaks data. | table | number_of_storms x nFields
        hm0_peaks: CHS STWAVE/WAM/SWAN Peaks data. | table | number_of_storms x nFields
        swl_timeseries: CHS ADCIRC Tiemseries data. | table | number_of_storms x nFields
        hm0_timeseries: CHS STWAVE/WAM/SWAN Timeseries data. | table | number_of_storms x nFields
        has_WaterElevation: STWAVE/WAM/SWAN provides water elevation. | bool | 1 x 1
        STWAVE_headers_location: CHS STWAVE/WAM/SWAN Hm0, Tp, wave direction header location. | struc | 1 x 3
        WLP_switch: Create WLP dataset. | bool | 1 x 1
        WHP_switch: Create WHP dataset. | bool | 1 x 1
        sample_type: Storm type being processed. ('XC' or 'TC') | char | 1 x 2
        
    %% OUTPUTS
        storm2rm: Appended list of stroms to remove from "Maxima" dataset. | bool | 1 x number_of_bad_storms
        WLP_matrix: WLP peaks dataset. | double | number_of_matched_storms x 4
        WHP_matrix: WHP peaks dataset. | double | number_of_matched_storms x 4
        storm2rm_WHP: Storms to remove from WHP dataset (row id). | double | number_of_matched_storms x 1
        storm2rm_WLP: Storms to remove from WLP dataset (row id). | double | number_of_matched_storms x 1
    
    %% DEV SIGNATURE
    Developed by: Fabian A. Garcia Moreno ERDC-CHL
        %}
        
        %% INITIALIZE VARIABLES
        % Define Time Window +/- Threshold
        tdelta = datenum(0,0,0,3,0,0);
        % Get Storm IDs
        stmID = unique(str2double(swl_timeseries.("Storm ID")));
        % Remove Missing Storms
        stmID(storm2rm) = [];
        % Pre-Allocate Peaks Storage Variable
        storm_matrix = [zeros(length(stmID),4),stmID,zeros(length(stmID),1)]; % Water Level Priority Failsafe
        WLP_matrix = storm_matrix; % Water Level Priority
        WHP_matrix = storm_matrix; % Wave Height Priority
        
        %% COMMAND WINDOW PROMPT
        % Display Progress Step
        if strcmp(sample_type,'XC')
            disp(['Inspecting CHS extratropicals timeseries files for mismatched storms....']);
        else
            disp(['Inspecting CHS tropicals timeseries files for mismatched storms....']);
        end
        % Display Completion Progress Initial Print
        fprintf(1,'   Completion Progress: %3d%%\n',0);
        
        % Loop Through All Storms
        for stm = 1:length(stmID)
            
            %% BUILD WATER LEVEL PRIORITY PEAKS FAILSAFE
            %{
    Create storm peak dataset for each storm ID using ADCIRC and STWAVE
    timeseries files. Entry for specific storm ID will be called as a
    replacement when ADCIRC SWL peak timestamp (from "Peaks" file) +/-
    threshold is not found within STWAVE timeseries data. This also
    serves as the default check when using timeseries data because it
    ensures that ADCIRC timeseries date range covers STWAVE's data range.
        
                |------- STWAVE TIMESERIES -------|
        
           |------------ ADCIRC TIMESERIES ------------|
            %}
            % Print Completion Progress
            fprintf(1,'\b\b\b\b%3.0f%%',(100*(stm/length(stmID))));
            % Find Table Row To Extract
            eIndx = str2double(hm0_timeseries.("Storm ID"))==stmID(stm);
            wData.("ZeroMomentWaveHeight") = hm0_timeseries.(STWAVE_headers_location.Hm0){eIndx,1};
            wData.("PeakPeriod") = hm0_timeseries.(STWAVE_headers_location.Tp){eIndx,1};
            wData.("MeanWaveDirection") = hm0_timeseries.(STWAVE_headers_location.wDir){eIndx,1};
            wData.("yyyymmddHHMM") = hm0_timeseries.('yyyymmddHHMM'){eIndx,1};
            wData = struct2table(wData);
            % Find Table Row To Extract
            eIndx = str2double(swl_timeseries.("Storm ID"))==stmID(stm);
            % Define New Formatted Table
            wlData.("WaterElevation") = swl_timeseries.("Water Elevation"){eIndx,1};
            wlData.("yyyymmddHHMM") = swl_timeseries.('yyyymmddHHMM'){eIndx,1};
            wlData = struct2table(wlData);
            % Correct Date Format In Storm Data
            wlData.yyyymmddHHMM = wlData.yyyymmddHHMM;
            wData.yyyymmddHHMM = wData.yyyymmddHHMM;
            % Get STWAVE Time Vector
            tvector = datenum(wData.yyyymmddHHMM,'yyyymmddHHMM');
            % Get Beggining Of Time Window
            tmin = min(tvector);
            % Get End Of Time Window
            tmax = max(tvector);
            % Extract ADCIRC Time Vector
            ADCIRC_tvector = datenum(wlData.yyyymmddHHMM,'yyyymmddHHMM');
            % Extract ADCIRC Data Points Within Time Window
            wlData = wlData(ADCIRC_tvector>=tmin & ADCIRC_tvector<=tmax,:);
            if ~isempty(wlData)
                % Extract New ADCIRC TIme Vector
                ADCIRC_tvector = datenum(wlData.yyyymmddHHMM,'yyyymmddHHMM');
                % Find And Extract ADCIRC Storm Peak Water Level
                [wlPeak,wlIndx] = max(wlData.WaterElevation);
                % Find Wave Data Within WL Peak Time Stamp +/- Threshold
                wIndx = find(tvector>=ADCIRC_tvector(wlIndx)-tdelta & tvector<=ADCIRC_tvector(wlIndx)+tdelta);
                % Find Closest Wave Data Point To WL Peaks Time Stamp
                [~,dindx] = min(abs(tvector(wIndx)-ADCIRC_tvector(wlIndx)));
                % Extract Corresponding Wave Height
                wPeak = wData.ZeroMomentWaveHeight(wIndx(dindx));
                % Extract Corresponding Wave Peak Period
                wPeakTp = wData.PeakPeriod(wIndx(dindx));
                % Extract Corresponding Mean Wave Direction
                wPeakWdir = wData.MeanWaveDirection(wIndx(dindx));
                % Assign Peaks To Storage Variable
                storm_matrix(stm,1:4) = [wlPeak,wPeak,wPeakTp,wPeakWdir];
                % Add Peak Timestamp
                storm_matrix(stm,end) = ADCIRC_tvector(wlIndx);
            else
                % Assign Peaks To Storage Variable
                storm_matrix(stm,1:4) = [-99999,-99999,-99999,-99999];
                storm_matrix(stm,end) = -99999;
            end
            
            %% BUILD WATER LEVEL PRIORITY PEAKS DATASET
            %{
The idea is to build a storm peaks dataset while keeping ADCIRC storm peak
water level timestamp as a reference to find a corresponding Hm0,Tp, Wave
Direction. Logical Steps For Creating Dataset:

    1. Find peaks water level for stmID in ADCIRC "Peaks" file
    2. Find ADCIRC peak timestamp +/- threshold inside STWAVE timeseries file
    3. Find nearest datapoint to peak timestamp
    4. Extract corresponding Hm0,Tp,Wave Direction associated to peak water
    level
        
The reason for using peak value from "Peaks" file is because values
reported in "Peaks" files come directly from ADCIRC's .15 file (Max's).
This means the values of the peak are more accurate.
            %}
            
            % If Water Level Priority Switch Is Truned On
            if WLP_switch
                % Find Table Row To Extract
                eIndx = str2double(swl_peaks.("Storm ID"))==stmID(stm);
                try
                    % ADCIRC Peak Value (From Peaks File)
                    if sum(eIndx)~=0
                        helperVar = datenum(swl_peaks.('yyyymmddHHMM')(eIndx,1),'yyyymmddHHMM');
                        % Find STWAVE Timeseries Data Points Withing The +/- Time Window (tdelta)
                        wIndx = find(abs(tvector-helperVar)<=tdelta);
                        %                     if ~isempty(wIndx) % ADCIRC Peak Is Outside STWAVE Temporal Range
                        % Determine The CLoses Timestamp
                        [~,wIndx2] = min(abs(tvector(wIndx)-helperVar));
                        % Redefine Index To Final Selection
                        wIndx = wIndx(wIndx2);
                        % Assign Storm Data
                        try
                            WLP_matrix(stm,:) = [swl_peaks.('Water Elevation')(eIndx,1),...
                                wData.ZeroMomentWaveHeight(wIndx), wData.PeakPeriod(wIndx), wData.MeanWaveDirection(wIndx),...
                                stmID(stm), swl_peaks.('yyyymmddHHMM')(eIndx,1)];
                        catch
                            try
                                WLP_matrix(stm,:) = [swl_peaks.('WaterElevation')(eIndx,1),...
                                    wData.ZeroMomentWaveHeight(wIndx), wData.PeakPeriod(wIndx), wData.MeanWaveDirection(wIndx),...
                                    stmID(stm), swl_peaks.('yyyymmddHHMM')(eIndx,1)];
                            catch
                                WLP_matrix(stm,:) = storm_matrix(stm,:);
                            end
                        end
                    else % Compute "New" Peak Value From ADCIRC Timeseries
                        %
                        WLP_matrix(stm,:) = storm_matrix(stm,:);
                    end
                catch
                    WLP_matrix(stm,:) = [-99999,-99999,-99999,-99999,stmID(stm),-99999];
                end
                % Check For Special Tp Case
                if Tp_special == 1
                    WLP_matrix(stm,3) = WLP_matrix(stm,3).*1.2;
                end
            else
                WLP_matrix = [];
                storm2rm_WLP =[];
            end
            
            %% BUILD WATER LEVEL PRIORITY PEAKS DATASET
            %{
The idea is to build a storm peaks dataset while keeping STWAVE storm peak
Hm0,Tp, Wave Direction timestamp as a reference to find a corresponding water level.
In the case that wave model provides water level outputs those will be used
instead. Logical Steps For Creating Dataset:

    1. Find peaks Hm0,Tp,Wave Direction for stmID in STWAVE "Peaks" file
    2. Find ADCIRC peak timestamp +/- threshold inside STWAVE timeseries file
    3. Find nearest datapoint to peak timestamp
    4. Extract corresponding Hm0,Tp,Wave Direction associated to peak water
    level

The reason for using peak value from "Peaks" file is because values
reported in "Peaks" files come directly from ADCIRC's .15 file (Max's).
This means the values of the peak are more accurate.
            %}
            if WHP_switch
                % Execute Needed Case
                if has_WaterElevation == 1 % STWAVE Peaks File Has Water Elevation
                    % Find Table Row To Extract
                    eIndx = str2double(hm0_peaks.("Storm ID"))==stmID(stm);
                    try
                        % Grab Data
                        WHP_matrix(stm,:) = [hm0_peaks.('Water Elevation')(eIndx,1), hm0_peaks.(STWAVE_headers_location.Hm0)(eIndx,1),...
                            hm0_peaks.(STWAVE_headers_location.Tp)(eIndx,1), hm0_peaks.(STWAVE_headers_location.wDir)(eIndx,1),...
                            str2double(hm0_peaks.("Storm ID")(eIndx,1)), datenum(hm0_peaks.('yyyymmddHHMM')(eIndx,1),'yyyymmddHHMM')];
                    catch
                        try
                            % Grab Data
                            WHP_matrix(stm,:) = [hm0_peaks.('WaterElevation')(eIndx,1), hm0_peaks.(STWAVE_headers_location.Hm0)(eIndx,1),...
                                hm0_peaks.(STWAVE_headers_location.Tp)(eIndx,1), hm0_peaks.(STWAVE_headers_location.wDir)(eIndx,1),...
                                str2double(hm0_peaks.("Storm ID")(eIndx,1)), datenum(hm0_peaks.('yyyymmddHHMM')(eIndx,1),'yyyymmddHHMM')];
                        catch % Flag As Bad Storm
                            WHP_matrix(stm,:) = [-99999, -99999, -99999, -99999, stmID(stm), -99999];
                        end
                    end
                else % Grab Water Elevation From ADCIRC Timeseries
                    % Find Table Row To Extract
                    eIndx = str2double(hm0_peaks.("Storm ID"))==stmID(stm);                  
                    if sum(eIndx)~=0 % try
                        % ADCIRC Peak Value (From Peaks File)
                        helperVar = datenum(hm0_peaks.('yyyymmddHHMM')(eIndx,1),'yyyymmddHHMM');
                        % Find STWAVE Timeseries Data Points Withing The +/- Time Window (tdelta)
                        wIndx = find(abs(ADCIRC_tvector-helperVar)<=tdelta);
                        % Determine The CLoses Timestamp
                        [~,wIndx2] = min(abs(ADCIRC_tvector(wIndx)-helperVar));
                        % Redefine Index To Final Selection
                        wIndx = wIndx(wIndx2);
                        % Assign Storm Data
                        try
                            WHP_matrix(stm,:) = [wlData.('Water Elevation')(wIndx,1), hm0_peaks.(STWAVE_headers_location.Hm0)(eIndx,1),...
                                hm0_peaks.(STWAVE_headers_location.Tp)(eIndx,1), hm0_peaks.(STWAVE_headers_location.wDir)(eIndx,1),...
                                str2double(hm0_peaks.("Storm ID")(eIndx,1)), helperVar];
                        catch
                            try
                                WHP_matrix(stm,:) = [wlData.('WaterElevation')(wIndx,1), hm0_peaks.(STWAVE_headers_location.Hm0)(eIndx,1),...
                                    hm0_peaks.(STWAVE_headers_location.Tp)(eIndx,1), hm0_peaks.(STWAVE_headers_location.wDir)(eIndx,1),...
                                    str2double(hm0_peaks.("Storm ID")(eIndx,1)), helperVar];
                            catch
                                WHP_matrix(stm,:) = [-99999,-99999,-99999,-99999,stmID(stm), -99999];
                            end
                        end
                    else % catch
                        WHP_matrix(stm,:) = [-99999,-99999,-99999,-99999,stmID(stm), -99999];
                    end
                end
                % Check For Special Tp Case
                if Tp_special == 1
                    WHP_matrix(stm,3) = WLP_matrix(stm,3).*1.2;
                end
            else
                WHP_matrix = [];
                storm2rm_WHP =[];
            end
            clearvars('wData','wlData');
        end % end stm
        disp('');
        
        %% ADD INVALID STORMS TO STORM REMOVAL INDEX
        % Storms To Remove From Maxima Dataset
        storm2rm = sort([storm2rm;storm_matrix(sum(storm_matrix==-99999,2)>=1,5)],'ascend');
        % Storms To Remove From WLP Dataset
        if WLP_switch
            storm2rm_WLP = sort(WLP_matrix(sum(WLP_matrix==-99999,2)>=1,5),'ascend');
        end
        % Storms To Remove From WHP Dataset
        if WHP_switch
            storm2rm_WHP = sort(WHP_matrix(sum(WHP_matrix==-99999,2)>=1,5),'ascend');
        end

end