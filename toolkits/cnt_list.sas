
* count the list items; 
%macro cnt_list(list=); 
* assign each iterm in the list to an indexd macro variable &&iterm&i; 
%let i = 1; 
%do %while (%cmpres(%scan(&list., &i.)) ne ); 
	%let item&i. = %cmpres(%scan(&list., &i)); 
	%let i = %eval((&i.) + 1); 
%end; 

%let cntitem = %eval((&i.) - 1); 
%mend; 
