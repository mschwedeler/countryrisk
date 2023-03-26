********************************************************************************
*                             Table7.do File:                                  *
*                                                                              *
*                   Prepare data used in Python for Table7                     *  
********************************************************************************

args transmissionrisk_tau_file transmissionrisk_firm_tau_file output_file


** A) Manually input crisis lables

clear all

input str4 crisis_abbrev str80 label str2 country_iso2 str20 country_name
"BR_1" "Lula election (2002q4)" "BR" "Brazil"
"BR_2" "Corruption scandal (2015q1-16q2)" "BR" "Brazil"
"CN_1" "Risk of `hard landing' (2012q4)" "CN" "China"
"CN_2" "Equity market volatility (2015q3-16q1)" "CN" "China"
"CN_3" "US-China trade war (2018q4-19q4)" "CN" "China"
"CN_4" "Start of Coronavirus outbreak (2020q1)" "CN" "China"
"EG_1" "Egyptian revolution (2011q1-11q2)" "EG" "Egypt"
"ES_1" "Sovereign debt crisis (2011q4)" "ES" "Spain"
"ES_2" "Bailout (2012q3-12q4)" "ES" "Spain"
"GB_1" "Brexit referendum (2016q3-16q4)" "GB" "United Kingdom"
"GB_2" "Lead-up to Brexit (2019q1-20q1)" "GB" "United Kingdom"
"GR_1" "First bailout (2010q1-10q2)" "GR" "Greece"
"GR_2" "Second bailout (2011q1-12q3)" "GR" "Greece"
"GR_3" "Grexit referendum (2015q3)" "GR" "Greece"
"HK_1" "Protests against extradition bill (2019q3-19q4)" "HK" "Hong Kong"
"IE_1" "Sovereign debt crisis (2011q4)" "IE" "Ireland"
"IE_2" "Brexit (2020q1)" "IE" "Ireland"
"IR_1" "Green Revolution (2012q1)" "IR" "Iran"
"IT_1" "Sovereign debt crisis (2011q4)" "IT" "Italy"
"JP_1" "Fukushima disaster (2011q2-11q3)" "JP" "Japan"
"MX_1" "Trump; trade risks (2017q1)" "MX" "Mexico"
"RU_1" "Economic uncertainty (2011q4)" "RU" "Russia"
"RU_2" "Crimean crisis (2014q2-15q4)" "RU" "Russia"
"TH_1" "Flood disaster (2011q4-12q1)" "TH" "Thailand"
"TH_2" "Military coup (2014q3)" "TH" "Thailand"
"TR_1" "FX volatility (2016q1)" "TR" "Turkey"
"TR_2" "Failed coup attempt (2016q3)" "TR" "Turkey"
"TR_3" "Currency and debt crisis (2018q4-19q1)" "TR" "Turkey"
"TR_4" "FX volatility (2019q4)" "TR" "Turkey"
"US_1" "Lehman; start of GFC (2008q1-08q3)" "US" "United States"
"US_3" "S\&P downgrade (2011q3-11q4)" "US" "United States"
"VE_1" "Aftermath of oil strike (2003q1)" "VE" "Venezuela"
"NG_1" "Oil workers' strike (2003q2)" "NG" "Nigeria"
"US_2" "Deepwater Horizon oil spill (2010q2)" "US" "United States"
"NO_1" "\textcolor{red}{coocurrence of local concerns}" "NO" "Norway"
"PL_1" "\textcolor{red}{coocurrence of local concerns (2020q1)}" "PL" "Poland"
end

compress
tempfile crises_labels
save "`crises_labels'", replace



** B) Create data for Table 7, columns 1-3

use "`transmissionrisk_tau_file'", clear
mat drop _all


* loop through crises

qui levelsof crisis_id, local(crises) clean
foreach a of local crises {
	qui levelsof country_iso2 if crisis_id == `a', local(country) clean
	qui levelsof crisis_nr if crisis_id == `a', local(nr) clean
	
	di "Obtaining statistics for `country': crisis #`nr'; crisis_id: `a'"
	qui su TransmissionRisk if crisis_id == `a'
	if r(N) < 5 {
		continue
	}
	
	// regular regression
	qui reg TransmissionRisk ibn.type_id ibn.type_id#c.mTREXCL ///
		if crisis_id == `a' [aw=nr_of_firms], nocons
	local r2_1 = e(r2)
	local df = e(df_r)
	local n = e(N)
	matrix B = (e(b))'
	mata st_matrix("SD_matrix",sqrt(diagonal(st_matrix("e(V)"))))
	mat regstuff = [B', SD_matrix']
	
	// tests
	qui test i`="ALL":`: value label type_id''.type_id#c.mTREXCL == 1
	local pvalALL = r(p)
	qui test i`="FIN":`: value label type_id''.type_id#c.mTREXCL == 1
	local pvalFIN = r(p)
	qui test i`="ALL":`: value label type_id''.type_id#c.mTREXCL == ///
		i`="FIN":`: value label type_id''.type_id#c.mTREXCL
	local pvaleq = r(p)
	
	// ypred
	qui su mTREXCL if crisis_id == `a' & type == "FIN" [aw=nr_of_firms], d
	local valueFIN = r(p50)
	qui lincom i`="FIN":`: value label type_id''.type_id ///
		+ i`="FIN":`: value label type_id''.type_id#c.mTREXCL*`valueFIN'
	local estimateFIN = r(estimate)
	qui su mTREXCL if crisis_id == `a' & type == "ALL" [aw=nr_of_firms], d
	local valueALL = r(p50)
	 lincom i`="ALL":`: value label type_id''.type_id ///
		+ i`="ALL":`: value label type_id''.type_id#c.mTREXCL*`valueALL'
	local estimateALL = r(estimate)
	
	qui su mTREXCL if crisis_id == `a' & type == "NFC" [aw=nr_of_firms], d
	local valueNFC = r(p50)
	qui lincom i`="NFC":`: value label type_id''.type_id ///
		+ i`="NFC":`: value label type_id''.type_id#c.mTREXCL*`valueNFC' ///
		- (i`="FIN":`: value label type_id''.type_id ///
		+ i`="FIN":`: value label type_id''.type_id#c.mTREXCL*`valueFIN')
	local estimateDIFF = r(estimate)
	local pvalDIFF = r(p)
	
	// r2
	qui reg TransmissionRisk ibn.type_id ibn.type_id#c.mTREXCL ///
		if crisis_id == `a' & type == "ALL" [aw=nr_of_firms]
	local r2_1 = e(r2)
	qui reg TransmissionRisk_dm ibn.type_id ibn.type_id#c.mTREXCL ///
		if crisis_id == `a' & type == "ALL" [aw=nr_of_firms]
	local r2_2 = e(r2)
	
	// collect all //, `r2_l', `r2_2', `n', `pvalFIN', `pvalNFC', `pvalequal'
	mat stats = (nullmat(stats) \ (`estimateALL', `estimateFIN', `estimateDIFF', `pvalDIFF', `r2_1', ///
		`r2_2', `n', `df', `pvalALL', `pvalFIN', `pvaleq'), regstuff)
		
	// names
	local crid =  "`crid' " + "`a'"
	local names = "`names' " + "`country'_`nr'"
}


* pooled
reg TransmissionRisk ibn.type_id ibn.type_id#c.mTREXCL ///
	if crisis_id != 0 [aw=nr_of_firms], nocons
local r2_1 = e(r2)
local df = e(df_r)
local n = e(N)
matrix B = (e(b))'
mata st_matrix("SD_matrix",sqrt(diagonal(st_matrix("e(V)"))))
mat regstuff = [B', SD_matrix']


* tests
test i`="ALL":`: value label type_id''.type_id#c.mTREXCL == 1
local pvalALL = r(p)
test i`="FIN":`: value label type_id''.type_id#c.mTREXCL == 1
local pvalFIN = r(p)
test i`="ALL":`: value label type_id''.type_id#c.mTREXCL == ///
	i`="FIN":`: value label type_id''.type_id#c.mTREXCL
local pvaleq = r(p)


* ypred
qui su mTREXCL if crisis_id != 0 & type == "FIN" [aw=nr_of_firms], d
local valueFIN = r(p50)
lincom i`="FIN":`: value label type_id''.type_id ///
	+ i`="FIN":`: value label type_id''.type_id#c.mTREXCL*`valueFIN'
local estimateFIN = r(estimate)
qui su mTREXCL if crisis_id != 0 & type == "ALL" [aw=nr_of_firms], d
local valueALL = r(p50)
lincom i`="ALL":`: value label type_id''.type_id ///
	+ i`="ALL":`: value label type_id''.type_id#c.mTREXCL*`valueALL'
local estimateALL = r(estimate)
qui su mTREXCL if crisis_id != 0 & type == "NFC" [aw=nr_of_firms], d
local valueNFC = r(p50)
lincom i`="NFC":`: value label type_id''.type_id ///
	+ i`="NFC":`: value label type_id''.type_id#c.mTREXCL*`valueNFC' ///
	- (i`="FIN":`: value label type_id''.type_id ///
	+ i`="FIN":`: value label type_id''.type_id#c.mTREXCL*`valueFIN')
local estimateDIFF = r(estimate)
local pvalDIFF = r(p)


* r2
qui reg TransmissionRisk ibn.type_id ibn.type_id#c.mTREXCL ///
	if crisis_id != 0 & type == "ALL" [aw=nr_of_firms]
local r2_1 = e(r2)
qui reg TransmissionRisk_dm ibn.type_id ibn.type_id#c.mTREXCL ///
	if crisis_id != 0 & type == "ALL" [aw=nr_of_firms]
local r2_2 = e(r2)

* collect all //, `r2_l', `r2_2', `n', `pvalFIN', `pvalNFC', `pvalequal'
mat stats = (nullmat(stats) \ (`estimateALL', `estimateFIN', `estimateDIFF', `pvalDIFF', `r2_1', ///
	`r2_2', `n', `df', `pvalALL', `pvalFIN', `pvaleq'), regstuff)
	
* names
local crid =  "`crid' " + "-99"
local names = "`names' " + "pooled"
drop _all


* matrix --> data
svmat stats


* create correct labels
ren (*) (ypredXmedALL ypredXmedFIN ypredXmedDIFF pvalDIFF r2 r2_deltay N df_regression ///
	pvalALL pvalFIN pvalequal ///
	alphaALL alphaFIN alphaNFC betaALL betaFIN betaNFC ///
	alphaALL_se alphaFIN_se alphaNFC_se betaALL_se betaFIN_se betaNFC_se)
local n = _N
gen crisis_id = .
gen crisis_name = ""
forvalues i=1/`n' {
	qui replace crisis_id = `:word `i' of `crid'' in `i'
	qui replace crisis_name = "`:word `i' of `names''" in `i'
}


* save
compress
tempfile crisispatterns
save "`crisispatterns'", replace



** C) Create data for Table 7, column 4
use "`transmissionrisk_firm_tau_file'", clear

mat drop _all
local names ""
local crid ""
qui levelsof crisis_id, local(crises) clean
foreach a of local crises {
	qui levelsof country_iso2 if crisis_id == `a', local(country) clean
	qui levelsof crisis_nr if crisis_id == `a', local(nr) clean
	qui su TransmissionRisk if crisis_id == `a'
	if r(N) < 11 {
		error "A crisis episode with <= 10 obs; this shouldn't happen"
	}
	di "Financial or not? `country' and crisis #`nr'"
	qui reg TransmissionRisk_dm financial_indicator if crisis_id == `a'
	local df = e(df_r)
	local cons = _b[_cons]
	local cons_se = _se[_cons]
	local b = _b[financial_indicator]
	local se = _se[financial_indicator]
	local n = e(N)
	qui nlcom _b[financial_indicator]
	mat temp1 = r(b)
	mat temp2 = r(V)
	local ratio = _b[financial_indicator] / _b[_cons]
	local ratio_se = sqrt(el(temp2, 1, 1))
	qui levelsof fin if crisis_id == `a', local(fin)
	mat impact = (nullmat(impact) \ (`cons', `cons_se', `b' ,`se',`df', `n', `fin', `ratio', `ratio_se'))
	local crid =  "`crid' " + "`a'"
	local names = "`names' " + "`country'_`nr'"
}

reg TransmissionRisk_dm financial_indicator
local cons = _b[_cons]
	local cons_se = _se[_cons]
local b = _b[financial_indicator]
local se = _se[financial_indicator]
local n = e(N)
nlcom _b[financial_indicator]  
mat temp1 = r(b)
mat temp2 = r(V)
local ratio = _b[financial_indicator] / _b[_cons]  
local ratio_se = sqrt(el(temp2, 1, 1))
mat impact = (nullmat(impact) \ (`cons', `cons_se', `b' ,`se',`df', `n', 0, `ratio', `ratio_se'))
local crid =  "`crid' " + " -99"
local names = "`names' " + "pooled"
drop _all


*  matrix --> data
svmat impact


*  create correct labels
local n = _N
gen crisis_id = .
gen crisis_name = ""
forvalues i=1/`n' {
	qui replace crisis_id = `:word `i' of `crid'' in `i'
	qui replace crisis_name = "`:word `i' of `names''" in `i'
}
ren (impact*) (alpha alpha_se alphafin alphafin_se df n fin_old ratio ratio_se)
gen tstat = alpha / alpha_se
gen tstatfin = alphafin / alphafin_se
gen _t90 = abs(invt(df,(1 - 0.90)/2)) // t stat scalar
gen financials_different = "financials" if tstatfin > _t90 & alphafin > 0
replace financials_different = "non-financials" if abs(tstatfin) > _t90 & alphafin < 0
gsort -alphafin

gen tstatratio = ratio / ratio_se
gen ratio_p = (2 * ttail(df, abs(tstatratio)))

gen alphaFIN_p = (2 * ttail(df, abs(tstatfin)))

compress
tempfile financials
save "`financials'", replace



** D) Collect all results and prepare for Python to write the table 7
use "`financials'", clear


* Add crisis patterns
merge 1:1 crisis_name using "`crisispatterns'"
qui count if _merge != 3
drop if _merge == 1  
drop _merge


* Add labels to the crises
ren crisis_name crisis_abbrev
merge 1:1 crisis_abbrev using "`crises_labels'"
drop if _merge == 2  
drop _merge


* Add variable labels to the variables
la var alpha "Intercept in origin-firm-tau regression"
la var alpha_se "S.E. of alpha"
la var alphafin "Coeff on dummy = 1 if firm i \in financials"
la var alphafin_se "S.E. of alphafin"
la var df "Degrees of freedom in origin-firm-tau regression"
la var n "Number of origin-firm-tau observations"
la var fin_old "Existing indicator for circle in crisis figure (affecting financials)"
la var ratio "alphafin / alpha"
la var ratio_se "S.E. on obtained using delta method"
la var crisis_id "Internal crisis identifier"
la var crisis_abbrev "Crisis abbreviation"
la var tstat "alpha / alpha_se"
la var tstatfin "alphafin / alphafin_se"
la var _t90 "10 percent two-sided t-statistic using df"
la var financials_different "=financials+ if tstatfin > _t90 & alphafin > 0; finacials- if vice versa"
la var ypredXmedALL "hat{y} with mean(NormalTransmissionRisk) evaluated at median"
la var ypredXmedFIN "hat{y} with mean(NormalTransmissionRisk) evaluated at median; sample=finacials"
la var r2 "R2 from TransmissionRisk = alpha + beta*mean(NormalTransmissionRisk) if crisis=a & country=b"
la var r2_deltay "Same as R2 but outcome is TransmissionRisk-mean(TransmissionRisk)"
la var N "Number of origin-destination-tau observations"
la var df_regression "Degress of freedom in origin-destimation-tau regression"
la var pvalALL "P-value testing that beta != 1"
la var pvalFIN "P-value testing that beta != 1; sample=financials"
la var pvalequal "P-value testing that beta^ALL = beta^FIN"
la var alphaALL "Intercept in origin-destination-tau regression"
la var alphaFIN "Intercept in origin-destination-tau regression; sample=finacials"
la var alphaNFC "Intercept in origin-destination-tau regression; sample=nfc"
la var alphaALL_se "S.E. of alphaALL"
la var alphaFIN_se "S.E. of alphaFIN"
la var alphaNFC_se "S.E. of alphaNFC"
la var betaALL "beta in origin-destination-tau regression"
la var betaFIN "beta in origin-destination-tau regression; sample=finacials"
la var betaNFC "beta in origin-destination-tau regression; sample=nfc"
la var betaALL_se "S.E. of betaALL"
la var betaFIN_se "S.E. of betaFIN"
la var betaNFC_se "S.E. of betaNFC"


* Write to file for Python
save "`output_file'", replace
