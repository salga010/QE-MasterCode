// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of Mobility
// This version July 05, 2019
// Serdar Ozkan and Sergio Salgado
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
*
// Loop over the years
timer clear 1
timer on 1
foreach yr of numlist $d1yrlist{

	disp("Working in year `yr'")
	*local yr = 2003
	local yrp1 = `yr'+1
	local yrp5 = `yr'+5
	
	*What alt perm income data will be loaded
	*see mobility section
	local pervars ""
	if `yr' >= ${yrfirst}+1 & `yr' <= ${yrlast}-11{
	
		local yrt5 = `yr'+5			// Five yrs ahead
		local yrt10 = `yr'+10		// Ten years ahead
		local yrl3 = ${yrlast}-3	// Last year - 3 
		local pervars = "permearnalt`yr' permearnalt`yrt5' permearnalt`yrt10' permearnalt`yrl3'"
		
	}
	
	*Loading the data
	if inlist(`yr',${d5yrlist}){
		use  male yob educ researn`yr' researn`yrp1' researn`yrp5' logearn`yr' `pervars' using ///
		"$maindir${sep}dta${sep}master_sample.dta" if logearn`yr'~=. , clear   
	}
	else{
		use  male yob educ researn`yr' researn`yrp1'  logearn`yr'  using ///
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
	
	// Calculating Shorrocks mobility as in KSS (QJE,2010) using variance
	// modsho defined as  modsho 1-M =  var(average)/average(var)	see KSS page pp.97
	*qui: bymySho researn`yr' researn`yrp1' "Sho_" "year"
	
	
	// Create the percentiles in t+5
	if inlist(`yr',${d5yrlist}){
		qui: gen ranktp5 = .
		qui: bymyxtile researn`yrp5' ranktp5 "100"
		qui: bymysum_meanonly "ranktp5" "L_" "_`yr'" "year rankt"
	}
	
	// Calculate the ranking on the alter permanent income. This depends on what data is available 
	// at any given time. 
	// Notice the following calculates the ranks for periods in which t+5, t+10, and t+Tmax-3 are available
	
	if `yr' >= ${yrfirst}+1 & `yr' <= ${yrlast}-11{			
		// Set some options and variables 
		local yrt5 = `yr'+5			// Five yrs ahead
		local yrt10 = `yr'+10		// Ten years ahead
		local yrl3 = ${yrlast}-3	// Last year - 3 
			
		// Create age groups 
			qui {
			gen agegp = . 
			replace agegp = 1 if age<= 34 & agegp == .
			replace agegp = 2 if age<= 44 & agegp == .
			replace agegp = 3 if age > 44 & agegp == .
			}
		
		// Creates Rankings
	
		    *Calculate next period rank unconditional 
			global small_sp = 0.001
			gen permearnaltrankt = .
			*Create rank and average in year t+5
			preserve
				*Drop if both measures of alt perm are equal to small_sp 
				qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yrt5' <= $small_sp

				*Create rank in year t 	
				qui: bymyxtile permearnalt`yr' permearnaltrankt "${nquantilesalt}"
				
				qui: gen permearnaltranktp5 = .
				qui: bymyxtile permearnalt`yrt5' permearnaltranktp5 "${nquantilesalt}"
				qui: bymysum_meanonly "permearnaltranktp5" "L_" "_`yr'" "year permearnaltrankt"
				
			restore 
			
			*Create rank and average in year t+10
			preserve
				*Drop if both measures of alt perm are equal to small_sp 
				qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yrt10' <= $small_sp
				
				*Create rank in year t 	
				qui: bymyxtile permearnalt`yr' permearnaltrankt "${nquantilesalt}"
				
				qui: gen permearnaltranktp10 = .
				qui: bymyxtile permearnalt`yrt10' permearnaltranktp10 "${nquantilesalt}"
				qui: bymysum_meanonly "permearnaltranktp10" "L_" "_`yr'" "year permearnaltrankt"
			restore 	
			
			*Create rank and average in year Tmax-3
			preserve 
				*Drop if both measures of alt perm are equal to small_sp 
				qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yrl3' <= $small_sp
				
				*Create rank in year t 	
				qui: bymyxtile permearnalt`yr' permearnaltrankt "${nquantilesalt}"
				
				qui: gen permearnaltranktl3 = .
				qui: bymyxtile permearnalt`yrl3' permearnaltranktl3 "${nquantilesalt}"
				qui: bymysum_meanonly "permearnaltranktl3" "L_" "_`yr'" "year permearnaltrankt"		
			restore 
			
		// Calculate next period rank conditional on age 
		
			*Create rank and average in year t+5
			preserve
				qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yrt5' <= $small_sp
				
				qui: bys agegp: bymyxtile permearnalt`yr' permearnaltrankt "${nquantilesalt}"
				
				qui: gen permearnaltranktp5 = .
				qui: bys agegp: bymyxtile permearnalt`yrt5' permearnaltranktp5 "${nquantilesalt}"
				qui: bymysum_meanonly "permearnaltranktp5" "L_agegp" "_`yr'" "year agegp permearnaltrankt"
			restore 
			
			*Create rank and average in year t+10
			preserve 
				qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yrt10' <= $small_sp
				
				qui: bys agegp: bymyxtile permearnalt`yr' permearnaltrankt "${nquantilesalt}"
				
				qui: gen permearnaltranktp10 = .
				qui: bys agegp: bymyxtile permearnalt`yrt10' permearnaltranktp10 "${nquantilesalt}"
				qui: bymysum_meanonly "permearnaltranktp10" "L_agegp" "_`yr'" "year agegp permearnaltrankt"
			restore 
			
			*Create rank and average in year Tmax-3
			preserve
				qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yrl3' <= $small_sp
				
				qui: bys agegp: bymyxtile permearnalt`yr' permearnaltrankt "${nquantilesalt}"
				
				qui: gen permearnaltranktl3 = .
				qui: bys agegp: bymyxtile permearnalt`yrl3' permearnaltranktl3 "${nquantilesalt}"
				qui: bymysum_meanonly "permearnaltranktl3" "L_agegp" "_`yr'" "year agegp permearnaltrankt"		
			restore 
	}
	
	
} // END of loop over years
***
*
*
// Calculating Transition Rates
local firstyr = $yrfirst + 1
local jumplist = "5 10 15 20"
foreach subgp of local jumplist {				// This is the of years that will be used for the jump from t to t+subgp
	local yrmax = ${yrlast} - `subgp' - 1	// This should not be negative, make sure that ${yrlast} > `subgp' - 1 for at least 
											// one year in the sample. The -1 is necessary to ensure we are looking to mid year 
											// of the calculation of alt permanent income measure
    if `yrmax' < 0 {
		continue
		// This ensure the calculation only happens if yrmax > 0
	}
	
	forvalues yr = `firstyr'/`yrmax'{		
	
		disp("Working in year `yr' of jump `subgp'")

		*Define which variables are we loading 
		local yrt = `yr'+`subgp'		// `subgp' yrs ahead
		
		*Load the data										
		use  yob permearnalt`yr' permearnalt`yrt' using ///
			"$maindir${sep}dta${sep}master_sample.dta" if permearnalt`yr'~=. & permearnalt`yrt' ~=., clear   
		
		// Create year
		gen year=`yr'
		
		// Create sub group 
		gen subg = `subgp'
	
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
		
		// Raking in year t
			qui: gen permearnaltrankt = .					// Re uses the rank on perm income alt
			gen temp =  permearnalt`yr' if  permearnalt`yr' >= 0.01*rmininc[`yr'-${yrfirst}+1,1] 
			
			qui: bys agegp: bymyxtile temp permearnaltrankt "${nquantilestran}"	
			
			replace permearnaltrankt = 0 ///
				if permearnalt`yr' < 0.01*rmininc[`yr'-${yrfirst}+1,1] & permearnalt`yr' != .
			rename permearnalt`yr' permearnalt	
			qui: bymysum "permearnalt" "L_agegp" "`subgp'_`yr'" "year agegp permearnaltrankt"	
			drop temp
			
			// Create rank and average in year `subgp' yrs ahead 
			qui: gen permearnaltranktp = .
			gen temp =  permearnalt`yrt' if  permearnalt`yrt' >= 0.01*rmininc[`yrt'-${yrfirst}+1,1] 
			qui: bys agegp: bymyxtile temp permearnaltranktp "${nquantilestran}"
			
			replace permearnaltranktp = 0 ///
				if permearnalt`yrt' < 0.01*rmininc[`yrt'-${yrfirst}+1,1] & permearnalt`yrt' != .
			rename permearnalt`yrt' permearnaltp
			qui: bymysum "permearnaltp" "L_agegp" "`subgp'_`yr'" "year agegp permearnaltranktp"	
			drop temp 
			
			// Create the transition shares
			qui: bymyTranMat "permearnaltrankt" "permearnaltranktp" "T_`subgp'_`yr'_" "year subg agegp"
				// You might notice some errors of the form __00001J not found
				// this happen when no individual has transited across two cells. The code 
				// corrects for those assigning a 0
			
		
	}	// END of loop over years 
}	// END loop over groups
*/
*
// Collect data across years 
clear

*Collect 1-year ahead rank
foreach vari in ranktp1{
clear 
foreach yr of numlist $d1yrlist{
	
	append using "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"	
}

outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_mobstat.csv", replace comma
}

*Collect 5-year ahead rank
foreach vari in ranktp5 {
clear 
foreach yr of numlist $d5yrlist{
	append using "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"	
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_mobstat.csv", replace comma
}

/*Collects data on Correlation Index
clear 
foreach yr of numlist $d1yrlist{
	append using "$maindir${sep}out${sep}$outfolder/Sho_researn`yr'.dta"
	erase "$maindir${sep}out${sep}$outfolder/Sho_researn`yr'.dta"
}
	outsheet using "$maindir${sep}out${sep}$outfolder/Sho_researn.csv", replace comma
*/

*Collect ranks of alt permanent income
clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+1 & `yr' <= ${yrlast}-11{
	    use "$maindir${sep}out${sep}$outfolder/S_L_permearnaltranktp5_`yr'.dta", clear 
		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltranktp5_`yr'.dta"	

		merge 1:1 year permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_permearnaltranktp10_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltranktp10_`yr'.dta"	
		
		merge 1:1 year permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_permearnaltranktl3_`yr'.dta", nogenerate 
		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltranktl3_`yr'.dta"	
		
		save "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt_`yr'.dta", replace 
	}
}
clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+1 & `yr' <= ${yrlast}-11{
		append using "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt_`yr'.dta"
		erase"$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt_`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_permearnalt_mobstat.csv", replace comma

*Collect ranks of alt permanent income with age groups
	
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+1 & `yr' <= ${yrlast}-11{
	    use "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltranktp5_`yr'.dta", clear 
		erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltranktp5_`yr'.dta"	

		merge 1:1 year agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltranktp10_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltranktp10_`yr'.dta"	
		
		merge 1:1 year agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltranktl3_`yr'.dta", nogenerate 
		erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltranktl3_`yr'.dta"	
		
		save "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltrankt_`yr'.dta", replace 
	}
}

clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+1 & `yr' <= ${yrlast}-11{
		append using "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltrankt_`yr'.dta"
		erase"$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltrankt_`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_agegppermearnalt_mobstat.csv", replace comma


// Collects data on transition matrix
clear 
local firstyr = $yrfirst + 1
foreach subgp of local jumplist {				
	local yrmax = ${yrlast} - `subgp' - 1										
    if `yrmax' < 0 {
		continue
		// This ensure the calculation only happens if yrmax > 0
	}
	forvalues yr = `firstyr'/`yrmax'	{	
		append using "$maindir${sep}out${sep}$outfolder/T_`subgp'_`yr'_permearnaltranktp_yearsubgagegp.dta"
		erase "$maindir${sep}out${sep}$outfolder/T_`subgp'_`yr'_permearnaltranktp_yearsubgagegp.dta"
	}
}
	sort year subg agegp permearnaltrankt movecount* share* 
	outsheet using "$maindir${sep}out${sep}$outfolder/T_permearnalt_tranmat.csv", replace comma


*Statistics
	clear 
	local firstyr = $yrfirst + 1
foreach subgp of local jumplist {
		local yrmax = ${yrlast} - `subgp' - 1										
		if `yrmax' < 0 {
			continue
			// This ensure the calculation only happens if yrmax > 0
		}
		forvalues yr = `firstyr'/`yrmax'	{	
			append using "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt`subgp'_`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt`subgp'_`yr'.dta"
		}
		cap: gen subg  = `subgp'
		cap: replace subg  = `subgp' if subg == . 
	}
		sort year subg agegp permearnaltrankt 
		order year subg agegp permearnaltrankt 
		save "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt.dta", replace
		
	clear 
	local firstyr = $yrfirst + 1
	foreach subgp of local jumplist {				
		local yrmax = ${yrlast} - `subgp' - 1										
		if `yrmax' < 0 {
			continue
			// This ensure the calculation only happens if yrmax > 0
		}
		forvalues yr = `firstyr'/`yrmax'	{	
			append using "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltp`subgp'_`yr'.dta"
			erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltp`subgp'_`yr'.dta"
		}
		cap: gen subg  = `subgp'
		cap: replace subg  = `subgp' if subg == . 
	}
		rename permearnaltranktp permearnaltrankt
		sort year subg agegp permearnaltrankt 
		order year subg agegp permearnaltrankt 
		save "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltp.dta", replace
		
	use "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt.dta", clear 
	merge 1:1 year subg agegp permearnaltrankt ///
		using "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltp.dta", nogenerate
		sort year subg agegp permearnaltrankt
		order year subg agegp permearnaltrankt
	*save "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt_summ.dta", replace
	outsheet using "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt_summ.csv", replace comma
	erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnalt.dta" 
	erase "$maindir${sep}out${sep}$outfolder/S_L_agegppermearnaltp.dta" 

timer off 1
timer list 1

*END OF THE CODE 
