        function [data,cData] = chs_h5_special_cases_importer(Filein,info,FA_units,FileDatasets,iCase)
            switch iCase
                case 1 % SRR

                    %% SPECIAL CASES: CHS HDF5 V1 SRR
                    %%%% GROUP DATASETS %%%%
                    % Get SRR
                    GDatasets1 = info.Groups(contains({info.Groups.Name},{'/Storm Rate'})).Datasets;
                    % Get Storm Relative Probabilities
                    GDatasets2 = info.Groups(contains({info.Groups.Name},{'/Storm Relative Probabilities'})).Datasets;

                    %%%% UNITS %%%%
                    try
                        GDS_units_indx = cellfun(@(x) find(strcmp({x.Name},'Units')==1),{GDatasets1.Attributes},'un',false);
                    end
                    GDS_units = [];
                    for ii = 1:length(GDS_units_indx)
                        GDS_units =  [GDS_units,{GDatasets1(ii).Attributes(GDS_units_indx{ii}).Value}];
                    end
                    cData.units = [FA_units,GDS_units,cell(size({GDatasets2.Name}))];
                    %%%% HEADERS
                    cData.headers = [{'Save Point ID','Save Point Latitude','Save Point Longitude'},{GDatasets1.Name},{GDatasets2.Name}];
                    %%%% PULL DATA
                    % Get Coordinate Data
                    data = num2cell(h5read(Filein,'/Save Point Locations')',1);
                    % Import All DataSets From Each Group
                    %{
        Importing HDF5 data as a self contained cell array first is much
        faster thant importing the full list as an array
                    %}
                    % Group 1
                    for DS = 1:length(GDatasets1)
                        % Read Datasets For Group
                        data  = [data,num2cell(h5read(Filein,[info.Groups(1).Name,'/',GDatasets1(DS).Name]),1)];
                    end
                    % Group 2
                    for DS = 1:length(GDatasets2)
                        % Read Datasets For Group
                        data  = [data,num2cell(h5read(Filein,[info.Groups(2).Name,'/',GDatasets2(DS).Name]),1)];
                    end
                    % Expand
                    dummy = cell(length(data{1}),length(data));
                    for ii = 1:length(data)
                        dummy(:,ii) = num2cell(data{ii});
                    end
                    % Rename
                    data = dummy;
                case 2 % NLR

                    %%%% DATASETS
                    % Fill Empty Attirbutes
                    try
                        FileDatasets(logical(cell2mat(cellfun(@(x) isempty(x),{FileDatasets.Attributes},'un',false)))).Attributes = struct('Name','Units','Value','');
                    end
                    % Define String Pattern To Search
                    FA = {'Save Point ID','Save Point Latitude','Save Point Longitude'};
                    % Find Within Datasets
                    FA_indx = cell2mat(cellfun(@(x) find(strcmp(x,{FileDatasets.Name})==1),FA,'un',false));
                    % Extract Found Objects
                    dummy = FileDatasets(FA_indx);
                    % Remove From Original Listing
                    FileDatasets(FA_indx) = [];
                    % Reorder
                    FileDatasets = [dummy;FileDatasets];

                    %%%% HEADERS
                    cData.headers = {FileDatasets.Name};
                    % Header 2
                    dummy = cell(size(cData.headers));
                    % Find Strings
                    DS_units_indx2 = cellfun(@(x) find(strcmp({x.Name},'Data Variable')==1),{FileDatasets.Attributes},'un',false);

                    %%%% UNITS
                    % Find Strings
                    DS_units_indx = cellfun(@(x) find(strcmp({x.Name},'Units')==1),{FileDatasets.Attributes},'un',false);
                    dummy2 = cell(size(cData.headers));

                    for ii = 1:length(DS_units_indx)

                        if ~isempty(DS_units_indx2{ii})
                            dummy(ii) = {FileDatasets(ii).Attributes(DS_units_indx2{ii}).Value};
                        end
                        if ~isempty(DS_units_indx{ii})
                            dummy2(ii) = {FileDatasets(ii).Attributes(DS_units_indx{ii}).Value};
                        end
                    end

                    % ADD TO OUT DATA
                    cData.units = dummy2;
                    cData.header2 = dummy;

                    %%%% PULL DATA
                    data=[];
                    % Loop Through ALl Datasets
                    for DS = 1:length(FileDatasets)
                        % Read Datasets
                        dummy  = num2cell(h5read(Filein,['/',FileDatasets(DS).Name]));
                        data = [data,dummy];
                    end

            end
        end
