# Indice de Rand ajusté : invariant aux permutations des étiquettes de classes.
rand_ajuste <- function(a,b) {
  t <- table(a,b); comb <- function(v) sum(v*(v-1)/2)
  n <- sum(t); total <- n*(n-1)/2
  attendu <- comb(rowSums(t))*comb(colSums(t))/total
  denom <- (comb(rowSums(t))+comb(colSums(t)))/2-attendu
  if(abs(denom)<1e-12) return(if(identical(outer(a,a,"=="),outer(b,b,"==")))1 else 0)
  (comb(t)-attendu)/denom
}

inertie_classes <- function(x,g) sum(vapply(split(seq_len(nrow(x)),g),function(i) {
  z <- x[i,,drop=FALSE]; sum(sweep(z,2,colMeans(z))^2)
},numeric(1)))
