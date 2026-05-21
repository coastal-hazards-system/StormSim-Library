function Data_out = call_chs_h5_converter(files_2_convert, print_progress)
    % Pre-allocate output struct array
    Data_out = struct('Filename', cell(1, length(files_2_convert)), ...
                      'Conv_Data', cell(1, length(files_2_convert)));
    % Loop Through H5 Files In Zip Folder
    for jj = 1:length(files_2_convert)
        disp_toggle(print_progress,['   - ' files_2_convert{jj} '...']);
        % Call H5 Converter
        [cData] = chs_h5_converter(files_2_convert{jj});
        % Store Converted Filename
        Data_out(jj).Filename = files_2_convert{jj};
        % Store Converted Data
        Data_out(jj).Conv_Data = cData;
    end
    disp_toggle(print_progress,'H5 conversion was sucessfull...');
end