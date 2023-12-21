function [StationList] = Label_correction(StationList)

% Great Lakes Unique ID's
ids = ['901';'903';'904';'905';'906';'907';'908';'909';'831'];
% Initialize Index Vector
indx=[];
% Get StationList ID's
dummy = {StationList.id}';
% Only Keep First Three Digits
dummy = cell2mat(cellfun(@(x) x(1:3), dummy, 'un', 0));
% Find Great Lake Gauges In StationList
for ii = 1:length(ids)
    % Get Matching Indexes
    dummy2 = find(strcmp(string(ids(ii,:)),dummy)==1);
    % Store Indexes
    indx = [indx;dummy2];
end
% Create Logical Vector
dummy = ismember([1:length(StationList)]',indx);
GLindx = find(dummy==1);
for hh = 1:length(GLindx)
    if strcmp(StationList(GLindx(hh)).datums.name,'STND')==1
        StationList(GLindx(hh)).datums.name = 'GL_LWD';
        StationList(GLindx(hh)).datums.description = 'Great Lakes Lower Water Datum';
        StationList(GLindx(hh)).datums.value = 'Unknown';
    end
    if strcmp(StationList(GLindx(hh)).WL_products,'Water Level Prediction')==1
        StationList(GLindx(hh)).WL_products = 'No Data Available';
        StationList(GLindx(hh)).startDate = 'No Data Available';
        StationList(GLindx(hh)).endDate = 'No Data Available';
        StationList(GLindx(hh)).record_length = 'No Data Available';
        StationList(GLindx(hh)).record_length_vector = 'No Data Available';
    end
    
end

% Find Non Great Lake Stations
nIndx = find(dummy==0);
% Find Non Great Lakes Stations With GL Flag
for ii = 1:length(nIndx)
    if length(StationList(nIndx(ii)).datums_predictions)==39
        % Correct GL Flag
        StationList(nIndx(ii)).datums_predictions = 'No Tidal Predictions';
        StationList(nIndx(ii)).predictions_products = 'No Tidal Predictions';
    end
end

end

