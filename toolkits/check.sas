
* check contents; 
%macro check(indata); 
	proc contents data = &indata; 
	run; 
%mend check; 
