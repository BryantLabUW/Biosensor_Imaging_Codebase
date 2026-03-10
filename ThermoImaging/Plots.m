function [] = Plots(Temps, CaResponse, UIDs, n, numfiles, Results)
%% Plots
%   Generates and saves plots of Fluorescent Thermal Imaging
%   Plots(Temps, CaResponse, UIDs, n, numfiles, Results)
%

global plots

%% Plot Individual Traces

if plots.plteach == 1
    for i = 1:numfiles
        DrawThePlots(Temps(:,i), CaResponse(:,i), UIDs{i}, Results.out(i));
    end
end
set(0,'DefaultFigureVisible','on');

%% Plot Average Traces and Heat Maps
if numfiles > 1
    % Calculate Mean and SD with non-normalized data
    avg_Tmp = mean(Temps,2,'omitnan');
    sd_Tmp = std(Temps,[],2,'omitnan');
    
    % Multiple line plot
    if plots.pltmulti == 1
        MakeTheMultipleLinePlot(CaResponse, avg_Tmp, sd_Tmp, n, median(Results.out, 'omitnan'));
    end
        
    % Normalize traces to the maximum calcium
    % response amongst all traces.
    % Used for Heatmap with normalized data
    

    if plots.pltheat == 1
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