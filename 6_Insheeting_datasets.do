// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the files that will be uploaded to the website
// This version January 25, 2022
// Created by Luigi Pistaferri
// Updated by Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off
set matsize 800
cap log close

// Definitions 
global maindir ="..."		// Define main directory
do "$maindir/do/0_Initialize.do"									
global folder="${maindir}${sep}out${sep}"
																	// Folder where the results are saved

global ineqdata = "25 Jan 2022 Inequality"			// Data on Inequality 
global voladata = "20 Jan 2022 Volatility"				// Data on Volatility
global mobidata = "19 Jan 2022 Mobility"				// Data on Mobility

global datafran="${folder}${sep}19 Jan 2022 Upload"			// Define were data will be saved
capture noisily mkdir "${folder}${sep}19 Jan 2022 Upload"	// Create the folder	

****************TAIL INDEX
forvalues mm = 0/2{			/*0: Women; 1: Men; 2: All*/
			
	if `mm' == 1{
		insheet using "$folder${sep}${ineqdata}${sep}RI_male_earn_idex.csv", clear comma 
		keep if male == `mm'
	}
	else if `mm' == 0{
		insheet using "$folder${sep}${ineqdata}${sep}RI_male_earn_idex.csv", clear comma 
		keep if male == `mm'	
	}
	else {
		insheet using "$folder${sep}${ineqdata}${sep}RI_earn_idex.csv", clear comma 			
	}	
	reshape long t me ra ob, i(year) j(level) string
	split level, p(level) 
	drop level1
	rename level2 numlevel
	destring numlevel, replace 
	order numlevel level year 
	sort year numlevel
	
	*Re scale and share of pop
	by year: gen aux = 20*ob if numlevel == 0 
	by year: egen tob = max(aux)   // Because ob is number of observations in top 5%
	drop aux
	by year: gen  shob = ob/tob
			 gen  lshob = log(shob)		  	
	
	gen t1000s = (t/1000)/${exrate2018}				// Tranform to dollars of 2018
	gen lt1000s = log(t1000s)
	gen lt = log(t)
	gen l10t = log10(t)
	
	*Check number of observations 
	replace  shob = . if ob <= $minnumberobs
	replace lshob = . if ob <= $minnumberobs
	
	*Keep years end in 0 or 5
// 	keep if inlist(year,1950,1960,1970,1980,1990,2000,2010,2020) | ///
// 		inlist(year,1955,1965,1975,1985,1995,2005,2015,2025)
// 	drop if year < 1950
	levelsof year, local(yyrs)
	
	*Re-reshape 
	reshape wide t me ra ob tob shob lshob t1000s lt l10t lt1000s, i(numlevel) j(year)	
	
	*Tail idexed
	foreach yr of local yyrs{
	
		/*5% Tail*/
		regress lshob`yr' lt`yr'	
		global slopep`yr'_tp5 = _b[lt`yr']
								
		/*1% Tail*/		
		regress lshob`yr' lt`yr' if shob`yr' < 0.01	
		global slopep`yr'_tp1 = _b[lt`yr']
			
	}
	*Save
	clear 
	set obs 1 		
	foreach yr of local yyrs{		
		gen slopep_tp5`yr' = ${slopep`yr'_tp5}
		gen slopep_tp1`yr' = ${slopep`yr'_tp1}			
	}
	gen i = 1
	reshape long slopep_tp5 slopep_tp1, i(i) j(year)	
	g str3 country="${iso}"
	g str12 age="25-55"
	if `mm' == 1{		
		g str12 gender="Male"
	}
	else if `mm' == 0{		
		g str12 gender="Female"		
	}
	else {
		g str12 gender="All genders"
	}	
	drop i
	order country age gender year 
	
	save $folder${sep}temp2_`mm'.dta, replace	
	
}

clear 
forvalues mm = 0/2{	
	append using $folder${sep}temp2_`mm'.dta
	erase $folder${sep}temp2_`mm'.dta
	
}
sort country age gender year
save "$datafran${sep}Slope", replace
*export delimited using "$datafran${sep}Slope.csv", replace
	
	
********************************************************************************
insheet using "$folder${sep}${ineqdata}${sep}L_earn_con.csv",clear
drop top*me*
g str3 country="${iso}"

g str12 age="25-55"
g str12 gender="All genders"
save $folder${sep}temp1,replace
*sleep 500

forvalues j=1(1)3	{
    insheet using "$folder${sep}${ineqdata}${sep}L_earn_con_age.csv",clear
	drop top*me*
	g str3 country="${iso}"
	g str12 gender="All genders"
	keep if agegp==`j'
	g str20 age="" 
	replace age="25-34" if agegp==1 
	replace age="35-44" if agegp==2
	replace age="45-55" if agegp==3
	drop agegp
	save $folder${sep}temp2_`j',replace
	*sleep 500
}

forvalues j=0(1)1	{
    insheet using "$folder${sep}${ineqdata}${sep}L_earn_con_male.csv",clear
	drop top*me*	
	g str3 country="${iso}"

	g str12 age="25-55"
	keep if male==`j'
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	save $folder${sep}temp3_`j',replace
	*sleep 500
}

u $folder${sep}temp1,clear
append using $folder${sep}temp2_1
append using $folder${sep}temp2_2
append using $folder${sep}temp2_3
append using $folder${sep}temp3_0
append using $folder${sep}temp3_1
order country year gender age
keep country year gender age *share gini
sort country year gender age
save "$datafran${sep}Ineq_earnings_stats_timeseries.dta", replace
*export delimited using "$datafran${sep}Ineq_earnings_stats_timeseries.csv", replace
erase $folder${sep}temp1.dta
erase $folder${sep}temp2_1.dta
erase $folder${sep}temp2_2.dta
erase $folder${sep}temp2_3.dta
erase $folder${sep}temp3_1.dta
erase $folder${sep}temp3_0.dta


********************************************************************************
insheet using "$folder${sep}${ineqdata}${sep}L_logearn_hist.csv",clear
reshape long val_logearn den_logearn,i(index) j(year)
g str3 country="${iso}"
g str20 gender="All genders"
save $folder${sep}temp1,replace
*sleep 500

forvalues j=0(1)1	{
    insheet using "$folder${sep}${ineqdata}${sep}L_logearn_hist_male.csv",clear
	g str3 country="${iso}"

	keep if male==`j'
	reshape long val_logearn den_logearn,i(index) j(year)
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	save $folder${sep}temp2_`j',replace
	*sleep 500
}

u $folder${sep}temp1,clear
append using $folder${sep}temp2_1
append using $folder${sep}temp2_0
g str12 age="25-55"
order country year gender age index
sort country gender year age index
save "$datafran${sep}Ineq_earnings_density_timeseries", replace
*export delimited using "$datafran${sep}Ineq_earnings_density_timeseries.csv", replace

erase $folder${sep}temp1.dta
erase $folder${sep}temp2_1.dta
erase $folder${sep}temp2_0.dta

********************************************************************************

foreach vv in permearn researn logearn {
	global varx = "`vv'"
	insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_sumstat.csv",clear	
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist {
		qui: replace `vvg' = . if n${varx} < $minnumberobs							
		}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 age="25-55"
	g str12 gender="All genders"
	save $folder${sep}temp1,replace
	*sleep 500
	
forvalues j=$begin_age(1)$end_age	{
	insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_age_sumstat.csv",clear	
	keep if age==`j'
	
	drop age
	g str3 country="${iso}"	
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 gender="All genders"
	g str2 age="`j'"
	save $folder${sep}temp2_`j',replace
}	
	
forvalues j=0(1)1	{
	insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_male_sumstat.csv",clear
	keep if male==`j'
	g str3 country="${iso}"
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	g str20 age="25-55"
	save $folder${sep}temp3_`j',replace
}	

forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age		{
		    insheet using "$folder${sep}${ineqdata}${sep}L_${varx}_maleage_sumstat.csv",clear
			keep if male==`j'
			keep if age==`k'
			drop age
			g str3 country="${iso}"
			
			qui: desc mean${varx}-p99_99${varx}, varlist
			local tvlist = r(varlist)
			foreach vvg of local tvlist{
				qui: replace `vvg' = . if n${varx} < $minnumberobs
			}
			
			gen p9010${varx} = p90${varx} - p10${varx}
			gen p9050${varx} = p90${varx} - p50${varx}
			gen p5010${varx} = p50${varx} - p10${varx}
			gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
			gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
			drop min${varx} max${varx}
			
			
			g str20 age="`k'"
			g str20 gender="" 
			replace gender="Male" if male==1
			replace gender="Female" if male==0
			drop male
	save $folder${sep}temp5_`j'_`k',replace
		}
	}

u $folder${sep}temp1,clear
forvalues j=$begin_age(1)$end_age	{
	append using $folder${sep}temp2_`j'
}	
forvalues j=0(1)1	{
	append using $folder${sep}temp3_`j'
}	
forvalues j=0(1)1	{
	    forvalues k=25(1)55	{
	append using $folder${sep}temp5_`j'_`k'
		}
	}
order country year gender age
sort country gender age year 
save "$datafran${sep}Ineq_${varx}_stats_timeseries", replace
*export delimited using "$datafran${sep}Ineq_${varx}_stats_timeseries.csv", replace

preserve
	drop if age=="25-55"
	destring age,gen(age_num)
	drop age
	ren age_num age
	gen groupage=1 if age>=25 & age<=34
	replace groupage=2 if age>=35 & age<=44
	replace groupage=3 if age>=45 & age<=55
	collapse (sum) n${varx} (mean) mean${varx}-p99_99${varx},by(groupage gender country year)
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})	

	
	ren groupage age
	tostring age,replace
	replace age="25-34" if age=="1"
	replace age="35-44" if age=="2"
	replace age="45-55" if age=="3"
	save "$datafran${sep}Ineq_${varx}_stats_timeseries_addition",replace
restore

u "$datafran${sep}Ineq_${varx}_stats_timeseries", clear
append using "$datafran${sep}Ineq_${varx}_stats_timeseries_addition"
erase "$datafran${sep}Ineq_${varx}_stats_timeseries_addition.dta"
sort country gender age year 
save,replace

}	

// END loop over variables
	
erase $folder${sep}temp1.dta
forvalues j=$begin_age(1)$end_age	{
	erase $folder${sep}temp2_`j'.dta
}	
forvalues j=0(1)1	{
	erase $folder${sep}temp3_`j'.dta
}	
forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
	erase $folder${sep}temp5_`j'_`k'.dta
		}
	}




********************************************************************************
********************************************************************************

foreach ff in 1 5{
		foreach x in res {
		insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_hist.csv",clear
		
		reshape long val_`x'earn`ff'f den_`x'earn`ff'f,i(index) j(year)
		g str3 country="${iso}"

g str20 gender="All genders"
save $folder${sep}temp1,replace
*sleep 500

forvalues j=0(1)1	{
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_hist_male.csv",clear
	g str3 country="${iso}"

	keep if male==`j'
	reshape long val_`x'earn`ff'f den_`x'earn`ff'f,i(index) j(year)
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	save $folder${sep}temp2_`j',replace
	*sleep 500
}

u $folder${sep}temp1,clear
append using $folder${sep}temp2_1
append using $folder${sep}temp2_0
g str12 age="25-55"
order country year gender age index
sort country gender year age index
save "$datafran${sep}Dynamics_`x'earn_`ff'_density_timeseries", replace
*export delimited using "$datafran${sep}Dynamics_`x'earn_`ff'_density_timeseries.csv", replace
}

erase $folder${sep}temp1.dta
erase $folder${sep}temp2_1.dta
erase $folder${sep}temp2_0.dta
}

u "$datafran${sep}Dynamics_researn_1_density_timeseries", clear
merge country gender year age index using "$datafran${sep}Dynamics_researn_5_density_timeseries" 
drop _merge
sort country gender year age index
merge using "$datafran${sep}Ineq_earnings_density_timeseries"
drop _merge
sort country gender year age index
export delimited using "$datafran${sep}Density.csv", replace

erase "$datafran${sep}Dynamics_researn_1_density_timeseries.dta"
erase "$datafran${sep}Dynamics_researn_5_density_timeseries.dta"
erase "$datafran${sep}Ineq_earnings_density_timeseries.dta"

********************************************************************************
foreach ff in 1 5 {
	foreach x in res arc {
	global varx = "`x'earn`ff'"
	
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_sumstat.csv",clear	
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 age="25-55"
	g str12 gender="All genders"
	save $folder${sep}temp1,replace
	*sleep 500

forvalues j=$begin_age(1)$end_age	{
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_age_sumstat.csv",clear
	keep if age==`j'
	drop age
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}

	g str12 gender="All genders"
	g str2 age="`j'"
	save $folder${sep}temp2_`j',replace
}		
	
	
forvalues j=0(1)1	{
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_male_sumstat.csv",clear
	keep if male==`j'
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str20 gender="" 
	replace gender="Male" if male==1 
	replace gender="Female" if male==0
	drop male
	g str20 age="25-55"
	save $folder${sep}temp3_`j',replace
}	

forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
		    insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_maleage_sumstat.csv",clear
			keep if male==`j'
			keep if age==`k'
			drop age
			g str3 country="${iso}"
			*Adjust for min number of observations
			qui: desc mean${varx}-p99_99${varx}, varlist
			local tvlist = r(varlist)
			foreach vvg of local tvlist{
				qui: replace `vvg' = . if n${varx} < $minnumberobs
			}		
			
			// HERE
			gen p9010${varx} = p90${varx} - p10${varx}
			gen p9050${varx} = p90${varx} - p50${varx}
			gen p5010${varx} = p50${varx} - p10${varx}
			gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
			gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
			drop min${varx} max${varx}	
			//------
			
*			drop male	
			
			g str20 age="`k'"
			g str20 gender="" 
			replace gender="Male" if male==1
			replace gender="Female" if male==0
			drop male
	save $folder${sep}temp5_`j'_`k',replace
		}
	}

u $folder${sep}temp1,clear
forvalues j=$begin_age(1)$end_age	{
	append using $folder${sep}temp2_`j'
}	
forvalues j=0(1)1	{
	append using $folder${sep}temp3_`j'
}	
forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
	append using $folder${sep}temp5_`j'_`k'
		}
	}
order country year gender age

sort country gender age year
save "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries", replace
*export delimited using "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries.csv", replace
*sleep 1000

preserve
	drop if age=="25-55"
	destring age,gen(age_num)
	drop age
	ren age_num age
	gen groupage=1 if age>=25 & age<=34
	replace groupage=2 if age>=35 & age<=44
	replace groupage=3 if age>=45 & age<=55
	collapse (sum) n`x'earn`ff' (mean) mean`x'earn`ff'-p99_99`x'earn`ff',by(groupage gender country year)
	
	//------
	cap: drop min${varx} max${varx} 		// HERE
	//------
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})	
	
	ren groupage age
	tostring age,replace
	replace age="25-34" if age=="1"
	replace age="35-44" if age=="2"
	replace age="45-55" if age=="3"
	save "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries_addition",replace
restore

u "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries", clear
append using "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries_addition"
erase "$datafran${sep}Dynamics_`x'earn_`ff'_stats_timeseries_addition.dta"
sort country gender age year 
save,replace

}	// END loop over variables
}	// END loop over jumps


erase $folder${sep}temp1.dta
forvalues j=$begin_age(1)$end_age	{
	erase $folder${sep}temp2_`j'.dta
}	
forvalues j=0(1)1	{
	erase $folder${sep}temp3_`j'.dta
}	
forvalues j=0(1)1	{
	    forvalues k=$begin_age(1)$end_age	{
	erase $folder${sep}temp5_`j'_`k'.dta
		}
	}

insheet using "$folder${sep}${ineqdata}${sep}autocorr.csv", clear
sort country gender age year 
drop if age=="2555"
save "$folder${sep}${ineqdata}${sep}autocorr", replace

	
u "$datafran${sep}Ineq_earnings_stats_timeseries",clear
sort country gender age year 
merge country gender age year using "$datafran${sep}Ineq_logearn_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Ineq_researn_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Ineq_permearn_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_researn_1_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_researn_5_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_arcearn_1_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_arcearn_5_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$datafran${sep}Dynamics_arcearn_5_stats_timeseries"
tab _merge
drop _merge
sort country gender age year 
merge country gender age year using "$folder${sep}${ineqdata}${sep}autocorr"
tab _merge
drop _merge
sort country gender age year 
replace nresearn5f=. if nresearn5f==0
replace narcearn5f=. if narcearn5f==0
replace nresearn1f=. if nresearn1f==0
replace narcearn1f=. if narcearn1f==0
replace npermearn=. if npermearn==0

*drop min* max*

sort country age gender year
merge country age gender year using "$datafran${sep}Slope"
drop if _merge==2
drop _merge

export delimited using "$datafran${sep}Stats.csv", replace
	
erase "$datafran${sep}Ineq_logearn_stats_timeseries.dta"
erase "$datafran${sep}Ineq_researn_stats_timeseries.dta"	
erase "$datafran${sep}Ineq_permearn_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_arcearn_5_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_arcearn_1_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_researn_5_stats_timeseries.dta"
erase "$datafran${sep}Dynamics_researn_1_stats_timeseries.dta"
erase "$datafran${sep}Ineq_earnings_stats_timeseries.dta"
erase "$folder${sep}${ineqdata}${sep}autocorr.dta"
erase "$datafran${sep}Slope.dta"

// END of Stats code	
	
	
********************************************************************************
foreach ff in 1 5{
	foreach x in res arc {
	global varx = "`x'earn`ff'"
	insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_allrank.csv",clear
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}			
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}
	
	g str12 age="25-55"
	g str12 gender="All genders"
	save $folder${sep}temp1,replace
	*sleep 500
	
forvalues j=1(1)3	{
    insheet using "$folder${sep}${voladata}${sep}L_`x'earn`ff'F_agerank.csv",clear
	g str3 country="${iso}"
	
	*Adjust for min number of observations
	qui: desc mean${varx}-p99_99${varx}, varlist
	local tvlist = r(varlist)
	foreach vvg of local tvlist{
		qui: replace `vvg' = . if n${varx} < $minnumberobs
	}	
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})
	drop min${varx} max${varx}

	g str12 gender="All genders"
	keep if agegp==`j'
	g str20 age="" 
	replace age="25-34" if agegp==1 
	replace age="35-44" if agegp==2
	replace age="45-55" if agegp==3
	drop agegp
	save $folder${sep}temp2_`j',replace
	*sleep 500
}

u $folder${sep}temp1,clear
drop gender age country
collapse *earn*f,by(permrank)
	g str3 country="${iso}"
	
	gen p9010${varx} = p90${varx} - p10${varx}
	gen p9050${varx} = p90${varx} - p50${varx}
	gen p5010${varx} = p50${varx} - p10${varx}
	gen ksk${varx} = (p9050${varx} - p5010${varx})/p9010${varx}
	gen cku${varx} = (p97_5${varx} - p2_5${varx})/(p75${varx} - p25${varx})

	g str12 gender="All genders"
	g str20 age="25-55" 
	g year=9999
	save $folder${sep}temp0,replace


u $folder${sep}temp0,clear
append using $folder${sep}temp1
append using $folder${sep}temp2_1
append using $folder${sep}temp2_2
append using $folder${sep}temp2_3
order country year gender age
sort country gender year age permrank 
*sleep 1000
save "$datafran${sep}Dynamics_`x'earn_`ff'_rank_heterogeneity", replace
*export delimited using "$datafran${sep}Dynamics_`x'earn_`ff'_rank_heterogeneity.csv", replace

erase $folder${sep}temp0.dta
erase $folder${sep}temp1.dta
erase $folder${sep}temp2_1.dta
erase $folder${sep}temp2_2.dta
erase $folder${sep}temp2_3.dta

}	// END loop arc res
}	// END loop over 1 and 5

u "$datafran${sep}Dynamics_researn_1_rank_heterogeneity", replace
merge country gender year age permrank using "$datafran${sep}Dynamics_researn_5_rank_heterogeneity"
tab _merge
drop _merge
sort country gender year age permrank
merge country gender year age permrank using "$datafran${sep}Dynamics_arcearn_1_rank_heterogeneity"
tab _merge
drop _merge
sort country gender year age permrank
merge country gender year age permrank using "$datafran${sep}Dynamics_arcearn_5_rank_heterogeneity"
tab _merge
drop _merge
ren * d*
ren  dcountry country  
ren  dgender gender 
ren  dyear year
ren  dage age
ren  dpermrank permrank

sort country gender year age permrank
export delimited using "$datafran${sep}Rank.csv", replace

erase "$datafran${sep}Dynamics_researn_1_rank_heterogeneity.dta"
erase "$datafran${sep}Dynamics_researn_5_rank_heterogeneity.dta"
erase "$datafran${sep}Dynamics_arcearn_1_rank_heterogeneity.dta"
erase "$datafran${sep}Dynamics_arcearn_5_rank_heterogeneity.dta"


****************MOBILITY
foreach jump in 1 5{
global wvari = "permearnalt"
insheet using "$folder${sep}${mobidata}${sep}L_all_${wvari}_mobstat.csv",clear

*Adjust for min number of observations
replace mean${wvari}ranktp`jump' = . if  n${wvari}ranktp`jump' < $minnumberobs

keep year ${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump'
rename (${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump') (rankt nranktp`jump' meanranktp`jump')

g str3 country="${iso}"
g str12 age="25-55"
g str12 gender="All genders"
save $folder${sep}temp`jump',replace
*sleep 500

forvalues j=1(1)3	{
    insheet using "$folder${sep}${mobidata}${sep}L_agegp_${wvari}_mobstat.csv",clear
	
	*Adjust for min number of observations
	replace mean${wvari}ranktp`jump' = . if  n${wvari}ranktp`jump' < $minnumberobs
	
	keep year agegp ${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump'
	rename (${wvari}rankt n${wvari}ranktp`jump' mean${wvari}ranktp`jump') (rankt nranktp`jump' meanranktp`jump')

	g str3 country="${iso}"

	g str12 gender="All genders"
	keep if agegp==`j'
	g str20 age="" 
	replace age="25-34" if agegp==1 
	replace age="35-44" if agegp==2
	replace age="45-55" if agegp==3
	drop agegp
	save $folder${sep}temp2_`j',replace
	*sleep 500
}

u $folder${sep}temp`jump',clear
append using $folder${sep}temp2_1
append using $folder${sep}temp2_2
append using $folder${sep}temp2_3
order country year gender age
sort country year gender age rankt
save, replace
erase $folder${sep}temp2_1.dta
erase $folder${sep}temp2_2.dta
erase $folder${sep}temp2_3.dta

}	// Jumps 1 and 5

u $folder${sep}temp1,clear
merge 1:1 country year gender age rankt using $folder${sep}temp5
drop _merge
drop nranktp*
export delimited using "$datafran${sep}Mobility.csv", replace
erase $folder${sep}temp1.dta
erase $folder${sep}temp5.dta



*#########################
*# END THE CODE
*#########################
