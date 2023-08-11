function [Stim, time, Pname] = Params(answer);
%% Params
%   Contains user-defined variables describing thermal stimuli for calcium
%   imaging experiments.
%
%   Version 1.0
%   Version Date: 07-24-23


%% Code

global assaytype
if ~exist('answer')
    [answer, ok] = listdlg('PromptString','Which stimulus was applied during these recordings?',...
        'SelectionMode','single',...
        'ListString',{'Liza (20->18->25->20)'}, ...
        'InitialValue', [1]);
    
    if ok<1
        error('User canceled analysis session');
    end
end

% Handle response
switch answer
        case 1 % Liza (20->18->25->20)
        assaytype = 1; % Positive thermotaxis
        Stim.min = 18;
        Stim.max = 25;
        Stim.F0 = 18;
        Stim.holding = 20;
        Stim.NearTh = [19; 21];
        Stim.AboveTh = [21];
        Stim.Analysis = [18; 25]; % Pick two temperatures to quantify mean calcium response at.
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 360; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.05; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 160; 370]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'U-Turn';
end