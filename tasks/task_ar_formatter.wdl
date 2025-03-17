version 1.0

task arFormatter {
    input{
        Array[File] summary_files
        Array[File] synopsis_files
        Array[File] trimmed_count_files
        File labResults
        String docker = "odhl-utilities:0.1"
        Int memory = 16
        Int cpu = 4
        Int disk_size = 100
    }

    command <<<
        set -euo pipefail

        mkdir summary_files_dir
        for file in ~{sep=' ' summary_files}; do
            cat $file
            cp $file summary_files_dir/
        done

        mkdir synopsis_files_dir
        for file in ~{sep=' ' synopsis_files}; do
            cat $file   
            cp $file synopsis_files_dir/
        done

        mkdir trimmed_counts
        for file in ~{sep=' ' trimmed_count_files}; do
            cat $file
            cp $file trimmed_counts/
        done

        ls ../*

        python3 /odhl_ar_utils/create_phoenix_summary_tsv.py \
            -d summary_files_dir \
            -o Phoenix_summary.tsv

        bash /odhl_ar_utils/post_process.sh \
            core_functions.sh \
            Phoenix_summary.tsv \
            ~{labResults}
    >>>

    output{
        File phoenix_summary = "Phoenix_summary.tsv"
        File processed_pipeline_results = "processed_pipeline_results.csv"
        File quality_results = "quality_results.csv"
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