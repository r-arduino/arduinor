#include <Rcpp.h>
using namespace Rcpp;

#include "arduino-serial/arduino-serial-lib.h"

// [[Rcpp::export]]
int test(int fd)
{
  serialport_close(fd);
}
