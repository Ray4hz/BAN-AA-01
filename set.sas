/*--------------------------------------------------------------*/
/*				 	Index and Double-set 						*/
/*--------------------------------------------------------------*/
/* 	This example is to demonstrate the use of proc datasets 	*/
/*	(index) and double-set.  									*/
/*                       										*/
/*--------------------------------------------------------------*/
/*	The first data set TRANSACTION is a lookup table.			*/
/*	The second data set MASTER is to get multiple 				*/
/*	observations per lookup observation.						*/
/*                                                              */
/*--------------------------------------------------------------*/
/*	This program is modifed from Kevin McKinney 				*/
/*                                                              */
/*--------------------------------------------------------------*/

* TRANSACTION as lookup table, with multiple records; 
data TRANSACTION;
	input ein year quarter dataitem $2.;
datalines;
170000000000 1990 1 a
170000000000 1990 1 b
170000000001 1991 1 c
170000000001 1992 4 d
170000000000 1990 1 e
170000000071 1992 4 f
170000000449 1992 3 g
170000000528 1990 1 h
170000000798 1991 2 i
170000001003 1992 1 j
;
run;

proc print; 
run; 

* MASTER has no unique Key; 
data MASTER; 
	input ein year quarter who $6.; 
datalines; 
170000000000 1990 1 one
170000000000 1991 1 two
170000000449 1992 3 three
170000000449 1992 3 four
170000001003 1992 1 five
170000001003 1992 1 six
; 
run; 

proc print; 
run; 

* Create index for MASTER; 
proc datasets lib = work; 
	modify MASTER; 
	index create ein; 
run; 

/* 	The dataset in the first set statement(TRANSACTION, lookup)				*/
/* 	is not a unique list of key values and the dataset in the second 		*/
/* 	set statement (MASTER) does NOT have a unique set of key values.		*/
/*	And the KEY (ein) is repeated for observation one, two, and five.		*/ 
/* 	So this requires resetting the pointer on each iteration of the 		*/
/* 	data step, and two additional lookups in the MASTER dataset.			*/
/*	Once to know when the end of all the records for that EIN is reached. 	*/
/*	Once more to reset the pointer. The auxiliary variables continue and 	*/ 
/* 	continue1 will create a supplementary condition within the do while 	*/ 
/*	loop. 																	*/

data out;
	set TRANSACTION;
	continue=0;
	continue1=0;
	do while ( continue=0 );
	    set MASTER key=ein;
	    if continue1=1 then continue=1;
	    if _iorc_ = 0 then do;
	        output;
	        end;
	    else do;
	       _error_=0;
	       ein= 00000000000;
	       continue1=1;
	    end;
	end;
run;

proc print; 
run; 





