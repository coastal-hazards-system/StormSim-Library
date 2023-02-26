

clc;clear
%% DEFINE H5 CREATION INPUTS
filename = 'Example_LCS_Output_Timeseries_v2.h5'; % Define Output H5 Filename
% Define Savepoint/Node List To Process
sp_list = 16885; % % Define Groups To Create (Savepoints/Nodes), Col vector
sp_list_files = {'Midbay_v1_A-1_CHS_NACCS_SP16885_raw_files'}; % sp_list x 1 cellarray
sp_list_forcing_files = {'Midbay_v1_A-1_LCS_project_forcing.mat'}; % sp_list x 1 cellarray
load('NACS_staID.mat','staID');
% Define SP Data Properties
nLC = 9; % Number Of LC. Must Be The Same Accross SPs
dsource = 'savepoint'; % Define Data Source, 'savepoint' or 'nodal'
dType = 'Timeseries'; % Define Data Type, 'Timeseries' or 'Peaks'
dType2 = 'Maxima'; % 'Maxima','WLP','WHP' -> Peaks only
storm_sampling = 'CC';
% Define Datasets To Create Inside Each Group (Cols Of LCs)
vars_desc = {'Storm ID','Number Of Timesteps','Simulation Year','Timestep','Storm Duration',...
    'SWL','Hm0','Damage Depth','Tp','Wave Direction'}; % Dataset Names
vars_att = {'','Number of timesteps','yyyy-mm-dd HH:MM','days','','m','m','m','s','deg (referenced to grid)'};
order_indx = [1 2 10 4 9 5 6 -9 7 8]; % Col Index For Each LC, -9 -> Damaging Depths





% Define swl_indx -> Damaging Depth Computations
switch dType
    case 'Timeseries'
        swl_indx = 5;
    case 'Peaks'
        swl_indx = 4;
end
% Initialize the HDF5 file
hdf5write(filename, '/', []);

switch dsource
    case 'nodal'
        fname = 'Node';
    case 'savepoint'
        fname = 'Savepoint';
end

%% GRAB METADATA INFROMATION FOR FIRST LAYER
% Define Simulation Metadata
metadata(1).Att = 'Source';
metadata(2).Att = 'Data Type';
metadata(3).Att = 'Number of Groups (Savepoints/Nodes)';
metadata(4).Att = 'Number of Sub-groups (Life Cycles)';
metadata(5).Att = 'Number of Datasets (Forcing Information)';
metadata(6).Att = 'Simulation Type';
metadata(7).Att = 'Group Keys';
metadata(8).Att = 'Datasets Keys';

metadata(1).Att_val = 'StormSim: MCS';
metadata(2).Att_val = dType;
metadata(3).Att_val = length(sp_list);
metadata(4).Att_val = nLC;
metadata(5).Att_val = length(order_indx);
metadata(6).Att_val = 'LCS';
metadata(7).Att_val = cellfun(@num2str, num2cell(sp_list), 'UniformOutput', false);
metadata(8).Att_val = vars_desc';

% Add H5 General Attributes
for kk = 1:length(metadata)
    h5writeatt(filename, '/', metadata(kk).Att, metadata(kk).Att_val);
end




%% FOR EACH GROUP (SAVEPOINT/NODE)
for sp = 1:length(sp_list)
    % Load Project Forcing Data
    load(sp_list_forcing_files{sp});
    % Extract Data
    switch dType
        case 'Peaks'
            data = project_forcing.(storm_sampling).(dType).(dType2);
        case 'Timeseries'
            data = project_forcing.(storm_sampling).(dType);
    end
    % Define Group Location
    loc = sprintf('/SP_%d/', sp_list(sp));
    % Create Group
    hdf5write(filename, loc, [], 'WriteMode', 'append');

    %% ADD GROUP SUBGROUP FOR LCS
    SPdepth = staID(sp_list(sp)==staID(:,1),4);
    % For Each LC
    for lc = 1:length(data)
        % Identify Storms In LC
        cc = find(data(lc).LCNUM(:,3)==0);
        stm_indx = {};
        for ll = 1:length(cc)
            if ll == length(cc)
                stm_indx(ll) = {cc(ll):length(data(lc).LCNUM(:,3))};
            else
                stm_indx(ll) = {cc(ll):cc(ll+1)-1};
            end
        end

        % For Each Col In LC Data
        for j = 4:length(order_indx) % Loop through each group
            % For Each Storm In LC
            for ss = 1:length(stm_indx)
                % Define Loc 2
                loc2 = sprintf(['/SP_%d/LC_%d/Event_%d/' vars_desc{j}], sp_list(sp), lc, ss); % Location
                % Define Dataset
                dset_details.Location = loc2; % Location
                dset_details.Name = vars_desc{j}; % Name
                % Grab Dataset
                if order_indx(j)~=-9 % From Data
                    dset = data(lc).LCNUM(stm_indx{ss},order_indx(j));
                else % Compute Damaging Depths
                    dset = data(lc).LCNUM(stm_indx{ss},:);
                    % Compute DD
                    [dset]=Damaging_Depth_v02212023(repmat(SPdepth,size(dset,1),1),...
                        dset(:,swl_indx+1), dset(:,swl_indx+2), dset(:,swl_indx),...
                        ones(size(dset,1),1));
                end
                % Create the group if it doesn't exist
                if contains(vars_att{j},{'yyyy'})
                    helper_var = string(datestr(dset,'yyyy-mm-dd HH:MM'));
                    hdf5write(filename, dset_details.Location , helper_var, 'WriteMode', 'append');
                else
                    % Write the data to the HDF5 file
                    hdf5write(filename, dset_details.Location  , dset, 'WriteMode', 'append');
                end
                if j == 4
                    for uu = 1:j-1
                        loc3 = sprintf(['/SP_%d/LC_%d/Event_%d'], sp_list(sp), lc, ss);
                        % Storm ID
                        h5writeatt(filename, loc3, vars_desc{uu},...
                            unique(data(lc).LCNUM(stm_indx{ss},order_indx(uu))));
                    end
                end

                h5writeatt(filename, dset_details.Location, 'Units', vars_att{j});
            end
        end
    end
end
%% DEFINE GROUP ATTRIBUTES
%{
What to include here:
Simulation length 
Simulation LC 
CHS Files Used
Storm Sampling 
Dataset Keys

%}
% Load CHS_Data Structure For SP/Node
load(sp_list_files{sp}, 'CHS_Data');
% Remove Unwanted Files
CHS_Data = CHS_Data(contains({CHS_Data.Filename}', metadata(2).Att_val)); % Keep Peaks Or Timeseries
if ~strcmp(storm_sampling, 'CC')
    CHS_Data = CHS_Data(contains({CHS_Data.Filename}', storm_sampling)); % Keep XC or TC
end
% Define Attributes To Pull From CHS_Data
fields_2_get = {'Save Point ID', 'Project', 'Region', 'Vertical Datum'};
% Create Logical Vector
s_indx = sum(cell2mat(cellfun(@(x) contains({CHS_Data(1).Conv_Data.Attributes.Name}',x),fields_2_get,'un',false)),2);
% Grab Attributes From ADCIRC File
Att_names = {CHS_Data(1).Conv_Data.Attributes(s_indx==1).Name};
Att_val = {CHS_Data(1).Conv_Data.Attributes(s_indx==1).Value};
% Add Savepoint/Node Lat/Lon & Depth
Att_names = [Att_names, {['CHS ' fname 'Latitude']},...
    {['CHS ' fname 'Longitude']}, {'Coordinates Units'},...
    {['CHS ' fname 'Depth']},{'Depth Units'}];
Att_val = [Att_val, {staID(sp_list(sp)==staID(:,1),2)},...
    {staID(sp_list(sp)==staID(:,1),3)},{'deg'},...
    {staID(sp_list(sp)==staID(:,1),4)},{'m'}];
% Add Files Used To Create LCs
Att_names = [{'Project Forcing Source'},Att_names];
Att_val = [{{CHS_Data(contains({CHS_Data.Filename}', metadata(2).Att_val)).Filename}'},Att_val];
% Create Logical Vector
s_indx = sum(cell2mat(cellfun(@(x) contains({CHS_Data(2).Conv_Data.Attributes.Name}',x),{'Grid Name'},'un',false)),2);
% Add Wave Model Grid
Att_names = [Att_names, {'Wave Model Grid Name'}];
Att_val = [Att_val, {CHS_Data(2).Conv_Data.Attributes(s_indx==1).Value}];
% Write Group Attributes
for kk = 1:length(Att_names)
    h5writeatt(filename, loc, Att_names{kk}, Att_val{kk});
end

% end





