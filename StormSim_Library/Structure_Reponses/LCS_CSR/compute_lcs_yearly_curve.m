function [Smax,SPcurves,yBox] = compute_lcs_yearly_curve(data, resp_vec, nYears)


% Define Years To Look For
years = [1:nYears];yBox = num2cell(zeros(size(years))');
%
for jj = 1:length(years)
    for ii = 1:length(data)
        % Extract Storm Data From Life Cycle
        lc_data = data{ii};
        % Get Storm Hydrograph Delimiters
        if size(data{1},2) == 10
            stm_beg = find(lc_data(:, 10)==0);
            dlen = diff(find([lc_data(:, 10);0]==0));
        else
            stm_beg = [1:length(lc_data(:, 1))]';
            dlen = ones(size(stm_beg));
        end
        % Extract Strom Year Col
        dyear = lc_data(stm_beg, 3);
        % Get Indexes Of Stomrs Ocurring on Years(jj)
        wanted_years = find(dyear==years(jj));
        wanted_stm_beg = stm_beg(wanted_years);
        % Get Length Of Storms Matching Years(jj)
        dlen = dlen(wanted_years);
        % Cycle Throuigh Matching Storms
        if isempty(wanted_stm_beg)==0
            % Grab All Storm Data Associated To Specific Year
            yData = resp_vec{ii}(wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1);
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

