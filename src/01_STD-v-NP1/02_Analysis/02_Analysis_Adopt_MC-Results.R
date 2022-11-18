# Analyze Simulation Results
#   Adoption Decision
#   Monte Carlo Simulation Output
#   Produce a display table for Cost-Effectiveness Results. 
#       - Expressed Incrementally, and using net-benefits, at 20K/30K.
#       - Output 1: Base Case (Female, Age 60)
#       - Output 2: All Scenarios

# Import Data ==================================================================
simResult <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "01_STD-v-NP1", 
                                              "MC-Sim.rds"))

# Analyses =====================================================================
## Incremental Analysis --------------------------------------------------------
library(HEEToolkit)

IA.BC <- inc_analysis(data = simResult[,,,"Female","60"], 
                      effect_measure = "QALYs")

IA.SA <- lapply(X = c("40" = "40", 
                      "60" = "60", 
                      "80" = "80"), 
                FUN = \(age){
                  lapply(X = c(Male = "Male", 
                               Female = "Female"), 
                         FUN = \(sex){
                           inc_analysis(data = simResult[,,,sex,age])
                         })
                })

## Net-Benefits Framework, (NMB) -----------------------------------------------
NB.BC <- nb_analysis(data = simResult[,,,"Female","60"], 
                     lambda = c(20000, 30000), 
                     effect_measure = "QALYs", 
                     nbType = "NMB", 
                     show.error = TRUE)

NB.SA <- lapply(X = c("40" = "40", 
                      "60" = "60", 
                      "80" = "80"), 
                FUN = \(age){
                  lapply(X = c(Male = "Male", 
                               Female = "Female"), 
                         FUN = \(sex){
                           nb_analysis(data = simResult[,,,sex,age], 
                                       lambda = c(20000, 30000), 
                                       effect_measure = "QALYs", 
                                       nbType = "NMB", 
                                       show.error = TRUE)
                         })
                })

# Build Display Table ==========================================================
## Base Case: Female, Age 60 ---------------------------------------------------
### Wrangle Input Data to Correct Format
####  - Coerce both output to data frames/tbls. 
####  - Add NA to P(Error) in rows which do not have max P(CE). 

for (i in seq_along(1:dim(NB.BC)[3])) {
  j <- which.max(x = NB.BC[,"eNB",i])
  NB.BC[-j,"p_error",i] <- NA
}

DF4tbl <- cbind(as.data.frame(IA.BC), 
                as.data.frame(NB.BC))
### Set Table
library(gt)
BC.tab <- 
  gt(data = DF4tbl, rownames_to_stub = TRUE) |> 
  tab_stubhead(label = "j") |> 
  tab_footnote(footnote = paste("STD: Standard Prosthesis", 
                                "NP1: New Prosthesis 1", 
                                sep = ", "), 
               locations = cells_stubhead())

### Format: Assign Dominance/Extended Dominance Labels
BC.tab <- 
  BC.tab |> 
  sub_missing(columns = "ICER", 
              rows = Dom == 1, missing_text = "D") |> 
  sub_missing(columns = "ICER", 
              rows = ExtDom == 1, missing_text = "ED") |> 
  sub_missing(columns = "ICER", 
              rows = (Dom == 0) & (ExtDom == 0), missing_text = "---") |> 
  tab_footnote(footnote = "D: Dominanted", 
               locations = cells_body(columns = c(ICER), 
                                      rows = Dom == 1), 
               placement = "right") |> 
  tab_footnote(footnote = "ED: Extendedly Dominanted", 
               locations = cells_body(columns = c(ICER), 
                                      rows = ExtDom == 1), 
               placement = "right") |> 
  cols_hide(columns = contains("Dom"))

### Format: Net-Benefit Results
BC.tab <- 
  BC.tab |>
  sub_missing(columns = contains("p_error"), 
              rows = everything(), 
              missing_text = "---") |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "20000/QALY"), 
              columns = contains("20000")) |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "30000/QALY"), 
              columns = contains("30000")) |> 
  cols_label("eNB.20000" = "NMB", 
             "eNB.30000" = "NMB", 
             "prob_CE.20000" = "P(CE)", 
             "prob_CE.30000" = "P(CE)", 
             "p_error.20000" = "P(Error)", 
             "p_error.30000" = "P(Error)")

### Format: Currency & Numbers
BC.tab <- 
  BC.tab |> 
  fmt_currency(columns = c("Costs", 
                           "ICER", 
                           contains("NB")), currency = "GBP") |> 
  fmt_number(columns = c(contains(match = "LY"), 
                         contains(match = "prob"), 
                         contains(match = "error")), decimals = 2)

### Add Title & Sub-Title
BC.tab <- 
  BC.tab |> 
  tab_header(title = "THR Model Cost-Effectiveness Results", 
             subtitle = "Monte Carlo Simulation, Base Case: Female, Age 60")

### Modify Table Theme
BC.tab <- 
  BC.tab |> 
  tab_style(style = cell_text(weight = "bold", align = "center"), 
            locations = cells_column_labels(columns = everything())) |> 
  tab_style(style = cell_text(style = "italic", weight = "bold", align = "right"), 
            locations = cells_stubhead()) |> 
  tab_style(style = cell_text(align = "center"), 
            locations = cells_body()) |> 
  tab_style(style = cell_text(align = "left", weight = "bold"), 
            locations = list(cells_title(groups = "title"), 
                             cells_title(groups = "subtitle"))) |> 
  tab_options(table.border.bottom.color = "black", 
              table.border.top.color = "black")

## All Scenarios ---------------------------------------------------------------
### Wrangle Input Data to Correct Format
Age <- c("40" = "40", "60" = "60", "80" = "80")
Gender <- c(Male = "Male", Female = "Female")

for (a in seq_along(Age)) {
  for (g in seq_along(Gender)) {
    for (i in seq_along(c(1,2))) {
      j <- which.max(x = NB.SA[[a]][[g]][,"eNB",i])
      NB.SA[[a]][[g]][-j,"p_error",i] <- NA
    }
  }
}

NB.SA <- 
purrr::map_dfr(.x = NB.SA, 
               .id = "Age", 
               .f = \(age){
                 purrr::map_dfr(.x = age, 
                                .id = "Gender", 
                                .f = \(sex){
                                  tibble::as_tibble(x = sex, 
                                                    rownames = "j")
                        })
           })

IA.SA <- 
  purrr::map_dfr(.x = IA.SA, 
                 .id = "Age", 
                 .f = \(age){
                   purrr::map_dfr(.x = age, 
                                  .id = "Gender", 
                                  .f = \(sex){
                                    tibble::as_tibble(x = sex, 
                                                      rownames = "j")
                                  })
                 })

DF4tbl <- dplyr::full_join(x = IA.SA, 
                           y = NB.SA, 
                           by = c("Age", "Gender", "j"))




### Set Table
library(gt)
Scenario.tab <- 
  gt(data = DF4tbl, rowname_col = "j", groupname_col = c("Gender", "Age")) |> 
  tab_stubhead(label = "j") |> 
  tab_footnote(footnote = paste("STD: Standard Prosthesis", 
                                "NP1: New Prosthesis 1", sep = ", "), 
               locations = cells_stubhead())

### Format: Assign Dominance/Extended Dominance Labels
Scenario.tab <- 
  Scenario.tab |> 
  sub_missing(columns = "ICER", 
              rows = Dom == 1, missing_text = "D") |> 
  sub_missing(columns = "ICER", 
              rows = ExtDom == 1, missing_text = "ED") |> 
  sub_missing(columns = "ICER", 
              rows = (Dom == 0) & (ExtDom == 0), missing_text = "---") |> 
  tab_footnote(footnote = "D: Dominanted", 
               locations = cells_body(columns = c(ICER), 
                                      rows = Dom == 1), 
               placement = "right") |> 
  tab_footnote(footnote = "ED: Extendedly Dominanted", 
               locations = cells_body(columns = c(ICER), 
                                      rows = ExtDom == 1), 
               placement = "right") |> 
  cols_hide(columns = contains("Dom"))

### Format: Net-Benefit Results
Scenario.tab <- 
  Scenario.tab |> 
  sub_missing(columns = contains(match = "p_error"), 
              rows = everything(), 
              missing_text = "---") |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "20000/QALY"), 
              columns = contains("20000")) |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "30000/QALY"), 
              columns = contains("30000")) |> 
  cols_label("eNB.20000" = "NMB", 
             "eNB.30000" = "NMB", 
             "prob_CE.20000" = "P(CE)", 
             "prob_CE.30000" = "P(CE)", 
             "p_error.20000" = "P(Error)", 
             "p_error.30000" = "P(Error)")

### Format: Currency & Numbers
Scenario.tab <- 
  Scenario.tab |> 
  fmt_currency(columns = c("Costs", 
                           "ICER", 
                           contains("NB")), currency = "GBP") |> 
  fmt_number(columns = c(contains(match = "LY"), 
                         contains(match = "prob"), 
                         contains(match = "error")), decimals = 2)

### Add Title & Sub-Title
Scenario.tab <- 
  Scenario.tab |> 
  tab_header(title = "Cost-Effectiveness Results: THR Model", 
             subtitle = "Monte Carlo Simulation, All Scenarios")

### Modify Table Theme
Scenario.tab <- 
  Scenario.tab |> 
  tab_style(style = cell_text(weight = "bold", align = "center"), 
            locations = cells_column_labels(columns = everything())) |> 
  tab_style(style = cell_text(style = "italic", weight = "bold", align = "right"), 
            locations = cells_stubhead()) |> 
  tab_style(style = cell_text(align = "center"), 
            locations = cells_body()) |> 
  tab_style(style = cell_text(align = "left", weight = "bold"), 
            locations = list(cells_title(groups = "title"), 
                             cells_title(groups = "subtitle"))) |> 
  tab_options(table.border.bottom.color = "black", 
              table.border.top.color = "black")

# Save Output as png ===========================================================
gtsave(data = BC.tab, 
       filename = "tbl_Adoption-Decision_BC.png", 
       path = file.path("results", "01_STD-v-NP1"))
gtsave(data = Scenario.tab, 
       filename = "tbl_Adoption-Decision_All-Scenarios.png", 
       path = file.path("results", "01_STD-v-NP1"))
