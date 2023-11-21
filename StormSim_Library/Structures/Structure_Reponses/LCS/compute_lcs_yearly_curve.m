function [Smax,SPcurves] = compute_lcs_yearly_curve(data,resp_vec,nYears)


% Define Years To Look For
years = [1:nYears];yBox = num2cell(zeros(size(years))');
dbug = num2cell(zeros(length(years),length(data)));
% Define Col Indexes For Peaks & Timeseries
switch size(data{1},2)
    case 10 % Timeseries
        % Storm Hydrograph Time Step Counter Col Index
        indx1 = 3;
        % Storm Year Col Index
        indx2 = 10;
        % Storm Hydrograph Length Col Index
        indx3 = 2;
    case 8 % Peaks
        % Storm Year Col Index
        indx2 = 1;
        % Storm Hydrograph Length Col Index
        indx3 = 2;
end
%
for jj = 1:length(years)
    for ii = 1:length(data)
        % Extract Storm Data From Life Cycle
        lc_data = data{ii};
        % Find Start Row of Each Concatenated Storm
        if exist('indx3','var') == 1 % Timeseries
            % Find Start Row of Each Concatenated Storm
            start_indx = find(lc_data(:,indx1)==0);
            % Extract Data Length Col
            dlen = lc_data(start_indx,indx3);
        else
            % Find Start Row of Each Concatenated Storm
            start_indx = [1:length(data)]';
            % Extract Data Length Col
            dlen = 0;
        end
        % Extract Strom Year Col
        dyear = lc_data(start_indx,indx2);
        % Get Indexes Of Storms Ocurring on Years(jj)
        yIndx = find(dyear==years(jj));
        dummy3 = start_indx(yIndx);
        % Get Length Of Storms Matching Years(jj)
        dlen = dlen(yIndx);
        % Get Storm Hydrograph Delimiters
        stm_beg = find(lc_data(:,indx1)==0);
        % Extract Strom Year Col
        dyear = lc_data(stm_beg,indx2);
        % Extract Data Length Col
        dlen = lc_data(stm_beg,indx3);
        % Get Indexes Of Stomrs Ocurring on Years(jj)
        wanted_years = find(dyear==years(jj));
        wanted_stm_beg = stm_beg(wanted_years);
        % Get Length Of Storms Matching Years(jj)
        dlen = dlen(wanted_years);
        % Cycle Throuigh Matching Storms
        if isempty(wanted_stm_beg)==0
            % Seaside
            yData = resp_vec{ii}(wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1);
            dbug{jj,ii} = yData;
            if ii==1
                yBox{jj} = max(yData);
            else
                yBox{jj} = [yBox{jj};max(yData)];
            end
        end
    end
end
SPcurves = cell2mat(cellfun(@(x) prctile(x,[10,16,84,90]),yBox,'un',false));
Smax = cell2mat(cellfun(@(x) mean(x,'omitnan'),yBox,'un',false));
end

