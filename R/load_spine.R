# Load the SHIP data if it does not exist
'load_spine.load' <- function() {
  # Constants
  CONSTANT.PATH_DARWIN <- "~/Sites/ship-tools/SHIP-Data/data/shipdata/SHIP_2013_combined/SHIP_2013_combined_image_trim_noumlauts.json"
  CONSTANT.PATH_LINUX <- "/home/paul/ship/ship-data/data/shipdata/SHIP_2013_combined/SHIP_2013_combined_image_trim_noumlauts.json"
  
  if (!(exists('ship_data'))) {
    if (Sys.info()['sysname'] == "Darwin") {
      ship_file_path <- CONSTANT.PATH_DARWIN
    } else {
      ship_file_path <- CONSTANT.PATH_LINUX
    }
    if (!file.exists("vardumps/ship_data_spine.Rdmped")) {
      cat('No SHIP Dataset dump found - Loading SHIP Dataset, this may take a few seconds ... ');
      load_spine.helper.load_and_dump_ship(path = ship_file_path)
    }
    else if (file.info(ship_file_path)$mtime > file.info("vardumps/ship_data_spine.Rdmped")$mtime) {
      cat('Newer SHIP Dataset found - Loading SHIP Dataset, this may take a few seconds ... ');
      load_spine.helper.load_and_dump_ship(path = ship_file_path)
    }
    cat('Loading SHIP Dataset dump ... ');
    load(file = "vardumps/ship_data_spine.Rdmped")
    ship_data <<- ship_data
  }
}

# define function read_json
'load_spine.helper.read_json' <- function(filepath) {
  # read json file
  json.file <- filepath;
  raw.json <- scan(json.file, what="raw()", sep="\n", encoding="MAC")
  
  # format json text to human-readable text
  json.data <- lapply(raw.json, function(x) jsonlite::fromJSON(x))
  
  # Return result
  return(json.data);
}

'load_spine.helper.load_and_dump_ship' = function(path) {
  ship_data_raw <- load_spine.helper.read_json(filepath = path);
  ship_data <- load_spine.helper.convert_dataset(ship_data_raw, replaceToZero=TRUE);
  cat('done!');
  cat('\nRebinning Pain Variables ...');
  ship_data <- load_spine.helper.fix_pain_scales(ship_data);
  cat(' done');
  cat('\nReplace IDs with dictionary values ...');
  ship_data <- load_spine.helper.replace_ids_with_dictionary_values(ship_data, ship_data_raw);
  cat(' done');
  cat('\nAdjust Pain Level Scales ...');
  ship_data <- load_spine.helper.adjust_level_scales(ship_data);
  cat(' done');
  cat('\nCreate BMI Variable ...');
  ship_data <- dplyr::mutate(.data = ship_data, BMI = Gewicht / (Groesse / 100)^2)
  cat(' done\n');
  # Create vardumps directory (only prints out a warning if the folder does not exist)
  dir.create("vardumps")
  save(list = c("ship_data"), file = "vardumps/ship_data_spine.Rdmped")
}

'load_spine.helper.convert_dataset' <- function(data, replaceErrorValues=TRUE, replaceToZero=TRUE) {
  if (replaceToZero) {
    set_these_to_zero = c('Ganzkoerperschwingungen_Dauer_Jahre', 'Schwerarbeit_Dauer_Jahre',
                          'Kinderanzahl', 'Anzahl_Zigaretten', 'Rueckenschmerz_Tageinaktiv', 
                          'Rueckenschmerz_3Monate_staerke')
  } else {
    set_these_to_zero = c()
  }
  
  set_these_to_NA = c('Mean_Curvature', 'Mean_Torsion', 'Mean_Curvature_Coronal', 
                      'Mean_Curvature_Transverse', 'Curvature_Angle', 
                      'Curvature_Angle_Coronal', 'Curvature_Angle_Transverse', 'Alter_Regelblutung',
                      'Alter_Beginn_Zigaretten')
  ignore_these = c('zz_nr', 'Alter_Ende_Zigaretten', 'GEBURTSTAG', 'Examine_date', 
                 'Alter_ende_Regelblutungen', 'Tailienumfang', 'BIA_KOERPERFETT_KORR_IN_KG', 
                 'LDL_Cholesterol', 'Examine_Location', 'HIV', 'Pankreatitis_chronisch', 
                 'Beruf', 'Andere_Beschwerden')
  elementList = list()
  elementNameList = list()
  for (i in 1:length(data[[1]])) {
    currentElement = data[[1]][i]
    currentElementName = currentElement[[1]]$name
    if (!(currentElementName %in% ignore_these)) {
      if (currentElement[[1]]$description$cohort == 'all') {
        elementNameList = c(elementNameList, currentElementName)
        elementList[[length(elementList) + 1]] <- c(as.vector(currentElement[[1]]$dataS2), as.vector(currentElement[[1]]$dataT0))
        
        if (replaceErrorValues) {# Remove Error Indicators
          if (currentElement[[1]]$description$dataType == 'ordinal' |
                currentElement[[1]]$description$dataType == 'dichotomous' |
                currentElement[[1]]$description$dataType == 'nominal') {
            
            if (currentElement[[1]]$name %in% set_these_to_zero) {
              elementList[[length(elementList)]][elementList[[length(elementList)]] > 997] <- 0 
            }
            else {
              elementList[[length(elementList)]][elementList[[length(elementList)]] > 997] <- NA
            }
          }
          else if (currentElement[[1]]$description$dataType == 'metric') {
            # Replace it with 0 or mean
            if (currentElement[[1]]$name %in% set_these_to_zero) {
              elementList[[length(elementList)]][elementList[[length(elementList)]] > 997] <- 0 
            }
            else if (currentElement[[1]]$name %in% set_these_to_NA) {
              elementList[[length(elementList)]][elementList[[length(elementList)]] > 997] <- NA 
            }
            else { # Replace with Mean
              meanNonError = mean(as.numeric(elementList[[length(elementList)]][elementList[[length(elementList)]] < 997]))
              elementList[[length(elementList)]][elementList[[length(elementList)]] > 997] <- meanNonError 
            }
          }
        }
        
        # Convert the Variable to the correct type
        if (currentElement[[1]]$description$dataType == 'ordinal') { # Make Ordered Factor
          elementList[[length(elementList)]] <- factor(elementList[[length(elementList)]], ordered = TRUE)
        }
        else if (currentElement[[1]]$description$dataType == 'metric') { # Make Numeric Variables
          elementList[[length(elementList)]] <- as.numeric(elementList[[length(elementList)]])
        }
      }
    }
  }
  data_as_frame = as.data.frame(elementList)
  colnames(data_as_frame) <- elementNameList
  
  return(data_as_frame)
}

'load_spine.helper.fix_pain_scales' <- function(ship_data) {
  variablesToFix <- c('Beeintraechtigung_Rueckenschmerz_3Monate', 'Schmerz_Beine', 'Schmerz_Fuesse');
  for (i in 1:length(ship_data)) { # Parse all Variables
    colname <- colnames(ship_data)[[i]];
    if (colname %in% variablesToFix) { # Parse all Entries
      # This is needed because the pain Indicators sort incorrectly the 10 as second factor
      ship_data[colname] <- factor(ship_data[colname][[1]], levels = c(0:10), ordered=TRUE);
      binnedVariable = c();
      for (j in 1:length(ship_data[colname][[1]])) {
        value <- ship_data[colname][[1]][[j]];
        newValue <- '0';
        if (is.na(value)) { newValue <- NA; }
        else {
          if (value < 1) { newValue <- 0; }
          if (value > 0 & value < 4) { newValue <- 1; }
          if (value > 3 & value < 7) { newValue <- 2; }
          if (value > 6) { newValue <- 3; }
        }
        binnedVariable = c(binnedVariable, newValue);
      }
      ship_data[colname] <- factor(binnedVariable, levels = c(0, 1, 2, 3), ordered=TRUE);
    }
  }
  return(ship_data);
}

'load_spine.helper.replace_ids_with_dictionary_values' <- function(ship_data, ship_data_raw, debug=FALSE) {
  ignore_these = c("Beeintraechtigung_Rueckenschmerz_3Monate", "Schmerz_Fuesse", "S2_SCHMERZ_02F",
                   "Schmerz_Beine", "T0_DIAB_01A", "Schilddruese_Ueberfunktion", "Schilddruese_andere",
                   "Schilddruese_Unterfunktion", "Schilddruese_Knoten", "Schilddruese_Struma",
                   "Rueckenschmerz_3Monate_staerke");
  new_ship <- ship_data;
  ship_data_names <- colnames(ship_data);
  for (i in 1:length(ship_data_names)) {
    currentName <- ship_data_names[[i]];
    if (!(currentName %in% ignore_these)) {
      currentRaw <- ship_data_raw[[1]][currentName];
      # Now replace Factor IDs with actual values
      if (currentRaw[[1]]$description$dataType == 'ordinal' |
            currentRaw[[1]]$description$dataType == 'dichotomous' |
            currentRaw[[1]]$description$dataType == 'nominal') {
        # Some custom Adjustments
        if (currentName == 'Schwerarbeit') {
          # Replace `3`values with two, because it encodes the same thing
          ship_data[currentName] <- plyr::revalue(ship_data[currentName][[1]], c(`3`=2));
        }
        dictionary <- currentRaw[[1]]$description$dictionary;
        numberOfElements <- length(levels(ship_data[currentName][[1]]));
        newDictionary <- dictionary[1:numberOfElements];
        new_ship[currentName][[1]] <- plyr::mapvalues(ship_data[currentName][[1]], from=levels(ship_data[currentName][[1]]), to=unlist(newDictionary));
        if (debug) {
          cat("Levels of "); print(currentName); print(levels(ship_data[currentName][[1]]));
          print(levels(new_ship[currentName][[1]]));
        }
      } # / Replace Factors
    }
  }
  return(new_ship);
}

'load_spine.helper.adjust_level_scales' <- function(ship_data) {
  # Adjust Levels of Pain Scales, which are wrong (usually '
  # "0"  "1"  "10" "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"')
  # Also Replaces NAs with 0
  adjust_these <- c('Rueckenschmerz_3Monate_staerke');
  for (i in 1:length(adjust_these)) {
    current_feature <- adjust_these[i];
    levels(ship_data[current_feature][[1]]) <- c('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10');
    ship_data[current_feature][[1]][is.na(ship_data[current_feature][[1]])] <- 0;
  }
  return(ship_data);
}