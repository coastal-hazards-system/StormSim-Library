function [min_file_req, chs_files_2_convert, chs_files_2_convert_paths] = minimum_file_requirement_check(chs_files_2_convert_paths, chs_files_2_convert, storm_sampling, use_peaks, use_timeseries)
%{
    PROS
        2 XC Peaks and/or 2 TC Peaks Files (ADCIRC + STWAVE/WAM/SWAN)
    MCS/CSR
        2 XC Peaks and/or 2 TC Peaks Files (ADCIRC + STWAVE/WAM/SWAN)
        Optional
        Corresponding timeseries files (4 or 8 total files)
%}
% Filter Out Peaks Files (If Any)
if use_peaks == 0
    % Remove Peaks
    chs_files_2_convert_paths = chs_files_2_convert_paths(~contains(chs_files_2_convert,{'Peaks'}));
    chs_files_2_convert = chs_files_2_convert(~contains(chs_files_2_convert,{'Peaks'}));
end
% Filter Out Timeseries Files (If Any)
if use_timeseries == 0
    % Remove Timeseries
    chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'Peaks'}));
    chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'Peaks'}));
end
% Filter Out Files According To Sampling Scheme
switch storm_sampling
    case 'XC'
        % Remove TCs
        chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'XC','XH'}));
        chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'XC','XH'}));
        % Keep Track Of File Requirement
        switch sum([use_timeseries,use_peaks])
            case 1 % Peaks or Timeseries
                min_file_req = 2;
            case 2 % Peaks And Timeseries
                min_file_req = 4;
        end
    case 'TC'
        % Remove XCs
        chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'TC','TS'}));
        chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'TC','TS'}));
        % Keep Track Of File Requirement
        switch sum([use_timeseries,use_peaks])
            case 1 % Peaks or Timeseries
                min_file_req = 2;
            case 2 % Peaks And Timeseries
                min_file_req = 4;
        end
    case 'CC'
        % Keep Track Of File Requirement
        switch sum([use_timeseries,use_peaks])
            case 1 % Peaks or Timeseries
                min_file_req = 4;
            case 2 % Peaks And Timeseries
                min_file_req = 8;
        end
end