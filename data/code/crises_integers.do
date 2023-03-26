
/******************************************************************************
  This code essentially gives an integer to each crisis within
  a country. It turns out that there are a maximum of 4 crises for a given
  country, so the variable crisis_id runs from 1 to 4. If a crisis spans
  multiple consecutive quarters within a country, they get the same integer.
*******************************************************************************/
	

import delimited "${DATA}/temp/crises.csv", clear varnames(1)


* Quarterly
gen dateQ = quarterly(dateq, "YQ")
format dateQ %tq
drop dateq


* Make sure no duplicates
duplicates report country_iso2 dateQ
assert r(unique_value) == r(N)


* Mark start of crises AND distinguish crises within country
sort country_iso2 dateQ
by country_iso2: gen start = 1 if dateQ != dateQ[_n-1] + 1
tempfile a
save "`a'", replace
drop if start == .
drop start
by country_iso2: gen crisis_id = _n
keep country_iso2 dateQ crisis_id
tempfile b
save "`b'", replace


* Merge
use "`a'", clear
merge 1:1 country_iso2 dateQ using "`b'"
drop _merge start


* Fill in missing
by country_iso2: replace crisis_id = crisis_id[_n-1] if crisis_id == .


* Manual intervention #1: Outreak of Covid
replace crisis_id = 4 if country_iso2 == "CN" & dateQ == q(2020q1)


* Manual intervention #2: Brazil only 2015q4 missing, so 2016q1-2 is part of previouscrisis
replace crisis_id = 2 if country_iso2 == "BR" & dateQ == q(2016q1)
replace crisis_id = 2 if country_iso2 == "BR" & dateQ == q(2016q2)
