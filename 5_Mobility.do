// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of Mobility
// Last edition Feb, 21, 2019
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
// You should change the below directory. 

*global maindir ="/Users/serdar/Dropbox/GLOBAL-MASTER-CODE/STATA/"
global maindir ="/Users/sergiosalgado/Dropbox/GLOBAL-MASTER-CODE/STATA/"

// Do not make changes from here on. Contact Ozkan/Salgado if changes are needed. 
do "$maindir/do/0_Initialize.do"

// Create folder for output and log-file
global outfolder=c(current_date)
global outfolder="$outfolder Mobility"
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
foreach yr of numlist $d1yrlist{
	disp("Working in year `yr'")
	local yrp1 = `yr'+1
	local yrp5 = `yr'+5
	
	if inlist(`yr',${d5yrlist}){
		use  male yob educ researn`yr' researn`yrp1' researn`yrp5' logearn`yr' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if logearn`yr'~=. , clear   
	}
	else{
		use  male yob educ researn`yr' researn`yrp1'  logearn`yr' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if logearn`yr'~=. , clear   
	}
	
	//Drop log earnings (not used in this code)
	qui: drop logearn`yr'
	
	// Create year
	gen year=`yr'
	
	// Create age 
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}
	
	// Create the percentiles in year t	
	qui: gen rankt = .
	qui: bymyxtile researn`yr' rankt "100"
	
	// Create the percentiles in year + 1
	qui: gen ranktp1 = .
	qui: bymyxtile researn`yrp1' ranktp1 "100"
	
	// Calculate average percentile in t+1 conditional on percentile in p
	qui: bymysum_meanonly "ranktp1" "L_" "_`yr'" "year rankt"
	
	// Create the percentiles in t+5
	if inlist(`yr',${d5yrlist}){
		qui: gen ranktp5 = .
		qui: bymyxtile researn`yrp5' ranktp5 "100"
		qui: bymysum_meanonly "ranktp5" "L_" "_`yr'" "year rankt"
	}
	
	
} // END of loop over years

*
// Collect data across years 
clear

foreach vari in ranktp1{
clear 
foreach yr of numlist $d1yrlist{
	
	append using "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"	
}

outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_mobstat.csv", replace comma
}

foreach vari in ranktp5 {
clear 
foreach yr of numlist $d5yrlist{
	append using "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"	
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_mobstat.csv", replace comma
}

timer off 1
timer list 1

*END OF THE CODE 
