#Phenotype analysis results exported from the Group 14 R Shiny dashboard.

This folder contains phenotype analysis results exported from the Group 14 R Shiny Gene Explorer for five genes:

Grk5

Rhbdl2

Scx

Muc5ac

Parpbp

The CSV files contain analysis records downloaded from the R Shiny application.

Checking the Results in MySQL

The database is named data_base_merged.

Open DBeaver, connect to the MySQL database and run the following SQL query to identify the available knockout models and their analysis record counts:

USE data_base_merged;

SELECT
    gene_symbol,
    allele_symbol,
    strain_name,
    COUNT(*) AS analysis_records
FROM clean_data
WHERE gene_symbol IN (
    'Grk5',
    'Rhbdl2',
    'Scx',
    'Muc5ac',
    'Parpbp'
)
GROUP BY
    gene_symbol,
    allele_symbol,
    strain_name
ORDER BY
    gene_symbol,
    allele_symbol,
    strain_name;

The query lists the gene symbol, allele, strain and number of analysis records for each available knockout model.
