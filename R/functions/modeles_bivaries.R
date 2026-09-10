# Bivariées exploratoires, sans sélection automatique des covariables.
analyser_bivaries <- function(b,design,candidats,exporter) {
  resultats <- list(); formes <- list(); nuages <- list()
  for(y in c("SCORE_DIF","SCORE_EVA","SCORE_NUM")) for(v in candidats) {
    cat("Bivariée :",y,"/",v,"\n")
    masque <- complete.cases(b[c(y,v)])
    if(v=="discipline") masque <- masque & b$degre=="Collège"
    d <- design; d$variables$.x <- b[[v]]; d$variables$.y <- b[[y]]
    m <- ajuster_demo(.y~.x,d,masque)
    p <- as.numeric(survey::regTermTest(m,~.x)$p)
    cle <- paste(y,v)
    if(is.numeric(b[[v]])) {
      ci <- confint(m)[2,]
      resultats[[cle]] <- data.frame(score=y,variable=v,modalite="Quantitative",n=sum(masque),
        estimation=unname(coef(m)[2]),ic95_inf=ci[1],ic95_sup=ci[2],type="Pente linéaire par unité",p_global=p,
        correlation_ponderee=correlation_ponderee(b[[v]],b[[y]],weights(design)),
        correlation_non_ponderee=cor(b[[v]][masque],b[[y]][masque]))
      d$variables$.x_centre <- b[[v]]-mean(b[[v]][masque])
      q <- ajuster_demo(.y~.x_centre+I(.x_centre^2),d,masque)
      formes[[cle]] <- data.frame(score=y,variable=v,p_courbure=as.numeric(survey::regTermTest(q,~I(.x_centre^2))$p),
        commentaire="Quadratique exploratoire centrée ; test non utilisé comme sélection automatique")
      nuages[[cle]] <- data.frame(score=y,variable=v,x=b[[v]][masque],y=b[[y]][masque],poids=weights(design)[masque])
    } else {
      resultats[[cle]] <- do.call(rbind,lapply(sort(unique(as.character(b[[v]][masque]))),function(g) {
        i <- masque & as.character(b[[v]])==g
        dd <- d[i,]; jj <- match(dd$variables$id_enseignant,b$id_enseignant)
        valeurs <- b[[y]][jj]; valeurs[weights(dd)<=0] <- NA_real_
        t <- resumer_continue(dd,valeurs)
        data.frame(score=y,variable=v,modalite=g,n=t$n,estimation=t$moyenne_ponderee,
          ic95_inf=t$ic95_inf,ic95_sup=t$ic95_sup,type="Moyenne pondérée",p_global=p,
          correlation_ponderee=NA_real_,correlation_non_ponderee=NA_real_)
      }))
    }
  }
  tab <- do.call(rbind,resultats)
  cle <- paste(tab$score,tab$variable)
  uniques <- !duplicated(cle)
  tab$p_global_BH <- p.adjust(tab$p_global[uniques],method="BH")[match(cle,cle[uniques])]
  exporter(tab,"bivariate_scores")
  exporter(do.call(rbind,formes),"formes_bivariees")
  donnees <- do.call(rbind,nuages)
  graphique <- ggplot2::ggplot(donnees,ggplot2::aes(x,y)) + ggplot2::geom_point(alpha=.07,size=.4) +
    ggplot2::geom_smooth(ggplot2::aes(weight=poids),method="lm",formula=y~x,se=FALSE,colour="#2166AC") +
    ggplot2::geom_smooth(ggplot2::aes(weight=poids),method="lm",formula=y~poly(x,2),se=FALSE,colour="#B35806",linetype=2) +
    ggplot2::facet_wrap(ggplot2::vars(score,variable),scales="free_x",ncol=4) +
    ggplot2::labs(title="Relations quantitatives : droite et courbe quadratique",subtitle="Ajustements pondérés descriptifs ; bleu : linéaire, orange : quadratique",x="Valeur du prédicteur (années, élèves ou jours)",y="Score 1–5")
  sauver_figure_demo(graphique,"relations_quantitatives",14,10)
}
