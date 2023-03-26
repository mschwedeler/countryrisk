""" Module providing helper functions to create tables and plot figures """
from typing import Union

import matplotlib.dates as mdates
import matplotlib.pyplot as plt
from matplotlib import ticker
from matplotlib import rcParamsDefault, rc
import numpy as np
import pandas as pd
import statsmodels.api as sm

# To make the figures pretty
plt.rcParams.update(rcParamsDefault)
plt.rcParams["text.latex.preamble"].join([
    r"\usepackage{soul}",  
    r"\usepackage{color}",
    r"\usepackage[sfdefault]{roboto}",
    r"\usepackage[T1]{fontenc}",
    r"\DeclareRobustCommand{\hlcyan}[1]{{\sethlcolor{cyan}\hl{#1}}}",
])
rc('text', usetex=True)



def prepare_table_1(
    coverage_file: str,
    worldscope_file: str,
    gdp_file: str
):
    # Load coverage data
    data_coverage = pd.read_pickle(coverage_file)
    # Load auxiliary data
    worldscope = import_worldscope(worldscope_file, data_coverage)
    gdp = pd.read_csv(gdp_file).set_index('country_name')
    # Collect 45 countries
    our_countries = data_coverage[
        data_coverage['our_countries']
    ]['country_earningscalls'].unique().tolist() + ['Iran']
    # Keep relevant year and countries
    subdf = data_coverage[data_coverage['year'] == 2019]
    # Calculate distribution
    share_marketcap = calculate_distribution(subdf)
    # Calculate number of firms in our sample
    nr_of_firms = count_nr_firms(data_coverage)
    nr_of_firms2019 = count_nr_firms(data_coverage, year=2019)
    # Add auxiliary data
    table_1_data = pd.concat(
        [
            share_marketcap,
            nr_of_firms,
            nr_of_firms2019,
            worldscope.rename('seg'),
            gdp['share'].rename('shareGDP') 
        ], axis=1
    )
    # Sort
    table_1_data = table_1_data.loc[our_countries]
    table_1_data = table_1_data.sort_index()
    return table_1_data


def count_nr_firms(
    input_df: pd.DataFrame,
    year: Union[bool, int]=False
) -> pd.Series:
    nr_of_firms = input_df.reset_index()[
        input_df['_merge_compustat'] != 'right_only'
    ]
    if year:
        nr_of_firms = nr_of_firms[nr_of_firms['year'] == year]
    nr_of_firms = nr_of_firms.groupby(
        ['gvkey', 'country_earningscalls']
    ).first().groupby(
        ['country_earningscalls']
    ).count()['year'].rename(f'nr_of_firms{year if year else ""}')
    return nr_of_firms


def import_worldscope(
    input_file: str,
    our_sample: pd.DataFrame
) -> pd.DataFrame:
    segment_data = pd.read_stata(input_file)
    # keep the gkvey-year pairs that are in earnings call data (overlap is 2002-2017)
    segment_data = segment_data[
        (segment_data['sale_seg_dummy'] == 1)
    ].assign(
        year=lambda x: x['year'].astype('int')
    ).merge(
        our_sample[
            our_sample['_merge_compustat'] != 'right_only'
        ].reset_index()[['gvkey','year']].assign(
            year=lambda x: x['year'].astype('int')
        ), on=['gvkey','year'], how='inner', validate='m:1', indicator=True
    )
    # remove time dimension: count link if the firm reported at least once
    segment_data = segment_data.groupby(['gvkey','country_name']).first()
    segment_data = segment_data.groupby('country_name').count()['sale_seg_dummy']
    return segment_data


def calculate_distribution(input_df: pd.DataFrame) -> pd.DataFrame:
    return input_df[
        input_df['gvkey'] != '334426'
        # take out Aramco
    ].assign(
        inTR=lambda x: x['country_earningscalls'].notna().astype('int'),
        withMC=lambda x: x['marketcap_first'].notna().astype('int'),
        inTRandMC=lambda x: x['inTR'].mul(x['marketcap_first'])
    ).groupby('country_combined').agg(
        inTR=('inTR', 'sum'),
        All=('inTR', 'count'),
        withMC=('withMC', 'sum'),
        totMC=('marketcap_first', 'sum'),
        inTRandMC=('inTRandMC', 'sum')
    ).assign(
        pctTR=lambda x: 100*x['inTR'].div(x['All']),
        pctMC=lambda x: 100*x['withMC'].div(x['All']),
        pctMCandTR=lambda x: 100*x['inTRandMC'].div(x['totMC'])
    )


def write_table_1(input_df: pd.DataFrame, output_file: str) -> None:
    with open(output_file, 'w', encoding='utf-8') as of:
        of.write(
            r'& \# of firms & \# of sales link & \% of world GDP ' +
            r'& \# of firms & \% of 2019 market\\' + '\n'
        )
        of.write(
            '& (all years) & (any year) & (2019) ' +
            '& (2019) & capitalization \\\\\\midrule\n'
        )
        for i, (country, row) in enumerate(input_df.iterrows(), start=1):
            if np.isnan(row['shareGDP']) or row['shareGDP'] == 0:
                pctTR = 'n/a'
            else:
                pctTR = f'{row["shareGDP"]*100:8.2f}\%'
            if np.isnan(row['pctMCandTR']) or row['pctMCandTR'] == 0:
                pctMCandTR = 'n/a'
            else:
                pctMCandTR = f'{row["pctMCandTR"]:8.1f}\%'
            if np.isnan(row["nr_of_firms"]) or row['nr_of_firms'] == 0:
                allfirms = '0'
            else:
                allfirms = rf'{row["nr_of_firms"]:,.0f}'
            if np.isnan(row["inTR"]) or row['inTR'] == 0:
                all2019firms = '0'
            else:
                all2019firms = rf'{row["inTR"]:,.0f}'
            of.write(
                country + '&' + allfirms + '&' + rf'{row["seg"]:,.0f} & '
                + pctTR + '&' + all2019firms + '&' + pctMCandTR + r' \\')
            
            if i <= (input_df.shape[0] - 1):
                of.write('\n')
            else:
                of.write('\\midrule\n')
        of.write(
            r'\textbf{Total}' +
            f' & {input_df["nr_of_firms"].sum():,.0f} & ' +
            f'{input_df["seg"].sum():,.0f} & ' +
            f'{input_df["shareGDP"].sum()*100:8.1f}\% & ' +
            f'{input_df["inTR"].sum():,.0f} & ' +
            f'{input_df["pctMCandTR"].mean():8.1f}\% (mean)' +
            r'\\' + '\n'
        )
    return None


def prepare_table_2(
    file: str,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    # Load
    input_df = pd.read_csv(file, low_memory=False)
    # Save ngram with maximum tfidf
    maximum_ngram = input_df[
        input_df['modified'] != 'imposed maximum'
    ].sort_values(
        by='tfidf', ascending=False
    ).head(1).iloc[0].to_dict()
    # Unigram country names
    unigram_cnames = set(
        input_df[input_df['from_geonames'] == 1]['ngram'].values
    )
    # Split ngrams
    input_df = pd.concat(
        [
            input_df,
            input_df['ngram'].str.split(' ', expand=True)
        ], axis=1
    )
    input_df = input_df.assign(
        contains_cn=(
            (input_df[0].isin(unigram_cnames)) |
            (input_df[1].isin(unigram_cnames))
        )
    )
    # Keep only ngrams with at least one country name
    input_df = input_df[
        (
            (input_df['from_geonames'] == 1) |
            ((input_df['from_geonames'] == 0) & ~(input_df['contains_cn']))
        )
    ]
    # Round tfidf so I can sort
    input_df = input_df.assign(
        tfidf=input_df['tfidf'].apply(lambda x: round(x, 3))
    )
    # Sort
    ofinterest = ['ngram','tfidf', 'count', 'modified']
    input_df = input_df[ofinterest].sort_values(
        by=['tfidf','modified','ngram'],
        ascending=[False, False, True],
        na_position='first'
    )
    input_df = input_df.reset_index(drop=True)
    # Add non-country name if it has the maximum tfidf
    if input_df.iloc[1]['modified'] == 'imposed maximum':
        addendum = input_df.iloc[0].to_dict()
        input_df = input_df.iloc[1:]
        input_df.at[1, 'ngram'] = (
            f'{input_df.iloc[0]["ngram"]}/{addendum["ngram"]}'
        )
        # For consistency, impose frequency of maximum ngram
        input_df.at[1, 'count'] = maximum_ngram['count']
    input_df.drop(columns=['modified'], inplace=True)
    # Make two parts
    part1 = input_df[0:10]
    part2 = input_df[10:20]
    return (part1, part2)


def write_table_2(
    input_data: tuple[pd.DataFrame, pd.DataFrame],
    output_file: str
) -> None:
    part1, part2 = input_data
    assert len(part1) == len(part2)
    with open(output_file, 'w+', encoding='utf-8') as ofile:
        for line_nr, (_, part1_stuff) in enumerate(part1.iterrows()):
            # Prepare data for left columns
            ngram1 = part1_stuff['ngram']
            tfidf1 = '{:,.2f}'.format(part1_stuff['tfidf'])
            count1 = '{:,}'.format(part1_stuff['count'])
            # Prepare data for right columns
            part2_stuff = part2.iloc[line_nr]
            ngram2 = part2_stuff['ngram']
            tfidf2 = '{:,.2f}'.format(part2_stuff['tfidf'])
            count2 = '{:,}'.format(part2_stuff['count'])
            # Write
            ofile.write(
                ngram1 + '&' + tfidf1 + '&' + count1
                + '&' + ngram2 + '&' + tfidf2 + '&' + count2
                + '\\\\\n'
            )
    return None


def prepare_table_6(input_file: str) -> pd.DataFrame:
    # load data and house keeping
    input_df = pd.read_stata(input_file)
    input_df.set_index(['country_iso2','loc_iso2'], inplace=True)
    # remove origin countries not in our list of 45 destinations
    input_df = input_df.reset_index()[
        input_df.reset_index()['loc_iso2'].isin(
            set(
            input_df.index.get_level_values(0).unique()
            )
        )
    ].set_index(['country_iso2', 'loc_iso2'])
    return input_df


def write_table_6(input_df: pd.DataFrame, output_file: str):
    # to move from iso2 to name
    iso2toname = input_df.reset_index()[
        ['country_iso2','country_name']
    ].set_index('country_iso2')['country_name'].to_dict()
    # to move from name to iso2
    nametoiso2 = {v:k for k,v in iso2toname.items()}
    # A) Left panel: Sorted by share in 2019 world GDP
    destinations = [
        'United States','China','Japan','Germany','United Kingdom',
        'India','France','Italy','Brazil','Canada',
        'South Korea','Australia','Russia','Spain','Mexico',
        'Indonesia','Turkey','Netherlands','Switzerland','Saudi Arabia'
    ] # sorting is manually transcribed from GDP data
    with open(output_file.replace('XXX', '_topsources'), 'w', encoding='utf-8') as ofile:
        for cat_nr, cat in enumerate(destinations):
            # restrict to 10 countries
            if cat_nr > 9:
                break
            ciso2 = nametoiso2[cat]
            sub_av = input_df.xs(ciso2, level='loc_iso2')['TransmissionRiskALL']
            sub_av = sub_av.loc[[x for x in input_df.index.get_level_values(0).unique() if not x == ciso2]]
            sub_av = sub_av.sort_values(ascending=False).head(5)
            for nr, (country, _) in enumerate(sub_av.items(), start=1):
                if nr == 1:
                    ofile.write(cat + ' & ' + iso2toname[country] + '\\\\\n')
                elif nr not in {1,5}:
                    ofile.write(' & ' + iso2toname[country] + '\\\\\n')
                elif nr == 5:
                    if cat_nr != 9:
                        ofile.write(' & ' + iso2toname[country] + '\\\\\\addlinespace\n')
                    else:
                        ofile.write(' & ' + iso2toname[country] + '\\\\\n')
    # B) Right panel: Sorted by countries with most crises
    sources_risk = [
        'China','Greece','Russia','Brazil','Turkey','United Kingdom',
        'Argentina','Egypt','Iran','Japan'
    ] # sorting is manually transcribed from crisis figure (Figure 6)
    with open(output_file.replace('XXX', '_topdestinations'), 'w', encoding='utf-8') as ofile:
        for cat_nr, cat in enumerate(sources_risk):
            ciso2 = nametoiso2[cat]
            sub_av = input_df.xs(ciso2, level='country_iso2')
            sub_av = sub_av[sub_av['nr_of_firmsALL']>25]['TransmissionRiskALL']
            #sub_av.drop(index=['LU','BM'], inplace=True)
            sub_av = sub_av.loc[[x for x in input_df.index.get_level_values(0).unique() if not x == ciso2 and x in sub_av]]
            sub_av = sub_av.sort_values(ascending=False).head(5)
            for nr, (country, _) in enumerate(sub_av.items(), start=1):
                if nr == 1:
                    ofile.write(cat + ' & ' + iso2toname[country] + '\\\\\n')
                elif nr not in {1,5}:
                    ofile.write(' & ' + iso2toname[country] + '\\\\\n')
                elif nr == 5:
                    if cat_nr != 9:
                        ofile.write(' & ' + iso2toname[country] + '\\\\\\addlinespace\n')
                    else:
                        ofile.write(' & ' + iso2toname[country] + '\\\\\n')
    return None
                 

def prepare_table_7(input_file: str) -> pd.DataFrame:
    # load and house keeping
    results = pd.read_stata(input_file)
    results.drop(columns=['country_iso2'], inplace=True)
    results.index = pd.MultiIndex.from_frame(
        results['crisis_abbrev'].str.split(
            '_', expand=True
        ).rename(columns={0:'country_iso2', 1:'crisis_nr'})
    )
    results = results.assign(
        label=results['label'].replace(np.nan, '')
    )
    results.reset_index(inplace=True)
    results = results.merge(
        results.groupby('country_iso2').count()['label'].rename('nrcrises'),
        on='country_iso2', 
        validate='m:1'
    )
    results = results[(results['label'] != '')]
    results = results[results['alpha'].notna()]
    results.sort_values(
        ['nrcrises','country_iso2','crisis_nr'],
        ascending=[False,True,True],
        inplace=True
    )
    results.set_index(['country_iso2','crisis_nr'], inplace=True)
    # manually drop non-sensical crises
    todrop = [('PL','1'),('NO','1'),('BR','1')]
    results.drop(index=todrop, inplace=True, errors='ignore')
    return results


def get_stars(pval):
    if pval <= 0.01:
        return '***'
    elif pval > 0.01 and pval <= 0.05:
        return '**'
    elif pval > 0.05 and pval <= 0.1:
        return '*'
    elif pval > 0.1:
        return ''


def write_table_7(data_df: pd.DataFrame, output_file: str) -> None:
    with open(output_file, 'w', encoding='utf-8') as of:
        for nr, (_, row) in enumerate(
                data_df.sort_values(
                    by='ypredXmedALL',
                    ascending=False
                ).iterrows()
            ):
            # a) overall impact on median country
            ypredALL_coef = '$' + '{:.2f}'.format(row['ypredXmedALL']) + '$'
            ratio = '$' + '{:.2f}'.format(row['ratio']) + '$'
            text = row['financials_different']
            #if text == 'non-financials':
            text = '$^{' + get_stars(row['alphaFIN_p']) + '}$'
            #elif text == 'financials':
            #    text = '$^{\\dagger}$'
            # b) slope
            slopeALL_coef = ('$' + '{:.2f}'.format(row['betaALL'])
                        + '^{' + get_stars(row['pvalALL']) + '} $')
            # c) r2
            r2 = '{:.3f}'.format(row['r2'])
            if nr == 33:
                lastpart = '\\\\\n'
            else:
                lastpart = '\\\\\\addlinespace\n'
            # label
            label = row['label'].replace('trade dispute','trade war')
            # write everything
            of.write(
                '\\textbf{' + row['country_name'] + '}: '
                + label + ' & ' + ' & '.join(
                    [ypredALL_coef, slopeALL_coef, r2, ratio + text]
                ) + lastpart
            )


def prepare_figure_1(coverage_file: str) -> pd.DataFrame:
    # Load data
    data_coverage = pd.read_pickle(coverage_file)
    # Prepare variables
    overtime = data_coverage.assign(
        inTR=lambda x: x['country_earningscalls'].notna().astype('int'),
        withMC=lambda x: x['marketcap_first'].notna().astype('int'),
        inTRandMC=lambda x: x['inTR'].mul(x['marketcap_first'])
    ).groupby(['year','country_combined']).agg(
        inTR=('inTR', 'sum'),
        All=('inTR', 'count'),
        withMC=('withMC', 'sum'),
        totMC=('marketcap_first', 'sum'),
        inTRandMC=('inTRandMC', 'sum')
    ).assign(
        pctTR=lambda x: 100*x['inTR'].div(x['All']),
        pctMC=lambda x: 100*x['withMC'].div(x['All']),
        pctMCandTR=lambda x: 100*x['inTRandMC'].div(x['totMC'])
    )
    # Reshape
    overtime = overtime.reset_index(level=0).loc[
        overtime.reset_index(level=0).index.isin(
            data_coverage[data_coverage['our_countries']]['country_earningscalls']
        )
    ].set_index('year', append=True)
    # Select US and non-US countries
    overtime_us = overtime.xs('United States', level=0)
    overtime_nonus = overtime.drop(
        index=['United States','Brazil','Venezuela'], level=0
    )
    # Collect relevant data
    figure_1_data = pd.concat(
        [
            (1/100)*overtime_us['pctMCandTR'].rename(
                'Share of US market cap'
            ),
            # EXCLUDE Brazil and Venezuela from average non-US
            (1/100)*overtime_nonus['pctMCandTR'].groupby(level=1).mean().rename(
                'Average share of non-US market cap'
            ),
            overtime['pctMCandTR'].apply(lambda x: x>50).groupby(level=1).sum().rename(
                'Share of countries with at least half of market cap'
            )
        ], axis=1
    )
    # Sort
    figure_1_data.index = figure_1_data.index.astype(int)
    return figure_1_data


def plot_figure_1(input_df: pd.DataFrame) -> plt.figure:
    # Prepare figure
    fig = plt.figure(figsize=(14, 8))
    ax1 = fig.add_subplot()
    ax1.margins(0) # remove space between axes and plot
    ax1.set_xlim(2003, 2020)
    ax1.set_ylim(0, 1.01)
    def form(x, pos):
        return '{:.0f}'.format(x)
    ax1.xaxis.set_major_formatter(form)
    ax1.spines['right'].set_visible(True)
    # set ticks of left y-axis
    yticks = [x/100 for x in range(0,105,20)]
    ax1.set_yticks(yticks)
    ax1.set_yticklabels(
        ['0'] + [f'{x:.0%}' for x in yticks[1:]],
        #verticalalignment='bottom'
    )
    ax1.yaxis.set_major_formatter(ticker.PercentFormatter(xmax=1, decimals=0))
    ax1.tick_params(
        axis='both', which='both', labelsize=16,
        top=False, labelbottom=True, labelright=False,
        left=True, right=False, labelleft=True
    )
    ax1.tick_params(axis='y', direction='out', pad=5)
    ax1.yaxis.set_tick_params(width=1, size=10)
    # right y-axis
    ax2 = ax1.twinx()
    ax2.margins(0) # remove space between axes and plot
    ax2.spines[:].set_visible(False)
    ax2.spines['bottom'].set_visible(True)
    ax2.spines['left'].set_visible(True)
    # set ticks of right y-axis
    ax2.set_ylim(0, 40)
    ax2.set_yticks([x for x in range(0,41,5)])
    ax2.tick_params(
        axis='both', which='both', labelsize=16,
        top=False, labelbottom=False, labelright=True,
        left=False, right=True, labelleft=False
    )
    ax2.tick_params(axis='y', direction='out', pad=5)
    ax2.yaxis.set_tick_params(width=1, size=10)
    ax2.set_ylabel(r'Number of countries', fontsize='18')

    # line plot
    ax1.plot(
        input_df.index[1:],
        input_df.iloc[1:]['Share of US market cap'],
        lw=3.5,
        color='#23001E',
        label=r'\% of US market capitalization covered',
        ls='--'
    )
    ax2.plot(
        input_df.index[1:],
        input_df.iloc[1:]['Share of countries with at least half of market cap'],
        lw=3.5,
        color='#1CCAD8',
        label='Number of countries with at least 50\% market capitalization (right y-axis)',
        ls='dotted'
    )
    ax1.plot(
        input_df.index[1:],
        input_df.iloc[1:]['Average share of non-US market cap'],
        lw=3.5,
        color='#696773',
        label=r'\% of non-US market capitalization covered (average)',
        ls='-.'
    )
    ax1.legend(ncol=1, bbox_to_anchor=(0.708, 0.05), loc='lower right',
            fontsize='18', frameon=True, framealpha=1, edgecolor='none')
    ax2.legend(ncol=1, bbox_to_anchor=(0.9, -0.01), loc='lower right',
            fontsize='18', frameon=True, framealpha=1, edgecolor='none')
    return fig


def prepare_figure_2(decomposed_fin_file: str) -> pd.DataFrame:

    # Prepare annotation
    arrow_dict = dict(
        arrowstyle='-', shrinkA=2, shrinkB=6, color='grey'
    )
    text = [
        {
            'dateQ':'2015-07-01',
            'text':'     Grexit\nReferendum',
            'coords':(20,-60),
            'arrows':arrow_dict,
            'bbox':dict(pad=0, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2010-04-01',
            'text':'First Bailout',
            'coords':(-130,10),
            'arrows':arrow_dict,
            'bbox':dict(pad=-3, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2011-10-01',
            'text':'Second Bailout',
            'coords':(-10,20),
            'arrows':arrow_dict,
            'bbox':dict(pad=0, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2008-10-01',
            'text':'Global Financial\n        Crisis',
            'coords':(-100,10),
            'arrows':arrow_dict,
            'bbox':dict(pad=-3, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2020-04-01',
            'text':'Coronavirus\n pandemic',
            'coords':(-60,35),'arrows':arrow_dict,
            'bbox':dict(pad=-3, facecolor='none', edgecolor='none')
        }
    ]
    text_df = pd.DataFrame(text)
    text_df = text_df.assign(
        dateQ=pd.to_datetime(text_df['dateQ'])
    )
    text_df.set_index('dateQ', inplace=True)

    # Load and prepare data
    wmean = pd.read_pickle(decomposed_fin_file)
    # Select subset for Greece; merge in annotation
    subset = wmean.xs(
        'GR', level=0, axis=0, drop_level=False
    )
    subset.reset_index('country_iso2', inplace=True)
    subset = pd.concat(
        [subset, text_df], axis=1, join='outer'
    )

    return subset


def prepare_figure_3(decomposed_fin_file: str) -> pd.DataFrame:
    # Prepare annotation
    arrow_dict = dict(
        arrowstyle='-', shrinkA=2, shrinkB=6, color='grey'
    )
    text = [
        {
            'dateQ':'2011-10-01',
            'text':'Flood disaster',
            'coords':(20,-20),
            'arrows':arrow_dict,
            'bbox':dict(pad=0, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2014-07-01',
            'text':'Coup d\'état\n   by miliatry',
            'coords':(30,-20),
            'arrows':arrow_dict,
            'bbox':dict(pad=0, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2008-10-01',
            'text':'Global Financial\n        Crisis',
            'coords':(-120,20),
            'arrows':arrow_dict,
            'bbox':dict(pad=-3, facecolor='none', edgecolor='none')
        },
        {
            'dateQ':'2020-04-01',
            'text':'Coronavirus\n pandemic',
            'coords':(-80,20),
            'arrows':arrow_dict,
            'bbox':dict(pad=-3, facecolor='none', edgecolor='none')
            }
    ]
    text_df = pd.DataFrame(text)
    text_df = text_df.assign(
        dateQ=pd.to_datetime(text_df['dateQ'])
    )
    text_df.set_index('dateQ', inplace=True)

    # Load and prepare data
    wmean = pd.read_pickle(decomposed_fin_file)
    subset = wmean.xs(
        'TH', level=0, axis=0, drop_level=False
    )
    subset.reset_index('country_iso2', inplace=True)
    subset = pd.concat(
        [subset, text_df], axis=1, join='outer'
    )

    return subset


def plot_figure_2_or_3(
    subset: pd.DataFrame,
    y_label: str,
) -> plt.figure:
    # Reset style
    plt.close()
    plt.rcParams.update(plt.rcParamsDefault)
    plt.style.use('fivethirtyeight')
    plt.rcParams['hatch.linewidth'] = 0.1
    plt.rcParams['axes.facecolor']='white'
    plt.rcParams['savefig.facecolor']='white'
    # Prepare plot
    fig, ax = plt.subplots(figsize=(8,4))
    # Plot gray recession bar
    ax.axvspan(
        mdates.datestr2num('2008-10-01'),
        mdates.datestr2num('2009-04-01'),
        ymin=0,
        hatch='x',
        color='whitesmoke',
        zorder=0
    )
    ax.axvspan(
        mdates.datestr2num('2020-04-01'),
        mdates.datestr2num('2020-07-01'),
        ymin=0,
        hatch='x',
        color='whitesmoke',
        zorder=0
    )
    # Plot lines and area
    ax.plot(
        subset['risk'],
        c=(73/255, 72/255, 80/255),
        label='Non-financial firms'
    )
    ax.plot(
        subset['risk_fin'],
        c=(230/255, 175/255, 46/255),
        ls='-',
        label='Financial firms'
    )
    ax.fill_between(
        subset['risk'].index,
        subset['risk'],
        subset['risk_fin'],
        facecolor=(73/255, 72/255, 80/255),
        hatch='/'
    )
    ax.fill_between(
        subset['risk'].index,
        subset['risk_fin'],
        0,
        facecolor=(230/255, 175/255, 46/255),
        hatch='\\'
    )
    # Annotate
    for x_value, row in subset.iterrows():
        txt = row['text']
        if not isinstance(txt, str):
            continue
        y_value = row['risk']
        coords = row['coords']
        ax.annotate(
            txt,
            xy=(mdates.date2num(x_value),y_value),
            xytext=coords,
            fontsize='12',
            textcoords='offset points',
            arrowprops=row['arrows'],
            bbox=row['bbox']
        )
    # Prettify
    ax.grid(None)
    for axis in ['top','right']:
        ax.spines[axis].set_color('white')
    for axis in ['bottom','left']:
        ax.spines[axis].set_linewidth(0.5)
        ax.spines[axis].set_color('black')
    ax.tick_params(direction='out', length=6, width=0.5)
    # Label
    ax.set_ylabel(y_label, fontsize=14)
    # Legend
    handles, labels = list(ax.get_legend_handles_labels())
    fig.legend(
        handles,
        labels[:2],
        fontsize=14,
        ncol=2,
        loc='lower left',
        bbox_to_anchor=(0.17,-0.15,0,0)
    )
    return fig


def prepare_figure_4(decomposed_hq_file: str) -> pd.DataFrame:
    # Prepare annotation
    arrow_dict = dict(
    arrowstyle='-', shrinkA=2, shrinkB=6, color='grey'
    )
    text = [
    {
        'dateQ':'2008-04-01',
        'text':'Bear Stearns;\nstart of GFC',
        'coords':(-70, 15),
        'arrows':arrow_dict,
        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
    },
    {
        'dateQ':'2003-04-01',
        'text':'Iraq war',
        'coords':(-20, 20),
        'arrows':arrow_dict,
        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
    },
    {
        'dateQ':'2010-04-01',
        'text':'Deepwater Horizon\n         oil spill',
        'coords':(-50, -55),
        'arrows':arrow_dict,
        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
    },
    {
        'dateQ':'2011-10-01',
        'text':'S&P downgrade of\nUS credit rating',
        'coords':(-30, 20),
        'arrows':arrow_dict,
        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
    },
    {
        'dateQ':'2013-01-01',
        'text':'Fiscal cliff',
        'coords':(15, 10),
        'arrows':arrow_dict,
        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
    },
    {
        'dateQ':'2017-01-01',
        'text':'Trump elected',
        'coords':(-20, 10),
        'arrows':arrow_dict,
        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
    },
    {
        'dateQ':'2020-04-01',
        'text':'Coronavirus\n pandemic',
        'coords':(-70,20),
        'arrows':arrow_dict,
        'bbox':dict(pad=-3, facecolor='none', edgecolor='none')
    }
    ]
    text_df = pd.DataFrame(text)
    text_df = text_df.assign(
    dateQ=pd.to_datetime(text_df['dateQ'])
    )
    text_df.set_index('dateQ', inplace=True)

    # Decompose, merge in annotation, normalize domestic mean
    input_df = pd.read_pickle(decomposed_hq_file)
    both = pd.concat(
        [input_df, text_df], axis=1, join='outer'
    )
    both = both.assign(
        risk_nhq=lambda v: v['risk_nhq'].add(
            v['risk_hq'].mean() - v['risk_nhq'].mean()
        )
    )
    return both


def plot_figure_4(
    subset: pd.DataFrame,
    y_label: str,
) -> plt.figure:
    # Reset style
    plt.close()
    plt.rcParams.update(plt.rcParamsDefault)
    plt.style.use('fivethirtyeight')
    plt.rcParams['hatch.linewidth'] = 0.1
    plt.rcParams['axes.facecolor']='white'
    plt.rcParams['savefig.facecolor']='white'
    # Prepare plot
    fig, ax = plt.subplots(figsize=(8,4))
    # Plot gray recession bar
    ax.axvspan(
        mdates.datestr2num('2008-10-01'),
        mdates.datestr2num('2009-04-01'),
        ymin=0,
        hatch='x',
        color='whitesmoke',
        zorder=0
    )
    ax.axvspan(
        mdates.datestr2num('2020-04-01'),
        mdates.datestr2num('2020-07-01'),
        ymin=0,
        hatch='x',
        color='whitesmoke',
        zorder=0
    )
    # Plot lines and area
    ax.plot(
        subset['risk_hq'],
        c='#2660a4',
        label='Domestic firms',
        ls='dashed'
    )
    ax2 = ax.twinx()
    ax.plot(
        subset['risk_nhq'] + 0.7,
        c='#eb6534',
        ls='-.',
        label='Foreign firms'
    )
    ax2.plot(
        subset['risk'],
        c='#2C6E49',
        ls='solid',
        label='All firms'
    )
    ax2.set_ylim([0, 16])
    ax2.yaxis.set_visible(False)
    ax.yaxis.set_visible(False)
    ax.set_ylim([9,21])

    # Annotate
    for x_value, row in subset.iterrows():
        txt = row['text']
        y_value = row['risk']
        coords = row['coords']
        if not isinstance(txt, str):
            continue
        ax2.annotate(
            txt,
            xy=(mdates.date2num(x_value), y_value),
            xytext=coords,
            fontsize='12',
            textcoords='offset points',
            arrowprops=row['arrows'],
            bbox=row['bbox']
        )
    # Prettify
    ax.grid(None)
    for axis in ['top','right']:
        ax.spines[axis].set_color('white')
    for axis in ['bottom','left']:
        ax.spines[axis].set_linewidth(0.5)
        ax.spines[axis].set_color('black')
    ax.tick_params(direction='out', length=6, width=0.5)
    ax2.grid(None)
    white = ['top','right','left']
    black = ['bottom']
    for axis in white:
        ax2.spines[axis].set_color('white')
    for axis in black:
        ax2.spines[axis].set_linewidth(0.5)
        ax2.spines[axis].set_color('black')
    ax2.tick_params(direction='out', length=6, width=0.5)
    # Label
    ax.set_ylabel(y_label, fontsize=14)
    # Legend
    handles, labels = list(ax.get_legend_handles_labels())
    handles2, labels2 = list(ax2.get_legend_handles_labels())
    fig.legend(
        handles2 + handles,
        labels2 + labels[:2],
        fontsize=14,
        ncol=3,
        loc='lower left',
        bbox_to_anchor=(0.12,-0.15,0,0)
    )
    return fig


def load_transmissionrisk(file: str) -> pd.DataFrame:
    # Load data plus house keeping
    data = pd.read_stata(file)
    data = data.assign(
        crisis_nr=data['crisis_nr'].astype(int).astype(str)
    )
    todrop = [
        'crisis_id','crisisfull_id','country_id','TransmissionRisk_dm',
        'hq_id','type_id','TransmissionRiskEXCLCrisis',
    ]
    data.drop(columns=todrop, inplace=True)
    data.set_index(['country_iso2','loc_iso2','crisis_nr','type'], inplace=True)
    data.rename(
        columns={
            'mTREXCL':'TransmissionRiskEXCLCrisis',
            'nr_of_firms':'nroffirms',
        },
        inplace=True
    )
    # Reshape wide the TYPE \in {ALL, FIN, NFC}
    data = data.unstack(level=3)
    cols = data.columns.to_list()
    data.columns = [''.join(x) if x[1] != 'ALL' else x[0] for x in cols]
    # Reshape wide the crisis_nr
    data = data.unstack(level=2)
    cols = data.columns.to_list()
    data.columns = [''.join(x) if x[1] != '0' else x[0] for x in cols]
    return data


def prepare_figure_7(
    transmissionrisk_file: str
) -> dict[str, pd.DataFrame]:
    # Load and prepare data
    arrow_dict = dict(arrowstyle='-', shrinkA=5, shrinkB=12, color='grey')
    crises = [
        {
            'country':'HK',
            'crisis':'1',
            'color':'#ffd166',
            'name':'Hong-Kong protests (2019q3-20q1)',
            'text':
                [
                    {
                        'loc_iso2':'SG',
                        'text':'Singapore',
                        'coords':(-10,-60),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'MY',
                        'text':'Malaysia',
                        'coords':(0,40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'CN',
                        'text':'China',
                        'coords':(45,5),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'TW',
                        'text':'Taiwan',
                        'coords':(50,-10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'PH',
                        'text':'Philippines',
                        'coords':(30,-30),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'GB',
                        'text':'United Kingdom',
                        'coords':(-10,-45),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'US',
                        'text':'United States',
                        'coords':(-20,-50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    }
                ],
            'label':r'$\widehat{\beta}_{o\to d,\tau}=1.49$ $(s.e.=0.05)$; ${R}^{2}=0.94$'
        },
        {
            'country':'JP',
            'crisis':'1',
            'color':'#26547c',
            'name':'Fukushima disaster (2011q2-11q3)',
            'text':
                [
                    {
                        'loc_iso2':'TW',
                        'text':'Taiwan',
                        'coords':(-80,-10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'KR',
                        'text':'South Korea',
                        'coords':(35,30),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'DE',
                        'text':'Germany',
                        'coords':(-100,10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'HK',
                        'text':'Hong Kong',
                        'coords':(35,0),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'SG',
                        'text':'Singapore',
                        'coords':(-30,50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'RU',
                        'text':'Russia',
                        'coords':(-80,30),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'US',
                        'text':'United States',
                        'coords':(-95,20),'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'CN',
                        'text':'China',
                        'coords':(30,10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    }
                ],
            'label':r'$\widehat{\beta}_{o\to d,\tau}=1.91$ $(s.e.=0.47)$; ${R}^{2}=0.28$'
        },
        {
            'country':'US',
            'crisis':'1',
            'color':'#06d6a0',
            'name':'Start of GFC in the United States (2008q1-08q3)',
            'text':
                [
                    {
                        'loc_iso2':'MX',
                        'text':'Mexico',
                        'coords':(50,00),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'JP',
                        'text':'Japan',
                        'coords':(-40,-60),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'CH',
                        'text':'China',
                        'coords':(-50,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'IN',
                        'text':'India',
                        'coords':(-80,-20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'GB',
                        'text':'United Kingdom',
                        'coords':(30,-50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'AT',
                        'text':'Austria',
                        'coords':(-20,-50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'FR',
                        'text':'France',
                        'coords':(30,-40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'IL',
                        'text':'Israel',
                        'coords':(40,-10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'NO',
                        'text':'Norway',
                        'coords':(-100,-10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'CA',
                        'text':'Canada',
                        'coords':(10,-40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    }
                ],
            'label':r'$\widehat{\beta}_{o\to d,\tau}=0.92$ $(s.e.=0.13)$; ${R}^{2}=0.55$'
        },
        {
            'country':'GR',
            'crisis':'1',
            'color':'#ef476f',
            'name':'Start of European debt crisis in Greece (2010q2)',
            'text':
                [
                    {
                        'loc_iso2':'BE',
                        'text':'Belgium',
                        'coords':(30,-40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'ES',
                        'text':'Spain',
                        'coords':(-50,30),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'DE',
                        'text':'Germany',
                        'coords':(-90,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'IT',
                        'text':'Italy',
                        'coords':(30,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'GB',
                        'text':'United Kingdom',
                        'coords':(45,-20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'AT',
                        'text':'Austria',
                        'coords':(-80,-20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'FR',
                        'text':'France',
                        'coords':(30,10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'US',
                        'text':'United States',
                        'coords':(30,-50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'TW',
                        'text':'Taiwan',
                        'coords':(30,-40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'DK',
                        'text':'Denmark',
                        'coords':(-80,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    }
                ],
            'label':r'$\widehat{\beta}_{o\to d,\tau}=2.80$ $(s.e.=0.34)$; ${R}^{2}=0.73$'
        },
        {
            'country':'CN','crisis':'4','color':'#ECC8AE',
            'name':'Start of Coronavirus pandemic (2020q1)',
            'text':
                [
                    {
                        'loc_iso2':'TW',
                        'text':'Taiwan',
                        'coords':(-70,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'KR',
                        'text':'South Korea',
                        'coords':(45,-15),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'DE',
                        'text':'Germany',
                        'coords':(-35,60),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'HK',
                        'text':'Hong Kong',
                        'coords':(35,0),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'SG',
                        'text':'Singapore',
                        'coords':(30,40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'RU',
                        'text':'Russia',
                        'coords':(50,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'US',
                        'text':'United States',
                        'coords':(30,-50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'JP',
                        'text':'Japan',
                        'coords':(40,10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    }
                ],
            'label':r'$\widehat{\beta}_{o\to d,\tau}=2.58$ $(s.e.=0.11)$; ${R}^{2}=0.90$'
        },
        {
            'country':'TH',
            'crisis':'1',
            'color':'#8FA6CB',
            'name':'Thai flood disaster (2011q4-12q1)',
            'text':
                [
                    {
                        'loc_iso2':'TW',
                        'text':'Taiwan',
                        'coords':(30,20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'KR',
                        'text':'South Korea',
                        'coords':(30,40),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'DE',
                        'text':'Germany',
                        'coords':(-45,50),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'HK',
                        'text':'Hong Kong',
                        'coords':(40,-10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'SG',
                        'text':'Singapore',
                        'coords':(-90,0),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'RU',
                        'text':'Russia',
                        'coords':(40,-30),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'US',
                        'text':'United States',
                        'coords':(0,-65),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'CN',
                        'text':'China',
                        'coords':(50,-20),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    },
                    {
                        'loc_iso2':'JP',
                        'text':'Japan',
                        'coords':(40,10),
                        'arrows':arrow_dict,
                        'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                    }
                ],
            'label':r'$\widehat{\beta}_{o\to d,\tau}=4.00$ $(s.e.=0.41)$; ${R}^{2}=0.68$'
        },
    ]

    transmissionrisk = load_transmissionrisk(transmissionrisk_file)

    plots = {}
    for crisis in crises:
        crisis_nr = crisis['crisis']
        country = crisis['country']
        # prepare regression data
        tokeep = [
            'TransmissionRiskEXCLCrisis',
            f'TransmissionRiskCrisis{crisis_nr}',
            f'nroffirms{crisis_nr}'
        ]
        data = transmissionrisk.loc[country][tokeep].dropna()
        y_var = pd.to_numeric(data[tokeep[1]].values)
        x_mat = sm.add_constant(data[tokeep[0]].values)
        weights = data[tokeep[2]]
        # run weighted regression
        mod_wls = sm.WLS(y_var, x_mat, weights=weights)
        res_wls = mod_wls.fit()
        label = (
            r'$\widehat{\beta}_{o\t d,\tau}=' + f'{res_wls.params[1]:.2f}' + r'$ '
            + '$(s.e.=' + f'{res_wls.bse[1]:.2f}' + r')$; ${R}^{2}='
            + f'{res_wls.rsquared:.2f}' + r'$'
        )
        # extend prediction through x=0 and max=same
        x_ext = np.vstack([np.array([1, -0.1]), x_mat, np.array([1, 100])])
        y_ext = np.hstack([np.array(np.nan), y_var, np.array(np.nan)])
        weights_ext = np.hstack([np.array(np.nan), weights, np.array(np.nan)])
        # create dataframe with results
        toplot = pd.DataFrame(
            data=np.vstack([
                y_ext,
                res_wls.predict(x_ext),
                x_ext[:,1],
                weights_ext]).T,
            index=['x=0'] + data.index.tolist() + ['x=max'],
            columns=['y','y_pred','x','weights'])
        toplot = toplot.assign(
            color=crisis['color'],
            label=label
        )
        text_df = pd.DataFrame(crisis['text'])
        if not text_df.empty:
            text_df.set_index('loc_iso2', inplace=True)
            text_df = text_df.loc[text_df.index.isin(toplot.index)]
            toplot = pd.concat([toplot, text_df], axis=1)
        toplot.name = crisis['name']
        plots[country + '_crisis' + crisis_nr] = toplot
    return plots


def prepare_figure_8(transmissionrisk_file: str) -> pd.DataFrame:
    # Prepare crisis
    arrow_dict = dict(arrowstyle='-', shrinkA=5, shrinkB=12, color='grey')
    crisis = {
        'country':'IT_NFCvsFIN',
        'crisis':'1',
        'colorFIN':'#ffa400',
        'colorNFC':'#009ffd',
        'name':'Italy: European sovereign debt crisis (2011q4)',
        'legendFIN':'Perceived by financials',
        'legendNFC':'Perceived by non-financials',
        'textFIN':
            [
                {
                    'loc_iso2':'FR',
                    'text':'France',
                    'coords':(30,20),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'NL',
                    'text':'Netherlands',
                    'coords':(-60,40),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'DE',
                    'text':'Germany',
                    'coords':(-70,40),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'AT',
                    'text':'Austria',
                    'coords':(50,-30),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'IL',
                    'text':'Israel',
                    'coords':(-80,0),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'BE',
                    'text':'Belgium',
                    'coords':(30,30),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'US',
                    'text':'United States',
                    'coords':(0,-65),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'ES',
                    'text':'Spain',
                    'coords':(50,-40),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'CH',
                    'text':'Switzerland',
                    'coords':(-100,10),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                }
            ],
        'textNFC':
            [
                {
                    'loc_iso2':'DE',
                    'text':'Germany',
                    'coords':(10,-50),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'US',
                    'text':'United States',
                    'coords':(-73,40),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'ES',
                    'text':'Spain',
                    'coords':(50,-20),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                },
                {
                    'loc_iso2':'FR',
                    'text':'France',
                    'coords':(60,10),
                    'arrows':arrow_dict,
                    'bbox':dict(pad=0, facecolor='none', edgecolor='none')
                }
            ]
    }

    # Load data
    transmissionrisk = load_transmissionrisk(transmissionrisk_file)

    country = crisis['country'].split('_')[0]
    crisis_nr = crisis['crisis']
    tokeep = [
        'TransmissionRiskEXCLCrisisNFC',
        'TransmissionRiskEXCLCrisisFIN',
        f'TransmissionRiskCrisisNFC{crisis_nr}',
        f'TransmissionRiskCrisisFIN{crisis_nr}',
        f'nroffirms{crisis_nr}'
    ]
    data = transmissionrisk.loc[country][tokeep].dropna()
    # run separate regression for NFC and FIN
    collected = []
    types_firms = ['NFC','FIN']
    for type_firms in types_firms:
        # define data and weights
        y_var = data[f'TransmissionRiskCrisis{type_firms}{crisis_nr}'].values
        x_vars = sm.add_constant(data[f'TransmissionRiskEXCLCrisis{type_firms}'].values)
        weights = data[f'nroffirms{crisis_nr}']
        # run weighted OLS
        mod_wls = sm.WLS(y_var, x_vars, weights=weights)
        res_wls = mod_wls.fit()
        # extend prediction through x=0 and max=same
        x_ext = np.vstack([np.array([1, -0.1]), x_vars, np.array([1, 100])])
        y_ext = np.hstack([np.array(np.nan), y_var, np.array(np.nan)])
        weights_ext = np.hstack([
            np.array(np.nan),
            weights,
            np.array(np.nan)
        ])
        # collect
        collected.append([
            y_ext,
            res_wls.predict(x_ext),
            x_ext[:,1],
            weights_ext
        ])
    # prepare dataframe with all relevant information
    cols = [
        (x, y) for x in types_firms for y in ['y', 'y_pred', 'x', 'weights']
    ]
    toplot = pd.DataFrame(
        data=np.vstack(collected).T,
        index=['x=0'] + data.index.tolist() + ['x=max'],
        columns=pd.MultiIndex.from_tuples(cols)
    )
    text_df = pd.concat([
        pd.DataFrame(crisis['textNFC']).set_index('loc_iso2'),
        pd.DataFrame(crisis['textFIN']).set_index('loc_iso2')], axis=1
    )
    text_df.columns = pd.MultiIndex.from_tuples(
        [
            (x, y) for x in types_firms for y in crisis['textNFC'][0].keys()
            if y != 'loc_iso2'
        ]
    )
    toplot = pd.concat([toplot, text_df], axis=1)
    colors = pd.DataFrame(
        data=np.vstack([
            [crisis['colorFIN']]*toplot.shape[0],
            [crisis['colorNFC']]*toplot.shape[0]
        ]).T,
        index=toplot.index,
        columns=pd.MultiIndex.from_tuples([('FIN','color'),('NFC','color')])
    )
    legend = pd.DataFrame(
        data=np.vstack([
            [crisis['legendFIN']]*toplot.shape[0],
            [crisis['legendNFC']]*toplot.shape[0]
        ]).T,
        index=toplot.index,
        columns=pd.MultiIndex.from_tuples([('FIN','legend'),('NFC','legend')])
    )
    toplot = pd.concat([toplot, colors, legend], axis=1)
    toplot.name = crisis['name']
    return toplot


def format_func(value, unused):
    if value == 0:
        return '0'
    if value.is_integer():
        return '{:.0f}'.format(value)
    return '{:.1f}'.format(value)


def plot_figure_7(input_df: pd.DataFrame) -> plt.figure:
    # Reset style
    plt.close()
    plt.rcParams.update(plt.rcParamsDefault)
    plt.rcParams['axes.grid'] = False
    # Set axes limits to ensure figure is square
    x_max = max(
        input_df[input_df['x']<100]['x'].dropna().max(),
        input_df[input_df['y']<100]['y'].dropna().max()
    )
    xlims = (0, x_max + x_max*0.1)
    # Define axis
    fig, ax = plt.subplots(figsize=(8,8))
    ax.set_xlim(xlims)
    ax.set_ylim(xlims)
    # Plot scatter
    ax.scatter(
        input_df[input_df['text'].isna()]['x'],
        input_df[input_df['text'].isna()]['y'],
        s=200,
        zorder=2.5,
        label=input_df.name,
        c=input_df[input_df['text'].isna()]['color'].values
    )
    ax.scatter(
        input_df[input_df['text'].notna()]['x'],
        input_df[input_df['text'].notna()]['y'],
        s=200,
        zorder=2.5,
        edgecolors='black',
        c=input_df[input_df['text'].notna()]['color'].values
    )
    # Plot predicted line
    ax.plot(
        input_df['x'],
        input_df['y_pred'],
        lw='3',
        c=input_df['color'].iloc[0],
        ls='-'
    )
    # Annotate scatter points
    for _, row in input_df.iterrows():
        txt = row['text']
        y = row['y']
        x = row['x']
        coords = row['coords']
        if not isinstance(txt, str):
            continue
        ax.annotate(
            txt,
            xy=(x,y),
            xytext=coords,
            fontsize='12',
            textcoords='offset points',
            arrowprops=row['arrows'],
            bbox=row['bbox']
        )
    # Add regression line coeff, R2
    lab = input_df.iloc[0]['label'].split('; ')
    ax.text(
        0.98,
        0.09,
        lab[0],
        verticalalignment='bottom',
        horizontalalignment='right',
        transform=ax.transAxes,
        fontsize=19
    )
    ax.text(
        0.695,
        0.03,
        lab[1],
        verticalalignment='bottom',
        horizontalalignment='right',
        transform=ax.transAxes,
        fontsize=19
    )
    # Prettify
    ax.axline([0,0], [1,1], lw='1', ls='--', c='grey')
    ax.tick_params(axis ='both', labelsize=16, length=6,
                    width=2, direction='in')
    ax.xaxis.set_major_formatter(plt.FuncFormatter(format_func))
    ax.yaxis.set_major_formatter(plt.FuncFormatter(format_func))
    plt.locator_params(axis='y', nbins=6)
    plt.locator_params(axis='x', nbins=6)
    # Label axes
    ax.set_ylabel('$TransmissionRisk_{o\\to d, t\\in {Crisis}}$', fontsize=22, labelpad=5)
    ax.set_xlabel('$\\overline{TransmissionRisk}_{o\\to d}$', fontsize=22, labelpad=5)
    plt.xticks(fontsize=22)
    plt.yticks(fontsize=22)
    return fig


def plot_figure_8(input_df: pd.DataFrame) -> plt.figure:
    # Reset style
    plt.close()
    plt.rcParams.update(plt.rcParamsDefault)
    plt.rcParams['axes.grid'] = False
    # Set axes limits to ensure figure is square
    x_max = max(
        input_df['NFC'][input_df['NFC']['x']<100]['x'].dropna().max(),
        input_df['NFC'][input_df['NFC']['y']<100]['y'].dropna().max(),
        input_df['FIN'][input_df['FIN']['x']<100]['x'].dropna().max(),
        input_df['FIN'][input_df['FIN']['y']<100]['y'].dropna().max(),

    )
    xlims = (0, x_max + x_max*0.1)
    # Define axis
    fig, ax = plt.subplots(figsize=(8,8))
    ax.set_xlim(xlims)
    ax.set_ylim(xlims)
    # Plot scatter, regression line, and annotate
    for key_df in input_df.columns.get_level_values(0).unique():
        subdf = input_df[key_df]
        if key_df == 'NFC':
            marker = 'D'
        elif key_df == 'FIN':
            marker = '^'
        ax.scatter(
            subdf[subdf['text'].isna()]['x'],
            subdf[subdf['text'].isna()]['y'],
            s=200,
            zorder=2.5,
            label=subdf['legend'].unique()[0],
            c=subdf[subdf['text'].isna()]['color'].values,
            marker=marker
        )
        ax.scatter(
            subdf[subdf['text'].notna()]['x'],
            subdf[subdf['text'].notna()]['y'],
            s=200,
            zorder=2.5,
            edgecolors='black',
            marker=marker,
            c=subdf[subdf['text'].notna()]['color'].values
        )
        ax.plot(
            subdf['x'],
            subdf['y_pred'],
            lw='3',
            c=subdf['color'].iloc[0],
            ls='-'
        )
        for _, row in subdf.iterrows():
            txt = row['text']
            y = row['y']
            x = row['x']
            coords = row['coords']
            if not isinstance(txt, str):
                continue
            ax.annotate(
                txt,
                xy=(x,y),
                xytext=coords,
                fontsize='12',
                textcoords='offset points',
                arrowprops=row['arrows'],
                bbox=row['bbox']
            )
    # Prettify
    ax.axline([0,0], [1,1], lw='1', ls='--', c='grey')
    ax.tick_params(axis ='both', labelsize=16, length=6,
                    width=2, direction='in')
    ax.xaxis.set_major_formatter(plt.FuncFormatter(format_func))
    ax.yaxis.set_major_formatter(plt.FuncFormatter(format_func))
    plt.locator_params(axis='y', nbins=6)
    plt.locator_params(axis='x', nbins=6)
    # Label axes
    ax.set_ylabel('$TransmissionRisk_{o\\to d, t\\in {Crisis}}$', fontsize=22, labelpad=5)
    ax.set_xlabel('$\\overline{TransmissionRisk}_{o\\to d}$', fontsize=22, labelpad=5)
    plt.xticks(fontsize=22)
    plt.yticks(fontsize=22)
    # Legend
    ax.legend(
        loc='lower right',
        fontsize='large',
        bbox_to_anchor=(1, 0.03),
        ncol=1,
        framealpha=1
    )
    return fig