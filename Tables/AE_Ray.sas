
/*******************************************************************************************************************
    Project:	Bancova 2012 AE Table
	Program:	
Description:	1. Import data; 
				2. Clean data; 
				3. Make the AE table; 
				4. Export AE table 
      Input:	C:\Users\NYU User\Google Drive\Personal\bancova\sasdata; 
     Output:	C:\Users\NYU User\Google Drive\Personal\bancova\output; 
 Programmer:	Ray (Hang Zhong)
    Created:	08/3/2012
	   QCer:	Xianzhang Meng
	QC date:	
      Notes:	
********************************************************************************************************************/ 

dm "log;clear;output;clear";
options nodate nonumber linesize=max;

%let hwname= HW4: AE table; 

%let   dirin=C:\Users\NYU User\Google Drive\Personal\bancova\sasdata;
%let  dirout=C:\Users\NYU User\Google Drive\Personal\bancova\output;
%let   rawae=C:\Users\NYU User\Google Drive\Personal\bancova\sasdata\AdverseEvents.xls;
%let rawdisp=C:\Users\NYU User\Google Drive\Personal\bancova\sasdata\disposition_data.xls;

%let span=\brdrb\brdrs\brdrw15;

** import data; 
proc import datafile="&rawae."
	out=ae
	dbms=xls replace;
	mixed=yes;
run;

proc import datafile="&rawdisp"
	out=disp
	dbms=xls replace;
	mixed=yes;
run;

** template for data report;
 proc template;
	Define style styles.panda;
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


** build combined table with itt population;
proc sql;
    create table comb as
	select a.subjid as subjid format 3.,
           a.soct as soct format $80. label="system organ class",
           a.ptterm as ptterm format $25. label="preferred term",
		   b.itt as itt format 3.,
		   b.treatmnt as treatment format 3. label="treatment"
	from ae as a, disp as b
	where a.subjid=b.subjid and b.itt=1;
quit;
	   

** remove missing data;
data comb;
    set comb;
	where soct^=' ';
	output;
	treatment=3;
	output;
run;

** sample size of different treatment;
proc sql;
    select count(distinct subjid) into:num1-:num3 from comb group by treatment;
quit;

** build single subjid, soct and ptterm combined data;
proc sql;
    create table byptterm as
	select distinct subjid, soct, ptterm, treatment
	from comb
	order by soct, ptterm;
quit;

** count numbers of different groups in byptterm data;
data cp(drop=treatment subjid);
    set byptterm;
	by soct ptterm;
	retain count1 count2 count3;
	if first.ptterm then do;
	     count1=0;
		 count2=0;
		 count3=0;
	 end;
	   if treatment=1 then count1+1;
	   if treatment=2 then count2+1;
	   if treatment=3 then count3+1;
	if last.ptterm ;
run;

** build single subjid and soct combined data;
proc sql;
    create table bysoct as
	select distinct subjid, soct, treatment
	from comb
	order by soct;
quit;

** count numbers of different groups in bysoct data;
data cs(drop=treatment subjid);
    set bysoct;
	by soct;
	retain count1 count2 count3;
	if first.soct then do;
	    count1=0;
		count2=0;
		count3=0;
	end;
	if treatment=1 then count1+1;
	if treatment=2 then count2+1;
	if treatment=3 then count3+1;
	if last.soct;
run;
    
** interweave cs and cp;
proc sort data=cs out=cs;
    by soct;
run;

proc sort data=cp out=cp;
    by soct;
run;

data list;
    set cs cp;
	by soct;
run;

** build final data;
** modify data list and change numerical variable to character;
data list(drop=ptterm count1 count2 count3);
    set list;
	length name $80. col1 col2 col3 $15.;
	if ptterm=' ' then name=propcase(soct);
	else name='      '||propcase(ptterm);
	col1=put(count1,3.)||" ("||put(count1*100/%eval(&num1),4.1)||"%)";
	col2=put(count2,3.)||" ("||put(count2*100/%eval(&num2),4.1)||"%)";
    col3=put(count3,3.)||" ("||put(count3*100/%eval(&num3),4.1)||"%)";
run;

** build one observation data;
data onse;
    length soct name $80. col1$15. col2$15. col3 $15.;
	soct="Subject with at Least One AE";
	name="Subject with at Least One AE";
    col1=put(&num1,3.)||"(100%)";
    col2=put(&num2,3.)||"(100%)";
    col3=put(&num3,3.)||"(100%)";
run;
 
** derive final data and build page index;
data final;
    set onse
	    list;
	 count=_n_;
	 if 0<count=<14 then mypage=1;
	 else if 14<count=< 28 then mypage=2;
	 else if 28<count=< 42 then mypage=3;
	 else if 42<count=<56 then mypage=4;
	 else if 56<count=<70 then mypage=5;
	 else if 70<count=<84 then mypage=6;
	 else if 84<count=<98 then mypage=7;
	 else mypage=8;
	 footnote=mypage;
	 bottomline=mypage;
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
ods rtf file="&dirout\NewAE.rtf" style=panda ;

title3 "^S={font_size=9pt just=c font_face=arial} BAN.3_1";
title4 "^S={font_size=10pt just=c font_face=arial} Adverse Events by MedDRA System Organ Class, High Level Term and Preferred Term";
title5 "^S={font_size=8pt just=c font_face=arial} ITT Population";
proc report data=final nowindows split='/' 
       style(column)={cellheight=0.22in };
	 column  mypage footnote  bottomline soct name col1 col2 col3;
     define mypage/order order=data  
	               noprint;
	 define footnote/order noprint;
	 define bottomline/order noprint;
	 define soct/order order=data noprint;
	 define name/'Primary System Organ Class N(%)/  Preferred Term' 
                 style={cellwidth=3.8 in just=left asis=on};
	 define col1/"Control/ N=&num1"
                 style={cellwidth=1.2in just=c leftmargin=0.2in};
	 define col2/"Treatmnt/ N=&num2"
                 style={cellwidth=1.2in just=c leftmargin=0.2in};
	 define col3/"Total/ N=&num3"
                 style={cellwidth=1.2in just=c leftmargin=0.2in};

     break after mypage/page;
     compute before soct/style={just=left font_size=10pt};
     line'';
	 endcomp;
	 compute after bottomline/style={protectspecialchars=off};
     line "&span";
     endcomp;
	 compute after footnote;
     line "^S={font_size=9pt just=l leftmargin=0.1in} Note: A subject is counted only once within a preferred term, High level term, and system organ class.Percents are based on the number of subjects in the ITT population.";
	 endcomp;
	 
run;
ods rtf close;
