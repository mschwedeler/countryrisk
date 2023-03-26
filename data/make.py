import os

from code.countryidentifiers_import import import_countryidentifiers
from code.compustat_import import import_compustat
from code.worldbank_gdp_import import import_worldbank_gdp
from code.create_coverage_data import import_our_sample, create_coverage_data
from code.country_quarter_decomposed import create_decomposed_country_quarter


if __name__ == '__main__':

    # Root dir
    ROOT_DIR = '..'

    # Folders
    RAW_DATA = f'{ROOT_DIR}/raw'
    DATA = f'{ROOT_DIR}/data'

    if not os.path.isdir(f'{DATA}/final'):
        os.mkdir(f'{DATA}/final')
    if not os.path.isdir(f'{DATA}/temp'):
        os.mkdir(f'{DATA}/temp')

    # Import country identifiers
    import_countryidentifiers(
        f'{RAW_DATA}/country_identifiers',
        f'{DATA}/temp'
    )
    # Import worldbank GDP (2019)
    import_worldbank_gdp(
        f'{RAW_DATA}/worldbank_gdp/86fdf075-7e81-4ace-bd88-1035908153e7_Data.csv',
        f'{DATA}/temp/worldbank_gdp_2019.csv'
    )
    # Import Compustat
    import_compustat(
        f'{RAW_DATA}/compustat',
        f'{DATA}/temp'
    )
    # Import our sample of firms
    import_our_sample(
        f'{RAW_DATA}/refinitiv/scores.dta',
        f'{DATA}/temp/our_sample.pkl'
    )
    # Create data set for Table 1 and Figure 1
    create_coverage_data(
        f'{DATA}/temp/compustat_merged.pkl',
        f'{DATA}/temp/iso2_names.dta',
        f'{DATA}/temp/iso2_iso3.dta',
        f'{DATA}/temp/our_sample.pkl',
        f'{DATA}/final/data_coverage.pkl'
    )
    # Create data set for Figures 2-4
    create_decomposed_country_quarter(
        f'{RAW_DATA}/refinitiv/scores.dta',
        f'{DATA}/final/country_quarter_decomposed_XXX.pkl'
    )