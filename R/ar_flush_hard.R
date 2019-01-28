#' Flush serial port in the hard way
#' 
#' @description In theory `ar_flush` should work but it didn't work out for me 
#' at least. So I recreated this `flush` feature in R, which basically let the 
#' data flow for a short time (default 50 ms). The selection of this value 
#' depends of many factors including the USB port and the size of data so please
#' pick this value wisely. 
#' 
#' @inheritParams ar_monitor
#' @param include_c_flush T/F for whether to call ar_flush at the beginning
#' @export
ar_flush_hard <- function(fd, flush_time = 0.05, include_c_flush = TRUE) {
  if (include_c_flush)   ar_flush(fd)
  start_time <- as.numeric(Sys.time())
  while ((as.numeric(Sys.time()) - start_time) < flush_time) {
    ar_read(fd)
  }
}