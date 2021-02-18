function [rsq, Correlation] = TCI_ResponseFitting (Temps,CaResponse, degree,name)
%%  TCI_ThermalResponseFitting
%   Linear fitting and correlation analysis of a set of temperature-driven calcium responses
%   Input is a structure array with fields named Temps and CaResponse
%   [rsq, Correlation] = TCI_ResponseFitting (Temps, CaResponse, degree, name)
%
%   Version number 1.0
%   Version date: 4-1-20
%
%% Revision History
%   10-16-19 Created by ASB
%   04-01-20    Name revised by ASB
%

%% Code
global newdir
global plotlogic

figure;
for i = 1:size(Temps,2)
    % Indexing
    index = ~isnan(Temps(:,i));
    
    % Linear Regression
    [p{i},S{i}] = polyfit(Temps(index,i),CaResponse(index,i),1);
    yfit = polyval(p{i},Temps(index,i));
    yresid = CaResponse(index,i) - yfit; % compute the residual vales as a vector of signed numbers
    SSresid = sum(yresid.^2); % square the residuals and total them to obtain the residual sum of squares
    SStotal = (length(CaResponse(index,i))-1)* var(CaResponse(index,i)); % compute the total sum of squares of y by multiplying the variance of y by the number of observations minus 1
    rsq(i) = 1 - SSresid/SStotal; % compute R^2 using its formula. Multiply this by 100 to get the percent of the variance predicted in the variable y by the linear fit.
    
    if degree == 1
        % Pearson's Correlation.
        [R, P, RL, RU] = corrcoef(Temps(index,i),CaResponse(index,i)); % R = pearson's R.
        %   Range from -1 to 1, with -1 = perfect negative linear relationship,
        %   0 = no linear relationship, 1 = perfect positive linear
        %   relationship between variables.
        Correlation.R(i) = R(2);
        Correlation.P(i) = P(2);
        Correlation.RL(i) = RL(2);
        Correlation.RU(i) = RU(2);
    elseif degree == 2
        % Spearmans Correlation
        [Rho, Pval] = corr (Temps(index,i),CaResponse(index,i),'type','Spearman');
        Correlation.R(i) = Rho;
        Correlation.P(i) = Pval;
    end
    % Plotting
    subplot(size(Temps,2),1,i);
    plot(Temps(index,i), CaResponse(index,i),'.',Temps(index,i),yfit,'-');
    
end
currentFigure = gcf;
title(currentFigure.Children(end), strcat(name,' Linear Fit'),'Interpreter','none');

if plotlogic > 0
    saveas(gcf, fullfile(newdir,['/', name, 'linear_fits.jpeg']),'jpeg');
end
close all
end