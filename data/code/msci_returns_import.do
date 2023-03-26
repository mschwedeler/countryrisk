********************************************************************************
*                            msci_returns_import.do file:                      *
*                                                                              *
*                             Prepare msci_returnsQ.dta                        *  
********************************************************************************


import delimited using "${RAW_DATA}/msci_returns/msci_updated20201222.csv", clear

gen dateD = date(date, "YMD")
format dateD %td
gen dateQ = qofd(dateD)
format dateQ %tq
drop date

ren return_net return_index  
ren price price_index
drop return_gross


** Standard deviation of returns

preserve
	
	// Generate business day
	bcal create "${DATA}/temp/msci", from(dateD) replace generate(dateB)
	format dateB %tbmsci
	
	// Xtset data
	egen country_id = group(country_iso2)
	xtset country_id dateB
	
	// Returns
	gen return = (d.return_index / l.return_index)
	
	// Days
	gen days = 1
	
	// SD of returns
	collapse (mean) av_return_index=return_index ///
		(sd) realizedvol=return ///
		(sum) days, by(country_iso2 dateQ)
		
	// Scale to get quarterly
	replace realizedvol = realizedvol * sqrt(days)
	
	tempfile sd_data
	save "`sd_data'", replace
	
restore


** Q-to-q level and return (end-of-quarter)

sort country_iso2 dateQ dateD
collapse (last) price_index return_index, by(country_iso2 dateQ)

egen country_id = group(country_iso2)
xtset country_id dateQ

gen returnrate = (log(return_index) - log(l.return_index))
gen returnpct = d.return_index / l.return_index
xtset, clear

drop country_id


** Bring in SD

merge 1:1 country_iso2 dateQ using "`sd_data'"
drop _merge

egen country_id = group(country_iso2)
xtset country_id dateQ
gen returnAVrate = (log(av_return_index) - log(l.av_return_index))
xtset, clear
drop country_id


** Label

la var price_index "End-of-quarter MSCI price index"
la var return_index "End-of-quarter MSCI return index"
la var returnrate "Log(return_index/l.return_index)"
la var returnAVrate "Log(av_return_index/l.av_return_index)"
la var realizedvol "Sd(daily return within quarter)*sqrt(# days in quarter)"

compress
sort country_iso2 dateQ
order country_iso2 dateQ

save "${DATA}/temp/msci_returnsQ.dta", replace
