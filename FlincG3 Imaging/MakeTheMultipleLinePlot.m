function []= MakeTheMultipleLinePlot(Response, avg_Tmp,  err_Tmp, n, varargin)
% varargin = x axis locations to draw vertical lines
global newdir


C=cbrewer('qual', 'Dark2', 7, 'PCHIP');
set(groot, 'defaultAxesColorOrder', C);
fig = figure;
ax.up = subplot(3,1,[1:2]);

hold on;

for k = 1:length(varargin)
    xline(varargin{k},'LineWidth', 2, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
end
plot([1:size(Response,1)],Response, 'LineWidth', 1);
plot([1:size(Response,1)],median(Response,2, 'omitnan'),'LineWidth', 2, 'Color', 'k');

hold off;
xlim([0, size(Response,1)]);
ylim([floor(min(min(Response))),ceil(max(max(Response)))]);
ylim([-50, 100]);

set(gca,'XTickLabel',[]);
ylabel('dF/F0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
set(gca,'xtickMode', 'auto');
hold on; 
for k = 1:length(varargin)
    xline(varargin{k},'LineWidth', 2, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
end
hold off;
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
ylim([10, 41]);
xlim([0, size(Response,1)]);
ylabel('Temperature (celcius)','Color','k');
xlabel('Time (seconds)');
currentFigure = gcf;

title(currentFigure.Children(end), strcat(n,'_Avg FlincG3 Response'),'Interpreter','none');

movegui('northeast');
setaxes = 1;
while setaxes>0 % loop through the axes selection until you're happy
    answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes');
    switch answer
        case 'Yes'
            setaxes=1;
            vals=inputdlg({'X Min','X Max','Y Min Upper', 'Y Max Upper','Y Min Lower', 'Y Max Lower'},...
                'New X/Y Axes',[1 35; 1 35; 1 35;1 35; 1 35;1 35],{num2str(ax.up.XLim(1)) num2str(ax.up.XLim(2))  num2str(ax.up.YLim(1)) num2str(ax.up.YLim(2)) num2str(ax.dwn.YLim(1)) num2str(ax.dwn.YLim(2))});
            if isempty(vals)
                setaxes = -1;
            else
                ax.up.XLim(1) = str2double(vals{1});
                ax.up.XLim(2) = str2double(vals{2});
                ax.dwn.XLim(1) = str2double(vals{1});
                ax.dwn.XLim(2) = str2double(vals{2});
                ax.up.YLim(1) = str2double(vals{3});
                ax.up.YLim(2) = str2double(vals{4});
                ax.dwn.YLim(1) = str2double(vals{5});
                ax.dwn.YLim(2) = str2double(vals{6});
            end
        case 'No'
            setaxes=-1;
        case 'Cancel'
            setaxes=-1;
    end
end

saveas(gcf, fullfile(newdir,['/', n, '-multiplot.jpeg']),'jpeg');
saveas(gcf, fullfile(newdir,['/', n, '-multiplot.eps']),'epsc');

close all
end