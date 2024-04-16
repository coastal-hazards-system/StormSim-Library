function [nearest_lat, nearest_lon, within_radius, min_distance, index] = find_nearest_latlon(target_lat, target_lon, latitudes, longitudes, max_radius_km)
% Convert latitude and longitude from degrees to radians
target_lat = deg2rad(target_lat);
target_lon = deg2rad(target_lon);
latitudes = deg2rad(latitudes);
longitudes = deg2rad(longitudes);

% Compute differences
dlat = latitudes - target_lat;
dlon = longitudes - target_lon;

% Haversine formula
a = sin(dlat/2).^2 + cos(target_lat) * cos(latitudes) .* sin(dlon/2).^2;
c = 2 * atan2(sqrt(a), sqrt(1-a));
distance_km = 6371 * c; % Radius of the Earth is approximately 6371 km

% Find minimum distance within max_radius_km
if isempty(max_radius_km)
    % Output nearest latitude and longitude
    nearest_lat = rad2deg(latitudes);
    nearest_lon = rad2deg(longitudes);
    within_radius = [];
    [min_distance,index] = min(distance_km);
    % Output nearest latitude and longitude
    nearest_lat = rad2deg(latitudes(index));
    nearest_lon = rad2deg(longitudes(index));
else
    within_radius = distance_km <= max_radius_km;
    [min_distance,index] = min(distance_km(within_radius));
    % Output nearest latitude and longitude
    nearest_lat = rad2deg(latitudes(index));
    nearest_lon = rad2deg(longitudes(index));
end
end