********************************************************************************
*                          worldscope_import.do file:                          *
*                                                                              *
*                Prepare worldscope.dta and worldscope_FirmCountry.dta         *  
********************************************************************************
args input_file compustat_na_file compustat_global_file firmcountryyear_output_file firmcountry_output_file


use "`input_file'", clear
	
*Keep only capex nonmissing
keep if segment_sale != .

*Rename
ren Country_In country_name
ren Country_In_iso3C country_iso3

*Convert to USD
replace segment_sale = segment_sale * (1/exchangerate)

*Go to firm-year-country level, take sum over product segments
sort ws_id year country_iso3 segment
collapse (sum) segment_sale (first) ticker cusip sedol isin country_name, ///
	by(ws_id year country_iso3)
	
*Remove those with negative sales
drop if segment_sale < 0

*Generate dummy
gen sale_seg_dummy = (segment_sale!=.)

*Bring in CUSIP-to-GVKey mapping
preserve
	import delimited "`compustat_na_file'" ///
		, stringcols(_all) clear
		
	// cusip is 9 digits
	drop if cusip == ""
	
	keep cusip gvkey conm year1 year2
	destring year*, replace
	
	tempfile a
	save "`a'", replace
restore
merge m:1 cusip using "`a'"
drop if _merge == 2

*Discard matches outside of year range
foreach var of varlist gvkey conm {
	replace `var' = "" if _merge == 3 & !inrange(year, year1, year2)
}
drop _merge year1 year2

*Bring in ISIN-to-GVKey mapping
preserve
	import delimited "`compustat_global_file'" ///
		, stringcols(_all) clear
		
	// cusip is 9 digits
	drop if isin == ""
	
	keep isin gvkey conm year1 year2
	destring year*, replace
	
	tempfile a
	save "`a'", replace
restore
merge m:1 isin using "`a'", update
drop if _merge == 2

*Discard matches outside of year range
foreach var of varlist gvkey conm {
	replace `var' = "" if _merge == 3 & !inrange(year, year1, year2)
}
drop _merge year1 year2

*Bring in SEDOL-to-GVKey mapping
preserve
	import delimited "`compustat_global_file'" ///
		, stringcols(_all) clear
		
	// cusip is 9 digits
	drop if sedol == ""
	
	keep sedol gvkey conm year1 year2
	destring year*, replace
	
	tempfile a
	save "`a'", replace
restore
merge m:1 sedol using "`a'", update
drop if _merge == 2

*Discard matches outside of year range
foreach var of varlist gvkey conm {
	replace `var' = "" if _merge == 3 & !inrange(year, year1, year2)
}
drop _merge year1 year2

*Bring in TIC-to-GVKey mapping
preserve
	import delimited "`compustat_na_file'" ///
		, stringcols(_all) clear
		
	// cusip is 9 digits
	drop if tic == ""
	
	keep tic gvkey conm year1 year2
	destring year*, replace
	ren tic ticker
	
	tempfile a
	save "`a'", replace
restore
merge m:1 ticker using "`a'", update
drop if _merge == 2

*Discard matches outside of year range
foreach var of varlist gvkey conm {
	replace `var' = "" if _merge == 3 & !inrange(year, year1, year2)
}
drop _merge year1 year2
	
*Drop those without GVKey
drop if gvkey == ""

*There are some duplicates in terms of gvkey, year, and country_iso3
duplicates tag gvkey year country_iso3, gen(x)
sort gvkey year country_iso3 isin // last variable is irrelevant
bys gvkey year country_iso3: egen mean_dummy = mean(sale_seg)
by gvkey year country_iso3: drop if _n > 1 & mean_dummy == sale_seg
drop x mean_dummy

*Make sure unique in terms of GVKey-year
duplicates report gvkey year country_iso3
assert r(N) == r(unique_value)

drop ws_id
la var segment_sales "Sales to geographic segment (in USD)"

*Save
compress
save "`firmcountryyear_output_file'", replace

*Save time invariant version
collapse (max) sale_seg_dummy (mean) segment_sales, by(gvkey country_iso3)
la var segment_sales "Sales to geographic segment (in USD)"
save "`firmcountry_output_file'", replace
