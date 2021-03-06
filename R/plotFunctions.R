#' Generate color set automatically
#'
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @param n integer; number of colors needed
#' @param name character; Palette name
#' @return an vector contains the color codes
auto.colSet <- function(n=2,name="Set1"){
  requireNamespace("RColorBrewer",quietly = T)
  if(n<=8){
    ret <- RColorBrewer::brewer.pal(max(n,3),name)[seq_len(n)]
  }else{
    ret <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(12,"Paired"))(n)
  }
  return(ret)
}

#' Determine point size automatically
#' @param n number of points to plot
#' @return points' cex
auto.point.size <- function(n){
  if(n<=100){
    return(1.2)
  }else if(n>=5000){
    return(0.6)
  }else{
    return(-0.6*n/4900+1.212002)
  }
}

#' Plot gene expression on tSNE map
#'
#' @importFrom RColorBrewer brewer.pal
#' @importFrom ggplot2 ggplot ggsave scale_colour_gradientn geom_point facet_wrap theme_bw coord_cartesian
#' @importFrom data.table melt
#' @importFrom utils head
#' @param Y matrix or data.frame; Gene expression data, rownames shoud be gene id, colnames
#' should be sample id
#' @param dat.map data.frame; tSNE map, must be two columns data.frame and rownames should be sample id
#' @param gene.to.show character; gene id to be showd on the tSNE map
#' @param out.prefix character; output prefix (default: NULL)
#' @param p.ncol integer; number of columns in the plot's layout (default: 3)
#' @param xlim integer or NULL; only draw points lie in the ragne specified by xlim and ylim (default NULL)
#' @param ylim integer or NULL; only draw points lie in the ragne specified by xlim and ylim (default NULL)
#' @param size double; points' size. If NULL, infer from number of points (default NULL)
#' @param width numeric; width of the plot (default: 9)
#' @param height numeric; height of the plot (default: 8)
#' @details For genes contained in both `Y` and `gene.to.show`, show their expression on the tSNE
#' map provided as `dat.map`. One point in the map represent a cell; cells with higher expression
#' also have darker color.
#' @return a ggplot object
ggGeneOnTSNE <- function(Y,dat.map,gene.to.show,out.prefix=NULL,p.ncol=3,
                         xlim=NULL,ylim=NULL,size=NULL,
                         width=9,height=8){
  #suppressPackageStartupMessages(require("data.table"))
  #requireNamespace("ggplot2",quietly = T)
  #requireNamespace("RColorBrewer",quietly = T)
  if(!is.null(out.prefix)){
    dir.create(dirname(out.prefix),showWarnings = F,recursive = T)
  }
  f.g <- gene.to.show %in% rownames(Y)
  if(sum(!f.g)>0){
    warning(sprintf("Some genes not in the expression data: \n"))
    print(head(gene.to.show[!f.g]))
  }
  gene.to.show <- gene.to.show[f.g]

  dat.plot <- data.frame(sample=rownames(dat.map),stringsAsFactors = F)
  dat.plot <- cbind(dat.plot,dat.map,t(as.matrix(Y[gene.to.show,dat.plot$sample,drop=F])))
  colnames(dat.plot) <- c("sample","Dim1","Dim2",names(gene.to.show))
  dat.plot.melt <- data.table::melt(dat.plot,id.vars = c("sample","Dim1","Dim2"))
  dat.plot.melt <- dat.plot.melt[order(dat.plot.melt$value,decreasing = F),]
  npts <- nrow(dat.plot.melt)
  p <- ggplot2::ggplot(dat.plot.melt,aes(Dim1,Dim2)) +
    geom_point(aes(colour=value),size=if(is.null(size)) auto.point.size(npts)*1.1 else size) +
    scale_colour_gradientn(colours = RColorBrewer::brewer.pal(9,"YlOrRd")) +
    facet_wrap(~variable, ncol = p.ncol) +
    theme_bw() +
    coord_cartesian(xlim = xlim, ylim = ylim, expand = TRUE)
  if(!is.null(out.prefix)){
    ggplot2::ggsave(sprintf("%s.geneOntSNE.pdf",out.prefix),width = width,height = height)
  }
  return(p)
}

#' Wrap for plotting 2D density
#'
#' @importFrom ks kde
#' @importFrom fields image.plot
#' @param x matrix or data.frame; map data, row for sample, column for dimension
#' @param peaks integer or character; index or names of the peaks. (default: NULL)
#' @usage plot.density2D(x, peaks)
#' @details use ks::kde for density estimation
#'
plot.density2D <- function(x,peaks=NULL)
{
  .density <- ks::kde(x)
  ##dev.new()
  par(mar=c(5,4,5,6))
  .zz <- c(10,20,30,40,50,60,70,80,90)
  plot(.density,display="filled.contour2", cont=.zz,xlab="Dim1", ylab="Dim2")
  fields::image.plot(zlim=c(0,.zz[length(.zz)]),legend.only=TRUE, col = c("transparent", rev(heat.colors(length(.zz)))),
                     axis.args=list( at=.zz, labels=sprintf("%s%%",100-.zz)), legend.width=2.0,legend.mar=4.5)
  if(!is.null(peaks)){
    plot(.density,display="filled.contour2", cont=.zz,xlab="Dim1", ylab="Dim2")
    points(x[peaks,,drop=F],pch=3,cex=2,col="black")
    fields::image.plot(zlim=c(0,.zz[length(.zz)]),legend.only=TRUE, col = c("transparent", rev(heat.colors(length(.zz)))),
                       axis.args=list( at=.zz, labels=sprintf("%s%%",100-.zz)), legend.width=2.0,legend.mar=4.5)
  }
  ##pp <- recordPlot()
  ##dev.off()
  #pp
}
