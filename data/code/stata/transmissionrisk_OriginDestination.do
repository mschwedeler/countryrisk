********************************************************************************
*                  transmissionrisk_OriginDestination.do file:                 *
*                                                                              *
*                  Prepare transmissionrisk_OriginDestination.dta              *  
********************************************************************************
args temp_folder output_file crises_integers_do


use "`temp_folder'/transmissionrisk_FirmCountryQuarter.dta", clear


** Merge in crises
tempfile parent_data
save "`parent_data'", replace
import delimited "`temp_folder'/crises.csv", clear varnames(1)
do "`crises_integers_do'"
merge 1:m country_iso2 dateQ using "`parent_data'"
drop _merge


* house keeping
replace crisis_id = 0 if crisis_id == .
ren crisis_id crisis_nr


* drop domestic firms' views about own country
drop if country_iso2 == loc_iso2


** Collapse to origin-destination level
foreach type_crises in ALL CRISIS NONCRISIS {
	di "`type_crises'"

	preserve
		// select sample
		if "`type_crises'" == "CRISIS" {
			// drop global crises, so local or no crises are left
			drop if nolocal == "yes"
			// define TR for only local crises
			gen TransmissionRisk = CountryRisk_less_noisy if crisis_nr > 0
			// gen TransmissionRisk = risk if crisis_nr > 0
		}
		
		else if "`type_crises'" == "NONCRISIS" {
			// define TR for neither local nor global crisis
			gen TransmissionRisk = CountryRisk_less_noisy if crisis_nr == 0
			// gen TransmissionRisk = risk if crisis_nr == 0
		}
		
		else if "`type_crises'" == "ALL" {
			gen TransmissionRisk = CountryRisk_less_noisy
			// gen TransmissionRisk = risk
		}
		
		// count unique firms (in a complicated way)
		bys gvkey country_iso2: gen nr_of_firms = 1 if _n == 1
		// collapse
		gcollapse (mean) TransmissionRisk (sum) nr_of_firms ///
			, by(country_iso2 loc_iso2)
		// rename
		ren TransmissionRisk TransmissionRisk`type_crises'
		ren nr_of_firms nr_of_firms`type_crises'
		tempfile file_`type_crises'
		save "`file_`type_crises''", replace
	restore
}

collapse (first) country_name, by(country_iso2 loc_iso2)
merge 1:1 country_iso2 loc_iso2 using "`file_ALL'"
drop _merge
merge 1:1 country_iso2 loc_iso2 using "`file_CRISIS'"
drop _merge
merge 1:1 country_iso2 loc_iso2 using "`file_NONCRISIS'"
drop _merge


compress
save "`output_file'", replace
