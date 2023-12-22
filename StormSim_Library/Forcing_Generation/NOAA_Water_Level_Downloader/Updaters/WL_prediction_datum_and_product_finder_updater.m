function [StationList] = WL_prediction_datum_and_product_finder_updater(StationList,pred_url,options,flag,ii)
%{
This function accesses the NOAA CO-OPS Tidal predictions webpage for each
station and extracts all the available datums through parsing in html code.
This function is the combination and optimization of
WL_prediction_datum_finder.m and predicted_WL_product_finder.m
%}
    %% DONWLOAD AND CLEAN HTML CODE
    % Check If Station Is on Great Lakes
    if sum(strcmp({StationList(ii).datums.name},'GL_LWD'))==0 && flag(ii) == 0
        % Read html code
        [html_code] = station_predictions_inventory_html_reader(StationList,pred_url,options,ii);
        % Extract string that includes all available prediction datums
        pred_indx = strfind(html_code,'<option');
        pred_datum = html_code(pred_indx(1):end);
        % Elminate everything below
        pred_indx = strfind(pred_datum,'</select>');
        pred_datum = pred_datum(1:pred_indx(1)-1);
        % Split resulting string to get datums
        pred_datum = cellstr(char(extractBetween(string(pred_datum),"""","""")));
        
        %% EXTRACT DATUMS
        % Compare with datum list of measured products
        chk = cell2mat(cellfun(@(c)strcmp(c,{StationList(ii).datums.name}'),pred_datum,'UniformOutput',false)');
        % Get row index of match strings
        [indx,col] = find(chk==1);
        
        %% GET MISSING INFORMATION FROM REFERENCE LIST
        % If avaialable prediction datums are not available in measured products datums
        if length(col)~=length(pred_datum)
            % Dummy vector
            dummy2 = [1:length(pred_datum)]';
            % Check what datums where not found
            [ia] = ismember(dummy2,col);
            [ia] = find(ia==0);
            % Load Reference List
            datums_reference = readcell('Measured_datums_reference_list.csv');
            % Find Datums in Reference List
            chk = cell2mat(cellfun(@(c)strcmp(c,datums_reference(:,1)),pred_datum(ia),'UniformOutput',false)');
            % Get Reference List Indexes
            [~,indx2] = max(chk);
        end
        
        %% DATA ASSIGNMENT - (DATUMS,DESCRIPTION,VALUE)
        if exist('indx2','var')==1
            StationList(ii).datums_predictions = struct('name',{StationList(ii).datums(indx).name,datums_reference{indx2,1}},'description',...
                {StationList(ii).datums(indx).description,datums_reference{indx2,2}},...
                'value',{StationList(ii).datums(indx).value,NaN(size(indx2))});
        else
            StationList(ii).datums_predictions = struct('name',{StationList(ii).datums(indx).name},'description',...
                {StationList(ii).datums(indx).description},'value',{StationList(ii).datums(indx).value});
        end
        
        %% CLEAN WORKSPACE
%         clearvars('-except','StationList','html_code','ii','pred_url');
        
        %% GET TIDAL PREDICTIONS DATA INTERVALS AVAILABLE
        % Find index of intervals available
        pred_indx = strfind(html_code,'<option id=''interval');
        % Eliminate everything above
        pred_interval = html_code(pred_indx(1):end);
        % Extract string that includes all available prediction intervals
        pred_indx = strfind(pred_interval,'</select>');
        % Eliminate everything below
        pred_interval = pred_interval(1:pred_indx(1)-1);
        % Get Tidal Predictions Interval Value
        pred_interval_value = cellstr(char(extractBetween(string(pred_interval)," value='","'")));
        % Get Tidal Predictions Interval Value
        pred_interval_description = cellstr(char(extractBetween(string(pred_interval),">","</option>")));
        % Check For Disabled Intervals - disable products will have style="display:none" disabled
        pred_interval_flag = cellstr(char(extractBetween(string(pred_interval),"value=",">")));
        % Correct If Needed
        pred_interval_value(cellfun('length',pred_interval_flag)>15) = [];
        pred_interval_description(cellfun('length',pred_interval_flag)>15) = [];
        % Assign To Data Structure
        StationList(ii).predictions_products = struct('value',pred_interval_value,'description',pred_interval_description);
        
    else
        StationList(ii).datums_predictions = 'Great Lakes Gauge. No Tidal Predictions';
        StationList(ii).predictions_products = 'Great Lakes Gauge. No Tidal Predictions';
    end
end