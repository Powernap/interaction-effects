# Libaries necessary: fmsb
# load_dataset("/Users/paul/Desktop/patients-100k.csv")
# matrix <- r_squared_matrix(dependent = "gender")
pkg.env <- new.env()
pkg.env$data <- NA

'load_dataset' <- function (csv_filepath){ #, type_filepath) {
  #csv_filepath <- "/Users/paul/Tresors/Regresson Cubes/js-html/prototype/data/breast_fat.csv"
  #type_filepath <- "/Users/paul/Tresors/Regresson Cubes/js-html/prototype/data/dictionary.json"
  pkg.env$data <- read.csv(csv_filepath, header = TRUE)
  data <- read.csv(csv_filepath, header = TRUE)
  #   library(rjson)
  #   dictionary <- fromJSON(file = type_filepath)
  #   # Extract the variable types
  #   variable_types = c()
  #   variable_names <- names(data)
  #   for (i in 1:length(data)) {
  #     current_variable_name <- variable_names[[i]]
  #     current_variable_dict <- dictionary[[current_variable_name]]
  #     current_variable_type <- "factor"
  #     if (!is.null(current_variable_dict))
  #       if (current_variable_dict$type == "numerical")
  #         current_variable_type <- "numeric"
  #       else if (current_variable_dict$type == "ordinal" | current_variable_dict$type == "nominal")
  #         current_variable_type <- "factor"
  #       else if (current_variable_dict$type == "dichotomous")
  #         current_variable_type <- "logical"
  #     else
  #       print(paste0(current_variable_name, " has no dictionary entry"))
  #     variable_types <- c(variable_types, current_variable_type)
  #   }
  return(data)
}

'r_squared_matrix' <- function(data, dependent, force_calculation = FALSE) {
  # filename <- paste0("vardumps/goodness_of_fit_matrix_", dependent, ".Rdmped")
  # if (file.exists(filename) && !force_calculation) {
  #   load(file = filename)
  #   return(goodness_of_fit_matrix)
  # }
  # DEBUG
  #data <- frame
  # /DEBUG
  # Get Class for each group
  # data <- pkg.env$data
  variable_classes <- lapply(data, class)
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
  #save(list = c("goodness_of_fit_matrix"), file = filename)
  return(goodness_of_fit_matrix)
}