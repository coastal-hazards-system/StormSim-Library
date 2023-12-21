function [StationList] = StationList_updater_function_2(station_IDs)
%{
This function is used to update the date ranges available for the tide gauges as
NOAA CO-OPS changes Preliminary measurements to verified measurements.
%}
% clc;clear all;
% %% LOAD STATIONLIST
% load('Functions/Station_inventory/Mat_files/StationListing_Final_V3.mat','StationList');

%% URL
% Station Inventory Page (in use)
inv_url = 'https://tidesandcurrents.noaa.gov/inventory.html?id=';
% Expand URL - Expand station metadata details (in use)
exp_url = 'https://tidesandcurrents.noaa.gov/mdapi/latest/webapi/stations/';
% Water Level Predictions Station Home Page
pred_url = 'https://tidesandcurrents.noaa.gov/noaatidepredictions/NOAATidesFacade.jsp?Stationid=';

% Update historical and active label
mes_url = 'https://tidesandcurrents.noaa.gov/mdapi/latest/webapi/stations.json?type=waterlevels';
options = weboptions('Timeout',300); % 5 minute timeout time suggested. Any less could result in error.
active = webread(mes_url,options);
active = {active.stations.id}';

active = sum(cell2mat(cellfun(@(x) contains(station_IDs,x),active,'UniformOutput',false)),1)';
dummy(active==1) = "active";
dummy(active==0) = "historical";

StationList = struct('id',station_IDs,'name',station_IDs,'lon',station_IDs,...
    'lat',station_IDs,'state',station_IDs,'products',station_IDs,...
    'datums',station_IDs,'datums_predictions',station_IDs,...
    'predictions_products',station_IDs,'WL_products',station_IDs,...
    'startDate',station_IDs,'endDate',station_IDs,...
    'region',station_IDs,'active_indx',cellstr(dummy));

%%%
timing.t1 = datetime('now');

%% GET STATION DETAILS - WORKING WITH HTML SCRIPT
for ii = 1:length(StationList)
    %Measurements Available
    try
        chk1 = strcmp(StationList(ii).startDate{1,1},'No Data Available')==0;
    catch
        chk1 = strcmp(StationList(ii).startDate,'No Data Available')==0;
    end
    % Predictions Available
    try
        chk2 = strcmp(StationList(ii).datums_predictions{1,1},'No Tidal Predictions')==0 |...
            strcmp(StationList(ii).datums_predictions{1,1},'Great Lakes Gauge. No Tidal Predictions')==0;
    catch
        chk2 = strcmp(StationList(ii).datums_predictions,'No Tidal Predictions')==0 |...
            strcmp(StationList(ii).datums_predictions,'Great Lakes Gauge. No Tidal Predictions')==0;
    end
    if chk1==1
        %% METADATA UPDATER
        % Get Station Datum 
        [StationList] = station_metadata_updater(exp_url,options,StationList,ii);
        % Fill Empty Datum with STND
        [StationList] = stationlist_datum_filler_updater(StationList,ii); % OK

        %% STATION INVENTORY HOMEPAGE HTML READER
        % Read Station Data Inventory
        [html_code] = station_inventory_html_reader(StationList,inv_url,options,ii);
        
        %% HTML WL PRODUCT (MEASURED) FINDER
        [StationList,indx] = measured_WL_product_finder(html_code,StationList,ii);
        
        %% HTML WL PRODUCT (MEASURED) DATE RANGE FINDER
        try
            [StationList] = measured_WL_products_daterange_finder(StationList,html_code,indx,ii);
            
            %% WL PRODUCT (MEASURED) RECORD LENGTH CALCULATOR
            [StationList] = record_length(StationList,ii);
        end
    end
    %% UPDATE LABELS 
    [StationList] = Label_correction(StationList);
      
    %% WATER LEVEL PREDICTIONS
    if chk2==1
        % Update available water level prediction download intervals
        % and datums
        % flag2 = 0 (tidal predictions exist) || flag2 = 1 (tidal predictions dont exist)
        flag2 = zeros(length(StationList),1);
        [StationList] = WL_prediction_datum_and_product_finder_updater(StationList,pred_url,options,flag2,ii);
    end
    
    %% UPDATE LABELS
    [StationList] = Label_correction(StationList);
    
end
timing.t2 = datetime('now');
timing.dt = timing.t2-timing.t1;
timing.runtime = char(timing.t2-timing.t1);
end