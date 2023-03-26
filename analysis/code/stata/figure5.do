
args input_file output_file

set scheme plotplain

use "`input_file'", clear

keep if data == "all" 
drop global*

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

* Take average and plot
collapse (mean) globalrisk=risk globalfirmrisk=firmrisk_5plus global_crises, by(dateQ)

qui su globalrisk if yofd(dofq(dateQ)) < 2020
replace globalrisk = (globalrisk - r(mean)) / r(sd)  
    
qui su globalfirmrisk if yofd(dofq(dateQ)) < 2020
replace globalfirmrisk = (globalfirmrisk - r(mean)) / r(sd)

twoway (scatter globalrisk dateQ if global_crises == 1, ///
    msymbol(circle) msize(large) mcolor(gs10) mlwidth(medium) mlcolor(black)) ///
    (line globalrisk dateQ, lcolor(midblue) lwidth(thick) lpattern(solid)) ///
    , text(4.8 `=q(2009q1)' "Global Financial" "Crisis", size(vsmall)) ///
    text(3.2 `=q(2012q1)' "European Sovereign" "Debt Crisis", size(vsmall)) ///
    text(5 `=q(2020q1)' "Coronavirus" "Pandemic", size(vsmall) placement(w)) ///
    ytitle("") ///
    yline(2, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
    xline(`=q(2009q1)' `=q(2020q2)', lwidth(4) lcolor(gs15) lpattern(solid)) ///
    xlabel(168(8)244, nogrid format(%tqCCYY)) ///
    ylabel(-4(2)6, nogrid) xtitle("") scale(2) ///
    xsize(8) ysize(4) legend(order(2 "GlobalRisk{sub:t}" ///
    ) position(6) cols(1))
        
graph export "`output_file'", as(eps) replace 
