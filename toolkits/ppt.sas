* print 20 obs; 
%macro ppt(dataset, obs=20);
	proc print data = &dataset (obs = &obs);
	run; 
%mend ppt; 
