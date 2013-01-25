%MACRO now( fmt= DATETIME23.3 ) /DES= 'timestamp' ; 
  %SYSFUNC( DATETIME(), &fmt )
%MEND now ;