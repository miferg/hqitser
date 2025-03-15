from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq
import sys

try:
    infilename = sys.argv[1]
    outfilepref = sys.argv[2]
    
except:
    print("""
Recortar nucleotidos de cada secuencia y descartar secuencias con cierto contenido de bases sin definir.
Ejemplo:
trim_and_filter.py <infile.fna> <oufile_prefix>
    """)
    sys.exit()

def trim_and_filter_sequences(input_fasta, output_fasta, trim_start=20, trim_end=20, max_n=3):
    """
    Reads sequences from a multifasta file, trims the specified number of nucleotides
    from the beginning and end, removes any gap characters, and writes only sequences 
    with no more than max_n 'N' characters to the output file.
    
    Parameters:
    input_fasta (str): Path to the input FASTA file
    output_fasta (str): Path to the output FASTA file
    trim_start (int): Number of nucleotides to trim from the beginning
    trim_end (int): Number of nucleotides to trim from the end
    max_n (int): Maximum number of 'N' characters allowed in the trimmed sequence
    
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
        
        # Skip sequences that are too short to trim
        if len(record.seq) <= trim_start + trim_end:
            print(f"Warning: Sequence {record.id} is too short to trim ({len(record.seq)} bp). Skipping.")
            continue
        
        # Trim the sequence
        trimmed_seq = record.seq[trim_start:len(record.seq)-trim_end]
        
        # Remove gap characters (-)
        original_length = len(trimmed_seq)
        ungapped_seq = Seq(str(trimmed_seq).replace('-', ''))
        gaps_removed = original_length - len(ungapped_seq)
        
        # Count N characters
        n_count = ungapped_seq.count('N') + ungapped_seq.count('n')
        
        # Check if the trimmed sequence passes our filter based on Ns
        if n_count <= max_n:
            # Create a new SeqRecord with the trimmed and ungapped sequence
            new_description = f"{record.description} [trimmed {trim_start}bp from start, {trim_end}bp from end"
            if gaps_removed > 0:
                new_description += f", removed {gaps_removed} gaps"
            new_description += "]"
            
            trimmed_record = SeqRecord(
                ungapped_seq,
                id=record.id,
                name=record.name,
                description=new_description
            )
            filtered_records.append(trimmed_record)
            sequences_written += 1
    
    # Write all filtered sequences to the output file
    SeqIO.write(filtered_records, output_fasta, "fasta")
    
    print(f"Processed {sequences_processed} sequences")
    print(f"Wrote {sequences_written} sequences to {outfilepref} .filtered.fna")
    
    return sequences_processed, sequences_written


# MAIN

if __name__ == "__main__":
    trim_and_filter_sequences(infilename, outfilepref +'.clean.fna')