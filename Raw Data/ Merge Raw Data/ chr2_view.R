# look into the chrom2.txt
readLines("Raw Data/chrom2.txt", n=5)
#these are separated by \ so need to use read.delim() 
chrom2 <- read.delim("Raw Data/chrom2.txt", sep = "\t", header = TRUE)
View(chrom2)
#this is ready 

# saving the file
write.csv(chrom2, file = "chrom2.csv", row.names = FALSE)
