version 1.0

task arAnalysis {
    input {
        #Necessary information
        String projectID 
        # Sample information to create csv
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
        # Pipeline parameters
        Boolean save_trimmed_fail = true
        Boolean saved_merged = true
        Int coverage = 30
        Int minlength = 500       
        String outdir = "OUT"
        # Runtime parameters
        String docker = "us-docker.pkg.dev/general-theiagen/theiagen/odhl-pipeline:dev2"
        Int memory = 32
        Int cpu = 16
        Int disk_size = 100
    }

    command <<<
        set -euo pipefail

        date | tee DATE

        # We need to create the samplesheet 
        echo "sample,fastq_1,fastq_2" > sample_sheet.csv
        read1_array=(~{sep=' ' fastq_1})
        read2_array=(~{sep=' ' fastq_2})
        sample_array=(~{sep=' ' samplenames})
        
        for i in ${!sample_array[@]}; do
            if [[ -z "${read2_array[$i]}" ]]; then
                echo "${sample_array[$i]},${read1_array[$i]}," >> sample_sheet.csv
            else
                echo "${sample_array[$i]},${read1_array[$i]},${read2_array[$i]}" >> sample_sheet.csv
            fi
        done


        # Launch nextflow pipeline with massive inputs
        nextflow run /ODHL_AR/main.nf \
            -entry arANALYSIS \
            --projectID ~{projectID} \
            --input sample_sheet.csv \
            --kraken2_db ~{kraken2_db} \
            --zipped_sketch ~{zipped_sketch} \
            --custom_mlstdb ~{custom_mlstdb} \
            --bbdukdb ~{bbdukdb} \
            --nodes ~{nodes} \
            --names ~{names} \
            --hvgamdb ~{hvgamdb} \
            --ardb ~{ardb} \
            --gamdbpf ~{gamdbpf} \
            --amrfinder_db ~{amrfinder_db} \
            --ncbi_assembly_stats ~{ncbi_assembly_stats} \
            --ncbi_db ~{ncbi_db} \
            --labResults ~{labResults} \
            --metadata_NCBI ~{metadata_NCBI} \
            --ncbi_post ~{ncbi_post} \
            --wgs_db ~{wgs_db} \
            --core_functions_script ~{core_functions_script} \
            --save_trimmed_fail ~{save_trimmed_fail} \
            --saved_merged ~{saved_merged} \
            --coverage ~{coverage} \
            --minlength ~{minlength} \
            --outdir ~{outdir}
    >>>

    output {
        String analysis_date = read_string("DATE")
        String ar_analysis_docker = docker
    }

    runtime {
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk ~{disk_size} SSD"
        maxRetries: 3
        preemptible: 0
        docker_mounts: "/var/run/docker.sock:/var/run/docker.sock"
    }
}