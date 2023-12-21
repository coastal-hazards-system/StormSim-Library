function [StationList] = measured_WL_products_daterange_finder(StationList,html_code,indx,ii)   
% Find initial dates index
    st_indx = strfind(html_code,'popstart');
    st_indx = st_indx' + 11;
    % Find end dates index
    end_indx = strfind(html_code,'popend');
    end_indx = end_indx' + 9;
    % Build datestring array
    for jj = 1:length(st_indx)
    st_dates(jj,:) = {html_code(st_indx(jj):st_indx(jj)+22)}; % Inital date string 
    end_dates(jj,:) = {html_code(end_indx(jj):end_indx(jj)+22)}; % End date string 
    end
    if ~isempty(st_indx)
        % Assign datestring array to corresponding station in data structure
        StationList(ii).startDate = st_dates(indx);
        StationList(ii).endDate = end_dates(indx);
    else
        % If stardate & endate are empty fields station only has predictions
        % Fill empty cell with 'Prediction' for uniformity (also station probably
        % has monthly and/or preliminary water level measurements)
        StationList(ii).startDate = {'Predictions'};
        StationList(ii).endDate = {'Predictions'};
    end
end