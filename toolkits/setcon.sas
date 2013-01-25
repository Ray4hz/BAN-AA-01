
* generate continuous variables; 
%macro setcon(indsn=, outdsn=, varname=, mean=, sd=, format=round, digit=.001, label=NEWVAR); 
data tem; 
	set &indsn; 
		x = normal(1); 
run; 
%if (&format NE "round") %then %do; 
data tem; 
	set tem; 
	&varname = &format( (%sysevalf(&mean) + x*%sysevalf(&sd))); 
	label &varname = "&label"; 
	drop x; 
run; 
%end; 
%else %do; 
data tem; 
	set tem; 
	&varname = &format( (%sysevalf(&mean) + x*%sysevalf(&sd)),&digit); 
	label &varname = "&label"; 
	drop x; 
run; 
%end; 

data &outdsn; 
	set tem; 
run; 
%mend; 
