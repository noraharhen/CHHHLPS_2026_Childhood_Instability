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

merge 1:1 pnr year using "Data\mental_health.dta"
drop if _merge == 2
drop _merge 


********************************************************************************

keep if ResponseStatus == "Completed"
drop if timetakenseconds < 300 

// Parental earnings in 1000 DKK
foreach var in disp gross earned {
	gen parents_avg_`var'inc_1000 = parents_avg_`var'inc_real_w/1000
	gen parents_avg_`var'inc_100k = parents_avg_`var'inc_real_w/100000
}

gen parents_unemp_months_total = parents_unemp_days_total/30.44

// High School 
gen high_school = 0 
replace high_school = 1 if gymnasie == "Fuldfør"

// Standardizing Cognitive Scores 
foreach var in cognitive_score math_score raven_score { 
	sum `var'
	gen `var'_std = (`var' - r(mean))/(r(sd))
}

// Normalized Variables
foreach var in mor_n_partners far_n_partners n_adresse_id n_schools parents_unemp_days_total {
	sum `var'
	gen `var'_norm = (`var' - r(min))/(r(max) - r(min))
}

foreach var in parents_avg_grossinc parents_sd_grossinc {
	sum `var'_real_w
	gen `var'_norm = (`var'_real_w - r(min))/(r(max) - r(min))
}


// QUIC Percentiles 
gen eps = rnormal(0,1)*0.001
gen QUIC_temp = QUIC_38_score + eps

xtile quic_quart = QUIC_temp, nq(4)
xtile quic_quint = QUIC_temp, nq(5)
drop eps QUIC_temp


// Registry Based QUIC (Simple)
gen QUIC_reg = parents_split + mor_n_partners_norm + far_n_partners_norm + 		///
	n_adresse_id_norm +	n_schools_norm + parents_unemp_days_total_norm - 		///
	parents_avg_grossinc_norm 

sum QUIC_reg
gen QUIC_reg_std = (QUIC_reg - r(mean))/(r(sd))

gen QUIC_sub = QUIC_3_3 + QUIC_3_5 + QUIC_3_6 + QUIC_4_2 + QUIC_4_3 + QUIC_5_2
sum QUIC_sub 
gen QUIC_sub_std = (QUIC_sub - r(mean))/(r(sd))

// Replacing missing mental health obs with 0 
replace depression = 0 if depression == . 
replace anxiety = 0 if anxiety == . 


// Parental death 
gen mom_dead = 0 
replace mom_dead = 1 if !mi(mor_doddato)
gen dad_dead = 0 
replace dad_dead = 1 if !mi(far_doddato)

********************************************************************************

// Correlations between QUIC and objective measures 

// QUIC vs. Registry QUIC
reg QUIC_std QUIC_reg_std, r
global corr = _b[QUIC_reg_std]
global se   = _se[QUIC_reg_std]

binscatter QUIC_std QUIC_reg_std, genxq(bins)									///
		   ytitle("QUIC") xtitle("Registry QUIC")								///
		   note("All bins based on min. 134 observations.", size(small))		///
		   text(-0.8 1.5 "Regression estimate: `:display %5.2fc ${corr}' (`:display %5.2fc ${se}')", size(medsmall))
drop bins
graph export "Figures\QUIC_38_QUIC_reg.pdf", replace


// QUIC vs. Parental Income 
reg QUIC_std parents_avg_grossinc_1000, r
global corr = _b[parents_avg_grossinc_1000]
global se   = _se[parents_avg_grossinc_1000]

binscatter QUIC_std parents_avg_grossinc_1000, genxq(bins)							///
		   ytitle("QUIC") xtitle("Avg. Annual Parental Gross Income (1000 DKK)")	///
		   note("All bins based on min. 134 observations.", size(small))			///
		   text(-0.8 1600 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
drop bins
graph export "Figures\QUIC_38_grossinc.pdf", replace


// QUIC vs. Parental Education 
gen mor_educ_years_round = round(mor_educ_years, 1.0)
tab mor_educ_years_round

reg QUIC_std mor_educ_years_round, r
global corr = _b[mor_educ_years_round]
global se   = _se[mor_educ_years_round]

binscatter QUIC_std mor_educ_years_round if mor_educ_years_round > 7 & mor_educ_years_round != 18, 	///
		   discrete	xlabels(8(4)20)	ytitle("QUIC") xtitle("Mother's Education (Years)")				///
		   note("All bins based on min. 16 observations.", size(small))								///
		   text(-0.5 11 "Regression estimate: `:display %5.3fc ${corr}' (`:display %5.3fc ${se}')", size(medsmall))
graph export "Figures\QUIC_38_mor_educ.pdf", replace
drop mor_educ_years_round


gen far_educ_years_round = round(far_educ_years, 1.0)
tab far_educ_years_round

reg QUIC_std far_educ_years_round, r
global corr = _b[far_educ_years_round]
global se   = _se[far_educ_years_round]

binscatter QUIC_std far_educ_years_round if far_educ_years_round != 18 & far_educ_years_round != 19, 	///
		   discrete	xlabels(8(4)20) ytitle("QUIC") xtitle("Father's Education (Years)")					///
		   note("All bins based on min. 9 observations.", size(small))									///
		   text(-0.5 11 "Regression estimate: `:display %5.3fc ${corr}' (`:display %5.3fc ${se}')", size(medsmall))
graph export "Figures\QUIC_38_far_educ.pdf", replace
drop far_educ_years_round


// QUIC vs. Parental Unemployment 
reg QUIC_std parents_unemp_months_total, r
global corr = _b[parents_unemp_months_total]
global se   = _se[parents_unemp_months_total]

binscatter QUIC_std parents_unemp_months_total, genxq(bins) 					///
		   ytitle("QUIC") xtitle("Parental Unemployment (Months)")				///
		   note("All bins based on min. 91 observations.", size(small))			///
		   text(-0.4 65 "Regression estimate: `:display %5.3fc ${corr}' (`:display %5.3fc ${se}')", size(medsmall))
drop bins
graph export "Figures\QUIC_38_parental_unemp.pdf", replace



********************************************************************************

// Regressions  

// GPA
global ses 			"parents_avg_grossinc_100k mor_educ_years far_educ_years"
global objective 	"parents_split mor_n_partners far_n_partners mom_dead dad_dead n_adresse_id n_schools parents_unemp_months_total"
global parental_mh 	"mor_depression_0422 mor_anxiety_0422 far_depression_0422 far_anxiety_0422"
global cognitive "cognitive_score_std math_score_std raven_score_std"
qui reg gpa_all QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh, r

reg gpa_all QUIC_std female if e(sample), r
outreg2 using "GPA_sub_obj.tex", replace ctitle("GPA")
reg gpa_all QUIC_std female $ses if e(sample), r
outreg2 using "GPA_sub_obj.tex", append ctitle("GPA")
reg gpa_all QUIC_std female $objective if e(sample), r
outreg2 using "GPA_sub_obj.tex", append ctitle("GPA")
reg gpa_all QUIC_std female $ses $objective if e(sample), r
outreg2 using "GPA_sub_obj.tex", append ctitle("GPA")
reg gpa_all QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh if e(sample), r
outreg2 using "GPA_sub_obj.tex", append ctitle("GPA") 
qui reg gpa_all QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh $cognitive, r
reg gpa_all QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh if e(sample), r
outreg2 using "GPA_sub_obj.tex", append ctitle("GPA") 
reg gpa_all QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh $cognitive if e(sample), r
outreg2 using "GPA_sub_obj.tex", append ctitle("GPA") 


// High School
global ses 			"parents_avg_grossinc_100k mor_educ_years far_educ_years"
global objective 	"parents_split mor_n_partners far_n_partners mom_dead dad_dead n_adresse_id n_schools parents_unemp_months_total"
global parental_mh 	"mor_depression_0422 mor_anxiety_0422 far_depression_0422 far_anxiety_0422"
qui reg high_school QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh, r

reg high_school QUIC_std female if e(sample), r
outreg2 using "highschool_sub_obj.tex", replace ctitle("High School")
reg high_school QUIC_std female $ses if e(sample), r
outreg2 using "highschool_sub_obj.tex", append ctitle("High School")
reg high_school QUIC_std female $objective if e(sample), r
outreg2 using "highschool_sub_obj.tex", append ctitle("High School")
reg high_school QUIC_std female $ses $objective if e(sample), r
outreg2 using "highschool_sub_obj.tex", append ctitle("High School")
reg high_school QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh if e(sample), r
outreg2 using "highschool_sub_obj.tex", append ctitle("High School") 
qui reg high_school QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh $cognitive, r
reg high_school QUIC_std female $ses $objective  anxiety_ever depression_ever $parental_mh if e(sample), r
outreg2 using "highschool_sub_obj.tex", append ctitle("High School") 
reg high_school QUIC_std female $ses $objective anxiety_ever depression_ever $parental_mh $cognitive if e(sample), r
outreg2 using "highschool_sub_obj.tex", append ctitle("High School") 



// GAD7
global ses 			"parents_avg_grossinc_100k mor_educ_years far_educ_years"
global objective 	"parents_split mor_n_partners far_n_partners mom_dead dad_dead n_adresse_id n_schools parents_unemp_months_total"
global parental_mh 	"mor_depression_0422 mor_anxiety_0422 far_depression_0422 far_anxiety_0422"
qui reg GAD7_score QUIC_std QUIC_reg_std female $ses $objective, r

reg GAD7_score $ses if e(sample), r
outreg2 using "GAD7_sub_obj.tex", replace ctitle("GAD7")
reg GAD7_score QUIC_std if e(sample), r
outreg2 using "GAD7_sub_obj.tex", append ctitle("GAD7")
reg GAD7_score QUIC_reg_std if e(sample), r
outreg2 using "GAD7_sub_obj.tex", append ctitle("GAD7")
reg GAD7_score $objective if e(sample), r
outreg2 using "GAD7_sub_obj.tex", append ctitle("GAD7")
reg GAD7_score QUIC_std QUIC_reg_std female $ses if e(sample), r
outreg2 using "GAD7_sub_obj.tex", append ctitle("GAD7")
reg GAD7_score QUIC_std female $ses $objective if e(sample), r
outreg2 using "GAD7_sub_obj.tex", append ctitle("GAD7")
reg GAD7_score QUIC_std female $ses $objective $parental_mh if e(sample), r
outreg2 using "GAD7_sub_obj.tex", append ctitle("GAD7")


// PHQ8
global ses 			"parents_avg_grossinc_100k mor_educ_years far_educ_years"
global objective 	"parents_split mor_n_partners far_n_partners mom_dead dad_dead n_adresse_id n_schools parents_unemp_months_total"
global parental_mh 	"mor_depression_0422 mor_anxiety_0422 far_depression_0422 far_anxiety_0422"
qui reg PHQ8_score QUIC_std QUIC_reg_std female $ses $objective, r

reg PHQ8_score $ses if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", replace ctitle("PHQ8")
reg PHQ8_score QUIC_std if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", append ctitle("PHQ8")
reg PHQ8_score QUIC_reg_std if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", append ctitle("PHQ8")
reg PHQ8_score $objective if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", append ctitle("PHQ8")
reg PHQ8_score QUIC_std QUIC_reg_std female $ses if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", append ctitle("PHQ8")
reg PHQ8_score QUIC_std female $ses $objective if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", append ctitle("PHQ8")
reg PHQ8_score QUIC_std female $ses $objective $parental_mh if e(sample), r
outreg2 using "PHQ8_sub_obj.tex", append ctitle("PHQ8")




********************************************************************************

// Predicted GPA by Parental Income Tertiles 
gen eps = rnormal(0,1)*0.001
gen parents_inc_eps = parents_avg_grossinc_100k + eps
xtile parents_inc_terc = parents_inc_eps, nq(3)
tab parents_inc_terc
drop eps

foreach var in gpa_all high_school anxiety depression GAD7_score PHQ8_score {
	local gpa_all_text 		"GPA"
	local high_school_text 	"High School"
	local depression_text 	"Depression"
	local anxiety_text 		"Anxiety"
	local GAD7_score_text 	"PHQ8"
	local PHQ8_score_text 	"GAD7"
	
	local gpa_all_y 		"6(1)10"
	local high_school_y		"0.4(1)1.0"
	
	
	// Full QUIC
	reg `var' c.QUIC_std##i.parents_inc_terc, r
	margins parents_inc_terc, at(QUIC_std = (-1(0.2)2))
	global obs = r(N)

	marginsplot, recast(line) recastci(rarea)									///
		plot1opts(lcolor(navy)) ci1opt(color(navy%50))							///
		plot2opts(lcolor(cranberry)) ci2opt(color(cranberry%50))				///
		plot3opts(lcolor(lavender)) ci3opt(color(lavender%50))					///
		legend(order(4 "Low Income" 5 "Middle Income" 6 "High Income")) 		///
		xtitle("QUIC (Standardized)") ytitle("Predicted ``var'_text'") 			///
		xlabel(-1(0.5)2, nogrid) ylabel(``var'_y', nogrid)						///
		title("") name(`var'_QUIC, replace)										///
		note("Based on $obs observations.", size(small))					
	graph export "Figures\ `var'_QUIC_byincome.pdf", replace
	
	// Registry QUIC
	reg `var' c.QUIC_reg_std##i.parents_inc_terc, r
	margins parents_inc_terc, at(QUIC_reg_std = (-1(0.2)2))
	global obs = r(N)

	marginsplot, recast(line) recastci(rarea)									///
		plot1opts(lcolor(navy)) ci1opt(color(navy%50))							///
		plot2opts(lcolor(cranberry)) ci2opt(color(cranberry%50))				///
		plot3opts(lcolor(lavender)) ci3opt(color(lavender%50))					///
		legend(order(4 "Low Income" 5 "Middle Income" 6 "High Income")) 		///
		xtitle("Registry QUIC (Standardized)") ytitle("Predicted ``var'_text'") ///
		title("") name(`var'_regQUIC, replace)									///
		ylabels(, nogrid) xlabel(-1(0.5)2, nogrid) 								///									
		note("Based on $obs observations.", size(small))		
	graph export "Figures\ `var'_regQUIC_byincome.pdf", replace
}



// Predicted GPA by Parental Education 
gen parental_educ_sum = mor_educ_years + far_educ_years
xtile parental_educ_terc = parental_educ_sum, nq(3)
tab parental_educ_terc

foreach var in gpa_all high_school anxiety depression GAD7_score PHQ8_score {
	local gpa_all_text 		"GPA"
	local high_school_text 	"High School"
	local depression_text 	"Depression"
	local anxiety_text 		"Anxiety"
	local GAD7_score_text 	"PHQ8"
	local PHQ8_score_text 	"GAD7"
	
	// FUll QUIC
	reg `var' c.QUIC_std##i.parental_educ_terc, r
	margins parental_educ_terc, at(QUIC_std = (-2(0.2)2))
	global obs = r(N)

	marginsplot, recast(line) recastci(rarea)										///
		plot1opts(lcolor(navy)) ci1opt(color(navy%50))								///
		plot2opts(lcolor(cranberry)) ci2opt(color(cranberry%50))					///
		plot3opts(lcolor(lavender)) ci3opt(color(lavender%50))						///
		legend(order(4 "Short Education" 5 "Medium Education" 6 "Long Education")) 	///
		xtitle("QUIC (Standardized)") ytitle("Predicted ``var'_text'") 				///
		title("") name(`var'_QUIC, replace)											///
		ylabels(, nogrid) xlabel(-2(1)2, nogrid)									///
		note("Based on $obs observations.", size(small))		
	graph export "Figures\ `var'_QUIC_bypareduc.pdf", replace
	
	// Registry QUIC
	reg `var' c.QUIC_reg_std##i.parental_educ_terc, r
	margins parental_educ_terc, at(QUIC_reg_std = (-2(0.2)2))
	global obs = r(N)

	marginsplot, recast(line) recastci(rarea)										///
		plot1opts(lcolor(navy)) ci1opt(color(navy%50))								///
		plot2opts(lcolor(cranberry)) ci2opt(color(cranberry%50))					///
		plot3opts(lcolor(lavender)) ci3opt(color(lavender%50))						///
		legend(order(4 "Short Education" 5 "Medium Education" 6 "Long Education")) 	///
		xtitle("QUIC (Standardized)") ytitle("Predicted ``var'_text'") 				///
		title("") name(`var'_regQUIC, replace)										///
		ylabels(, nogrid) xlabel(-2(1)2, nogrid) 									///
		note("Based on $obs observations.", size(small))		
	graph export "Figures\ `var'_regQUIC_bypareduc.pdf", replace
}

