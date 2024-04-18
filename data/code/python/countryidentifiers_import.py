import json
import os
from pathlib import Path
import re
from typing import Iterable, Optional

import pandas as pd  # type: ignore


def import_countryidentifiers(
    input_files: Iterable[Path], output_folder: Path, return_files: bool = False
) -> Optional[dict[str, pd.DataFrame]]:
    print("Import country identifiers...")
    # Save each as dta for Stata import
    colnames = {"iso3.json": "iso3", "names.json": "country_name"}
    toreturn: dict[str, pd.DataFrame] = {}
    for file in input_files:
        colname = colnames[file.name]
        with file.open("r", encoding="utf-8") as infile:
            data = json.load(infile)
        data = (
            pd.DataFrame.from_dict(data, orient="index")
            .reset_index()
            .rename(columns={"index": "iso2", 0: colname})
        )
        if not return_files:
            data.to_stata(
                os.path.join(
                    output_folder, re.sub(r"\.json", ".dta", f"iso2_{file.name}")
                ),
                write_index=False,
            )
        else:
            toreturn[f"iso2_{file.name}"] = data
    if return_files:
        return toreturn
    return None


def add_countrynames(input_file: Path, countrynames: pd.DataFrame) -> None:
    """This function checks if there is a column named 'country_name' in
    the file with CountryRisk. If not, it presumes that the 'loc_cname' is
    also not present, that there is a country ISO-2 for the country of the
    CountryRisk measure and the firms' headquarter, and merges in the
    country names.

    The purpose of this all is to have a consistent set of country names.

    Args:
        input_file (Path): File with CountryRisk measures.
        countrynames (pd.DataFrame): DataFrame with two columns: the
        country ISO-2 code and the country name.
    """
    print("Checking that country names are in country risk score file...")
    try:
        scores = pd.read_stata(
            input_file,
            columns=["country_name"],
        )
    except ValueError:
        print("Adding country names...")
        scores = (
            pd.read_stata(input_file)
            .merge(
                countrynames,
                left_on="loc_iso2",
                right_on="iso2",
                how="left",
            )
            .drop(columns=["iso2"])
            .rename(columns={"country_name": "loc_cname"})
            .merge(
                countrynames,
                left_on="country_iso2",
                right_on="iso2",
                how="left",
            )
            .drop(columns=["iso2"])
        )
        scores.to_stata(input_file, convert_dates={"dateQ": "tq"}, write_index=False)
