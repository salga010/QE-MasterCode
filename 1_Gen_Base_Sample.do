// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the base sample 
// This version Nov 30, 2019
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off

// PLEASE MAKE THE APPROPRIATE CHANGES BELOW. 
// You should change the below directory. 
*global maindir ="/Users/serdar/Dropbox/GLOBAL-MASTER-CODE/STATA"
global maindir ="/Users/ssalgado/Dropbox/GLOBAL-MASTER-CODE/STATA/"

do "$maindir/do/0_Initialize.do"

global logname=c(current_date)
global logname="$logname BaseSample"
capture log close
capture noisily log using "$maindir${sep}log${sep}$logname.log", replace

cd "$maindir${sep}dta${sep}"
*	
if($wide==1){
	use $personid_var $male_var $yob_var $yod_var $educ_var ${labor_var}* using ${datafile}
	order  ${labor}*, alphabetic
	keep $personid_var $male_var $yob_var $yod_var $educ_var  ${labor_var}${yrfirst}-${labor_var}${yrlast}
	order $personid_var $male_var $yob_var $yod_var $educ_var  ${labor_var}*
	describe
}
else{
	use $personid_var $male_var $yob_var $yod_var $educ_var $year_var $labor_var ///
		if ${year_var} >= ${yrfirst} & ${year_var} <= ${yrlast} using ${datafile}  
	describe
	tab ${year_var}
	/*  The default STATA reshape commend is slow! 
	timer clear 1
	timer on 1
	sort $personid_var $year_var
	reshape wide $labor_var, i($personid_var) j($year_var)
	timer off 1
	timer list 1
	*/
	// The below part reshapes data in long format to wide. Faster than RESHAPE commend. 
	sort $personid_var $year_var
	forvalues yr = $yrfirst/$yrlast{
		preserve
		keep if $year_var ==`yr'
		
		rename $labor_var $labor_var`yr'
		
		keep $personid_var $labor_var`yr' $male_var $yob_var $yod_var $educ_var 		
			// Need to keep all variable. If only keep for first year, we 
			// miss the data for observations that enter in the sample after 
			// the first year. 
		
		sort $personid_var
		save "temp`yr'.dta",replace
		restore
	}
	
	local first=$yrfirst+1
	use "temp$yrfirst.dta", clear
	erase temp${yrfirst}.dta
	forvalues yr=`first'/$yrlast{
		merge 1:1 $personid_var using "temp`yr'.dta", nogen update replace
				// update replace makes sure the variables such as year of birth 
				// are replaced by noin missing values for observations that enter 
				// in the sample after the first year. 
		erase temp`yr'.dta
		sort $personid_var
	}
	
	order $personid_var $male_var $yob_var $yod_var $educ_var ${labor_var}*

}

rename $personid_var personid
rename $male_var male
rename $yob_var yob
rename $yod_var yod
rename $educ_var educ


// Drop anybody who is too old or too young or too dead. 
// Criteria 1 (Age) in CS Sample
drop if yob==.
drop if $yrfirst-yob+1>$end_age | $yrlast-yob+1<$begin_age 
drop if yod<=$yrfirst & yod~=.
describe

global base_price_index = ${base_price}-${yrfirst}+1	// The base year nominal values are converted to real. 

forvalues yr = $yrfirst/$yrlast{

	rename ${labor_var}`yr' labor`yr'
	
	label var labor`yr' "Real labor earnings in `yr'"

	// Covert to real values
	// Criteria d (Inflation) in CS Sample
	
	local cpi_index = `yr'-${yrfirst}+1
	replace labor`yr'=labor`yr'/cpimat[`cpi_index',1]		//Coverting to real values
	
	// Winsorization
	gen temp=labor`yr' if `yr'-yob+1>= $begin_age & `yr'- yob+1<= $end_age & `yr'< yod  // yod=. id very big number  
	_pctile temp, p($winsor)
	replace labor`yr'= r(r1) if labor`yr'>=r(r1) & labor`yr'!=. 
	drop temp
		
	// Add a small noise
	gen temp=${noise}*(uniform()-0.5)
	replace labor`yr'=labor`yr'+labor`yr'*temp 
	drop temp

	if(${miss_earn}==0){
	// Any earnings that are missing inside of $begin_age and $end_age are set to zero.
	replace labor`yr'= 0 if labor`yr'== . &  ///
	   `yr'-yob+1 >= $begin_age & `yr'- yob+1<=$end_age & `yr'< yod
	}
		
	// Assing missing if outside of $begin_age and $end_age
	replace labor`yr'= . if `yr'-yob+1 < $begin_age | `yr'- yob+1>$end_age 
	replace labor`yr'= . if `yr'>= yod & yod~=.  // (yod=. is very big number)
	
}

// Base sample creation completed.
order personid male yob yod educ labor*
compress
save "$maindir${sep}dta${sep}base_sample.dta", replace


// Creating residuals of log-earnings and saving the coefficients

cd "$maindir${sep}dta${sep}"

forvalues yr = $yrfirst/$yrlast{	
	use personid male yob educ labor`yr' using ///
	"$maindir${sep}dta${sep}base_sample.dta" if labor`yr'~=. , clear   

	// Create year
	gen year=`yr'
	
	// Create age 
	gen age = `yr'-yob+1
	drop if age<${begin_age} | age>${end_age}
	
	// Create log earn if earnings above the min treshold
	// Criteria c (Trimming) in CS Sample
	// Notice we do not drop the observations but log-earnings are generated for those with
	// income below 1/3*min threshold. Variable logearn`yr'c is used for growth rates conditional
	// on permanent income only
	
	gen logearn`yr' = log(labor`yr') if labor`yr'>=rmininc[`yr'-${yrfirst}+1,1] & labor`yr'!=. 
	gen logearnc`yr' = log(labor`yr') if labor`yr'>=(1/3)*rmininc[`yr'-${yrfirst}+1,1] & labor`yr'!=. 
	
	
	// Create dummies for age and education groups
	tab age, gen(agedum)
	drop agedum1
	tab educ, gen(educdum)
	drop educdum1

	// Regression for residuals earnigs
	statsby _b,  by(year) saving(age_yr`yr'_m,replace):  ///
	regress logearn`yr' agedum* if male==1
	
	predict temp_m if e(sample)==1, resid
	
	statsby _b,  by(year) saving(age_yr`yr'_f,replace):  ///
	regress logearn`yr' agedum* if male==0
	
	predict temp_f if e(sample)==1, resid
	
	// Regressions for residuals earnings with income above 1/3*minincome
	regress logearnc`yr' agedum* if male==1
	predict temp_m_c if e(sample)==1, resid
	
	regress logearnc`yr' agedum* if male==0
	predict temp_f_c if e(sample)==1, resid
	
	// Regressions for profiles
	statsby _b,  by(year) saving(age_educ_yr`yr'_m,replace):  ///
	regress logearn`yr' educdum* agedum* if male==1
	
	statsby _b,  by(year) saving(age_educ_yr`yr'_f,replace):  ///
	regress logearn`yr' educdum* agedum* if male==0
	
	
	// Generate the residuals by year and save a database for later append.
	gen researn`yr'= temp_m
	replace researn`yr'= temp_f if male==0
	
	gen researnc`yr'= temp_m_c
	replace researnc`yr'= temp_f_c if male==0 
	

	keep personid researn`yr' researnc`yr' logearn`yr' logearnc`yr' labor`yr' male age
	sort personid
	
	// Save data set for later append
	label var researn`yr' "Residual of real log-labor earnings of year `yr'"
	label var logearn`yr' "Real log-labor earnings of year `yr' above min threshold"
	label var researnc`yr' "Residual of real log-labor earnings of year `yr' above 1/3*min threshold"
	label var logearnc`yr' "Real log-labor earnings of year `yr' above 1/3*min threshold"
	save "researn`yr'.dta", replace
}

forvalues yr = $yrfirst/$yrlast{
	if (`yr' == $yrfirst){
		use researn`yr'.dta, clear
		erase researn`yr'.dta
	}
	else{
		merge 1:1 personid using researn`yr'.dta, nogen
		erase researn`yr'.dta
	}
	sort personid
}
save "researn.dta", replace 
// END: Residuals calculation complete

// Appending coefficients of agen and education for gender groups 
clear
forvalues yr = $yrfirst/$yrlast{
	append using age_educ_yr`yr'_m.dta
	cap: gen male = 1 
	cap: replace male = 1 if male == . 
	erase age_educ_yr`yr'_m.dta
	append using age_educ_yr`yr'_f.dta
	cap: replace male = 0 if male == . 
	erase age_educ_yr`yr'_f.dta	
}
order year male 
save "age_educ_dums.dta", replace 

// Appending coefficients of age for gender groups 
clear
forvalues yr = $yrfirst/$yrlast{
	append using age_yr`yr'_m.dta
	cap: gen male = 1 
	cap: replace male = 1 if male == .
	erase age_yr`yr'_m.dta
	append using age_yr`yr'_f.dta
	cap: replace male = 0 if male == . 
	erase age_yr`yr'_f.dta	
}
order year male 
save "age_dums.dta", replace 
// END: coefficients appending complete

// Calculate growth of (residual) earnings (Section 2.e and 2.f)
clear
foreach k in 1 5{

	// Given the jump k, calculate the growth rate for each worker in each year

	local lastyr=$yrlast-`k'
	forvalues yr = $yrfirst/`lastyr'{
	
		local yrnext=`yr'+`k'

		use personid male age researn`yr' researn`yrnext' researnc`yrnext' labor`yrnext' labor`yr' using "researn.dta", clear
		
		bys male age: egen avelabor`yrnext' = mean(labor`yrnext')
		bys male age: egen avelabor`yr' = mean(labor`yr')
		
		gen researn`k'F`yr'= researnc`yrnext'-researn`yr'		// Growth with earninbgs above mininc in t and 1/3*mininc in t+k
		gen arcearn`k'F`yr'= (labor`yrnext'/avelabor`yrnext' - labor`yr'/avelabor`yr')/(0.5*(labor`yrnext'/avelabor`yrnext' + labor`yr'/avelabor`yr'))
		
		label var researn`k'F`yr'  "Residual earnings growth between `yrnext' and `yr'"
		label var arcearn`k'F`yr'  "Arc-percent earnings growth between `yrnext' and `yr'"

		keep personid researn`k'F`yr' arcearn`k'F`yr'
		save researn`k'F`yr'.dta, replace
		
	}
	
	// Merge data across all years
	forvalues yr = $yrfirst/`lastyr'{
	
		if (`yr' == $yrfirst){
		use researn`k'F`yr'.dta, clear
		erase researn`k'F`yr'.dta
		}
		else{
			merge 1:1 personid using researn`k'F`yr'.dta, nogen
			erase researn`k'F`yr'.dta
		}
		sort personid
	}
	
	compress 
	save "researn`k'F.dta", replace 
	
}
// END calculate growth rates

// Calculate permanent income
clear
local firstyr=$yrfirst+2
forvalues yr = `firstyr'/$yrlast{
	local yrL1=`yr'-1
	local yrL2=`yr'-2	

	use personid male yob educ labor`yrL2' labor`yrL1' labor`yr' using ///
	"$maindir${sep}dta${sep}base_sample.dta" if labor`yr'~=. , clear  
	
	// Create year
	gen year=`yr'
	
	// Create age 
	gen age = `yr'-yob+1
	drop if age<${begin_age} | age>${end_age}
	
	// Create average income for those with at least 2 years of income above 
	// the treshold income between t-1 and t-3
	gen totearn=0
	gen numobs=0
	
	*replace numobs = -5 if labor`yr' < rmininc[`yr'-${yrfirst}+1,1]
	// This ensures that permanent income is only constructed for those 
	// with income above the threshold in t-1
		
	
	forvalues yrp=`yrL2'/`yr'{
		replace totearn=totearn+labor`yrp' if labor`yrp'~=.
		replace numobs=numobs+1 if labor`yrp'>=rmininc[`yrp'-${yrfirst}+1,1] & labor`yrp'~=.		
		// Notice earnings below the min threshold are still used to get totearn
	}
		
	replace totearn=totearn/numobs if numobs>=2			// Average income
	drop	if numobs<2									// Drop if less than 2 obs
	
	// Create log earn
	replace totearn = log(totearn) 
	drop if totearn==.
	
	// Gen dummies for regressions
	tab age, gen(agedum)
	drop agedum1
	
	// Regression to get residuals permanent income
	regress totearn agedum* if male==1
	predict temp_m if e(sample)==1, resid
	
	qui regress totearn agedum* if male==0
	predict temp_f if e(sample)==1, resid
	
	gen permearn`yr'= temp_m
	replace permearn`yr'= temp_f if male==0

	// Save 
	keep personid permearn`yr'
	label var permearn`yr' "Residual permanent income between `yr' and `yrL2'"
	
	compress 
	sort personid
	save "permearn`yr'.dta", replace
	
}

clear
local firstyr=$yrfirst+2
forvalues yr = `firstyr'/$yrlast{

	if (`yr' == `firstyr'){
		use permearn`yr'.dta, clear
		erase permearn`yr'.dta
	}
	else{
		merge 1:1 personid using permearn`yr'.dta, nogen
		erase permearn`yr'.dta
	}
	sort personid
}
save "permearn.dta", replace 
***
*/
/* Calculate modified permanent income
   Relative to the previos version, here we consider all individuals 
   even thouse with low earnimgs. See section "Key Statisitcs 4: Mobilitity"
*/
clear
local firstyr=$yrfirst + 1
local lastyr = $yrlast - 1
forvalues yr = `firstyr'/`lastyr'{
	local yrL1=`yr'-1
	local yrF1=`yr'+1		

	use personid male yob educ labor`yrF1' labor`yrL1' labor`yr' using ///
	"$maindir${sep}dta${sep}base_sample.dta" if labor`yr'~=. , clear  
	
	// Create year
	gen year=`yr'
	
	// Create age 
	gen age = `yr'-yob+1
	drop if age<${begin_age} + 1 | age>${end_age} - 1			// This makes the min age 26 and max age 54
	
	// Create average income for those with at least 2 years of income 
	gen totearn=0
	gen numobs=0

	forvalues yrp=`yrL1'/`yrF1'{
		replace totearn=totearn+labor`yrp' if labor`yrp'~=.
		replace numobs=numobs+1 if labor`yrp'~=.
			// Notice earnings below the min threshold are still used to get totearn
			// This ensure we do not consider income of individuals when they were 24 yrs old or less
	}
	replace totearn=totearn/numobs if numobs==3			// Average income	
	drop if numobs<3									// Drop if less than 2 obs
	drop if totearn==.
	
	bys male age: egen avg = mean(totearn)
	bys male: egen avgall = mean(totearn)
		
	gen permearnalt`yr' = avgall*totearn/avg					// This is because we want to control for age effects
	
	
	// Save 
	keep personid permearnalt`yr'
	label var permearnalt`yr' "Altenative residual permanent income between `yr' and `yrL2'"
	

	compress 
	sort personid
	save "permearnalt`yr'.dta", replace
	
}
***

clear
local firstyr=$yrfirst + 1
local lastyr = $yrlast - 1
forvalues yr = `firstyr'/`lastyr'{

	if (`yr' == `firstyr'){
		use permearnalt`yr'.dta, clear
		erase permearnalt`yr'.dta
	}
	else{
		merge 1:1 personid using permearnalt`yr'.dta, nogen
		erase permearnalt`yr'.dta
	}
	sort personid
}
save "permearnalt.dta", replace 

// END of calculation of alternative permanent income

// Merge all data sets to a master code

use "$maindir${sep}dta${sep}base_sample.dta", clear 
merge 1:1 personid using "permearn.dta", nogen 			
merge 1:1 personid using "permearnalt.dta", nogen 			
merge 1:1 personid using "researn.dta", nogen 
merge 1:1 personid using "researn1F.dta", nogen 
merge 1:1 personid using "researn5F.dta", nogen 
compress
order  personid male yob yod educ labor* logearn* permearn* researn* 
save "$maindir${sep}dta${sep}master_sample.dta", replace 

capture log close

// END OF DO-FILE
//////////////////////////////////////////////
