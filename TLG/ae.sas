/*====================================================================
| COMPANY           Bancova LLC
| PROJECT:          BAN-AA-01
| PROGRAM:          ae.sas
| PROGRAMMER(S):    Ray
| DATE:             
| PURPOSE:          Generate ae table
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
	invalue socin
		"Cardiac Disorders" 								= 1
		"Gastrointestinal Disorders"						= 2
		"General Disorders"									= 3
		"Infections and Infestations"					 	= 4
		"Musculoskeletal and Connective Tissue Disorders" 	= 5
		"Renal and Urinary Disorders"						= 6
		"Respiratory, Thoracic and Mediastinal Disorders" 	= 7
		"Vascular Disorders"								= 8
		" "													= 99
		other 												= 100
		; 
	value socf
		1	= "Cardiac Disorders" 								
		2	= "Gastrointestinal Disorders"						
		3	= "General Disorders"									
		4	= "Infections and Infestations"					 	
		5	= "Musculoskeletal and Connective Tissue Disorders" 
		6	= "Renal and Urinary Disorders"						
		7	= "Respiratory, Thoracic and Mediastinal Disorders" 	
		8	= "Vascular Disorders"		
		other = " "	
		; 	
	invalue pttin
		"Arrhythmia"								= 1
		"Treatment Discontinued"					= 2
		"Cardiac Failure"							= 3
		"Chest Pain or Chest Discomfort"			= 4
		"Cough"										= 5
		"Diarrhea"									= 6
		"Dysperpsia"								= 7
		"Edema"										= 8
		"Hot Flush"									= 9
		"Hypertension"								= 10
		"Joint Swelling/ Discomfort"				= 11
		"Muscle Discomfort"							= 12
		"Nocturia"									= 13
		"Upper Respiratory Tract Infection"			= 14
		"Urinary Frequency"							= 15
		"Urinary Tract Infection"					= 16
		" "											= 99
		other 										= 100
		; 
	value pttf
		1	= "Arrhythmia"								
		2	= "Treatment Discontinued"					
		3	= "Cardiac Failure"							
		4	= "Chest Pain or Chest Discomfort"			
		5	= "Cough"										
		6	= "Diarrhea"									
		7	= "Dysperpsia"								
		8	= "Edema"										
		9	= "Hot Flush"									
		10	= "Hypertension"								
		11	= "Joint Swelling/ Discomfort"				
		12	= "Muscle Discomfort"							
		13	= "Nocturia"									
		14	= "Upper Respiratory Tract Infection"			
		15	= "Urinary Frequency"							
		16	= "Urinary Tract Infection"		
		other = " "	
		; 	
	invalue sevin
		"MILD"		= 1
		"MODERATE" 	= 2
		"SEVERE"	= 3
		" "			= 99
		other  		= 100
		; 
	invalue relin
		"POSSIBLE"  = 1
		"RELATED"	= 2
		"UNLIKELY"	= 3
		" "			= 99
		other		= 100
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
proc import 	datafile = "&dDir\ae\ae.xls"
				out 	 = rawae
				dbms 	 = xls replace; 
	sheet 		= "ae";
	getnames 	= yes;  
run;  

%ppt(rawae); 

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
	create table ae1 as
	select strip(a.USUBJID) as usubjid, strip(a.AETERM) as ptterm, strip(a.AEBODSYS) as soct, strip(a.AESEV) as seve, strip(a.AEREL) as rela, a.RFSTDTC as rfstdt, a.RFENDTC as rfendt, a.AESTDTC as aestdt, a.AEENDTC as aeendt, b.treatment, b.SAFETY
		from rawae as a
			left join
				rawdm as b
			on a.USUBJID = b.usubjid and b.SAFETY = 1;
quit; 

%ppt(ae1); 

** remove missing data for the system organ class; 
data ae2; 
	set ae1; 
	where missing(soct) = 0; 
	output; 
run; 

data ae3; 
	set ae2; 
	soc = input(strip(soct), socin.); 
	ptt = input(strip(ptterm), pttin.); 
	sev = input(strip(seve), sevin.); 
	rel = input(strip(rela), relin.); 
run; 



*--------------------------------------------*;
* QC
* rule 1: check all missing values and report them
* rule 2: check all illogic data and report them
*--------------------------------------------*;
** check illogic and missing data; 
data aeDiag; 
	set ae3; 
	** any index greater than 0 will make diag = 1; 
	diag = ( max( soc, ptt, sev, rel ) > 99 ) ; 

run; 

proc print data = aeDiag; 
	where diag = 1; 
run; 
* no illogic data; 



*--------------------------------------------*;
* select qualified TEAE in two cases; 
* 1. After the subject was administered IP; 
* 		 < 30 days after the last IP; 
* 		put into : after_teae; 
* 		other    : after_noae; 
* 2. Before the subject was administered IP; 
*        increase severity; 
*		put into : before_teae; 
* 		other 	 : before_noae; 
*--------------------------------------------*;
** devide the data set into dsn; 
data before_sev before_noae after_teae after_noae; 
	set ae3; 
	if aestdt < rfstdt then do; 
		if aeendt >= rfstdt then output before_sev; 
		else output before_noae; 
	end; 
	else if aestdt >= rfstdt then do; 
		if ((aeendt - rfendt) < 30) then output after_teae; 
		else output after_noae; 
	end; 
run; 

%pt(ae3); ** 2048 obs; 
%pt(before_sev); ** 158 obs; 
%pt(before_noae); ** 312 obs; 
%pt(after_teae); ** 1578 osb;
%pt(after_noae); ** no obs; 

** compare = after.severity - before.severity; 
proc sql; 
	create table checksev as
	select a.*, (b.sev-a.sev) as compare
	from before_sev as a
		left join 
			after_teae as b
		on 	a.usubjid = b.usubjid 		and   
			a.treatment = b.treatment 	and
			a.soc = b.soc 				and
			a.ptt = b.ptt
		order by a.treatment, a.soc, a.ptt, a.usubjid; 
quit; 

data before_teae; 
	set checksev; 
	if missing(compare) = 0; 
	drop compare; 
run; 

%pt(before_teae); ** 1 obs; 

data teae; 
	set before_teae
		after_teae; 
run; 

%pt(teae); ** 1579 obs; 



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
data ae; 
	set teae; 
	output; 
	treatment = 3; 
	output; 
run; 

** patients with at least one AE; 
proc sql noprint; 
	select count(distinct usubjid) into: none1 - : none3 from ae group by treatment; 
quit; 

%put &none1.; ** 600; 
%put &none2.; ** 199; 
%put &none3.; ** 799; 

data atone; 
	soc = .; 
	ptt = .; 
	grp1 = %eval(&none1.); 
	grp2 = %eval(&none2.); 
	grp3 = %eval(&none3.); 
run; 

%pt(atone); 

** by severity; 
proc sql; 
	select count(distinct usubjid) into: none_sev_1_1 - : none_sev_1_3
	from (select * from ae where treatment = 1) group by sev; 
	select count(distinct usubjid) into: none_sev_2_1 - : none_sev_2_3
	from (select * from ae where treatment = 2) group by sev; 
	select count(distinct usubjid) into: none_sev_3_1 - : none_sev_3_3
	from (select * from ae where treatment = 3) group by sev; 
run; 
data atone_sev; 
	soc = .; 
	ptt = .; 
	grp1_v1 = %eval(&none_sev_1_1.); 
	grp1_v2 = %eval(&none_sev_1_2.); 
	grp1_v3 = %eval(&none_sev_1_3.); 
	grp2_v1 = %eval(&none_sev_2_1.); 
	grp2_v2 = %eval(&none_sev_2_2.); 
	grp2_v3 = %eval(&none_sev_2_3.); 
	grp3_v1 = %eval(&none_sev_3_1.); 
	grp3_v2 = %eval(&none_sev_3_2.); 
	grp3_v3 = %eval(&none_sev_3_3.); 
run; 

%pt(atone_sev); 


** by relation; 
proc sql; 
	select count(distinct usubjid) into: none_rel_1_1 - : none_rel_1_3
	from (select * from ae where treatment = 1) group by rel; 
	select count(distinct usubjid) into: none_rel_2_1 - : none_rel_2_3
	from (select * from ae where treatment = 2) group by rel; 
	select count(distinct usubjid) into: none_rel_3_1 - : none_rel_3_3
	from (select * from ae where treatment = 3) group by rel; 
run; 
data atone_rel; 
	soc = .; 
	ptt = .; 
	grp1_v1 = %eval(&none_rel_1_1.); 
	grp1_v2 = %eval(&none_rel_1_2.); 
	grp1_v3 = %eval(&none_rel_1_3.); 
	grp2_v1 = %eval(&none_rel_2_1.); 
	grp2_v2 = %eval(&none_rel_2_2.); 
	grp2_v3 = %eval(&none_rel_2_3.); 
	grp3_v1 = %eval(&none_rel_3_1.); 
	grp3_v2 = %eval(&none_rel_3_2.); 
	grp3_v3 = %eval(&none_rel_3_3.); 
run; 

%pt(atone_rel); 

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
%catstat2(indsn=ae, outdsn=cntptt, grp=treatment, var=soc ptt); 

%pt(cntptt); 

%catstat2(indsn=ae, outdsn=cntsoc, grp=treatment, var=soc); 

%pt(cntsoc); 

data out;
	format col1 col2 col3 $15.; 
	set atone
		cntsoc
		cntptt; 
	col1 	= strip(put(grp1, 4.0)) || " (" || strip(put( grp1/%eval(&num1), percent8.1)) || ")"; 
	col2 	= strip(put(grp2, 4.0)) || " (" || strip(put( grp2/%eval(&num2), percent8.1)) || ")"; 
	col3 	= strip(put(grp3, 4.0)) || " (" || strip(put( grp3/%eval(&num3), percent8.1)) || ")"; 
	drop grp1 grp2 grp3; 
run; 

%pt(out); 

proc sort data = out out = outsort; 
	by soc ptt; 
run; 

%pt(outsort); 

data final; 
	format soct ptterm listf $48.; 
	set outsort; 
	if missing(soc) then soct = "Patients with at least one AE"; 
	else soct = put(soc, socf.); 

	if missing(ptt) then ptterm = " "; 
	else ptterm = put(ptt, pttf.); 

	if missing(ptt) then listf = soct; 
	else listf = "    " || ptterm; 

	mypage 		= ceil(_n_/13); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	drop soct ptterm ptt; 
run; 

%pt(final); 

** AE by severity; 
%catstat2(indsn=ae, outdsn=cntsev, grp=treatment, var=soc ptt sev, transpose=lastsev); 

%pt(lastsev); 

proc sql; 
	create table sevsum as
	select 	soc, . as ptt, 
			sum(grp1_v1) as grp1_v1, 
			sum(grp1_v2) as grp1_v2, 
			sum(grp1_v3) as grp1_v3,
			sum(grp2_v1) as grp2_v1,
			sum(grp2_v2) as grp2_v2,
			sum(grp2_v3) as grp2_v3,
			sum(grp3_v1) as grp3_v1,
			sum(grp3_v2) as grp3_v2,
			sum(grp3_v3) as grp3_v3
	from lastsev
	group by soc; 
quit; 

%pt(sevsum); 

data out1; 
	format col1 col2 col3 col4 col5 col6 col7 col8 col9 $15.; 
	set atone_sev
		sevsum
		lastsev; 
	col1 	= strip(put(grp1_v1, 4.0)) || " (" || strip(put( grp1_v1/%eval(&num1), percent8.1)) || ")"; 
	col2 	= strip(put(grp1_v2, 4.0)) || " (" || strip(put( grp1_v2/%eval(&num2), percent8.1)) || ")"; 
	col3 	= strip(put(grp1_v3, 4.0)) || " (" || strip(put( grp1_v3/%eval(&num3), percent8.1)) || ")"; 
	col4 	= strip(put(grp2_v1, 4.0)) || " (" || strip(put( grp2_v1/%eval(&num3), percent8.1)) || ")"; 
	col5 	= strip(put(grp2_v2, 4.0)) || " (" || strip(put( grp2_v2/%eval(&num3), percent8.1)) || ")"; 
	col6 	= strip(put(grp2_v3, 4.0)) || " (" || strip(put( grp2_v3/%eval(&num3), percent8.1)) || ")"; 
	col7 	= strip(put(grp3_v1, 4.0)) || " (" || strip(put( grp3_v1/%eval(&num3), percent8.1)) || ")"; 
	col8 	= strip(put(grp3_v2, 4.0)) || " (" || strip(put( grp3_v2/%eval(&num3), percent8.1)) || ")"; 
	col9 	= strip(put(grp3_v3, 4.0)) || " (" || strip(put( grp3_v3/%eval(&num3), percent8.1)) || ")"; 
	drop grp1_v1  grp1_v2  grp1_v3  grp2_v1  grp2_v2  grp2_v3  grp3_v1  grp3_v2  grp3_v3; 
run; 

%pt(out1); 

proc sort data = out1 out = out1sort; 
	by soc ptt; 
run; 

data final1; 
	format soct ptterm listf $48.; 
	set out1sort; 
	if missing(soc) then soct = "Patients with at least one AE"; 
	else soct = put(soc, socf.); 

	if missing(ptt) then ptterm = " "; 
	else ptterm = put(ptt, pttf.); 

	if missing(ptt) then listf = soct; 
	else listf = "    " || ptterm; 

	mypage 		= ceil(_n_/11); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	drop soct ptterm ptt; 
run; 

%pt(final1); 



** AE by relation; 
%catstat2(indsn=ae, outdsn=cntrel, grp=treatment, var=soc ptt rel, transpose=lastrel); 

%pt(lastrel); 

proc sql; 
	create table relsum as
	select 	soc, . as ptt, 
			sum(grp1_v1) as grp1_v1, 
			sum(grp1_v2) as grp1_v2, 
			sum(grp1_v3) as grp1_v3,
			sum(grp2_v1) as grp2_v1,
			sum(grp2_v2) as grp2_v2,
			sum(grp2_v3) as grp2_v3,
			sum(grp3_v1) as grp3_v1,
			sum(grp3_v2) as grp3_v2,
			sum(grp3_v3) as grp3_v3
	from lastrel
	group by soc; 
quit; 

%pt(relsum); 

data out2; 
	format col1 col2 col3 col4 col5 col6 col7 col8 col9 $15.; 
	set atone_rel
		relsum
		lastrel; 
	col1 	= strip(put(grp1_v1, 4.0)) || " (" || strip(put( grp1_v1/%eval(&num1), percent8.1)) || ")"; 
	col2 	= strip(put(grp1_v2, 4.0)) || " (" || strip(put( grp1_v2/%eval(&num2), percent8.1)) || ")"; 
	col3 	= strip(put(grp1_v3, 4.0)) || " (" || strip(put( grp1_v3/%eval(&num3), percent8.1)) || ")"; 
	col4 	= strip(put(grp2_v1, 4.0)) || " (" || strip(put( grp2_v1/%eval(&num3), percent8.1)) || ")"; 
	col5 	= strip(put(grp2_v2, 4.0)) || " (" || strip(put( grp2_v2/%eval(&num3), percent8.1)) || ")"; 
	col6 	= strip(put(grp2_v3, 4.0)) || " (" || strip(put( grp2_v3/%eval(&num3), percent8.1)) || ")"; 
	col7 	= strip(put(grp3_v1, 4.0)) || " (" || strip(put( grp3_v1/%eval(&num3), percent8.1)) || ")"; 
	col8 	= strip(put(grp3_v2, 4.0)) || " (" || strip(put( grp3_v2/%eval(&num3), percent8.1)) || ")"; 
	col9 	= strip(put(grp3_v3, 4.0)) || " (" || strip(put( grp3_v3/%eval(&num3), percent8.1)) || ")"; 
	drop grp1_v1  grp1_v2  grp1_v3  grp2_v1  grp2_v2  grp2_v3  grp3_v1  grp3_v2  grp3_v3; 
run; 

proc sort data = out2 out = out2sort; 
	by soc ptt; 
run; 

data final2; 
	format soct ptterm listf $48.; 
	set out2sort; 
	if missing(soc) then soct = "Patients with at least one AE"; 
	else soct = put(soc, socf.); 

	if missing(ptt) then ptterm = " "; 
	else ptterm = put(ptt, pttf.); 

	if missing(ptt) then listf = soct; 
	else listf = "    " || ptterm; 

	mypage 		= ceil(_n_/11); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	drop soct ptterm ptt; 
run; 

%pt(final2); 




*--------------------------------------------*;
* report general AE; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = AE; 
%let tableno = Table 9; 
%let title = Incidence of Adverse Events by Treatment Group, System Organ Class, and Preferred Term during the Treatment Period; 
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
	column mypage footnote bottomline soc listf col1 col2 col3; 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;
	define soc 		 / order noprint; 

	** Display the values; 
	define listf		/"System Organ Class/ |    Preferred Term" 	style=[asis=on cellwidth=3in];
	define col1		   /"AA		 | N=&num1"			style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col2		  /"Placebo  | N=&num2" 		style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col3		 /"Total     | N=&num3" 		style=[just=c rightmargin=0.2in cellwidth=1.2in];

	break after mypage	/	page;	

	compute before soc; 
		line " "; 
	endcomp; 

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes:   Version 11.1, or newer, of MedDRA was used to code adverse events."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab n = Number of patients with adverse events during the treatment period."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Patients are counted only once within each system organ class and preferred term."; 
	endcomp;
run; 

ods rtf close;




*--------------------------------------------*;
* report AE by severity; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = AE_Severity; 
%let tableno = Table 10; 
%let title = Incidence of Adverse Events by Treatment Group, System Organ Class, Preferred Term, and Severity during the Treatment Period; 
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
proc report data = final1 nowindows missing headline headskip split="|" 
													style(header)={just=l}
													style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline soc 
		("^S={ just=l }System Organ Class/ ^n ^S={ just=l }     Preferred Term" listf)
		("^S={ just=c borderbottomcolor=black }AA      |^S={ just=c borderbottomcolor=black borderbottomwidth=2}N=&num1." col1 col2 col3) 
		("^S={ just=c borderbottomcolor=black }Placebo |^S={ just=c borderbottomcolor=black borderbottomwidth=2}N=&num2." col4 col5 col6); 
	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;
	define soc 		 / order noprint; 

	** Display the values; 
	define listf	 /" " 							style=[asis=on cellwidth=3in];
	define col1		 /"Mild		| n (%)"			style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col2		 /"Moderate	| n (%)" 			style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col3		 /"Severe	| n (%)" 			style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col4		 /"Mild		| n (%)"			style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col5		 /"Moderate	| n (%)" 			style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col6		 /"Severe	| n (%)" 			style=[just=c rightmargin=0.1in cellwidth = 10%];

	break after mypage	/	page;	

	compute before soc; 
		line " "; 
	endcomp; 

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes:   Version 11.1, or newer, of MedDRA was used to code adverse events."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Imputed severity is used if the severity is missing."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab n = Number of patients with adverse events during the treatment period."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab If a patient had more than one occurrence in the same event category, only the most severe occurrence was counted."; 
	endcomp;
run; 

ods rtf close;




*--------------------------------------------*;
* report AE by relation; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = AE_Relation; 
%let tableno = Table 11; 
%let title = Incidence of Adverse Events by Treatment Group, System Organ Class, Preferred Term, and Relationship to the IP during the Treatment Period; 
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
proc report data = final2 nowindows missing headline headskip split="|" 
													style(header)={just=l}
													style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline soc 
		("^S={ just=l }System Organ Class/ ^n ^S={ just=l }     Preferred Term" listf)
		("^S={ just=c borderbottomcolor=black }AA      |^S={ just=c borderbottomcolor=black borderbottomwidth=2}N=&num1." col1 col2 col3) 
		("^S={ just=c borderbottomcolor=black }Placebo |^S={ just=c borderbottomcolor=black borderbottomwidth=2}N=&num2." col4 col5 col6); 
	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;
	define soc 		 / order noprint; 

	** Display the values; 
	define listf	 /" " 							style=[asis=on cellwidth=3in];
	define col1		 /"None			| n (%)"		style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col2		 /"Possible		| n (%)" 		style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col3		 /"Very likely	| n (%)" 		style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col4		 /"None			| n (%)"		style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col5		 /"Possible		| n (%)" 		style=[just=c rightmargin=0.1in cellwidth = 10%];
	define col6		 /"Very likely	| n (%)" 		style=[just=c rightmargin=0.1in cellwidth = 10%];

	break after mypage	/	page;	

	compute before soc; 
		line " "; 
	endcomp; 

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes:   Version 11.1, or newer, of MedDRA was used to code adverse events."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Imputed relationship to IP is used if the severity is missing."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab n = Number of patients with the specified relationship."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab If a patient had more than one occurrence in the same event category, only the most severe occurrence was counted."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Relationship to IP: None = drug did not cause AE; Possible = drug possibly caused AE; Very likely = drug very likely caused AE"; 
	endcomp;
run; 

ods rtf close;





*--------------------------------------------*;
* Example for %catstat
*--------------------------------------------*;
data in; 
	infile datalines; 
	input id grp var1 var2 var3; 
datalines; 
101 2 2 1 2
102 2 2 1 2
103 1 1 2 4
104 3 1 1 1
105 3 1 1 1
106 1 2 3 3
107 2 1 2 4
108 3 1 2 1
109 3 2 2 2
110 2 2 3 3
;
run; 
 
%pt(in); 

** common method; 
proc freq data = in; 
	table var1*grp; 
run; 

%catstat2(indsn=in, outdsn=var1, 	grp=grp, var=var1);
 
%pt(var1); 

%catstat2(indsn=in, outdsn=var1var2var3, grp=grp, var=var1 var2 var3, transpose=last); 

%pt(var1var2var3); 

%pt(last); 
