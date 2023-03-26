args data_folder output_folder

use "`data_folder'/final/analysis_CountryQuarter.dta", clear


* Restrict to pre-2020
drop if yofd(dofq(dateQ)) > 2019


* Keep sample of all firms
keep if data == "all"


* Inverse hyperbolic sine
xtset country_id dateQ
foreach v in risk sentiment {
	gen ihs_`v' = asinh(`v'_std)
	gen d_ihs_`v' = d.ihs_`v'
}

est clear
foreach v in returnAVrate d_realizedvol d_cds_pa {

	if "`v'" == "returnAVrate" {
		local fname "returns"
		local outcome "DOLLAR\textit{MSCI equity return}_{c,t}DOLLAR"
	}
	else if "`v'" == "d_realizedvol" {
		local fname "vola"
		local outcome "DOLLAR\Delta\textit{Realized MSCI volatility}_{c,t}DOLLAR"
	}
	else if "`v'" == "d_cds_pa" {
		local outcome "DOLLAR\Delta\textit{CDS spread}_{c,t}DOLLAR"
		local fname "dcds"
	}

	reghdfe `v' d_log_risk ///
		, vce(cluster country_id) noabsorb
	est sto `fname'_a
	reghdfe `v' d_log_risk d_ihs_sentiment ///
		, vce(cluster country_id) noabsorb
	est sto `fname'_b
	
}
esttab returns_*, r2 
estout returns_* dcds_* vola_* using ///
    "`output_folder'/tables/Table5_countrylevel_validation.tex", replace ///
	cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") stats(r2 N, ///
	fmt(%9.3f %9.0fc) ///
	labels("\addlinespace\$R^2\$" "\$N\$")) ///
	msign(--) style(tex) collabels(,none) ///
	mlabels("1" "2" "3" "4" "5" "6", prefix("(") suffix(")")) ///
	substitute("DOLLAR" "\$") starlevel(* 0.10 ** 0.05 *** 0.01) ///
	mgroups("DOLLAR\textit{MSCI equity return}_{c,t}DOLLAR" ///
	"DOLLAR\Delta\textit{CDS spread}_{c,t}DOLLAR" ///
	"DOLLAR\Delta\textit{Realized volatility}_{c,t}DOLLAR", ///
	pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) ///
	suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
	prehead("") ///
	posthead("\hline\addlinespace") prefoot("\addlinespace") ///
	keep(d_log_risk d_ihs_sentiment) ///
	order(d_log_risk d_ihs_sentiment) ///
	varlabels(d_ihs_sentiment "\$\Delta\textit{IHS}(\textit{CountrySentiment}_{c,t}^{\textit{ALL}}\textit{ (std.)})\$" ///
	d_log_risk "\$\Delta\log(\textit{CountryRisk}_{c,t}^{\textit{ALL}}\textit{ (std.)})\$" ///
	d_log_globalrisk "\$\Delta\log(\textit{GlobalRisk}_{t}\textit{ (std.)})\$")
	