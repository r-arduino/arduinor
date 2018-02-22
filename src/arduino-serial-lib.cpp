// The MIT License (MIT)
//   
//   Copyright (c) 2014 Tod E. Kurt
//   
//   Permission is hereby granted, free of charge, to any person obtaining a copy
//   of this software and associated documentation files (the "Software"), to deal
//   in the Software without restriction, including without limitation the rights
//   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//   copies of the Software, and to permit persons to whom the Software is
//   furnished to do so, subject to the following conditions:
//     
//     The above copyright notice and this permission notice shall be included in all
//     copies or substantial portions of the Software.
//   
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//     SOFTWARE.
//   
//
// arduino-serial-lib -- simple library for reading/writing serial ports
//
// 2006-2013, Tod E. Kurt, http://todbot.com/blog/
// 
// Modified by Hao Zhu, 2018
//

#include <Rcpp.h>
using namespace Rcpp;

#include "arduino-serial-lib.h"

#include <stdio.h>    // Standard input/output definitions 
#include <unistd.h>   // UNIX standard function definitions 
#include <fcntl.h>    // File control definitions 
#include <errno.h>    // Error number definitions 
#include <termios.h>  // POSIX terminal control definitions 
#include <string.h>   // String function definitions 
#include <sys/ioctl.h>
#include <vector>

// uncomment this to debug reads
//#define SERIALPORTDEBUG 

// takes the string name of the serial port (e.g. "/dev/tty.usbserial","COM1")
// and a baud rate (bps) and connects to that port at that speed and 8N1.
// opens the port in fully raw mode so you can send binary data.
// returns valid fd, or -1 on error

//' Initiate a connection to the serial port
//' 
//' @param serialport Name of the serial port (e.g. "/dev/tty.usbserial","COM1")
//' @param baud Baud rate (bps) in integer. 
//' 
//' @description This function sets up a connection to the serial port at the 
//' specified port name and baud rate. The port is set in 8-N-1 mode and is
//' opened in fully raw mode so you can send binary data. 
//' 
//' @examples 
//' \dontrun{
//' # On Windows
//' con <- ar_init("COM1") 
//' 
//' # On Mac
//' con <- ar_init("/dev/cu.SLAB_USBtoUART")
//' }
//' 
//' @return If connection is setup successfully, this function will return the 
//' file descriptor. If not, it will return -1.
//' 
//' @export
// [[Rcpp::export]]
int ar_init(const char* serialport, int baud = 9600)
{
  struct termios toptions;
  int fd;
  
  fd = open(serialport, O_RDWR | O_NONBLOCK );
  
  if (fd == -1)  {
    perror("serialport_init: Unable to open port ");
    return -1;
  }
  
  //int iflags = TIOCM_DTR;
  //ioctl(fd, TIOCMBIS, &iflags);     // turn on DTR
  //ioctl(fd, TIOCMBIC, &iflags);    // turn off DTR
  
  if (tcgetattr(fd, &toptions) < 0) {
    perror("serialport_init: Couldn't get term attributes");
    return -1;
  }
  speed_t brate = baud; // let you override switch below if needed
  switch(baud) {
  case 4800:   brate=B4800;   break;
  case 9600:   brate=B9600;   break;
#ifdef B14400
  case 14400:  brate=B14400;  break;
#endif
  case 19200:  brate=B19200;  break;
#ifdef B28800
  case 28800:  brate=B28800;  break;
#endif
  case 38400:  brate=B38400;  break;
  case 57600:  brate=B57600;  break;
#ifdef B74880
  case 74880:  brate=B74880;  break;
#endif
  case 115200: brate=B115200; break;
  }
  cfsetispeed(&toptions, brate);
  cfsetospeed(&toptions, brate);
  
  // 8N1
  toptions.c_cflag &= ~PARENB;
  toptions.c_cflag &= ~CSTOPB;
  toptions.c_cflag &= ~CSIZE;
  toptions.c_cflag |= CS8;
  // no flow control
  toptions.c_cflag &= ~CRTSCTS;
  
  //toptions.c_cflag &= ~HUPCL; // disable hang-up-on-close to avoid reset
  
  toptions.c_cflag |= CREAD | CLOCAL;  // turn on READ & ignore ctrl lines
  toptions.c_iflag &= ~(IXON | IXOFF | IXANY); // turn off s/w flow ctrl
  
  toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // make raw
  toptions.c_oflag &= ~OPOST; // make raw
  
  // see: http://unixwiz.net/techtips/termios-vmin-vtime.html
  toptions.c_cc[VMIN]  = 0;
  toptions.c_cc[VTIME] = 0;
  //toptions.c_cc[VTIME] = 20;
  
  tcsetattr(fd, TCSANOW, &toptions);
  if( tcsetattr(fd, TCSAFLUSH, &toptions) < 0) {
    perror("init_serialport: Couldn't set term attributes");
    return -1;
  }
  
  return fd;
}

//' Close Connection to a serial port
//' 
//' @description This function closes the connection opened by `ar_init()`.
//' 
//' @param fd File descriptor returned by `ar_init()`. Should be an integer.
//' 
//' @examples
//' \dontrun{
//' con <- ar_init("/dev/cu.SLAB_USBtoUART") 
//' ar_close(con)
//' }
//' 
//' @export
// [[Rcpp::export]]
int ar_close( int fd )
{
  return close( fd );
}

int ar_writebyte( int fd, uint8_t b)
{
  int n = write(fd,&b,1);
  if( n!=1)
    return -1;
  return 0;
}

int ar_write(int fd, const char* str)
{
  int len = strlen(str);
  int n = write(fd, str, len);
  if( n!=len ) {
    perror("serialport_write: couldn't write whole string\n");
    return -1;
  }
  return 0;
}

// 
int ar_read_until(int fd, char* buf, char until, int buf_max, int timeout)
{
  char b[1];  // read expects an array, so we give it a 1-byte array
  int i=0;
  do { 
    int n = read(fd, b, 1);  // read a char at a time
    if( n==-1) return -1;    // couldn't read
    if( n==0 ) {
      usleep( 1 * 1000 );  // wait 1 msec try again
      timeout--;
      if( timeout==0 ) return -2;
      continue;
    }
    // printf("%d%d%c", i, n, b[0]); // debug
    //usleep(4000);
    buf[i] = b[0]; 
    i++;
  } while( b[0] != until && i < buf_max && timeout>0 );
  
  buf[i] = 0;  // null terminate the string
  return 0;
}

//' Read one entry of input from an opened serial connection
//' 
//' @description This function reads one entry of input from an opened serial
//' port. Each line of entry is identified by the end of line character 
//' `eolchar`. 
//' 
//' @param fd File descriptor returned by `ar_init()`. Should be an integer.
//' @param eolchar End of line character. Default value is `'\\n'`
//' @param buf_max Maximum length of one line of entry. Default is 256.
//' @param timeout Timeout for reads in millisecs. Default is 5000 ms.
//' 
//' @examples
//' \dontrun{
//' con <- ar_init("/dev/cu.SLAB_USBtoUART")
//' ar_read(con)
//' }
//' 
//' @export
// [[Rcpp::export]]
Rcpp::String ar_read(int fd, char eolchar = '\n', 
                     int buf_max = 256, int timeout = 5000)
{
  R_CheckUserInterrupt();
  char buf[buf_max];

  memset(buf,0,buf_max);
  ar_read_until(fd, buf, eolchar, buf_max, timeout);
  Rcpp::String out = buf;
  return(out);
}

//' Flush serial port
//' 
//' @description clearing the serial port's buffer
//' 
//' @param fd File descriptor returned by `ar_init()`. Should be an integer.
//' 
//' @examples
//' \dontrun{
//' con <- ar_init("/dev/cu.SLAB_USBtoUART")
//' ar_flush(con)
//' }
//' 
//' @export
// [[Rcpp::export]]
int ar_flush(int fd)
{
  sleep(2); //required to make flush work, for some reason
  return tcflush(fd, TCIOFLUSH);
}
