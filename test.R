library(Rcpp)
sourceCpp("src/arduino-serial/arduino-serial-lib.cpp")

aaa <- arduino_read("/dev/cu.SLAB_USBtoUART", times = 1000, eolchar = "\n")

