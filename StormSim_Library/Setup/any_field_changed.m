function [changed, changed_field] = any_field_changed(a, b, field_names)
%ANY_FIELD_CHANGED True if any named field's value differs between two structs.
%{
%% DESCRIPTION
Generic struct-field comparator with no domain knowledge of what the
fields mean. Field names present in only one of the two structs are
treated as "not changed" for that field (not an error) -- this makes
it safe to compare a freshly-parsed config against an older cached
config that may predate a field being introduced.

%% INPUTS
a, b: Two structs to compare.
field_names: Cell array of field name strings to check.

%% OUTPUTS
changed: true if any named field is present in both structs and its
         value differs (via isequal); false otherwise.
changed_field: Name of the first field found to differ, or '' if
               changed is false.

%R DEV SIGNATURE
Developed by: Fabian A. Garcia Moreno ERDC-CHL
%}
changed = false;
changed_field = '';
for kk = 1:numel(field_names)
    fld = field_names{kk};
    if isfield(a, fld) && isfield(b, fld) && ~isequal(a.(fld), b.(fld))
        changed = true;
        changed_field = fld;
        return
    end
end
end
