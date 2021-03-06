# Edited version of:
# [ggplot theme for publication ready plots](https://rpubs.com/Koundy/71792)

theme_Publication = function(base_size=14, base_family="Times New Roman") {
  library(grid)
  library(ggthemes)
  (theme_foundation(base_size=base_size, base_family=base_family)
    + theme(plot.title = element_text(face = "bold", size = rel(1.2), hjust = 0.5),
            text = element_text(),
            panel.background = element_rect(color = NA),
            plot.background = element_rect(color = NA),
            panel.border = element_rect(color = NA),
            axis.title = element_text(face = "bold",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust =2),
            axis.title.x = element_text(vjust = -0.2),
            axis.text = element_text(),
            axis.line = element_line(color="black"),
            axis.ticks = element_line(),
            panel.grid.major = element_line(color="#f0f0f0"),
            panel.grid.minor = element_blank(),
            legend.key = element_rect(color = NA),
            legend.key.size = unit(0.3, "cm"),
            legend.key.height = unit(0.4, "cm"),
            legend.position = "bottom",
            legend.direction = "horizontal",
            #legend.margin = unit(0, "cm"),
            legend.spacing = unit(0, "cm"),
            legend.title = element_text(face="italic"),
            plot.margin = unit(c(10,5,5,5), "mm"),
            strip.background = element_rect(color="#f0f0f0", fill="#f0f0f0"),
            strip.text = element_text(face="bold")
    ))
}

scale_fill_Publication = function(...){
  library(scales)
  discrete_scale("fill", "Publication", manual_pal(values=c("#386cb0","#fdb462","#7fc97f","#ef3b2c","#662506","#a6cee3","#fb9a99","#984ea3","#ffff33")), ...)
}

scale_color_Publication = function(...){
  library(scales)
  discrete_scale("color", "Publication", manual_pal(values = c("#386cb0","#fdb462","#7fc97f","#ef3b2c","#662506","#a6cee3","#fb9a99","#984ea3","#ffff33")), ...)
}
