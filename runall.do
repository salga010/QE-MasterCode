// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This code runs files 0 to 5 for the GRID project
// This version Aug 20, 2023
// Ozkan, Salgado
// Notice you still need to go to the specific files to make some small changes
// (e.g. add folders and location) including 0_Initialize.do
// You can always run the do-files independently. 
// 6_Insheeting_datasets.do is an stand-alone code
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

clear all 
// Define what is the main directory where the data and do files are saved 
global maindir =""

// Run the codes 
do "$maindir/do/1_Gen_Base_Sample.do"
do "$maindir/do/2_DescriptiveStats.do"
do "$maindir/do/3_Inequality.do" 
do "$maindir/do/4_Volatility.do" 
do "$maindir/do/5_Mobility.do"

// END OF THE CODE

