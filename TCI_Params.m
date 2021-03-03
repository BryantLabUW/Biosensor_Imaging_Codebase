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
        'ListString',{'Pos Ramp 4 (23->17->40->23)';  'Neg Ramp 2 (23->22->13->23)'; 'pFictive PT (23->20->34->23)'; 'pFictive PT15 (15->12->26->15)';'pF Extended (23->20->40->23)'; 'pF PT15 extended (15->12->32->15)'});
    
    if ok<1
        error('User canceled analysis session');
    end
end

% Handle response
switch answer
    case 1 % Pos Ramp 4
        assaytype = 1;
        Stim.min = 17;
        Stim.max = 40;
        Stim.F0 = 17;
        Stim.holding = 23;
        Stim.NearTh = [19; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [18; 28]; % Pick two temperatures to quantify mean calcium response at.
        time.soak = 60; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 350; % duration of stimulus upwards ramp
        time.rampspeed = 0.1; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0;0 ; 120; 500]; % start/end times of standardized "full" range for export
        Pname = 'Pos Ramp 4';
        
%     case 2 % 'Pos Ramp 5 (23->17->25->23)';
%         assaytype = 1; % Positive Ramp
%         Stim.min = 17;
%         Stim.max = 25;
%         Stim.F0 = 17;
%         Stim.holding = 23;
%         Stim.NearTh = [19; 25];
%         Stim.AboveTh = [24.8];
%         Stim.Analysis = [17; 20];
%         time.soak = 60; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
%         time.stimdur = 350; % duration of stimulus upwards ramp
%         time.pad = [0;0 ; 120; 500]; % start/end times of standardized "full" range for export
%         Pname = 'Pos Ramp 5';
case 2 % Neg Ramp 2
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

    case 3 % pFictive Ramp
        assaytype = 1; % Pseudo-fictive Positive Thermotaxis
        Stim.min = 20;
        Stim.max = 34;
        Stim.F0 = 20;
        Stim.holding = 23;
        Stim.NearTh = [20; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [24; 33];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 800; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 60; 900]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'PseudoFictive PT';
        
    
        
     case 4 % pFictive Ramp Tc = 15
        assaytype = 3; % Pseudo-fictive Positive Thermotaxis
        Stim.min = 12;
        Stim.max = 26;
        Stim.F0 = 12;
        Stim.holding = 15;
        Stim.NearTh = [12; 17];
        Stim.AboveTh = [17];
        Stim.Analysis = [16; 25];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 800; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 60; 900]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'PseudoFictive PT 15C';
        
        case 5 % pFictive Extended Ramp
        assaytype = 1; % Pseudo-fictive Positive Thermotaxis
        Stim.min = 20;
        Stim.max = 40;
        Stim.F0 = 20;
        Stim.holding = 23;
        Stim.NearTh = [20; 25];
        Stim.AboveTh = [25];
        Stim.Analysis = [24; 33];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 1040; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 60; 1200]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pFictive Extended';
        
         case 6 % pFictive15 Extended
        assaytype = 3; %Tc = 15
        Stim.min = 12;
        Stim.max = 32;
        Stim.F0 = 12;
        Stim.holding = 15;
        Stim.NearTh = [12; 17];
        Stim.AboveTh = [17];
        Stim.Analysis = [16; 25];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 1040; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [0; 0 ; 60; 1200]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF pT15 Extended';
end