/*******************************************************************************************************************
Project:	BAN-AA-01
Program:	s_dm
Des:		To generate SDTM DM; 		
Input:		
Output:		s_prog.dm.sas, s_prog.dm_spec.sas, s_prog.dm.xls, s_prog.dm_spec.xls
Programmer:	Ray (Hang Zhong)
Created:	
QCer:	
QC date:	11/16/2012
LABELs:		
********************************************************************************************************************/ 

* autocall macros; 
filename autoM "C:\bancova\projects\prostate\programs\macros\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 

* libname; 
%include "C:\bancova\projects\prostate\data\sdtm\prog\libname.sas"; 

* import demog raw and spec, and sdtm spec; 
%let r_dm 	= C:\bancova\projects\prostate\data\sdtm\data\dm_c_1.xls; 
%let r_dm_spec 	= C:\bancova\projects\prostate\data\sdtm\data\dm_c_spec_1.xls;
%let s_dm_spec 	= C:\bancova\projects\prostate\data\sdtm\specs\DM-Spec_1.xls;
%let ct 	= C:\bancova\projects\prostate\data\sdtm\specs\CT.xls;

/*******************************************************************************************************************
*
* 1. import raw dataset, raw dataset specification, SDTM DM specification, and Controlled Terminology
*
********************************************************************************************************************/ 

proc import datafile= "&r_dm."
	out 	= r_dm
	dbms 	= xls replace; 
	mixed 	= yes; 
run; 

proc import datafile= "&r_dm_spec."
	out 	= r_dm_spec
	dbms 	= xls replace; 
	mixed 	= yes; 
run; 

proc import datafile= "&s_dm_spec."
	out 	= s_dm_spec
	dbms 	= xls replace; 
	mixed 	= yes; 
	sheet 	= "DM-Spec"; 
run; 

proc import datafile= "&ct."
	out 	= ct
	dbms 	= xls replace; 
	mixed 	= yes; 
	sheet 	= "SDTM Terminology 2011-07-22"; 
run; 

data raw; 
	set r_dm; 
	drop Obs enrollment investigator birth; 
run; 

%pt(raw); 

data rds; 
	set r_dm_spec; 
	drop Obs LENGTH VARNUM FORMAT CODE NOBS NOTE; 
run; 

%ppt(rds); 

/**************************************************************
Mapping: 
STUDYID = study			
DOMAIN 	= DM     * 
USUBJID = u_subject
SUBJID 	= subject
RFSTDTC = start_date
RFENDTC = end_date
SITEID 	= site
AGE 	= age_year
AGEU	= YEARS   * 
SEX 	= gender
RACE	= race
ETHNIC	= ethnic
ARMCD 	= A (treatment = 1) or P (treatment = 2)
ARM 	= Drug A (treatment = 1) or Placebo (treatment = 2)
COUNTRY = location
***************************************************************/ 

data sds; 
	set s_dm_spec; 
	drop Obs CDISC_Notes Code; 
run; 

%pt(sds); 

/*******************************************************************************************************************
*
* 2. check the value in the CT
*
********************************************************************************************************************/ 

proc sql; 
	create table getct as 
	select Codelist_Name as co, CDISC_Submission_Value as va
	from ct
	where   ct.CDISC_Submission_Value = "AGEU"
	or 		ct.CDISC_Submission_Value = "SEX"
	or 		ct.CDISC_Submission_Value = "RACE"
	or 		ct.CDISC_Submission_Value = "ETHNIC"
	or 		ct.CDISC_Submission_Value = "COUNTRY"; 
quit; 

%pt(getct); 

proc sql; 
	create table getvalue as
	select * 
	from ct as a, getct as b
	where a.Codelist_Name = b.co; 
quit; 

data getvalue; 
	set getvalue;
	drop Code Codelist Codelist_Code VAR3;  
run; 

%ppt(getvalue); 

data ageu; 
	set getvalue; 
	if va = "AGEU" and co = "Age Unit"; 
run; 

%pt(ageu); 

data sex; 
	set getvalue; 
	if va = "SEX" and co = "Sex"; 
run; 

%pt(sex); 

data race; 
	set getvalue; 
	if va = "RACE" and co = "Race"; 
run; 

%pt(race); 

data ethnic; 
	set getvalue; 
	if va = "ETHNIC" and co = "Ethnic Group"; 
run; 

%pt(ethnic); 

data country; 
	set getvalue; 
	if va = "COUNTRY" and co = "Country"; 
run; 

%pt(country); 

/*******************************************************************************************************************
*
* 3. convert the raw to SDTM DM
*
********************************************************************************************************************/  

data s_prog.dm; 
	set raw (rename=(ethnic=_ethnic)); 
	keep 	STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC 
			SITEID AGE SEX RACE ETHNIC ARMCD ARM COUNTRY; 
	attrib STUDYID 	length = $40 	label = "Study Identifier"; 
	attrib DOMAIN 	length = $8 	label = "Domain Abbreviation"; 
	attrib USUBJID 	length = $40 	label = "Unique Identifier for the Study"; 
	attrib SUBJID 	length = $40 	label = "Subject Identifier for the Study"; 
	attrib RFSTDTC 	length = $64 	label = "Subject Reference Start Date"; 
	attrib RFENDTC 	length = $64 	label = "Subject Rference End Date"; 
	attrib SITEID 	length = $40 	label = "Study Site Identifier"; 
	attrib AGE 	length = 8	label = "Age";  
	attrib AGEU 	length = $10 	label = "Age Units"; 
	attrib SEX 	length = $2 	label = "Sex"; 
	attrib RACE 	length = $40	label = "Race"; 
	attrib ETHNIC 	length = $40	label = "Ethnicity";
	attrib ARMCD 	length = $20	label = "Planned Arm Code"; 
	attrib ARM 	length = $40 	label = "Description of Planned Arm"; 
	attrib COUNTRY 	length = $3	label = "Country"; 

* derive SDTM DM variables; 
	STUDYID = study; 
	DOMAIN 	= "DM"; 
	USUBJID = u_subject; 
	SUBJID 	= subject; 
	RFSTDTC = put( input( put(start_date, z8.), yymmdd8.), is8601da.); 
	RFENDTC = put( input( put(end_date, z8.), yymmdd8.), is8601da.); 
	SITEID 	= site; 
	AGE 	= age_year; 
	AGEU	= "YEARS"; 
	SEX 	= "M"; 
	RACE	= upcase(race_group); 
	if _ethnic = "Other" then ETHNIC = "UNKNOWN"; 
	else ETHNIC = upcase(_ethnic); 
	if TREATMENT = 1 then ARMCD = "A"; 
	else ARMCD = "P"; 
	if TREATMENT = 1 then ARM = "Drug A"; 
	else ARM = "Placebo"; 
	if location = "Europe" then COUNTRY = "FRA"; 
	else if location = "USA" then COUNTRY = "USA"; 
	else if location = "Canada" then COUNTRY = "CAN"; 
	else COUNTRY = "AUS"; 
run; 

/*******************************************************************************************************************
*
* 4. print out and export to excel
*
********************************************************************************************************************/

%pt(s_prog.dm); 

* output the dm spec; 
%look(s_prog.dm, dm_spec); 

%pt(dm_spec); 

data s_prog.dm_spec; 
	set dm_spec; 
run; 

proc contents data = s_prog._all_ nods; 
run; 

data out; 
	set s_prog.dm; 
run; 

%ppt(out); 

* sort by USUBJID and then export to export; 
proc sort data = out; 
	by USUBJID; 
run; 

%ppt(out); 

data s_prog.dm; 
	set out; 
run; 

%look(out); 

%excel(indsn=out, name=dm, path=C:\bancova\projects\prostate\data\sdtm\prog); 

%excel(indsn=s_prog.dm_spec, name=dm_spec, path=C:\bancova\projects\prostate\data\sdtm\prog); 
