#include <Rcpp.h>
using namespace Rcpp;

/*
 * Example R Code
 * 
 * # Initiate the Class with a window-length of size 3
 * obj <- arduinor:::RunningMean$new(3)
 * 
 * # insert a new value
 * obj$insert(1.03)
 * obj$insert(1.05)
 * obj$insert(1.04)
 * 
 * # inspect the object 
 * obj
 * 
 * # get the running mean
 * obj$get_mean()
 * 
 * # add another value, effectively removing the first insert (1.03)
 * obj$insert(1.06)
 * obj
 * obj$get_mean()
 * 
 */

// defines the RunningMean class
class RunningMean{
public:
  RunningMean();
  RunningMean(int n);
  
  void insert(double val);
  double get_mean();
  void show();
  
private:
  std::deque<double> deq;
  const int n;
  int n_values;
  double sum;
};

// Exposes the class
RCPP_MODULE(RunningMeanModule) {
  class_<RunningMean>("RunningMean")
    .default_constructor("Default constructor")
    .constructor<int>("Constructor with an argument") 
    .method("insert", &RunningMean::insert)
    .method("get_mean", &RunningMean::get_mean)
    .method("show", &RunningMean::show)
    ;
}

