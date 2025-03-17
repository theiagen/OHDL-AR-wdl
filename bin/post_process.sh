# bash bin/core_wgs_id.sh phoenix_results.sh labResults.csv

#########################################################
# ARGS
#########################################################
core_functions=$1
rawPipeline_results=$2
lab_results=$3

##########################################################
# Eval, source
#########################################################
source $(dirname "$0")/$core_functions

##########################################################
# Set files, dir
#########################################################
intermed_results="processed_pipeline_results.csv"
processed_samples="processed_samples.csv"
quality_results="quality_results.csv"

#########################################################
# project variables
#########################################################

##########################################################
# Run code
#########################################################
# pull sample files
cat $rawPipeline_results | awk -F"\t" '{print $1}' | grep -v "ID" | uniq > $processed_samples
IFS=$'\n' read -d '' -r -a sample_list < $processed_samples

# for each sample
## update the synopsis file
## review lab results
## update pass/fail
for sample_id in "${sample_list[@]}"; do
	# pull stats
	cat trimmed_counts/${sample_id}_trimmed_read_counts.txt >> all_trimmed_read_counts.txt #stats.txt

	# determine number of warnings, fails
	synopsis=synopsis_files_dir/$sample_id.synopsis
	num_of_warnings=`cat $synopsis | grep -v "WARNINGS" | grep "WARNING" | wc -l`
	num_of_fails=`cat $synopsis | grep -v "completed as FAILED" | grep "FAILED" | wc -l`

	# review lab results
	labValue=`cat $lab_results | grep $sample_id | cut -f2 -d","`
	pipelineValue=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $9}' | awk -F" " '{print $1}'`
	pipelineStatus=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $2}'`
		
	# message if the lab didnt give results
	if [[ $labValue == "" ]]; then echo "Missing lab value: $sample_id" >> $log_results; fi

	# update the results and reasons
	SID=$(awk -F"\t" -v sid=$sample_id '{ if ($1 == sid) print NR }' $rawPipeline_results)
	if [[ $num_of_fails -gt 0 ]]; then
		reason=$(cat $synopsis | grep -v "completed as" | grep -E "FAILED" | awk -F": " '{print $3}' |  awk 'BEGIN { ORS = "; " } { print }' | sed "s/; ; //g")
		cat $rawPipeline_results | awk -F";" -v i=$SID -v reason="${reason}" 'BEGIN {OFS = FS} NR==i {$2="FAIL"; $24=reason}1' > tmp
		mv tmp $rawPipeline_results

		echo "$sample_id,FAIL,SeqFailure" >> $quality_results
	elif [[ $num_of_warnings -gt 4 ]]; then
		reason=$(cat $synopsis | grep -v "Summarized" | grep -E "WARNING" | awk -F": " '{print $3}' |  awk 'BEGIN { ORS = "; " } { print }' | sed "s/; ; //g")
		cat $rawPipeline_results | awk -F";" -v i=$SID -v reason="${reason}" 'BEGIN {OFS = FS} NR==i {$2="FAIL"; $24=reason}1' > tmp
		mv tmp $rawPipeline_results

		echo "$sample_id,FAIL,WARNING($num_of_warnings)" >> $quality_results
	fi

	if [[ $pipelineStatus == "PASS" ]]; then
		if [[ "$pipelineValue" == "$labValue"  ]]; then
			echo "$sample_id,PASS,NA" >> $quality_results
		else
			reason="Lab Discordance"
			cat $rawPipeline_results | awk -F"\t" -v i=$SID -v reason="${reason}" 'BEGIN {OFS = FS} NR==i {$2="FAIL"; $24=reason}1' > tmp
			mv tmp $rawPipeline_results
			echo "$sample_id,FAIL,labDiscordance($pipelineValue,$labValue)" >> $quality_results
		fi
	fi

	# set MLST scheme
	species=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $9}' | sort | uniq`
    MLST_1=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $16}' | sort | uniq | cut -f1 -d","`
    MLST_Scheme_1=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $15}' | sort | uniq`
    MLST_2=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $18}'| sort | uniq | cut -f1 -d","`
    MLST_Scheme_2=`cat $rawPipeline_results | grep $sample_id | awk -F"\t" '{print $17}'| sort | uniq`

	# handle schemes that have parenthesis
    if [[ $MLST_Scheme_1 =~ "(" ]]; then MLST_Scheme_1=`echo $MLST_Scheme_1 | sed -E -n 's/.*\((.*)\).*$/\1/p'`; fi
    if [[ $MLST_Scheme_2 =~ "(" ]]; then MLST_Scheme_2=`echo $MLST_Scheme_2 | sed -E -n 's/.*\((.*)\).*$/\1/p'`; fi

    # check if the first scheme exists
	if [[ $MLST_1 == "-" ]] || [[ $MLST_1 == *"Novel"* ]]; then
        sequence_classification="MLST__${species}"
    else
		# check if there is a second MLST
		if [[ $MLST_2 == "-" ]]; then
			sequence_classification=`echo "ML${MLST_1}_${MLST_Scheme_1}_${species}"`
		else
			sequence_classification=`echo "ML${MLST_1}_${MLST_Scheme_1}_${species}-ML${MLST_2}_${MLST_Scheme_2}_${species}"`
		fi
    fi
		
	# Add corrected MLST and labvalue
	awk -v add="$sequence_classification\t$labValue" -v sample="$sample_id" '$0 ~ sample {print $0";"add}' "$rawPipeline_results" >> "$intermed_results"
done