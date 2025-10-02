#this script merges all *.pdfs in to 1 pdf (merging should be ordered base, not name based) (should take an argument for output pdf file name)
#useage: py merge.py usb2p0_phy_impl_specs_v0p1

import os
import sys
from PyPDF2 import PdfMerger

files_list = [
                "tittle",
                "index",
                "lof",
                "lot",
                "release_note",
                "usb_2p0_phy_layer",
                "parameters",
                "enums",
                "defines",
                "features",
                "limitations",
                "file_structure",
                "registers",
                "line_det_line_drv",
                "possible_testcases"
             ]
             
merger = PdfMerger()
for file in files_list:
    merger.append("../../doc/impl/"+file+".pdf")
merger.write("../../doc/"+str(sys.argv[1])+".pdf")
merger.close()