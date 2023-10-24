function LC_SimOUT_hyd = mcs_timeseries_life_cycle_formater(sYear,flag,ycounter,stIndx,storm,prob_mass, TC_iclass)
%% RECREATE PEAKS SAMPLING
% Storm Flag
if flag==0
    % Format Data
    storm_timeseries_ID = [storm.('XC').Timeseries{:,1}];
    storm_timeseries = storm.('XC').Timeseries{cell2mat(storm.('XC').Timeseries(:,1))==stIndx,2};
    % Make Sure Storm Has Data And Correct If Necessary
    if isempty(storm_timeseries) || length(storm_timeseries)<10
        while isempty(storm_timeseries) || length(storm_timeseries)<10
            sample_indx = storm_timeseries_ID;
            % Remove Storm From List (If found)
            sample_indx(sample_indx==stIndx)=[];
            % Resample Storm
            stIndx = randsample(sample_indx,1);
            % get New Storm
            storm_timeseries = storm.('XC').Timeseries{cell2mat(storm.('XC').Timeseries(:,1))==stIndx,2};
        end
    end
else
    smpl0 = prob_mass.smpl0;
    smpl1 = prob_mass.smpl1;
    % Format Data
    storm_timeseries = storm.('TC').Timeseries{cell2mat(storm.('TC').Timeseries(:,1))==stIndx,2};
    % Make Sure Storm Has Data And Correct If Necessary
    if isempty(storm_timeseries) || length(storm_timeseries)<10
        while isempty(storm_timeseries) || length(storm_timeseries)<10
            if TC_iclass==0
                sample_indx = smpl0;
            end
            if TC_iclass==1
                sample_indx = smpl1;
            end
            % Remove Storm From List (If found)
            sample_indx(sample_indx==stIndx)=[];
            % Resample Storm
            stIndx = randsample(sample_indx,1);
            % get New Storm
            storm_timeseries = storm.('TC').Timeseries{cell2mat(storm.('TC').Timeseries(:,1))==stIndx,2};
        end
    end
end

%
LC_SimOUT_hyd = zeros(length(storm_timeseries(:,1)),10);
%% ADD STORM TO LC STRUCTURE LIFE CYCLE
%{
        Life Cycle matrix headers
            LC_SimOUT_hyd(lc).LCNUM(:,1:3); %storm, number of wave ts, ts#
            LC_SimOUT_hyd(lc).LCNUM(:,4);   %Date/Time
            LC_SimOUT_hyd(lc).LCNUM(:,5);   %SWL, m, MSL
            LC_SimOUT_hyd(lc).LCNUM(:,6);   %Hm0, m
            LC_SimOUT_hyd(lc).LCNUM(:,7);   %Tp, s
            LC_SimOUT_hyd(lc).LCNUM(:,8);   %Wave Direction
            LC_SimOUT_hyd(lc).LCNUM(:,9)    %Duration
            LC_SimOUT_hyd(lc).LCNUM(:,10)   %Storm year
%}
LC_SimOUT_hyd(:,:) = [repmat(stIndx,length(storm_timeseries(:,1)),1),...
    repmat(length(storm_timeseries(:,1)),length(storm_timeseries(:,1)),1),...
    [0:length(storm_timeseries(:,1))-1]',...
    storm_timeseries,...
    repmat(sYear,length(storm_timeseries(:,1)),1)];

end