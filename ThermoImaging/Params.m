function [Stim, time, Pname] = Params(answer);
%% Params
%   Contains user-defined variables describing thermal stimuli for calcium
%   imaging experiments.
%
%   Version 1.0
%   Version Date: 07-24-23


%% Code
if ~exist('answer')
    [answer, ok] = listdlg('PromptString','Which stimulus was applied during these recordings?',...
        'SelectionMode','single',...
        'ListString',{'Parasite Heating (23->20->40->23)', ...
        'Pristy (20->15->30->20)'}, ...
        'Other',...
        'InitialValue', [1]);
    
    if ok<1
        error('User canceled analysis session');
    end
end

% Handle response
switch answer
    case 1 % Heating Extended (20 -> 40C @0.025C/s)
        Stim.F0 = 20;
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 880; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = 120; % duration (sec) of prestimulus time to include. 
        Pname = '20to40WarmingRamp';

   case 2 % Paula (20->15->30->20)
        Stim.F0 = 15;
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 360; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.05; % rate of temperature change during primary phase, in degrees per second
        time.pad = 0; % duration (sec) of prestimulus time to include. 
        Pname = 'P. pacificus';
    
    case 3 % Other
        

end