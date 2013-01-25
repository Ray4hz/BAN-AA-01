
* create categorical variables, not random; 
%macro createcat(indsn=, outdsn=, varname=, len=40, cat=, ncat=); 
data copy; 
	set &indsn; 
	seq = _n_; 
run; 

* put the number of each category in ncat1, ncat2,...ncati, count the total number of categories; 
%let i = 1; 
%do %while (%cmpres(%scan(&ncat., &i., "|")) ne ); 
	%let ncat&i. = %cmpres(%scan(&ncat., &i., "|")); 
	%let i = %eval((&i.) + 1); 
%end; 

%let cntitem = %eval((&i.) - 1); 

* put categories in the cat1, cat2,...catk (exclude if the number cases of category = 0); 
%let k = 1; 
%let cat1 = %scan(&cat., &k., "|"); 
%do %while ( %eval( &k. ne &i. ) );
	%let k = %eval(&k. + 1); 
	%let cat&k. = %scan(&cat., &k., "|"); 
%end; 

%do j = 1 %to &cntitem.; 
	data sub&j.; 
		set copy; 
		if (_n_ >= &j.) and (_n_ < &j. + &&ncat&j.); 
		keep seq; 
	run; 
	data sub&j.; 
		format &varname $&len..; 
		set sub&j.; 
		&varname = "&&cat&j"; 
	run; 
%end; 

data all; 
	set sub1; 
run; 

%do i = 2 %to &cntitem.; 
	data all; 
		set all sub&i; 
	run; 
%end; 

data allt; 
	set all; 
	seq = _n_; 
run; 

data outt; 
	merge copy allt; 
	 by seq; 
run; 

data &outdsn; 
	set outt; 
	drop seq; 
run; 
%mend; 
