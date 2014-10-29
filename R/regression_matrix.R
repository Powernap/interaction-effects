'create_goodness_of_fit_matrix_dependent' <- function(data, dependent = NA, force_calculation = FALSE) {
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
goodness_of_fit_matrix_gender <- create_goodness_of_fit_matrix_dependent(frame, dependent = "Gender", force_calculation = F)
# # Remove Entries from the regression matrix
# remove <- c('Mean_Curvature', 'Mean_Torsion', 'Mean_Curvature_Coronal', 
#             'Mean_Curvature_Transverse', 'Mean_Curvature_Sagittal', 'Curvature_Angle', 
#             'Curvature_Angle_Coronal', 'Curvature_Angle_Sagittal', 'Curvature_Angle_Transverse')

# goodness_of_fit_matrix <-goodness_of_fit_matrix[!rownames(goodness_of_fit_matrix) %in% remove, ]
# goodness_of_fit_matrix <-goodness_of_fit_matrix[, !colnames(goodness_of_fit_matrix) %in% remove]