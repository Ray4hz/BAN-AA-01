/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	visit 
Description:	
				To generate visit data		
      Input:	
     Output:	visit.svisit, visit.visit
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

data last; 
	set survival.last; 
run; 

* set up 26 visit for the whole study, including v1 = screening; 
data vi; 
	set last; 
	cutdate = "22jan2010"d; 
	array visit(26) v1-v26; 
	v1 = STRTDT; 	* screening; 
	v2 = v1 + 15; 	* c1 day 1; 
	v3 = v2 + 14; 	* c1 day 15; 
	v4 = v3 + 13; 	* c2 day 1; 
	v5 = v4 + 15; 	* c2 day 15; 
	v6 = v5 + 13; 	* c3 day 1; 
	v7 = v6 + 15; 	* c3 day 15; 
	v8 = v7 + 13; 	* c4 day 1, later all become 28 days cycle, like c4 day 28, c5 day 1, c5 day 28 ...; 
	v9 = v8 + 29; 
	do i = 10 to 26; 
		visit(i) = visit(i-1) + 28; 
	end; 
	format v1-v26 yymmddn8.;
	drop i; 
run;  

data vi; 
	set vi; 
	array visit(26) v1-v26; 
	do i = 1 to 26; 
		if (visit(i) > cutdate) then visit(i) = cutdate; 
	end; 
	drop i; 
run; 

data vi; 
	set vi; 
	array visit(26) v1-v26; 
	do i = 3 to 26; 
		if (visit(i) - visit(2)) > LAST then visit(i) = .; 
	end; 
	drop i; 
run; 

* fit the death date from the survival data; 
data visit; 
	set vi; 
	array visit(26) v1-v26; 
	ENROLDT = visit(1); 
	STOPDT = visit(2); 
	do i = 3 to 26; 
		if visit(i) NE . then STOPDT = visit(i); 
	end; 
	drop i cutdate; 
	format ENROLDT STOPDT yymmddn8.; 
run; 

data visit.visit; 
	set visit; 
run; 

***********************************************************************************************************; 
* here use disp data; 
data nt; 
	set disp.nt; 
run; 

* mark visit with never treated; 
proc sql; 
	create table x as
		select * 
			from visit as a
				left join nt as b
					on a.SUBJID = b.SUBJID; 
quit; 

data y; 
	set x; 
	if TREATED NE "Never Treated" then TREATED = "Treated"; 
	format TREATED $15.; 
run; 

data z; 
	set y; 
	array visit(26) v1-v26; 
	if TREATED = "Never Treated" then do; 
		STOPDT = visit(2); 
		do i = 3 to 26; 
			visit(i) = .; 
		end; 
	end; 
	drop i; 
run; 

data visit visit.visit; 
	set z; 
run; 
***********************************************************************************************************; 

* generate subject visit; 
* add actual visit v31 = visit 3.1, v51 = visit 5.1, v71 = 7.1; 
* create one missing visit for 20% patients in range of visit 4, 6, 8, 12, 14, 16; 
data sv; 
	set visit; 
	x = uniform(1); 
	y = uniform(2); 
	if x LT 0.3 then do; 
	v31 = v3 + int(1 + ranuni(1)*4); 
	v51 = v5 + int(1 + ranuni(1)*4); 
	v71 = v7 + int(1 + ranuni(1)*4); 
	format v31 v51 v71 yymmddn8.; 
	end; 
	else do; 
	v31 = .; 
	v51 = .; 
	v71 = .; 
	end; 
	label 	v31 = "SVSTDTC VISITNUM 3.1"
			v51 = "SVSTDTC VISITNUM 5.1"
			v71 = "SVSTDTC VISITNUM 7.1"; 
	if y LT 0.2 then do; 
		z = rantbl(1, 0.1, 0.1, 0.3, 0.2, 0.2, 0.1); 
		if z = 1 then v4 = .; 
		else if z = 2 then v6 = .; 
		else if z = 3 then v8 = .; 
		else if z = 4 then v12 = .; 
		else if z = 5 then v14 = .; 
		else if z = 6 then v16 = .; 
	end; 
	drop x y z; 
run; 

data visit.sv; 
	set sv; 
run; 

data sv; 
	set visit.sv; 
run; 

data newsv; 
	set sv; 
	array visit(26) v1-v26; 
	array svisit(3) v31 v51 v71; 
	array mnum(3) m1-m3; 
	mnum(1) = 3.1; 
	mnum(2) = 5.1; 
	mnum(3) = 7.1; 
	do i = 1 to 26; 
		SVSTDTC = visit(i);  
		VISITNUM = STRIP(put(i, best32.)); 
		VISITDT = (visit(i) - visit(2)) + 1; 
		output; 
	end; 
	do i = 1 to 3; 
		SVSTDTC = svisit(i); 
		VISITNUM = STRIP(put(mnum(i), best32.)); 
		VISITDT = (svisit(i) - visit(2)) + 1; 
		output; 
	end; 
	keep SUBJID ENROLDT SVSTDTC STOPDT VISITNUM VISITDT TREATED; 
	format SVSTDTC yymmddn8.; 
run; 

data svisit; 
	set newsv; 
	if SVSTDTC NE .; 
run; 

proc sort data = svisit; 
	by SUBJID VISITNUM; 
run; 

data visit.svisit; 
	set svisit; 
run; 

data subvis; 
	set visit.svisit; 
	drop TREATED CENSOR TREATMENT; 
run; 

%excel(indsn=subvis, name=sv); 

%look(visit.svisit, sv); 

%createcat(indsn=sv, outdsn=out, varname=LABEL, len=40, cat=Enrollment Date|Stop Date|Subject id|
Start Date/Time of Visit|Treated or not|Planned Study Day of Visit|Visit Number, ncat=1|1|1|1|1|1|1); 

%excel(indsn=out, name=Spec_sv); 





