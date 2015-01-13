'load_dataset' <- function (filepath) {
  data <- read.csv(filepath, header = TRUE)
  
}

# Goodness of fit 2D-Matrix: Dependent ~ Independent
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