# FUNCTIONS TO PLOT MODEL RESULTS
#   1. Cost-Effectiveness Plane
#   2. Cost-Effectiveness Acceptability Curve (CEAC)

# PLOT THE COST-EFFECTIVENESS PLANE ############################################
## The number of alternatives in the model will play a key role in determining 
## the approach used to plot the scatter plot of costs versus effects. 
##    If there are only two alternatives in the model: 
##        - Plot change in Effects vs. change in Cost. 
##    If there are more than two alternatives in the model: 
##        - Plot costs vs effects for each alternative. 
##        - Include ICER calculations, show expected values, and display the 
##          cost-effectiveness frontier. 
viz_CEPlane <- function(data, 
                        Effect = "QALYs", 
                        Currency, 
                        show.EV = FALSE, 
                        lambda = NULL) {
  # Validate Inputs
  CurSYM <- c(GBP = "\U00A3", CAD = "\U0024", USD = "\U0024", EUR = "\U20AC")
  Currency <- match.arg(arg = Currency, choices = names(CurSYM))
  CurSYM <- scales::label_dollar(prefix = CurSYM[[Currency]])
  
  # Check Attributes of Data
  Result.Dims <- c("i", "Result", "j")
  ## Subset result dimensions that are present in data
  ID.Dims <- Result.Dims[which(Result.Dims %in% names(dimnames(data)))]
  ## Count the number of alternative J's
  n_j <- length(dimnames(data)$j)
  ## Identify the names of any SG.Dims (if present)
  SG.Dims <- names(dimnames(data))[!names(dimnames(data)) %in% Result.Dims]
  if (length(SG.Dims) == 0) {
    SG.Dims <- NULL
  }
  
  usethis::ui_info(paste("{usethis::ui_field('data')} includes", 
                         "{usethis::ui_value(n_j)} values", 
                         "for {usethis::ui_field('j')}"))
  # Plot Construction by Number of J's
  if (n_j == 2) {
    # Calculate Differences in Costs and Effects between J's.
    DLTA.margin <- c(ID.Dims, SG.Dims)
    DLTA.margin <- DLTA.margin[which(DLTA.margin != "j")]
    
    DLTA.df <- apply(X = data, 
                     MARGIN = DLTA.margin, 
                     FUN = diff)
    
    # Is data deterministic/stochastic? 
    if (length(ID.Dims) == 2) {
      usethis::ui_info(paste("{usethis::ui_field('data')} only contains", 
                             "expected costs and effects"))
      
      ## Define Plot Meta-Data
      Fig.Cap <- "Plot generated from expected costs and effects."
      points.attr <- list(alpha = 1, colour = "black") 
      
      # Sub-Group Modifications
      if (is.null(SG.Dims)) {
        # No Sub-Groups in data
        usethis::ui_info(paste("{usethis::ui_field('data')} has", 
                               "{usethis::ui_value(0)} sub-group dimensions."))
        
        DLTA.df <- as.data.frame(x = as.list(DLTA.df))
      } else if (!is.null(SG.Dims)) {
        usethis::ui_info(paste("{usethis::ui_field('data')} has", 
                               "{usethis::ui_value(length(SG.Dims))} sub-group", 
                               "dimensions: {usethis::ui_value(SG.Dims)}"))
        DLTA.df <-  
          DLTA.df |> 
          as.data.frame() |> 
          tibble::rownames_to_column(var = "Result") |> 
          tidyr::pivot_longer(cols = -"Result", 
                              names_to = SG.Dims, 
                              names_sep = "\\.",
                              values_to = "Output") |> 
          tidyr::pivot_wider(names_from = "Result", 
                             values_from = "Output")
        
      }
      
    } else if (length(ID.Dims == 3)) {
      usethis::ui_info(paste("{usethis::ui_field('data')} contains", 
                             "distributions of costs and effects."))
      
      ## Define Plot Meta-Data
      Fig.Cap <- paste("Data generated from Monte Carlo simulation of", 
                       nrow(data), "iterations.")
      points.attr <- list(alpha = 1, colour = "grey")
      
      ## Show Expected Values? 
      if (isTRUE(show.EV)) {
        EV <- colMeans(x = DLTA.df, na.rm = FALSE, dims = 1)
      }
      
      ## Sub-Group Formatting
      if (is.null(SG.Dims)) {
        # No Sub-Groups in data
        usethis::ui_info(paste("{usethis::ui_field('data')} has", 
                               "{usethis::ui_value(0)} sub-group dimensions."))
        
        DLTA.df <- tibble::as_tibble(DLTA.df, rownames = "i")
        
        if (isTRUE(show.EV)) {
          EV <- tibble::as_tibble(as.list(EV))
        }
        
      } else if (!is.null(SG.Dims)) {
        usethis::ui_info(paste("{usethis::ui_field('data')} has", 
                               "{usethis::ui_value(length(SG.Dims))} sub-group", 
                               "dimensions: {usethis::ui_value(SG.Dims)}"))
        DLTA.df <- 
          tibble::as_tibble(DLTA.df, rownames = "i") |> 
          tidyr::pivot_longer(cols = -"i", 
                              names_to = c("Result", SG.Dims), 
                              names_sep = "\\.", 
                              values_to = "Output") |> 
          tidyr::pivot_wider(names_from = "Result", 
                             values_from = "Output")
        
        if (isTRUE(show.EV)) {
          EV <- tibble::as_tibble(x = EV, rownames = "Result") |> 
            tidyr::pivot_longer(cols = -"Result", 
                                names_to = c("Gender", "Age"), 
                                names_sep = "\\.",
                                values_to = "Output") |> 
            tidyr::pivot_wider(names_from = "Result", 
                               values_from = "Output")
        }
        
      }
      
    }
    
    # Build Plot ================
    CEplane <- 
      ggplot2::ggplot(data = DLTA.df, 
                      mapping = ggplot2::aes_(x = as.name(Effect), 
                                              y = quote(Costs))) + 
      ggplot2::theme_bw()
    
    ## Add Scales and Labels
    CEplane <- 
      CEplane + 
      ggplot2::scale_y_continuous(labels = CurSYM) + 
      ggplot2::labs(x = paste("Effect Difference, ", 
                              paste0("\U0394", Effect)), 
                    y = paste("Cost Difference, ", 
                              paste0("\U0394", "Costs")), 
                    caption = Fig.Cap)
    
    ## Add Points
    CEplane <- 
      CEplane + 
      ggplot2::geom_point(alpha = points.attr$alpha, 
                          colour = points.attr$colour)
    if (isTRUE(show.EV) && length(ID.Dims == 3)) {
      CEplane <- 
        CEplane + 
        ggplot2::geom_point(data = EV, size = 2, colour = "black")
    }
    
    if (!is.null(lambda)) {
      xmax <- max(ggplot2::layer_scales(CEplane)$x$range$range)
      ymax <- max(ggplot2::layer_scales(CEplane)$y$range$range)
      
      # Define new Data frame to add lines as separate plot layer. 
      LDA.df <- data.frame(slope = lambda, 
                           intercept = 0, 
                           xpos = pmin((ymax - 0)/lambda, xmax), 
                           ypos = pmin((lambda*xmax + 0), ymax))
      # Update Plot
      CEplane <- 
        CEplane + 
        ggplot2::geom_abline(slope = lambda, 
                             intercept = 0, 
                             linetype = "dashed") + 
        ggplot2::geom_label(data = LDA.df, 
                            ggplot2::aes(x = xpos, 
                                         y = ypos, 
                                         label = paste0("\U03BB=",
                                                        as.character(slope))))
    }
    
    
  } else if (n_j > 2) {
    usethis::ui_info(paste("Building CE Plane for multiple alternatives."))
  }
  
  return(CEplane)
}