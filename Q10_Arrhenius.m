Qten = (Results.ResponseBin2./Results.ResponseBin2)
Qten = (Results.ResponseBin2-Results.ResponseBin1)./abs(Results.ResponseBin1)


Results.Thresh.temp(ii) + 0.5

for ii = 1 : size(Temps.subset,2)
    a = Temps.subset(~isnan(Temps.subset(:,ii)),ii);
   b = CaResponse.subset(~isnan(Temps.subset(:,ii)),ii); 
   
   c = a(find(a >= (Results.Thresh.temp(ii) + 0.5) & a <= Results.Thresh.temp(ii)+1.0));
   d = b(find(a >= (Results.Thresh.temp(ii) + 0.5) & a <= Results.Thresh.temp(ii)+1.0));
   
   T = c + 273.15; % Convert C to K
X = 1000./T;
Y = log(d);

figure;
subplot(1,2,1), plot(c,d);
axis tight
subplot(1,2,2), plot(X,Y);
axis tight
   
end

for ii = 1:numfiles
    
  
   a = Temps.subset(~isnan(Temps.subset(:,ii)),ii);
   b = CaResponse.subset(~isnan(Temps.subset(:,ii)),ii); 
   
   c = a(find(a >= (Results.Thresh.temp(ii) + 0.5) & a <= Results.Thresh.temp(ii)+1.0));
   d = b(find(a >= (Results.Thresh.temp(ii) + 0.5) & a <= Results.Thresh.temp(ii)+1.0));
    
    edges = (floor(min(c)):0.2:ceil(max(c)));
    [~,~,loc] = histcounts(c,edges);
    tempsBin = edges(1:size(edges,2)-1)';
    avgCaBin = accumarray(loc,d) ./ accumarray(loc,1);
    %plot(edges(1:size(edges,2)-1),avgCaBin);

T = tempsBin + 273.15; % Convert C to K
X = 1000./T;
Y = log(avgCaBin);
%plot(1000./T,log(avgCaBin))

T = c + 273.15; % Convert C to K
X = 1000./T;
Y = log(d);

figure;
subplot(1,2,1), plot(c,d);
axis tight
subplot(1,2,2), plot(X,Y);
axis tight



figure;
subplot(1,2,1), plot(edges(1:size(edges,2)-1),avgCaBin);
axis tight
subplot(1,2,2), plot(1000./T,log(avgCaBin));
axis tight

clear avgCaBin tempsBin
end