inline_widget <- function(x, width = "100px") {
  shiny::div(
    style = glue("display: inline-block;vertical-align:top; width: {width};"),
    x)
}

csv_newline <- function(x) {
  paste0(paste(x, collapse = ","), "\r\n")
}
