* write sasdata to excel; 
%macro toexcel(indsn=, name=, path=); 
ods tagsets.excelxp
	file  = "&path.\&name..xls"
	style = minimal
	options (Orientation = "landscape"
	FitToPage = "yes"
	Pages_FitWidth = "1"
	Pages_FitHeight = "100"); 
	proc print data = &indsn. NOOBS; 
	run; 
ods tagsets.excelxp close; 
%mend; 
