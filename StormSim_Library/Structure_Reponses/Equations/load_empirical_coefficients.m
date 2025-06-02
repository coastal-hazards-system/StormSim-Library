function [emp_coeff] = load_empirical_coefficients()
%% READ & FORMAT EMPIRICAL COEFFICIENTS FILE
% Import Empirical Coefficients Reference Document
emp_coeff2 = readcell('StormSim_empirical_coefficients.txt'); % [ variable_name, description, Units, Value, Std ]
% Remove Headers
emp_coeff2 = emp_coeff2(2:end,:);
% Grab Fieldnames
fields_2_read = emp_coeff2(:,1);
% % Create Fields
for ii = 1:length(fields_2_read)
    emp_coeff.(fields_2_read{ii}) = emp_coeff2{ii,4}; % Mean Value
    emp_coeff.std.(fields_2_read{ii}) = emp_coeff2{ii,5}; % Std
end
end