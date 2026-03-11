function [] = MakeTheTempVResponsePlot(Bin1_Temps, Bin1_Response, Bin2_Temps, Bin2_Response, n, Stim,labels)
global newdir
global assaytype

fig = figure;
ax.L = subplot(1,15,1:5);
hold on; 

plot(Bin1_Temps, Bin1_Response,'-');
% Calculate median response at each unique temperature measurement,
% then smooth the temperature and responses to reduce periodic
% trends triggered by outliers, which are likely instances where the specific
% temperature measurement are only observed in a small number of traces. 
[V, jj, kk] = unique(Bin1_Temps);
avg_Response = accumarray(kk, (1:numel(kk))', [], @(x) median(Bin1_Response(x), 'omitnan'));
avg_Temp = accumarray(kk, (1:numel(kk))', [], @(x) median(Bin1_Temps(x), 'omitnan'));
smoothed_Response = smoothdata(avg_Response,'movmedian',5);
smoothed_Temp = smoothdata(avg_Temp, 'movmedian',5);
plot(smoothed_Temp,smoothed_Response,'LineWidth', 2, 'Color', 'k');
hold off
ylabel('dF/F0 (%)');xlabel('Temperature (C)');
ylim([-50 50]);
xlim([20 25]);
title(labels{1});

ax.R = subplot(1,15,6:15);
hold on;
plot(Bin2_Temps, Bin2_Response,'-');

[V, jj, kk] = unique(Bin2_Temps);
avg_Response = accumarray(kk, (1:numel(kk))', [], @(x) median(Bin2_Response(x), 'omitnan'));
avg_Temp = accumarray(kk, (1:numel(kk))', [], @(x) median(Bin2_Temps(x), 'omitnan'));
smoothed_Response = smoothdata(avg_Response,'movmedian',10);
smoothed_Temp = smoothdata(avg_Temp, 'movmedian',10);
plot(smoothed_Temp,smoothed_Response,'LineWidth', 2, 'Color', 'k');
hold off

set(gca,'YTickLabel',[]); xlabel('Temperature (C)');
ylim([-50 400]);
xlim([25 34]);
title(labels{2});

if exist('Stim.NearTh')
    ax.L.XLim = [Stim.NearTh(1) Stim.NearTh(2)];
    ax.L.XTick = [Stim.NearTh(1):2:Stim.NearTh(2)];
    ax.R.XLim = [Stim.AboveTh(1) Stim.max];
    ar.R.XTick = [Stim.AboveTh:5:Stim.max]
elseif exist('Stim.BelowTh')
    ax.L.XLim = [Stim.BelowTh(2) Stim.BelowTh(1)];
    ax.L.XTick = [Stim.BelowTh(2):2:Stim.BelowTh(1)];
end

movegui('northeast');
setaxes = 1;
while setaxes>0 % loop through the axes selection until you're happy
    answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes');
    switch answer
        case 'Yes'
            setaxes=1;
            vals=inputdlg({'X Min Left','X Max Left','Y Min Left', 'Y Max Left','X Min Right','X Max Right','Y Min Right', 'Y Max Right'},...
                'New X/Y Axes',[1 35; 1 35; 1 35;1 35; 1 35;1 35; 1 35;1 35],{num2str(ax.L.XLim(1)) num2str(ax.L.XLim(2))  num2str(ax.L.YLim(1)) num2str(ax.L.YLim(2)) num2str(ax.R.XLim(1)) num2str(ax.R.XLim(2)) num2str(ax.R.YLim(1)) num2str(ax.R.YLim(2))});
            if isempty(vals)
                setaxes = -1;
            else
                ax.L.XLim(1) = str2double(vals{1});
                ax.L.XLim(2) = str2double(vals{2});
                
                ax.L.YLim(1) = str2double(vals{3});
                ax.L.YLim(2) = str2double(vals{4});
                
                ax.R.XLim(1) = str2double(vals{5});
                ax.R.XLim(2) = str2double(vals{6});
                
                ax.R.YLim(1) = str2double(vals{7});
                ax.R.YLim(2) = str2double(vals{8});
            end
        case 'No'
            setaxes=-1;
        case 'Cancel'
            setaxes=-1;
    end
end

saveas(gcf, fullfile(newdir,['/', n, '-Temperature vs FlincG3Response_lines']),'epsc');
saveas(gcf, fullfile(newdir,['/', n, '-Temperature vs FlincG3Response_lines']),'jpeg');

close all
end