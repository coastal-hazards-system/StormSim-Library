function [Smax,SPcurves,yBox,dbug] = compute_lcs_yearly_curve(data,resp_vec,nYears, dbug_type)


% Define Years To Look For
years = [1:nYears];yBox = num2cell(zeros(size(years))');
dbug = num2cell(nan(length(years),length(data)));
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
            % Grab All Storm Data Associated To Specific Year
            yData = resp_vec{ii}(wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1);
            if dbug_type == 1
                dbug{jj,ii} = [repmat(ii,length([wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1]),1), lc_data(wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1,:)];
            else
                dbug{jj,ii} = yData;%wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1;
            end
            % Check If We Have Multiple Storms 
            if length(dlen)>1
                % Find Individual Storm Max Response 
                yData = arrayfun(@(x,y) max(resp_vec{ii}(x:x+y-1)),wanted_stm_beg, dlen, 'un', true);
            else
                yData = max(yData);
            end
            if ii==1
                yBox{jj} = yData;
            else
                yBox{jj} = [yBox{jj};yData];
            end
        end
    end
end
%
% yBox = mean(cell2mat(cellfun(@(x) max(x), dbug, 'un', false)), 2, 'omitnan');
%
SPcurves = cell2mat(cellfun(@(x) prctile(x,[10,16,84,90]),yBox,'un',false));
Smax = cell2mat(cellfun(@(x) mean(x,'omitnan'),yBox,'un',false));
end

