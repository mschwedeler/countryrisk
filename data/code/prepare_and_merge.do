


*global ROOT "/Users/Jiarui/Dropbox/Res_GRCF/Replication"
global ROOT "/Users/markusschwedeler/Dropbox/Res_GRCF/Replication"
cd ${ROOT}

global RAW_DATA "raw"
global DATA "data"


*Install gcollapse
*cap ssc install gtools	
cap ssc install mmerge


*-----------------*
* Import all data *
*-----------------*
* Import CFNAI
do "${DATA}/code/cfnai_import.do"

* Import GDP
do "${DATA}/code/ifs_gdp_import.do"

* Import IMF capital flows  
do "${DATA}/code/imf_capitalflows_import.do"

* Import MSCI data
do "${DATA}/code/msci_returns_import.do"

* Import Markit CDS data
do "${DATA}/code/markit_cds_import.do"

* Import World Uncertainty Index
do "${DATA}/code/wui_import.do"

* Import Orbis
do "${DATA}/code/orbis_import.do"

* Import Worldscope
do "${DATA}/code/worldscope_import.do"

* Import firm risk
do "${DATA}/code/firmrisk_import.do"

* Import EPU national
do "${DATA}/code/epu_national.do"

* Define crises
do "${DATA}/code/define_crises.do"

* Define CountryRisk_ict
do "${DATA}/code/countryrisk_less_noisy.do"


*----------------------------*
* Collect and merge all data *
*----------------------------*
* Country Risk
do "${DATA}/code/country_quarter.do"
do "${DATA}/code/firm_country.do"

* Transmission Risk
do "${DATA}/code/transmissionrisk_OriginDestination.do"
do "${DATA}/code/transmissionrisk_OriginDestinationTau.do"
do "${DATA}/code/transmissionrisk_OriginFirmTau.do"
