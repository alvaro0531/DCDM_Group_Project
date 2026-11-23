setwd("../")
getwd()

proc_path <- file.path("Raw Data/", "IMPC_procedure.txt")
readLines(proc_path, n = 15)

#comma separated

proc_df <- read.csv(
  proc_path,
  stringsAsFactors = FALSE,
  strip.white = TRUE,
  na.strings = c("", "NA")
)

# Check structure and first few rows
dim(proc_df)
colnames(proc_df)
head(proc_df, 5)

# Check uniqueness and duplicates
anyDuplicated(proc_df$impcParameterOrigId)
sum(duplicated(proc_df))



# Check values of isMandatory and impcParameterOrigId for procedures with NA descriptions
na_desc_procs <- proc_df[is.na(proc_df$description), ]

table(na_desc_procs$isMandatory, useNA = "ifany")
summary(na_desc_procs$impcParameterOrigId)

# See which procedure names have NA descriptions vs. non-NA descriptions
na_by_name <- aggregate(
  is.na(description) ~ name,
  data = proc_df,
  FUN = function(x) c(n_total = length(x), n_na = sum(x))
)
head(na_by_name, 15)

#here there was no parsing error 
#isMandatory has zero NA across the rows and impcParameterOrigID is clean

sum(duplicated(proc_df)) # no duplicate rows so good to save


#saving the df and the script
setwd("Raw Data/loading_txt_files/")
write.csv(proc_df, "procedures.csv", row.names = FALSE, na = "")

