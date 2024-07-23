function [min_file_req, chs_files_2_convert, chs_files_2_convert_paths] = minimum_file_requirement_check(chs_files_2_convert_paths, chs_files_2_convert, storm_sampling, use_peaks, use_timeseries)
%{
Minimum File Requirements Per Fidelity & Storm Type:
    use_peaks = 1 & use_timeseries = 0
        Storm Sampling: XC ( 2 files )
          - CHS ADCIRC XC Peaks HDF5 file + CHS STWAVE XC Peaks HDF5 file.
        Storm Sampling: TC ( 2 files )
          - CHS ADCIRC TC Peaks HDF5 file + CHS STWAVE TC Peaks HDF5 file.
        Storm Sampling: CC ( 4 files )
          - CHS ADCIRC TC Peaks HDF5 file + CHS STWAVE TC Peaks HDF5 file. 
          - CHS ADCIRC XC Peaks HDF5 file + CHS STWAVE XC Peaks HDF5 file. 

    use_peaks = 0 & use_timeseries = 1
        Storm Sampling: XC ( 2 files )
          - CHS ADCIRC XC Timeseries HDF5 file + CHS STWAVE XC Timeseries HDF5 file.
        Storm Sampling: TC ( 2 files )
          - CHS ADCIRC TC Timeseries HDF5 file + CHS STWAVE TC Timeseries HDF5 file.
        Storm Sampling: CC ( 4 files )
          - CHS ADCIRC TC Timeseries HDF5 file + CHS STWAVE TC Timeseries HDF5 file. 
          - CHS ADCIRC XC Timeseries HDF5 file + CHS STWAVE XC Timeseries HDF5 file. 

    use_peaks = 1 & use_timeseries = 1
        Storm Sampling: XC ( 4 files )
        Storm Sampling: TC ( 4 files )
        Storm Sampling: CC ( 8 files )

%}
%% REMOVE h5 FILES TO PROCESS PER CONFIG SPECIFICATIONS 
% Remove CHS Peaks h5 Files From List Of Files To Process (If Any)
if use_peaks == 0
    % Remove Peaks Files From List Of h5 To Process
    chs_files_2_convert_paths = chs_files_2_convert_paths(~contains(chs_files_2_convert,{'Peaks'}));
    chs_files_2_convert = chs_files_2_convert(~contains(chs_files_2_convert,{'Peaks'}));
end
% Remove CHS Timeseries h5 Files From List Of Files To Process. (If Any)
if use_timeseries == 0
    % Remove Timeseries Files From List Of h5 To Process
    chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'Peaks'}));
    chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'Peaks'}));
end
% Remove Files According To Sampling Scheme
switch storm_sampling
    case 'XC' % Extratropical Storms Only
        % Remove TC Files (Peaks & Timeseries) From List Of h5 To Process
        chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'XC','XH'}));
        chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'XC','XH'}));
    case 'TC' % Tropical Cyclones Only
        % Remove XC Files (Peaks & Timeseries) From List Of h5 To Process
        chs_files_2_convert_paths = chs_files_2_convert_paths(contains(chs_files_2_convert,{'TC','TS'}));
        chs_files_2_convert = chs_files_2_convert(contains(chs_files_2_convert,{'TC','TS'}));
end

%% DEFINE MINIMUM FILE REQUIREMENT ACCORDING TO FIDELITY & STORM TYPE
switch storm_sampling
    case {'XC','TC'} % Extratropical Storms Only
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