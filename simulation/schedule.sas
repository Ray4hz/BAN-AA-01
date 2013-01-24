/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	schedule
Description:	
				To generate 16 permuted block randomizatoin schedules for 
					treatment : placebo = 2 : 1 
					mixed block size = 3, 6, 9 
					block number for each size = 45, 45, 45 (one schedule hold 810 people)
      Input:	
				b1: number of blocks for block size 3;
				b2: number of blocks for block size 6;
				b3: number of blocks for block size 9; 
     Output:	
				schedule1111 to schedule 2222; 
					output: postfix number of "schedule", like "1111"; 
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

%macro mixsize(b1=, b2=, b3=, output=); 
%let total = %eval(&b1 + &b2 + &b3); 
proc plan seed = &output; 
	factors block = &b1 ordered treatment = 3/noprint; 
	output out = per3 treatment nvals = (1 1 2); 
run; 
data per3; 
	set per3; 
	blksize = 3; 
run; 
proc plan seed = &output; 
	factors block = &b2 ordered treatment = 6/noprint; 
	output out = per6 treatment nvals = (1 1 1 1 2 2); 
run; 
data per6; 
	set per6; 
	blksize = 6; 
run; 
proc plan seed = &output; 
	factors block = &b3 ordered treatment = 9/noprint; 
	output out = per9 treatment nvals = (1 1 1 1 1 1 2 2 2); 
run; 
data per9; 
	set per9; 
	blksize = 9; 
run; 
data bl; 
	set per3 per6 per9; 
run; 
data b;
	set bl; 
	if blksize = 3 then unit = block; 
		else if blksize = 6 then unit = (block + &b1); 
			else if blksize = 9 then unit = (block + &b1 + &b2); 
run; 
* randomized the different sets of block size; 
proc plan seed = &output; 
	factors unit = &total/noprint; 
	output data = b out = out; 
run; 
proc sort data = out; 
	by unit; 
run; 
data schedule&output; 
	set out; 
	an = _n_; 
	label	treatment 	= "Treatment group"
			unit 		= "Block number"
			blksize 	= "Block size"
			block		= "Original block number"
			an 			= "Allocation number"; 
run; 

%mend; 

* It can contain 810 patients; 
%macro strata; 
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
	%mixsize(b1 = 45, b2 = 45, b3 = 45, output = &&s&i); 
	data rand.schedule&&s&i; 
		set schedule&&s&i; 
	run; 
%end; 
%mend; 
%strata; 


