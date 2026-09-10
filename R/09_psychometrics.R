# Psychométrie exploratoire sur la base nettoyée ; aucun score définitif.
if (!file.exists("config/psychometrie.yml")) stop("Exécuter depuis la racine du projet.")
for (p in c("psych", "yaml")) if (!requireNamespace(p, quietly=TRUE)) stop("Package absent : ",p," ; restaurer renv.")
cfg <- yaml::read_yaml("config/psychometrie.yml")
config <- yaml::read_yaml("config/config.yml")
set.seed(cfg$graine)
options(mc.cores=1)
chemin <- config$nettoyage$sortie_clean
empreinte <- tools::md5sum(chemin)
base <- readRDS(chemin)
dict <- read.csv("metadata/dictionnaire_variables.csv",fileEncoding="UTF-8")
dict <- dict[dict$bloc=="PRATIQUES",]
dimensions <- config$dimensions_latentes$dimensions
items <- unlist(lapply(dimensions,function(d) paste0(d,sprintf("%02d",1:6))))
stopifnot(length(items)==48L,setequal(items,dict$variable),all(items %in% names(base)),
          nrow(base)>0,!anyNA(base$id_enseignant),!anyDuplicated(base$id_enseignant))
x <- base[items]
stopifnot(all(vapply(x,is.numeric,logical(1))),all(is.na(as.matrix(x)) | as.matrix(x) %in% 1:5))
for (d in c("outputs/tables","outputs/models","outputs/figures")) dir.create(d,recursive=TRUE,showWarnings=FALSE)
exporter <- function(z,nom) {
  rownames(z) <- NULL
  z$avertissement <- config$projet$avertissement
  write.csv(z,paste0("outputs/tables/",nom,".csv"),row.names=FALSE,fileEncoding="UTF-8")
}
# Moments descriptifs des codes : asymétrie g1 et excès de kurtosis g2 (moments non corrigés).
diagnostic <- do.call(rbind,lapply(items,function(nom) {
  v <- x[[nom]]; y <- v[!is.na(v)]; stopifnot(length(y)>2,stats::var(y)>0)
  f <- tabulate(y,nbins=5); m2 <- mean((y-mean(y))^2)
  z <- data.frame(variable=nom,dimension=sub("[0-9]+$","",nom),n_valide=length(y),
    moyenne=mean(y),mediane=median(y),ecart_type=sd(y),variance=var(y),
    asymetrie=mean((y-mean(y))^3)/m2^1.5,kurtosis_exces=mean((y-mean(y))^4)/m2^2,
    taux_missing=mean(is.na(v)),proportion_min=f[1]/length(y),proportion_max=f[5]/length(y),
    nb_modalites=sum(f>0),modalites_utilisees=paste(which(f>0),collapse="|"))
  for(k in 1:5) {z[[paste0("n_",k)]] <- f[k]; z[[paste0("proportion_",k)]] <- f[k]/length(y)}
  z$flag_quasi_constant <- max(f)/length(y)>=cfg$seuil_concentration | sd(y)<cfg$seuil_ecart_type
  z$flag_asymetrie <- abs(z$asymetrie)>cfg$seuil_asymetrie
  z$flag_plancher <- z$proportion_min>=cfg$seuil_extremite
  z$flag_plafond <- z$proportion_max>=cfg$seuil_extremite
  z$flag_missing <- z$taux_missing>cfg$seuil_missing
  z
}))
exporter(diagnostic,"diagnostic_items_psychometrie")
alphas <- omegas <- total <- kmos <- msa <- correlations <- paralleles <- decisions <- charges <- list()
avertissements <- character()
# Les avertissements restent visibles et sont archivés avec leur bloc.
surveiller <- function(expr,bloc) withCallingHandlers(expr,warning=function(w) {
  avertissements <<- c(avertissements,paste(bloc,conditionMessage(w),sep=" : "))
})
for (d in c(dimensions,"global")) {
  noms <- if(d=="global") items else paste0(d,sprintf("%02d",1:6))
  brut <- x[noms]; z <- brut[complete.cases(brut),,drop=FALSE]; n <- nrow(z)
  stopifnot(n>ncol(z)+2,all(vapply(z,function(v)length(unique(v))==5,logical(1))))
  cat("Analyse",d,":",n,"cas complets sur",nrow(brut),"\n")
  # Pas de lissage silencieux : arrêt si la matrice empirique n'est pas définie positive.
  poly <- surveiller(psych::polychoric(z,smooth=FALSE,global=TRUE,correct=.5,progress=FALSE),d)
  r <- poly$rho; ev <- eigen(r,symmetric=TRUE,only.values=TRUE)$values
  stopifnot(all(is.finite(r)),min(ev)>0,max(abs(r))<=1+1e-8)
  saveRDS(r,paste0("outputs/models/correlations_polychoric_",d,".rds"))
  vals <- r[lower.tri(r)]
  correlations[[d]] <- data.frame(dimension=d,n_complets=n,n_total=nrow(brut),
    correlation_min=min(vals),correlation_mediane=median(vals),correlation_max=max(vals),
    nb_negatives=sum(vals<0),valeur_propre_min=min(ev))
  print(correlations[[d]],row.names=FALSE)
  km <- psych::KMO(r)
  # Bartlett de référence sur Pearson/cas complets ; ordinal et plan complexe : p indicative.
  bart <- psych::cortest.bartlett(cor(z),n=n)
  kmos[[d]] <- data.frame(dimension=d,n_complets=n,KMO=km$MSA,MSA_min=min(km$MSAi),
    nb_MSA_faibles=sum(km$MSAi<cfg$seuil_msa),bartlett_chi2=bart$chisq,bartlett_ddl=bart$df,
    bartlett_p_indicative=bart$p.value,methode="KMO polychorique ; Bartlett Pearson, approximation iid")
  msa[[d]] <- data.frame(dimension=d,variable=names(km$MSAi),MSA=unname(km$MSAi))
  if(d=="global") next
  a <- surveiller(psych::alpha(z,check.keys=FALSE,warnings=TRUE),d)
  alphas[[d]] <- data.frame(dimension=d,n_complets=n,nb_items=ncol(z),alpha_brut=a$total$raw_alpha,
    alpha_standardise=a$total$std.alpha,correlation_Pearson_moyenne=a$total$average_r,
    flag_alpha_excessif=a$total$raw_alpha>=cfg$seuil_alpha_redondance)
  # Modèle congénérique à un facteur, résidus non corrélés ; oméga sur réponses latentes standardisées.
  fa <- surveiller(psych::fa(r,nfactors=1,n.obs=n,rotate="none",fm="minres",scores="none"),d)
  lambda <- as.numeric(fa$loadings[,1]); if(sum(lambda)<0) lambda <- -lambda
  unicites <- fa$uniquenesses
  admissible <- all(unicites>0 & unicites<=1) && all(is.finite(lambda))
  omega <- if(admissible) sum(lambda)^2/(sum(lambda)^2+sum(unicites)) else NA_real_
  omegas[[d]] <- data.frame(dimension=d,n_complets=n,omega_total_ordinal=omega,
    omega_hierarchique=NA_real_,modele_admissible=admissible,alpha_brut=a$total$raw_alpha,
    reserve="Omega latent ordinal ; alpha sur codes observés : métriques distinctes. Aucun modèle hiérarchique justifié.")
  charges[[d]] <- data.frame(dimension=d,variable=noms,charge=lambda,communalite=fa$communality,unicite=unicites)
  saveRDS(fa,paste0("outputs/models/modele_un_facteur_",d,".rds"))
  # Analyse parallèle ordinale : permutation des colonnes, marges conservées, 100 réplications.
  set.seed(cfg$graine+match(d,dimensions))
  png(paste0("outputs/figures/parallel_",d,".png"),width=1500,height=1000,res=140)
  par(mar=c(6,5,4,2))
  pa <- surveiller(psych::fa.parallel(z,fa="fa",fm="minres",cor="poly",n.iter=cfg$iterations_parallel,
    sim=FALSE,quant=cfg$quantile_parallel,SMC=FALSE,plot=TRUE,
    main=paste("Analyse parallèle ordinale —",d),ylabel="Valeurs propres factorielles"),d)
  mtext("Source : données simulées DEPP_B4 — aucun résultat officiel DEPP",side=1,line=4,cex=.75)
  mtext("Cas complets non pondérés ; permutations ; seuil au quantile 95 %",side=1,line=5,cex=.75)
  dev.off()
  saveRDS(pa,paste0("outputs/models/parallel_",d,".rds"))
  paralleles[[d]] <- data.frame(dimension=d,facteurs_theoriques=1,facteurs_suggeres=pa$nfact,
    n_complets=n,iterations=cfg$iterations_parallel,
    commentaire=if(pa$nfact==1) "Compatible avec un facteur ; confronter au contenu et aux résidus" else "Divergence avec un facteur ; réexaminer la structure")
  diag_d <- diagnostic[match(noms,diagnostic$variable),]
  moyenne_r <- (rowSums(r)-1)/(ncol(r)-1)
  r_sans_diag <- r; diag(r_sans_diag) <- NA
  flag_liaison <- a$item.stats$r.drop<cfg$seuil_item_total | moyenne_r<cfg$seuil_correlation_moyenne
  flag_structure <- lambda<cfg$seuil_charge | fa$communality<cfg$seuil_communalite | km$MSAi<cfg$seuil_msa
  flag_distribution <- diag_d$flag_quasi_constant | diag_d$flag_asymetrie | diag_d$flag_plancher | diag_d$flag_plafond | diag_d$flag_missing
  flag_redondance <- apply(r_sans_diag,1,max,na.rm=TRUE)>cfg$seuil_redondance
  examiner <- flag_liaison | flag_structure | flag_redondance | diag_d$flag_quasi_constant | diag_d$flag_missing |
    ((diag_d$flag_plancher | diag_d$flag_plafond) & diag_d$flag_asymetrie)
  total[[d]] <- data.frame(variable=noms,dimension=d,libelle=dict$libelle[match(noms,dict$variable)],
    n_complets=n,item_total_corrige=a$item.stats$r.drop,moyenne_dimension=mean(rowMeans(z)),
    variance=diag_d$variance,alpha_si_supprime=a$alpha.drop$raw_alpha,correlation_poly_moyenne=moyenne_r,
    charge=lambda,communalite=fa$communality,MSA=km$MSAi,
    flag_liaison=flag_liaison,flag_structure=flag_structure,flag_distribution=flag_distribution,
    flag_redondance=flag_redondance,decision_preliminaire=ifelse(examiner,"A_EXAMINER","CONSERVER"),
    raison=paste0("liaison=",flag_liaison," ; structure=",flag_structure," ; distribution=",flag_distribution,
      " ; redondance=",flag_redondance," ; conservation provisoire, contenu à revoir"))
  compatible <- pa$nfact==1 && admissible && !any(flag_structure) && min(vals)>0
  avis <- if(compatible) "PLUTOT_OUI" else if(pa$nfact>1 && any(flag_structure)) "NON" else "INCERTAIN"
  decisions[[d]] <- data.frame(dimension=d,unidimensionnelle=avis,niveau_confiance=if(compatible) "MODERE" else "FAIBLE",
    arguments=sprintf("PA=%s ; r=[%.3f;%.3f] ; alpha=%.3f ; omega=%.3f ; charge min=%.3f ; h2 min=%.3f ; %s items à examiner",
      pa$nfact,min(vals),max(vals),a$total$raw_alpha,omega,min(lambda),min(fa$communality),sum(examiner)),
    decision="Conserver les six items à ce stade ; revue conceptuelle et structure globale avant validation du score")
}
for (nom in c("alphas","omegas","total","kmos","msa","correlations","paralleles","decisions","charges")) {
  sortie <- switch(nom,alphas="alpha_cronbach",omegas="omega_mcdonald",total="item_total_analysis",
    kmos="kmo_bartlett",msa="msa_par_item",correlations="diagnostic_correlations_polychoric",
    paralleles="nombre_facteurs_parallel",decisions="decision_unidimensionnalite",charges="charges_un_facteur")
  exporter(do.call(rbind,get(nom)),sortie)
}
writeLines(enc2utf8(unique(avertissements)),"outputs/tables/avertissements_psychometrie.txt",useBytes=TRUE)
capture.output(sessionInfo(),file="outputs/tables/session_psychometrie.txt")
source("R/functions/figures_parallel.R",encoding="UTF-8")
dessiner_parallel(dimensions,cfg$quantile_parallel)
source("R/functions/sensibilite_psychometrie.R",encoding="UTF-8")
sensibilite_psychometrie(base,dimensions,cfg,config,exporter)
stopifnot(identical(empreinte,tools::md5sum(chemin)),length(alphas)==8L,length(kmos)==9L)
print(do.call(rbind,decisions),row.names=FALSE)
cat(config$projet$avertissement,"\n48 items conservés ; base source inchangée.\n")
