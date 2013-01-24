/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	medhis
Description:	
				To generate medical history data		
      Input:	
     Output:	medical.mh
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

data cm; 
	set conmed.cm; 
	by SUBJID; 
	retain SUBJID; 
	if last.SUBJID then output; 
	keep SUBJID; 
run; 

proc sql; 
	create table sp as
	select * 
	from s as a, cm as b
	where a.SUBJID = b.SUBJID; 
quit; 

data sb; 
	set s; 
	x = uniform(0); 
	if x < 0.05 then output; 
	drop x; 
run; 

data tem; 
	set sp sb; 
	if SUBJID = 1210009 then delete; 
run; 

data mh; 
	set tem; 
	array term[8] 	$40 _TEMPORARY_ ("ASTHMA", "FREQUENT HEADACHES", "BROKEN LEG", "ISCHEMIC STROKE", 
										"DIABETES", "HYPERCHOLESTEROLEMIA", "TIA", "MATERNAL FAMILY HX OF STROKE" ); 
	array code[8] 	$15 _TEMPORARY_ ("Asthma", "Headache", "Bone fracture", " ", " ", " ", " ", " " );  
	array cat[8] 	$40 _TEMPORARY_ ("GENERAL MEDICAL HISTORY", "GENERAL MEDICAL HISTORY", "GENERAL MEDICAL HISTORY", 
										"STROKE HISTORY", "RISK FACTORS", "RISK FACTORS", "RISK FACTORS", "RISK FACTORS" ); 
	array resp[2] 	$2 	_TEMPORARY_ ("Y", "N" ); 
	array cur[3]	$2 	_TEMPORARY_ ("Y", "N", " "); 
	DOMAIN = "MH"; 
	VISIT = "SCREEN"; 
	VISITNUM = "1"; 
	format MHDTC yymmddn8.; 
	x = 1 + ranuni(0)*5; 
	do i = 1 to x; 
		MHSEQ = i; 
		y = int(1 + ranuni(0)*7); 
		MHTERM = term[ y ]; 
		MHDECOD = code[ y ]; 
		MHSCAT = cat [ y ]; 
		MHPRESP = resp[  rantbl(0, 0.8, 0.2)  ]; 
		MHOCCUR = cur[ rantbl(0, 0.4, 0.5, 0.1) ]; 
		VISITNUM = STRIP(put(i, best32.)); 
		MHDTC = RFSTDTC - ranuni(0)*8; 
		output; 
	end; 
	drop x y i TREATMENT ENROLDT RFENDTC DMDTC SITEID SEX INVNAM COUNTRY AGEU AGE ETHNICITY RACE
	BIRTHDTC cutdate TREATED CENSOR DISC;
run; 

data medical.mh; 
	set mh; 
run; 

%excel(indsn=mh, name=mh); 

%look(mh, out); 

%createcat(indsn=out, outdsn=output, varname=LABEL, len=40, cat=Domain|
Dictionary-Derived Term|Date/Time of History Collection|Medical History Occurence|
Medical History Event Pre-specified|Subcategory for Medical History|Sequence Number|
Reported Term for the Medical History|Reference Subject Start Date|
Study id|Subject id|Unique Suject id|Visit Name|Visit Number, 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

%pt(output); 

%excel(indsn=output, name=Spec_mh); 




































