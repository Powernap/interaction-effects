# Goodness of fit Cube 3D: depdenent ~ independent1 + independent2 + independent3
'create_goodness_of_fit_cube' <- function(data, dependent, force_calculation = FALSE) {
  filename <- paste0("vardumps/cubes/cube_", dependent, ".Rdmped")
  filename_log <- paste0("vardumps/cubes/cube_", dependent, ".log")
  if (file.exists(filename) && !force_calculation) {
    load(file = filename)
    return(goodness_of_fit_matrix)
  }
  # Prepare logging
  connection_log <- file(filename_log, open = "wt")
  sink(connection_log, type = "message")
  
  variable_classes <- lapply(frame, class)
  variable_names <- colnames(data)
  # Create result matrix
  goodness_of_fit_matrix <- array(0, dim=c(length(variable_names), length(variable_names), length(variable_names)))
  dimnames(goodness_of_fit_matrix)[[1]] <- variable_names
  dimnames(goodness_of_fit_matrix)[[2]] <- variable_names
  dimnames(goodness_of_fit_matrix)[[3]] <- variable_names
  # Class of dependent variable
  dependent_class <- variable_classes[dependent]
  # Iterate over all variables
  for (i in 1:length(variable_names)) {
  #for (i in 1:3) {
    current_independent_variable1_name <- variable_names[[i]]
    # Iterate over all other variables
    for (j in 1:length(variable_names)) {
    #for (j in 1:3) {
      current_independent_variable2_name <- variable_names[[j]]
      # Iterate over all other variables
      for (k in 1:length(variable_names)) {
      #for (k in 1:3) {
        # No correlation of variables with each other
        if (i != j && i !=k) {
          current_independent_variable3_name <- variable_names[[k]]
          formula <- paste(dependent, "~", current_independent_variable1_name, '+', current_independent_variable2_name, '+', current_independent_variable3_name)
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
              goodness_of_fit_matrix[i,j,k] <- model_summary$r.squared
            }
            else
              goodness_of_fit_matrix[i,j,k] <- fmsb::NagelkerkeR2(model)['R2'][[1]]
          }
        }
      }
    }
    print(paste0("[", dependent, "] ", round((i + 1) / length(variable_names), digits=3) * 100, " % done"))
  }
  # Create Dir if neccessary (otherwise it only displays a warning that the folder already exists)
  dir.create(paste0("vardumps/cubes"))
  save(list = c("goodness_of_fit_matrix"), file = filename)
  
  unlink(connection_log)
  return(goodness_of_fit_matrix)
}

# Goodness of fit Matrix 2D: depdenent ~ independent1 + independent2
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

'helper.export_as_json' <- function(data, filename, pretty = TRUE) {
  # Create JSON Object
  data_as_json <- jsonlite::toJSON(data, pretty=pretty)
  sink(file = filename)
  print(data_as_json)
  sink()
}

'export_goodness_of_fit_cube_json' <- function(cube, dependent, pretty = FALSE) { 
  filename <- paste0("vardumps/cubes/cube_", dependent, ".json")
  dir.create("vardumps/cubes")
  helper.export_as_json(cube, filename = filename, pretty = pretty)
}

'export_goodness_of_fit_matrix_json' <- function(data, pretty = FALSE) {
  filename <- "vardumps/matrix_144x144x144_float.json"
  dimensions <- length(names(data))
  json_array <- array(0, dim=c(dimensions, dimensions, dimensions))
  count = 0
  for (variable_name in names(data)) {
    current_matrix <- create_goodness_of_fit_matrix_dependent(data = data, dependent = variable_name)
    #current_matrix[upper.tri(current_matrix)] <- 0
    current_matrix[current_matrix == '-Inf'] <- 0
    current_matrix <- round(current_matrix, digits=3)
    json_array[count,,] <- current_matrix
    count <- count + 1
  }
  helper.export_as_json(json_array, filename = filename, pretty = pretty)
}

'export_goodness_of_fit_matrix' <- function(data, as_binary = TRUE) {
  filename <- "vardumps/matrix_144x144x144_float.raw"
  result <- ''
  file_connection<-file(filename, "wb")
  for (variable_name in names(data)) {
    current_matrix <- create_goodness_of_fit_matrix_dependent(data = data, dependent = variable_name)
    current_matrix[upper.tri(current_matrix)] <- 0
    current_matrix[current_matrix == '-Inf'] <- 0
    current_matrix <- round(current_matrix, digits=3)
    print(paste0("[", variable_name, "] #Rows: ", nrow(current_matrix)[[1]], ", #Cols: ", ncol(current_matrix)[[1]], ", Min: ", min(current_matrix), ", Max: ", max(current_matrix)))
    current_data <- paste(current_matrix, sep = "", collapse = " ")
    if (result == '')
      result <- current_data
    else
      result <- c(result, current_data)
  }
  if (as_binary) {
    file_connection<-file(filename, "wb")
    writeBin(as.numeric(unlist(strsplit(result, split = " "))), file_connection, size = 4)
    close(file_connection)
  }
  else {
    file_connection<-file(filename)
    writeLines(result, file_connection, sep = " ")
    close(file_connection)
  }
  return(current_matrix)
}

# Creates regression Cubes for all Variables
'create_goodness_of_fit_cube_for_all_variables' <- function(data, process_number, number_of_cores) {
  # DEBUG
  # data <- frame
  # process_number <- 1
  # number_of_cores <- 8
  # / DEBUG
  number_of_variables <- length(names(data))
  number_of_steps <- round(number_of_variables / number_of_cores)
  start_count <- ((process_number - 1) * number_of_steps) + 1
  stop_count <- process_number * (number_of_steps)
  for (i in start_count:stop_count) {
    variable_name <- names(data)[i]
    print(paste0("[", i, '/', stop_count, '] Processing ', variable_name))
    cube <- create_goodness_of_fit_cube(data = data, dependent = variable_name)
    export_goodness_of_fit_cube_json(cube = cube, dependent = variable_name, pretty = FALSE)
  }
}

## Creates Vardumps for all Variable Combinations
'create_goodness_of_fit_matrix_for_all_variables' <- function(data) {
  number_of_variables <- length(names(data))
  count <- 0
  for (variable_name in names(data)) {
    count <- count + 1
    print(paste0("[", count, '/', number_of_variables, '] Processing ', variable_name))
    create_goodness_of_fit_matrix_dependent(data = data, dependent = variable_name)
  }
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

source("load_spine.R")

# Load the spine data set
frame <- load_spine()

goodness_of_fit_matrix <- create_goodness_of_fit_matrix(frame, force_calculation = F)
#create_goodness_of_fit_matrix_for_all_variables(data=frame)
#export_goodness_of_fit_cube_json(cube = create_goodness_of_fit_cube(data = frame, dependent = "Gender"), dependent="Gender", pretty = FALSE)
#create_goodness_of_fit_cube_for_all_variables(data = frame, process_number = 1, number_of_cores = 8)