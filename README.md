# DMHEE_THR
This repo is a redevelopment of the Total Hip Replacement (THR) model from the 
DMHEE textbook [^1] using computing strategies for reproducibility. The original 
THR model was developed by Briggs et al.[^2], to assess the cost-effectiveness 
of two or three alternative surgical prostheses. 

The re-development involved organizing the relevant methodological sequence into 
an automated workflow. To capture the provenance of the results, the workflow 
was designed to incorporate the procedures of the economic evaluation as well as 
those used to estimate the parameter inputs. 

This effort was initiated in response to the fact that the original textbook 
exercises are designed and organized for a spreadsheet environment. Adapting 
this project to a programming language (`R`) offered the ability to show how 
this model could be developed in a reproducible fashion. A collection of 
previously identified strategies for reproducibility were used to achieve a 
level of reproducibility that would allow for the reliable re-generation of 
results, including intermediate data sets. 

# Documentation

* [Progress](docs/01_Progress.md)
* [Summary of the THR Model](docs/02_Model-Summary.md)

# Project Organization
This project is organized using a consistent directory structure which could be 
applied to most projects. Additionally, it allows for the use of relative file 
paths within scripts - which is essential for portability. An outline of the 
directory structure is presented below. 

```
PROJECT-DIRECTORY
|-data\
|   |-data-raw\
|   |-data-gen\
|     |-Model-Params\
|     |-Simulation-Output\
|-docs\
|-results\
|-src\
|   |-FUNS\
|   |-01_Simulations
|   |-02_Analysis
```

`data`
  : The data directory is used to store both raw (`data-raw`) and generated 
  (`data-gen`) data set. In the latter category, additional sub-directories are 
  used to distinguish between Model Parameters and Simulation Output. 
  
`docs`
  : The docs directory is used to store documents relevant to the project. This 
  may include project-specific [documentation](#documentation), diagrams, or 
  even manuscripts and reports. 
  
`results`
  : The results directory is used to store results from the project. In this 
  case a result is conceptualized as output which is ready to be placed in a 
  manuscript or report. This may include a formatted display table or different 
  kinds of plots produced for the project. 
  
`src`
  : The src is used to store all of the scripts for a project. It is organized 
  into three specific sub-directories. The first sub-directory, `FUNS`, is used 
  to store *functions* which are specific to the project in general. This is 
  where all of the functions used to define the decision model and prepare its 
  parameter inputs are stored. The second sub-directory, `01_Simulations`, is 
  used to store *scripts* which execute all relevant simulations for this 
  project. The third sub-directory, `02_Analysis`, is used to store *scripts* 
  which perform the relevant steps to produce a specific result. In other words, 
  these scripts accept simulation output as input and return a result (i.e. 
  tabular or graphical) which will be stored in the `results` directory. 

# Notes

  * :information_source: Add Function to return Display Table for  
  Cost-Effectiveness Results. 
    - There is a considerable amount of code duplication. 
    - Requirements: 
      - Deterministic vs probabilistic output. 
      - Scenarios as row groups. 
      

[^1]: Briggs AH, Claxton K, Sculpher MJ. Decision modelling for health economic
evaluation. Oxford: Oxford University Press; 2006. 237 p. (Briggs A, Gray A, 
editors. Oxford handbooks in health economic evaluation). 
[^2]: Briggs A, Sculpher M, Dawson J, Fitzpatrick R, Murray D, Malchau H. 
Modelling the cost-effectiveness of primary hip replacement: how cost-effective 
is the Spectron compared to the Charnley prosthesis? 2003 Dec;52. 