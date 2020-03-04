Log of Changes 
First version April, 19, 2019
This  version January, 18, 2019 
Serdar Ozkan (serdar.ozkan@toronto.ca)
Sergio Salgado (ssalgado@wharton.upenn.edu)
----------------

March 03, 2020

Updated 1_Gen_Sample.do, 6_Core_Figs.do, and (very minor) changes in myplots.do and 3_Inequality.do. Below the important changes

- On 1_Gen line 158 that was incorrectly dropping observations with little earnings dropping all observations with 0 earnings. Dropped that line. We also added a condition on arc-percent that only kicks in if labor earnings in t and in t+k are below the min income. 

- On 6_Core, adjusted some of the figures to put the figures of 5-year changes centered in the moving window. That is, if the moment is calculated as t+5, the plot is centered in t+2. Also, added a new version of figure 5a to have two axis. 



January, 18, 2019

Updated the codes to the version 2.0; This new version of the code contains several major changes relative to the original version of April 2019. Among others 

- Adds a new set of results for the arc-percent change in income
- Modifies the change income growth measure to allow for declines below the min value in t+k. 
- Adds new features to the plots such as recession bars and differential color schemes.
- Adds several new plots: density plots, cohort plots, etc. 


August, 14, 2019

We have modified 1_Gen_Sample.do so now it records the gender for which the profiles are calculated. These changes are made between lines 210 and 236


July, 05, 2019 

We have modified some of the calculations in the gen_base and mobility codes. In the first, we have added 

	bys male: egen avgall = mean(totearn)
	gen permearnalt`yr' = avgall*totearn/avg	// This is because we want to control for age effects
	
In lines 388 to have permearnalt in the correct scale. This does not change the results. 
The mobility code has more changes. In particular, we have modified the transition matrix calculation to account for 0. Individuals with 0 permanent earnings are now grouped in one category only, whereas the rest of individuals (with positive permearnalt earnings, are separated in 10 groups, to a total of 11 rows in the transition matrix). See lines 240 to 266. We have also saved some summary stats within each cell (see line 248 for instance).  



April, 19, 2019

The folder contains the first version of the code for the Global Income Dynamics Database project. The code was developed in Stata 13 by Serdar Ozkan and Sergio Salgado. 
The original set of do files is the following 

0_Initialize1_Gen_Base_Sample.do2_DescriptiveStats3_Inequality4_Volatility5_Mobility6_Core_FigsGenDatamyplotsmyprogs

See the file Code_Guidelines_April2019.pdf for additional details. 