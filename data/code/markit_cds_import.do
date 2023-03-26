********************************************************************************
*                             markit_cds_import.do file:                       *
*                                                                              *
*                            Prepare markit_cdsQ.dta                           *  
********************************************************************************


use "$RAW_DATA/markit_cds/ZBCJBOFJ843QUMYB.dta", clear

keep redcode date tier ccy ticker shortname docclause country spread5y

* Keep only tier == SNRFOR ("Foreign Currency Sovereign Debt")
keep if tier == "SNRFOR"
drop tier


* Keep only currency USD
keep if ccy == "USD"
drop ccy


* Manually add country iso2 codes
gen country_iso2 = ""
replace country_iso2 = "DZ" if ticker == "ALGERI"
replace country_iso2 = "AO" if ticker == "ANGOLA"
replace country_iso2 = "AR" if ticker == "ARGENT"
replace country_iso2 = "AU" if ticker == "AUSTLA"
replace country_iso2 = "AT" if ticker == "AUST"
replace country_iso2 = "BH" if ticker == "BHREIN"
replace country_iso2 = "BB" if ticker == "BARBAD"
replace country_iso2 = "BE" if ticker == "BELG"
replace country_iso2 = "BZ" if ticker == "BLZE"
replace country_iso2 = "BR" if ticker == "BRAZIL"
replace country_iso2 = "BG" if ticker == "BGARIA"
replace country_iso2 = "CA" if ticker == "CAN"
replace country_iso2 = "CL" if ticker == "CHILE"
replace country_iso2 = "CN" if ticker == "CHINA"
replace country_iso2 = "CI" if ticker == "IVYCST"
replace country_iso2 = "CO" if ticker == "COLOM"
replace country_iso2 = "CR" if ticker == "COSTAR"
replace country_iso2 = "HR" if ticker == "CROATI"
replace country_iso2 = "CY" if ticker == "CYPRUS"
replace country_iso2 = "CZ" if ticker == "CZECH"
replace country_iso2 = "DK" if ticker == "DENK"
replace country_iso2 = "DO" if ticker == "DOMREP"
replace country_iso2 = "EC" if ticker == "ECUA"
replace country_iso2 = "EG" if ticker == "EGYPT"
replace country_iso2 = "SV" if ticker == "ELSALV"
replace country_iso2 = "EE" if ticker == "ESTONI"
replace country_iso2 = "FJ" if ticker == "FIJI"
replace country_iso2 = "FI" if ticker == "FINL"
replace country_iso2 = "FR" if ticker == "FRTR"
replace country_iso2 = "DE" if ticker == "DBR"
replace country_iso2 = "GH" if ticker == "RPGANA"
replace country_iso2 = "GR" if ticker == "GREECE"
replace country_iso2 = "GT" if ticker == "GUATEM"
replace country_iso2 = "HK" if ticker == "CHINA-HongKong"
replace country_iso2 = "IS" if ticker == "ICELND"
replace country_iso2 = "IN" if ticker == "IGB"
replace country_iso2 = "ID" if ticker == "INDON"
replace country_iso2 = "IQ" if ticker == "IRAQ"
replace country_iso2 = "IE" if ticker == "IRELND"
replace country_iso2 = "IL" if ticker == "ISRAEL"
replace country_iso2 = "IT" if ticker == "ITALY"
replace country_iso2 = "JM" if ticker == "JAMAN"
replace country_iso2 = "JP" if ticker == "JAPAN"
replace country_iso2 = "JO" if ticker == "JORDAN"
replace country_iso2 = "KZ" if ticker == "KAZAKS"
replace country_iso2 = "KR" if ticker == "KOREA"
replace country_iso2 = "LV" if ticker == "LATVIA"
replace country_iso2 = "LB" if ticker == "LEBAN"
replace country_iso2 = "LT" if ticker == "LITHUN"
replace country_iso2 = "MK" if ticker == "MCDNIA"
replace country_iso2 = "MY" if ticker == "MALAYS"
replace country_iso2 = "MT" if ticker == "MALTA"
replace country_iso2 = "MX" if ticker == "MEX"
replace country_iso2 = "MA" if ticker == "MOROC"
replace country_iso2 = "NL" if ticker == "NETHRS"
replace country_iso2 = "NZ" if ticker == "NZ"
replace country_iso2 = "NG" if ticker == "NGERIA"
replace country_iso2 = "NO" if ticker == "NORWAY"
replace country_iso2 = "OM" if ticker == "OMAN"
replace country_iso2 = "PK" if ticker == "PAKIS"
replace country_iso2 = "PA" if ticker == "PANAMA"
replace country_iso2 = "PE" if ticker == "PERU"
replace country_iso2 = "PH" if ticker == "PHILIP"
replace country_iso2 = "PL" if ticker == "POLAND"
replace country_iso2 = "PT" if ticker == "PORTUG"
replace country_iso2 = "QA" if ticker == "QATAR"
replace country_iso2 = "RO" if ticker == "ROMANI"
replace country_iso2 = "RU" if ticker == "RUSSIA"
replace country_iso2 = "SA" if ticker == "SAUDI"
replace country_iso2 = "SG" if ticker == "SIGB"
replace country_iso2 = "SK" if ticker == "SLOVAK"
replace country_iso2 = "SI" if ticker == "SLOVEN"
replace country_iso2 = "ZA" if ticker == "SOAF"
replace country_iso2 = "ES" if ticker == "SPAIN"
replace country_iso2 = "LK" if ticker == "SRILAN"
replace country_iso2 = "SE" if ticker == "SWED"
replace country_iso2 = "CH" if ticker == "SWISS"
replace country_iso2 = "TW" if ticker == "TGB"
replace country_iso2 = "TH" if ticker == "THAI"
replace country_iso2 = "TT" if ticker == "TRITOB"
replace country_iso2 = "TN" if ticker == "BTUN"
replace country_iso2 = "TR" if ticker == "TURKEY"
replace country_iso2 = "UA" if ticker == "UKRAIN"
replace country_iso2 = "AE" if ticker == "UAE"
replace country_iso2 = "GB" if ticker == "UKIN"
replace country_iso2 = "US" if ticker == "USGB"
replace country_iso2 = "UY" if ticker == "URUGAY"
replace country_iso2 = "VE" if ticker == "VENZ"
replace country_iso2 = "VN" if ticker == "VIETNM"

keep if country_iso2 != ""


*Prefer docclause == "CR"
duplicates tag ticker date, gen(x)
gen y = 1 if docclause == "CR"
sort ticker date y
drop if y == . & x > 0
drop x y

duplicates drop


*Take end of quarter value
gen dateQ = qofd(date)
format dateQ %tq
gen spread5y_pa=spread5y
collapse (lastnm) spread5y=spread5y (mean) spread5y_pa, by(dateQ country_iso2)


*Convert to percent
replace spread5y = spread5y*100
replace spread5y_pa = spread5y_pa*100

la var spread5y "5-year sovereign CDS spread (in pct)"
la var spread5y_pa "5-year sovereign CDS spread (in pct), Period Average"

compress
save "$DATA/temp/markit_cdsQ.dta", replace
