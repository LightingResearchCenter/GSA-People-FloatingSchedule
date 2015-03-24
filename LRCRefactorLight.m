function light = LRCRefactorLight(light, idx)
%LRCREFACTORLIGHT Summary of this function goes here
%   Detailed explanation goes here

[githubDir,~,~] = fileparts(pwd);
circadianDir = fullfile(githubDir,'circadian');
addpath(circadianDir);

light.illuminance = light.illuminance(idx);
light.cla = light.cla(idx);

x = light.chromaticity.x(idx);
y = light.chromaticity.y(idx);
z = light.chromaticity.z(idx);

% chromaticity = chromcoord('x',x,'y',y,'z',z);
% light.chromaticity = chromaticity;


end