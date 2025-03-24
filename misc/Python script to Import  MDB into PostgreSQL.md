Below is a complete Python script that combines the functionality from my first answer (basic MDB to PostgreSQL import with `COPY`) with the enhancements from my last answer (logging with row counts and a delimited CSV format for spreadsheet analysis). This script is ready to share with your boss as a comprehensive solution for importing `SynergyV.mdb` into `xOpti` on a Linux environment, clearing existing records, optimizing performance with `COPY`, and providing detailed logs for analysis.

### Complete Python Script
```python
#!/usr/bin/env python3
import subprocess
import os
import psycopg2
from io import StringIO
import logging
from time import time

# Configuration
MDB_FILE = "/path/to/SynergyV.mdb"  # Update with the actual path to SynergyV.mdb
PG_HOST = "localhost"              # PostgreSQL host
PG_DB = "xOpti"                    # PostgreSQL database name
PG_USER = "your_username"          # PostgreSQL username
PG_PASSWORD = "your_password"      # PostgreSQL password
LOG_FILE = "import_log.csv"        # Log file name (CSV format)

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s|%(levelname)s|%(message)s",  # Pipe-delimited for CSV
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()  # Console output remains readable
    ]
)
logger = logging.getLogger()

# Custom formatter for console (human-readable)
console_handler = logger.handlers[1]  # StreamHandler is the second handler
console_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))

# Function to get list of tables from MDB file
def get_mdb_tables(mdb_file):
    result = subprocess.run(["mdb-tables", "-1", mdb_file], capture_output=True, text=True, check=True)
    return result.stdout.strip().split("\n")

# Function to export MDB table to CSV and count rows
def export_table_to_csv(mdb_file, table_name):
    result = subprocess.run(
        ["mdb-export", "-b", "strip", "-H", mdb_file, table_name],
        capture_output=True,
        text=True,
        check=True
    )
    csv_data = result.stdout
    row_count = len(csv_data.strip().split("\n")) - 1 if csv_data.strip() else 0  # Subtract 1 for header
    return csv_data, row_count

# Function to clear and import data into PostgreSQL
def import_to_postgres(tables):
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host=PG_HOST,
        database=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD
    )
    cursor = conn.cursor()

    try:
        # Step 1: Clear existing tables
        for table in tables:
            cursor.execute(f"DROP TABLE IF EXISTS \"{table}\" CASCADE;")
            logger.info(f"Cleared table|table={table}")

        # Step 2: Recreate table structures using mdb-schema
        start_time = time()
        schema = subprocess.run(
            ["mdb-schema", MDB_FILE, "postgres"],
            capture_output=True,
            text=True,
            check=True
        )
        cursor.execute(schema.stdout)
        conn.commit()
        elapsed_time = time() - start_time
        logger.info(f"Recreated table structures|xOpti|time={elapsed_time:.2f}")

        # Step 3: Import data using COPY with timing and row counts
        for table in tables:
            logger.info(f"Starting import|table={table}")
            start_time = time()

            csv_data, row_count = export_table_to_csv(MDB_FILE, table)
            if not csv_data.strip():  # Skip empty tables
                logger.info(f"Skipping empty table|table={table}|rows=0")
                continue

            # Use StringIO to pass CSV data to COPY
            csv_buffer = StringIO(csv_data)
            cursor.copy_expert(
                f"COPY \"{table}\" FROM STDIN WITH (FORMAT csv, HEADER true)",
                csv_buffer
            )
            conn.commit()

            elapsed_time = time() - start_time
            logger.info(f"Imported data|table={table}|rows={row_count}|time={elapsed_time:.2f}")

    except Exception as e:
        logger.error(f"Error occurred|details={str(e)}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

def main():
    # Write CSV header to log file
    with open(LOG_FILE, "w") as f:
        f.write("timestamp|level|message|details\n")

    # Verify mdbtools is installed
    if subprocess.call(["which", "mdb-tools"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0:
        logger.error("mdbtools not installed|Install with 'sudo apt install mdbtools'")
        return

    # Check if MDB file exists
    if not os.path.isfile(MDB_FILE):
        logger.error(f"MDB file not found|path={MDB_FILE}")
        return

    # Get list of tables
    tables = get_mdb_tables(MDB_FILE)
    if not tables or tables == ['']:
        logger.error("No tables found|file={MDB_FILE}")
        return

    logger.info(f"Found tables|tables={','.join(tables)}")
    start_time = time()
    import_to_postgres(tables)
    total_time = time() - start_time
    logger.info(f"Import completed|total_time={total_time:.2f}")

if __name__ == "__main__":
    main()
```

### How It Works
This script addresses your requirement to convert `SynergyV.mdb` (Microsoft Access) to `xOpti` (PostgreSQL) in a Linux environment, with the following features:

1. **Prerequisites**:
   - Requires `mdbtools` (`sudo apt install mdbtools`) for MDB file handling.
   - Requires `psycopg2` (`pip install psycopg2-binary`) for PostgreSQL interaction.
   - Assumes a working PostgreSQL setup with credentials provided.

2. **Core Functionality**:
   - **Table Extraction**: Uses `mdb-tables` to list tables in `SynergyV.mdb`.
   - **Clearing Tables**: Drops existing tables in `xOpti` with `DROP TABLE IF EXISTS ... CASCADE`.
   - **Schema Recreation**: Uses `mdb-schema` to recreate table structures in PostgreSQL.
   - **Data Import**: Exports each table to CSV using `mdb-export`, then imports it into PostgreSQL with the `COPY` command for high performance, especially for large datasets.

3. **Performance Optimization**:
   - The `COPY` command is used instead of individual `INSERT` statements, making it ideal for huge record counts due to its efficiency in bulk loading.

4. **Logging Enhancements**:
   - Logs to `import_log.csv` in a pipe-delimited (`|`) format with columns: `timestamp|level|message|details`.
   - Tracks time taken for each table import and the total process.
   - Includes row counts for each table, calculated from the CSV output.
   - Console output remains human-readable, while the log file is spreadsheet-friendly.

### Example Log Output (`import_log.csv`)
```
timestamp|level|message|details
2025-03-24 10:00:00,123|INFO|Found tables|tables=Table1,Table2,Table3
2025-03-24 10:00:00,150|INFO|Cleared table|table=Table1
2025-03-24 10:00:00,160|INFO|Cleared table|table=Table2
2025-03-24 10:00:00,170|INFO|Cleared table|table=Table3
2025-03-24 10:00:00,200|INFO|Recreated table structures|xOpti|time=0.03
2025-03-24 10:00:00,210|INFO|Starting import|table=Table1
2025-03-24 10:00:00,500|INFO|Imported data|table=Table1|rows=150|time=0.29
2025-03-24 10:00:00,510|INFO|Starting import|table=Table2
2025-03-24 10:00:01,000|INFO|Imported data|table=Table2|rows=2000|time=0.49
2025-03-24 10:00:01,010|INFO|Starting import|table=Table3
2025-03-24 10:00:01,200|INFO|Imported data|table=Table3|rows=50|time=0.19
2025-03-24 10:00:01,210|INFO|Import completed|total_time=1.09
```

### Usage Instructions
1. Save the script as `import_mdb_to_postgres.py`.
2. Update the configuration section (`MDB_FILE`, `PG_HOST`, `PG_DB`, `PG_USER`, `PG_PASSWORD`) with your specific values.
3. Make it executable: `chmod +x import_mdb_to_postgres.py`.
4. Run it: `./import_mdb_to_postgres.py`.

### Benefits for Your Boss
- **Efficiency**: Uses `COPY` for fast bulk imports, critical for large datasets.
- **Reliability**: Clears `xOpti` before importing, ensuring it mirrors `SynergyV`.
- **Analysis**: Provides a detailed log with timing and row counts, exportable to a spreadsheet for performance review.
- **Error Handling**: Includes checks for prerequisites and robust transaction management.

You can tell your boss this script automates the MDB-to-PostgreSQL conversion process, optimizes performance, and offers valuable insights into the import process through structured logging—all tailored to run seamlessly in our Linux environment. Let me know if you need a summary doc or further tweaks!
