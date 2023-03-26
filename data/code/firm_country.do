********************************************************************************
*                            firm_country.do file:                             *
*                                                                              *
*                       Prepare analysis_FirmCountry.dta                       *  
********************************************************************************


*** Start with data at firm-country-quarter level
use "${RAW_DATA}/refinitiv/scores.dta", clear
drop if yofd(dofq(dateQ)) > 2019


*** Take average by gvkey-country
collapse (mean) exposure risk sentiment (first) company_name loc_iso2, by(gvkey country_iso2)


* Add countryname for country of score
ren country_iso2 iso2
merge m:1 iso2 using "${DATA}/temp/iso2_names.dta"
drop if _merge == 2
drop _merge
merge m:1 iso2 using "${DATA}/temp/iso2_iso3.dta"
drop if _merge == 2
drop _merge
ren iso2 country_iso2
ren iso3 country_iso3


* Add updated ORBIS
sort gvkey country_iso2
merge 1:1 gvkey country_iso2 using "${DATA}/temp/orbis.dta", sorted
drop if _merge == 2
drop _merge


* Add Worldscope
merge 1:1 gvkey country_iso3 using "${DATA}/temp/worldscope_FirmCountry.dta"
drop if _merge == 2
drop _merge


* Add countryname for hq
ren loc_iso2 iso2
ren country_name c
merge m:1 iso2 using "${DATA}/temp/iso2_names.dta"
drop if _merge == 2
drop _merge
ren country_name loc_cname
ren iso2 loc_iso2
ren c country_name


* Huge assumption: If firm has at least one capex_seg_dummy non-missing, then missing means zero
sort gvkey
by gvkey: egen x = sum(sale_seg_dummy)
replace sale_seg_dummy = 0 if sale_seg_dummy == . & x > 0
drop x


*** House keeping

* Standardize score
foreach v of varlist exposure risk sentiment {
	qui su `v'
	gen `v'_std = `v' / r(sd)
}

* Other variables
gen hq = (country_iso2 == loc_iso2)
egen country_id = group(country_name)
egen firm_id = group(gvkey)

* Save
sort gvkey country_iso2
order gvkey country_iso2
compress
save "${DATA}/final/analysis_FirmCountry.dta", replace
