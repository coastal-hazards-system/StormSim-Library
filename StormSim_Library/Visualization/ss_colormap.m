function customColormap = ss_colormap(~)
% Define the number of colors
numColors = 64;
% Number of colors for the transition zone
transitionColors = 8;
% Create a colormap ranging from magenta to blue
startColor = [0.8 0 1];  % Magenta
endColor = [0 0 1];      % Blue
magentaSection = [linspace(startColor(1), endColor(1), transitionColors);
    linspace(startColor(2), endColor(2), transitionColors);
    linspace(startColor(3), endColor(3), transitionColors)]';
% Append the rest of the jet colormap
jetMap = jet(numColors - transitionColors);
% Concatenate magenta to blue and jet colormap
customColormap = [magentaSection; jetMap];
end