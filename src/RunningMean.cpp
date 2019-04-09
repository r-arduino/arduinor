#include "RunningMean.h"


RunningMean::RunningMean() : n(0) {
  stop("n (size of window) must be supplied");
}

// Initiates a new Running Mean class of size n (constant)
RunningMean::RunningMean(int n) : n(n) {
  if (n <= 0) stop("n (size of window) must be supplied");
  deq.resize(n);
  n_values = 0;
  sum = 0;
}

// inserts a new value into the internal deque. Deletes the oldest value
void RunningMean::insert(double v) {
  if (n == 0) stop("n (size of window) must be larger than zero");
  
  // TODO: What happens if we insert a missing value? 
  if (!R_IsNA(v) && !R_IsNaN(v)) {
    n_values++;
    sum += v - deq.back();
    deq.push_front(v);
    deq.pop_back();
  }
}

// Returns the running mean of the values in the deque
// if the size is 0, return NA, if the number of already inserted values (n_values)
// is smaller than the size of the deque, use n_values. This allows the running mean 
// to return values even if the number of values is smaller than window lengths
// could also be set to NA if needed...
double RunningMean::get_mean() {
  if (n == 0) return NA_REAL;
  if (n_values < n) return(sum / n_values);
  return sum / n;
}

// prints the values of the deque
void RunningMean::show() {
  Rcout << "RunningMean object <" << static_cast<const void*>(this) << 
    "> window size " << n << ", number of inserts " << n_values << "\n" << 
      deq[0];
  for (int i = 1; i < n; ++i) {
    Rcout << " " << deq[i];
  }
  Rcout << "\n";
}

