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
      cat('No SHIP Dataset dump found - Loading SHIP Dataset, this may take a few seconds ... ')
      load_spine.helper.load_and_dump_ship(path = ship_file_path)
    }
    else if (file.info(ship_file_path)$mtime > file.info("vardumps/ship_data_spine.Rdmped")$mtime) {
      cat('Newer SHIP Dataset found - Loading SHIP Dataset, this may take a few seconds ... ')
      load_spine.helper.load_and_dump_ship(path = ship_file_path)
    }
    cat('Loading SHIP Dataset dump ... ')
    load(file = "vardumps/ship_data_spine.Rdmped")
    ship_data <<- ship_data
    ship_data_image <<- ship_data_image
  }
}

# define function read_json
'load_spine.helper.read_json' <- function(filepath) {
  # read json file
  json.file <- filepath
  raw.json <- scan(json.file, what="raw()", sep="\n", encoding="MAC")
  
  # format json text to human-readable text
  json.data <- lapply(raw.json, function(x) jsonlite::fromJSON(x))
  
  # Return result
  return(json.data)
}

'load_spine.helper.load_and_dump_ship' = function(path) {
  ship_data_raw <- load_spine.helper.read_json(filepath = path)
  ship_data <- load_spine.helper.convert_dataset(ship_data_raw, replaceToZero=TRUE)
  cat('done!')
  cat('\nRebinning Pain Variables ...')
  ship_data <- load_spine.helper.fix_pain_scales(ship_data)
  cat(' done')
  cat('\nReplace IDs with dictionary values ...')
  ship_data <- load_spine.helper.replace_ids_with_dictionary_values(ship_data, ship_data_raw)
  cat(' done')
  cat('\nAdjust Pain Level Scales ...')
  ship_data <- load_spine.helper.adjust_level_scales(ship_data)
  cat(' done')
  cat('\nCreate BMI Variable ...')
  ship_data <- dplyr::mutate(.data = ship_data, BMI = Gewicht / (Groesse / 100)^2)
  cat(' done')
  cat('\nRename manifestations and dimensions ...')
  ship_data <- load_spine.helper.rename_manifestations(ship_data)
  ship_data <- load_spine.helper.rename_dimensions(ship_data)
  ship_data_image <- subset(ship_data, !(is.na(Curvature_Angle)))
  cat(' done\n')
  # Create vardumps directory (only prints out a warning if the folder does not exist)
  dir.create("vardumps")
  save(list = c("ship_data", "ship_data_image"), file = "vardumps/ship_data_spine.Rdmped")
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
  variablesToFix <- c('Beeintraechtigung_Rueckenschmerz_3Monate', 'Schmerz_Beine', 'Schmerz_Fuesse')
  for (i in 1:length(ship_data)) { # Parse all Variables
    colname <- colnames(ship_data)[[i]]
    if (colname %in% variablesToFix) { # Parse all Entries
      # This is needed because the pain Indicators sort incorrectly the 10 as second factor
      ship_data[colname] <- factor(ship_data[colname][[1]], levels = c(0:10), ordered=TRUE)
      binnedVariable = c()
      for (j in 1:length(ship_data[colname][[1]])) {
        value <- ship_data[colname][[1]][[j]]
        newValue <- '0'
        if (is.na(value)) { newValue <- NA }
        else {
          if (value < 1) { newValue <- 0 }
          if (value > 0 & value < 4) { newValue <- 1 }
          if (value > 3 & value < 7) { newValue <- 2 }
          if (value > 6) { newValue <- 3 }
        }
        binnedVariable = c(binnedVariable, newValue)
      }
      ship_data[colname] <- factor(binnedVariable, levels = c(0, 1, 2, 3), ordered=TRUE)
    }
  }
  return(ship_data)
}

'load_spine.helper.replace_ids_with_dictionary_values' <- function(ship_data, ship_data_raw, debug=FALSE) {
  ignore_these = c("Beeintraechtigung_Rueckenschmerz_3Monate", "Schmerz_Fuesse", "S2_SCHMERZ_02F",
                   "Schmerz_Beine", "T0_DIAB_01A", "Schilddruese_Ueberfunktion", "Schilddruese_andere",
                   "Schilddruese_Unterfunktion", "Schilddruese_Knoten", "Schilddruese_Struma",
                   "Rueckenschmerz_3Monate_staerke")
  new_ship <- ship_data
  ship_data_names <- colnames(ship_data)
  for (i in 1:length(ship_data_names)) {
    currentName <- ship_data_names[[i]]
    if (!(currentName %in% ignore_these)) {
      currentRaw <- ship_data_raw[[1]][currentName]
      # Now replace Factor IDs with actual values
      if (currentRaw[[1]]$description$dataType == 'ordinal' |
            currentRaw[[1]]$description$dataType == 'dichotomous' |
            currentRaw[[1]]$description$dataType == 'nominal') {
        # Some custom Adjustments
        if (currentName == 'Schwerarbeit') {
          # Replace `3`values with two, because it encodes the same thing
          ship_data[currentName] <- plyr::revalue(ship_data[currentName][[1]], c(`3`=2))
        }
        dictionary <- currentRaw[[1]]$description$dictionary
        numberOfElements <- length(levels(ship_data[currentName][[1]]))
        newDictionary <- dictionary[1:numberOfElements]
        new_ship[currentName][[1]] <- plyr::mapvalues(ship_data[currentName][[1]], from=levels(ship_data[currentName][[1]]), to=unlist(newDictionary))
        if (debug) {
          cat("Levels of ")
          print(currentName)
          print(levels(ship_data[currentName][[1]]))
          print(levels(new_ship[currentName][[1]]))
        }
      } # / Replace Factors
    }
  }
  return(new_ship)
}

'load_spine.helper.adjust_level_scales' <- function(ship_data) {
  # Adjust Levels of Pain Scales, which are wrong (usually '
  # "0"  "1"  "10" "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"')
  # Also Replaces NAs with 0
  adjust_these <- c('Rueckenschmerz_3Monate_staerke')
  for (i in 1:length(adjust_these)) {
    current_feature <- adjust_these[i]
    levels(ship_data[current_feature][[1]]) <- c('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
    ship_data[current_feature][[1]][is.na(ship_data[current_feature][[1]])] <- 0
  }
  return(ship_data)
}

'load_spine.helper.rename_manifestations' <- function(data) {
  levels(data$SEX) <- c("1 - male", "2 - female")
  levels(data$Schwerarbeit) <- c("1 - Yes", "2 - No")
  levels(data$Ganzkoerperschwingungen) <- c("1 - Yes", "2 - No")
  levels(data$Sport_Winter) <- c("1 - Regularly more than 2 hours per week", "2 - Regularly 1 to 2 hours per week", "3 - Less than 1 hour per week", "4 - No exercise")
  levels(data$Sport_Sommer) <- c("1 - Regularly more than 2 hours per week", "2 - Regularly 1 to 2 hours per week", "3 - Less than 1 hour per week", "4 - No exercise")
  levels(data$Haltung_Hautpbeschaeftigung) <- c("1 - mostly sitting", "2 - mostly standing", "3 - mostly in motion", "4 - equal sitting, standing and in motion")
  levels(data$Gallenblasensteine) <- c("1 - Yes", "2 - No")
  levels(data$Thrombose_Krampfadern_Venenentzuendung) <- c("1 - Yes", "2 - No")
  levels(data$Nierenerkrankung) <- c("1 - Yes", "2 - No")
  levels(data$Dialyse) <- c("1 - Yes", "2 - No")
  levels(data$Gelenkverschleiss) <- c("1 - Yes", "2 - No")
  levels(data$Abnutzungserscheinungen_Wirbelsaule) <- c("1 - Yes", "2 - No")
  levels(data$Gelenkerkrankung) <- c("1 - Yes", "2 - No")
  levels(data$Osteoporose) <- c("1 - Yes", "2 - No")
  levels(data$Leberzirrhose) <- c("1 - Yes", "2 - No")
  levels(data$Fettleber) <- c("1 - Yes", "2 - No")
  levels(data$Gallenblasenentzuendung) <- c("1 - Yes", "2 - No")
  levels(data$Erhoehtes_Blutfett) <- c("1 - Yes", "2 - No")
  levels(data$Gicht) <- c("1 - Yes", "2 - No")
  levels(data$Bronchitis) <- c("1 - Yes", "2 - No")
  levels(data$Diabetis) <- c("1 - Yes", "2 - No")
  levels(data$Diabetis_Behandlung) <- c("1 - only dietetic", "2 - only with tablet", "3 - only with insulin", "4 - with insulin and tablets", "5 - no treatment")
  levels(data$Bereits_Schwanger) <- c("1 - Yes", "2 - No")
  levels(data$Hormonersatztherapie) <- c("1 - Yes", "2 - No")
  levels(data$Bereits_Regelblutungen) <- c("1 - Yes", "2 - No")
  levels(data$Blutdruck_hoch) <- c("1 - Yes", "2 - No")
  levels(data$Blutdruck_hoch_medikamente) <- c("1 - Yes", "2 - No")
  levels(data$Lungenerkrankung) <- c("1 - Yes", "2 - No")
  levels(data$Schilddruesenerkrankung) <- c("1 - Yes", "2 - No")
  levels(data$Schilddruese_Ueberfunktion) <- c("-1", "0")
  levels(data$Schilddruese_Unterfunktion) <- c("-1", "0")
  levels(data$Schilddruese_Struma) <- c("-1", "0")
  levels(data$Schilddruese_Knoten) <- c("-1", "0")
  levels(data$Schmerzen_7Tage) <- c("1 - Yes", "2 - No")
  levels(data$Rueckenschmerz_3Monate) <- c("1 - Yes", "2 - No")
  levels(data$Rueckenschmerz_3Monate_staerke) <- c("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10")
  levels(data$Vorzeitiger_Ruhestand_Grund) <- c("1 - reaching retirement age", "2 - health reasons", "3 - voluntary early", "4 - involuntary early of other reasons", "5 - involuntary early because of the company")
  levels(data$Einkommen) <- c("1 - Below 500 Euro", "2 - 500 - 900 Euro", "3 - 900 - 1300 Euro", "4 - 1300 - 1800 Euro", "5 - 1800 - 2300 Euro", "6 - 2300 - 2800 Euro", "7 - 2800 - 3300 Euro", "8 - 3300 - 3800 Euro", "9 - 3800 Euro and more")
  levels(data$Rueckenschmerz_Sozialprobleme) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Nacken_Schulterschmerzen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Gelenk_Gliederschmerzen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Haeufigkeit_Alkohol_12Monate) <- c("1 - never", "2 - 1 time a month or less", "3 - 2-4 times a month", "4 - 2-3 times a week", "5 - 4 or more times a week")
  levels(data$Wenn_Alkohol_wie_viel) <- c("1 - 1-2 drinks", "2 - 3-4 drinks", "3 - 5-6 drinks", "4 - 7-9 drinks", "5 - 10 or more drinks")
  levels(data$Pankreatitis) <- c("1 - Yes", "2 - No")
  levels(data$Hepatitis) <- c("1 - Yes", "2 - No")
  levels(data$Ernaehrung_Fleisch) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - About once a month or less", "6 - Never or almost never")
  levels(data$Ernaehrung_Wurst) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Fisch) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Kartoffeln) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Pommes) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Teigwaren) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Reis) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Gemuese) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Gemuese_gekocht) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Obst) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Brot) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Muesli) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Eier) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Kuchen) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Suesswaren) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Ernaehrung_Knabbereien) <- c("1 - Daily or almost daily", "2 - Several times a week", "3 - About once a week", "4 - Several times a month", "5 - Etwa einmal im Monat oder seltener", "6 - Never or almost never")
  levels(data$Herzinsuffizienz) <- c("1 - Yes", "2 - No")
  levels(data$Schilddruese_andere) <- c("-1", "0")
  levels(data$Familienstand) <- c("1 - Married, living with spouse", "2 - Married, living separated from spouse", "3 - Single, never married", "4 - divorced", "5 - widowed")
  levels(data$Zusammenleben_Partner) <- c("1 - Yes", "2 - No")
  levels(data$HepatitisB) <- c("0 - No", "1 - Yes")
  levels(data$HepatitisC) <- c("0 - No", "1 - Yes")
  levels(data$Akne) <- c("1 - Yes", "2 - No")
  levels(data$Hypotonie) <- c("1 - Yes", "2 - No")
  levels(data$Harnwegserkrankung) <- c("1 - Yes", "2 - No")
  levels(data$Parkinson) <- c("1 - Yes", "2 - No")
  levels(data$Andere_Krankheiten) <- c("1 - Yes", "2 - No")
  levels(data$Schmerz_Beine) <- c("0", "1", "2", "3")
  levels(data$Schmerz_Fuesse) <- c("0", "1", "2", "3")
  levels(data$Beeintraechtigung_Rueckenschmerz_3Monate) <- c("0", "1", "2", "3")
  levels(data$Rueckenschmerzen_Ausstrahlung) <- c("1 - No", "2 - Yes, Radiating to the buttocks, the groin or hips", "3 - Yes, Radiating to the thigh (to the knee)", "4 - Yes, Radiating to the lower leg")
  levels(data$Klossgefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Kurzatmig) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schwaechegefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schluckbeschwerden) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schmerz_Brust) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Voellegefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Mattigkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Ueblkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Aufstossen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Reizbarkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Gruebelei) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schwitzen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Innere_Unruhe) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schweregefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Unruhe_Beine) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Waerme_Ueberempfindlichkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Kaelte_Ueberempfindlichkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Hohes_Schlafbeduerfnis) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schlaflosigkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Schwindelgefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Zittern) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Gewichtabnahme) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Kopfschmerzen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Muedigkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Atemnot) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Erstickungsgefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Herzklopfen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Angstgefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Leibschmerzen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Ernergielosigkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Konzentrationsschwaeche) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Hitzewallungen) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Gespanntheit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Taubheitsgefuehl) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Wetterfuehligkeit) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Hoerbeschwerden) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  levels(data$Depression) <- c("1 - not at all", "2 - hardly", "3 - moderately", "4 - strong")
  return (data)
}

'load_spine.helper.rename_dimensions' <- function(data) {
  dims <- c("Gender", "Age", "hard_working", "hard_working_years", "Whole_body_vibration", "Whole_body_vibration_years", "Sport_Winter", "Sport_Summer", "posuture_work", "Gallbladder_stones", "thrombosis", "kidney_disease", "dialysis", "joint_degeneration", "spine_abrasion", "joint_disease", "osteoporosis", "liver_cirrhosis", "fatty_liver", "cholecystitis", "Increased_blood_lipid", "gout", "bronchitis", "diabetes", "diabetes_treatment", "already_pregnant", "number_of_children", "age_menstrual_period", "Hormone_replacement_therapy", "already_menstrual_period", "high_blood_pressure", "high blood pressure_medication", "pulmonary_disease", "thyroid_disease", "Hyperthyroidism", "Hypothyroidism", "thyroid_goiter", "thyroid_nodules", "pain_last_7_days", "back_pain_last_3_month", "back_pain_last_3_month_intensity", "early_retirement_reason", "income", "body_fat_percent", "size", "weight", "hip_size", "back_pain_induced_social_problems", "neck_shoulder_pain", "joint_limb_pain", "frequency_of_alcohol_last_year", "If_alcohol_how_much", "pancreatitis", "hepatitis", "nutrition_meat", "nutrition_sausage", "nutrition_fish", "nutrition_potatoes", "nutrition_French", "nutrition_pasta", "nutrition_rice", "nutrition_vegetables", "nutrition_Gemuese_gekocht", "nutrition_fruit", "nutrition_bread", "nutrition_Muesli", "nutrition_eggs", "nutrition_cake", "nutrition_confectionery products ", "nutrition_munchies", "heart_failure", "number_of_cigarettes", "age_started_smoking", "other_thyroid_disease", "marital_status", "living_with_partner", "HBA1C", "triglycerides", "cholesterol", "hdl_cholesterol", "ALAT_S", "ASAT_S", "AMYL_S", "GGT_S", "LIP_S", "hepatitis_B", "Hepatitis_C", "acne", "hypotension", "uropathy", "Parkinson", "other_diseases", "pain_legs", "pain_feet", "inactive_days_due_to_back_pain", "impairment_by_backpain_3_month", "radiating_backpain", "Globus", "short_winded", "weakness", "sip_complain", "pain_chest", "bloating", "languor", "nausea", "burping", "irritability", "brooding", "sweating", "internal_unrest", "heaviness", "restlessness_legs", "heat_hypersensitive", "cold_hypersensitive", "high_need_for_sleep", "insomnia", "vertigo", "tremor", "loss_in_weight", "headache", "tiredness", "difficulty_in_breathing", "suffocation", "palpitation", "anxiety", "abdominal_pain", "anergy", "attentiveness_disorder", "hot_flashes", "tension", "numbness", "meteorosensitivity", "hearing_problems", "depression", "Mean_Curvature", "Mean_Torsion", "Mean_Curvature_Coronal", "Mean_Curvature_Sagittal", "Mean_Curvature_Transverse", "Curvature_Angle", "Curvature_Angle_Sagittal", "Curvature_Angle_Coronal", "Curvature_Angle_Transverse", "BMI")
  colnames(data) <- dims
  return(data)
}