function [X]=biascorrect_tp(forecast,obs);
skip=1;
if skip 
    comm=11:40;
g=nanmean(forecast(comm,:),1);gs=nanstd(forecast(comm,:),[],1);
Z=(forecast-g)./gs;
g1=nanmean(obs(comm,:),1);gs1=nanstd(obs(comm,:),[],1);

X=Z.*gs1+g1;
else X=forecast;end
V=forecast(comm,:);V=V(:);
oo=obs(comm);
[F,X]=ecdf(forecast(:));
[F1,X1]=ecdf(obs(:));
%FF=interp1(X,F,forecast(:));
XX=interp1(F1,X1,F);
plot(F1,X1);
size(XX)
size(forecast(:))
