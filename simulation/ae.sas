/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	ae 
Description:	
				To generate ae data		
      Input:	
     Output:	ae.ae
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

data safety; 
	set disp.ds; 
	if SAFETY = 1; 
run;

data saf; 
	set safety; 
	keep SUBJID USUBJID TREATMENT RFSTDTC RFENDTC CENSOR; 
run; 

data saf_a saf_p; 
	set saf; 
	if TREATMENT = 1 then output saf_a; 
	else output saf_p; 
run; 

* create different ae; 
data x; 
	set saf_a; 
%setcat(indsn=x, outdsn=x, rn=16, varname=v1, len=2, cat=1|., ncat=233|558); 
%setcat(indsn=x, outdsn=x, rn=17, varname=v2, len=2, cat=2|., ncat=207|584); 
%setcat(indsn=x, outdsn=x, rn=18, varname=v3, len=2, cat=3|., ncat=211|580); 
%setcat(indsn=x, outdsn=x, rn=19, varname=v4, len=2, cat=4|., ncat=150|641); 
%setcat(indsn=x, outdsn=x, rn=20, varname=v5, len=2, cat=5|., ncat=67|724); 
%setcat(indsn=x, outdsn=x, rn=21, varname=v6, len=2, cat=6|., ncat=139|652); 
%setcat(indsn=x, outdsn=x, rn=22, varname=v7, len=2, cat=7|., ncat=48|743); 
%setcat(indsn=x, outdsn=x, rn=23, varname=v8, len=2, cat=8|., ncat=91|700); 
%setcat(indsn=x, outdsn=x, rn=24, varname=v9, len=2, cat=9|., ncat=43|748); 
%setcat(indsn=x, outdsn=x, rn=25, varname=v10, len=2, cat=10|., ncat=83|708); 
%setcat(indsn=x, outdsn=x, rn=26, varname=v11, len=2, cat=11|., ncat=57|734); 
%setcat(indsn=x, outdsn=x, rn=27, varname=v12, len=2, cat=12|., ncat=49|742); 
%setcat(indsn=x, outdsn=x, rn=28, varname=v13, len=2, cat=13|., ncat=57|734); 
%setcat(indsn=x, outdsn=x, rn=29, varname=v14, len=2, cat=14|., ncat=30|761); 
%setcat(indsn=x, outdsn=x, rn=30, varname=v15, len=2, cat=15|., ncat=18|773); 

data saf_at; 
	set x; 
run; 

data x; 
	set saf_p; 
run; 

%setcat(indsn=x, outdsn=x, rn=1, varname=v1, len=2, cat=1|., ncat=92|302); 
%setcat(indsn=x, outdsn=x, rn=2, varname=v2, len=2, cat=2|., ncat=92|302); 
%setcat(indsn=x, outdsn=x, rn=3, varname=v3, len=2, cat=3|., ncat=72|322); 
%setcat(indsn=x, outdsn=x, rn=4, varname=v4, len=2, cat=4|., ncat=64|330); 
%setcat(indsn=x, outdsn=x, rn=5, varname=v5, len=2, cat=5|., ncat=27|367); 
%setcat(indsn=x, outdsn=x, rn=6, varname=v6, len=2, cat=6|., ncat=53|341); 
%setcat(indsn=x, outdsn=x, rn=7, varname=v7, len=2, cat=7|., ncat=13|381); 
%setcat(indsn=x, outdsn=x, rn=8, varname=v8, len=2, cat=8|., ncat=28|366); 
%setcat(indsn=x, outdsn=x, rn=9, varname=v9, len=2, cat=9|., ncat=10|384); 
%setcat(indsn=x, outdsn=x, rn=10, varname=v10, len=2, cat=10|., ncat=30|364); 
%setcat(indsn=x, outdsn=x, rn=11, varname=v11, len=2, cat=11|., ncat=20|374); 
%setcat(indsn=x, outdsn=x, rn=12, varname=v12, len=2, cat=12|., ncat=16|378); 
%setcat(indsn=x, outdsn=x, rn=13, varname=v13, len=2, cat=13|., ncat=18|376); 
%setcat(indsn=x, outdsn=x, rn=14, varname=v14, len=2, cat=14|., ncat=11|383); 
%setcat(indsn=x, outdsn=x, rn=15, varname=v15, len=2, cat=15|., ncat=4|390); 

data saf_pt; 
	set x; 
run; 

data a; 
	set saf_at saf_pt; 
run; 

data aet; 
	set a; 
	array pt(15) v1-v15; 
	do i = 1 to 15; 
		PTTERM = pt(i); 
		output; 
	end; 
	keep SUBJID USUBJID TREATMENT RFSTDTC RFENDTC CENSOR PTTERM; 
run; 

data aety; 
	set aet; 
	if PTTERM NE .; 
run; 

data aety1; 
	set aety; 
	if PTTERM in (1:2) then SOCT = 1; 
	else if PTTERM = 3 then SOCT = 2; 
	else if PTTERM in (4:5) then SOCT = 3; 
	else if PTTERM in (6:7) then SOCT = 4; 
	else if PTTERM in (8:9) then SOCT = 5; 
	else if PTTERM = 10 then SOCT = 6; 
	else if PTTERM in (11:12) then SOCT = 7; 
	else if PTTERM in (13:15) then SOCT = 8; 
run; 

data ae; 
	set aety1; 
	array SEVLIST[3] $16 _TEMPORARY_ ("MILD", "MODERATE", "SEVERE"); 
	array RELATION[3] $16 _TEMPORARY_ ("UNLIKELY", "POSSIBLE", "RELATED"); 
	array PT[15] $40 _TEMPORARY_ (	"Joint Swelling/Discomfort","Muscle Discomfort", 
									"Edema", "Hot Flush", 
									"Hypertension", "Diarrhea", 
									"Dysperpsia", "Urinary Tract Infection", 
									"Upper Respiratory Tract Infection", 
									"Cough", "Urinary Frequency", 
									"Nocturia", "Arrhythmia", 
									"Chest Pain or Chest Discomfort", "CardiacFailure"); 
	array SOC[8] $50 _TEMPORARY_ ( "Musculoskeletal and Connective Tissue Disorders", 
									 "General Disorders", 
									 "Vascular Disorders", 
									 "Gastrointestinal Disorders", 
									 "Infections and Infestations", 
									 "Respiratory, Thoracic and Mediastinal Disorders", 
									 "Renal and Urinary Disorders", 
									 "Cardiac Disorders"); 
	array OUT[4] $20 _TEMPORARY_ ("CONTINUING", "RESOLVED+HOSPITAL", "RESOLVED" ,"DEATH"); 
	array ACN[4] $20 _TEMPORARY_ ("DRUG WITHDRAWN", "DOSE NOT CHANGED", "NOT APPLICABLE", "DOSE REDUCED"); 
	array SER[2] $2 _TEMPORARY_ ("Y", "N"); 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			AETERM = PT[PTTERM]; 
			AEBODSYS = SOC[SOCT]; 
			gap = RFENDTC - RFSTDTC; 
			AESTDTC = RFSTDTC + int(ranuni(0)*(gap - 7)); 
			AEENDTC = AESTDTC + int(ranuni(0)*5); 
			AESEV = SEVLIST[ rantbl(0, .3, .2, .5) ]; 
			AEREL = RELATION[ rantbl(0, .2, .4, .4) ]; 
			AEOUT = OUT[ rantbl(0, .4, .2, .3, .1) ]; 
			AEACN = ACN[ rantbl(0, .3, .3, .3, .1) ]; 
			if CENSOR = 1 then AESER = SER[ rantbl(0, .8, .2) ]; 
			else AESER = SER[ rantbl(0, .2, .8) ]; 
			AESTDY = AESTDTC - RFSTDTC; 
			AEENDY = AEENDTC - RFSTDTC; 
			DOMAIN = "AE"; 
		end; 
		else do; 
			AETERM = PT[PTTERM]; 
			AEBODSYS = SOC[SOCT]; 
			gap = RFENDTC - RFSTDTC; 
			AESTDTC = RFSTDTC + int(ranuni(0)*(gap - 7)); 
			AEENDTC = AESTDTC + int(ranuni(0)*5); 
			AESEV = SEVLIST[ rantbl(0, .6, .2, .2) ]; 
			AEREL = RELATION[ rantbl(0, .5, .3, .2) ]; 
			AEOUT = OUT[ rantbl(0, .4, .2, .4, 0) ]; 
			AEACN = ACN[ rantbl(0, .3, .3, .3, .1) ]; 
			if CENSOR = 1 then AESER = SER[ rantbl(0, .8, .2) ]; 
			else AESER = SER[ rantbl(0, .2, .8) ]; 
			AESTDY = AESTDTC - RFSTDTC; 
			AEENDY = AEENDTC - RFSTDTC; 
			DOMAIN = "AE"; 
		end; 
	end; 
	else 
		if CENSOR = 1 then do; 
			AETERM = PT[PTTERM]; 
			AEBODSYS = SOC[SOCT]; 
			gap = RFENDTC - RFSTDTC; 
			AESTDTC = RFSTDTC + int(ranuni(0)*(gap - 7)); 
			AEENDTC = AESTDTC + int(ranuni(0)*5); 
			AESEV = SEVLIST[ rantbl(0, .2, .2, .6) ]; 
			AEREL = RELATION[ rantbl(0, .2, .4, .4) ]; 
			AEOUT = OUT[ rantbl(0, .3, .2, .3, .2) ]; 
			AEACN = ACN[ rantbl(0, .3, .3, .3, .1) ]; 
			if CENSOR = 1 then AESER = SER[ rantbl(0, .8, .2) ]; 
			else AESER = SER[ rantbl(0, .2, .8) ]; 
			AESTDY = AESTDTC - RFSTDTC; 
			AEENDY = AEENDTC - RFSTDTC; 
			DOMAIN = "AE"; 
		end; 
		else do; 
			AETERM = PT[PTTERM]; 
			AEBODSYS = SOC[SOCT]; 
			gap = RFENDTC - RFSTDTC; 
			AESTDTC = RFSTDTC + int(ranuni(0)*(gap - 7)); 
			AEENDTC = AESTDTC + int(ranuni(0)*5); 
			AESEV = SEVLIST[ rantbl(0, .3, .3, .4) ]; 
			AEREL = RELATION[ rantbl(0, .4, .3, .3) ]; 
			AEOUT = OUT[ rantbl(0, .4, .2, .4, 0) ]; 
			AEACN = ACN[ rantbl(0, .3, .3, .3, .1) ]; 
			if CENSOR = 1 then AESER = SER[ rantbl(0, .8, .2) ]; 
			else AESER = SER[ rantbl(0, .2, .8) ]; 
			AESTDY = AESTDTC - RFSTDTC; 
			AEENDY = AEENDTC - RFSTDTC; 
			DOMAIN = "AE"; 
		end; 
	; 
	format AESTDTC AEENDTC AESTDY AEENDY yymmddn8.; 
	drop gap PTTERM SOCT; 
run; 

data ae.ae; 
	set ae; 
run; 

data ae; 
	set ae.ae; 
	drop TREATMENT CENSOR; 
run; 

%toexcel(indsn=ae, name=ae, path=C:\bancova\projects\prostate\data\raw\legacy); 

%look(ae, out); 

%createcat(indsn=out, outdsn=output, varname=LABEL, len=40, cat=Action Taken with Study Treatment|
Body System or Organ Class|End Date/Time of Adverse Event|Study Day of End of Adverse Event|
Outcome of Adverse Event|Causality|Serious Event|Severity/Intensity|Start Date/Time of Adverse Event|
Study Day of Start of Adverse Event|Reported Term for the Adverse Event|Domain|Reference Subject End date|Reference Subject Start Date|
Subject id|Unique Subject id, ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

%excel(indsn=output, name=Spec_ae); 




