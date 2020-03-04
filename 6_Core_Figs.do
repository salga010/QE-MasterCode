// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the core figures
// Last edition March, 03, 2020
// Serdar Ozkan and Sergio Salgado
// 
// The figures below are meant to be a guideline and might require some changes 
// to accommodate the particularities of each dataset. If you have any question
// please contact Ozkan/Salgado in Slack
//
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off

global maindir =".../GLOBAL-MASTER-CODE/STATA"

// Where the data is stored
global ineqdata = ".."			// Data on Inequality 
global voladata = "..."			// Data on Volatility
global mobidata = ".."			// Data on Mobility

// Do not make change from here on. Contact Ozkan/Salgado if changes are needed. 
	do "$maindir/do/0_Initialize.do"
	do "$maindir${sep}do${sep}myplots.do"		
	
// Define some common charactristics of the plots 
	global xtitlesize =   "medium" 
	global ytitlesize =   "medium" 
	global titlesize  =   "large" 
	global subtitlesize = "medium" 
	global formatfile  =  "pdf"
	global fontface   =   "Times New Roman"
	global marksize =     "medium"	


// Where the firgures are going to be saved 
	global outfolder="figs_18Jan2020"			
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}"

	*Save Inequality
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Inequality"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Inequality${sep}logearn"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Inequality${sep}researn"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Inequality${sep}permearn"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Inequality${sep}tail"
	
	*Concentration
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Concentration"
	
	*Save Volatility
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Volatility"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Volatility${sep}researn1F"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Volatility${sep}researn5F"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Volatility${sep}arcearn1F"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Volatility${sep}arcearn5F"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Volatility${sep}densities"
	
	
	*Save Quantile plots
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Quantiles"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Quantiles${sep}researn1F"
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Quantiles${sep}researn5F"
	
	*Save Mobility plots
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Mobility"
	
	*Save Cohort plots
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}Cohorts"
	
	   
// Cd to folder with out 
	cd "$maindir${sep}" // Cd to the folder containing the files
	

// Which section are we ploting 
	global figineq = "no"			// Inequality  Figs 1 and 2 
	global figtail = "no"			// Tail 	   Figs 3a
	global figcon =  "no"			// Concetration Figb 3a
	global figvol =  "yes"			// Volatility Figb 4 to 7
	global figquan = "no"			// quantiles Figb 8
	global figmob = "no"			// Mobility Fig 11
	global figcoh = "no"			// Cohorts Fig 12
	
	global yrlast = 2017
		
/*---------------------------------------------------	
    This section generates the figures 1 and 2 
	and corresponding appendix figures required in poins 1 to 4 in  the
	Common Core section of the Guidelines
 ---------------------------------------------------*/
if "${figineq}" == "yes"{ 	


	// PLOTS OF TAIL COEFFICIENTS FOR RELATIVE VALUES
	global folderfile = "figs${sep}${outfolder}${sep}Inequality${sep}tail"
	
	*Load and reshape data 			
	insheet using "out${sep}${ineqdata}${sep}RI_earn_idex.csv", clear comma 

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
	
	gen t1000s = t/1000
	gen lt1000s = log(t1000s)
	gen lt = log(t)
	gen l10t = log10(t)
	
	*Re-reshape 
	reshape wide t me ra ob tob shob lshob t1000s lt l10t lt1000s, i(numlevel) j(year)
	
	preserve 
		keep if lt1995 != . & ra1995 !=.
		dnplot "ra1995" "l10t1995" /// y and x variables 
				"Labor Income Threshold in 1000s of Real LC" "Ratio Ave-Earnigs to Threshold" "medium" "medium" 	///
				 "Saez Figure for Realtive Income Levels in 1995" "" "large" ""  ///	Plot title
				 "" "" "" "" "" ""						/// Legends
				 ""	"11" "2"				/// Leave empty for active legend; 2 for position
				"figSaez_REearn1995"		// Name of file
	restore 
	
	preserve 
		keep if ra2000 != . & lt2000 !=.
		dnplot "ra2000 ra1995" "l10t2000" /// y and x variables 
				"Labor Income Threshold in 1000s of Real LC" "Ratio Ave-Earnigs to Threshold" "medium" "medium" 	///
				 "Saez Figure for Realtive Income Levels in 2000" "" "large" ""  ///	Plot title
				 "1995" "2000" "2005" "2010" "" ""						/// Legends
				 ""	"11" "2"				/// Leave empty for active legend; 2 for position
				"figSaez_REearn2000"		// Name of file
	restore 
	
	dnplot "lshob1995 lshob2000 lshob2005 lshob2010" "lt2000" /// y and x variables 
			"Log Labor Income" "log(1-CDF)" "medium" "medium" 	///
			 "Inverse log-CDF" "" "large" ""  ///	Plot title
			 "1995" "2000" "2005" "2010" "" ""						/// Legends
			 ""	"2" "1"				/// Leave empty for active legend; 2 for position
			"figSaez_lshob2000"		// Name of file

	dnplot "lshob1995 lshob2000 lshob2005 lshob2010" "numlevel" /// y and x variables 
			"Labor Income Threshold in 1000s of Real LC" "Ratio Ave-Earnigs to Threshold" "medium" "medium" 	///
			 "Inverse log-CDF" "" "large" ""  ///	Plot title
			 "1995" "2000" "2005" "2010" "" ""						/// Legends
			 ""	"2" "1"				/// Leave empty for active legend; 2 for position
			"figSaez_lshob2000_nume"		// Name of file
	

// PLOTS OF TAIL COEFFICIENTS FOR ABSOLUTE VALUES
	global folderfile = "figs${sep}${outfolder}${sep}Inequality${sep}tail"
	
	*Load and reshape data 
	insheet using "out${sep}${ineqdata}${sep}AI_earn_idex.csv", clear comma 
	
	reshape long t me ra ob, i(year) j(level) string
	split level, p(level) 
	drop level1
	rename level2 numlevel
	destring numlevel, replace 
	order numlevel level year 
	sort year numlevel
	
	*Re scale and share of pop
	by year: egen tob = sum(ob)
	by year: gen  shob = 100*ob/tob
	
	gen t1000s = t/1000
	
	*Re-reshape 
	reshape wide t me ra ob tob shob, i(numlevel) j(year)
	
	
	*Ploting
	dnplot "ra1995 ra2000 ra2005 ra2010" "t1000s" /// y and x variables 
			"Labor Income Threshold in 1000s of Real LC" "Ratio Ave-Earnigs to Threshold" "medium" "medium" 	///
			 "Saez Figure for Income Levels" "" "large" ""  ///	Plot title
			 "1995" "2000" "2005" "2010" "" ""						/// Legends
			 ""	"2" "1"				/// Leave empty for active legend; 2 for position
			"figSaez_earn"		// Name of file

	dnplot "shob1995 shob2000 shob2005 shob2010" "t1000s" /// y and x variables 
			"Labor Income Threshold in 1000s of Real LC" "Share of Polulation above w (1-G(w))" "medium" "medium" 	///
			 "Saez Figure for Income Levels" "" "large" ""  ///	Plot title
			 "1995" "2000" "2005" "2010" "" ""						/// Legends
			 ""	"2" "1"				/// Leave empty for active legend; 2 for position
			"figSaez_shares_earn"		// Name of file

	
// PLOTS RESEARN
	*Define the saving folder 
	global folderfile = "figs${sep}${outfolder}${sep}Inequality${sep}researn"	

	foreach var in researn {	
	foreach subgp in all male fem{
	
	*Which variable will be ploted
	global vari = "`var'"						 
	
	*What is the group under analysis? 
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_sumstat.csv", clear
		local labname = "All"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
		local labname = "Men"
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local labname = "Women"
	}
	
	*What is the label for title 
	if "${vari}" == "logearn"{
		local labtitle = "log y{sub:it}"
	}
	if "${vari}" == "researn"{
		local labtitle = "{&epsilon}{sub:it}"
	}
	if "${vari}" == "permearn"{
		local labtitle = "P{sub:it-1}"
	}
	
	*What are the x-axis limits
	if "${vari}" == "logearn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "researn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "permearn"{
		local lyear = ${yrfirst}+2
		local ryear = ${yrlast}
	}
	
	*Normalize Percentiles 
	gen var${vari} = sd${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}

	*Rescale by first year 
	foreach vv in sd$vari var$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
		p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
		p97_5$vari p99$vari p99_9$vari p99_99$vari p9010$vari p9050${vari} p5010${vari} ksk${vari}{
		sum  `vv' if year == ${normyear}, meanonly
		gen n`vv' = `vv' - r(mean)	
	}
	gen rece = inlist(year,${receyears})

// Figure 1 (normalized percentiles)
	tspltAREALim "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari np99$vari np99_9$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99" "p99.9" /// Labels 
	   "2" "11" ///
	   "" /// x axis title
	    "Percentiles Relative to `lyear'" /// y axis title 
	   "Percentiles of `labtitle' for Sample: `labname'" ///  Plot title
	   "" ///
	   "fig1_`subgp'_${vari}"	/// Figure name
	   "-0.2" "1" "0.2"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
		       
	tspltAREALim "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "" "" /// Labels 
	   "3" "11" ///
	   "" /// x axis title
	    "Percentiles of `labtitle' (`lyear'=0)" /// y axis titl
	   "Percentiles of `labtitle' for Sample: `labname'" ///  Plot title
	   "" ///
	   "fig1short_`subgp'_${vari}"	/// Figure name
	   "-.2" "0.2" "0.1"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
		
// Figure 2 (Inequality)
	tsplt2sc "p9010${vari}" "var${vari}" /// variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "Variance" /// Labels 
		   "" /// x axis title
		   "P90-P10 of `labtitle'" /// y axis title (left)
		   "Variance of `labtitle'" /// y axis title  (right)
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2a_`subgp'_${vari}"	// Figure name
	
	tspltAREALim2 "p9050${vari} p5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2b_`subgp'_${vari}"	/// Figure name
		    "0.4" "1.2" "0.2"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
// Figure 2 Rescale
	tspltAREALim2 "np9010${vari} nvar${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "Variance" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle' Relative to `lyear'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2aN_`subgp'_${vari}"	/// Figure name
		    "-0.05" "0.20" "0.05"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
		   
	tspltAREALim2 "np9050${vari} np5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle' Relative to `lyear'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2bN_`subgp'_${vari}"	/// Figure name
		     "-0.05" "0.1" "0.05"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   asd
	   }	// END of loop over subgroups
	   
}		// END of researn
*/

// PLOTS OF LOG EARN: The limints need to change for each variable; Better seperate them
	*Define the saving folder 
	global folderfile = "figs${sep}${outfolder}${sep}Inequality${sep}logearn"	
	
	foreach var in logearn {

	foreach subgp in male all fem{	
	
	*Which variable will be ploted
	global vari = "`var'"						 
	
	*What is the group under analysis? 
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_sumstat.csv", clear
		local labname = "All"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
		local labname = "Men"
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local labname = "Women"
	}
	
	*What is the label for title 
	if "${vari}" == "logearn"{
		local labtitle = "log y{sub:it}"
	}
	if "${vari}" == "researn"{
		local labtitle = "{&epsilon}{sub:it}"
	}
	if "${vari}" == "permearn"{
		local labtitle = "P{sub:it-1}"
	}
	
	*What are the x-axis limits
	if "${vari}" == "logearn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "researn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "permearn"{
		local lyear = ${yrfirst}+2
		local ryear = ${yrlast}
	}
	
	*Normalize Percentiles 
	gen var${vari} = sd${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}

	*Rescale by first year 
	foreach vv in sd$vari  var$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
		p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
		p97_5$vari p99$vari p99_9$vari p99_99$vari p9010$vari p9050${vari} p5010${vari} ksk${vari}{
		sum  `vv' if year == `lyear', meanonly
		gen n`vv' = `vv' - r(mean)
		}
	
	
	gen rece = inlist(year,${receyears})

// Figure 1 (normalized percentiles)
	tspltAREALim "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari np99$vari np99_9$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99" "p99.9" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Percentiles Relative to `lyear'" /// y axis title 
	   "Percentiles of `labtitle' for Sample: `labname'" ///  Plot title
	   "" ///
	   "fig1_`subgp'_${vari}"	/// Figure name
	   "0" "1" "0.2"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
		
	tspltAREALim "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Percentiles Relative to `lyear'" /// y axis title 
	   "Percentiles of `labtitle' for Sample: `labname'" ///  Plot title
	   "" ///
	   "fig1short_`subgp'_${vari}"	/// Figure name
	   "0" "0.6" "0.2"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
	
// Figure 2 (Inequality)
	tsplt2sc "p9010${vari}" "var${vari}" /// variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P9010" "Variance" /// Labels 
		   "" /// x axis title
		   "P90-P10 of `labtitle'" /// y axis title (left)
		   "Variance of `labtitle'" /// y axis title  (right)
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2a_`subgp'_${vari}"	// Figure name
	
	tspltAREALim2 "p9050${vari} p5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2b_`subgp'_${vari}"	/// Figure name
		    "0.5" "1.5" "0.25"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
// Figure 2 Rescale
	tspltAREALim2 "np9010${vari} nvar${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "Variance" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle' Relative to `lyear'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2aN_`subgp'_${vari}"	/// Figure name
		    "-0.05" "0.20" "0.05"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
		   
	tspltAREALim2 "np9050${vari} np5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle' Relative to `lyear'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2bN_`subgp'_${vari}"	/// Figure name
		     "-0.05" "0.1" "0.05"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
		   asd
	   }	// END of loop over subgroups
}		// END loop over variables


// PLOTS PERMEARN
	*Define the saving folder 
	global folderfile = "figs${sep}${outfolder}${sep}Inequality${sep}permearn"	

	foreach var in permearn {	
	foreach subgp in all male fem{
	
	*Which variable will be ploted
	global vari = "`var'"						 
	
	*What is the group under analysis? 
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_sumstat.csv", clear
		local labname = "All"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
		local labname = "Men"
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local labname = "Women"
	}
	
	*What is the label for title 
	if "${vari}" == "logearn"{
		local labtitle = "log y{sub:it}"
	}
	if "${vari}" == "researn"{
		local labtitle = "{&epsilon}{sub:it}"
	}
	if "${vari}" == "permearn"{
		local labtitle = "P{sub:it-1}"
	}
	
	*What are the x-axis limits
	if "${vari}" == "logearn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "researn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "permearn"{
		local lyear = ${yrfirst}+2
		local ryear = ${yrlast}
	}
	
	
	*Normalize Percentiles 
	gen var${vari} = sd${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}

	*Rescale by first year 
	foreach vv in sd$vari var$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
		p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
		p97_5$vari p99$vari p99_9$vari p99_99$vari p9010$vari p9050${vari} p5010${vari} ksk${vari}{
		sum  `vv' if year == `lyear', meanonly
		gen n`vv' = `vv' - r(mean)
		
	}
	
	
	gen rece = inlist(year,${receyears})

// Figure 1 (normalized percentiles)
	tspltAREALim "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari np99$vari np99_9$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99" "p99.9" /// Labels 
	   "2" "11" ///
	   "" /// x axis title
	    "Percentiles of `labtitle' (`lyear'=0)" /// y axis title 
	   "Percentiles of `labtitle' for Sample: `labname'" ///  Plot title
	   "" ///
	   "fig1_`subgp'_${vari}"	/// Figure name
	   "-0.2" "0.8" "0.2"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
		       
	tspltAREALim "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "" "" /// Labels 
	   "3" "11" ///
	   "" /// x axis title
	    "Percentiles of `labtitle' (`lyear'=0)" /// y axis titl
	   "Percentiles of `labtitle' for Sample: `labname'" ///  Plot title
	   "" ///
	   "fig1short_`subgp'_${vari}"	/// Figure name
	   "-.1" "0.1" "0.05"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
		
// Figure 2 (Inequality)
	tsplt2sc "p9010${vari}" "var${vari}" /// variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P9010" "Variance" /// Labels 
		   "" /// x axis title
		   "P90-P10 of `labtitle'" /// y axis title (left)
		   "Variance of `labtitle'" /// y axis title  (right)
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2a_`subgp'_${vari}"	// Figure name
	
	tspltAREALim2 "p9050${vari} p5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Percentiles of `labtitle'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2b_`subgp'_${vari}"	/// Figure name
		    "0.4" "1" "0.2"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
// Figure 2 Rescale
	tspltAREALim2 "np9010${vari} nvar${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "Variance" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle' Relative to `lyear'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2aN_`subgp'_${vari}"	/// Figure name
		    "-0.05" "0.10" "0.05"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
		   
	tspltAREALim2 "np9050${vari} np5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle' Relative to `lyear'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labname'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2bN_`subgp'_${vari}"	/// Figure name
		     "-0.05" "0.1" "0.05"			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors
	   }	// END of loop over subgroups
	   
}		// END of permearn	
	

}	// END of inequality section
***


/*---------------------------------------------------	
    This section generates the figures 3a in the
	Common Core section of the Guidelines male fem 
 ---------------------------------------------------*/
if "${figtail}" == "yes"{
foreach subgp in male fem all{
	
	local minival = 16		// sets the upper limit of the plots. 
							// Large number for all the data
	
	*Where the files are saved 
	global folderfile = "figs${sep}${outfolder}${sep}Inequality${sep}tail"
	
	*Obtain the 95th and 99th percentiles of the distribution 	 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_sumstat.csv", clear
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_male_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_male_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
	}
	
	foreach yy in 1995 2000 2005 2010 {		// Can add other years here
		sum p95logearn if year == `yy'
		local p95_`yy' = r(mean)
		
		sum p99logearn if year == `yy'
		local p99_`yy' = r(mean)
		
		sum p99_99logearn if year == `yy'
		local minival_`yy' = r(mean)
		
	}
	
	*Plot the log-densities
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_hist.csv", clear
		local labname = "All"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_hist_male.csv", clear
		keep if male == 1	// Keep the group we want to plot 
		local labname = "Men"
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_hist_male.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local labname = "Women"
	}
	

	foreach yy in  1995 2000 2005 2010 {		// Can add other years here
	
	gen lden_logearn`yy' = log(den_logearn`yy')
	
	*First cutoff: 5% 
	* Notice the slope is calculated with all data by the plot cuts the very top. 
	*reg lden_logearn`yy' val_logearn`yy' if val_logearn`yy' >=  `p95_`yy''
	reg lden_logearn`yy' val_logearn`yy' if val_logearn`yy' >=  `p95_`yy'' & val_logearn`yy' <= `minival_`yy''
	predict lden_logearn`yy'_hat1 if e(sample) == 1, xb 
	global slope : di %4.2f _b[val_logearn`yy']
	
	
	//NOTE: CREATE HERE THE SHARES FROM DENSITY AND INVERSE CDF
	
	preserve 
	keep if val_logearn`yy' >=  `p95_`yy''
	keep if val_logearn`yy' <= `minival_`yy''	// This is 300k in dollars. 
											// Check this with Serdar we might need to add some noise here
	
	dnplot "lden_logearn`yy' lden_logearn`yy'_hat1" "val_logearn`yy'" /// y and x variables 
			"log y{sub:it}" "log-Density" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Log Density of log y{sub:it} at top 5% in `yy'" "Sample: `labname' - Slope: ${slope}" "large" ""  ///	Plot title
			 "" "" "" "" "" ""						/// Legends
			 "off" "11"	"2"									/// Leave empty for active legend
			"fig3a_pareto95_`subgp'_lden_logearn`yy'"			// Name of file
			
	restore 
	
	
	*Second cutoff: 1% 
	*reg lden_logearn`yy' val_logearn`yy' if val_logearn`yy' >=  `p99_`yy'' 
	reg lden_logearn`yy' val_logearn`yy' if val_logearn`yy' >=  `p99_`yy'' & val_logearn`yy'  <= `minival_`yy''
	predict lden_logearn`yy'_hat2 if e(sample) == 1, xb 
	global slope : di %4.2f _b[val_logearn`yy']
	
	
	preserve 
	keep if val_logearn`yy' >=  `p99_`yy''
	keep if val_logearn`yy' <= `minival_`yy''		// This is 300k in dollars. Check this with Serdar 
	dnplot "lden_logearn`yy' lden_logearn`yy'_hat2" "val_logearn`yy'" /// y and x variables 
			"log y{sub:it}" "log-Density" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Log Density of log y{sub:it} at top 1% in `yy'" "Sample: `labname' - Slope: ${slope}" "large" ""  ///	Plot title
			 "" "" "" "" "" ""						/// Legends
			 "off" "11"	"2"							/// Leave empty for active legend
			"fig3a_pareto99_`subgp'_lden_logearn`yy'"			// Name of file	
	restore 
	
	}	// END loop over years
	
}	// END loop over sub groups
}
***

/*---------------------------------------------------	
    This section generates the figures 3b in the
	Common Core section of the Guidelines
 ---------------------------------------------------*/	
if "${figcon}" == "yes"{ 
	*Folder to save figures 
	global folderfile = "figs${sep}${outfolder}${sep}Concentration"	
	
	*Load data 
	insheet using  "out${sep}${ineqdata}${sep}L_earn_con.csv", clear
	
	
	*Normalizing data to value in ${normyear}
	local lyear = ${normyear}	// Normalization year
	foreach vv in q1share q2share q3share q4share q5share ///
				  top10share top5share top1share top05share top01share top001share ///
				  bot50share{
		
		sum  `vv' if year == `lyear', meanonly
		gen n`vv' = `vv' - r(mean)
		
		}
		
	*What years 
	local rlast = ${yrlast} - 1
	
	*Recession bars 
	gen rece = inlist(year,${receyears})


	*Quintiles
	tspltAREALim "q1share q2share q3share q4share q5share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Q1" "Q2" "Q3" "Q4" "Q5" "" "" "" "" /// Labels 
		    "5" "7" ///
		   "" /// x axis title
		   "Income Shares (%)" /// y axis title 
		   "Income Shares of y{sub:it} by Quintiles" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_quintile"	/// Figure name
		   "" "" ""				/// ylimits
			"" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors
	
	tspltAREALim "nq1share nq2share nq3share nq4share nq5share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Q1" "Q2" "Q3" "Q4" "Q5" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Income Shares (%  `lyear' = 0)" /// y axis title 
		   "Rescaled Income Shares of y{sub:it} by Quintiles" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_nquintile"	/// Figure name
		   "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
	       "green black maroon red navy blue forest_green purple gray orange"			// Colors
		   
	*Bottom 50%
	tspltAREALim2 "bot50share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Bottom 50" "" "" "" "" "" "" "" "" /// Labels 
		    "1" "7" ///
		   "" /// x axis title
		   "Income Shares (%)" /// y axis title 
		   "Income Shares of y{sub:it} of Bottom 50%" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_bottom50"	/// Figure name
		    "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
	tspltAREALim2 "nbot50share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Bottom 50" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "7" ///
		   "" /// x axis title
		    "Income Shares (%  `lyear' = 0)" /// y axis title 
		   "Rescaled Income Shares of y{sub:it} of Bottom 50%" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_nbottom50"	/// Figure name
		    "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
	*Top shares
	tspltAREALim "top10share top5share top1share top05share top01share top001share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Top 10%" "Top 5%" "Top 1%" "Top 0.5%" "Top 0.1%" "Top 0.01%" "" "" "" /// Labels 
		   "6" "11" ///
		   "" /// x axis title
		   "Income Shares (%)" /// y axis title 
		   "Income Shares of y{sub:it} by Top Income Earnears" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_topshares"	/// Figure name
		   "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
	       "green black maroon red navy blue forest_green purple gray orange"			// Colors
		   
	tspltAREALim "ntop10share ntop5share ntop1share ntop05share ntop01share ntop001share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Top 10%" "Top 5%" "Top 1%" "Top 0.5%" "Top 0.1%" "Top 0.01%" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		    "Income Shares (%  `lyear' = 0)" /// y axis title 
		   "Rescaled  Income Shares of y{sub:it} by Top Income Earners" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_ntopshares"	/// Figure name
		   "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
	       "green black maroon red navy blue forest_green purple gray orange"			// Colors
		   
		   
	*Gini
	tspltAREALim2 "gini" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Gini" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Gini Coefficient" /// y axis title 
		   "Gini Coefficient of y{sub:it}" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_gini"	/// Figure name
		    "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
		   "blue red"			// Colors
}
***

/*---------------------------------------------------	
    This section generates the figures 4 to 7 
 ---------------------------------------------------*/
if "${figvol}" == "yes"{  

*Where the figures are going to be saved 
	global folderfile = "figs${sep}${outfolder}${sep}Volatility${sep}densities"	 

*Densities 
	
// 	local yy = 1995	
// // 	local vari = "researn5F"
// 	foreach sam in men women all {
// 	foreach yy in 1995 2000 2005{
// 	foreach vari in researn1F researn5F  {
	
// 		*Labels 
// 		if "`vari'" == "researn1F"{
// 			local labtitle = "{&Delta}{sup:1}{&epsilon}{sub:it}"
// 		}
// 		if "`vari'" == "researn5F"{
// 			local labtitle = "{&Delta}{sup:5}{&epsilon}{sub:it}"
// 		}
	
// 		*Data
// 		if "`sam'" == "all"{
// 			insheet using "out${sep}${voladata}${sep}L_`vari'_sumstat.csv", case clear
			
// 			sum sd`vari' if year == `yy'
// 			global sd = r(mean) 
// 			global sdplot: di %4.2f  ${sd}
			
// 			insheet using "out${sep}${voladata}${sep}L_`vari'_hist.csv", case clear
// 			local labtitle2 = "(All Sample)"
// 		}
// 		else if "`sam'" == "men"{
// 			insheet using "out${sep}${voladata}${sep}L_`vari'_male_sumstat.csv", case clear
			
// 			sum sd`vari' if year == `yy' & male == 1
// 			global sd = r(mean) 
// 			global sdplot: di %4.2f  ${sd}
			
			
// 			insheet using "out${sep}${voladata}${sep}L_`vari'_hist_male.csv", case clear
// 			keep if male == 1
// 			local labtitle2 = "(Men Only)"
// 		}
// 		else if "`sam'" == "women"{
// 			insheet using "out${sep}${voladata}${sep}L_`vari'_male_sumstat.csv", case clear
			
// 			sum sd`vari' if year == `yy' & male == 0
// 			global sd = r(mean) 
// 			global sdplot: di %4.2f  ${sd}
			
// 			insheet using "out${sep}${voladata}${sep}L_`vari'_hist_male.csv", case clear
// 			keep if male == 0
// 			local labtitle2 = "(Women Only)"
// 		}
		
		
// 		*Log densities 
// 		gen lden_`vari'`yy' = log(den_`vari'`yy')
// 		gen lnden_`vari'`yy' = log(normalden(val_`vari'`yy',0,${sd}))
		
// 		*Slopes
// 		reg lden_`vari'`yy' val_`vari'`yy' if val_`vari'`yy' < -1 & val_`vari'`yy' > -4
// 		global blefttail: di %4.2f _b[val_`vari'`yy']
// 		predict lefttail if e(sample), xb 
		
// 		reg lden_`vari'`yy' val_`vari'`yy' if val_`vari'`yy' > 1 & val_`vari'`yy' < 4
// 		global brighttail: di %4.2f _b[val_`vari'`yy']
// 		predict righttail if e(sample), xb 
		
// 		*Trimming for plots
// 		replace lnden_`vari'`yy' = . if val_`vari'`yy' < -2
// 		replace lnden_`vari'`yy' = . if val_`vari'`yy' > 2
		
// 		replace lden_`vari'`yy' = . if val_`vari'`yy' < -4
// 		replace lden_`vari'`yy' = . if val_`vari'`yy' > 4
		
// 		replace lefttail = . if val_`vari'`yy' < -4
// 		replace lden_`vari'`yy' = . if val_`vari'`yy' > 4
		
// 		replace righttail = . if val_`vari'`yy' > 4
// 		replace lden_`vari'`yy' = . if val_`vari'`yy' > 4
		
		
// 		logdnplot "lden_`vari'`yy' lnden_`vari'`yy' lefttail righttail" "val_`vari'`yy'" /// y and x variables 
// 				"`labtitle'" "Log-Density" "medium" "medium" 		/// x and y axcis titles and sizes 
// 				 "Log Density of `labtitle' in `yy' `labtitle2'" "" "large" ""  ///	Plot title
// 				 "Data" "N(0,${sdplot}{sup:2})" "Left Slope: ${blefttail}" "Right Slope: ${brighttail}" "" ""						/// Legends
// 				 "on" "11"	"1"							/// Leave empty for active legend
// 				 "-4" "4" "1" "-10" "2" "2"				/// Set limits of x and y axis 
// 				 "lden_`vari'`yy'"					/// Set what variable defines the y-axis
// 				"fig13_lden_`vari'_`sam'_`yy'"			// Name of file
				
	
// 	}	// END loop over variables	
// 	}	// END loop over years 
// 	}	// END loop over samples
	
*Time series 
*Time series 
foreach var in researn1F researn5F  arcearn1F arcearn5F {				
	foreach subgp in all male fem{
	
	*Which variable will be ploted
	global vari = "`var'"						 
	
	*What is the group under analysis? 
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${voladata}${sep}L_`var'_sumstat.csv", case clear
		local labtitle2 = "All"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${voladata}${sep}L_`var'_male_sumstat.csv", case clear
		keep if male == 1	// Keep the group we want to plot 
		local labtitle2 = "Men"
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${voladata}${sep}L_`var'_male_sumstat.csv", case clear
		keep if male == 0	// Keep the group we want to plot 
		local labtitle2 = "Women"
	}
	
	*What are the recession years
	gen rece = inlist(year,${receyears})
	
	
	*What is the label for title 
	if "${vari}" == "researn1F"{
		local labtitle = "{&Delta}{sup:1}{&epsilon}{sub:it}"
		global folderfile = "figs${sep}${outfolder}${sep}Volatility${sep}researn1F"	
	}
	if "${vari}" == "arcearn1F"{
		local labtitle = "{&Delta}{sup:1}dhs{sub:it}"
		global folderfile = "figs${sep}${outfolder}${sep}Volatility${sep}arcearn1F"	
	}
	if "${vari}" == "researn5F"{
		local labtitle = "{&Delta}{sup:5}{&epsilon}{sub:it}"
		global folderfile = "figs${sep}${outfolder}${sep}Volatility${sep}researn5F"	
	}
	if "${vari}" == "arcearn5F"{
		local labtitle = "{&Delta}{sup:5}dhs{sub:it}"
		global folderfile = "figs${sep}${outfolder}${sep}Volatility${sep}arcearn5F"	
	}
	
	
	*What are the x-axis limits
	if "${vari}" == "researn1F"  | "${vari}" == "arcearn1F"  {
		local lyear = ${yrlast}-1		
		local ljum = 0
		local fyear = ${yrfirst} + `ljum'
		local nyear = ${normyear}
	}
	if "${vari}" == "researn5F" | "${vari}" == "arcearn5F"{
		local lyear = ${yrlast} - 5
		local ljum = 2		// So plot is centered in year 3
		local fyear = ${yrfirst} + `ljum'
		local nyear = ${normyear}
	}

	*Normalize Percentiles 
	gen var${vari} = sd${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen p7525${vari} = p75${vari} - p25${vari}
	
	gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}
	gen cku${vari} = (p97_5${vari} - p2_5${vari})/p7525${vari}
	
	
	*Rescale by first year 
	foreach vv in sd$vari var${vari} p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
		p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
		p97_5$vari p99$vari p99_9$vari p99_99$vari ///
		p9010${vari} p9050${vari} p5010${vari} p7525${vari} ksk${vari} {
		sum  `vv' if year == `nyear', meanonly
		qui: gen n`vv' = `vv' - r(mean)
		
	}
	
	tsset year
// Figure 4	
	tspltEX "L`ljum'.p5$vari L`ljum'.p10$vari L`ljum'.p25$vari L`ljum'.p50$vari L`ljum'.p75$vari L`ljum'.p90$vari L`ljum'.p95$vari L`ljum'.p99$vari L`ljum'.p99_9$vari" /// Which variables?
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99" "p99.9" /// Labels 
		   "" /// x axis title
		   "Percentiles of `labtitle'" /// y axis title 
		   "Percentiles of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig4a_`subgp'_${vari}"	/// Figure name
		   "green black maroon red navy blue forest_green purple gray orange"
		    
	tspltAREALim "L`ljum'.np5$vari L`ljum'.np10$vari L`ljum'.np25$vari L`ljum'.np50$vari L`ljum'.np75$vari L`ljum'.np90$vari L`ljum'.np95$vari L`ljum'.np99$vari L`ljum'.np99_9$vari" /// Which variables?
	   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99" "p99.9" /// Labels 
	   "3" "11" ///
	   "" /// x axis title
	    "Percentiles of `labtitle' relative to ${yrfirst}" /// y axis title 
	   "Percentiles of `labtitle' for Sample: `labtitle2'" ///  Plot title
	   "" ///
	   "fig4a_`subgp'_n${vari}"	/// Figure name
	   "-0.3" "0.3" "0.2"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors	   
		    
	tspltEX "L`ljum'.p5$vari L`ljum'.p10$vari L`ljum'.p25$vari L`ljum'.p50$vari L`ljum'.p75$vari L`ljum'.p90$vari L`ljum'.p95$vari" /// Which variables?
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "" "" /// Labels 
		   "" /// x axis title
		   "Percentiles of `labtitle'" /// y axis title 
		   "Percentiles of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig4ashort_`subgp'_${vari}"	/// Figure name
		   "green black maroon red navy blue forest_green purple gray orange" 
		 
	tspltAREALim "L`ljum'.np5$vari L`ljum'.np10$vari L`ljum'.np25$vari L`ljum'.np50$vari L`ljum'.np75$vari L`ljum'.np90$vari L`ljum'.np95$vari" /// Which variables?
	   "year" ///
		`fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "" ""  /// Labels 
	   "3" "11" ///
	   "" /// x axis title
	   "Percentiles of `labtitle' Relative to ${yrfirst}" /// y axis title 
	   "Percentiles of `labtitle' for Sample: `labtitle2'" ///  Plot title
	   "" ///
	   "fig4ashort_`subgp'_n${vari}"	/// Figure name
	   "-0.3" "0.3" "0.2"				/// ylimits
	   "" 						/// If legend is active or nor	
	    "green black maroon red navy blue forest_green purple gray orange"			// Colors	   
		   
// Figure 5	   
	tspltAREALim2 "L`ljum'.p9010${vari}" ///  variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "P90-P10 of `labtitle'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig5a_`subgp'_${vari}"	/// Figure name
		    "" "" ""			/// ylimits
			"off" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
	tsplt2sc "L`ljum'.p9010${vari}" "L`ljum'.var${vari}" /// variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P10" "Variance" /// Labels 
		   "" /// x axis title
		   "P90-P10 of `labtitle'" /// y axis title (left)
		   "Variance of `labtitle'" /// y axis title  (right)
		   "Measures of Dispersion of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig5a_`subgp'_${vari}COMPARE"	// Figure name
		   
	
	tspltAREALim2 "L`ljum'.p9050${vari} L`ljum'.p5010${vari}" ///  variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle'" /// y axis title 
		   "Measures of Dispersion of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig5b_`subgp'_${vari}"	/// Figure name
		    "" "" ""			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors	   
		   
// Figure 6
	tspltAREALim2 "L`ljum'.ksk${vari}" ///  variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Kelley Skewness" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Kelley Skewness of `labtitle'" /// y axis title 
		   "Skewness of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig6ksk_`subgp'_${vari}"	/// Figure name
		   "" "" ""			/// ylimits
			"" 						/// If legend is active or nor	
		   "blue red"			// Colors	
		   
	tspltAREALim2 "L`ljum'.skew${vari}" ///  variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Coef. of Skewness" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Skewness of `labtitle'" /// y axis title 
		   "Skewness of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig6skew_`subgp'_${vari}"	/// Figure name
		   "" "" ""			/// ylimits
		   "" 						/// If legend is active or nor	
		   "blue red"			// Colors	
		   
	tsplt2sc "L`ljum'.ksk${vari}" "L`ljum'.skew${vari}" /// variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Kelley Skewness" "Coef. of Skewness" /// Labels 
		   "" /// x axis title
		   "Kelley Skewness of `labtitle'" /// y axis title (left)
		   "Coef. of Skewness of `labtitle'" /// y axis title  (right)
		   "Measures of Skewness of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig6_`subgp'_${vari}"	// Figure name  
		   
// Figure 7 
	tspltAREALim2 "L`ljum'.cku${vari}" ///  variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Crow-Siddiqui" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Crow-Siddiqui of `labtitle'" /// y axis title 
		   "Kurtosis of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig7cku_`subgp'_${vari}"	/// Figure name
		   "" "" ""			/// ylimits
		   "off" 						/// If legend is active or nor	
		   "blue red"			// Colors	
		   
		   
		   
	tspltAREALim2  "L`ljum'.kurt${vari}" ///  variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Coef. of Kurtosis" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Coef. of Kurtosis of `labtitle'" /// y axis title 
		   "Kurtosis of `labtitle' for Sample: `labtitle2'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig7ku_`subgp'_${vari}"	/// Figure name
		   "" "" ""			/// ylimits
		   "off" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
		   
	tsplt2sc "L`ljum'.cku${vari}" "L`ljum'.kurt${vari}" /// variables plotted
		   "year" ///
		   `fyear' `lyear' 2 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Crow-Siddiqui Kurtosis" "Coef. of Kurtosis" /// Labels 
		   "" /// x axis title
		   "Crow-Siddiqui Kurtosis of `labtitle'" /// y axis title (left)
		   "Coef. of Kurtosis of `labtitle'" /// y axis title  (right)
		   "Measures of Kurtosis of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig7_`subgp'_${vari}"	// Figure name 
		   
	   }	// END of loop over subgroups
}	// END loop over variables


}
***

/*---------------------------------------------------	
    This section generates the figures 8a in the
	Common Core section of the Guidelines
 ---------------------------------------------------*/	
if "${figquan}" == "yes"{  
 
foreach var in researn5F researn1F  {	
	*Which variable will be ploted
	global vari = "`var'"
	
	*What is the label for title 
	if "${vari}" == "researn1F"{
		local labtitle = "g{sub:it}"
		global folderfile = "figs${sep}${outfolder}${sep}Quantiles${sep}researn1F"
	}
	if "${vari}" == "researn5F"{
		local labtitle = "g{sub:it}{sup:5}"
		global folderfile = "figs${sep}${outfolder}${sep}Quantiles${sep}researn5F"			
	}
 
	*Load the data 
	insheet using "out${sep}${voladata}${sep}L_`var'_agerank.csv", clear case
	
	*Calculate additional moments 
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen p7525${vari} = p75${vari} - p25${vari}
	gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}
	gen cku${vari} = (p97_5${vari} - p2_5${vari})/p7525${vari}
	
	*Averagegin statistics over time 
	*This can be changed to seperate recession to expansion periods
	collapse  p9010${vari}  sd${vari} ksk${vari} skew${vari} cku${vari} kurt${vari}, by(agegp permrank)
	
	*Reshape to have a cleaner plot 
	reshape wide p9010${vari}  sd${vari} ksk${vari} skew${vari} cku${vari} kurt${vari}, i(permrank) j(agegp)
	
	replace permrank = permrank - 1	// Just to have better plot starting from 0
	replace permrank = 2.5*permrank
	
	
	*Ploting
	dnplot "p9010${vari}1 p9010${vari}2 p9010${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "P90-P10 of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Dispersion of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""	"2" "1"				/// Leave empty for active legend; 2 for position
			"fig8a_${vari}"			// Name of file

	dnplot "sd${vari}1 sd${vari}2 sd${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Standard Deviation of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Standard Deviation of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""	"2"	"1"								/// Leave empty for active legend
			"fig8b_${vari}"			// Name of file

	dnplot "ksk${vari}1 ksk${vari}2 ksk${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Kelley Skewness of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Kelley Skewness of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""	"2"	"1"								/// Leave empty for active legend
			"fig9a_${vari}"			// Name of file

	dnplot "skew${vari}1 skew${vari}2 skew${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Coef. of Skewness of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Coef. of Skewness of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""	"2"	"1"								/// Leave empty for active legend
			"fig9b_${vari}"			// Name of file

	dnplot "cku${vari}1 cku${vari}2 cku${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Crow-Siddiqui of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Crow-Siddiqui of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""	"5"	"1"								/// Leave empty for active legend
			"fig10a_${vari}"			// Name of file

	dnplot "kurt${vari}1 kurt${vari}2 kurt${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Coef. of Kurtosis of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Coef. of Kurtosis of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""	"11" "1"								/// Leave empty for active legend
			"fig10b_${vari}"			// Name of file	
}
}
***		
	
/*----------------------------------------------
	This section generates figure 11: Mobility
------------------------------------------------*/
if "${figmob}" == "yes"{ 
// Figure 11A
foreach yr in 1995 2005{		// Add years here if you need
	
	*What is the folder to save files 
	global folderfile = "figs${sep}${outfolder}${sep}Mobility"
	
	*Load data of short term mobility
	insheet using "out${sep}${mobidata}${sep}L_ranktp1_mobstat.csv", clear
	keep if year == `yr'
		
	dnplot "meanranktp1 rankt" "rankt" /// y and x variables 
			"Rank of {&epsilon}{sub:t} in year t" ///
			"Mean Rank of {&epsilon}{sub:t} in year t+1" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Short-Term Mobility in Year: `yr'" "" "large" ""  ///	Plot title
			 "" "" "" "" "" ""						/// Legends
			 "off"	"2" "1"									/// Leave empty for active legend
			"fig11a_`yr'_mobility"			// Name of file
			
	
	*Load data of long term mobility
	insheet using "out${sep}${mobidata}${sep}L_ranktp5_mobstat.csv", clear
	keep if year == `yr'
	
	dnplot "meanranktp5 rankt" "rankt" /// y and x variables 
	"Rank of {&epsilon}{sub:t} in year t" ///
	"Mean Rank of {&epsilon}{sub:t} in year t+5" "medium" "medium" 		/// x and y axcis titles and sizes 
	 "Long-Term Mobility in Year: `yr'" "" "large" ""  ///	Plot title
	 "" "" "" "" "" ""						/// Legends
	 "off"	"2" "1"										/// Leave empty for active legend
	"fig11b_`yr'_mobility"			// Name of file		
	
}

// Figure 11B
foreach yr in 2000 1995 {	// Add more years here if you need

	*Load data of short term mobility
	insheet using "out${sep}${mobidata}${sep}L_permearnalt_mobstat.csv", clear
	keep if year == `yr'
	replace permearnaltrankt = 2.5*permearnaltrankt
	replace meanpermearnaltranktp5 = 2.5*meanpermearnaltranktp5
	replace meanpermearnaltranktp10 = 2.5*meanpermearnaltranktp10
	replace meanpermearnaltranktl3 = 2.5*meanpermearnaltranktl3
		
	dnplot "meanpermearnaltranktp5 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year t+5" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility Year: `yr'" "" "large" ""  ///	Plot title
			"" "" "" "" "" ""						/// Legends
			 "off"	"2" "1"											/// Leave empty for active legend
			"fig11b_`yr'_tp5_mobility"			// Name of file
 
	dnplot "meanpermearnaltranktp10 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year t+10" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility Year: `yr'" "" "large" ""  ///	Plot title
			"" "" "" "" "" ""						/// Legends
			"off"	"2" "1"									/// Leave empty for active legend
			"fig11b_`yr'_tp10_mobility"			// Name of file
 
	dnplot "meanpermearnaltranktl3 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year T{sup:Max}-3" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility Year: `yr'" "" "large" ""  ///	Plot title
			"" "" "" "" "" ""						/// Legends
			"off"	"2" "1"										/// Leave empty for active legend
			"fig11b_`yr'_tl3_mobility"			// Name of file
			
	*Load data of short term mobility by age group
	insheet using "out${sep}${mobidata}${sep}L_agegppermearnalt_mobstat.csv", clear
	keep if year == `yr'
	
	keep meanpermearnaltranktp5  permearnaltrankt agegp
	
	reshape wide meanpermearnaltranktp5 , i(permearnaltrankt) j(agegp)
	
	dnplot "meanpermearnaltranktp51 meanpermearnaltranktp52 meanpermearnaltranktp53 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year t+5" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility by Age in Year: `yr'" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "45 line" "" ""						/// Legends
			 "on"	"11" "1"											/// Leave empty for active legend
			"fig11b_`yr'_age_tp5_mobility"			// Name of file
	
}
}
****	
	
/*----------------------------------------
	This section generates figure 12 & 14
------------------------------------------*/
if "${figcoh}" == "yes"{ 

	*What is the folder to save plot?
	global folderfile = "figs${sep}${outfolder}${sep}Cohorts"	
	

foreach var in logearn{	// Add here other variables 
	foreach subgp in fem male all {			// Add here other groups 
				
				
// Plots by cohorts (as in Guvenen, Kaplan, Song, and Weidner, 2018)	
			
	*Which variable is under analysis? 
	*The code generates for raw earnimgs and residuals earnigs
	global vari = "`var'"		
	
	*Label for plots
	local labtitle = "log y{sub:it}"
								
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_age_sumstat.csv", clear
		local tlocal = "All Sample"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_maleage_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
		local tlocal = "Men"
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_maleage_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local tlocal = "Women"
	}
	
	*Calculate additional moments 
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}

	*Gen cohort that is the age at which cohort was 25 years old 
	gen cohort25 = year - age + 25
	order year age cohort25
	
	gkswplot "p50`var'" "year" ///
			 "1993 1995 2000 2005 2010" /// what cohorts?
			 "25 30 35" /// What ages: code allows three
			 "${yrfirst}" "${yrlast}" "5" /// x-axis
			 "on" "11" "1" "Age 25" "Age 30" "Age 35" /// Legends
			 "Year" "50th percentile of Log Real Earnigs"  /// x and y titles 
			 "Age Profiles of Median Earnings for `tlocal'" "large" "" "" ///
			 "fig14_gksw_p50logearn_`subgp'"
		
	gkswplot "p10`var'" "year" ///
			 "1993 1995 2000 2005 2010" /// what cohorts?
			 "25 30 35" /// What ages: code allows three
			 "${yrfirst}" "${yrlast}" "5" /// x-axis
			 "on" "11" "1" "Age 25" "Age 30" "Age 35" /// Legends
			 "Year" "10th percentile of Log Real Earnigs"  /// x and y titles 
			 "Age Profiles of 10th percentile Earnings for `tlocal'" "large" "" "" ///
			 "fig14_gksw_p10`var'_`subgp'"			 
		
	gkswplot "p90`var'" "year" ///
			 "1993 1995 2000 2005 2010" /// what cohorts?
			 "25 30 35" /// What ages: code allows three
			 "${yrfirst}" "${yrlast}" "5" /// x-axis
			 "on" "11" "1" "Age 25" "Age 30" "Age 35" /// Legends
			 "Year" "90th percentile of Log Real Earnigs"  /// x and y titles 
			 "Age Profiles of 90th percentile Earnings `tlocal'" "large" "" "" ///
			 "fig14_gksw_p90`var'_`subgp'"	
			 
	gkswplot "p9010`var'" "year" ///
			 "1993 1995 2000 2005 2010" /// what cohorts?
			 "25 30 35" /// What ages: code allows three
			 "${yrfirst}" "${yrlast}" "5" /// x-axis
			 "on" "7" "1" "Age 25" "Age 30" "Age 35" /// Legends
			 "Year" "90th-to-10th percentiles differential of Log Real Earnigs"  /// x and y titles 
			 "Age Profiles of Dispersion of Earnings for `tlocal'" "large" "" "" ///
			 "fig14_gksw_p9010`var'_`subgp'"
			 
// Plots at the age of entry

	foreach ageval in 25 30 35{
	preserve
		*Keep only the sub sample at the age of age val 
	// 	local ageval = 25		// Choose here which age will be ploted
		keep if age == `ageval'
		
		*Rescale by first year 
		foreach vv in sd$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
			p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
			p97_5$vari p99$vari p99_9$vari p99_99$vari{
			
			sum  `vv' if year == ${yrfirst}, meanonly
			gen n`vv' = `vv' - r(mean)
			
			}
		*Recessions bars 
		gen rece = inlist(year,${receyears})

		*What is the last year in the x axis 
		local rlast = ${yrlast}-1

	// 	*Plots
		
	// Percentiles
		tspltAREALim "p10${vari} p25${vari} p50${vari} p75${vari} p90${vari} p95${vari} p99${vari}" /// Which variables?
			   "year" ///
			   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
			   "p10" "p25" "p50" "p75" "p90" "p95" "p99" "" "" /// Labels 
			   "4" "7" ///
			   "Workers at Age `ageval'" /// x axis title
			   "Percentiles of `labtitle'" /// y axis title 
			   "Percentiles of `labtitle' in Sample: `subgp'" ///  Plot title
			   ""  /// 	 Plot subtitle  
			   "fig12a_`subgp'_`ageval'_${vari}"	/// Figure name
			   "" "" ""				/// ylimits
				"" 						/// If legend is active or nor	
				"black maroon red navy blue forest_green purple gray orange green"			// Colors
			   
		tspltAREALim "np10${vari} np25${vari} np50${vari} np75${vari} np90${vari} np95${vari} np99${vari}" /// Which variables?
			   "year" ///
				${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
			   "p10" "p25" "p50" "p75" "p90" "p95" "p99" "" "" /// Labels 
			   "2" "11" ///
			   "Workers at Age `ageval'" /// x axis title
			   "Percentiles of `labtitle'" /// y axis title 
			   "Percentiles of `labtitle' for Sample: `subgp'" ///  Plot title
			   ""  /// 	 Plot subtitle  
			   "fig12a_`subgp'_`ageval'_n${vari}"	/// Figure name
			   "" "" ""				/// ylimits
				"" 						/// If legend is active or nor	
				"black maroon red navy blue forest_green purple gray orange green"			// Colors
			
			
	// P9010 
		tspltAREALim2 "p9010${vari}" /// Which variables?
			   "year" ///
				${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
			   "P90-P10" "" "" "" "" "" "" "" "" /// Labels 
			   "2" "11" ///
			   "Workers at age `ageval'" /// x axis title
			   "P90-P10 of `labtitle'" /// y axis title 
			   "Inequality of `labtitle' for Sample: `subgp'" ///  Plot title
			   ""  /// 	 Plot subtitle  
			   "fig12b_`subgp'_`ageval'_${vari}"	/// Figure name
				"" "" ""			/// ylimits
				"" 						/// If legend is active or nor	
			   "blue red"			// Colors	  
		   
	// P9050 
		tspltAREALim2  "p9050${vari}" /// Which variables?
			   "year" ///
			   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
			   "P90-P50" "" "" "" "" "" "" "" "" /// Labels 
				"2" "11" ///
			   "Workers at age `ageval'" /// x axis title
			   "P90-P50 of `labtitle'" /// y axis title 
			   "Right-Tail Inequality of `labtitle' for Sample: `subgp'" ///  Plot title
			   ""  /// 	 Plot subtitle  
			   "fig12c_`subgp'_`ageval'_${vari}"	/// Figure name
				"" "" ""			/// ylimits
				"" 						/// If legend is active or nor	
			   "blue red"			// Colors	  
		   
	// P5010
		tspltAREALim2 "p5010${vari}" /// Which variables?
			   "year" ///
			   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
			   "P50-P10" "" "" "" "" "" "" "" "" /// Labels 
				"2" "11" ///
			   "Workers at age `ageval'" /// x axis title
			   "P50-P10 of `labtitle'" /// y axis title 
			   "Left-Tail Inequality of `labtitle' for Sample: `subgp'" ///  Plot title
			   ""  /// 	 Plot subtitle  
			   "fig12d_`subgp'_`ageval'_${vari}"	/// Figure name
				"" "" ""			/// ylimits
				"" 						/// If legend is active or nor	
			   "blue red"			// Colors	 
	restore
	} // END of loop over age val
		   
		   
}	// END loop subgroups
}	// END loop over variables 
}


***

*END OF THE CODE
