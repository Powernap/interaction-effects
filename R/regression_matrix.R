'create_regression_matrix' <- function(data, force_calculation = FALSE) {
  if (file.exists("vardumps/coefficient_matrix.Rdmped") && !force_calculation) {
    load(file = "vardumps/coefficient_matrix.Rdmped")
    return(coefficient_matrix)
  }
  # DEBUG
  data <- frame
  # /DEBUG
  # Get Class for each group
  variable_classes <- lapply(frame, class)
  variable_names <- colnames(data)
  # Create result matrix
  coefficient_matrix <- matrix(0, length(variable_names), length(variable_names))
  row.names(coefficient_matrix) <- variable_names
  colnames(coefficient_matrix) <- variable_names
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
          #model <- try(glm(formula = formula, family = "binomial", data = data), silent = TRUE)
          model <- try(glm(formula = formula, family = "binomial", data = data), silent = TRUE)
        # If binning fails, return null
        if(class(model) == "try-error") {
          message(paste0("'", formula, "' failed!"))
        } else {
          #coefficient <- model$coefficients[[2]]
          #coefficient_matrix[i,j] <- coefficient
          #coefficient_matrix[i,j] <- mean(resid(model))
          model_summary <- summary(model)
          if (current_dependent_class == 'numeric')
            coefficient_matrix[i,j] <- model_summary$r.squared
          else
            coefficient_matrix[i,j] <- fmsb::NagelkerkeR2(model)['R2'][[1]]

          #coefficient_matrix[i,j] <- mean(abs(residuals(model)))
          #if (current_dependent_class == 'numeric')
          #  coefficient_matrix[i,j] <- summary(model)$sigma
          #else
          #  coefficient_matrix[i,j] <- model$deviance
        }
      }
    }
  }
  save(list = c("coefficient_matrix"), file = "vardumps/coefficient_matrix.Rdmped")
  return(coefficient_matrix)
}

source("load_spine.R")

# Load the spine data set
frame <- load_spine()

regression_matrix <- create_regression_matrix(frame, force_calculation = F)
# Remove Entries from the regression matrix
remove <- c('Mean_Curvature', 'Mean_Torsion', 'Mean_Curvature_Coronal', 
            'Mean_Curvature_Transverse', 'Mean_Curvature_Sagittal', 'Curvature_Angle', 
            'Curvature_Angle_Coronal', 'Curvature_Angle_Sagittal', 'Curvature_Angle_Transverse')

regression_matrix <-regression_matrix[!rownames(regression_matrix) %in% remove, ]
regression_matrix <-regression_matrix[, !colnames(regression_matrix) %in% remove]