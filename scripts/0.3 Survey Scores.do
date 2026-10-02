// Author: Ida Maria Hartmann
// Last edited: 03.06.2025

drop if timetakenseconds < 300



// Turning QUIC items into numeric scores 
// QUIC 1: Parental monitoring and involvement
forvalues x = 1/9 {
	replace QUIC_1_`x' = "0" if QUIC_1_`x' == "Enig"
	replace QUIC_1_`x' = "1" if QUIC_1_`x' == "Uenig"
	destring QUIC_1_`x', replace
}
// QUIC 2: Parental predictability
foreach x in 1 3 4 6 8 9 10 11 12 {
	replace QUIC_2_`x' = "0" if QUIC_2_`x' == "Uenig"
	replace QUIC_2_`x' = "1" if QUIC_2_`x' == "Enig"
	destring QUIC_2_`x', replace
}
foreach x in 2 5 7 {
	replace QUIC_2_`x' = "0" if QUIC_2_`x' == "Enig"
	replace QUIC_2_`x' = "1" if QUIC_2_`x' == "Uenig"
	destring QUIC_2_`x', replace
}
// QUIC 3: Parental environment
foreach x in 1 2 3 4 6 7 {
	replace QUIC_3_`x' = "0" if QUIC_3_`x' == "Uenig"
	replace QUIC_3_`x' = "1" if QUIC_3_`x' == "Enig"
	destring QUIC_3_`x', replace
}
replace QUIC_3_5 = "0" if QUIC_3_5 == "Enig"
replace QUIC_3_5 = "1" if QUIC_3_5 == "Uenig"
destring QUIC_3_5, replace 
// QUIC 4: Physical environment
foreach x in 1 2 3 4 6 7 {
	replace QUIC_4_`x' = "0" if QUIC_4_`x' == "Uenig"
	replace QUIC_4_`x' = "1" if QUIC_4_`x' == "Enig"
	destring QUIC_4_`x', replace
}
replace QUIC_4_5 = "0" if QUIC_4_5 == "Enig"
replace QUIC_4_5 = "1" if QUIC_4_5 == "Uenig"
destring QUIC_4_5, replace 
// QUIC 5: Safety and security
forvalues x = 1/3 {
	replace QUIC_5_`x' = "0" if QUIC_5_`x' == "Uenig"
	replace QUIC_5_`x' = "1" if QUIC_5_`x' == "Enig"
	destring QUIC_5_`x', replace
}
// QUIC 6: Financial instability
foreach x in 1 3 5 6 7 8 {
	replace QUIC_6_`x' = "0" if QUIC_6_`x' == "Uenig"
	replace QUIC_6_`x' = "1" if QUIC_6_`x' == "Enig"
	destring QUIC_6_`x', replace
}
foreach x in 2 4 {
	replace QUIC_6_`x' = "0" if QUIC_6_`x' == "Enig"
	replace QUIC_6_`x' = "1" if QUIC_6_`x' == "Uenig"
	destring QUIC_6_`x', replace
}


// Sub QUICs 
forvalues x = 1(1)6 {
	egen QUIC_`x' = rowtotal(QUIC_`x'_*)
}

label var QUIC_1 "Parental Monitoring and Involvement (9 Items)"
label var QUIC_2 "Parental Predictability (12 Items)"
label var QUIC_3 "Parental Environment (7 Items)"
label var QUIC_4 "Physical Environment (7 Items)"
label var QUIC_5 "Safety and Security (3 Items)"
label var QUIC_6 "Financial Stress (8 Items)"


// Label QUIC Items 
// Parental Monitoring and Involvement
label var QUIC_1_1 "QUIC 1.1: Prior to Age 12: I had a set morning routine on school day (R)"
label var QUIC_1_2 "QUIC 1.2: Prior to Age 12: My parents kept tract of what I ate (R)"
label var QUIC_1_3 "QUIC 1.3: Prior to Age 12: My family ate a meal together most days (R)"
label var QUIC_1_4 "QUIC 1.4: Prior to Age 12: My parents tried to make sure I got a good night's sleep (R)"
label var QUIC_1_5 "QUIC 1.5: Prior to Age 12: I had a bedtime routine (R)"
label var QUIC_1_6 "QUIC 1.6: Prior to Age 12: In my afterschool or free time hours at leat one of my parents knew what I was doing (R)"
label var QUIC_1_7 "QUIC 1.7: Prior to Age 12: At least one on my parents regularly checked that I did my homework (R)"
label var QUIC_1_8 "QUIC 1.8: Prior to Age 12: At least one of my parents regularly kept track of my school progress (R)"
label var QUIC_1_9 "QUIC 1.9: Prior to Age 12: At least one of parents made time each day to see how I was doing (R)"
// Parental Predictability
label var QUIC_2_1 "QUIC 2.1: Prior to Age 12: My parents were often late to pick me up"
label var QUIC_2_2 "QUIC 2.2: Prior to Age 12: I usually knew when my parents were going to be home (R)"
label var QUIC_2_3 "QUIC 2.3: Prior to Age 18: At least one of my parents had punishments that were unpredictable"
label var QUIC_2_4 "QUIC 2.4: Prior to Age 18: I often wondered whether or not one of my parents would come home at the end of the day"
label var QUIC_2_5 "QUIC 2.5: Prior to Age 18: My family planned activities to do together (R)"
label var QUIC_2_6 "QUIC 2.6: Prior to Age 18: At least one of my parents would plan something for the family, but then not follow through with the plan"
label var QUIC_2_7 "QUIC 2.7: Prior to Age 18: My family had holiday traditions that we did every year (R)"
label var QUIC_2_8 "QUIC 2.8: Prior to Age 18: At least one of my parents wre disorganized"
label var QUIC_2_9 "QUIC 2.9: Prior to Age 18: At least one of my parents was unpredictable"
label var QUIC_2_10 "QUIC 2.10: Prior to Age 18: For at least one of my parents, when they were upset I did not know how they would act"
label var QUIC_2_11 "QUIC 2.11: Prior to Age 18: One of my parents could go from calm to furious in an instant"
label var QUIC_2_12 "QUIC 2.12: Prior to Age 18: One of my parents could go from calm to stressed or nervous in an instant"
// Parental Environment
label var QUIC_3_1 "QUIC 3.1: Prior to Age 18: There was a long period of time when I didn't see one of my parents"
label var QUIC_3_2 "QUIC 3.2: Prior to Age 18: I experienced changes in my custody arrangement"
label var QUIC_3_3 "QUIC 3.3: Prior to Age 18: At least one of my parents changed jobs frequently"
label var QUIC_3_4 "QUIC 3.4: Prior to Age 18: There were times when one of my parents was unemployed and couldn't find a job even though he/she wanted one"
label var QUIC_3_5 "QUIC 3.5: Prior to Age 18: My parents had a stable relationship with each other (R)"
label var QUIC_3_6 "QUIC 3.6: Prior to Age 18: My parents got divorced"
label var QUIC_3_7 "QUIC 3.7: Prior to Age 18: At least one of my parents had many romantic partners"
// Physical Environment
label var QUIC_4_1 "QUIC 4.1: Prior to Age 18: There were often people coming and going in my house that I did not expect to be there"
label var QUIC_4_2 "QUIC 4.2: Prior to Age 18: I moved frequently"
label var QUIC_4_3 "QUIC 4.3: Prior to Age 18: I changed schools frequently"
label var QUIC_4_4 "QUIC 4.4: Prior to Age 18: I changed schools mid-year"
label var QUIC_4_5 "QUIC 4.5: Prior to Age 18: I lived in a clean house (R)"
label var QUIC_4_6 "QUIC 4.6: Prior to Age 18: I lived in a cluttered house"
label var QUIC_4_7 "QUIC 4.7: Prior to Age 18: In my house things I needed were often misplaced so that I could not find them"
// Safety and Security
label var QUIC_5_1 "QUIC 5.1: Prior to Age 18: There was a period of time when I often worried that I was not going to have enough food to eat"
label var QUIC_5_2 "QUIC 5.2: Prior to Age 18: There was a period of time when I often worried that my family would not have enough money to pay for necessities like clothing or bills"
label var QUIC_5_3 "QUIC 5.3: Prior to Age 18: There was a period of time when I did not feel safe in my home"



// QUIC Score
egen QUIC_38_score = rowtotal(QUIC_1_* QUIC_2_* QUIC_3_* QUIC_4_* QUIC_5_*), missing

egen financial_stress = rowtotal(QUIC_6_*), missing

// Standardized QUIC Scores 
sum QUIC_38_score
gen QUIC_std = (QUIC_38_score - r(mean))/(r(sd))

forvalues x = 1(1)6 {
	sum QUIC_`x'
	gen QUIC_`x'_std = (QUIC_`x' - r(mean))/(r(sd))
}

sum financial_stress 
gen financial_stress_std = (financial_stress - r(mean))/(r(sd))

// Survey Ranks
set seed 11
gen epsilon = runiform(0,1)/10
gen QUIC_eps = QUIC_38_score + epsilon
egen QUIC_rank = group(QUIC_eps) 

sum QUIC_rank 
gen QUIC_rank_100 = QUIC_rank/r(max) * 100
drop epsilon QUIC_eps




// Mental Health
egen GAD7_score = rowtotal(GAD7_1 GAD7_2 GAD7_3 GAD7_4 GAD7_5 GAD7_6 GAD7_7)
egen PHQ8_score = rowtotal(PHQ8_1 PHQ8_2 PHQ8_3 PHQ8_4 PHQ8_5 PHQ8_6 PHQ8_7 PHQ8_8)


// Expected Salary 
gen exp_salary = salary_m * 1000