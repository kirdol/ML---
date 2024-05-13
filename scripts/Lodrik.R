data <- fread(here::here("data", "Vehicle MPG - 1984 to 2023.csv"))

install.packages("tidyverse") # For data manipulation and visualization
install.packages("data.table") # For fast data manipulation
install.packages("caret") # For machine learning
install.packages("keras") # For neural networks

library(tidyverse)
library(data.table)
library(caret)
library(keras)

# Drop the 'Model' column
data_dropped <- data[, .(Model = NULL)]

# Check for missing values
missing_data_summary <- sapply(data_dropped, function(x) sum(is.na(x)))

# Drop specified columns
data_cleaned <- data_dropped[, .(Fuel_Type_2 = NULL, Engine_Description = NULL)]

# Fill missing values for numerical columns with their median
num_cols <- c('Engine_Cylinders', 'Engine_Displacement')
data_cleaned[, (num_cols) := lapply(.SD, function(x) ifelse(is.na(x), median(x, na.rm = TRUE), x)), .SDcols = num_cols]

# Drop rows with any remaining missing values
data_cleaned <- na.omit(data_cleaned)

# Check again for missing values to ensure a clean dataset
final_missing_data_summary <- sapply(data_cleaned, function(x) sum(is.na(x)))

# Select categorical columns for one-hot encoding
categorical_columns <- c('Make', 'Fuel_Type_1', 'Drive', 'Transmission', 'Vehicle_Class')
data_cleaned <- data_cleaned %>%
  mutate(across(all_of(categorical_columns), as.factor)) %>%
  mutate(dummy = model.matrix(~ . - 1, data = .))

# Normalize numeric columns
numeric_columns <- setdiff(names(data_cleaned), c(categorical_columns, 'dummy'))
preProcValues <- preProcess(data_cleaned[, ..numeric_columns], method = c("center", "scale"))
data_cleaned[, ..numeric_columns] <- predict(preProcValues, data_cleaned[, ..numeric_columns])

set.seed(42)
trainIndex <- createDataPartition(data_cleaned$Make, p = .8, list = FALSE, times = 1)
train_data <- data_cleaned[trainIndex, ]
test_data <- data_cleaned[-trainIndex, ]

# Assuming 'Make' is a categorical outcome
Y_train <- to_categorical(as.numeric(train_data$Make))
Y_test <- to_categorical(as.numeric(test_data$Make))
model <- keras_model_sequential() %>%
  layer_dense(units = 128, activation = 'relu', input_shape = c(ncol(train_data) - 1)) %>%
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dense(units = ncol(Y_train), activation = 'softmax')

# Compile the model
compile(model, loss = 'categorical_crossentropy', optimizer = 'adam', metrics = 'accuracy')

# Train the model
history <- fit(model, as.matrix(train_data[, -ncol(train_data)]), Y_train, epochs = 10, validation_split = 0.2, batch_size = 32)

# Plot training & validation accuracy values
plot(history)


```{r} Missing values by vehicle class
# Check for missing values in the 'Drive' column
missing_drive <- data_cleaning %>% filter(is.na(Drive))

# Count the missing values per vehicle class
missing_counts <- missing_drive %>% count(Vehicle.Class)

# Get total counts per vehicle class in the entire dataset
total_counts <- data_cleaning %>% count(Vehicle.Class)

# Calculate the percentage of missing 'Drive' values per vehicle class
percentage_missing <- missing_counts %>% 
  left_join(total_counts, by = "Vehicle.Class", suffix = c(".missing", ".total")) %>%
  mutate(PercentageMissing = (n.missing / n.total))

# Print the summary dataframe
datatable(percentage_missing,
          options = list(pageLength = 6,
                         class = "hover",
                         searchHighlight = TRUE),
          rownames = FALSE)%>%
  formatPercentage("PercentageMissing", 2)
```

