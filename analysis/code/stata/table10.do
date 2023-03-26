args countryquarter_file output_folder

use "`countryquarter_file'", clear

drop if yofd(dofq(dateQ)) > 2019


*  Keep sample
keep if inlist(data, "all", "NOT: hq", "hq", "us", "financial", "NOT: financial")
replace data = "nohq" if data == "NOT: hq"
replace data = "fin" if data == "financial"
replace data = "nfc" if data == "NOT: financial"


*  Prepare to reshape
keep risk_std sentiment_std firmrisk_5plus_std portfolio_total_inflows ///
	country_iso2 dateQ country_id data gdp_real_pct wui_std d_log_wui_std ///
	total_inflows spread5y_pa d_cds_pa d_log_risk_std d_log_sentiment_std ///
	d_log_firmrisk_std
foreach v of varlist risk_std sentiment_std d_cds_pa d_log_wui_std ///
	d_log_risk_std d_log_sentiment_std d_log_firmrisk_std firmrisk_5plus_std {
	ren `v' `v'_
}


*  Reshape
reshape wide *_std_ d_cds_pa, i(country_iso2 dateQ) j(data) string


*  Rename
foreach v of varlist *risk_std_* *sentiment_std_* {
	local lastpart = regexr("`v'", ".+std_", "")
	local firstpart = regexr("`v'", "_std_[a-z]+", "")
	ren `v' `firstpart'_`lastpart'_std
}

corr risk_all_std risk_us_std risk_nohq_std



** PANEL A


est clear
qui reghdfe total_inflows risk_all_std ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto a
qui reghdfe total_inflows risk_us_std ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto b
qui reghdfe total_inflows risk_nohq_std ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto c
qui reghdfe total_inflows risk_nohq_std wui_std ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto d

estout a b c d using `="`output_folder'/" ///
+ "tables/Table10_PanelA_countrylevel_executivesviews_inflows.tex"', replace ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") stats(r2 N, ///
fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "\$N\$")) ///
msign(--) style(tex) collabels(,none) numbers ///
substitute("DOLLAR" "\$") starlevel(* 0.10 ** 0.05 *** 0.01) ///
mlabels(,none) mgroups("\textit{Total inflows}DOLLAR_{c,t}DOLLAR\textit{ (\%)}" ///
"\textit{Portfolio}DOLLAR_{c,t}DOLLAR \textit{(\%)}", ///
pattern(1 0 0 0 ) prefix(\multicolumn{@span}{c}{) ///
suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
prehead("\textsc{Panel A}") ///
posthead("\hline\addlinespace") prefoot("\addlinespace") ///
keep(risk_all_std risk_us_std risk_nohq_std wui_std) ///
order(risk_all_std risk_us_std risk_nohq_std wui_std) ///
varlabels(sentiment_all_std "\textit{CountrySentiment}\$_{c,t}\textit{ (std.)}\$" ///
risk_all_std "\textit{CountryRisk}\$_{c,t}^{ALL}\textit{ (std.)}\$" ///
risk_hq_std "\textit{CountryRisk}\$_{c,t}^{HQ}\textit{ (std.)}\$" ///
risk_fin_std "\textit{CountryRisk}\$_{c,t}^{FIN}\textit{ (std.)}\$" ///
risk_nfc_std "\textit{CountryRisk}\$_{c,t}^{NFC}\textit{ (std.)}\$" ///
risk_us_std "\textit{CountryRisk}\$_{c,t}^{\textit{US firms}}\textit{ (std.)}\$" ///
wui_std "\textit{WUI}\$_{c,t}\textit{ (std.)}\$" ///
risk_nohq_std "\textit{CountryRisk}\$_{c,t}^{NHQ}\textit{ (std.)}\$" ///
risk_nolink_std "CountryRisk\$_{C,t}^{NL}\textit{ (std.)}\$" ///
firmrisk_5plus "\$\overline{\text{FirmRisk}_{i,t}}_{c,t}\textit{ (std.)}\$")



** PANEL B


est clear
qui reghdfe total_inflows risk_nohq_std risk_hq_std ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto a
qui reghdfe total_inflows risk_nohq_std firmrisk_5plus_std_all ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto b
 reghdfe total_inflows risk_fin_std risk_nfc_std ///
, vce(cluster country_id) absorb(i.country_id i.dateQ)
test _b[risk_fin_std] == _b[risk_nfc_std]
est sto c
qui reghdfe portfolio_total_inflows risk_fin_std risk_nfc_std ///
	, vce(cluster country_id) absorb(i.country_id i.dateQ)
est sto d

estout a b c d using `="`output_folder'/" ///
+ "tables/Table10_PanelB_countrylevel_executivesviewsFIN_inflows.tex"', replace ///
cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") stats(r2 N, ///
fmt(%9.3f %9.0fc) ///
labels("\addlinespace\$R^2\$" "\$N\$")) ///
msign(--) style(tex) collabels(,none) numbers ///
substitute("DOLLAR" "\$") starlevel(* 0.10 ** 0.05 *** 0.01) ///
mlabels(,none) mgroups("\textit{Total inflows}DOLLAR_{c,t}DOLLAR\textit{ (\%)}" ///
"\textit{Portfolio}DOLLAR_{c,t}DOLLAR \textit{(\%)}", ///
pattern(1 0 0 1) prefix(\multicolumn{@span}{c}{) ///
suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
prehead("\textsc{Panel B}") ///
posthead("\hline\addlinespace") prefoot("\addlinespace") ///
keep(risk_nohq_std risk_hq_std firmrisk_5plus_std_all risk_fin_std risk_nfc_std) ///
order(risk_nohq_std risk_hq_std firmrisk_5plus_std_all risk_fin_std risk_nfc_std) ///
varlabels(sentiment_all_std "\textit{CountrySentiment}\$_{c,t}\textit{ (std.)}\$" ///
risk_all_std "\textit{CountryRisk}\$_{c,t}^{ALL}\textit{ (std.)}\$" ///
risk_hq_std "\textit{CountryRisk}\$_{c,t}^{HQ}\textit{ (std.)}\$" ///
risk_fin_std "\textit{CountryRisk}\$_{c,t}^{FIN}\textit{ (std.)}\$" ///
risk_nfc_std "\textit{CountryRisk}\$_{c,t}^{NFC}\textit{ (std.)}\$" ///
risk_us_std "\textit{CountryRisk}\$_{c,t}^{\textit{US firms}}\textit{ (std.)}\$" ///
wui_std "\textit{WUI}\$_{c,t}\textit{ (std.)}\$" ///
risk_nohq_std "\textit{CountryRisk}\$_{c,t}^{NHQ}\textit{ (std.)}\$" ///
risk_nolink_std "CountryRisk\$_{C,t}^{NL}\textit{ (std.)}\$" ///
firmrisk_5plus_std_all "\$\overline{\text{FirmRisk}_{i,t}}_{c,t}\textit{ (std.)}\$")
