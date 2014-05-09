#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ft=python ts=4 sw=4 sts=4 et fenc=utf-8
# Original author: "Eivind Magnus Hvidevold" <hvidevold@gmail.com>
# License: GNU GPLv3 at http://www.gnu.org/licenses/gpl.html

'''
'''

import os
import sys
import re
import json

def main():
    'entry point'

if __name__ == '__main__':
    fname = sys.argv[1]

    head = '0 results '
    data = file(fname).readlines()
    for line in data:
        if line.startswith(head):
            jsondata = line[len(head):]
            #print jsondata
    results = json.loads(jsondata)
    print results['rows'], results['cols']
    for row in results['mat']:
        for col in row:
            print col,
        print
    main()

