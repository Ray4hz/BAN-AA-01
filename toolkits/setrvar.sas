
* randomize the categorical variable in the dataset; 
%macro setrvar(indsn=, outdsn=, rn=, varname=); 
%let dsid = %sysfunc(open(&indsn)); 
%global nobs; 
%let nobs = %sysfunc(attrn(&dsid, nlobs)); 
%let rc = %sysfunc(close(&dsid));
proc plan seed = &rn; 
	factors &varname = &nobs/noprint; 
	output data = &indsn out = &outdsn; 
run; 
%mend; 
