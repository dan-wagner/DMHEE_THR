# VoI Display Table: 
# EVPI/EVPPI

# Import Calculated EVPI/EVPPI =================================================
VoI <- readr::read_rds(file = file.path("data", 
                                        "data-gen", 
                                        "VoI-Results", 
                                        "02_STD-v-NP1-v-NP2", 
                                        "VoI_EVPI-EVPPI.rds"))

# Prepare input Data for Display Table =========================================
# Subset data to include scenario and desired thresholds -----------------------
## Gender = Female
## Age = 60
## Lambda = 20,000 and 30,000
VoI.Disp <- dplyr::filter(.data = VoI, 
                          Gender == "Female" & Age == 60, 
                          lambda == 20000 | lambda == 30000)
VoI.Disp <- dplyr::select(.data = VoI.Disp, -Gender, -Age)
# Reshape data ---------------------------------------------------------
VoI.Disp <- tidyr::pivot_longer(data = VoI.Disp, 
                                cols = c("Pt", "Pop"), 
                                names_to = "type", 
                                values_to = "result")
VoI.Disp <- tidyr::pivot_wider(data = VoI.Disp, 
                               names_from = c("type", "lambda"), 
                               values_from = "result")




# Build Table ==================================================================
library(gt)

# Define Table
VoI.tbl <- 
  gt(data = VoI.Disp, 
     groupname_col = "VoI.stat",
     rowname_col = "PHI")

# Format Table
## Set Currency, decimal points
VoI.tbl <- fmt_currency(data = VoI.tbl, 
                        columns = c(contains("Pt"), 
                                   contains("Pop")), 
                        currency = "GBP", 
                        decimals = 2)
## Add Spanners for each lambda to create column groupings.
VoI.tbl <- tab_spanner(data = VoI.tbl, 
                       label = paste("\U03BB =", 
                                     paste0("\U00A3", "20,000")), 
                       columns = contains("20000"))
VoI.tbl <- tab_spanner(data = VoI.tbl, 
                       label = paste("\U03BB =", 
                                     paste0("\U00A3", "30,000")), 
                       columns = contains("30000"))
VoI.tbl <- cols_label(.data = VoI.tbl, 
                      Pt_20000 = "Per Patient", 
                      Pt_30000 = "Per Patient", 
                      Pop_20000 = "Population", 
                      Pop_30000 = "Population")

# Add Title/Subtitle
VoI.tbl <- tab_header(data = VoI.tbl, 
                      title = "Value of Information Analysis Results", 
                      subtitle = "THR Model: STD vs NP1 vs NP2")
# Add Footntoes
## 1) SCENARIO Information.
VoI.tbl <- tab_footnote(data = VoI.tbl, 
                        footnote = "Scenario: Females, Age 60", 
                        locations = cells_title(groups = "subtitle"))

## 2) Simulation configuration for EVPI/EVPPI.
FN.EVPI <- paste("Data generated from Monte Carlo simulations", 
                 "of 10,000 iterations.")
FN.EVPPI <- paste("Data generated from nested Monte Carlo simulations",
                  "of 1,000,000 iterations for each parameter of interest.")

VoI.tbl <- tab_footnote(data = VoI.tbl, 
                        footnote = FN.EVPI, 
                        locations = cells_row_groups(groups = "EVPI"))
VoI.tbl <- tab_footnote(data = VoI.tbl, 
                        footnote = FN.EVPPI, 
                        locations = cells_row_groups(groups = "EVPPI"))

## 3) Assumptions for calculating effective population size. 
FN.EP <- paste("Effective Population Assumptions:", 
               "i) technology lifetime of 10 years;", 
               "ii) incident population of 20,000 patients;", 
               "and iii) discounted at 3%.")
VoI.tbl <- tab_footnote(data = VoI.tbl, 
                        footnote = FN.EP, 
                        locations = cells_column_labels(columns = contains("Pop")))

# Format Table -----------------------------------------------------------------
VoI.tbl <- 
  tab_style(data = VoI.tbl, 
            style = cell_text(weight = "bold", align = "center"), 
            locations = cells_column_labels(columns = everything())) |> 
  tab_style(style = cell_text(align = "left", weight = "bold"), 
            locations = list(cells_title(groups = "title"), 
                             cells_title(groups = "subtitle"))) |> 
  tab_options(table.border.bottom.color = "black", 
              table.border.top.color = "black")

# Save Output
gtsave(data = VoI.tbl, 
       filename = file.path("results", 
                            "02_STD-v-NP1-v-NP2", 
                            "VoI_EVPI-EVPPI_tbl.png"))
