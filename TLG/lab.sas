/*====================================================================
| COMPANY           Bancova LLC
| PROJECT:          BAN-AA-01
| PROGRAM:          lab.sas
| PROGRAMMER(S):    Ray
| DATE:             
| PURPOSE:          Generate lab table
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
		1   = "    n"
		2   = "    Mean (Std Dev)"
		3 	= "    Median"
		4	= "    Minimum, Maximum"
		; 
	value sf
		1  = "    Low"
		2  = "    Normal"
		3  = "    High"
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

proc template;
	define style styles.panda2;
		style titleAndNoteContainer /
        	outputwidth 		= _undef_;
      	style data /
          	foreground 			= black
          	font_face 			= arial
          	font_weight 		= medium
          	font_size 			= 7pt
          	protectspecialchars	= off;
      	style header /
          	protectspecialchars	= off
          	font_face 			= Arial
          	font_weight 		= medium
          	font_size 			= 7pt;
       	style Table /
          	cellspacing			= 1pt
          	cellpadding			= 2pt
          	frame				= above
          	rules				= groups
          	borderwidth 		= 1.5pt;
       	style systemtitle /
          	font_face 			= arial
          	font_weight 		= medium
          	font_size 			= 7pt
          	protectspecialchars	= off;
       	style systemfooter /
          	font_face 			= arial
          	font_weight 		= medium
          	font_size 			= 7pt;
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
** import vital sign data; 
%macro in; 
%do i = 1 %to 10; 
proc import 	datafile = "&dDir\lab\lab_l&i..xls"
				out 	 = rawlab&i.
				dbms 	 = xls replace; 
	sheet 		= "l&i.";
	getnames 	= yes;  
run; 

data l&i.; 
	set rawlab&i.; 
	vis = int(visitnum-1); 
	high = input( scanq(lbornrhi, 2, " %"), best.); 
	low = input( scanq(lbornrlo, 2, " %"), best.); 
	drop visitnum visitdt lbdtc lbendtc lbtestcd lbcat lborresu; 
run; 
%end; 
%mend; 
%in; 

** import demog data; 
proc import 	datafile = "&dDir\demog\newdemog.xls"
				out 	 = rawdemog
				dbms 	 = xls replace; 
	sheet 		= "newdemog";
	getnames 	= yes;  
run; 

%ppt(rawdemog); 

%ppt(l3); 
data l3; 
	set l3; 
	keep subjid treatment PSA vis high low; 
run; 

proc sql; 
	create table lab11 as
	select b.usubjid, b.treatment, a.*
	from l1 as a, rawdemog as b
	where a.subjid = b.subjid and safety = 1; 
quit;

%ppt(l3); 

proc freq data = l1; 
	table vis; 
run; 


** derive lab; 
%macro la; 
%do i = 1 %to 10; 
proc sql; 
	create table lab&i. as
	select b.usubjid, b.treatment, a.*
	from l&i. as a, rawdemog as b
	where a.subjid = b.subjid and safety = 1; 
quit;
proc sort data = lab&i.; 
	by usubjid; 
run; 
data lab&i.; 
	set lab&i.; 
	output; 
	treatment = 3; 
	output; 
	drop subjid lbtest lbstresu lbornrlo lbornrhi lborres; 
run; 
%end;  
%mend; 
%la; 


proc freq data = lab1; 
	table vis; 
run; 


%macro lab; 
%do i = 1 %to 10; 
data lab_&i.; 
	format usubjid treatment vis; 
	set lab&i.;  
	drop high low; 
run; 
%end; 
data lab; 
	merge 
		%do i = 1 %to 10; 
		lab_&i.
		%end; 
		; 
	by usubjid; 
run; 		 
%mend; 
%lab; 

%ppt(lab); 

data lab; 
	set lab; 
	rename 	
			Protein		= var1
			Glucose 	= var2
			PSA			= var3
			HEMOGLOBIN 	= var4
			HCT			= var5
			WBC			= var6
			ALT			= var7
			AST			= var8
			HDL 		= var9
			LDL			= var10
	;			
run; 

%ppt(lab); 

proc freq data = lab; 
	table vis; 
run; 

%macro avg; 
** average the multiple value for each visit of the subject; 
proc sql; 
	create table laball as
	select 
			%do i = 1 %to 10; 
			avg(var&i.) as var&i., 
			%end; 
			usubjid, treatment, vis
	from lab
	group by usubjid, vis; 
quit; 
%mend; 
%avg; 

%ppt(laball); 

proc sort data = laball nodup out = laballs; 
	by usubjid treatment vis; 
run; 

%look(laballs);  
** 24844; 

** for the change from baseline; 
data base; 
	set laballs; 
	if vis = 0; 
run; 

%macro change; 
proc sql; 
	create table lab_change as
	select 	
			%do i = 1 %to 10; 
			case
				when a.vis = 0 then a.var&i.
				else (a.var&i. - b.var&i.)
			end as var&i., 
			%end; 
			a.usubjid, a.treatment, a.vis
	from laballs as a, base as b
	where a.usubjid = b.usubjid and a.treatment = b.treatment; 
quit; 
%mend; 
%change; 

%ppt(lab_change); 



*--------------------------------------------*;
* calculate the counts # for each group; 
*--------------------------------------------*;
proc sql noprint; 
	select count(distinct usubjid) into :num1- :num3 from laballs group by treatment; 
quit; 

%put &num1; ** 791; 
%put &num2; ** 394; 
%put &num3; ** 1185; 


** calculate each lab test; 
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

%numstat2(indsn=laballs, outdsn=temp, grp=treatment, var=var1 var2 var3 var4 var5 var6 var7 var8 var9 var10, stra=vis); 

%pt(temp); 

data out; 
	format listf $20.; 
	set temp; 
	v = input(vis, 5.); 
	array var{10} var1-var10; 
	if list in (9, 10, 2, 11); 
	seq = input(list, seqin.); 
	listf = put(seq, listf.); 
	output; 
	if seq = 4 then do; 
		do i = 1 to 10; 
			var{i} = " "; 
		end; 
		list = .; 
		seq = 0; 
		if vis = 0 then listf = "Baseline (Visit=0)"; 
		else listf = "Visit " || strip(put(vis, 4.0)); 
		output; 
	end; 
	drop i; 
run; 

%ppt(out); 

proc sort data = out; 
	by treatment v seq; 
run; 

%pt(out); 

%ppt(final1); 


** final dataset with index for page, footnote, bottomline; 
data final1 final2 final3;
    set out;
	visit = put(vis, 3.); 
	mypage 		= ceil(_n_/10); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	if treatment = 1 then output final1; 
	if treatment = 2 then output final2; 
	if treatment = 3 then output final3; 
run;



** for change; 

%numstat2(indsn=lab_change, outdsn=temp2, grp=treatment, var=var1 var2 var3 var4 var5 var6 var7 var8 var9 var10, stra=vis); 

%pt(temp2); 

data out2; 
	format listf $20.; 
	set temp2; 
	v = input(vis,5.); 
	array var{10} var1-var10; 
	if list in (9, 10, 2, 11); 
	seq = input(list, seqin.); 
	listf = put(seq, listf.); 
	output; 
	if seq = 4 then do; 
		do i = 1 to 10; 
			var{i} = " "; 
		end; 
		list = .; 
		seq = 0; 
		if vis = 0 then listf = "Baseline (Visit=0)"; 
		else listf = "Visit " || strip(put(vis, 4.0)); 
		output; 
	end; 
	drop i; 
run; 

proc sort data = out2; 
	by treatment v seq; 
run; 

%pt(out2); 


** final dataset with index for page, footnote, bottomline; 
data final12 final22 final32;
    set out2;
	visit = put(vis, 3.); 
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

%let task = lab; 
%let tableno = Table 15; 
%let title = Summary of Laboratory Parameters over Time; 
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
options ps=77 ls=150 nonumber orientation=landscape; 

** output to rtf; 
ods rtf file="&oDir\&task._%now(fmt=b8601dt).rtf" style=panda2;

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
	column mypage footnote bottomline visit 
			listf	("^S={ just=c borderbottomcolor=black borderbottomwidth=2} %scan(AA/Placebo/Total,&i,/) | N = &&num&i" 
						var1 var2 var3 var4 var5 var6 var7 var8 var9 var10); 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;

	** Group to cosolidate observations; 
	define visit		/ order noprint; 

	** Display the values; 
	define listf	/"Visit" 																			style=[asis=on];
	define var1	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} PROTEIN | mg/dL" 		style=[just=c rightmargin=0.2in cellwidth=8%];
	define var2	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} GLUCOSE | mmol/L"  		style=[just=c rightmargin=0.2in cellwidth=10%];
	define var3		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} PSA | ng/mL" 			style=[just=c rightmargin=0.2in cellwidth=8%];
	define var4		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} HEMOGLOBIN | mmol/L"		style=[just=c rightmargin=0.2in cellwidth=10%];
	define var5		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} HCT | 1.0" 				style=[just=c rightmargin=0.2in cellwidth=8%];
	define var6		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} WBC | 10^12/L"  			style=[just=c rightmargin=0.2in cellwidth=8%];
	define var7	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} ALT | mckat/L(37C)" 		style=[just=c rightmargin=0.2in cellwidth=8%];
	define var8	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} AST | kat/L(37C)"		style=[just=c rightmargin=0.2in cellwidth=8%];
	define var9	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} HDL | mmol/L"  			style=[just=c rightmargin=0.2in cellwidth=8%];
	define var10	/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} LDL | mmol/L" 			style=[just=c rightmargin=0.2in cellwidth=8%];

	break after mypage	/	page;	

	compute before visit;
		line " "; 
	endcomp;

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes:   Baseline is defined as the last assessment before the first dose of IP."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Only patients with baseline and at least one postbaseline assessment are included."; 
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

%let task = lab_change; 
%let tableno = Table 14; 
%let title = Summary of Changes from Baseline Laboratory Parameters over Time; 
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
options ps=77 ls=150 nonumber orientation=landscape; 

** output to rtf; 
ods rtf file="&oDir\&task._%now(fmt=b8601dt).rtf" style=panda2;

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
	column mypage footnote bottomline visit 
			listf	("^S={ just=c borderbottomcolor=black borderbottomwidth=2} %scan(AA/Placebo/Total,&i,/) | N = &&num&i" 
						var1 var2 var3 var4 var5 var6 var7 var8 var9 var10); 

	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;

	** Group to cosolidate observations; 
	define visit		/ order noprint; 

	** Display the values; 
	define listf	/"Visit" 																			style=[asis=on];
	define var1	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} PROTEIN | mg/dL" 		style=[just=c rightmargin=0.2in cellwidth=8%];
	define var2	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} GLUCOSE | mmol/L"  		style=[just=c rightmargin=0.2in cellwidth=10%];
	define var3		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} PSA | ng/mL" 			style=[just=c rightmargin=0.2in cellwidth=8%];
	define var4		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} HEMOGLOBIN | mmol/L"		style=[just=c rightmargin=0.2in cellwidth=10%];
	define var5		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} HCT | 1.0" 				style=[just=c rightmargin=0.2in cellwidth=8%];
	define var6		/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} WBC | 10^12/L"  			style=[just=c rightmargin=0.2in cellwidth=8%];
	define var7	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} ALT | mckat/L(37C)" 		style=[just=c rightmargin=0.2in cellwidth=8%];
	define var8	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} AST | kat/L(37C)"		style=[just=c rightmargin=0.2in cellwidth=8%];
	define var9	    /"^S={ just=c borderbottomcolor=black borderbottomwidth=2} HDL | mmol/L"  			style=[just=c rightmargin=0.2in cellwidth=8%];
	define var10	/"^S={ just=c borderbottomcolor=black borderbottomwidth=2} LDL | mmol/L" 			style=[just=c rightmargin=0.2in cellwidth=8%];

	break after mypage	/	page;	

	compute before visit;
		line " "; 
	endcomp;

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Notes:   Baseline is defined as the last assessment before the first dose of IP."; 
		line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} ^\tab Only patients with baseline and at least one postbaseline assessment are included."; 
	endcomp;
run; 
%end; 
%mend; 
%rt; 
ods rtf close;






*--------------------------------------------*;
* for the shift table; 
*--------------------------------------------*;
data lab1; 
	set lab1; 
	rename PROTEIN = var1; 
run; 

data lab2; 
	set lab2; 
	rename GLUCOSE = var2; 
	low = 50; 
run; 

data lab3; 
	set lab3; 
	rename PSA = var3; 
	low = 0; 
run; 

data lab4; 
	set lab4; 
	rename HEMOGLOBIN = var4; 
run; 

data lab5; 
	set lab5; 
	rename HCT = var5; 
run; 

data lab6; 
	set lab6; 
	rename WBC = var6; 
run; 

data lab7; 
	set lab7; 
	rename ALT = var7; 
run; 

data lab8; 
	set lab8; 
	rename AST = var8; 
run; 

data lab9; 
	set lab9; 
	high = 300; 
	rename HDL = var9; 
run; 

data lab10; 
	set lab10; 
	low = 0; 
	rename LDL = var10; 
run; 

%look(lab1); 

proc sql; 
	create table tlab&i. as
	select avg(var&i.) as var&i., usubjid, treatment, vis, low, high
	from lab&i.
	group by usubjid, treatment, vis; 
quit; 

%macro avg2; 
%do i = 1 %to 10; 
proc sql; 
	create table tlab&i. as
	select avg(var&i.) as var&i., usubjid, treatment, vis, low, high
	from lab&i.
	group by usubjid, treatment, vis; 
quit; 
proc sort data = tlab&i. nodup out = stlab&i.; 
	by usubjid treatment vis; 
run; 
data flab&i.; 
	set stlab&i.; 
	if var&i. > high then range = 3; 
	else if var&i. < low then range = 1; 
	else range = 2; 
	drop low high var&i.; 
run; 
proc sort data = flab&i.; 
	by treatment vis range usubjid; 
run; 
%end; 
%mend; 
%avg2; 

** protein and glucose were checked only in the screening, no shift table; 
proc freq data = flab3; 
	table vis; 
run; 

%macro shift; 
proc sql noprint; 
	%global nvis; 
	select strip( put( count(distinct vis ), best.) ) into: nvis from flab3;
quit;

proc sort data = flab3; 
	by usubjid treatment vis range; 
run; 

proc sql; 
	create table unique as
	select distinct usubjid, treatment 
	from flab3; 
quit; 

data uni; 
	set unique; 
	%do i = 1 %to &nvis.; 
		vis = input(&&v&i., best.); 
		range = .; 
		output; 
	%end; 
run; 

proc sql; 
	create table unicom as
	select a.usubjid, a.treatment, a.vis, 
			case
				when missing(b.range) then a.range
				else b.range
			end as range
	from uni as a
		left join 
			flab3 as b
		on 	a.usubjid = b.usubjid and 
			a.treatment = b.treatment and 
			a.vis = b.vis
		order by usubjid, treatment, vis, range; 
quit; 
%mend; 
%shift; 

%ppt(unicom); 

proc transpose data = unicom
	out = pp 
	prefix = v; 		
	by usubjid treatment; 
	var range; 
run; 

proc sort data = pp out = ppp; 
	by treatment; 
run; 

%ppt(ppp); 

%macro labshift; 
data dum; 
	count = 0; 
	do y = 1 to 3; 
		do x = 1 to 9; 
			output; 
		end; 
	end; 
run; 
%do k = 2 %to &nvis.; 
proc freq data = ppp noprint; 
	table v&k.*v1 / out = freq&k.1;
	by treatment; 
run; 

data freq&k.1t; 
	set freq&k.1; 
	if treatment = 1 then x = v1; 
	else if treatment = 2 then x = v1 + 3; 
	else x = v1 + 6; 
	drop PERCENT treatment v1; 
	rename v&k. = y; 
run; 

proc sort data = freq&k.1t; 
	by y; 
run; 

proc sql; 
	create table freq&k.1dum as
	select a.y, a.x, 
		case 
			when missing(b.COUNT) then a.COUNT
			else b.COUNT
		end as count
	from dum as a
		left join 
			freq&k.1t as b
		on a.x = b.x and 
			a.y = b.y
	order by y, x; 
quit; 

proc transpose data = freq&k.1dum
	out = freq&k.1out
	prefix = v; 
	by y; 
	var COUNT; 
run; 

data f&k.1; 
	set freq&k.1out; 
	vis = %eval(&k.-1); 
	list = y; 
	drop _NAME_ y; 
run; 
%end; 

data shift; 
	set 
	%do j = 2 %to &nvis.; 
		f&j.1
	%end; 
	; 
run; 
%mend; 
%labshift; 

%pt(shift); 

%macro out; 
data lbs; 
	format c1 c2 c3 c4 c5 c6 c7 c8 c9 $15.; 
	set shift; 
	%do i = 1 %to 3; 
	c&i. = strip(put(v&i., 4.0)) || " (" || strip(put( v&i./%eval(&num1), percent8.1)) || ")"; 
	%end; 
	%do i = 4 %to 6; 
	c&i. = strip(put(v&i., 4.0)) || " (" || strip(put( v&i./%eval(&num2), percent8.1)) || ")"; 
	%end; 
	%do i = 7 %to 9; 
	c&i. = strip(put(v&i., 4.0)) || " (" || strip(put( v&i./%eval(&num3), percent8.1)) || ")"; 
	%end; 
	drop v1 v2 v3 v4 v5 v6 v7 v8 v9 j; 
run; 
data lbs; 
	set lbs; 
	output; 
	if list = 3 then do; 
		list = .; 
		%do p = 1 %to 9; 
		c&p. = " "; 
		%end; 
		output; 
	end; 
	drop j; 
run; 
proc sort data = lbs; 
	by vis list; 
run; 
%mend; 
%out; 

%pt(lbs); 

%look(lbs); 
	
data finalshift; 
	set lbs; 
	visit = put(vis, 3.); 
	mypage 		= ceil(_n_/12); ** set up lines to break pages; 
	footnote 	= mypage;
	bottomline 	= mypage;
	if list = . then listf = "Visit " || strip(put(vis, 4.0)); 
	else listf = put(list, sf.); 
run; 

%ppt(finalshift); 




*--------------------------------------------*;
* report lab shift table ; 
*--------------------------------------------*;
** timestamp for footnote and title of rtf file; 
%macro now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
	%sysfunc(strip(%SYSFUNC( DATETIME(), &fmt ))) 
%mend;

** output parameters; 
ods escapechar="^";

%let task = Lab_shift_PSA; 
%let tableno = Table 12; 
%let title = Shift Table for Clinical Laboratory Parameters over Time: PSA; 
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
proc report data = finalshift nowindows missing headline headskip split="|" 
													style(header)={just=l}
													style(column)={cellheight=0.2in }; 
	** The COLUMN tells which variables you want to print, and in what order.; 
	column mypage footnote bottomline visit 
		("^S={ just=c borderbottomcolor=black borderbottomwidth=2 } Lab Test Prostate Specific Antigen"	
			("^S={ just=c borderbottomcolor=black borderbottomwidth=2 }" listf)
			("^S={ just=c borderbottomcolor=black }AA      |^S={ just=c borderbottomcolor=black borderbottomwidth=2}N=&num1." c1 c2 c3) 
			("^S={ just=c borderbottomcolor=black }Placebo |^S={ just=c borderbottomcolor=black borderbottomwidth=2}N=&num2." c4 c5 c6)
		) ; 
	** Order to sort the data; 
	define mypage		/ order noprint;
	define footnote	   / order noprint;
	define bottomline /	order noprint;
	define visit 	 / order noprint; 

	** Display the values; 
	define listf	 /"Baseline " 					style=[asis=on cellwidth=1.5in];
	define c1		 /"Low"							style=[just=c rightmargin=0.1in cellwidth = 10%];
	define c2		 /"Normal" 						style=[just=c rightmargin=0.1in cellwidth = 10%];
	define c3		 /"High" 						style=[just=c rightmargin=0.1in cellwidth = 10%];
	define c4		 /"Low"							style=[just=c rightmargin=0.1in cellwidth = 10%];
	define c5		 /"Normal" 						style=[just=c rightmargin=0.1in cellwidth = 10%];
	define c6		 /"High" 						style=[just=c rightmargin=0.1in cellwidth = 10%];

	break after mypage	/	page;	

	compute before visit; 
		line " "; 
	endcomp; 

	compute after bottomline /						style={protectspecialchars=off};
    	line "&span";
    endcomp;
run; 

ods rtf close;



