// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This code specify country-specific variables.  
// This version April 21, 2019
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// PLEASE DO NOT CHANGE VALUES FRM LINE 7 TO 20. IF NEEDS TO BE CHANGED, CONTACT Ozkan/Salgado

set more off
set matsize 500
set linesize 255
version 13  // This program uses Stata version 13. 

global begin_age = 25 		// Starting age
global end_age = 55			// Ending age
global base_price = 2018	// The base year nominal values are converted to real. 
global winsor=99.999999		// The values above this percentile are going to be set to this percentile. 
global noise=0.0			// The values above this percentile are going to be set to this percentile. 


// PLEASE MAKE THE APPROPRIATE CHANGES BELOW. 

global unix=1  // Please change this to 1 if you run stata on Unix or Mac

global wide=0  // Please change this to 1 if your raw data is in wide format; 0 if long. 

if($unix==1){
	global sep="/"
}
else{
	global sep="\"
}
// If there are missing observations for earnings between $begin_age and $end_age
// set the below global to 1. Otherwise, the code will convert all missing earnings
// observations to zero.
global miss_earn=0 

//Please change the below to the name of the actual data set
global datafile="$maindir${sep}dta${sep}data_long" 

// Define the variable names in your dataset.
global personid_var="idnr" 	// The variable name for person identity number.
global male_var="male" 		// The variable name for gender: 1 if male, 0 o/w.
global yob_var="b_year" 	// The variable name for year of birth.
global yod_var="yod" 		// The variable name for year of death.
global educ_var="educ" 		// The variable name for year of death.
global labor_var="wage_inc" // The variable name for total annual labor earnings from all jobs during the year.  
global year_var="year" 		// The variable name for year if the data is in long format


// Define these variables for your dataset
global yrfirst = 1993 		// First year in the dataset 
global yrlast =  2014 		// Last year in the dataset

global kyear = 5
	// This controls the years for which the empirical densities will be calculated.
	// The densisity is calculated every mod(year/kyear) == 0. Set to 1 if 
	// every year is needed (If need changes, contact  Ozkan/Salgado)
	
global nquantiles = 40
	// Number of quantiles used in the statistics conditioning on permanent income
	// One additional quintile will be added at the top for a total of 41 (see Guidelines)
		
global nquantilesalt = 40
	// Number of quantiles used in the statistics conditioning on the alternative measure of permanent income
	
global nquantilestran = 10 
	// Number of quantiles used in the age transition matrix
		
global hetgroup = `" male age educ "male age" "male educ" "male educ age" "' 
	// Define heterogenous groups for which time series stats will be calculated 

// Price index for converting nominal values to real, e.g., the PCE for the US.  
// IMPORTANT: Please set the CPI starting from year ${yrfirst} and ending in ${yrlast}.

global cpi2018 = 110.007		// Set the value of the CPI in 2018. 
matrix cpimat = /*  CPI between ${yrfirst}  and ${yrlast}
*/ (71.436, 73.034, 74.625, 76.04, 77.382, 78.366, 79.425, 80.804, 82.258, 83.639, 84.837, /*
*/  86.515, 88.373, 90.392, 92.378, 94.225, 95.315,96.608, 98.139, 100, 101.526, 103.168 )'

matrix cpimat = cpimat/${cpi2018}

matrix exrate = /*  Nominal average exchange rate from FRED between ${yrfirst}  and ${yrlast} (LC per dollar)
*/ (7.101,7.055,6.335,6.459,7.086,7.552,7.807,8.813,8.996,7.984, /*
*/	7.080,6.740,6.441,6.409,5.856,5.637,6.291,6.045,5.602,5.818, /*
*/	5.877)'



// The below part uses US minimum wage values to create the minimum income threshold. 
// If your country does not have a minimum wage, and you want to use the US specific threshold
// then do not make any changes below.

// If your country has a minimum wage, then use the commented out part below. 

// Or if you want to use  a percentage criterion, then you need to specify those rmininc values.

// CREATING MINIMUM INCOME THRESHOLD USING US MINIMUM WAGE  

matrix minwgus = /* Nominal minimum wage 1959-2018 in the US
*/ (1.00,1.00,1.00,1.15,1.15,1.25,1.25,1.25,1.25,1.40,1.60,1.60,1.60,1.60,/*
*/  1.60,1.60,2.00,2.10,2.10,2.30,2.65,2.90,3.10,3.35,3.35,3.35,3.35,3.35,/*
*/  3.35,3.35,3.35,3.35,3.80,4.25,4.25,4.25,4.25,4.25,4.75,5.15,5.15,5.15,/*
*/  5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.85,6.55,7.25,7.25,7.25,7.25,7.25,/*
*/  7.25,7.25,7.25)'

local yinic = ${yrfirst} - 1959 + 1						
local yend = ${yrlast} - 1959 + 1

matrix minincus = 260*minwgus[`yinic'..`yend',1]		// Nominal min income in the US
														// This uses the factor of 260 given in the Guidelines
matrix rmininc = J(${yrlast}-${yrfirst}+1,1,0)
local i = 1
local tnum = ${yrlast}-${yrfirst}+1
forvalues pp = 1(1)`tnum'{
	matrix rmininc[`i',1] = minincus[`i',1]*exrate[`i',1]/cpimat[`i',1]					
					// real min income threshold in local currency 
	local i = `i' + 1
}

// CREATING MINIMUM INCOME THRESHOLD USING COUNTRY SPECIFIC MINIMUM WAGE  
/*
matrix minwg_C = /* Nominal minimum wage 1959-2018 in YOUR COUNTRY
*/ (1.00,1.00,1.00,1.15,1.15,1.25,1.25,1.25,1.25,1.40,1.60,1.60,1.60,1.60,/*
*/  1.60,1.60,2.00,2.10,2.10,2.30,2.65,2.90,3.10,3.35,3.35,3.35,3.35,3.35,/*
*/  3.35,3.35,3.35,3.35,3.80,4.25,4.25,4.25,4.25,4.25,4.75,5.15,5.15,5.15,/*
*/  5.15,5.15,5.15,5.15,5.15,5.15,5.15,5.85,6.55,7.25,7.25,7.25,7.25,7.25,/*
*/  7.25,7.25,7.25)'

// Change 1959 to the first year in your minwg_C matrix
local yinic = ${yrfirst} - 1959 + 1	
local yend = ${yrlast} - 1959 + 1

matrix mininc_C = 260*minwg_C[`yinic'..`yend',1]		// Nominal min income in the US
														// This uses the factor of 260 given in the Guidelines
matrix rmininc = J(${yrlast}-${yrfirst}+1,1,0)
local i = 1
local tnum = ${yrlast}-${yrfirst}+1
forvalues pp = 1(1)`tnum'{
	matrix rmininc[`i',1] = 100*mininc_C[`i',1]/cpimat[`i',1]					
					// real min income threshold in local currency 
	local i = `i' + 1
}
*/

// CREATING MINIMUM INCOME THRESHOLD USING CUSTOM VALUES 
// (E.G., the bottom 23% of the gender, combined earnings distribution, etc.)  
/*
matrix rmininc = /* REAL MINIMUM INCOME THRESHOLD ${yrfirst}-${yrlast} in YOUR COUNTRY
*/ (1.00,1.00,1.00,1.15,1.15,1.25,1.25,1.25,1.25,1.40,1.60,1.60,1.60,/*
*/  1.60,1.60,2.00,2.10,2.10,2.30,2.65,2.90,3.10,3.35,3.35,3.35)'
*/











// PLEASE DO NOT CHANGE THIS PART. IF NEEDS TO BE CHANGED, CONTACT Ozkan/Salgado


*global yrlist = ///
*	"${yrfirst} 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ${yrlast}"
*	// Define the years for which the inequality and concetration measures are calculated

global  yrlist = ""
forvalues yr = $yrfirst(1)$yrlast{
	global yrlist = "${yrlist} `yr'"
}		
	
*global d1yrlist = ///
*	"1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012"
	// Define years for which one-year log-changes measures are calculated

global d1yrlist = ""
local tempyr = $yrlast-1
forvalues yr = $yrfirst(1)`tempyr'{
	global d1yrlist = "${d1yrlist} `yr'"
}
	
*global d5yrlist = ///
*	"1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008"
	// Define years t for which five-years log-changes between t+5 and t are calculated
	
global d5yrlist = "$yrfirst"
local tempyrb = $yrfirst+1
local tempyr = $yrlast-5
forvalues yr = `tempyrb'(1)`tempyr'{
	local tmp = ",`yr'"
	global d5yrlist = "${d5yrlist}`tmp'"
}	
	
*global perm3yrlist = /// 
*	"1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,${yrlast}"
	// Define the ending years (t) to construct permanent income between t-2 and t 
	
local tempyrb = $yrfirst+2	
global perm3yrlist = "`tempyrb'"
local tempyrb = $yrfirst+3	
local tempyre = $yrlast
forvalues yr = `tempyrb'(1)`tempyre'{
	local tmp = ",`yr'"
	global perm3yrlist = "${perm3yrlist}`tmp'"
}	

