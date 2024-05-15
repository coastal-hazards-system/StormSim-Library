function fout = fill_stormsim_input(ifile, outpath, fields_2_change, values_2_change)
% Get Sotrage Folder
[fpath, ~, ~] = fileparts(outpath);
% Create Output Dir If Needed
if ~exist(fpath, 'dir')
    mkdir(fpath);
end
% Copy Template
copyfile(ifile, outpath);
% Read Input File Template
input_template = readcell(outpath);
% Find Rows
for kk = 1:length(fields_2_change)
    % Find Entry
    [rr,cc] = find(strcmp(input_template,fields_2_change{kk}));
    input_template{rr, cc+3} = values_2_change{kk};
end
input_template(cell2mat(cellfun(@(x) isa(x,'missing'),input_template,'UniformOutput',false)))={''};
% input_template(cell2mat(cellfun(@(x) any(ismissing(x)), input_template, 'UniformOutput', false))) = {' '};
writecell(input_template,outpath);
fout = outpath;
end