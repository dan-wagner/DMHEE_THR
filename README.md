# DMHEE_THR
The goal of this repo is to develop and execute the Total Hip Replacement (THR) 
model from the DMHEE textbook. This exercise was developed in response to the
observation that the textbook is written and organized for a spreadsheet 
environment. A different approach is required when using a programming language 
like R. 

Source Text: 
1. Briggs AH, Claxton K, Sculpher MJ. Decision modelling for health economic
evaluation. Oxford: Oxford University Press; 2006. 237 p. (Briggs A, Gray A, 
editors. Oxford handbooks in health economic evaluation). 

# Model Summary
Insert description of the model here. 

# Project Organization
TODO: Provide an explanation for how the project is organized here. 

# Progress
:white_check_mark: Complete
:warning: In-Progress
:x: Ice-Box.

## :warning: Develop THR Model
* Start with model evaluating two alternative prostheses.   
  - Include capability for deterministic and probabilistic simulation. 

## :x: Perform Simulations

### :x: Adoption Decision
* :x: Deterministic Simulation
  - Save to `data/data-gen/Simulation-Output` directory as `THR_Deter.rds`. 
* :x: Monte Carlo Simulation (5,000 iterations)
  - Save to `data/data-gen/Simulation-Output` directory as `THR_MC-Sim_5000.rds`

### :x: Research Decision
* :x: Nested Monte Carlo Simulation. 
  - Save to `data/data-gen/Simulation-Output` directory as `THR_Nested-MC_param.rds`
  
## :x: Analyze Simulation Results

### :x: Adoption Decision

* :x: Deterministic - Calculate ICER. 
* :x: Probabilisitc
  - :x: Perform Incremental Analysis
  - :x: Net-Benefits Analysis. 
  - :x: Prepare CEA Results Table. 
  - :x: Plot Cost-Effectiveness Plane. 
  - :x: Plot CEAC. 
  
### :x: Research Decision
* :x: Implement VoI Methods. 
  - :x: Calculate EVPI (per-patient and population). 
  - :x: Calculate EVPPI (per-patient and population). 
  - :x: Plot EVPI and EVPPI as a function of cost-effectiveness threshold. 