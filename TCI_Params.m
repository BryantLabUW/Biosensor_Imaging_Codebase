function [Stim, time, Pname] = TCI_Params(answer);
%% TCI_Params
%   Contains user-defined variables describing thermal stimuli for calcium
%   imaging experiments.
%
%   Version number: 1.1
%   Version date: 10-17-20

%% Revision History
%   10-19-19    Forked from crawl_Cam file by ASB
%   11-15-19    Added an F0 parameter, for when the baseline F0 isn't the
%               same as the minimum stimulus. (ASB)
%   03-01-20    Renamed and made prettier (ASB)

%% Code

global assaytype
if ~exist('answer')
    [answer, ok] = listdlg('PromptString','Which stimulus was applied during these recordings?',...
        'SelectionMode','single',...
        'ListString',{'Rapid Heating (23->17->40->23)';  'Cooling Ramp (23->22->13->23)'; 'Heating (23->20->34->23)'; 'Heating PT15 (15->12->26->15)';'Heating Extended (23->20->40->23)'; 'Heating PT15 extended (15->12->32->15)'; 'UTurn (15->22->15)'}, ...
        'InitialValue', [3]);
    
    if ok<1
        error('User canceled analysis session');
    end
end

% Handle response
switch answer
    case 1 % Rapid Heating Ramp (17 -> 40C @0.1C/s)
        assaytype = 1; % Positive Thermotaxis
        Stim.min = 17;
        Stim.max = 40;
        Stim.F0 = 17;
        Stim.holding = 23;
        Stim.NearTh = [19; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [23; 33]; % Pick two temperatures to quantify mean calcium response at.
        time.soak = 60; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 280; % duration of stimulus upwards ramp
        time.rampspeed = 0.1; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 120; 500]; % start/end times of standardized "full" range for export
        Pname = 'Pos Ramp 4';
        
case 2 % Cooling Ramp (22 -> 13C @ 0.1C/s)
        assaytype = 2; % Negative Ramp
        Stim.min = 13;
        Stim.max =23;
        Stim.F0 = 22;
        Stim.holding = 23;
        Stim.BelowTh = [22 ; 13];
        Stim.Analysis = [22; 13];
        time.soak = 120; % duration (sec) of soak time at F0
        time.stimdur = 375;
        time.rampspeed = .1; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0;0 ;120;580];
        Pname = 'Neg Ramp 2';

    case 3 % Heating Ramp (20 -> 34C @0.025C/s)
        assaytype = 1; % Positive Thermotaxis
        Stim.min = 20;
        Stim.max = 34;
        Stim.F0 = 20;
        Stim.holding = 23;
        Stim.NearTh = [20; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [23; 33];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 640; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [60; 0 ; 120; 760]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF PT';
        
    
        
     case 4 % Heating PT15 (12 -> 26C @0.025C/s) Tambient = 15
        assaytype = 3; % Positive Thermotaxis, Tambient = 15
        Stim.min = 12;
        Stim.max = 26;
        Stim.F0 = 12;
        Stim.holding = 15;
        Stim.NearTh = [12; 17];
        Stim.AboveTh = [17];
        Stim.Analysis = [22; 26];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 640; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [60; 0 ; 120; 760]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF PT15';
        
        case 5 % Heating Extended (20 -> 40C @0.025C/s)
        assaytype = 1; % Positive Thermotaxis
        Stim.min = 20;
        Stim.max = 40;
        Stim.F0 = 20;
        Stim.holding = 23;
        Stim.NearTh = [20; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [22; 25];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 880; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [60; 0 ; 120; 1060]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF PT extended';
        
         case 6 % Heating Extended PT15 (12 -> 32C @0.025C/s) Tambient = 15
        assaytype = 3; %Positive Thermotaxis, Tambient = 15
        Stim.min = 12;
        Stim.max = 32;
        Stim.F0 = 12;
        Stim.holding = 15;
        Stim.NearTh = [12; 17];
        Stim.AboveTh = [17];
        Stim.Analysis = [22; 32];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 880; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [60; 0 ; 120; 1060]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF pT15 extended';
        
        case 7 % U-turn Tc = 15
        assaytype = 4; % U-turn
        Stim.min = 15;
        Stim.max = 22;
        Stim.F0 = 15;
        Stim.holding = 15;
        Stim.NearTh = [15; 17];
        Stim.AboveTh = [17];
        Stim.Analysis = [22; 21.5];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 560; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 0; 900]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'U-Turn';
end