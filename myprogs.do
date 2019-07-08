capture program drop bymySho bymyTranMat bymyKDN bymyKDNmale bymyCNT bymyPCT bymysum bymysum_detail ///
					bymysum_meanonly bymyxtile bymyCNTg bymyCNTgPop

/*
	Programs do file for different statistics 
	Last update: June,21,2018
*/


// Calculating Shorrocks mobility as in KSS (QJE,2010) using variance
// modsho defined as  modsho 1-M =  var(average)/average(var)	see KSS page pp.97
	
program bymySho
	
	local varT1 = "`1'"		// Variable from which individuals are transitioning 
	local varT2 = "`2'"		// Variable to which individuals are transitioning 
	
	local prefix="`3'"
	
	*local suffix = "`4'"
	
	qui: sum `varT1'
	local v1 = (r(sd))^2
	
	qui: sum `varT2'
	local v2 = (r(sd))^2
	preserve
		gen averesearn = (`varT1' + `varT2')/2
		qui: sum averesearn
		local v3 = (r(sd))^2
		
		gen modsho = `v3'/(`v1' + `v2')
		collapse modsho, by(`4')
	
		save "`prefix'`varT1'.dta", replace
	
	restore 

end 

/*Program to calculate transition matrix
  Note this program calculates the stats and creates a table in long form 
  This makes the conditioning on additional obsrvanle easier (like transition 
  within an age group)
*/
program bymyTranMat

	local varT1 = "`1'"		// Variable from which individuals are transitioning 
	local varT2 = "`2'"		// Variable to which individuals are transitioning 
	
	local prefix="`3'"
	
	local suffix = "`4'"	// Conditioning variables
	
	*preserve 
	
	gen progaux = 1			// Auxiliary variable
	
	drop if `varT2' ==.		// Drop if response variable is missing 
	
	collapse (count) movecount = progaux, by(`varT1' `varT2' `suffix')
	
	bys `suffix' `varT1': egen totcount = sum(movecount)
	bys `suffix' `varT1':  gen share =   100*movecount/totcount
	
	sort `suffix' `varT1' `varT2'
	order `suffix' `varT1' `varT2' movecount totcount share
	
	*Reshapes
	reshape wide movecount totcount share, i(`suffix' `varT1') j(`varT2')
	
	*Replaces missing transitions (transitions that are not present in the data) by 0
	levelsof `varT1', local(counts) clean
	foreach dd of local counts{
		replace movecount`dd' = 0 if movecount`dd' == .
		replace share`dd' = 0 if share`dd' == .
	}
	
	*Drop totals, they are not necessary.
	drop totcount*
	
	*Reshape back to long form 
	reshape long movecount share, i(`suffix' `varT1') j(`varT2')
	
	*Saves 
	local suffix = subinstr("`suffix'"," ","",.)
	save "`prefix'`varT2'_`suffix'.dta", replace	
	
	
	*restore 

end 

*Program to calculate the density and pareto tails
program bymyKDN 

	local varM = "`1'"
	local prefix="`2'"
	local npoint = "`3'"
	local suffix = "`4'"
	
	preserve 

	*Create the k-density 
	kdensity `varM', generate(val_`varM'`suffix' den_`varM'`suffix') nograph n(`npoint')
	keep val_`varM'`suffix' den_`varM'`suffix'
	qui: drop if val_`varM'`suffix' == . 		// Keep only the just created variables
	
	gen index  = _n
	
	*Save
	order index val_`varM'`suffix' den_`varM'`suffix'
	qui: save `prefix'`varM'_`suffix'_hist.dta, replace	
	
	restore 

end 

*Program to calculate the density and pareto tails
program bymyKDNmale 

	local varM = "`1'"
	local prefix="`2'"
	local npoint = "`3'"
	local suffix = "`4'"
	
	preserve 
	keep if male == 1
	*Create the k-density 
	kdensity `varM', generate(val_`varM'`suffix' den_`varM'`suffix') nograph n(`npoint')
	keep val_`varM'`suffix' den_`varM'`suffix'  male
	qui: drop if val_`varM'`suffix' == . 		// Keep only the just created variables
	
	gen index  = _n
	
	*Save
	order index val_`varM'`suffix' den_`varM'`suffix'
	qui: save `prefix'`varM'_`suffix'_hist1.dta, replace	
	
	restore 
	
	preserve 
	keep if male == 0
	*Create the k-density 
	kdensity `varM', generate(val_`varM'`suffix' den_`varM'`suffix') nograph n(`npoint')
	keep val_`varM'`suffix' den_`varM'`suffix' male
	qui: drop if val_`varM'`suffix' == . 		// Keep only the just created variables
	
	gen index  = _n
	
	*Save
	order index val_`varM'`suffix' den_`varM'`suffix'
	qui: save `prefix'`varM'_`suffix'_hist0.dta, replace	
	
	restore 
	
	preserve 
	*Append
	use `prefix'`varM'_`suffix'_hist1.dta, clear
	append using `prefix'`varM'_`suffix'_hist0.dta
	save `prefix'`varM'_`suffix'_hist_male.dta, replace
	
	erase  `prefix'`varM'_`suffix'_hist1.dta
	erase  `prefix'`varM'_`suffix'_hist0.dta
	restore 

end 

*Program to calculate the change in concentration at the top fo the distribution using 
*the decomposition of  "Displacement and the Rise in Top Wealth Inequality: by  Matthieu Gomez
*This implements the version with population change. 

program bymyCNTgPop
	
	local varM   = "`1'"			// Current earnings 
	local prefix = "`2'"			// Name of the file 
	local yrl = "`3'"				// Current year
	local p = "`4'"					// Value of tau
	local qtile = "`5'"				// What top percentile we are calculating (e.g. 99 for the top 1%)	
	local het = "`6'"				// What sample. Missing if all sample; 0 for women; 1 for men
	
	local varMp = "earnp`p'"
	local yrpl = `yrl'+1
	
	
	preserve
	
		*Defines whether we are calculating the concetration decompisition within 
		*Gender groups. Het must take values 1 (for men) or 0 (for women)
		if "`het'" != ""{
			qui: keep if male == `het'
		}
		
		*Normalizing individual income (i.e. `varmM' is the individual share on total income)
		sum `varM'  if (`varM' >= rmininc[`yrl'-${yrfirst}+1,1]) & `varM' != .,  meanonly
		qui: gen double aux = 100*`varM'/r(sum)	
		local totM = r(sum)
		drop `varM'
		rename aux `varM'
		
		sum `varMp' if (`varMp' >= rmininc[`yrpl'-${yrfirst}+1,1]) & `varMp' != .,  meanonly
		qui: gen double aux = 100*`varMp'/r(sum)	
		local totMp = r(sum)
		drop `varMp'
		rename aux `varMp'
		
		
		*Calculate percentile 
		_pctile `varM'  if (`varM'  >= 100*rmininc[`yrl'-${yrfirst}+1,1]/`totM')  & `varM' != .  ,p(`qtile')		// Income in t
		local top =  r(r1)
		
		_pctile `varMp' if (`varMp' >= 100*rmininc[`yrpl'-${yrfirst}+1,1]/`totMp') & `varMp' != . ,p(`qtile')		// Income in t+p
		local topp =  r(r1)
		
		*Top shares and identification of those at the top in period t
		*This is equivalent to S_t in top expression in page 16 of Gomez's paper
		sum `varM' if `varM' >= `top' & `varM' != . ,  meanonly
		
		local St = r(sum)								// This is the share. Recall income is normalized already
		local T = r(N)									// Number of observations at the top 
		cap: gen idSt = `varM' >= `top' if `varM' != .  // This identifies individuals at the top in year t
		
		*Top shares and identification of those at the top in period t+p
		sum `varMp' if `varMp' >= `topp' & `varMp' != . ,  meanonly
		
		local Stp = r(sum)									// This is the share 
		local Tp = r(N)										// Number of observations at the top 
		cap: gen idStp = `varMp' >= `topp' if `varMp' != . 	// This identifies individuals at the top in year t
		
		*Define Within share 
			sum `varM'  if idSt == 1 & `varMp' != . ,meanonly   // Sum i\inT\Xd in eq. 21
															   // We treat missing observations as death in eq. 21
			local deno = r(sum)								   // Denominator eq. 21
			
			sum `varMp' if idSt == 1 & `varMp' != .,meanonly 	// t+p earnings for those who were at the top in t 
			local nume = r(sum)
			local Rwith = `nume'/`deno'-1.0
				
		*Define the displacement share (As in equation 22)
			qui: gen aux = `varMp' - `topp'
			sum aux if (idStp == 1 & idSt == 0), meanonly	
			local RdispL = r(sum)/`St'
			drop aux
			
			qui: gen aux = `topp' - `varMp' 
			sum aux if (idStp == 0 & idSt == 1), meanonly			
			local RdispR = r(sum)/`St'
			drop aux
			
			local Rdisp = `RdispL' + `RdispR'
		
		*Define the Demographic Share. This has four pieces
			*Sum of Ed--> This in individuals entering the top p percent in 
			*year t+tau that where ${begin_age} - 1 in year t
			qui: sum `varMp' if (idStp == 1 & `varM' == .), meanonly
			local demo25 = r(sum)/`St'
			local numE25 = r(N)
			
			*Sum (1+R)wit, is the last term in the death part
			qui: sum `varM' if idSt == 1 & `varMp'== ., meanonly
			local demo55 = r(sum)*(1+`Rwith')/`St'
			local numX55 = r(N)
			
		
			*(Xd-Ed)*qt+tau
			local demoDiff =  ((`numX55' - `numE25')*`topp')/`St'
			
			*(T'+T)*q/Wt, is the fraction due to pop growth
			local demoPop = ((`Tp'-`T')*`topp')/`St'
			
			*Left section 
			local Rretir = (`demo25' + `demoDiff' - `demo55')
			
			local Rgrowth = `demoPop'		
		
		*Define the growth in share 
		local gSt = `Rwith' + `Rdisp' + `Rretir' +`Rgrowth'
		
		/* This displays the results
		disp `Rwith'
		disp `Rdisp'
		disp `Rretir'
		disp `Rgrowth'
		disp ""
		disp `gSt'
		disp (`Stp' - `St')/`St' 
		disp ""
		disp `St'
		disp `Stp'
		*/
		
		clear 
		qui: set obs 1 
		gen year = `yrl'
		gen yearp = `yrl' + `p'
		
		gen St = `St'
		gen Stp = `Stp'
		gen gSt = (`Stp' - `St')/`St' 
		gen Rwithin = `Rwith'
		gen Rdispla = `Rdisp'
		gen Rretir =  `Rretir'
		gen Rgrowth = `Rgrowth'
		
		
		label var St  "Share of Top 1% in year t"
		label var Stp "Share of Top 1% in year t+`p'"
		label var gSt "Growth of share of Top 1% between year t and t+`p'"
		label var Rwithin "Part of growth by within change in income"
		label var Rdispla "Part of growth by displacement"
		label var Rretir "Part of growth by retirement"
		label var Rgrowth "Part of growth by pop growth"
		
		*Save
		
		
		*Define the sample. If we take all the sample the code does not enter here
		if "`het'" != ""{
			gen male = `het'
			order year male yearp St Stp Rwithin Rdispla Rretir Rgrowth
			qui: save `prefix'`varM'_`yrl'_gStPop`p'_male`het'.dta, replace	
		}
		else{
			order year yearp St Stp Rwithin Rdispla Rretir Rgrowth
			qui: save `prefix'`varM'_`yrl'_gStPop`p'.dta, replace	
		}

	restore 
		
end 



*Program to calculate the change in concetration at the top of the distribution using 
*the decomposition of "Displacement and the Rise in Top Wealth Inequality: by  Matthieu Gomez
*This implements the version w/o population change. 
program bymyCNTg

	local varM   = "`1'"
	local prefix = "`2'"
	local suffix = "`3'"
	local p = "`4'"
	local qtile = "`5'"
	
	local varMp = "earnp`p'"
	preserve
		*Keep non-missing in period t 		
		qui: drop if `varM'==.				
		
		*Keep non-missing in period t+p
		qui: drop if `varMp'==.				// This ensure the population does not change
		
		*Calculate total income 
		sum `varM',  meanonly
		local tot = r(sum)
		local numobs = r(N)
		
		*Calculate percentile 
		_pctile `varM',p(`qtile')		// Income in t
		local top =  r(r1)
		
		_pctile `varMp',p(`qtile')		// Income in t+p
		local topp =  r(r1)
		
		*Top shares and identification of those at the top in period t
		*This is equivalent to S_t in top expression in page 16 of Gomez's paper
		sum `varM' if `varM' >= `top' & `varM' != . ,  meanonly
		
		local St = r(sum)/`tot'							// This is the share 
		local Wt = r(sum)								// This is the sum
		cap: gen idSt = `varM' >= `top' & `varM' != .  // This identifies individuals at the top in year t
		
		*Top shares and identification of those at the top in period t+p
		sum `varMp' if `varMp' >= `topp' & `varMp' != . ,  meanonly
		
		local Stp = r(sum)/`tot'							// This is the share 
		local Wtp = r(sum)									// This is the sum
		cap: gen idStp = `varMp' >= `topp' & `varMp' != . 	// This identifies individuals at the top in year t
		
		*Define Within share 
		sum `varMp' if idSt == 1 & `varMp' != . , meanonly	// t+p earnings for those who were at the top in t 
		local aux = r(sum)
		local Rwith = `aux'/`Wt'-1
		
		*Define displacement Share (As in equation 18)
		sum `varMp' if (idStp == 1 & idSt == 0)		// Individuals that entered at the top
		local RdispL = r(sum)
		
		sum `varMp' if (idStp == 0 & idSt == 1)		// Indicviduals that exited the top 
		local RdispR = r(sum)
		
		local Rdisp = (`RdispL' - `RdispR')/`Wt'
		
		*Decomposing the displacement share (As in equation 19)
		gen aux = `varMp' - `topp'
		sum aux if (idStp == 1 & idSt == 0)		
		local RdispL = r(sum)/`Wt'
		drop aux
		
		gen aux = `topp' - `varMp' 
		sum aux if (idStp == 0 & idSt == 1)		
		local RdispR = r(sum)/`Wt'
		drop aux
		
		*Define the growth in share 
		local gSt = `Rwith' + `Rdisp'
		
		disp `Rwith'
		disp `Rdisp'
		disp `RdispL' + `RdispR'
		disp `gSt'
		disp (`Stp' - `St')/`St' 
		
		clear 
		qui: set obs 1 
		gen year = `suffix'
		gen yearp = `suffix' + `p'
		
		gen St = `St'
		gen Stp = `Stp'
		gen Wt = `Wt'
		gen Wtp = `Wtp'
		gen gSt = (`Stp' - `St')/`St' 
		gen Rwithin = `Rwith'
		gen Rdispla = `Rdisp'
		gen RdispL = `RdispL'
		gen RdispR = `RdispR'
		
		
		label var St  "Share of Top 1% in year t"
		label var Stp "Share of Top 1% in year t+`p'"
		label var gSt "Growth of share of Top 1% between year t and t+`p'"
		label var Rwithin "Part of growth by within change in income"
		label var Rdispla "Part of growth by displacement"
		
		*Save
		order year yearp St Stp Wt Wtp Rwithin Rdispla
		qui: save `prefix'`varM'_`suffix'_gSt`p'.dta, replace	
	restore 
		
end 


*Program to calculate the concetration measures 
program bymyCNT 

	local varM   = "`1'"
	local prefix = "`2'"
	local suffix = "`3'"
	
	preserve
	qui: drop if `varM'==.
	
	*Sorting income 
	sort `varM'
	
	*Calculate total income 
	sum `varM',  meanonly
	local tot = r(sum)
	local numobs = r(N)
	
	*Calculate percentiles
	_pctile `varM',p(20,40,50,60,80,90,95,99,99.5,99.9,99.99)	
	
	local p20 =  r(r1)
	local p40 =  r(r2)
	local p50 =  r(r3)
	local p60 =  r(r4)
	local p80 =  r(r5)
	local p90 =  r(r6)
	local p95 =  r(r7)
	local p99 =  r(r8)
	local p995 =  r(r9)
	local p999 =  r(r10)
	local p9999 =  r(r11)
	
	*Quintiles
	sum `varM' if `varM' <= `p20',  meanonly
	local q1share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' >= `p20' & `varM' <= `p40',  meanonly
	local q2share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' >= `p40' & `varM' <= `p60',  meanonly
	local q3share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' >= `p60' & `varM' <= `p80',  meanonly
	local q4share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' >= `p80',  meanonly
	local q5share = 100*r(sum)/`tot'
	
	*Bottom and top 50%
	
	sum `varM' if `varM' <= `p50',  meanonly
	local bot50share = 100*r(sum)/`tot'
	
	*Top shares
	
	sum `varM' if `varM' >= `p90',  meanonly
	local top10share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' >= `p95',  meanonly
	local top5share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' >= `p99',  meanonly
	local top1share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' >= `p995',  meanonly
	local top05share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' >= `p999',  meanonly
	local top01share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' >= `p9999',  meanonly
	local top001share = 100*r(sum)/`tot'
	
	*Gini Coefficient
	gen temp = _n*`varM'
	sum temp, meanonly 
	local ginitot = r(sum)
	
// https://www.statsdirect.com/help/default.htm#nonparametric_methods/gini.htm		
	local gini = (2.0*`ginitot' -(`numobs'+1)*`tot')/(`numobs'*`tot')		
		
		clear 
		qui: set obs 1 
		gen year = `suffix'
		
		
		gen p20 = `p20'
		gen p40 = `p40'
		gen p50 = `p50'
		gen p60 = `p60'
		gen p80 = `p80'
		gen p90 = `p90'
		gen p95 = `p95'
		gen p99 = `p99'
		gen p995 = `p995'
		gen p999 = `p999'
		gen p9999 = `p9999'
		
		gen q1share = `q1share'
		gen q2share = `q2share'
		gen q3share = `q3share'
		gen q4share = `q4share'
		gen q5share = `q5share'
		
		gen bot50share = `bot50share'
		
		gen top10share = `top10share'
		gen top5share = `top5share'
		gen top1share = `top1share'
		gen top05share = `top05share'
		gen top01share = `top01share'
		gen top001share = `top001share'
		
		gen gini = `gini'
		
		*Save
		order year p* q* bot* top* 
		qui: save `prefix'`varM'_`suffix'_con.dta, replace	
	
	restore 
end 
// END of program for concentration


*Program to calculate the cross sectional statistics
program bymyPCT 

	preserve
	local varM="`1'"
	local prefix="`2'"
	local suffix="`3'"
				
	global statlist1 ="p1`varM'=r(r1) p2_5`varM'=r(r2) p5`varM'=r(r3) p10`varM'=r(r4) p12_5`varM'=r(r5)"
	global statlist2 ="p25`varM'=r(r6) p37_5`varM'=r(r7) p50`varM'=r(r8) p62_5`varM'=r(r9)"
	global statlist3 ="p75`varM'=r(r10) p87_5`varM'=r(r11) p90`varM'=r(r12) p95`varM'=r(r13)" 
	global statlist4 ="p97_5`varM'=r(r14) p99`varM'=r(r15) p99_9`varM'=r(r16) p99_99`varM'=r(r17)" 
	qui statsby $statlist1 $statlist2 $statlist3 $statlist4, by(`4') saving(PC_`prefix'`varM'`suffix',replace): ///
	_pctile `varM',p(1,2.5,5,10,12.5,25,37.5,50,62.5,75,87.5,90,95,97.5,99,99.9,99.99) 
	
	restore
end


*Program to calculate the cross sectional statistics
program bymysum 
	preserve
	local varM="`1'"
	local prefix="`2'"
	local suffix="`3'"
	
	global statlist1 ="N`varM'=r(N) mean`varM'=r(mean) sd`varM'=r(sd)"
	global statlist2 ="min`varM'=r(min) max`varM'=r(max)"
	qui statsby $statlist1 $statlist2, by(`4') saving(S_`prefix'`varM'`suffix',replace): ///
	summarize `varM'
				
	restore
end

*Program to calculate the cross sectional statistics
program bymysum_meanonly 
	preserve
	local varM="`1'"
	local prefix="`2'"
	local suffix="`3'"
	
	global statlist1 ="N`varM'=r(N) mean`varM'=r(mean) "
	qui statsby $statlist1, by(`4') saving(S_`prefix'`varM'`suffix',replace): ///
	summarize `varM', meanonly
				
	restore
end


*Program to calculate the cross sectional statistics
program bymysum_detail
	preserve
	local varM="`1'"
	local prefix="`2'"
	local suffix="`3'"
	
	global statlist1 ="N`varM'=r(N) mean`varM'=r(mean) sd`varM'=r(sd) skew`varM'=r(skewness)"
	global statlist2 ="kurt`varM'=r(kurtosis) min`varM'=r(min) max`varM'=r(max)"
	qui statsby $statlist1 $statlist2, by(`4') saving(S_`prefix'`varM'`suffix',replace): ///
	summarize `varM',detail 
				
	restore
end

*Program to put individuals in bins given percentiles
program bymyxtile, byable(recall)
	//	syntax [varlist] [if] 
	local numq = "`3'"
	marksample touse 
	tempvar temp_rank
	capture noisily xtile `temp_rank'=`1' if `touse', nq(`numq')
	capture noisily replace `2'=`temp_rank' if `touse'
end 
