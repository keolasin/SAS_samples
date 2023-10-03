/*********************************************************
This program contains the formats for MCAH_lbw.sas
By: Matthew Reyes, MPH
**********************************************************/

/* #### Format #### */
PROC FORMAT;
VALUE lbw
	0 = "Normal Birth Weight (>2500g)"
	1 = "Low Birth Weight (<2500g)";
RUN;

/* #### Macro 1 #### */
/* Create SAS macros to read in 4 datasets we wish to stack and merge */
%macro read_maternal(dfname, newdf); 											/* args(input, output) */
%let path = "/home/u63125930/data/&dfname"; 									/* path to data using dfname */
DATA &newdf;																	/* create the temp data */
INFILE &path;																	/* import in the dataset (.DAT) */
INPUT ID 1-5 Preg 6 GravAge 18-19 BirthWt 50-52 GrHeight 84-85 GrWeight 86-88; 	/* assign variables/columns, see data dictionary */
RUN;

DATA &newdf;																	/* Save our new data */
SET &newdf;
RUN;

TITLE "Data from: &path";														/* Section title is dataset location */
PROC CONTENTS data=&newdf; RUN;													/* Inspect metadata */
PROC PRINT data=&newdf (obs=20); RUN;											/* Inspect first 20 obs */
%mend;

/* #### Macro 2 #### */
/* Create a SAS macro to read in 2 placental datasets we wish to stack */
%macro read_placenta(dfname, newdf);											/* args(input, output) */
%let path = "/home/u63125930/data/&dfname";										/* path to data using dfname */
DATA &newdf;																	/* create the temp data */
INFILE &path;																	/* import in the dataset (.DAT) */
INPUT ID 1-5 Preg 6 PlacenWt 33-35;												/* assign variables/columns, see data dictionary */
RUN;

DATA &newdf;																	/* save our new data */
SET &newdf;
RUN;

TITLE "Data from: &path";														/* Section title is dataset location */
PROC CONTENTS data=&newdf; RUN;													/* Inspect metadata */
PROC PRINT data=&newdf (obs=20); RUN;											/* Inspect first 20 obs */
%mend;

/* #### Macro 3 #### */
/* Convert birthweight from ounces to grams */
%macro unit_converter(dfname, newdf);											/* args(input, output) */
DATA &newdf																		/* new dataset */
(KEEP = id preg gravage grheight grweight placenwt BirthWt_grams );				/* remove birthweight in ounces from new dataset */
TITLE "Convert birthweight ounces to grams";
SET &dfname;
birthWt_grams = BirthWt*28.3495;												/* gram to ounces */
RUN;

/* PROC PRINT data = newdf; RUN; */												/* inspect data */
%mend;

/* #### Macro 4 #### */
/* Create indicator variable for low birth weight */
%macro create_flags(dfname, newdf);												/* args(input, output) */
DATA &newdf;																	/* new dataset */
SET &dfname;																	/* data to clean */
TITLE "Indicator flag for low birth weight (birth weight < 2500g)";
IF birthWt_grams = . THEN lbw_flag = .;											/* catch missings */
	ELSE IF birthWt_grams LT 2500 THEN lbw_flag = 1;							/* lbw defined as < 2500g, set to 1 (+) */
	ELSE lbw_flag = 0;															/* if not lbw, set to 0 (-) */
RUN;

/* PROC PRINT data = newdf; RUN; */												/* inspect data */
%mend;