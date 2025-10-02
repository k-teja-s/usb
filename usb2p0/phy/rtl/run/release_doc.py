#py -m pip install openpyxl - for install using cmd
#this script will convert md 2 pdf,
#then merge all the pdfs and creates a release doc in pdf at 
#then deletes all the pdfs generated
#useage:py release_doc.py usb2p0_phy_impl_specs_r0p1

import os
import sys

os.system("py md2pdf.py all")
os.system("py merge.py "+str(sys.argv[1]))

folder_path = '../../doc/impl/'

if not os.path.exists(folder_path):
    print(f"Error: Folder '{folder_path}' does not exist.")
else:
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        try:
            if os.path.isfile(file_path) and filename.lower().endswith('.pdf'):
                os.remove(file_path)
                print(f"Deleted: {file_path}")
        except Exception as e:
            print(f"Error deleting {file_path}: {e}")