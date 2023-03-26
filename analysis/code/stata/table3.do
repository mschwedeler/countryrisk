args input_file output_file

use "`input_file'", clear

est clear

reghdfe exposure_std hq, noabsorb vce(robust)
est sto b
reghdfe exposure_std sale_seg_dummy, noabsorb vce(robust)
est sto c
reghdfe exposure_std standard_count, noabsorb vce(robust)
est sto d
reghdfe exposure_std hq sale_seg_dummy standard_count, noabsorb vce(robust)
est sto e
reghdfe exposure_std hq sale_seg_dummy standard_count, absorb(i.country_id) vce(robust)
est sto f


estout * using "`output_file'", replace ///
	cells("b(star fmt(%9.3fc))" "se(fmt(%9.3fc) par)") stats(r2 N, ///
	fmt(%9.3f %9.0fc) ///
	labels("\addlinespace\$R^2\$" "\$N\$")) ///
	msign(--) style(tex) collabels(,none) numbers ///
	substitute("DOLLAR" "$") starlevel(* 0.10 ** 0.05 *** 0.01) ///
	mlabels(,none) mgroups( ///
	"\textit{CountryExposure}DOLLAR_{i,c}DOLLAR (\textit{std.})", ///
	pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) ///
	suffix(}) erepeat(\cmidrule(lr){@span}) span) ///
	prehead("") ///
	posthead("\hline\addlinespace") prefoot("\addlinespace") ///
	keep(hq sale_seg_dummy standard_count) ///
	order(hq sale_seg_dummy standard_count) ///
	varlabels(hq "\$\mathbbm{1}(\textit{Headquarter})_{i,c}\$" ///
	sale_seg_dummy "\$\mathbbm{1}(\textit{Exports})_{i,c}\$" ///
	sub "\$\mathbbm{1}(\text{Subsidiaries})_{i,c}\$" ///
	adr "\$\mathbbm{1}(\text{ADR})_{i}\$" ///
	standard_count "\$\mathbbm{1}(\textit{Subsidiary})_{i,c}\$" ///
)
