function [] = MakeTheHeatmap(Ca, avg_Tmp, err_Tmp, n, range)

global newdir
global assaytype

% Use hierarchical clustering to determine optimal order for rows
% the method for the linkage is: Unweighted average distance (UPGMA), aka
% average linkage clustering
D = pdist(Ca);
tree = linkage(D, 'average');
leafOrder = optimalleaforder(tree, D);

% Reorder Calcium traces to reflect optimal leaf order
Ca = Ca(leafOrder, :);

figure
colormap(viridis);
subplot(3,1,[1:2]);
imagesc(Ca,range);
set(gca,'XTickLabel',[]);
xlim([0, round(size(avg_Tmp,1),-1)]);
ylabel('Worms');
colorbar

subplot(3,1,3);
colors = get(gca,'colororder');
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'r',0);
set(gca,'xtickMode', 'auto');
ylim([15, 30]);
xlim([0, round(size(avg_Tmp,1),-1)]);
ylabel('Temperature (celcius)','Color','r');
xlabel('Time (seconds)');
currentFigure = gcf;
colorbar

title(currentFigure.Children(end), strcat(n,'_Heatmap'),'Interpreter','none');

movegui('northeast');

saveas(gcf, fullfile(newdir,['/', n, '-heatmap.eps']),'epsc');
saveas(gcf, fullfile(newdir,['/', n, '-heatmap.jpeg']),'jpeg');

close all
end