function deps = hotstart_cache_dependencies()
%HOTSTART_CACHE_DEPENDENCIES Declares which config fields invalidate which hotstart cache flag.
%{
%% DESCRIPTION
Single source of truth for "which config fields, if changed between
reruns of the same project/struc_id/case_name, mean a cached
project_forcing.mat can no longer be trusted." Read by
resolve_hotstart_state.m in production and by the unit test suite
(unit_test/HotstartDependencyDriftTest.m), so the declared list and
what the pipeline actually checks can never silently drift apart.

deps.f_adjust: Fields consumed by
    Forcing_Generation/Forcing_Adjustments/adjust_project_forcing.m
    (and its callees apply_depth_limitation.m / apply_random_tide.m).
    A change in any of these invalidates config.f_adjust.

deps.u_engine: Fields consumed by Uncertainty/apply_uncertainty.m
    (called from call_uncertainty_engine.m). A change in any of these
    invalidates config.u_engine.

deps.data_shape: Fields consumed by project_forcing_coverage.m (via
    call_project_forcing_formater.m). Unlike deps.f_adjust/deps.u_engine,
    this list is NOT equality-diffed against a cached config via
    any_field_changed.m -- project_forcing_coverage.m instead runs an
    asymmetric "does the cached data's coverage satisfy the request"
    check, where a cache having MORE than requested (e.g. cached CC data
    satisfying an XC-only request) is valid and must not be invalidated.
    use_peaks is deliberately NOT in this list: it only matters for PROS,
    and project_forcing_coverage.m branches on config.workflow internally
    to decide whether to check it at all (see that function).

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
deps.f_adjust = {'apply_depth_limitation','apply_random_tides','tide_file','swl_slr', ...
    'toe_elevation','wall_bottom_elevation','berm_elevation','berm_slope','berm_width'};
deps.u_engine = {'mcs_nLC'};
deps.data_shape = {'create_wlp','create_whp','use_timeseries','storm_sampling'};
end
