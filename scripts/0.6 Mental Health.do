// Author: Ida Maria Hartmann
// Last edited: 17.09.2025

clear all
set more off

set scheme stcolor
set linesize 255
capture log close
set matsize 10000

cd "P:\Workdata\707906\imh\Childhood Predictability"
global data "P:\Workdata\707906\imh\Childhood Predictability\Data"
global code	"P:\Workdata\707906\imh\Childhood Predictability\Programs"
global rslt	"P:\Workdata\707906\imh\Childhood Predictability\Results"

use "Data\mental_health_diagnoses.dta", clear 
destring pnr, replace 
tostring pnr, replace format(%012.0f)

********************************************************************************

gen depression = 0 
replace depression = 1 if substr(diagnose,1,3) == "DF3"							// Depressive Perioder

gen depression_severity = 0 
// Depressive enkelt episoder
replace depression_severity = 1 if substr(diagnose,1,5) == "DF320"				// Mild 
replace depression_severity = 2 if substr(diagnose,1,5) == "DF321"				// Moderate
replace depression_severity = 3 if substr(diagnose,1,5) == "DF322"				// Severere
replace depression_severity = 4 if substr(diagnose,1,5) == "DF323"				// Severere, with psychotic symptoms
// Periodisk depression
replace depression_severity = 1 if substr(diagnose,1,5) == "DF330"				// Mild 
replace depression_severity = 2 if substr(diagnose,1,5) == "DF331"				// Moderate
replace depression_severity = 3 if substr(diagnose,1,5) == "DF332"				// Severere
replace depression_severity = 4 if substr(diagnose,1,5) == "DF333"				// Severere, with psychotic symptoms

gen anxiety = 0 
replace anxiety = 1 if substr(diagnose,1,3) == "DF4"							// Angsttilstande

gen ocd = 0 
replace ocd = 1 if substr(diagnose,1,4) == "DF42"								// Obsessive-compulsive disorder

gen stress_reaktion = 0 
replace stress_reaktion = 1 if substr(diagnose,1,4) == "DF43"					// Reaktioner på svær belastning og tilpasningsreaktioner


foreach var in depression anxiety {
	// Age at first diagnosis 
	by pnr `var' (age), sort: gen temp = age if _n == 1 & `var' == 1
	by pnr (age), sort: egen `var'_first_age = min(temp)
	drop temp
	// Year of first diagnosis
	by pnr `var' (year), sort: gen temp = year if _n == 1 & `var' == 1
	by pnr (year), sort: egen `var'_first_year = min(temp)
	drop temp
	
	rename `var' `var'_temp 
	by pnr year, sort: egen `var' = max(`var'_temp)
	by pnr (year), sort: egen `var'_ever = max(`var'_temp)
	drop `var'_temp
}

replace anxiety_ever = 0 if anxiety_ever  == .
replace depression_ever = 0 if depression_ever  == .


// Saving dataset 
keep pnr year depression anxiety depression_ever anxiety_ever depression_first_age depression_first_year anxiety_first_age anxiety_first_year type
duplicates drop

save "Data\mental_health.dta", replace