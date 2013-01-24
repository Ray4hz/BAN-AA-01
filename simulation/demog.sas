/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	demog
Description:	
				To generate demog data		
      Input:	
     Output:	demog.dm
 Programmer:	Ray (Hang Zhong)
    Created:	
	   QCer:	
	QC date:	
      LABELs:	
********************************************************************************************************************/ 
* autocall macros; 
filename autoM "C:\bancova\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 
* set up the libname; 
%include "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\program\libname.sas"; 

%let path = G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\sasdata; 

* check the output; 
data dm; 
	set demog.dm; 
run; 

%look(dm); 

data rand; 
	set demog.randomized; 
	keep SITE REG SUBJID TREATMENT; 
run; 

data sv; 
	set visit.visit; 
	keep SUBJID ENROLDT STOPDT v2; 
run; 

proc sql; 
	create table d as
	select * 
	from rand as a, sv as b
	where a.SUBJID = b.SUBJID; 
quit; 

data d1; 
	set d; 
	keep SUBJID SITE REG TREATMENT ENROLDT STOPDT v2; 
run; 

*******************************************************************************************************; 
* generate other demog characteristics
* SDTM: 
STUDYID
DOMAIN		DM
USUBJID		STUDYID-SITEID-SUBJID
SBUJID		unique within the study
RFSTDTC		subject reference start/date
RFENDTC		subject reference end/date
SITED		study site identifier
INVID		investigator identifier
INVNAM		investigator name
BRTHDTC		Date/time of birth
AGE			
AGEU		age units
SEX			
RACE
ETHNIC		
ARMCD		planned arm code, 20 characters, if screen fail, ARMCD = "SCRNFAIL"
ARM			description of planned arm, if screen fail, ARM = "Screen Failure"
COUNTRY		site 
DMDTC		data/time of collection
DMDY		study day of collection 
*******************************************************************************************************;

data d2; 
	set d1; 
	STUDYID	=	"BAN-AA-01"; 
	DOMAIN 	=	"DM"; 
	USUBJID = 	cats("BAN-AA-01", put(input(SITE,3.),z3.), SUBJID); 
	RFSTDTC = 	v2; 
	RFENDTC = 	STOPDT;
	DMDTC = v2;  
	SITEID 	= 	SITE; 
	SEX = "M"; 
	format INVNAM $7.; 
	format COUNTRY $10.; 
	if REG = 1 then INVNAM = "RAY,Z"; 
	else if REG = 2 then INVNAM = "JOHN,Z"; 
	else if REG = 3 then INVNAM = "PETER,L"; 
	else if REG = 4 then INVNAM = "CLEO,L"; 
	if REG = 1 then COUNTRY = "USA";  
	else if REG = 2 then COUNTRY = "Europe"; 
	else if REG = 3 then COUNTRY = "Australia"; 
	else if REG = 4 then COUNTRY = "Canada"; 
	AGEU = "YEARS"; 
	format RFSTDTC RFENDTC DMDTC yymmddn8.; 
	drop v2 SVSTDTC SITE STOPDT REG; 
run; 

data trt pla; 
	set d2; 
	if TREATMENT = 1 then output trt; 
	else output pla;
run; 

%setcon(indsn=trt, outdsn=trt1, varname=AGE, mean=69.1, sd=8.4, format=round, digit=.1, LABEL=Age); 

%setcat(indsn=trt1, outdsn=trt2, rn=1, varname=ETHNICITY, len=25, cat=Hispanic or Latino|Not Hispanic or Latino|Other, 
		ncat=39|757|1); 

%setcat(indsn=trt2, outdsn=trt3, rn=3, varname=RACE, len=40, cat=White|Black|Asian|American Indian or Alaska Native|
		Native Hawaiian or other Pacific Islander|Other, ncat=743|28|11|3|1|11); 


%setcon(indsn=pla, outdsn=pla1, varname=AGE, mean=68.9, sd=8.61, format=round, digit=.1, LABEL=Age); 

%setcat(indsn=pla1, outdsn=pla2, rn=2, varname=ETHNICITY, len=25, cat=Hispanic or Latino|Not Hispanic or Latino|Other, 
		ncat=7|390|1); 
%setcat(indsn=pla2, outdsn=pla3, rn=3, varname=RACE, len=40, cat=White|Black|Asian|American Indian or Alaska Native|
		Other, ncat=368|15|9|1|5); 

* create the birthday for each patient; 
data d3; 
	set trt3 pla3; 
	BIRTHYEAR = 2008 - AGE; 
	day = 1 + int(ranuni(888)*29); 
	month = 1 + int(ranuni(999)*11); 
	BIRTHDTC = mdy(month, day, BIRTHYEAR); 
	format birth yymmddn8.; 
	drop BIRTHYEAR day month; 
run; 

data demog.dm; 
	set d3; 
run; 

%pt(demog.dm); 

%toexcel(indsn=demog.dm, name=demog, path=&path.); 

* label; 
data out; 
	set dm; 
	format LABEL CODE $40.; 
	CODE = " "; 
	if _n_ = 1 then LABEL = "Age"; 
	if _n_ = 2 then LABEL = "Age unit"; 
	if _n_ = 3 then LABEL = "Birthday"; 
	if _n_ = 4 then LABEL = "Country"; 
	if _n_ = 5 then LABEL = "Date/Time of Collection"; 
	if _n_ = 6 then LABEL = "Domain"; 
	if _n_ = 7 then LABEL = "Enrollment date"; 
	if _n_ = 8 then LABEL = "Ethnicity"; 
	if _n_ = 9 then LABEL = "Investigator name"; 
	if _n_ = 10 then LABEL = "Race"; 
	if _n_ = 11 then LABEL = "Subject reference start date/time"; 
	if _n_ = 12 then LABEL = "Subject reference end data/time"; 
	if _n_ = 13 then LABEL = "Sex"; 
	if _n_ = 14 then LABEL = "Site id"; 
	if _n_ = 15 then LABEL = "Study identifier"; 
	if _n_ = 16 then LABEL = "Subject idenfitifier for the study"; 
	if _n_ = 17 then LABEL = "Treatment"; 
	if _n_ = 17 then CODE = "1:treatment, 2:placebo"; 
	if _n_ = 18 then LABEL = "Unique subject identifier"; 
run; 

data dm; 
	set demog.dm; 
run; 

%ppt(dm); 

%look(dm, dm2); 

* rename the dm in order to make it a little bit more difficult for SDTM; 
data dm_c ; 
	set demog.dm; 
	rename 	BIRTHDTC = birth
			AGE = age_year
			COUNTRY = location
			ENROLDT = enrollment
			ETHNICITY = ethnic
			INVNAM = investigator
			RACE = race_group
			RFENDTC = end_date
			RFSTDTC = start_date
			SEX = gender
			SITEID = site
			STUDYID = study
			SUBJID = subject
			USUBJID =u_subject;
	drop AGEU DMDTC DOMAIN TREATMENT; 
run; 

%ppt(dm_c); 

%toexcel(indsn=dm_c, name=dm_c, path=&path.); 

%look(dm_c, dm_c1); 

data out; 
	set dm_c1; 
	format LABEL CODE $40.; 
	CODE = " "; 
	if _n_ = 1 then LABEL = "Age"; 
	if _n_ = 2 then LABEL = "Birthday"; 
	if _n_ = 8 then LABEL = "Country"; 
	if _n_ = 4 then LABEL = "Enrollment date"; 
	if _n_ = 5 then LABEL = "Ethnicity"; 
	if _n_ = 7 then LABEL = "Investigator name"; 
	if _n_ = 9 then LABEL = "Race"; 
	if _n_ = 11 then LABEL = "Subject reference start date/time"; 
	if _n_ = 3 then LABEL = "Subject reference end data/time"; 
	if _n_ = 6 then LABEL = "Sex"; 
	if _n_ = 10 then LABEL = "Site id"; 
	if _n_ = 12 then LABEL = "Study identifier"; 
	if _n_ = 13 then LABEL = "Subject idenfitifier for the study"; 
	if _n_ = 14 then LABEL = "Unique subject identifier"; 
run; 

%ppt(out); 

data demog.dm_c; 
	set dm_c; 
run; 

%excel(indsn=dm_c, name=dm_c); 

data demog.dm_c_out; 
	set out; 
run; 

%excel(indsn=out, name=Spec_dm_c); 

* make a xpt file; 
data out.dm; 
	set out; 
run; 
 
libname out "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\demog\out";
libname tranfile xport "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\demog\dm.xpt";
proc copy in=out out=tranfile; 
run; 

* convert xpt to sasdataset; 
libname back "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\demog\back";
libname tranfile xport "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\demog\dm.xpt";

proc copy in = tranfile out = back; 
run; 

%ppt(back.dm); 
