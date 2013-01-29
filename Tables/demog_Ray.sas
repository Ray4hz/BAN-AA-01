/*=================================================================================
       PROJECT: demog                             
     DIRECTORY:                                        

   DESCRIPTION: 
				1. Import data from an excel file with subject demographic info.;
                2. Create new variable(s); 
				3. QC diagnose data and modify data if necessary; 
				4. Create macro variable(s), descriptive statistics, 
                dataset(s), and report(s) to populate the table shell
  
    INPUT DATA: &pDir\data\demog_data.xls
   OUTPUT DATA: &pDir\data\demog.sas7bdat
  OUTPUT FILES: &pDir\output\

    PROGRAMMER: Ray (Hang Zhong) 
          DATE: 7/11/2012
         NOTES: 
==================================================================================*/

*----------------------------------------------*;
* options, directories, librefs, etc.
*----------------------------------------------*;
options nocenter mprint formdlim='-' msglevel= i;

%let dDir = F:\bancova\hw2p1\data;
%let oDir = F:\bancova\hw2p1\output; 

libname hw2p1 "&dDir\";


*--------------------------------------------*;
* 1. import, create new variable(s) and QC 
*--------------------------------------------*;
** 1.1 import ;
proc import datafile  = "&dDir\demog_data.xls"
            out       = hw2p1.demog
			dbms      = xls replace;
   			sheet     = 'Demog';
       		getnames  = yes;

run;

** create temp variable; 
data demog;
	set hw2p1.demog;
run;


** 1.2 create new varaibles age and bmi;
data demog;
  set demog;

  length age 3.;
  label age = 'Age as of today';
  dob = input(birthdtf, yymmdd10.);
  age = floor((intck('month', dob, today()) - (day(today()) < day(dob)))/12);
  drop dob;

  length bmi 3.;
  label bmi = 'Body Mass Index';
  bmi = weight/(height/100)**2;

run;


** 1.3 QC diagnose ;
*** 1.3a data contents ;
proc contents data= demog position out= dataCnt; run;


*** 1.3b create formats for QC diagnosis ;
proc format;
  value $sex
  	'MALE' = 1
   	'FEMALE' = 2
    other = 99;

  value $rac
    'CAUCASIAN' = 1
	'BLACK'     = 2
	'ASIAN'     = 3
	'HISPANIC'  = 4
	'OTHER'     = 5
    other  = 99;

  value agF
    low - 17,
    100 - high  = 99
    other  = 1;

  value htF
    low - 140,
	200 - high  = 99
    other  = 1;

  value wtF
    low - 30,
	200 - high  = 99
    other  = 1;

run;


*** 1.3c diagnose data ;
data demogDiag;
  set demog;
  diag = (max(put(gender, $sex.),
              put(race,   $rac.),
              put(age,     agF.),
              put(height,  htF.),
              put(weight,  wtF.)
              )
          >= 99);
run;

proc print data= demogDiag;
  where diag = 1;
run;


** 1.4 modify data ;
*** data diagnosis showed that 'ASIAIAN' in   ***
*** variable race should be 'ASIAN'           ***;
data demog;
  set demog;
  if race = 'ASIAIAN' then race = 'ASIAN';
run;



*----------------------------------------------*;
* 2. create macro variables of N(s) to be used
*    in headers of the table shell
*----------------------------------------------*;
proc sql;
  select trim(put(count(subjid), 3.)) into: nTot from demog where itt = 1;
  select trim(put(count(subjid), 3.)) into: nTr1 from demog where itt = 1 and treatmnt = 1;
  select trim(put(count(subjid), 3.)) into: nTr2 from demog where itt = 1 and treatmnt = 2;
quit;

%put Total N = &nTot;
%put Trt1  N = &nTr1;
%put Trt2  N = &nTr2;



*-------------------------------------------------------*;
* 3. create datasets containing descriptive statistics
*-------------------------------------------------------*;
** 3.1 numeric variable(s) ;
%macro varStat (vr, grp);

*** 3.1a get descriptive statistics ;
proc summary data= demog (where=(itt = 1));
  class treatmnt;
  var &vr;
  output out= &vr.Stat (drop= _:)
                          n = &vr.N
                       mean = &vr.Mean
                     median = &vr.Medn
                        std = &vr.Std
                        min = &vr.Min
                        max = &vr.Max;
run;

*** 3.1b transpose the dataset output from the above step ;
proc transpose data= &vr.Stat
                out= &vr.S    (rename =(_name_= stat col1= &vr)
                                 drop = _label_);
  by treatmnt;
run;

*** 3.1c arrange statistics in the order shown in the table shell ;
proc sql;
  create table &vr.Sm as
  select ' '     as varGrp length 10,
         T1.stat as vr     length 12,
         T1.&vr  as vr1,
         T2.&vr  as vr2,
         TT.&vr  as vrt
  from  (select * from &vr.s where treatmnt = 1) as T1,
   (select * from &vr.s where treatmnt = 2) as T2,
   (select * from &vr.s where treatmnt = .) as TT
  where T1.stat = T2.stat and T1.stat = TT.stat;
quit;

*** 3.1d assign values and formats ;
data &vr.SS;
  set &vr.Sm;
  varGrp = &grp;
  length v1 v2 vt $12;

  if _n_ = 1 then vr= 'N';
  if _n_ = 2 then vr= 'Mean';
  if _n_ = 3 then vr= 'Median';
  if _n_ = 4 then vr= 'Std. Dev.';
  if _n_ = 5 then vr= 'Minimum';
  if _n_ = 6 then vr= 'Maximum';

  if _n_ in (1) then do;
                  v1 = trim(left(put(vr1, 10.)));
 v2 = trim(left(put(vr2, 10.)));
 vt = trim(left(put(vrt, 10.)));
 end;
  if _n_ in (2, 3, 5, 6) then do;
                  v1 = trim(left(put(vr1, 10.1)));
 v2 = trim(left(put(vr2, 10.1)));
 vt = trim(left(put(vrt, 10.1)));
 end;
  if _n_ in (4) then do;
                  v1 = trim(left(put(vr1, 10.2)));
 v2 = trim(left(put(vr2, 10.2)));
 vt = trim(left(put(vrt, 10.2)));
 end;
  drop vr1--vrt;
run;

%mend varStat;
%varStat (age,    'age')
%varStat (height, 'height')
%varStat (weight, 'weight')
%varStat (bmi,    'bmi')
;


** 3.2 categorical variable(s) ;
*** 3.2a get counts and percents ;
%macro getFreq (val, nm);
proc freq data= demog (where=(treatmnt in (&val) and itt= 1));
  tables gender /missing out= genderS&nm;
  tables race   /missing out= raceS&nm; 
run;

  %macro perct (vr, fmt);
     data &vr.P&nm;
     set &vr.S&nm;
     &vr = put(&vr, &fmt..);
     pct = put(percent/100, percent8.1);
     drop percent;
  run;
  %mend perct;
  %perct (gender, $sex)
  %perct (race,   $rac)
  ;

%mend getFreq;
%getFreq (1 2, %str())
%getFreq (1,   1)
%getFreq (2,   2)
;

%macro varFp (vr, grp);
*** 3.2b arrange statistics in the order shown in the table shell ;
proc sql;
  create table &vr.Sm as
  select ' ' as varGrp length 10,
         T1.&vr as vr length 12,
T1.count as vr1,
T2.count as vr2,
TT.count as vrt,
  T1.pct as pct1,
  T2.pct as pct2,
  TT.pct as pctt
  from &vr.P1 as T1,
       &vr.P2 as T2,
       &vr.P as TT 
  where T1.&vr = T2.&vr and T1.&vr = TT.&vr
  order by vr;
quit;

*** 3.2c assign values and formats ;
data &vr.SS;
  set &vr.Sm;
  varGrp = &grp;

  length v1 v2 vt $12;
  v1 = trim(left(vr1))||' ('||trim(left(pct1))||')';
  v2 = trim(left(vr2))||' ('||trim(left(pct2))||')';
  vt = trim(left(vrt))||' ('||trim(left(pctt))||')';

  %if &vr = gender %then %do;
    if vr = '1' then vr = 'Male';
    if vr = '2' then vr = 'Female';
  %end;

  %if &vr = race %then %do;
    if vr = '1' then vr = 'Caucasian';
    if vr = '2' then vr = 'Black';
    if vr = '3' then vr = 'Asian';
    if vr = '4' then vr = 'Hispanic';
    if vr = '5' then vr = 'Other';
  %end;
  
  drop vr1--pctt;

run;
%mend varFp;
%varFp (gender, 'gender')
%varFp (race,   'race')
;


** 3.3 deal with missing categories of race ;
proc sql ;
  select vr into :mr separated by ' ' from racess;
quit;

%put race = &mr;

data raceSS;
  set raceSS end= eof;
  output;

  if eof then do;
   if index("&mr", 'Caucasian') = 0 then do; vr= 'Caucasian'; v1= '0 (0.0%)'; v2= '0 (0.0%)'; vt= '0 (0.0%)'; output; end;
   if index("&mr", 'Black')     = 0 then do; vr= 'Black';     v1= '0 (0.0%)'; v2= '0 (0.0%)'; vt= '0 (0.0%)'; output; end;
   if index("&mr", 'Asian')     = 0 then do; vr= 'Asian';     v1= '0 (0.0%)'; v2= '0 (0.0%)'; vt= '0 (0.0%)'; output; end;
   if index("&mr", 'Hispanic')  = 0 then do; vr= 'Hispanic';  v1= '0 (0.0%)'; v2= '0 (0.0%)'; vt= '0 (0.0%)'; output; end;
   if index("&mr", 'Other')     = 0 then do; vr= 'Other';     v1= '0 (0.0%)'; v2= '0 (0.0%)'; vt= '0 (0.0%)'; output; end;
  end;
run;


** 3.4 stack up all datasets of statistics generated by the above process;
data  hw2p1.varSum;
  set genderSS
      raceSS
 ageSS
 heightSS
 weightSS
 bmiSS;
run;
 
proc print data= hw2p1.varSum; run;



*-------------------------------------------------------*;
* 4. create tables and write into an rtf file
*-------------------------------------------------------*;
** 4.1 create my own ODS style ;
proc template;
  define style dwBCVb;
  parent = styles.printer;

  replace fonts /
    'TitleFont'           = ("Verdana",10pt,Bold)
    'TitleFont2'          = ("Verdana", 10pt)
    'StrongFont'          = ("Verdana",10pt,Bold)
    'EmphasisFont'        = ("Verdana",10pt)
    'BatchFixedFont'      = ("Courier New",9pt)
    'FixedEmphasisFont'   = ("Courier New",9pt)
    'FixedStrongFont'     = ("Courier New",9pt)
    'FixedHeadingFont'    = ("Courier New",9pt)
    'FixedFont'           = ("Courier New",9pt)
    'headingEmphasisFont' = ("Verdana",10pt,Bold)
    'headingFont'         = ("Baskerville Old Face",8pt)
    'docFont'             = ("Baskerville Old Face",8pt);

  replace color_list /
    'bg'   = white
    'fg'   = black
    'fgH'  = black
    'bgH'  = white
    'link' = blue ;

  style body from document /
    leftmargin    = 1.0in
    rightmargin   = 1.0in
    topmargin     = 0.8in
    bottommargin  = 0.5in;

  style Table from output /
    background  = _undef_
    frame       = box
    rules       = groups
    cellpadding = 1pt
    cellspacing = 0pt
    borderwidth = 1pt;
  end;
run;

** 4.2 define header and footer ;
options center nonumber nodate orientation= landscape;

ods escapechar= '^';
ods rtf file= "&oDir\hw2p1_%sysfunc(today(), mmddyyn.).rtf"
    style= dwBCVb options(continue_tag= 'no'); 

title1 j=r '^S={font_size=7pt font_face=arial}Page ^{pageof}';
title2 j= l ' ';
     
** 4.3 create the table ;
title3 j=c '^S={font= ("Baskerville Old Face", 8pt, light)}TABLE 1';
title4 j=c '^S={font_size= 8pt} ';
title5 j=c '^S={font= ("Baskerville Old Face", 8pt, light)}DEMOGRAPHICS AND BASELINE CHARACTERISTICS';
title6 j=c '^S={font_size= 8pt} ';
title7 j=c '^S={font= ("Baskerville Old Face", 8pt, light)}ITT POPULATION)*';
title8 j=c '^S={font_size= 8pt} ';
title9 j=c '^S={font_size= 8pt} ';

proc format; 
   value $grpF
      gender = 'Gender N (%)' 
        race = 'Race N (%)' 
         age = 'Age (yrs)' 
      height = 'Height (cm)' 
      weight = 'Weight (kg)' 
         bmi = 'BMI (kg/m^{super 2})';
run;

proc report data= hw2p1.varSum nowd style(header)= {just=center marginbottom= 5mm};
  column varGrp vr v1 v2 vt;

  define varGrp     /group noprint order=data;
  define vr         /display left    "Variables/ / " 
                                     style(column)= {cellwidth=2.9in marginleft= 5mm};
  define v1         /display center  "Anticancer000/(N= %left(&nTr1))**"
                                     style(column)= {cellwidth=2.0in};
  define v2         /display center  "Anticancer001/(N= %left(&nTr2))**"
                                     style(column)= {cellwidth=2.0in};
  define vt         /display center  "Total/(N= %left(&nTot))**"
                                     style(column)= {cellwidth=2.0in};

  compute before;
     line ' ';
  endcomp;
  compute before varGrp /style= {just= left};
     line varGrp $grpF.;
  endcomp;
  compute after varGrp /style= {just= left font_size= 2pt};
     line ' ';
  endcomp;

run;

ods rtf text='^S={font=("Times New Roman", 12pt)} ';
ods rtf text='^S={font=("Times New Roman", 12pt)}* ITT (Intent to Treat) population is defined as including all subjects who have at least one baseline assessment and one post baseline assessment.';
ods rtf text='^S={font=("Times New Roman", 12pt)}** N is the number of subjects in the treatment group.';

title1;
title2;
title3;
title4;
title5;
title6;
title7;
title8;
title9;

ods rtf close;


*** END ***;
