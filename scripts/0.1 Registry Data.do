// Author: Ida Maria Hartmann
// Last edited: 25.09.2024


// Demographics
gen female = koen == 2
gen foed_aar = year(foed_dag)

gen single = 0 
replace single = 1 if mi(e_faelle_id)

gen civstatus = . 
replace civstatus = 1 if civst == "G"	// Married 
replace civstatus = 2 if civst == "F"	// Divorced
replace civstatus = 3 if civst == "E" 	// Widow
replace civstatus = 4 if civst == "P"	// Same sex partnership
replace civstatus = 5 if civst == "O"	// Divorced, same sex partnership
replace civstatus = 6 if civst == "L"	// Widow same sex partnership
replace civstatus = 7 if civst == "U"	// Unmarried
replace civstatus = 8 if civst == "D"	// Dead
label define civ 1 "Married" 2 "Divorced from marriage" 3 "Widow from marriage"	///
				 4 "Same-sex civil partnership" 5 "Divorced from same-sex"		///
				 6 "Widow from same-sex" 7 "Unmarried, no partnership" 8 "Dead"
label values civstatus civ

gen educode = afsp1e
replace educode = "" if h1 == "90"	// Unspecified

lab define fam 1 "Married" 2 "Same-sex partnership" 3 "Cohabitants w children"	///
			   4 "Cohabitants w/o children" 5 "Single"
label var familie_type fam 

destring kom, gen(municipality)

 
// Income and Assets 
gen grossinc  = perindkialt 
gen earnedinc = erhvervsindk_13
gen dispinc   = dispon_13 - lejev_egen_bolig 

winsor2 earnedinc, cuts(1 99) by(year foed_aar)

gen house_val		= 0 
replace house_val 	= koejd if year <= 1993 
replace house_val 	= ejendomsvurdering if year >= 1994 

egen total_ass		= rsum(oblakt bankakt pantakt kursakt house_val)
egen total_debt		= rsum(bankgaeld pantgaeld oblgaeld)

gen house_equity 	= house_val - oblgaeld

gen homeowner 		= 0 
replace homeowner 	= 1 if (koejd > 0 & koejd != .) 
 
// Earnings, year t-1
by pnr (year), sort: gen earnedinc_prev1 = earnedinc[_n-1]
gen ln_earnedinc_prev1 = ln(earnedinc_prev1)
winsor2 earnedinc_prev1, cuts(1 99) by(year)
winsor2 ln_earnedinc_prev1, cuts(1 99)

// Realized Earnings Growth 
gen earnedinc_growth = (earnedinc - earnedinc_prev1)/earnedinc_prev1
winsor2 earnedinc_growth, cuts(2 98)
 
// Income at age 40 
by pnr (year), sort: gen temp = earnedinc if alder == 40 
winsor2 temp, by(year) cuts(1 99)
by pnr (year), sort: egen earnedinc_age40   = min(temp)
by pnr (year), sort: egen earnedinc_age40_w = min(temp_w)
drop temp temp_w

// Average Income age 30-39
by pnr (year), sort: egen temp = mean(earnedinc) if alder >= 30 & alder < 40
by pnr (year), sort: egen earnedinc_age3039 = min(temp)
winsor2 earnedinc_age3039, cuts(1 99)
drop temp
 

// Labor Market  
destring pstill, replace 
destring psoc_status_kode, replace 

gen wageearner = 0 if (pstill != . & year < 2008) | (psoc_status_kode != . & year >= 2008)
replace wageearner = 1 if ((pstill >= 31 & pstill <= 37 & pstill != .) | (pstill >= 71 & pstill <= 77 & pstill != .)) & year < 2008
replace wageearner = 1 if (psoc_status_kode >= 131 & psoc_status_kode <= 137 & psoc_status_kode != .) & year >= 2008

gen selfemp = 0 if (pstill != . & year < 2008) | (psoc_status_kode != . & year >= 2008)
replace selfemp = 1 if pstill < 31 & pstill != . & year < 2008
replace selfemp = 1 if psoc_status_kode <= 120 & psoc_status_kode != . 

gen out_labor = 0 if (pstill != . & year < 2008) | (psoc_status_kode != . & year >= 2008)
replace out_labor = 1 if ((pstill >= 41 & pstill <= 56 & pstill != .) | (pstill >= 89 & pstill <= 90 & pstill != .)) & year < 2008
replace out_labor = 1 if (psoc_status_kode >= 300 & psoc_status_kode <= 313) | psoc_status_kode == 513 

gen student = 0 if (pstill != . & year < 2008) | (psoc_status_kode != . & year >= 2008)
replace student = 1 if pstill == 91 & year < 2008
replace student = 1 if psoc_status_kode == 511 & year >= 2008

gen grossunemp = 0 if (pstill != . & year < 2008) | (psoc_status_kode != . & year >= 2008)
replace grossunemp = 1 if(pstill == 40 | pstill == 45 | pstill == 46 | pstill == 47 | pstill == 48 | pstill == 51 | pstill == 52 | pstill == 57) & year < 2008
replace grossunemp = 1 if (psoc_status_kode == 200 | psoc_status_kode >= 314 & psoc_status_kode <= 318) & year >= 2008

gen netunemp = 0 if (pstill != . & year < 2008) | (psoc_status_kode != . & year >= 2008)
replace netunemp = 1 if (pstill == 40 | pstill == 57) & year < 2008
replace netunemp = 1 if psoc_status_kode == 200 & year >= 2008 

label var disco_kode "Occupation code (ISCO)"
 

// Unemployment shock 
gen unemp = (arledgr_brutto > 0 & year >= 2008) | (arledgr > 0 & year < 2008)
replace unemp = . if (mi(arledgr_brutto) & year >= 2008) | (mi(arledgr) & year < 2008)
lab var unemp "Gross unemployment (Based on arledgr_brutto)"

// Unemployment shock of min. 1 month 
gen unemp_month = (arledgr_brutto > 83  & year >= 2008) | (arledgr > 83 & year < 2008)
replace unemp_month = . if (mi(arledgr_brutto) & year >= 2008) | (mi(arledgr) & year < 2008)
lab var unemp_month "Gross unemployment of min. 1 month (Based on arledgr_brutto)"

// Length of unemployment spell (days)
gen unemp_days = arledgr_brutto/2.739726 
replace unemp_days = arledgr/2.739726 if year < 2008
lab var unemp_days "Lenght of Unemployment Spell (Days)"

// Total number of of unemployment days age 30-39 
by pnr (year), sort: egen temp = sum(unemp_days) if alder >= 30 & alder < 40
by pnr (year), sort: egen total_unempdays_age3039 = min(temp)
drop temp

// Average length of unemployment spell age 30-39 
by pnr (year), sort: egen temp = mean(unemp_days) if alder >= 30 & alder < 40
by pnr (year), sort: egen avg_unempdays_age3039 = min(temp)
drop temp

// Unemployment Insurance 
gen ui = 0 
replace ui = 1 if forsikringskategori_kode == "H"
replace ui = 2 if forsikringskategori_kode == "D"
label var ui "Unemployment Insurance Coverage"
label define insurance 0 "Not insured" 1 "Full time coverage" 2 "Part time coverage"
label values ui insurance

gen d_akasse = . 
replace d_akasse = 0 if akasse_id == 0 
replace d_akasse = 1 if akasse_id > 0 & !mi(akasse_id)
 
// Sector Information
gen start = arb_sektorkode
merge m:1 start using "P:\Workdata\707906\imh\Peer Effects\Data\n_sektorkode_gr4_sb.dta"
drop if _merge == 2 
drop _merge 

// Define private and public sector. Sektor: 1 = private, 2 = state, 3 = municipality/region
gen 	sector = 1 if substr(SEKTORKODE_GR4_SB,1,2) == "03" | substr(SEKTORKODE_GR4_SB,1,2) == "04"
replace sector = 2 if substr(SEKTORKODE_GR4_SB,1,2) == "01" | substr(SEKTORKODE_GR4_SB,1,2) == "02"
label define sec 1 "Private" 2 "Public" 
label values sector sec


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

destring hfpria, replace
by pnr (year), sort: egen educ_years= max(hfpria)
replace educ_years = educ_years/12


// Industry 
replace persbrc = "" if persbrc == "     ."
destring persbrc, replace

gen industry = arb_hoved_bra_db07
replace industry = persbrc if year <= 2007


// Industry Codes 
gen db03 = industry if year <= 2007
sort db03 
merge m:1 db03 using "P:\Workdata\707906\imh\Peer Effects\Data\DB03" 
tab _merge 
tab _merge if db03 != .
tab year _merge, row 
drop if _merge == 2 
rename _merge _mergedb03

gen db07 = industry if year >= 2008
sort db07 
merge m:1 db07 using "P:\Workdata\707906\imh\Peer Effects\Data\DB07"
tab _merge 
tab _merge if db07 != .
tab year _merge, row 
drop if _merge == 2 
rename _merge _mergedb07

foreach i in 3 4 5 {
	gen db03_db07_grp`i' 	 = db03_grp`i' if year <= 2007
	replace db03_db07_grp`i' = db07_grp`i' if year >= 2008
}

* Keep industry code unchanged, remember that code 999999 means "unspecified"
* Do not use industry = 999999 or missing when creating 1st digit and 2nd digit groups 
* Check that no unique industry codes, 1st digit groups and 2nd digit groups are the same all years 2008-2017

egen ind1 = group(db03_db07_grp5) if db03_db07_grp5 != "Uoplyst aktivitet" & db03_db07_grp5 != ""
egen ind2 = group(db03_db07_grp4) if db03_db07_grp4 != "Uoplyst aktivitet" & db03_db07_grp4 != ""
egen ind3 = group(db03_db07_grp3) if db03_db07_grp3 != "Uoplyst aktivitet" & db03_db07_grp3 != ""
tab ind1	// 20 groups 
tab ind2 	// 43 groups
tab ind3 	// 81 groups 
lab var ind1 "Industry level 1"
lab var ind2 "Industry level 2"
lab var ind3 "Industry level 3"

// Missing and unspecified 
*tab year if ind1 == . 
*tab year if ind2 == . 
*tab year if ind3 == . 



// OCCUPATION
gen ocp = disco_kode
label var ocp "Occupation code (ISCO)"

replace ocp = "" if ocp == "000000" | ocp == "999999" | ocp == "99900" 

gen miss_ocp = 0 
replace miss_ocp = 1 if ocp == ""
tab year miss_ocp, row 	

gen ocp1 = substr(ocp,1,1)
destring ocp1, replace

tab ocp1 
