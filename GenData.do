/* GenData.do (STATA)
	Generate a fake Norwegian Registry dataset.
	by Halvorsen, Ozkan, and Salgado.*/

clear all
set more off

cd "/Users/serdar/Dropbox/GLOBAL-MASTER-CODE/STATA/dta"

global male=1 			// 1 male, 0 female
local seednum=1000+${male}
set seed `seednum'

global yrfirst = 1993 		// First year in the dataset
global yrlast = 2014 		// Last year in the dataset
global begin_age = 20 
global retire_age = 60

global sd_alpha=0.50
global sd_beta=0.252
global rho=0.97
global sd_eta=0.174
global sd_eps=0.03
global a0=2.60
//global a0=2.75
global a1=0.509338054
global a2=-0.076545279	
global a3=-0.0016078135

global unemp_prob=0.05
global wage_self_prob=0.035 // wage_self_prob fraction of population has both wage and self employment income
global self_prob=0.07 // self_prob fraction of population has self employment income

global prob_ainc=0.80 // probability of having nonzero asset income

global nobs=1500

global firstcoh=${yrfirst}-${retire_age} 
global lastcoh= ${yrlast}-${begin_age}

global base_price = 52   /* this is the index of the year 2010 */
matrix cpimat = /*  PCE for 1959-2013 from the US
*/ (17.262,17.546,17.730,17.939,18.149,18.414,18.681,19.155,19.637,20.402,	/*
*/ 21.327,22.325,23.274,24.070,25.368,28.009,30.348,32.013,34.091,36.479, 	/*
*/ 39.714,43.978,47.908,50.553,52.729,54.724,56.661,57.887,59.650,61.974,	/*
*/ 64.641,64.641,67.440,69.652,71.494,73.279,74.803,76.356,77.981,79.327,	/*
*/ 79.936,81.110,83.131,84.736,85.873,87.572,89.703,92.261,94.729,97.101, 	/*
*/ 100.065,100.000,101.653,104.149,106.062,107.333)


forvalues coh=$firstcoh/$lastcoh{
	capture drop _all
	local tnobs=floor(${nobs}*1.015^(`coh'-${firstcoh}))
	set obs `tnobs'
	gen byte male=${male}
	label variable male "=1 if men"
	gen b_year=`coh'
	label variable b_year "year of birth"
	gen yod=b_year+55+floor(runiform()*30)
	replace yod=. if yod>2015
	label variable yod "year of death"	
	gen educ=min(3,1+floor(runiform()*3))
	label variable educ "Education"	
	gen alpha=${sd_alpha}*rnormal()
	gen beta=${sd_beta}*rnormal()
	gen z=0
	gen alpha_s=${sd_alpha}*rnormal()
	gen beta_s=${sd_beta}*rnormal()
	gen z_s=0		
	gen unemp=.
	gen oldein=.
	gen self=.	
	gen temps=.
	gen tempw=.
	forvalues age=$begin_age/$retire_age{
		local agen=(`age'-${begin_age}+1)/10
		replace z=${rho}*z+${sd_eta}*rnormal()
		replace z_s=${rho}*z_s+${sd_eta}*rnormal()		
		local yr=`coh'+`age'-1
		if(`yr'>=${yrfirst} & `yr'<=${yrlast}){
			gen double wage_inc`yr' = alpha + beta*`agen'+z+${sd_eps}*rnormal() + ///
			${a0} + ${a1}*`agen'+${a2}*`agen'^2+ ${a3}*`agen'^3
			replace wage_inc`yr'=exp(wage_inc`yr')*1000
			local cpi_index = `yr'-1959+1
			local deflate = cpimat[1,`cpi_index']/cpimat[1,$base_price]
			replace wage_inc`yr'=wage_inc`yr'*`deflate'
			label variable wage_inc`yr' "Wage income"
			
			// I choose mu1 such that only self_prob fraction of the population
			// has a self employment income higher than wage.
			local age1=(`age'-${begin_age}+1)
			local rho_sq=${rho}^2
			local sd=${sd_alpha}^2 + (`agen'^2)*${sd_beta}^2 + ${sd_eps}^2 + ///
						((1-`rho_sq'^`age1')/(1-`rho_sq'))*${sd_eta}^2
			local sd=sqrt(`sd'*2)
			local mu2=${a0} + ${a1}*`agen'+${a2}*`agen'^2+ ${a3}*`agen'^3
			local mu1=-invnormal(1-${self_prob})*`sd' + `mu2' 			
			gen double bus_inc`yr' = `mu1'+ alpha_s + beta_s*`agen'+z_s+${sd_eps}*rnormal() 		
			replace bus_inc`yr'=exp(bus_inc`yr')*1000
			local cpi_index = `yr'-1959+1
			local deflate = cpimat[1,`cpi_index']/cpimat[1,$base_price]
			replace bus_inc`yr'=bus_inc`yr'*`deflate'
			label variable bus_inc`yr' "Net business income"
			
			replace unemp=runiform()
			gen unemp_benefit`yr'=(unemp<${unemp_prob})*(wage_inc`yr'+bus_inc`yr')*0.4
			label variable unemp_benefit`yr' "Unemployment Benefit"
			replace bus_inc`yr'= 0 if unemp<${unemp_prob}
			replace wage_inc`yr'= 0 if unemp<${unemp_prob}

			
			replace self=runiform()
			replace temps=bus_inc`yr'
			replace tempw=wage_inc`yr'
			// wage_self_prob fraction of population has both wage and self employment income
			replace bus_inc`yr'=temps*(self<${wage_self_prob})+ ///
								temps*(self>=${wage_self_prob})*(temps>tempw)
			replace wage_inc`yr'=tempw*(self<${wage_self_prob}) + ///
							   tempw*(self>=${wage_self_prob})*(tempw>=temps)
			replace bus_inc`yr'= . if `yr'>=yod
			replace wage_inc`yr'= . if `yr'>=yod	
			
			local mean_a=exp(${a0} + ${a1}*`agen'+${a2}*`agen'^2+ ${a3}*`agen'^3)*1000/2
			local sd_a=0.2*`mean_a'			
			gen double cap_inc`yr' =(runiform()>${prob_ainc})*rnormal(`mean_a',`sd_a')
			replace cap_inc`yr' = . if `yr'>=yod
			label variable cap_inc`yr' "Capital income"
						
			gen double grossinc`yr' = wage_inc`yr' + bus_inc`yr' + cap_inc`yr'
			label variable grossinc`yr' "Wage+Bus+Cap Income"
			
			gen double inc_at`yr' = exp(${a0} + ${a1} +${a2} + ${a3} )*1000/4 + 0.7*grossinc`yr'
			label variable inc_at`yr' "After Tax/Transfer Income"
		}
	}
	drop alpha beta z alpha_s beta_s z_s unemp oldein self temps tempw
	save coh`coh'.dta, replace
}

drop _all
use coh$firstcoh
erase coh$firstcoh.dta
local cohn=$firstcoh+1
forvalues coh=`cohn'/$lastcoh{
	append using coh`coh'
	erase coh`coh'.dta
}

gen long hh_id=_n
order hh_id, first
save temp_${male}.dta, replace


// Merge Male and Female datasets

drop _all 
use temp_1.dta
erase temp_1.dta
append using temp_0.dta
erase temp_0.dta
save temp.dta,replace

// 

gen idnr= 2*_N + _n 
label variable idnr "Individual identity number"
order hh_id idnr male b_year yod, first	

bys hh_id: egen temp=max(b_year) 
replace temp=temp+ 20 + floor(40*uniform())
bys hh_id: egen beg_mar=max(temp) 
drop temp

gen temp=min(beg_mar + floor(40*uniform()),yod)
bys hh_id: egen end_mar=min(temp) 
drop temp

gen temp=0
forvalues yr=$yrfirst/$yrlast{
	gen hh_idn`yr'=0
	label variable hh_idn`yr' "Household Id"
	
	replace hh_idn`yr'=hh_id if `yr'>=beg_mar & `yr'<=end_mar 
	replace hh_idn`yr'=idnr+ _N if `yr'<beg_mar | `yr'>end_mar 

	gen marital`yr'=0
	replace marital`yr'=1 if `yr'>=beg_mar & `yr'<=end_mar 
	label variable marital`yr' "Marital Status"
	
	gen main`yr'=0
	replace main`yr'=1 if male==1
	replace main`yr'=1 if male==0 & marital`yr'==0
	label variable main`yr' "Head of household"	
	
	foreach var in wage_inc bus_inc unemp_benefit cap_inc grossinc inc_at{
		replace `var'`yr'=0 if `var'`yr'==.
	}
	
	replace temp=1 + floor(2*uniform())
	replace temp=temp+1  if marital`yr'==1
	bys hh_idn`yr': egen size`yr'=min(temp) 
	label variable size`yr' "Family size"	
	
	by hh_idn`yr': egen hhwage_inc`yr'=total(wage_inc`yr')
	label variable hhwage_inc`yr' "HH Wage income"

	by hh_idn`yr': egen hhbus_inc`yr'=total(bus_inc`yr')
	label variable hhbus_inc`yr' "HH Business income"

	by hh_idn`yr': egen hhunemp_benefit`yr'=total(unemp_benefit`yr')
	label variable hhunemp_benefit`yr' "HH Unemployment Benefit"
	
	by hh_idn`yr': egen hhcap_inc`yr'=total(cap_inc`yr')
	label variable hhcap_inc`yr' "HH Capital Income"
	
	by hh_idn`yr': egen hhgrossinc`yr'=total(grossinc`yr')	
	label variable hhgrossinc`yr' "HH Gross Income"
	
	by hh_idn`yr': egen hhinc_at`yr'=total(inc_at`yr')	
	label variable hhinc_at`yr' "HH After Tax/Transfer Income"	
	
	by hh_idn`yr': gen consumption`yr'=0.75*hhinc_at`yr'*runiform() + ///
								exp(${a0} + ${a1} +${a2} + ${a3} )*1000/4		
	label variable consumption`yr' "HH Consumption"
}
drop temp beg_mar end_mar hh_id


save data_wide, replace
//erase temp.dta

reshape long wage_inc bus_inc unemp_benefit cap_inc grossinc inc_at ///
hh_idn marital main size hhwage_inc hhbus_inc hhcap_inc hhgrossinc hhinc_at ///
consumption, i(idnr) j(year)

gen age=year-b_year+1

gen cpi =0
forvalues yr=$yrfirst/$yrlast{
	replace cpi = cpimat[1,`yr'-1959+1] if year==`yr'
}
order hh_idn year idnr male b_year yod age marital main cpi, first
drop if yod<=year
save data_long, replace
saveold data_long12, replace



