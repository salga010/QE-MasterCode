// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This program generates the time series of Mobility
// First  version January 06, 2019
// This version January 19, 2022
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

// Loop over the years
timer clear 1
timer on 1

global numestates = "1 3 5"		// How many years ahead mobility 3 5 10 15

global mathetgroup = `" "" "male agegp" male "' // Mobility conditional on

foreach varx in permearnalt researn{
	if ("`varx'"=="researn"){
		local firstyr = $yrfirst 
	}		
	if ("`varx'"=="permearnalt") {
		local firstyr = $yrfirst + 2	
	}
	foreach subgp in $numestates{		// This is the of years that will be used for the jump
		local yrmax = ${yrlast} - `subgp' 	// This should not be negative
		
		if `yrmax' < 0 {
			continue
			*This ensure the calculation only happens if yrmax > 0
		}
		
		forvalues yr = `firstyr'/`yrmax'{		
			*local yr = `firstyr'
			disp("-------------------------------------")
			disp("Working in year `yr' of jump `subgp'")
			disp("-------------------------------------")
		
			*Define which variables are we loading 
			local yrp = `yr'+`subgp'		// `subgp' yrs ahead
			
			*Load the data							
			// Not include individuals that do not have `varx' in year `yr' or `yrp' 		
			use  yob male `varx'`yr' `varx'`yrp' using ///
			"$maindir${sep}dta${sep}master_sample.dta" if `varx'`yr'~=. & `varx'`yrp'~=. , clear 

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
			local het="male age"  // we are always ranking within gender and age (not agegp)
			foreach t in "" "p"{ //Calculate the ranking in `yr' and `yrp'
				gen `varx'rankt`t'=.
				sort `het' `varx'`yr`t''
				by `het' : egen numobs=count(`varx'`yr`t'')
				by `het' : replace `varx'rankt`t' = _n/numobs 
				if ("`t'" == "p"){
					replace `varx'rankt`t' =100*`varx'rankt`t'
				}
				else{
				replace `varx'rankt`t' = 100 if `varx'rankt`t' > 0.999 			
				
				replace `varx'rankt`t' = 99.9 if `varx'rankt`t' > 0.99 & `varx'rankt`t' <= 0.999 
				replace `varx'rankt`t' = 99   if `varx'rankt`t' > 0.975 & `varx'rankt`t' <= 0.99 
				
				replace `varx'rankt`t' = (100/${nquantilemob})* ///
								(floor(numobs*`varx'rankt`t'*${nquantilemob}/(1+numobs))+1)	///
								if `varx'rankt`t'<=0.975
				}
				drop numobs
				
			}
			rename `varx'ranktp `varx'ranktp`subgp'
			foreach het in "all" "male" "agegp" "male_agegp"{ // For each heterogeneity group
				if "`het'" == "all"{					
					local hetsuf=""
				}
				else if "`het'" == "male"{					
					local hetsuf="male"
				}
				else if "`het'" == "agegp"{					
					local hetsuf="agegp"
				}				
				else if "`het'" == "male_agegp"{
					local hetsuf="male agegp"
				}
//				disp("`het'")
//				disp("`hetsuf'")								
				qui: bymysum_meanonly "`varx'ranktp`subgp'" ///
				"L_`het'_" "_`yr'" "year `hetsuf' `varx'rankt"									
			}
		}
	}
}


		
// Collect data across years 
foreach varx in permearnalt researn{
	
	if ("`varx'"=="researn") {
		local firstyr = $yrfirst 
	}		
	if ("`varx'"=="permearnalt") {
		local firstyr = $yrfirst + 2	
	}
	foreach het in "all" "male" "agegp" "male_agegp"{ // For each heterogeneity group
		local hetsuf = ""
		if "`het'" == "all"{					
			local hetsuf=""
		}
		else if "`het'" == "male"{					
			local hetsuf="male"
		}
		else if "`het'" == "agegp"{					
			local hetsuf="agegp"
		}
		else if "`het'" == "male_agegp"{
			local hetsuf="male agegp"
		}
				
		foreach subgp in $numestates{ // Number of years that will be used for the jump		
			clear
			local yrmax = ${yrlast} - `subgp' 	// This should not be negative
		
			if `yrmax' < 0 {
				continue
				*This ensure the calculation only happens if yrmax > 0
			}
			
			forvalues yr = `firstyr'/`yrmax'{		

				append using S_L_`het'_`varx'ranktp`subgp'_`yr'.dta
				erase S_L_`het'_`varx'ranktp`subgp'_`yr'.dta

				
			}
//			disp("`het'")
//		    disp("`hetsuf'")
			order year `hetsuf' `varx'rankt 
			sort year `hetsuf' `varx'rankt	
			save S_L_`het'_`varx'ranktp`subgp'.dta, replace	
		}	
	}
}	
	
// Collect data across jumps 
foreach varx in permearnalt researn{
	foreach het in "all" "male" "agegp" "male_agegp"{ // For each heterogeneity group
	
		if "`het'" == "all"{					
			local hetsuf=""
		}
		else if "`het'" == "male"{					
			local hetsuf="male"
		}
		else if "`het'" == "agegp"{					
			local hetsuf="agegp"
		}
		else if "`het'" == "male_agegp"{
			local hetsuf="male agegp"
		}
		clear

		foreach subgp in $numestates{ // Number of years that will be used for the jump		
		
			if (`subgp'==1){
				use S_L_`het'_`varx'ranktp`subgp'.dta, clear
				erase S_L_`het'_`varx'ranktp`subgp'.dta
			}
			else{
				merge 1:1 year `hetsuf' `varx'rankt ///
					using S_L_`het'_`varx'ranktp`subgp'.dta, nogenerate
				erase S_L_`het'_`varx'ranktp`subgp'.dta
			}
		}
		outsheet using "L_`het'_`varx'_mobstat.csv", replace comma			
	}
}
	
timer off 1
timer list 1
*END OF THE CODE 
