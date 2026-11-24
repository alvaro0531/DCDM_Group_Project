# IMPC Database: Workflow from Cleaned CSV Files to MySQL

## 1. Overall Approach

For the database part, I used the cleaned datasets directly. I did not repeat the data cleaning or missing-value imputation that had already been completed.

My main task was to organise these CSV files into a relational database structure in MySQL and establish the relationships between the tables.

The overall workflow was:

**6 cleaned CSV files from team members + 2 Parameter Group files prepared by me → 8 input CSV files → Data transformation using R Markdown → 18 import CSV files → Create 18 tables in MySQL → Import the data using DBeaver → Check the data and table relationships.**

I decided to use 18 tables in the final database. This allowed me to store gene information, experimental parameters, phenotype results, disease information and chromosome data separately, while connecting them through primary and foreign keys.

## 2. Preparing the Input Data

I used the following six cleaned CSV files provided by my team members:

1. `Group14_Cleaned_Imputed_Dataset.csv`
2. `Parameters.csv`
3. `Procedures.csv`
4. `bespokeTask.csv`
5. `Disease_information.csv`
6. `chrom2.csv`

The `Group14_Cleaned_Imputed_Dataset.csv` file already contained the results of the previous missing-value imputation, so I used this final version directly.

I had also prepared two Parameter Group files:

7. `parameter_group.csv`
8. `parameter_group_member.csv`

These two files store the six parameter groups and the parameters belonging to each group.

In total, I used eight input CSV files and placed them in the `database_import` folder.

## 3. Splitting the Data Using R Markdown

To make the database transformation process easier to understand, I organised the code in:

`build_impc_import_tables.Rmd`

Instead of importing the eight CSV files directly into MySQL, I first split and reorganised the data based on the relationships needed in the database.

The main steps were:

- **Mouse Gene:** I combined mouse gene information from four relevant data sources into the `mouse_gene` table. This allows different tables to be linked using the same MGI ID.
- **Human Gene:** I created a separate `human_gene` table to store human Entrez IDs and HGNC IDs. Since the two sources provide different identifiers, some records contain only one type of ID.
- **Parameters and Procedures:** I linked these two tables using `procedure_code`, based on the updated datasets provided by my team members.
- **Phenotype Results:** I split the main phenotype dataset into `clean_data` and `lacz_expression`. The first table stores the analysis information, while the second stores LacZ expression results for 11 tissues. The two tables are linked through `result_id`.
- **Bespoke Task:** I kept the original Bespoke records and created separate relationship tables for records containing multiple MP IDs.
- **Disease Information:** I kept the disease information and split multiple Mouse Genotype IDs into individual relationship records.
- **Chromosome 2:** I organised the chromosome data into three levels: Gene, Transcript and Exon.
- **Parameter Groups:** I used `parameter_group` and `parameter_group_member` to store the six groups and their associated parameters.

I split the data this way mainly to reduce unnecessary duplication and make it easier to join different tables in SQL queries.

## 4. Generating the Import CSV Files

After running the code chunks in `build_impc_import_tables.Rmd` in RStudio, the script successfully generated an output folder called:

`database_import_revised`

The folder contains **20 files in total**:

- 18 CSV files ending in `_import.csv`, which are used for importing data into MySQL.
- `import_summary.csv`, which records the row counts of the generated tables.
- `validation_notes.txt`, which records information about the data transformation and validation checks.

Only the 18 `_import.csv` files need to be imported into MySQL.

I kept these exported files so I could compare the row counts in MySQL with the R outputs after importing the data.

## 5. Creating the Database in MySQL

I used MySQL 8.0 and managed the database through DBeaver.

The database name is:

`data_base_merged`

I first ran the final SQL schema to create all 18 empty tables. The code for this part can be found in `schema.sql`.

The SQL schema defines the data types, primary keys, foreign keys and other relevant constraints for each table.

One difference from my earlier database design is that I removed the `IMPC_procedure_parameter` table because Parameters can now be linked directly to Procedures using `procedure_code`.

I also added a `chrom2_gene` table to store the relationship between Ensembl Gene IDs and MGI Gene IDs.

Therefore, the final database still contains 18 tables.

## 6. Importing the Data Using DBeaver

After creating the tables, I used DBeaver's **Import Data** function to import each CSV file into its corresponding MySQL table.

I initially tried importing all the CSV files using SQL commands, but I encountered problems with the data not loading correctly and foreign key constraints. To make it easier to check each step, I decided to import the files individually through DBeaver instead.

During the import, I used the first row of each CSV as the column headers and selected a comma as the delimiter. I imported the data into the existing MySQL tables rather than creating new tables.

One important setting was **Set empty strings to NULL**, which needed to be enabled. I also left **Ignore duplicate rows** disabled.

This meant that empty fields were stored as SQL `NULL` values. However, the original `No data` values in the LacZ fields were kept as text rather than being converted to `NULL`.

## 7. Import Order

Since some tables depend on other tables through foreign keys, I imported the parent tables before the child tables.

I followed this order:

| Order | CSV File | MySQL Table |
|---|---|---|
| 1 | `mouse_gene_import.csv` | `mouse_gene` |
| 2 | `human_gene_import.csv` | `human_gene` |
| 3 | `IMPC_procedure_import.csv` | `IMPC_procedure` |
| 4 | `IMPC_parameter_description_import.csv` | `IMPC_parameter_description` |
| 5 | `parameter_group_import.csv` | `parameter_group` |
| 6 | `parameter_group_member_import.csv` | `parameter_group_member` |
| 7 | `clean_data_import.csv` | `clean_data` |
| 8 | `lacz_expression_import.csv` | `lacz_expression` |
| 9 | `bespokeTask_import.csv` | `bespokeTask` |
| 10 | `mp_terms_import.csv` | `mp_terms` |
| 11 | `bespokeTask_mp_import.csv` | `bespokeTask_mp` |
| 12 | `human_diseases_import.csv` | `human_diseases` |
| 13 | `Disease_information_import.csv` | `Disease_information` |
| 14 | `Disease_information_genotype_import.csv` | `Disease_information_genotype` |
| 15 | `chrom2_gene_import.csv` | `chrom2_gene` |
| 16 | `chrom2_transcript_import.csv` | `chrom2_transcript` |
| 17 | `chrom2_import.csv` | `chrom2` |
| 18 | `parameter_group_external_data_import.csv` | `parameter_group_external_data` |

The last table, `parameter_group_external_data`, does not currently have any external resource data, so I left the table empty after creating it.

## 8. Checking the Imported Data

After importing the data, I checked the number of records in all 18 tables using SQL queries in DBeaver.

I used the following SQL query to retrieve the row counts of all tables together:

```sql
USE data_base_merged;

SELECT 'mouse_gene' AS table_name, COUNT(*) AS row_count FROM mouse_gene
UNION ALL
SELECT 'human_gene', COUNT(*) FROM human_gene
UNION ALL
SELECT 'IMPC_procedure', COUNT(*) FROM IMPC_procedure
UNION ALL
SELECT 'IMPC_parameter_description', COUNT(*) FROM IMPC_parameter_description
UNION ALL
SELECT 'parameter_group', COUNT(*) FROM parameter_group
UNION ALL
SELECT 'parameter_group_member', COUNT(*) FROM parameter_group_member
UNION ALL
SELECT 'clean_data', COUNT(*) FROM clean_data
UNION ALL
SELECT 'lacz_expression', COUNT(*) FROM lacz_expression
UNION ALL
SELECT 'bespokeTask', COUNT(*) FROM bespokeTask
UNION ALL
SELECT 'mp_terms', COUNT(*) FROM mp_terms
UNION ALL
SELECT 'bespokeTask_mp', COUNT(*) FROM bespokeTask_mp
UNION ALL
SELECT 'human_diseases', COUNT(*) FROM human_diseases
UNION ALL
SELECT 'Disease_information', COUNT(*) FROM Disease_information
UNION ALL
SELECT 'Disease_information_genotype', COUNT(*) FROM Disease_information_genotype
UNION ALL
SELECT 'chrom2_gene', COUNT(*) FROM chrom2_gene
UNION ALL
SELECT 'chrom2_transcript', COUNT(*) FROM chrom2_transcript
UNION ALL
SELECT 'chrom2', COUNT(*) FROM chrom2
UNION ALL
SELECT 'parameter_group_external_data', COUNT(*) FROM parameter_group_external_data;
```

The query returned the following results:

| Table Name | Number of Records |
|---|---:|
| `mouse_gene` | 24,020 |
| `human_gene` | 24,358 |
| `IMPC_procedure` | 66 |
| `IMPC_parameter_description` | 4,633 |
| `parameter_group` | 6 |
| `parameter_group_member` | 189 |
| `clean_data` | 28,660 |
| `lacz_expression` | 28,660 |
| `bespokeTask` | 28,880 |
| `mp_terms` | 27 |
| `bespokeTask_mp` | 87,315 |
| `human_diseases` | 5,727 |
| `Disease_information` | 13,912 |
| `Disease_information_genotype` | 138,055 |
| `chrom2_gene` | 5,482 |
| `chrom2_transcript` | 21,109 |
| `chrom2` | 105,204 |
| `parameter_group_external_data` | 0 |

All 18 tables were created successfully, and 17 of them contain data.

The row counts of the main datasets were consistent with the numbers provided in the team handover. I also kept `import_summary.csv` for further comparison with the tables generated during the R transformation.

## 9. Checking the Relationships Between Tables

Apart from checking the row counts, I also tested whether the main tables could be joined correctly.

I first checked the relationships between three core tables:

- `clean_data`
- `lacz_expression`
- `mouse_gene`

I used the following SQL query:

```sql
USE data_base_merged;

SELECT
    COUNT(*) AS total_results,
    COUNT(l.result_id) AS matched_lacz,
    COUNT(m.gene_accession_id) AS matched_genes
FROM clean_data AS c
LEFT JOIN lacz_expression AS l
    ON c.result_id = l.result_id
LEFT JOIN mouse_gene AS m
    ON c.gene_accession_id = m.gene_accession_id;
```

The query returned:

| Check | Result |
|---|---:|
| `total_results` | 28,660 |
| `matched_lacz` | 28,660 |
| `matched_genes` | 28,660 |

These results show that all 28,660 analysis records in `clean_data` can be matched to their corresponding LacZ records and mouse gene information.

This confirms that the relationships between these three main tables are working as expected.

The primary and foreign keys for the other tables have also been defined in the database schema, but I still need to check those relationships further using additional queries.

## 10. Current Progress and Next Steps

So far, I have completed the main database tasks:

- Used the final cleaned datasets as input.
- Used R Markdown to transform eight input CSV files into the data needed for 18 database tables.
- Created 18 relational tables in MySQL.
- Imported all available data using DBeaver.
- Checked the row counts of the tables.
- Tested the relationships between the main phenotype data, LacZ expression data and mouse gene information.

The database is now ready to be used for SQL queries and R Shiny development.

There are still a few things I need to complete:

1. Write and test the SQL queries required by the coursework.
2. Further check whether the relationships between the remaining tables work as expected.
