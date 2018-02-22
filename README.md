# arduino
> Arduino is an open source computer hardware and software company, project, and user community that designs and manufactures single-board microcontrollers and microcontroller kits for building digital devices and interactive objects that can sense and control objects in the physical world. --Wikipedia

As one important piece of the fast growing ["IoT"](https://en.wikipedia.org/wiki/Internet_of_things) movement, arduino chips enable scientists and hobbyists to build customizable digital devices at will at a very inexpensive price. For the scientific community, it opens up a new way to collect various formats of data, such as accelerometer, gyroscope, thermometer and IR. Data collected by arduino can be sent to computers both wirelessly (through the WiFi kit on some recent devices such as ESP8266) or wirely through serial ports. This package handles reading arduino data from serial port into R.

Current approaches in R, including the `serial` package or [this post](https://www.r-bloggers.com/connecting-the-real-world-to-r-with-an-arduino/), both have dependency requirements. This package binds the light-weight [arduino-serial](https://github.com/todbot/arduino-serial) C library by Tod E. Kurt to R using Rcpp. It is both dependency-free and fast.

# Installation
```r
devtools::install("hebrewseniorlife/arduino")
```

# Getting Started
```r
library(arduino)

# Use the baud rate you set in `Serial.begin();` in arduino
# On Mac
con <- ar_init("/dev/cu.SLAB_USBtoUART", baud = 57600)  
# On Windows
con <- ar_init("COM1", baud = 57600)  

# Start to stream arduino data into console. Press STOP to stop.
ar_stream(con)
```