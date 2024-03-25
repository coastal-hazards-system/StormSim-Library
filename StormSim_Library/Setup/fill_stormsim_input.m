function fout = fill_stormsim_input(ifile, outpath, fields_2_change, values_2_change)
% Read Input File Template
input_template = readcell(ifile);
% Find Rows
for kk = 1:length(fields_2_change)
    [rr,cc] = find(strcmp(input_template,fields_2_change{kk}));
    input_template{rr, cc+3} = values_2_change{kk};
end
input_template(cell2mat(cellfun(@(x) isa(x,'missing'),input_template,'UniformOutput',false)))={''};
% input_template(cell2mat(cellfun(@(x) any(ismissing(x)), input_template, 'UniformOutput', false))) = {' '};
writecell(input_template,outpath);
fout = outpath;
end