fattail <- function(x, alpha, c) {
  left <- (c/(2*alpha*gamma(1/c)))
  right <- exp(-1*((abs(x/alpha))^c))
  result <- left*right
  return(right)
}

ftmean <- function(alpha, c) {
  result <-(alpha*gamma(2/c))/gamma(1/c)
  return(result)
}
