version 1.0

import "../tasks/task_ar_formatter.wdl" as ar_formatter

workflow ar_formatter_wf{
    meta{
        description: "A formatter workflow for outputs from arAnalyzer."
    }
    input{
        Array[File] summary_files
        Array[File] synopsis_files
        Array[File] trimmed_count_files
        File labResults
    }
    
    call ar_formatter.arFormatter {
        input:
            summary_files = summary_files,
            synopsis_files = synopsis_files,
            trimmed_count_files = trimmed_count_files,
            labResults = labResults
    }
    output{
        File phoenix_summary = arFormatter.phoenix_summary
        File processed_pipeline_results = arFormatter.processed_pipeline_results
        File quality_results = arFormatter.quality_results
    }
}