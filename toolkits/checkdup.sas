
* check duplicates; 
%macro checkdup(indsn=, outdsn=, dupes=, byvar=); 
data &outdsn. &dupes.; 
	set &indsn.; 
	by &byvar.; 
	retain &byvar.; 
	if not (first.&byvar. and last.&byvar.) then output &dupes.; 
	if last.&byvar. then output &outdsn.; 
run; 
%mend; 
