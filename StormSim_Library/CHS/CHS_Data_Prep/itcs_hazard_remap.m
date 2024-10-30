function [HC_resp_diff, DSW_node, ITCS_HC, unmapped_storms] = itcs_hazard_remap(ITCS_Resp, ATCS_HC, ATCS_AEF, do_int)
% Define Number Of Storms And Nodes
[Nnode, Nstrm] = size(ITCS_Resp);

%% RANK STORMS BY SSL RESPONSE AND TRACK INDEXES
% Sort Storm Response By Magnitude Along All Nodes/Savepoints
[Resp_sort,Resp_indx0]  = sort(ITCS_Resp, 2, 'descend');% High to Low
% Preallocate for speed
Resp_index = NaN(Nnode,Nstrm);
% Find Ranking Order Per Storm
for ii = 1:Nnode
    for j = 1:Nstrm
        Resp_index(ii,j) = find(Resp_indx0(ii,:)==j);
    end
end
% Change -99999 to NaN (after sorting)
Resp_sort(Resp_sort==-99999)=NaN;
ITCS_Resp(ITCS_Resp==-99999)=NaN;

%% COMPUTE DSW PER NODE
%Preallocate for speed
DSW0 = NaN(Nnode,Nstrm);DSW_node = NaN(Nnode,Nstrm);
% Compute Discrete Storm Weights (DSWs) per node
for i = 1:Nnode % In case We Need This Left As A Loop
    % Get ATCS HC Response
    x = ATCS_HC(i,~isnan(ATCS_HC(i,:))); %remove NaNs
    % Get AEF's
    v = ATCS_AEF(~isnan(ATCS_HC(i,:))); %remove NaNs
    % Grab ITCS Peak Responses
    xq = Resp_sort(i,~isnan(Resp_sort(i,:))); %remove NaNs
    % Remove Repeated Values
    [~,ind] = unique(x,'last'); %remove repeated values
    try
        % Try interp
        out = exp(interp1(x(ind),log(v(ind)),xq)); % Find AEF Associated With Storm Event
        df = out(1); df(2:length(out)) = diff(out); % Compute df (Why?)
        DSW0(i,1:length(df)) = df;
    catch
        DSW0(i,:)=NaN;
    end
    % Reorder DSWs according to initial order
    DSW_node(i,:) = DSW0(i,Resp_index(i, :));
end%for i

%% JPM INTEGRATION (MAPPING ITCS PEAK RESPONSES TO ATCS HAZARD CURVE)
if do_int == 1
    % Compute Hazard Curves with DSW_node
    % Preallocate for speed
    ITCS_HC = NaN(Nnode,length(ATCS_AEF));
    x_out = NaN(Nnode,length(DSW_node));

    %JPM Integration
    for i = 1:Nnode
        % Get Node Peak Data
        Resp_i = ITCS_Resp(i,:);% Resp & DSW_node Are Sorted in the same way
        % Get Associated AEF's
        DSW_i=DSW_node(i,:);
        try
            index_n = find(~isnan(Resp_i)&Resp_i>0&~isnan(DSW_i)); %indices for storms that have made location wet
            unmapped_storms(i, 1) = {find(isnan(Resp_i)|Resp_i<0|isnan(DSW_i))};
            [~,I]=sort(Resp_i(index_n),'descend');%sort response for non-dry storms
            y = Resp_i(index_n(I)); %HC_Resp: Response; thresholds for defining hazard curve
            x_aef = cumsum(DSW_i(index_n(I))); %HC_Prob: exceedance of therehold rates
            %             x_out(index_n(I)) = x_aef;
            Lx_aef = log(x_aef); % Convert To Linear Scale
            y(abs(Lx_aef)==Inf)=[]; Lx_aef(abs(Lx_aef)==Inf)=[]; %remove "Inf" after "log"
            [~,ia_x,] = unique(Lx_aef); [~,ia_y] = unique(y);

            % Interpolation
            if (~isempty(y)) %&& sum(~isnan(y))>=(length(y)*0.05))
                ITCS_HC(i,:) = interp1(Lx_aef(ia_x),y(ia_x),log(ATCS_AEF));
            end% if
        catch
        end
    end% for

    % Save Hazard Curves DSW_node
    HC_resp_diff = ITCS_HC - ATCS_HC;
else
    HC_resp_diff = [];
    ITCS_HC = [];
end
end

