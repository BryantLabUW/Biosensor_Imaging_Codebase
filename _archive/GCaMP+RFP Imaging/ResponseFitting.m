function [rsq, Correlation] = ResponseFitting (Temps,CaResponse, degree, Stim)
%%  ResponseFitting
%   Linear fitting and correlation analysis of a set of temperature-driven calcium responses
%   Input is a structure array with fields named Temps and CaResponse
%   [rsq, Correlation] = ResponseFitting (Temps,CaResponse, degree, Stim)
%

%% Code

% Calculate correlation across large time windows
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

end


% Calculate "instantaenous" correlation across 0.1C windows
%Subset the trace into 1 degree temperature bins?
if degree == 3
    rsq = [];
edges = [Stim.NearTh(1):2:Stim.max];

for i = 1:size(Temps,2)
    index = ~isnan(Temps(:,i));
    
    bins = discretize(Temps(index,i), edges);
    for ii = min(bins):max(bins)
        timeindex = find(bins == ii);
        responseindexed = CaResponse(timeindex, i);
        [rho, ~] = corr(timeindex, responseindexed);
        Correlation.R_instant(ii,i) = rho;
    end
    Correlation.R_ibins(:,i) = edges(2:end);
end
end
end