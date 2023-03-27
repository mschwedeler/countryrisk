********************************************************************************
*                              ifs_gdp_import.do file:                         *
*                                                                              *
*                                Prepare ifs_gdpQ.dta                          *  
********************************************************************************

args input_file output_file

import excel using "`input_file'", clear


*Clean
ren A country_name
ren B quarterly
ren C country_iso2
ren D gdpreal_pcty
ren E gdpreal_pct
ren F gdpreal_referencech
ren G gdpreal_referencech_sa
ren H gdprealspliced
ren I gdprealspliced_sa
drop if _n < 3
destring gdp*, replace
replace quarterly = substr(quarterly, 4, .) + substr(quarterly, 1, 2)
gen dateQ = quarterly(quarterly, "YQ")
format dateQ %tq
drop quarterly


*Pick GDP series
sort country_name
foreach v of varlist gdp* {
	by country_name: egen COUNT`v' = count(`v')
}
egen max = rowmax(COUNT*)
gen gdpreal_mix = .
foreach v of varlist gdprealspliced gdpreal_referencech ///
	gdprealspliced_sa gdpreal_referencech_sa {
	replace gdpreal_mix = `v' if max == COUNT`v' & gdpreal_mix == .
}


*Pct change
egen country_id = group(country_name)
xtset country_id dateQ
gen gdprealmix_pct = D.gdpreal_mix / L.gdpreal_mix


*Keep relevant variables
keep country_iso2 dateQ gdprealmix_pct country_name gdpreal_pct

replace gdprealmix_pct = gdprealmix_pct * 100
la var gdprealmix_pct "Pct change of real gdp (spliced); domestic curr; not SA"


*Save
sort country_iso2 dateQ
compress
save "`output_file'", replace
