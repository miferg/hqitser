import sys
import pandas as pd
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

try:
    fnafilename = sys.argv[1]
    itsxfilename = sys.argv[2]
    outfilepref = sys.argv[3]
    
except:
    print("""
Tomar un archivo fasta y una tabla de salida de ITSx y conservar secuencias en las que se
ha detectado el ITS1 e ITS2.
Ejemplo:
filter_by_its_content.py <infile.fna> <itsx.wits.tsv> <oufile_prefix>
    """)
    sys.exit()


def filter_sequences(input_fasta, secnames, output_fasta):
    """
    Reads sequences from a multifasta file and appends to the output file
    those present in the itsx output table.
    
    Parameters:
    input_fasta (str): Path to the input FASTA file
    secnames (list): List of sequence headers to keep
    output_fasta (str): Path to the output FASTA file
    
    Returns:
    tuple: (sequences_processed, sequences_written)
    """
    sequences_processed = 0
    sequences_written = 0
    
    # Create a list to store filtered sequences
    filtered_records = []
    
    # Process each sequence in the input file
    for record in SeqIO.parse(input_fasta, "fasta"):
        sequences_processed += 1
        
        if record.id in secnames:
            record.name = record.id
            filtered_records.append(record)
            sequences_written += 1
    
    # Write all filtered sequences to the output file
    SeqIO.write(filtered_records, output_fasta, "fasta")
    
    print(f"Processed {sequences_processed} sequences")
    print(f"Wrote {sequences_written} sequences to {outfilepref}.wits.fna")
    
    return sequences_processed, sequences_written


# MAIN

if __name__ == "__main__":
    
    itsx = pd.read_csv(itsxfilename, sep='\t', header=None)
    
    secnames = list(itsx[0])
    
    filter_sequences(fnafilename, secnames, outfilepref +'.wits.fna')