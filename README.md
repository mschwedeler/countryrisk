# Overview

This repository replicates the 10 tables and 8 figures in [Hassan et al. (2023)](#countryrisk). There are two main Python files:
- `data/make.py` will run all necessary data cleaning and manipulation codes, and
- `analysis/make.py` will generate the tables and figures in the paper.

To run either code, the replicator should ensure that all necessary programs and modules are installed; see the [how to run](#how-to-run-the-replication) section below.

The replicator should expect the `data/make.py` to run in about 30 minutes, wheras the `analysis/make.py` should take less than five minutes. This is with a 2021 MacBook Pro.

# How to run the replication

## Overview

To run the replication, you need to have Stata installed and available in your path environment, and a Python virtual environment with the config/requirements.txt installed.

The code was tested on MacOS 12.6.3 with Stata 14.2, Python 3.9.13, and the Python modules specified in `config/requirements.txt`.

## Preparation

1) Install Stata, a few community-contributed packages, and make sure Stata can be accessed via the command line:
    - This repository was tested using Stata 14.2.
    - Make sure the following community-contributed Stata packages are installed: `mmerge, estout, blindschemes, reghdfe`.
    - Test whether Stata is available via the command line. To do so, open a terminal and type `stata` (or `stata-mp`, depending on the flavor you have installed). This should open Stata in the command line; if it doesn't please check whether the command is in your path environment. 

2) Create a virtual environment with Python 3.9 and install the `config/requirements.txt`. One way to do this:
    ```shell
    # be sure that you are in the replication folder
    python -m venv .venv # installs virtual environment in ./.venv
    source .venv/bin/activate # activates virtual environment
    python -m pip install -r config/requirements.txt # installs all modules
    ```
    (Optional:) You can also manually compile the the config/requirements.txt from the config/requirements.in with the `pip-tools` module, and sync all packages in the virtual environment with pip-sync.
    ```shell
    source .ven/bin/activate
    python -m pip install pip-tools # install pip-tools
    pip-compile --generate-hashes config/requirements.in
    pip-sync config/requirements.txt
    ```
    Note that you do not need the `eikon` and `wrds` modules for running either `data/make.py` or `analysis/make.py`. They are used for downloading the raw data.

3) Edit line 2 of the config.yaml file in the root directory of this replication folder by adding the command that calls Stata from the command line.

4) Make sure that you have all the `raw_data` files that the config.yaml expects. If necessary, adjust the path or file name in config.yaml.

5) Run the code that creates the final data sets. Open your shell, navigate to the replication directory, and then run the data manipulation codes. This will create all data sets necessary to produce the tables and figures:
    ```shell
    source .venv/bin/activate
    python data/make.py
    ```
6) Run the code that creates the tables and figures. Open your shell, navigate to the replication directory, and run
    ```shell
    source .venv/bin/activate
    python analysis/make.py
    ```
7) (Optional) Compile the `analysis/output/tables_figures.tex` with your favorite tex editor.


# List of Figures and Tables

All figures and tables are created -- and the relevant code is called from -- `analysis/code/make.py`.

Figure/Table | Program | Output file | Notes
--- | --- | --- | ---
Figure 1 | `analysis/code/python/helpers.py` | `analysis/output/figures/Figure1_coverage.eps`
Figure 2 | `analysis/code/python/helpers.py` | `analysis/output/figures/Figure2_greece.eps`
Figure 3 | `analysis/code/python/helpers.py` | `analysis/output/figures/Figure3_thailand.eps`
Figure 4 | `analysis/code/python/helpers.py` | `analysis/output/figures/Figure4_unitedstates.eps`
Figure 5 | `analysis/code/stata/figure5.do` | `analysis/output/figures/Figure5_risk_timeFE.eps`
Figure 6 | `analysis/code/stata/figure6.do` | `analysis/output/figures/Figure6_crises_XX.eps` | XX stands for all countries with local crises
Figure 7 | `analysis/code/python/helpers.py` | `analysis/output/figures/Figure7_transmissionrisk_scatter_XX.eps` | XX stands for selected crises: CN, GR, HK, JP, TH, US
Figure 8 | `analysis/code/python/helpers.py` | `analysis/output/figures/Figure8_transmissionrisk_scatter_IT_NFCvsFIN_crisis1.eps`
Table 1 | `analysis/code/python/helpers.py` | `analysis/output/tables/Table1_coverage.tex` 
Table 2 | `analysis/code/python/helpers.py` | `analysis/output/tables/Table2_top20ngrams_gr.tex`, `analysis/output/tables/Table2_top20ngrams_jp.tex`, `analysis/output/tables/Table2_top20ngrams_tr.tex` 
Table 3 | `analysis/code/stata/table3.do` | `analysis/output/tables/Table3_firmcountry_pooledreg.tex`
Table 4 | `analysis/code/stata/table4.do` | `analysis/output/tables/Table4_PanelA_sustats_FirmCountry.tex` `analysis/output/tables/Table4_PanelB_sustats_CountryQuarter.tex`
Table 5 | `analysis/code/stata/table4.do` | `analysis/output/tables/Table5_countrylevel_validation.tex`
Table 6 | `analysis/code/python/helpers.py` | `analysis/output/tables/Table6_transmissionrisk_topdestinations.tex`, `analysis/output/tables/Table6_transmissionrisk_topsources.tex`
Table 7 | `analysis/code/stata/table7_prepare.do`, `analysis/code/python/helpers.py` | `analysis/output/tables/Table7_transmissionrisk_overview.tex` | Stata code prepares the table; Python code writes the table
Table 8 | `analysis/code/stata/table8.do` | `analysis/output/tables/Table8_countrylevel_capitalflows.tex`, `analysis/output/tables/Table8_countrylevel_indicator_capitalflows.tex`
Table 9 | `analysis/code/stata/table9.do` | `analysis/output/tables/Table9_countrylevel_retrench.tex`, `analysis/output/tables/Table8_countrylevel_stop.tex`
Table 10 | `analysis/code/stata/table10.do` | `analysis/output/tables/Table10_PanelA_countrylevel_executivesviews_inflows.tex`, `analysis/output/tables/Table10_PanelA_countrylevel_executivesviewsFIN_inflows.tex`

# Data availability statements

The following table lists all data sources used to create the figures and tables in the paper. Following the table, we provide more details about each data source and how to access the data.

Data name | Data files | Location | Provided | Citation | Last accessed
--- | --- | --- | --- | --- | ---
BvD Orbis | orbis_downloaded.dta | raw/orbis | No | [BvD Orbis](#bvdorbis) | Early 2021
Chicago Fed National Activity Index (CFNAI) | cfnai-realtime-3-xlsx.xlsx | raw/cfnai | Yes | [Federal Reserve Bank of Chicago](#cfnai) | December 23, 2020
Compustat Global | global_company.pkl, global_names.csv, global_secd_decXXXX_marketcap.pkl | raw/compustat/global | No | [S&P Market Intelligence](#compustat) | February 2023
Compustat North America | na_company.pkl, na_names.csv, na_secd_decXXXX_marketcap.pkl | raw/compustat/na | No | [S&P Market Intelligence](#compustat) | February 2023
Country.io | iso3.json, names.json | raw/country_identifiers | Yes | [Country.io](#countryio) | July 2019
Economist Intelligence Unit | Country Commerce Reports 2002-2019 for the largest 45 economies | raw/eiu | No | [Economist Intelligence Unit](#eiu) | January 2020
Firm Risk | firmquarter_2022q1.csv | raw/firm_risk | Yes | [Hassan et al. (2019)](#hassanetal2019) | February 2023
IHS Markit | ZBCJBOFJ843QUMYB.dta | raw/markit_cds | No | [IHS Markit](#ihsmarkit) | July 2019
IMF Balance of Payments Statistics (BOPS) | BOP_02-21-2021 20-53-42-00_timeSeries | raw/imf_capitalflows | Yes | [IMF BOPS](#imfbops) | February 2021
IMF International Financial Statistics (IFS) | imf_ifs_gdp.xlsx | raw/ifs_gdp | Yes | [IMF IFS](#imfifs) | January 2021
MSCI Indices | msci_updated20201222.csv | raw/msci_returns | No | [MSCI Indices](#msciindices) | December 2020
Refinitiv | Transcribed earnings calls | raw/refinitiv | No | [Refinitiv](#refinitiv) | January 2021
Sudden stops | ForbesWarnock_episodes.dta,  Capital Flow Waves or Ripples_READ ME.pdf | raw/forbeswarnock_suddenstops | yes | [Forbes and Warnock (2021)](#forbeswarnock) | February 2021
World Bank Open Data | 86fdf075-7e81-4ace-bd88-1035908153e7_Data.csv, 86fdf075-7e81-4ace-bd88-1035908153e7_Series - Metadata.csv | raw/worldbank_gdp | Yes | [World Bank](#worldbank) | July 2022
World Uncertainty Index | WUI_Data_03032021.xlsx | raw/world_uncertainty_index | Yes | [Ahir et al. (2022)](#ahir2022) | March 2021
WorldScope Geographic Segments | capex_sales_intermediate.dta | raw/worldscope | No | [WorldScope Geographic Segments](#worldscope) | Early 2019


## BvD Orbis

The paper uses data from [BvD Orbis](#bvdorbis). The data were downloaded from the NBER [https://www.nber.org/research/data/orbis](https://www.nber.org/research/data/orbis) in early 2021. This is a commercial data set that can also be subscribed through Bureau van Dijk directly.

## Chicago Fed National Activity Index (CFNAI)

The paper uses the Chicago Fed National Activity Index, [CFNAI](#cfnai). The data can be downloaded from [https://www.chicagofed.org/research/data/cfnai/historical-data](https://www.chicagofed.org/research/data/cfnai/historical-data). We last downloaded the data on December 22, 2020.

## Compustat Global and North America

The paper uses data from [S&P Global Intelligence](#compustat)'s Compustat Global and North America. This is a commercial data set that is not freely available. We obtained the data with our Wharton Research Data Services (WRDS) account.

We provide a Python script (`raw/compustat/download_compustat.py`) for interested researchers, who also have a WRDS license. The script will download the data necessary for this paper. We last downloaded the so-called "names" files in June 2020; the remaining files were last downloaded in February 2023.

## Country.io

The paper uses data provided by [Country.io](#countryio2019) to consistently move between country's ISO-2 abbreviation, ISO-3 abbreviation, and names. The data is freely available. We last downloaded the data in July 2019.

## Economist Intelligence Unit

The paper uses the Country Commerce Reports from the [Economist Intelligence Unit](#eiu). This is a commercial data set that can be purchased directly from the Economist Intelligence Unit. Some university libraries also have access to these reports. We last accessed the data in January 2020.

## Firm Risk

The paper uses data from [Hassan et al. (2019)](#hassanetal2019). The firm level data can be downloaded from [firmlevelrisk.com](firmlevelrisk.com). We last downloaded the data in February 2023.

## IHS Markit

The paper uses data from [IHS Markit](#ihsmarkit). The quarterly country CDS data is proprietary but can be subscribed to through Wharton Research Data Services (WRDS); the name on WRDS of the data set we use is `markit_cds`. We last downloaded the data in July 2019.

## IMF Balance of Payments Statistics

The paper uses data from the [IMF BOPS](#imfbops) data. The data is freely available and can be downloaded from [data.imf.org](data.imf.org). We last downloaded the balance of payment statistics in February 2021.

## IMF International Financial Statistics

The paper uses the quarterly GDP data from the [IMF IFS](#imfifs) data. The data is freely available and can be downloaded from [data.imf.org](data.imf.org). We last downloaded the quarterly GDP data in January 2021.

## MSCI Indices

The paper uses the quarterly country level equity indices from [MSCI Indices](#msciindices). This is a commercial data set that can be purchased through, for example, Refinitiv. We downloaded the data with the Python API of Refinitiv's Eikon. Please see the script `raw/msci_returns/download_msci_data.py` and the notes below.

Our last update was on 12-22-2020. We download the following three indices:
1. "MSCI XXX Gross Index Local"
2. "MSCI XXX Net Index Local"
3. "MSCI XXX Price Index Local"

If you have an Refinitiv Eikon subscription, you can proceed as follows to download the data:
- Fill in your Eikon app key in the relevant line (line 11) of `download_msci_data.py`
- Run `python download_data.py` from the command line.
The script will create a temporary folder "temp" that can be deleted after the files have been downloaded successfully.

## Refinitiv

The paper uses the transcribed earnings calls from [Refinitiv](#refinitiv). This is a commercial data set that can be subscribed through various products of Refinitiv, including Eikon, Workspace, or a dedicated API. We last updated the earnings calls in January 2021.

## Sudden Stops

The paper uses data from [Forbes and Warnock, (2021)](#forbeswarnock). The data and explanatory pdf file can be downloaded from Kirstin Forbes' [website](#https://mitmgmtfaculty.mit.edu/kjforbes/research/) (a direct [link](https://www.dropbox.com/s/vdrryyeio35zxr3/ForbesWarnock_episodes.dta?dl=1) to the Stata file). We last downloaded the data in February 2021.

## World Bank Open Data

The paper uses annual country-level GDP data from the [World Bank](#worldbank) through their [World Bank Open Data](#data.worldbank.org) portal. We last downloaded the data in July 2022.

We use the series `NY.GDP.MKTP.KD`, which is GDP (constant 2015 US$).

## World Uncertainty Index

The paper uses the quarterly country-level newspaper-based World Uncertainty Index developed by [Ahir et al., (2022)](#ahir2022). The data is freely available from [https://worlduncertaintyindex.com](#https://worlduncertaintyindex.com). We last downloaded the data in March 2021.

## WorldScope Geographic Segments

The paper uses Refnitiv's [WorldScope Geographic Segments](#worldscope) data. The data is proprietary but can be subscribed to through Wharton Research Data Services (WRDS). We last downloaded the data in early 2019.

We gratefully acknowledge Thomas Rauter, whose prior work [(Rauter, 2020)](#rauter) with cleaning the data we were able to use.

# References

<a id="ahir2021">[Ahir et al., 2022]</a> Hites Ahir, Nicholas Bloom, Davide Furceri, World Unicertainty Index, NBER Working Paper [29763](https://www.nber.org/papers/w29763), February 2022.

<a id="bvdorbis">[BvD Orbis]</a> Bureau van Dijk, Orbis, retrieved from the NBER Orbis group; [https://www.nber.org/research/data/orbis](https://www.nber.org/research/data/orbis), early 2021.

<a id="cfnai">[CFNAI]</a> Federal Reserve Bank of Chicago, Chicago Fed National Activity Index (CFNAI), retrieved from the Federal Reserve Bank of Chicago; [https://www.chicagofed.org/research/data/cfnai/historical-data](https://www.chicagofed.org/research/data/cfnai/historical-data), December 22, 2020.

<a id="countryio2019">[Country.io]</a> Country ISO-3 abbreviations and names, retrieved from Country.io; [http://country.io/data/](http://country.io/data/), July 2019.

<a id="eiu">[Economist Intelligence Unit]</a> Economist Intelligence Unit, Country Commerce Reports, retrieved from [https://store.eiu.com/product/country-commerce/](#https://store.eiu.com/product/country-commerce/) in January 2020.

<a id="forbeswarnock">[Forbes and Warnock, 2021]</a> Kristin J. Forbes and Francis E. Warnock, Capital Flow Waves—or Ripples? Extreme Capital Flow Movements since the Crisis, Journal of International Money and Finance, 2021, 116, 102394, [https://doi.org/10.1016/j.jimonfin.2021.102394](https://doi.org/10.1016/j.jimonfin.2021.102394)

<a id="hassanetal2019">[Hassan et al., 2019]</a> Tarek A. Hassan, Stephan Hollander, Laurence van Lent, Ahmed Tahoun, Firm-Level Political Risk: Measurement and Effects, The Quarterly Journal of Economics, Volume 134, Issue 4, November 2019, Pages 2135–2202, [https://doi.org/10.1093/qje/qjz021](https://doi.org/10.1093/qje/qjz021)

<a id="countryrisk">[Hassan et al., 2023]</a> Tarek A. Hassan, Stephan Hollander, Laurence van Lent, Ahmed Tahoun, Sources and Transmission of Country Risk, The Review of Economic Studies, forthcoming.

<a id="ihsmarkit">[IHS Markit]</a> IHS Markit, Credit Default Swap (CDS), retrieved from Wharton Research Data Services as "markit_cds", July 2019.

<a id="imfifs">[IMF IFS]</a> International Monetary Fund, International Financial Statistics (IFS), retrieved from [data.imf.org](data.imf.org) in January 2021.

<a id="imfbops">[IMF BOPS]</a> International Monetary Fund, Balance of Payments and International Investment Position Statistics (BOP/IIP), retrieved from [data.imf.org](data.imf.org) in February 2021.

<a id="msciindices">[MSCI Indices]</a> Morgan Stanley Capital International (MSCI) Indices, retrieved via the Python API of Thomson Eikon using the module `eikon`, from Thomson Eikon, December 2020.

<a id="rauter">[Rauter, 2020]</a> Thomas Rauter, The Effect of Mandatory Extraction Payment Disclosures on Corporate Payment and Investment Policies Abroad. Journal of Accounting Research, 58: 1075-1116. [https://doi.org/10.1111/1475-679X.12332](https://doi.org/10.1111/1475-679X.12332), August 2020.

<a id="refinitiv">[Refinitiv]</a> Refinitiv, Street Events, retrieved from Refinitiv Eikon, January 2021.

<a id="compustat">[S&P Global Market Intelligence]</a> S&P Global Market Intelligence, Compustat North America and Compustat Global (Compustat), retrieved via the Python API using the module `wrds`, from Wharton Research Data Services, February 2023.

<a id="worldbank">[World Bank]</a> World Bank Open Data: Global Development Indicators, retrieved via [data.worldbank.org](#data.worldbank.org), July 2022.

<a id="worldscope">[Worldscope Geographic Segments]</a> Refinitiv WorldScope Geographic Segments, retrieved from Wharton Research Data Services, early 2019.


# Acknowledgements

We thank Jiarui Wang for her help in preparing this repository.