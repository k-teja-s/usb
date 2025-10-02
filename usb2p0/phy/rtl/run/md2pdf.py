#this script converts all *.md files to *.pdfs
#useage: py md2pdf.py line_det_line_drv - this will convert only that perticular file to pdf
#        py md2pdf.py all - this will convert all required files to make a release doc

import os
import sys

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
             
if str(sys.argv[1]) == "all":
    for file in files_list:
        os.system("pandoc ../../doc/impl/"+file+".md -o ../../doc/impl/"+file+".pdf --pdf-engine=wkhtmltopdf")
else:
    os.system("pandoc ../../doc/impl/"+str(sys.argv[1])+".md -o ../../doc/impl/"+str(sys.argv[1])+".pdf --pdf-engine=wkhtmltopdf")