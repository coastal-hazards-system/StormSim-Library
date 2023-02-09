function [gamma_v,gamma_star] = wall_influence_factor(crest_elevation,toe_elevation,Rc,strucType)
    % Wall influence coefficients
    if strucType== 2 % Floodwall
        h_wall = crest_elevation-toe_elevation;
        % gamma_v and gamma_star are for influence of floodwall on a levee
        gamma_v = exp(-0.56*h_wall./Rc);
        gamma_star = gamma_v;
    else
        gamma_v    = ones(size(Rc));
        gamma_star = ones(size(Rc));
    end
end