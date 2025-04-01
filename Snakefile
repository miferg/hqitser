import subprocess
import glob
import os
import pathlib

querydir = Path(config["querydir"])
outdir = Path(config["outdir"])
LOCBASE = [x.split('.fna')[0] for x in os.listdir(querydir) if x.endswith('.fna')]

rule all:
    input:
        str(outdir) + "/merged/ecmits.merged.fna",
        str(outdir) + "/clean/ecmits.clean.fna",
        str(outdir) + "/clean/ecmits.derep.fna",
        str(outdir) + "/itsx_out/itsx_out.positions.txt",
        str(outdir) + "/ecmitser.wits.tsv",
        str(outdir) + "/itsx_out/ecmitser.wits.fna",
        str(outdir) + "/annot/sh_general_release_dynamic_s_19.02.2025.fasta",
        str(outdir) + "/annot/unite.ndb",
        expand(str(outdir) + "/annot/ac_slice_{slice_num}.fasta", slice_num=range(1, 11)),
        str(outdir) + "/annot/ecmitser.btout",
        str(outdir) + "/ecmitser.fna"

rule merge_fna_files:
    input:
        expand(str(querydir) + "/{lbase}.fna", lbase=LOCBASE)
    output:
        str(outdir) + "/merged/ecmits.merged.fna"
    params:
        str(querydir) +"/*.fna"
    shell:
        """
        cat {params} > {output}
        """

rule clean_sequences:
    conda:
        "snakes/ecmitser_pylibs.yaml"
    input:
        str(outdir) + "/merged/ecmits.merged.fna"
    output:
        str(outdir) + "/clean/ecmits.clean.fna"
    params:
        str(outdir) + "/clean/ecmits"
    shell:
        """
        python snakes/trim_and_filter.py {input} {params}
        """

rule dereplicate:
    conda:
        "snakes/vsearch.yaml"
    input:
        str(outdir) + "/clean/ecmits.clean.fna"
    output:
        str(outdir) + "/clean/ecmits.derep.fna",
        str(outdir) + "/clean/ecmits.derep.uc"
    params:
        str(outdir) + "/clean/ecmits"
    shell:
        """
        vsearch --derep_fulllength {input} --output {output[0]} --uc {output[1]}
        """

rule search_itsx:
    conda:
        "snakes/itsx.yaml"
    input:
        str(outdir) + "/clean/ecmits.derep.fna"
    output:
        str(outdir) + "/itsx_out/itsx_out.positions.txt"
    params:
        str(outdir) + "/itsx_out/itsx_out"
    shell:
        """
        ITSx -i {input} -o {params} --cpu 4 -t F
        """

rule filter_itsx_table:
    input:
        str(outdir) + "/itsx_out/itsx_out.positions.txt"
    output:
        str(outdir) + "/ecmitser.wits.tsv" # with ITS
    shell:
        """
        awk -F"\t" '{{print $1"\t"$4"\t"$6}}' {input} | grep -v "Not found" > {output}
        """

rule  filter_by_its_content:
    conda:
        "snakes/ecmitser_pylibs.yaml"
    input:
        str(outdir) + "/clean/ecmits.derep.fna",
        str(outdir) + "/ecmitser.wits.tsv"
    output:
        str(outdir) + "/itsx_out/ecmitser.wits.fna"
    params:
        str(outdir) + "/itsx_out/ecmitser"
    shell:
        """
        python snakes/filter_by_its_content.py {input[0]} {input[1]} {params}
        """

rule get_annot_db:
   # download reference database
    output:
        temp(str(outdir) + "/annot/1c8647cd-31f2-44ff-8c77-dbd470e6154c.tgz")
    params:
        str(outdir) +'/annot'
    shell:
        """
        wget --directory-prefix={params} https://s3.hpc.ut.ee/plutof-public/original/1c8647cd-31f2-44ff-8c77-dbd470e6154c.tgz
        """

rule unzip_annot_db:
   # decompress reference database
    input:
        str(outdir) + "/annot/1c8647cd-31f2-44ff-8c77-dbd470e6154c.tgz"
    output:
        str(outdir) + "/annot/sh_general_release_dynamic_s_19.02.2025.fasta"
    params:
        str(outdir) +'/annot'
    shell:
        """
        tar xzf {input} --directory {params}
        """

rule build_bl_db:
   # build bast db
    conda:
        "snakes/blast.yaml"
    input:
        str(outdir) + "/annot/sh_general_release_dynamic_s_19.02.2025.fasta"
    output:
        str(outdir) + "/annot/unite.ndb"
    params:
        str(outdir) +'/annot'
    shell:
        """
        makeblastdb -in {input} -dbtype 'nucl' -out {params}/unite
        """

rule split_fasta:
    # split query fasta to speed up the blast search
    input:
        str(outdir) + "/itsx_out/ecmitser.wits.fna"
    output:
        expand(str(outdir) + "/annot/ac_slice_{slice_num}.fasta", slice_num=range(1, 11))
    params:
        str(outdir) + "/annot"
    shell:
        """
        python3 snakes/slice_fasta.py {input} {params}/ac
        """

rule blast:
    # run blast searches
    conda:
        "snakes/blast.yaml"
    input:
        str(outdir) + "/annot/ac_slice_{slice_num}.fasta",
        str(outdir) + "/annot/unite.ndb"
    output:
        str(outdir) + "/annot/ac_slice_{slice_num}.btout"
    params:
        db=str(outdir) + "/annot/unite"
    shell:
        """
        blastn -db {params.db} -query {input[0]} -outfmt 6 -max_target_seqs 10 -evalue 1e-5 -out {output}
        """

rule merge_blast:
    # merge blast output into single table
    input:
        expand(str(outdir) + "/annot/ac_slice_{slice_num}.btout", slice_num=range(1, 11))
    output:
        str(outdir) + "/annot/ecmitser.btout"
    params:
        str(outdir) + "/annot"
    shell:
        """
        cat {params}/ac_slice_*.btout > {output}
        """

rule  orient_sequences:
    conda:
        "snakes/vsearch.yaml"
    input:
        str(outdir) + "/itsx_out/ecmitser.wits.fna",
        str(outdir) + "/annot/sh_general_release_dynamic_s_19.02.2025.fasta"
    output:
        str(outdir) + "/ecmitser.fna"
    shell:
        """
        vsearch --orient {input[0]} --db {input[1]} --fastaout {output}
        """

# END