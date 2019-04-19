capture program drop bymyKDN bymyKDNmale bymyCNT bymyPCT bymysum bymysum_detail ///
					bymysum_meanonly bymyxtile

/*
	Programs do file for different statistics 
	Last update: April,18,2018
*/

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
	
	sum `varM' if `varM' > `p20' & `varM' <= `p40',  meanonly
	local q2share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' > `p40' & `varM' <= `p60',  meanonly
	local q3share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' > `p60' & `varM' <= `p80',  meanonly
	local q4share = 100*r(sum)/`tot'
	
	sum `varM' if `varM' > `p80',  meanonly
	local q5share = 100*r(sum)/`tot'
	
	*Bottom and top 50%
	
	sum `varM' if `varM' <= `p50',  meanonly
	local bot50share = 100*r(sum)/`tot'
	
	*Top shares
	
	sum `varM' if `varM' > `p90',  meanonly
	local top10share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' > `p95',  meanonly
	local top5share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' > `p99',  meanonly
	local top1share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' > `p995',  meanonly
	local top05share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' > `p999',  meanonly
	local top01share = 100*r(sum)/`tot'	
	
	sum `varM' if `varM' > `p9999',  meanonly
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
