function [Stim, time, Pname] = FlincG3_Params(answer);
%% FlincG3_Params
%   Contains user-defined variables describing thermal stimuli for FlincG3
%   imaging experiments.
%

%% Code

global assaytype
if ~exist('answer')
    [answer, ok] = listdlg('PromptString','Which stimulus was applied during these recordings?',...
        'SelectionMode','single',...
        'ListString',{'pF Short (23->20->25->23)'});
    
    if ok<1
        error('User canceled analysis session');
    end
end

% Handle response
switch answer
    case 1 % pFictive 20->24C
        assaytype = 1;
        Stim.min = 20;
        Stim.max = 25;
        Stim.F0 = 20;
        Stim.holding = 23;
        Stim.NearTh = [20; 23];
        Stim.AboveTh = [23];
        Stim.Analysis = [22; 25];
        time.soak = 120; % duration (sec) of soak time at coolest point in thermal stimulus; indicates amount of time to wait before gathering data for export
        time.stimdur = 300; % duration (in sec) from start of F0 to end of upwards ramp
        time.rampspeed = 0.025; % rate of temperature change during primary phase, in degrees per second
        time.pad = [60; 0 ; 120; 600]; % start/end times of standardized "full" range for export; if Stim.min == Stim.F0, first 2 values should be 0,0
        Pname = 'pF PT short';
end