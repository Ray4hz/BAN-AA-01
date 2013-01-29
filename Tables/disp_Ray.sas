
/*******************************************************************************************************************
    Project:	Bancova 2012 Disposition Table
	Program:	hw2p2_redo.sas
Description:	1. Import data; 
				2. Clean data; 
				3. Make the disposition table; 
				4. Export disposition table 
      Input:	C:\Users\NYU User\Google Drive\Personal\bancova\sasdata; 
     Output:	C:\Users\NYU User\Google Drive\Personal\bancova\output; 
 Programmer:	Ray (Hang Zhong)
    Created:	07/25/2012
	   QCer:	Xianzhang Meng
	QC date:	
      Notes:	
********************************************************************************************************************/ 

** set up the system options; 
options nodate nonumber orientation=landscape linesize=max;
ods escapechar='^';

** define the root for input and output; 
%let myroot=C:\Users\NYU User\Google Drive\Personal\bancova; 

** define the format for the output; 
proc format;
	value $listform 
          	'enroll'='Enrolled Population      (a)  n (xx)'
          	'ppp'=   'Per-Protocol Population  (b)  n  (xx)'
			'itt'=   'ITT Population     (c)'
			'safety'='Safety Population  (d)'
			'complete'='Patients Completed'
		  	'disc1'=  'Patients Discontinued'
			'pro'=  'Primary Reason for discontinuation of Study Dose'
			'disr1'=  '    Patient withdrew consent'
			'disr2'=  '    Protocol Violation'
			'disr3'=  '    Lost to follow up'
			'disr4'=  '    Adverse Event'
		    ;
run;


** set up the Bancova panda template; 
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


** import data; 
proc import 
	datafile="&myroot.\sasdata\disposition_data.xls"
	out=temp
	dbms=xls replace;
	mixed=yes;
run;


** clean data; 
data dispt;
	set temp(keep=treatmnt itt ppp enroll complete safety disrsn);
	where enroll ne .;
	output;
	treatmnt=3;
	output;
run;

** count the observations for treatmnt; 
proc sql noprint;  
	select count(*) into :num1-:num3 
		from dispt 
		group by treatmnt;
quit;

** count complete, discontinue, disposition; 
data disp (drop=disrsn);
	set dispt;
	if disrsn=' ' then do;
		disc=0;
        dis=1;
		disr=0;
	 end;
	 else do;
        disc=1;
	    dis=0;
		disr=disrsn;
	 end;
run;   


** creat macro to count, for continuous and categorical varialbes; 
%macro coun(indata  =disp,    /** input data;                */ 
            pop     =,        /** population;                */
            kind    =,        /** dataset and variable group;*/
            outdata =,        /** output data;               */
			val     =         /** possible population number;*/
             );

	** build macro variable for every population by treatmnt;
	%if &pop^= %then %do;	    
        proc sql;
            select sum(&pop=&val) into :var1-:var3 from &indata
            group by treatmnt;
		quit;

		** build output dataset;
		** build different group varialbe for report to seperate;
		data &outdata;
			length group list $8. col1 col2 col3 $15.;
   			
			%if &kind=0 %then %do;
                group="&pop.";
			    list="&pop.";
			%end;

			%else %do;
                group="com";
				list="&pop&&val";
			%end;
			    col1=put(&var1,4.0)||" (" ||put( %sysevalf(&var1*100/&num1),5.1)||"%)";
                col2=put(&var2,4.0)||" (" ||put( %sysevalf(&var2*100/&num2),5.1)||"%)";
                col3=put(&var3,4.0)||" (" ||put( %sysevalf(&var3*100/&num3),5.1)||"%)";
		run;
	%end;
	%else %do;
		** build one sentence data set;
		data &outdata;
		    length group list $8.;
			group="com";
			list="pro";
		 run;
	%end;
%mend coun;


** count desired result; 
%coun (pop=enroll,
	   kind=0,
	   outdata=tem1,
	   val=1)
                 
%coun (pop=ppp,
	   kind=0,
	   outdata=tem2,
	   val=1)
     
%coun (pop=itt,
	   kind=0,
	   outdata=tem3,
	   val=1)

%coun (pop=safety,
	   kind=0,
	   outdata=tem4,
	   val=1)

%coun (pop=complete,
	   kind=1,
	   outdata=tem5,
	   val=1)

%coun (pop=disc,
	   kind=1,
	   outdata=tem6,
	   val=1)

%coun (outdata=tem7)

%coun (pop=disr,
	   kind=2,
	   outdata=tem8,
	   val=1)

%coun (pop=disr,
	    kind=2,
		outdata=tem9,
		val=2)

%coun (pop=disr,
	   kind=2,
	   outdata=tem10,
	   val=3)

%coun (pop=disr,
	   kind=2,
	   outdata=tem11,
	   val=4)

** stack up all the count; 
data final;
	set tem1 - tem11;
	mypage=1;
	footnote=1;
run;

** set up output title and footnote; 
%macro rtftit;
title1 font='arial' h=1 justify=l "Bancova Institute"  
                        justify=r "Class 2012";
title2 font='arial' h=1 justify=r "page^{pageof}";
footnote1 justify=c "______________________________________________________________________________________________________________________________________";
footnote2 font='arial' h=1 justify=c " hw2p2: disposition table produced by Ray, %sysfunc(date(), worddate18.)";
%mend;

%rtftit;

%let span=\brdrb\brdrs\brdrw15;

** output file in this path by panda sytle; 
ods rtf file="&myroot.\output\newdisp.rtf" style=panda;

** use proc report to put the data in the template; 
proc report data=final headskip nowindows headline headskip split="/"
             style(column)={cellheight=0.2in };

	column mypage footnote group list col1 col2 col3; /*lz: singled out for later maintance */

	define mypage/order noprint;
	define footnote/group noprint;
    define group/group order=data noprint;
    define list/display ' ' format=$listform. 
              style=[asis=on cellwidth=3.5in];
    define col1/display "Anticancer000" 
              style=[just=c rightmargin=0.2in cellwidth=1.2in];
    define col2/display "Anticancer001"
              style=[just=c rightmargin=0.2in cellwidth=1.2in];
	define col3/display "Total"
              style=[just=c rightmargin=0.2in cellwidth=1.2in];
  
  	compute before group;
  		line'';
   	endcomp;
  	compute after footnote /style={protectspecialchars=off};
  		line "&span";
  	endcomp;
  	compute after mypage;
		line "^S={font_size=10pt just=l font_face=arial font_weight=medium} Note:";
   		line "^S={font_size=10pt just=l font_face=arial} a)  Enrolled population includes all patients who signed the informed consent.";
   		line "^S={font_size=10pt just=l font_face=arial} b)  Per Protocol population is defined as a subset of the ITT population with a list of criteria met.";
   		line "^S={font_size=10pt just=l font_face=arial} c)  ITT is defined as including all patients who have the baseline value and at least one post-baseline"; 
   		line "^S={font_size=10pt just=l font_face=arial leftmargin=0.5in}     value for the primary efficacy measure.";
   		line "^S={font_size=10pt just=l font_face=arial} d)  Safety population is defined as including all patients who took any study medication.";
	endcomp;

title4 "^S={font_size=10pt just=c font_face=arial} TABLE 2";
title5 "^S={font_size=12pt just=c font_face=arial font_weight=bold} Patient Disposition";
title6 "^S={font_Size=8pt just=c font_face=arial font_weight=medium} (all patients)";

run;
     
ods rtf close;
