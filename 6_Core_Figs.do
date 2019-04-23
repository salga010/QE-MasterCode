// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the core figures
// Last edition April, 22, 2019
// Serdar Ozkan and Sergio Salgado
// 
// The figures below are meant to be a guideline and might require some changes 
// to accommodate the particularities of each dataset. If you have any question
// please contact Ozkan/Salgado in Slack
//
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all
set more off

*global maindir ="/Users/serdar/Dropbox/GLOBAL-MASTER-CODE/STATA/"
global maindir ="/Users/sergiosalgado/Dropbox/GLOBAL-MASTER-CODE/STATA/"

// Where the data is stored
global ineqdata = "23 Apr 2019 Inequality"			// Data on Inequality 
global voladata = "23 Apr 2019 Volatility"			// Data on Volatility
global mobidata = "23 Apr 2019 Mobility"			// Data on Mobility

// Do not make change from here on. Contact Ozkan/Salgado if changes are needed. 
	do "$maindir/do/0_Initialize.do"
	do "$maindir${sep}do${sep}myplots.do"		
	
// Define some common caractristics of the plots 
	global xtitlesize = "medium" 
	global ytitlesize = "medium" 
	global titlesize  = "vlarge" 
	global subtitlesize = "medium" 
	global formatfile  = "pdf"
	global fontface   = "Times New Roman"
	global marksize = "medium"	


// Where the firgures are going to be saved 
global outfolder=subinstr(c(current_date)," ","",.) 
global outfolder="figs_${outfolder}"
capture noisily mkdir "$maindir${sep}figs${sep}$outfolder"
global folderfile = "figs${sep}$outfolder"	
	
	
// Cd to folder with out 
	cd "$maindir${sep}" // Cd to the folder containing the files
	

/*---------------------------------------------------	
    This section generates the figures 1 and 2 
	and corresponding appendix figures required in poins 1 to 4 in  the
	Common Core section of the Guidelines
 ---------------------------------------------------*/
foreach var in logearn researn permearn{
	foreach subgp in male fem all{
	
	*Which variable will be ploted
	global vari = "`var'"						 
	
	*What is the group under analysis? 
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_sumstat.csv", clear
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_male_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
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
		local lyear = 1993
	}
	if "${vari}" == "researn"{
		local lyear = 1993
	}
	if "${vari}" == "permearn"{
		local lyear = 1995
	}
	
	
	*Normalize Percentiles 
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}

	*Rescale by first year 
	foreach vv in sd$vari p1$vari p2_5$vari p5$vari p10$vari p12_5$vari p25$vari ///
		p37_5$vari p50$vari p62_5$vari p75$vari p87_5$vari p90$vari p95$vari ///
		p97_5$vari p99$vari p99_9$vari p99_99$vari{
		
		sum  `vv' if year == `lyear', meanonly
		gen n`vv' = `vv' - r(mean)
		
		}
		
// Figure 1 (Inequality)	
	tsplt "np5$vari np10$vari  np25$vari np50$vari np75$vari np90$vari np95$vari np99_9$vari np99_99$vari" /// Which variables?
		   "year" ///
		   `lyear' 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99.9" "p99.99" /// Labels 
		   "Year" /// x axis title
		   "Percentiles of `labtitle' (${nyear}=0)" /// y axis title 
		   "Percentiles of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig1_`subgp'_${vari}"	// Figure name
		   
// Figure 2 (Inequality)	
	tsplt2sc "p9010${vari}" "sd${vari}" /// variables plotted
		   "year" ///
		   1.2 2.2 0.2  /// 
		   0.5 0.8 0.05  ///
		   `lyear' 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "P9010" "Standard Deviation" /// Labels 
		   "Year" /// x axis title
		   "P9010 of log y{sub:it}" /// y axis title (left)
		   "Standard Deviation of `labtitle'" /// y axis title  (right)
		   "Measures of Dispersion of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2a_`subgp'_${vari}"	// Figure name

	tsplt "p9050${vari} p5010${vari}" ///  variables plotted
		   "year" ///
		   `lyear' 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p90-p50" "p50-p10" "" "" "" "" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "Percentiles of log y{sub:it}" /// y axis title 
		   "Measures of Dispersion of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig2b_`subgp'_${vari}"	// Figure name
		   
	   }	// END of loop over subgroups
}	// END loop over variables
***


/*---------------------------------------------------	
    This section generates the figures 3a in the
	Common Core section of the Guidelines
 ---------------------------------------------------*/
foreach subgp in male fem all{
	
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
	
	foreach yy in 1995 2005 {		// Can add other years here
		sum p95logearn if year == `yy'
		local p95_`yy' = r(mean)
		
		sum p99logearn if year == `yy'
		local p99_`yy' = r(mean)
	}
	
	*Plot the log-densities
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_hist.csv", clear
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_hist_male.csv", clear
		keep if male == 1	// Keep the group we want to plot 
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_logearn_hist_male.csv", clear
		keep if male == 0	// Keep the group we want to plot 
	}
	

	foreach yy in 1995 2005 {		// Can add other years here
	
	gen lden_logearn`yy' = log(den_logearn`yy')
	
	*First cutoff: 5% 
	reg lden_logearn`yy' val_logearn`yy' if val_logearn`yy' >=  `p95_`yy''
	predict lden_logearn`yy'_hat1 if e(sample) == 1, xb 
	global slope : di %4.2f _b[val_logearn`yy']
	
	
	preserve 
	keep if val_logearn`yy' >=  `p95_`yy''
	
	dnplot "lden_logearn`yy' lden_logearn`yy'_hat1" "val_logearn`yy'" /// y and x variables 
			"log y{sub:it}" "log-Density" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Log Density of log y{sub:it} at top 5% in `yy'" "Sample: `subgp' - Slope: ${slope}" "large" ""  ///	Plot title
			 "" "" "" "" "" ""						/// Legends
			 "off"									/// Leave empty for active legend
			"fig3a_pareto95_`subgp'_lden_logearn`yy'"			// Name of file
			
	restore 
	
	*Second cutoff: 1% 
	reg lden_logearn`yy' val_logearn`yy' if val_logearn`yy' >=  `p99_`yy''
	predict lden_logearn`yy'_hat2 if e(sample) == 1, xb 
	global slope : di %4.2f _b[val_logearn`yy']
	
	
	preserve 
	keep if val_logearn`yy' >=  `p99_`yy''
	
	dnplot "lden_logearn`yy' lden_logearn`yy'_hat2" "val_logearn`yy'" /// y and x variables 
			"log y{sub:it}" "log-Density" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Log Density of log y{sub:it} at top 1% in `yy'" "Sample: `subgp' - Slope: ${slope}" "large" ""  ///	Plot title
			 "" "" "" "" "" ""						/// Legends
			 "off"									/// Leave empty for active legend
			"fig3a_pareto99_`subgp'_lden_logearn`yy'"			// Name of file
			
	restore 
	}	// END loop over years
}	// END loop over sub groups
***



/*---------------------------------------------------	
    This section generates the figures 3b in the
	Common Core section of the Guidelines
 ---------------------------------------------------*/	
 
	*Load data 
	insheet using  "out${sep}${ineqdata}${sep}L_earn_con.csv", clear
	
	*Quintiles
	tsplt "q1share q2share q3share q4share q5share" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Q1" "Q2" "Q3" "Q4" "Q5" "" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "Income Shares (%)" /// y axis title 
		   "Income Shares of y{sub:it} by Quintiles" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_quintile"	// Figure name
		   
	*Bottom 50%
	tsplt "bot50share" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "" "" "" "" "" "" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "Income Shares (%)" /// y axis title 
		   "Income Shares of y{sub:it} of Bottom 50%" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_bottom50"	// Figure name
		   
		   
	*Top shares
	tsplt "top10share top5share top1share top05share top01share top001share" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Top 10%" "Top 5%" "Top 1%" "Top 0.5%" "Top 0.1%" "Top 0.01%" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "Income Shares (%)" /// y axis title 
		   "Income Shares of y{sub:it} by Top Income Earnears" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_topshares"	// Figure name
		   
	*Gigi 
	tsplt "gini" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "" "" "" "" "" "" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "Gini Coefficient" /// y axis title 
		   "Gini Coefficient of y{sub:it}" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig3b_gini"	// Figure name
***


/*---------------------------------------------------	
    This section generates the figures 4 to 7 
 ---------------------------------------------------*/
foreach var in researn5F researn1F{				
	foreach subgp in fem male all{
	
	*Which variable will be ploted
	global vari = "`var'"						 
	
	*What is the group under analysis? 
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${voladata}${sep}L_`var'_sumstat.csv", case clear
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${voladata}${sep}L_`var'_male_sumstat.csv", case clear
		keep if male == 1	// Keep the group we want to plot 
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${voladata}${sep}L_`var'_male_sumstat.csv", case clear
		keep if male == 0	// Keep the group we want to plot 
	}
	
	
	*What is the label for title 
	if "${vari}" == "researn1F"{
		local labtitle = "g{sub:it}"
	}
	if "${vari}" == "researn5F"{
		local labtitle = "g{sub:it}{sup:5}"
	}
	
	
	*What are the x-axis limits
	if "${vari}" == "researn1F"{
		local lyear = ${yrlast}
	}
	if "${vari}" == "researn5F"{
		local lyear = ${yrlast} - 5
	}

	
	*Normalize Percentiles 
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen p7525${vari} = p75${vari} - p25${vari}
	
	gen ksk${vari} = (p9050${vari} - p5010${vari})/p9010${vari}
	gen cku${vari} = (p97_5${vari} - p2_5${vari})/p7525${vari}
	
	
	
// Figure 4	
	tsplt "p5$vari p10$vari p25$vari p50$vari p75$vari p90$vari p95$vari p99_9$vari p99_99$vari" /// Which variables?
		   "year" ///
		   1993 `lyear' 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p5" "p10" "p25" "p50" "p75" "p90" "p95" "p99.9" "p99.99" /// Labels 
		   "Year" /// x axis title
		   "Percentiles of `labtitle'" /// y axis title 
		   "Percentiles of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig4a_`subgp'_${vari}"	// Figure name
		   
// Figure 5
	tsplt "p9010${vari}" ///  variables plotted
		   "year" ///
		   1993 `lyear' 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "" "" "" "" "" "" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "P9010 of `labtitle'" /// y axis title 
		   "Dispersion of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig5a_`subgp'_${vari}"	// Figure name
		   
	
	tsplt "p9050${vari} p5010${vari}" ///  variables plotted
		   "year" ///
		   1993 `lyear' 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p90-p50" "p50-p10" "" "" "" "" "" "" "" /// Labels 
		   "Year" /// x axis title
		   "Dispersion of `labtitle'" /// y axis title 
		   "Measures of Dispersion of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig5b_`subgp'_${vari}"	// Figure name
		   
// Figure 6

	tsplt2sc "ksk${vari}" "skew${vari}" /// variables plotted
		   "year" ///
		   -1.0 1.0 0.25  /// 
		   -0.1 0.1 0.1  ///
		   1993 `lyear' 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Kelley Skewness" " Coeff. of Skewness" /// Labels 
		   "Year" /// x axis title
		   "Kelley Skewness of `labtitle'" /// y axis title (left)
		   "Coeff. of Skewness of `labtitle'" /// y axis title  (right)
		   "Measures of Skewness of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig6_`subgp'_${vari}"	// Figure name

// Figure 7 
	tsplt2sc "cku${vari}" "kurt${vari}" /// variables plotted
		   "year" ///
		   2.0 5.0 1.0  /// 
		   2.0 5.0 1.0  ///
		   1993 `lyear' 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "Crow-Siddiqi Kurtosis" " Coeff. of Kurtosis" /// Labels 
		   "Year" /// x axis title
		   "Crow-Siddiqi Kurtosis of `labtitle'" /// y axis title (left)
		   "Coeff. of Kurtosis of `labtitle'" /// y axis title  (right)
		   "Measures of Kurtosis of `labtitle'" ///  Plot title
		   ""  /// 	 Plot subtitle  (left blank in this example)
		   "fig7_`subgp'_${vari}"	// Figure name

	   }	// END of loop over subgroups
}	// END loop over variables
***
	
	

/*---------------------------------------------------	
    This section generates the figures 8a in the
	Common Core section of the Guidelines
 ---------------------------------------------------*/	
 
foreach var in researn5F researn1F{	
	
	*Which variable will be ploted
	global vari = "`var'"
	
	*What is the label for title 
	if "${vari}" == "researn1F"{
		local labtitle = "g{sub:it}"
	}
	if "${vari}" == "researn5F"{
		local labtitle = "g{sub:it}{sup:5}"
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
	
	*Ploting
	dnplot "p9010${vari}1 p9010${vari}2 p9010${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "P90-P10 of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Dispersion of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""									/// Leave empty for active legend
			"fig8a_${vari}"			// Name of file

	dnplot "sd${vari}1 sd${vari}2 sd${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Standard Deviation of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Standard Deviation of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""									/// Leave empty for active legend
			"fig8b_${vari}"			// Name of file

	dnplot "ksk${vari}1 ksk${vari}2 ksk${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Kelley Skewness of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Kelley Skewness of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""									/// Leave empty for active legend
			"fig9a_${vari}"			// Name of file

	dnplot "skew${vari}1 skew${vari}2 skew${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Coef. of Skewness of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Coef. of Skewness of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""									/// Leave empty for active legend
			"fig9b_${vari}"			// Name of file

	dnplot "cku${vari}1 cku${vari}2 cku${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Crow-Siddiqi of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Crow-Siddiqi of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""									/// Leave empty for active legend
			"fig10a_${vari}"			// Name of file

	dnplot "kurt${vari}1 kurt${vari}2 kurt${vari}3 " "permrank" /// y and x variables 
			"Quantiles of P{sub:it-1}" "Coef. of Kurtosis of `labtitle'" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Coef. of Kurtosis of `labtitle' by P{sub:it-1}" "" "large" ""  ///	Plot title
			 "[25-34]" "[35-44]" "[45-55]" "" "" ""						/// Legends
			 ""									/// Leave empty for active legend
			"fig10b_${vari}"			// Name of file
}
***		
	

/*----------------------------------------------
	This section generates figure 11: Mobility
------------------------------------------------*/

// Figure 11A
foreach yr in 1995 2005{		// Add years here if you need
	
	*Load data of short term mobility
	insheet using "out${sep}${mobidata}${sep}L_ranktp1_mobstat.csv", clear
	keep if year == `yr'
		
	dnplot "meanranktp1 rankt" "rankt" /// y and x variables 
			"Rank of {&epsilon}{sub:t} in year t" ///
			"Mean Rank of {&epsilon}{sub:t} in year t+1" "medium" "medium" 		/// x and y axcis titles and sizes 
			 "Short-Term Mobility" "Year: `yr'" "large" ""  ///	Plot title
			 "" "" "" "" "" ""						/// Legends
			 "off"									/// Leave empty for active legend
			"fig11a_`yr'_mobility"			// Name of file
 
	 
	*Load data of long term mobility
	insheet using "out${sep}${mobidata}${sep}L_ranktp5_mobstat.csv", clear
	keep if year == `yr'
	
	dnplot "meanranktp5 rankt" "rankt" /// y and x variables 
	"Rank of {&epsilon}{sub:t} in year t" ///
	"Mean Rank of {&epsilon}{sub:t} in year t+5" "medium" "medium" 		/// x and y axcis titles and sizes 
	 "Long-Term Mobility" "Year: `yr'" "large" ""  ///	Plot title
	 "" "" "" "" "" ""						/// Legends
	 "off"									/// Leave empty for active legend
	"fig11b_`yr'_mobility"			// Name of file		
	
}

// Figure 11B
foreach yr in 1995 2000{	// Add more years here if you need

	*Load data of short term mobility
	insheet using "out${sep}${mobidata}${sep}L_permearnalt_mobstat.csv", clear
	keep if year == `yr'
		
	dnplot "meanpermearnaltranktp5 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year t+5" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility" "Year: `yr'" "large" ""  ///	Plot title
			"" "" "" "" "" ""						/// Legends
			"off"									/// Leave empty for active legend
			"fig11b_`yr'_tp5_mobility"			// Name of file
 
	dnplot "meanpermearnaltranktp10 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year t+10" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility" "Year: `yr'" "large" ""  ///	Plot title
			"" "" "" "" "" ""						/// Legends
			"off"									/// Leave empty for active legend
			"fig11b_`yr'_tp10_mobility"			// Name of file
 
	 
	dnplot "meanpermearnaltranktl3 permearnaltrankt" "permearnaltrankt" /// y and x variables 
			"Rank of P{sub:3t} in year t" ///
			"Mean Rank of P{sub:3t} in year T{sup:Max}-3" "medium" "medium" 		/// x and y axcis titles and sizes 
			"Permanent Income Mobility" "Year: `yr'" "large" ""  ///	Plot title
			"" "" "" "" "" ""						/// Legends
			"off"									/// Leave empty for active legend
			"fig11b_`yr'_tl3_mobility"			// Name of file

}
****	
	


/*----------------------------------------
	This section generates figure 12
------------------------------------------*/

foreach var in logearn{	// Add here other variables 
	foreach subgp in male fem all{			// Add here other groups 
				
	*Which variable is under analysis? 
	*The code generates for raw earnimgs and residuals earnigs
	global vari = "`var'"		
	
	*Label for plots
	local labtitle = "log y{sub:it}"
								
	*You can add more groups to this section 
	if "`subgp'" == "all"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_age_sumstat.csv", clear
	}
	if "`subgp'" == "male"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_maleage_sumstat.csv", clear
		keep if male == 1	// Keep the group we want to plot 
	}
		
	if "`subgp'" == "fem"{
		insheet using "out${sep}${ineqdata}${sep}L_`var'_maleage_sumstat.csv", clear
		keep if male == 0	// Keep the group we want to plot 
	}
	
	*Calculate additional moments 
	gen p9010${vari} = p90${vari} - p10${vari}
	gen p9050${vari} = p90${vari} - p50${vari}
	gen p5010${vari} = p50${vari} - p10${vari}
	gen ksk${vari} = (p9050${vari} - p9010${vari})/p9010${vari}
	
	*Keep only the sub sample at the age of 25
	keep if age == 25
	
	*Plots
	
// Percentiles
	tsplt "p10${vari} p25${vari} p50${vari} p75${vari} p90${vari} p95${vari} p99${vari}" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "p10" "p25" "p50" "p75" "p90" "p95" "p99" "" "" /// Labels 
		   "Cohort of Entry (Workers at age 25)" /// x axis title
		   "Percentiles of `labtitle'" /// y axis title 
		   "Percentiles of `labtitle'" ///  Plot title
		   "Sample: `subgp'"  /// 	 Plot subtitle  
		   "fig12a_`subgp'_${vari}"	// Figure name
		   
// P9010 
	tsplt "p9010${vari}" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "" "" "" "" "" "" "" "" "" /// Labels 
		   "Cohort of Entry (Workers at age 25)" /// x axis title
		   "P90-P10 of `labtitle'" /// y axis title 
		   "Inequality of `labtitle'" ///  Plot title
		   "Sample: `subgp'"  /// 	 Plot subtitle  
		   "fig12b_`subgp'_${vari}"	// Figure name

	   
// P9050 
	tsplt "p9050${vari}" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "" "" "" "" "" "" "" "" "" /// Labels 
		   "Cohort of Entry (Workers at age 25)" /// x axis title
		   "P90-P90 of `labtitle'" /// y axis title 
		   "Right-Tail Inequality of `labtitle'" ///  Plot title
		   "Sample: `subgp'"  /// 	 Plot subtitle  
		   "fig12c_`subgp'_${vari}"	// Figure name
	   
// P5010
	tsplt "p5010${vari}" /// Which variables?
		   "year" ///
		   1993 2013 5 /// Limits of x and y axis. Example: x axis is -.1(0.05).1 
		   "" "" "" "" "" "" "" "" "" /// Labels 
		   "Cohort of Entry (Workers at age 25)" /// x axis title
		   "P50-P10 of `labtitle'" /// y axis title 
		   "Left-Tail Inequality of `labtitle'" ///  Plot title
		   "Sample: `subgp'"  /// 	 Plot subtitle  
		   "fig12d_`subgp'_${vari}"	// Figure name
		   
}	// END loop subgroups
}	// END loop over variables 
