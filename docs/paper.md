---
title: 'arduinor: An R Package for Easily Access Serial Data from Arduino'
tags:
  - R
  - IoT
  - microcontroller
  - serial port
authors:
  - name: Hao Zhu
    orcid: 0000-0002-3386-6076
    affiliation: 1
  - name: Brad Manor
    orcid: 0000-0000-0000-0000
    affiliation: 1,2
  - name: Wanting Yu
    orcid: 0000-0000-0000-0000
    affiliation: 1
  - name: Thomas Travison
    orcid: 0000-0000-0000-0000
    affiliation: 1, 2
affiliations:
 - name: Marcus Institute for Aging Research, Hebrew Seniorlife
   index: 1
 - name: Harvard Medical School
   index: 2
date: 1 March 2019
bibliography: references.bib
---

# Summary

Sensors are fun and they potentially can be quite benefitial to the science communities. These are small electroic chips that can "sense" this world from various aspects. For example, clinical researchers can use an accelerometer to track human body movements[@Gafurov_2009] while ecologist can use a GPS device to track the movement of birds[@Marvin_2016]. Today, these ideas can be easily prototyped using open-source hardware development platforms such as  [arduino](https://www.arduino.cc/) and [Raspberry Pi](https://www.raspberrypi.org/). One critical step during this idea prototyping phase is to find out how to get the data out of the device for analytics. People usually choose to program the chip so it can save the data as files on a SD card. However, it would be useful to be able to stream data into analytical environment in real time. 

`arduinor` is a R package that can read data from serial port into R with minimum requirements of setup. Currently, there are several ways to do this in R, such as this [serial](https://cran.r-project.org/web/packages/serial/index.html) and the `file` and `scan` method as described in [this blog post](https://magesblog.com/post/2015-02-17-reading-arduino-data-directly-into-r/). However, these methods are either too obscured to be used correctly or they lack the ability to flush buffed data in the serial port. `arduinor` provides a largely simplified API to users and under the hood, it's using [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html) and imported the [arduino-serial](https://github.com/todbot/arduino-serial) C library. Basically users only need to provide the port name and baud rate, both of which can be easily found on the Arduino IDE, to be able to setup an connection. At the same time, it comes with a mechnism to forcefully dispose buffed data stuck in the serial port and makes the results more predictable and controllable. 

```r
# Example code of using arduinor
library(arduinor)
con <- ar_init("/dev/cu.SLAB_USBtoUART", baud = 9600)

# ar_monitor will print out the readings in R console until "Stopped"
ar_monitor(con)
> Flushing Port...
> 97922,44
> 98022,55
> 98122,69
> 98223,61
> ...
```

`arduinor` also provides a ploting app that can plot out signal inputs in real-time in a similar way as the "Serial Plotter" in the original Arduino IDE. With this app, people can choose to start/pause, reset, pick different variables and start to collect data into a file. By default, this function will split the string input by comma but user can provide their own separtion functions. 

![](ar_plotter.png)


# References