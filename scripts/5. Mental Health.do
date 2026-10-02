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

use "$data\data_cohort2004_final.dta", clear 


********************************************************************************

keep if ResponseStatus == "Completed"
drop if timetakenseconds < 300 


// Parental earnings in 1000 DKK
foreach var in disp gross earned {
	gen parents_avg_`var'inc_1000 = parents_avg_`var'inc_real_w/1000
}

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

********************************************************************************


// Distribution of GAD7 
egen GAD7_count = count(pnr), by(GAD7_score)
sum GAD7_count 
global min = r(min)

hist GAD7_score, start(-0.5) width(1) frac color(gs6)							///
	 xline(4.5 9.5 14.5, lcolor(gs12)) xsize(9) ysize(6)						///
	 xtitle("GAD7 Score", height(5)) name(GAD7, replace) ylab(, nogrid)			///
	 xlabel(2 "1-4: Minimal Anxiety" 7 "5-9: Mild Anxiety" 						///
	 12 "10-14: Moderate Anxiety" 												///
	 17 "15-21: Severe Anxiety", labsize(small) nogrid)							///
	 note("All bins based on min. $min observations", size(small))	
graph export "Figures\GAD7_score_dist.pdf", replace
drop GAD7_count



// Distribution of PHQ8 
egen PHQ8_count = count(pnr), by(PHQ8_score)
sum PHQ8_count 
global min = r(min)

hist PHQ8_score, start(-0.5) width(1) frac color(gs6)							///
	 xtitle("PHQ8 Score", height(5)) name(PHQ8, replace) ylab(, nogrid)			///
	 xline(4.5 9.5 14.5 19.5, lcolor(gs12)) xsize(9) ysize(6)					///
	 xlabel(2 `" "1-4: Minimal" "Depression" "' 								///
	 7 `" "5-9: Mild" "Depression" "' 12 `" "10-14: Moderate" "Depression" "' 	///
	 17 `" "15-19: Moderately" "Severe Depression" "' 							///
	 22 `" "20-24: Severe" "Depression" "', labsize(small) nogrid)				///
	 note("All bins based on min. $min observations", size(small))
graph export "Figures\PHQ8_score_dist.pdf", replace
drop PHQ8_count



// Correlation between Anxiety and GAD7 
reg anxiety GAD7_score
global corr = _b[GAD7_score]
global se   = _se[GAD7_score]

binscatter anxiety GAD7_score, ytitle("Probability of Anxiety Diagnosis") 		///
		   xtitle("GAD7 Score") name("anx_GAD7", replace) genxq(bins)			///
		   ylab(, nogrid) xlab(, nogrid)										///	
		   note("All bins based on min. 90 observations.", size(small))	
// text(0.01 16 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
graph export "Figures\anx_GAD7.pdf", replace
tab bins 
drop bins

// Correlation between Depression and PHQ8 
reg depression PHQ8_score
global corr = _b[PHQ8_score]
global se   = _se[PHQ8_score]

binscatter depression PHQ8_score, ytitle("Probability of Depression Diagnosis") ///
		   xtitle("PHQ8 Score") name("dep_PHQ8", replace) genxq(bins)			///
		   ylab(, nogrid) xlab(, nogrid)										///	
		   note("All bins based on min. 94 observations.", size(small))	
// text(0.01 16 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
graph export "Figures\dep_PHQ8.pdf", replace
tab bins 
drop bins



// Correlation between GAD7 and QUIC
reg GAD7_score QUIC_38_score
global corr = _b[QUIC_38_score]
global se   = _se[QUIC_38_score]

binscatter GAD7_score QUIC_38_score, ytitle("GAD7 Score", size(vlarge)) 		///
		   xlab(, labsize(vlarge)) ylab(, labsize(vlarge)) genxq(bins)			///
		   xtitle("QUIC Score", size(vlarge)) name("GAD7_QUIC", replace) 		///
		   note("All bins based on min. 117 observations.", size(small))		///
		   
//text(5 20 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
graph export "Figures\GAD7_QUIC.pdf", replace
tab bins 
drop bins


// Correlation between Registry Anxiety and QUIC
reg anxiety QUIC_38_score
global corr = _b[QUIC_38_score]
global se   = _se[QUIC_38_score]

binscatter anxiety QUIC_38_score, genxq(bins)									///
		   ytitle("Probability of Anxiety", size(vlarge)) 						///
		   xtitle("QUIC Score", size(vlarge)) name("anx_QUIC", replace) 		///
		   xlab(, labsize(vlarge)) ylab(, labsize(vlarge))						///
		   note("All bins based on min. 117 observations.", size(small))		
//text(0.005 20 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
graph export "Figures\anx_QUIC_meta.pdf", replace
tab bins 
drop bins
		
		
// Correlation between PHQ8 and QUIC
reg PHQ8_score QUIC_38_score
global corr = _b[QUIC_38_score]
global se   = _se[QUIC_38_score]

binscatter PHQ8_score QUIC_38_score, genxq(bins)								///
		   ytitle("PHQ8 Score", size(vlarge)) 									///
		   xtitle("QUIC Score", size(vlarge)) name("PHQ8_QUIC", replace)		///
		   xlab(, labsize(vlarge)) ylab(, labsize(vlarge))						///
		   note("All bins based on min. 117 observations.", size(small))		
//text(5 20 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
graph export "Figures\PHQ8_QUIC.pdf", replace 
tab bins
drop bins


// Correlation between Registry Depression and QUIC
reg depression QUIC_38_score
global corr = _b[QUIC_38_score]
global se   = _se[QUIC_38_score]

binscatter depression QUIC_38_score, genxq(bins)								///
		   ytitle("Probability of Depression", size(vlarge)) 					///
		   xtitle("QUIC Score", size(vlarge)) name("dep_QUIC", replace) 		///
		   xlab(, labsize(vlarge)) ylab(, labsize(vlarge))						///
		   note("All bins based on min. 117 observations.", size(small))		
//text(0.005 20 "Regression estimate: `:display %5.4fc ${corr}' (`:display %5.4fc ${se}')", size(medsmall))
graph export "Export\dep_QUIC.pdf", replace 
tab bins
drop bins




// Anxiety vs. QUIC
global controls 	"female parents_avg_grossinc_1000 mor_educ_years far_educ_years"
global cognitive 	"cognitive_score_std math_score_std raven_score_std"
global parental_mh 	"mor_depression_0422 mor_anxiety_0422 far_depression_0422 far_anxiety_0422"
qui reg GAD7_score QUIC_std $controls $parental_mh gpa_all, r

reg GAD7_score QUIC_std if e(sample), r
outreg2 using "anxiety_QUIC.tex", replace ctitle("GAD7")
reg GAD7_score QUIC_std $controls if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("GAD7") keep(QUIC_std)			///
		addtext(Gender, X, Parental Income, X, Parental Education, X)	
reg GAD7_score QUIC_std $controls $parental_mh if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("GAD7")	keep(QUIC_std)			///
		addtext(Gender, X, Parental Income, X, Parental Education, X, Parental Mental Health, X)	
reg GAD7_score QUIC_std $controls $parental_mh  gpa_all if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("GAD7")	keep(QUIC_std)			///
		addtext(Gender, X, Parental Income, X, Parental Education, X,  Parental Mental Health, X, Cognitive, X)	

qui reg anxiety QUIC_std $controls $parental_mh gpa_all, r
reg anxiety QUIC_std if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("Anxiety")
reg anxiety QUIC_std $controls if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("Anxiety") keep(QUIC_std)		///
		addtext(Gender, X, Parental Income, X, Parental Education, X)		
reg anxiety QUIC_std $controls $parental_mh if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("Anxiety")	keep(QUIC_std)		///
		addtext(Gender, X, Parental Income, X, Parental Education, X, Parental Mental Health, X)	
reg anxiety QUIC_std $controls $parental_mh  gpa_all if e(sample), r
outreg2 using "anxiety_QUIC.tex", append ctitle("Anxiety")	keep(QUIC_std)		///
		addtext(Gender, X, Parental Income, X, Parental Education, X,  Parental Mental Health, X, Cognitive, X)	

probit anxiety QUIC_std $controls $parental_mh  gpa_all, vce(robust)
margins, dydx(QUIC_std)


		
// Depression vs.QUIC
global controls 	"female parents_avg_grossinc_1000 mor_educ_years far_educ_years"
global cognitive 	"cognitive_score_std math_score_std raven_score_std"
global parental_mh 	"mor_depression_0422 mor_anxiety_0422 far_depression_0422 far_anxiety_0422"
qui reg PHQ8_score QUIC_std $controls $parental_mh gpa_all, r

reg PHQ8_score QUIC_std if e(sample), r
outreg2 using "depression_QUIC.tex", replace ctitle("PHQ8")
reg PHQ8_score QUIC_std $controls if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("PHQ8") keep(QUIC_std)		///
		addtext(Gender, X, Parental Income, X, Parental Education, X)		
reg PHQ8_score QUIC_std $controls $parental_mh if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("PHQ8")	keep(QUIC_std)		///
		addtext(Gender, X, Parental Income, X, Parental Education, X, Parental Mental Health, X)	
reg PHQ8_score QUIC_std $controls $parental_mh gpa_all if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("PHQ8") keep(QUIC_std)		///
		addtext(Gender, X, Parental Income, X, Parental Education, X,  Parental Mental Health, X, Cognitive, X)	

qui reg depression QUIC_std $controls $parental_mh gpa_all, r
reg depression QUIC_std if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("Depression")
reg depression QUIC_std $controls if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("Depression") keep(QUIC_std)	///
		addtext(Gender, X, Parental Income, X, Parental Education, X)		
reg depression QUIC_std $controls $parental_mh if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("Depression") keep(QUIC_std)	///
		addtext(Gender, X, Parental Income, X, Parental Education, X, Parental Mental Health, X)	
reg depression QUIC_std $controls $parental_mh gpa_all if e(sample), r
outreg2 using "depression_QUIC.tex", append ctitle("Depression") keep(QUIC_std)	///
		addtext(Gender, X, Parental Income, X, Parental Education, X,  Parental Mental Health, X, Cognitive, X)	

probit depression QUIC_std $controls $parental_mh gpa_all, vce(robust)
margins, dydx(QUIC_std)
		
