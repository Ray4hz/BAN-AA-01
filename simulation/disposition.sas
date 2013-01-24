/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	disposition 
Description:	
				To generate disposition data		
      Input:	
     Output:	disp.safety, disp.d, disp.ds
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

data rand; 
	set demog.randomized; 
	keep SUBJID TREATMENT; 
run; 

data demog; 
	set demog.dm; 
run; 

proc sql; 
	create table demog as
	select * 
	from rand as a, demog as b
	where a.SUBJID = b.SUBJID; 
quit; 

* select 10 from the patients who survival till the study cut off date as never treated; 
data tillcut other; 
	set demog; 
	cutdate = "22jan2010"d; 
	format cutdate yymmddn8.; 
	if (RFENDTC = cutdate) then output tillcut; 
	else output other; 
run; 

data a p;
	set tillcut; 
	if TREATMENT = 1 then output a; 
	else output p; 
run; 

* generate 6 never treated from 169 treatment group in tillcut; 
%setcat(indsn=a, outdsn=a1, rn=1, varname=TREATED, len=15, cat=Never Treated|Treated, ncat=6|157); 

* generate 4 never treated from 84 placebo group in tillcut; 
%setcat(indsn=p, outdsn=p1, rn=2, varname=TREATED, len=15, cat=Never Treated|Treated, ncat=4|76); 

* 10 never treated, 243 treated, total 253; 
data tillcut2; 
	set a1 p1; 
run; 

* ongoing 157 in AA, 76 in placebo; 
proc freq data = tillcut2; 
	tables TREATED*TREATMENT; 
run; 

* generate all treated from other, 942; 
data other; 
	set other; 
	format TREATED $15.; 
	TREATED = "Treated";
run; 

data d; 
	set tillcut2 other; 
run; 

proc freq data = d; 
	tables TREATED*TREATMENT; 
run; 

* has mark for treated or not; 
data disp.d; 
	set d; 
run; 

* not trreated list; 
* 10 patients; 
data disp.nt; 
	set d; 
	if TREATED = "Never Treated"; 
	keep SUBJID TREATED; 
run; 

data safety; 
	set disp.d; 
	if TREATED = "Treated"; 
run; 

* get CENSOR status; 
data death; 
	set survival.death; 
	keep SUBJID CENSOR USUBJID; 
run; 

* safety population with censor indicating death; 
proc sql; 
	create table safety as
	select *
	from safety as a, death as b
	where a.SUBJID = b.SUBJID; 
quit; 

data a p;
	set safety; 
	if TREATMENT = 1 then output a; 
	else output p; 
run; 

* generate disc (discontinued or not) from safety A group ; 
%setcat(indsn=a, outdsn=a3, rn=3, varname=DISC, len=25, cat=Treatment Discontinued|Treatment Ongoing, ncat=634|157); 

* generate disc (discontinued or not) from safety P group; 
%setcat(indsn=p, outdsn=p3, rn=4, varname=DISC, len=25, cat=Treatment Discontinued|Treatment Ongoing, ncat=318|76); 

data disp.s s; 
	set a3 p3; 
run;

* 634 ad, 157 ao; 
data ad ao; 
	set a3; 
	if DISC = "Treatment Discontinued" then output ad; 
	else output ao; 
run; 

data ao; 
	set ao; 
	format REASONS $40.; 
	REASONS = .; 
run; 

* 318 pd, 76 po; 
data pd po; 
	set p3; 
	if DISC = "Treatment Discontinued" then output pd; 
	else output po; 
run; 

data po; 
	set po; 
	format REASONS $40.; 
	REASONS = .; 
run; 

* pull out the death group from survival; 
data die; 
	set survival.death; 
	if CENSOR = 1; 
	keep SUBJID CENSOR; 
run; 

* 634; 
* mark the die in ad with CENSOR, censor would be ., death would be 1; 
proc sql; 
	create table addie as
		select * 
			from ad as a 
				left join die as b
					on a.SUBJID = b.SUBJID; 
quit; 

* generate random 21 deaths from addie, 239 for addie_c, 395 for addie_n, total 634; 
data addie_c addie_n; 
	set addie; 
	if CENSOR = 1 then output addie_c; 
	else output addie_n; 
run; 

%setcat(indsn=addie_c, outdsn=addie_cout, rn=5, varname=REASONS, len=40, cat=Death|Later, ncat=21|218); 

data addie_nout; 
	set addie_n; 
	format REASONS $40.; 
	REASONS = "Later"; 
run; 

data addie_a; 
	set addie_cout addie_nout; 
run; 

data addie_die addie_later; 
	set addie_cout; 
	if REASONS = "Death" then output addie_die; 
	else output addie_later; 
run; 

data addie_nout; 
	set addie_nout addie_later; 
run; 

* 613; 
data addie_nout1; 
	set addie_nout; 
	drop REASONS; 
run; 

* generate reasons for disc; 
%setcat(indsn=addie_nout1, outdsn=ad1, rn=4, varname=REASONS, len=40, 
		cat=Disease Progression|Initiation of new anticancer therapy|Adverse event|Withdrawal of consent to treatment|Investigator discretion|Subject Choice|Administration of prohibited medication|Dosing noncompliance|Other, 
		ncat=284|107|98|70|36|5|3|3|7); 

data ad2; 
	set ad1 addie_die; 
	drop CENSOR; 
run; 

* now it's placebo; 
* mark the die in pd with CENSOR; 
proc sql; 
	create table pddie as
		select * 
			from pd as a 
				left join die as b
					on a.SUBJID = b.SUBJID; 
quit; 

* generate random 9 deaths from pddie, 166 pddie_c, 152 pddie_n; 
data pddie_c pddie_n; 
	set pddie; 
	if CENSOR = 1 then output pddie_c; 
	else output pddie_n; 
run; 

%setcat(indsn=pddie_c, outdsn=pddie_cout, rn=5, varname=REASONS, len=40, cat=Death|Later, ncat=9|157); 

data pddie_nout; 
	set pddie_n; 
	format REASONS $40.; 
	REASONS = "Later"; 
run; 

data pddie_a; 
	set pddie_cout pddie_nout; 
run; 

proc freq data = pddie_a; 
	tables REASONS; 
run; 

data pddie_die pddie_later; 
	set pddie_cout; 
	if REASONS = "Death" then output pddie_die; 
	else output pddie_later; 
run; 

data pddie_nout; 
	set pddie_nout pddie_later; 
run; 

data pddie_nout1; 
	set pddie_nout; 
	drop REASONS; 
run; 

* generate reasons for disc; 
%setcat(indsn=pddie_nout1, outdsn=pd1, rn=4, varname=REASONS, len=40, 
		cat=Disease Progression|Initiation of new anticancer therapy|Adverse event|Withdrawal of consent to treatment|Investigator discretion|Subject Choice|Administration of prohibited medication|Dosing noncompliance|Other, 
		ncat=90|64|70|40|27|4|1|3|10); 

data pd2; 
	set pd1 pddie_die; 
	drop CENSOR; 
run; 

data a; 
	set ad2 ao; 
run; 

data p; 
	set pd2 po; 
run; 

data safety; 
	set a p; 
	drop cutdate; 
run; 

data disp.safety; 
	set safety; 
run; 

proc sql; 
	create table t as
		select * 
			from demog as a 
				left join safety as b
					on a.SUBJID = b.SUBJID; 
quit;

data ds; 
	set t; 
	DOMAIN = "DS"; 
	keep SUBJID TREATMENT STUDYID DOMAIN USUBJID ENROLDT RFSTDTC RFENDTC TREATED DISC REASONS;  
run; 

* with censor indicating death; 
proc sql; 
	create table ds as
	select *
	from ds as a, death as b
	where a.SUBJID = b.SUBJID; 
quit; 

proc sort data = ds; 
	by SUBJID; 
run; 

data ds; 
	set ds; 
	if TREATED = " " then SAFETY = 0; 
	else SAFETY= 1; 
	if TREATED = " " then TREATED = "Never Treated"; 
run; 

data disp.ds; 
	set ds; 
run; 

%excel(indsn=ds, name=ds); 

%look(ds, ds2); 

%createcat(indsn=ds2, outdsn=out, varname=LABEL, len=40, cat=Censor or not|Discontinued or not|Domain|
Enrollment Date|Reasons for Discontinuation|Reference Subject End Date|Reference Subject Start Date|
Safety population or not|Study id|Subject id|Treated or not|Treatment group|Unique Subject id, 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1); 

%excel(indsn=out, name=Spec_ds); 


%ppt(disp.ds); 

data ds; 
	set disp.ds; 
run; 

data s; 
	set ds; 
	cutdate = "22jan2010"d; 
	format cutdate yymmddn8.; 
	if RFENDTC = cutdate; 
run; 

%ppt(s); 
%look(s); 

proc freq data = s; 
	tables CENSOR*TREATMENT; 
run; 






