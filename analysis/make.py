import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
from typing import Dict, Iterable, Union

import yaml

import code.python.helpers as h

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
OUTPUT_FOLDER = ROOT.joinpath('analysis/output')


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
        if isinstance(path_str, str):
            if not os.path.exists(path_str):
                raise FileNotFoundError(
                    f'File {file_name}: {path_str} is required but not found. Make sure it has been generated.'
                )
        elif isinstance(path_str, Iterable):
            for file in path_str:
                if not os.path.exists(file):
                    raise FileNotFoundError(
                        f'File {file} is required but not found. Make sure it has been generated.'
                    )
        else:
            raise NotImplementedError
        

def prepend_files(
        input_dict: Dict[str, Union[str, Iterable[str]]],
        to_prepend: Path,
        raw_data: Path
) -> Dict[str, Union[Path, Iterable[str]]]:
    data_files = {}
    for file_name, files in input_dict.items():
        if file_name == 'TFIDF_FILES':
            data_files[file_name] = [
                raw_data.joinpath(x).as_posix() for x in files
            ]
            continue
        if isinstance(files, str):
            data_files[file_name] = to_prepend.joinpath(files).as_posix()
        elif isinstance(files, list):
            data_files[file_name] = [
                to_prepend.joinpath(x).as_posix() for x in files
            ]
        elif isinstance(files, dict):
            data_files[file_name] = {
                key: to_prepend.joinpath(value).as_posix() for key, value in files.items()
            }
        else:
            raise NotImplementedError(f'Not implemented: {type(files)}')
    return data_files

if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        description='Creates all tables and figures.'
    )
    parser.add_argument('--clean_slate', action='store_true', default=True)
    parser.add_argument('--also_compile', action='store_true', default=False)
    args = parser.parse_args()

    # load config yaml
    with CONFIG_FILE.open('r', encoding='utf-8') as stream:
        try:
            config_dict = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
        # add absolute path to files
        final_data = prepend_files(config_dict['final_data'], DATA, RAW_DATA)
    
    # Replace existing output folder with empty folder
    if args.clean_slate:
        print('Deleting existing output...')
        if OUTPUT_FOLDER.joinpath('figures').exists():
            shutil.rmtree(OUTPUT_FOLDER.joinpath('figures'), ignore_errors=True)
        if OUTPUT_FOLDER.joinpath('tables').exists():
            shutil.rmtree(OUTPUT_FOLDER.joinpath('tables'), ignore_errors=True)
    if not OUTPUT_FOLDER.joinpath('figures').exists():
        OUTPUT_FOLDER.joinpath('figures').mkdir()
    if not OUTPUT_FOLDER.joinpath('tables').exists():
        OUTPUT_FOLDER.joinpath('tables').mkdir()

    # Check that required files exist
    check_files_exist(final_data)
    print('All final data files exist')
    
    # Figure 1
    print('Figure 1...')
    # Prepare figure
    figure_1_data = h.prepare_figure_1(final_data['COVERAGE_FILE'])
    # Plot and save
    figure_1 = h.plot_figure_1(figure_1_data)
    figure_1.savefig(
        os.path.join(OUTPUT_FOLDER, 'figures/Figure1_coverage.eps'),
        format='eps',
        bbox_inches='tight'
    )

    # Figure 2
    print('Figure 2...')
    # Prepare figure
    figure_2_data = h.prepare_figure_2(final_data['DECOMPOSED_FIN_FILE'])
    # Plot and save
    figure_2 = h.plot_figure_2_or_3(
        figure_2_data,
        y_label='Greek CountryRisk$_{t}$ (std.)'
    )
    figure_2.savefig(
        os.path.join(OUTPUT_FOLDER, 'figures/Figure2_greece.eps'),
        bbox_inches='tight',
        pad_inches=0,
        format='eps'
    )

    # Figure 3
    print('Figure 3...')
    # Prepare figure
    figure_3_data = h.prepare_figure_3(final_data['DECOMPOSED_FIN_FILE'])
    # Plot and save
    figure_3 = h.plot_figure_2_or_3(
        figure_3_data,
        y_label='Thai CountryRisk$_{t}$ (std.)'
    )
    figure_3.savefig(
        os.path.join(OUTPUT_FOLDER, 'figures/Figure3_thailand.eps'),
        bbox_inches='tight',
        pad_inches=0,
        format='eps'
    )

    # Figure 4
    print('Figure 4...')
    # Prepare figure
    figure_4_data = h.prepare_figure_4(final_data['DECOMPOSED_HQ_FILE'])
    # Plot and save
    figure_4 = h.plot_figure_4(
        figure_4_data,
        y_label='US CountryRisk$_{t}$ (std.)'
    )
    figure_4.savefig(
        os.path.join(OUTPUT_FOLDER, 'figures/Figure4_unitedstates.eps'),
        bbox_inches='tight',
        pad_inches=0,
        format='eps'
    )

    # Figure 5
    print('Figure 5...')
    # Plot and save
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/figure5.do\"',
            final_data['COUNTRYQUARTER_FILE'],
            f'{OUTPUT_FOLDER}/figures/Figure5_risk_timeFE.eps'
        ],
        check=False
    )

    # Figure 6
    print('Figure 6...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/figure6.do\"',
            final_data['COUNTRYQUARTER_FILE'],
            f'{OUTPUT_FOLDER}/figures/Figure6_crises_XX.eps',
            f'{DATA}'
        ],
        check=False
    )

    # Figure 7
    print('Figure 7...')
    # Prepare figure
    figure_7_data = h.prepare_figure_7(final_data['TRANSMISSIONRISK_TAU_FILE'])
    # Plot and save
    for crisis, toplot in figure_7_data.items():
        # Plot and save
        figurename = f'{OUTPUT_FOLDER}/figures/Figure7_transmissionrisk_scatter_{crisis}.eps'
        h.plot_figure_7(toplot).savefig(
            figurename, bbox_inches='tight', pad_inches=0, format='eps'
        )

    # Figure 8
    print('Figure 8...')
    # Prepare figure
    figure_8_data = h.prepare_figure_8(final_data['TRANSMISSIONRISK_TAU_FILE'])
    # Plot and save
    figure_8_filename = f'{OUTPUT_FOLDER}/figures/Figure8_transmissionrisk_scatter_IT_NFCvsFIN_crisis1.eps'
    h.plot_figure_8(figure_8_data).savefig(
        figure_8_filename, bbox_inches='tight', pad_inches=0, format='eps'
    )

    # Table 1
    print('Table 1...')
    # Prepare data
    table_1_data = h.prepare_table_1(
        final_data['COVERAGE_FILE'],
        final_data['WORLDSCOPE_FILE'],
        final_data['GDP_FILE']
    )
    # Write table
    h.write_table_1(
        table_1_data,
        f'{OUTPUT_FOLDER}/tables/Table1_coverage.tex'
    )

    # Table 2
    print('Table 2...')
    for file in final_data['TFIDF_FILES']:
        # prepare data
        table_2_data = h.prepare_table_2(file)
        # write data
        h.write_table_2(
            table_2_data,
            f"{OUTPUT_FOLDER}/tables/Table2_top20ngrams_{re.search(r'/([a-z][a-z])_', file)[1]}.tex"
        )

    # Table 3
    print('Table 3...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table3.do\"',
            final_data['FIRMCOUNTRY_FILE'],
            f'{OUTPUT_FOLDER}/tables/Table3_firmcountry_pooledreg.tex',
        ],
        check=False
    )

    # Table 4
    print('Table 4...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table4.do\"',
            f'{DATA}',
            f'{OUTPUT_FOLDER}',
        ],
        check=False
    )

    # Table 5
    print('Table 5...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table5.do\"',
            f'{DATA}',
            f'{OUTPUT_FOLDER}',
        ],
        check=False
    )

    # Table 6
    print('Table 6...')
    # Prepare data
    table_6_data = h.prepare_table_6(final_data['TRANSMISSIONRISK_FILE'])
    # Write table
    h.write_table_6(
        table_6_data,
        f'{OUTPUT_FOLDER}/tables/Table6_transmissionriskXXX.tex'
    )

    # Table 7
    print('Table 7...')
    # Prepare data
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table7_prepare.do\"',
            final_data['TRANSMISSIONRISK_TAU_FILE'],
            final_data['TRANSMISSIONRISK_FIRM_TAU_FILE'],
            f'{OUTPUT_FOLDER}/tables/table7_data.dta',
        ],
        check=False
    )
    # Read and write table
    table_7_data = h.prepare_table_7(f'{OUTPUT_FOLDER}/tables/table7_data.dta')
    h.write_table_7(
        table_7_data,
        f'{OUTPUT_FOLDER}/tables/Table7_transmissionrisk_overview.tex'
    )

    # Table 8
    print('Table 8...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table8.do\"',
            final_data['COUNTRYQUARTER_FILE'],
            f'{OUTPUT_FOLDER}',
        ],
        check=False
    )

    # Table 9
    print('Table 9...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table9.do\"',
            final_data['COUNTRYQUARTER_FILE'],
            f'{OUTPUT_FOLDER}',
        ],
        check=False
    )

    # Table 10
    print('Table 10...')
    subprocess.run(
        [
            config_dict['general']['stata_exec'],
            '-q',
            '-b',
            'do',
            f'\"{ROOT}/analysis/code/stata/table10.do\"',
            final_data['COUNTRYQUARTER_FILE'],
            f'{OUTPUT_FOLDER}',
        ],
        check=False
    )

    # Compile tex file
    if args.also_compile:
        print('Compiling tex file...')
        subprocess.run(
            [
                'pdflatex',
                '-synctex=1',
                '-interaction=nonstopmode',
                '-file-line-error',
                '-recorder'
            ],
            check=False
        )