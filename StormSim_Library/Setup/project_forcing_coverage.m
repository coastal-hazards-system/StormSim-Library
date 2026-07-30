function [covers, missing_desc] = project_forcing_coverage(config, project_forcing)
%PROJECT_FORCING_COVERAGE True if a cached project_forcing satisfies the current request.
%{
%% DESCRIPTION
Checks whether a loaded project_forcing.mat already contains everything
the current run needs (Peaks/WLP/WHP/Timeseries, and TC/XC storm-type
coverage per config.storm_sampling). A cache having MORE than requested
(e.g. cached CC data satisfying an XC-only request) is valid and is not
flagged as missing.

For LCS (config.workflow == 3), use_peaks/has_peaks is deliberately
EXCLUDED from the comparison -- stormsim_lcs.m unconditionally builds a
dummy Peaks dataset from Timeseries max() for sampling purposes even
when use_peaks == 0, so has_peaks is true for every LCS cache regardless
of what was requested; checking it there produces false "covered"
results. PROS (stormsim_pros_formater.m) has no such proxy, so
use_peaks/has_peaks stays in the check for PROS exactly as it always has.

%% INPUTS
config: Current run's parsed config struct.
project_forcing: Loaded contents of a cached project_forcing.mat.

%% OUTPUTS
covers: true if project_forcing satisfies everything config requests.
missing_desc: comma-joined string of human-readable labels for whichever
              requested items are missing (for logging); '' if covers is true.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
has_peaks = contains('Peaks', fieldnames(project_forcing));
if ~has_peaks
    has_wlp = false;
    has_whp = false;
else
    has_wlp = contains('WLP', fieldnames(project_forcing.Peaks));
    has_whp = contains('WHP', fieldnames(project_forcing.Peaks));
end
has_timeseries = contains('Timeseries', fieldnames(project_forcing));
if ~has_peaks
    has_xc = contains('XC', fieldnames(project_forcing.Timeseries.Default));
    has_tc = contains('TC', fieldnames(project_forcing.Timeseries.Default));
else
    has_xc = contains('XC', fieldnames(project_forcing.Peaks.Default));
    has_tc = contains('TC', fieldnames(project_forcing.Peaks.Default));
end
switch lower(config.storm_sampling)
    case 'xc'
        tc_conf = false;
        xc_conf = true;
    case 'tc'
        tc_conf = true;
        xc_conf = false;
    case 'cc'
        tc_conf = true;
        xc_conf = true;
end
if config.workflow == 3
    have = [has_wlp;has_whp;has_timeseries;has_tc;has_xc];
    need = [cellfun(@(x) logical(config.(x)), {'create_wlp','create_whp','use_timeseries'}, 'un', true)';tc_conf;xc_conf];
    labels = {'WLP';'WHP';'Timeseries';'TC';'XC'};
else
    have = [has_peaks;has_wlp;has_whp;has_timeseries;has_tc;has_xc];
    need = [cellfun(@(x) logical(config.(x)), {'use_peaks','create_wlp','create_whp','use_timeseries'}, 'un', true)';tc_conf;xc_conf];
    labels = {'Peaks';'WLP';'WHP';'Timeseries';'TC';'XC'};
end
missing_mask = need & ~have;
covers = ~any(missing_mask);
missing_desc = strjoin(labels(missing_mask), ', ');
end
