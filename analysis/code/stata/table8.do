args countryquarter_file output_folder

use "`countryquarter_file'", clear

*  Keep pre 2020
drop if yofd(dofq(dateQ)) > 2019


*  Relabel
gen measure="all" if data=="all"
replace measure="nfc" if data=="NOT: financial"
replace measure="foreign" if data=="NOT: hq"
replace measure="fin_domestic" if data=="Financial; domestic"
replace measure="fin_foreign" if data=="Financial; foreign"
replace measure="nfc_domestic" if data=="Non-financial; domestic"
replace measure="nfc_foreign" if data=="Non-financial; foreign"
replace measure="not_us" if data=="NOT: us"
replace measure="fin" if data=="financial"
replace measure="domestic" if data=="hq"
replace measure="foreign_fin" if data=="nohqfinancial"
replace measure="us" if data=="us"
drop if measure == ""


*  Prepare to reshape to wide the types of views by firms
keep fdi_total_inflows other_loans_inflows total_inflows ///
	portfolio_total_inflows country_iso3 country_id dateQ globalrisk_std ///
	risk_std gdp_real_pct sentiment_std measure ///
	firmrisk_5plus spread5y_pa ///
	d_cds_pa d_log_risk_std d_log_sentiment_std ///
	d_log_globalrisk stop_epiTO retrench_epiTO emerging developed

foreach a in risk_std sentiment_std d_log_risk_std d_log_sentiment_std ///
	d_cds_pa d_log_globalrisk {
	rename `a' `a'_
}


*  Reshape
reshape wide risk_std sentiment_std d_log_risk_std d_log_sentiment_std ///
	d_cds_pa d_log_globalrisk, i(dateQ country_iso3) j(measure) str
 

order dateQ country_iso3 *inflows gdp_real_pct country_id risk* sentiment*


*  Regressions
est clear
qui reghdfe total_inflows globalrisk_std ///
    , vce(cluster country_id) absorb(i.country_id)
est sto a
qui reghdfe total_inflows risk_std_all globalrisk_std ///
    , vce(cluster country_id) absorb(i.country_id)
est sto b
qui reghdfe total_inflows risk_std_all globalrisk_std gdp_real_pct ///
    , vce(cluster country_id) absorb(i.country_id)
est sto c
qui reghdfe total_inflows risk_std_all gdp_real_pct ///
    , vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto d
qui reghdfe total_inflows risk_std_all sentiment_std_all ///
    , vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto e

estout a b c d e using ///
"`output_folder'/tables/Table8_countrylevel_capitalflows.tex", replace ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") stats(r2 N, ///
fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "\$N\$")) ///
msign(--) style(tex) collabels(,none) ///
mlabels(,none) numbers ///
substitute("DOLLAR" "\$") starlevel(* 0.10 ** 0.05 *** 0.01) ///
mgroups("\textit{Total inflows}DOLLAR_{c,t}DOLLAR \textit{(\%)}" ///
, ///
pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) ///
suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
prehead("\textsc{Panel A}") ///
posthead("\hline\addlinespace") prefoot("\addlinespace") ///
keep(risk_std_all globalrisk_std gdp_real_pct sentiment_std_all) ///
order(risk_std_all globalrisk_std gdp_real_pct sentiment_std_all) ///
varlabels(sentiment_std_all "\$\textit{CountrySentiment}_{c,t}^{ALL}\textit{ (std.)}\$" ///
risk_std_all "\$\textit{CountryRisk}_{c,t}^{ALL}\textit{ (std.)}\$" ///
globalrisk_std "\$\textit{GlobalRisk}_{t}\textit{ (std.)}\$" ///
gdp_real_pct "\textit{Real GDP growth}\$_{c,t}\$")


*Panel B


use "`countryquarter_file'", clear


*  Drop pre 2020
drop if yofd(dofq(dateQ)) > 2019


*  Relabel
gen measure="all" if data=="all"
replace measure="nfc" if data=="NOT: financial"
replace measure="foreign" if data=="NOT: hq"
replace measure="fin_domestic" if data=="Financial; domestic"
replace measure="fin_foreign" if data=="Financial; foreign"
replace measure="nfc_domestic" if data=="Non-financial; domestic"
replace measure="nfc_foreign" if data=="Non-financial; foreign"
replace measure="not_us" if data=="NOT: us"
replace measure="fin" if data=="financial"
replace measure="domestic" if data=="hq"
replace measure="foreign_fin" if data=="nohqfinancial"
replace measure="us" if data=="us"
drop if measure == ""


*  Reshape
keep fdi_total_inflows other_loans_inflows total_inflows ///
	portfolio_total_inflows country_iso3 country_id dateQ globalrisk_std ///
	risk_std gdp_real_pct sentiment_std measure ///
	firmrisk_5plus spread5y_pa crisis ///
	d_cds_pa d_log_risk_std d_log_sentiment_std ///
	d_log_globalrisk stop_epiTO retrench_epiTO emerging developed

foreach a in risk_std sentiment_std d_log_risk_std d_log_sentiment_std ///
	d_cds_pa d_log_globalrisk {
	rename `a' `a'_
}

reshape wide risk_std sentiment_std d_log_risk_std d_log_sentiment_std ///
	d_cds_pa d_log_globalrisk, i(dateQ country_iso3) j(measure) str

order dateQ country_iso3 *inflows gdp_real_pct country_id risk* sentiment*
tsset country_id dateQ

gen local_crisis = (crisis=="local")
gen global_crisis = (crisis=="global")


* Regressions

est clear
qui reghdfe total_inflows global_crisis ///
    , vce(cluster country_id) absorb(i.country_id)
est sto a
qui reghdfe total_inflows local_crisis global_crisis ///
    , vce(cluster country_id) absorb(i.country_id)
est sto b
qui reghdfe total_inflows local_crisis global_crisis gdp_real_pct ///
    , vce(cluster country_id) absorb(i.country_id)
est sto c
qui reghdfe total_inflows local_crisis gdp_real_pct ///
    , vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto d

estout a b c d using ///
"`output_folder'/tables/Table8_countrylevel_indicator_capitalflows.tex", replace ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") stats(r2 N, ///
fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "\$N\$")) ///
msign(--) style(tex) collabels(,none) ///
mlabels(,none) numbers ///
substitute("DOLLAR" "\$") starlevel(* 0.10 ** 0.05 *** 0.01) ///
mgroups("\textit{Total inflows}DOLLAR_{c,t}DOLLAR \textit{(\%)}", ///
pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) ///
suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
prehead("\textsc{Panel B}") ///
posthead("\hline\addlinespace") prefoot("\addlinespace") ///
keep(local_crisis global_crisis gdp_real_pct) ///
order(local_crisis global_crisis gdp_real_pct sentiment_std_all) ///
varlabels(sentiment_std_all "\$\textit{CountrySentiment}_{c,t}^{ALL}\textit{ (std.)}\$" ///
local_crisis "\$\mathbbm{1}(\textit{CountryCrisis}_{c,t})\$" ///
global_crisis "\$\mathbbm{1}(\textit{GlobalCrisis}_{t})\$" ///
gdp_real_pct "\textit{Real GDP growth}\$_{c,t}\$")
