********************************************************************************
*                           country_quarter.do file:                           *
*                                                                              *
*                       Prepare analysis_CountryQuarter.dta                    *  
********************************************************************************
args input_file output_file temp_folder forbes_warnock_file

global datatypes "_all _hq _financial _us"

*** 1) Collapse different aggregations
/* foreach weight in "" "_at" "_lat" "_bc" "_small" "_large" {

	/*
	The weights are only used once, for Appendix Table 11 when we stratify
	CountryRisk. Since it takes ages to go through this loop multiple times,
	I commented this out.
	*/
*/
local weight ""

foreach dataset of global datatypes  {

    /*
    This inner loop creates one data set for each set K of firms.
    */

    di "-----"
    di as result "Working on `dataset'..."
    di "-----"

    *Start with data at firm-country-quarter level
    use "`input_file'", clear
    
    *Restrict to relevant sample
    if "`dataset'" == "_all" {
        *Any firm
        gen sample = 1
    }
    else if "`dataset'" == "_financial" {
        *Financial firms
        destring sic, gen(sic_int)
        gen sample = (sic_int >= 6000 & sic_int < 6800)
    }
    
    else if "`dataset'" == "_hq" {
        *Firms with HQ
        gen sample = (country_iso2 == loc_iso2)
    }
    else if "`dataset'" == "_us" {
        *US firms
        gen sample = (loc_iso2 == "US")
    }
	
	*Take average by gvkey-country-year
	gen nroffirms = 1
	gen nrofhqfirms = (country_iso2 == loc_iso2)

    *Deal with weighted data sets (for Appendix Table 11)
    if "`weight'" != "" {
        if "`weight'" == "_at" {
            gen touse = at
        }
        else if "`weight'" == "_lat" {
            gen touse = lat
        }
        else if "`weight'" == "_bc" {
            gen touse = at_bc
        }
        else if "`weight'" == "_small" {
            keep if big == 0
            gen touse = 1
        }
        else if "`weight'" == "_large" {
            keep if big == 1
            gen touse = 1
        }
        sort country_iso2 dateQ sample
        by country_iso2 dateQ sample: egen total = total(touse)
        gen weight_ict = touse / total
        drop total
        foreach a in exposure risk sentiment {
            replace `a' = weight_ict * `a'
        }
        local mode "sum"
    }
    else {
        local mode "mean"
    }
		
	* Collapse
	gcollapse (`mode') exposure risk sentiment ///
		(sum) nroffirms nrofhqfirms, by(country_iso2 dateQ sample)
	// gcollapse is MUCH faster than collapse but doesn't allow for strings,
	// so I add country identifiers later again
    
    *Give samples slightly more attractive name
    gen data = substr("`dataset'", 2, .) if sample == 1
    replace data = "NOT: " + substr("`dataset'", 2, .) if sample == 0
    drop sample
    
    *Save tempfile
    sort country_iso2 dateQ data
    compress
    save "`temp_folder'/`dataset'.dta", replace
}


*** 2) Merge all scores together
use "`temp_folder'/_all.dta", clear
foreach dataset of global datatypes  {
    if "`dataset'"~="_all" {
        merge 1:1 country_iso2 dateQ data using "`temp_folder'/`dataset'"
        drop _merge
    }
}


* Add firm risk (see Hassan et al. (2019))
merge m:1 country_iso2 dateQ using "`temp_folder'/firmrisk.dta"
drop if _merge == 2
drop _merge


* Add country identifiers
ren country_iso2 iso2
merge m:1 iso2 using "`temp_folder'/iso2_iso3.dta"
drop if _merge == 2
drop _merge
ren iso3 country_iso3
merge m:1 iso2 using "`temp_folder'/iso2_names.dta"
drop if _merge == 2
drop _merge
ren iso2 country_iso2


* Add IMF capital flows (broken down by type) data
preserve
    use "`temp_folder'/grcf_capital_flows.dta", clear
    keep iso_country_code date_q  *_outflows *_inflows total_net
    foreach x in total portfolio_debt portfolio_equity portfolio_total ///
        fdi_debt fdi_equity fdi_total other_loans {
        replace `x'_outflows = `x'_outflows*100
        replace `x'_inflows = `x'_inflows*100
    }
    replace total_net = total_net * 100
    drop if iso_country_code == "" | date_q == .
    ren iso_country_code country_iso3
    ren date_q dateQ
    tempfile a
    save "`a'", replace
restore
merge m:1 country_iso3 dateQ using "`a'"
drop if _merge == 2
drop _merge


* ForbesWarnock sudden stops/retrenchment
preserve
    use "`forbes_warnock_file'", clear
    ren time dateQ
    ren cc_d country_iso2
    keep country_iso2 dateQ stop_epiTO retrench_epiTO
    tempfile a
    save "`a'", replace
restore
merge m:1 country_iso2 dateQ using "`a'"
drop if _merge == 2
drop _merge


* Add MSCI data
merge m:1 country_iso2 dateQ using "`temp_folder'/msci_returnsQ.dta"
drop if _merge == 2
drop _merge


* Add soveregin CDS data
merge m:1 country_iso2 dateQ using "`temp_folder'/markit_cdsQ.dta"
drop if _merge == 2
drop _merge
    
	
* Add World Uncertainty Index
merge m:1 country_iso3 dateQ using "`temp_folder'/wuiQ.dta"
drop if _merge == 2
drop _merge

/*
* Add EPU national
merge m:1 country_iso3 dateQ using "`temp_folder'/epu_national.dta"
drop if _merge == 2
drop _merge
*/

* Add GDP
merge m:1 country_iso2 dateQ using "`temp_folder'/ifs_gdpQ.dta", ///
    keepusing(gdprealmix_pct gdpreal_pct)
drop if _merge == 2
drop _merge
ren gdprealmix_pct gdp_real_pct


* Standardize scores with sd of respective sample & < 2020
qui levelsof data, local(datasets)
foreach v of varlist exposure risk sentiment firmrisk_5plus {
    gen `v'_std = .
    foreach d of local datasets {
        qui su `v' if data == "`d'" & yofd(dofq(dateQ)) < 2020
        replace `v'_std = `v' / r(sd) if data == "`d'"
    }
}


* Global risk and sentiment
preserve
    keep if data == "all"
    collapse (mean) globalrisk=risk globalsentiment=sentiment, by(dateQ)
    su globalrisk if yofd(dofq(dateQ)) < 2020
    gen globalrisk_std = globalrisk / r(sd)
    qui su globalsentiment if yofd(dofq(dateQ)) < 2020
    gen globalsentiment_std = globalsentiment / r(sd)
    tempfile a
    save "`a'", replace
restore
merge m:1 dateQ using "`a'"
drop _merge


* Crisis indicator
preserve
	import delimited using "`temp_folder'/crises.csv", clear varnames(1)
	gen dateQ = quarterly(dateq, "YQ")
	format dateQ %tq
	drop dateq
	gen crisis = "local" if nolocal == "no"
	replace crisis = "global" if nolocal == "yes"
	drop nolocal
	drop if yofd(dofq(dateQ)) > 2019
	tempfile a
	save "`a'", replace
restore
merge m:1 country_iso2 dateQ using "`a'"
drop _merge
replace crisis = "global" if inlist(dateQ, 195, 196, 197)

* ID variables
egen country_id = group(country_iso2)
egen id = group(country_id data)
drop if id== .

* Winsorize CDS
winsor2 spread5y spread5y_pa, cuts(0 99) replace

* Panel variables
xtset id dateQ
gen exposure_stdD = exposure_std - l.exposure_std
gen sentiment_stdD = sentiment_std - l.sentiment_std
gen risk_stdD = risk_std - l.risk_std
gen spread5yD = spread5y - l.spread5y

gen log_risk_std = log(risk_std)
gen log_sentiment_std = log(sentiment_std)
gen log_risk = log(risk)
gen log_sentiment = log(sentiment)
gen log_globalrisk = log(globalrisk)
gen d_log_sentiment_std = log(sentiment_std) - log(l.sentiment_std)
gen d_log_risk_std = log(risk_std) - log(l.risk_std)
gen d_log_sentiment = log(sentiment) - log(l.sentiment)
gen d_log_risk = log(risk) - log(l.risk)
gen d_log_globalrisk = log(globalrisk) - log(l.globalrisk)
gen d_log_firmrisk_std = log(firmrisk_5plus_std) - log(l.firmrisk_5plus_std)
gen d_cds = spread5y - l.spread5y
gen d_cds_pa = spread5y_pa - l.spread5y_pa
gen d_realizedvol = realizedvol - l.realizedvol
gen d_total_inflows = total_inflows - l.total_inflows
gen d_wui_std = d.wui_std
gen d_log_wui = log(wui) - log(l.wui)
*gen d_log_epu_national = log(epu_national) - log(l.epu_national)

xtset, clear
drop id

*Emerging markets (taken from S&P Emerging BMI as of Oct 27, 2020)
gen emerging = 1 if country_name == "Brazil" | country_name == "Chile" ///
    | country_name == "China" | country_name == "Colombia" ///
    | country_name == "Czech Republic" | country_name == "Egypt" ///
    | country_name == "Greece" | country_name == "Hungary" ///
    | country_name == "India" | country_name == "Indonesia" ///
    | country_name == "Malaysia" | country_name == "Mexico" ///
    | country_name == "Pakistan" | country_name == "Peru" ///
    | country_name == "Philippines" | country_name == "Poland" ///
    | country_name == "Qatar" | country_name == "Russia" ///
    | country_name == "South Africa" | country_name == "Taiwan" ///
    | country_name == "Saudi Arabia" | country_name == "Kuwait" ///
    | country_name == "Thailand" | country_name == "Turkey" ///
    | country_name == "UAE" ///
    | country_name == "Argentina" | country_name == "Iran" ///
    | country_name == "Nigeria" | country_name == "Venezuela"
replace emerging = 0 if emerging == .

*Developed markets (taken from S&P Developed BMI as of Oct 27, 2020
gen developed = 1 if country_name == "United States" | country_name == "Japan" | ///
    country_name == "United Kingdom" | country_name == "Canada" | ///
    country_name == "Switzerland" | country_name == "France" | ///
    country_name == "Germany" | country_name == "Australia" | ///
    country_name == "South Korea" | country_name == "Netherlands" | ///
    country_name == "Sweden" | country_name == "Hong Kong" | ///
    country_name == "Italy" | ///
    country_name == "Spain" | country_name == "Singapore" | ///
    country_name == "Belgium" | ///
    country_name == "Israel" | country_name == "Norway" | ///
    country_name == "Ireland" | country_name == "New Zealand"
replace developed = 0 if developed == .

*** Risk resid

* Risk residual after taking out country FE
reghdfe risk if data == "all", absorb(country_id) residuals(risk_resid)
qui su risk_resid if yofd(dofq(dateQ)) < 2020 & data == "all"
scalar sd = r(sd)
replace risk_resid = risk_resid / `=sd' if data == "all"

* Label
la var data "Sample"
la var exposure "Average country exposure"
la var risk "Average country exposure: risk"
la var sentiment "Average country exposure: sentiment"
la var nroffirms "Number of firms the average is based on"
la var nrofhqfirms "Number of firms with HQ in that country"
la var firmrisk_5plus "Average risk based on domestic firms"

* Save
sort country_iso2 data dateQ
order country_iso2 data dateQ
compress
save "`output_file'", replace
*}
