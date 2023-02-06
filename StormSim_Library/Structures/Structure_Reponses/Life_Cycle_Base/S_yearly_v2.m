function [Smax,LSmax,SPcurves,LSPcurves] = S_yearly_v2(data,S,LS,nYears)
    %
    % Define Years To Look For
    years = [1:nYears];yBox = num2cell(zeros(size(years))');LyBox = num2cell(zeros(size(years))');
    dbug = num2cell(zeros(length(years),length(data)));Ldbug = num2cell(zeros(length(years),length(data)));
    
    for jj = 1:length(years)
        for ii = 1:length(data)
            % Extract Storm Data From Life Cycle
            dummy = data{ii};
            % Find Start Row of Each Concatenated Storm
            dummy2 = find(dummy(:,3)==0);
            % Extract Strom Year Col
            dyear = dummy(dummy2,10);
            % Extract Data Length Col
            dlen = dummy(dummy2,2);
            % Get Indexes Of Stomrs Ocurring on Years(jj)
            dummy4 = find(dyear==years(jj));
            dummy3 = dummy2(dummy4);
            % Get Length Of Storms Matching Years(jj)
            dlen = dlen(dummy4);
            % Cycle Throuigh Matching Storms
            
            if isempty(dummy3)==0
                % Extract Storm Data From Life Cycle
                LC_data = data{ii};
                % Find Start Row of Each Concatenated Storm
                stm_beg = find(LC_data(:,3)==0);
                % Extract Strom Year Col
                dyear = LC_data(stm_beg,10);
                % Extract Data Length Col
                dlen = LC_data(stm_beg,2);
                % Get Indexes Of Stomrs Ocurring on Years(jj)
                wanted_years = find(dyear==years(jj));
                wanted_stm_beg = stm_beg(wanted_years);
                % Get Length Of Storms Matching Years(jj)
                dlen = dlen(wanted_years);
                % Cycle Throuigh Matching Storms
                
                if isempty(wanted_stm_beg)==0
                    % Seaside
                    yData = S{ii}(wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1);
                    dbug{jj,ii} = yData;
                    % Leeside
                    LyData = LS{ii}(wanted_stm_beg(1):wanted_stm_beg(end)+dlen(end)-1);
                    Ldbug{jj,ii} = LyData;
                    if ii==1
                        yBox{jj} = max(yData);
                        LyBox{jj} = max(LyData);
                        
                    else
                        yBox{jj} = [yBox{jj};max(yData)];
                        LyBox{jj} = [LyBox{jj};max(LyData)];
                        
                    end
                end
            end
        end        
    end
    SPcurves = cell2mat(cellfun(@(x) prctile(x,[10,16,84,90]),yBox,'un',false));
    LSPcurves = cell2mat(cellfun(@(x) prctile(x,[10,16,84,90]),LyBox,'un',false));
    Smax = cell2mat(cellfun(@(x) mean(x,'omitnan'),yBox,'un',false));
    LSmax = cell2mat(cellfun(@(x) mean(x,'omitnan'),LyBox,'un',false));
    
end

