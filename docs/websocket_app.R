library(webrockets)
library(shiny)

con <- webrockets::ws_connect("ws://192.168.49.140:81")

inline_widget <- function(x, width = "100px") {
  shiny::div(
    style = glue("display: inline-block;vertical-align:top; width: {width};"),
    x)
}

csv_newline <- function(x) {
  paste0(paste(x, collapse = ","), "\r\n")
}


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