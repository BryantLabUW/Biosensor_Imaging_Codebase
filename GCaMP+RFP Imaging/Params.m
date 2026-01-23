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
        'ListString',{'Parasite Heating (23->20->40->23)', ...
        'Pristy (20->15->30->20)'}, ...
        'InitialValue', [1]);
    
    if ok<1
        error('User canceled analysis session');
    end
end

% Handle response
switch answer
    case 1 % Heating Extended (20 -> 40C @0.025C/s)
        assaytype = 1; % Positive Thermotaxis
        Stim.min = 20;
        Stim.max = 40;
        Stim.F0 = 20;
        Stim.holding = 23;
        Stim.NearTh = [20; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [32; 34];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 880; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [60; 0 ; 120; 1060]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF PT extended';

        case 2 % Paula (20->15->30->20)
        assaytype = 1; % Positive thermotaxis
        Stim.min = 15;
        Stim.max = 30;
        Stim.F0 = 15;
        Stim.holding = 20;
        Stim.NearTh = [19; 21];
        Stim.AboveTh = [21];
        Stim.Analysis = [18; 25]; % Pick two temperatures to quantify mean calcium response at.
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 360; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.05; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 0; 700]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'P. pacificus';
end