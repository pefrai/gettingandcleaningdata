## Prerequisites:
## For this script to work as expected, the UCI dataset must have been downloaded from 
## https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
## and extracted (unzipped) to the working directory.
## The working directory should therefore include 2 folders
##     test
##     train
##
## Also, library dplyr must be available
library(dplyr)

## The code is broken down in parts according to the assignment instructions
## in https://www.coursera.org/learn/data-cleaning/peer/FIZtT/getting-and-cleaning-data-course-project


## 1. Merge the training and test data sets to create one data set
# Load training data set. Explicitly assigning col.names will facilitate future
# operations
train_x <- read.table("train/X_train.txt")
train_y <- read.table("train/y_train.txt", col.names = "Activity",
                colClasses = "factor")
train_subject <- read.table("train/subject_train.txt", col.names = "Subject",
                colClasses = "factor")

# Load test data set in a similar way
test_x <- read.table("test/X_test.txt")
test_y <- read.table("test/y_test.txt", col.names = "Activity", 
                     colClasses = "factor")
test_subject <- read.table("test/subject_test.txt", col.names = "Subject",
                           colClasses = "factor")

# Load feature names
feature_names <- read.table("features.txt",
                            col.names = c("feature_number", "feature_label"),
                            stringsAsFactors = FALSE)
# Make sure the labels follow the order of the column number (not really needed,
# given the content of the actual features.txt, but it could be required if the
# file changes)
feature_names <- feature_names[order(feature_names$feature_number), ]

# Merge test and train dataset
# The call to rbind simply puts one dataset after the other, keeping the order
# This is possible because both tables have the same variables
full_dataset <- rbind(train_x, test_x)

## 2. Extract only the measurements on the mean and standard deviation for each
# measurement
# Let us get a vector with the indexes of the variable names including "mean"
# or "std" in the name
subset_columns <- grep("mean|std", feature_names$feature_label)
# Extract those variables from full_dataset
partial_dataset <- full_dataset[, subset_columns]

# Add the activity labels and subject names. For the sake of clarity, they are
# added at the beginning of the dataset (i.e., using the first and second column)
partial_dataset <- cbind(rbind(train_y, test_y), 
                         rbind(train_subject, test_subject), partial_dataset)

## 3.- Use descriptive activity names to name the activities in the data set
# Load activity names from the file
activity_labels <- read.table("activity_labels.txt", 
                              col.names = c("Activity_number", "Activity_label"),
                              colClasses = c("integer", "factor"))
# Make sure the labels follow the oder of the number in the first column
activity_labels <- activity_labels[order(activity_labels$Activity_number), ]
# Assign the descriptive labels to the factors
levels(partial_dataset$Activity)<-activity_labels$Activity_label

## 4.- Label the data set with descriptive variable names
# Label columns with descriptive variable names
# Criteria about what "descriptive" means in agreement with
# https://www.coursera.org/learn/data-cleaning/peer/FIZtT/getting-and-cleaning-data-course-project/discussions/threads/eoUpRb-JEeW_UhLKov_F2Q
# - Replace ^t with Time
# - Replace ^f with Frequency
# - Eliminate ()
# - Replace Acc with Acceleration
# - Replace Mag with Magnitude
# - Replace jerk with Jerk (for consistency)

# In the initial assignment of feature_names$feature_label to names()
# the first 2 columns of partial_dataset must be respected, as they
# already have the right name
names(partial_dataset)[3:length(names(partial_dataset))]<- 
                gsub("^t", "Time", feature_names$feature_label[subset_columns])
names(partial_dataset)<- gsub("^f", "Frequency", names(partial_dataset))
names(partial_dataset)<- gsub("()", "", names(partial_dataset), fixed = TRUE)
names(partial_dataset)<- gsub("Acc", "Acceleration", names(partial_dataset), fixed = TRUE)
names(partial_dataset)<- gsub("Mag", "Magnitude", names(partial_dataset), fixed = TRUE)
names(partial_dataset)<- gsub("jerk", "Jerk", names(partial_dataset), fixed = TRUE)

## 5.- Create an independent tidy data set with the average of each variable for each
# activity and each subject. The suffix "groupmean" is added to each variable name
tidy_dataset <- partial_dataset %>%
        group_by(Activity, Subject) %>%
        summarise_all(funs(groupmean = mean))

# Write the result to the file tidy_dataset.txt, including column headers
write.table(tidy_dataset, file = "tidy_dataset.txt", col.names = TRUE)
# To check the result, invoke
# test_dataset <- read.table("tidy_dataset.txt", header = TRUE)
# View(test_dataset)