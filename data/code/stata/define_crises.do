********************************************************************************
*                                  Define Crises                               *  
********************************************************************************
args input_file iso2_to_names_file crisis_variables_do output_file


use "`input_file'", clear

gcollapse (mean) risk, by(country_iso2 dateQ)
		
*Add country names

ren country_iso2 iso2
merge m:1 iso2 using "`iso2_to_names_file'"
drop if _merge == 2
drop _merge
ren iso2 country_iso2

egen country_id = group(country_iso2) // needed for running crises_variables.do


* Create crises variables (important code shared with code for Figure 6)

tempfile parent_data
save "`parent_data'", replace

do "`crisis_variables_do'"
// note that risk_resid is normalized to have sd=2, so next line is legal
scalar sd_global = 2

merge 1:1 country_iso2 dateQ using "`parent_data'"
drop _merge


* Prepare data file that will save crises for later use

capture file close saving_file
file open saving_file using "`output_file'", write replace
file write saving_file "country_iso2,dateQ,nolocal" _n


* Run loop over countries

local colist1 `""China", "Turkey", "Greece", "United States", "Brazil", "United Kingdom""'
local colist2 `""Russia", "Ireland", "Spain", "Thailand", "Egypt", "Hong Kong", "Japan""'
local colist3 `""Italy", "Iran", "Mexico", "Nigeria", "Norway", "Poland", "Venezuela""'

keep if inlist(country_name, `colist1') | inlist(country_name,`colist2') | inlist(country_name,`colist3') 

local true_i = 0   
levelsof rankNumber, local(levels)

foreach i of local levels{

	di as result "===========NEXT COUNTRY==========="
	
	// Obtain quarters of crises: sd_global
	qui levelsof dateQ if rankNumber == `i' & (risk_resid > sd_global), local(crises) clean
	
	// Obtain country iso2 and name
	qui levelsof country_iso2 if rankNumber == `i', local(ciso2) clean
	qui levelsof country_name if rankNumber == `i', local(cname) clean
	di "Working on `cname'..."

	// How many non-global crises?
	qui levelsof dateQ if rankNumber == `i' & global_crises == 0 & ///
		(risk_resid > sd_global), local(crises_excl_global) clean
	
	// Manual intervention for Iran: Add quarter
	if "`ciso2'" == "IR" {
		local crises_excl_global = "`crises_excl' " + "208"
	}
	
	// County how many local crises
	local howmany = wordcount("`crises'")
	local howmany_excl_global = wordcount("`crises_excl_global'")
	
	// If no crisis, don't write to saving_file
	if `howmany' == 0 {
		di as result = "------" + "`cname'" + ": NO CRISES----------"
	}
	
	// Else if only global crises, run regression, and write that to file
	else if `howmany_excl_global' == 0 & `howmany' > 0 {
		foreach d of local crises {
			di %tq `d'
			file write saving_file "`ciso2',`: di %tq `d'',yes" _n
		}
		di as result = "------" + "`cname'" + " NO LOCAL CRISES----------"
	}

	// Else if local crises, find out whether financial or non-financial
	else if `howmany_excl_global' > 0 {
		*Add to counter
		local true_i = `true_i' + 1
		
		*Reset locals
		local financial = ""
		local nonfinancial = ""
		
		*Loop through crises
		foreach d of local crises_excl_global {
			di %tq `d'
			*Write result
			file write saving_file "`ciso2',`: di %tq `d'',no" _n
		}
		*Report statistics
		di as result = "------" + "`cname'" + " CRISES----------"
		di "number of non-global crises: `howmany_excl_global'"
	}
}
di "Total countries with local crises: `true_i'"
file close saving_file
