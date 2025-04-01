# ecmitser

Analyze ITS sequences.

# installation

Pull the repository:

`git clone https://github.com/miferg/ecmitser.git`

Set up and activate a conda environment with snakemake. All dependencies will be installed with conda when the pipeline runs for the first time.

# usage

Store all your fasta files in a same directory. Files must end with ".fna". Minimun number of cores is 4.

Example:

`snakemake --cores 4 --use-conda --config querydir="my_files" outdir="ecmitser_out"`
