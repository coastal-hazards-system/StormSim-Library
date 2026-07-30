function [Resp] = call_project_response(config, project_forcing, structure, create_plots)
% CALL_PROJECT_RESPONSE Computes structure response based on a workflow config.

    %% ================= CONFIGURATION & VARIABLE MAPPING =================
    % Modify these variables to change how fields are read from 'config'
    workflow       = config.workflow;
    storm_sampling = config.storm_sampling;
    use_peaks      = config.use_peaks;
    use_timeseries = config.use_timeseries;
    use_whp        = config.create_whp;
    use_wlp        = config.create_wlp;
    project_name   = config.project_name;
    struc_id       = config.struc_id;
    case_name      = config.case_name;
    
    % Core Output File Target
    save_target    = config.out_files.resp_data;
    % =====================================================================

    % Load Empirical Coefficients & Initialize Output Struct
    [emp_coeff] = load_empirical_coefficients();
    Resp        = struct();
    
    % Establish Base Output Directory 
    subDir = fullfile(config.outfolder, project_name, struc_id, case_name);

    %% COMPUTE STRUCTURE RESPONSE BASED ON WORKFLOW
    switch workflow
        
        case {1, 4} % ================= PROS WORKFLOW =================
            % Define workflow parameters
            wName  = ifthen(workflow == 4, 'FB', 'RB');
            subDir = fullfile(subDir, 'PROS');
            ensure_directory(subDir);

            % Process Peaks Datasets (PROS)
            if use_peaks && isfield(project_forcing, 'Peaks')
                disp('Running StormSim: Probabilistic Response Of Structures (PROS) - Peaks....');
                
                peak_fields = fieldnames(project_forcing.Peaks);
                for i = 1:numel(peak_fields)
                    fName = peak_fields{i};
                    
                    % Filter based on water level/height configurations
                    if (strcmp(fName, 'WLP') && ~use_wlp) || (strcmp(fName, 'WHP') && ~use_whp)
                        continue; 
                    end
                    
                    fprintf('   Processing %s dataset....\n', fName);
                    save_path = fullfile(subDir, sprintf('%s1_%s', wName, fName));
                    
                    Resp.Peaks.(fName) = stormsim_pros(config, ...
                        project_forcing.Peaks.(fName), structure, emp_coeff, save_path);
                end
            end

            % Process Timeseries Datasets (PROS)
            if use_timeseries && isfield(project_forcing, 'Timeseries')
                disp('Running StormSim: Probabilistic Response Of Structures (PROS) - Timeseries....');
                save_path = fullfile(subDir, [wName, '3']);
                
                Resp.Timeseries.Default = stormsim_pros(config, ...
                    project_forcing.Timeseries.Default, structure, emp_coeff, save_path);
            end

            % Plotting Outputs
            if create_plots
                disp('      Plotting StormSim: PROS Analysis outputs... ');
                call_pros_plots(config, structure, project_forcing, Resp);
            end

        case 3 % ================== CSR WORKFLOW ==================
            % Define workflow parameters
            subDir = fullfile(subDir, 'LCS');
            ensure_directory(subDir);

            % Process Peaks Datasets (CSR)
            if use_peaks && isfield(project_forcing, 'Peaks')
                disp('Running StormSim: Coastal Structure Reliability - Peaks....');
                
                peak_fields = fieldnames(project_forcing.Peaks);
                for i = 1:numel(peak_fields)
                    fName = peak_fields{i};
                    fprintf('   Processing %s dataset....\n', fName);
                    
                    Resp.Peaks.(fName) = stormsim_csr(config, ...
                        project_forcing.Peaks.(fName), structure, emp_coeff, 'peaks', subDir);
                end
            end

            % Process Timeseries Datasets (CSR)
            if use_timeseries && isfield(project_forcing, 'Timeseries')
                disp('Running StormSim: Coastal Structure Reliability - Timeseries....');
                
                Resp.Timeseries.Default = stormsim_csr(config, ...
                    project_forcing.Timeseries.Default, structure, emp_coeff, 'timeseries', subDir);
            end
    end

    %% EXPORT OUTPUTS
    disp('Saving project responses....');
    save(save_target, 'Resp', '-v7.3');
end

%% ================= HELPER FUNCTIONS =================
function ensure_directory(dir_path)
    % Verifies and creates directory if it doesn't exist
    if ~exist(dir_path, 'dir')
        mkdir(dir_path);
    end
end

function out = ifthen(cond, true_val, false_val)
    % Fast inline ternary condition
    if cond, out = true_val; else, out = false_val; end
end
