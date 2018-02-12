library(Rcpp)
sourceCpp("src/arduino-serial-lib.cpp")

arduino_read("/dev/cu.SLAB_USBtoUART", times = 100, delay = 10, baud = 57600)


aa <- serialport_init("/dev/cu.SLAB_USBtoUART", baud = 57600)

bb <- c()
for (i in 1:1000) {
  bb <- c(bb, serialport_read(aa, "\n", 256, 5000))
}

