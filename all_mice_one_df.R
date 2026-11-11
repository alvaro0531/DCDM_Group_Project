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

#lets get this into one big data frame where we have everything - but first do a dummy df
library(data.table)

# 1. Define your target files
target_files <- c("group14_data/an3702961657.csv", "group14_data/an9082083823.csv")

# 2. Process each file into a single row and combine them immediately into ONE big df
multiple_mice_list <- lapply(target_files, function(f) {
  temp <- unz("Raw Data/group14_data.zip", f)
  df <- read.csv(temp, stringsAsFactors = FALSE, header = TRUE)
  
  # Extract animal ID from column header
  animal_id <- colnames(df)[2]
  
  # Standardize and transpose
  colnames(df) <- c("attribute", "value")
  df$attribute <- tolower(trimws(df$attribute))
  df <- df[!is.na(df$attribute) & df$attribute != "", ]
  df <- df[!duplicated(df$attribute), ]
  
  single_row <- as.data.frame(t(df$value), stringsAsFactors = FALSE)
  colnames(single_row) <- df$attribute
  single_row$animal_id <- animal_id
  
  return(single_row)
})

# 3. Bind them into ONE big dataframe
dummy_df <- rbindlist(multiple_mice_list, fill = TRUE)

# Put animal_id first
setcolorder(one_big_df, c("animal_id", setdiff(names(one_big_df), "animal_id")))



#now lets do it for the rest of 28k mice + note the format is in long data, perhaps consider converting this into wide format but first need to make the one big data frame 

# loop through every file path in all_csv$Name and process into individual rows
mouse_list <- lapply(seq_len(nrow(all_csv)), function(i) {
  file_path <- all_csv$Name[i]
  
  if (i %% 1000 == 0) {
    cat("Processing file", i, "of", nrow(all_csv), "...\n")
  }
  
  con <- unz("Raw Data/group14_data.zip", file_path)
  df <- read.csv(con, stringsAsFactors = FALSE, header = TRUE)
  
  animal_id <- colnames(df)[2]  # extract the unique animal ID from the second column header
  
  colnames(df) <- c("attribute", "value")  # standardise and clean the best we can
  df$attribute <- tolower(trimws(df$attribute))
  df$attribute <- gsub('["\\\\]', '', df$attribute)
  
  df <- df[!is.na(df$attribute) & df$attribute != "", ]
  df <- df[!duplicated(df$attribute), ]
  
  single_row <- as.data.frame(t(df$value), stringsAsFactors = FALSE)   # transpose into a single horizontal row for this mouse
  colnames(single_row) <- df$attribute
  single_row$animal_id <- animal_id
  
  return(single_row)
})

one_big_df <- rbindlist(mouse_list, fill = TRUE) # combine everything into one big unified dataframe
setcolorder(one_big_df, c("animal_id", setdiff(names(one_big_df), "animal_id")))

one_big_df <- one_big_df[, 1:(ncol(one_big_df) - 4)] # remove those last 4 columns that show NA 

