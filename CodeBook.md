# Getting and Cleaning Data Peer-graded Assignment
# CodeBook

Acknowledgements:  
I want to thank David Hood, author of ["Getting & Cleaning Data: The Assignment"](https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/)
and other contributors to the Course message board for their valuable insight into this assignment.

### UCI dataset

The UCI data set can be downloaded from https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip. Once unzipped, the relevant data for this assignment is the following:  

* File activity_labels.txt  
* File features.txt  
* Folder "train", containing the train data set  
* Folder "test", containing the test data set  

Each folder contains 3 files  

* X_\<folder\>.txt
* y_\<folder\>.txt  
* subject_\<folder\>.txt  

where \<folder\> is either train or test[^1].  

The content of the files is as follows.  

1. activity_labels.txt  
Data set with 2 columns  
* 1st column, integer, 1 to 6: index for the activity label.  
* 2nd column, character: textual identifications for each of the activities.  

2. features.txt  
Data set with 2 columns  
* 1st column, integer: index for the feature name.  
* 2nd column, character: identifier (name) of the variable stored in file X_\<folder\>.txt in the column number given by the corresponding index on the 1st column.  

3. X_\<folder\>.txt  
These files contain the data tables obtained from the readings of the smartphone accelerometer and gyroscope, processed as described in the file features_info.txt.  
* Column \<n\> contains the variable whose label appears in row \<n\> of features.txt  
* Each row is an observation on one activity performed by one subject.  
For a detailed description of each of the variables, origin and units, please refer to the UCI data set files features_info.txt and README.txt  

4. y_\<folder\>.txt  
Files with one single column, type integer, range 1 to 6.  
Each row of these files gives the activity index corresponding to the respective row in the file X_\<folder\>.txt. This index allows identifying the activity label through the equivalence given in file activity_labels.txt.  

5. subject_\<folder\>.txt   
File with one single column, type integer, range 1 to 30.  
Each row of these files identifies the subject involved in the observation on the respective row of files X_\<folder\>.txt and y_\<folder\>.txt  

### Assignment step 1: Merge the training and test data sets to create one data set

Each table is read through an invocation of

        read.table(...)

creating 3 couples of data frames:

* **train_x** and **test_x** for the contents of X_\<folder\>.txt
* **train_y** and **test_y** for the contents of y_\<folder\>.txt
* **train_subject** and **test_subject** for the contents of subject_\<folder\>.txt

The explicit use of col.names() and colClasses() when reading y_\<folder\>.txt and subject_\<folder\>.txt facilitates future operations.

The content of features.txt is also read into the data frame **feature_names**.

**train_x** and **test_x** are merged into a single data set **full_dataset** through

        full_dataset <- rbind(train_x, test_x)

Merging **train_y**, **test_y**, **train_subject** and **test_subject** is postponed to facilitate the following step

### Assignment step 2: Extract only the measurements on the mean and standard deviation for each measurement

The indexes of the columns of interest, containing the string "mean" or "std", are obtained through

        subset_columns <- grep("mean|std", feature_names$feature_label)

These columns are then extracted from **full_dataset** in a new data frame

        partial_dataset <- full_dataset[, subset_columns]

**train_y**, **test_y**, **train_subject** and **test_subject** are now merged with **partial_dataset**, stacking them column or row wise.

        partial_dataset <- cbind(rbind(train_y, test_y), rbind(train_subject, test_subject), partial_dataset)

**partial_dataset** now contains:

* One row per observation of both the train and test sets.
* The activity index in column 1.
* The subject index in column 2.
* Next 561 columns are the respective features in X_\<folder\>.txt

### Assignment step 3: Use descriptive activity names to name the activities in the data set

The activity indexes and labels are read into the data frame **activity_labels**

        activity_labels <- read.table("activity_labels.txt", ...)

and ordered by activity index. The single variables in **train_y** and **test_y** were set of type factor in step 1 above. This allows assigning descriptive activity names easily through the factor levels.

        levels(partial_dataset$Activity)<-activity_labels$Activity_label


### Assignment step 4: Label the data set with descriptive variable names

The definition of "descriptive variable names" is ambiguous. After reading several posts on the Coursera discussion boards (see for instance https://www.coursera.org/learn/data-cleaning/peer/FIZtT/getting-and-cleaning-data-course-project/discussions/threads/eoUpRb-JEeW_UhLKov_F2Q) I have opted for the following actions:

* Replace ^t with Time
* Replace ^f with Frequency
* Eliminate ()
* Replace Acc with Acceleration
* Replace Mag with Magnitude
* Replace jerk with Jerk (for consistency)

This is accomplished by a series of calls to gsub(...). The first one

        names(partial_dataset)[3:length(names(partial_dataset))]<- gsub("^t", "Time", feature_names$feature_label[subset_columns])

also replaces the column names V1, V2, V3, etc in **partial_dataset** with the names read into **feature_names$feature_label** in step 1 above.

**partial_dataset** now contains:

* One row per observation of both the train and test sets.  
* The activity label in column 1.  
* The subject index in column 2.  
* Next 79 columns are the features in X_\<folder\>.txt whose name contains "mean" or "std", properly labeled.  

### Assignment step 5: Create an independent tidy data set with the average of each variable for each activity and each subject.

Citing David Hood's ["Getting & Cleaning Data: The Assignment"](https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/), there can be several interpretations to what "tidy" means in this case, as the problem to be studied is not defined. I have opted for a "wide" data set, with the interpretation that each row will be an observation corresponding to the average of the result from one "activity" performed by one "subject".

The combination of group_by() and summarise_all() from the dplyr package gives the desired result

        tidy_dataset <- partial_dataset %>% group_by(Activity, Subject) %>% summarise_all(funs(groupmean = mean))

The resulting data frame **tidy_dataset** is written to disk through

        write.table(tidy_dataset, file = "tidy_dataset.txt", col.names = TRUE)

**tidy_dataset** contains:

* One row per combination of activity (6) and subject (30), so 180 rows in total.  
* The activity label in column 1.  
* The subject index in column 2.  
* Next 79 columns are the average of the features in X_\<folder\>.txt whose name contains "mean" or "std", grouped by activity and subject.  

[^1]:The sub-folders "Inertial Signals" are not meaningful for this assignment, as noted in https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/