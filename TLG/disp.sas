/*====================================================================
| COMPANY           Bancova LLC
| PROJECT:          BAN-AA-01
| PROGRAM:          disp.sas
| PROGRAMMER(S):    Ray
| DATE:             
| PURPOSE:          Generate disposition table
|                        
| INPUT FILE DIRECTORY(S)		 : N/A  
| OUTPUT FILE DIRECTORY(S)  	 : N/A        
| OUTPUT AND PRINT SPECIFICATIONS: N/A  
|
| REVISION HISTORY
| DATE     	BY        	COMMENTS
|
=====================================================================
|COMMENTS:
|
=====================================================================*/ 
 
*----------------------------------------------*;
* options, directories, librefs, macros etc.
*----------------------------------------------*;

** clean the log and output screen; 
dm 'log; clear; output; clear';

** log, output and procedure options; 
options center formchar="|____|||___+=|_/\<>*" missing = '.' nobyline nodate;

** macro debug options; 
options symbolgen mprint spool msglevel = i; 

** define the location for the input and output; 
%let dDir = E:\Dropbox\Oncology\Simulation\raw;
%let oDir = E:\Dropbox\Oncology\TLG; 

** output libname; 
libname out "&oDir"; 

** autocall macros; 
filename autoM "C:\bancova\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 



*--------------------------------------------*;
* define format and template for report 
*--------------------------------------------*;

** format for varaibles; 
proc format;
	invalue trtin
		"Never Treated" 						= 2
		"Treated"							= 3
		other								= 99
		; 
	invalue disin
		"Treatment Ongoing"						= 1
		"Treatment Discontinued"					= 2
		other 								= 99
		; 
	invalue reain
		"Disease Progression"						= 2
		"Initiation of new anticancer therapy" 				= 3
		"Adverse event"							= 4 
		"Withdrawal of consent to treatment" 				= 5
		"Investigator discretion" 					= 6
		"Death"								= 7
		"Subject choice"						= 8
		"Administration of prohibited medication"			= 9
		"Dosing noncompliance"						= 10
		"Other"								= 11
		other								= 99
		; 
	value trtf
		1	= 'All Randomized'
		2 	= '    Never Treated'
		3 	= '    Treated'
		; 
	value disf
		1 	= '        Treatment Ongoing'
		2 	= '        Treatment Discontinued'
		; 
	value reaf
		1 	= 'Reasons for Discontinuation'
		2 	= '    Disease Progression'
		3 	= '    Initiation of new anticancer therapy'
		4 	= '    Adverse event'
		5 	= '    Withdrawal of consent to treatment'
		6 	= '    Investigator discretion'
		7 	= '    Death'
		8 	= '    Subject choice'
		9 	= '    Administration of prohibited medication'
		10 	= '    Dosing noncompliance'
		11 	= '    Other'
		;
	invalue namef
		"trt"	= 1
		"dis"	= 2
		"rea"	= 3
		; 
run;


** template for data report;
proc template;
	define style styles.panda;
		style titleAndNoteContainer /
        	outputwidth 			= _undef_;
      	style data /
          	foreground 			= black
          	font_face 			= arial
          	font_weight 			= medium
          	font_size 			= 10pt
          	protectspecialchars		= off;
      	style header /
          	protectspecialchars		= off
          	font_face 			= Arial
          	font_weight 			= medium
          	font_size 			= 10pt;
       	style Table /
          	cellspacing			= 1pt
          	cellpadding			= 2pt
          	frame				= above
          	rules				= groups
          	borderwidth 			= 1.5pt;
       	style systemtitle /
          	font_face 			= arial
          	font_weight 			= medium
          	font_size 			= 10pt
          	protectspecialchars		= off;
       	style systemfooter /
          	font_face 			= arial
          	font_weight 			= medium
          	font_size 			= 10pt;
       	style column /
          	protectspecialchars		= off;
       	style notecontent;
       	style pageno /
          	foreground 			= white;
       	style SysTitleAndFooterContainer;
       	style body /
          	bottommargin 			= 1in
          	topmargin 			= 1in
          	rightmargin 			= _undef_
          	leftmargin 			= _undef_;
	end;
run ;




*--------------------------------------------*;
* import, create new variable(s) and QC 
*--------------------------------------------*;
** import disposition raw data into dis; 
proc import 	datafile = "&dDir\disposition\ds.xls"
				out 	 = rawds
				dbms 	 = xls replace; 
	sheet 		= "ds";
	getnames 	= yes;  
run;  

** import demog data for itt index; 
proc import 	datafile = "&dDir\demog\demog.xls"
				out 	 = rawdm
				dbms 	 = xls replace; 
	sheet 		= "demog";
	getnames 	= yes;  
run; 

proc sql; 
	create table raw as
	select a.USUBJID as usubjid, a.TREATMENT as treatment, a.TREATED as treated, 
	a.DISC as disc, a.REASONS as reasons, b.ITT, b.SAFETY
	from rawds as a, rawdm as b
	where a.USUBJID = b.usubjid; 
quit; 



*--------------------------------------------*;
* derive disposition data
* select ITT patients
* analysis variables must be numeric
*--------------------------------------------*;
data out.drds; 
	format usubjid treatment treated disc reasons ITT SAFETY; 
	set raw; 
	if ITT = 1; 
	trt = input(strip(treated), trtin.); 
	dis = input(strip(disc), disin.); 
	rea = input(strip(reasons), reain.); 
	keep usubjid treatment trt dis rea treated disc reasons ITT SAFETY; 
run;  

proc sort data = out.drds out = ds; 
	by usubjid; 
run; 

** quick check the values of each categorical variable; 
%macro frqtab(ids=, tabvar=);
  proc freq %if &ids ne %then %do;
                  data = &ids
			%end;;
       tables &tabvar / list missing nopercent;
  run;
%mend;

%frqtab(ids = ds, tabvar= trt dis rea ITT*treatment ITT*SAFETY);



*--------------------------------------------*;
* QC
* rule 1: check all duplicates and report them
* rule 2: check all missing values and report them
* rule 3: check all illogic data and report them
*--------------------------------------------*;
** check duplicates; 
data ds dsdupes; 
	set ds; 
	by usubjid; 
	if not (first.usubjid and last.usubjid) then output dsdupes; 
	if last.usubjid then output ds; 
run; 

%pt(dsdupes); 
* no duplicates; 

** check illogic data according to the disposition variable structure; 
** missing values of disc and reasons are permitted if beyond the their range; 
data dsDiag; 
	set ds; 
	** index1 : check whether variable treated are all in ITT populations; 
	if trt < 99 and ITT ^= 1	then index1 = 1; 
	else 						 	 index1 = 0; 
	** index2 : check whether non-missing values of disc are all within "Treated" in treated; 
	if dis < 99 and trt ^= 12	then index2 = 1; 
	else 							 index2 = 0; 
	** index3 : check whether non-missing values of reasons are within "Treatment Discontinued" in disc; 
	if rea < 99 and dis ^= 14	then index3 = 1; 
	else 							 index3 = 0; 
	** any index greater than 0 will make diag = 1; 
	diag = ( max( index1, index2, index3 ) > 0 ) ; 
run; 

proc print data = dsDiag; 
	where diag = 1; 
run; 
* no illogic data; 




*--------------------------------------------*;
* calculate the counts # for each group; 
*--------------------------------------------*;
** keep the analysis variables age, ethnicity and race; 
** create the treatment = 3 for calculating the total; 
data ds1; 
	set ds; 
	output; 
	treatment = 3; 
	output; 
run; 

proc sort data = ds1 out = ds2; 
	by treatment usubjid; 
run; 
 
proc sql noprint; 
	select strip(put(count(treatment), best.)) into :num1- :num3 from ds2 group by treatment; 
quit; 

%put &num1; ** 797; 
%put &num2; ** 398; 
%put &num3; ** 1195; 




*--------------------------------------------*;
* A macro to count; 
*--------------------------------------------*;
** indsn: input data set; 
** outdsn: output data set; 
** grp: group for transpose, like treatment, must start from 1 to n; 
** var: variable for counting, like soct, ptterm, severity, name from var1 to var&n if more than one; 
** transpose: output data set if the last variable will be tranposed within each group; 
%macro catstat2(indsn=, outdsn=, grp=, var=, transpose=last); 
%global cntvar cntvar2; 
%local i; 
%let i = 1; 
%do %while ( %sysfunc(scan(&var., &i.)) ne ); 
	%global var&i.; 
	%let var&i. = %sysfunc(scan(&var., &i.)); 
	%let i = %eval( &i. + 1 ); 
%end; 
%let cntvar = %eval( &i. - 1 ); 
%let cntvar2 = %eval( &i. - 2 ); 

data &indsn._&cntvar._storevar; 
	format v $10.; 
	%do j = 1 %to &cntvar.; 
		v = "&&var&j"; 
		output; 
	%end; 
run; 

proc sql noprint; 
	select v into: newvar separated by "," from &indsn._&cntvar._storevar; 
	select v into: newvar2 separated by "*" from &indsn._&cntvar._storevar; 
quit; 

%global newcomma newstar; 
%let newcomma = &newvar.; 
%let newstar = &newvar2.; 

data &indsn._&cntvar._varsent; 
	%do i = 1 %to &cntvar.; 
		s = "and a.&&var&i. = c.&&var&i."; 
		output; 
	%end; 
run; 
proc sql noprint; 
	select s into:newsen separated by " " from &indsn._&cntvar._varsent; 
quit; 

%global newand; 
%let newand = &newsen.; 

proc sort data = &indsn. out = indsnsort; 
	by &grp.; 
run; 

proc freq data = indsnsort noprint; 
	table &newstar. / out = indsnsort_in; 
	by &grp.; 
run; 

%global ngrp; 

proc sql noprint; 
	select strip( put( count(distinct &grp.), best.) ) into: ngrp from indsnsort_in;  
	%let ngrp=&ngrp.; 
	create table &outdsn. as
	select distinct &newcomma.
	from &indsn.
	order by &newcomma.; 
quit; 

data &outdsn.; 
	set &outdsn.; 
	key = _n_; 
run; 

%do i = 1 %to &ngrp.; 
proc sql noprint; 
	create table &indsn._&ngrp._col&i. as
	select a.*, 
		case 
			when missing((select COUNT from indsnsort_in as c
			where c.&grp. = &i.
			&newand.
			)) = 1 then 0

			else (select COUNT from indsnsort_in as c
			where c.&grp. = &i.
			&newand.
			)
		end as grp&i.
	from &outdsn. as a; 
quit; 

data &indsn._col&i.; 
	set &indsn._col&i.; 
	key = _n_; 
run; 

data &outdsn.; 
	merge &outdsn. &indsn._&ngrp._col&i.; 
	by key;
run; 
%end;
data &outdsn.; 
	set &outdsn.; 
	drop key; 
run; 

data &indsn._&cntvar._storevar2; 
	set &indsn._&cntvar._storevar; 
	if _n_ = &cntvar. then delete; 
run; 

proc sql noprint; 
	select v into: newvar2 separated by "," from &indsn._&cntvar._storevar2;
 	select v into: newempty2 separated by " " from &indsn._&cntvar._storevar2;
quit; 

%global newcomma2 newspace2; 
%let newcomma2 = &newvar2.; 
%let newspace2 = &newempty2.; 

%global nlast; 
proc sql noprint; 
	select strip( put( count(distinct &&var&cntvar.), best.) ) into: nlast from &outdsn.;  
	%let nlast = &nlast.; 
quit; 

%do j = 1 %to &nlast.; 
	%global newlast&j.; 
	data lastcom&j.; 
		%do i = 1 %to &ngrp.; 
			s = "case when missing(b.grp&i.) then 0 else b.grp&i. end as grp&i._v&j.,"; 
			output; 
		%end; 
	run; 
	proc sql noprint; 
		select s into:newcase&j. separated by " " from lastcom&j.; 
	quit; 
	%let newlast&j. = &&newcase&j.; 
%end; 

data &indsn._&cntvar._varsent2; 
	%do i = 1 %to &cntvar2.; 
		s = "a.&&var&i. = b.&&var&i."; 
		output; 
	%end; 
run; 
proc sql noprint; 
	select s into:newsen2 separated by " and " from &indsn._&cntvar._varsent2; 
quit; 

%global newand2; 
%let newand2 = &newsen2.; 

proc sql noprint; 
	create table last0 as
	select distinct &newcomma2.
	from &outdsn.; 

%do i = 1 %to &nlast.; 
	create table last&i. as
	select 
			&&newlast&i.
			a.*
	from last%eval(&i.-1) as a
		left join 
			(select * from &outdsn. where &&var&cntvar. = &i.) as b
		on 	&newand2.; 
%end; 
quit; 

data &transpose.; 
	format &newspace2.; 
	%do i = 1 %to &ngrp.; 
		%do j = 1 %to &nlast.; 
			format grp&i._v&j. grp&i._v&j. grp&i._v&j.; 
		%end; 
	%end; 
	set last&nlast.; 
run; 
%mend; 

** count trt; 
%catstat2(indsn=ds2, outdsn=cnttrt, grp=treatment, var=trt); 

%pt(cnttrt); 

proc sql; 
	create table sumtrt as 
	select 1 as trt, sum(grp1) as grp1, sum(grp2) as grp2, sum(grp3) as grp3
	from cnttrt; 
quit; 

%pt(sumtrt); 

data out1; 
	set sumtrt
		cnttrt; 
	cat = 1; 
	list = trt; 
	drop trt; 
run; 

%pt(out1); 

** count dis; 
%catstat2(indsn=ds2, outdsn=cntdis, grp=treatment, var=dis); 

%pt(cntdis); 

data out2; 
	set cntdis; 
	if dis < 99; 
	cat = 2; 
	list = dis; 
	drop dis; 
run; 

%pt(out2); 

** count rea; 
%catstat2(indsn=ds2, outdsn=cntrea, grp=treatment, var=rea); 

%pt(cntrea); 

data out3; 
	set cntrea; 
	if rea < 99; 
	cat = 3; 
	list = rea; 
	drop rea; 
run; 

%pt(out3); 




*--------------------------------------------*;
* prepare the final dataset for report; 
*--------------------------------------------*;
data temp; 
	set out1
		out2
		out3; 
	col1 	= strip(put(grp1, 4.0)) || " (" || strip(put( grp1/%eval(&num1), percent8.1)) || ")"; 
	col2 	= strip(put(grp2, 4.0)) || " (" || strip(put( grp2/%eval(&num2), percent8.1)) || ")"; 
	col3 	= strip(put(grp3, 4.0)) || " (" || strip(put( grp3/%eval(&num3), percent8.1)) || ")"; 
	drop grp1 grp2 grp3; 
run; 

** dummy to ensure the integrity of the list; 
%macro dum(outdsn=, ncat=, catlist=, ngrp=); 
%local i; 
%let i = 1; 
%do %while ( %sysfunc(scan(&catlist., &i.)) ne ); 
	%global cat&i.; 
	%let cat&i. = %sysfunc(scan(&catlist., &i.)); 
	%let i = %eval( &i. + 1 ); 
%end; 

%do j = 1 %to &ncat.; 
	data dsn&j.; 
		do k = 1 to &&cat&j.; 
			cat = &j.; 
			list = k; 
			%do l = 1 %to &ngrp.; 
			grp&l. = " "; 
			%end; 
			output; 
		end; 
		drop k; 
	run; 
%end; 

data &outdsn.; 
	set 
		%do g = 1 %to &ncat.; 
			dsn&g.
		%end; 
 	; 
run; 
%mend; 

%dum(outdsn=dum, ncat=3, catlist=3 2 11, ngrp=3); 

%pt(dum); 


** stack up data sets for variables; 
proc sql; 
	create table out as
	select a.cat, a.list, 
		case 
			when missing(b.col1) then a.grp1
			else b.col1
		end as col1, 
		case
			when missing(b.col2) then a.grp2
			else b.col2
		end as col2,
		case 
			when missing(b.col3) then a.grp3
			else b.col3
		end as col3
	from dum as a
		left join 
			temp as b
		on 	a.cat = b.cat and 
			a.list = b.list; 
quit; 

%pt(out); 

data out; 
	set out; 
	format listf $50.; 
	if cat = 1 then listf = put(list, trtf.); 
	if cat = 2 then listf = put(list, disf.); 
	if cat = 3 then listf = put(list, reaf.); 
run; 

%pt(out); 

** set up the page break, footnote, bottomline; 
data final; 
	set out; 
	mypage 		= ceil(_n_/18); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
run; 

%pt(final); 




*--------------------------------------------*;
* report; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = Disposition; 
%let tableno = Table 1; 
%let title = Subject Disposition; 
%let population = ITT Population; 
%let span=\brdrb\brdrs\brdrw15;
%let project = BAN-AA-01; 
%let company = Bancova Institute; 

%macro rtftit;
title1 font='arial' h=1 justify=l "&company."  
                        justify=r "&project.";
title2 font='arial' h=1 justify=r "page^{pageof}";
footnote1 justify=c "______________________________________________________________________________________________________________________________________";
footnote2 font='arial' h=1 justify=c "&task. by Ray at %now()";
%mend;
%rtftit; 
title3 "^S={font_size=9pt just=c font_face=arial} &tableno.";
title4 "^S={font_size=10pt just=c font_face=arial} &title.";
title5 "^S={font_size=8pt just=c font_face=arial} &population.";

options ps=77 ls=100 nonumber orientation=landscape; 

** output to rtf; 
ods rtf file="&oDir\&task._%now(fmt=b8601dt).rtf" style=panda;

proc report data = final nowindows missing headskip headline split="/" 
										style(header)={just=l}
										style(column)={cellheight=0.2in }; 	
	column mypage footnote bottomline listf col1 col2 col3; 

	define mypage	    / order noprint;
	define footnote	   / order noprint;
	define bottomline / order noprint;

	define listf		    /" " 					style=[asis=on cellwidth=3in];
	define col1		   /"AA		   / N=&num1"			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col2		  /"Placebo	  / N=&num2" 			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col3		 /"Total         / N=&num3" 			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	
	compute before; 
		line " "; 
	endcomp; 

	break after mypage / page;	

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes: N = Number of patients in the ITT Population. "; 
		line " "; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} n = Number of patients within a specific category."; 
		line " "; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} AA = abiraterone acetate"; 
	endcomp;
run; 

ods rtf close;















