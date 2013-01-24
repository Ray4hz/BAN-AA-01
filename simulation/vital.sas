/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	vital sign
Description:	
				To generate vital sign data		
      Input:	
     Output:	vital.vital
 Programmer:	Ray (Hang Zhong)
    Created:	
	   QCer:	
	QC date:	
      Notes:	
********************************************************************************************************************/ 
* autocall macros; 
filename autoM "C:\bancova\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 
* set up the libname; 
%include "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\program\libname.sas"; 

* only when VISITNUM = 5,5.1,7,7.1 there is no vital sign record; 
data svisit; 
	set visit.svisit; 
run; 

* 12696; 
data vs1; 
	set svisit; 
	if VISITNUM in (5,5.1,7,7.1) then delete; 
run; 

proc freq data = vs1; 
	tables VISITNUM; 
run; 

data death; 
	set survival.death; 
	keep SUBJID CENSOR USUBJID; 
run; 

proc sql; 
	create table vs2 as
	select *
	from vs1 as a, death as b
	where a.SUBJID = b.SUBJID; 
quit; 

data trt; 
	set demog.dm; 
	keep SUBJID TREATMENT; 
run; 

proc sql; 
	create table vs as
	select * 
	from vs2 as a, trt as b
	where a.SUBJID = b.SUBJID; 
run; 

proc sort data = vs; 
	by SUBJID VISITDT; 
run; 

data vital; 
	set vs; 
	by SUBJID; 
	retain BMI HEIGHT WEIGHT; 
	if first.SUBJID then do; 
		BMI = round((22.5 + normal(0)*2), .1); 
		HEIGHT = round((1.82 + normal(0)*0.05), .001); 
		WEIGHT = round(BMI*HEIGHT**2, .1); 
	end; 
		* treatment group should be more stable then placebo group, and dead patient should be worse; 
		* weight decrease as time goes by; 
		if TREATMENT = 1 then do; 
			if CENSOR = 1 then do; 
				SYSTBP 	= 	110 + normal(0)*20; 
				DIASBP 	= 	SYSTBP - 20 + normal(0)*3; 
				PULSE 	= 	80 + int(normal(0)*5); 
				TEMPER 	= 	38 + normal(0)*.8; 
				x = round((WEIGHT - ranuni(0)*5), .1); 
				if ((WEIGHT*0.7 < x) and (x > 30 )) then WEIGHT = x; 
			end; 
			else do; 
				SYSTBP 	= 	110 + normal(0)*5; 
				DIASBP 	= 	SYSTBP - 20 + normal(0)*3; 
				PULSE 	= 	80 + int(normal(0)*5); 
				TEMPER 	= 	38 + normal(0)*.2; 
			end; 
		end; 
		else do; 
			if CENSOR = 1 then do; 
				SYSTBP 	= 	110 + normal(0)*30; 
				DIASBP 	= 	SYSTBP - 20 + normal(0)*3; 
				PULSE 	= 	80 + int(normal(0)*5); 
				TEMPER 	= 	38 + normal(0)*1.2; 
				x	= 	round((WEIGHT - ranuni(0)*10), .1); 
				if ((WEIGHT*0.7 < x) and (x > 30 )) then WEIGHT = x; 
			end; 
			else do; 
				SYSTBP 	= 	110 + normal(0)*10; 
				DIASBP 	= 	SYSTBP - 20 + normal(0)*3; 
				PULSE 	= 	80 + int(normal(0)*5); 
				TEMPER 	= 	38 + normal(0)*.5; 
			end; 
		end; 
		drop x; 
		format SYSTBP DIASBP 4.; 
		TEMPER = round(TEMPER, .1); 
run; 

data vital.vital; 
	set vital; 
run; 

data v; 
	set vital; 
	VSDTC = SVSTDTC; 
	DOMAIN = "VS"; 
	format VSDTC yymmddn8.; 
	drop ENROLDT STOPDT TREATMENT SVSTDTC CENSOR TREATED; 
run; 

data vital.vs; 
	set v; 
run; 

%excel(indsn=v, name=vital); 

%look(vital.vs, out); 

%createcat(indsn=out, outdsn=output, varname=LABEL, len=40, cat=BMI score|Diastolic Blood Pressure|
Domain|Height|Pulse rate|Subject id|Systolic Blood Pressure|Temperature|Planned Study Day of Visit|
Visit Number|Date/Time of Measurements|Weight, ncat=1|1|1|1|1|1|1|1|1|1|1|1); 

%pt(output); 

%excel(indsn=output, name=Spec_vs); 


