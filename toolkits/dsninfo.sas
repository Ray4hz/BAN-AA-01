
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

%mend; 
