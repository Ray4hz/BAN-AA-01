
/*******************************************************************************************************************
    Project:	Bancova 2012 concomitant Medications Table
	Program:	hw5_conmed
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
%let myroot  = C:\Users\NYU User\Google Drive\Personal\bancova; 
%let hwname  = Conmed Table; 

%let span = \brdrb\brdrs\brdrw15; 

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


** import data; 
** 19 obs; 
proc import 
	datafile = "&myroot.\sasdata\Demog_data.xls"
	out = demog_data
	dbms = xls replace;
	getnames = yes;
run;


** keep only subjid, treatmnt; 
proc sql;
    create table demog as
  	select subjid,treatmnt, itt, safety
  	from demog_data
  	where safety = 1;
quit;

** import conmed data; 
** 144 obs; 
proc import 
	datafile = "&myroot.\sasdata\conmed.csv"
	out = conmed
	dbms = csv
	replace; 
	getnames = yes;
	guessingrows = 32767; 
run; 

** keep only subjid and prefterm; 
** 34 obs;
proc sql
	noprint; 
	create table cn as
	select subjid, prefterm
	from conmed
	where prefterm is not missing; 
quit; 


** perform a simple count of each treatment and output result;
proc sql
	noprint; 

	select count(distinct subjid) format = 3.
	into :n1
	from demog
	where treatmnt = 1; 

	select count(distinct subjid) format = 3.
	into :n2
	from demog
	where treatmnt = 2; 

	select count(distinct subjid) format = 3.
	into :n3
	from demog
	where treatmnt ne .; 
quit; 
 
%put &n1; 
%put &n2; 
%put &n3; 

** merge conmed and treatmnt data; 
** 28 obs; 
proc sql
	noprint; 
	create table cmtosum as 
	select unique(cn.prefterm) as prefterm, cn.subjid, demog.treatmnt
	from cn, demog
	where cn.subjid = demog.subjid
	order by subjid, prefterm; 
quit;
 
** count for subjects with at least one concomitant medications;
data alocm; 
	set cmtosum;
	keep subjid treatmnt; 
run; 

proc sort 
	data = alocm nodup; ** delete duplicate obs; 
	by _all_; ** force the duplicate obs to be next to each other; 
run; 

proc freq 
	data = alocm; 
	table treatmnt / noprint out = alocm_n (keep = treatmnt count); 
run; 

proc transpose 
	data = alocm_n
	out = alocm_f (drop = _name_ _label_)
	prefix = col;
	var count; 
	id treatmnt; 
run; 

** add first row; 
data alocm_f_r; 
	set alocm_f; 
	col1 = sum(col1, 0);
	col2 = sum(col2, 0); 
	col3 = sum(col1, col2); 
	length name $80. cout1 cout2 cout3 $15.;
	name = "Subjects with at Least One Con Med";
	cout1 = put(col1,3.)||"("||put(col1*100/%eval(&n1),4.1)||"%)";
	cout2 = put(col2,3.)||"("||put(col2*100/%eval(&n2),4.1)||"%)";
	cout3 = put(col3,3.)||"("||put(col3*100/%eval(&n3),4.1)||"%)";
	grp = 1; 
run; 


** count the individual prefterm; 
data pref; 
	set cmtosum; 
	keep subjid treatmnt prefterm; 
run; 

proc sort data = pref nodup;
	by _all_;
run; 

proc freq
	data = pref; 
	table treatmnt * prefterm / noprint out = pref_n (keep = prefterm treatmnt count); 
run; 

proc sort data = pref_n; 
	by prefterm; 
run; 

proc transpose data = pref_n
    out = pref_f (drop = _name_ _label_)
    prefix = col;
	by prefterm;
	var count;
	id treatmnt;
run;

** add rest rows; 
data pref_f_r; 
	set pref_f; 
	col1 = sum(col1, 0);
	col2 = sum(col2, 0); 
	col3 = sum(col1, col2); 
	name = '     '||propcase(prefterm);
	grp = 2;
    cout1 = put(col1,3.)||"("||put(col1*100/%eval(&n1),4.1)||"%)";
	cout2 = put(col2,3.)||"("||put(col2*100/%eval(&n2),4.1)||"%)";
	cout3 = put(col3,3.)||"("||put(col3*100/%eval(&n3),4.1)||"%)";
run; 

** insert a sub title into group 2; 
data name;
	length name $80.;
	name = "Therapeutic Sublevel";
	grp=2;
run; 


** prepare the final dataset; 
data final; 
	set alocm_f_r name pref_f_r; 
	p = ceil(_n_/14); ** set up lines to break pages; 
	footnote = p;
	bottomline = p;
	keep p footnote bottomline grp name cout1 cout2 cout3;
run; 

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

ods rtf file="&dirout\&hwname. %sysfunc(today(), mmddyyn.).rtf" style=panda;

title3 "^S={font_size=10pt just=c font_face=arial} Table 4";
title4 "^S={font_size=12pt just=c font_face=arial font_weight=bold} Concomitant Medications by WHO Drug Class and Preferred Term";
title5 "^S={font_size=8pt just=c font_face=arial} (Safety Population)";


** report the data; 
proc report data=final nowindows split='/' 
    style(column)={cellheight=0.22in };
	column p footnote bottomline grp name cout1 cout2 cout3;

    define p/order noprint;
	define footnote/order noprint;
	define bottomline/order noprint;

	define grp /group noprint order=data;
	define name / 'Therapeutic Sublevel  N(%)/   Preferred Term'
		style = {cellwidth = 3.8in just = l asis = on};
	define cout1 / "Anticancer00/ N=&n1"
		style = {cellwidth = 1.2in just = c leftmargin = 0.2in};
	define cout2 / "Anticancer01/ N=&n2"
		style = {cellwidth = 1.2in just = c leftmargin = 0.2in};
	define cout3 / "Total/ N=&n3"
		style = {cellwidth = 1.2in just = c leftmargin = 0.2in};
	
	compute before grp;
	    line "  ";
	endcomp;

	break after p/page;	
	
	compute after bottomline/style={protectspecialchars=off};
    	line "&span";
    endcomp;

	compute after footnote;
     	line "^S={font_size=8pt just=l leftmargin=0.1in font_face=arial} Programming Note: When you program this table, ignore “Therapeutic Sublevel  N(%)”.";
	endcomp;
	  
run;
ods rtf close;





