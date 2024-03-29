********************************************************************************
*                                wui_import.do file:                           *
*                                                                              *
*                                 Prepare wuiQ.dta                             *  
********************************************************************************
args input_file output_file


import excel "`input_file'", ///
	sheet("T2") firstrow allstring clear
	
	
* Reshape to long
ren (*) (country_*)
ren country_year year
reshape long country_, i(year) j(country_iso3) string


* House keeping
destring country_, replace
ren country_ wui
gen dateQ = quarterly(year, "YQ")
format dateQ %tq
drop year


* Standardize
qui su wui
gen wui_std = wui / r(sd)


* Log difference
egen cid = group(country_iso3)
xtset cid dateQ
gen d_log_wui_std = log(wui_std) - log(l.wui_std)
drop cid
xtset, clear


* Save
sort country_iso3 dateQ
order country_iso3 dateQ
compress
save "`output_file'", replace	
