%===========================================
%  Description: Operational MATLAB code to generate JSON of Water Year Indices for Sacramento/San Joaquin River Basins
%  Author: J. Abatzoglou
%  Date: 2024/11/21
%  Still needs: 
% 	1) update models and isolate to models that are operational
%	2) download last years's water year index

%===========================================
%    RUNTIME OPTIONS
%===========================================
% option to use observed plus CFSv2 for current month
optionS2S=1;

%===========================================
%   CURRENT MONTH
%===========================================
% need to figure out what month it is
today=clock;
todayyear = today(1);
todaymonth=today(2);
doy_today_firstofmonth=datenum(todayyear,today(2),1)-datenum(todayyear,1,0);
if leapyear(todayyear);
        days_in_months = [31 29 31 30 31 30 31 31 30 31 30 31 ];
else;
        days_in_months = [31 28 31 30 31 30 31 31 30 31 30 31 ];
end;
days_in_currentMonth = days_in_months(todaymonth);

%===========================================
%   LAST YEAR's WYI
%===========================================
[lwSac,lwSJ] = get_lastyears_waterindex();

%===========================================
%  PARAMETERS
%===========================================
path_gridmet_monthly = 'http://thredds.northwestknowledge.net:8080/thredds/dodsC/MET/summaries/';
path_gridmet_daily = 'http://thredds.northwestknowledge.net:8080/thredds/dodsC/MET/';
path_cfsgridmet = 'http://thredds.northwestknowledge.net:8080/thredds/dodsC/NWCSC_INTEGRATED_SCENARIOS_ALL_CLIMATE/cfsv2_metdata_90day/';
path_nmme_ensembles = '/data/nmme/new_nmme/ensembles/rawNMME_1982ToCurrent/MAT/';

t1={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sept';'Oct';'Nov';'Dec'};

wyind=todayyear-1978;
if todaymonth<9 wyind=wyind-1;end

%===========================================
% this will only run between October and March!
if todaymonth>=10 | todaymonth<=3

	%===========================================
	%   GET LAT/LON AND SUBSET INDICES
	%===========================================
	file_test = [path_gridmet_monthly,'metdata_tmean_monthlyTimeSeries_Jan.nc'];
	lat=ncread(file_test,'lat');
	lon=ncread(file_test,'lon');

	%get target lat/lon indices
	LATS =[33.5 42.5];
	LONS = [-123.5 -117.9];
	indices_lat = find(lat>=min(LATS) & lat<=max(LATS));
	indices_lon = find(lon>=min(LONS) & lon<=max(LONS));

	lon=lon(indices_lon);lat=lat(indices_lat);

	%temporary variables 
	f2 = indices_lon; f = indices_lat;
	%===========================================
	%  GET GRIDMET MONTHLY T/P DATA (1979-2024)
	%===========================================
	start = [indices_lon(1) indices_lat(1) 1];
	count = [length(indices_lon) length(indices_lat) Inf];
	stride = [1 1 1];
	for i=1:12
	    t=ncread([path_gridmet_monthly,'metdata_tmean_monthlyTimeSeries_',char(t1(i)),'.nc'],'air_temperature',start,count,stride);
	    tmeanobs(:,:,1:size(t,3),i)=single(t);
	    p=ncread([path_gridmet_monthly,'metdata_pr_monthlyTimeSeries_',char(t1(i)),'.nc'],'precipitation_amount',start, count, stride);
	    probs(:,:,1:size(p,3),i)=single(p);
	end

	%permute to month x year(1979-2024) x lon(216) x lat(134)
	tmeanobs=permute(tmeanobs,[2 1 4 3]);
	probs=permute(probs,[2 1 4 3]);
	tmeanobs=permute(tmeanobs,[3 4 1 2]);
	probs=permute(probs,[3 4 1 2]);

	%===========================================
	%   SPATIAL MEAN OVER RIVER BASIN
	% SACRAMENTO (1) and SAN JOAQUIN(2) RIVER BASINS 
	%===========================================
	% spatial mask of river basins for gridmet grid
        m=matfile('newgridbasin');
        mask_sac = m.a; %sacramento
        mask_sanjoaq = m.a4; %san joaquin

	% mean over all space in river basin
	tmeanobsd(:,:,1)=nanmean(tmeanobs(:,:,mask_sac),3);
	tmeanobsd(:,:,2)=nanmean(tmeanobs(:,:,mask_sanjoaq),3);
	probsd(:,:,1)=nanmean(probs(:,:,mask_sac),3);
	probsd(:,:,2)=nanmean(probs(:,:,mask_sanjoaq),3);
	clear tmeanobs probs 

	%===========================================
	% SHIFT TIMES TO START IN OCTOBER: HISTORICAL RECORD OF PAST WATER YEARS
	%===========================================
	probsd=permute(probsd,[3 1 2]);
	probsd=probsd(:,10:end);probsd(:,end+1:end+9)=NaN;
 	probsd=reshape(probsd,2,12,size(probsd,2)/12);

	tmeanobsd=permute(tmeanobsd,[3 1 2]);
	tmeanobsd=tmeanobsd(:,10:end);tmeanobsd(:,end+1:end+9)=NaN;
	tmeanobsd=reshape(tmeanobsd,2,12,size(tmeanobsd,2)/12);

	% tmeanobsd, probsd have dimensions: basin x month x water year(1980-2024)
	%===========================================
	%===========================================
	if optionS2S; % option to use observed plus CFSv2 for current month
		% next add data for the month to date
		if(today(3)<=2); %need accommodation for 1st/2nd of month because get error otherwise
			l=datenum(todayyear,today(2)-1,1)-datenum(todayyear,1,0);
		        flag=2; % special case
		else;
			l=datenum(todayyear,today(2),1)-datenum(todayyear,1,0);
			flag=0;
		end;

		start =  [indices_lon(1) indices_lat(1) l];
		count =  [length(indices_lon) length(indices_lat) Inf];
		stride = [1 1 1];

		%===========================================
		% GET GRIDMET FROM THIS MONTH
		%===========================================
		%get monthly precipitation from daily precipitation
		p1=ncread([path_gridmet_daily,'/pr/pr_',num2str(todayyear),'.nc'],'precipitation_amount',start,count,stride);
		p1=sum(p1,3);

		%get mean monthly temperature from daily min/max temperature
		t1=ncread([path_gridmet_daily,'/tmmn/tmmn_',num2str(todayyear),'.nc'],'air_temperature',start,count,stride);
		t2=ncread([path_gridmet_daily,'/tmmx/tmmx_',num2str(todayyear),'.nc'],'air_temperature',start,count,stride);
		t1=t1/2+t2/2;clear t2

		nd=size(t1,3);
		ndd=30-nd; 


		%new as of 10/3/25 -KCH
		%ndd needs to be less than 28 or cfs section will be in error
		if(ndd>28);
			ndd = 28;
		end;

		t1=mean(t1,3);

		%===========================================
		% GET MONTHLY CFS FORECASTS
		%===========================================
		start = [1 1 f2(1) f(1)];
		count = [ndd Inf length(f2) length(f)];
		stride = [1 1 1 1];

		%monthly precipitation
		p2=ncread([path_cfsgridmet,'cfsv2_metdata_forecast_48ENS_pr_daily_4d.nc'],'pr',start,count,stride);

		%make monthly meantemperature
		t2=ncread([path_cfsgridmet,'cfsv2_metdata_forecast_48ENS_tmmn_daily_4d.nc'],'tmmn',start,count,stride);
		t3=ncread([path_cfsgridmet,'cfsv2_metdata_forecast_48ENS_tmmx_daily_4d.nc'],'tmmx',start,count,stride);
		t2=t2/2+t3/2;clear t3

		if todaymonth<=2
		%get median ensemble forecast over next ndd days
		 p2=squeeze(nanmedian(sum(p2,1),2));
		 t2=squeeze(nanmedian(mean(t2,1),2));

		 p1=p1+p2;
		 rat1=(31-ndd)/30;
		 rat2=1-rat1;
		 t1=t1*rat1+t2*rat2;

		 pfor1(1)=nanmean(p1(mask_sac));
		 pfor1(2)=nanmean(p1(mask_sanjoaq));

		 tfor1(1)=nanmean(t1(mask_sac));
 		 tfor1(2)=nanmean(t1(mask_sanjoaq));
 		 pfor1=pfor1;
		else
		 p2=squeeze(sum(p2,1));t2=squeeze(mean(t2,1));
		 p1=repmat(p1,[1 1 48])+permute(p2,[2 3 1]);
		 rat1=(31-ndd)/30;
		 rat2=1-rat1;
		 t1=repmat(t1,[ 1 1 48])*rat1+permute(t2,[ 2 3 1])*rat2;
		 t1=permute(t1,[3 1 2]);
		 p1=permute(p1,[3 1 2]);

		 pfor1(:,1)=nanmean(p1(:,mask_sac),2);
		 pfor1(:,2)=nanmean(p1(:,mask_sanjoaq),2);

		 tfor1(:,1)=nanmean(t1(:,mask_sac),2);
 		 tfor1(:,2)=nanmean(t1(:,mask_sanjoaq),2);

		end
	end


	%===========================================
	% GET NMME ENSEMBLE FORECASTS
	%===========================================
	% updated the name of this .mat file 10/8/25 - KCH
	m=matfile([path_nmme_ensembles,'NMME_hindcast_CONUS_ALLEnsembles_1982Current.mat']);

	%it is necessary to flip the latitudes of the NMME data to match the gridMET/CFS-gridmET
	%grids of  42.4833 to  33.5250

	MODELS=m.MODELS;

	lon1=m.lon;  %values have been changed to  -125:-66;
	lat1=m.lat; 
	f=find(lon1>=-124 & lon1<=-118); %f=find(lon1>=360-124 & lon1<=360-118);
	f2=find(lat1>=36 & lat1<=42);

	lon1=lon1(f);lat1=lat1(f2);

	%no need to flip the longitudes and the tref/prec longitude data because this has been fixed in .mat
	tref=m.tref(f2,f,:,:,:,:,:);%tref=flip(m.tref(f2,f,:,:,:,:,:),2);
	pref=m.prec(f2,f,:,:,:,:,:);%pref=(m.prec(f2,sort(60-f),:,:,:,:,:));
	%lon1=flip(lon1);

	%precipitation in inches and temperature in K, convert precipitation to mm
	pref=pref*25.4;

	% 1 degree pixels
	aa=zeros(7,7);
	aa(2:3,4:5)=2;
	aa(4:6,3:4)=1;
	aa(6,5)=1;
	aa=flip(aa,2);
	tref=permute(tref,[3 4 5 6 7 1 2]);
	pref=permute(pref,[3 4 5 6 7 1 2]);

	clear tfor;clear pfor;
%lead x month x year x ens x model x region
	for i=1:2
	    f=find(aa==i);
	    tfor(:,:,:,:,:,i)=nanmean(tref(:,:,:,:,:,f),6);
	    pfor(:,:,:,:,:,i)=nanmean(pref(:,:,:,:,:,f),6);
	end
	clear tref pref


% should only go into this if we are not in March!!
  if todaymonth~=3
	[tfore,pfore]=aggregate_obs_forecast(tfor,pfor,todaymonth,m,today,flag,tmeanobsd,probsd,tfor1,pfor1,wyind);
  else
      tfore=0.25*tfor1+0.75*repmat(squeeze(mean(tmeanobsd(:,3:5,todayyear-1979),2))',[48 1])-repmat(mean(mean(tmeanobsd(:,3:6,13:42),2),3)',[48 1]);
      pfore=(pfor1+repmat(squeeze(sum(probsd(:,2:5,todayyear-1979),2))',[48 1]))./repmat(mean(sum(probsd(:,2:6,13:42),2),3)',[48 1]);
  end
	%===========================================
	% MODEL PARAMETERS FOR WATER YEAR INDEX
	%===========================================
	tmodel_sac=[0.3664   -0.0347];
	tmodel_sj=[    0.6509   -0.0441];

	pmodel_octmar_sj=[-1.6066   10.7832];
	pmodel_aprjul_sj=[-1.6342  8.1803];

	pmodel_octmar_sac=[-5.3714   25.8193];
	pmodel_aprjul_sac=[-1.8594   21.8557];

	%===========================================
	% GENERATE WATER YEAR INDICES FROM MODEL
	%===========================================

       if todaymonth~=3
	[wySAC]=wateryearcalc(squeeze(tfore(:,:,1)),squeeze(pfore(:,:,1)),tmodel_sac,pmodel_octmar_sac,pmodel_aprjul_sac,1,lwSac);
	[wySJ]=wateryearcalc(squeeze(tfore(:,:,2)),squeeze(pfore(:,:,2)),tmodel_sj,pmodel_octmar_sj,pmodel_aprjul_sj,2,lwSJ);
nmod=size(pfore,2);

	%[wySAC]=waterfor_sac(tforecast(:,:,1),pforecast(:,:,1),tmodel_sac,pmodel_octmar_sac,pmodel_aprjul_sac,1,lwSac);
	%[wySJ]=waterfor_sac(tforecast(:,:,2),pforecast(:,:,2),tmodel_sj,pmodel_octmar_sj,pmodel_aprjul_sj,2,lwSJ);
tfore=reshape(permute(tfore,[3 1 2]),2,24*nmod);
pfore=reshape(permute(pfore,[3 1 2]),2,24*nmod);
sj=table(tfore(2,:)',pfore(2,:)');
sac=table(tfore(1,:)',pfore(1,:)');
       else
	[wySAC]=wateryearcalc(squeeze(tfore(:,1)),squeeze(pfore(:,1)),tmodel_sac,pmodel_octmar_sac,pmodel_aprjul_sac,1,lwSac);
	[wySJ]=wateryearcalc(squeeze(tfore(:,2)),squeeze(pfore(:,2)),tmodel_sj,pmodel_octmar_sj,pmodel_aprjul_sj,2,lwSJ);
sj=table(tfore(:,2),pfore(:,2));
sac=table(tfore(:,1),pfore(:,1));
        end

writetable(sac,'sac.csv');
writetable(sj,'sjv.csv');
	%===========================================
	% TEST PLOT
	%===========================================
	if(0);
		subplot(2,1,1)
		cdfplot(wySAC(:));hold on
		plot([5.4 5.4],[0 1],'r');plot([6.5 6.5],[0 1],'y');
		plot([7.8 7.8],[0 1],'c');plot([9.2 9.2],[0 1],'b');
		xlabel('water year index')

		subplot(2,1,2)
		cdfplot(wySJ(:));hold on
		plot([2.1 2.1],[0 1],'r');plot([2.5 2.5],[0 1],'y');
		plot([3.1 3.1],[0 1],'c');plot([3.8 3.8],[0 1],'b');
		xlabel('water year index')
	end;

	%===========================================
	% OUTPUT JSON FILES AND TRANSFER TO WEBPAGE
	%===========================================
	% now one can output wySJ and wySAC as json files
	% files are 24 (ensembles) x 11 (models)

        %write to JSON only the non nans and sort them
        f = find(~isnan(wySAC));
        wySAC = wySAC(f);
        wySAC = sort(wySAC);

        f = find(~isnan(wySJ));
        wySJ = wySJ(f);
        wySJ = sort(wySJ);

        filename_wy = 'forecasted_wyi.json';
        date_string = [num2str(todayyear),'/',num2str(today(2)),'/',num2str(today(3))];
        JSONFILE_name= filename_wy;
        fid=fopen(JSONFILE_name,'w')
        s = struct("lastyear_wi_SAC", lwSac, ...
                   "lastyear_wi_SJ", lwSJ,...
                   "thisdate_wi_SAC",wySAC,...
                   "thisdate_wi_SJ",wySJ,...
                   "lastDateUpdated",date_string...
            );
        encodedJSON = jsonencode(s);
        fprintf(fid, encodedJSON);
        fclose('all');

	%===========================================
        % TRANSFER JSON TO WEBPAGE
        %===========================================
        PATH_WATER_YEAR_TOOL_SCP =  ['khegewisch@climate.nkn.uidaho.edu:/html/climate/NWTOOLBOX/pages/wateryeartype/JSON'];
        defaultFilename = filename_wy;
        scpstatus = system(['scp ',defaultFilename,' ',PATH_WATER_YEAR_TOOL_SCP]);

        PATH_WATER_YEAR_TOOL_SCP2 = ['khegewisch@climate-utils.nkn.uidaho.edu:/nethome/khegewisch/wateryeartype/'];
        defaultFilename = filename_wy;
        scpstatus = system(['scp ',defaultFilename,' ',PATH_WATER_YEAR_TOOL_SCP2]);

        %PATH_WATER_YEAR_TOOL_SCP2 = ['khegewisch@climate-toolbx.hpc.uidaho.edu:/content/climate-toolbox/FastAPI/static/data/wateryeartype/'];
        %defaultFilename = filename_wy;
        %scpstatus = system(['scp ',defaultFilename,' ',PATH_WATER_YEAR_TOOL_SCP2]);


	'finished successfully'
end
