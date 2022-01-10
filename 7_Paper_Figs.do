// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the core figures for the draft
// This version January 10, 2022
// Serdar Ozkan and Sergio Salgado
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off

global maindir ="..."

// Where the data is stored
global ineqdata = "..."			// Data on Inequality 
global voladata = "..."			// Data on Volatility
global mobidata = "..."							// Data on Mobility

// Where the firgures are going to be saved 
global outfolder="..."			
capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}"

// Read initialize and plotting code. Do not change myplots.do
do "$maindir/do/0_Initialize.do"
do "$maindir${sep}do${sep}myplots.do"		

// Define these variables for your dataset
global yrfirst = 1993 					// First year in the dataset 
global yrlast =  2017 					// Last year in the dataset	

/* Following the guidelines 
	Our suggestion is set  Tmax to the maximum length available (i.e., 24 years for Brazil, 34 years for Canada, etc.). As for Tcommon, we recommend  Tcommon=min{Tmax, 20}, going backward from the last year for which data are currently available (hence for Brazil is 1998-2017, for Canada 1997-2016, etc., while for Mexico would be 2005-2014).
*/
global Tcommon = ${yrlast} - 20 + 1	



// Define some common charactristics of the plots 
	global xtitlesize =   "large" 
	global ytitlesize =   "large" 
	global xlabsize =     "large" 
	global ylabsize =     "large" 
	global titlesize  =   "large" 
	global subtitlesize = "medium" 
	global formatfile  =  "pdf"
	global fontface   =   "Times New Roman"
	global marksize =     "medium"	
	global legesize =     "large"	
	
// Where the figs are going to be saved
	capture noisily mkdir "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"
	   
// Cd to folder with out 
	cd "$maindir${sep}" // Cd to the folder containing the files
	
// Which section are we ploting 
	global figineq =  "yes"			// Inequality
	global figcoh =   "yes"			// Cohorts and initial inequality
	global figvol =   "yes"			// Volatility
	global figquan =  "yes"			// Income growth heterogeneity 
	global figmob =   "yes"			// Mobility
	global figtail =  "yes"			// Tail 
	global figcon =   "yes"			// Concentration 
	global figden =   "yes"			// Density Plots

/*---------------------------------------------------	
    Inequality
 ---------------------------------------------------*/
if "${figineq}" == "yes"{ 	

// PLOTS OF LOG EARN: The limints need to change for each variable; Better seperate them
	*Define the saving folder 
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
	
	foreach subgp in fem male all{	
	
	*For residual-education earnings we are only ploting the aggregated results
	if 	"`subgp'" == "all"{
		local wlist = "logearn researne researn"			
	}	
	else {
		local wlist = "logearn researn"	
	}
	
	*Start main loop over variables
	foreach var of local wlist{
	
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
		local labtitle = "Log Earnings"
// 		local labtitle = "log y{sub:it}"
	}
	if "${vari}" == "researn" | "${vari}" == "researne"{
		local labtitle = "Residual Log Earnings"
// 		local labtitle = "{&epsilon}{sub:it}"
	}

	
	*What are the x-axis limits
	if "${vari}" == "logearn"{
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}
	if "${vari}" == "researn" | "${vari}" == "researne" {
		local lyear = ${yrfirst}
		local ryear = ${yrlast}
	}

	
	*Normalize Percentiles 
	gen var${vari} = sd${vari}^2
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9901${vari} = p99${vari} - p1${vari}
	gen p99901${vari} = p99_9${vari} - p1${vari}
	gen p999901${vari} = p99_99${vari} - p1${vari}
	
	gen p9990${vari} = p99${vari} - p90${vari}
	gen p999_p99${vari} = p99_9${vari} - p99${vari}
	gen p9999_p999${vari} = p99_99${vari} - p99_9${vari}
	
	
	gen p9505${vari} = p95${vari} - p5${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}

	*Rescale by first year 
	foreach vv in sd$vari  var$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
		p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
		p97_5$vari p99$vari p99_9$vari p99_99$vari p9010$vari  p9901$vari  p9505$vari p9050${vari} p5010${vari} ksk${vari} ///
		p99901${vari} p999901${vari} p9990${vari} p999_p99${vari} p9999_p999${vari}{
		sum  `vv' if year == `lyear', meanonly
		gen n`vv' = `vv' - r(mean)
		}
	
	*Generate recession vars
	gen rece = inlist(year,${receyears})
	
	*Rescale standard deviation for plots
	replace sd$vari = 2.56*sd$vari

// Figure 1A (normalized percentiles)
	local y1 = ""
	local y2 = ""
	local y2 = ""
	
	if "${vari}" == "logearn"{
		local y1 = 0
		local y2 = 0.65
		local y3 = 0.1
	}
	if "${vari}" == "researn" | "${vari}" == "researne" {
		local y1 = -0.06
		local y2 =  0.06
		local y3 = .02
	}
	
	tspltAREALimPA "np90$vari np75$vari np50$vari np25$vari np10$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p90" "p75" "p50" "p25" "p10" "" "" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Percentiles Relative to `lyear'" /// y axis title 
	   "" ///  Plot title
	   "" ///
	   "fig1A_`subgp'_${vari}"	/// Figure name
	   "`y1'" "`y2'" "`y3'"		/// ylimits
	   "" 						/// Set to off to have inactive legend
	   "blue green red navy black maroon forest_green purple gray orange"			/// Colors
	   "O + S x D" 
	   
// Figures 1B (normalized top percentiles)	 
	if "${vari}" == "logearn"{
		local y1 = 0
		local y2 = 1.30
		local y3 = 0.2
	}
	if "${vari}" == "researn"{
		local y1 = 0
		local y2 = .8
		local y3 = 0.1
	}
	if "${vari}" == "researne" {
		local y1 = 0
		local y2 = .7
		local y3 = 0.1
	}
	
	tspltAREALimPA "np99_99$vari np99_9$vari np99$vari np95$vari np90$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "p99.99" "p99.9" "p99" "p95" "p90" "" "" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Percentiles Relative to `lyear'" /// y axis title 
	   "" ///  Plot title
	   "" ///
	   "fig1B_`subgp'_${vari}"	/// Figure name
	   "`y1'" "`y2'" "`y3'"				/// ylimits
	   "" 						/// If legend is active or nor	
	   "blue green red navy black maroon forest_green purple gray orange"			/// Colors
	   "D + S x O" 

// Figure 2 (Inequality)	
	if "${vari}" == "logearn"{
		local y1 = 1.6
		local y2 = 2.2
		local y3 = 0.2
	}
	if "${vari}" == "researn"{
		local y1 = 1.6
		local y2 = 2.2
		local y3 = 0.2
	}
	if "${vari}" == "researne" {
		local y1 = 1.6
		local y2 = 2.2
		local y3 = 0.2
	}
		   		   
	tspltAREALimPA "sd$vari p9010$vari" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "2.56*{&sigma}" "P90-P10" "" "" "" "" "" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Dispersion of `labtitle'" /// y axis title 
	   "" ///  Plot title
	   "" ///
	   "fig2A_`subgp'_${vari}"	/// Figure name
	   "`y1'" "`y2'" "`y3'"				/// ylimits
	   "" 						/// If legend is active or nor	
	   "blue red navy blue maroon forest_green purple gray orange"			/// Colors
	   "O S" 
	   
	if "${vari}" == "logearn"{
		local y1 = 0.4
		local y2 = 1.6
		local y3 = 0.2
	} 
	if "${vari}" == "researn"{
		local y1 = 0.4
		local y2 = 1.6
		local y3 = 0.2
	}
	if "${vari}" == "researne" {
		local y1 = 0.4
		local y2 = 1.6
		local y3 = 0.2
	}
	 tspltAREALimPA "p9050$vari  p5010$vari " /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Dispersion of `labtitle'" /// y axis title 
	   "" ///  Plot title
	   "" ///
	   "fig2B_`subgp'_${vari}"	/// Figure name
	   "`y1'" "`y2'" "`y3'"				/// ylimits
	   "" 						/// If legend is active or nor	
	   "blue red navy blue maroon forest_green purple gray orange"			/// Colors
	   "O S" 	  		
	   
	   }	// END of loop over subgroups
	   
}		// END loop over variables
}	// END of inequality section
	
/*----------------------------------------
	Cohorts and Initial Inequality
------------------------------------------*/
if "${figcoh}" == "yes"{ 

	*What is the folder to save plot?
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
	

foreach var in logearn{	// Add here other variables 
	foreach subgp in male fem {			// Add here other groups 
	
	// Generates plot for initial wealth inequality
													
	*The code generates for raw earnimgs and residuals earnigs
	global vari = "`var'"		
	
	*Label for plots
	local labtitle = "Log Earnings"
								
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
	gen p99990${vari} = p99_9${vari} - p99${vari}
	gen p9990${vari} = p99${vari} - p90${vari}
	gen p9010${vari} = p90${vari} - p10${vari}	
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}

	*Gen cohort that is the age at which cohort was 25 years old 
	gen cohort25 = year - age + 25
	order year age cohort25
		
			 			
// Plots at the age of entry

	foreach ageval in 25{
	preserve
		*Keep only the sub sample at the age of age val 
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
		local rlast = ${yrlast}

	// 	*Plots
		
	// Percentiles
		tspltAREALimPA "p9050${vari} p5010${vari}" /// Which variables?
	   "year" ///
	   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
	   "1" "3" ///
	   "" /// x axis title
	   "Dispersion of `labtitle'" /// y axis title 
	   "" ///  Plot title
	   ""  /// 	 Plot subtitle  
	   "fig3_`subgp'_${vari}"	/// Figure name
	   "0.4" "1.9" "0.2"				/// ylimits
		"" 						/// If legend is active or nor	
		"red blue forest_green purple gray orange green"			/// Colors
		 "O S x D" 	
		 
	restore
	
	} // END of loop over age val		
	
	// Plots by cohorts 			
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
		
		*Age 25
		local posi1= 2.35
		local posi2= 2.25
		local posi3= 2.4
		
		local yposi1= 1997
		local yposi2= 1998
		local yposi3= 1997
		
		*Age 35
		local posj1= 1.55
		local posj2= 1.45
		local posj3= 1.6
		
		local yposj1= 2003
		local yposj2= 2005
		local yposj3= 2004
		
	}	
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_maleage_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local tlocal = "Women"
		
		*Age 25
		local posi1= 2.35
		local posi2= 2.25
		local posi3= 2.4
		
		local yposi1= 1997
		local yposi2= 1998
		local yposi3= 1997
		
		*Age 35
		local posj1= 1.65
		local posj2= 1.80
		local posj3= 1.6
		
		local yposj1= 2003
		local yposj2= 2005
		local yposj3= 2004
	}
		
	*Calculate additional moments 
	gen p99990${vari} = p99_9${vari} - p99${vari}
	gen p9990${vari} = p99${vari} - p90${vari}
	gen p9010${vari} = p90${vari} - p10${vari}	
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}

	*Gen cohort that is the age at which cohort was 25 years old 
	gen cohort25 = year - age + 25
	order year age cohort25
	
	

	gkswplot_co "p9010`var'" "year" ///
			 "1993 2000 2005 2010" /// what cohorts?
			 "25 30 35 45" /// What ages: code allows three
			 "1995" "2015" "5" /// x-axis
			 "on" "7" "2" "Cohort 1993" "Cohort 2000" "Cohort 2005" "Cohort 2010" /// Legends
			 "" "P90-P10 of Log Earnigs"  /// x and y titles 
			 "" "large" "" "" ///
			 "1" "2.5" "0.5" ///
			 "fig3B_`subgp'_${vari}" ///
			 "`posi1'" "`yposi1'" "`posi2'" "`yposi2'" "`posi3'" "`yposi3'" "25 yrs old" ///
			 "`posj1'" "`yposj1'" "`posj2'" "`yposj2'" "`posj3'" "`yposj3'" "35 yrs old" 

	
}	// END loop subgroups
}	// END loop over variables 
}	// END section cohorts
 
/*---------------------------------------------------	
    Volatility
 ---------------------------------------------------*/
if "${figvol}" == "yes"{  


*Time series for slides 

	*Plot One-year changes
	foreach jj in 1 5{ 
		
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
	global vari = "researn`jj'F"
	
	*Figure 4
	foreach subgp in men women {
		
		if "${vari}" == "researn1F"{
			local lyear = ${yrfirst}
			local ryear = ${yrlast}
			local labtitle = "g{sup:1}{sub:it}"
		}		
		if "${vari}" == "researn5F"{
			local lyear = ${yrfirst} + 2
			local ryear = ${yrlast} - 3	
			local labtitle = "g{sup:5}{sub:it}" // ?? what labels here?
		}
		
		*Load data 				
		insheet using "out${sep}${voladata}${sep}L_${vari}_male_sumstat.csv", case clear
		
		if "`subgp'" == "men"{
			keep if male == 1
		}
		else{
			keep if male == 0
		}				
		gen rece = inlist(year,${receyears})
		
		gen p9050$vari = p90$vari - p50$vari
		gen p5010$vari = p50$vari - p10$vari
		
		if "${vari}" == "researn1F"{
			local ylimlo = 0.2
			local ylimup = 0.75
			local ylimdf = 0.1			
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = 0.4
			local ylimup = 1.0
			local ylimdf = 0.2	
			replace year = year + 2		// This is to center the 5-year changes
		}
		
		   tspltAREALimPA "p9050$vari  p5010$vari" /// Which variables?
		   "year" ///
		   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P90-P50" "P50-P10" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Dispersion of `labtitle'" /// y axis title 
		   "" ///  Plot title
		   "" ///
		   "fig4_`subgp'_${vari}"	/// Figure name
		   "`ylimlo'" "`ylimup'" "`ylimdf'"				/// ylimits
		   "" 						/// If legend is active or nor	
		   "blue red navy blue maroon forest_green purple gray orange"			/// Colors
		   "O S" 
		   
	}
	
	*Figure 5
	insheet using "out${sep}${voladata}${sep}L_${vari}_male_sumstat.csv", case clear
	gen ksk${vari} = ((p90${vari} - p50${vari}) - (p50${vari} - p10${vari}) )/(p90$vari - p10${vari})
	gen cku${vari} = (p97_5${vari} - p2_5${vari})/(p75$vari - p25${vari}) - 2.91
	
	keep year male ksk${vari} cku${vari}
	reshape wide ksk${vari} cku${vari}, i(year) j(male)
	gen rece = inlist(year,${receyears})
	
	if "${vari}" == "researn1F"{
		local ylimlo = -0.1
		local ylimup = 0.2
		local ylimdf = 0.05			
	}		
	if "${vari}" == "researn5F"{
		local ylimlo = -0.05
		local ylimup = 0.20
		local ylimdf = 0.05		
		replace year = year + 2		// This is to center the 5-year changes
	}

	
	 tspltAREALimPA "ksk${vari}0 ksk${vari}1" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "Women" "Men" "" "" "" "" "" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Skewness of `labtitle'" /// y axis title 
	   "" ///  Plot title
	   "" ///
	   "fig5A_${vari}"	/// Figure name
		"`ylimlo'" "`ylimup'" "`ylimdf'"				/// ylimits
	   "" 						/// If legend is active or nor	
	   "red blue navy blue maroon forest_green purple gray orange"			/// Colors
	   "O S" "yes"		   
	   
	if "${vari}" == "researn1F"{
		local ylimlo = 8
		local ylimup = 12
		local ylimdf = 1	
	}		
	if "${vari}" == "researn5F"{
		local ylimlo = 4
		local ylimup = 8
		local ylimdf = 2			
	}
 	 
	 tspltAREALimPA "cku${vari}0 cku${vari}1" /// Which variables?
	   "year" ///
	   `lyear' `ryear' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
	   "Women" "Men" "" "" "" "" "" "" "" /// Labels 
	   "1" "11" ///
	   "" /// x axis title
	   "Excess Kurtosis of `labtitle'" /// y axis title 
	   "" ///  Plot title
	   "" ///
	   "fig5B_${vari}"	/// Figure name
	   "`ylimlo'" "`ylimup'" "`ylimdf'"				/// ylimits
	   "" 						/// If legend is active or nor	
	   "red blue navy blue maroon forest_green purple gray orange"			/// Colors
	   "O S" 
	   
	   }	// END loop jumps
}
***

/*---------------------------------------------------	
    Income growth heterogeneity 
 ---------------------------------------------------*/	
if "${figquan}" == "yes"{ 
	
		foreach mm in  0 1{		// 0: Women; 1: Men; 2: All		
		foreach jj in  1 5{
		local var = "researn`jj'F"
		global vari = "`var'"

		*What is the label for title 
		if "${vari}"== "researn1F"{
			local labtitle = "g{sub:it}"
			global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
		}
		if "${vari}" == "researn5F"{
			local labtitle = "g{sub:it}{sup:5}"
			global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
		}
	 
		*Load the data for the last percentile
		insheet using "out${sep}${voladata}${sep}L_`var'_maleagerank.csv", clear case
		
		*Calculate additional moments 
		gen p9010${vari} = p90${vari} - p10${vari}
		gen p9050${vari} = p90${vari} - p50${vari}
		gen p5010${vari} = p50${vari} - p10${vari}
		gen p7525${vari} = p75${vari} - p25${vari}
		gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}
		gen cku${vari} = (p97_5${vari} - p2_5${vari})/p7525${vari} - 2.91		// Excess Kurtosis
		replace kurt${vari} = kurt${vari} - 3.0		// Excess Kurtosis
		
		if `mm' == 1{
			keep if male == `mm'
			local lname = "men"
			local mlabel = "Men"
		}
		else if `mm' == 0{
			keep if male == `mm'
			local lname = "women"
			local mlabel = "Women"
		}
		
		drop if year < ${Tcommon} 	// we would like to compare countries over the same time period. This shorter sample period will be called Tcommon. Notice, Tcommon is defined in the start of this code. 
		
		collapse  p9010${vari} p9050${vari} p5010${vari} sd${vari} ksk${vari} skew${vari} cku${vari} kurt${vari}, by(agegp permrank)
		reshape wide p9010${vari} p9050${vari} p5010${vari} sd${vari} ksk${vari} skew${vari} cku${vari} kurt${vari}, i(permrank) j(agegp)
		
		*Idex for plot: the code calculates the top 0.1% in a seperated group (group 42). Since some countries might have 
		*top coded values, we do not plot the top 0.1%
		gen idex = _n
		order idex 
	
		*Figure A		
		if "${vari}" == "researn1F"{
			local ylimlo = 0.0
			local ylimup = 2.2
			local ylimdf = 0.5			
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = 0.5
			local ylimup = 3
			local ylimdf = 0.5		
		}
		
		tw (connected p9010${vari}1 p9010${vari}2 p9010${vari}3 permrank if idex<=42, msymbol(none none o)  ///
		color(red blue green) lpattern(solid dash dash_dot) lwidth(thick thick thick)), ///
		xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", labsize(${xlabsize}) grid) ///
		graphregion(color(white)) plotregion(lcolor(black)) ///
		legend(ring(0) position(2) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(${legesize}) cols(1) symxsize(7) region(color(none))) ///
		xtitle("Quantiles of Permanent Income P{sub:it-1}", size(${xtitlesize})) ///
		ytitle("P90-P10 Differential of `labtitle'", size(${ytitlesize})) ///
		title("", color(black) size(${titlesize})) ylabel(`ylimlo'(`ylimdf')`ylimup',labsize(${ylabsize}))		
		graph export "${folderfile}/fig6A_${vari}_`lname'.pdf", replace 
			
		*Figure B	
		if "${vari}" == "researn1F"{
			local ylimlo = -0.3
			local ylimup = 0.25
			local ylimdf = 0.1			
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = -0.3
			local ylimup = 0.2
			local ylimdf = 0.1		
		}
		
		tw (connected ksk${vari}1 ksk${vari}2 ksk${vari}3 permrank if idex<=42, msymbol(none none o) ///
		color(red blue green) lpattern(solid dash dash_dot) lwidth(thick thick thick)), ///
		xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", labsize(${xlabsize}) grid) ///
		graphregion(color(white)) plotregion(lcolor(black)) ///
		legend(ring(0) position(2) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(${legesize}) cols(1) symxsize(7) region(color(none))) ///
		xtitle("Quantiles of Permanent Income P{sub:it-1}", size(${xtitlesize}))  ///
		ytitle("Kelley Skewness of `labtitle'", size(${ytitlesize})) ///
		title("", color(black) size(${titlesize})) ylabel(`ylimlo'(`ylimdf')`ylimup',labsize(${ylabsize})) yline(0,lcolor(black) lpattern(dash))
		graph export "${folderfile}/fig6B_${vari}_`lname'.pdf", replace 
				
		*Figure C
		if "${vari}" == "researn1F"{
			local ylimlo = 1
			local ylimup = 15
			local ylimdf = 2
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = 1
			local ylimup = 9
			local ylimdf = 2	
		}
		
		tw (connected cku${vari}1 cku${vari}2 cku${vari}3 permrank if idex<=42, msymbol(none none o) ///
		color(red blue green) lpattern(solid dash dash_dot) lwidth(thick thick thick)), ///
		xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", labsize(${xlabsize}) grid) ///
		graphregion(color(white)) plotregion(lcolor(black)) ///
		legend(ring(0) position(11) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(${legesize}) cols(1) symxsize(7) region(color(none))) ///
		xtitle("Quantiles of Permanent Income P{sub:it-1}", size(${xtitlesize}))  ///
		ytitle("Excess Crow-Siddiqui Kurtosis of `labtitle'", size(${ytitlesize})) ///
		title("", color(black) size(medium)) ylabel(`ylimlo'(`ylimdf')`ylimup',labsize(${ylabsize}))
		graph export "${folderfile}/fig6C_${vari}_`lname'.pdf", replace 	
		
		
		*For appendix
		*Figure AA
		
		if "${vari}" == "researn1F"{
			local ylimlo = 0.25
			local ylimup = 1
			local ylimdf = .25
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = 0.3
			local ylimup = 1.2
			local ylimdf = .3	
		}
		
		tw (connected sd${vari}1 sd${vari}2 sd${vari}3 permrank if idex<=42, msymbol(none none o)  ///
		color(red blue green) lpattern(solid dash dash_dot) lwidth(thick thick thick)), ///
		xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", labsize(${xlabsize}) grid) ///
		graphregion(color(white)) plotregion(lcolor(black)) ///
		legend(ring(0) position(2) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(${legesize}) cols(1) symxsize(7) region(color(none))) ///
		xtitle("Quantiles of Permanent Income P{sub:it-1}", size(${xtitlesize}))  ///
		ytitle("Standard Deviation of `labtitle'", size(${ytitlesize})) ///
		title("", color(black) size(medium)) ylabel(`ylimlo'(`ylimdf')`ylimup',labsize(${ylabsize}))
		graph export "${folderfile}/fig6A_${vari}_`lname'_ct.pdf", replace 		
		
			
		*Figure BB			
		if "${vari}" == "researn1F"{
			local ylimlo = -4
			local ylimup = 0
			local ylimdf = 1
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = -4
			local ylimup = 0
			local ylimdf = 1
		}
		
		tw (connected skew${vari}1 skew${vari}2 skew${vari}3 permrank if idex<=42, msymbol(none none o) ///
		color(red blue green) lpattern(solid dash dash_dot) lwidth(thick thick thick)), ///
		xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", labsize(${xlabsize}) grid) ///
		graphregion(color(white)) plotregion(lcolor(black)) ///
		legend(ring(0) position(7) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(${legesize}) cols(1) symxsize(7) region(color(none))) ///
		xtitle("Quantiles of Permanent Income P{sub:it-1}", size(${xtitlesize}))  ///
		ytitle("Skewness of `labtitle'", size(${ytitlesize})) ///
		title("", color(black) size(medium)) ylabel(`ylimlo'(`ylimdf')`ylimup',labsize(${ylabsize}))  yline(0,lcolor(black) lpattern(dash))
		graph export "${folderfile}/fig6B_${vari}_`lname'_ct.pdf", replace 
		
		*Figure CC
		if "${vari}" == "researn1F"{
			local ylimlo = 0
			local ylimup = 80
			local ylimdf = 20
		}		
		if "${vari}" == "researn5F"{
			local ylimlo = 0
			local ylimup = 40
			local ylimdf = 10
		}
		
		tw (connected kurt${vari}1 kurt${vari}2 kurt${vari}3 permrank if idex<=42, msymbol(none none o) ///
		color(red blue green) lpattern(solid dash dash_dot) lwidth(thick thick thick)), ///
		xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", labsize(${xlabsize}) grid) ///
		graphregion(color(white)) plotregion(lcolor(black)) ///
		legend(ring(0) position(11) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(${legesize}) cols(1) symxsize(7) region(color(none))) ///
		xtitle("Quantiles of Permanent Income P{sub:it-1}", size(${xtitlesize}))  ///
		ytitle("Excess Kurtosis of `labtitle'", size(${ytitlesize})) ///
		title("", color(black) size(medium)) ylabel(`ylimlo'(`ylimdf')`ylimup',labsize(${ylabsize})) yline(0,lcolor(black) lpattern(dash))
		graph export "${folderfile}/fig6C_${vari}_`lname'_ct.pdf", replace 	
		
		}	// END loop variables		
		}	// END loop men/women	
}
	
/*----------------------------------------------
	Mobility
------------------------------------------------*/
if "${figmob}" == "yes"{ 
	
	*What is the folder to save files 
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
		
		foreach mm in  0 1{			/*Gender: Men 1; Women 0*/		
		/*Load Data*/
		insheet using "out${sep}${mobidata}${sep}L_male_agegp_permearnalt_mobstat.csv", clear			
		keep if male == `mm'
		collapse meanpermearnaltranktp5 [aw=npermearnaltranktp5], by(permearnaltrankt year)
		keep meanpermearnaltranktp5 permearnaltrankt year
		reshape wide meanpermearnaltranktp5 , i(permearnaltrankt) j(year)
		gen idex = _n
		
		*T+5
		cap: drop  y1 x1 y2 x2
		if `mm' == 1{			
			gen y1 = 93 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 93 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 93
			local t2pos = 85 
		
		}
		else{
			gen y1 = 95 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 95 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 95
			local t2pos = 85 
		}
		tw  (line meanpermearnaltranktp51995 meanpermearnaltranktp52005 permearnaltrankt permearnaltrankt if idex<= 41, ///
			color(red blue black) lpattern(solid dash dash) lwidth(thick thick )) ///
			(scatter meanpermearnaltranktp51995 meanpermearnaltranktp52005 permearnaltrankt if idex==42, ///
			color(red blue green) lpattern(dash dash dash) msymbol(D S O)  msize(large large large) ) ///
			(pcarrow y1 x1 y2 x2, msize(medlarge) mlwidth(medthick) mlcolor(black) lcolor(black) ), ///
			text(`t1pos' `t2pos' "Top 0.1% of P{sub:it-1}", place(w) size(large))  ///
			legend(ring(0) position(11) order(1 "1995" 2 "2005") size(large) cols(1) symxsize(7) region(color(none))) ///
			xtitle("Percentiles of Permanent Income, P{sub:it}", size(large)) title("", color(black) size(medlarge)) ///
			xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 99 "99.9", labsize(large) grid) ///
			graphregion(color(white)) plotregion(lcolor(black)) ///
			ytitle("Mean Percentiles of P{sub:it+5}", color(black) size(large)) ylabel(,labsize(large))									
			*graph export "${folderfile}/fig7_mobility_male`mm'_yrs_T5.pdf", replace 
			
		*T+10
		insheet using "out${sep}${mobidata}${sep}L_male_agegp_permearnalt_mobstat.csv", clear			
		keep if male == `mm'
		collapse meanpermearnaltranktp10 [aw=npermearnaltranktp10], by(permearnaltrankt year)
		keep meanpermearnaltranktp10 permearnaltrankt year
		reshape wide meanpermearnaltranktp10 , i(permearnaltrankt) j(year)
		gen idex = _n
		
		cap: drop  y1 x1 y2 x2
		if `mm' == 1{	
			gen y1 = 88 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 88 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 88
			local t2pos = 85 
				   			
		}
		else{			
			gen y1 = 90 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 90 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 90
			local t2pos = 85 

		}
			
		tw  (line meanpermearnaltranktp101995 meanpermearnaltranktp102005 permearnaltrankt permearnaltrankt if idex<= 41, ///
			color(red blue black) lpattern(solid dash dash) lwidth(thick thick)) ///
			(scatter meanpermearnaltranktp101995 meanpermearnaltranktp102005 permearnaltrankt if idex==42, ///
			color(red blue green) lpattern(dash dash dash) msymbol(D S O)  msize(large large large) ) ///
			(pcarrow y1 x1 y2 x2, msize(medlarge) mlwidth(medthick) mlcolor(black) lcolor(black) ), ///
			text(`t1pos' `t2pos' "Top 0.1% of P{sub:it-1}", place(w) size(large))  ///
			legend(ring(0) position(11) order(1 "1995" 2 "2005") size(large) cols(1) symxsize(7) region(color(none))) ///
			xtitle("Percentiles of Permanent Income, P{sub:it}", size(large)) title("", color(black) size(medlarge)) ///
			xlabel(0(10)90 99, labsize(large) grid) graphregion(color(white)) plotregion(lcolor(black)) ///
			ytitle("Mean Percentiles of P{sub:it+10}", color(black) size(large)) ylabel(,labsize(large))			
			graph export "${folderfile}/fig7_mobility_male`mm'_yrs_T10.pdf", replace 
		
	/*--- Mobility by age group---*/			
				
		/*Load Data*/
		insheet using "out${sep}${mobidata}${sep}L_male_agegp_permearnalt_mobstat.csv", clear
		keep if male == `mm'
		collapse meanpermearnaltranktp5, by(permearnaltrankt agegp)
		keep meanpermearnaltranktp5 permearnaltrankt agegp
		reshape wide meanpermearnaltranktp5 , i(permearnaltrankt) j(agegp)
		gen idex = _n
		
		/*T+5 mobility*/
		cap: drop  y1 x1 y2 x2
		if `mm' == 1{			
			gen y1 = 93 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 93 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 93
			local t2pos = 85 
		
		}
		else{
			gen y1 = 95 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 95 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 95
			local t2pos = 85 
		}
						
		tw  (line meanpermearnaltranktp51 meanpermearnaltranktp52 meanpermearnaltranktp53 permearnaltrankt permearnaltrankt if idex<= 41, ///
			color(red blue green black) lpattern(solid dash dash_dot dash) lwidth(thick thick thick)) ///
			(scatter meanpermearnaltranktp51 meanpermearnaltranktp52 meanpermearnaltranktp53 permearnaltrankt if idex==42, ///
			color(red blue green) lpattern(dash dash dash) msymbol(D S O)  msize(large large large) ) ///
			(pcarrow y1 x1 y2 x2, msize(medlarge) mlwidth(medthick) mlcolor(black) lcolor(black) ), ///
			text(`t1pos' `t2pos' "Top 0.1% of P{sub:it-1}", place(w) size(large))  ///
			legend(ring(0) position(11) order(1 "[25-34]" 2 "[35-44]" 3 "[45-55]") size(large) cols(1) symxsize(7) region(color(none))) ///
			xtitle("Percentiles of Permanent Income, P{sub:it}", size(large)) title("", color(black) size(medlarge)) ///
			xlabel(2.5 "0" 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 99 "99.9", labsize(large) grid) ///
			graphregion(color(white)) plotregion(lcolor(black)) ///
			ytitle("Mean Percentiles of P{sub:it+5}", color(black) size(large)) ylabel(,labsize(large))						
			graph export "${folderfile}/fig7_mobility_male`mm'_T5.pdf", replace 
		
			 
		/*T+10 mobility*/
		insheet using "out${sep}${mobidata}${sep}L_male_agegp_permearnalt_mobstat.csv", clear
		keep if male == `mm'
		collapse meanpermearnaltranktp10, by(permearnaltrankt agegp)
		keep meanpermearnaltranktp10 permearnaltrankt agegp
		reshape wide meanpermearnaltranktp10 , i(permearnaltrankt) j(agegp)
		gen idex = _n
		
		cap: drop  y1 x1 y2 x2
		if `mm' == 1{	
			gen y1 = 88 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 88 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 88
			local t2pos = 85 
				   			
		}
		else{			
			gen y1 = 90 if _n == 1
			gen x1 = 85 if _n == 1
			gen y2 = 90 if _n == 1
			gen x2 = 97 if _n == 1
			local t1pos = 90
			local t2pos = 85 

		}	
		tw  (line meanpermearnaltranktp101 meanpermearnaltranktp102 permearnaltrankt permearnaltrankt if idex<= 41, ///
			color(red blue black) lpattern(solid dash dash) lwidth(thick thick)) ///
			(scatter meanpermearnaltranktp101 meanpermearnaltranktp102 permearnaltrankt if idex==42, ///
			color(red blue green) lpattern(dash dash dash) msymbol(D S O)  msize(large large large) ) ///
			(pcarrow y1 x1 y2 x2, msize(medlarge) mlwidth(medthick) mlcolor(black) lcolor(black) ), ///
			text(`t1pos' `t2pos' "Top 0.1% of P{sub:it-1}", place(w) size(large))  ///
			legend(ring(0) position(11) order(1 "[25-34]" 2 "[35-44]") size(large) cols(1) symxsize(7) region(color(none))) ///
			xtitle("Percentiles of Permanent Income, P{sub:it}", size(large)) title("", color(black) size(medlarge)) ///
			xlabel(0(10)90 99, labsize(large) grid) graphregion(color(white)) plotregion(lcolor(black)) ///
			ytitle("Mean Percentiles of P{sub:it+10}", color(black) size(large)) ylabel(,labsize(large))		
			graph export "${folderfile}/fig7_mobility_male`mm'_T10.pdf", replace 
	}	// END loop over men and women	
}
****	

/*---------------------------------------------------	
    Tail For Appendix 
 ---------------------------------------------------*/
if "${figtail}" == "yes"{
	
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"
	
	*Load and reshape data 		
	forvalues mm = 0/2{			/*0: Women; 1: Men; 2: All*/
				
		if `mm' == 1{
			insheet using "out${sep}${ineqdata}${sep}RI_male_earn_idex.csv", clear comma 
			keep if male == `mm'
			local llabel = "Male"
		}
		else if `mm' == 0{
			insheet using "out${sep}${ineqdata}${sep}RI_male_earn_idex.csv", clear comma 
			keep if male == `mm'
			local llabel = "Women"		
		}
		else {
			insheet using "out${sep}${ineqdata}${sep}RI_earn_idex.csv", clear comma 			
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
		
		*Re-reshape 
		reshape wide t me ra ob tob shob lshob t1000s lt l10t lt1000s, i(numlevel) j(year)
		
		
		/*5% Tail*/
		regress lshob1995 lt1995
		predict lshob1995_hat, xb
		global slopep1995 : di %4.2f _b[lt1995]
		
		regress lshob2015 lt2015
		predict lshob2015_hat, xb
		global slopep2015 : di %4.2f _b[lt2015]
				
		tw (line lshob1995 lshob1995_hat lt1995, color(red red) lwidth(thick) lpattern(solid dash)) ///
			(line  lshob2015 lshob2015_hat lt2015 , color(blue blue)  lwidth(thick) lpattern(solid dash)) , ///
		legend(ring(0) position(2) ///
			order(1 "1995 Level (Slope: ${slopep1995})" 3 "2015 Level (Slope: ${slopep2015})") size(medium) cols(1) symxsize(7) region(color(none))) ///
			 xtitle("log y{sub:it}", size(${xtitlesize})) title(, color(black) size(medlarge)) ///
			  xlabel(, grid labsize(${xlabsize})) graphregion(color(white)) plotregion(lcolor(black)) ///
			 ytitle("log(1-CDF)", color(black) size(${ytitlesize})) ylabel(,labsize(${ylabsize}))
			 graph export "${folderfile}/logCDF_5pct_`llabel'.pdf", replace 
		drop lshob2015_hat lshob1995_hat
		
		/*1% Tail*/		
		regress lshob1995 lt1995 if shob1995 < 0.01
		predict lshob1995_hat if e(sample), xb
		global slopep1995 : di %4.2f _b[lt1995]
		
		regress lshob2015 lt2015 if shob2015 < 0.01
		predict lshob2015_hat if e(sample), xb
		global slopep2015 : di %4.2f _b[lt2015]
				
		tw (line lshob1995 lshob1995_hat lt1995    if shob1995 < 0.01, color(red red) lwidth(thick) lpattern(solid dash)) ///
			(line  lshob2015 lshob2015_hat lt2015  if shob2015 < 0.01, color(blue blue)  lwidth(thick) lpattern(solid dash)) , ///
		legend(ring(0) position(2) order(1 "1995 Level (Slope: ${slopep1995})" 3 "2015 Level (Slope: ${slopep2015})") ///
		size(medium) cols(1) symxsize(7) region(color(none))) ///
			 xtitle("log y{sub:it}", size(${xtitlesize})) title(, color(black) size(medlarge)) ///
			  xlabel(, grid labsize(${xlabsize})) graphregion(color(white)) plotregion(lcolor(black)) ///
			 ytitle("log(1-CDF)", color(black) size(${ytitlesize})) ylabel(,labsize(${ylabsize}))
			 graph export "${folderfile}/logCDF_1pct_`llabel'.pdf", replace 
		drop lshob2015_hat lshob1995_hat
		
	}
}

/*---------------------------------------------------	
    This section generates the figures 3b in the
	Common Core section of the Guidelines
 ---------------------------------------------------*/	
if "${figcon}" == "yes"{ 
	*Folder to save figures 
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
	
	foreach subgp in male fem   all{
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using  "out${sep}${ineqdata}${sep}L_earn_con.csv", clear
		local tlocal = "All Sample"
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_earn_con_male.csv", clear
		keep if male == 1	// Keep the group we want to plot 
		local tlocal = "Men"
	}	
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_earn_con_male.csv", clear
		keep if male == 0	// Keep the group we want to plot 
		local tlocal = "Women"
	}
	
	
	*Normalizing data to value in ${normyear}
	local lyear = ${normyear}	// Normalization year
	foreach vv in q1share q2share q3share q4share q5share ///
				  top10share top5share top1share top05share top01share top001share ///
				  bot50share{
		
		sum  `vv' if year == `lyear', meanonly
		gen n`vv' = (`vv' - r(mean))/100
		
		}
		
	*What years 
	local rlast = ${yrlast}
	
	*Recession bars 
	gen rece = inlist(year,${receyears})
	
	
	*Joint Quintiles Figures
	tspltAREALimZero "nq1share nq2share nq3share nq4share nq5share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Q1" "Q2" "Q3" "Q4" "Q5" "" "" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Change in Income Shares Relative to `lyear'" /// y axis title 
		   "" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig11B_nquintile_more_`subgp'"	/// Figure name
		   "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
	       "green black maroon red navy blue forest_green purple gray orange"	/// Colors
		   "solid solid solid solid solid solid solid solid" ///
		   "O T D S T dh sh th dh sh x none"
		   
		tspltAREALimZero "nbot50share ntop10share ntop5share ntop1share ntop05share ntop01share ntop001share" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Bottom 50%" "Top 10%" "Top 5%" "Top 1%" "Top 0.5%" "Top 0.1%" "Top 0.01%" "" "" /// Labels 
		    "1" "11" ///
		   "" /// x axis title
		   "Change in Income Shares Relative to `lyear'" /// y axis title 
		   "" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig11B_bot50share_more_`subgp'"	/// Figure name
		   "" "" ""				/// ylimits
		   "" 						/// If legend is active or nor	
	       "green black maroon red navy blue forest_green purple gray orange"	/// Colors
		   "solid solid solid solid solid solid solid solid" ///
		   "O T D S T dh sh th dh sh x none"
		   
		   
	*Gini
	tspltAREALim2 "gini" /// Which variables?
		   "year" ///
		   ${yrfirst} `rlast' 3 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Gini" "" "" "" "" "" "" "" "" /// Labels 
		   "1" "11" ///
		   "" /// x axis title
		   "Gini Coefficient" /// y axis title 
		   "" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_gini_`subgp'"	/// Figure name
		   "" "" ""				/// ylimits
		   "off" 						/// If legend is active or nor	
		   "blue red"			// Colors
		   
		   
}	// END of loop over variables
} // END of section 


/*---------------------------------------------------	
	Earnings growth Densities
---------------------------------------------------	*/

if "${figden}" == "yes"{ 
	
	*Folder to save figures 
	global folderfile = "$maindir${sep}figs${sep}${outfolder}${sep}FigsPaper"	
	
	*Ploting
	foreach sam in women men {
		foreach yy in 1995 2005{			// Which years are being plotted
			foreach vari in researn1F researn5F    {
			
				*Labels 
				if "`vari'" == "researn1F"{
// 					local labtitle = "{&Delta}{sup:1}{&epsilon}{sub:it}"
					local labtitle = "g{sup:1}{sub:it}"
				}
				if "`vari'" == "researn5F"{
// 					local labtitle = "{&Delta}{sup:5}{&epsilon}{sub:it}"
					local labtitle = "g{sup:5}{sub:it}"
				}
			
				*Data
				if "`sam'" == "all"{
					insheet using "out${sep}${voladata}${sep}L_`vari'_sumstat.csv", case clear
					
					sum sd`vari' if year == `yy'
					global sd = r(mean) 
					
					sum skew`vari' if year == `yy'
					global skew = r(mean) 
								
					sum kurt`vari' if year == `yy'
					global kurt = r(mean) 
					
					global sdplot: di %4.2f  ${sd}
					global skplot: di %4.2f  ${skew}
					global kuplot: di %4.2f  ${kurt}
					
					insheet using "out${sep}${voladata}${sep}L_`vari'_hist.csv", case clear
					local labtitle2 = "(All Sample)"
				}
				else if "`sam'" == "men"{
					insheet using "out${sep}${voladata}${sep}L_`vari'_male_sumstat.csv", case clear
					
					sum sd`vari' if year == `yy' & male == 1
					global sd = r(mean) 
					
					sum skew`vari' if year == `yy' & male == 1
					global skew = r(mean) 
								
					sum kurt`vari' if year == `yy' & male == 1
					global kurt = r(mean) 
					
					global sdplot: di %4.2f  ${sd}
					global skplot: di %4.2f  ${skew}
					global kuplot: di %4.2f  ${kurt}
					
					
					insheet using "out${sep}${voladata}${sep}L_`vari'_hist_male.csv", case clear
					keep if male == 1
					local labtitle2 = "(Men Only)"
				}
				else if "`sam'" == "women"{
					insheet using "out${sep}${voladata}${sep}L_`vari'_male_sumstat.csv", case clear
					
					sum sd`vari' if year == `yy' & male == 0
					global sd = r(mean) 
					
					sum skew`vari' if year == `yy' & male == 0
					global skew = r(mean) 
								
					sum kurt`vari' if year == `yy' & male == 0
					global kurt = r(mean) 
					
					global sdplot: di %4.2f  ${sd}
					global skplot: di %4.2f  ${skew}
					global kuplot: di %4.2f  ${kurt}
					
					insheet using "out${sep}${voladata}${sep}L_`vari'_hist_male.csv", case clear
					keep if male == 0
					local labtitle2 = "(Women Only)"
				}
				
				
				*Log densities 
				gen lden_`vari'`yy' = log(den_`vari'`yy')
				gen lnden_`vari'`yy' = log(normalden(val_`vari'`yy',0,${sd}))
				
				gen nden_`vari'`yy' = (normalden(val_`vari'`yy',0,${sd}))
				
				*Slopes
				reg lden_`vari'`yy' val_`vari'`yy' if val_`vari'`yy' < -1 & val_`vari'`yy' > -4
				global blefttail: di %4.2f _b[val_`vari'`yy']
				predict lefttail if e(sample), xb 
				
				reg lden_`vari'`yy' val_`vari'`yy' if val_`vari'`yy' > 1 & val_`vari'`yy' < 4
				global brighttail: di %4.2f _b[val_`vari'`yy']
				predict righttail if e(sample), xb 
				
				*Trimming for plots
				replace lnden_`vari'`yy' = . if val_`vari'`yy' < -2
				replace lnden_`vari'`yy' = . if val_`vari'`yy' > 2
				
				replace lden_`vari'`yy' = . if val_`vari'`yy' < -4
				replace lden_`vari'`yy' = . if val_`vari'`yy' > 4
				
				
				replace nden_`vari'`yy' = . if val_`vari'`yy' < -4
				replace nden_`vari'`yy' = . if val_`vari'`yy' > 4
				
				replace den_`vari'`yy' = . if val_`vari'`yy' < -4
				replace den_`vari'`yy' = . if val_`vari'`yy' > 4
				
				replace lefttail = . if val_`vari'`yy' < -4
				replace lden_`vari'`yy' = . if val_`vari'`yy' > 4
				
				replace righttail = . if val_`vari'`yy' > 4
				replace lden_`vari'`yy' = . if val_`vari'`yy' > 4
				
				
				logdnplot "lden_`vari'`yy' lnden_`vari'`yy' lefttail righttail" "val_`vari'`yy'" /// y and x variables 
						"One-Year Log Earnings Growth" "Log-Density" "medium" "medium" 		/// x and y axcis titles and sizes 
						 "" "" "large" ""  ///	Plot title
						 "Data Density" "N(0,${sdplot}{sup:2})" "Left   Slope: ${blefttail}" "Right Slope: ${brighttail}" "" ""						/// Legends
						 "on" "11"	"1"							/// Leave empty for active legend
						 "-4" "4" "1" "-10" "3" "2"				/// Set limits of x and y axis 
						 "lden_`vari'`yy'"					    /// Set what variable defines the y-axis
						"fig13_lden_`vari'_`sam'_`yy'"			/// Name of file
						"St. Dev.: ${sdplot}" "Skewness: ${skplot}"  "Kurtosis: ${kuplot}" ///
						 "2 1.8" "1 1.8" "0 1.8"				// Position of the right text
						 										
				logdnplot "den_`vari'`yy' nden_`vari'`yy'" "val_`vari'`yy'" /// y and x variables 
						"One-Year Log Earnings Growth" "Density" "medium" "medium" 		/// x and y axcis titles and sizes 
						 "" "" "large" ""  ///	Plot title
						 "Data Density" "N(0,${sdplot}{sup:2})" "" "" "" ""						/// Legends
						 "on" "11"	"1"							/// Leave empty for active legend
						 "-2.5" "2.5" "1" "0" "4" "1"				/// Set limits of x and y axis 
						 "den_`vari'`yy'"					/// Set what variable defines the y-axis
						"fig13_den_`vari'_`sam'_`yy'"		/// Name of file
						"St. Dev.: ${sdplot}" "Skewness: ${skplot}"  "Kurtosis: ${kuplot}" ///
						 "3.0 1" "2.5 1" "2.0 1"							 				
			
			}	// END loop over variables	
		}	// END loop over years 
	}	// END loop over samples
} 	// END of section

*END OF THE CODE
