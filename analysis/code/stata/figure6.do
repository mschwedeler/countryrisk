args input_file output_file data_folder no_appendix

set scheme plotplain

quietly {

use "`input_file'", clear

keep if data == "all" 
drop global*


* Create crises variables

tempfile parent_data
save "`parent_data'", replace

do "`data_folder'/code/stata/crises_variables.do"
scalar sd_global = 2

merge 1:1 country_iso2 dateQ using "`parent_data'"
drop _merge


* Run loop over countries

local colist1 `""China", "Turkey", "Greece", "United States", "Brazil", "United Kingdom""'
local colist2 `""Russia", "Ireland", "Spain", "Thailand", "Egypt", "Hong Kong", "Japan""'
local colist3 `""Italy", "Iran", "Mexico", "Nigeria", "Norway", "Poland", "Venezuela""'
if `no_appendix' == 1 {
	keep if inlist(country_name, `colist1') | inlist(country_name,`colist2') | inlist(country_name,`colist3')
}
  
levelsof rankNumber, local(levels)

foreach i of local levels {

	di as result "===========NEXT COUNTRY==========="
	
	// Obtain quarters of crises: sd_global
	qui levelsof dateQ if rankNumber == `i' & (risk_resid > sd_global), local(crises) clean
	
	// Obtain country iso2 and name
	qui levelsof country_iso2 if rankNumber == `i', local(ciso2) clean
	qui levelsof country_name if rankNumber == `i', local(cname) clean
	noisily di "Plotting crises of `cname'..."

	// Define variable for points in scatter that are local-not-global
	tempvar forscatter
	gen `forscatter' = risk_resid if rankNumber == `i' & risk_resid > sd_global
	replace `forscatter' = . if global_crises == 1
	if "`ciso2'" == "IR" {
		// Manual intervention for Iran
		replace `forscatter' = risk_resid if rankNumber == `i' & dateQ == 208
	}

	// Define global crisis variable
	tempvar forscatter_global
	gen `forscatter_global' = risk_resid if global_crises == 1 & risk_resid > sd_global
	
	// Plot
	qui su risk_resid if rankNumber == `i'
	local max = r(max)
	local min = r(min)
	twoway (line risk_resid dateQ, lcolor(midblue) lwidth(thick)) ///
		(scatter `forscatter' dateQ, msymbol(circle) msize(large) mcolor(red) ///
		mlwidth(medium) mlcolor(black)) ///
		(scatter `forscatter_global' dateQ, ///
		msymbol(circle) msize(large) mcolor(gs10) mlwidth(medium) mlcolor(black)) ///
		if rankNumber == `i', yline(`=sd_global', lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
		xline(`=q(2009q1)' `=q(2020q2)', lwidth(3) lcolor(gs15) lpattern(solid)) ///
		legend(off) ///
		xsize(8) ysize(4) xlabel(168(16)240, nogrid format(%tqCCYY)) ///
		ylabel(-4(2)4, nogrid) scale(4) xtitle("") title("`cname'") ytitle("")
	
	if inlist("`cname'", `colist1') | inlist("`cname'", `colist2') | inlist("`cname'", `colist3') {
		local filename `= subinstr("`output_file'", "XX", "`ciso2'", .)'
	}
	else {
		local modified `=subinstr("`output_file'", "Figure6", "AppendixFigure4", .)'
		local filename `= subinstr("`modified'", "XX", "`ciso2'", .)'
	}
	graph export `filename', as(eps) replace 
}
}
