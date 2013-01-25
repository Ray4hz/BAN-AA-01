* macro to print the dataset; 
%macro pt(dataset);
	proc print data = &dataset;
	run; 
%mend pt; 
