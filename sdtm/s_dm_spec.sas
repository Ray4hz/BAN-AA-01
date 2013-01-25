/*******************************************************************************************************************
    Project:	BAN-AA-01
	Program:	s_dm_spec
Description:	
				To generate DM specification		
      Input:	
     Output:	
 Programmer:	Ray (Hang Zhong)
    Created:	
	   QCer:	
	QC date:	
      LABELs:	
********************************************************************************************************************/ 


* autocall macros; 
filename autoM "C:\bancova\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 

* libname; 
%include "C:\bancova\projects\prostate\data\sdtm\prog\libname.sas"; 

data spec; 
	do i = 1 to 16; 
		n = i; 
		output; 
	end; 
	drop i; 
run; 

%ppt(spec); 

* varible name; 
%createcat(indsn=spec, outdsn=spec, varname=Varname, len=10, 
cat=STUDYID|DOMAIN|USUBJID|SUBJID|RFSTDTC|RFENDTC|SITEID|AGE|AGEU|SEX|RACE|ETHNIC|ARMCD|ARM|COUNTRY, 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

* variable label; 
%createcat(indsn=spec, outdsn=spec, varname=Varlabel, len=40, 
cat=Study Identifier|Domain Abbreviation|Unique Subject Identifier
|Subject Identifier for the Study|Subject Reference Start Date/Time|Subject Reference End Date/Time
|Study Site Identifier|Age|Age Units
|Sex|Race|Ethnicity
|Planned Arm Code|Description of Planned Arm|Country,
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

* type; 
%createcat(indsn=spec, outdsn=spec, varname=Type, len=4, 
cat=Char|Char|Char
|Char|Char|Char
|Char|Num|Char
|Char|Char|Char
|Char|Char|Char, 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

* role; 
%createcat(indsn=spec, outdsn=spec, varname=Role, len=40, 
cat=Identifier|Identifier|Identifier
|Topic|Record Qualifier|Record Qualifier
|Record Qualifier|Record Qualifier|Variable Qualifier
|Record Qualifier|Record Qualifier|Record Qualifier
|Record Qualifier|Record Qualifier|Record Qualifier, 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

* core; 
%createcat(indsn=spec, outdsn=spec, varname=Core, len=4, 
cat=Req|Req|Req
|Req|Exp|Exp
|Req|Exp|Exp
|Req|Exp|Perm
|Req|Req|Req, 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

* format; 
%createcat(indsn=spec, outdsn=spec, varname=Format, len=10, 
cat= |DM| 
| |ISO 8601|ISO 8601| 
| | |(AGEU)
|(SEX)|(RACE)|(ETHNIC)
|*|*|(COUNTRY), 
ncat=1|1|1|1|1|1|1|1|1|1|1|1|1|1|1); 

data spec; 
	set spec; 
	drop n; 
run; 

data s_spec.s_dm_spec; 
	set spec; 
run; 

* output; 
%excel(indsn=spec, name=s_dm_spec, path=C:\bancova\projects\prostate\data\sdtm\prog); 



