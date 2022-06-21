# Analyze Simulation Results
#   Adoption Decision
#   Monte Carlo Simulation Output
#   Produce a display table for Cost-Effectiveness Results. 
#       - Expressed Incrementally, and using net-benefits, at 20K/30K.
#       - Output 1: Base Case (Female, Age 60)
#       - Output 2: All Scenarios

# Import Data ==================================================================
THR.2j <- readr::read_rds(file = file.path("data", 
                                           "data-gen", 
                                           "Simulation-Output", 
                                           "01_STD-v-NP1", 
                                           "MC-Sim.rds"))

str(THR.2j)
str(THR.2j[,,,"Female","60"])

# Analyses =====================================================================
## Incremental Analysis --------------------------------------------------------
library(HEEToolkit)

IA.BC <- colMeans(x = THR.2j[,,,"Female", "60"], na.rm = FALSE, dims = 1)
IA.BC <- t(IA.BC)

IA.BC <- inc_analysis(data = IA.BC, Effects = "QALYs")

IA.Scenario <- colMeans(x = THR.2j, na.rm = FALSE, dims = 1)
IA.Scenario <- aperm(a = IA.Scenario, perm = c("j", "Result", "Gender", "Age"))

IA.Scenario <- 
  sapply(X = c("40" = "40", "60" = "60", "80" = "80"), 
         FUN = \(age){
           sapply(X = c(Male = "Male", Female = "Female"), 
                  FUN = \(sex){
                    inc_analysis(data = IA.Scenario[,,sex,age], 
                                Effects = "QALYs")
                    },
                  simplify = "array")
           },
         simplify = "array")

## Net-Benefits Framework, (NMB) -----------------------------------------------
NB.BC <- nb_analysis(data = THR.2j[,,,"Female","60"], 
                     lambda = c(20000, 30000), 
                     Effects = "QALYs", 
                     type = "NMB")

NB.Scenario <- 
  sapply(X = c("40" = "40", "60" = "60", "80" = "80"), 
         FUN = \(age){
           sapply(X = c(Male = "Male", Female = "Female"), 
                  FUN = \(sex){
                    nb_analysis(data = THR.2j[,,,sex,age],
                                lambda = c(20000, 30000), 
                                Effects = "QALYs", 
                                type = "NMB")
                  },
                  simplify = "array")
         },
         simplify = "array")

# Build Display Table ==========================================================
## Base Case: Female, Age 60 ---------------------------------------------------
### Wrangle Input Data to Correct Format
DF4tbl <- cbind(as.data.frame(IA.BC), 
                as.data.frame(NB.BC))
### Set Table
library(gt)
BC.tab <- gt(data = DF4tbl, rownames_to_stub = TRUE) |> 
  tab_stubhead(label = "j") |> 
  tab_footnote(footnote = "STD: Standard Prosthesis", 
               locations = cells_stub(rows = "STD")) |> 
  tab_footnote(footnote = "NP1: New Prosthesis 1", 
               locations = cells_stub(rows = "NP1"))

### Format: Assign Dominance/Extended Dominance Labels
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

### Format: Net-Benefit Results
BC.tab <- 
  BC.tab |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "20000/QALY"), 
              columns = contains("20000")) |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "30000/QALY"), 
              columns = contains("30000")) |> 
  cols_label("eNB.20000" = "NMB", 
             "eNB.30000" = "NMB", 
             "prob_CE.20000" = "P(CE)", 
             "prob_CE.30000" = "P(CE)")

### Format: Currency & Numbers
BC.tab <- 
  BC.tab |> 
  fmt_currency(columns = c("Costs", 
                           "ICER", 
                           contains("NB")), currency = "GBP") |> 
  fmt_number(columns = c(contains(match = "LY"), 
                         contains(match = "prob")), decimals = 2)

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
DF4tbl_2 <- 
  list(IA = tibble::rownames_to_column(.data = as.data.frame(IA.Scenario), var = "j"),
       NB = tibble::rownames_to_column(.data = as.data.frame(NB.Scenario), var = "j"))

DF4tbl_2$IA <- 
  DF4tbl_2$IA |> 
  tidyr::pivot_longer(cols = -"j", 
                      names_to = c("Result", "Gender", "Age"), 
                      names_sep = "\\.", 
                      values_to = "Output") |> 
  tidyr::pivot_wider(names_from = "Result", values_from = "Output")

DF4tbl_2$NB <- 
DF4tbl_2$NB |> 
  tidyr::pivot_longer(cols = -"j", 
                      names_to = c("stat", "lambda", "Gender", "Age"), 
                      names_sep = "\\.", 
                      values_to = "Result") |> 
  tidyr::pivot_wider(names_from = c("stat", "lambda"), 
                     values_from = "Result")

DF4tbl_2 <- dplyr::full_join(x = DF4tbl_2$IA, 
                             y = DF4tbl_2$NB, 
                             by = c("j", "Gender", "Age"))

### Set Table
library(gt)
Scenario.tab <- 
  gt(data = DF4tbl_2, rowname_col = "j", groupname_col = c("Gender", "Age")) |> 
  tab_stubhead(label = "j") |> 
  tab_footnote(footnote = "STD: Standard Prosthesis", 
               locations = cells_stub(rows = "STD")) |> 
  tab_footnote(footnote = "NP1: New Prosthesis 1", 
               locations = cells_stub(rows = "NP1"))

### Format: Assign Dominance/Extended Dominance Labels
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

### Format: Net-Benefit Results
Scenario.tab <- 
  Scenario.tab |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "20000/QALY"), 
              columns = contains("20000")) |> 
  tab_spanner(label = paste0("\U03BB = ", "\U00A3", "30000/QALY"), 
              columns = contains("30000")) |> 
  cols_label("eNB_20000" = "NMB", 
             "eNB_30000" = "NMB", 
             "prob_CE_20000" = "P(CE)", 
             "prob_CE_30000" = "P(CE)")

### Format: Currency & Numbers
Scenario.tab <- 
  Scenario.tab |> 
  fmt_currency(columns = c("Costs", 
                           "ICER", 
                           contains("NB")), currency = "GBP") |> 
  fmt_number(columns = c(contains(match = "LY"), 
                         contains(match = "prob")), decimals = 2)

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
