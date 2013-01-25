* write sasdata to excel; 
%macro excel(indsn=, name=, path=); 
ods tagsets.excelxp
	file  = "&path.\&name..xls"
	style = minimal
	options (Orientation = "landscape"
	FitToPage = "yes"
	Pages_FitWidth = "1"
	Pages_FitHeight = "100"); 
	%pt(&indsn.); 
ods tagsets.excelxp close; 
%mend; 
