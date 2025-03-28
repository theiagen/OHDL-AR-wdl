version 1.0

task arAnalysis {
    input {
        #Necessary information
        String projectID 
        # Sample information to create csv
        String samplename
        File fastq_1
        File fastq_2
        # Database files
        File kraken2_db = "gs://theiagen-public-files/terra/theiaprok-files/k2_standard_8gb_20210517.tar.gz"
        File zipped_sketch = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/REFSEQ_20240124_Bacteria_complete.msh.gz"
        File custom_mlstdb = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/mlst_db_20240124.tar.gz"
        File bbdukdb = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/phiX.fasta"
        File nodes = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/nodes_20240129.dmp.gz"
        File names = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/names_20240129.dmp.gz"
        File hvgamdb = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/HyperVirulence_20220414.fasta"
        File ardb = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/ResGANNCBI_20240131_srst2.fasta"
        File gamdbpf = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/PF-Replicons_20240124.fasta"
        File amrfinder_db = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/amrfinderdb_v3.12_20240131.1.tar.gz"
        File ncbi_assembly_stats = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/NCBI_Assembly_stats_20240124.txt"
        File ncbi_db = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/ncbiDB/srr_db_example.csv"
        File labResults = "gs://theiagen-public-files/terra/ODHL_AR/test/labResults_test.csv"
        File metadata_NCBI = "gs://theiagen-public-files/terra/ODHL_AR/test/metaData_NCBI.csv"
        File ncbi_post = "gs://theiagen-public-files/terra/ODHL_AR/test/ncbi_post.txt"
        File wgs_db = "gs://theiagen-public-files/terra/ODHL_AR/assets/databases/wgsDB/wgs_db_example.csv"
        File core_functions_script = "gs://theiagen-public-files/terra/ODHL_AR/bin/core_functions.sh"
        # Pipeline parameters
        Boolean save_trimmed_fail = true
        Boolean saved_merged = true
        Int coverage = 30
        Int minlength = 500       
        String outdir = "OUT"
        # Runtime parameters
        String docker = "us-docker.pkg.dev/general-theiagen/theiagen/odhl-pipeline:0.4"
        Int memory = 32
        Int cpu = 16
        Int disk_size = 100
    }

    command <<<
        set -euo pipefail

        date | tee DATE

        # We need to create the samplesheet 
        echo "sample,fastq_1,fastq_2" > sample_sheet.csv
        
        if [[ -z ~{fastq_2} ]]; then
            echo "~{samplename},~{fastq_1}," >> sample_sheet.csv
        else
            echo "~{samplename},~{fastq_1},~{fastq_2}" >> sample_sheet.csv
        fi

        # Launch nextflow pipeline with massive inputs
        nextflow -q run /ODHL_AR/main.nf \
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
            --outdir ~{outdir} \
            --labResults ~{labResults}\
            --metadata_NCBI ~{metadata_NCBI}\
            --ncbi_post ~{ncbi_post}\
            --wgs_db ~{wgs_db}\
            --core_functions_script ~{core_functions_script}\
            --save_trimmed_fail ~{save_trimmed_fail} \
            --saved_merged ~{saved_merged} \
            --coverage ~{coverage} \
            --minlength ~{minlength}
        
    >>>

    output {
        String analysis_date = read_string("DATE")
        String ar_analysis_docker = docker
        File summary_results = "~{outdir}/create_phoenix_summary_line/~{samplename}_summaryline.tsv"
        File trimmed_counts = "~{outdir}/get_trimd_stats/~{samplename}_trimmed_read_counts.txt"
        File synopsis = "~{outdir}/generate_pipeline_stats/~{samplename}.synopsis"
    }

    runtime {
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk ~{disk_size} SSD"
        maxRetries: 3
        preemptible: 0
    }
}