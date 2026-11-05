

--------------------------------------------------------------
		CRON JOB
--------------------------------------------------------------
The data for the water year type tool (https://climate.northwestknowledge.net/NWTOOLBOX/wateryeartype) is run with a cronjobs from root on zephyr at 6:01 pm each day. 

This is the current crontab for root: 
01 18 * * * /home/abatz/CAH2O/cron_run_water_year_index.cron >/home/katherine/CRONJOBS/LOGS/water_year_index_cron.log 2>&1

--------------------------------------------------------------
		SCRIPT RUN
--------------------------------------------------------------
The script that is run is /home/abatz/CAH2O/cron_run_water_year_index.cron.

--------------------------------------------------------------
		LOGS
--------------------------------------------------------------
The log for this run is here: 
/home/katherine/CRONJOBS/LOGS/water_year_index_cron.log 
There is a link to this file here: 
/home/abatz/CAH2O/water_year_index_matlab.out
view that log with: 
sudo more /home/abatz/CAH2O/water_year_index_matlab.out

--------------------------------------------------------------
		MANUALLY UPDATING WY INDEX FROM LAST YEAR (AROUND OCT 1)
--------------------------------------------------------------
Each year, we need to manually update the WY index for the last year here in this function: get_lastyears_waterindex.m 

        %John's guess for WY 2023-24
        lwSac=8.95;
        lwSJ=2.52;

where I think we get this info from here: 
https://cdec.water.ca.gov/reportapp/javareports?name=FNFSUM




