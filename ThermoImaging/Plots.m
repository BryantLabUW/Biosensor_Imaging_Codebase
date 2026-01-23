function [] = Plots(Temps, CaResponse, UIDs, n, numfiles)
%% TCI_Plots
%   Generates and saves plots of Fluorescent Thermal Imaging
%   TCI_Plots(Temps, CaResponse, UIDs, n, numfiles)
%
%   Version 2.0
%   Version Date: 3-18-22
%
%% Revision History
%   3-31-20:    Forked from older version by ASB
%   2021_01_27  Changed heatmap such that the heamtap rows (individual
%               traces) are now ordered using average linkage distance.
%               Also changed the inputs to the heatmap so that the traces
%               are normalized to the maximum Ca2+ response for the group.

global plotflag
global plteach
global pltheat
global pltmulti

%% Plot Individual Traces
plotflag = 1 ;
if plteach == 1
    for i = 1:numfiles
        DrawThePlots(Temps(:,i), CaResponse(:,i), UIDs{i});
    end
end
set(0,'DefaultFigureVisible','on');

%% Plot Average Traces and Heat Maps
if numfiles > 1
    % Calculate Mean and SD with non-normalized data
    avg_Tmp = mean(Temps,2,'omitnan');
    sd_Tmp = std(Temps,[],2,'omitnan');
    
    % Multiple line plot
    if pltmulti == 1
        MakeTheMultipleLinePlot(CaResponse, avg_Tmp, sd_Tmp, n);
    end
        
    % Normalize traces to the maximum calcium
    % response amongst all traces.
    % Used for Heatmap with normalized data
    

    if pltheat == 1
        CaResponse_norm = CaResponse/max(max(CaResponse));
        setaxes = 1;
        while setaxes>0 % loop through the axes selection until you're happy
            switch assaytype
                case 1
                    range = {'-20', '100'};
                case 2
                    range = {'-10', '20'};
                case 3
                    range = {'-60', '60'};
            end
            
            answer = inputdlg({'Heatmap Range Min', 'Heatmap Range Max'}, ...
                'Heatmap Parameters', 1, range);
            range = [str2num(answer{1}), str2num(answer{2})];
            
            MakeTheHeatmap(CaResponse'*100, mean(Temps,2,'omitnan'), std(Temps,[],2,'omitnan'), n, range);
            
            answer = questdlg('Adjust Heatmap Params', 'Plot adjustment', 'Yes');
            switch answer
                case 'Yes'
                    setaxes=1;
                    close all
                case 'No'
                    setaxes=-1;
                case 'Cancel'
                    setaxes=-1;
            end
        end
        close all
        
    end
    
end
end