function [i2]=biascorrect_tp(forecast,obs);
[F,X]=ecdf(obs);
[F1,X1]=ecdf(forecast);
[a,b]=unique(X1);
i=interp1(X1(b),F1(b),forecast);
[a,b]=unique(X);
i2=interp1(F(b),X(b),i);

