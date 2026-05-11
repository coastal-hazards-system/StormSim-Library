function [effective_slope, slope_metadata] = find_slope(SWL, Hm0, x, y)
%{
This function finds the weighted slope of a levee with respect to 
SWL +/- c*Hm0. Profile direction must be from toe to crest (positive slope)
Inputs:
SWL = Still Water Level
Hm0 = Wave Height 
x = Structure Seaside Slope Profile Point X Coordinate (toe to crest
direction). Must have a minimum of 4 points
Y = Structure Seaside Slope Profile Point y Coordinate (toe to crest
direction). Must have a minimum of 4 points
%}

%% DEFINE INPUTS
% Get Shape
[nrow,ncol] = size(SWL);
% Vectorize Forcing Variables
SWL = SWL(:);
Hm0 = Hm0(:);
% Slopes Along Profile
slopes = diff(y)./diff(x);
% Starting Coeff.
c = 1.5;
% Initialize Counter
ctr = 1;
% While Exit Flag Initialization
w_exit = 0;

%% INITIALIZE COMPUTATIONAL VARIABLES ( Number of Events x Replicates, 1 )
% This is needed in order to reduce data volume each while iteration
% Index To Store Results Back To
ref_row = 1:length(SWL);
% Initalize Slope Variables
effective_slope = NaN(size(SWL)); % Effective Slope (Final Result)
slope_mid = NaN(size(SWL)); % Resulting Slope For Middle Section
nSlopes = NaN(size(SWL)); % Profile Slope Segments Withing Influence Range
% Initialize Low Point Influence Variables
highY = NaN(size(SWL)); % High Point Influence SWL + c*Hm0
highYprev = NaN(size(SWL)); % High Point Influence Neighbor Y For DX Computations
highXprev = NaN(size(SWL)); % High Point Influence Neighbor X For DX Computations
tempSlopeH = NaN(size(SWL)); % High Point Influence Unweighted Slopes
tempSlopeH_indx = NaN(size(SWL)); % High Point Influence Assigned Slope Index
pt_neighbors_beg_h = NaN(length(SWL), 2); % High Point Influence Event Neighbors (Slope Bin)
pt_neighbors_end_h = NaN(length(SWL), 2); % High Point Influence Event Neighbors (Slope Bin)
highdY = NaN(size(SWL)); % High Point Influence DY With Associated Neighbor
highdX = NaN(size(SWL)); % High Point Influence DX With Associated Neighbor
highX = NaN(size(SWL)); % High Point Influence X Position On Profile
% Intialize Low Point Influence Variables
lowY = NaN(size(SWL)); % Low Point Influence SWL + c*Hm0
lowYnext = NaN(size(SWL)); % Low Point Influence Neighbor Y For DX Computations
lowXnext = NaN(size(SWL)); % Low Point Influence Neighbor X For DX Computations
tempSlopeL = NaN(size(SWL)); % Low Point Influence Unweighted Slopes
tempSlopeL_indx = NaN(size(SWL));% Low Point Influence Assigned Slope Index
pt_neighbors_beg_l = NaN(length(SWL), 2); % Low Point Influence Event Neighbors (Slope Bin)
pt_neighbors_end_l = NaN(length(SWL), 2); % Low Point Influence Event Neighbors (Slope Bin)
lowdY = NaN(size(SWL)); % Low Point Influence DY With Associated Neighbor
lowdX = NaN(size(SWL)); % Low Point Influence DX With Associated Neighbor
lowX = NaN(size(SWL)); % Low Point Influence X Position On Profile
% Initialize Total Influence Range DX
dxTotal = NaN(size(SWL));
% Initialize Weighting Variables
weightHigh = NaN(size(SWL)); % High Point Influence Weight
weightLow = NaN(size(SWL)); % Low Point Influence Weight
weightMiddle = NaN(size(SWL)); % Middle Point Influence Weight
% 
while_fail = 0;

%% COMPUTE EFFECTIVE SLOPE FOR ALL EVENTS
% Loop Through Entries
while w_exit == 0
    if ~isempty(ref_row)
        %% STEP 1: COMPUTE HIGH/LOW POINT OF INFLUENCE FOR EVENT
        % Compute Surge/Wave Interaction High Point With Seaward Slope  (SWL + c*Hm0)
        highY(ref_row) = SWL(ref_row) + c.*Hm0(ref_row); % High Point
        highY(highY>max(y,[],'omitnan')) = max(y,[],'omitnan'); % Replace Events With High Point > Crest Elevation with Crest Elevation
        highY(highY<min(y,[],'omitnan')) = min(y,[],'omitnan');% Replace Events With Low Point < Toe Elevation with Toe Elevation
        % Compute Surge/Wave Interaction High Point With Seaward Slope  (SWL - c*Hm0)
        lowY(ref_row) = SWL(ref_row) - c.*Hm0(ref_row); % Low Point
        lowY(lowY<min(y,[],'omitnan')) = min(y,[],'omitnan');% Replace Events With Low Point < Toe Elevation with Toe Elevation
        lowY(lowY>max(y,[],'omitnan')) = max(y,[],'omitnan'); % Replace Events With High Point > Crest Elevation with Crest Elevation

        %% STEP 2: IDENTIFY SLOPE SEGMENTS ASSOCIATED TO EACH EVENT
        % Determine Where SWL +/- c*Hm0 Falls Along Seaward Slope
        [tempSlopeH_indx(ref_row), pt_neighbors_beg_h(ref_row,:), pt_neighbors_end_h(ref_row,:)] = where_in_slope(highY(ref_row), x, y, 1);%arrayfun(@(z) where_in_slope(z, x, y), highY, 'un', false); % SWL + c*Hm0
        [tempSlopeL_indx(ref_row), pt_neighbors_beg_l(ref_row,:), pt_neighbors_end_l(ref_row,:)] = where_in_slope(lowY(ref_row), x, y, 1);%arrayfun(@(z) where_in_slope(z, x, y), lowY, 'un', false); % SWL - c*Hm0
        % Assign Slopes To Event Influence Ranges 
        aux_var = find(~isnan(tempSlopeH_indx(ref_row))); % Need to ensure Indexes Are Real But need to track ref_row
        tempSlopeH(ref_row(aux_var)) = slopes(tempSlopeH_indx(ref_row(aux_var))); % Assign Profile Slope
        aux_var = find(~isnan(tempSlopeL_indx(ref_row))); % Need to ensure Indexes Are Real But need to track ref_row
        tempSlopeL(ref_row(aux_var)) = slopes(tempSlopeL_indx(ref_row(aux_var))); % Assign Profile Slope

        %% STEP 3: COMPUTE HIGH POINT HORIZONTAL DISTANCE (highX)
        % Per S2G Code 
        % Grab Previous Neighbor To High Point
        highYprev(ref_row) = pt_neighbors_end_h(ref_row, 2);%cellfun(@(x) x(1,2), pt_neighbors_h, 'un', true);
        highXprev(ref_row) = pt_neighbors_end_h(ref_row, 1);%cellfun(@(x) x(1,1), pt_neighbors_h, 'un', true);
        % Compute DY Of High Point
        highdY(ref_row) =  highY(ref_row) - highYprev(ref_row);
        % Compute DX Of High Point
        highdX(ref_row) = highdY(ref_row)./tempSlopeH(ref_row);
        % Compute High Point Length
        highX(ref_row) = highdX(ref_row) + highXprev(ref_row);

        %% STEP 4: COMPUTE LOW POINT HORIZONTAL DISTANCE lowX)
        % Grab Next Neighbor To Low Point
        lowYnext(ref_row) = pt_neighbors_beg_l(ref_row, 2);%cellfun(@(x) x(2,2), pt_neighbors_l, 'un', true);
        lowXnext(ref_row) = pt_neighbors_beg_l(ref_row, 1);%cellfun(@(x) x(2,1), pt_neighbors_l, 'un', true);
        % Compute DY Of Low Point
        lowdY(ref_row) = lowYnext(ref_row) - lowY(ref_row);
        % Compute DX Of Low Point
        lowdX(ref_row) = lowdY(ref_row)./tempSlopeL(ref_row);
        % Compute Low Point Length
        lowX(ref_row) = lowXnext(ref_row)-lowdX(ref_row);

                %% STEP 5: COMPUTE SLOPE WEIGHTING
        % Compute Total Dx Of High/Low Influence Point
        dxTotal(ref_row) = highX(ref_row)-lowX(ref_row);
        % Compute High Point Influence Weight
        weightHigh(ref_row) = abs(highdX(ref_row)./dxTotal(ref_row));
        % Compute Low Point Influence Weight
        weightLow(ref_row) = abs(lowdX(ref_row)./dxTotal(ref_row));
        % Assign 50% Weight To Events Where Influnce Range Falls On A Single Slope Segment
        weightHigh(tempSlopeH_indx == tempSlopeL_indx) = 0.5;
        weightLow(tempSlopeH_indx == tempSlopeL_indx) = 0.5;
        % Compute Weight For Middle Slope
        weightMiddle(ref_row) =  1-weightHigh(ref_row)-weightLow(ref_row);


        %% STEP 6: DEFINE MIDDLE SLOPE FOR ALL EVENT INFLUENCE RANGES
        % Determine The Number Of Slopes Segments Within Influence Range
        nSlopes(ref_row) = abs(tempSlopeH_indx(ref_row) - tempSlopeL_indx(ref_row)) + 1; % Inclusive Substraction
        valid_indx = find(~isnan(nSlopes));
        % Cycle Through All Events
        for mm = 1:length(valid_indx)
            % Define Middle Slope According To N Segments
            if nSlopes(valid_indx(mm))<=2 % No Middle Slope Here (3 Datapoints or less)
                % Set Mid Slope To Zero
                slope_mid(valid_indx(mm),1) = 0;
            elseif nSlopes(valid_indx(mm)) == 3 % There is only 1 segment between High/Low Point
                % Get Slope Segments Associated To Event
                aux_var = slopes(tempSlopeH_indx(valid_indx(mm)):tempSlopeL_indx(valid_indx(mm)));
                % Grab Middle Segment Slope
                slope_mid(valid_indx(mm),1) = aux_var(2);
            else % There Are Multiple Slope Segments Take The Average
                % How Many Slope Segments Are In Middle 
                mid_segments = nSlopes(valid_indx(mm))-2;% Substract High/Low Segments
                % Adjust Weighting To Be Equally Distributed Through All Mid Segments 
                weightMiddle(valid_indx(mm)) = weightMiddle(valid_indx(mm))/mid_segments;
                % Compute Mean Slope Across Mid Segment
                slope_mid(valid_indx(mm),1) = mean(slopes(tempSlopeH_indx(valid_indx(mm))+1:tempSlopeL_indx(valid_indx(mm))-1));
            end
        end
        % Assign 0 Weight To Events With No Middle Slope
        weightMiddle(slope_mid == 0) = 0;
        %% STEP 7: COMPUTE EFFECTIVE SLOPE
        % Define the slope using the weighted values (tan(a))
        effective_slope(ref_row) = ((tempSlopeH(ref_row).*weightHigh(ref_row))+...
            (tempSlopeL(ref_row).*weightLow(ref_row))+(slope_mid(ref_row).*weightMiddle(ref_row)));

        %% STEP 8: CHECK FOR CASES WHERE EFFECTIVE SLOPE (TAN(a)) IS > 10
        % Check For "Bad Cases"
        if any(abs(effective_slope(ref_row))<0.1)  %tan(a)
            % Increment c
            c = c + 0.05;
            % Determine Rows To Recompute & Update
            ref_row = find(abs(effective_slope)<0.1);
        else
            w_exit = 1;
        end
    end
    %% STEP 9: KILL WHILE LOOP IF NEEDED
    % Increase While Loop Counter
    ctr = ctr + 1;
    % Check For While Exit Or C Increment
    if ctr > 10
        effective_slope(ref_row) = mean(slopes); % tan_a
        % Exit Flag
        w_exit = 1;
        % Define Flag To Indicate This Was Applied
        while_fail = 1;
    end
end
%% STEP 10: RESHAPE VECTOR & CONVERT SLOPE TO COT(a)
% Define Variables To Store Info For Plotting
vars_to_store = {'x', 'y', 'highX', 'highXprev', 'lowXnext', 'lowX',...
    'highY', 'highYprev', 'lowYnext', 'lowY','effective_slope',...
    'weightHigh','weightLow','weightMiddle','tempSlopeL_indx','tempSlopeH_indx','nSlopes'};
% Store Info For Plotting
for kk = 1:length(vars_to_store)
    slope_metadata.(vars_to_store{kk}) = eval(vars_to_store{kk});
end
% Add While Flag 
slope_metadata.while_fail = while_fail;
% Reshape Back To Matrix A
effective_slope = reshape(1./effective_slope,nrow,ncol); % Cot_a

%% AUXILIARY FUNCTIONS
% Finds Associated Slope Segments To All Events Influence Range
    function [slope_indx, pt_neighbors_beg, pt_neighbors_end] = where_in_slope(cond, x, y, s_dir)
        % Intialize Variables
        pt_neighbors_beg = NaN(length(cond), 2);
        pt_neighbors_end = NaN(length(cond), 2);
        slope_indx = NaN(length(cond), 1);

        % Loop Trough Transect Bins
        for ll = 1:length(y)-1
            if s_dir == 1 % Seaward Slope Is Drawn From Crest to Toe (Left to Rigth)
                profile_bins(:, ll) =  cond>=y(ll+1) & cond<=y(ll);
            else % Seaward Slope Is Drawn From Toe to Crest (Left to Rigth)
                profile_bins(:, ll) =  cond>=y(ll) & cond<=y(ll+1);
            end
        end
        % Find Matched Cases
        [rr, aa] = find(profile_bins == 1);
        % Store Indexes
        slope_indx(rr) = aa;
        % Store Associated Neighrbors For Valid Cases
        pt_neighbors_beg(rr, :) = [x(aa), y(aa)];
        pt_neighbors_end(rr, :) = [x(aa+1), y(aa+1)];
    end
end
