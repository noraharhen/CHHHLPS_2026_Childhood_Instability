// Author: Ida Maria Hartmann
// Last edited: 08.07.2025

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

// Difference in Means 
use "$data\data_cohort2004_final.dta", clear 
gen completed = ResponseStatus == "Completed"

mat t_test = J(18,4,.)
mat colnames t_test = "Respondents" "Non-Respondents" "Difference" "P-value"
mat rownames t_test = "Females" "Age" "9th Grade GPA" "Number of Siblings" 		/// 
				   "Parents Divorced" "Mom Age" "Dad Age" 						///
				   "Mom Avg Earnings" "Dad Avg Earnings"						///
				   "Mom Unemployment (Days)" "Dad Unemployment (Days)"			///
				   "Anxiety Diagnosis" "Depression Diagnosis"					///
				   "Mom Anxiety" "Dad Anxiety" 									///
				   "Mom Depression" "Dad Depression"							///
				   "Observations"

local r = 1 
foreach var in female alder gpa_all n_siblings parents_divorced mor_alder_fodsel far_alder_fodsel mor_avg_earnedinc_real_w far_avg_earnedinc_real_w mor_unemp_days_total far_unemp_days_total anxiety_ever depression_ever mor_anxiety_0422 far_anxiety_0422 mor_depression_0422 far_depression_0422 {  
	ttest `var', by(completed)
	mat t_test[`r',1] = r(mu_2)				// Respondents 
	mat t_test[`r',2] = r(mu_1)				// Non-Respondents 
	mat t_test[`r',3] = r(mu_2) - r(mu_1)	// Difference
	mat t_test[`r',4] = r(p)				// P-value
	local ++r
}

count if completed == 1
mat t_test[18,1] = r(N)
count if completed == 0
mat t_test[18,2] = r(N)

mat list t_test
esttab matrix(t_test, fmt(%12.2fc)) using "$rslt\summ_stats_ttest.tex", replace nomtitles


********************************************************************************

use "$data\data_cohort2004_final.dta", clear 

keep if ResponseStatus == "Completed"



// Time take to complete survey 
sum timetakenseconds
twoway__histogram_gen timetakenseconds if timetakenseconds < 7000, bins(15) freq gen(count where)
sum count
global min = r(min)
drop count where

// Histogram
hist timetakenseconds if timetakenseconds < 7000, bins(15) frac color(gs7) 		///
	 xtitle("Time Taken to Complete Survey (Seconds)", size(vlarge))			///
	 xlabels(, labsize(vlarge) nogrid) ylabels(, labsize(vlarge) nogrid) 		///
	 ytitle("Fraction", size(vlarge)) name(timetaken, replace)					///
	 note("All bins based on minimum $min observations", size(small))
graph export "Figures\timetaken.pdf", replace

drop if timetakenseconds < 300 


// Distribution of the QUIC Score 
egen QUIC_count = count(pnr), by(QUIC_38_score)
sum QUIC_count if QUIC_count

hist QUIC_38_score if QUIC_count > 5, start(-0.5) width(1) frac color(gs6)		///
	 xtitle("QUIC Score") name(QUIC_38_score, replace) 							///
	 note("All bins based on min. 6 observations", size(small))					
graph export "Figures\QUIC_score_dist.pdf", replace
drop QUIC_count


// Distribution of QUIC Categories 
forvalues x = 1(1)6 {
	egen QUIC_`x'_count = count(pnr), by(QUIC_`x')
	sum QUIC_`x'_count if QUIC_`x'_count
	global min = r(min)
	
	sum QUIC_`x' 
	global x_max = r(max)

	hist QUIC_`x' if QUIC_`x'_count > 5, start(-0.5) width(1) frac color(gs6)	///
		 xtitle("`: var label QUIC_`x''") name(QUIC_`x', replace)				///
		 xlabels(0(1)$x_max)													///
		 note("All bins based on min. $min observations", size(small))	
	graph export "Figures\QUIC_`x'.pdf", replace
	drop QUIC_`x'_count
}



********************************************************************************

// Education 
// GPA 
twoway__histogram_gen gpa_all if gpa_all > 0, start(-0.5) width(1) freq gen(count where)
sum count
global min = r(min)
drop count where

hist gpa_all if gpa_all > 0, start(-0.5) width(1) frac color(gs7)				///
	 xtitle("9th Grade GPA", size(vlarge)) ytitle("Fraction", size(vlarge))		///
	 xlab(0 2 4 7 10 12, labsize(vlarge) nogrid) ylab(, labsize(vlarge) nogrid)	///
	 note("All bins based on min. $min observations.", size(small))		
graph export "Export\GPA_histogram.pdf", replace



// Mental Health 

// Distribution of GAD7 
egen GAD7_count = count(pnr), by(GAD7_score)
sum GAD7_count 
global min = r(min)

hist GAD7_score, start(-0.5) width(1) frac color(gs6)							///
	 xline(4.5 9.5 14.5, lcolor(gs12))											///
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
	 xline(4.5 9.5 14.5 19.5, lcolor(gs12))										///
	 xlabel(2 `" "1-4: Minimal" "Depression" "' 								///
	 7 `" "5-9: Mild" "Depression" "' 12 `" "10-14: Moderate" "Depression" "' 	///
	 17 `" "15-19: Moderately" "Severe Depression" "' 							///
	 22 `" "20-27: Severe" "Depression" "', labsize(small) nogrid)				///
	 note("All bins based on min. $min observations", size(small))
graph export "Figures\PHQ8_score_dist.pdf", replace
drop PHQ8_count



// Correlation between GAD7 and QUIC
reg GAD7_score QUIC_38_score
global corr = _b[QUIC_38_score]
global se   = _se[QUIC_38_score]

binscatter GAD7_score QUIC_38_score, ytitle("GAD7 Score") xtitle("QUIC Score")	///
		   name("GAD7_QUIC", replace) genxq(bins)								///
		   note("All bins based on min. 117 observations.", size(small))		///
		   text(5 20 "Regression estimate: `:display %5.2fc ${corr}' (`:display %5.2fc ${se}')", size(medsmall))
graph export "Figures\GAD7_QUIC.pdf", replace
tab bins 
drop bins
		
		
// Correlation between PHQ8 and QUIC
reg PHQ8_score QUIC_38_score
global corr = _b[QUIC_38_score]
global se   = _se[QUIC_38_score]

binscatter PHQ8_score QUIC_38_score, ytitle("PHQ8 Score") xtitle("QUIC Score")	///
		   name("PHQ8_QUIC", replace) genxq(bins)								///
		   note("All bins based on min. 117 observations.", size(small))		///
		   text(5 20 "Regression estimate: `:display %5.2fc ${corr}' (`:display %5.2fc ${se}')", size(medsmall))
graph export "Figures\PHQ8_QUIC.pdf", replace 
tab bins
drop bins


