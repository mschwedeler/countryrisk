********************************************************************************
*                                Crises Variables                              *  
********************************************************************************

* Identify global crises 

preserve
	collapse (mean) globalrisk=risk, by(dateQ)
	qui su globalrisk if yofd(dofq(dateQ)) < 2020  
	replace globalrisk = (globalrisk - r(mean)) / r(sd)  
	sort dateQ
	list if globalrisk > 2
	gen global_crises = (globalrisk > 2)
	keep dateQ global_crises
	tempfile a
	save "`a'", replace
restore
merge m:1 dateQ using "`a'"
drop if _merge == 2
drop _merge


* Risk residual after taking out country FE

capture ren risk_resid risk_resid_
reghdfe risk, absorb(country_id) residuals(risk_resid)


* Normalize and take panel SD

qui su risk_resid if yofd(dofq(dateQ)) < 2020  
scalar sd = r(sd)
replace risk_resid = risk_resid / `=sd'  


* Sort countries by name

preserve
	keep country_name
	duplicates drop
	sort country_name
	gen rankNumber = _n
	tempfile a
	save "`a'", replace
restore
merge m:1 country_name using "`a'", keepusing(rankNumber)
drop _merge

sort country_name dateQ


keep country_iso2 dateQ global_crises risk_resid rankNumber
