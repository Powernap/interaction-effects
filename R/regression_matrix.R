'create_regression_matrix' <- function(data, force_calculation = FALSE) {
  if (file.exists("vardumps/coefficient_matrix.Rdmped") && !force_calculation) {
    load(file = "vardumps/coefficient_matrix.Rdmped")
    return(coefficient_matrix)
  }
  # Get Class for each group
  variable_classes <- lapply(frame, class)
  variable_names <- colnames(data)
  # Create result matrix
  coefficient_matrix <- matrix(0, length(variable_names), length(variable_names))
  row.names(coefficient_matrix) <- variable_names
  colnames(coefficient_matrix) <- variable_names
  # Iterate over all variables
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
          coefficient <- model$coefficients[[2]]
          coefficient_matrix[i,j] <- coefficient
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

regression_matrix <- create_regression_matrix(frame)
ggplot2::qplot(x=Var1, y=Var2, data=reshape2::melt(regression_matrix), fill=value, geom="tile", xlab="dependent", ylab="independent") +
  ggplot2::scale_fill_gradient2(limits=c(min(regression_matrix), max(regression_matrix)))