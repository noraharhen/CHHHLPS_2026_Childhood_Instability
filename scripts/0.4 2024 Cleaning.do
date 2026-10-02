// Author: Ida Maria Hartmann
// Last edited: 02.07.2025

clear all
set more off

cd "P:\Workdata\707906\imh\Childhood Predictability"
global data "P:\Workdata\707906\imh\Childhood Predictability\Data"
global code	"P:\Workdata\707906\imh\Childhood Predictability\Programs"

use "$data\cohort_2004_clp5.dta", clear


********************************************************************************

duplicates report pnr	// No duplicates 

// Renaming variables 
rename TimeTakentoCompleteSeconds timetakenseconds
destring timetakenseconds, replace

// Gender 
label define gender_lbl 1 "Mand" 2 "Kvinde" 3 "Andet" 4 "Ønsker ikke at oplyse"
rename Q_1_1 gender
replace gender = "1" if gender == "Mand"
replace gender = "2" if gender == "Kvinde"
replace gender = "3" if gender == "Andet"
replace gender = "4" if gender == "Ã˜nsker ikke at oply"
destring gender, replace 
label values gender gender_lbl

// Age
rename Q_1_2 age 
destring age, replace

replace Extraversion = "" if Extraversion == "NaN"
destring Extraversion, replace

// OCEAN 
rename BFIE ocean_1
rename DZ 	ocean_2
rename BFIA ocean_3 
rename EB 	ocean_4 
rename BFIC ocean_5
rename ED 	ocean_6 
rename BFIN ocean_7 
rename EF 	ocean_8
rename BFIO ocean_9
rename EH	ocean_10

label var ocean_1 "Jeg ser mig selv som en der er reserveret"
label var ocean_2 "Jeg ser mig selv som en der er udadvendt of selskabelig"
label var ocean_3 "Jeg ser mig selv som en der er generelt tillidsfuld"
label var ocean_4 "Jeg ser mig selv som en der har tendens til at finde fejl ved andre"
label var ocean_5 "Jeg ser mig selv som en der gør et grundigt arbejde"
label var ocean_6 "Jeg ser mig selv som en der har tendens til at være doven"
label var ocean_7 "Jeg ser mig selv som en der er afslappet og håndterer stress godt"
label var ocean_8 "Jeg ser mig selv som en der let bliver nervøs"
label var ocean_9 "Jeg ser mig selv som en der har en god fantasi"
label var ocean_10 "Jeg ser mig selv som en der kun har få kreative interesser"



// RAVEN
forvalues x = 1(1)5 {
	rename Raven_`x'raven raven_`x'
}

gen raven_score = 0 
replace raven_score = raven_score + 1 if raven_1 == 5
replace raven_score = raven_score + 1 if raven_2 == 5
replace raven_score = raven_score + 1 if raven_3 == 7
replace raven_score = raven_score + 1 if raven_4 == 2
replace raven_score = raven_score + 1 if raven_5 == 1
replace raven_score = . if mi(raven_1) & mi(raven_2) & mi(raven_3) & mi(raven_4) & mi(raven_5)  


// COGNITIVE 
rename EP 		cognitive_1 
rename Q21C21	cognitive_2
rename Q21C2C22 cognitive_3
rename Q21C2C74 cognitive_4
rename Q21C2C75 cognitive_5
rename Q21C2C76 cognitive_6

label var cognitive_1 "A bat and a ball cost 110 kr. in total. The bat costs 100 kr. more than the ball. What does the ball cost?"
label var cognitive_2 "If it takes 5 machines 5 minutes to make 5 things, how long does it take 100 machines to make 100 things?"
label var cognitive_3 "In a lake, there is an area with lilypads. Every day, the area doubles in size. If it takes 48 days for the entire lake to be covered, how long does it take before half the lake is covered?"
label var cognitive_4 "Jens received both the 15. lowest and the 15th highest grade in the class. How many students are there in the class?"
label var cognitive_5 "If Niels is able to drink a tub of water in 6 days and Marie is able to drink a tub of water in 12 days, how long would it take both of them to drink a whole tub of water?"
label var cognitive_6 "A man buys a pig for 600 kr., sells it for 700 kr., buys it back for 800 kr. and finally, sells it for 900 kr. How much money did he make?"

gen cognitive_score = 0 
replace cognitive_score = cognitive_score + 1 if cognitive_1 == 5
replace cognitive_score = cognitive_score + 1 if cognitive_2 == 5
replace cognitive_score = cognitive_score + 1 if cognitive_3 == 47
replace cognitive_score = cognitive_score + 1 if cognitive_4 == 29
replace cognitive_score = cognitive_score + 1 if cognitive_5 == 4
replace cognitive_score = cognitive_score + 1 if cognitive_6 == 200
replace cognitive_score = . if mi(cognitive_1) & mi(cognitive_2) & mi(cognitive_3) & mi(cognitive_4) & mi(cognitive_5) & mi(cognitive_6)


// RMET 
rename Q62 		rmet_1
rename Q62C6C63 rmet_2
rename Q62C6C64 rmet_3
rename Q62C6C65 rmet_4
rename Q62C6C66 rmet_5
rename Q62C6C67 rmet_6
rename Q62C6C68 rmet_7
rename Q62C6C69 rmet_8
rename Q62C6C70 rmet_9
rename Q62C6C71 rmet_10
rename Q62C6C72 rmet_11
rename Q62C6C73 rmet_12


// Math 
rename FJ 		math_1
rename Q21C2C24 math_2
rename Q21C2C23 math_3
rename Q21C2C25 math_4 

gen math_score = 0 
replace math_score = math_score + 1 if math_1 == 25
replace math_score = math_score + 1 if math_2 == 20
replace math_score = math_score + 1 if math_3 == 30
replace math_score = math_score + 1 if math_4 == 50
replace math_score = . if mi(math_1) & mi(math_2) & mi(math_3) & mi(math_4)


// Assignment Game 
rename CustomVariable41 assignment_game1_score
rename CustomVariable42 assignment_game2_score
rename CustomVariable43 assignment_game3_score
rename CustomVariable44 assignment_game4_score
rename CustomVariable45 assignment_game5_score
rename CustomVariable46 assignment_game6_score
rename CustomVariable47 assignment_game7_score

egen assignment_game_score = rowtotal(assignment_game*)

// Preferences 
rename Q_5_1 patience
rename Q_5_2 risk_aversion
rename Q_5_3_1 inflation_belief 
rename Q_5_3_2 inflation_belief_num 

// Beliefs 
rename Q_6_1 total_inc_increase 
rename Q_6_2 unemp_increase 
rename Q_6_3 recession 


// AI 
rename Q69 chatgpt_know_use 
rename Q71 chatgpt_future


// Education: Started/Finished
rename Q102 grundskole 
replace grundskole = IO if !mi(IO)
rename IP klasse10 
replace klasse10 = IQ if !mi(IQ)
rename IR STU 
replace STU = IS if !mi(IS)
rename IT gymnasie 
replace gymnasie = IU if !mi(IU)
rename IV erhvervsuddannelse 
replace erhvervsuddannelse = IW if !mi(IW)
rename IX professionsbachelor 
replace professionsbachelor = IY if !mi(IY)
rename IZ bachelor 
replace bachelor = JA if !mi(JA)
drop IO IQ IS IU IW IY JA

label define educ_lbl 0 "Begyndt" 1 "Fuldført"
foreach var in grundskole klasse10 STU gymnasie erhvervsuddannelse professionsbachelor bachelor {
	replace `var' = "0" if `var' == "Begyndt"
	replace `var' = "1" if `var' == "FuldfÃ¸"
	
	destring `var', replace 
	label values `var' educ_lbl
}


// Education: Plans
rename JB gymnasie_plan 
rename JC erhvervsuddannelse_plan
rename JD professionsbachelor_plan
rename JE bachelor_plan
rename JF kandidat_plan



// Standardizing Cognitive Measures 
foreach var in cognitive_score math_score raven_score assignment_game_score {
	sum `var'
	gen `var'_std = (`var' - r(mean))/(r(sd))
}



// Dataset for Combining with Childhood Predictability Dataset
keep pnr ResponseStatus timetakenseconds Extraversion Agreeableness 	///
	 Conscientiousness Neuroticism Openness assignment_game* 			///
	 ocean_* cognitive_score math_score raven_score

rename ResponseStatus   ResponseStatus_2024
rename timetakenseconds timetakenseconds_2024

save "$data\2024_cognitive.dta", replace