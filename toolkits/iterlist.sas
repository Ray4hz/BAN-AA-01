
* iterlist; 
%macro iterlist(list=, code=); 
* assign each iterm in the list to an indexd macro variable &&iterm&i; 
%let i = 1; 
%do %while (%cmpres(%scan(&list., &i.)) ne ); 
	%let item&i. = %cmpres(%scan(&list., &i)); 
	%let i = %eval((&i. + 1); 
%end; 

%let cntitem = %eval((&i. - 1); 

* express code, replacing tokens with elements of the list in sequence; 
%do i = 1 %to &cntitem.; 
	%let codeprp = %qsysfunc(tranwrd(&code., ?, %nrstr(&&item&i..))); 
	%unquote(&codeprp.)
%end; 
%mend; 
