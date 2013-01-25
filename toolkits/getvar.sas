
* get one variable; 
%macro getvar(indsn, var, nobs); 
proc sql noprint; 
	select count(*)
		into :nl
	from &indsn.; 

	create table temp as
	select &var.
		into :val1-:val%left(&nl)
	from &indsn.; 
quit; 

%if ("&nobs." = "") %then %do; 
	proc print data = temp; 
	run; 
%end; 
%else %do; 
	data outdsn; 
		set temp; 
		if _n_ = &nobs.then output; 
	run; 
	%global v; 
	proc sql noprint; 
		select &var. into :v
		from outdsn;
	quit; 
	%put &v; 
%end; 
%mend; 
