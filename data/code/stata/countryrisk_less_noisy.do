********************************************************************************
*                         countryrisk_less_noisy.do file:                      *
*                                                                              *
*                  Define CountryRisk_ict, Create FirmCountryQuarter.dta       *  
********************************************************************************
args input_file output_file

use "`input_file'", clear

keep gvkey country_iso2 country_name dateQ loc_iso2 sic risk exposure company_name


** Create CountryRisk_less_noisy = Exposure_ict * tilde(CountryRisk_ct)

preserve

	// Keep perceptions by foreign firms for tilde(CountryRisk_ct)
	keep if country_iso2 != loc_iso2
	// Take average
	gcollapse (mean) risk, by(country_iso2 dateQ)
	// Residualize
	egen country_fe = group(country_iso2)
	reghdfe risk, absorb(i.country_fe i.dateQ) residuals(risk_resid)
	
	* country-quarter
	// Add mean back
	qui su risk
	replace risk_resid = risk_resid + r(mean)
	// Keep relevant
	keep country_iso2 dateQ risk_resid
	tempfile a
	save "`a'", replace
	
restore


merge m:1 country_iso2 dateQ using "`a'"
drop _merge

gen CountryRisk_less_noisy = exposure * risk_resid


compress
save "`output_file'	", replace
