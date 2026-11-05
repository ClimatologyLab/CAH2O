function [wyf]=wateryearcalc(tfor,pfor,tmodel,pmodel_octmar,pmodel_aprjul,model,lW);

	%=======================================
	%  PARAMETERS FOR CALCULATION 
	%=======================================
%ref is not used
	if model==1; %sacramento river basin
	    	rat1=0.3;rat2=0.4;rat3=0.3;ref=5;miny=10;
	else; %san joaquin river basin
	     	rat1=0.2;rat2=0.6;rat3=0.2;ref=3;miny=4.5;
	end
	lW=min(lW,miny);  

	%=======================================
	%  
	%=======================================
	tfor=squeeze(tfor);
	pfor=squeeze(pfor);

	ratio=tmodel(1)+tfor*tmodel(2);
	ratio=max(min(1,ratio),0);

	poctmar=max(0,pmodel_octmar(1)+pmodel_octmar(2).*(1-ratio).*pfor);
	paprjul=max(0,pmodel_aprjul(1)+pmodel_aprjul(2).*(ratio).*pfor);

	%=======================================
	% REDO NAN MASK  
	%=======================================
	f=find(isnan(tfor));
	paprjul(f)=NaN;
	poctmar(f)=NaN;
	ratio(f)=NaN;

	%=======================================
	%  WATER YEAR INDEX CALCULATION
	%=======================================
	wyf = poctmar*rat1 + paprjul*rat2 + rat3*lW;


	%=======================================
	% next rerun to update wy
	%plot([2 16],[5.4 5.4],'--k');plot([2 16],[6.5 6.5],'--r');plot([2 16],[7.8 7.8],'--g');plot([2 16],[9.2 9.2],'--b');
	%legend({'Wet';'Above Normal';'Below Normal';'Dry';'Critical'})
end
