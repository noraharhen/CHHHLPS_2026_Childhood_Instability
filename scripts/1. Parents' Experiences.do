// Author: Ida Maria Hartmann
// Last edited: 29.10.2024

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
order pnr year 
drop if mi(pnr)
tostring pnr, replace format(%012.0f)

save "Data\registerdata19862022.dta", replace


********************************************************************************

// Characteristics
use "Data\registerdata19862022.dta", clear
keep if alder >= 18

do "$code\0.1 Registry Data.do"


*tostring pnr, replace format(%012.0f)

keep pnr year alder antboernf civst e_faelle_id familie_type ie_type koen opr_land civstatus educode ///
	 perindkialt dispon_13 lejev_egen_bolig bankakt oblakt pantakt kursakt koejd ejendomsvurdering 	 ///
	 oblakt bankgaeld pantgaeld oblgaeld erhvervsindk_13 dagpenge_kontant_13 loenmv_13 grossinc 	 ///
	 off_overforsel_13 earnedinc dispinc house_val house_equity total_ass total_debt homeowner 		 ///
	 arledgr pstill psoc_status_kode wageearner selfemp out_labor student grossunemp netunemp 	 	 ///
	 arledgr_brutto arledgr_netto unemp unemp_month unemp_days ui d_akasse arb_sektorkode sector	 ///
	 educ_basic educ_short educ_med educ_long hfaudd hf_vfra educ_years ind1 ind2 ind3 ocp ocp1 	///
	 disco_kode

duplicates drop 
	
	 
save "Data\parental_characteristics.dta", replace 


********************************************************************************

// Adding Parental Characteristics to Child info
use "Data\registerdata19862022.dta", clear
keep if year(foed_dag) == 2004
keep pnr year alder mor_id far_id

tostring mor_id, replace format(%012.0f)
tostring far_id, replace format(%012.0f)
replace mor_id = "" if mor_id == "."
replace far_id = "" if far_id == "."

drop if mi(mor_id) & mi(far_id)

duplicates drop 
rename (mor_id far_id) (mor_pnr far_pnr)
rename (pnr alder) (barn_pnr barn_alder)


// Merging with information about parents 
foreach p in mor far {  
	rename `p'_pnr pnr 
	
	merge m:1 pnr year using "Data\parental_characteristics.dta"
	drop if _merge == 2 
	drop _merge 
	
	merge m:1 pnr year using "Data\mental_health.dta"
	drop if _merge == 2 
	drop _merge 
	
	rename pnr `p'_pnr
	local vars alder antboernf civst e_faelle_id familie_type ie_type koen opr_land						/// 
	bankakt bankgaeld dagpenge_kontant_13 dispon_13 ejendomsvurdering erhvervsindk_13 koejd kursakt 	///
	lejev_egen_bolig loenmv_13 oblakt oblgaeld off_overforsel_13 pantakt pantgaeld						/// 
	perindkialt_13 arb_sektorkode disco_kode arledgr_brutto arledgr_netto								/// 
	psoc_status_kode pstill hf_vfra hfaudd educ_years civstatus educode grossinc earnedinc				/// 
	dispinc house_val total_ass total_debt house_equity homeowner 										///
	wageearner selfemp out_labor student grossunemp netunemp unemp unemp_month 							///
	unemp_days ui d_akasse sector educ_basic educ_short educ_med educ_long								///
	ind1 ind2 ind3 ocp ocp1 																			///
	depression anxiety depression_ever anxiety_ever depression_first_age depression_first_year 			///
	anxiety_first_age anxiety_first_year

	rename (`vars') (`p'_=)
}

rename (barn_pnr barn_alder) (pnr alder) 
drop if mor_alder <= alder | far_alder <= alder	// 212 observations dropped

gen mor_foedalder = mor_alder - alder 
gen far_foedalder = far_alder - alder

drop if mor_foedalder < 15 | mor_foedalder > 65 & mor_foedalder != .	// 834,689 (0.7 pct. of) observations dropped 
drop if far_foedalder < 15 | far_foedalder > 65 & far_foedalder != . 	// 118,552 (0.1 pct. of) observations dropped 

// Considering only parental characteristics for individuals below the age of 18 
drop if alder > 18 | alder < 0

save "Data\parents_temp.dta", replace


// Consumer Price Index 
merge m:1 year using "Data\pris8.dta"
drop if _merge == 2 
drop _merge


// Counting number of parents 
foreach p in mor far {
	by pnr `p'_pnr (year), sort: gen N = _n
	replace N = 0 if N != 1 
	by pnr (year), sort: egen `p'_count = sum(N)
	drop N
}

sum mor_count, d 
sum far_count, d 

// Parent age at birth 
foreach p in mor far {
	gen temp = `p'_alder - alder if `p'_count == 1 
	by pnr (year), sort: egen `p'_alder_fodsel = min(temp)
	drop temp
}



// Indicator for parents married/living together 
gen parents_together = mor_e_faelle_id == far_pnr 

// Indicator for parents divorcing 
gen temp = 0 
replace temp = 1 if (mor_e_faelle_id[_n-1] == far_pnr[_n-1] & !mi(far_pnr[_n-1]) & mor_civstatus[_n-1] == 1) & mor_civstatus == 2
by pnr (year), sort: egen parents_divorced = max(temp)
drop temp

foreach p in mor far {
	gen `p'_temp = 0
	replace `p'_temp = 1 if `p'_civstatus == 2 
	by pnr (year), sort: egen `p'_divorced = max(`p'_temp)
	drop `p'_temp
}


// Indicator for parents splitting
gen temp = 0 
replace temp = 1 if (mor_e_faelle_id[_n-1] == far_pnr[_n-1] & !mi(far_pnr[_n-1])) & mor_e_faelle_id[_n] != far_pnr[_n]
by pnr (year), sort: egen parents_split = max(temp)
drop temp


// Number of Partners
foreach p in mor far {
	egen tag = tag(`p'_pnr `p'_e_faelle_id)
	egen `p'_n_partners_temp = total(tag), by(`p'_pnr)
	drop tag
	by pnr (`p'_pnr), sort: egen `p'_n_partners = max(`p'_n_partners_temp)
}


// Parental Education 
foreach p in mor far {
	gen temp = 0 
	replace temp = 4 if `p'_educ_long  == 1
	replace temp = 3 if `p'_educ_med   == 1 & temp == 0
	replace temp = 2 if `p'_educ_short == 1 & temp == 0
	replace temp = 1 if `p'_educ_basic == 1 & temp == 0
	
	by pnr (year), sort: egen `p'_educ = max(temp)
	replace `p'_educ = . if `p'_educ == 0
	drop temp
	
	// Accounting for missing observations in some years
	rename `p'_educ_years `p'_educ_years_temp
	by pnr (year), sort: egen `p'_educ_years = max(`p'_educ_years_temp)
	drop `p'_educ_years_temp
}

label define educ 1 "Basic" 2 "Short" 3 "Medium" 4 "Long"
label values mor_educ educ
label values far_educ educ

label var mor_educ "Mom's highest achieved education before child turned 18"
label var far_educ "Dad's highest achieved education before child turned 18"




// Unemployment Measures
foreach p in mor far {
	// Indicator for any unemployment before the age of 18  (mor_unemp mor_unemp_month mor_unemp_days)
	by pnr (year), sort: egen `p'_unemp_before18 = max(`p'_unemp)

	// Indicator for unemployment before the age of 5 
	by pnr (year), sort: egen temp = max(`p'_unemp) if alder < 5
	by pnr (year), sort: egen `p'_unemp_before5 = max(temp)
	drop temp

	// Indicator for unemployment between the ages of 5 and 15
	by pnr (year), sort: egen temp	 = max(`p'_unemp) if alder >= 5 & alder < 16
	by pnr (year), sort: egen `p'_unemp_ages515 = max(temp)
	drop temp 

	// Unemployed for more than 6 months 
	by pnr (year), sort: gen temp = `p'_unemp_days > 180 & !mi(`p'_unemp_days)
	by pnr (year), sort: egen `p'_unemp_6months = max(temp)
	drop temp
	
	// Number of days unemployed before the age of 18 
	by pnr (year), sort: egen `p'_unemp_days_total = sum(`p'_unemp_days)
	
	// Average annual number of days unemployed
	by pnr (year), sort: egen `p'_unemp_days_avg = mean(`p'_unemp_days)
}

// Sum of Parental Unemployment
gen parents_unemp_days = mor_unemp_days + far_unemp_days
by pnr (year), sort: egen parents_unemp_days_total = sum(parents_unemp_days)
by pnr (year), sort: egen parents_unemp_days_avg   = mean(parents_unemp_days)


// Earned Income Measures 
foreach p in mor far { 
	qui sum price_index if year == 2021
	global pi_2021 = r(mean)
	
	// Real Earned Income 
	gen `p'_earnedinc_real = (`p'_earnedinc * price_index)/$pi_2021
	
	// Average Annual Earnings 
	by pnr (year), sort: egen `p'_avg_earnedinc_real = mean(`p'_earnedinc_real)
	winsor2 `p'_avg_earnedinc_real, cuts(2 98)
	
	// Std. of Annual Earnings 
	by pnr (year), sort: egen `p'_sd_earnedinc_real = sd(`p'_earnedinc_real)
	gen `p'_cv_earnedinc_real = `p'_sd_earnedinc_real/`p'_avg_earnedinc_real
	winsor2 `p'_sd_earnedinc_real, cuts(2 98)
	winsor2 `p'_cv_earnedinc_real, cuts(2 98)
	
	// Real Gross Income 
	gen `p'_grossinc_real = (`p'_grossinc * price_index)/$pi_2021
	
	// Average Annual Gross Income 
	by pnr (year), sort: egen `p'_avg_grossinc_real = mean(`p'_grossinc_real)
	winsor2 `p'_avg_grossinc_real, cuts(2 98)
	
	// Std. and Coeffition of Variation of Annual Gross Income 
	by pnr (year), sort: egen `p'_sd_grossinc_real = sd(`p'_grossinc_real)
	gen `p'_cv_grossinc_real = `p'_sd_grossinc_real/`p'_avg_grossinc_real
	winsor2 `p'_sd_grossinc_real, cuts(2 98)
	winsor2 `p'_cv_grossinc_real, cuts(2 98)
	
	// Real Disposable Income 
	gen `p'_dispinc_real = (`p'_dispinc * price_index)/$pi_2021
	
	// Average Annual Disposable Income 
	by pnr (year), sort: egen `p'_avg_dispinc_real = mean(`p'_grossinc_real)
	winsor2 `p'_avg_dispinc_real, cuts(2 98)
	
	// Std. of Annual Disposable Income 
	by pnr (year), sort: egen `p'_sd_dispinc_real = sd(`p'_dispinc_real)
	gen `p'_cv_dispinc_real = `p'_sd_dispinc_real/`p'_avg_dispinc_real
	winsor2 `p'_sd_dispinc_real, cuts(2 98)
	winsor2 `p'_cv_dispinc_real, cuts(2 98)
	
	// Annual earnings growth 
	by pnr `p'_pnr (year), sort: gen `p'_earnedinc_growth = (`p'_earnedinc[_n] - `p'_earnedinc[_n-1])/`p'_earnedinc[_n-1] if `p'_wageearner[_n-1] == 1 & `p'_wageearner[_n] == 1
	winsor2 `p'_earnedinc_growth, by(year) cuts(2 98)
	
	// Average earnings growth 
	by pnr (year), sort: egen `p'_avg_earnedinc_growth = mean(`p'_earnedinc_growth)
	winsor2 `p'_avg_earnedinc_growth, cuts(2 98)
	
	// One-time earned income growth above 25 pct. (appr. average)
	by pnr (year), sort: gen temp = `p'_earnedinc_growth > 0.25 & `p'_wageearner[_n-1] == 1 & `p'_wageearner[_n] == 1
	by pnr (year), sort: egen `p'_high_earnedinc_growth = max(temp)
	drop temp 
	lab var `p'_high_earnedinc_growth "`p' saw income growth larger than 25 pct."
	
	// One-time negative income growth 
	by pnr (year), sort: gen temp = `p'_earnedinc_growth < -0.1 & `p'_wageearner[_n-1] == 1 & `p'_wageearner[_n] == 1
	by pnr (year), sort: egen `p'_neg_earnedinc_growth = max(temp)
	drop temp 
	lab var `p'_neg_earnedinc_growth "`p' saw negative income growth"
	
	// Real Public Benefits
	gen `p'_off_overforsel_real = (`p'_off_overforsel_13 * price_index)/$pi_2021
	
	// Average Public Benefits 
	by pnr (year), sort: egen `p'_avg_benefits_real = mean(`p'_off_overforsel_real)
	winsor2 `p'_avg_benefits_real, cuts(2 98)
	
	// Average Cash Benefits and Unemployment Insurance 
	gen `p'_dagpenge_kontant_real = (`p'_dagpenge_kontant_13 * price_index)/$pi_2021
	
	by pnr (year), sort: egen `p'_avg_dagpenge_kontant_real = mean(`p'_dagpenge_kontant_real)
	winsor2 `p'_avg_dagpenge_kontant_real, cuts(2 98)
}

// Sum of Parental Earnings
foreach var in earned gross disp {
	gen parents_`var'inc 	   = mor_`var'inc + far_`var'inc 
	gen parents_`var'inc_real = mor_`var'inc_real + far_`var'inc_real
	by pnr (year), sort: egen parents_avg_`var'inc_real = mean(parents_`var'inc_real)
	by pnr (year), sort: egen parents_sd_`var'inc_real = sd(parents_`var'inc_real)
	gen parents_cv_`var'inc_real = parents_sd_`var'inc_real/parents_avg_`var'inc_real
	winsor2 parents_`var'inc_real, cuts(2 98)
	winsor2 parents_avg_`var'inc_real, cuts(2 99)
	winsor2 parents_sd_`var'inc_real, cuts(2 99)
	winsor2 parents_cv_`var'inc_real, cuts(2 99)
}

// Parental Earnings Growth
by pnr (year), sort: gen parents_earnedinc_growth = (parents_earnedinc[_n] - parents_earnedinc[_n-1])/parents_earnedinc[_n-1] 
winsor2 parents_earnedinc_growth, by(year) cuts(2 98)
	
// Average earnings growth 
by pnr (year), sort: egen parents_avg_earnedinc_growth = mean(parents_earnedinc_growth)
winsor2 parents_avg_earnedinc_growth, cuts(2 98)

// Parental Income Standardized
foreach var in earned gross disp {
	sum mor_avg_`var'inc_real 
	gen mor_avg_`var'inc_std = (mor_avg_`var'inc_real - r(mean))/r(sd)
	
	sum far_avg_`var'inc_real 
	gen far_avg_`var'inc_std = (parents_avg_`var'inc_real - r(mean))/r(sd)
	
	sum parents_avg_`var'inc_real 
	gen parents_avg_`var'inc_std = (parents_avg_`var'inc_real - r(mean))/r(sd)
}



// Mental Health
foreach var in depression anxiety {
	foreach p in mor far {
		replace `p'_`var' = 0 if mi(`p'_`var')
		
		// Mental Health Issues when child is 0-18 years old
		rename `p'_`var' `p'_`var'_temp 
		by pnr (year), sort: egen `p'_`var'_0422 = max(`p'_`var'_temp)
		drop `p'_`var'_temp
		
		// Age at first diagnosis 
		rename `p'_`var'_first_age `p'_`var'_first_age_temp
		by pnr (year), sort: egen `p'_`var'_first_age = min(`p'_`var'_first_age_temp)
		drop `p'_`var'_first_age_temp
		
		// Year of first diagnosis
		rename `p'_`var'_first_year `p'_`var'_first_year_temp
		by pnr (year), sort: egen `p'_`var'_first_year = min(`p'_`var'_first_year_temp)
		drop `p'_`var'_first_year_temp
	}
}





// Keeping Averages 
keep pnr mor_count far_count mor_alder_fodsel far_alder_fodsel parents_divorced parents_split 						///
	 mor_educ mor_educ_years far_educ far_educ_years																///
	 mor_divorced far_divorced mor_unemp_before18 mor_unemp_before5 mor_unemp_ages515 mor_unemp_6months 			///
	 mor_unemp_days_total mor_unemp_days_avg far_unemp_before18 far_unemp_before5 far_unemp_ages515 				///
	 mor_n_partners far_n_partners far_unemp_6months far_unemp_days_total far_unemp_days_avg						///
	 mor_avg_earnedinc_real mor_avg_earnedinc_real_w far_avg_earnedinc_real far_avg_earnedinc_real_w				///
	 mor_avg_earnedinc_growth mor_avg_earnedinc_growth_w mor_high_earnedinc_growth mor_neg_earnedinc_growth  		///
	 mor_avg_grossinc_real mor_avg_grossinc_real_w mor_avg_dispinc_real mor_avg_dispinc_real_w 						///
	 far_avg_grossinc_real far_avg_grossinc_real_w far_avg_dispinc_real far_avg_dispinc_real_w 						///
	 mor_avg_benefits_real mor_avg_benefits_real_w mor_avg_dagpenge_kontant_real mor_avg_dagpenge_kontant_real_w 	///
	 far_avg_earnedinc_growth far_avg_earnedinc_growth_w far_high_earnedinc_growth far_neg_earnedinc_growth 		///
	 far_avg_dagpenge_kontant_real far_avg_dagpenge_kontant_real_w far_avg_benefits_real far_avg_benefits_real_w	///		
	 mor_sd_* far_sd_* mor_cv_* far_cv_* parents_avg_earnedinc_real parents_avg_earnedinc_real_w 					///
	 parents_avg_grossinc_real parents_avg_grossinc_real_w	 														///
	 parents_avg_dispinc_real parents_avg_dispinc_real_w	 														///
	 parents_avg_earnedinc_growth parents_avg_earnedinc_growth_w parents_sd_* parents_cv_*							///
	 parents_unemp_days_total parents_unemp_days_avg																///
	 mor_avg_dispinc_std mor_avg_earnedinc_std mor_avg_grossinc_std													///
	 far_avg_dispinc_std far_avg_earnedinc_std far_avg_grossinc_std													///
	 parents_avg_dispinc_std parents_avg_earnedinc_std parents_avg_grossinc_std										///
	 mor_depression_0422 far_depression_0422 mor_anxiety_0422 far_anxiety_0422										///
	 mor_depression_first_age mor_depression_first_year far_depression_first_age far_depression_first_year 			///
	 mor_anxiety_first_age mor_anxiety_first_year far_anxiety_first_age far_anxiety_first_year
	 
duplicates drop

// Income Ranks 
set seed 11
gen epsilon = runiform(0,1)/10
foreach var in earned gross disp {
	foreach p in mor far parents {
		gen `p'_`var'inc_eps = `p'_avg_`var'inc_real + epsilon
		
		egen `p'_`var'inc_min = min(`p'_`var'inc_eps)
		egen `p'_`var'inc_max = max(`p'_`var'inc_eps)
	
		gen `p'_`var'inc_rank = 100 * (`p'_`var'inc_eps - `p'_`var'inc_min)/(`p'_`var'inc_max - `p'_`var'inc_min)
	}
	

}

drop epsilon mor_earnedinc_eps mor_dispinc_eps mor_grossinc_eps far_earnedinc_eps far_dispinc_eps far_grossinc_eps parents_earnedinc_eps parents_dispinc_eps parents_grossinc_eps
drop mor_earnedinc_min mor_dispinc_min mor_grossinc_min far_earnedinc_min far_dispinc_min far_grossinc_min parents_earnedinc_min parents_dispinc_min parents_grossinc_min
drop mor_earnedinc_max mor_dispinc_max mor_grossinc_max far_earnedinc_max far_dispinc_max far_grossinc_max parents_earnedinc_max parents_dispinc_max parents_grossinc_max


save "Data\parents_outcomes.dta", replace