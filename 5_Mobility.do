// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of Mobility
// First  version January 06, 2019
// This version July 14, 2020
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
// You should change the below directory. 
global maindir ="..."

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
*
foreach yr of numlist $d1yrlist{
// 	local yr = 1998
	disp("====================")
	disp("Working in year `yr'")
	disp("====================")

	local yrp1 = `yr'+1
	local yrp3 = `yr'+3
	local yrp5 = `yr'+5
	
	*What alt perm income data will be loaded
	*see mobility section
	local pervars ""
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{
		local yrt3 = `yr'+3			// Three yrs ahead
		local yrt5 = `yr'+5			// Five yrs ahead
		local yrt10 = `yr'+10		// Ten years ahead
		local yrl3 = ${yrlast}-3	// Last year - 3 
		local pervars = "permearnalt`yr' permearnalt`yrt3'  permearnalt`yrt5' permearnalt`yrt10' permearnalt`yrl3'"
	}
	
	*Loading the data
	if inlist(`yr',${d5yrlist}){
		use  male yob educ researn`yr' researn`yrp1' researn`yrp3' researn`yrp5' logearn`yr' `pervars' using ///
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
	
	// Create age groups 
	qui {
		gen agegp = . 
		replace agegp = 1 if age<= 34 & agegp == .
		replace agegp = 2 if age<= 44 & agegp == .
		replace agegp = 3 if age > 44 & agegp == .
	}
	
	*
	// Calculate the ranking on conditional on residual log earnings 
	keep if researn`yr' != . & researn`yrp1' != . 
	// Create the percentiles in year t	
	qui: gen rankt = .
	qui: bymyxtile researn`yr' rankt "100"
	
	// Create the percentiles in year + 1
	sort researn`yrp1'
	sum researn`yrp1'  if researn`yrp1' != . & researn`yr'!=.,meanonly
	qui: gen ranktp1 = 100*(_n/_N) if researn`yrp1' != . & researn`yr'!=.
	
	// Calculate average percentile in t+1 conditional on percentile in p
	qui: bymysum_meanonly "ranktp1" "L_" "_`yr'" "year rankt"
	
	// Create the percentiles in t+5
	if inlist(`yr',${d5yrlist}){
		sort researn`yrp5'
		sum researn`yrp5' if researn`yrp5' != . & researn`yr'!=.,meanonly
		qui: gen ranktp5 = 100*(_n/_N) if researn`yrp5' != . & researn`yr'!=.
		qui: bymysum_meanonly "ranktp5" "L_" "_`yr'" "year rankt"
	}
	
	// Percentiles conditional on age 
	replace rankt = .
	replace ranktp1 = .
	qui: bys agegp: bymyxtile researn`yr' rankt "100"
	
	sort agegp researn`yrp1'
	by agegp: egen numeobs = count(researn`yrp1') if researn`yrp1' != . & researn`yr'!=.	
	by agegp: replace ranktp1 = 100*(_n/numeobs)  if researn`yrp1' != . & researn`yr'!=.	
	qui: bymysum_meanonly "ranktp1" "L_agegp_" "_`yr'" "year agegp rankt"
	drop numeobs
	
	if inlist(`yr',${d5yrlist}){
		qui: replace ranktp5 = .
		sort agegp researn`yrp5'
		by agegp: egen numeobs = count(researn`yrp5') if researn`yrp5' != . & researn`yr'!=.	
		by agegp: replace ranktp5 = 100*(_n/numeobs)  if researn`yrp5' != . & researn`yr'!=.	
		qui:  bymysum_meanonly "ranktp5" "L_agegp_" "_`yr'" "year agegp rankt"
		drop numeobs
	}
	
	// Percentiles conditional on age and gender
	replace rankt = .
	replace ranktp1 = .
	qui: bys male agegp: bymyxtile researn`yr' rankt "100"
	
	sort male agegp researn`yrp1'
	by male agegp: egen numeobs = count(researn`yrp1') if researn`yrp1' != . & researn`yr'!=.	
	by male agegp: replace ranktp1 = 100*(_n/numeobs)  if researn`yrp1' != . & researn`yr'!=.	
	qui: bymysum_meanonly "ranktp1" "L_male_agegp_" "_`yr'" "year male agegp rankt"
	drop numeobs
	
	if inlist(`yr',${d5yrlist}){
		qui: replace ranktp5 = .
		sort male agegp researn`yrp5'
		by male agegp: egen numeobs = count(researn`yrp5') if researn`yrp5' != . & researn`yr'!=.	
		by male agegp: replace ranktp5 = 100*(_n/numeobs)  if researn`yrp5' != . & researn`yr'!=.	
		qui:  bymysum_meanonly "ranktp5" "L_male_agegp_" "_`yr'" "year male agegp rankt"
		drop numeobs
	}
		
	// Calculate the ranking on the alt-permanent income. This depends on what data is available 
	// at any given time. 
	// Notice the following calculates the ranks for periods in which t+5,t+3, t+10, and t+Tmax-3 are available
	
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{			
		// Set some options and variables 
		local yrt3 = `yr'+3			// Three yrs ahead
		local yrt5 = `yr'+5			// Five yrs ahead
		local yrt10 = `yr'+10		// Ten years ahead
		local yrl3 = ${yrlast}-3	// Last year - 3 

			// Creates Rankings
		    
			global small_sp = 0.001			// Drop invididals with very little income
											// recall permearnalt uses ALL income data, even those with income 
											// below mininc											
			gen permearnaltrankt = .			
			foreach gg in t3 t5 t10 l3{
				*Calculate next period rank unconditional 
				preserve
					*Drop if both measures of alt perm are equal to small_sp 
					qui: drop if permearnalt`yr' <= $small_sp | permearnalt`yr`gg'' <= $small_sp
					
					*Calculate the ranking in t
					sort permearnalt`yr'
					egen numobs=count(permearnalt`yr')
					replace permearnaltrankt = (100/${nquantilesalt})*(floor(_n*${nquantilesalt}/(1+numobs))+1) if permearnalt`yr'~=.
					_pctile permearnalt`yr', p(97.5 99 99.9)
					
					replace permearnaltrankt = 99 if permearnalt`yr'   >= r(r1) & permearnalt`yr'  < r(r2) & permearnalt`yr' !=. 
					replace permearnaltrankt = 99.9 if permearnalt`yr' >= r(r2) & permearnalt`yr'  <= r(r3) & permearnalt`yr' !=. 
					replace permearnaltrankt = 100 if permearnalt`yr' >=  r(r3) & permearnalt`yr' !=. 
					drop numobs
					
					*Calculate the ranking in t+gg
					gen permearnaltrank`gg' = .
					sort permearnalt`yr`gg''
					egen numobs=count(permearnalt`yr`gg'')
					replace permearnaltrank`gg' = 100*(_n/numobs) if permearnalt`yr`gg''~=.
								
					qui: bymysum_meanonly "permearnaltrank`gg'" "L_" "_`yr'" "year permearnaltrankt"					
					
				restore 
				
				*Calculate next period rank conditional on age
				preserve
					*Drop if both measures of alt perm are equal to small_sp 
					qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yr`gg'' <= $small_sp
					
					*Calculate the ranking in t
					sort agegp permearnalt`yr'
					by agegp: egen numobs=count(permearnalt`yr')
					by agegp: replace permearnaltrankt = (100/${nquantilesalt})*(floor(_n*${nquantilesalt}/(1+numobs))+1) if permearnalt`yr'~=.
					
					by agegp: egen aux1 = pctile(permearnalt`yr'), p(97.5)
					by agegp: egen aux2 = pctile(permearnalt`yr'), p(99)
					by agegp: egen aux3 = pctile(permearnalt`yr'), p(99.9)
					
					replace permearnaltrankt = 99   if permearnalt`yr' >= aux1 & permearnalt`yr' < aux2  & permearnalt`yr' !=. 
					replace permearnaltrankt = 99.9 if permearnalt`yr' >= aux2 & permearnalt`yr' < aux3  & permearnalt`yr' !=. 
					replace permearnaltrankt = 100 if permearnalt`yr' >= aux3 & permearnalt`yr' !=. 
					drop aux1 aux2 aux3 numobs
					
					*Calculate the ranking in t+gg
					gen permearnaltrank`gg' = .
					sort agegp permearnalt`yr`gg''
					by agegp: egen numobs=count(permearnalt`yr`gg'')
					by agegp: replace permearnaltrank`gg' = 100*(_n/numobs) if permearnalt`yr`gg''~=.
					
					qui: bymysum_meanonly "permearnaltrank`gg'" "L_agegp_" "_`yr'" "year agegp permearnaltrankt"	
				restore 
				
				*Calculate next period rank conditional on age and gender
				preserve
					*Drop if both measures of alt perm are equal to small_sp 
					qui: drop if permearnalt`yr' <= $small_sp & permearnalt`yr`gg'' <= $small_sp
					
					*Calculate the ranking in t
					sort male agegp permearnalt`yr'
					by male agegp: egen numobs=count(permearnalt`yr')
					by male agegp: replace permearnaltrankt = (100/${nquantilesalt})*(floor(_n*${nquantilesalt}/(1+numobs))+1) if permearnalt`yr'~=.
					
					by male agegp: egen aux1 = pctile(permearnalt`yr'), p(97.5)
					by male agegp: egen aux2 = pctile(permearnalt`yr'), p(99)
					by male agegp: egen aux3 = pctile(permearnalt`yr'), p(99.9)
					
					replace permearnaltrankt = 99   if permearnalt`yr' >= aux1 & permearnalt`yr' < aux2  & permearnalt`yr' !=. 
					replace permearnaltrankt = 99.9 if permearnalt`yr' >= aux2 & permearnalt`yr' < aux3  & permearnalt`yr' !=. 
					replace permearnaltrankt = 100 if permearnalt`yr' >= aux3 & permearnalt`yr' !=. 
					drop aux1 aux2 aux3 numobs
					
					*Calculate the ranking in t+gg
					gen permearnaltrank`gg' = .
					sort male agegp permearnalt`yr`gg''
					by male agegp: egen numobs=count(permearnalt`yr`gg'')
					by male agegp: replace permearnaltrank`gg' = 100*(_n/numobs) if permearnalt`yr`gg''~=.
					
					qui: bymysum_meanonly "permearnaltrank`gg'" "L_male_agegp_" "_`yr'" "year male agegp permearnaltrankt"					
				restore 
				
			} // END loop over all possible jumps			
	} // END of loop t+gg is possible
} // END of loop over years

// Calculating Transition Rates
local firstyr = $yrfirst + 2
foreach subgp in 1 3 5 10 15 20 {				// This is the of years that will be used for the jump from t to t+subgp
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
		use  yob male permearnalt`yr' permearnalt`yrt' permearn`yr' permearn`yrt' researn`yr' researn`yrt' using ///
			"$maindir${sep}dta${sep}master_sample.dta" if permearnalt`yr'~=. , clear   
				// We do not consider individuals that do not have permalt and do not have researn in t
				// Individuals without t+k values will considered a different category. 
		
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
		
		*local varx = "permearnalt" // For bugs
		foreach varx in permearnalt researn permearn{
		
		// Raking in year t
		qui: gen `varx'rankt = .					// Re uses the rank on perm income alt
		qui: bys agegp: bymyxtile `varx'`yr' `varx'rankt "${nquantilestran}"	
		qui: bys agegp: egen aux0 = pctile(`varx'`yr'), p(95)
		qui: bys agegp: egen aux1 = pctile(`varx'`yr'), p(99)
		qui: bys agegp: egen aux2 = pctile(`varx'`yr'), p(99.9)
		replace `varx'rankt = ${nquantilestran} + 1 if `varx'`yr' > aux0 & `varx'`yr' !=. 
		replace `varx'rankt = ${nquantilestran} + 2 if `varx'`yr' > aux1 & `varx'`yr' !=. 
		replace `varx'rankt = ${nquantilestran} + 3 if `varx'`yr' > aux2 & `varx'`yr' !=. 
		replace `varx'rankt = ${nquantilestran} + 4 if `varx'`yr' ==. 		// If value in ytr is missing (e.g. researn below min income tresh)
		replace `varx'rankt = ${nquantilestran} + 5 if  age>${end_age}		// If individuals exit the sample because of age
		drop aux0 aux1 aux2
		
		// Create rank and average in year `subgp' yrs ahead 
		qui: gen `varx'ranktp = .
		qui: bys agegp: bymyxtile `varx'`yrt' `varx'ranktp "${nquantilestran}"
		qui: bys agegp: egen aux0 = pctile(`varx'`yrt'), p(95)
		qui: bys agegp: egen aux1 = pctile(`varx'`yrt'), p(99)
		qui: bys agegp: egen aux2 = pctile(`varx'`yrt'), p(99.9)
		replace `varx'ranktp = ${nquantilestran} + 1 if `varx'`yrt' > aux0 & `varx'`yrt' !=. 
		replace `varx'ranktp = ${nquantilestran} + 2 if `varx'`yrt' > aux1 & `varx'`yrt' !=. 
		replace `varx'ranktp = ${nquantilestran} + 3 if `varx'`yrt' > aux2 & `varx'`yrt' !=. 
		replace `varx'ranktp = ${nquantilestran} + 4 if `varx'`yrt' ==. 	// If value in ytr is missing (e.g. researn below min income tresh)
		replace `varx'ranktp = ${nquantilestran} + 5 if  age>${end_age}		// If individuals exit the sample because of age
		drop aux0 aux1 aux2
		
		// Create the transition shares
		qui: bymyTranMat "`varx'rankt" "`varx'ranktp" "T_`subgp'_`yr'_" "year subg agegp"
			// You might notice some errors of the form __00001J not found
			// this happen when no individual has transited across two cells. The code 
			// corrects for those assigning a 0
		drop `varx'rankt `varx'ranktp
		
		/*Age and gender*/
		// Raking in year t
		qui: gen `varx'rankt = . // Re uses the rank on perm income alt
		qui: bys male agegp: bymyxtile `varx'`yr' `varx'rankt "${nquantilestran}"	
	
		bys male agegp: egen aux0 = pctile(`varx'`yr'), p(95)
		bys male agegp: egen aux1 = pctile(`varx'`yr'), p(99)
		bys male agegp: egen aux2 = pctile(`varx'`yr'), p(99.9)
		replace `varx'rankt = ${nquantilestran} + 1 if `varx'`yr' > aux0 & `varx'`yr' !=. 
		replace `varx'rankt = ${nquantilestran} + 2 if `varx'`yr' > aux1 & `varx'`yr' !=. 
		replace `varx'rankt = ${nquantilestran} + 3 if `varx'`yr' > aux2 & `varx'`yr' !=. 
		replace `varx'rankt = ${nquantilestran} + 4 if `varx'`yr' ==. 
		replace `varx'rankt = ${nquantilestran} + 5 if  age>${end_age}		
		drop aux0 aux1 aux2

		// Create rank and average in year `subgp' yrs ahead 
		qui: gen `varx'ranktp = .
		qui: bys male agegp: bymyxtile `varx'`yrt' `varx'ranktp "${nquantilestran}"
		bys male agegp: egen aux0 = pctile(`varx'`yrt'), p(95)
		bys male agegp: egen aux1 = pctile(`varx'`yrt'), p(99)
		bys male agegp: egen aux2 = pctile(`varx'`yrt'), p(99.9)
		replace `varx'ranktp = ${nquantilestran} + 1 if `varx'`yrt' > aux0 & `varx'`yrt' !=. 
		replace `varx'ranktp = ${nquantilestran} + 2 if `varx'`yrt' > aux1 & `varx'`yrt' !=. 
		replace `varx'ranktp = ${nquantilestran} + 3 if `varx'`yrt' > aux2 & `varx'`yrt' !=. 
		replace `varx'ranktp = ${nquantilestran} + 4 if `varx'`yrt' ==. 
		replace `varx'ranktp = ${nquantilestran} + 5 if  age>${end_age}	
		drop aux0 aux1 aux2
		

		// Create the transition shares
		qui: bymyTranMat "`varx'rankt" "`varx'ranktp" "T_male`subgp'_`yr'_" "year subg male agegp"
			// You might notice some errors of the form __00001J not found
			// this happen when no individual has transited across two cells. The code 
			// corrects for those assigning a 0
		drop `varx'rankt `varx'ranktp
		
		} // END loop over varx
				
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
	
	clear 
	foreach yr of numlist $d1yrlist{
		
		append using "$maindir${sep}out${sep}$outfolder/S_L_agegp_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/S_L_agegp_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_agegp_`vari'_mobstat.csv", replace comma
	
	clear 
	foreach yr of numlist $d1yrlist{
		
		append using "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_male_agegp_`vari'_mobstat.csv", replace comma
	
}

*Collect 5-year ahead rank
foreach vari in ranktp5 {
	clear 
	foreach yr of numlist $d5yrlist{
		append using "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_`vari'_mobstat.csv", replace comma
	
	clear 
	foreach yr of numlist $d5yrlist{
		append using "$maindir${sep}out${sep}$outfolder/S_L_agegp_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/S_L_agegp_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_agegp_`vari'_mobstat.csv", replace comma
	
	clear 
	foreach yr of numlist $d5yrlist{
		append using "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_`vari'_`yr'.dta"
		erase "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_`vari'_`yr'.dta"	
	}
	outsheet using "$maindir${sep}out${sep}$outfolder/L_male_agegp_`vari'_mobstat.csv", replace comma
}

*Collect ranks of alt permanent income
clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{
	    use "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt3_`yr'.dta", clear 
		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt3_`yr'.dta"	

		merge 1:1 year permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt5_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt5_`yr'.dta"	
		
		merge 1:1 year permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt10_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt10_`yr'.dta"	
				
		merge 1:1 year permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankl3_`yr'.dta", nogenerate 
		erase "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankl3_`yr'.dta"	
		
		save "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt_`yr'.dta", replace 
	}
}
clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{
		append using "$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt_`yr'.dta"
		erase"$maindir${sep}out${sep}$outfolder/S_L_permearnaltrankt_`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_permearnalt_mobstat.csv", replace comma

*Collect ranks of alt permanent income with age groups
	
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{
		*Only age
	    use "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt3_`yr'.dta", clear 
		erase "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt3_`yr'.dta"	

		merge 1:1 year agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt5_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt5_`yr'.dta"	
		
		merge 1:1 year agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt10_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt10_`yr'.dta"	
		
		merge 1:1 year agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankl3_`yr'.dta", nogenerate 
		erase "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankl3_`yr'.dta"	
		
		save "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt_`yr'.dta", replace 
		
		*Age and Gender
		use "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt3_`yr'.dta", clear 
		erase "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt3_`yr'.dta"	

		merge 1:1 year male agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt5_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt5_`yr'.dta"	
		
		merge 1:1 year male agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt10_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt10_`yr'.dta"	
		
		merge 1:1 year male agegp permearnaltrankt using ///
			"$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankl3_`yr'.dta", nogenerate 
 		erase "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankl3_`yr'.dta"	
		
		save "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt_`yr'.dta", replace 
	}
}

clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{
		append using "$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt_`yr'.dta"
		erase"$maindir${sep}out${sep}$outfolder/S_L_agegp_permearnaltrankt_`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_agegp_permearnalt_mobstat.csv", replace comma

clear 
foreach yr of numlist $d1yrlist{
	if `yr' >= ${yrfirst}+2 & `yr' <= ${yrlast}-11{
		append using "$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt_`yr'.dta"
		erase"$maindir${sep}out${sep}$outfolder/S_L_male_agegp_permearnaltrankt_`yr'.dta"
	}
}
outsheet using "$maindir${sep}out${sep}$outfolder/L_male_agegp_permearnalt_mobstat.csv", replace comma


*/ 
*Collects data on transition matrix
foreach vv in researnranktp permearnaltranktp  permearnranktp { 
	clear 
	local firstyr = $yrfirst + 2
	foreach subgp in 5 10 15 20 {				
		local yrmax = ${yrlast} - `subgp' - 1										
		if `yrmax' < 0 {
			continue
			// This ensure the calculation only happens if yrmax > 0
		}
		forvalues yr = `firstyr'/`yrmax'	{	
			append using "$maindir${sep}out${sep}$outfolder/T_`subgp'_`yr'_`vv'_yearsubgagegp.dta"
			erase "$maindir${sep}out${sep}$outfolder/T_`subgp'_`yr'_`vv'_yearsubgagegp.dta"
		}
	}
		cap: sort year subg agegp `vv' movecount* share* 
// 		cap: sort year subg agegp researnranktp movecount* share* 
		outsheet using "$maindir${sep}out${sep}$outfolder/T_`vv'_tranmat.csv", replace comma
		

	clear 
	local firstyr = $yrfirst + 2
	foreach subgp in 5 10 15 20 {				
		local yrmax = ${yrlast} - `subgp' - 1										
		if `yrmax' < 0 {
			continue
			// This ensure the calculation only happens if yrmax > 0
		}
		forvalues yr = `firstyr'/`yrmax'	{	
			cap: append using "$maindir${sep}out${sep}$outfolder/T_male`subgp'_`yr'_`vv'_yearsubgmaleagegp.dta"
			cap: erase "$maindir${sep}out${sep}$outfolder/T_male`subgp'_`yr'_`vv'_yearsubgmaleagegp.dta"
		}
	}
		cap: sort year subg agegp `vv' movecount* share* 
// 		cap: sort year subg agegp researnranktp movecount* share* 
		outsheet using "$maindir${sep}out${sep}$outfolder/T_male`vv'_tranmat.csv", replace comma
}	
*/

timer off 1
timer list 1

*END OF THE CODE 
