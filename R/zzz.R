.onUnload <- function(libpath) {
  library.dynam.unload("arduino", libpath)
}