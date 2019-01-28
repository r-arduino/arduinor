#' Stream serial port data into R console
#' 
#' @description This function wraps around `ar_read()` and will read serial
#' port data into R console until user stop it.
#' 
#' @param size Size
#' @inheritParams ar_monitor
#' 
#' @export
ar_collect <- function(fd, size = 100, flush_time = 0.5,
                       eolchar = "\n", buf_max = 256, timeout = 5000) {
  message("Flushing Port...")
  ar_flush_hard(fd, flush_time = flush_time)
  out <- character()
  pb <- progress::progress_bar$new(total = size)
  for (i in seq(size)) {
    out[i] <- ar_read(fd, eolchar, buf_max, timeout)
    pb$tick()
  }
  message("Done")
  return(out)
}