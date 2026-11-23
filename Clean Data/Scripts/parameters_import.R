setwd("../")
getwd()

param_path <- file.path("Raw Data/", "IMPC_parameter_description.txt")
readLines(param_path, n = 15)

param_desc <- read.csv(
  param_path,
  stringsAsFactors = FALSE,
  strip.white = TRUE,
  na.strings = c("", "NA")
)

# Check dimensions, column names, and first few rows
dim(param_desc)
colnames(param_desc)
head(param_desc, 5)



#Checking if iD columns are unique 
anyDuplicated(param_desc$impcParameterOrigId) 
anyDuplicated(param_desc$parameterId)


# Counts rows where EVERY column matches an earlier row (true exact duplicates)
sum(duplicated(param_desc))

# Collects parameterId values that appear more than once
dup_param_ids <- param_desc$parameterId[duplicated(param_desc$parameterId)]
head(param_desc[param_desc$parameterId %in% head(dup_param_ids, 5), ], 15) # Shows up to 15 rows for the first 5 repeated parameterIds to see if descriptions/IDs differ

# 3. See examples of repeated impcParameterOrigId values
dup_orig_ids <- param_desc$impcParameterOrigId[duplicated(param_desc$impcParameterOrigId)]
head(param_desc[param_desc$impcParameterOrigId %in% head(dup_orig_ids, 5), ], 15)


param_clean <- unique(param_desc) # Removes only 100% identical rows while keeping rows that share an ID but differ in other fields
nrow(param_desc) # Row count before removing exact duplicate rows
nrow(param_clean) # Row count after removing exact duplicate rows

getwd()
setwd("Raw Data/loading_txt_files/")

write.csv(param_clean, "IMPC_parameters.csv", row.names = FALSE, na = "")
