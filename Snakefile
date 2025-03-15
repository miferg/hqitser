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
        str(outdir) + "/ecmitser.wits.tsv"

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

rule filter_by_its_content:
    input:
        str(outdir) + "/itsx_out/itsx_out.positions.txt"
    output:
        str(outdir) + "/ecmitser.wits.tsv" # with ITS
    shell:
        """
        awk -F"\t" '{{print $1"\t"$4"\t"$6}}' {input} | grep -v "Not found" > {output}
        """
        # braces were escaped beause are not in the context of snakemake

# END