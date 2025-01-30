version 1.0

import "../tasks/task_ar_analysis.wdl" as ar_analysis

workflow ar_analysis_wf {
    meta {
        description: "A WDL wrapper around the AR Analysis nextflow pipeline from ODHL."
    }
    input {
        # Project information
        String projectID
        # Sample information
        Array[String] samplenames
        Array[File] fastq_1
        Array[File] fastq_2
        # Database files
        File kraken2_db
        File zipped_sketch
        File custom_mlstdb
        File bbdukdb
        File nodes
        File names
        File hvgamdb
        File ardb
        File gamdbpf
        File amrfinder_db
        File ncbi_assembly_stats
        File ncbi_db
        File labResults
        File metadata_NCBI
        File ncbi_post
        File wgs_db
        File core_functions_script
        # Optional pipeline parameters
        Boolean? save_trimmed_fail
        Boolean? saved_merged
        Int? coverage
        Int? minlength
    }

    call ar_analysis.arAnalysis {
        input:
            projectID = projectID,
            samplenames = samplenames,
            fastq_1 = fastq_1,
            fastq_2 = fastq_2,
            kraken2_db = kraken2_db,
            zipped_sketch = zipped_sketch,
            custom_mlstdb = custom_mlstdb,
            bbdukdb = bbdukdb,
            nodes = nodes,
            names = names,
            hvgamdb = hvgamdb,
            ardb = ardb,
            gamdbpf = gamdbpf,
            amrfinder_db = amrfinder_db,
            ncbi_assembly_stats = ncbi_assembly_stats,
            ncbi_db = ncbi_db,
            labResults = labResults,
            metadata_NCBI = metadata_NCBI,
            ncbi_post = ncbi_post,
            wgs_db = wgs_db,
            core_functions_script = core_functions_script,
            save_trimmed_fail = select_first([save_trimmed_fail, true]),
            saved_merged = select_first([saved_merged, true]),
            coverage = coverage,
            minlength = minlength,
    }

    output {
        String ar_analysis_docker = arAnalysis.ar_analysis_docker
        String analysis_date = arAnalysis.analysis_date
    }
}