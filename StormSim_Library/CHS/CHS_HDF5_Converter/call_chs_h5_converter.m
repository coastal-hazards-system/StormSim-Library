function Data_out = call_chs_h5_converter(files_2_convert)
    % initialize Counter
    ctr = 1;
    % Loop Through H5 Files In Zip Folder
    for jj = 1:length(files_2_convert)
        disp(['   - ' files_2_convert{jj} '...']);
        % Call H5 Converter
        [cData] = chs_h5_converter(files_2_convert{jj});
        % Store Converted Filename
        Data_out(ctr).Filename = files_2_convert{jj};
        % Store Converted Data
        Data_out(ctr).Conv_Data = cData;
        % Increment Counter
        ctr = ctr + 1;
    end
    disp('H5 conversion was sucessfull...');
end