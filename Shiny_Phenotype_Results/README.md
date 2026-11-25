#Phenotype analysis results exported from the Group 14 R Shiny dashboard.
## MySQL Database Validation

The five coursework genes (Grk5, Rhbdl2, Scx, Muc5ac and Parpbp) can be checked in the `data_base_merged` MySQL database using DBeaver before comparing the results with R Shiny.

Run the following SQL query to identify the available knockout models and their analysis record counts:

```sql
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
```

The query returns the gene, allele, strain and total number of analysis records for each knockout model.

In the R Shiny **Gene Explorer**, select the same gene and knockout model, then choose **All results**. The displayed **Analysis records** count should match the corresponding MySQL query result.
