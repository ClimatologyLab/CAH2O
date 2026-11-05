function [tforecast,pforecast]=aggregate_obs_forecast(tfor,pfor,todaymonth,m,today,flag,tmeanobsd,probsd,tfor1,pfor1,wyind);

	%===========================================
	%    REMOVE NANS FROM FINAL ARRAY
	%===========================================
        %only use the models that have some non-nan recent data
	 years_nmme = m.YEARS;
	indices_models=[];
	MODELS=m.MODELS;
	todayyear=today(1);
	% if you try to pull nmme for a month w/o data it will fail

	% fix to account for that in January, we are looking at Dec of previous year data -KCH (1/13/26)
        if(todaymonth == 1 & today(3)<=12);
        	yrindex_to_replace =todayyear  - min(years_nmme) + 1 - 1;
	else;
        	yrindex_to_replace =todayyear  - min(years_nmme) + 1;
	end;

        nmme_this_month =  squeeze(tfor(1,todaymonth,yrindex_to_replace,1,:,1));
        indices_models = find(~isnan(nmme_this_month));
        pull_month=todaymonth;
	inc_month=1;

% there are three cases to deal with
% 1) is once nmme forecasts are in for the month and last month of data has been completed. In this case
% pfor1 gets used for the rest of the current month and NMME forecasts appended thereafter (e.g., month 2)
% 2) nmme forecasts not in for the month yet, but last month has been completed. Here pfor1 gets used for current
% months, but we use last months forecast for months for later forecasts (month 2)
% 3) nmme forecasts and last month of data is not yet in. Here we use pfor for last month and the prior NMME forecast for month 2 for the current month

	if isempty(indices_models);
		% this means that NMME is not available yet, and we pull from the next month		 
		pull_month=todaymonth-1;
		if pull_month<1 pull_month=12;yrindex_to_replace=yrindex_to_replace-1;end;
		if flag==0 inc_month=2;end
		nmme_this_month =  squeeze(tfor(1+inc_month,pull_month,yrindex_to_replace,1,:,1));
		indices_models = find(~isnan(nmme_this_month)); % this now needs to pull from the next month!!
        end

        MODELS=MODELS(indices_models);
        nmod=length(MODELS);

        tfor=tfor(:,:,:,:,indices_models,:);
        pfor=pfor(:,:,:,:,indices_models,:);

	%===========================================
	%===========================================
	% which of these models are any good?
	% next lets loop through NMME forecasts 

	endmonth=4-pull_month
	startmonthp=inc_month+1;startmontht=inc_month+1;

	if pull_month==10 | pull_month==11
	 startmontht=startmontht+1;
        end

	if endmonth<1 
	    endmonth=endmonth+12;
	end

	nmontht=endmonth-inc_month;
	nmonthp=endmonth-inc_month;

	%===========================================
	% BIAS CORRECT NMME ENSEMBLES
	%===========================================
	% ideally we bias correct so that each ensemble has the same mean and
	% variance as observations over 1991-2020 period of record
	for basin=1:2;
	   for i=1:nmod
		 % figure out what component needs to be bias corrected
		 % month 1 does NOT need to besince it is downscaled CFSv2+obs
		 basep = [1991:2020]-1982;

		    modelt=squeeze(mean(tfor(startmontht:endmonth,pull_month,:,:,i,basin),1));
		    modelp=squeeze(sum(pfor(startmonthp:endmonth,pull_month,:,:,i,basin),1));
		    obst=squeeze(mean(tmeanobsd(basin,7-nmontht:6,:),2));
		    obsp=squeeze(sum(probsd(basin,7-nmonthp:6,:),2));
		    obspall=squeeze(sum(probsd(basin,2:6,:),2));obstall=squeeze(mean(tmeanobsd(basin,3:6,:),2));
		    % start obs in year 1982
		    obst=obst(3:end);obsp=obsp(3:end);obstall=obstall(3:end);obspall=obspall(3:end);
		    if todaymonth>9
			obst=obst(1:today(1)-1982);obsp=obsp(1:today(1)-1982);
		    else
			obst=obst(1:today(1)-1981);obsp=obsp(1:today(1)-1981);
		    end
		     todaya=todayyear;

		    tt=reshape(biascorrect2(modelt(:),obst),size(modelt));
		    pp=reshape(biascorrect2(modelp(:),obsp),size(modelt));
[nanmean(tt(todaya-1981,:),2)-nanmean(obst(:)) nanmean(pp(todaya-1981,:),2)./nanmean(obsp(:))]

		% here it can be combined with pfor1 and tfor1
	    	    pp=pp+pfor1(basin);
		    tt=tt*(nmontht/(nmontht+1))+tfor1(basin)/(nmontht+1);

		    switch todaymonth
			case 12,
			     modelp=pp(todaya-1981,:)+squeeze(probsd(basin,2,wyind));
	 		     modelt=tt(todaya-1981,:);
			case 1,
			    modelp=pp(todaya-1981,:)+squeeze(nansum(probsd(basin,2:3,wyind),2));
			     rata1=3/4;rata2=1/4;
			     modelt=tt(todaya-1981,:)*rata1+squeeze(tmeanobsd(basin,3,wyind))*rata2;
			case 2,
			    modelp=pp(todaya-1981,:)+squeeze(nansum(probsd(basin,2:4,wyind),2));
			   rata1=2/4;rata2=2/4;
				modelt=tt(todaya-1981,:)*rata1+squeeze(mean(tmeanobsd(basin,3:4,wyind)))*rata2;
			case 3,
			    modelp=pp(todaya-1981,:)+squeeze(nansum(probsd(basin,2:5,wyind),2));
			    
				rata1=1/4;rata2=3/4;
				modelt=tt(todaya-1981,:)*rata1+squeeze(mean(tmeanobsd(basin,3:4,wyind)))*rata2;
			case 10,
			    modelp=pp(todaya-1981,:);
			    modelt=tt(todaya-1981,:);
			case 11,
			    modelp=pp(todaya-1981,:);
			    modelt=tt(todaya-1981,:);
		    end; %switch

		    % convert to anomalies degrees C for T and fraction for P 1991-2020
		    % base


% damn, if there is another month, this needs to be fixed here by adjusting obstall and obspall
[nanmean(modelt(:)) nanmean(obstall(basep))]
		    tforecast(:,i,basin)=modelt-nanmean(obstall(basep));
		    pforecast(:,i,basin)=modelp./nanmean(obspall(basep));
   	     end; %i
	end; %basin
