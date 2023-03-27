from pathlib import Path
from typing import Iterable

import pandas as pd


def create_marketcap(stock_data: pd.DataFrame, only_exclude_adr: bool=False) -> pd.DataFrame:
    if only_exclude_adr:
        return stock_data[
            stock_data['iid'].str.extract(r'(\d+)')[0].astype('int') < 90
        ]
    stock_data = stock_data.assign(
        datadate=lambda v: pd.to_datetime(v['datadate'])
    )
    # Keep December (and later restrict to last available data point in December)
    stock_data = stock_data[
        stock_data['datadate'].dt.month == 12
    ]
    # Exclude ADR: "If the 2-digit numeric component is 90 or above, the security is an American Depository Receipt (ADR)."
    # from https://wrds-www.wharton.upenn.edu/data-dictionary/form_metadata/comp_na_daily_all_secd_dataitems/IID/
    stock_data = stock_data[
        stock_data['iid'].str.extract(r'(\d+)')[0].astype('int') < 90
    ]
    # Aggregate all issues to company level
    marketcap_sum = stock_data.groupby(
        ['gvkey','datadate']
    )['marketcap'].sum()
    marketcap_median = stock_data.sort_values(
        by=['gvkey','iid','datadate']
    ).groupby(
        ['gvkey','datadate']
    )['marketcap'].median()
    marketcap_first = stock_data.sort_values(
        by=['gvkey','iid','datadate']
    ).groupby(
        ['gvkey','datadate']
    )[['prccd','exchange_rate_toUSD','cshoc','marketcap']].first()
    marketcap = pd.concat([
        marketcap_sum.rename('marketcap_sum'),
        marketcap_median.rename('marketcap_median'),
        marketcap_first.rename(columns={'marketcap':'marketcap_first'})
    ], axis=1)
    marketcap = marketcap.reset_index()
    # Restrict to last date of each firm in December
    marketcap = marketcap.sort_values(
        by=['gvkey','datadate'],
        na_position='first'
    ).groupby(['gvkey']).last().reset_index()
    # Potential problem: Not all iids are available on each day.
    return marketcap


def import_compustat_marketcap(input_files: Iterable[Path]) -> pd.DataFrame:
    all_files = []
    for year in range(2002, 2021):
        print(f'Importing market cap for year {year}...')
        # load
        g_marketcap = create_marketcap(
            pd.read_pickle(
                [x for x in input_files if x.match(
                    f'*/g_secd_dec{year}_marketcap.pkl'
                )][0]
            )
        )
        na_marketcap = create_marketcap(
            pd.read_pickle(
                [x for x in input_files if x.match(
                    f'*/na/na_secd_dec{year}_marketcap.pkl'
                )][0]
            )
        )
        # combine (Compustat NA takes precedence)
        g_marketcap_sub = g_marketcap[
            ~g_marketcap['gvkey'].isin(set(na_marketcap['gvkey'].values))
        ]
        marketcap = pd.concat(
            [na_marketcap, g_marketcap_sub], ignore_index=True
        ).assign(
            year=year
        )
        marketcap = marketcap[marketcap['datadate'].dt.year == year]
        all_files.append(marketcap)
    return pd.concat(all_files).drop_duplicates()


def import_compustat_company(input_files: Iterable[Path]) -> pd.DataFrame:
    # global company file
    g_company = pd.read_pickle(
        [x for x in input_files if x.match('global/g_company.pkl')][0]
    )
    # na company file
    na_company = pd.read_pickle(
        [x for x in input_files if x.match('na/na_company.pkl')][0]
    )
    # combine
    company = pd.concat(
        [
            g_company[['gvkey','conm','sic','naics','loc']],
            na_company[['gvkey','conm','sic','naics','loc']]
        ], axis=0
    ).drop_duplicates(subset=['gvkey'])
    # if row in both, value for first value (North America) is kept
    assert company['gvkey'].unique().shape[0] == company.shape[0]
    return company


def merge_compustat(
    marketcap_file: str,
    names_file: str
) -> pd.DataFrame:
    print('Merge all Compustat...')
    marketcap = pd.read_pickle(marketcap_file)
    names = pd.read_pickle(names_file)
    # merge with SIC information
    merged = marketcap.merge(
        names,
        on=['gvkey'],
        how='left',
        validate='m:1',
        indicator=True
    )
    merged = merged.rename(
        columns={'_merge':'_merge_names'}
    )
    # Drop ETFs
    merged = merged[
        ~merged['sic'].isin(['6722', '6726']) |
        ~merged['naics'].isin(['525910', '525990'])
    ]
    return merged


def import_compustat(input_files: Iterable[Path], output_folder: str) -> None:
    # Output files
    marketcap_file = f'{output_folder}/compustat_marketcap.pkl'
    company_file = f'{output_folder}/compustat_company.pkl'
    compustat_file = f'{output_folder}/compustat_merged.pkl'
    # Import Compustat market capitalization
    marketcap = import_compustat_marketcap(input_files)
    marketcap.to_pickle(marketcap_file)
    # Import Compustat SIC sectors
    names = import_compustat_company(input_files)
    names.to_pickle(company_file)
    # Merge (and remove ETFs)
    merged = merge_compustat(marketcap_file, company_file)
    merged.to_pickle(compustat_file)