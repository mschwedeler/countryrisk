import json
import os
from pathlib import Path
import re
from typing import Iterable

import pandas as pd


def import_countryidentifiers(
        input_files: Iterable[Path],
        output_folder: Path
) -> None:
    print('Import country identifiers...')
    # Save each as dta for Stata import
    colnames = {
        'iso3.json': 'iso3',
        'names.json': 'country_name'
    }
    for file in input_files:
        colname = colnames[file.name]
        with file.open('r', encoding='utf-8') as infile:
            data = json.load(infile)
        data = pd.DataFrame.from_dict(
            data, orient='index'
        ).reset_index().rename(
            columns={'index':'iso2', 0:colname}
        ).to_stata(
            os.path.join(
                output_folder, re.sub(r'\.json','.dta', f'iso2_{file.name}')
            ),
            write_index=False
        )
