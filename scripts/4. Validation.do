// Author: Ida Maria Hartmann
// Last edited: 16.09.2025

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

use "$data\data_cohort2004_final.dta", clear 

********************************************************************************

keep if ResponseStatus == "Completed"
drop if timetakenseconds < 300 

gen household_stable_num = .
replace household_stable_num = 0 if household_stable == "Nej"
replace household_stable_num = 1 if household_stable == "Ja"

gen par_avg_dagpenge_kontant_real   = mor_avg_dagpenge_kontant_real + far_avg_dagpenge_kontant_real
gen par_avg_dagpenge_kontant_real_w = mor_avg_dagpenge_kontant_real_w + far_avg_dagpenge_kontant_real_w
gen parents_avg_benefits_real 	  = mor_avg_benefits_real + far_avg_benefits_real


// Capping of variables is done for privacy reasons, to ensure min. 5 observations in each cell.
// Capping unemployment at 900 days
foreach p in mor far parents {
	gen `p'_unemp_cap = `p'_unemp_days_total
	replace `p'_unemp_cap = 600 if `p'_unemp_days_total > 600
}


// Capping unemployment benefits at 100 000 DKK 
foreach p in mor far par { 
	gen `p'_dagpenge_kontant_cap = `p'_avg_dagpenge_kontant_real
	replace `p'_dagpenge_kontant_cap = 100000 if `p'_avg_dagpenge_kontant_real > 100000
	replace `p'_dagpenge_kontant_cap = 0 if `p'_avg_dagpenge_kontant_real < 0
}

foreach p in mor far { 
	gen `p'_avg_benefits_cap = `p'_avg_benefits_real
	replace `p'_avg_benefits_cap = 150000 if `p'_avg_benefits_real > 150000
	replace `p'_avg_benefits_cap = 0 if `p'_avg_benefits_real < 0
}

gen parents_avg_benefits_cap = parents_avg_benefits_real
replace parents_avg_benefits_cap = 200000 if parents_avg_benefits_real > 200000
replace parents_avg_benefits_cap = 0 if parents_avg_benefits_real < 0



// Capping earned income at 1 000 000 DKK 
foreach p in mor far { 
	gen `p'_earnedinc_cap = `p'_avg_earnedinc_real_w
	replace `p'_earnedinc_cap = 600000 if `p'_avg_earnedinc_real_w > 600000
	
	gen `p'_grossinc_cap = `p'_avg_grossinc_real_w
	replace `p'_grossinc_cap = 600000 if `p'_avg_grossinc_real_w > 600000
	
	gen `p'_dispinc_cap = `p'_avg_dispinc_real_w
	replace `p'_dispinc_cap = 600000 if `p'_avg_dispinc_real_w > 600000
}

gen parents_earnedinc_cap = parents_avg_earnedinc_real_w
replace parents_earnedinc_cap = 1000000 if parents_avg_earnedinc_real_w > 1000000


gen parents_grossinc_cap = parents_avg_grossinc_real_w
replace parents_grossinc_cap = 1000000 if parents_avg_grossinc_real_w > 1000000

gen parents_dispinc_cap = parents_avg_dispinc_real_w
replace parents_dispinc_cap = 800000 if parents_avg_dispinc_real_w > 800000


// Capping CV measures at 1.5 
foreach p in mor far parents {
	gen `p'_cv_earnedinc_cap = `p'_cv_earnedinc_real_w
	replace `p'_cv_earnedinc_cap = 1.0 if `p'_cv_earnedinc_real_w > 1.0
	
	gen `p'_cv_grossinc_cap = `p'_cv_grossinc_real_w
	replace `p'_cv_grossinc_cap = 0.6 if `p'_cv_grossinc_real_w > 0.6
	
	gen `p'_cv_dispinc_cap = `p'_cv_grossinc_real_w
	replace `p'_cv_dispinc_cap = 0.6 if `p'_cv_grossinc_real_w > 0.6
}
	

********************************************************************************

// Demographics
tab gender if koen == 1
tab gender if koen == 2


********************************************************************************


// QUIC Questions

// Parental Environment 
* QUIC_3_1: Prior to age 18: There was a long period of time when I didn't see one of my parents. 
* QUIC_3_2: Prior to age 18: I experienced changes in my custody arrangement.
* QUIC_3_3: Prior to age 18: There were times when one of my parents was unemployed and couldn't find a job even though he/she wanted one. 
sum mor_unemp_days_total if QUIC_3_3 == 0
sum mor_unemp_days_total if QUIC_3_3 == 1

sum far_unemp_days_total if QUIC_3_3 == 0
sum far_unemp_days_total if QUIC_3_3 == 1


// Bar Graphs
preserve 

collapse (mean) mor_unemp_days_total far_unemp_days_total (sd) sd_mor = mor_unemp_days_total sd_far = far_unemp_days_total (count) mor_n = mor_unemp_days_total far_n = far_unemp_days_total, by(QUIC_3_3)

foreach var in mor far {
	gen `var'_hi = `var'_unemp_days_total + invttail(`var'_n-1,0.025)*(sd_`var'/sqrt(`var'_n))
	gen `var'_lo = `var'_unemp_days_total - invttail(`var'_n-1,0.025)*(sd_`var'/sqrt(`var'_n))
	
	sum `var'_n if QUIC_3_3 == 0 
	local no = r(mean)
	sum `var'_n if QUIC_3_3 == 1
	local yes = r(mean)
	
	// Bar graph
	local mor_text = "Mom"
	local far_text = "Dad"
	graph twoway (bar `var'_unemp_days_total QUIC_3_3, color(gs12)) 			///
		  (rcap `var'_hi `var'_lo QUIC_3_3, lcolor(cranberry)),					///
		  xlabels(0 "No (N = `no')" 1 "Yes (N = `yes')", labsize(med)) 			///
		  ylabels(0(100)500) legend(off) name(`var', replace)					///
		  ytitle("``var'_text''s Unemployment (Days)", size(med))				///
		  xtitle("Prior to age 18: There were times when one of my parents was unemployed" "and couldn't find a job even though he/she wanted one", size(med))
	graph export "Figures\QUIC_3_3_`var'_unemp.pdf", replace
	
}

restore 

// Histogram: Both Parents
forvalues x = 0(30)600 { 
	local y = `x' + 30
	di "`x' - `y' number of days unemployed"
	count if parents_unemp_cap >= `x' & parents_unemp_cap < `y' & QUIC_3_3 == 0 
	count if parents_unemp_cap >= `x' & parents_unemp_cap < `y' & QUIC_3_3 == 1
}

count if QUIC_3_3 == 0
global no = r(N)
count if QUIC_3_3 == 1
global yes = r(N)

twoway (hist parents_unemp_cap if QUIC_3_3 == 0 & parents_unemp_cap <= 600,		///
		frac lcolor(gs15) fcolor(gs12) start(0) width(30))						///
	   (hist parents_unemp_cap if QUIC_3_3 == 1 & parents_unemp_cap <= 600,		///
	    frac lcolor(cranberry) fcolor(none) start(0) width(30)),				/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") 						///
	   cols(1) pos(2) ring(0)) xlabels(0(100)500 585 "600+") 					///
	   ylabels(0(0.1)0.5) name(QUIC_3_3_both, replace)							///
	   xtitle("Both Parents: Total Number of Days Unemployed") 					///
	   note("All bars based on min. 5 observations", size(small)) 				
graph export "Figures\validation_QUIC_3_3_unemployment_both.pdf", replace






// Histograms: QUIC_3_3 vs. Cash Benefits and UI
forvalues x = 0(5000)100000 { 
	local y = `x' + 5000
	di "`x' - `y' number of days unemployed"
	count if par_dagpenge_kontant_cap >= `x' & par_dagpenge_kontant_cap < `y' & QUIC_3_3 == 0 
	count if par_dagpenge_kontant_cap >= `x' & par_dagpenge_kontant_cap < `y' & QUIC_3_3 == 1
}

count if QUIC_3_3 == 0 
global no = r(N)
count if QUIC_3_3 == 1 
global yes = r(N)

twoway (hist par_dagpenge_kontant_cap if QUIC_3_3 == 0,								///
		frac lcolor(gs15) fcolor(gs12) start(0) width(4999))						///
	   (hist par_dagpenge_kontant_cap if QUIC_3_3 == 1,								///
	    frac lcolor(cranberry) fcolor(none) start(0) width(4999)),					///
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Both Parents: Avg. Annual Cash Benefits and UI (2021 DKK)") 			///
	   xlabels(0(20000)80000 100000 "100 000+")											///
	   name(QUIC_3_3_ui_both, replace)												///						
	   note("All bars based on min. 9 observations", size(small)) 
graph export "Figures\validation_QUIC_3_3_ui_both.pdf", replace



********************************************************************************

* QUIC_3_4: Prior to age 18: My parents had a stable relationship with each other. 
* QUIC_3_5: Prior to age 18: My parents got divorced.
sum parents_divorced if QUIC_3_5 == 0
sum parents_divorced if QUIC_3_5 == 1

sum parents_split if QUIC_3_5 == 0
sum parents_split if QUIC_3_5 == 1


preserve 

collapse (mean) parents_split (sd) sd = parents_split (count) n = parents_split, by(QUIC_3_5)

	gen hi = parents_split + invttail(n-1,0.025)*(sd/sqrt(n))
	gen lo = parents_split - invttail(n-1,0.025)*(sd/sqrt(n))

	sum n if QUIC_3_5 == 0 
	local no = r(mean)
	sum n if QUIC_3_5 == 1
	local yes = r(mean)
	
	// Bar graph
	graph twoway (bar parents_split QUIC_3_5, color(gs12)) 						///
		  (rcap hi lo QUIC_3_5, lcolor(cranberry)),								///
		  xlabels(0 "No (N = `no')" 1 "Yes (N = `yes')", labsize(med)) 			///
		  ylabels(0.0(0.2)1.0) legend(off) 										///
		  ytitle("Parents Split (Fraction)", size(med)) name(both, replace)		///
		  xtitle("Prior to age 18: My parents got divorced", size(med))				
	graph export "Figures\QUIC_3_5_split.pdf", replace

restore 


* QUIC_3_6: Prior to age 18: At least one of my parents had many romantic partners.
tab mor_n_partners if QUIC_3_6 == 0 
tab mor_n_partners if QUIC_3_6 == 1

tab far_n_partners if QUIC_3_6 == 0 
tab far_n_partners if QUIC_3_6 == 1


// Bar Graphs 
preserve 

collapse (mean) mor_n_partners far_n_partners (sd) sd_mor = mor_n_partners sd_far = far_n_partners (count) mor_n = mor_n_partners far_n = far_n_partners, by(QUIC_3_6)

foreach var in mor far {
	gen `var'_hi = `var'_n_partners + invttail(`var'_n-1,0.025)*(sd_`var'/sqrt(`var'_n))
	gen `var'_lo = `var'_n_partners - invttail(`var'_n-1,0.025)*(sd_`var'/sqrt(`var'_n))

	sum `var'_n if QUIC_3_6 == 0 
	local no = r(mean)
	sum `var'_n if QUIC_3_6 == 1
	local yes = r(mean) 
	
	// Bar graph
	local mor_text = "Mom"
	local far_text = "Dad"
	graph twoway (bar `var'_n_partners QUIC_3_6, color(gs12)) 					///
		  (rcap `var'_hi `var'_lo QUIC_3_6, lcolor(cranberry)),					///
		  xlabels(0 "No (N = `no')" 1 "Yes (N = `yes')", labsize(med)) 			///
		  ylabels(0(0.5)2) legend(off) name(`var', replace)						///
		  ytitle("``var'_text''s Number of Partners", size(med))				///
		  xtitle("Prior to age 18: At least one of my parents had many romantic partners", size(med))
	graph export "Figures\QUIC_3_6_`var'_partners.pdf", replace
	
}

restore 


count if QUIC_3_6 == 0 
global no = r(N)
count if QUIC_3_6 == 1 
global yes = r(N)

preserve 
	contract mor_n_partners 
	sum _freq, meanonly 
	global min = r(min)
restore 

twoway (hist mor_n_partners if QUIC_3_6 == 0 & mor_n_partners <= 2, 				///
		frac lcolor(gs15) fcolor(gs12) start(-0.5) width(1))						///
	   (hist mor_n_partners if QUIC_3_6 == 1 & mor_n_partners <= 4, 				///
	    frac lcolor(cranberry) fcolor(none) start(-0.5) width(1)),					/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xlabels(0(2)6) xtitle("Mom: Number of Partners") name(QUIC_3_6_mor, replace)	///
	   note("All bars based on min. 7 observations", size(small))
graph export "Figures\validation_QUIC_3_6_mom.pdf", replace

twoway (hist far_n_partners if QUIC_3_6 == 0 & far_n_partners <= 2, 				///
		frac lcolor(gs15) fcolor(gs12) start(-0.5) width(1))						///
	   (hist far_n_partners if QUIC_3_6 == 1 & far_n_partners <= 5,					///
		frac lcolor(cranberry) fcolor(none) start(-0.5) width(1)),					/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Dad: Number of Partners") name(QUIC_3_6_far, replace)   				///
	   note("All bars based on min. 5 observations", size(small))
graph export "Figures\validation_QUIC_3_6_dad.pdf", replace
	   
graph combine QUIC_3_6_mor QUIC_3_6_far 												
graph export "Figures\validation_QUIC_3_6.pdf", replace



********************************************************************************

// Physical Environment
* QUIC_4_2: Prior to age 18: I moved frequently. 
tab n_adresse_id if QUIC_4_2 == 0
tab n_adresse_id if QUIC_4_2 == 1

sum n_adresse_id if QUIC_4_2 == 0
sum n_adresse_id if QUIC_4_2 == 1


preserve 

collapse (mean) n_adresse_id (sd) sd = n_adresse_id (count) n = n_adresse_id, by(QUIC_4_2)

	gen hi = n_adresse_id + invttail(n-1,0.025)*(sd/sqrt(n))
	gen lo = n_adresse_id - invttail(n-1,0.025)*(sd/sqrt(n))

	sum n if QUIC_4_2 == 0 
	local no = r(mean)
	sum n if QUIC_4_2 == 1
	local yes = r(mean)
	
	// Bar graph
	graph twoway (bar n_adresse_id QUIC_4_2, color(gs12)) 						///
		  (rcap hi lo QUIC_4_2, lcolor(cranberry)),								///
		  xlabels(0 "No (N = `no')" 1 "Yes (N = `yes')", labsize(med))			///
		  ytitle("Number of Residential Adresses", size(med)) 					///
		  ylabels(1(1)5) legend(off) name(QUIC_4_2, replace)					///
		  xtitle("Prior to age 18: I moved frequently", size(med))								
	graph export "Figures\QUIC_4_2_nadresses.pdf", replace

restore 


count if QUIC_4_2 == 0 
global no = r(N)
count if QUIC_4_2 == 1 
global yes = r(N)

twoway (hist n_adresse_id if QUIC_4_2 == 0 & n_adresse_id <= 8, 					///
		frac lcolor(gs15) fcolor(gs12) start(0.5) width(1))							///
	   (hist n_adresse_id if QUIC_4_2 == 1 & n_adresse_id <= 10,					///
	    frac lcolor(cranberry) fcolor(none) start(0.5) width(1)),					/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	/// 
	   xlabels(2(2)10) xtitle("Number of Residential Adresses before Age 18") 		///
	   note("All bars based on min. 7 observations", size(small)) 					///
	   name(QUIC_4_2, replace) 
graph export "Figures\validation_QUIC_4_2.pdf", replace




* QUIC_4_3: Prior to age 18: I changed schools frequently.
tab n_schools if QUIC_4_3 == 0
tab n_schools if QUIC_4_3 == 1

sum n_schools if QUIC_4_3 == 0
sum n_schools if QUIC_4_3 == 1


preserve 

collapse (mean) n_schools (sd) sd = n_schools (count) n = n_schools, by(QUIC_4_3)

	gen hi = n_schools + invttail(n-1,0.025)*(sd/sqrt(n))
	gen lo = n_schools - invttail(n-1,0.025)*(sd/sqrt(n))

	sum n if QUIC_4_3 == 0 
	local no = r(mean)
	sum n if QUIC_4_3 == 1
	local yes = r(mean)
	
	// Bar graph
	graph twoway (bar n_schools QUIC_4_3, color(gs12)) 							///
		  (rcap hi lo QUIC_4_3, lcolor(cranberry)),								///
		  xlabels(0 "No (N = `no')" 1 "Yes (N = `yes')", labsize(med)) 			///
		  ytitle("Number of Schools", size(med)) 								///
		  ylabels(0(1)4) legend(off) name(QUIC_4_2, replace)					///
		  xtitle("Prior to age 18: I changed schools frequently", size(med))					
	graph export "Figures\QUIC_4_3_nschools.pdf", replace

restore 


count if QUIC_4_3 == 0 
global no = r(N)
count if QUIC_4_3 == 1 
global yes = r(N)

twoway (hist n_schools if QUIC_4_3 == 0 & n_schools <= 4, 							///
		frac lcolor(gs15) fcolor(gs12) start(0.5) width(1))							///
	   (hist n_schools if QUIC_4_3 == 1 & n_schools <= 5,							///
	    frac lcolor(cranberry) fcolor(none) start(0.5) width(1)),					/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///  
	   xlabels(1(1)5) xtitle("Number of Elementary Schools (Grades 0-9)")    		///
	   note("All bars based on min. 16 observations", size(small)) 					///
	   name(QUIC_4_2, replace)
graph export "Figures\validation_QUIC_4_3.pdf", replace



********************************************************************************


// Safety and Security 
* QUIC_5_2: Prior to age 18: There was a period of time when I often worried that my family would not have enough money to pay for necessities like clothing or bills. 
sum mor_avg_dispinc_real if QUIC_5_2 == 0 
sum mor_avg_dispinc_real if QUIC_5_2 == 1

sum far_avg_dispinc_real if QUIC_5_2 == 0 
sum far_avg_dispinc_real if QUIC_5_2 == 1

sum parents_avg_dispinc_real if QUIC_5_2 == 0 
sum parents_avg_dispinc_real if QUIC_5_2 == 1

sum parents_cv_dispinc_real if QUIC_5_2 == 0 
sum parents_cv_dispinc_real if QUIC_5_2 == 1


foreach var in disp gross {
	local disp_text  = "Disposable"
	local gross_text = "Gross"
	
	local disp_y  = "ylabels(200000(100000)500000)"
	local gross_y = "ylabels(500000(100000)900000)"
	
	preserve 

	collapse (mean) parents_avg_`var'inc_real (sd) sd = parents_avg_`var'inc_real (count) n = parents_avg_`var'inc_real, by(QUIC_5_2)

		gen hi = parents_avg_`var'inc_real + invttail(n-1,0.025)*(sd/sqrt(n))
		gen lo = parents_avg_`var'inc_real - invttail(n-1,0.025)*(sd/sqrt(n))

		sum n if QUIC_5_2 == 0 
		local no = r(mean)
		sum n if QUIC_5_2 == 1
		local yes = r(mean)
		
		// Bar graph
		graph twoway (bar parents_avg_`var'inc_real QUIC_5_2, color(gs12)) 		///
			  (rcap hi lo QUIC_5_2, lcolor(cranberry)),							///
			  xlabels(0 "No (N = `no')" 1 "Yes (N = `yes')", labsize(med))	 	///
			  ytitle("Avg. Parental ``var'_text' Income (DKK)", size(med)) 		///
			  ``var'_y' legend(off) name(QUIC_5_2_`var', replace)				///
			  xtitle("Prior to age 18: There was a period of time when I often worried that my family" "would not have enough money to pay for necessities like clothing or bills", size(med))				
		graph export "Figures\QUIC_5_2_parental_`var'inc.pdf", replace

	restore 
}




// Histogram: Gross/Disposable Income, Both Parents
forvalues x = 0(100000)1900000 { 
	local y = `x' + 100000
	di "`x' - `y' DKK in Gross Income"
	count if parents_avg_grossinc_real >= `x' & parents_avg_grossinc_real < `y' & QUIC_5_2 == 0 
	count if parents_avg_grossinc_real >= `x' & parents_avg_grossinc_real < `y' & QUIC_5_2 == 1
}

count if QUIC_5_2 == 0 
global no = r(N)
count if QUIC_5_2 == 1 
global yes = r(N)

twoway (hist parents_avg_grossinc_real if QUIC_5_2 == 0								///
		& parents_avg_grossinc_real >= 200000										/// 
		& parents_avg_grossinc_real < 2000000,										///
		frac lcolor(gs15) fcolor(gs12) start(0) width(100000))						///
	   (hist parents_avg_grossinc_real if QUIC_5_2 == 1 							///
		& parents_avg_grossinc_real >= 200000										/// 
		& parents_avg_grossinc_real < 1100000,										///
	    frac lcolor(cranberry) fcolor(none) start(0) width(100000)),				/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Both Parents: Avg. Annual Gross Income (2021 DKK)") 					///
	   name(QUIC_5_2_gross_both, replace)											///						
	   note("All bars based on min. 5 observations. Avg. gross income winsorized at 2nd and 98th percentiles, at the population level.", size(vsmall)) 
graph export "Figures\validation_QUIC_5_2_grossinc_both.pdf", replace




// Histogram: Disposable Income, Both Parents
forvalues x = 0(100000)1300000 { 
	local y = `x' + 100000
	di "`x' - `y' DKK in Disposable Income"
	count if parents_avg_dispinc_real >= `x' & parents_avg_dispinc_real < `y' & QUIC_5_2 == 0 
	count if parents_avg_dispinc_real >= `x' & parents_avg_dispinc_real < `y' & QUIC_5_2 == 1
}

count if QUIC_5_2 == 0 
global no = r(N)
count if QUIC_5_2 == 1 
global yes = r(N)

twoway (hist parents_avg_dispinc_real if QUIC_5_2 == 0								///
		& parents_avg_dispinc_real >= 100000 										///
		& parents_avg_dispinc_real < 1400000,										///
		frac lcolor(gs15) fcolor(gs12) start(0) width(100000))						///
	   (hist parents_avg_dispinc_real if QUIC_5_2 == 1 								///
		& parents_avg_dispinc_real >= 100000 										///
		& parents_avg_dispinc_real < 800000,										///
	    frac lcolor(cranberry) fcolor(none) start(0) width(100000)),				/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Both Parents: Avg. Annual Disposable Income (2021 DKK)") 			///
	   name(QUIC_5_2_disp_both, replace)											///						
	   note("All bars based on min. 5 observations. Avg. disposable income winsorized at 2nd and 98th percentiles, at the population level.", size(vsmall)) 
graph export "Figures\validation_QUIC_5_2_dispinc_both.pdf", replace



********************************************************************************

// Childhood Financial Stress
* QUIC_6_1: Prior to age 18: I experienced financial stress in my household. 
sum mor_avg_dispinc_real if QUIC_6_1 == 0 
sum mor_avg_dispinc_real if QUIC_6_1 == 1

sum mor_avg_dispinc_real if QUIC_6_1 == 0 
sum mor_avg_dispinc_real if QUIC_6_1 == 1

sum mor_avg_dispinc_real if QUIC_6_1 == 0 
sum mor_avg_dispinc_real if QUIC_6_1 == 1


// Histogram: Disposable Income, Both Parents
forvalues x = 0(100000)1300000 { 
	local y = `x' + 100000
	di "`x' - `y' DKK in Disposable Income"
	count if parents_avg_dispinc_real >= `x' & parents_avg_dispinc_real < `y' & QUIC_6_1 == 0 
	count if parents_avg_dispinc_real >= `x' & parents_avg_dispinc_real < `y' & QUIC_6_1 == 1
}

count if QUIC_6_1 == 0 
global no = r(N)
count if QUIC_6_1 == 1 
global yes = r(N)

twoway (hist parents_avg_dispinc_real if QUIC_6_1 == 0								///
		& parents_avg_dispinc_real >= 200000										/// 
		& parents_avg_dispinc_real < 1400000,										///
		frac lcolor(gs15) fcolor(gs12) start(0) width(100000))						///
	   (hist parents_avg_dispinc_real if QUIC_6_1 == 1 								///
		& parents_avg_dispinc_real >= 200000										/// 
		& parents_avg_dispinc_real < 800000,										///
	    frac lcolor(cranberry) fcolor(none) start(0) width(100000)),				/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Both Parents: Avg. Annual Disposable Income (2021 DKK)") 			///
	   name(QUIC_6_1_disp_both, replace)											///						
	   note("All bars based on min. 5 observations. Avg. disposable income winsorized at 2nd and 98th percentiles, at the population level.", size(vsmall)) 
graph export "Figures\validation_QUIC_6_1_dispinc_both.pdf", replace



********************************************************************************

* QUIC_6_5: Prior to age 18: My parents primarily relied on social benefits. 
sum mor_avg_benefits_real if QUIC_6_5 == 0
sum mor_avg_benefits_real if QUIC_6_5 == 1

sum far_avg_benefits_real if QUIC_6_5 == 0
sum far_avg_benefits_real if QUIC_6_5 == 1

sum parents_avg_benefits_real if QUIC_6_5 == 0
sum parents_avg_benefits_real if QUIC_6_5 == 1

// Histograms: Public Benefits
forvalues x = 0(25000)325000 { 
	local y = `x' + 25000
	di "`x' - `y' DKK"
	count if parents_avg_benefits_real >= `x' & parents_avg_benefits_real < `y' & QUIC_6_5 == 0 
	count if parents_avg_benefits_real >= `x' & parents_avg_benefits_real < `y' & QUIC_6_5 == 1
}

count if QUIC_6_5 == 0 
global no = r(N)
count if QUIC_6_5 == 1 
global yes = r(N)

twoway (hist mor_avg_benefits_real if QUIC_6_5 == 0 								///
		& mor_avg_benefits_real <= 300000, 											///
		frac lcolor(gs15) fcolor(gs12) start(0) width(25000))						///
	   (hist mor_avg_benefits_real if QUIC_6_5 == 1 								///
	    & mor_avg_benefits_real >= 25000 & mor_avg_benefits_real <= 350000, 		///
	    frac lcolor(cranberry) fcolor(none) start(0) width(25000)),					/// 
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Both Parents: Avg. Annual Benefits (2021 DKK)", margin(small)) 		///
	   note("All bars based on min. 6 observations", size(small)) 					///
	   name(QUIC_6_5_mor, replace)									
graph export "Figures\validation_QUIC_6_5_benefits_both.pdf", replace



// Histograms: UI and Cash Benefits
forvalues x = 0(20000)240000 { 
	local y = `x' + 20000
	di "`x' - `y' number of days unemployed"
	count if parents_avg_dagpenge_kontant >= `x' & parents_avg_dagpenge_kontant < `y' & QUIC_6_5 == 0 
	count if parents_avg_dagpenge_kontant >= `x' & parents_avg_dagpenge_kontant < `y' & QUIC_6_5 == 1
}

count if QUIC_6_5 == 0 
global no = r(N)
count if QUIC_6_5 == 1 
global yes = r(N)

twoway (hist parents_avg_dagpenge_kontant if QUIC_6_5 == 0							///
		& parents_avg_dagpenge_kontant < 220000										///
		& parents_avg_dagpenge_kontant >= 0,										///
		frac lcolor(gs15) fcolor(gs12) start(0) width(10000))						///
	   (hist parents_avg_dagpenge_kontant if QUIC_6_5 == 1							///
		& parents_avg_dagpenge_kontant < 240000										///
		& parents_avg_dagpenge_kontant >= 0,										///
	    frac lcolor(cranberry) fcolor(none) start(0) width(10000)),					///
	   legend(order(1 "No (N = $no)" 2 "Yes (N = $yes)") cols(1) pos(2) ring(0)) 	///
	   xtitle("Both Parents: Avg. Annual Cash Benefits and UI (2021 DKK)") 			///
	   name(QUIC_6_5_ui_both, replace)												///						
	   note("All bars based on min. 8 observations", size(small)) 
graph export "Figures\validation_QUIC_6_5_ui_both.pdf", replace


