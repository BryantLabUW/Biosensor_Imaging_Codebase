function [rsq, Correlation] = FlincG3_ResponseFitting (Temps,Response, degree,name)
%%  FlincG3_ThermalResponseFitting
%   Linear fitting and correlation analysis of a set of temperature-driven cGMP responses
%   Input is a structure array with fields named Temps and Response
%   [rsq, Correlation] = FlincG3_ResponseFitting (Temps, Response, degree, name)
%

%% Code
global newdir
global plotlogic

figure;
for i = 1:size(Temps,2)
    % Indexing
    index = ~isnan(Temps(:,i));
    
    % Linear Regression
    [p{i},S{i}] = polyfit(Temps(index,i),Response(index,i),1);
    yfit = polyval(p{i},Temps(index,i));
    yresid = Response(index,i) - yfit; % compute the residual vales as a vector of signed numbers
    SSresid = sum(yresid.^2); % square the residuals and total them to obtain the residual sum of squares
    SStotal = (length(Response(index,i))-1)* var(Response(index,i)); % compute the total sum of squares of y by multiplying the variance of y by the number of observations minus 1
    rsq(i) = 1 - SSresid/SStotal; % compute R^2 using its formula. Multiply this by 100 to get the percent of the variance predicted in the variable y by the linear fit.
    
    if degree == 1
        % Pearson's Correlation.
        [R, P, RL, RU] = corrcoef(Temps(index,i),Response(index,i)); % R = pearson's R.
        %   Range from -1 to 1, with -1 = perfect negative linear relationship,
        %   0 = no linear relationship, 1 = perfect positive linear
        %   relationship between variables.
        Correlation.R(i) = R(2);
        Correlation.P(i) = P(2);
        Correlation.RL(i) = RL(2);
        Correlation.RU(i) = RU(2);
    elseif degree == 2
        % Spearmans Correlation
        [Rho, Pval] = corr (Temps(index,i),Response(index,i),'type','Spearman');
        Correlation.R(i) = Rho;
        Correlation.P(i) = Pval;
    end
    % Plotting
%     subplot(size(Temps,2),1,i);
%     plot(Temps(index,i), Response(index,i),'.',Temps(index,i),yfit,'-');
    
end
% currentFigure = gcf;
% title(currentFigure.Children(end), strcat(name,' Linear Fit'),'Interpreter','none');
% 
% if plotlogic > 0
%     saveas(gcf, fullfile(newdir,['/', name, 'linear_fits.jpeg']),'jpeg');
% end
close all
end