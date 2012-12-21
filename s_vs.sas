/*******************************************************************************************************************
Project:	BAN-AA-01
Program:	s_vs
Des:		To generate SDTM VS; 		
Input:		
Output:		
Programmer:	Ray (Hang Zhong)
Created:	
QCer:	
QC date:	11/28/2012
LABELs:		
********************************************************************************************************************/ 

* autocall macros; 
filename autoM "C:\bancova\projects\prostate\programs\macros\toolkits"; 
options mautolocdisplay mautosource sasautos = (autoM); 

* libname; 
%include "C:\bancova\projects\prostate\data\sdtm\prog\libname.sas"; 

* import vs raw and spec, and sdtm vs spec; 
%let r_vs 	= C:\bancova\projects\prostate\data\sdtm\data\dm_c_1.xls; 
%let r_vs_spec 	= C:\bancova\projects\prostate\data\sdtm\data\dm_c_spec_1.xls;
%let s_vs_spec 	= C:\bancova\projects\prostate\data\sdtm\specs\DM-Spec_1.xls;
%let ct 	= C:\bancova\projects\prostate\data\sdtm\specs\CT.xls;



