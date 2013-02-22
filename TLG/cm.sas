/*====================================================================
| COMPANY           Bancova LLC
| PROJECT:          BAN-AA-01
| PROGRAM:          cm.sas
| PROGRAMMER(S):    Ray
| DATE:             
| PURPOSE:          Generate conmed table
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
	invalue pttin
		"AVANAFIL" 											= 1
		"LODENAFIL"											= 2
		"MIRODENAFIL"										= 3
		"SILDENAFIL"										= 4
		"TADALAFIL"											= 5
		"UDENAFIL"											= 6
		"VARDENAFIL"										= 7
		" "													= 99
		other 												= 100
		; 
	value pttf
		1 = "AVANAFIL" 											
		2 = "LODENAFIL"									
		3 = "MIRODENAFIL"										
		4 = "SILDENAFIL"										
		5 = "TADALAFIL"										
		6 = "UDENAFIL"											
		7 = "VARDENAFIL"																	
		; 	
run;

** template for data report;
proc template;
	define style styles.panda;
		style titleAndNoteContainer /
        	outputwidth 		= _undef_;
      	style data /
          	foreground 			= black
          	font_face 			= arial
          	font_weight 		= medium
          	font_size 			= 10pt
          	protectspecialchars	= off;
      	style header /
          	protectspecialchars	= off
          	font_face 			= Arial
          	font_weight 		= medium
          	font_size 			= 10pt;
       	style Table /
          	cellspacing			= 1pt
          	cellpadding			= 2pt
          	frame				= above
          	rules				= groups
          	borderwidth 		= 1.5pt;
       	style systemtitle /
          	font_face 			= arial
          	font_weight 		= medium
          	font_size 			= 10pt
          	protectspecialchars	= off;
       	style systemfooter /
          	font_face 			= arial
          	font_weight 		= medium
          	font_size 			= 10pt;
       	style column /
          	protectspecialchars	= off;
       	style notecontent;
       	style pageno /
          	foreground 			= white;
       	style SysTitleAndFooterContainer;
       	style body /
          	bottommargin 		= 1in
          	topmargin 			= 1in
          	rightmargin 		= _undef_
          	leftmargin 			= _undef_;
	end;
run ;



*--------------------------------------------*;
* import, create new variable(s) and QC 
*--------------------------------------------*;
** import ae data into rawae; 
proc import 	datafile = "&dDir\conmed\conmed.xls"
				out 	 = rawcm
				dbms 	 = xls replace; 
	sheet 		= "cm";
	getnames 	= yes;  
run;  

%ppt(rawcm); 

** import demog data for itt index; 
proc import 	datafile = "&dDir\demog\demog.xls"
				out 	 = rawdm
				dbms 	 = xls replace; 
	sheet 		= "demog";
	getnames 	= yes;  
run; 

%ppt(rawdm); 

** get treatment, SAFETY variables from demog; 
** select the SAFETY population; 
proc sql; 
	create table cm1 as
	select strip(a.USUBJID) as usubjid, strip(a.CMTRT) as ptterm, b.treatment, b.SAFETY
		from rawcm as a
			left join
				rawdm as b
			on a.USUBJID = b.usubjid and b.SAFETY = 1;
quit; 

%ppt(cm1); 

proc freq data = cm1; 
	table ptterm; 
run; 

data cm2; 
	set cm1; 
	ptt = input(strip(ptterm), pttin.); 
run; 

%ppt(cm2); 


*--------------------------------------------*;
* QC
* rule 1: check all missing values and report them
* rule 2: check all illogic data and report them
*--------------------------------------------*;
** check illogic and missing data; 
data cmDiag; 
	set cm2; 
	** any index greater than 0 will make diag = 1; 
	diag = ( ptt > 99 ) ; 

run; 

proc print data = cmDiag; 
	where diag = 1; 
run; 
* no illogic data; 





*--------------------------------------------*;
* calculate counts # as denominator (safety); 
*--------------------------------------------*;
data rawdm1; 
	set rawdm; 
	output; 
	treatment = 3; 
	output; 
run; 

%pt(rawdm1); 

proc sql noprint; 
	select strip(put(count(treatment), best.)) into :num1- :num3 
	from rawdm1 (where =(SAFETY = 1))
	group by treatment; 
quit; 

%put &num1; ** 791; 
%put &num2; ** 341; 
%put &num3; ** 1185; 



*--------------------------------------------*;
* count the ptt and soc separately; 
*--------------------------------------------*;
** set up treatment = 3 for total count; 
data cm; 
	set cm2; 
	output; 
	treatment = 3; 
	output; 
run; 

** patients with at least one AE; 
proc sql noprint; 
	select count(distinct usubjid) into: none1 - : none3 from cm group by treatment; 
quit; 

%put &none1.; ** 16; 
%put &none2.; ** 11; 
%put &none3.; ** 27; 

data atone; 
	ptt = .; 
	grp1 = %eval(&none1.); 
	grp2 = %eval(&none2.); 
	grp3 = %eval(&none3.); 
run; 

%pt(atone); 


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

** use macro to count; 
%catstat2(indsn=cm, outdsn=cntptt, grp=treatment, var=ptt); 

%pt(cntptt); 


data out;
	format col1 col2 col3 $15.; 
	set atone
		cntptt; 
	col1 	= strip(put(grp1, 4.0)) || " (" || strip(put( grp1/%eval(&num1), percent8.1)) || ")"; 
	col2 	= strip(put(grp2, 4.0)) || " (" || strip(put( grp2/%eval(&num2), percent8.1)) || ")"; 
	col3 	= strip(put(grp3, 4.0)) || " (" || strip(put( grp3/%eval(&num3), percent8.1)) || ")"; 
	drop grp1 grp2 grp3; 
run; 

%pt(out); 

proc sort data = out out = outsort; 
	by ptt; 
run; 

%pt(outsort); 

data final; 
	format ptterm listf $48.; 
	set outsort; 

	if missing(ptt) then listf = "Subjects with at Least One Con Med"; 
	else listf = "    " || put(ptt, pttf.); 

	mypage 		= ceil(_n_/13); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	output; 
	if _n_ = 1 then do; 
		listf = "Therapeutic Sublevel"; 
		col1 = " "; 
		col2 = " "; 
		col3 = " "; 
		output; 
	end; 
	drop soct ptterm ptt; 
run; 

%pt(final); 



*--------------------------------------------*;
* report general mh; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = CM; 
%let tableno = Table 4; 
%let title = Concomitant Mediations by WHO Drug Class and Preferred Term; 
%let population = Safety Population; 
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

** ps : Specify the number of lines in a page of the report; 
** ls : Specify the length of a line of the report.; 
options ps=77 ls=100 nonumber orientation=landscape; 

** output to rtf; 
ods rtf file="&oDir\&task._%now(fmt=b8601dt).rtf" style=panda;

** Nowindows tells PROC REPORT not to go into interactive mode; 
** Missing tells SAS not to silently delete observations with missing values in their classification variables.; 
** Headline tells PROC REPORT to print an underline below the column headers. ; 
** Headskip tells PROC REPORT to skip a line after the header.; 
proc report data = final nowindows missing headline headskip split="|" 
													style(header)={just=l}
													style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline listf col1 col2 col3; 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;

	** Display the values; 
	define listf		/"Preferred Term" 			style=[asis=on cellwidth=3in];
	define col1		   /"AA		 | N=&num1"			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col2		  /"Placebo  | N=&num2" 		style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col3		 /"Total     | N=&num3" 		style=[just=c rightmargin=0.2in cellwidth=1.2in];

	break after mypage	/	page;	

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;
run; 

ods rtf close;


