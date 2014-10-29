'create_goodness_of_fit_matrix_dependent' <- function(data, dependent, force_calculation = FALSE) {
  filename <- paste0("vardumps/goodness_of_fit_matrix_", dependent, ".Rdmped")
  if (file.exists(filename) && !force_calculation) {
    load(file = filename)
    return(goodness_of_fit_matrix)
  }
  # DEBUG
  #data <- frame
  # /DEBUG
  # Get Class for each group
  variable_classes <- lapply(frame, class)
  variable_names <- colnames(data)
  # Create result matrix
  goodness_of_fit_matrix <- matrix(0, length(variable_names), length(variable_names))
  row.names(goodness_of_fit_matrix) <- variable_names
  colnames(goodness_of_fit_matrix) <- variable_names
  # Class of dependent variable
  dependent_class <- variable_classes[dependent]
  # Iterate over all variables
  #for (i in 2:2) {
  for (i in 1:length(variable_names)) {
    current_independent_variable1_name <- variable_names[[i]]
    # Iterate over all other variables
    for (j in 1:length(variable_names)) {
      # No correlation of variables with each other
      if (i != j) {
        current_independent_variable2_name <- variable_names[[j]]
        formula <- paste(dependent, "~", current_independent_variable1_name, '+', current_independent_variable2_name)
        # If current class is numeric, apply Linear Regression
        if (dependent_class == 'numeric')
          model <- try(lm(formula = formula, data = data), silent = TRUE)
        else
          model <- try(glm(formula = formula, family = "binomial", data = data), silent = TRUE)
        # If binning fails, return null
        if(class(model) == "try-error") {
          message(paste0("'", formula, "' failed!"))
        } else {
          #coefficient <- model$coefficients[[2]]
          if (dependent_class == 'numeric') {
            model_summary <- summary(model)
            goodness_of_fit_matrix[i,j] <- model_summary$r.squared
          }
          else
            goodness_of_fit_matrix[i,j] <- fmsb::NagelkerkeR2(model)['R2'][[1]]
        }
      }
    }
  }
  save(list = c("goodness_of_fit_matrix"), file = filename)
  return(goodness_of_fit_matrix)
}

'export_goodness_of_fit_matrix' <- function(data) {
  filename <- paste0("vardumps/matrix.raw")
  result <- ''
  debug_names <- c('Gender', 'bronchitis', 'diabetes_treatment', 'gout', 'posuture_work')
  #for (variable_name in names(data)) {
  for (variable_name in debug_names) {
    current_matrix <- create_goodness_of_fit_matrix_dependent(data = data, dependent = variable_name)
    current_data <- paste(current_matrix, sep=",")
    if (result == '')
      result <- current_data
    else
      result <- c(result, current_data)
  }
  # Write result
  file_connection<-file(filename)
  writeLines(result, file_connection)
  close(file_connection)
}

## Creates Vardumps for all Variable Combinations
'create_goodness_of_fit_matrix_for_all_variables' <- function(data) {
  number_of_variables <- length(names(data))
  count <- 0
  for (variable_name in names(data)) {
    count <- count + 1
    print(paste0("[", count, '/', number_of_variables, ']Processing ', variable_name))
    create_goodness_of_fit_matrix_dependent(data = data, dependent = variable_name)
  }
}

'create_goodness_of_fit_matrix' <- function(data, force_calculation = FALSE) {
  if (file.exists("vardumps/goodness_of_fit_matrix.Rdmped") && !force_calculation) {
    load(file = "vardumps/goodness_of_fit_matrix.Rdmped")
    return(goodness_of_fit_matrix)
  }
  # DEBUG
  #data <- frame
  # /DEBUG
  # Get Class for each group
  variable_classes <- lapply(frame, class)
  variable_names <- colnames(data)
  # Create result matrix
  goodness_of_fit_matrix <- matrix(0, length(variable_names), length(variable_names))
  row.names(goodness_of_fit_matrix) <- variable_names
  colnames(goodness_of_fit_matrix) <- variable_names
  # Iterate over all variables
  #for (i in 2:2) {
  for (i in 1:length(variable_names)) {
    current_dependent_variable_name <- variable_names[[i]]
    current_dependent_class <- variable_classes[current_dependent_variable_name]
    # Iterate over all other variables
    for (j in 1:length(variable_names)) {
      # No correlation of variables with each other
      if (i != j) {
        current_independent_variable_name <- variable_names[[j]]
        current_independent_class <- variable_classes[current_independent_variable_name]
        formula <- paste(current_dependent_variable_name, "~", current_independent_variable_name)
        # If current class is numeric, apply Linear Regression
        if (current_dependent_class == 'numeric')
          model <- try(lm(formula = formula, data = data), silent = TRUE)
        else
          model <- try(glm(formula = formula, family = "binomial", data = data), silent = TRUE)
        # If binning fails, return null
        if(class(model) == "try-error") {
          message(paste0("'", formula, "' failed!"))
        } else {
          #coefficient <- model$coefficients[[2]]
          if (current_dependent_class == 'numeric') {
            model_summary <- summary(model)
            goodness_of_fit_matrix[i,j] <- model_summary$r.squared
          }
          else
            goodness_of_fit_matrix[i,j] <- fmsb::NagelkerkeR2(model)['R2'][[1]]
        }
      }
    }
  }
  save(list = c("goodness_of_fit_matrix"), file = "vardumps/goodness_of_fit_matrix.Rdmped")
  return(goodness_of_fit_matrix)
}

source("load_spine.R")

# Load the spine data set
frame <- load_spine()

goodness_of_fit_matrix <- create_goodness_of_fit_matrix(frame, force_calculation = F)
#create_goodness_of_fit_matrix_for_all_variables(data=frame)