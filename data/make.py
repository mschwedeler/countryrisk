import argparse
import os
from pathlib import Path
import shutil
import subprocess
from typing import Dict, Iterable, Union

import yaml

from code.python.countryidentifiers_import import import_countryidentifiers
from code.python.compustat_import import import_compustat
from code.python.worldbank_gdp_import import import_worldbank_gdp
from code.python.create_coverage_data import (
    import_our_sample, create_coverage_data
)
from code.python.country_quarter_decomposed import create_decomposed_country_quarter


# project root
ROOT = Path(
    os.path.join(
        os.path.abspath(os.path.dirname(__file__)),
        '../'
    )
)

# config file, input and output folder
CONFIG_FILE = ROOT.joinpath('config.yaml')
DATA = ROOT.joinpath('data')
RAW_DATA = ROOT.joinpath('raw')


def check_files_exist(file_dict: Dict[str, str]) -> Dict[str, str]:
    """Checks whether files exist. Raises FileNotFoundError if file is not found.

    Args:
        file_dict (Dict[str, Path]): Dictionary of file name keys and path values.

    Raises:
        FileNotFoundError: Raised if file doesn't exist.

    Returns:
        _type_: Returns none if all files exist.
    """
    for file_name, path_str in file_dict.items():
        if not os.path.exists(path_str):
            raise FileNotFoundError(
                f'File {file_name}: {path_str} is required but not found. Make sure it has been generated.'
            )
        

def prepend_files(
        input_dict: Dict[str, Union[str, Iterable[str]]],
        to_prepend: Path
) -> Dict[str, Union[Path, Iterable[Path]]]:
    data_files = {}
    for file_name, files in input_dict.items():
        if isinstance(files, str):
            data_files[file_name] = to_prepend.joinpath(files)
        elif isinstance(files, list):
            data_files[file_name] = [
                to_prepend.joinpath(x) for x in files
            ]
        elif isinstance(files, dict):
            data_files[file_name] = {
                key: to_prepend.joinpath(value) for key, value in files.items()
            }
        else:
            raise NotImplementedError(f'Not implemented: {type(files)}')
    return data_files


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        description='Processes all raw data to create analysis data sets.'
    )
    parser.add_argument('--clean_slate', action='store_true', default=True)
    args = parser.parse_args()

    # Replace existing output folder with empty folder
    if args.clean_slate:
        print('Deleting existing output...')
        if DATA.joinpath('final').exists():
            shutil.rmtree(DATA.joinpath('final'), ignore_errors=True)
        if DATA.joinpath('temp').exists():
            shutil.rmtree(DATA.joinpath('temp'), ignore_errors=True)
        if DATA.joinpath('logs').exists():
            shutil.rmtree(DATA.joinpath('logs'), ignore_errors=True)
    if not DATA.joinpath('final').exists():
        DATA.joinpath('final').mkdir()
    if not DATA.joinpath('temp').exists():
        DATA.joinpath('temp').mkdir()
    if not DATA.joinpath('logs').exists():
        DATA.joinpath('logs').mkdir()

    # load config yaml
    with CONFIG_FILE.open('r', encoding='utf-8') as stream:
        try:
            config_dict = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
        # add absolute path to files
        final_data = prepend_files(config_dict['final_data'], DATA)
        raw_data = prepend_files(config_dict['raw_data'], RAW_DATA)

    # Change folder so that Stata logs end up in the correct folder
    os.chdir(DATA.joinpath('logs'))

    # Import country identifiers
    import_countryidentifiers(
        input_files=raw_data['COUNTRYIDENTIFIERS_FILES'],
        output_folder=DATA.joinpath('temp')
    )

    # Import worldbank GDP (2019)
    import_worldbank_gdp(
        input_file=raw_data['WORLDBANK_FILE'],
        output_file=DATA.joinpath('final/worldbank_gdp_2019.csv')
    )
    
    # Import Compustat
    import_compustat(
        raw_data['COMPUSTAT_FILES'],
        DATA.joinpath('temp')
    )

    # Import our sample of firms
    import_our_sample(
        raw_data['SCORES_FILE'],
        DATA.joinpath('temp/our_sample.pkl')
    )

    # Create data set for Table 1 and Figure 1
    create_coverage_data(
        DATA.joinpath('temp/compustat_merged.pkl'),
        DATA.joinpath('temp/iso2_names.dta'),
        DATA.joinpath('temp/iso2_iso3.dta'),
        DATA.joinpath('temp/our_sample.pkl'),
        final_data['COVERAGE_FILE']
    )

    # Create data set for Figures 2-4
    create_decomposed_country_quarter(
        raw_data['SCORES_FILE'],
        final_data['DECOMPOSED_FIN_FILE'].as_posix().replace('_fin', '_XXX')
    )

    # Import CFNAI
    print('Import CFNAI...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/cfnai_import.do\"',
            raw_data['CFNAI_FILE'],
            DATA.joinpath('temp/cfnaiQ.dta').as_posix()
        ],
        check=False
    )

    # Import IMF IFS GDP
    print('Import IMF IFS GDP...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/ifs_gdp_import.do\"',
            raw_data['IMF_IFS_GDP_FILE'],
            DATA.joinpath('temp/ifs_gdpQ.dta').as_posix()
        ],
        check=False
    )
    
    # Import IMF Capital flows
    print('Import IMF capital flows...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/imf_capitalflows_import.do\"',
            f'\"{raw_data["IMF_CAPITALFLOWS_FILES"]["BOP_CODES"]}\"',
            f'\"{raw_data["IMF_CAPITALFLOWS_FILES"]["BOP_TIMESERIES"]}\"',
            f'\"{raw_data["IMF_CAPITALFLOWS_FILES"]["COUNTRYCODES"]}\"',
            DATA.joinpath('temp/grcf_capital_flows.dta').as_posix(),
            DATA.joinpath('temp').as_posix()
        ],
        check=False
    )
    
    # Import MSCI data
    print('Import MSCI...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/msci_returns_import.do\"',
            f'\"{raw_data["MSCI_FILE"]}\"',
            DATA.joinpath('temp/msci_returnsQ.dta').as_posix(),
            DATA.joinpath('temp')
        ],
        check=False
    )

    # Import Markit CDS data
    print('Import Markit CDS...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/markit_cds_import.do\"',
            f'\"{raw_data["MARKIT_FILE"]}\"',
            DATA.joinpath('temp/markit_cdsQ.dta').as_posix(),
        ],
        check=False
    )

    # Import World Uncertainty Index
    print('Import World Uncertainty Index...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/wui_import.do\"',
            f'\"{raw_data["WUI_FILE"]}\"',
            DATA.joinpath('temp/wuiQ.dta').as_posix(),
        ],
        check=False
    )

    # Import Orbis
    print('Import Orbis...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/orbis_import.do\"',
            f'\"{raw_data["ORBIS_FILE"]}\"',
            DATA.joinpath('temp/orbis.dta').as_posix(),
        ],
        check=False
    )

    # Import Worldscope
    print('Import Worldscope...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/worldscope_import.do\"',
            f'\"{raw_data["WORLDSCOPE_FILE"]}\"',
            f'\"{raw_data["COMPUSTAT_NA_NAMES_FILE"]}\"',
            f'\"{raw_data["COMPUSTAT_GLOBAL_NAMES_FILE"]}\"',
            DATA.joinpath('final/worldscope_FirmYearCountry.dta').as_posix(),
            DATA.joinpath('temp/worldscope_FirmCountry.dta').as_posix()
        ],
        check=False
    )

    # Import firm level risk
    print('Import firm-level risk...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/firmrisk_import.do\"',
            f'\"{raw_data["FIRMLEVELRISK_FILE"]}\"',
            DATA.joinpath('temp/firmrisk.dta').as_posix(),
        ],
        check=False
    )

    # Define crises
    print('Define local crises...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/define_crises.do\"',
            f'\"{raw_data["SCORES_FILE"]}\"',
            DATA.joinpath('temp/iso2_names.dta').as_posix(),
            DATA.joinpath('code/stata/crises_variables.do').as_posix(),
            DATA.joinpath('temp/crises.csv').as_posix(),
        ],
        check=False
    )

    # Define CountryRisk_ict
    print('Define CountryRisk_ict (less noisy)...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/countryrisk_less_noisy.do\"',
            f'\"{raw_data["SCORES_FILE"]}\"',
            DATA.joinpath('temp/transmissionrisk_FirmCountryQuarter.dta').as_posix(),
        ],
        check=False
    )

    # Create data sets
    print('Create country-quarter level data...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/country_quarter.do\"',
            f'\"{raw_data["SCORES_FILE"]}\"',
            DATA.joinpath('final/analysis_CountryQuarter.dta').as_posix(),
            DATA.joinpath('temp'),
            raw_data['FORBESWARNOCK_FILE']
        ],
        check=False
    )

    print('Create firm-country level data...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/firm_country.do\"',
            f'\"{raw_data["SCORES_FILE"]}\"',
            DATA.joinpath('final/analysis_FirmCountry.dta').as_posix(),
            DATA.joinpath('temp'),
        ],
        check=False
    )

    print('Create transmissionrisk origin-destination level data...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/transmissionrisk_OriginDestination.do\"',
            DATA.joinpath('temp').as_posix(),
            DATA.joinpath('final/transmissionrisk_OriginDestination.dta').as_posix(),
            DATA.joinpath('code/stata/crises_integers.do').as_posix()
        ],
        check=False
    )

    print('Create transmissionrisk origin-destination-tau level data...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/transmissionrisk_OriginDestinationTau.do\"',
            DATA.joinpath('temp').as_posix(),
            DATA.joinpath('final/transmissionrisk_OriginDestinationTau.dta').as_posix(),
            DATA.joinpath('code/stata/crises_integers.do').as_posix()
        ],
        check=False
    )

    print('Create transmissionrisk origin-firm-tau level data...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{DATA}/code/stata/transmissionrisk_OriginFirmTau.do\"',
            DATA.joinpath('temp').as_posix(),
            DATA.joinpath('final/transmissionrisk_OriginFirmTau.dta').as_posix(),
            DATA.joinpath('code/stata/crises_integers.do').as_posix()
        ],
        check=False
    )
