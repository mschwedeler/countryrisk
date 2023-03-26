********************************************************************************
*                              epu_national.do file:                           *
*                                                                              *
*                            Prepare epu_national.dta                          *  
********************************************************************************


import excel "$RAW_DATA/epu_national/All_Country_Data.xlsx", ///
	sheet("EPU") firstrow allstring clear

	
drop AC-AJ
drop if _n > 433
gen ym = Year + "-" + Month
gen dateM = monthly(ym, "YM")
format dateM %tm
drop ym GEPU_current GEPU_ppp Year Month
	
	
*Reshape to long
ren (*) (country_*)
ren country_dateM dateM
reshape long country_, i(dateM) j(country_name) string


*House keeping
destring country_, replace
ren country_ epu_national
drop if inlist(country_name, "MainlandChina", "SCMPChina")

gen country_iso3 = ""
replace country_iso3 = "AUS" if country_name == "Australia"
replace country_iso3 = "BRA" if country_name == "Brazil"
replace country_iso3 = "CAN" if country_name == "Canada"
replace country_iso3 = "CHL" if country_name == "Chile"
replace country_iso3 = "CHN" if country_name == "China"
replace country_iso3 = "COL" if country_name == "Colombia"
replace country_iso3 = "FRA" if country_name == "France"
replace country_iso3 = "DEU" if country_name == "Germany"
replace country_iso3 = "GRC" if country_name == "Greece"
replace country_iso3 = "IND" if country_name == "India"
replace country_iso3 = "IRL" if country_name == "Ireland"
replace country_iso3 = "ITA" if country_name == "Italy"
replace country_iso3 = "JPN" if country_name == "Japan"
replace country_iso3 = "KOR" if country_name == "Korea"
replace country_iso3 = "MEX" if country_name == "Mexico"
replace country_iso3 = "NLD" if country_name == "Netherlands"
replace country_iso3 = "RUS" if country_name == "Russia"
replace country_iso3 = "SGP" if country_name == "Singapore"
replace country_iso3 = "ESP" if country_name == "Spain"
replace country_iso3 = "SWE" if country_name == "Sweden"
replace country_iso3 = "GBR" if country_name == "UK"
replace country_iso3 = "USA" if country_name == "US"
qui count if country_iso3 == ""
assert r(N) == 0
drop country_name

*Current data is by country and month; take average by country and quarter
gen dateQ = qofd(dofm(dateM))
format dateQ %tq
collapse (mean) epu_national, by(country_iso3 dateQ)

*House keeping
qui su epu_national
gen epu_national_std = epu_national / r(sd)
egen cid = group(country_iso3)
xtset cid dateQ
gen d_log_epu_national_std = log(epu_national_std) - log(l.epu_national_std)
drop cid
xtset, clear
sort country_iso3 dateQ
order country_iso3 dateQ
compress
save "$DATA/temp/epu_national.dta", replace
