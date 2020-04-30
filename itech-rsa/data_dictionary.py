#!/bin/env python

from __future__ import print_function
import argparse
import csv
import pandas as pd
from collections import defaultdict
import re
import os

import sys

if len(sys.argv) < 2:
    print('You need to specify at least one form name for conversion')
    sys.exit(1)

xlsfiles = sys.argv[1:]
xlsx_path_prefix = os.getcwd() + '/forms/app/'
data_dict_path_prefix = os.getcwd() + '/data_dictionary/'

def check_xlsx_paths(xlsfiles, path_prefix=xlsx_path_prefix):
    result = []
    for xlsfile in xlsfiles:
        filename, extension = os.path.splitext(xlsfile)
        if extension and extension != '.xlsx':
            print('Bad extension for {}. We only accept .xlsx files'.format(filename + extension))
            sys.exit(1)
        if not extension:
            xlsfile = filename + '.xlsx'

        if not os.path.isfile(path_prefix + xlsfile):
            print('{} is missing from {}'.format(xlsfile, path_prefix))
            sys.exit(1)

        result.append(path_prefix + xlsfile)
    return result

def ensure_path(path):
    if not os.path.isdir(path):
        try:
            os.makedirs(path)
            return True
        except Exception as e:
            print(e)
    return os.path.isdir(path)


if not ensure_path(data_dict_path_prefix):
    print('Could not find/create the data dictionary folder: {}'.format(data_dict_path_prefix))
    sys.exit(1)

for target_file in check_xlsx_paths(xlsfiles):
    choices_dict = defaultdict(list)

    choices = pd.read_excel(target_file, sheet_name='choices', dtype=object)
    for idx, row in choices.iterrows():
        choices_dict[row['list_name']].append(row['label'])

    survey = pd.read_excel(target_file, sheet_name='survey',dtype=object)
    survey.fillna('', inplace=True)

    with open(data_dict_path_prefix + os.path.splitext(os.path.basename(target_file))[0] + '.csv', 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=['name','label','options','relevant_when'])
        writer.writeheader()
        for idx, row in survey.iterrows():
            has_options = False
            if re.search(r'begin|note|end', row['type']):
                continue

            if re.search('select', row['type']):
                has_options = True

            question = {}
            question['name'] = row['name']
            question['label'] = re.sub('nan','', str(row['label']))

            if has_options:
                question['options'] = ",".join(map(str,choices_dict[row['type'].split()[-1]]))
            question['relevant_when'] = row['relevant']

            writer.writerow(question)
    print("Created data dictonary for: {}".format(os.path.basename(target_file)))
