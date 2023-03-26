********************************************************************************
*                      transmissionrisk_OriginFirmTau.do file:                 *
*                                                                              *
*                     Prepare transmissionrisk_OriginFirmTau.dta               *  
********************************************************************************

use "${DATA}/temp/transmissionrisk_FirmCountryQuarter.dta", clear


**  Merge in crises
tempfile parent_data
save "`parent_data'", replace
do "${DATA}/code/crises_integers.do"
merge 1:m country_iso2 dateQ using "`parent_data'"
drop _merge



** House keeping

* exclude local firms
drop if loc_iso2 == country_iso2

* drop global crises
drop if nolocal == "yes" 
drop nolocal

* skip Norway crisis #1  
drop if country_iso2 == "NO" & crisis_id == 1

* define non-crisis times
replace crisis_id = 0 if crisis_id == . 

* ren CountryRisk_less_noisy TransmissionRisk
ren risk TransmissionRisk 



** Collapse to origin-FIRM-tau
ren crisis_id crisis_nr
keep gvkey loc_iso2 country_iso2 dateQ TransmissionRisk crisis_nr sic
gen nr_of_periods = 1
collapse (mean) TransmissionRisk (first) loc_iso2 sic ///
	(sum) nr_of_periods, by(gvkey country_iso2 crisis_nr)

* standardize
qui su TransmissionRisk
foreach a in TransmissionRisk {
	replace `a' = `a' / r(sd)
}

* proper TransmissionRiskEXCLCrisis
gen mTREXCL = TransmissionRisk
replace mTREXCL = . if crisis_nr > 0
sort country_iso2 gvkey mTREXCL
by country_iso2 gvkey: replace mTREXCL = mTREXCL[_n-1] if mTREXCL == .

* demeaned
gen TransmissionRisk_dm = TransmissionRisk - mTREXCL

* identifiers
encode loc_iso2, gen(loc_id)
encode gvkey, gen(firm_id)
egen crisis_id = group(country_iso2 crisis_nr) if crisis_nr != 0
encode country_iso2, gen(country_id)

* financial indicator
destring sic, gen(sic_int)
gen financial_indicator = (sic_int >= 6000 & sic_int < 6800)


compress
save "${DATA}/final/transmissionrisk_OriginFirmTau.dta", replace
