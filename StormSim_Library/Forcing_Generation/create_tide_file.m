function [StationList, Sdata] = create_tide_file(station, datum, start_date, outName)
% create_tide_file Downloads a Year's worth of tidal predictions from NOAA
% CO-OPS API. Stations location and data availability can be found  
% <a href="matlab: web('https://tidesandcurrents.noaa.gov/stations.html?type=Water+Levels')">here</a>.
%
% Inputs:
%       station: NOAA CO-OPS unique station identifier. Number string with
%                7 characters (i.e. '8638660').
%
%       datum: Preferred vertical datum. The fucntion supports 
%              Mean Sea Level ('MSL') & North American Vertical Datum 1988
%              ('NAVD').
%       
%       start_date: Start date for data download. Must be a datesring with  
%                   'yyyy-mm-dd HH:MM:SS' format. Time must be in the GMT 
%                   timezone. Data and product availability can be seen in
%                   the station's data inventory page.
%
%       end_date: End date for data download. Must be a datesring with  
%                 'yyyy-mm-dd HH:MM:SS' format. Time must be in the GMT 
%                 timezone. Data and product availability can be seen in
%                 the station's data inventory page.
%
%       outName: Output file name and location (.csv).
%
% Outputs:
%       Sdata: Downloaded tidal prediction dataset.
%
%       StationList: Requested station metadata.
%
%       tidal_file: Downloaded preedcition data is written to a CSV file
%       under outName.
%
% Example Usage:
%       data = create_tide_file('1617760', 'MSL', '1975-01-01 00:00:00', '1976-01-021 00:00:00', outName)

%% INPUTS 
% Define Station IDs (Only Fill If selectionType == 1)
config.stationIDs = station;
% Desired product {'Verified Hourly Height Water Level','Verified 6-Minute Water Level','Verified Monthly Mean Water Level','Preliminary 6-Minute Water Level'};
config.prod = {'Verified Hourly Height Water Level'};
% Operational Mode 
config.opMode = 2;% (1 - Full Record, 2 - Specific Date, 3 - Prediction Only) 
% Dates of interest (Only if opMode == 2 or 3)
config.dBeg = datenum(start_date, 'yyyy-mm-dd HH:MM:SS');
config.dEnd = config.dBeg + datenum(1,0,0,0,0,0);

% Tide File Name (Only if opMode == 3)
[fpath, fname,~] = fileparts(outName); % Ensure CSV Is Being Written 
config.tide_file = fullfile(fpath, [fname '.csv']);

%% PULL STATIONS METADATA & DATA INVENTORY
    disp(['Pulling station ' station ' metadata...']);
% Scans Station Data Inventory HTML Code To Update Data Availability
[StationList] = StationList_updater_function(config.stationIDs);

%% ENSURE 1 YEAR OF DATA IS DOWNLOADED AND AVAILABLE
% Look Into Hourly Products 
wl_prod_indx = strcmp(config.prod, StationList.WL_products);
% Grab Data Ranges
dates_avail = [StationList.startDate(wl_prod_indx),StationList.endDate(wl_prod_indx)];
dates_avail = cell2mat(cellfun(@(x) datenum(x(1:end-4),'yyyy-mm-dd HH:MM:SS'), dates_avail, 'un', false));
% Find What Entry Covers Date Range 
d_indx = config.dBeg>=dates_avail(:,1) & config.dBeg<=dates_avail(:,2);
% Try And Make Corrections (If Needed)
if sum(d_indx) == 0
    % Prompt User
    disp(['Could not find a continous year of tidal predictions starting on ' start_date '.' newline 'Trying to find valid date range.']);
    % Check Product Dt
    dt = dates_avail(:,2) - dates_avail(:,1);
    [~,dt_max] = max(dt);
    % Find The Product With 1 Year
    dt_indx = find(dt>=datenum(1,0,0,0,0,0) == 1);
    % Keep The First Entry
    if isempty(dt_indx)
        % Could Not Find A Years Worth Of Data
        error('Verify station data ranges. Could not find a years worth of data.');
    else
        dt_indx = dt_indx(dt_max);
        % End Date
        config.dEnd = dates_avail(dt_indx,2);
        config.dBeg = config.dEnd - datenum(1,0,0,0,0,0);
        disp(['New date range is: ' datestr(config.dBeg,'yyyy-mmm-dd HH:MM:SS') ' - ' datestr(config.dEnd,'yyyy-mmm-dd HH:MM:SS')]);
    end
end
disp(['Requested data is available...'  newline 'Downloading hourly tidal predictions for: ' StationList.name ' (' StationList.id ')...']);
%% DOWNLOAD/LOAD DATA FOR STATIONS
% Download Specified Product @ Specified Datum (Only supports MSL or NAVD88)
[Sdata,notFound] = WL_downloader_V2({StationList.id},StationList, datum, config.prod,config.opMode,config.dBeg,config.dEnd);

%% CREATE TIDAL FILE (MEANT FOR 1 STATION)
% Parse Tidal File
data = [[{'Date'},{'Prediction [m]'}];cellstr(datestr(Sdata.TP.DateTime,'mm-dd-yyyy HH:MM')),...
    num2cell(Sdata.TP.Prediction)];
% Write Tidal File
writecell(data,config.tide_file);
end