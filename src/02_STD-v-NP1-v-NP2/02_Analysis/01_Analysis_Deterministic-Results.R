# Analyze Simulation Results
#   Adoption Decision
#   Deterministic Output
#   Produce a display table of estimated costs and effects.
#       - Output 1: Base Case (Female, Age 60)
#       - Output 2: All Scenarios

# Import Data ==================================================================
simResult <- readr::read_rds(file = file.path("data", 
                                              "data-gen", 
                                              "Simulation-Output", 
                                              "02_STD-v-NP1-v-NP2", 
                                              "THR_Deter.rds"))
# Incremental Analysis =========================================================
library(HEEToolkit)
## Base Case | Female, Age 60 --------------------------------------------------
BC.ICER <- inc_analysis(data = simResult[,,"Female", "60"], Effects = "QALYs")
## All Scenarios ---------------------------------------------------------------
SA.ICER <- 
  lapply(X = c("40" = "40", "60" = "60", "80" = "80"), 
         FUN = \(age){
           lapply(X = c(Male = "Male", Female = "Female"), 
                  FUN = \(sex){
                    inc_analysis(data = simResult[,,sex, age], 
                                 Effects = "QALYs")
                  })
         })

# Build Display Tables =========================================================
library(gt)
## Base Case | Female, Age 60 --------------------------------------------------
BC.tab <- gt(data = as.data.frame(BC.ICER), 
             rownames_to_stub = TRUE) |> 
  tab_stubhead(label = "j")

### Format: Assign Dominance/Extended Dominance
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
                                      rows = Dom == 1)) |> 
  tab_footnote(footnote = "ED: Extendedly Dominanted", 
               locations = cells_body(columns = c(ICER), 
                                      rows = ExtDom == 1)) |> 
  cols_hide(columns = contains("Dom"))

### Format: Currency and Numbers
BC.tab <- 
  BC.tab |> 
  fmt_currency(columns = c("Costs", "ICER"), currency = "GBP") |> 
  fmt_number(columns = contains(match = "LY"), decimals = 2)

### Add Title, Sub-Title
BC.tab <- 
  BC.tab |> 
  tab_header(title = "THR Model Cost-Effectiveness Results: Incremental Analysis", 
             subtitle = "Deterministic Simulation, Base Case: Female, Age 60")

### Add Footnotes
BC.tab <- 
  BC.tab |> 
  tab_footnote(footnote = paste("STD: Standard Prosthesis", 
                                "NP1: New Prosthesis 1", 
                                "NP2: New Prosthesis 2", 
                                sep = ", "), 
               locations = cells_stubhead())

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
### Wrangle Input Data
SA.ICER <- purrr::map_dfr(.x = SA.ICER, 
                          .id = "Age",
                          .f = \(age){
                            purrr::map_dfr(.x = age,
                                           .id = "Gender",
                                           .f = \(sex){
                                             tibble::as_tibble(x = sex, 
                                                               rownames = "j")
                                           })
                          })


### Define Table

Scenario.tab <- gt(data = SA.ICER, 
                   rowname_col = "j", 
                   groupname_col = c("Gender", "Age")) |> 
  tab_stubhead(label = "j")


### Format: Assign Dominance/Extended Dominance
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
                                      rows = Dom == 1)) |> 
  tab_footnote(footnote = "ED: Extendedly Dominanted", 
               locations = cells_body(columns = c(ICER), 
                                      rows = ExtDom == 1)) |> 
  cols_hide(columns = contains("Dom"))

### Format: Currency and Numbers
Scenario.tab <- 
  Scenario.tab |> 
  fmt_currency(columns = c("Costs", "ICER"), currency = "GBP") |> 
  fmt_number(columns = contains(match = "LY"), decimals = 2)

### Add Title, Sub-Title
Scenario.tab <- 
  Scenario.tab |> 
  tab_header(title = "THR Model Cost-Effectiveness Results: Incremental Analysis", 
             subtitle = "Deterministic Simulation, All Scenarios")

### Add Footnotes
Scenario.tab <- 
  Scenario.tab |> 
  tab_footnote(footnote = paste("STD: Standard Prosthesis", 
                                "NP1: New Prosthesis 1", 
                                "NP2: New Prosthesis 2", 
                                sep = ", "), 
               locations = cells_stubhead())

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

# Save Output ##################################################################
gtsave(data = BC.tab, 
       filename = "tbl_Inc-Analysis_Deter_Base-Case.png", 
       path = file.path("results", "02_STD-v-NP1-v-NP2"))
gtsave(data = Scenario.tab, 
       filename = "tbl_Inc-Analysis_Deter_All-Scenarios.png", 
       path = file.path("results", "02_STD-v-NP1-v-NP2"))
