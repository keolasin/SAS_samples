/*********************************************************
This program prepares sample maternal and child health data:
	
	1. Data Import using Custom Macros
	2. Merges datasets on a shared primary-foreign key
	3. Cleans and prepares data
	4. Exports a cleaned dataset for further analysis
	
By: Matthew Reyes, MPH
**********************************************************/

/*********************************************************

## Setup environment

**********************************************************/

LIBNAME data "/home/u63125930/data"; 											/* set local data path */

/*********************************************************

## 1. Include macros

**********************************************************/

%include "/home/u63125930/includes/lbw_format.sas";								/* includes for format and helper functions/macros */

/* ### Data Import ### */
/* stack the maternal datasets, records 1 - 300 */
%read_maternal(B_1_150.DAT, b1_150);											/* maternal IDs 1-150 */
%read_maternal(B_151_300.DAT, b151_300);										/* maternal IDs 151-300 */

DATA b1_300;																	/* New dataset, IDs 1-300 */
SET b1_150 b151_300;
TITLE "Stacked Maternal Observations, IDs 1 - 300";
PROC CONTENTS data = b1_300;													/* Inspect metadata */
PROC SORT data = p1_300; BY id; RUN;											/* Sort on ID */
PROC PRINT data = b1_300;														/* full dataset, uncomment to view */
RUN;

/* stack the placental datasets, records 1 - 300 */
%read_placenta(P_1_150.DAT, p1_150);											/* placental IDs 1-150 */
%read_placenta(P_151_300.DAT, p151_300);										/* placental IDs 151-300 */

DATA p1_300;																	/* New dataset, IDs 1-300 */
SET p1_150 p151_300;
TITLE "Stacked Placental Observations, IDs 1 - 300";
PROC CONTENTS data = p1_300;													/* Inspect metadata */
PROC SORT data = p1_300; BY id; RUN;											/* Sort on ID */
PROC PRINT data = p1_300;														/* full dataset, uncomment to view */
RUN;

/*********************************************************

## 2. Merge Datasets

**********************************************************/

/* Many-to-many merge of maternal and placental datasets via PROC SQL */ 
PROC SORT data= b1_300; BY id preg; RUN;										/* Sort each dataset by ID and Pregnancy */
PROC SORT data= p1_300; BY id preg; RUN; 
																
TITLE "Merged (many-to-many) maternal and placental data on ID, Pregnancy number";
PROC SQL feedback;																/* feedback option for debugging */
CREATE TABLE merged AS															/* name our dataset (table) 'merged' */
SELECT *																		/* include ALL variables from both datasets */
FROM b1_300 AS m, p1_300 AS p													/* tables we're selecting from with aliases */
WHERE m.id = p.id AND m.preg = p.preg											/* merge criteria (INNER JOIN) */
ORDER BY m.id, preg;															/* sort the resulting table */
QUIT;

PROC CONTENTS data = merged;													/* inspect metadata */
PROC PRINT data = merged;														/* inspect observations */
RUN;

/* Create a left-join merged dataset, missings for some pregnancies */
PROC SORT data= b1_300; BY id preg; RUN;										/* Sort each dataset by ID and Pregnancy */
PROC SORT data= p1_300; BY id preg; RUN; 
																
TITLE "Merged (left-join) maternal and placental data on ID, Pregnancy number";
PROC SQL feedback;																/* feedback option for debugging */
CREATE TABLE left_join AS														/* name our dataset (table) 'left_join' */
SELECT *																		/* include ALL variables from both datasets */
FROM b1_300 AS m LEFT JOIN p1_300 AS p											/* tables we're selecting from with aliases */
ON m.id = p.id AND m.preg = p.preg;												/* merge criteria (LEFT JOIN) */
																				/* sort the resulting table */
QUIT;

PROC CONTENTS data = left_join;													/* inspect metadata */
PROC PRINT data = left_join;													/* inspect observations */
RUN;


/*********************************************************

## 3. Data Cleaning and Preparation

**********************************************************/

/* Convert birthweight from ounces to grams */
%unit_converter(merged, merged_units);
%unit_converter(left_join, left_units);

/* Create indicator variable for low birth weight */
%create_flags(merged_units, merged_flagged);
%create_flags(left_units, left_flagged);

/*********************************************************

## 4. Data Export

**********************************************************/

/* Inspect data prior to export */
PROC PRINT data = merged_flagged (obs = 20); 									/* inspect data */
TITLE "Merged (inner join) dataset";
RUN;								
PROC FREQ data = merged_flagged;												/* inspect proportions */
TABLE lbw_flag;
FORMAT lbw_flag lbw.;															/* apply format from includes */
RUN;

PROC PRINT data = left_flagged (obs = 20); 										/* inspect data */
TITLE "Missings (left join) dataset";
RUN;									
PROC FREQ data = left_flagged;													/* inspect proportions */
TABLE lbw_flag;
FORMAT lbw_flag lbw.;															/* apply format from includes */
RUN;

/* Export data to a CSV */
PROC EXPORT DATA = merged_flagged												/* merged (inner join) data*/
	DBMS = CSV
	OUTFILE = "/home/u63125930/data/MCAH_lbw_inner.csv"							/* change local path and name */
	REPLACE;
RUN;

PROC EXPORT DATA = left_flagged													/* left join data */
	DBMS = CSV
	OUTFILE = "/home/u63125930/data/MCAH_lbw_left.csv"							/* change local path and name */
	REPLACE;
RUN;