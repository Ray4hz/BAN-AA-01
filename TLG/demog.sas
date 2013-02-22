/*====================================================================
| COMPANY           Bancova LLC
| PROJECT:          BAN-AA-01
| PROGRAM:          demog.sas
| PROGRAMMER(S):    Ray
| DATE:             
| PURPOSE:          Generate demographics table
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
	invalue namef	
		"age"			= 1
		"eth"			= 2
		"rac"			= 3
		; 
	invalue agein
    	"age"  			= 1
		"_mean"			= 2
		"_std"			= 3
		"_median"		= 4
		"_range"		= 5
		"_n"			= 6
		"_min"			= 7
		"_max"			= 8
		low - 17,
    	100 - high  	= 99
		;
	value agef
		1 	= 'Age (years)'
		2 	= '    Mean'
		3 	= '    SD'
		4	= '    Median'
		5	= '    Range'
		6	= '    N'	
		; 
	invalue ethin
		"eth"						= 1
		"Hispanic or Latino" 		= 2
		"Not Hispanic or Latino" 	= 3
		"Other" 					= 4
		other						= 99
		; 
	value ethf
		1 	= 'Ethnicity, n(%)'
		2 	= '    Hispanic'
		3 	= '    Non-Hispanic'
		4 	= '    Other'
		; 
	invalue racin
		"rac"										= 1
		"White" 									= 2
		"Black"     								= 4
		"Asian"    									= 5
    	"American Indian or Alaska Native" 			= 6
		"Native Hawaiian or other Pacific Islande"  = 7 /* It should be Islander,beyong 40 bytes */
		"Other"     								= 8
		other										= 99
 		;
	value racf
		1 	= 'Race, n(%)'
		2 	= '    Caucasian (White)'
		3 	= '    Non-Caucasian'
		4 	= '        Black or African American'
		5 	= '        Asian'
		6 	= '        American Indian or Alaska Native'
		7 	= '        Native Hawaiian or Other Pacific Islander'
		8 	= '        Other'
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
** import demographics data, stractification factors for p-value calculation; 
**** ECOG(ECOG status): 1 = "0 or 1", 2 = "2";     
**** PAIN: 1 = "Present", 2 = "Absent"; 
**** CHEMO(Number of prior cytotoxic chemotherapy): 1 = "1", 2 = "2"; 
**** DPSA(Evidence of disease progression): 1 = "PSA only", 2 = "Radiographic progression with or without PSA progression"; 
proc import 	datafile = "&dDir\demog\demog.xls"
				out 	 = raw
				dbms 	 = xls replace; 
	sheet 		= "demog";
	getnames 	= yes;  
run; 

** %look(raw); 
%ppt(raw); 



*--------------------------------------------*;
* derive demog data
* select ITT patients
* rule 1: analysis variables must be numeric
* rule 2: date must be sas dates
*--------------------------------------------*;
data out.drdm;   
	format usubjid treatment ITT SAFETY age eth rac ECOG PAIN CHEMO DPSA; 
	set raw; 

	date2 	= input( put(dtconsent, z8.), yymmdd8.); 
	date1 	= input(dtbirth, yymmdd8.); 
	age 	= (date2 - date1 + 1) / 365.25; 

	eth 	= input(strip(ethnic), ethin.); 
	rac 	= input(strip(race), racin.); 

	** select ITT patients; 
	if ITT 	= 1; 

	label 	age 	= "Age (yr)"
			eth 	= "Ethnicity"
			rac 	= "Race"; 	
	keep usubjid treatment ITT SAFETY age eth rac ECOG PAIN CHEMO DPSA;
run;

proc sort data = out.drdm out = demog; 
	by usubjid; 
run; 

%ppt(demog); 

** quick check the values of each categorical variable; 
%macro frqtab(ids=, tabvar=);
  proc freq %if &ids ne %then %do;
                  data = &ids
			%end;;
       tables &tabvar / list missing nopercent;
  run;
%mend;

%frqtab(ids = demog, tabvar= eth rac ITT*treatment ITT*SAFETY);



*--------------------------------------------*;
* QC
* rule 1: check all duplicates and report them
* rule 2: check all missing values and report them
* rule 3: check all illogic data and report them
*--------------------------------------------*;
** check duplicates; 
data demog dmdupes; 
	set demog; 
	by usubjid; 
	if not (first.usubjid and last.usubjid) then output dmdupes; 
	if last.usubjid then output demog; 
run; 

%pt(dmdupes); 
* no duplicates; 

** check illogic data with demogDiag; 
data demogDiag;
	set demog;
  	diag = ( max( age, ethnic1, race1 )  >= 99 );
run;

proc print data = demogDiag; 
	where diag = 1; 
run; 
* no abnormal values; 

** check missing; 
data missing; 
	set demog; 
	array check{8} treatment age eth rac ECOG PAIN CHEMO DPSA; 
	do i = 1 to 8; 
		if check{i} < . then output missing; 
	end; 
	drop i; 
run; 

%pt(missing); 
* no missing; 



*--------------------------------------------*;
* calculate the p-value; 
*--------------------------------------------*;
** stractification factors are combined together into stractum variable; 
data getp; 
	set demog; 
	if ECOG = 1 and PAIN = 1 and CHEMO = 1 and DPSA = 1 then stractum = 1111; 
	if ECOG = 2 and PAIN = 1 and CHEMO = 1 and DPSA = 1 then stractum = 2111; 
	if ECOG = 1 and PAIN = 2 and CHEMO = 1 and DPSA = 1 then stractum = 1211; 
	if ECOG = 1 and PAIN = 1 and CHEMO = 2 and DPSA = 1 then stractum = 1121; 
	if ECOG = 1 and PAIN = 1 and CHEMO = 1 and DPSA = 2 then stractum = 1112; 
	if ECOG = 2 and PAIN = 2 and CHEMO = 1 and DPSA = 1 then stractum = 2211; 
	if ECOG = 2 and PAIN = 1 and CHEMO = 2 and DPSA = 1 then stractum = 2121; 
	if ECOG = 2 and PAIN = 1 and CHEMO = 1 and DPSA = 2 then stractum = 2112; 
	if ECOG = 1 and PAIN = 2 and CHEMO = 1 and DPSA = 2 then stractum = 1212; 
	if ECOG = 1 and PAIN = 1 and CHEMO = 2 and DPSA = 2 then stractum = 1122; 
	if ECOG = 1 and PAIN = 2 and CHEMO = 2 and DPSA = 1 then stractum = 1221; 
	if ECOG = 2 and PAIN = 2 and CHEMO = 2 and DPSA = 1 then stractum = 2221; 
	if ECOG = 2 and PAIN = 2 and CHEMO = 1 and DPSA = 2 then stractum = 2212; 
	if ECOG = 2 and PAIN = 1 and CHEMO = 2 and DPSA = 2 then stractum = 2122; 
	if ECOG = 1 and PAIN = 2 and CHEMO = 2 and DPSA = 2 then stractum = 1222; 
	if ECOG = 2 and PAIN = 2 and CHEMO = 2 and DPSA = 2 then stractum = 2222; 
	keep usubjid treatment age eth rac stractum; 
run; 

** check which ods table to be used; 
ods trace on; 
proc glm data = getp; 
	class stractum treatment; 
	model age = stractum | treatment;
run; 
quit; 
ods trace off; 

** select the table for p-value; 
ods output OverallANOVA = work.ageout ; 
proc glm data = getp; 
	class stractum treatment; 
	model age = stractum | treatment;
run; 
quit; 
ods output close; 

** put p-value into a macro variable; 
data _null_; 
	set ageout; 
	if _n_ = 1 then do; 
		call symput('agepval', put(ProbF, pvalue6.4)); 
	end; 
run; 

%put &agepval; 
* 0.8528; 

** generate p-value for categorical variable ethnicity by CMH test; 
** P_CMHGA	: the general association statistic treats both variables as nominal and thus has df = (I -1)×(J -1); 
** P_CMHRMS : the row mean scores differ statistic treats the row variable as nominal and column variable as ordinal, and has df = I - 1; 
** P_CMHCOR	: the nonzero correlation statistic treats both variables as ordinal, and df = 1; 
** cmh test on ethnicity (ordinal); 
proc freq data = getp; 
	tables stractum*treatment*eth / CMH nopercent nocol;
	output out = ethcmh (keep = P_CMHRMS) cmh; 
run; 

%pt(ethcmh); 
* 0.0069; 

** put pvalue into a macro variable; 
data _null_; 
	set ethcmh; 
	call symput('ethpval', put(P_CMHRMS, pvalue6.4)); 
run; 

** cmh test on race (ordinal); 
proc freq data = getp; 
	tables stractum*rac / CMH nopercent nocol; 
	output out = raccmh (keep = P_CMHRMS) cmh; 
run; 

%pt(raccmh); 
data _null_; 
	set raccmh; 
	call symput('racpval', put(P_CMHRMS, pvalue6.4)); 
run; 

%put &racpval; 
* 0.94638; 



*--------------------------------------------*;
* calculate the counts # for each group; 
*--------------------------------------------*;
** keep the analysis variables age, ethnicity and race; 
** create the treatment = 3 for calculating the total; 
data dm1; 
	set demog; 
	output; 
	treatment = 3; 
	output; 
	keep usubjid treatment age eth rac; 
run; 

proc sort data = dm1 out = dm2; 
	by treatment usubjid; 
run; 
 
proc sql noprint; 
	select strip(put(count(treatment), best.)) into :num1- :num3 from dm2 group by treatment; 
quit; 

%put &num1; ** 797; 
%put &num2; ** 398; 
%put &num3; ** 1195; 



*--------------------------------------------*;
* continuous variables : age
*--------------------------------------------*;
** macro to prepare the continuous variables; 

%macro num(indsn=, outdsn=, var=, group=, namef=); 
** subset for each section; 
data sub&var.; 
	set &indsn.; 
	where &var. < 99; 
run; 

proc univariate data = sub&var. noprint; 
	var &var.; 
	by &group.; 
	output out = uni&var. n=n mean=mean median=median std=std min=min max=max;
run; 

data uni&var.; 
	keep treatment _mean _std _median _range _n _min _max; 
	set uni&var.; 
	_mean 	= strip(put(mean, 4.1)); 
	_std 	= strip(put(std, 4.2)); 
	_median = strip(put(median, 4.1)); 
	_range 	= "("|| strip(put(min,4.1)) ||", "|| strip(put(max,4.1)) ||")"; 
	_n 		= strip(put(n, 4.1)); 
	_min 	= strip(put(min, 4.1)); 
	_max	= strip(put(max, 4.1)); 
run; 

proc transpose data = uni&var. out = new&var.; 
	var _mean _std _median _range _n _min _max; 
	id &group.; 
run; 

data &outdsn. (drop =_name_ _1 _2 _3); 
	set new&var.;
	col1 = _1; 
	col2 = _2; 
	col3 = _3; 
	name = "&var."; 
	cat  = input(strip(name), &namef..); 
	list = input(strip(_name_), &var.in.); 
	drop name; 
run;
%mend; 

%num(indsn=dm2, outdsn=out1, var=age, group=treatment, namef=namef); 

%pt(out1); 

** keep only the neccessary list for report; 
data out1; 
	set out1; 
	if list < 7; 
run; 

%pt(out1); 



*--------------------------------------------*;
* categorical: ethnic, race
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

** use macro to count; 
** eth; 
%catstat2(indsn=dm2, outdsn=cnteth, grp=treatment, var=eth); 

%pt(cnteth); 

data out2; 
	set cnteth; 
	cat = 2; 
	list = eth; 
	drop eth; 
run; 

%pt(out2); 

** rac; 
%catstat2(indsn=dm2, outdsn=cntrac, grp=treatment, var=rac); 

%pt(cntrac); 

** count the sum for non-caucasian group; 
proc sql; 
	create table noncau as
	select 	3 as rac, 
			sum(grp1) as grp1, 
			sum(grp2) as grp2, 
			sum(grp3) as grp3
	from (select * from cntrac where rac ^= 2); 
quit; 

%pt(noncau); 

data cntrac2; 
	set noncau
		cntrac; 
run; 

proc sort data = cntrac2; 
	by rac; 
run; 

%pt(cntrac2); 

data out3; 
	set cntrac2; 
	cat = 3; 
	list = rac; 
	drop rac; 
run; 

%pt(out3); 

data outcat; 
	set out2
		out3; 
	col1 	= strip(put(grp1, 4.0)) || " (" || strip(put( grp1/%eval(&num1), percent8.1)) || ")"; 
	col2 	= strip(put(grp2, 4.0)) || " (" || strip(put( grp2/%eval(&num2), percent8.1)) || ")"; 
	col3 	= strip(put(grp3, 4.0)) || " (" || strip(put( grp3/%eval(&num3), percent8.1)) || ")"; 
	drop grp1 grp2 grp3; 
run; 

data temp; 
	set out1
		outcat; 
run; 

%pt(temp); 




*--------------------------------------------*;
* prepare the final dataset for report; 
*--------------------------------------------*;
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

%dum(outdsn=dum, ncat=3, catlist=6 4 8, ngrp=4); 


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
		end as col3, 
		a.grp4 as pval
	from dum as a
		left join 
			temp as b
		on 	a.cat = b.cat and 
			a.list = b.list; 
quit; 

data out; 
	format col1 col2 col3 $15. pval $6.; 
	format listf $50.; 
	set out; 
	if cat = 1 and list = 1 then pval = "&agepval."; 
	if cat = 2 and list = 1 then pval = "&ethpval."; 
	if cat = 3 and list = 1 then pval = "&racpval."; 
	if 		cat = 1 and list in (1:6) then listf = put(list, agef.); 
	else if cat = 2 and list in (1:4) then listf = put(list, ethf.); 
	else if cat = 3 and list in (1:8) then listf = put(list, racf.); 
	else listf = " "; 
run; 

%pt(out); 

** final dataset with index for page, footnote, bottomline; 
data final;
    set out;
	if missing(listf) = 0; 
	mypage 		= ceil(_n_/10); ** set up lines to break pages; 
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

%let task = Demographics; 
%let tableno = Table 2; 
%let title = Demographics; 
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

** ps : Specify the number of lines in a page of the report; 
** ls : Specify the length of a line of the report.; 
options ps=77 ls=100 nonumber orientation=landscape; 

** output to rtf; 
ods rtf file="&oDir\&task._%now(fmt=b8601dt).rtf" style=panda;

** Nowindows tells PROC REPORT not to go into interactive mode; 
** Missing tells SAS not to silently delete observations with missing values in their classification variables.; 
** Headline tells PROC REPORT to print an underline below the column headers. ; 
** Headskip tells PROC REPORT to skip a line after the header.; 
proc report data = final nowindows missing headline headskip split="/" 
													style(header)={just=l}
													style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline cat listf col1 col2 col3 pval; 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;

	** Group to cosolidate observations; 
	define cat		/ order noprint; 

	** Display the values; 
	define listf		/"Demographics Parameter" 	style=[asis=on cellwidth=3in];
	define col1		   /"AA		 / N=&num1"			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col2		  /"Placebo	/ N=&num2" 			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col3		 /"Total   / N=&num3" 			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define pval	    /"P-value" 						style=[just=c rightmargin=0.2in cellwidth=1.2in];

	break after mypage	/	page;	

	compute before cat;
		line " "; 
	endcomp;

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes:"; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Age = (Date of informed consent – date of birth + 1)/365.25."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab P-values for continuous variables (age) are from an GLM model with treatment group and stratification factors as factors; p-values for"; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} categorical variables (ethnicity and race) are from a CMH test controlling for stratification factors."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab SD = Standard Deviation, Min = minimum, and Max = maximum."; 
	endcomp;
run; 

ods rtf close;

