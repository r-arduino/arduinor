#' Arduino Plotter for websocket
#' 
#' @param ws websocket connection
#' @param names Labels for variables 
#' @param sep_fun A function that separates the inline string into different 
#' variables. By default, it is `ar_sep_comma`, which splits the string by 
#' comma. You can easily write your own function, which can even do additional
#' calculation. 
#' @param freq Length of miliseconds that the shiny app will check for new data.
#' The default 50ms (20Hz) is almost the maxium on normal computer nowadays. 
#' 
#' @export
ar_ws_plotter <- function(ws, names = NULL, sep_fun = ar_sep_comma, 
                          freq = 50) {
  shiny::runApp(
    ar_ws_app(ws = ws, names = names, sep_fun = sep_fun, freq = freq), 
    launch.browser = rstudioapi::viewer
  )
}

# con <- ar_init("/dev/cu.SLAB_USBtoUART", baud = 57600)

ar_ws_app <- function(ws, names = NULL, sep_fun = ar_sep_comma, freq = 50) {
  first_dot <- webrockets::ws_receive(ws, 0)
  if (first_dot == "") {
    stop("Your websocket connection is broken. ")
  }
  first_dot <- sep_fun(first_dot)
  signal_vars <- seq(length(first_dot))
  
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
    })
    
    observeEvent(input$reset, {
      rv$state <- 0
      updateActionButton(session, "start", icon = icon("play"))
    })
    
    observeEvent(input$save, {
      if (!file.exists(input$file)) {
        file.create(input$file)
        cat(csv_newline(names(first_dot)), file = input$file)
      }
    }, ignoreInit = TRUE)
    
    observe({
      invalidateLater(freq)
      if (rv$state) {
        realtime <- webrockets::ws_receive(ws, 0)
        if (realtime != "") {
          realtime <- sep_fun(realtime)
          if (input$save) {
            cat(csv_newline(realtime), file = input$file, append = TRUE)
          }
          realtime_y <- lapply(realtime[sort(as.integer(input$y_var))], list)
          realtime_list <- list(y = realtime_y)
          to_traces <- as.list(seq(length(input$y_var)))
          plotlyProxy("plot", session) %>%
            plotlyProxyInvoke("extendTraces", realtime_list, to_traces)
        }
      }
    })
    
    observeEvent(input$power, {
      invisible(stopApp())
    })
  }
  
  shinyApp(ui, server)
}

#' Setup a websocket connection
#' 
#' @description Setup a websocket connection
#' 
#' @export
ar_ws_init <- function(ws) {
  webrockets::ws_connect(ws)
}

#' Disconnect a websocket connection
#' 
#' @description Disconnect a websocket connection
#' 
#' @export
ar_ws_close <- function(ws) {
  remove(ws)
}
