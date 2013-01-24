/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	born
Description:	
				To generate basic info for patients
				Steps: 
					1. create 5 random number; 
					2. generate subjid, started date, center, 
						stratification factors; 
      Input:	
     Output:	demog.born
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

* create a sequence of random numer, ranged from 1 to 1195;
data seq;
	do i = 1 to 1195; 
		num = put(i, 4.); 
		output;
	end; 
	drop i; 
run; 

%setr(indsn=seq, outdsn=seqvar, rn=5); 
%setr(indsn=seqvar, outdsn=seqvar, rn=54); 
%setr(indsn=seqvar, outdsn=seqvar, rn=543); 
%setr(indsn=seqvar, outdsn=seqvar, rn=5432); 
%setr(indsn=seqvar, outdsn=seqvar, rn=54321); 

data demog.seqvar; 
	set seqvar; 
run; 

** create basic information with subjid, started date, center, stratification factors; 
* Stratification factors: ; 
* 	ECOG(ECOG status):  							1 = "0 or 1", 	2 = "2";     
* 	PAIN:  											1 = "Present", 	2 = "Absent"; 
* 	CHEMO(Number of prior cytotoxic chemotherapy): 	1 = "1", 		2 = "2"; 
* 	DPSA(Evidence of disease progression): 			1 = "PSA only", 2 = "Radiographic progression with or without PSA progression"; 

data born;
	set seqvar;
* create a started date from enrollement period; 
	mindate = "08may2008"d; 
	maxdate = "28jul2009"d; 
	enrange = maxdate - mindate + 1; 
	format mindate maxdate STRTDT yymmddn8.; 
	STRTDT = mindate + int(ranuni(888)*enrange); 
* study center; 
* 	US = U 498; 
* 	Canada = C 154; 
* 	Europe = E 439; 
* 	Australia = A 104; 
* 	site = 147;
	x = 1 + int(ranuni(888)*146); 
	SITE = put(x, 3.); 
	x = rnum5;
	if x in (1:498) then REG = 1;
		else if x in (499:652) then REG = 2;
			else if x in (653:1091) then REG = 3;
				else if x in (1092:1195) then REG = 4;
					else REG = 5; 
* create patient id;
	SUBJID = 12*100000 + REG*10000 + num;
* create stratification factors; 
* DPSA; 
	x = rnum54;
	if x in (1:363) then DPSA = 1; 
		else DPSA = 2; 
* ECOG;
	x = rnum543;
	if x in (1:1068) then ECOG = 1;
		else ECOG = 2; 
* PAIN;
	x = rnum5432; 
	if x in (1:536) then PAIN =1;
		else PAIN = 2;
* CHEMO;
	x = rnum54321;
	if x in (1:833) then CHEMO = 1;
		else CHEMO = 2;
	drop mindate maxdate enrange x num rnum5 rnum54 rnum543 rnum5432 rnum54321; 
	output; 
	label 	STRTDT 	= "STARTED DATE"
			SITE	= "INVESTIGATIONAL SITE"
			REG		= "REGION"
			SUBJID	= "SUBJECT ID"
			DPSA	= "DPSA(EVIDENCE OF DISEASE PROGRESSION)"
			ECOG	= "ECOG(ECOG STATUS)"
			PAIN	= "PAIN"
			CHEMO	= "CHEMO(NUMBER OF PRIOR CYTOTOXIC CHEMOTHERAPY)"
			; 
run;

* classify the stratum; 
data demog.born; 
	set born; 
* STRATUM; 
	if DPSA = 1 and ECOG = 1 and PAIN = 1 and CHEMO = 1 then STRATUM = 1111; 
	else if DPSA = 1 and ECOG = 1 and PAIN = 1 and CHEMO = 2 then STRATUM = 1112;
	else if DPSA = 1 and ECOG = 1 and PAIN = 2 and CHEMO = 1 then STRATUM = 1121;
	else if DPSA = 1 and ECOG = 2 and PAIN = 1 and CHEMO = 1 then STRATUM = 1211;
	else if DPSA = 2 and ECOG = 1 and PAIN = 1 and CHEMO = 1 then STRATUM = 2111;
	else if DPSA = 1 and ECOG = 1 and PAIN = 2 and CHEMO = 2 then STRATUM = 1122;
	else if DPSA = 2 and ECOG = 2 and PAIN = 1 and CHEMO = 1 then STRATUM = 2211;
	else if DPSA = 1 and ECOG = 2 and PAIN = 1 and CHEMO = 2 then STRATUM = 1212;
	else if DPSA = 2 and ECOG = 1 and PAIN = 1 and CHEMO = 2 then STRATUM = 2112;
	else if DPSA = 2 and ECOG = 1 and PAIN = 2 and CHEMO = 1 then STRATUM = 2121;
	else if DPSA = 1 and ECOG = 2 and PAIN = 2 and CHEMO = 1 then STRATUM = 1221;
	else if DPSA = 1 and ECOG = 2 and PAIN = 2 and CHEMO = 2 then STRATUM = 1222;
	else if DPSA = 2 and ECOG = 1 and PAIN = 2 and CHEMO = 2 then STRATUM = 2122;
	else if DPSA = 2 and ECOG = 2 and PAIN = 1 and CHEMO = 2 then STRATUM = 2212;
	else if DPSA = 2 and ECOG = 2 and PAIN = 2 and CHEMO = 1 then STRATUM = 2221;
	else if DPSA = 2 and ECOG = 2 and PAIN = 2 and CHEMO = 2 then STRATUM = 2222;
run; 

proc freq data = demog.born; 
	tables STRATUM; 
run; 


