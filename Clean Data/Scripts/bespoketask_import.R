task_path <- file.path("../", "bespokeTask.txt")
readLines(task_path, n = 15)

# tab delimited

bespoketask_df <- read.delim(
  task_path,
  header = FALSE,
  sep = "\t",
  stringsAsFactors = FALSE,
  quote = "",
  na.strings = c("", "NA")
)

# Inspect column count first so you know if there's an empty 6th column from the trailing tab
ncol(bespoketask_df)
head(bespoketask_df, 5)


#There are 6 columns, keep only the first 5 (dropping the empty V6 column)
if (ncol(bespoketask_df) == 6) {
  bespoketask_df <- bespoketask_df[, 1:5]
}

# Set all 5 column names explicitly (no NAs allowed in colnames)
colnames(bespoketask_df) <- c(
  "human_gene_symbol",
  "human_ncbi_gene_id",
  "mouse_gene_symbol",
  "mgi_id",
  "mp_ids"
)

# Add row ID
bespoketask_df$task_row_id <- seq_len(nrow(bespoketask_df))

# Build bespoke_task_table directly by dropping "mp_ids" using column indexing
bespoke_task_table <- bespoketask_df[, names(bespoketask_df) != "mp_ids", drop = FALSE]

head(bespoke_task_table, 5)

#saving clean data into the file 
getwd()
write.csv(bespoke_task_table, "bespoke_task_table.csv", row.names = FALSE, na = "")
write.csv(bespoke_task_mp_bridge, "bespoke_task_mp_bridge.csv", row.names = FALSE, na = "")
