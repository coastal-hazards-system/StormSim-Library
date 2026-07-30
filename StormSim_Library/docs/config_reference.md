# StormSim Config Reference

The `config` struct is the single data object that flows through the entire StormSim pipeline. It is built in two stages: first from the user-supplied Excel input file, then augmented at runtime by the MATLAB setup and processing functions. This page documents every field — its type, units, default value, and which structure types it applies to.

**Structure types:**
- **Type 1** — Levee
- **Type 2** — Floodwall
- **Type 3** — Rubblemound
- **Type 4** — Low-Crested Breakwater (LCBW)

> Note: the `struc_type` description text inside the Levee, Floodwall, and Rubblemound `SS_*.xlsx` templates still reads "(Levee - 1, Floodwalls - 2, Rubblemound - 3)" with no mention of Type 4; only the LCBW template's description text has been updated to list all four. This is a cosmetic inconsistency in the Excel template content itself (out of scope for this doc).

---

## Table of Contents

1. [Project & Output Settings](#1-project--output-settings)
2. [CHS Forcing Data](#2-chs-forcing-data)
3. [Structure Geometry](#3-structure-geometry)
4. [Structure Properties](#4-structure-properties)
5. [Response Switches](#5-response-switches)
6. [Forcing Uncertainty](#6-forcing-uncertainty)
7. [MCS Module (LCS Workflow)](#7-mcs-module-lcs-workflow)
8. [CSR Module (LCS Workflow)](#8-csr-module-lcs-workflow)
9. [PROS Module](#9-pros-module)
10. [Runtime / Code-Added Fields](#10-runtime--code-added-fields)

---

## How Config Is Built

```
SS_*.xlsx  ──►  call_input_parser.m  ──►  call_environment_setup.m
                (parses Excel rows,         (derives out_files paths,
                 adds runtime metadata)      enforces type-specific
                                             constraints, sets hotstart
                                             state flags)
                       │
                       ▼
              CHS / Forcing / Response pipeline
              (may overwrite bias, uncertainty,
               and state flag fields)
```

Most fields in Sections 1–9 originate from the Excel file (`Model Variable Symbol` column). Exceptions are called out inline: the berm fields in Section 3 and all of Section 6 (Forcing Uncertainty) are set exclusively by MATLAB code and do not appear in any Excel template, despite being grouped here by subject matter rather than by source. Fields in Section 10 are also set exclusively by MATLAB code and do not appear in the Excel schema.

---

## 1. Project & Output Settings

Applies to all structure types. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `project_name` | string | — | `'Chicago Shoreline GRR'` | All | Project name used in output file headers and plot titles |
| `struc_id` | string | — | `'R7175_T3'` | All | Structure or transect identifier |
| `case_name` | string | — | `'Seawall_existing'` | All | Case name; used to name output subdirectory and .mat files |
| `outfolder` | string | — | `'SS_Outputs_7175_T3'` | All | Root StormSim output folder path (relative or absolute) |
| `project_datum` | string | — | `'IGLD85'` | All | Vertical datum label used in plot titles and axis labels |
| `project_CLs` | string | — | `'[84 90]'` | All | Confidence limit percentiles to compute (max 4; 50th always included). Entered as a string expression, e.g. `'[84 90]'` |
| `workflow` | integer | — | `1` | All | StormSim workflow selector: `1`=PROS, `3`=LCS, `4`=PROS-FB. Any other value raises an explicit validation error in `call_input_parser.m` (the former `2`=EVA alias has been removed) |
| `struc_type` | integer | — | `1` / `2` / `3` / `4` | All | Structure type: `1`=Levee, `2`=Floodwall, `3`=Rubblemound, `4`=Low-Crested Breakwater (LCBW) |
| `storm_sampling` | string | — | `'XC'` | All | Storm sampling scheme: `'XC'` (extratropical), `'TC'` (tropical), or `'CC'` (combined) |
| `swl_slr` | numeric | m | — | All | Sea level rise applied as a vertical offset to still water level (SWL) |
| `apply_random_tides` | logical | — | `0` | All | Apply random tidal sampling to storm SWL: `0`=Off, `1`=On |
| `apply_depth_limitation` | logical | — | `1` | All | Apply depth limitation to incident waves: `0`=Off, `1`=On |
| `use_peaks` | logical | — | `0` | All | Include CHS peaks files in the forcing dataset: `0`=Off, `1`=On |
| `use_timeseries` | logical | — | `1` | All | Include CHS timeseries files in the forcing dataset: `0`=Off, `1`=On |
| `create_wlp` | logical | — | `0` | All | Create Water Level Priority (WLP) peaks dataset (requires both `use_peaks=1` and `use_timeseries=1`): `0`=Off, `1`=On |
| `create_whp` | logical | — | `0` | All | Create Wave Height Priority (WHP) peaks dataset (requires both `use_peaks=1` and `use_timeseries=1`): `0`=Off, `1`=On |
| `create_plots` | logical | — | `1` | All | Generate output visualizations: `0`=Off, `1`=On |
| `load_project_forcing` | logical | — | `1` | All | Load `project_forcing` from a previously run case instead of re-sampling: `0`=sample new, `1`=load from `ref_case_name` |
| `ref_case_name` | string | — | `'none'` | All | Name of the reference case to load `project_forcing` from when `load_project_forcing=1`. Set to `'none'` to load from the current case |

---

## 2. CHS Forcing Data

Applies to all structure types. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `storm_duration` | numeric | hrs | `1` | All | Storm duration used in overtopping volume calculations |
| `chs_sp_depth` | numeric | m | — | All | CHS savepoint water depth; used as fallback if depth is not found in the h5 file attributes |
| `chs_dependencies` | string | — | `'..\CHS_Dependencies'` | All | Relative path to the CHS_Dependencies folder (read-only regional data: `Grid_Files`, `Probability_Masses`, `Bias_and_Uncertainty`). Used throughout `call_environment_setup.m` for regional file discovery via `dir()`/`contains()` |
| `chs_zip` | string | — | — | All | Relative path to the CHS zip archive or custom modeling .mat file containing storm data |
| `tide_file` | string | — | `'none'` | All | Relative path to tidal record file for random tidal sampling of storm SWL. Set to `'none'` if `apply_random_tides=0` |

---

## 3. Structure Geometry

Several fields are structure-type-specific. Sourced from Excel, except the berm fields noted below.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `crest_elevation` | numeric | m | — | All | Crest elevation (levee/rubblemound) or top of wall elevation (floodwall) |
| `crest_width` | numeric | m | — | All | Crest width (levee/rubblemound) or wall thickness (floodwall) |
| `toe_elevation` | numeric | m | — | Types 1, 3, 4 | Mound toe elevation. Negative values are below the datum zero. Also present and populated in the Type 2 (floodwall) template, but gets overwritten by `wall_bottom_elevation` for Type 2 at runtime (see runtime override table in Section 10) |
| `wall_bottom_elevation` | numeric | m | — | Type 2 | Elevation of the bottom of the wall. Only applicable to floodwall (Type 2) |
| `seaside_slope` | numeric | — | — | Types 1, 3, 4 | Seaward face slope expressed as cot(α). Not applicable to Type 2 |
| `leeside_slope` | numeric | — | — | Types 1, 3, 4 | Landward face slope expressed as cot(α). Not applicable to Type 2 |

Not user-configurable via any current Excel template. `call_input_parser.m` (~lines 336-340) unconditionally hardcodes these four fields every run, with the code comment "Hide Berms Until Conceptual Models Are Set":

| Field | Type | Units | Hardcoded Value | Applicability | Description |
|-------|------|-------|------------------|---------------|-------------|
| `add_berm` | logical | — | `0` | All | Add a seaward berm to the structure cross-section: `0`=No berm, `1`=Add berm. Currently disabled pending future conceptual-model support |
| `berm_slope` | numeric | — | `1` | All | Berm slope (seaward and landward assumed equal). Ignored and set to 0 at runtime when `add_berm=0` |
| `berm_width` | numeric | m | `0` | All | Berm width. Set to 0 at runtime when `add_berm=0` |
| `berm_elevation` | numeric | m | `0` | All | Berm elevation. Set to `toe_elevation` (Types 1,3,4) or `wall_bottom_elevation` (Type 2) at runtime when `add_berm=0` |

Since `add_berm` is currently hardcoded to `0` on every run, this override logic in `call_environment_setup.m` (~lines 78-88) is always exercised; the fields remain live in `config` and would only vary if a future Excel template re-exposed `add_berm`.

---

## 4. Structure Properties

Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `water_density` | numeric | kg/m³ | `1000` | All | Water density used in wave force and stability calculations |
| `roughness_ifactor` | numeric | — | `0.9` | All | Roughness influence factor γ_f (EurOtop Table 6.2): `2`=grass, `1`=concrete/asphalt/closed blocks, `0.9`=basalt/placed revetment blocks, `0.8`=stepped structure |
| `armor_delta` | numeric | — | `1.65` | Types 2, 3, 4 | Armor stone immersed relative density Δ = (ρ_s − ρ_w) / ρ_w |
| `cem_P` | numeric | — | `0.4` | Types 3, 4 | Mean value of the notational permeability coefficient P (CEM Fig. VI-5-11) for Hudson/Van der Meer stability |
| `seaside_mass` | numeric | kg | — | Types 3, 4 | Seaside armor stone mass; used to derive existing Dn50 for damage number calculations |
| `leeside_mass` | numeric | kg | — | Type 3 | Leeside armor stone mass; used to derive existing Dn50 for damage number calculations |
| `seaside_design_S` | numeric | — | `0` | Type 3 | PROS design seaside damage limit state S for stone sizing. Set to `0` to compute required Dn50 |
| `leeside_design_S` | numeric | — | `0` | Type 3 | PROS design leeside damage limit state S for stone sizing. Set to `0` to compute required Dn50 |
| `seaside_S_uls` | numeric | — | `15` | Type 3 | LCS-CSR seaside ultimate limit state (ULS) damage number |
| `leeside_S_uls` | numeric | — | `15` | Type 3 | LCS-CSR leeside ultimate limit state (ULS) damage number |

---

## 5. Response Switches

Control which structural response quantities are computed. Sourced from Excel; some are enforced or overridden at runtime by `call_environment_setup.m` based on `struc_type`.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `compute_q` | logical | — | `1` | All | Compute mean overtopping discharge rate per unit width q (EurOtop): `0`=Off, `1`=On. Forced to `1` at runtime if `compute_nappe=1` |
| `compute_q_vol` | logical | — | `1` | All | Compute overtopping discharge volume per unit width (EurOtop): `0`=Off, `1`=On. Excel description text notes "RB3 Only" — RB3 refers to the Timeseries-derived response basis (Q_vol is integrated from a full discharge timeseries; see `compute_structure_response.m` comment "Find Max Responses For Timeseries (RB3)"), as opposed to RB1 (Peaks-derived response basis), not a "rubblemound-only" restriction. Forced to `0` for workflow=4 |
| `compute_wave_transmission` | logical | — | `1` | All | Compute wave transmission coefficient Kt (EurOtop): `0`=Off, `1`=On |
| `compute_damaging_depth` | logical | — | `0` | All | Compute damaging depth response: `0`=Off, `1`=On |
| `compute_damaging_depth_Ks` | numeric | — | `1` | All | Shielding parameter Ks used in damaging depth calculation. Only used when `compute_damaging_depth=1` |
| `compute_damaging_depth_slope` | numeric | — | — | All | Bottom slope tan(β) used in damaging depth calculation. Only used when `compute_damaging_depth=1` |
| `compute_r2p` | logical | — | `1` | Types 1, 3, 4 | Compute 2% run-up height R2% (EurOtop): `0`=Off, `1`=On. Not applicable to Type 2 |
| `compute_dn50_seaside` | logical | — | `1` | Type 3 | Compute seaward median stone size Dn50 response (Melby momentum flux method): `0`=Off, `1`=On |
| `compute_dn50_leeside` | logical | — | `1` | Type 3 | Compute landward median stone size Dn50 response (Van Gent): `0`=Off, `1`=On |
| `compute_dn50_submerged` | logical | — | `1` | Type 3 | Compute Dn50 responses when the structure is submerged (CEM VI-5-25): `0`=Off, `1`=On |
| `compute_dn50_lcbw` | logical | — | `1` | Type 4 | Compute seaward median stone size / stability response for low-crested breakwaters (Melby, `melby_low_crested_stability` → `Resp.Dn50_LCBW`/`Resp.FS_LCBW`): `0`=Off, `1`=On. Forced to `0` for Types 1–3 |
| `compute_p1` | logical | — | `1` | Type 2 | Compute surface pressure P1 (Goda): `0`=Off, `1`=On. Only applicable to Type 2 |
| `compute_p2_p3` | logical | — | `1` | Type 2 | Compute uplift pressure P2 and toe pressure P3 (Goda): `0`=Off, `1`=On. Only applicable to Type 2 |
| `compute_nappe` | logical | — | `1` | Type 2 | Compute nappe responses: `0`=Off, `1`=On. Only applicable to Type 2. Enabling this forces `compute_q=1` |

---

## 6. Forcing Uncertainty

Uncertainty parameters used by the uncertainty engine. **None of these fields appear in any `SS_*.xlsx` template** — they are all set by MATLAB code rather than sourced from Excel:

- `dn50_u`, `p1_u`, `q_u`, `r2p_u` are loaded unconditionally (regardless of `struc_type`) from `StormSim_Library/Structure_Reponses/Equations/primary_responses_epistemic_uncertainties.txt` in `call_input_parser.m` (~lines 343-349).
- `chs_swl_u_a`, `chs_swl_u_r`, `chs_hm0_u_a`, `chs_hm0_u_r` are set exclusively by `call_environment_setup.m`, either from a CHS_Dependencies regional bias/uncertainty file (~lines 254-257, 268-273) or, when no regional file is available, via an interactive `input()` manual-entry prompt (~lines 296-304). They have no fixed default — the value is always dynamically sourced, never defaulted. See `chs_swl_bu_source`/`chs_hm0_u_source` in Section 10 for how the source of each is recorded.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `chs_swl_u_a` | numeric | m | — | All | Still water level (SWL) absolute uncertainty U_a. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `chs_swl_u_r` | numeric | — | — | All | Still water level (SWL) proportional uncertainty U_r. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `chs_hm0_u_a` | numeric | m | — | All | Significant wave height Hm0 absolute uncertainty U_a. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `chs_hm0_u_r` | numeric | — | — | All | Significant wave height Hm0 proportional uncertainty U_r. Sourced from CHS_Dependencies or manual entry (see above); no fixed default |
| `dn50_u` | numeric | m | `0.15` | All | Median stone size Dn50 uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` |
| `q_u` | numeric | m³/s/m | `0.78` | All | Mean overtopping discharge uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` |
| `r2p_u` | numeric | m | `0.13` | All | Run-up R2% uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` |
| `p1_u` | numeric | N/m² | `0.43` | Type 2 | Surface pressure P1 uncertainty. Loaded from `primary_responses_epistemic_uncertainties.txt` for all structure types; only meaningful for Type 2 (Floodwall), the only type that computes P1 |

---

## 7. MCS Module (LCS Workflow)

Only used when `workflow=3` (Life Cycle Simulation). Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `mcs_nLC` | integer | — | `1000` | All (workflow=3) | Number of life cycles to simulate in the Monte Carlo simulation |
| `mcs_nYears` | integer | years | `50` | All (workflow=3) | Number of years per life cycle |

---

## 8. CSR Module (LCS Workflow)

Cumulative Storm Response (CSR) / Damage Progression Analysis (DPA) settings. Only active when `workflow=3`. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `csr_call_dpa` | logical | — | `0` | Type 3 | Activate the CSR-DPA module: `0`=Off, `1`=On. Only meaningful for Type 3 |
| `csr_apply_structure_repair` | logical | — | `0` | Type 3 | Allow structure repair during DPA analysis: `0`=Off, `1`=On |
| `csr_compute_S_submerged` | logical | — | `1` | Type 3 | Compute Dn50 responses when submerged during DPA (CEM VI-5-25): `0`=Off, `1`=On |
| `csr_apply_cutoff_correction` | logical | — | `0` | All | Apply a cutoff elevation correction in DPA: `0`=Off, `1`=On |
| `csr_cutoff_offset` | numeric | m | `0` | All | Cutoff elevation delta for DPA correction. Must be ≥ 0. Only used when `csr_apply_cutoff_correction=1` |

---

## 9. PROS Module

Probabilistic Response Output System (PROS) settings. Only active when `workflow=1` or `workflow=4`. Sourced from Excel.

| Field | Type | Units | Default | Applicability | Description |
|-------|------|-------|---------|---------------|-------------|
| `pros_compute_forcing_HC` | integer | — | `1` | All (workflow=1,4) | Compute hazard curves for waves and water level: `1`=On, `0`=Off. Forced to `1` at runtime when workflow=4 or when nappe/P2P3 responses are requested |
| `pros_use_aep` | logical | — | `0` | All (workflow=1,4) | Hazard curve x-axis convention: `1`=Annual Exceedance Probability (AEP), `0`=Annual Exceedance Frequency (AEF) |
| `pros_plot_hc` | logical | — | `1` | All (workflow=1,4) | Plot individual response hazard curves: `0`=Off, `1`=On |
| `pros_plot_forcing_hc_w_pot` | logical | — | `1` | All (workflow=1,4) | Plot forcing hazard curves with POT sample overlay: `0`=Off, `1`=On |
| `pros_plot_prioty_comp` | logical | — | `0` | All (workflow=1,4) | Plot RB1 priority dataset response comparisons: `0`=Off, `1`=On |
| `pros_plot_hc_xsec` | logical | — | `1` | All (workflow=1,4) | Plot hazard curve cross-section plots: `0`=Off, `1`=On |

---

## 10. Runtime / Code-Added Fields

These fields are **not present in the Excel input files**. They are computed and appended to `config` by MATLAB setup and processing functions.

### Set by `call_input_parser.m`

| Field | Type | Source File | Description |
|-------|------|-------------|-------------|
| `stormsim_input_file` | string | `call_input_parser.m` | Absolute path to the Excel input file used for the run |
| `gravity_constant` | numeric | `call_input_parser.m` | Gravitational acceleration constant (9.80665 m/s²) |
| `temp_path` | string | `call_input_parser.m` | Path to temporary working directory created during CHS zip extraction (`'Temp'` or `'Temp_N'`); empty string if no zip |
| `chs_files_2_convert` | cell (Nx2) | `call_input_parser.m` | Cell array of CHS h5 file paths and filenames queued for conversion |
| `region` | string | `call_input_parser.m` | CHS study region identifier parsed from the CHS filename (e.g., `'CHS-GLMH'`) |
| `sp_ID` | numeric | `call_input_parser.m` | CHS ADCIRC savepoint ID (integer, or `[]` if not applicable) |
| `sp_ID_wave` | numeric | `call_input_parser.m` | CHS wave model savepoint ID (integer, or `[]` if not applicable) |
| `name_prefix` | string | `call_input_parser.m` | Base string prefix for naming all output .mat files; includes simulation directory and region |
| `Nyrs_XC` | numeric | `call_input_parser.m` | Number of years in the extratropical storm record; `0` if sampling is TC-only |
| `Nstm_XC` | numeric | `call_input_parser.m` | Number of extratropical storms in record; only set for XC or CC sampling |
| `u_engine` | logical | `call_input_parser.m` | Hotstart state flag: `1` if uncertainty engine has already been applied to `project_forcing`, `0` otherwise |
| `f_adjust` | logical | `call_input_parser.m` | Hotstart state flag: `1` if forcing adjustments have been applied, `0` otherwise |
| `structure_dir` | numeric | `call_input_parser.m` | Structure orientation direction relative to waves (0 = shore-normal). Not yet implemented; hardcoded `0` |
| `chs_wDir_u_a` | numeric | `call_input_parser.m` | Wave direction absolute uncertainty. Not yet implemented; hardcoded `0` |
| `tide_std` | numeric | `call_input_parser.m` | Tidal standard deviation. Not yet implemented; hardcoded `0` |
| `print_progress` | logical | `call_input_parser.m` | Toggle progress output to the command window; always `true` |

### Set by `call_environment_setup.m`

| Field | Type | Source File | Description |
|-------|------|-------------|-------------|
| `out_files` | struct | `call_environment_setup.m` | Struct holding all output file paths for the simulation run (see subfields below) |
| `out_files.storm_and_prob_mass` | string | `call_environment_setup.m` | Full path to the transect-level storm + prob_mass .mat file |
| `out_files.chs_data` | string | `call_environment_setup.m` | Full path to the raw CHS_Data .mat file |
| `out_files.config` | string | `call_environment_setup.m` | Full path to the case-level config .mat save file |
| `out_files.resp_data` | string | `call_environment_setup.m` | Full path to the response data .mat file |
| `out_files.project_forcing` | string | `call_environment_setup.m` | Full path to the project_forcing .mat file |
| `chs_swl_b_a` | numeric | `call_environment_setup.m` | SWL absolute bias correction. Set from the CHS_Dependencies regional bias file (~line 254) when available, otherwise via the interactive manual-entry prompt (~line 296). **Not** set by `call_chs_storm_quality_check.m` — that function only reads/applies this value (see below) |
| `chs_swl_b_r` | numeric | `call_environment_setup.m` | SWL proportional bias correction. Same sourcing logic as `chs_swl_b_a` |
| `chs_swl_u_a` | numeric | `call_environment_setup.m` | SWL absolute uncertainty. Same sourcing logic as `chs_swl_b_a` (regional file ~line 256, or manual entry ~line 298) |
| `chs_swl_u_r` | numeric | `call_environment_setup.m` | SWL proportional uncertainty. Same sourcing logic as `chs_swl_b_a` |
| `chs_hm0_u_a` | numeric | `call_environment_setup.m` | Hm0 absolute uncertainty. Set from the CHS_Dependencies regional bias/uncertainty file (~line 268) when available, otherwise via manual entry (~line 303) |
| `chs_hm0_u_r` | numeric | `call_environment_setup.m` | Hm0 proportional uncertainty. Same sourcing logic as `chs_hm0_u_a` |
| `chs_swl_bu_source` | string | `call_environment_setup.m` | Records where THIS run's `chs_swl_b_a`/`chs_swl_b_r`/`chs_swl_u_a`/`chs_swl_u_r` values came from: `'chs_dependencies'` (regional file, ~line 258) or `'manual'` (interactive prompt, ~line 300). Not purely descriptive: `resolve_hotstart_state.m` uses it to gate hotstart carryover — a value freshly sourced from CHS_Dependencies this run always wins over a cached value; the cache is only consulted when this run has no file-based source (field absent or `'manual'`) |
| `chs_hm0_u_source` | string | `call_environment_setup.m` | Same role as `chs_swl_bu_source`, but for `chs_hm0_u_a`/`chs_hm0_u_r`: `'chs_dependencies'` (~line 274) or `'manual'` (~line 305) |

The following fields are **overridden** at runtime by `call_environment_setup.m` based on structure type and configuration logic:

| Field | Override Condition | Effect |
|-------|--------------------|--------|
| `berm_elevation` | `add_berm == 0` | Set to `toe_elevation` (Types 1,3,4) or `wall_bottom_elevation` (Type 2) |
| `toe_elevation` | Type 2 and `add_berm == 0` | Set to `wall_bottom_elevation` |
| `berm_slope` | `add_berm == 0` | Forced to `0` |
| `berm_width` | `add_berm == 0` | Forced to `0` |
| `compute_q` | `compute_nappe == 1` | Forced to `1` (nappe computation requires q) |
| `create_wlp` | `use_peaks` or `use_timeseries` is `0` | Forced to `0` |
| `create_whp` | `use_peaks` or `use_timeseries` is `0` | Forced to `0` |
| `storm_sampling` | TC probability masses not found | Forced to `'XC'` as a fallback |
| `pros_compute_forcing_HC` | `workflow == 4` or nappe/P2P3 requested | Forced to `1` |
| `compute_q_vol` | `workflow == 4` | Forced to `0` (cannot integrate q hazard curve in FB mode) |

### `call_chs_storm_quality_check.m`'s role

This function does **not set** `chs_swl_b_a`, `chs_swl_b_r`, `chs_swl_u_a`, or `chs_swl_u_r` — all four are assigned exclusively by `call_environment_setup.m` (see table above). `call_chs_storm_quality_check.m` is a **consumer**: it reads `chs_swl_b_a`/`chs_swl_b_r` and applies the bias correction formula to TC storm SWL values.

---

> **Note:** The authoritative schema for user-configurable fields is the `SS_*.xlsx` Excel input files (`Model Variable Symbol` column). This document is derived from `StormSim_Library` source code and the four Excel input files (levee, floodwall, rubblemound, low-crested breakwater).
