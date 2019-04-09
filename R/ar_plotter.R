#' Arduino Plotter
#' 
#' @param names Labels for variables 
#' @param sep_fun A function that separates the inline string into different 
#' variables. By default, it is `ar_sep_comma`, which splits the string by 
#' comma. You can easily write your own function, which can even do additional
#' calculation. 
#' @param reduce_freq T/F. It might be the case that plotly streaming API can't 
#' process frequency > 25 Hz (40ms delay time) or it might be the case that 
#' my computer doesn't have enough power. Anyway, I set this option here to
#' add 40ms delay time to reduce the sampling frequency. 
#' @param running_mean If an integer larger than 0 is chosen, the running mean 
#' of each series is computed, effectively smoothing the signals. Default value
#' is set to 0 (no running mean is calculated)
#' @inheritParams ar_monitor
#' 
#' @export
ar_plotter <- function(fd, names = NULL, sep_fun = ar_sep_comma,  
                       reduce_freq = TRUE, flush_time = 0.05,
                       eolchar = "\n", buf_max = 256, timeout = 5000,
                       running_mean = 0) {
  shiny::runApp(
    ar_app(con = fd, names = names, sep_fun = sep_fun, 
           flush_time = flush_time, reduce_freq = reduce_freq,
           eolchar = eolchar, buf_max = buf_max, timeout = timeout, 
           running_mean = running_mean), 
    launch.browser = rstudioapi::viewer
  )
}

# con <- ar_init("/dev/cu.SLAB_USBtoUART", baud = 57600)

ar_app <- function(con, names = NULL, sep_fun = ar_sep_comma, 
                   flush_time = 0.05, reduce_freq = TRUE,
                   eolchar = "\n", buf_max = 256, timeout = 5000, 
                   running_mean = 0) {
  
  message("Flushing Port...")
  ar_flush_hard(con, flush_time)
  first_dot <- ar_read(con, eolchar, buf_max, timeout)
  if (first_dot == "") {
    stop("Your connection is probably dead. Please use ar_init and start",
         " a new connection")
  }
  first_dot <- sep_fun(first_dot)
  signal_vars <- seq(length(first_dot))
  
  if (running_mean > 0) {
    rmeans <- vector("list", length(first_dot))
    for (i in signal_vars) {
      rmeans[[i]] <- arduinor:::RunningMean$new(running_mean)
      rmeans[[i]]$insert(first_dot[i])
    }
  }
  
  if (is.null(names)) {
    names(signal_vars) <- paste("Var", signal_vars)
    names(first_dot) <- paste("Var", signal_vars)
  } else {
    if (length(names) != length(first_dot)) {
      stop(
        "The amount of names provided is different from the amount of values."
      )
    }
    names(signal_vars) <- names
    names(first_dot) <- names
  }
  
  save_file_default <- glue("arduino_{format(Sys.time(), '%Y%m%d_%H%M%S')}.csv")
  
  ui <- fluidPage(
    br(),
    actionButton("power", label = NULL, icon = icon("power-off", "text-danger"),
                 width = NULL, 
                 style = "border-radius: 25px; position: absolute; top: 15px; right: 15px;z-index: 20;"),
    inline_widget(actionButton("start", icon = icon("play"), 
                               label = NULL, width = "100%"), "50px"),
    inline_widget(actionButton("reset", icon = icon("undo"), 
                               label = NULL, width = "100%"), "50px"),
    inline_widget(h5("Vars:"), "35px"),
    inline_widget(selectInput(
      "y_var", label = NULL, choices = signal_vars, 
      selected = signal_vars, multiple = T
    ), "calc(95% - 180px);z-index: 15;"),
    plotlyOutput("plot", height = "250px"),
    inline_widget(checkboxInput("save", strong("Save to file?")), "30%"),
    inline_widget(textInput("file", NULL, save_file_default), "65%")
  )
  
  server <- function(input, output, session) {
    rv <- reactiveValues()
    rv$state <- 0

    # first_xy <- separateXY(first_dot)
    
    output$plot <- renderPlotly({
      req(input$y_var)
      input$reset
      p <- plot_ly(type = 'scatter', mode = 'lines', line = list(width = 3))
      for (y_i in sort(as.integer(input$y_var))) {
        p <- add_trace(p, y = first_dot[y_i], name = names(first_dot[y_i]))
      }
      return(p)
    })
    
    observeEvent(input$start, {
      rv$state <- 1 - rv$state
      start_icon <- icon(c("play", "pause")[rv$state + 1])
      updateActionButton(session, "start", icon = start_icon)
      ar_flush_hard(con, flush_time)
    })
    
    observeEvent(input$reset, {
      rv$state <- 0
      updateActionButton(session, "start", icon = icon("play"))
      ar_flush_hard(con, flush_time)
    })
    
    observeEvent(input$save, {
      if (!file.exists(input$file)) {
        file.create(input$file)
        cat(csv_newline(names(first_dot)), file = input$file)
      }
    }, ignoreInit = TRUE)
    
    observe({
      invalidateLater(1)
      if (rv$state) {
        ar_flush_hard(con, 0.04, FALSE)
        realtime <- sep_fun(ar_read(con, eolchar, buf_max, timeout))
        
        if (running_mean > 0) {
          for (i in seq(length(realtime))) {
            rmeans[[i]]$insert(realtime[[i]])
            realtime[[i]] <- rmeans[[i]]$get_mean()
          }
        }
        
        if (input$save) {
          cat(csv_newline(realtime), file = input$file, append = TRUE)
        }
        realtime_y <- lapply(realtime[sort(as.integer(input$y_var))], list)
        realtime_list <- list(y = realtime_y)
        to_traces <- as.list(seq(length(input$y_var)))
        plotlyProxy("plot", session) %>%
          plotlyProxyInvoke("extendTraces", realtime_list, to_traces)
      }
    })
    
    observeEvent(input$power, {
      invisible(stopApp())
    })
  }
  
  shinyApp(ui, server)
}

