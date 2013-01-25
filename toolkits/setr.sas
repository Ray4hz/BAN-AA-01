
* create random number in a dataset according to its obs; 
%macro setr(indsn=, outdsn=, rn=); 
%let dsid = %sysfunc(open(&indsn)); 
%global nobs; 
%let nobs = %sysfunc(attrn(&dsid, nlobs)); 
%let rc = %sysfunc(close(&dsid));
data tem; 
	set &indsn; 
	rnum&rn = _n_; 
run; 
proc plan seed = &rn; 
	factors rnum&rn = &nobs/noprint; 
	output data = tem out = &outdsn; 
run; 
%mend; 
