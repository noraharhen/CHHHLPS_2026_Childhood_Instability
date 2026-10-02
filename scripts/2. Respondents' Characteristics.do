// Author: Ida Maria Hartmann
// Last edited: 22.09.2025

clear all
set more off

set scheme s1color
set linesize 255
capture log close
set matsize 10000

cd "P:\Workdata\707906\imh\Childhood Predictability"
global data "P:\Workdata\707906\imh\Childhood Predictability\Data"
global code	"P:\Workdata\707906\imh\Childhood Predictability\Programs"



********************************************************************************

// Identifying Siblings

use "$data\registerdata19862022", clear
keep if year >= 2022
keep pnr year mor_id far_id 


foreach v in mor far {
	tostring `v'_id, replace format(%012.0f)
	replace `v'_id = "" if `v'_id == "."
}


// Saving siblings 
foreach p in mor far {
	preserve
	keep pnr year `p'_id
	drop if mi(`p'_id)
	by `p'_id, sort: gen child = _n
	rename pnr sibling_`p'
	reshape wide sibling_`p', i(`p'_id) j(child)
	duplicates drop 
	
	save "$data\Siblings `p'.dta", replace
	
	restore
}

merge m:1 mor_id year using "$data\Siblings mor.dta"
drop _merge 
merge m:1 far_id year using "$data\Siblings far.dta"
drop _merge

reshape long sibling_, i(pnr year) j(parent_n) string
rename sibling_ sibling_pnr
drop if mi(sibling_pnr)
*drop if pnr == sibling_pnr

drop mor_id far_id parent_n 
duplicates drop 
by pnr year, sort: egen n_siblings = count(sibling_pnr) 
replace n_siblings = n_siblings - 1

drop sibling_pnr 
duplicates drop 

save "$data\Siblings.dta", replace



********************************************************************************

// Identifying number of moves before age 18
use "$data\registerdata19862022.dta", clear
keep if alder <= 18
drop if mi(pnr)

keep pnr year adresse_id
tostring pnr, replace format(%012.0f)

egen tag = tag(pnr adresse_id)
egen n_adresse_id = total(tag), by(pnr)
drop tag 

keep pnr n_adresse_id
duplicates drop
save "$data\n_adresse.dta", replace


********************************************************************************

use "$data\registerdata19862022.dta", clear
/*
keep if alder == 16
keep pnr kom
rename kom kom_16
label var kom_16 "Municipality at age 16"
destring kom_16, replace 
duplicates drop 
duplicates tag pnr, gen(dup)
drop if dup == 1 		// 28 individuals dropped
drop dup
save "$data\kom_age_16.dta", replace
*/
keep if alder >= 18
keep if year >= 2004

do "$code\0.1 Registry Data.do"

// Number of siblings
merge 1:1 pnr year using "$data\Siblings.dta" 
drop if _merge == 2 
drop _merge 

// Municipality at age 16 
merge m:1 pnr using "$data\kom_age_16.dta"
drop if _merge == 2 
drop _merge 

// 9th Grade GPA
merge m:1 pnr using "$data\udfk_new.dta"
drop if _merge == 2 
drop _merge 


// Merging with parental information 
merge m:1 pnr using "$data\parents_outcomes.dta"
keep if _merge == 3
drop _merge 


save "$data\data_all_final.dta", replace
clear all


********************************************************************************

// Survey Respondents
use "Data\cohort_2004.dta", clear 

gen year = 2022
order pnr year 

do "$code\0.3 Survey Scores.do"


// Expected Earnings 
merge 1:1 pnr using "$data\earnings_by_edu.dta"
drop if _merge == 2
drop _merge


// Cognitive measures from 2024
merge 1:1 pnr using "$data\2024_cognitive.dta"
drop if _merge == 2 
drop _merge


// Registry data for 2004-2022
merge 1:1 pnr year using "$data\registerdata19862022.dta"	/* 477 individuals not matched */
drop if _merge == 2
drop _merge 

gen female = koen == 2

// Education
gen educode = afsp1e
replace educode = "" if h1 == "90"	// Unspecified

// Education 
destring h1, replace

sort pnr year 
gen educ_basic	= (h1 == 10 | h1 == 20 | h1 == 25)
gen educ_short	= (h1 == 35 | h1 == 40)
gen educ_med 	= (h1 == 50 | h1 == 60)
gen educ_long 	= (h1 == 65 | h1 == 70)

* Detailed Education Information 
lab var almaudd 	"Highest achieved general education"
lab var alm_vfra	"Date of graduation, general education"
lab var alminstnr	"Institution of general education"

lab var erhaudd 	"Highest achieved vocational education"
lab var erh_vfra	"Date of graduation, vocational education"
lab var erhinstnr	"Institution of vocational education"

lab var hfaudd 		"Highest achieved education"
lab var hf_vfra		"Date of graduation, highest achieved education"
lab var hfinstnr	"Institution of highest achieved education"

lab var udd			"Current education"
lab var ig_vfra		"Start of current education"
lab var iginstnr	"Institution of current education"

// Drop variables with all missing 
foreach var of varlist _all {
	* Count number of non-missing values for each variable 
	qui count if !mi(`var')
	* If the count of non-missing values is zero, drop the variable 
	if r(N) == 0 {
		di "`var'"
		drop `var'	/* Dropping 60 variables */
	}
}

// Number of siblings
merge 1:1 pnr year using "$data\Siblings.dta" 
drop if _merge == 2 
drop _merge 

// Municipality at age 16 
merge 1:1 pnr using "$data\kom_age_16.dta"			/* 928 individuals not matched */
drop if _merge == 2 
drop _merge 

// Number of adresses before age 18 
merge 1:1 pnr using "$data\n_adresse.dta" 			/* 418 individuals not matched */
drop if _merge == 2 
drop _merge 

// 9th Grade GPA
merge 1:1 pnr using "$data\udfk_new.dta"			/* 2,068 individuals not matched */
drop if _merge == 2 
drop _merge 

// Number of Schools (Folkeskoler)
merge 1:1 pnr using "$data\n_schools.dta"			/* 418 individuals not matched */
drop if _merge == 2 
drop _merge 

// Merging with parental information 
merge 1:1 pnr using "$data\parents_outcomes.dta"	/* 687 individuals not matched */
drop if _merge == 2 
drop _merge 

// Merging with Parental deaths 
foreach p in mor far { 
	rename pnr pnr_main 
	rename `p'_id pnr 
	merge m:1 pnr using "Data\dod20032022.dta"
	drop if _merge == 2 
	drop _merge 
	rename doddato `p'_doddato
	rename pnr `p'_id 
	rename pnr_main pnr 
}

// Mental Health 
merge 1:1 pnr year using "Data\mental_health.dta"
drop if _merge == 2
drop _merge 

replace anxiety_ever = 0 if anxiety_ever  == .
replace depression_ever = 0 if depression_ever  == .


save "$data\data_cohort2004_final.dta", replace

