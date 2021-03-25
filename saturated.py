#!/usr/bin/env python3

import rawpy
import argparse

parser = argparse.ArgumentParser(description="Returns number of saturated pixels from raw image")
parser.add_argument("filename",help="File to process.")

args = parser.parse_args()

raw = rawpy.imread(args.filename)
rgb = raw.postprocess(
    gamma = (1,1),
    output_bps = 16,
    no_auto_bright = True,
    user_flip = 0,
    demosaic_algorithm = rawpy.DemosaicAlgorithm(0)
)

print((rgb == 2**16-1).any(2).sum())
