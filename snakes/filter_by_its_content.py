import sys
import pandas as pd

try:
    infilename = sys.argv[1]
    outfilepref = sys.argv[2]
    
except:
    print("""
Tomar una tabla de salida de ITSx y conservar secuencias en las que se
ha detectado el ITS1 e ITS2.
Ejemplo:
filter_by_its_content.py <infile.fna> <oufile_prefix>
    """)
    sys.exit()



# MAIN

if __name__ == "__main__":
    trim_and_filter_sequences(infilename, outfilepref +'.clean.fna')