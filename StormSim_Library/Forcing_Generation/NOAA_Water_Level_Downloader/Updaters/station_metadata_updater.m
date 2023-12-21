function [inventory] = station_metadata_updater(exp_url,options,inventory,ii)
% Read Station Metadata
[dummy] = station_metadata_reader(inventory,exp_url,options,ii);
% Reformat Metadata Structure
dummy = dummy.stations;
strd = dummy.products.products;
% Assign station details
inventory(ii).id = dummy.id;
inventory(ii).name = dummy.name;
inventory(ii).lon = dummy.lng;
inventory(ii).lat = dummy.lat;
inventory(ii).state = dummy.state;
inventory(ii).products = strd; % Station available products
inventory(ii).datums = dummy.datums.datums; % Station available datums
% For loop for converting datum values from ft to m
for jj = 1:length(inventory(ii).datums)
    inventory(ii).datums(jj).value = inventory(ii).datums(jj).value/3.28084; % 1 m = 3.28084 ft
end
end