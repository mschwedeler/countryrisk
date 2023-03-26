import json
import os
import re

import pandas as pd


def import_countryidentifiers(
        rawdata_folder: str,
        data_folder: str
) -> None:
    print('Import country identifiers...')
    # Identify files
    files_expected = [
        'iso3.json',
        'names.json'
    ]
    files = [x for x in os.listdir(rawdata_folder) if '.json' in x]
    assert set(files).intersection(files_expected) == set(files_expected)
    # Save each as dta for Stata import
    colnames = {
        'iso3.json': 'iso3',
        'names.json': 'country_name'
    }
    for file in files:
        colname = colnames[file]
        with open(os.path.join(rawdata_folder, file), 'r', encoding='utf-8') as infile:
            data = json.load(infile)
        data = pd.DataFrame.from_dict(
            data, orient='index'
        ).reset_index().rename(
            columns={'index':'iso2', 0:colname}
        ).to_stata(
            os.path.join(data_folder, re.sub(r'\.json','.dta', f'iso2_{file}')),
            write_index=False
        )
    return None