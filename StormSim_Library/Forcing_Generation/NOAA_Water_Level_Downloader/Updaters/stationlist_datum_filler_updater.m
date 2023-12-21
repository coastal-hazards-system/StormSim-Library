function [StationList] = stationlist_datum_filler_updater(StationList,ii)
%{
This function fills out all stations (rows) in data structure with an empty value in the datum field.
An empty value means that the station only has its native datum available for
measurements (Station Datum [STND]).
%}


    % Check if station measured datums are empty
    dummy = isempty(StationList(ii).datums);
    % If it is empty fill out empty structure row with Station datum 
    if dummy == 1
        StationList(ii).datums.name = 'STND'; % datum name 
        StationList(ii).datums.description = 'Station Datum'; % datum description
        StationList(ii).datums.value = 0; % Datum value (vertical offset) 
    end


end
