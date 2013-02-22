/*====================================================================
| COMPANY           Bancova LLC
| PROJECT:          BAN-AA-01
| PROGRAM:          vs.sas
| PROGRAMMER(S):    Ray
| DATE:             
| PURPOSE:          Generate vital sign table
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
	value itemf
		1 	= "Mean"
		2 	= "Median"
		3 	= "Std"
		4 	= "Minimum"
		5 	= "Maximum"
		6	= "p95"
		7	= "q25"
		8	= "q75"
		9 	= "n"
		10 	= "Mean (Std Dev)"
		11 	= "Minimum, Maximum"
		12	= "(Minimum, Maximum)"
		; 
	invalue seqin
		9	= 1
		10	= 2
		2	= 3
		11	= 4
		; 
	value listf
		1   	= "    n"
		2   	= "    Mean (Std Dev)"
		3 	= "    Median"
		4	= "    Minimum, Maximum"
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
** import vital sign data; 
proc import 	datafile = "&dDir\vital\vital.xls"
				out 	 = raw
				dbms 	 = xls replace; 
	sheet 		= "vital";
	getnames 	= yes;  
run; 

%ppt(raw); 

%look(raw); 
** diasbp, pulse, systbp, temper, visitnum; 

** import demog data; 
proc import 	datafile = "&dDir\demog\newdemog.xls"
				out 	 = rawdemog
				dbms 	 = xls replace; 
	sheet 		= "newdemog";
	getnames 	= yes;  
run; 

%ppt(rawdemog); 

** derive vs; 
proc sql; 
	create table vs as
	select b.usubjid, b.treatment, a.visitnum, a.systbp, a.diasbp, a.temper, a.pulse
	from raw as a, rawdemog as b
	where a.subjid = b.subjid and safety = 1; 
quit; 

%ppt(vs); 

proc freq data = vs; 
	table visitnum; 
run; 

** visit 3.1 means extra visit around 3, can be combined together; 
data vs_t; 
	set vs; 
	visit = int(visitnum - 1);
run; 

%ppt(vs_t); 

proc freq data = vs_t; 
	table visit; 
run; 

** average the multiple value for each visit of the subject; 
proc sql; 
	create table vs_a as
	select usubjid, treatment, visit, avg(systbp) as var1, avg(diasbp) as var2, avg(temper) as var3, avg(pulse) as var4
	from vs_t
	group by usubjid, visit; 
quit; 
** 11324; 
%look(vs_a); 
%ppt(vs_a); 

** no duplicated for each visit; 
proc sort data = vs_a nodup out = vs_as; 
	by usubjid visit; 
run; 
** 11065; 
%look(vs_as); 
%ppt(vs_as); 

** set up for the total; 
data vs_ast; 
	set vs_as; 
	output; 
	treatment = 3; 
	output; 
run; 

proc sort data = vs_ast out = vs_ast; 
	by treatment usubjid visit; 
run; 

%ppt(vs_ast); 

** check illogic data with demogDiag; 
data vs_ast;
	set vs_ast;
  	diag = ( min( var1, var2, var3, var4 )  < 0 );
run;

proc print data = vs_ast; 
	where diag = 1; 
run; 

** delete illogic data; 
data vs_ast; 
	set vs_ast; 
	if diag = 0; 
	drop diag; 
run; 

%look(vs_ast); 
** 22124 obs; 

%ppt(vs_ast); 

data base; 
	set vs_ast; 
	if visit = 0; 
run; 
%ppt(base); 

proc sql; 
	create table vs_change as
	select 	a.usubjid, a.treatment, a.visit, 
			case
				when a.visit = 0 then a.var1
				else (a.var1 - b.var1)
			end as var1, 
			case
				when a.visit = 0 then a.var2
				else (a.var2 - b.var2)
			end as var2, 
			case
				when a.visit = 0 then a.var3
				else (a.var3 - b.var3)
			end as var3, 
			case
				when a.visit = 0 then a.var4
				else (a.var4 - b.var4)
			end as var4 
	from vs_ast as a, base as b
	where a.usubjid = b.usubjid and a.treatment = b.treatment; 
quit; 

%ppt(vs_change); 



*--------------------------------------------*;
* calculate the counts # for each group; 
*--------------------------------------------*;
proc sql noprint; 
	select count(distinct usubjid) into :num1- :num3 from vs_ast group by treatment; 
quit; 

%put &num1; ** 791; 
%put &num2; ** 394; 
%put &num3; ** 1185; 



%macro numstat2(indsn=, outdsn=, grp=, var=, stra=, fmt=6.1|6.1|6.2|6.1|6.1|6.1|6.1|6.1|6.0); 
%global cntvar; 
%local i; 
%let i = 1; 
%do %while ( %sysfunc(scan(&var., &i.)) ne ); 
	%global var&i.; 
	%let var&i. = %sysfunc(scan(&var., &i.)); 
	%let i = %eval( &i. + 1 ); 
%end; 
%let cntvar = %eval( &i. - 1 ); 

proc sql noprint; 
	create table &stra.list as select distinct &stra. as val from &indsn.; 
	select strip(put(count(val), best.)) into : nval from &stra.list; 
	select val into : val1 - :val&nval. from &stra.list; p
quit; 

%do i = 1 %to &cntvar.; 
	%do j = 1 %to &nval.; 
		proc sort data = &indsn.; 
			by &grp.; 
		run; 

		proc univariate data = &indsn.(where=(&stra.=&&val&j.)); 
			var &&var&i.; 
			by &grp.; 
			output out = uni_&i._&j. n=n mean=mean median=median std=std min=min max=max p95=p95 Q1=q25 Q3=q75;
		run; 

		data uni_&i._&j.; 
			format var val $8.; 
			set uni_&i._&j.; 
			var = "&&var&i."; 
			val = "&&val&j."; 
		run; 
	%end; 
%end; 

data uni; 
	set
%do i = 1 %to &cntvar.; 
	%do j = 1 %to &nval.; 
		uni_&i._&j.
	%end; 
%end; 
	; 
run; 

proc sort data = uni; 
	by &grp. val; 
run; 

data uniout; 
	set uni; 
	array ss{9} mean median std min max p95 q25 q75 n;
	array str{12} $15. str1-str12 ('mean' 'median' 'std' 'min' 'max' 'p95' 'q25' 'q75' 'n' 'Mean (Sd)' 'Min, Max' '(Min, Max)');
	%do j = 1 %to 9;
		str{&j.} = trim(left( put(ss{&j.}, %scan(&fmt,&j,'|'))  ))  ;
	%end;
	str{10} = strip(str{1})||" ("||strip(str{3})||")"; 
	str{11} = strip(str{4})||", "||strip(str{5}); 
	str{12} = "("||strip(str{4})||", "||strip(str{5})||")"; 
	drop mean median std min max p95 q25 q75 n;
run; 

proc transpose data = uniout out = &outdsn.; 
	id var; 
	by &grp. val; 
	var str1-str12; 
run; 

data &outdsn.; 
	set &outdsn.; 
	if _NAME_ = 'str1' then list = 1; 
	if _NAME_ = 'str2' then list = 2; 
	if _NAME_ = 'str3' then list = 3; 
	if _NAME_ = 'str4' then list = 4; 
	if _NAME_ = 'str5' then list = 5; 
	if _NAME_ = 'str6' then list = 6; 
	if _NAME_ = 'str7' then list = 7; 
	if _NAME_ = 'str8' then list = 8; 
	if _NAME_ = 'str9' then list = 9; 
	if _NAME_ = 'str10' then list = 10; 
	if _NAME_ = 'str11' then list = 11; 
	if _NAME_ = 'str12' then list = 12; 
	rename 	val = &stra.; 
	drop _NAME_; 
run; 
%mend; 

%numstat2(indsn=vs_ast, outdsn=temp, grp=treatment, var=var1 var2 var3 var4, stra=visit); 

data out; 
	format listf $20.; 
	set temp; 
	vis = input(visit, 4.0); 
	if list in (9, 10, 2, 11); 
	seq = input(list, seqin.); 
	listf = put(seq, listf.); 
	output; 
	if seq = 4 then do; 
		var1 = " "; 
		var2 = " "; 
		var3 = " "; 
		var4 = " "; 
		list = .; 
		seq = 0; 
		if vis = 0 then listf = "Baseline (Visit=0)"; 
		else listf = "Visit " || visit; 
		output; 
	end; 
run; 

proc sort data = out; 
	by treatment vis seq; 
run; 

** final dataset with index for page, footnote, bottomline; 
data final1 final2 final3;
    set out;
	mypage 		= ceil(_n_/10); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	if treatment = 1 then output final1; 
	if treatment = 2 then output final2; 
	if treatment = 3 then output final3; 
run;

** for change; 
%numstat2(indsn=vs_change, outdsn=temp2, grp=treatment, var=var1 var2 var3 var4, stra=visit); 

data out2; 
	format listf $20.; 
	set temp2; 
	vis = input(visit, 4.0); 
	if list in (9, 10, 2, 11); 
	seq = input(list, seqin.); 
	listf = put(seq, listf.); 
	output; 
	if seq = 4 then do; 
		var1 = " "; 
		var2 = " "; 
		var3 = " "; 
		var4 = " "; 
		list = .; 
		seq = 0; 
		if vis = 0 then listf = "Baseline (Visit=0)"; 
		else listf = "Visit " || visit; 
		output; 
	end; 
run; 

proc sort data = out2; 
	by treatment vis seq; 
run; 

** final dataset with index for page, footnote, bottomline; 
data final12 final22 final32;
    set out2;
	mypage 		= ceil(_n_/10); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	if treatment = 1 then output final12; 
	if treatment = 2 then output final22; 
	if treatment = 3 then output final32; 
run;




*--------------------------------------------*;
* report; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = Vital; 
%let tableno = Table 15; 
%let title = Vital Sign Parameters over Time; 
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

%macro rt; 
** Nowindows tells PROC REPORT not to go into interactive mode; 
** Missing tells SAS not to silently delete observations with missing values in their classification variables.; 
** Headline tells PROC REPORT to print an underline below the column headers. ; 
** Headskip tells PROC REPORT to skip a line after the header.; 
%do i = 1 %to 3; 
proc report data = final&i. nowindows missing headline headskip split="|" 
										style(header)={just=l}
										style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline visit listf ("^S={ just=c borderbottomcolor=black borderbottomwidth=2} %scan(AA/Placebo/Total,&i,/) | N = &&num&i" ("^S={ just=c borderbottomcolor=black borderbottomwidth=2}Blood Pressure (mmHg)" var1 var2) var3 var4); 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   	/ order noprint;
	define bottomline 	/ order noprint;

	** Group to cosolidate observations; 
	define visit		/ order noprint; 

	** Display the values; 
	define listf		/"Visit" 					style=[asis=on cellwidth=2.5in];
	define var1		/"Systolic"					style=[just=c rightmargin=0.2in cellwidth=1.4in];
	define var2		/"Diastolic" 					style=[just=c rightmargin=0.2in cellwidth=1.4in];
	define var3		/"Temperature (�C)" 				style=[just=c rightmargin=0.2in cellwidth=1.4in];
	define var4	    	/"Pulse Rate (bpm)" 				style=[just=c rightmargin=0.2in cellwidth=1.4in];
	
	break after mypage	/	page;	

	compute before visit;
		line " "; 
	endcomp;

	compute after bottomline /						style={protectspecialchars=off};
    		line "&span";
    	endcomp;

	compute after footnote;
     		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes: Only patients with available baseline and postbaseline values are included in the by-visit analysis."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab * Visit = Derived."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab n = Number of patients with available analysis value at both baseline and a specific time point in the Safety Population."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Baseline is defined as the last assessment before the first dose of double-blind IP."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab End of Study is the last available postbaseline assessment."; 
	endcomp;
run; 
%end; 
%mend; 
%rt; 
ods rtf close;





*--------------------------------------------*;
* report the chance from baseline; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = Vital_change; 
%let tableno = Table 16; 
%let title = Change from baseline in Vital Sign Parameters over Time; 
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

%macro rt; 
** Nowindows tells PROC REPORT not to go into interactive mode; 
** Missing tells SAS not to silently delete observations with missing values in their classification variables.; 
** Headline tells PROC REPORT to print an underline below the column headers. ; 
** Headskip tells PROC REPORT to skip a line after the header.; 
%do i = 1 %to 3; 
proc report data = final&i.2 nowindows missing headline headskip split="|" 
										style(header)={just=l}
										style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline visit listf ("^S={ just=c borderbottomcolor=black borderbottomwidth=2} %scan(AA/Placebo/Total,&i,/) | N = &&num&i" ("^S={ just=c borderbottomcolor=black borderbottomwidth=2}Blood Pressure (mmHg)" var1 var2) var3 var4); 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   	/ order noprint;
	define bottomline 	/ order noprint;

	** Group to cosolidate observations; 
	define visit		/ order noprint; 

	** Display the values; 
	define listf		/"Visit" 					style=[asis=on cellwidth=2.5in];
	define var1		/"Systolic"					style=[just=c rightmargin=0.2in cellwidth=1.4in];
	define var2		/"Diastolic" 					style=[just=c rightmargin=0.2in cellwidth=1.4in];
	define var3		/"Temperature (�C)" 				style=[just=c rightmargin=0.2in cellwidth=1.4in];
	define var4	    	/"Pulse Rate (bpm)" 				style=[just=c rightmargin=0.2in cellwidth=1.4in];
	
	break after mypage	/	page;	

	compute before visit;
		line " "; 
	endcomp;

	compute after bottomline /						style={protectspecialchars=off};
    		line "&span";
    	endcomp;

	compute after footnote;
     		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes: Only patients with available baseline and postbaseline values are included in the by-visit analysis."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab * Visit = Derived."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab n = Number of patients with available analysis value at both baseline and a specific time point in the Safety Population."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Baseline is defined as the last assessment before the first dose of double-blind IP."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab End of Study is the last available postbaseline assessment."; 
	endcomp;
run; 
%end; 
%mend; 
%rt; 
ods rtf close;





