# exploring the files inside Raw Data

getwd()

# Check what files are inside the zipped archive 
unzip("Raw Data/group14_data.zip", list = TRUE)


# lets get this saved into a df
group14_data_overview <- unzip("Raw Data/group14_data.zip", list = TRUE)
head(group14_data_overview)

file_info <- unzip("Raw Data/group14_data.zip", list = TRUE)
all_csv <- file_info[grepl("\\.csv$", file_info$Name) & !grepl("__MACOSX|/\\._", file_info$Name), ]
head(all_csv) #this code ensures we only have the csv files and we drop the parent directory row 

# there are so many files...

# first lets inspect one file and see the structure 
first_read <- unz("Raw Data/group14_data.zip", "group14_data/an1201041847.csv")
one_mouse_df <- read.csv(first_read)
dim(one_mouse_df)
head(one_mouse_df)
one_mouse_df

second_read <- unz("Raw Data/group14_data.zip", "group14_data/an3702961657.csv")
second_mouse_df <- read.csv(second_read)
dim(second_mouse_df)
head(second_mouse_df)

#lets get all data into one dataframe
library(tidyr)

# Set your folder path (since you are already in the Raw Data directory)
folder <- getwd()

# Find all CSV files whose names start with "an"
files <- list.files(
  folder,
  pattern = "^an.*\\.csv$",
  full.names = TRUE
)

if (length(files) == 0) {
  stop("No an*.csv files were found. Please check the working directory.")
}

# Import one file and standardise known field-name variations
read_one <- function(f) {
  x <- read.csv(
    f,
    header = FALSE,
    col.names = c("variable", "value"),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    colClasses = "character",
    na.strings = character(),
    fill = TRUE,
    quote = "\""
  )
  
  if (ncol(x) != 2) {
    stop(paste("The file was not read as two columns:", basename(f)))
  }
  
  x$variable <- trimws(x$variable)
  x$value <- trimws(x$value)
  
  # Fix known cases where a field name and value were joined together
  missing_value <- is.na(x$value) | x$value == ""
  
  i <- grepl('^lacz_skin"?expression$', x$variable) & missing_value
  x$variable[i] <- "lacz_skin"
  x$value[i] <- "expression"
  
  i <- grepl('^lacz_colon"?No data$', x$variable) & missing_value
  x$variable[i] <- "lacz_colon"
  x$value[i] <- "No data"
  
  # Remove an accidental trailing quote from field names
  x$variable <- sub('"$', "", x$variable)
  
  # Standardise confirmed spelling variations
  name_map <- c(
    "mouselife_stage" = "mouse_life_stage",
    "Allele_symbol"   = "allele_symbol",
    "laczHeart"       = "lacz_heart"
  )
  
  i <- x$variable %in% names(name_map)
  x$variable[i] <- unname(name_map[x$variable[i]])
  
  # Remove rows with a missing or blank field name
  keep <- !is.na(x$variable) & x$variable != ""
  x <- x[keep, ]
  
  # Stop if a field name occurs more than once in a file
  if (anyDuplicated(x$variable)) {
    stop(paste("Duplicate field names found in:", basename(f)))
  }
  
  # Record the source file for each row
  x$source_file <- basename(f)
  x
}

# Import and combine all files in long format
data_fixed <- do.call(rbind, lapply(files, read_one))
rownames(data_fixed) <- NULL

# Check that each file has only one record for each field
if (anyDuplicated(data_fixed[c("source_file", "variable")])) {
  stop("A field occurs more than once in the same file. Please inspect the source files.")
}

# Convert to wide format: one row per file and one column per field
wide_data <- pivot_wider(
  data_fixed,
  id_cols = source_file,
  names_from = variable,
  values_from = value
)

# View and inspect the result
View(wide_data)
dim(wide_data)
names(wide_data)

