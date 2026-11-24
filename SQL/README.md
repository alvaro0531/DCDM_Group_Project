# IMPC Database: Complete Workflow from Cleaned CSV Files to MySQL

## 1. Overall Workflow

The database was built directly from the datasets that had already been cleaned and imputed. Therefore, the previous data cleaning and missing-value imputation steps did not need to be repeated.

The main task was to transform the CSV files into a relational database structure suitable for MySQL and establish relationships between the tables using primary and foreign keys.

The overall workflow was:

**6 cleaned CSV files + 2 Parameter Group files → 8 input CSV files → Data transformation using R Markdown → 18 import CSV files → Create 18 tables in MySQL → Import data using DBeaver → Check data integrity and table relationships.**

The final database contains 18 tables. Gene information, experimental parameters, phenotype results, disease information and chromosome data are stored separately and linked through primary and foreign keys. This structure makes it easier to perform SQL queries and further data analysis.

## 2. Preparing the Input Data

The following six cleaned CSV files were used as the main input datasets:

1. `Group14_Cleaned_Imputed_Dataset.csv`
2. `Parameters.csv`
3. `Procedures.csv`
4. `bespokeTask.csv`
5. `Disease_information.csv`
6. `chrom2.csv`

The `Group14_Cleaned_Imputed_Dataset.csv` file already included the results of missing-value imputation, so the final cleaned version was used directly.

Two additional Parameter Group files were also included to store the six parameter groups and the parameters belonging to each group:

7. `parameter_group.csv`
8. `parameter_group_member.csv`

All eight CSV files were placed in the `database_import` folder as the input for the R Markdown transformation process.

```text
IMPC_Project/
├── build_impc_import_tables.Rmd
├── database_import/
│   ├── Group14_Cleaned_Imputed_Dataset.csv
│   ├── Parameters.csv
│   ├── Procedures.csv
│   ├── bespokeTask.csv
│   ├── Disease_information.csv
│   ├── chrom2.csv
│   ├── parameter_group.csv
│   └── parameter_group_member.csv
└── database_import_revised/
    └── [Automatically generated output files]
```
## 3. Splitting the Data Using R Markdown

The code for the database transformation is saved in:

`build_impc_import_tables.Rmd`

Instead of importing the eight CSV files directly into MySQL, the data was first split and reorganised according to the relational database structure.

The main transformation steps included:

- **Mouse Gene:** Mouse gene information from four relevant data sources was combined into the `mouse_gene` table. This allows different tables to be linked using the same MGI ID.
- **Human Gene:** A separate `human_gene` table was created to store human Entrez IDs and HGNC IDs. Since these identifiers came from different sources, some records contain only one type of ID.
- **Parameters and Procedures:** The `IMPC_parameter_description` and `IMPC_procedure` tables were linked through `procedure_code`, based on the cleaned datasets.
- **Phenotype Results:** The main phenotype dataset was split into `clean_data` and `lacz_expression`. The `clean_data` table stores the experimental analysis information, while `lacz_expression` stores LacZ expression results for 11 tissues. These two tables are linked through `result_id`.
- **Bespoke Task:** The original Bespoke records were retained, while fields containing multiple MP IDs were split into separate relationship records.
- **Disease Information:** The original disease information was retained, and fields containing multiple Mouse Genotype IDs were split into individual relationship records.
- **Chromosome 2:** Chromosome 2 data was organised into three levels: Gene, Transcript and Exon.
- **Parameter Groups:** The `parameter_group` and `parameter_group_member` tables were used to store the six parameter groups and their associated parameters.

This approach helps reduce unnecessary data duplication and makes it easier to join different tables in SQL queries.

## 4. Generating the Import CSV Files

The `build_impc_import_tables.Rmd` file was opened in RStudio, and all code chunks were executed in order.

After the code ran successfully, the following output folder was generated:

`database_import_revised`

The folder contains **20 files in total**:

- 18 CSV files ending in `_import.csv`, which are used for importing data into MySQL.
- `import_summary.csv`, which records the row counts of the exported tables.
- `validation_notes.txt`, which contains information about the data transformation and validation checks.

Only the 18 `_import.csv` files need to be imported into MySQL.

The other two files are used to check the transformation results and compare the row counts after importing the data into MySQL.

## 5. Creating the Database in MySQL

The database was created using MySQL 8.0 and managed through DBeaver.

The database name is:

`data_base_merged`

The final SQL schema was executed first to create all 18 empty tables. The corresponding SQL code is saved in `schema.sql`.

The schema defines the data types, primary keys, foreign keys and other relevant constraints for each table.

Compared with the earlier design, the final version no longer includes the `IMPC_procedure_parameter` table because Parameters can now be linked directly to Procedures through `procedure_code`.

A new `chrom2_gene` table was also added to store the relationship between Ensembl Gene IDs and MGI Gene IDs.

As a result, the final database still contains 18 tables.

## 6. Importing Data Using DBeaver

After the database tables were created, DBeaver's **Import Data** function was used to import the generated CSV files into their corresponding MySQL tables one by one.

The initial attempt used SQL commands to import the CSV files in batches, but some data was not loaded correctly and foreign key constraint errors occurred. To make each step easier to check, the data was eventually imported individually using DBeaver's CSV import function.

During the import, the first row of each CSV file was used as the column headers, and the delimiter was set to a comma. The existing MySQL tables were selected as the import targets.

One important setting was **Set empty strings to NULL**, which needed to be enabled.

This converts empty fields in the CSV files into SQL `NULL` values, preventing multiple empty strings from being inserted into columns with unique constraints.

The primary key IDs generated by R Markdown also needed to be preserved during the import to maintain the relationships between different tables.

## 7. Table Import Order

Since some tables depend on other tables through foreign keys, the parent tables needed to be imported before the child tables.

The following import order was used:

| Order | CSV File | MySQL Table |
|---:|---|---|
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

The `parameter_group_external_data` table currently has no corresponding external resource data. Therefore, the table has been created but remains empty for now.

## 8. Checking the Imported Data

After importing the CSV files, SQL queries were executed in DBeaver to check the number of records in all 18 tables.

The following SQL query was used to retrieve the row counts of all tables together:

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

The results show that all 18 database tables were created successfully, and 17 of them contain data.

The row counts of the main datasets are consistent with the numbers provided in the team handover.

The `import_summary.csv` file generated by R Markdown can also be used to compare the MySQL row counts with the exported data and check whether any records were missed during the import.

## 9. Checking the Relationships Between Tables

Apart from checking the row counts, it was also necessary to confirm that the different tables could be linked correctly.

The first relationship check focused on three core tables:

- `clean_data`
- `lacz_expression`
- `mouse_gene`

The following SQL query was used:

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

The query returned the following results:

| Check | Result |
|---|---:|
| `total_results` | 28,660 |
| `matched_lacz` | 28,660 |
| `matched_genes` | 28,660 |

The results show that all 28,660 analysis records in `clean_data` can be matched to their corresponding LacZ records and mouse gene information.

This confirms that the relationship checks between `clean_data`, `lacz_expression` and `mouse_gene` passed.

The primary and foreign keys for the remaining tables have also been defined in the SQL schema. However, further queries are still needed to check whether the corresponding data relationships work as expected.

## 10. Current Progress and Next Steps

The main database tasks have now been completed, including:

- Using the final cleaned CSV files as the database input.
- Transforming eight input CSV files into the data required for 18 database tables using R Markdown.
- Creating 18 relational tables in MySQL.
- Importing all available data using DBeaver.
- Checking the row counts of all 18 tables.
- Verifying the relationships between the main phenotype data, LacZ expression data and mouse gene information.

The database now provides the basic structure needed for SQL queries and R Shiny development.

The remaining tasks include:

1. Writing and testing the SQL queries required by the coursework.
2. Further checking the relationships between the remaining database tables.
