args data_folder output_folder

use "`data_folder'/final/analysis_FirmCountry.dta", clear

capture file close sutab
file open sutab using "`output_folder'/tables/Table4_PanelA_sustats_FirmCountry.tex", replace write
file write sutab "\textsc{Panel A: Firm-country} & Mean & Median & "
file write sutab "St.\ Dev. & Min & Max & \$N\$ \\\hline\addlinespace" _n
qui su exposure_std, d
file write sutab "\textit{CountryExposure}\$_{i,c}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su hq, d
file write sutab "\$\mathbbm{1}(\textit{Headquarter})_{i,c}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su sale_seg_dummy , d
file write sutab "\$\mathbbm{1}(\textit{Exports})_{i,c}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su standard_count , d
file write sutab "\$\mathbbm{1}(\textit{Subsidiaries})_{i,c}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
file close sutab


* PANEL B


use "`data_folder'/final/analysis_CountryQuarter.dta", clear

drop if yofd(dofq(dateQ)) > 2019

capture file close sutab
file open sutab using "`output_folder'/tables/Table4_PanelB_sustats_CountryQuarter.tex", write replace
file write sutab "\textsc{Panel B: Country-quarter} & Mean & Median & "
file write sutab "St.\ Dev. & Min & Max & \$N\$ \\\hline\addlinespace" _n
qui su risk_std if data == "all", d
file write sutab "\textit{CountryRisk}\$_{c,t}^{ALL}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su risk_std if data == "NOT: hq", d
file write sutab "\textit{CountryRisk}\$^{NHQ}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su risk_std if data == "financial", d
file write sutab "\textit{CountryRisk}\$^{FIN}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su risk_std if data == "NOT: financial", d
file write sutab "\textit{CountryRisk}\$^{NFC}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su risk_std if data == "us", d
file write sutab "\textit{CountryRisk}\$^{US}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su risk_std if data == "hq", d
file write sutab "\textit{CountryRisk}\$^{HQ}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su sentiment_std if data == "all", d
file write sutab "\textit{CountrySentiment}\$^{ALL}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su firmrisk_5plus_std if data == "all", d
file write sutab "\$\overline{\textit{FirmRisk}_{i,c,t}}_{c,t}\$ \textit{(std.)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su realizedvol if data == "all", d
file write sutab "\textit{Realized MSCI volatility}\$_{c,t}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su returnAVrate if data == "all", d
file write sutab "\$\textit{MSCI equity return}_{c,t}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su total_inflows if data == "all", d
file write sutab "\textit{Total inflows}\$_{c,t}\$\textit{ (\%)} & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su spread5y_pa if data == "all", d
file write sutab "\textit{Sovereign CDS spread}\$_{c,t}\$ (\textit{pct}) & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su gdp_real_pct if data == "all", d
file write sutab "\textit{Real GDP growth}\$_{c,t}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su stop_epiTO if data == "all", d
file write sutab "\$\mathbbm{1}(\textit{Stop episode for total flows}_{c,t})\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su retrench_epiTO if data == "all", d
file write sutab "\$\mathbbm{1}(\textit{Retrenchment episode for total flows}_{c,t}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
qui su wui_std if data == "all", d
file write sutab "\$\textit{WUI}_{c,t}\textit{ (std.)}\$ & `: di %15.2fc `=r(mean)'' & "
file write sutab "`: di %15.2fc `=r(p50)'' & `: di %15.2fc `r(sd)'' & "
file write sutab "`: di %15.2fc `r(min)'' & `: di %15.2fc `r(max)'' & "
file write sutab "`: di %15.0fc `r(N)'' \\" _n
file close sutab
