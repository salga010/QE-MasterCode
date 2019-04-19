// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of Volatility and Higher Order Moments
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
global outfolder="$outfolder Volatility"
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
	*local yr = 2008
	
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
		// If permanent income CAN be calculated (H Sample)
		if inlist(`yr',${d5yrlist}){	// Has 5yr change (LX Sample)
			use  male yob educ researn1F`yr' researn5F`yr' logearn`yr' permearn`yrp' ///
				if logearn`yr'~=. using ///
			"$maindir${sep}dta${sep}master_sample.dta", clear   
		}
		else{
			use  male yob educ researn1F`yr' logearn`yr' permearn`yrp' ///
				if logearn`yr'~=. using ///
			"$maindir${sep}dta${sep}master_sample.dta", clear   
		}
	}
	else{
		// If permanent income CANNOT be calculated (LX sample)
		if inlist(`yr',${d5yrlist}){  // Has 5yr change (LX Sample)
			use  male yob educ researn1F`yr' researn5F`yr' logearn`yr' if logearn`yr'~=. using ///
			"$maindir${sep}dta${sep}master_sample.dta", clear   
		}
		else{
			use  male yob educ researn1F`yr' logearn`yr' if logearn`yr'~=. using ///
			"$maindir${sep}dta${sep}master_sample.dta", clear   
		}
	}
	
	// Drop logearn (not used in this code)
	drop logearn
	
	// Create year
	gen year=`yr'
	
	// Create age 
	gen age = `yr'-yob+1
	qui: drop if age<${begin_age} | age>${end_age}

	// Create age groups 
	qui {
		gen agegp = . 
		replace agegp = 1 if age<= 34 & agegp == .
		replace agegp = 2 if age<= 44 & agegp == .
		replace agegp = 3 if age > 44 & agegp == .
	}
	
	// Moments of 1 year changes
	// Calculate cross sectional moments for year `yr'
	bymysum_detail "researn1F" "L_" "_`yr'" "year"
	
	bymyPCT "researn1F" "L_" "_`yr'" "year"
	
	// Calculate cross sectional moments for year `yr' within heterogeneity groups
	foreach  vv in $hetgroup{ 
		local suf=subinstr("`vv'"," ","",.)
		
		bymysum_detail "researn1F" "L_" "_`suf'`yr'" "year `vv'"
	
		bymyPCT "researn1F" "L_" "_`suf'`yr'" "year `vv'"
	}

	// Moments of 5 year changes
	if inlist(`yr',${d5yrlist}){
		bymysum_detail "researn5F" "L_" "_`yr'" "year"
	
		bymyPCT "researn5F" "L_" "_`yr'" "year"
		
		foreach  vv in $hetgroup{ 
			local suf=subinstr("`vv'"," ","",.)
		
			bymysum_detail "researn5F" "L_" "_`suf'`yr'" "year `vv'"
	
			bymyPCT "researn5F" "L_" "_`suf'`yr'" "year `vv'"
		}
	}
	
	// Calculate Empirical Density of one year and 5 years changes 
	// Notice we are doing this for years that can be divided by kyear
	if mod(`yr',${kyear}) == 0 {
		bymyKDN "researn1F" "L_" "${kpoints}" "`yr'"
		if inlist(`yr',${d5yrlist}){
		bymyKDN "researn5F" "L_" "${kpoints}" "`yr'"
		}
	}

	// Moments within percentiles of the permanent income distribution
	// for the years in which permanent income and 5 yr changes can be 
	// calculated (H sample of the guidelines)
	
	if inlist(`yrp',${perm3yrlist}){
		*If 5-year changes are possible
		if inlist(`yr',${d5yrlist}){
			// Overall ranking 
			// Ranking created for those individuals that have measure of earnings growth
			gen permrank = .
			gen permearntemp = permearn if researn1F != . & researn5F != .			
			
			bymyxtile permearntemp permrank "${nquantiles}"	// This puts individuals into nquantiles bins
			if ${nquantiles} < 100{
				egen aux = pctile(permearntemp), p(99)
				replace permrank = ${nquantiles} + 1 if permearntemp > aux & permearntemp !=. 
			}
			drop aux
			
			bymysum_detail "researn1F" "L_" "_allrank`yr'" "year permrank"
			bymyPCT "researn1F" "L_" "_allrank`yr'" "year permrank"
			drop permrank 
			
			//Within age group rankings
			gen permrank = .
			bys agegp: bymyxtile permearntemp permrank "${nquantiles}"	
			if ${nquantiles} < 100{
				bys agegp: egen aux = pctile(permearntemp), p(99)
				replace permrank = ${nquantiles} + 1 if permearntemp > aux & permearntemp !=. 
			}
			drop aux
			
			bymysum_detail "researn1F" "L_" "_agerank`yr'" "year agegp permrank"
			bymyPCT "researn1F" "L_" "_agerank`yr'" "year agegp permrank"
			
			
			// Within permanent income top earners groups
			_pctile permearntemp, p(99 99.9)
			local top1 = r(r1)
			local top01 = r(r2)
			
			// Top 1%
			gen top1 = permearntemp >= `top1' & permearntemp !=. 
			bymysum_detail "researn1F" "L_" "_top1`yr'" "year top1"
			bymyPCT "researn1F" "L_" "_top1`yr'" "year top1"
			drop top1
			
			// Top 0.1%
			gen top0_1 = permearntemp >= `top01' & permearntemp !=. 
			bymysum_detail "researn1F" "L_" "_top0_1`yr'" "year top0_1"
			bymyPCT "researn1F" "L_" "_top0_1`yr'" "year top0_1"
			drop top0_1
			
			// Top 1% ex 0.1%
			gen top1ex0_1 = (permearntemp >= `top1' & permearntemp < `top01')
			bymysum_detail "researn1F" "L_" "_top1ex0_1`yr'" "year top1ex0_1"
			bymyPCT "researn1F" "L_" "_top1ex0_1`yr'" "year top1ex0_1"
			drop top1ex0_1
			
			// Drop rank and temp permnanent income and move to 5-year change
			drop permrank permearntemp
				
			// Ranking created for those individuals that have measure of earnings growth
			gen permrank = .
			gen permearntemp = permearn if researn1F != . & researn5F != .		
			bymyxtile permearntemp permrank "${nquantiles}"	
			if ${nquantiles} < 100{
				egen aux = pctile(permearntemp), p(99)
				replace permrank = ${nquantiles} + 1 if permearntemp > aux & permearntemp !=. 
			}
			drop aux
			
			bymysum_detail "researn5F" "L_" "_allrank`yr'" "year permrank"
			bymyPCT "researn5F" "L_" "_allrank`yr'" "year permrank"
			drop permrank 
			
			//Within age group rankings
			gen permrank = .
			bys agegp: bymyxtile permearntemp permrank "${nquantiles}"
			if ${nquantiles} < 100{
				bys agegp: egen aux = pctile(permearntemp), p(99)
				replace permrank = ${nquantiles} + 1 if permearntemp > aux & permearntemp !=. 
			}
			drop aux
			
			bymysum_detail "researn5F" "L_" "_agerank`yr'" "year agegp permrank"
			
			bymyPCT "researn5F" "L_" "_agerank`yr'" "year agegp permrank"
			
			drop permrank permearntemp
		} // END if 5-years available
	} // END if Per income is available	
*
	
	
} // END of loop over years


// Collect data across years  for the 1-year change measure
clear

foreach vari in researn1F{

foreach yr of numlist $d1yrlist{
	local yrp = `yr' - 1

	*Stats 
	use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
	merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta", ///
		nogenerate
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta"
	
	save "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta", replace
	
	if inlist(`yrp',${perm3yrlist}){
		if inlist(`yr',${d5yrlist}){
		*Stats per rank
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta", clear
		merge 1:1 year permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta", replace
		
		*Stats per rank within age gp
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta", clear
		merge 1:1 year age permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta", replace
		
		*Top earners 1
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_top1`yr'.dta", clear
		merge 1:1 year top1 using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_top1`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_top1`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_top1`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_top1`yr'.dta", replace
		
		*Top earners 0.1
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_top0_1`yr'.dta", clear
		merge 1:1 year top0_1 using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_top0_1`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_top0_1`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_top0_1`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_top0_1`yr'.dta", replace
		
		*Top earners 1 ex top 0.1
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_top1ex0_1`yr'.dta", clear
		merge 1:1 year top1ex0_1 using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_top1ex0_1`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_top1ex0_1`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_top1ex0_1`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_top1ex0_1`yr'.dta", replace
		}
	}
	***
	
}
clear 
foreach yr of numlist $d1yrlist{
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"	
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_sumstat.csv", replace comma
clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank.csv", replace comma

clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank.csv", replace comma

clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_top1`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_top1`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_top0_1.csv", replace comma
clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_top0_1`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_top0_1`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_top0_1.csv", replace comma

clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_top1ex0_1`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_top1ex0_1`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_top1ex0_1.csv", replace comma


// Collect data across all years and heterogeneity groups. saves one database per group 
foreach  vv in $hetgroup{

	clear 
	local suf=subinstr("`vv'"," ","",.)
	foreach yr of numlist $d1yrlist{
		
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta", clear
		merge 1:1 year `vv' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta", ///
			nogenerate	
			
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta", replace
	}	
	clear 
	foreach yr of numlist $d1yrlist{
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
	}
	
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'_sumstat.csv", replace comma 		
} 	// END loop over heterogeneity group

}	// END loop over variables 


// Collect moments for the 5-years change measure

foreach vari in researn5F {

foreach yr of numlist $d5yrlist{

	*Stats
	use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
	merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta", ///
		nogenerate
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta"
	
	save "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta", replace
	
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
		*Stats per rank
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta", clear
		merge 1:1 year permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_allrank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_allrank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta", replace
		
		*Stats per rank within age gp
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta", clear
		merge 1:1 year agegp permrank using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta", ///
			nogenerate
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_agerank`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_agerank`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta", replace
	}
}
clear 
foreach yr of numlist $d5yrlist{
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`yr'.dta"	
}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_sumstat.csv", replace comma

clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank`yr'.dta"
	}
}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_allrank.csv", replace comma

clear
foreach yr of numlist $d5yrlist{
	local yrp = `yr' - 1
	if inlist(`yrp',${perm3yrlist}){
	append using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank`yr'.dta"
	}
}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_agerank.csv", replace comma


// Collect data across all years and heterogeneity groups. saves one database per group 
foreach  vv in $hetgroup{

	clear 
	local suf=subinstr("`vv'"," ","",.)
	foreach yr of numlist $d5yrlist{
		
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta", clear
		merge 1:1 year `vv' using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta", ///
			nogenerate	
			
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`suf'`yr'.dta"
		
		save "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta", replace
	}	
	clear 
	foreach yr of numlist $d5yrlist{
		append using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'`yr'.dta"
	}
	
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_`suf'_sumstat.csv", replace comma 		
} 	// END loop over heterogeneity group

}	// END loop over variables 

set more off

//Collect data for empirical density 
foreach k in 1 5{
	local i=1
	if `k' == 1{
		foreach yr in $d1yrlist{
			if mod(`yr',${kyear}) == 0 {
				if(`i'==1){
				use "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", clear
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				else{
				merge 1:1 index using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", nogen
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				local i=`i'+1
			}
		} 
		outsheet using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_hist.csv", replace comma
	}
	else{
		foreach yr of numlist $d5yrlist{
			if mod(`yr',${kyear}) == 0 {
				if(`i'==1){
				use "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", clear
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				else{
				merge 1:1 index using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta", nogen
				erase "$maindir${sep}out${sep}$outfolder/L_researn`k'F_`yr'_hist.dta"
				}
				local i=`i'+1
			}
		} 
		outsheet using "$maindir${sep}out${sep}$outfolder/L_researn`k'F_hist.csv", replace comma
	}
}
timer off 1
timer list 1

*END OF THE CODE 
