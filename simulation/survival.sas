/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	survival 
Description:	
				To generate survival data		
      Input:	
     Output:	
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

*******************************************************************************************************; 
*
* simulate weibull distribution for survival analysis
* record: with length of life in "LAST"
* after the patient died, the visit date will be "."; 
* 
*******************************************************************************************************;

** get time-to-event and time-to-censoring; 
%macro settte(r=, indsn=, outdsn=, beta1=2, beta2=-1, lambdat=0.002, lambdac=0.004); 
%let dsid = %sysfunc(open(&indsn)); 
%global nobs; 
%let nobs = %sysfunc(attrn(&dsid, nlobs)); 
%let rc = %sysfunc(close(&dsid));
data test; 
	set &indsn; 
	i = _n_; 
run; 
data simcox; 
	beta1 = &beta1; 
	beta2 = &beta2; 
	lambdat = &lambdat; * baseline hazard; 
	lambdac = &lambdac; * censoring hazard; 
	do i = 1 to &nobs; 
		x1 = normal(&r); 
		x2 = normal(&r); 
		linpred = exp(-beta1*x1 - beta2*x2); * linear predicator; 
		t = rand("WEIBULL", 1, lambdat*linpred); 
		* time to event; 
		c = rand("WEIBULL", 1, lambdac); 
		* time to censoring; 
		time = min(t, c)*5700; 
		censor = (c lt t); 
		output; 
	end; 
	drop x1 x2 t c; 
run; 
data simcox;
	set simcox; 
	i = _n_;
run; 
data &outdsn; 
	merge test simcox; 
	by i; 
	drop i beta1 beta2 lambdat lambdac linpred; 
run; 
%mend; 

data test; 
	set demog.randomized; 
run; 

data testtrt testpla; 
	set test; 
	if TREATMENT = 1 then output testtrt; 
	else if TREATMENT = 2 then output testpla; 
run; 

* real result, median:14.8, death:333, censored:464, 58.2%; 
%settte(r=3, indsn=testtrt, outdsn=testtrt3, beta1=2.2, beta2=-1, lambdat=0.002, lambdac=0.004); 
* median = 14.6, deaths = 330, censored = 467, 58.59%; 
proc lifetest data = testtrt3; 
	time time*censor(0); 
run; 

data survival.treatment1; 
	set testtrt3; 
run; 

* real result, placebo median: 10.9, death:219, censored:179, 45%; 
* random result: median = 10.7, deaths = 212, censored = 186, 46%; 
%settte(r=6, indsn=testpla, outdsn=testpla1, beta1=10, beta2=-20, lambdat=0.005, lambdac=0.003); 
proc lifetest data = testpla1; 
	time time*censor(0); 
run; 

data survival.placebo1;
	set testpla1; 
run; 

data life; 
	set survival.treatment1 survival.placebo1; 
run; 

data survival.life; 
	set life; 
run; 

ods pdf file="G:\bancova\m5\datasets\BAN-AA-01\tabulations\legacy\survival\surv.pdf"; 
proc lifetest data = life outsurv = survival.surv plots =(s); 
	time time*censor(0); 
	strata treatment; 
run; 
ods pdf close; 

ods listing; 
proc lifetest data = survival.life
	alphaqt = 0.05 timelist = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
	plots = (survival)
	outsurv = KMPLOT; 
	time time*censor(0); 
	strata treatment; 
	id SUBJID; 
run; 
ods listing close; 

data death; 
	set survival.life; 
	LAST = int(time*28) + 1; 
run; 

data survival.death; 
	set death (rename=(time=TIME censor=CENSOR)); 
run; 

data survival.last; 
	set survival.death; 
	keep SUBJID STRTDT LAST; 
run; 

proc freq data = survival.death; 
	tables LAST*CENSOR; 
run; 




