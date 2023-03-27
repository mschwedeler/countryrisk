from pathlib import Path

import pandas as pd


def import_our_sample(input_file: Path, output_file: Path) -> None:
    print('Creating firm-year file of our sample...')
    scores = pd.read_stata(
        input_file,
        columns=['gvkey','country_name','loc_iso2','loc_cname','dateQ']
    )
    our_countries = scores['country_name'].unique().tolist()
    # Keep last available country_name by gvkey-year
    scores = scores.assign(
        year=lambda v: v['dateQ'].dt.year
    ).drop(columns=['country_name'])
    collapsed = scores.dropna().sort_values(
        by=['gvkey','dateQ']
    ).groupby(
        ['gvkey','year']
    )[['loc_iso2','loc_cname']].last()
    # Create boolean variable indicating one of the 45 countries
    collapsed = collapsed.assign(
        our_countries=lambda v: v['loc_cname'].isin(our_countries)
    )
    collapsed.to_pickle(output_file)


def create_coverage_data(
    compustat_file: Path,
    iso2toname_file: Path,
    iso2toiso3_file: Path,
    oursample_file: Path,
    output_file: str
) -> None:
    print('Creating coverage data set...')
    # Load all data
    compustat = pd.read_pickle(compustat_file)
    iso2toname = pd.read_stata(iso2toname_file)
    iso2toiso3 = pd.read_stata(iso2toiso3_file)
    our_sample = pd.read_pickle(oursample_file)
    # add country name that is consistent with our data
    compustat = compustat.merge(
        iso2toname.merge(
            iso2toiso3,
            on='iso2',
            validate='1:1'
        ),
        left_on='loc',
        right_on='iso3',
        validate='m:1',
        indicator=True
    )
    compustat = compustat.rename(
        columns={
            '_merge':'_merge_iso2tonames',
            'country_name':'country_compustat'
        }
    )
    # merge with our sample
    merged = our_sample.merge(
        compustat,
        on=['gvkey','year'],
        how='outer',
        validate='1:1',
        indicator=True
    )
    merged = merged.rename(
        columns={
            '_merge':'_merge_compustat',
            'loc_cname':'country_earningscalls',
            'loc_iso2':'countryiso2_earningscalls',
        }
    )
    # Note that not all firms in our sample can be merged to Compustat;
    # in principle this should not happen, as we get the earnings calls'
    # GVKeys from Compustat. In practice this is probably due to
    # Compustat Banks, which we used for matching the earnings calls to
    # GVKeys (but which we don't use here in the Compustat data set).
    # add combined countryname
    merged = merged.assign(
        country_combined=lambda x: x['country_earningscalls'].mask(
            x['country_earningscalls'].isna(),
            x['country_compustat']
        )
    )
    # update our countries
    merged = merged.assign(
        our_countries=lambda v: v['country_earningscalls'].isin(
            our_sample[our_sample['our_countries']]['loc_cname'].unique()
        )
    )
    merged.to_pickle(output_file)
    return None