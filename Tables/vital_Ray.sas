dm 'log; clear; output; clear';
/*******************************************************************************************************************
    Project:	Bancova 2012 vital Table
	Program:	hw5_vital_Ray
Description:	1. Import data; 
				2. Clean data; 
				3. Make the table; 
				4. Export table 
      Input:	C:\Users\NYU User\Google Drive\Personal\bancova\sasdata; 
     Output:	C:\Users\NYU User\Google Drive\Personal\bancova\output; 
 Programmer:	Ray (Hang Zhong)
    Created:	
	   QCer:	
	QC date:	
      Notes:	
********************************************************************************************************************/ 
** use to print dataset; 
%macro pt(dataset);
	proc print data = &dataset;
	run; 
%mend pt; 

** a macro to put a specific value of a dataset into a macro variable; 
%MACRO Get_data(myDataset=,myLine=,myColumn=,myMVar=);
%GLOBAL &myMVar.;
data _null_;
set &myDataset.;
if _N_ = &myLine. then do;
	call symput(symget('myMVar'),&myColumn.);
end;
run;
%MEND Get_data;


** set up the system options; 
options nodate nonumber orientation=landscape linesize=max;

** define the root for input and output; 
%let   dirin = C:\Users\NYU User\Google Drive\Personal\bancova\sasdata;
%let  dirout = C:\Users\NYU User\Google Drive\Personal\bancova\output;
%let    span = \brdrb\brdrs\brdrw15; 

** template for data report;
 proc template;
	define style styles.panda;
    	style titleAndNoteContainer /
          	  outputwidth = _undef_;
      	style data /
          	foreground = black
          	font_face = arial
          	font_weight = medium
          	font_size = 10pt
          	protectspecialchars=off;
      	style header /
          	protectspecialchars=off
          	font_face = Arial
          	font_weight = medium
          	font_size = 10pt;
       	style Table/
          	cellspacing=1pt
          	cellpadding=2pt
          	frame=above
          	rules=groups
          	borderwidth =1.5pt;
       	style systemtitle /
          	font_face = arial
          	font_weight = medium
          	font_size = 10pt
          	protectspecialchars=off;
       	style systemfooter /
          	font_face = arial
          	font_weight = medium
          	font_size = 10pt;
       	style column /
          	protectspecialchars=off;
       	style notecontent;
       	style pageno /
          	foreground = white;
       	style SysTitleAndFooterContainer;
       	style body /
          	bottommargin = 1in
          	topmargin = 1in
          	rightmargin = _undef_
          	leftmargin = _undef_;
	end;
run ;

** import pe data; 
** 213 obs; 
proc import 
	datafile = "&dirin\Vitalsgn.xls"
	out = vsraw
	dbms = xls replace;
	getnames = yes;
run;

** import disp data; 
** 20 obs; 
proc import
	datafile = "&dirin\Demog_data.xls"
	out = demog
	dbms = xls replace; 
	getnames = yes;
run; 

proc sql; 
	create table vs as 
	select a.visit as visit, 
		   a.sysbp as sysbp,
		   a.diabp as diabp,
		   a.pulse as pulse,
		   a.temp as temp,
		   a.resp as resp, 
		   a.subjid as subjid,
		   b.treatmnt as treatmnt
	from vsraw as a, demog as b
	where a.subjid = b.subjid and b.safety = 1; 
quit; 

%pt(vs); 


** average the multiple value for each visit of the subject; 
** 199 obs; 
proc sql; 
	create table vs_a as 
	select avg(sysbp) as var1, avg(diabp) as var2, avg(temp) as var3, avg(pulse) as var4, avg(resp) as var5, visit, subjid, treatmnt
	from vs
	group by subjid, visit;
quit; 

%pt(vs_a);

** no duplicate for each visit, single record; 
** 115 obs; 
proc sort data= vs_a noduplicates out = vs_as;
	by subjid visit;
run;

%pt(vs_as); 

** average, single, total; 
** 230 obs; 
data vs_ast; 
	set vs_as; 
	output; 
	treatmnt = 3; 
	output; 
run; 
 
** dataset vs_ast : before calculate the change; 
proc sort data= vs_ast out = vs_ast;
	by treatmnt subjid visit;
run;

%pt(vs_ast); 


** count for total subjects in each treatment group;
** 10, 9, 19; 
proc sql;
    select count(distinct subjid) into :num1 - :num3
    from vs_ast
    group by treatmnt;
quit;

** 19 subjects; 
proc sql; 
	create table subj_list as
	select distinct subjid from vs_ast; 
quit; 

%pt(subj_list); 

** 12 different visits, including baseline visit = 0; 
proc sql; 
	create table visit_list as 
	select distinct visit from vs_ast; 
quit; 

%pt(visit_list); 

** identify the baseline; 
proc sql; 
	create table baseline as
	select var1, var2, var3, var4, var5, subjid, treatmnt, visit
	from vs_ast
	where visit = 0; 
quit; 

%pt(baseline); 

** calculate the change from baseline; 
proc sql; 
	create table change as
	select 
			case 
				when a.visit NE 0 then (a.var1 - b.var1)
				else b.var1
			end as var1, 
			case 
				when a.visit NE 0 then (a.var2 - b.var2)
				else b.var2
			end as var2, 
			case 
				when a.visit NE 0 then (a.var3 - b.var3)
				else b.var3
			end as var3, 
			case 
				when a.visit NE 0 then (a.var4 - b.var4)
				else b.var4
			end as var4, 
			case 
				when a.visit NE 0 then (a.var5 - b.var5)
				else b.var5
			end as var5, 
			a.subjid, a.treatmnt, a.visit
	from vs_ast as a, baseline as b
	where a.subjid = b.subjid
	order by a.treatmnt, a.subjid, a.visit;
quit; 

%pt(change); 

** remove exact duplicates; 
** 230 obs; 
proc sort data = change nodup; 
	by _all_; 
run; 

** dataset change: calculated change; 
proc sort data = change; 
	by treatmnt subjid visit; 
run; 

%pt(change); 


** macro to get dataset info; 
%macro dsninfo(indata); 

proc contents data = &indata out = &indata.info; 
run; 

proc print data = &indata.info; 
	var name type length varnum; 
run; 

%global &indata.info_cnt &indata.info_var &indata.info_typ &indata.info_len; 

proc sql noprint;
   select name ,type, length
      into :&indata.info_var separated by ' ',
           :&indata.info_typ separated by ' ',
           :&indata.info_len separated by ' '
         from &indata.info;
   quit;


%let &indata.info_cnt = &sqlobs;

%put &&&indata.info_var;
%put &&&indata.info_typ;
%put &&&indata.info_len;
%put &&&indata.info_cnt;

%mend dsninfo; 

%dsninfo(vs_ast); 


%macro judge(inmacro); 

%if symget(&inmacro) = "subjid treatmnt var1 var2 var3 var4 var5 visit" %then %do; 

	%put come; 

%end; 


%if &vs_astinfo_var = "subjid treatmnt var1 var2 var3 var4 var5 visit" %then %do; 

	%put &vs_astinfo_cont; 

%end; 

%put hi; 

%put symget(&vs_astinfo_var); 

%mend judge; 

%judge(&vs_astinfo_var); 

%put symget(&vs_astinfo_var); 






proc sort data = vs_ast; 
	by treatmnt visit; 
run; 

%pt(vs_ast); 

proc means data = vs_ast; 
	var var1; 
	by treatmnt visit; 
	output out = comb1 n = n mean = mean std = std median = median min = min max = max;
run;

%pt(comb1); 









proc contents data = comb1 out = comb1_1; 
run; 

proc print data = comb1_1; 
	var name type length varnum; 
run; 

proc sql noprint;
   select name ,type, length
      into :varlist separated by ' ',
           :typlist separated by ' ',
           :lenlist separated by ' '
         from comb1_1;
   quit;
%let cntlist = &sqlobs;
%put &varlist;
%put &typlist;
%put &lenlist;
%put &cntlist;


%GetVars(comb1); 
%GetVars(vs_ast); 

proc contents data = vs_ast out = vs_ast_1; 
run; 

proc sql noprint;
   select name ,type, length
      into :varlist separated by ' ',
           :typlist separated by ' ',
           :lenlist separated by ' '
         from vs_ast_1;
   quit;
%let cntlist = &sqlobs;
%put &varlist;
%put &typlist;
%put &lenlist;
%put &cntlist;

%macro emptydsn(dsn);
data &dsn(keep=&varlist);
   length
   %do i = 1 %to &cntlist;
      %scan(&varlist,&i) %if %scan(&typlist,&i)=2 %then $; %scan(&lenlist,&i)
   %end;
   ;
   stop;
   run;
%mend emptydsn;

%emptydsn(vs_ast); 

data vs_ast_2; 
	set vs_ast; 
	call symput ('sub' || left (_n_), subjid); 
	run; 


%pt(vs_ast_2); 




data comb1; 
	set comb1; 
	n = put(n, 2.);
	mean_std = put(round(mean), 3.)||' ('||put(std, 4.1)||')';
	median = put(round(median), 3.);
	min_max = put(round(min),3.)||','||put(round(max),3.);
	keep treatmnt visit n mean_std median min_max;
run;

%pt(comb1); 


proc transpose data = comb1
	out = combt1
 	prefix = col1; 
	by treatmnt visit;
	var n mean_std median min_max;
run; 

%pt(combt1); 




proc sort data = vs_ast; 
	by treatmnt visit; 
run; 

%pt(vs_ast); 

proc means data = vs_ast; 
	var var2; 
	by treatmnt visit; 
	output out = comb2 n = n mean = mean std = std median = median min = min max = max;
run;

%pt(comb1); 

data comb2; 
	set comb2; 
	n = put(n, 2.);
	mean_std = put(round(mean), 3.)||' ('||put(std, 4.1)||')';
	median = put(round(median), 3.);
	min_max = put(round(min),3.)||','||put(round(max),3.);
	keep treatmnt visit n mean_std median min_max;
run;


proc transpose data = comb2
	out = combt2
 	prefix = col2; 
	by treatmnt visit;
	var n mean_std median min_max;
run; 

%pt(combt2); 



proc sql;
    create table outdata as
	select a.treatmnt, a.visit, a._name_ as name, a.col11 as col1, b.col21 as col2
	from combt1 as a, combt2 as b
	where a.treatmnt=b.treatmnt
          and a.visit=b.visit
          and a._name_=b._name_;
quit;

%pt(outdata); 

data outdata1;
    set outdata;
	length list $20. treatna $20.;
	if visit < 6 then mypage = 1;
	else mypage = 2;
	if name = "n" then list = "    N";
	if name = "mean_std" then list = "    Mean (Std Dev)";
	if name = "median" then list = "    Median";
	if name = "min_max" then list = "    Minimum, Maximum";
	if treatmnt = 1 then treatna = "Anticancer00 N = &num1";
	if treatmnt = 2 then treatna = "Anticancer01 N = &num2";
	if treatmnt = 3 then treatna = "Total N = &num3";
	drop name;
run;

%pt(outdata1); 








data t; 
	set vs_ast; 
	if subjid <= 105; 
run ;

proc sort data = t out = test; 
	by treatmnt subjid visit;
run; 

%pt(test); 




proc sql; 
	create table vs_1 as 
	select a.visit as visit, 
		   a.sysbp as sysbp,
		   a.diabp as diabp,
		   a.pulse as pulse,
		   a.temp as temp,
		   a.resp as resp, 
		   a.subjid as subjid,
		   b.treatmnt as treatmnt
	from vsraw as a, demog as b
	where a.subjid = b.subjid and b.safety = 1 and a.subjid <= 105 and b.subjid <= 105; 
quit; 

%pt(vs_1); 


** average the multiple value for each visit of the subject; 
** 39 obs; 
proc sql; 
	create table vs_1a as 
	select avg(sysbp) as var1, avg(diabp) as var2, avg(temp) as var3, avg(pulse) as var4, avg(resp) as var5, visit, subjid, treatmnt
	from vs_1
	group by subjid, visit;
quit; 

%pt(vs_1a);

** no duplicate for each visit, single record; 
** 22 obs; 
proc sort data= vs_1a noduplicates out = vs_1as;
	by subjid visit;
run;

%pt(vs_1as); 

** average, single, total; 
** 230 obs; 
data vs_1ast; 
	set vs_1as; 
	output; 
	treatmnt = 3; 
	output; 
run; 
 
proc sort data= vs_1ast out = vs_1ast;
	by treatmnt subjid visit;
run;

%pt(vs_1ast); 


proc sort data = vs_1ast; 
	by treatmnt visit; 
run; 

%pt(vs_1ast); 

proc means data = vs_1ast; 
	var var1; 
	by treatmnt visit; 
	output out = comb1 n = n mean = mean std = std median = median min = min max = max;
run;

%pt(comb1); 

proc data = comb1; 
run; 


%macro hi(indata =, var = ); 

%put &var; 

%mend hi; 

%hi(var = 1 2 2 3); 



/*
average repeat visit for each var, remove the dup
sort



contiSUM


if vita, then
	if demog, then 

catSUM

if demog, then 
if ae, then
	if disp, then 

*/ 






contiSUM( indata = vs_ast, var = sys

%macro contiSUM(indata,outdata); 
proc sort data = &indata; 
	by treatmnt visit; 
run; 

%do i = 1 %to 5; 
proc means data = &indata noprint; 
	var var&i; 
	by treatmnt visit; 
	output out = comb&i n = n mean = mean std = std median = median min = min max = max;
run;

data comb&i;
    set comb&i;
	n = put(n, 2.);
	mean_std = put(round(mean), 3.)||' ('||put(std, 4.1)||')';
	median = put(round(median), 3.);
	min_max = put(round(min),3.)||','||put(round(max),3.);
	keep treatmnt visit n mean_std median min_max;
run;

proc transpose data = comb&i
    out = combt&i
    prefix = col&i;
	by treatmnt visit;
	var n mean_std median min_max;
run;
%end;

proc sql;
    create table &outdata as
	select a.treatmnt, a.visit, a._name_ as name, a.col11 as col1, b.col21 as col2, c.col31 as col3, d.col41 as col4, e.col51 as col5
	from combt1 as a, combt2 as b, combt3 as c, combt4 as d, combt5 as e
	where a.treatmnt=b.treatmnt=c.treatmnt=d.treatmnt=e.treatmnt
          and a.visit=b.visit=c.visit=d.visit=e.visit
          and a._name_=b._name_=c._name_=d._name_=e._name_;
quit;

data &outdata;
    set &outdata;
	length list $20. treatna $20.;
	if visit < 6 then mypage = 1;
	else mypage = 2;
	if name = "n" then list = "    N";
	if name = "mean_std" then list = "    Mean (Std Dev)";
	if name = "median" then list = "    Median";
	if name = "min_max" then list = "    Minimum, Maximum";
	if treatmnt = 1 then treatna = "Anticancer00 N = &num1";
	if treatmnt = 2 then treatna = "Anticancer01 N = &num2";
	if treatmnt = 3 then treatna = "Total N = &num3";
	drop name;
run;

%do i= 1 %to 3;
data &outdata&i;	
    set &outdata;
	where treatmnt = &i;
run;
%end;

%mend contiSUM; 

%contiSUM(vs_ast, vs_1); 

%pt(vs_1); 



























** generate report table; 
ods escapechar='^';
%macro rtftit;
title1 font='arial' h=1 justify=l "Bancova Institute"  
                        justify=r "Class 2012";
title2 font='arial' h=1 justify=r "page^{pageof}";
footnote1 justify=c "______________________________________________________________________________________________________________________________________";
footnote2 font='arial' h=1 justify=c " &hwname produced by Ray,%sysfunc(date(), worddate18.)";
%mend;
%rtftit
options orientation=landscape; 
ods rtf file="&dirout\&hwname. %sysfunc(today(), mmddyyn.) Ray.rtf" style=panda;
** macro to report the final datasets; 
%macro re; 
%do i = 1 %to 3; 
	title3 "^S={font_size=9pt just=c font_face=arial} Table 5";
   	title4 "^S={font_size=10pt just=c font_face=arial font_weight=bold} Physical Examination - Shift Table from Screening to End of Treatment (%scan(Anticancer00/Anticancer01/Total,&i,/))";
   	title5 "^S={font_size=9pt just=c font_face=arial} Safety Population";

	proc report 
		data=final&i nowindows split='/'
	    style(column)={cellheight=0.33in };
	    column mypage nbodysys ("--------------- NO CHANGE----------------" col1 col2) ("------IMPROVED------" col3)("------- WORSED------" col4);
		define mypage/group noprint;
		define nbodysys/order order=data 'Body System'  style={just=left asis=on cellwidth=1.5in};
		define col1/'Abnormal->Abnormal' style={just=right cellwidth=1.6in leftmargin=0.2in};
		define col2/'Normal->Normal' style={just=right cellwidth=1.6in rightmargin=0.2in};
		define col3/'Abnormal->Normal' style={just=right cellwidth=1.6in rightmargin=0.2in};
		define col4/'Normal->Abnormal' style={just=right cellwidth=1.6in rightmargin=0.2in};

		compute before mypage;
			line'';
		endcomp;
		compute after mypage/style={protectspecialchars=off};
			line "&span";
		endcomp;
	 run;
%end;
%mend;
%re
ods rtf close;




