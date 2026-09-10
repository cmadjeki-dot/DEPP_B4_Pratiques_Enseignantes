# Modèles associatifs sur données simulées : exécuter depuis la racine du projet.
for(p in c("survey","yaml","ggplot2","modelsummary","gt")) if(!requireNamespace(p,quietly=TRUE)) stop("Package absent : ",p)
cfg <- yaml::read_yaml("config/modeles.yml")
config <- yaml::read_yaml("config/config.yml")
set.seed(cfg$graine)
source("R/functions/theme_depp_demo.R",encoding="UTF-8")
source("R/functions/descriptive.R",encoding="UTF-8")
source("R/functions/modeles.R",encoding="UTF-8")
chemins <- c("data/processed/base_analytique.rds","data/processed/design_depp.rds")
empreintes <- tools::md5sum(chemins)
b <- readRDS(chemins[1]); design <- readRDS(chemins[2])
j <- match(design$variables$id_enseignant,b$id_enseignant)
stopifnot(!anyNA(j),!anyDuplicated(b$id_enseignant),nrow(b)==nrow(design$variables),
  isTRUE(all.equal(as.numeric(weights(design)),b$poids_final[j])))
b <- b[j,]; rownames(b) <- b$id_enseignant
exporter <- function(t,nom) {
  rownames(t) <- NULL; t$avertissement <- rep(config$projet$avertissement,nrow(t))
  write.csv(t,paste0("outputs/tables/",nom,".csv"),row.names=FALSE,fileEncoding="UTF-8")
}
candidats <- c("degre","sexe","age","anciennete","anciennete_classe","secteur","education_prioritaire","territoire","effectif_classe","statut","formation_continue","equipement_numerique","discipline")
stopifnot(all(c(candidats,"CLUSTER_ID","flag_analyse_sensibilite") %in% names(b)))
audit <- do.call(rbind,lapply(candidats,function(v) {
  z <- b[[v]]; if(v=="discipline") z <- z[b$degre=="Collège"]
  t <- table(z); numerique <- is.numeric(z)
  data.frame(variable=v,n=length(z),missing=sum(is.na(z)),modalites=length(t),
    minimum=if(numerique) min(z,na.rm=TRUE) else NA_real_,maximum=if(numerique) max(z,na.rm=TRUE) else NA_real_,
    variance=if(numerique) var(z,na.rm=TRUE) else NA_real_,part_dominante=max(t)/sum(t),
    quasi_constante=max(t)/sum(t)>=cfg$seuil_quasi_constant,
    modalites_rares=if(!numerique) paste(names(t)[t<cfg$seuil_modalite_rare],collapse=" | ") else "Non applicable")
}))
exporter(audit,"audit_variables_modeles")
numeriques <- c("age","anciennete","anciennete_classe","effectif_classe","formation_continue")
exporter(data.frame(variable=numeriques,cor(b[numeriques],use="pairwise.complete.obs")),"redondance_modeles")
references <- c(degre="Premier degré",sexe="Femme",secteur="Public",education_prioritaire="Hors EP",territoire="Urbain",equipement_numerique="Faible")
for(v in names(references)) b[[v]] <- relevel(factor(b[[v]]),ref=references[[v]])
for(v in c("statut","discipline")) b[[v]] <- factor(b[[v]])
exporter(data.frame(variable=names(references),reference=unname(references)),"references_modeles")
b$anciennete_10 <- (b$anciennete-cfg$centre_anciennete)/cfg$unite_anciennete
b$effectif_5 <- (b$effectif_classe-cfg$centre_effectif)/cfg$unite_effectif
b$profil_2 <- ifelse(is.na(b$CLUSTER_ID),NA_real_,as.numeric(b$CLUSTER_ID==2))
stopifnot(setequal(na.omit(unique(b$CLUSTER_ID)),1:2))
# Les variables analytiques sont ajoutées au plan calibré, sans le reconstruire.
for(v in names(b)) design$variables[[v]] <- b[[v]]
source("R/functions/modeles_bivaries.R",encoding="UTF-8")
analyser_bivaries(b,design,candidats,exporter)

# Comparaisons de spécifications sur une même population complète par réponse.
formules <- list(
  mod_dif_1=SCORE_DIF~formation_continue,
  mod_dif_2=SCORE_DIF~formation_continue+anciennete_10+degre+secteur+education_prioritaire+territoire+effectif_5+equipement_numerique,
  mod_dif_final=SCORE_DIF~formation_continue+anciennete_10+degre+secteur+education_prioritaire+territoire+effectif_5+equipement_numerique+SCORE_COL+SCORE_DEV,
  mod_eva_1=SCORE_EVA~formation_continue,
  mod_eva_2=SCORE_EVA~formation_continue+anciennete_10+degre+education_prioritaire,
  mod_eva_final=SCORE_EVA~formation_continue+anciennete_10+degre+education_prioritaire+SCORE_EXP+SCORE_DIF+SCORE_DEV+SCORE_COL,
  mod_num_1=SCORE_NUM~equipement_numerique,
  mod_num_final=SCORE_NUM~equipement_numerique+formation_continue+anciennete_10+degre+territoire+secteur,
  mod_gap_final=GAP_DIF~CONTRAINTE_DIF+effectif_5+education_prioritaire+formation_continue+anciennete_10+degre+SCORE_DEV+SCORE_COL,
  mod_profil_final=profil_2~degre+anciennete_10+secteur+education_prioritaire+territoire+formation_continue+equipement_numerique)
finaux <- c("mod_dif_final","mod_eva_final","mod_num_final","mod_gap_final","mod_profil_final")
masques <- list(); modeles <- list()
for(n in finaux) masques[[all.vars(formules[[n]])[1]]] <- complete.cases(b[all.vars(formules[[n]])])
for(n in names(formules)) {
  y <- all.vars(formules[[n]])[1]
  modeles[[n]] <- ajuster_demo(formules[[n]],design,masques[[y]],if(y=="profil_2") quasibinomial() else gaussian())
  assign(n,modeles[[n]])
}
exporter(do.call(rbind,lapply(names(modeles),function(n) table_coefficients(modeles[[n]],n))),"specifications_modeles")
exporter(do.call(rbind,lapply(names(masques),function(y) data.frame(reponse=y,n_initial=nrow(b),n_analyse=sum(masques[[y]]),n_exclus_missing=sum(!masques[[y]])))),"selection_modeles")
source("R/functions/modeles_complements.R",encoding="UTF-8")
completer_modeles(modeles,finaux,b,design,masques,cfg,exporter)
diagnostics <- do.call(rbind,lapply(finaux,function(n) diagnostic_modele(modeles[[n]],n,exporter)))
exporter(diagnostics,"diagnostic_modeles")
tab <- do.call(rbind,lapply(finaux,function(n) table_coefficients(modeles[[n]],n)))
exporter(tab,"modeles_finaux")
# gt respecte exactement les IC et SE extraits des modèles survey.
html <- gt::gt(tab[c("modele","terme","effet","erreur_standard","effet_ic95_inf","effet_ic95_sup","p_value","n","unite_effet")],groupname_col="modele")
html <- gt::tab_header(html,title="Modèles associatifs des pratiques simulées")
html <- gt::cols_label(html,terme="Terme",effet="Estimation / OR",erreur_standard="SE du coefficient",effet_ic95_inf="IC 95 % inférieur",effet_ic95_sup="IC 95 % supérieur",p_value="p",n="n observé",unite_effet="Unité")
html <- gt::tab_options(html,table.font.size=11,data_row.padding=3)
html <- gt::tab_source_note(html,source_note=paste(config$projet$avertissement,"Poids finaux calibrés. SE sur l'échelle du coefficient, donc log-odds pour le modèle de profil. Aucun effet causal."))
html <- gt::fmt_number(html,columns=c("effet","erreur_standard","effet_ic95_inf","effet_ic95_sup"),decimals=3)
html <- gt::fmt(html,columns="p_value",fns=function(x) format.pval(x,digits=3,eps=.001))
gt::gtsave(html,"outputs/tables/modeles_finaux.html")
saveRDS(modeles,"outputs/models/modeles_statistiques.rds")
source("R/functions/interpretation_modeles.R",encoding="UTF-8")
interpreter_modeles(tab,diagnostics,config)
stopifnot(identical(empreintes,tools::md5sum(chemins)))
sources_provenance <- c(chemins,"R/12_models.R","config/modeles.yml","config/config.yml","renv.lock",list.files("R/functions",pattern="modeles.*[.]R$",full.names=TRUE),"R/functions/theme_depp_demo.R","R/functions/descriptive.R")
saveRDS(tools::md5sum(sources_provenance),"outputs/models/provenance_modeles.rds")
print(diagnostics,row.names=FALSE)
cat("Modèles et diagnostics terminés ; données sources préservées.\n")
