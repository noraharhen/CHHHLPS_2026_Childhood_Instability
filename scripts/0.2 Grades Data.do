// Author: Ida Maria Hartmann
// Last edited: 31.07.2024

clear all
set more off

set scheme s1color
set linesize 255
capture log close
set matsize 10000

cd "P:\Workdata\707906\imh\Childhood Predictability"
global data "P:\Workdata\707906\imh\Childhood Predictability\Data"
global code	"P:\Workdata\707906\imh\Childhood Predictability\Programs"


use "Data\registerdata19862022.dta", clear
keep pnr alder foed_dag year
gen foed_aar = year(foed_dag)

keep pnr foed_aar
duplicates drop
drop if pnr == "."
duplicates drop pnr, force

merge 1:m pnr using "Data\udfk20112023.dta"
drop if _merge == 1
drop _merge 

order pnr year 
drop if mi(pnr)
tostring pnr, replace format(%012.0f)

gen school_year = substr(skoleaar,-4,4)
destring school_year, replace 

keep if kltrin == "09"
drop if grundskolekarakter == .

// Dropping duplicates
duplicates drop

// Checking remaining duplicates 
by pnr school_year, sort: gen N = _n
replace N = 0 if N != 1
by pnr, sort: egen count = sum(N)
tab count 	// 1.6 pct. of the sample recorded as having fininshed 9th grade 2-4 times 
drop if count > 1 
drop N count


// Average grades 
by pnr school_year, sort: egen gpa_all = mean(grundskolekarakter)
label var gpa_all "Average grades in all courses in 9th grade"

by pnr school_year, sort: egen temp_gpa_mde = mean(grundskolekarakter) if (grundskolefag == "Dansk" | grundskolefag == "Matematik" | grundskolefag == "Engelsk")
by pnr school_year, sort: egen gpa_mde = min(temp_gpa_mde)
label var gpa_mde "Average grades in danish, math and english, 9th grade"
by pnr school_year, sort: egen temp_gpa_exams = mean(grundskolekarakter) if grundskoleniveau == "FP9"
by pnr school_year, sort: egen gpa_exams = min(temp_gpa_exams)
label var gpa_exams "Average grades in all exams in 9th grade"
by pnr school_year, sort: egen temp_gpa_class = mean(grundskolekarakter) if grundskoleniveau == "Uopl"
by pnr school_year, sort: egen gpa_class = min(temp_gpa_class)
label var gpa_class "Average grades in all classes (standpunktskarakterer) in 9th grade"


// Grade Ranks (By Cohort) 
set seed 11
gen epsilon = runiform(0,1)/100
foreach var in all mde exams class { 
	gen gpa_`var'_eps = gpa_`var' + epsilon
	
	by foed_aar, sort: egen gpa_`var'_min = min(gpa_`var'_eps)
	by foed_aar, sort: egen gpa_`var'_max = max(gpa_`var'_eps)
	
	gen gpa_`var'_rank = 100 * (gpa_`var' - gpa_`var'_min)/(gpa_`var'_max - gpa_`var'_min)
}



keep pnr school_year gpa_mde gpa_all gpa_exams gpa_class gpa_mde_rank gpa_all_rank gpa_exams_rank gpa_class_rank
duplicates drop

save "Data\udfk_new.dta", replace

********************************************************************************

use "Data\registerdata19862022.dta", clear
keep pnr alder foed_dag year
order pnr year 
drop if mi(pnr)

keep pnr alder foed_dag year
keep if year(foed_dag) == 2004

tostring pnr, replace format(%012.0f)

merge 1:1 pnr year using "Data\udda19862022.dta"
drop if _merge == 2 
drop _merge 

// Highest Obtained Education
* 1006: 6th grade
* 1007: 7th grade
* 1008: 8th grade
* 1009: 9th grade
* 1010: 10th grade 
* 1011: 11th grade 
* 1098: Foreign high school exam 
* 1532: 2. hf 


gen folkeskole = . 
replace folkeskole = 0 if !mi(almaudd)
replace folkeskole = 1 if almaudd == 1106 | almaudd == 1107 | almaudd == 1108 | almaudd == 1109

gen efterskole = . 
replace efterskole = 0 if !mi()
replace efterskole = 1 if almaudd == 2508 | almaudd == 2509 | almaudd == 2510
egen tag = tag(pnr hfinstnr_c) if efterskole == 1
egen n_efterskole = total(tag), by(pnr)
drop tag

gen temp = year(hf_vfra) if hfaudd == 1109
replace temp = year(hf_vfra) if hfaudd == 2509 & mi(temp)
by pnr (year), sort: egen year_9th_grade = min(temp)
drop temp

// Number of elementary schools 
egen tag = tag(pnr iginstnr_c)
egen temp = total(tag) if (year(ig_vfra) < year_9th_grade & !mi(year_9th_grade) | year(ig_vfra) < 2020), by(pnr)
by pnr (year), sort: egen n_schools = min(temp)
drop tag temp

// Has the individual ever gone to efterskole? 
rename efterskole temp 
by pnr (year), sort: egen efterskole = max(temp)
drop temp

keep pnr year_9th_grade n_schools efterskole
duplicates drop 

duplicates report pnr	/* None */
save "Data\n_schools.dta", replace