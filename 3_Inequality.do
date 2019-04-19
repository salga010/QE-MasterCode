// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of concetration and inequality
// This version April 17, 2019
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
// You should change the below directory. 

*global maindir ="/Users/serdar/Dropbox/GLOBAL-MASTER-CODE/STATA/"
global maindir ="/Users/sergiosalgado/Dropbox/GLOBAL-MASTER-CODE/STATA/"

// Do not make change from here on. Contact Ozkan/Salgado if changes are needed. 
do "$maindir/do/0_Initialize.do"

// Create folder for output and log-file
global outfolder=c(current_date)
global outfolder="$outfolder Inequality"
capture noisily mkdir "$maindir${sep}out${sep}$outfolder"
capture log close
capture noisily log using "$maindir${sep}log${sep}$outfolder.log", replace

// Cd to the output file, create the program for moments, and load base sample.
cd "$maindir${sep}out${sep}$outfolder"
do "$maindir${sep}do${sep}myprogs.do"		

// Defines the number of points in the Kernel Density Estimator
global kpoints =  1000

// Loop over the years
timer clear 1
timer on 1

foreach yr of numlist $yrlist{
	disp("Working in year `yr'")
	
	if inlist(`yr',${perm3yrlist}){
		use  male yob educ labor`yr' logearn`yr' researn`yr' permearn`yr' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear   
	}
	else{
		use  male yob educ labor`yr' logearn`yr' researn`yr' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear   
	}
	// Create year
	gen year=`yr'
	
	// Create age and restrict to CS sample
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}
	
	// Drop if log earnings does not exist
	qui: drop if logearn==.
	
	// Gen earnings
	gen earn = labor`yr' if labor`yr'>=rmininc[`yr'-${yrfirst}+1,1]
	
	// A1. Moments of log earnings
	// Calculate cross sectional moments for year `yr'
	
	bymysum "logearn" "L_" "_`yr'" "year"
	
	bymyPCT "logearn" "L_" "_`yr'" "year"
	
	// Calculate cross sectional moments for year `yr' within heterogeneity groups
	foreach  vv in $hetgroup{ 
		local suf=subinstr("`vv'"," ","",.)
		
		bymysum "logearn" "L_" "_`suf'`yr'" "year `vv'"
	
		bymyPCT "logearn" "L_" "_`suf'`yr'" "year `vv'"
	}
	
	// A2. Moments of Residuals
	bymysum "researn" "L_" "_`yr'" "year"
	
	bymyPCT "researn" "L_" "_`yr'" "year"
	
	// Calculate cross sectional moments for year `yr' within heterogeneity groups
	foreach  vv in $hetgroup{ 
		local suf=subinstr("`vv'"," ","",.)
		
		bymysum "researn" "L_" "_`suf'`yr'" "year `vv'"
	
		bymyPCT "researn" "L_" "_`suf'`yr'" "year `vv'"
	}
	
	// B4. Moments of Permanent Income
	if inlist(`yr',${perm3yrlist}){
		bymysum "permearn" "L_" "_`yr'" "year"
	
		bymyPCT "permearn" "L_" "_`yr'" "year"
		
		foreach  vv in $hetgroup{ 
			local suf=subinstr("`vv'"," ","",.)
		
			bymysum "permearn" "L_" "_`suf'`yr'" "year `vv'"
	
			bymyPCT "permearn" "L_" "_`suf'`yr'" "year `vv'"
		}
	}
	
	// Calculate Empirical Density 
	if mod(`yr',${kyear}) == 0 {
		bymyKDN "logearn" "L_" "${kpoints}" "`yr'"
		
		bymyKDNmale "logearn" "L_" "${kpoints}" "`yr'"
		
	}

	
	// Calculate measures of concentration
	bymyCNT "earn" "L_" "`yr'" 	
	
} // END of loop over years


// Collect data across years 
clear

foreach vari in logearn researn {

foreach yr of numlist $yrlist{

	use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
	merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta", ///
		nogenerate
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta"
	
	save "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta", replace
}
clear 
foreach yr of numlist $yrlist{
	
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"	

}

outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_sumstat.csv", replace comma

// Collect data across all years and heterogeneity groups. saves one output file per group 
foreach  vv in $hetgroup{

	clear 
	local suf=subinstr("`vv'"," ","",.)
	foreach yr of numlist $yrlist{
		
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta", clear
		merge 1:1 year `vv' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta", ///
			nogenerate	
			
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta", replace
	}	
	clear 
	foreach yr of numlist $yrlist{
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
	}
	
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'_sumstat.csv", replace comma 		
} 	// END loop over heterogeneity group

}	// END loop over variables 


// Collect moments for the permanent income measure

foreach vari in permearn {

foreach yr of numlist $perm3yrlist{

	use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
	merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta", ///
		nogenerate
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta"
	
	save "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta", replace
}
clear 
foreach yr of numlist $perm3yrlist{
	
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"	

}

outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_sumstat.csv", replace comma

// Collect data across all years and heterogeneity groups. saves one output file per group 
foreach  vv in $hetgroup{

	clear 
	local suf=subinstr("`vv'"," ","",.)
	foreach yr of numlist $perm3yrlist{
		
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta", clear
		merge 1:1 year `vv' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta", ///
			nogenerate	
			
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta", replace
	}	
	clear 
	foreach yr of numlist $perm3yrlist{
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
	}
	
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'_sumstat.csv", replace comma 		
} 	// END loop over heterogeneity group

}	// END loop over variables 

set more off

//Collect data for empirical density (all)
local i=1
foreach yr of numlist $yrlist{

	if mod(`yr',${kyear}) == 0 {
		if(`i'==1){
		use "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist.dta", clear
		erase "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist.dta"
		}
		else{
		merge 1:1 index using "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist.dta", nogen
		erase "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist.dta"
		}
		local i=`i'+1
	}
	
} 
outsheet using "$maindir${sep}out${sep}$outfolder/L_logearn_hist.csv", replace comma


//Collect data for empirical density (male)
local i=1
foreach yr of numlist $yrlist{

	if mod(`yr',${kyear}) == 0 {
		if(`i'==1){
		use "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist_male.dta", clear
		erase "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist_male.dta"
		}
		else{
		merge 1:1 index male using "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist_male.dta", nogen
		erase "$maindir${sep}out${sep}$outfolder/L_logearn_`yr'_hist_male.dta"
		}
		local i=`i'+1
	}
	
} 
outsheet using "$maindir${sep}out${sep}$outfolder/L_logearn_hist_male.csv", replace comma


// Collect data across years for the concentration measures 
clear
foreach yr of numlist $yrlist{
	append using "$maindir${sep}out${sep}$outfolder/L_earn_`yr'_con.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_earn_`yr'_con.dta"	
} 
//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con.csv", replace comma
// Time series statistics for annual earnings is computed above! 


timer off 1
timer list 1

*END OF THE CODE 
