#!/usr/bin/env python3

import rawpy
import argparse

parser = argparse.ArgumentParser(description="Returns number of saturated pixels from raw image")
parser.add_argument("filename",help="File to process.")

args = parser.parse_args()

raw = rawpy.imread(args.filename)
print(np.sum(raw.raw_image_visible > raw.white_level/2))
