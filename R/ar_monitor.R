#' Stream serial port data into R console
#' 
#' @description This function wraps around `ar_read()` and will read serial
#' port data into R console until user stop it.
#' @param flush_time Time to flush buffed results in the serial channel
#' 
#' @inheritParams ar_read
#' 
#' @export
ar_monitor <- function(fd, flush_time = 0.5, 
                      eolchar = "\n", buf_max = 256, timeout = 5000) {
  message("Flushing Port...")
  ar_flush_hard(fd, flush_time)
  repeat (cat(ar_read(fd, eolchar, buf_max, timeout)))
}