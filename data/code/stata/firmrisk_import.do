********************************************************************************
*                              Import Firm Risk                                *
********************************************************************************
args input_file output_file


import delimited "`input_file'", clear


* Collapse to firm-quarter units
gen dateQ = qofd(date(date_earningscall, "DMY"))
format %tq dateQ
collapse (mean) risk (first) country_iso2=hqcountrycode, by(gvkey dateQ)


***----- START: Backfill dates for firm-quarter units -----***

* a) Balance panel
fillin gvkey dateQ


* b) Create indicator = 1 if missing BETWEEN  two non-missing
gsort gvkey -dateQ
by gvkey: gen x = 1 if risk != .
by gvkey: replace x = x[_n-1] if x[_n-1] != . & x == .
sort gvkey dateQ
by gvkey: gen y = 1 if risk != .
by gvkey: replace y = y[_n-1] if y[_n-1] != . & y ==.
gen z = x + y if risk == .
drop x y


* b) Create indicator to backfill up to 3 quarters after a conference call
sort gvkey
by gvkey: gen x = 1 if risk == . & (risk[_n-1] != . | ///
	risk[_n-2] != . | risk[_n-3] != . | risk[_n-4] != .)

	
* c) Actual backfill
foreach v of varlist risk country_iso2 {
	by gvkey: replace `v' = `v'[_n-1] if x == 1 & z == 2
}


* d) Drop those observations created by fillin but not backfilled
drop if risk == .


* e) Clean
tab _fillin
drop _fillin x z



***----- END: Backfill dates for firm-quarter units -----***

* Drop before 2002
drop if yofd(dofq(dateQ)) < 2002
drop if country_iso2 == ""

* Generate average by country of headquarter
gen nroffirms = 1
collapse (mean) risk (sum) nroffirms, by(country_iso2 dateQ)

* Keep only if at least 5 firms by country-quarter
keep if nroffirms >= 5 & nroffirms != .
ren risk firmrisk_5plus

keep country_iso2 dateQ firmrisk_5plus
sort country_iso2 dateQ
order country_iso2 dateQ
compress
save "`output_file'", replace
