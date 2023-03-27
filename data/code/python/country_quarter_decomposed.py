from pathlib import Path

import pandas as pd

def create_decomposed_country_quarter(
    scores_file: Path, output_file: str
) -> None:
    print('Create decomposed country-quarter data...')
    # Load firm-country-quarter data
    scores = pd.read_stata(
        scores_file,
        columns=['gvkey','country_iso2','sic','dateQ', 'risk', 'loc_iso2']
    )
    # Standard deviation for later
    risk_sd = scores[(scores['dateQ'].dt.year < 2020)].groupby(
        ['country_iso2','dateQ']
    )['risk'].mean().std()
    groupby = ['country_iso2','dateQ']
    ### A) Decompose by financial vs non-financial
    # Define group
    scores = scores.assign(
        group=(scores['sic'].str[:1] == '6').astype(int)
    )
    # Count (inverse of) share of observations for each group
    obs = scores.groupby(
        groupby
    )['risk'].count().rename('total_obs')
    obs_gr = scores.groupby(
        groupby + ['group']
    )['risk'].count().rename('gr_obs')
    inverse_share = obs_gr.div(obs)
    # Get weighted mean
    wmean = inverse_share.mul(
        scores.groupby(groupby + ['group'])['risk'].mean()
    )
    wmean = wmean.unstack('group')
    wmean.columns = [
        'risk' + '_' + {1:'fin', 0:'nfin'}[x]
        for x in wmean.columns.to_list()
    ]
    to_sum = ['fin','nfin']
    wmean = wmean.assign(
        risk=lambda v: v['risk_' + to_sum[0]].add(
            v['risk_' + to_sum[1]]
        )
    )
    # Divide by sd of risk
    wmean = wmean.div(risk_sd)
    wmean.to_pickle(output_file.replace('XXX','fin'))
    ### B) Decompose by hq
    decomposed = pd.concat(
        [
            scores.assign(
                hq=(
                    scores['country_iso2'] == scores['loc_iso2']
                ).astype(int)
            ).groupby(
                ['country_iso2','dateQ','hq']
            )['risk'].mean().unstack(
                level=2
            ).loc['US'].rename(
                columns={0:'risk_nhq',1:'risk_hq'}
            ),
            scores.groupby(
                ['country_iso2','dateQ']
            )['risk'].mean().loc['US']
        ], axis=1
    )
    decomposed = decomposed.div(decomposed['risk'].std())
    decomposed.to_pickle(output_file.replace('XXX','hq'))
    return None