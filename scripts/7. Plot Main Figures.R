library(tidyverse)
library(dplyr)
library(ggplot2)
library(ggdist)
library(patchwork)
library(data.table)
library(ggtext)

options(scipen = 999)

rm(list=ls())
cat("\014")

# setwd("C:/Users/sfx625/Dropbox/PROJECTS/Income_Denmark/Childhood Stability/code repository")
setwd("/Users/nharhen/Downloads/code repository/")

quic_dist<-fread('data/quic_dist.txt')
moments<-fread('data/moments.txt')
titles<-fread('data/titles.txt')
coef<-fread('data/coef.txt')
plot_lines<-fread('data/plot_lines.txt')


#################
# PLOT FIGURE 1 #
#################

###
titles[,under:=substr(titles,5,12)]
titles[,under2:=c(
  'Parents divorced',
  'Could not afford\n necessities',
  'Parents had many\n romantic partners',
  'Parents had many\n romantic partners',
  'Moved often',
  'Changed schools\n often',
  'Parents often\n unemployed',
  'Parents often\n unemployed'
)]

# 1,000 DKKK
moments[spec=='q_5_2',est:=est/1000]
moments[spec=='q_5_2',lo:=lo/1000]
moments[spec=='q_5_2',hi:=hi/1000]
titles[spec=='q_5_2',axes:="Avg. Parental Gross Income (000's DKK)"]

moments[,response:=fifelse(grepl("^Yes",txt),'Yes','No')]
moments[,txt2:=gsub(' (','\n(',txt, fixed = TRUE)]
moments[,txt2:=gsub(' ','',txt2)]



###
bar_width <- 0.9

large_font_size = 15
theme_common_large <- theme_classic() +
  theme(
    axis.text.x = element_text(size = large_font_size, color = "black"),
    axis.text.y = element_text(size = large_font_size, color = "black"),
    axis.title.x = element_text(size = large_font_size, color = "black"),
    axis.title.y = element_text(size = large_font_size, color = "black"),
    axis.line = element_line(linewidth = 0.8),
    plot.title = element_text(size = large_font_size, hjust = 0.5),
    legend.position = "none",
    plot.margin = margin_auto(0.2, unit = "cm")
  )

small_font_size = 10
theme_common_small <- theme_classic() +
  theme(
    axis.text.x = element_text(size = small_font_size, color = "black"),
    axis.text.y = element_text(size = small_font_size, color = "black"),
    axis.title.x = element_text(size = small_font_size, color = "black"),
    axis.title.y = element_text(size = small_font_size, color = "black"),
    axis.line = element_line(linewidth = 0.8),
    plot.title = element_text(size = small_font_size, hjust = 0.5),
    legend.position = "none",
    plot.margin = margin_auto(0.2, unit = "cm")
  )

quic_dist[,share:=QUIC_count/sum(QUIC_count,na.rm=T)]
median_quic <- quic_dist[!is.na(QUIC_count), median(rep(QUIC_38_score, QUIC_count))]
quic_max <- max(quic_dist$QUIC_38_score, na.rm = TRUE)

p1 <- ggplot(quic_dist,aes(QUIC_38_score,share,fill = QUIC_38_score))+geom_col(color='black')+
  scale_fill_gradientn(
    colours = c("#3f6ca6cc", "#ffffff", "#cf3119cc"),
    values = c(0, median_quic / quic_max, 1),
    limits = c(0, quic_max),
    name = "QUIC Score"
  ) +
  scale_y_continuous(expand = c(0,0))+
  labs(x = "QUIC Score", y = "Proportion") +
  theme_common_large +
  coord_cartesian(xlim = c(0, 38))

#plot comparisons
plots <- vector("list", length(titles$spec))
names(plots) <- titles$spec


for (q in titles$spec){
  mom_plot <- moments[spec==q]
  p <- ggplot(mom_plot, aes(x = response, y = est, fill = response)) +
    geom_col(width = bar_width, alpha = 0.8, color = NA) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0, linewidth = 1, color = "black") +
    scale_fill_manual(
      name = "Response",
      values = c("Yes" = "#cf3119", "No" = "#3f6ca6")
    ) +
    geom_text(
      aes(label = txt2, y = 0),   # small upward shift; adjust 1.02 as needed
      color = "white",
      vjust = -0.5,
      fontface = "bold",
      size=3
    ) +
    ylab(titles[spec==q]$axes) +
    xlab(titles[spec==q]$under2) +
    theme_common_small+
    theme(axis.text.x = element_blank(),axis.ticks.x = element_blank(),
          axis.title.x = element_text(margin = margin(t = 6)))+ 
    scale_y_continuous(expand = expansion(mult = c(0, 0.08)))
  p
  plots[[q]] <- p
  
}


rhs <- wrap_elements(
  panel = wrap_plots(plots, ncol = 4, nrow = 2, guides = "collect")
)

lhs <- p1 / plot_spacer() + plot_layout(heights = c(1, -0.02))  # 0.08 = spacer share
final <- lhs | rhs 
ggsave("figures/figure1.png", width = 16, height = 8)
ggsave("figures/figure1.pdf", width = 16, height = 8)

#################
# PLOT FIGURE 2 #
#################
font_size = 16
font_family = "Helvetica Neue"
theme_common <- theme_classic() +
  theme(
    axis.text.x = element_text(size = font_size, color = "black", family = font_family),
    axis.text.y = element_text(size = font_size, color = "black", family = font_family),
    axis.title.x = element_text(size = font_size, color = "black", family = font_family),
    axis.title.y = element_text(size = font_size, color = "black", family = font_family),
    axis.line = element_line(linewidth = 0.8),
    plot.title = element_text(size = font_size, hjust = 0.5),
    legend.position = "none"
  )


coef[title=='Avg. Household Gross Income (100 000 DKK)',title:='Household Gross Income']
coef[group=='Objective Instabilitys',group:='Objective Instability']
coef[group=='Objective Instability',group:='Unpredictability (admin records)']
coef[group=='Subjective Unpredictability',group:='Unpredictability (self-report)']
coef[title=='Dad Number of Partners',title:='Father Number of Partners']
coef[title=='Mom Number of Partners',title:='Mother Number of Partners']
coef[title=='Dad Anxiety',title:='Father Anxiety']
coef[title=='Mom Anxiety',title:='Mother Anxiety']
coef[title=='Dad Depression',title:='Father Depression']
coef[title=='Mom Depression',title:='Mother Depression']
coef <- coef[!title %in% c("Dad Died", "Mom Died")]

# sort order
# Fix: Use the cleaned-up 'title' field for `levels` for precise matching to avoid confusion between renamed titles and literal source names
coef$term <- factor(
  coef$title,
  levels = rev(c(
    "Female",
    "Raven Score",
    "Probabilistic Reasoning",
    "Cognitive Reflection",
    "Father's Education (Years)",
    "Mother's Education (Years)",
    "Household Gross Income",
    "Father Number of Partners",
    "Mother Number of Partners",
    "Number of Residential Addresses",
    "Number of Schools",
    "Parents Split",
    "Parental Unemployment (Years)",
    "Father Anxiety",
    "Father Depression",
    "Mother Anxiety",
    "Mother Depression",
    "QUIC"
  ))
)

out_plots<- list()

# # specify the desired models
# 1: SES + Cognitive
# 2: SES + Objective
# 3: SES + Parental Health
# 4: All

MODEL = 2

p_data<-setDT(coef[id %in% c(MODEL,MODEL+4) & !is.na(title)])

plots <- vector("list", 2)
names(plots) <- unique(p_data$outcome2)

for(q in names(plots)){
  dt <- copy(p_data[outcome2 == q][order(group, term)])
  dt[, pos := seq_len(.N), by = group]
  hdr <- unique(dt[, .(group)])
  hdr[, `:=`(
    term     = group,
    estimate = NA_real_, lo = NA_real_, hi = NA_real_,
    pos      = 0L
  )]
  
  dt2 <- rbind(dt, hdr, fill = TRUE)
  dt2[, term_id := paste(group, term, sep = "||")]
  
  dt2[, term_id := factor(term_id, levels = dt2[order(group, -pos), unique(term_id)])]
  
  
  lab_dt <- unique(dt2[, .(term_id, term, pos)])
  lab_dt[, term_lab := ifelse(pos == 0, paste0("*", term, "*"), as.character(term))]
  
  lab_vec <- setNames(lab_dt$term_lab, as.character(lab_dt$term_id))
  
  pal <- c(
    "Unpredictability (self-report)" = "#D7221C",
    "Unpredictability (admin records)" = "#FEB6A3",
    "Parental SES" = "#0b6198",
    "Gender" = "#9A4777"
  )
  # To reverse the order of groups on the y-axis, reverse the factor levels for the group variable
  dt2[, group_rev := factor(group, levels = rev(unique(group)))]
  dt2[, term_id_rev := paste(group_rev, term, sep = "||")]
  dt2[, term_id_rev := factor(term_id_rev, levels = dt2[order(group_rev, -pos), unique(term_id_rev)])]

  # Update label vector for the new term_id_rev
  lab_dt_rev <- unique(dt2[, .(term_id_rev, term, pos)])
  lab_dt_rev[, term_lab := ifelse(pos == 0, paste0("*", term, "*"), as.character(term))]
  lab_vec_rev <- setNames(lab_dt_rev$term_lab, as.character(lab_dt_rev$term_id_rev))

  p <-
    ggplot(dt2, aes(estimate, term_id_rev, color = group_rev, fill = group_rev)) +
      geom_vline(xintercept = 0, color = "black", linetype = "dotted", linewidth = 1) +
      geom_errorbarh(data = dt2[pos > 0], aes(xmin = lo, xmax = hi), height = 0, linewidth = 0.5) +
      geom_point(data = dt2[pos >= 0], size = 6) +
      scale_y_discrete(labels = lab_vec_rev) +
      scale_color_manual(values = pal) +
      scale_fill_manual(values = pal) +
      facet_grid(group_rev ~ ., scales = "free_y", space = "free_y") +
      theme_common +
      theme(
        axis.text.y = element_markdown(),  
        strip.text.y = element_blank(),
        strip.background = element_blank()
      ) +
      guides(color = "none", fill = "none") +
      xlab(q) + ylab(NULL)

  p
  plots[[q]] <- p
}

lhs <- wrap_elements(
  panel = wrap_plots(plots, ncol = 1, nrow = 2, guides = "collect")
)

high_income_hex <- "#065b8f"
middle_income_hex <- "#6397b8"
low_income_hex <- "#b0c9d9"

p2<-ggplot(plot_lines[id==1], aes(x = QUIC_std, y = fit, 
                                  color = group, fill = group)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1.5) +
  scale_color_manual(
    values = c("Low Income" = low_income_hex, "Middle Income" = middle_income_hex, "High Income" = high_income_hex),
    name = "Household Income"
  ) +
  scale_fill_manual(
    values = c("Low Income" = low_income_hex, "Middle Income" = middle_income_hex, "High Income" = high_income_hex),
    name = "Household Income"
  ) +
  theme_common +
  scale_color_manual(
    values = c("High Income" = high_income_hex, "Middle Income" = middle_income_hex, "Low Income" = low_income_hex),
    breaks = c("High Income", "Middle Income", "Low Income"),
    name = "Household Income"
  ) +
  scale_fill_manual(
    values = c("High Income" = high_income_hex, "Middle Income" = middle_income_hex, "Low Income" = low_income_hex),
    breaks = c("High Income", "Middle Income", "Low Income"),
    name = "Household Income"
  ) +
  theme(
    legend.position = c(0.9,0.9),
    legend.title = element_text(size = font_size - 4),
    legend.text = element_text(size = font_size - 6)
  ) +
  labs(
    x = "QUIC Score (Standardized)",
    y = "9th Grade GPA"
  )

p3<-ggplot(plot_lines[id==3], aes(x = QUIC_std, y = fit, 
                                  color = group, fill = group)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1.5) +
  scale_color_manual(
    values = c("Low Income" =low_income_hex, "Middle Income" = middle_income_hex, "High Income" = high_income_hex),
    name = "Household Income"
  ) +
  scale_fill_manual(
    values = c("Low Income" = low_income_hex, "Middle Income" = middle_income_hex, "High Income" = high_income_hex),
    name = "Household Income"
  ) +
  theme_common +
  theme(
    legend.position = 'none'
  ) +
  labs(
    x = "QUIC Score (Standardized)",
    y = "High School Completion"
  )

rhs <- wrap_elements(
  panel = wrap_plots(p2/p3, ncol = 1, nrow = 1)
)

# Increase the width of the rhs plots by changing plot_layout widths from c(2, 1) to c(2, 1.5)
final <- (lhs | rhs) + plot_layout(widths = c(2.3, 1.5))

ggsave("figures/figure2.png", width = 14, height = 12)
ggsave("figures/figure2.pdf", width = 14, height = 12)
