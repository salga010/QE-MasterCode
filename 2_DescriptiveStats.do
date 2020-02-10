// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the descriptive statistics 
// This version Feb 08, 2020
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
// You should change the below directory. 

*global maindir ="/Users/serdar/Dropbox/GLOBAL-MASTER-CODE/STATA/"
global maindir ="/Users/ssalgado/Dropbox/GLOBAL-MASTER-CODE/STATA/"

// Do not make change from here on. Contact Ozkan/Salgado if changes are needed. 
do "$maindir/do/0_Initialize.do"

// Create folder for output and log-file
global outfolder=c(current_date)
global outfolder="$outfolder Descriptive_Stat"
capture noisily mkdir "$maindir${sep}out${sep}$outfolder"
capture log close
capture noisily log using "$maindir${sep}log${sep}$outfolder.log", replace

// Cd to the output file, create the program for moments, and load base sample.
cd "$maindir${sep}out${sep}$outfolder"
do "$maindir${sep}do${sep}myprogs.do"		

timer clear 1
timer on 1

// Loop over samples
foreach spl in CS LX H{

// Loop over the years
if "`spl'" == "CS" {
	local fsrtyr = $yrfirst
	local lastyr = $yrlast
}
else if "`spl'" == "LX" {
	local fsrtyr = $yrfirst
	local lastyr = $yrlast - 5		// So 5 year changes are present in the sample
}
else if "`spl'" == "H" {
	local fsrtyr = $yrfirst + 2		// So perm   income is present in the sample
	local lastyr = $yrlast - 5		// So 5 year change is present in the sample
}

forvalues yr = `fsrtyr'/`lastyr'{
*foreach yr of numlist $yrlist{

	disp("Working in year `yr' for Sample `spl'")
	if "`spl'" == "CS" {
		use  male yob educ labor`yr' using ///
			"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear  	
	}
	else if "`spl'" == "LX" {
		use  male yob educ labor`yr' researn1F`yr' researn5F`yr' using ///
			"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear  	
	}
	else if "`spl'" == "H" {
		use  male yob educ labor`yr' researn1F`yr' researn5F`yr' permearn`yr' using ///
			"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear  	
	}
	
	// Create year
	gen year=`yr'
	
	// Create age (This applies to all samples)
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}
	
	// Select CS sample (Individual has earnings above min treshold)
	if "`spl'" == "CS"{
		qui: keep if labor`yr'>=rmininc[`yr'-${yrfirst}+1,1] & labor`yr'!=. 
	}
	
	// Select LX sample (Individual has 1 and 5 yr residual earnings change)
	if "`spl'" == "LX"{
		qui: keep if researn1F`yr'!=. & researn5F`yr'!= . 
	}
	
	// Select H sample (Individual has permanent income measure)
	if "`spl'" == "H"{
		qui: keep if researn1F`yr'!=. & researn5F`yr'!= . 
		qui: keep if permearn`yr' != . 
	}
	
	// Transform to US dollars
	local er_index = `yr'-${yrfirst}+1
	qui: replace labor`yr' = labor`yr'/exrate[`er_index',1]
	
	// Calculate cross sectional moments for year `yr'
	rename labor`yr' labor 	

	bymysum "labor" "L_" "_`yr'" "year"
	bymysum "labor" "L_" "_male`yr'" "year male"
	
	bymyPCT "labor" "L_" "_`yr'" "year"
	bymyPCT "labor" "L_" "_male`yr'" "year male"
		
	collapse (count) numobs = labor, by(year male educ age)
	order year male educ age numobs
	qui: save "numobs`yr'.dta", replace
	
} // END of loop over years

* Collects number of observations data across years (for what did we need this?)
clear
forvalues yr = `fsrtyr'/`lastyr'{
	append using "numobs`yr'.dta"
	erase "numobs`yr'.dta"	
}
outsheet using "$maindir${sep}out${sep}$outfolder/`spl'_cross_tabulation.csv", replace comma


// Collects descriptive statistics across years

clear
forvalues yr = `fsrtyr'/`lastyr'{
	use "S_L_labor_`yr'.dta"
	merge 1:1 year using "PC_L_labor_`yr'.dta",  nogenerate 
	
	erase "S_L_labor_`yr'.dta"
	erase "PC_L_labor_`yr'.dta"
	save "L_labor_`yr'.dta", replace 
	
	use "S_L_labor_male`yr'.dta"
	merge 1:1 year male using "PC_L_labor_male`yr'.dta", nogenerate 
	
	erase "S_L_labor_male`yr'.dta"
	erase "PC_L_labor_male`yr'.dta"
	save "L_labor_male`yr'.dta", replace 
}

clear 
forvalues yr = `fsrtyr'/`lastyr'{
	append using "L_labor_`yr'.dta"
	erase "L_labor_`yr'.dta"
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`spl'_labor_yr_sum_stats.csv", replace comma

clear 
forvalues yr = `fsrtyr'/`lastyr'{
	append using "L_labor_male`yr'.dta"
	erase "L_labor_male`yr'.dta"
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`spl'_labor_yrgender_sum_stats.csv", replace comma
	
} // END of loop over samples 

*Save the age education dummies for residual log earnings
use "$maindir${sep}dta${sep}age_educ_dums.dta", clear
outsheet using "$maindir${sep}out${sep}$outfolder/age_educ_dums.csv", replace comma

*Save the age education dummies for residual log earnings
use "$maindir${sep}dta${sep}age_dums.dta", clear
outsheet using "$maindir${sep}out${sep}$outfolder/age_dums.csv", replace comma

// END OF THE CODE 
