// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of concetration and inequality
// This version Jan 25, 2022
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
set type double
 
// You should change the below directory. 

global maindir =".."

// Do not make change from here on. Contact Ozkan/Salgado if changes are needed. 
do "$maindir/do/0_Initialize.do"
// cap noisily: ssc install gtools
	// This code uses gcollapse below to speed up the calculation of teh autocorrelations/
	// If not able to install gtools, please change gcollapse for collapse in line 295 and subsequent lines
	// or contanct Ozkan/Salgado
	

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

foreach yr of numlist $yrlist{
	disp("")
	disp("------------------------------")
	disp("Working in year `yr'")
	disp("------------------------------")
// 	local yr = 2000			// For checking bugs
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
	
	// Create the alternative age/cohort for plots
	qui: sum yob
	local minyob = r(min) 		
	gen yob2 = yob + mod(`minyob',${mergecohort}) - mod(yob,${mergecohort})
	
	gen agealt = `yr'-yob2+1
	qui: drop if agealt<${begin_age} | agealt>${end_age}
	
	// Drop if log earnings does not exist
	qui: drop if logearn==.
	
	// Gen earnings adjusted by the real min income
	gen earn = labor`yr' if labor`yr'>=rmininc[`yr'-${yrfirst}+1,1]
	
	// Age group 
	gen agegp = . 
	replace agegp = 1 if age <= 34 & agegp == .
	replace agegp = 2 if age <= 44 & agegp == .
	replace agegp = 3 if age <= 55 & agegp == .

	
	// A1. Moments of log earnings
	// Calculate cross sectional moments for year `yr'
	
	bymysum "logearn" "L_" "_`yr'" "year"
	
	bymyPCT "logearn" "L_" "_`yr'" "year"
	
	// Calculate cross sectional moments for year `yr' within heterogeneity groups
	foreach  vv in $hetgroup "male agealt"{ 
		local suf=subinstr("`vv'"," ","",.)
		
		bymysum "logearn" "L_" "_`suf'`yr'" "year `vv'"
	
		bymyPCT "logearn" "L_" "_`suf'`yr'" "year `vv'"
	}
	
	// A2. Moments of Residuals
	bymysum "researn" "L_" "_`yr'" "year"
	
	bymyPCT "researn" "L_" "_`yr'" "year"
	
	// Calculate cross sectional moments for year `yr' within heterogeneity groups
	foreach  vv in $hetgroup "male agealt"{ 
		local suf=subinstr("`vv'"," ","",.)
		
		bymysum "researn" "L_" "_`suf'`yr'" "year `vv'"
	
		bymyPCT "researn" "L_" "_`suf'`yr'" "year `vv'"
	}
	
	
	// B4. Moments of Permanent Income
	if inlist(`yr',${perm3yrlist}){
		bymysum "permearn" "L_" "_`yr'" "year"
	
		bymyPCT "permearn" "L_" "_`yr'" "year"
		
		foreach  vv in $hetgroup "male agealt"{ 
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
		
	// Calculate the tail coefficients and shares of earnings	
		bymyRAT "earn" "RI_" "`yr'"
		
		forvalues mm = 0/1{
		*Gender
		preserve 
		keep if male == `mm'	
			bymyRAT "earn" "RI_male`mm'_" "`yr'"
		restore 
		
		*Gender age
		levelsof(agegp) if male == `mm', local(agp)		
		foreach aa of local agp{
		preserve 
			keep if male == `mm'
			keep if agegp == `aa'	
			bymyRAT "earn" "RI_male`mm'age`aa'_" "`yr'"
		restore
		} 
		}
		
		
	// Calculate measure of concentration within heterogeneity groups
	
		qui{
		*Male & Female
		forvalues mm = 0/1{
			*Over all
			preserve
			keep if male == `mm'
			bymyCNT "earn" "L_male`mm'" "`yr'" 
			restore 
			
			*by Educ
			levelsof(educ) if male == `mm', local(edu)
			foreach ee of local edu{
				preserve
				keep if male == `mm'
				keep if educ == `ee'
				bymyCNT "earn" "L_male`mm'educ`ee'" "`yr'" 
				restore
			}
			
			*By age
			levelsof(agegp) if male == `mm', local(agp)
			foreach aa of local agp{
				preserve
				keep if male == `mm'
				keep if agegp == `aa'
				bymyCNT "earn" "L_male`mm'age`aa'" "`yr'" 
				restore
			}	
		}
		*Education groups
		levelsof(educ), local(edu)
		foreach ee of local edu{
			preserve
			keep if educ == `ee'
			bymyCNT "earn" "L_educ`ee'" "`yr'" 
			restore
		}
		
		*By age
		levelsof(agegp), local(agp)
		foreach aa of local agp{
			preserve
			keep if agegp == `aa'
			bymyCNT "earn" "L_age`aa'" "`yr'" 
			restore
		}
		
		}	// END of qui statement
		
} // END of loop over years


// Calculate moments of Residuals Earnings with Education Controls
foreach yr of numlist $yrlist{
	
	// Load data	
	use researne`yr' using "$maindir${sep}dta${sep}researne.dta", clear   
	
	// Create year
	gen year=`yr'
	
	// Moments of Residuals by Education
	bymysum "researne" "L_" "_`yr'" "year"
	
	bymyPCT "researne" "L_" "_`yr'" "year"
}	

// Calculate autocorrelation moments
// This is based on Luigi's codes

*Reshape back the data. The reshape comnand is too slow
foreach yr of numlist $yrlist{		
	use personid male yob researn`yr' if researn`yr' != . using ///
		"$maindir${sep}dta${sep}master_sample.dta" , clear 
	rename researn`yr' researn
	gen year = `yr'
	if `yr' == $yrfirst{
		save "$maindir${sep}dta${sep}temporal.dta", replace
	}
	else{
		append using "$maindir${sep}dta${sep}temporal.dta"
		save "$maindir${sep}dta${sep}temporal.dta", replace
	}
}
erase "$maindir${sep}dta${sep}temporal.dta"
gen age = year - yob + 1

keep if age>=${begin_age} & age<= ${end_age}
// reg logearn i.age i.year i.male	// Calculate residuals from gender/age/year dummies
// predict u,res
rename researn u
xtset personid year

gen u0u1=u*L1.u 
gen u0u2=u*L2.u 
gen u0u3=u*L3.u 
gen u0u4=u*L4.u 
gen u0u5=u*L5.u 
gen u1=L1.u 
gen u2=L2.u 
gen u3=L3.u 
gen u4=L4.u 
gen u5=L5.u
gen du=D.u 
gen du0du1=du*L1.du 
gen du0du2=du*L2.du 
gen du0du3=du*L3.du 
gen du0du4=du*L4.du 
gen du0du5=du*L5.du 
gen du1=L1.du 
gen du2=L2.du 
gen du3=L3.du 
gen du4=L4.du 
gen du5=L5.du 
keep u0u* du0du* du u u1-u5 du1-du5 year year male age
compress 
save "$maindir${sep}dta${sep}temporal.dta", replace
	// Save simple file 


use "$maindir${sep}dta${sep}temporal.dta", clear
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_year,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year male)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_gender,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year age)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_age,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year male age)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_age_gender,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
replace age=2534 if age>=25 & age<=34
replace age=3544 if age>=35 & age<=44
replace age=4555 if age>=45 & age<=55
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year age)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_age1,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
replace age=2534 if age>=25 & age<=34
replace age=3544 if age>=35 & age<=44
replace age=4555 if age>=45 & age<=55
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year male age)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_age_gender1,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
replace age=2555 if age>=25 & age<=55
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year age)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_age2,replace


use "$maindir${sep}dta${sep}temporal.dta", clear
replace age=2555 if age>=25 & age<=55
collapse u0u* du0du* (sd) du u u1-u5 du1-du5,by(year male age)
gen ac_researn_1=u0u1/(u*u1)
gen ac_researn_2=u0u2/(u*u2)
gen ac_researn_3=u0u3/(u*u3)
gen ac_researn_4=u0u4/(u*u4)
gen ac_researn_5=u0u5/(u*u5)
gen ac_dresearn_1=du0du1/(du*du1)
gen ac_dresearn_2=du0du2/(du*du2)
gen ac_dresearn_3=du0du3/(du*du3)
gen ac_dresearn_4=du0du4/(du*du4)
gen ac_dresearn_5=du0du5/(du*du5)
save temp_lev_age_gender2,replace


clear
u temp_lev_year,clear
append using temp_lev_gender
append using temp_lev_age
append using temp_lev_age_gender
append using temp_lev_age1
append using temp_lev_age_gender1
append using temp_lev_age2
append using temp_lev_age_gender2

keep year age male ac_*
g str3 country="${iso}"

tostring age,replace
replace age="25-55" if age=="."
replace age="25-34" if age=="2534" 
replace age="35-44" if age=="3544"
replace age="45-55" if age=="4555"

g str12 gender="All genders"
replace gender="Male" if male==1
replace gender="Female" if male==0
drop male

order country year gender age
sort country gender age year
export delimited using "$maindir${sep}out${sep}$outfolder${sep}autocorr.csv", replace
erase "$maindir${sep}dta${sep}temporal.dta"
// END of section for autocovariance.


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
foreach  vv in $hetgroup "male agealt"{

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
foreach  vv in $hetgroup "male agealt"{

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
		order agegp
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_age.csv", replace comma
	*Age and gender
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3{	// Age groups
		foreach aa in 0 1 {		// Gender groups
			append using "$maindir${sep}out${sep}$outfolder/L_male`aa'age`mm'earn_`yr'_con.dta"
			erase "$maindir${sep}out${sep}$outfolder/L_male`aa'age`mm'earn_`yr'_con.dta"	
			cap:gen agegp = `mm' 
			cap:replace agegp = `mm'  if agegp == .
			cap:gen male = `aa' 
			cap:replace male = `aa'  if male == .
		}
		}
	}	
		order male agegp
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_male_age.csv", replace comma
	
	*Educ	
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3{
		cap: append using "$maindir${sep}out${sep}$outfolder/L_educ`mm'earn_`yr'_con.dta"
		cap: erase "$maindir${sep}out${sep}$outfolder/L_educ`mm'earn_`yr'_con.dta"	
		cap:gen educ = `mm' 
		cap:replace educ = `mm'  if educ == .
		}
	}	
		order educ
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_educ.csv", replace comma
		
	*Education and Gender
	clear
	foreach yr of numlist $yrlist{
		foreach mm in 1 2 3{
		foreach aa in 0 1 {
		cap: append using "$maindir${sep}out${sep}$outfolder/L_male`aa'educ`mm'earn_`yr'_con.dta"
		cap: erase "$maindir${sep}out${sep}$outfolder/L_male`aa'educ`mm'earn_`yr'_con.dta"	
		cap:gen educ = `mm' 
		cap:replace educ = `mm'  if educ == .
		cap:gen male = `aa' 
		cap:replace male = `aa'  if male == .
		}
		}
	}	
		order male educ
		outsheet using "$maindir${sep}out${sep}$outfolder/L_earn_con_male_educ.csv", replace comma

// Collects the data on ratios 
	// Over all
	clear
	foreach yr of numlist $yrlist{
			append using "$maindir${sep}out${sep}$outfolder/RI_earn_`yr'_idex.dta"
			erase "$maindir${sep}out${sep}$outfolder/RI_earn_`yr'_idex.dta"	
	} 	
			outsheet using "$maindir${sep}out${sep}$outfolder/RI_earn_idex.csv", replace comma
	
	// By gender
	clear
	forvalues mm = 0/1{
		foreach yr of numlist $yrlist{
			append using "$maindir${sep}out${sep}$outfolder/RI_male`mm'_earn_`yr'_idex.dta"
			erase "$maindir${sep}out${sep}$outfolder/RI_male`mm'_earn_`yr'_idex.dta"	
		} 
		cap: gen male = `mm'
		cap: replace male = `mm' if male == .
	}
		order year male
	outsheet using "$maindir${sep}out${sep}$outfolder/RI_male_earn_idex.csv", replace comma
	
	// By gender age
	clear
	forvalues aa = 1/3{
		forvalues mm = 0/1{
			foreach yr of numlist $yrlist{
				append using "$maindir${sep}out${sep}$outfolder/RI_male`mm'age`aa'_earn_`yr'_idex.dta"
				erase "$maindir${sep}out${sep}$outfolder/RI_male`mm'age`aa'_earn_`yr'_idex.dta"	
			} 
			cap: gen male = `mm'
			cap: replace male = `mm' if male == .
		}
		cap: gen agegp = `aa'
		cap: replace agegp = `aa' if agegp == .
	}
	
	order year male agegp
	outsheet using "$maindir${sep}out${sep}$outfolder/RI_maleagegp_earn_idex.csv", replace comma
	
	
// Collect data from the researn
foreach vari in researne{
	foreach yr of numlist $yrlist{
		use "$maindir${sep}out${sep}$outfolder/S_L_`vari'_`yr'.dta", clear
		merge 1:1 year using "$maindir${sep}out${sep}$outfolder/PC_L_`vari'_`yr'.dta",nogenerate
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
}
	
	

timer off 1
timer list 1

*END OF THE CODE 
