# exploring the files inside Raw Data

getwd()

# Check what files are inside the zipped archive 
unzip("Raw Data/group14_data.zip", list = TRUE)

# lets get this saved into a df
group14_data_overview <- unzip("Raw Data/group14_data.zip", list = TRUE)
head(group14_data_overview)

# there are so many files...

# first lets inspect one file and see the structure 
first_read <- unz("Raw Data/group14_data.zip", "group14_data/an1201041847.csv")
one_mouse_df <- read.csv(first_read)
dim(one_mouse_df)
head(one_mouse_df)

second_read <- unz("Raw Data/group14_data.zip", "group14_data/an3702961657.csv")
second_mouse_df <- read.csv(second_read)
dim(second_mouse_df)
head(second_mouse_df)

#note the format is in long data, perhaps consider converting this into wide format but first need to make the one big data frame 

csv_files <- group14_data_overview$Name[grepl("group14_data/an.*\\.csv$", group14_data_overview$Name)]

library(data.table)

# Read every file and bind them together safely by creating a function 
total_long_df <- rbindlist(lapply(csv_files, function(f) { #here stack the csv ontop one by one
  temp <- unz("Raw Data/group14_data.zip", f) #files are zip so we need to ensure that the files are opened inside the zip without having to unzip it in hardrive 
  read.csv(temp, stringsAsFactors = FALSE) #parse to a df, keep everything in standard text to prevent data corruption
}), fill = TRUE)

dim(total_long_df)
head(total_long_df)

# this took way too long and kept freezing my r session so looked for an alternative method using a loop:
library(data.table)

total_files <- length(csv_files)

# Process and stack all files into your master long data frame
total_long_df <- rbindlist(lapply(seq_along(csv_files), function(i) {
  f <- csv_files[i]
  # Print progress update every 500 files
  if (i %% 2000 == 0) {
    cat("Processing file", i, "of", total_files, "...\n")
  }
  temp <- unz("Raw Data/group14_data.zip", f)
  df <- read.csv(temp, stringsAsFactors = FALSE)
  # Standardise the second column so everything stacks vertically
  colnames(df)[2] <- "measurement_value"
  
  return(df)
}), fill = TRUE)

#looking into the structure of our big df
dim(total_long_df)
colnames(total_long_df)

#i have noted that when uploading the files and reading the headers/ col names should not be the headers but still be part of the df so will adjust the code 
#converting to wide format 
library(dplyr)
library(tidyr)
total_files <- length(csv_files)

total_long_df <- rbindlist(lapply(seq_along(csv_files), function(i) {
  f <- csv_files[i]
  
  if (i %% 500 == 0) {
    cat("Processing file", i, "of", total_files, "...\n")
  }
  
  temp <- unz("Raw Data/group14_data.zip", f)
  df <- read.csv(temp, stringsAsFactors = FALSE)
  
  # The second column name is the unique animal ID (e.g., "MGI.1306812")
  animal_id <- colnames(df)[2]
  
  # Standardise column names so every file matches
  colnames(df) <- c("attribute", "value")
  
  # Tag this animal's rows with its ID
  df$animal_id <- animal_id
  
  return(df)
}), fill = TRUE)

# 2. Pivot wide so each animal gets exactly 1 row, and attributes become columns
total_wide_df <- total_long_df %>%
  pivot_wider(
    names_from = attribute,     # Turns gene_symbol, p_value, parameters into columns
    values_from = value,        # Fills in the corresponding data
    values_fn = first
  )

# Check your final wide dataset structure
dim(total_wide_df)
head(total_wide_df[, 1:6])


# See unique attribute names that might have slight variations
sort(unique(total_long_df$attribute))


#there are NAs in the total_wide_df because of inconsistent capitalisations and typo variations





# look into the chrom2.txt
readLines("Raw Data/chrom2.txt", n=5)
#these are separated by \ so need to use read.delim() 
chrom2 <- read.delim("Raw Data/chrom2.txt", sep = "\t", header = TRUE)
View(chrom2)
#this is ready 

