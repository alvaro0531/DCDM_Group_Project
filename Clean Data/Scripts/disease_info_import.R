# opening up other files besides big data 

setwd("../MSc Bioinformatics/Data Cleaning Data Management/")

disease_path <- file.path("DCDMGroup14/Raw Data/", "Disease_information.txt")
readLines(disease_path, n = 10)

# See lines 11–25 to spot the column header row
readLines(disease_path, n = 25)[11:25]

# Load tab-delimited data while ignoring '#' comment lines
disease_info <- read.delim(
  disease_path,
  comment.char = "#",
  stringsAsFactors = FALSE,
  quote = ""
)



# Verify dimensions and column names
dim(disease_info)
head(disease_info, 3)

colnames(disease_info)
head(disease_info$X)

#col names should actually be the rows - here fix it


colnames(disease_info) <- c(
  "human_gene_symbol",
  "human_gene_name",
  "hgnc_id",
  "disease_name",
  "doid",
  "mouse_genotype_ids",
  "mouse_gene_symbol",
  "mgi_id"
)[seq_len(ncol(disease_info))]


head(disease_info$mouse_genotype_ids)


#fixing pipe separated mouse genotype ids 

library(dplyr)
library(tidyr)

# 1. Add a stable row ID and turn empty strings "" into proper NA
disease_clean <- disease_info %>%
  mutate(
    row_id = row_number(),
    mouse_genotype_ids = na_if(trimws(mouse_genotype_ids), "")
  )

# 2. Core disease table (without the jumbled multi-ID column)
disease_table <- disease_clean %>%
  select(-mouse_genotype_ids)

# 3. Normalized bridge table: 1 row per (row_id, mouse_genotype_id)
genotype_bridge <- disease_clean %>%
  select(row_id, mouse_genotype_ids) %>%
  filter(!is.na(mouse_genotype_ids)) %>%
  separate_rows(mouse_genotype_ids, sep = "\\|") %>%
  mutate(mouse_genotype_id = trimws(mouse_genotype_ids)) %>%
  select(row_id, mouse_genotype_id) %>%
  distinct()

# Check the result
head(genotype_bridge, 10)
nrow(genotype_bridge)

#row id was made to link the mgi col which is mouse gene id with - disease_clean
#mouse genotype id which is in the genotype_bridge df

#SAVING THE DF
write.csv(disease_clean, "disease_clean.csv", row.names = FALSE, na = "")
write.csv(genotype_bridge, "genotype_bridge.csv", row.names = FALSE, na = "")
