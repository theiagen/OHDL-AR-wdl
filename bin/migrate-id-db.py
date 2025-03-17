import pandas as pd
from google.cloud import bigquery
import sys
import argparse
from datetime import datetime
import uuid
from google.api_core import exceptions
import logging

logger = logging.getLogger(__name__)
logging.basicConfig(filename='example.log', encoding='utf-8', level=logging.DEBUG)

def update_data(df: pd.DataFrame):
    """
    Update the dataframe with improved data types and additional columns.
    
    Args:
        df: Pandas DataFrame with the original CSV data
    
    Returns:
        Update DataFrame ready for BigQuery upload
    """
    # Drop this START column from the get go
    df = df[df['PROJECT_ID'] != "START"]
    
    update_df = df.copy()

    update_df.columns = update_df.columns.str.lower()
    
    # Add a UUID column as primary key
    update_df['id'] = [str(uuid.uuid4()) for _ in range(len(update_df))]
    
    update_df['date_assigned'] = pd.to_datetime(update_df['date_assigned'], format='%Y%m%d')
    # Add ncbi_upload_successful column based on srrid
    update_df['ncbi_upload_successful'] = update_df['srrid'].apply(
        lambda x: False if pd.isna(x) or str(x).strip() == '' else True
    )
    
    cols = ['id'] + [col for col in update_df.columns if col != 'id']
    update_df = update_df[cols]
    
    return update_df

def migrate_csv_to_bigquery(csv_file, project_name, dataset_name, table_name):
    """
    Migrate data from CSV file to BigQuery table with enhanced schema.
    
    Args:
        csv_file: Path to the CSV file
        project_name: Google Cloud project ID
        dataset_name: BigQuery dataset name
        table_name: BigQuery table name
    
    Returns:
        Boolean indicating success/failure
    """
    logger.info(f"Starting migration from {csv_file} to BigQuery")
    
    try:
        df = pd.read_csv(csv_file)
        logger.info(f"Read {len(df)} records from {csv_file}")
        
        # Apply data migration
        update_df = update_data(df)
        logger.info("Applied schema enhancements:")
        logger.info(f"- Converted column names to lowercase")
        logger.info(f"- Added UUID primary key")
        logger.info(f"- Converted date_assigned to DATE type")
        logger.info(f"- Added ncbi_upload_successful column")
        
    except Exception as e:
        logger.error(f"Error processing CSV file: {e}")
        return False
    
    # Create BigQuery client
    client = bigquery.Client(project=project_name)
    table_id = f"{project_name}.{dataset_name}.{table_name}"
    
    # Configure the load job with the enhanced schema
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        schema=[
            bigquery.SchemaField("id", "STRING", description="UUID primary key"),
            bigquery.SchemaField("project_id", "STRING", description="Project identifier"),
            bigquery.SchemaField("ohio_id", "STRING", description="Original sample identifier"),
            bigquery.SchemaField("wgsid", "STRING", description="Assigned unique identifier in format YYYY-ZN-####"),
            bigquery.SchemaField("srrid", "STRING", description="SRR identifier from NCBI"),
            bigquery.SchemaField("samid", "STRING", description="SAM identifier from NCBI"),
            bigquery.SchemaField("date_assigned", "DATE", description="Date when ID was assigned"),
            bigquery.SchemaField("ncbi_upload_successful", "BOOLEAN", description="Flag indicating if NCBI upload was successful")
        ]
    )
    
    try:
        load_job = client.load_table_from_dataframe(
            update_df, table_id, job_config=job_config
        )
        load_job.result()
        
        # Get the destination table and print info
        table = client.get_table(table_id)
        logger.info(f"Loaded {table.num_rows} rows into {table_id}")
        
        # Print sample of first few records to verify
        query = f"SELECT * FROM `{table_id}` LIMIT 5"
        query_job = client.query(query)
        results = query_job.result()
        
        logger.info("\nSample of migrated data:")
        for row in results:
            logger.info(row)
            
        return True
    except Exception as e:
        logger.info(f"Error loading data to BigQuery: {e}")
        return False

def create_dataset_if_not_exists(project_name, dataset_name):
    """Create the dataset if it doesn't already exist."""
    client = bigquery.Client(project=project_name)
    dataset_id = f"{project_name}.{dataset_name}"
    
    try:
        client.get_dataset(dataset_id)
        logger.info(f"Dataset {dataset_id} already exists")
    except exceptions.NotFound:
        # Dataset does not exist, create it
        dataset = bigquery.Dataset(dataset_id)
        dataset.location = "us-central-1" 
        dataset = client.create_dataset(dataset)
        logger.info(f"Created dataset {dataset_id}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Migrate CSV data to BigQuery with enhanced schema')
    parser.add_argument('csv_file', help='Path to the CSV file to migrate')
    parser.add_argument('project_name', help='Google Cloud Project ID')
    parser.add_argument('dataset_name', help='BigQuery Dataset name')
    parser.add_argument('table_name', help='BigQuery Table name')
    
    args = parser.parse_args()
    
    # Create dataset if it doesn't exist
    create_dataset_if_not_exists(args.project_name, args.dataset_name)
    
    success = migrate_csv_to_bigquery(
        args.csv_file, 
        args.project_name, 
        args.dataset_name, 
        args.table_name
    )
    
    if success:
        logger.info("Migration completed successfully!")
    else:
        logger.error("Migration failed.")
        sys.exit(1)