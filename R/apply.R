##Apply functions
# widetable  <- FLTable("FL_DEMO", "iris", "rownames")
# ddply(widetable,c("PetalWidth","PetalLength"),
#       function(d)c(meanx=mean(d$SepalWidth),
#                    meany=mean(d$SepalLength)))
# ddply(widetable,c("PetalWidth","PetalLength"),
# 		mean) --> ??
# "select flt.petalwidth,flt.petalength,
#     mean(flt.sepalwidth) as meanx,
#     mean(flt.sepallength) as meany
# from FL_DEMO.iris AS flt
# group by flt.petalwidth,flt.petallength"
## Return Type ?
## deeptable ?

setClass(
    "FLAbstractTable",
    slots = list(
        select = "FLTableQuery",
        dimnames = "list",
        isDeep = "logical",
        mapSelect = "FLSelectFrom"
    )
)

setClass(
	"FLAbstractColumn",
	slots=list(
		columnName = "character"))

as.FLAbstractCol <- function(object,indexCol=FALSE)
{
    UseMethod("as.FLAbstractCol", object)
}

as.FLAbstractCol.FLAbstractColumn <- function(object,indexCol=FALSE){
	return(object)
}

as.FLAbstractCol.FLVector <- function(object,indexCol=FALSE){
	if(!indexCol)
		vcolnames <- "vectorValueColumn"
	else vcolnames <- c("vectorIndexColumn",
						"vectorValueColumn")
	return(new("FLAbstractColumn",
				columnName=vcolnames))
}

genScalarFunCall <- function(object,func){
    sqlstr <- paste0(" SELECT ",func(as.FLAbstractCol(object)),
                     "\n FROM(",constructSelect(object),") AS a")

    return(sqlQuery(getOption("connectionFL"),sqlstr)[1,1])
}
mean.FLAbstractColumn <- function(object){
	return(paste0(" FLMean(",
				paste0(object@columnName,collapse=","),") "))
}
mean.FLVector <- function(x,...){
	return(genScalarFunCall(x,mean.FLAbstractColumn))
}

function (.data, .variables, .fun = NULL, ..., .progress = "none", 
    .inform = FALSE, .drop = TRUE, .parallel = FALSE, .paropts = NULL) 


require(plyr)
setGeneric("ddply", function(.data,.variables,.fun=NULL,...)
    standardGeneric("ddply"))

setMethod("ddply",
	signature(.data="FLTable",
			.variables="character",
			.fun="function"),
	function(.data,.variables,.fun,...){
		.data <- as.FLAbstractTable(.data)
		if(!all(.variables %in% colnames(.data)))
		stop("variables not in colnames of data")
		vfunCalls <- .fun(.data)
		if(is.null(names(vfunCalls)))
		names(vfunCalls) <- paste0("v",1:length(vfunCalls))
		else
		names(vfunCalls) <- sapply(1:length(names(vfunCalls)),
					function(x){if(names(vfunCalls)[x]=="")
								return(paste0("v",x))
								else return(names(vfunCalls)[x])})

		class(.data) <- "FLTable"
		sqlstr <- paste0("SELECT ",paste0(.variables,collapse=","),",",
						paste0(vfunCalls," AS ",names(vfunCalls),
							 collapse=","),"\n",
						" FROM  ",remoteTable(.data),"\n",
						constructWhere(constraintsSQL(.data)),"\n",
						" GROUP BY ",paste0(.variables,collapse=","))
		return(sqlQuery(getOption("connectionFL"),sqlstr))
	})

setMethod("ddply",
	signature(.data="ANY"),
	plyr::ddply)

as.FLAbstractTable <- function(object){
	object <- setAlias(object,"")
	class(object) <- "FLAbstractTable"
	return(object)
}

`$.FLAbstractTable` <- function(object,property){
  vcolnames <- colnames(object)
  property <- property[1]
  if(!is.character(property))
  return(NULL)
  if(property %in% colnames(object))
  return(new("FLAbstractColumn",
  			columnName=property))
  else stop("column not in colnames of data")
}

# flm <- as.FLMatrix(matrix(1:4,2,
#         dimnames=list(c("a","b"),c("c","d"))))
# apply(flm,1,mean)
# apply(flm,1,function(x)c(meanx=mean(x),
# 						meany=mean(x)))
# SELECT
#      mtrx.rowIdColumn,
# 	 FLMean(mtrx.valuecolumn),
# 	 FLMax(mtrx.valuecolumn)
#  FROM FL_DEMO.tblMatrixMultiResult_test AS mtrx 
#  WHERE   (mtrx.MATRIX_ID=1)
#  group by mtrx.rowidcolumn

# setGeneric("apply", function(X,MARGIN,FUN,...)
#     standardGeneric("apply"))

setMethod("apply",
	signature(X="FLMatrix",
			 MARGIN="numeric",
			 FUN="function"),
	function(X,MARGIN,FUN,...){
		X <- setAlias(X,"")
		if(MARGIN==1){
		vgroupCol <- getVariables(X)[["rowIdColumn"]]
		vvalueCol <- getVariables(X)[["colIdColumn"]]
		vrownames <- rownames(X)
		ifelse(is.null(vrownames),vrownames <- 1:nrow(X),
			vrownames <- vrownames)
		}
		else if(MARGIN==2){
		vgroupCol <- getVariables(X)[["colIdColumn"]]
		vvalueCol <- getVariables(X)[["rowIdColumn"]]
		vrownames <- colnames(X)
		ifelse(is.null(vrownames),vrownames <- 1:ncol(X),
			vrownames <- vrownames)
		}
		else stop("MARGIN can be 0 or 1 in apply.FLMatrix")
		vabstractCol <- new("FLAbstractColumn",
							columnName=vvalueCol)
		vfunCalls <- FUN(vabstractCol)
		sqlstr <- paste0("SELECT '%insertIDhere%' AS vectorIdColumn,\n",
								vgroupCol," AS vectorIndexColumn,\n",
								vfunCalls," AS vectorValueColumn \n",
						" FROM  ",remoteTable(X),"\n",
						constructWhere(constraintsSQL(X)),"\n",
						" GROUP BY ",vgroupCol)

		tblfunqueryobj <- new("FLTableFunctionQuery",
	                    connection = getOption("connectionFL"),
	                    variables = list(
			                obs_id_colname = "vectorIndexColumn",
			                cell_val_colname = "vectorValueColumn"),
	                    whereconditions="",
	                    order = "",
	                    SQLquery=sqlstr)

		flv <- new("FLVector",
					select = tblfunqueryobj,
					dimnames = list(vrownames,"vectorValueColumn"),
					isDeep = FALSE)
		if(!all(vrownames == 1:length(vrownames)))
		names(flv) <- vrownames
		return(flv)
	})
