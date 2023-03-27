********************************************************************************
*                              cfnai_import.do file:                           *
*                                                                              *
*                               Prepare cfnaiQ.dta                             *  
********************************************************************************

args input_file output_file

import excel "`input_file'", sheet("cfnai_realtime") firstrow case(lower) clear

	
* Keep most recent iteration
keep date cf122019  


* Take simple average within quarter
gen dateQ = qofd(date)
format dateQ %tq
collapse (mean) cf122019, by(dateQ)

ren cf122019 cfnai

* Save
compress
sort dateQ
save "`output_file'", replace
