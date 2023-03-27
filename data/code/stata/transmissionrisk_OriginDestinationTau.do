********************************************************************************
*                   transmissionrisk_OriginDestinationTau.do file:             *
*                                                                              *
*                  Prepare transmissionrisk_OriginDestinationTau.dta           *  
********************************************************************************
args temp_folder output_file crises_integers_do


use "`temp_folder'/transmissionrisk_FirmCountryQuarter.dta", clear


* Drop domestic firms' views about own country
drop if country_iso2 == loc_iso2
destring sic, gen(sic_int)


** Collapse to origin-destination-quarter level
foreach type_firms in ALL FIN NFC {

	preserve
		// Select sample
		if "`type_firms'" == "FIN" {
			gen fin = (sic_int >= 6000 & sic_int < 6800)
			keep if fin == 1
		}
		
		else if "`type_firms'" == "NFC" {
			gen fin = (sic_int >= 6000 & sic_int < 6800)
			keep if fin == 0
		}
		
		// Count unique firms
		bys gvkey country_iso2 dateQ: gen nr_of_firms = 1 if _n == 1
		
		// Collapse
		gcollapse (mean) CountryRisk_less_noisy risk (sum) nr_of_firms ///
			, by(country_iso2 loc_iso2 dateQ)
		// Rename
		
		ren CountryRisk_less_noisy TransmissionRisk`type_firms'
		
		// ren risk TransmissionRisk`type_firms'
		ren nr_of_firms nr_of_firms`type_firms'
		tempfile file_`type_firms'
		save "`file_`type_firms''", replace
	restore
}


use "`file_ALL'", clear
merge 1:1 country_iso2 loc_iso2 dateQ using "`file_FIN'"
drop _merge
merge 1:1 country_iso2 loc_iso2 dateQ using "`file_NFC'"
drop _merge


**  Merge in crises
tempfile parent_data
save "`parent_data'", replace
import delimited "`temp_folder'/crises.csv", clear varnames(1)
do "`crises_integers_do'"
merge 1:m country_iso2 dateQ using "`parent_data'"
drop _merge


** Collapse to origin-destination-tau level

* > 10 firms and local crisis
keep if nolocal != "yes"  
keep if nr_of_firmsALL > 10  

* house keeping
replace crisis_id = 0 if crisis_id == .
ren crisis_id crisis_nr

* reshape to tuck type={ALL,FIN,NFC} into a new vaiable
reshape long TransmissionRisk nr_of_firms ///
	, i(country_iso2 loc_iso2 dateQ crisis_nr) j(type) string
	
* EXCLcrisis and WITHcrsisi
gen TransmissionRiskEXCLCrisis = TransmissionRisk if crisis_nr == 0
gen TransmissionRiskCrisis = TransmissionRisk if crisis_nr > 0

* average over quarters to tau
collapse (mean) TransmissionRisk TransmissionRiskEXCLCrisis ///
	TransmissionRiskCrisis nr_of_firms ///
	, by(country_iso2 loc_iso2 type crisis_nr)

* fixed effects and other useful variables
egen crisis_id = group(country_iso2 crisis_nr) if crisis_nr != 0
egen crisisfull_id = group(country_iso2 crisis_nr)
encode country_iso2, gen(country_id)
encode loc_iso2, gen(hq_id)
encode type, gen(type_id)
	
* standardize by the same standard deviation
qui levelsof type, local(type) clean
foreach t of local type {
	qui su TransmissionRisk if type == "`t'"
	foreach a in TransmissionRisk TransmissionRiskEXCLCrisis TransmissionRiskCrisis {
		replace `a' = `a' / r(sd) if type == "`t'"
	}
}

* proper TransmissionRiskEXCLCrisis
gen mTREXCL = TransmissionRiskEXCLCrisis
replace mTREXCL = . if mTREXCL == 0
sort country_iso2 loc_iso2 type mTREXCL
by country_iso2 loc_iso2 type: replace mTREXCL = mTREXCL[_n-1] if mTREXCL == .


* TransmissionRisk - meanTransmissionRiskEXCL
gen TransmissionRisk_dm = TransmissionRisk - mTREXCL


compress
save "`output_file'", replace
