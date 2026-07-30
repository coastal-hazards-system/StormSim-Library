function [config, u_load] = resolve_hotstart_state(config, wflow2)
%{
%% DESCRIPTION
Compares the current run's config against a previously cached
"_config_file.mat" (if one exists) and decides which hotstart state
carries over: bias/uncertainty values, and the u_engine/f_adjust
flags that gate call_uncertainty_engine.m and
call_project_forcing_adjuster.m. Forces a full transect wipe on
sp_ID/region mismatch, and forces the cached project_forcing.mat to
be deleted (so it is regenerated from raw storm data rather than
reprocessing already-adjusted data) whenever a forcing-adjustment or
uncertainty-relevant setting changed since the cache was written.

SWL/Hm0 bias-uncertainty carryover follows a priority rule rather than
always preferring cache: config.chs_swl_bu_source/chs_hm0_u_source
(set in call_environment_setup.m to 'chs_dependencies' or 'manual')
records where THIS run's value came from. If it was freshly loaded
from CHS_Dependencies this run, that value always wins and the cache
is ignored -- CHS_Dependencies data must take precedence whenever
available. The cache is only consulted when this run has no file-based
value (source field absent), so a prior manual entry keeps propagating
forward without re-prompting until a region file eventually appears.

%% INPUTS
config: Current run's parsed config struct (pre-hotstart-resolution).
wflow2: Workflow subfolder name ('PROS' or 'LCS'), used when
        rebuilding a wiped transect directory.

%% OUTPUTS
config: config struct with u_engine/f_adjust/bias-uncertainty fields
        resolved.
u_load: true if bias/uncertainty values were successfully carried
        over from a compatible cached config (suppresses the manual
        bias/uncertainty entry prompt downstream).

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
% Initialize Load Flag
u_load = false;
if exist(config.out_files.config, 'file')
    % Load Config
    config_load = load(config.out_files.config, 'config');
    config_load = config_load.config;
    % Pull Bias & Uncertainty Values If Same File For Convenience
    if strcmp(config.out_files.config, config_load.out_files.config) % Same Bias File
        try
            % If SP ID Or Region Doesn't Match, Wipe Transect Folder, New Forcing
            if config.sp_ID ~= config_load.sp_ID || ~strcmp(config.region, config_load.region)
                sp_mismatch = config.sp_ID ~= config_load.sp_ID;
                region_mismatch = ~strcmp(config.region, config_load.region);
                if sp_mismatch && region_mismatch
                    disp_toggle(config.print_progress, sprintf('Hotstart: sp_ID changed (%g -> %g) and region changed (%s -> %s), wiping transect and running cold start....', config_load.sp_ID, config.sp_ID, config_load.region, config.region));
                elseif sp_mismatch
                    disp_toggle(config.print_progress, sprintf('Hotstart: sp_ID changed (%g -> %g), wiping transect and running cold start....', config_load.sp_ID, config.sp_ID));
                else
                    disp_toggle(config.print_progress, sprintf('Hotstart: region changed (%s -> %s), wiping transect and running cold start....', config_load.region, config.region));
                end
                % Delete Files Because Bias Needs to Be Recomputed
                sim_dir = fullfile(config.outfolder, config.project_name, config.struc_id, config.case_name);
                rmdir(sim_dir, 's');
                mkdir(sim_dir);
                mkdir(fullfile(sim_dir, wflow2));
                % Grab Forcing Adjustment Flags
                config.u_engine = 0;
                config.f_adjust = 0;
            else
                % SWL Bias/Uncertainty: CHS_Dependencies files always take priority when
                % available this run -- only carry over the cached value when this run
                % did NOT freshly source it from CHS_Dependencies (i.e. files missing,
                % falling back to whatever was cached: a prior manual entry or a stale
                % file-based value from before the source file existed/changed).
                swl_fresh_from_files = isfield(config, 'chs_swl_bu_source') && strcmp(config.chs_swl_bu_source, 'chs_dependencies');
                if ~swl_fresh_from_files && isfield(config_load, 'chs_swl_u_a')
                    config.chs_swl_u_a = config_load.chs_swl_u_a;
                    config.chs_swl_u_r = config_load.chs_swl_u_r;
                    config.chs_swl_b_a = config_load.chs_swl_b_a;
                    config.chs_swl_b_r = config_load.chs_swl_b_r;
                    if isfield(config_load, 'chs_swl_bu_source')
                        config.chs_swl_bu_source = config_load.chs_swl_bu_source;
                    end
                    disp_toggle(config.print_progress, 'Hotstart: SWL bias/uncertainty carried over from cache (no CHS_Dependencies file available this run)....');
                elseif swl_fresh_from_files
                    disp_toggle(config.print_progress, 'Hotstart: SWL bias/uncertainty loaded fresh from CHS_Dependencies this run, ignoring cache....');
                end

                % Hm0 Uncertainty: same priority rule as SWL above.
                hm0_fresh_from_files = isfield(config, 'chs_hm0_u_source') && strcmp(config.chs_hm0_u_source, 'chs_dependencies');
                if ~hm0_fresh_from_files && isfield(config_load, 'chs_hm0_u_a')
                    config.chs_hm0_u_a = config_load.chs_hm0_u_a;
                    config.chs_hm0_u_r = config_load.chs_hm0_u_r;
                    if isfield(config_load, 'chs_hm0_u_source')
                        config.chs_hm0_u_source = config_load.chs_hm0_u_source;
                    end
                    disp_toggle(config.print_progress, 'Hotstart: Hm0 uncertainty carried over from cache (no CHS_Dependencies file available this run)....');
                elseif hm0_fresh_from_files
                    disp_toggle(config.print_progress, 'Hotstart: Hm0 uncertainty loaded fresh from CHS_Dependencies this run, ignoring cache....');
                end

                % Check Whether Forcing-Adjustment/Uncertainty-Relevant Settings Changed
                % (chs_swl_u_a/u_r/chs_hm0_u_a/u_r Are Deliberately Excluded From unc_fields:
                % Their Own CHS_Dependencies-vs-cache Precedence Is Already Resolved Above,
                % So Comparing Them Here Would Be Redundant)
                deps = hotstart_cache_dependencies();
                [adj_changed, adj_field] = any_field_changed(config, config_load, deps.f_adjust);
                [unc_changed, unc_field] = any_field_changed(config, config_load, deps.u_engine);

                if adj_changed
                    disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- regenerating forcing adjustments....', adj_field));
                end
                if unc_changed
                    disp_toggle(config.print_progress, sprintf('Hotstart: config field ''%s'' changed since cache -- regenerating uncertainty engine results....', unc_field));
                end
                if ~adj_changed && ~unc_changed
                    disp_toggle(config.print_progress, 'Hotstart cache is valid, reusing forcing adjustments and uncertainty engine results....');
                end

                % Force Regeneration Of Cached Project Forcing If Either Changed
                if (adj_changed || unc_changed) && exist(config.out_files.project_forcing, 'file')
                    if adj_changed && unc_changed
                        forcing_reason = sprintf('''%s'' and ''%s''', adj_field, unc_field);
                    elseif adj_changed
                        forcing_reason = sprintf('''%s''', adj_field);
                    else
                        forcing_reason = sprintf('''%s''', unc_field);
                    end
                    disp_toggle(config.print_progress, sprintf('Hotstart: deleting cached project forcing since config field %s changed, will be regenerated....', forcing_reason));
                    delete(config.out_files.project_forcing);
                end

                % Grab Forcing Adjustment Flags
                if adj_changed
                    config.f_adjust = 0;
                else
                    config.f_adjust = config_load.f_adjust;
                end
                if unc_changed
                    config.u_engine = 0;
                else
                    config.u_engine = config_load.u_engine;
                end
                u_load = true;
            end
        catch ME
            warning('Hotstart cache failed to load: %s -- running cold start....', ME.message);
            % Delete Files Because Bias Needs to Be Recomputed
            sim_dir = fullfile(config.outfolder, config.project_name, config.struc_id, config.case_name, wflow2);
            rmdir(sim_dir, 's');
            mkdir(sim_dir);
            % Uncertainty Engine Field Initialization
            config.u_engine = 0;
            % Forcing Adjustments Field Initialization
            config.f_adjust = 0;
        end
    end
else
    disp_toggle(config.print_progress, sprintf('Hotstart: no cache found for region ''%s'' / sp_ID %g, running cold start....', config.region, config.sp_ID));
    % Uncertainty Engine Field Initialization
    config.u_engine = 0;
    % Forcing Adjustments Field Initialization
    config.f_adjust = 0;
end
end
