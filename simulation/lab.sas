/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	lab
Description:	
				To generate lab data		
      Input:	
     Output:	lab.lab
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

data s; 
	set visit.svisit; 
run; 

data death; 
	set survival.death; 
	keep SUBJID CENSOR USUBJID; 
run; 

proc sql; 
	create table sv1 as
	select *
	from s as a, death as b
	where a.SUBJID = b.SUBJID; 
quit; 

data trt; 
	set demog.dm; 
	keep SUBJID TREATMENT; 
run; 

proc sql; 
	create table svisit as
	select * 
	from sv1 as a, trt as b
	where a.SUBJID = b.SUBJID; 
run; 

proc sort data = svisit; 
	by SUBJID VISITDT; 
run; 

* 1. Urinalysis, only on visit 1, creening; 
data vs1; 
	set svisit; 
	if VISITNUM = 1;  
run; 

data l1; 
	set vs1; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST 		= "Protein"; 
	LBTESTCD 	= "PROT"; 
	LBCAT 		= "URINALYSIS";
	LBORRESU 	= " "; 
	LBSTRESU 	= "mg/dL"; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 50 mg/24h"; 
	LBORNRHI	= "> 80 mg/24h"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			PROTEIN 	= 45 + ranuni(0)*45; 
		end; 
		else do; 
			PROTEIN 	= 48 + ranuni(0)*32;
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			PROTEIN 	= 45 + ranuni(0)*50; 
		end; 
		else do; 
			PROTEIN 	= 48 + ranuni(0)*35;
		end; 
	end; 
	PROTEIN = round(PROTEIN, .1); 
	if PROTEIN >= 50 and PROTEIN <= 80 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

data l2; 
	set vs1; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST 		= "Glucose"; 
	LBTESTCD 	= "GLUCOSE"; 
	LBCAT 		= "URINALYSIS";
	LBORRESU 	= "mg/dL"; 
	LBSTRESU 	= "mmol/L"; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= " "; 
	LBORNRHI	= "> 500mg/24h"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			GLUCOSE 	= 1 + ranuni(0)*600; 
		end; 
		else do; 
			GLUCOSE 	= 1 + ranuni(0)*500;
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			GLUCOSE 	= 1 + ranuni(0)*700; 
		end; 
		else do; 
			GLUCOSE 	= 1 + ranuni(0)*510;
		end; 
	end; 
	GLUCOSE = round(GLUCOSE, .1); 
	if GLUCOSE > 500 then LBORRES = "HIGH"; 
	else LBORRES = "MODERATE"; 
run; 

* 2. PSA, only on v1, v2, v4, v6, v8, v9 and last visit; 
data vs2; 
	set svisit; 
	if VISITNUM in (1, 2, 4, 6, 8, 9) or (SVSTDTC = STOPDT);  
run; 

data l3; 
	set vs2; 
	by SUBJID; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $30.; 
	retain PSA; 
	if first.SUBJID then do; 
		PSA = 0 + ranuni(0)*60; 
		LBTEST 		= "PROSTATE SPECIFIC ANTIGEN"; 
		LBTESTCD 	= "PSA"; 
		LBCAT 		= "HEMATOLOGY";
		LBORRESU 	= "ng/mL"; 
		LBSTRESU 	= " "; 
		LBDTC 		= SVSTDTC; 
		LBENDTC 	= SVSTDTC; 
		LBORNRLO 	= " "; 
		LBORNRHI	= "> 40 ng/mL"; 
	end; 
	else do; 
		LBTEST 		= "PROSTATE SPECIFIC ANTIGEN"; 
		LBTESTCD 	= "PSA"; 
		LBCAT 		= "HEMATOLOGY";
		LBORRESU 	= "ng/mL"; 
		LBSTRESU 	= " "; 
		LBDTC 		= SVSTDTC; 
		LBENDTC 	= SVSTDTC; 
		LBORNRLO 	= " "; 
		LBORNRHI	= "> 40 ng/mL"; 
		if TREATMENT = 1 then do; 
			if CENSOR = 1 then do;  
				x = PSA - ranuni(0)*2; 
				if PSA*0.7 > x then PSA = PSA + ranuni(0)*1; 
				else PSA = x; 
			end; 
			else do; 
				x = PSA - ranuni(0)*3; 
				if PSA*0.6 > x then PSA = PSA + ranuni(0)*1; 
				else PSA = x; 
			end; 
		end; 
		else do; 
			if CENSOR = 1 then do; 
				x = PSA + normal(0)*2; 
				if PSA*0.9 > x then PSA = PSA +ranuni(0)*3; 
				else PSA = x; 
			end; 
			else do; 
				x = PSA + normal(0)*1; 
				if PSA*0.9 > x then PSA = PSA +ranuni(0)*2; 
				else PSA = x;  
			end; 
		end; 
	end; 
	if PSA < 0 then PSA = 0; 
	PSA = round(PSA, .1); 
	if PSA > 40 then LBORRES = "HIGH"; 
	else LBORRES = "MODERATE"; 
	drop x; 
run; 

* 3. CBC, not on v3, v5, v7; 
data vs3; 
	set svisit; 
	if VISITNUM in (3, 3.1, 5, 5.1, 7, 7.1) then delete;  
run; 

data l4; 
	set vs3; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "Hemoglobin"; 
	LBTESTCD 	= "HEMOGLOBIN"; 
	LBCAT 		= "HEMATOLOGY";
	LBORRESU 	= "g/dL"; 
	LBSTRESU 	= "mmol/L"; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 14.0 g/dL "; 
	LBORNRHI	= "> 18.0 g/dL"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			HEMOGLOBIN = 13.8 + ranuni(0)*4.5; 
		end; 
		else do; 
			HEMOGLOBIN = 14.0 + ranuni(0)*4; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			HEMOGLOBIN = 13.5 + ranuni(0)*5; 
		end; 
		else do; 
			HEMOGLOBIN = 14.0 + ranuni(0)*4; 
		end; 
	end; 
	HEMOGLOBIN = round(HEMOGLOBIN, .1); 
	if (HEMOGLOBIN < 14 or HEMOGLOBIN > 18) then LBORRES = "ABNORMAL"; 
	else LBORRES = "MODERATE"; 
run; 

data l5; 
	set vs3; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "Hematocrit"; 
	LBTESTCD 	= "HEMATOCRIT"; 
	LBCAT 		= "HCT";
	LBORRESU 	= "%"; 
	LBSTRESU 	= " "; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 42%"; 
	LBORNRHI	= "> 52%"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			HCT = 40 + ranuni(0)*14; 
		end; 
		else do; 
			HCT = 41 + ranuni(0)*12; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			HCT = 37 + ranuni(0)*17; 
		end; 
		else do; 
			HCT = 40 + ranuni(0)*13; 
		end; 
	end; 
	HCT = round(HCT, .1); 
	if HCT >= 42 and HCT <= 52 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

data l6; 
	set vs3; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "Leukocytes"; 
	LBTESTCD 	= "WBC"; 
	LBCAT 		= "HEMATOLOGY";
	LBORRESU 	= "10^3/mcL"; 
	LBSTRESU 	= "10^12/L "; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 4.8 10^3/mcL"; 
	LBORNRHI	= "> 10.8 10^3/mcL"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			WBC = 4.3 + ranuni(0)*7; 
		end; 
		else do; 
			WBC = 4.6 + ranuni(0)*6.5; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			WBC = 4 + ranuni(0)*7.5; 
		end; 
		else do; 
			WBC = 4.5 + ranuni(0)*6.6; 
		end; 
	end; 
	WBC = round(WBC, .1); 
	if WBC >= 4.8 and WBC <= 10.8 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

* 4. Chemistry, all; 
data vs4; 
	set svisit; 
run; 

data l7; 
	set vs4; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "Alanine aminotranserase"; 
	LBTESTCD 	= "ALT"; 
	LBCAT 		= "CHEMISTRY";
	LBORRESU 	= "U/L(37C)"; 
	LBSTRESU 	= "mckat/L(37C)"; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 13 U/L(37C)"; 
	LBORNRHI	= "> 40 U/L(37C)"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			ALT = 12 + ranuni(0)*40; 
		end; 
		else do; 
			ALT = 11 + ranuni(0)*32; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			ALT = 8 + ranuni(0)*45; 
		end; 
		else do; 
			ALT = 10 + ranuni(0)*35; 
		end; 
	end; 
	ALT = round(ALT,.1); 
	if ALT >= 13 and ALT <= 40 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

data l8; 
	set vs4; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "Aspartate aminotranserase"; 
	LBTESTCD 	= "AST"; 
	LBCAT 		= "CHEMISTRY";
	LBORRESU 	= "U/L(37C)"; 
	LBSTRESU 	= "kat/L(37C)"; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 10 U/L(37C)"; 
	LBORNRHI	= "> 59 U/L(37C)"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			AST = 6 + ranuni(0)*60; 
		end; 
		else do; 
			AST = 8 + ranuni(0)*55; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			AST = 5 + ranuni(0)*65; 
		end; 
		else do; 
			AST = 7 + ranuni(0)*58; 
		end; 
	end; 
	AST = round(AST,.1); 
	if AST >= 10 and AST <= 59 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

data l9; 
	set vs4; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "High-density lipoprotein"; 
	LBTESTCD 	= "HDL"; 
	LBCAT 		= "CHEMISTRY";
	LBORRESU 	= "mg/dL"; 
	LBSTRESU 	= " "; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= "< 32"; 
	LBORNRHI	= " "; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			HDL = 50 + normal(0)*13; 
		end; 
		else do; 
			HDL = 50 + normal(0)*8; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			HDL = 50 + normal(0)*17; 
		end; 
		else do; 
			HDL = 50 + normal(0)*12; 
		end; 
	end; 
	HDL = round(HDL, .1); 
	if HDL > 32 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

data l10; 
	set vs4; 
	format LBDTC LBENDTC yymmddn8.; 
	format LBTEST LBTESTCD LBCAT LBORRESU LBSTRESU LBORNRLO LBORNRHI LBORRES $20.; 
	LBTEST		= "Low-density lipoprotein"; 
	LBTESTCD 	= "LDL"; 
	LBCAT 		= "CHEMISTRY";
	LBORRESU 	= "mg/dL"; 
	LBSTRESU 	= "mmol/L"; 
	LBDTC 		= SVSTDTC; 
	LBENDTC 	= SVSTDTC; 
	LBORNRLO 	= " "; 
	LBORNRHI	= "> 192 mg/dL"; 
	if TREATMENT = 1 then do; 
		if CENSOR = 1 then do; 
			LDL = 130 + normal(0)*30; 
		end; 
		else do; 
			LDL = 130 + normal(0)*10; 
		end; 
	end; 
	else do; 
		if CENSOR = 1 then do; 
			LDL = 130 + normal(0)*40; 
		end; 
		else do; 
			LDL = 130 + normal(0)*10; 
		end; 
	end; 
	LDL = round(LDL, .1); 
	if LDL <= 192 then LBORRES = "MODERATE"; 
	else LBORRES = "ABNORMAL"; 
run; 

%excel(indsn=l3, name=lab_l3); 

%macro storelab; 
%do i = 1 %to 10; 
	data lab.l&i.; 
		set l&i.; 
		drop ENROLDT STOPDT TREATED SVSTDTC CENSOR TREATMENT; 
	run; 
	ods tagsets.excelxp
	file  = "G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\sasdata\lab_l&i..xls"
	style = minimal
	options (Orientation = "landscape"
	FitToPage = "yes"
	Pages_FitWidth = "1"
	Pages_FitHeight = "100"); 
	%pt(lab.l&i.); 
	ods tagsets.excelxp close; 
%end; 
%mend; 
%storelab; 

%macro writespec; 
%do q = 1 %to 10; 
	%look(lab.l&q., t&q.); 
	proc sort data = t&q.; 
		by VARNUM; 
	run; 
	%createcat(indsn=t&q., outdsn=out&q., varname=LABEL, len=40, cat=Subject id|Visit Number|
	Planned Study Day of Visit|Date/Time of Specimen Collection|End Date/Time of Specimen collection|
	Lab Test of Examination Name|Lab Test or Examination Short Name|Category for Lab Test|Original Units|
	Standard Units|Reference Range Lower Limit-Std Units|Reference Range Upper Limits-Std Units|
	Result or Finding in Original Units|Test Target, ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1); 
	%excel(indsn=out&q., name=Spec_lab_l&q.); 
%end; 
%mend; 
%writespec; 
