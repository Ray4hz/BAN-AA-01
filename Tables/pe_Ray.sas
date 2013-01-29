
/*******************************************************************************************************************
    Project:	Bancova 2012 PE Table
	Program:	hw5_pe_Ray
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
	proc print data=&dataset;
	run; 
%mend pt; 

dm 'log; clear; output; clear';

** set up the system options; 
options nodate nonumber orientation=landscape linesize=max;

** define the root for input and output; 
%let   dirin = C:\Users\NYU User\Google Drive\Personal\bancova\sasdata;
%let  dirout = C:\Users\NYU User\Google Drive\Personal\bancova\output;
%let  myroot = C:\Users\NYU User\Google Drive\Personal\bancova; 
%let  hwname = PE Table; 
%let    span = \brdrb\brdrs\brdrw15; 

** setup proc format;
proc format;
   invalue formres 'ABNORMAL'=1
                   'NOT DONE'=.
				   'NORMAL'=2
;
   invalue formbod 'ABDOMEN'=10
                   'BREAST'=20
				   'CARDIOVASCULAR'=30
				   'GENITOURINARY'=40
				   'HEENT/NECK'=50
				   'LYMPHATIC'=60
				   'MUSCULOSKELETAL'=70
				   'NEUROLOGICAL'=80
				   'PULMONARY'=90
				   'RECTAL'=100
				   'SKIN'=110
				   'OTHER'=120
 ;

 VALUE formbody    10='ABDOMEN'
                   20='BREAST'
				   30='CARDIOVASCULAR'
				   40='GENITOURINARY'
				   50='HEENT/NECK'
                   60='LYMPHATIC'
				   70='MUSCULOSKELETAL'
				   80='NEUROLOGICAL'
				   90='PULMONARY'
				   100='RECTAL'
				   110='SKIN'
				   120='OTHER'
;
run;

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
** 1392 obs; 
proc import 
	datafile = "&dirin\PE_table5.xls"
	out = pe
	dbms = xls replace;
	getnames = yes;
run;

** import disp data; 
** total 33 obs, 20 complete obs; 
proc import
	datafile = "&dirin\disposition_data.xls"
	out = disp
	dbms = xls replace; 
	getnames = yes;
run; 
 
** select safty population;
** 1296 obs; 
proc sql;
    create table comb_name as
	select p.subjid,p.visit,p.result format $15.,
	       p.bodysys format $15., d.treatmnt
	from   pe as p, disp as d
	where  p.subjid = d.subjid and d.safety = 1;
quit;

** change variable result to numeric variable;
data comb(drop=result bodysys);
    set comb_name;
	nresult=input(result, formres.);
	nbodysys=input(bodysys, formbod.);
run;

** perform a simple count of each treatment and output result;
proc sql
	noprint; 
	select count(distinct subjid) format = 3.
	into :num1
	from comb
	where treatmnt = 1; 

	select count(distinct subjid) format = 3.
	into :num2
	from comb
	where treatmnt = 2; 

	select count(distinct subjid) format = 3.
	into :num3
	from comb
	where treatmnt ne .; 
quit; 
%put &num1; ** 10; 
%put &num2; ** 9; 
%put &num3; ** 19; 

** get baseline; 
** 228 obs; 
data pe_bas; 
	set comb; 
	if visit = 0; 
		base_val = nresult; 
run; 

proc sort data = comb; 
	by subjid nbodysys; 
run; 

proc sort data = pe_bas; 
	by subjid nbodysys; 
run; 

** do locf; 
** 228 obs; 
data last (keep = subjid treatmnt hold_visit locf nbodysys);
	set comb; 
	by subjid nbodysys;
	retain hold_visit locf;
	if first.nbodysys then 
		do; 
			hold_visit = visit; 
			locf = nresult; 
		end; 
	else 
		do; 
			if visit > hold_visit and nresult ne . then ** use hold_visit and locf to record the visit of LOCF result; 
				do; 
					hold_visit = visit; 
					locf = nresult; 
				end; 
		end; 
	if last.nbodysys; 
run; 

** merge baseline data with locf data;  
data new(keep=subjid treatmnt nbodysys base_val locf diff);
    merge pe_bas last;
    by  subjid nbodysys ;
	if base_val = 1 and locf = 1 then diff = 1;     	* Abnormal->Abnormal; 
	else if base_val = 2 and locf = 2 then diff = 2; 	* Normal->Normal; 
	else if base_val = 1 and locf = 2 then diff = 3; 	* Abnormal->Normal; 
	else if base_val = 2 and locf = 1 then diff = 4;    * Normal->Abnormal; 
	else diff = 5; 										* missing;  
	/*
		'ABNORMAL'=1
        'NOT DONE'=.
		'NORMAL'=2
	*/ 
run;

** set up total; 
data locf_t;
	set new;
	output; 
	treatmnt = 3; 
	output; 
run; 

** counts by group for each category;
 proc sql;
 	create table cnt_pe_trt as
 	select count(subjid) as cnt_pe,nbodysys,diff,treatmnt
 	from locf_t
 	group by treatmnt,nbodysys,diff;
 quit;
 
** compute the percenage and format as n (%);
data cnt_pe_trt_p;
    set cnt_pe_trt;
    if treatmnt=1 then p=put(cnt_pe,3.)||" ("||compress(put(100*cnt_pe/(&num1),4.1))||"%)";
    if treatmnt=2 then p=put(cnt_pe,3.)||" ("||compress(put(100*cnt_pe/(&num2),4.1))||"%)";
    if treatmnt=3 then p=put(cnt_pe,3.)||" ("||compress(put(100*cnt_pe/(&num3),4.1))||"%)";
 run;

proc sort 
	data = cnt_pe_trt_p;
	by nbodysys diff;
run;

** a macro to transpose the percentage to final dataset; 
%macro trtdt(trt);
proc transpose 
	data = cnt_pe_trt_p(where =(treatmnt = &trt)) 
	out = cnt_pe_trt_p_t&trt(drop=_name_ ) 
	prefix = col;
	var p;
	by nbodysys ;
	id diff;
run;
** 3 final datasets; 
data final&trt (drop = col5);
    set cnt_pe_trt_p_t&trt;
	format nbodysys formbody.;
	** after transformation the 0 count wiith missing value instead of 0, now imoute it as 0 (0.0%);
	if col1 = "" then col1 = "0 (0.0%)";
	if col2 = "" then col2 = "0 (0.0%)";
	if col3 = "" then col3 = "0 (0.0%)";
	if col4 = "" then col4 = "0 (0.0%)";
	** page number; 
    mypage = &trt;
run;
%mend;
%trtdt(1)
%trtdt(2)
%trtdt(3)

%pt(final1); 
%pt(final2); 
%pt(final3); 

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




