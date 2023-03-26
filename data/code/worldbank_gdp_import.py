import numpy as np
import pandas as pd


def import_worldbank_gdp(input_file: str, output_file: str) -> None:
    print('Import World GDP...')
    # Import world gdp
    gdp_df = pd.read_csv(input_file)
    # Drop groups of countries
    todrop = [
        'Africa Eastern and Southern',
        'Africa Western and Central',
        'Arab World',
        'Caribbean small states',
        'Central Europe and the Baltics',
        'Early-demographic dividend',
        'East Asia & Pacific',
        'East Asia & Pacific (excluding high income)',
        'East Asia & Pacific (IDA & IBRD countries)',
        'Euro area',
        'Europe & Central Asia',
        'Europe & Central Asia (excluding high income)',
        'Europe & Central Asia (IDA & IBRD countries)',
        'European Union',
        'Fragile and conflict affected situations',
        'Heavily indebted poor countries (HIPC)',
        'High income',
        'IBRD only',
        'IDA & IBRD total',
        'IDA blend',
        'IDA only',
        'IDA total',
        'Late-demographic dividend',
        'Latin America & Caribbean',
        'Latin America & Caribbean (excluding high income)',
        'Latin America & the Caribbean (IDA & IBRD countries)',
        'Least developed countries: UN classification',
        'Low & middle income',
        'Low income',
        'Lower middle income',
        'Middle East & North Africa',
        'Middle East & North Africa (excluding high income)',
        'Middle East & North Africa (IDA & IBRD countries)',
        'Middle income',
        'North America',
        'Not classified',
        'OECD members',
        'Other small states',
        'Pacific island small states',
        'Post-demographic dividend',
        'Pre-demographic dividend',
        'Small states',
        'South Asia',
        'South Asia (IDA & IBRD)',
        'Sub-Saharan Africa',
        'Sub-Saharan Africa (excluding high income)',
        'Sub-Saharan Africa (IDA & IBRD countries)',
        'Upper middle income',
        'World'
    ]
    gdp_df = gdp_df[
        ~gdp_df['Country Name'].isin(todrop)
    ]
    # Rename columns
    gdp_df.rename(columns={
        'GDP (constant 2015 US$) [NY.GDP.MKTP.KD]':'gdp',
        'Time':'year',
        'Country Name':'country_name'
    }, inplace=True)
    # Drop those missing either year, name, or gdp
    gdp_df = gdp_df[
        ['year','country_name','gdp']
    ].dropna()
    # Fix string to missing
    gdp_df = gdp_df.assign(
        gdp=lambda v: v['gdp'].replace('..', np.nan).astype('float32')
    )
    # Rename countries to be consistent with our naming
    name_mapping = {
        'Egypt, Arab Rep.': 'Egypt',
        'Hong Kong SAR, China': 'Hong Kong',
        'Russian Federation': 'Russia',
        'Korea, Rep.': 'South Korea',
        'Virgin Islands (U.S.)': 'U.S. Virgin Islands',
        'Turkiye':'Turkey',
        'Iran, Islamic Rep.': 'Iran'
    }
    gdp_df = gdp_df.assign(
        country_name=lambda x: x['country_name'].apply(
            lambda v: name_mapping[v] if v in name_mapping else v
        )
    )
    # Keep only 2019
    gdp_df = gdp_df[
        gdp_df['year'] == '2019'
    ].drop(columns=['year']).set_index('country_name')
    gdp_df.index.name = 'country_name'
    # Calculat share of World GDP
    gdp_df = gdp_df.assign(
        gdp=lambda x: x['gdp'],
        share=lambda x:x['gdp'].div(x['gdp'].sum())
    )
    gdp_df.reset_index().to_csv(
        output_file, index=False
    )
    return None