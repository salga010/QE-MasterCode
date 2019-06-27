// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of concetration and inequality
// This version June 20, 2019
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
set type double
 
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
global kpoints =  400

// Loop over the years
timer clear 1
timer on 1

*Concetrations measures as in Gomez 2018
foreach yr of numlist $yrlist{
	*local yr = 1995
	if `yr' <= ${yrlast} - 1{
	
	disp("Working in year `yr'")
	local yrp = `yr' + 1
	
	// Load data 
	use  male yob yod educ labor`yr' labor`yrp' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if (labor`yr'~=. | labor`yrp'~=.) , clear   
	
	// Create year
	gen year=`yr'
	
	// Create age and restrict to CS sample
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} - 1 | age>${end_age}			// This keep 24 to 55 yrs old individuals
	
	// Rename labor income to earn in t and earn in t+p
	rename labor`yr' earn
	rename labor`yrp' earnp1 
		
	// Calculate measures of concetration and mobility at the top using 
	// the decomposition of Matthieu Gomez "Displacement and the Rise in Top Wealth Inequality"
	// This case is with population change as in equation (22) of the paper
	
	bymyCNTgPop "earn" "L_" "`yr'" "1"	"${qpercent}" ""
	
	*For men and women
	forvalues mm = 0/1{
		bymyCNTgPop "earn" "L_" "`yr'" "1"	"${qpercent}" "`mm'"
	}
	
	}	
}	// END loop over years 
*/

foreach yr of numlist $yrlist{
	disp("Working in year `yr'")
	*local yr = 1995
	// Define some variables to calculate
	local moreearn = ""
	if `yr' <= ${yrlast} - 1{
		local yrp = `yr' + 1
		local moreearn = "labor`yrp'"
	}
	if `yr' <= ${yrlast} - 5{
		local yrp = `yr' + 5
		local moreearn = "`moreearn' labor`yrp'"
	}
	
	// Load data 
	if inlist(`yr',${perm3yrlist}){
		use  male yob educ labor`yr' logearn`yr' researn`yr' permearn`yr' `moreearn' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear   
	}
	else{
		use  male yob educ labor`yr' logearn`yr' researn`yr' `moreearn' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if labor`yr'~=. , clear   
	}
	
	// Create year
	gen year=`yr'
	
	// Create age and restrict to CS sample
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}
	
	// Drop if log earnings does not exist
	qui: drop if logearn==.
	
	// Gen earnings adjusted by the real min income
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
		
	// Calculate measure of concetration within heterogeneity groups
		qui{
		*Male & Female
		forvalues mm = 0/1{
			preserve
			keep if male == `mm'
			bymyCNT "earn" "L_male`mm'" "`yr'" 
			restore 
		}
		*Education groups
		levelsof(educ), local(edu)
		foreach ee of local edu{
			preserve
			keep if educ == `ee'
			bymyCNT "earn" "L_educ`ee'" "`yr'" 
			restore
		}
		*Age group 
		gen agegp = . 
		replace agegp = 1 if age <= 34 & agegp == .
		replace agegp = 2 if age <= 44 & agegp == .
		replace agegp = 3 if age <= 55 & agegp == .
		
		levelsof(agegp), local(agp)
		foreach aa of local agp{
			preserve
			keep if agegp == `aa'
			bymyCNT "earn" "L_age`aa'" "`yr'" 
			restore
		}
		
		*Same for men
		levelsof(educ) if male == 1, local(edu)
		foreach ee of local edu{
			preserve
			keep if male == 1
			keep if educ == `ee'
			bymyCNT "earn" "L_male1educ`ee'" "`yr'" 
			restore
		}
		
		levelsof(agegp) if male == 1, local(agp)
		foreach aa of local agp{
			preserve
			keep if male == 1
			keep if agegp == `aa'
			bymyCNT "earn" "L_male1age`aa'" "`yr'" 
			restore
		}
		*Same for women
		levelsof(educ) if male == 0, local(edu)
		foreach ee of local edu{
			preserve
			keep if male == 0
			keep if educ == `ee'
			bymyCNT "earn" "L_male0educ`ee'" "`yr'" 
			restore
		}
		
		levelsof(agegp) if male == 0, local(agp)
		foreach aa of local agp{
			preserve
			keep if male == 0
			keep if agegp == `aa'
			bymyCNT "earn" "L_male0age`aa'" "`yr'" 
			restore
		}
		}	// END of qui statement
		
} // END of loop over years

*

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

// Collect data across years for the concentration measures for heterogeneoty groups
	*Men and Women 
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 0 1{
		append using "$maindir${sep}out${sep}$outfolder/L_male`mm'earn_`yr'_con.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_male`mm'earn_`yr'_con.dta"	
		cap:gen male = `mm' 
		cap:replace male = `mm'  if male == .
		}
	} 
		//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
		order male
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_male.csv", replace comma

	*Age	
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3{
		append using "$maindir${sep}out${sep}$outfolder/L_age`mm'earn_`yr'_con.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_age`mm'earn_`yr'_con.dta"	
		cap:gen agegp = `mm' 
		cap:replace agegp = `mm'  if agegp == .
		}
	}	
		//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
		order agegp
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_age.csv", replace comma
	*Age and gender
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3{
		foreach aa in 0 1 {
			append using "$maindir${sep}out${sep}$outfolder/L_male`aa'age`mm'earn_`yr'_con.dta"
			erase "$maindir${sep}out${sep}$outfolder/L_male`aa'age`mm'earn_`yr'_con.dta"	
			cap:gen agegp = `mm' 
			cap:replace agegp = `mm'  if agegp == .
			cap:gen male = `mm' 
			cap:replace male = `mm'  if male == .
		}
		}
	}	
		//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
		order male agegp
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_male_age.csv", replace comma

	
	
	*Educ	
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3 4{
		append using "$maindir${sep}out${sep}$outfolder/L_educ`mm'earn_`yr'_con.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_educ`mm'earn_`yr'_con.dta"	
		cap:gen educ = `mm' 
		cap:replace educ = `mm'  if educ == .
		}
	}	
		//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
		order educ
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_educ.csv", replace comma
		
	*Education and Gender
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3 4{
		foreach aa in 0 1 {
		append using "$maindir${sep}out${sep}$outfolder/L_male`aa'educ`mm'earn_`yr'_con.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_male`aa'educ`mm'earn_`yr'_con.dta"	
		cap:gen educ = `mm' 
		cap:replace educ = `mm'  if educ == .
		cap:gen male = `mm' 
		cap:replace male = `mm'  if male == .
		}
		}
	}	
		//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
		order male educ
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_male_educ.csv", replace comma

	
// Collect data across years for the contration growth measures between t and t+1
clear
foreach yr of numlist $yrlist{
	if `yr' <= ${yrlast} - 1{
		append using "$maindir${sep}out${sep}$outfolder/L_earn_`yr'_gStPop1.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_earn_`yr'_gStPop1.dta"	
	}
} 
	//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
	outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_gStPop1.csv", replace comma
clear
foreach yr of numlist $yrlist{
	if `yr' <= ${yrlast} - 1{
		forvalues mm = 0/1{
		append using "$maindir${sep}out${sep}$outfolder/L_earn_`yr'_gStPop1_male`mm'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_earn_`yr'_gStPop1_male`mm'.dta"	
		}
	}
} 
	//save "$maindir${sep}out${sep}$outfolder/L_earn_con.dta", replace
	outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_gStPop1_male.csv", replace comma

timer off 1
timer list 1

*END OF THE CODE 
