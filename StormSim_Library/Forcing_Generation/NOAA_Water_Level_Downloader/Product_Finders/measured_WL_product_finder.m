function [StationList,indx] = measured_WL_product_finder(html_code,StationList,ii)

    %% Find Products of interest (Water Levels)
% Isolate product name
products=cellstr(char(extractBetween(string(html_code),'''content'': ''',''', ''group'': ')));
indx = 1:length(products);
%{
% Find Products of interest (water levels: verified 6 minute & hourly wl)
% The availability of water level predictions was already addressed at 1st
% stage filtering (see stationlist_product_filter.m)

% Var List To Extract 
want = {'Verified 6-Minute Water Level','Verified Hourly Height Water Level','Verified Monthly Mean Water Level','Verified High/Low Water Level','Preliminary 6-Minute Water Level'};
% Compute Logical Matrix (Columns Correspond To Cases In want)
logical_matrix = cell2mat(cellfun(@(c)strcmp(c,products),want,'UniformOutput',false));
% Get Indexes of WL Products Of Interest
[indx,~] = find(logical_matrix==1);
 %}
% Store selected products in data structure
if sum(indx) > 0  
    WL_products = products(indx);
    StationList(ii).WL_products = WL_products;
else % if measured products are not found station only has predictions and/or monthly WL and/or preliminary data
    StationList(ii).WL_products = {'Water Level Prediction'};
end
   
    
end
