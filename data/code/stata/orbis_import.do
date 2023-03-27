********************************************************************************
*                             orbis_import.do file:                            *
*                                                                              *
*                        		Prepare orbis.dta                              *  
********************************************************************************
args input_file output_file


use "`input_file'", clear


* Keep cross section of 2016
keep if year == 2016
drop year

* House keeping
drop index bvdID
ren level_2 country_iso2
tostring gvkey, replace
replace gvkey = "0" + gvkey if length(gvkey) == 5
replace gvkey = "00" + gvkey if length(gvkey) == 4


sort gvkey country_iso2
order gvkey country_iso2
save "`output_file'", replace
