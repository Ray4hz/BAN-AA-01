/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	randomized
Description:	
				To get randomized allocation number for each patents				
      Input:	
     Output:	demog.randomized
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

* get randomized id; 
%macro getrand(dsn); 
data stra&dsn; 
	set demog.born; 
	if STRATUM = &dsn; 
	drop STRATUM; 
run; 

proc sort data = stra&dsn; 
	by STRTDT; 
run; 

data stra&dsn; 
	set stra&dsn; 
	an = _n_; 
run; 

data allo&dsn; 
	merge stra&dsn rand.schedule&dsn; 
	by an; 
run; 

data allo&dsn; 
	set allo&dsn; 
	if SUBJID NE .; 
run; 
%mend; 

%macro allo; 
%let s1 =1111; 
%let s2 =1112; 
%let s3 =1121; 
%let s4 =1211; 
%let s5 =2111; 
%let s6 =1221; 
%let s7 =2112; 
%let s8 =2211; 
%let s9 =2121; 
%let s10 =1122; 
%let s11 =1212; 
%let s12 =1222; 
%let s13 =2122; 
%let s14 =2212; 
%let s15 =2221; 
%let s16 =2222; 

%do i = 1 %to 16; 
	%getrand(&&s&i); 
	data allo.allo&&s&i; 
		set allo&&s&i; 
	run;  
%end; 
%mend; 
%allo; 

data randomized; 
	set allo1111

		allo1112
		allo1121
		allo1211
		allo2111

		allo1221
		allo1122
		allo2211
		allo2121
		allo2112
		allo1212
		allo1222

		allo2122
		allo2212
		allo2221

		allo2222; 
run; 

data demog.randomized; 
	set randomized (rename = (an = AN block = BLOCK treatment = TREATMENT 
						blksize = BLKSIZE unit = UNIT)); 
run;







