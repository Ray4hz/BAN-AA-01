
** a macro to put a specific value of a dataset into a macro variable; 
%macro getval(dsn=,row=,var=,name=);
%GLOBAL &name.;
data _null_;
set &dsn.;
if _N_ = &row. then do;
	call symput(symget('name'),&var.);
end;
run;
%mend;
