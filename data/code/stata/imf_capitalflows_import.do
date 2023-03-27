********************************************************************************
*                        imf_capitalflows_import.do file:                      *
*                                                                              *
*                     Prepare grcf_capital_flows.dta                           *  
********************************************************************************

args bop_codes_file bop_timeseries_file countrycodes_file output_file temp_folder

di "bop_codes_file `bop_codes_file'"
di "bop_timeseries_file `bop_timeseries_file'"
di "countrycodes_file `countrycodes_file'"
di "output_file `output_file'"
di "temp_folder `temp_folder'"

** Make Crosswalk for IMF Codes

import excel "`bop_codes_file'", sheet("toinclude") firstrow clear

rename ii* codeii*
rename bop* codebop*
reshape long code, i(lmns_id indicator_name) j(type) str

gen lmns_suffix="_x_Om_i_ni" if regexm(type,"asset")==1
replace lmns_suffix="_x_Om_ni_i" if regexm(type,"liability")==1
gen lmns_prefix="Q_" if regexm(type,"iip")==1
replace lmns_prefix="F_" if regexm(type,"bop")==1
gen lmns_not=lmns_prefix+lmns_id+lmns_suffix
keep code lmns_not
rename code indicator_code

save "`temp_folder'/lmns_imf_crosswalk.dta", replace


** Import and Prepare Raw IMF Data 

import delimited "`bop_timeseries_file'", varnames(nonames) clear

save "`temp_folder'/imf_bop.dta", replace
use "`temp_folder'/imf_bop.dta", clear

rename v1 country
rename v2 ccode
rename v3 indicator_name
rename v4 indicator_code
rename v5 attribute
drop if regexm(indicator_name,", National Currency")==1
drop if regexm(indicator_name,", Euros")==1
cap describe
local var_num=r(k)-1
forvalues i=6/`var_num' {
	cap tostring v`i', replace
	local temp=v`i'[1]
	rename v`i' q`temp'
	destring q`temp', force replace
}

save "`temp_folder'/imf_bop_smaller.dta", replace

drop v*
drop if _n==1
compress
destring ccode, replace
mmerge ccode using "`countrycodes_file'", umatch(ifscode) ukeep(wbcode)
keep if _merge==3
drop _merge
rename wbcode iso_country_code
replace iso_co="EMU" if iso_co=="EUR"

save "`temp_folder'/imf_bop_smaller.dta", replace



** Separate Quartelry and Annual Series, Generate Flow Ratios

use "`temp_folder'/imf_bop_smaller.dta", clear


* Store first and last year covered in data as f_year and l_year respectively.
local i="first"
foreach x of varlist q* {
	if "`i'"=="first" {
		local f_year = substr("`x'",2,4)
		local i = "not"
	}
	local l_year = substr("`x'",2,4)
}

* Separate annual and quarterly time series. Apply crosswalk.
foreach freq in "y" "q" {
	use "`temp_folder'/imf_bop_smaller.dta", clear
	if "`freq'"=="q"{
		forvalues year=`f_year'/`l_year' {
			if `year' < `l_year' {
				drop q`year'
			}
		}
	}
	
	if "`freq'"=="y"{
		forvalues year=`f_year'/`l_year' {
			drop q`year'Q*
		}
	}


	keep if attribute=="Value"
	drop attribute
	mmerge indicator_code using "`temp_folder'/lmns_imf_crosswalk.dta"
	keep if _merge==3

    // Reshape data so that each observation is a country-period, variables are stocks and flows.

	order iso_country_code
	collapse (lastnm) q*, by(iso_country_code indicator_name lmns_not indicator_code)
	reshape long q, i(iso_country_code indicator_name indicator_code lmns_not) j(date_`freq') str
	rename q value
	if "`freq'"=="q"{
		gen month=""
		local q_to_months "1mar 2jun 3sep 4dec"
		foreach q_month of local q_to_months {
		    replace month = substr("`q_month'",2,3) if substr(date_q,6,1)==substr("`q_month'",1,1)
		}
		gen date = date("30"+month+substr(date_q,1,4), "DMY")
		drop date_q
		gen date_q=qofd(date)
		format date_q %tq
		drop month date
	}
	cap destring date_`freq', replace

	drop indicator*
	reshape wide value, i(iso_co date_`freq') j(lmns_not) str
	renpfix value

	encode iso_co, gen(cid)
	tsset cid date_`freq'

    // Calculate flow ratios.

	foreach x of varlist F* {
		local Q=subinstr("`x'","F","Q",.)
		local f=subinstr("`x'","F","f",.)
		gen `f'=`x'/L.`Q'
	}

	save "`temp_folder'/imf_bop_lmns_regression_`freq'.dta", replace

}



** Interpolate to Annual Series, Merge to Extend Quarterly Series 

* Interpolate annual stock values.

use "`temp_folder'/imf_bop_lmns_regression_y.dta", clear
keep Q* iso_co date_y cid 
gen date_q=qofd(dofy(date_y)+364)
tsset cid date_q
tsfill
order cid date_q
foreach x of varlist Q* {
	bysort cid: ipolate `x' date_q , gen(i_`x')
	replace `x'=i_`x'
	drop i_`x'
}
keep cid date_q Q*
save "`temp_folder'/imf_bop_lmns_regression_ipolate.dta", replace


** Merge and recalculate flow ratio variables.

use "`temp_folder'/imf_bop_lmns_regression_q.dta", clear
mmerge cid date_q using "`temp_folder'/imf_bop_lmns_regression_ipolate.dta", update

* Total

gen F_Z_x_Om_i_ni=F_D_x_Om_i_ni+F_O_x_Om_i_ni+F_T_x_Om_i_ni+F_R_x_Om_i_ni
gen Q_Z_x_Om_i_ni=Q_D_x_Om_i_ni+Q_O_x_Om_i_ni+Q_T_x_Om_i_ni+Q_R_x_Om_i_ni  
gen f_Z_x_Om_i_ni=.

gen F_Z_x_Om_ni_i=F_D_x_Om_ni_i+F_O_x_Om_ni_i+F_T_x_Om_ni_i
gen Q_Z_x_Om_ni_i=Q_D_x_Om_ni_i+Q_O_x_Om_ni_i+Q_T_x_Om_ni_i
gen f_Z_x_Om_ni_i=.

gen F_Z_x_Om_ni_i_ex=F_O_x_Om_ni_i+F_T_x_Om_ni_i
gen Q_Z_x_Om_ni_i_ex=Q_O_x_Om_ni_i+Q_T_x_Om_ni_i
gen f_Z_x_Om_ni_i_ex=.

sort cid date_q
foreach x of varlist F* {
	local Q=subinstr("`x'","F","Q",.)
	local f=subinstr("`x'","F","f",.)
	replace `f'=`x'/L.`Q'
}
save "`temp_folder'/imf_bop_lmns_regression_q_ipolate.dta", replace


use "`temp_folder'/imf_bop_lmns_regression_q_ipolate.dta", clear
replace Q_Z_x_Om_i_ni=. if Q_Z_x_Om_i_ni<0
replace Q_Z_x_Om_ni_i=. if Q_Z_x_Om_ni_i<0

gen total_flows=(F_Z_x_Om_ni_i-F_Z_x_Om_i_ni)
gen total_stock=(Q_Z_x_Om_ni_i+Q_Z_x_Om_i_ni)
gen total_net=total_flows/L.total_stock

drop total_flows total_stock
drop Q_* F_*
*drop f_O_x_Om_ni_i 

rename f_B_x_Om_ni_i portfolio_debt_inflows
rename f_DB_x_Om_ni_i fdi_debt_inflows
rename f_DE_x_Om_ni_i fdi_equity_inflows
rename f_D_x_Om_ni_i  fdi_total_inflows
rename f_E_x_Om_ni_i  portfolio_equity_inflows
rename f_OL_x_Om_ni_i other_loans_inflows
rename f_T_x_Om_ni_i portfolio_total_inflows
rename f_Z_x_Om_ni_i total_inflows
rename f_Z_x_Om_ni_i_ex total_inflows_exFDI
rename f_O_x_Om_ni_i other_unknown

rename f_B_x_Om_i_ni portfolio_debt_outflows
rename f_DB_x_Om_i_ni fdi_debt_outflows
rename f_DE_x_Om_i_ni fdi_equity_outflows
rename f_D_x_Om_i_ni  fdi_total_outflows
rename f_E_x_Om_i_ni  portfolio_equity_outflows
rename f_OL_x_Om_i_ni other_loans_outflows
rename f_T_x_Om_i_ni portfolio_total_outflows
rename f_Z_x_Om_i_ni total_outflows

drop *_i_ni _merge

save "`output_file'", replace
