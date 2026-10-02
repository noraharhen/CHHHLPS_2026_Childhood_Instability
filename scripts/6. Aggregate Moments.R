library(haven)
library(data.table)
library(ggplot2)
library(bit64)


options(scipen = 999)

rm(list=ls())
cat('\014')
x11()


setwd('I:/Workdata/707906/js/ChildhoodPredictability')

# Load data
dat<- as.data.table(read_dta('P:/Workdata/707906/imh/Childhood Predictability/Data/data_cohort2004_final.dta'))


dt<- dat[ResponseStatus == "Completed" & timetakenseconds >= 300]

dt[is.na(depression),depression:=0]
dt[is.na(anxiety),anxiety:=0]

dt[,QUIC_100:= (QUIC_38_score/38)*100]

dt[,GAD7_01:= (GAD7_score/21)]
dt[,PHQ8_01:= (PHQ8_score/24)]

# QUIC distribution
quic_dist<-dt[,.(QUIC_count = .N),.(QUIC_38_score)]
quic_dist[QUIC_count<5,QUIC_count:=NA]


#yes / no splits
tt_by<-function(DT,x,group){
  # x<-as.character(substitute(x))
  # group<-as.character(substitute(group))
  
  res<-DT[,{
    v<-get(x)
    tt<-t.test(v)
    list(
      est=unname(tt$estimate),
      lo = tt$conf.int[1],
      hi = tt$conf.int[2],
      N = sum(!is.na(v)),
      txt = fifelse(get(group)==1,'Yes','No')
    )
  },
  by=group]
  res[,(group):=NULL]
  res[]
}



specs<- list(
  list(name="q_3_5",x='parents_split',gr='QUIC_3_5'),
  list(name="q_5_2",x='parents_avg_grossinc_real',gr='QUIC_5_2'),
  list(name="q_3_6a",x='mor_n_partners',gr='QUIC_3_6'),
  list(name="q_3_6b",x='far_n_partners',gr='QUIC_3_6'),
  
  list(name="q_4_2",x='n_adresse_id',gr='QUIC_4_2'),
  list(name="q_4_3",x='n_schools',gr='QUIC_4_3'),
  list(name="q_3_3a",x='mor_unemp_days_total',gr='QUIC_3_3'),
  list(name="q_3_3b",x='far_unemp_days_total',gr='QUIC_3_3')
  
)


moments <- rbindlist(lapply(specs, function(s){
  tt_by(dt,s$x,s$gr)[,spec:= s$name]
}),use.names=T,fill=T)

moments[,txt:=paste0(txt,' (N= ',N,')')]




# setup text object

titles<-data.table(
  spec = c('q_3_5','q_5_2','q_3_6a','q_3_6b','q_4_2','q_4_3','q_3_3a','q_3_3b'),
  titles=c(
    '(a) QUIC 3.5: My parents got divorced',
    '(b) QUIC 5.2: There was a period of time when I often worried that my family would not have enough money to pay for necessities like clothing or bills',
    '(c) QUIC 3.6: At least one of my parents had many romantic partners',
    '(d) QUIC 3.6: At least one of my parents had many romantic partners',
    '(e) QUIC 4.2: I moved frequently',
    '(f) QUIC 4.3 I changed schools frequently',
    "(g) QUIC 3.3: There were times when one of my parents was unemployed and couldn't find a job even though he/she wanted one",
    "(h) QUIC 3.3: There were times when one of my parents was unemployed and couldn't find a job even though he/she wanted one"
  ),
  axes=c(
    "Parents Split (Fraction)",
    "Avg. Parental Gross Income (DKK)",
    "Mom's Number of Partners",
    "Dad's Number of Partners",
    "Number of Residential Adresses",
    "Number of Schools",
    "Mom's Unemployment (Days)",
    "Dad's Unemployment (Days)"
  )
)

write.table(quic_dist,file='../data/quic_dist.txt',sep=';',row.names = F)
write.table(moments,file='../data/moments.txt',sep=';',row.names = F)
write.table(titles,file='../data/titles.txt',sep=';',row.names = F)


#######
#######



cols_std<-c('cognitive_score','math_score','raven_score')
dt[!is.na(cognitive_score),paste0(cols_std,'_std') := lapply(.SD,function(v) (v-mean(v,na.rm=T)) / sd(v,na.rm=T)), .SDcols=cols_std ]


dt[,parents_avg_grossinc_100k:=parents_avg_grossinc_real/1e5]
dt[,parents_unemp_years_total := parents_unemp_days_total/365.25]

dt[,mom_dead := fifelse(!is.na(mor_doddato),1,0)]
dt[,dad_dead := fifelse(!is.na(far_doddato),1,0)]

dt[,high_school := fifelse(gymnasie == "Fuldf?r",1,0)]

dt[,parents_inc_terc:=cut(parents_avg_grossinc_100k,
                          breaks=c(-Inf,quantile(parents_avg_grossinc_100k,probs=(1:2)/3,na.rm=T),Inf),
                          labels=c('Low Income','Middle Income','High Income'),include.lowest=T)]

dt[,parental_educ_sum := mor_educ_years + far_educ_years]
dt[,parental_educ_terc:=cut(parental_educ_sum,
                            breaks=c(-Inf,quantile(parental_educ_sum,probs=(1:2)/3,na.rm=T),Inf),
                            labels=c('Low Education','Middle Education','High Education'),include.lowest=T)]

##
#define dictionary for y's and x's

dict<-
  c(
    gpa_all = 'Average GPA',
    high_school = 'High School Completion',
    QUIC_std = "QUIC",
    female = "Female",
    parents_avg_grossinc_100k = "Avg. Household Gross Income (100 000 DKK)",
    mor_educ_years = "Mother's Education (Years)",
    far_educ_years = "Father's Education (Years)",
    parents_split = "Parents Split",
    mor_n_partners = "Mom Number of Partners",
    far_n_partners = "Dad Number of Partners",
    mom_dead = "Mom Died",
    dad_dead = "Dad Died",
    n_adresse_id = "Number of Residential Addresses",
    n_schools = "Number of Schools",
    parents_unemp_years_total = "Parental Unemployment (Years)",
    mor_depression_0422 = "Mom Depression",
    mor_anxiety_0422 = "Mom Anxiety",
    far_depression_0422 = "Dad Depression",
    far_anxiety_0422 = "Dad Anxiety",
    cognitive_score_std = "Cognitive Reflection",
    math_score_std = "Probabilistic Reasoning",
    raven_score_std = "Raven Score"
  )
setFixest_dict(dict)

# define dict for grouping
dict_group<-
  c(
    QUIC_std = "Subjective Unpredictability",
    female = "Gender",
    parents_avg_grossinc_100k = "Parental SES",
    mor_educ_years = "Parental SES",
    far_educ_years = "Parental SES",
    parents_split = "Objective Instability",
    mor_n_partners = "Objective Instability",
    far_n_partners = "Objective Instability",
    mom_dead = "Objective Instability",
    dad_dead = "Objective Instability",
    n_adresse_id = "Objective Instability",
    n_schools = "Objective Instability",
    parents_unemp_years_total = "Objective Instability",
    mor_depression_0422 = "Parental Mental Health",
    mor_anxiety_0422 = "Parental Mental Health",
    far_depression_0422 = "Parental Mental Health",
    far_anxiety_0422 = "Parental Mental Health",
    cognitive_score_std = "Cognitive Ability",
    math_score_std = "Cognitive Ability",
    raven_score_std = "Cognitive Ability"
  )








###

# Fit all the models


fit1<-feols(c(gpa_all,high_school)~QUIC_std+female+parents_avg_grossinc_100k+mor_educ_years+far_educ_years+
              sw(cognitive_score_std+math_score_std+raven_score_std,
                 parents_split+mor_n_partners+far_n_partners+n_adresse_id+n_schools+parents_unemp_years_total+mom_dead+dad_dead,
                 mor_depression_0422+mor_anxiety_0422+far_depression_0422+far_anxiety_0422,
                 cognitive_score_std+math_score_std+raven_score_std+
                   parents_split+mor_n_partners+far_n_partners+n_adresse_id+n_schools+parents_unemp_years_total+
                   mom_dead+dad_dead+mor_depression_0422+mor_anxiety_0422+far_depression_0422+far_anxiety_0422),
            data=dt)

etable(fit1,vcov='HC1')


n<-as.data.table(vapply(as.list(fit1),nobs,1L))
colnames(n)<-'N'
n[,id:=1:8]


ci<-confint(fit1,vcov='HC1',level=0.95)
est<-coef(fit1)
est_long<-reshape2::melt(est,id.vars=c('id'),measure.vars=c(4:24),
               variable.name = "var", value.name = "estimate")


coef<-data.table(
  id=ci$id,
  outcome=ci$lhs,
  var=ci$coefficient,
  lo=ci$`2.5 %`,
  hi=ci$`97.5 %`
)

coef<-merge(coef,est_long,c('id','var'))
coef<-merge(coef,n,c('id'))


coef[,title:=dict[var]]
coef[,outcome2:=dict[outcome]]

coef[,group:=dict_group[var]]

ggplot(coef[id==2 & !is.na(title)],aes(estimate,title))+
  geom_vline(xintercept = 0)+geom_errorbarh(aes(xmin=lo,xmax=hi),height=0)+
  geom_point()

###
# Compute reg lines

fit2<-feols(c(gpa_all,high_school)~sw(QUIC_std*parents_inc_terc,QUIC_std*parental_educ_terc),
            data=dt)
etable(fit2)

plots<-data.table()
for (i in 1:4){
  f<-fit2[[i]]
  
  # Check if parental income
  if(substr(rownames(f$coeftable)[3],1,16) == 'parents_inc_terc'){
    plot_lines<-as.data.table(expand.grid(
      QUIC_std=seq(-2,2,0.05),
      parents_inc_terc=c('Low Income','Middle Income','High Income')
    ))
  }else{
    plot_lines<-as.data.table(expand.grid(
      QUIC_std=seq(-2,2,0.05),
      parental_educ_terc=c('Low Education','Middle Education','High Education')
    ))
  }
  
  # Check if y == GPA
  if(as.character(f$fml)[2] == 'gpa_all'){
    x_label='Average GPA'
  }else{
    x_label='High School Completion'
  }
  
  pred<-predict(f,newdata=plot_lines,se.fit=T,level=0.95,interval = 'confidence',vcoc='HC1')
  plot_lines<-cbind(plot_lines,pred)
  
  plot_lines[,id:=i]
  plot_lines[,outcome2:=x_label]
  
  if(substr(rownames(f$coeftable)[3],1,16) == 'parents_inc_terc'){
    plot_lines[,group:=parents_inc_terc]
  }else{
    plot_lines[,group:=parental_educ_terc]
  }
  
  
  #collect in one object
  plots<-rbind(plots,plot_lines,fill=T)
  
}

ggplot(plots,aes(QUIC_std,fit,color=group,fill=group))+geom_line()+
  geom_ribbon(aes(ymin=ci_low,ymax=ci_high),alpha=0.2,color=NA)+
  facet_wrap(~id,scales='free')


###


write.table(plots,file='../data/plot_lines.txt',sep=';',row.names = F)
write.table(coef,file='../data/coef.txt',sep=';',row.names = F)

# regress each obj instability at a time
#
fit3<-feols(c(gpa_all,high_school)~sw(parents_split,mor_n_partners,far_n_partners,n_adresse_id,n_schools,parents_unemp_years_total,mom_dead,dad_dead,
                                      parents_split+mor_n_partners+far_n_partners+n_adresse_id+n_schools+parents_unemp_years_total+mom_dead+dad_dead,
                                      parents_split+mor_n_partners+far_n_partners+n_adresse_id+n_schools+parents_unemp_years_total+mom_dead+dad_dead+
                                        QUIC_std+female+parents_avg_grossinc_100k+mor_educ_years+far_educ_years),
            data=dt)

etable(fit3[1:10],vcov='HC1',file = '../data/table_gpa.tex',replace = T)
etable(fit3[11:20],vcov='HC1',file = '../data/table_HS.tex',replace = T)

