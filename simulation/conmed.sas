/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	conmed
Description:	
				To generate conmed data		
      Input:	
     Output:	conmed.conmed
 Programmer:	Ray (Hang Zhong)
    Created:	conmed.cm
	   QCer:	
	QC date:	
      Notes:	
********************************************************************************************************************/ 
* autocall macros; 
filename autoM "C:\bancova\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 
* set up the libname; 
%include "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\program\libname.sas"; 

data s; 
	set disp.s; 
run; 

data sb; 
	set s; 
	x = uniform(0); 
	if x < 0.01 then output; 
	drop x; 
run; 

data conmed; 
	set sb; 
	array DRUG[8] $15 _TEMPORARY_ ("AVANAFIL", "LODENAFIL", "MIRODENAFIL", "SILDENAFIL", 
									"TADALAFIL", "VARDENAFIL", "UDENAFIL", "ZAPRINAST"); 
	array FRQ[4] $5 _TEMPORARY_ ("ONCE", "BID", "Q24H", "PRN");  
	DOMAIN = "CM"; 
	gap = RFENDTC - ENROLDT; 
	format CMSTDTC CMENDTC yymmddn8.; 
	x = 2 + ranuni(0)*6; 
	do i = 1 to x; 
		CMSEQ = i; 
		CMTRT = DRUG[ 1 + ranuni(0)*7  ]; 
		CMDOSE = 100; 
		CMDOSU = "MG"; 
		CMDOSFRQ = FRQ[  1 + ranuni(0)*3  ]; 
		CMSTDTC = RFENDTC + ranuni(0)*gap - 1; 
		CMENDTC = CMSTDTC; 
		output; 
	end; 
	drop x gap i TREATMENT ENROLDT RFSTDTC RFENDTC DMDTC SITEID SEX INVNAM COUNTRY AGEU AGE ETHNICITY RACE
	BIRTHDTC cutdate TREATED CENSOR DISC;
run; 

proc sort data = conmed; 
	by SUBJID CMSEQ; 
run; 

proc freq data = conmed; 
	tables SUBJID*CMTRT; 
run; 

data conmed.cm; 
	set conmed; 
run; 

%excel(indsn=conmed, name=conmed); 

%look(conmed.cm, cm); 

%createcat(indsn=cm, outdsn=out, varname=LABEL, len=40, cat=Dose Per Administration|
Dose Frequency Per Interval|Dose Units|End Date/Time of Medication|Sequence Number|
Start Date/Time of Medication|Reported Name of Drug Med or Therapy|Domain|Study id|
Subject id|Unique Subject id, ncat=1|1|1|1|1|1|1|1|1|1|1); 

%excel(indsn=out, name=Spec_cm); 


