library(haven)
library(data.table)
library(ggplot2)
library(bit64)


options(scipen = 999)

rm(list=ls())
cat('\014')
x11()


setwd('I:/Workdata/707906/js/ChildhoodPredictability')

# Load plans
dat<- as.data.table(read_dta('P:/Workdata/707906/imh/Childhood Predictability/Data/cohort_2004.dta'))
parents<- as.data.table(read_dta('P:/Workdata/707906/imh/Childhood Predictability/Data/parental_characteristics.dta'))

parents[far]
pnrs<-rbind(
  dat[,.(pnr=as.integer64(pnr),type='kid')],
  parents[,.(pnr=as.integer64(mor_id),type='mom')],
  parents[,.(pnr=as.integer64(far_id),type='dad')]
)

pnrs<-na.omit(unique(pnrs,by='pnr'))


# load data
demo_dt <- fread('../DATA/bef_25.csv' )

lpr_old_adm  <- fread('../DATA/LPRADMUPD_25.csv' )

lpr_new_adm  <- fread('../DATA/LPR_A_KONTAKT_25.csv' )
lpr_new_diag <- fread('../DATA/LPR_A_DIAGNOSE_25.csv' )

psyk_adm  <- fread('../DATA/PSYK_ADM_25.csv' )
psyk_diag <- fread('../DATA/PSYK_DIAG_25.csv' )

sssy <- fread('../DATA/SSSYUPD02_25.csv' )

lpr_new_adm[,pnr:=as.integer64(PNR)]
psyk_adm[,pnr:=as.integer64(PNR)]

#only sample
both  <-merge(unique(demo_dt[,. (pnr=PNR ,FOED_DAG,KOEN)],by='pnr'),
              pnrs[,.(pnr,type)],'pnr',all.y=T)

both[,cohort:=as.integer(substr(FOED_DAG,7,10))]


psyk_adm2  <- psyk_adm [pnr %in% both$pnr]
psyk_adm2[,year:=as.integer(substr(D_INDDTO,6,9))]
psyk_diag2 <- psyk_diag[RECNUM %in% psyk_adm2$RECNUM]

lpr_new_adm2  <- lpr_new_adm [pnr %in% both$pnr]
lpr_new_diag2 <- lpr_new_diag[DW_EK_KONTAKT %in% lpr_new_adm2$DW_EK_KONTAKT]

# find year/date
lpr_new_adm2

# Collect
old<-merge(psyk_adm2[,.(pnr,RECNUM,reason=C_KONTAARS,year)],
           psyk_diag2[,.(RECNUM,diagnose=C_DIAG,type=C_DIAGTYPE,sec_diagnose=C_TILDIAG)],
           'RECNUM')
old[,.N,.(year)]
old<- merge(old,both[,.(pnr,cohort)],'pnr',all.x=T)
old[,age:=year-cohort]

new<-merge(lpr_new_adm2[,.(pnr,DW_EK_KONTAKT,age=BORGER_ALDER_AAR_IND,reason=KONT_AARSAG,year=as.integer(substr(KONT_STARTTIDSPUNKT,6,9)))],
           lpr_new_diag2[,.(DW_EK_KONTAKT,diagnose=DIAG_KODE,type=DIAG_KODE_TYPE)],
           'DW_EK_KONTAKT')
new[,.N,.(age)]
new[,.N,.(year)]




diagnosis<-rbind(
  old[,.(pnr,year,age,diagnose)],
  new[,.(pnr,year,age,diagnose)],
  fill=T)

diagnosis[,.(.N),.(age,year)]

diagnosis[,diag_1:=substr(diagnose,1,2)]
diagnosis[,diag_2:=as.integer64(substr(diagnose,3,4))]



diag<-diagnosis[diag_1=='DF' & diag_2 %in% c(32:34,40:48), .(pnr,age,year,diagnose)]

diag<-merge(diag,both[,.(pnr,type)],'pnr')

diag[,.(.N,mean(age,na.rm=T)),.(type)]

diag[,pnr:=as.character(pnr)]
####


write_dta(diag,path = 'P:/Workdata/707906/imh/Childhood Predictability/Data/mental_health_diagnoses.dta')


######
# Switch to visits


sssy2  <- sssy [PNR %in% both$pnr, .(pnr=PNR,year=sssyupd02SourceYear,SPEC2,SPECIALE )]
sssy2[,.N,year]

sssy2<-merge(sssy2,both[,.(pnr,cohort,type)],'pnr')

sssy2[,age:=year-cohort]

sssy2[,.N,.(SPEC2,type)]
sssy2[,.N,.(cohort)]

sssy2[,pnr:=as.character(as.numeric(pnr))]


write_dta(sssy2,path = 'P:/Workdata/707906/imh/Childhood Predictability/Data/mental_health_visits.dta')
