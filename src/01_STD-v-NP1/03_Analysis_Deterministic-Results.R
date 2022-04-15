# Analyze Simulation Results
#   Adoption Decision
#   Deterministic Output
#   Produce a display table of estimated costs and effects.
#       - Output 1: Base Case (Female, Age 60)
#       - Output 2: All Scenarios

# Import Data ==================================================================
THR.2j <- readr::read_rds(file = file.path("data", 
                                           "data-gen", 
                                           "Simulation-Output", 
                                           "01_STD-v-NP1", 
                                           "THR_Deter.rds"))
# Incremental Analysis =========================================================
library(HEEToolkit)
## Base Case | Female, Age 60 --------------------------------------------------
BC.ICER <- inc_analysis(data = THR.2j[,,"Female", "60"], Effect = "QALYs")
BC.ICER
## All Scenarios ---------------------------------------------------------------
SCENARIO.ICER <- 
  sapply(X = c("40" = "40", "60" = "60", "80" = "80"), 
         FUN = \(age){
           sapply(X = c(Male = "Male", Female = "Female"), 
                  FUN = \(sex){
                    inc_analysis(data = THR.2j[,,sex, age], 
                                 Effect = "QALYs")
                  }, 
                  simplify = "array")
         }, 
         simplify = "array")
names(dimnames(SCENARIO.ICER))[c(3,4)] <- c("Gender", "Age")

# Build Display Tables =========================================================
library(gt)
## Base Case | Female, Age 60 --------------------------------------------------
BC.tab <- gt(data = as.data.frame(BC.ICER), rownames_to_stub = TRUE) |> 
  tab_stubhead(label = "j")

### Format: Assign Dominance/Extended Dominance
BC.tab <- 
  BC.tab |> 
  fmt_missing(columns = "ICER", 
              rows = Dom == 1, missing_text = "D") |> 
  fmt_missing(columns = "ICER", 
              rows = ExtDom == 1, missing_text = "ED") |> 
  fmt_missing(columns = "ICER", 
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
  tab_footnote(footnote = "STD: Standard Prosthesis", 
               locations = cells_stub(rows = "STD")) |> 
  tab_footnote(footnote = "NP1: New Prosthesis 1", 
               locations = cells_stub(rows = "NP1"))

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
DF4tbl <- as.data.frame(x = SCENARIO.ICER)
DF4tbl <- 
tibble::rownames_to_column(.data = DF4tbl, var = "j") |> 
  tidyr::pivot_longer(cols = -"j", 
                       names_to = c("Result", "Gender", "Age"), 
                       names_sep = "\\.", 
                      names_transform = list(Age = as.double), 
                       values_to = "Output") |> 
  tidyr::pivot_wider(names_from = "Result", 
                     values_from = Output)


Scenario.tab <- gt(data = DF4tbl, 
                   rowname_col = "j", 
                   groupname_col = c("Gender", "Age"))


### Format: Assign Dominance/Extended Dominance
Scenario.tab <- 
  Scenario.tab |> 
  fmt_missing(columns = "ICER", 
              rows = Dom == 1, missing_text = "D") |> 
  fmt_missing(columns = "ICER", 
              rows = ExtDom == 1, missing_text = "ED") |> 
  fmt_missing(columns = "ICER", 
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
  tab_footnote(footnote = "STD: Standard Prosthesis", 
               locations = cells_stub(rows = "STD")) |> 
  tab_footnote(footnote = "NP1: New Prosthesis 1", 
               locations = cells_stub(rows = "NP1"))

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
       path = file.path("results", "01_STD-v-NP1"))
gtsave(data = Scenario.tab, 
       filename = "tbl_Inc-Analysis_Deter_All-Scenarios.png", 
       path = file.path("results", "01_STD-v-NP1"))
