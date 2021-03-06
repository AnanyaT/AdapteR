% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/FLAggClustering.R
\name{agnes.FLTable}
\alias{agnes.FLTable}
\title{Agglomerative Nesting}
\usage{
\method{agnes}{FLTable}(x, diss = FALSE, metric = "euclidean",
  Stand = FALSE, method = "average", par.method = 0,
  keep.diss = (!diss), keep.data = (!diss), trace.lev = 0, maxit = 500,
  excludeCols = "", classSpec = list(), whereconditions = "",
  distTable = "")
}
\arguments{
\item{x}{an object of class FLTable, can be wide or deep table}

\item{diss}{logical if \code{x} is dissimilarity matrix.
currently not used}

\item{metric}{only "euclidean" distance supported currently}

\item{Stand}{logical indicating if standardization
should be done before calculating diss matrix}

\item{method}{character. Allowed methods are "average",
"single", "complete", "centroid"}

\item{par.method}{currently not used and always 0}

\item{keep.diss}{logicals indicating if the 
dissimilarities and/or input data x should be kept in the result}

\item{keep.data}{logicals indicating if the 
dissimilarities and/or input data x should be kept in the result}

\item{trace.lev}{integer specifying a trace level for 
printing diagnostics during the build and swap phase of the algorithm.
currently always 0}

\item{maxit}{maximum number of iterations}

\item{excludeCols}{the comma separated character string of columns to be excluded}

\item{classSpec}{list describing the categorical dummy variables}

\item{whereconditions}{takes the where_clause as a string}

\item{distTable}{name of the in-database table having dissimilarity
matrix or distance table}
}
\value{
\code{agnes} returns a list and replicates equivalent R output
from \code{agnes} in cluster package. The mapping table can be viewed
using \code{object$mapping} if input is wide table.
}
\description{
\code{agnes} computes agglomeraive hierarchial 
clustering on FLTable objects.
}
\section{Constraints}{

Plotting for large datasets takes longer time to fetch data.
Error is thrown if results cannot be fetched. maxit should be more than
no.of. observations for algorithm to reach completion.
Error is thrown if algorithm does not reach completion or more than one
cluster is formed at any step.
If classSpec is not specified, the categorical variables are excluded
from analysis by default.
}
\examples{
connection <- flConnect(odbcSource="Gandalf")
deeptable  <- FLTable("FL_DEMO", "tblUSArrests", "ObsID","VarID","Num_Val")
agnesobject <- agnes(deeptable,maxit=50)
print(agnesobject)
plot(agnesobject)
One can specify ClassSpec and transform categorical variables 
before clustering. This increases the number of variables in the plot
because categorical variable is split into binary numerical variables.
The clusters may not be well-defined as is observed in the case below:-
widetable  <- FLTable( "FL_DEMO", "iris", "rownames")
agnesobjectnew <- agnes(widetable,maxit=500,classSpec=list("Species(setosa)"))
The below plot throws warnings!
plot(agnesobjectnew)
}

