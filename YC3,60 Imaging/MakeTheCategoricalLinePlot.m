function []= MakeTheCategoricalLinePlot(Ca, avg_Tmp,  err_Tmp, category, n, vertline)
global newdir

% Break calcium imaging traces into two groups, depending on the
% categorical grouping variable (logical array).
Ca_group1 = Ca(:,category); 
Ca_group2 = Ca(:,~category);

C=cbrewer('qual', 'Dark2', 7, 'PCHIP');
set(groot, 'defaultAxesColorOrder', C);
fig = figure;
ax.up = subplot(3,1,[1:2]);

hold on;

xline(vertline,'LineWidth', 2, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
% plot([1:size(Ca_group1,1)],Ca_group1, 'LineWidth', 1);
% plot([1:size(Ca_group1,1)],median(Ca_group1,2, 'omitnan'),'LineWidth', 2, 'Color', 'k');

 plot([1:size(Ca_group2,1)],Ca_group2, 'LineWidth', 1);
 plot([1:size(Ca_group2,1)],median(Ca_group2,2, 'omitnan'),'LineWidth', 2, 'Color', 'k');

hold off;
xlim([0, size(Ca,1)]);
ylim([floor(min(min(Ca))),ceil(max(max(Ca)))]);
ylim([-50, 100]);

set(gca,'XTickLabel',[]);
ylabel('dR/R0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
set(gca,'xtickMode', 'auto');
hold on; 
xline(vertline,'LineWidth', 2, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
hold off;
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
ylim([10, 41]);
xlim([0, size(Ca,1)]);
ylabel('Temperature (celcius)','Color','k');
xlabel('Time (seconds)');
currentFigure = gcf;

title(currentFigure.Children(end), strcat(n,'_ Avg Cameleon Response'),'Interpreter','none');

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

saveas(gcf, fullfile(newdir,['/', n, '-categoricalplot_g2.jpeg']),'jpeg');
saveas(gcf, fullfile(newdir,['/', n, '-categoricalplot_g2.eps']),'epsc');

close all
end