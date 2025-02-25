#' @export
abess <- function(x, ...) UseMethod("abess")

#' @title Adaptive Best-Subset Selection via Splicing
#'
#' @description Adaptive best-subset selection for regression, 
#' classification, counting-response, censored-response, multi-response modeling 
#' in polynomial times.
#' 
#' @aliases abess
#' 
#' @author Jin Zhu, Junxian Zhu, Canhong Wen, Heping Zhang, Xueqin Wang
#'
#' @param x Input matrix, of dimension \eqn{n \times p}; each row is an observation
#' vector and each column is a predictor/feature/variable. 
#' Can be in sparse matrix format (inherit from class \code{"dgCMatrix"} in package \code{Matrix}).
#' @param y The response variable, of \code{n} observations. 
#' For \code{family = "binomial"} should have two levels. 
#' For \code{family="poisson"}, \code{y} should be a vector with positive integer. 
#' For \code{family = "cox"}, \code{y} should be a two-column matrix with columns named \code{time} and \code{status}.
#' For \code{family = "mgaussian"}, \code{y} should be a matrix of quantitative responses.
#' For \code{family = "multinomial"}, \code{y} should be a factor of at least three levels.
#' Note that, for either \code{"binomial"} or \code{"multinomial"}, 
#' if y is presented as a numerical vector, it will be coerced into a factor.
# @param type One of the two types of problems.
# \code{type = "bss"} for the best subset selection,
# and \code{type = "bsrr"} for the best subset ridge regression.
#' @param family One of the following models: 
#' \code{"gaussian"} (continuous response), 
#' \code{"binomial"} (binary response), 
#' \code{"poisson"} (non-negative count), 
#' \code{"cox"} (left-censored response), 
#' \code{"mgaussian"} (multivariate continuous response).
#' Depending on the response. Any unambiguous substring can be given.
#' @param tune.path The method to be used to select the optimal support size. For
#' \code{tune.path = "sequence"}, we solve the best subset selection problem for each size in \code{support.size}.
#' For \code{tune.path = "gsection"}, we solve the best subset selection problem with support size ranged in \code{gs.range},
#' where the specific support size to be considered is determined by golden section. 
# @param method The method to be used to select the optimal support size and \eqn{L_2} shrinkage. For
# \code{tune.path = "sequence"}, we solve the best subset selection and the best subset ridge regression
# problem for each \code{s} in \code{1,2,...,s.max} and \eqn{\lambda} in \code{lambda.list}. 
# For \code{tune.path = "gsection"}, which is only valid for \code{type = "bss"},
# we solve the best subset selection problem with the range support size \code{gs.range},
# where the specific support size to be considered is determined by golden section. we
# solve the best subset selection problem with a range of non-continuous model
# sizes. For \code{tune.path = "pgsection"} and \code{"psequence"}, the Powell method is used to
# solve the best subset ridge regression problem. Any unambiguous substring can be given.
#' @param tune.type The type of criterion for choosing the support size. 
#' Available options are \code{"gic"}, \code{"ebic"}, \code{"bic"}, \code{"aic"} and \code{"cv"}.
#' Default is \code{"gic"}.
#' @param support.size An integer vector representing the alternative support sizes. 
#' Only used for \code{tune.path = "sequence"}. Default is \code{0:min(n, round(n/(log(log(n))log(p))))}.
#' @param gs.range A integer vector with two elements. 
#' The first element is the minimum model size considered by golden-section, 
#' the later one is the maximum one. Default is \code{gs.range = c(1, min(n, round(n/(log(log(n))log(p)))))}.
#' Not available now.
#' @param lambda A single lambda value for regularized best subset selection. Default is 0.
# 0.
# @param s.min The minimum value of support sizes. Only used for \code{tune.path =
# "gsection"}, \code{"psequence"} and \code{"pgsection"}. Default is 1.
# @param s.max The maximum value of support sizes. Only used for \code{tune.path =
# "gsection"}, \code{"psequence"} and \code{"pgsection"}. Default is \code{min(p, round(n/log(n)))}.
# @param lambda.min The minimum value of lambda. Only used for \code{tune.path =
# "powell"}. Default is \code{0.001}.
# @param lambda.max The maximum value of lambda. Only used for \code{tune.path =
# "powell"}. Default is \code{100}.
# @param nlambda The number of \eqn{\lambda}s for the Powell path with sequence line search method.
# Only valid for \code{tune.path = "psequence"}.
#' @param always.include An integer vector containing the indexes of variables that should always be included in the model.
#' @param group.index A vector of integers indicating the which group each variable is in.
#' For variables in the same group, they should be located in adjacent columns of \code{x}
#' and their corresponding index in \code{group.index} should be the same.
#' Denote the first group as \code{1}, the second \code{2}, etc.
#' If you do not fit a model with a group structure,
#' please set \code{group.index = NULL} (the default).
#' @param splicing.type Optional type for splicing. 
#' If \code{splicing.type = 1}, the number of variables to be spliced is 
#' \code{c.max}, ..., \code{1}; if \code{splicing.type = 2}, 
#' the number of variables to be spliced is \code{c.max}, \code{c.max/2}, ..., \code{1}.
#' (Default: \code{splicing.type = 2}.)
#' @param screening.num An integer number. Preserve \code{screening.num} number of predictors with the largest 
#' marginal maximum likelihood estimator before running algorithm.
#' @param normalize Options for normalization. \code{normalize = 0} for no normalization. 
#' \code{normalize = 1} for subtracting the mean of columns of \code{x}.
#' \code{normalize = 2} for scaling the columns of \code{x} to have \eqn{\sqrt n} norm.
#' \code{normalize = 3} for subtracting the means of the columns of \code{x} and \code{y}, and also
#' normalizing the columns of \code{x} to have \eqn{\sqrt n} norm.
#' If \code{normalize = NULL}, \code{normalize} will be set \code{1} for \code{"gaussian"},
#' \code{2} for \code{"binomial"}. Default is \code{normalize = NULL}.
#' @param c.max an integer splicing size. Default is: \code{c.max = 2}. 
#' @param weight Observation weights. Default is \code{1} for each observation.
#' @param max.splicing.iter The maximum number of performing splicing algorithm. 
#' In most of the case, only a few times of splicing iteration can guarantee the convergence. 
#' Default is \code{max.splicing.iter = 20}.
#' @param warm.start Whether to use the last solution as a warm start. Default is \code{warm.start = TRUE}.
#' @param nfolds The number of folds in cross-validation. Default is \code{nfolds = 5}.
#' @param cov.update A logical value only used for \code{family = "gaussian"}. If \code{cov.update = TRUE}, 
#' use a covariance-based implementation; otherwise, a naive implementation. 
#' The naive method is more efficient than covariance-based method only when \eqn{p >> n}. 
#' Default: \code{cov.update = TRUE}. 
# @param n The number of rows of the design matrix. A must if \code{x} in triplet form.
# @param p The number of columns of the design matrix. A must if \code{x} in triplet form.
# @param sparse.matrix A logical value indicating whether the input is a sparse matrix.
#' @param newton A character specify the Newton's method for fitting generalized linear models, 
#' it should be either \code{newton = "exact"} or \code{newton = "approx"}.
#' If \code{newton = "exact"}, then the exact hessian is used, 
#' while \code{newton = "approx"} uses diagonal entry of the hessian, 
#' and can be faster (especially when \code{family = "cox"}).
#' @param newton.thresh a numeric value for controlling positive convergence tolerance. 
#' The Newton's iterations converge when \eqn{|dev - dev_{old}|/(|dev| + 0.1)<} \code{newton.thresh}.
#' @param max.newton.iter a integer giving the maximal number of Newton's iteration iterations.
#' Default is \code{max.newton.iter = 10} if \code{newton = "exact"}, and \code{max.newton.iter = 60} if \code{newton = "approx"}.
#' @param early.stop A boolean value decide whether early stopping. 
#' If \code{early.stop = TRUE}, algorithm will stop if the last tuning value less than the existing one. 
#' Default: \code{early.stop = FALSE}.
#' @param num.threads An integer decide the number of threads to be 
#' concurrently used for cross-validation (i.e., \code{tune.type = "cv"}). 
#' If \code{num.threads = 0}, then all of available cores will be used. 
#' Default: \code{num.threads = 0}.
#' @param seed Seed to be used to divide the sample into cross-validation folds. 
#' Default is \code{seed = 1}.
#' @param ... further arguments to be passed to or from methods.
#'
#' @return A S3 \code{abess} class object, which is a \code{list} with the following components:
# \item{best.model}{The best model chosen by algorithm. It is a \code{list} object comprising the following sub-components:
#  1. \code{beta}: a fitted \eqn{p}-dimensional coefficients vector; 2. \code{coef0}: a numeric fitted intercept; 
#  3. \code{support.index}: an index vector of best model's support set; 4. \code{support.size}: the support size of the best model; 
#  5. \code{dev}: the deviance of the model; 6. \code{tune.value}: the tune value of the model.
# }
#' \item{beta}{A \eqn{p}-by-\code{length(support.size)} matrix of coefficients for univariate family, stored in column format;
#' while a list of \code{length(support.size)} coefficients matrix (with size \eqn{p}-by-\code{ncol(y)}) for multivariate family.}
#' \item{intercept}{An intercept vector of length \code{length(support.size)} for univariate family; 
#' while a list of \code{length(support.size)} intercept vector (with size \code{ncol(y)}) for multivariate family.}
#' \item{dev}{the deviance of length \code{length(support.size)}.}
#' \item{tune.value}{A value of tuning criterion of length \code{length(support.size)}.}
# \item{best.model}{The best fitted model for \code{type = "bss"}.}
# \item{lambda}{The lambda chosen for the best fitting model}
# \item{beta.all}{For \code{bess} objects obtained by \code{gsection}, \code{pgsection}
# and \code{psequence}, \code{beta.all} is a matrix with each column be the coefficients
# of the model in each iterative step in the tuning path.
# For \code{bess} objects obtained by \code{sequence} method,
# A list of the best fitting coefficients of size
# \code{s=0,1,...,p} and \eqn{\lambda} in \code{lambda.list} with the
# smallest loss function. For \code{"bess"} objects of \code{"bsrr"} type, the fitting coefficients of the
# \eqn{i^{th} \lambda} and the \eqn{j^{th}} \code{s} are at the \eqn{i^{th}}
# list component's \eqn{j^{th}} column.}
# \item{coef0.all}{For \code{bess} objects obtained from \code{gsection}, \code{pgsection} and \code{psequence},
# \code{coef0.all} contains the intercept for the model in each iterative step in the tuning path.
# For \code{bess} objects obtained from \code{sequence} path,
# \code{coef0.all} contains the best fitting
# intercepts of size \eqn{s=0,1,\dots,p} and \eqn{\lambda} in
# \code{lambda.list} with the smallest loss function.}
# \item{loss.all}{For \code{bess} objects obtained from \code{gsection}, \code{pgsection} and \code{psequence},
# \code{loss.all} contains the training loss of the model in each iterative step in the tuning path.
# For \code{bess} objects obtained from \code{sequence} path, this is a
# list of the training loss of the best fitting intercepts of support size
# \eqn{s=0,1,\dots,p} and \eqn{\lambda} in \code{lambda.list}. For \code{"bess"} object obtained by \code{"bsrr"},
# the training loss of the \eqn{i^{th} \lambda} and the \eqn{j^{th}} \code{s}
# is at the \eqn{i^{th}} list component's \eqn{j^{th}} entry.}
# \item{ic.all}{For \code{bess} objects obtained from \code{gsection}, \code{pgsection} and \code{psequence},
# \code{ic.all} contains the values of the chosen information criterion of the model in each iterative step in the tuning path.
# For \code{bess} objects obtained from \code{sequence} path, this is a
# matrix of the values of the chosen information criterion of support size \eqn{s=0,1,\dots,p}
# and \eqn{\lambda} in \code{lambda.list} with the smallest loss function. For \code{"bess"} object obtained by \code{"bsrr"},
# the training loss of the \eqn{i^{th} \lambda} and the \eqn{j^{th}}
# \code{s} is at the \eqn{i^{th}} row \eqn{j^{th}} column. Only available when
# model selection is based on a certain information criterion.}
# \item{lambda.all}{The lambda chosen for each step in \code{pgsection} and \code{psequence}.}
#' \item{nobs}{The number of sample used for training.}
#' \item{nvars}{The number of variables used for training.}
#' \item{family}{Type of the model.}
#' \item{tune.path}{The path type for tuning parameters.}
#' \item{support.size}{The actual \code{support.size} values used. 
#' Note that it is not necessary the same as the input  
#' if the later have non-integer values or duplicated values.}
# \item{support.df}{The degree of freedom in each support set, 
# in other words, the number of predictors in each group. 
# Particularly, it would be a all one vector with length \code{nvars} when \code{group.index = NULL}.}
#' \item{best.size}{The best support size selected by the tuning value.} 
#' \item{tune.type}{The criterion type for tuning parameters.}
#' \item{tune.path}{The strategy for tuning parameters.}
#' \item{screening.vars}{The character vector specify the feature 
#' selected by feature screening. 
#' It would be an empty character vector if \code{screening.num = 0}.}
#' \item{call}{The original call to \code{abess}.}
# \item{type}{Either \code{"bss"} or \code{"bsrr"}.}
#'
#' @details 
#' Best-subset selection aims to find a small subset of predictors, 
#' so that the resulting model is expected to have the most desirable prediction accuracy. 
#' Best-subset selection problem under the support size \eqn{s} is
#' \deqn{\min_\beta -2 \log L(\beta) \;\;{\rm s.t.}\;\; \|\beta\|_0 \leq s,}
#' where \eqn{L(\beta)} is arbitrary convex functions. In
#' the GLM case, \eqn{\log L(\beta)} is the log-likelihood function; in the Cox
#' model, \eqn{\log L(\beta)} is the log partial-likelihood function. 
#' 
#' The best subset selection problem is solved by the "abess" algorithm in this package, see Zhu (2020) for details. 
#' Under mild conditions, the algorithm exactly solve this problem in polynomial time. 
#' This algorithm exploits the idea of sequencing and splicing to reach a stable solution in finite steps
#' when \eqn{s} is fixed. 
#' To find the optimal support size \eqn{s}, 
#' we provide various criterion like GIC, AIC, BIC and cross-validation error to determine it. 
#' 
#' @references A polynomial algorithm for best-subset selection problem. Junxian Zhu, Canhong Wen, Jin Zhu, Heping Zhang, Xueqin Wang. Proceedings of the National Academy of Sciences Dec 2020, 117 (52) 33117-33123; DOI: 10.1073/pnas.2014241117
#' @references Sure independence screening for ultrahigh dimensional feature space. Fan, J. and Lv, J. (2008), Journal of the Royal Statistical Society: Series B (Statistical Methodology), 70: 849-911. https://doi.org/10.1111/j.1467-9868.2008.00674.x
#' @references Targeted Inference Involving High-Dimensional Data Using Nuisance Penalized Regression. Qiang Sun & Heping Zhang (2020). Journal of the American Statistical Association, DOI: 10.1080/01621459.2020.1737079
#' @references Certifiably Polynomial Algorithm for Best Group Subset Selection. Zhang, Yanhang, Junxian Zhu, Jin Zhu, and Xueqin Wang (2021). arXiv preprint arXiv:2104.12576. 
#' 
#' @seealso \code{\link{print.abess}}, 
#' \code{\link{predict.abess}}, 
#' \code{\link{coef.abess}}, 
#' \code{\link{extract.abess}},
#' \code{\link{plot.abess}},
#' \code{\link{deviance.abess}}. 
#' 
#' @export
#' @rdname abess
#' @method abess default
#' @examples
#' \donttest{
#' library(abess)
#' n <- 100
#' p <- 20
#' support.size <- 3
#' 
#' ################ linear model ################
#' dataset <- generate.data(n, p, support.size)
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]])
#' ## helpful generic functions:
#' print(abess_fit)
#' coef(abess_fit, support.size = 3)
#' predict(abess_fit, newx = dataset[["x"]][1:10, ], 
#'         support.size = c(3, 4))
#' str(extract(abess_fit, 3))
#' deviance(abess_fit)
#' plot(abess_fit)
#' 
#' ################ logistic model ################
#' dataset <- generate.data(n, p, support.size, family = "binomial")
#' ## allow cross-validation to tuning
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], 
#'                    family = "binomial", tune.type = "cv")
#' abess_fit
#' 
#' ################ poisson model ################
#' dataset <- generate.data(n, p, support.size, family = "poisson")
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], 
#'                    family = "poisson", tune.type = "cv")
#' abess_fit
#' 
#' ################ Cox model ################
#' dataset <- generate.data(n, p, support.size, family = "cox")
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], 
#'                    family = "cox", tune.type = "cv")
#' 
#' ################ Multivariate gaussian model ################
#' dataset <- generate.data(n, p, support.size, family = "mgaussian")
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], 
#'                    family = "mgaussian", tune.type = "cv")
#' plot(abess_fit, type = "l2norm")
#' 
#' ################ Multinomial model (multi-classification) ################
#' dataset <- generate.data(n, p, support.size, family = "multinomial")
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], 
#'                    family = "multinomial", tune.type = "cv")
#' predict(abess_fit, newx = dataset[["x"]][1:10, ], 
#'         support.size = c(3, 4), type = "response")
#' 
#' ########## Best group subset selection #############
#' dataset <- generate.data(n, p, support.size)
#' group_index <- rep(1:10, each = 2)
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], group.index = group_index)
#' str(extract(abess_fit))
#' 
#' ################ Golden section searching ################
#' dataset <- generate.data(n, p, support.size)
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], tune.path = "gsection")
#' abess_fit
#' 
#' ################ Feature screening ################
#' p <- 1000
#' dataset <- generate.data(n, p, support.size)
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]], 
#'                    screening.num = 100)
#' str(extract(abess_fit))
#' 
#' ################ Sparse predictor ################
#' require(Matrix)
#' p <- 1000
#' dataset <- generate.data(n, p, support.size)
#' dataset[["x"]][abs(dataset[["x"]]) < 1] <- 0
#' dataset[["x"]] <- Matrix(dataset[["x"]])
#' abess_fit <- abess(dataset[["x"]], dataset[["y"]])
#' str(extract(abess_fit))
#' }
abess.default <- function(x, 
                          y,
                          family = c("gaussian", "binomial", "poisson", "cox", "mgaussian", "multinomial"),
                          tune.path = c("sequence", "gsection"),
                          tune.type = c("gic", "ebic", "bic", "aic", "cv"),
                          weight = rep(1, nrow(x)),
                          normalize = NULL,
                          c.max = 2,
                          support.size = NULL,
                          gs.range = NULL, 
                          lambda = 0,
                          always.include = NULL,
                          group.index = NULL, 
                          splicing.type = 2, 
                          max.splicing.iter = 20,
                          screening.num = NULL, 
                          warm.start = TRUE,
                          nfolds = 5, 
                          cov.update = TRUE, 
                          newton = c("exact", "approx"), 
                          newton.thresh = 1e-6, 
                          max.newton.iter = NULL, 
                          early.stop = FALSE, 
                          num.threads = 0, 
                          seed = 1, 
                          ...)
{
  tau <- NULL
  if(length(lambda) > 1){
    stop("only a single lambda value is allowed.")
  }
  if(length(lambda) == 1 && lambda == 0){
    type <- "bss"
  }else{
    type <- "bsrr"
  }
  algorithm_type = switch(type,
                          "bss" = "GPDAS",
                          "bsrr" = "GL0L2")
  
  ## check lambda
  stopifnot(!anyNA(lambda))
  stopifnot(all(lambda >= 0))
  lambda.list <- lambda
  lambda.min <- 0.001
  lambda.max <- 100
  nlambda <- 100
  
  set.seed(seed)
  
  ## check number of thread:
  stopifnot(is.numeric(num.threads) & num.threads >= 0)
  num_threads <- as.integer(num.threads)
  
  ## check early stop:
  stopifnot(is.logical(early.stop))
  early_stop <- early.stop
  
  ## check warm start:
  stopifnot(is.logical(warm.start))
  
  ## check splicing type
  stopifnot(length(splicing.type) == 1)
  stopifnot(splicing.type %in% c(1, 2))
  splicing_type <- as.integer(splicing.type)
  
  ## check max splicing iteration
  stopifnot(is.numeric(max.splicing.iter) & max.splicing.iter >= 1)
  max_splicing_iter <- as.integer(max.splicing.iter)
  
  ## task type:
  family <- match.arg(family)
  model_type <- switch(
    family,
    "gaussian" = 1,
    "binomial" = 2,
    "poisson" = 3,
    "cox" = 4, 
    "mgaussian" = 5, 
    "multinomial" = 6
  )
  
  # check weight
  nobs <- nrow(x)
  stopifnot(is.vector(weight))
  if (length(weight) != nobs) {
    stop("Rows of x must be the same as length of weight!")
  }
  stopifnot(all(is.numeric(weight)), all(weight >= 0))
  
  ## check predictors:
  # if (anyNA(x)) {
  #   stop("x has missing value!")
  # }
  nvars <- ncol(x)
  vn <- colnames(x)
  if (is.null(vn)) {
    vn <- paste0("x", 1:nvars)
  }
  
  sparse_X <- ifelse(class(x)[1] %in% c("matrix", "data.frame"), FALSE, TRUE)
  if (sparse_X) {
    if (class(x) == "dgCMatrix") {
      x <- summary(x)
      x[, 1:2] <- x[, 1:2] - 1
      x <- as.matrix(x)
      x <- x[, c(3, 1, 2)]
    } else {
      stop("Must be a dgCMatrix matrix!")
    }
  } else {
    if (!is.matrix(x)) {
      x <- as.matrix(x)
    }    
  }
  if (nvars == 1) {
    stop("x should have at least two columns!")
  }

  ## check C-max:
  stopifnot(is.numeric(c.max) & c.max >= 1)
  if (c.max >= nvars) {
    stop("c.max should smaller than the number of predictors!")
  }
  c_max <- as.integer(c.max)
  
  ## check response:
  if (anyNA(y)) {
    stop("y has missing value!")
  }
  if (any(is.infinite(y))) {
    stop("y has infinite value!")
  }
  if (family == "gaussian") {
    if (is.matrix(y)) {
      if (dim(y)[2] > 1) {
        stop("The dimension of y should not exceed 1 when family = 'gaussian'!")
      }
    } 
  }
  if (family == "binomial" || family == "multinomial")
  {
    if (length(unique(y)) == 2 && family == "multinomial") {
      warning("y is a binary variable and is not match to family = 'multinomial'. 
              We change to family = 'binomial'")
      model_type <- 2
      family <- "binomial"
    }
    if (length(unique(y)) > 2 && family == "binomial") {
      stop("Input binary y when setting family = 'binomial'; otherwise, 
           change the option for family to 'multinomial'. ")
    }
    if (!is.factor(y)) {
      y <- as.factor(y)
    }
    class.name <- levels(y)
    y_vn <- class.name
    
    if (family == "binomial") {
      y <- as.numeric(y) - 1
    }
    if (family == "multinomial") {
      y <- model.matrix(~factor(as.numeric(y) - 1) + 0)
      colnames(y) <- NULL
    }
  }
  if (family == "poisson") {
    if (any(y < 0)) {
      stop("y must be positive integer value when family = 'poisson'.")
    }
  }
  if (family == "cox")
  {
    if (!is.matrix(y)) {
      y <- as.matrix(y)
    }
    if (ncol(y) != 2) {
      stop("Please input y with two columns!")
    }
    ## pre-process data for cox model
    sort_y <- order(y[, 1])
    y <- y[sort_y, ]
    x <- x[sort_y, ]
    y <- y[, 2]
  }
  if (family == "mgaussian") {
    if (!is.matrix(y) || dim(y)[2] <= 1) {
      stop("y must be a n-by-q matrix (q >= 1) when family = 'mgaussian'!")
    }
    y_vn <- colnames(y)
    if (is.null(y_vn)) {
      y_vn <- colnames("y", 1:dim(y)[2])
    }
  }
  y <- as.matrix(y)
  y_dim <- ncol(y)
  multi_y <- family %in% MULTIVARIATE_RESPONSE
  
  # check whether x and y are matching:
  if (is.vector(y)) {
    if (nobs != length(y))
      stop("Rows of x must be the same as length of y!")
  } else {
    if (nobs != nrow(y))
      stop("Rows of x must be the same as rows of y!")
  }
  
  ## strategy for tunning
  tune.path <- match.arg(tune.path)
  if (tune.path == "gsection") {
    path_type <- 2
  } else if (tune.path == "sequence") {
    path_type <- 1
  }
  
  ## group variable:
  group_select <- FALSE
  if (is.null(group.index)) {
    g_index <- 1:nvars - 1
    ngroup <- 1
    max_group_size <- 1
    # g_df <- rep(1, nvars)
  } else {
    group_select <- TRUE
    gi <- unique(group.index)
    g_index <- match(gi, group.index) - 1
    g_df <- c(diff(g_index), nvars - max(g_index))
    ngroup <- length(g_index)
    max_group_size <- max(g_df)
  }
  
  # sparse level list (sequence):
  if (is.null(support.size)) {
    if (group_select) {
      s_list <- 0:min(c(ngroup, round(nobs / max_group_size / log(ngroup))))
    } else {
      s_list <- 0:min(c(nvars, round(nobs / log(log(nobs)) / log(nvars))))
    }
  } else {
    stopifnot(any(is.numeric(support.size) & support.size >= 0))
    if (group_select) {
      stopifnot(max(support.size) < ngroup)
    } else {
      stopifnot(max(support.size) < nvars)
    }    
    stopifnot(max(support.size) < nobs)
    support.size <- sort(support.size)
    support.size <- unique(support.size)
    s_list <- support.size
    # if (s_list[1] == 0) {
    #   zero_size <- TRUE
    # } else {
    #   zero_size <- FALSE
    #   s_list <- c(0, s_list)
    # }
  }
  
  # sparse range (golden-section):
  if (is.null(gs.range)) {
    s_min <- 1
    if (group_select) {
      s_max <- min(c(ngroup, round(nobs / max_group_size / log(ngroup))))
    } else {
      s_max <- min(c(nvars, round(nobs / log(log(nobs)) / log(nvars))))
    }
  } else {
    stopifnot(length(gs.range) == 2)
    stopifnot(any(is.numeric(gs.range) & gs.range > 0))
    stopifnot(as.integer(gs.range)[1] != as.integer(gs.range)[2])
    if (group_select) {
      stopifnot(max(gs.range) < ngroup)
    } else {
      stopifnot(max(gs.range) < nvars)
    }
    gs.range <- as.integer(gs.range)
    s_min <- min(gs.range)
    s_max <- max(gs.range)
  }
  
  ## check compatible between group selection and support size
  if (group_select) {
    if (path_type == 1 & max(s_list) > length(gi))
      stop("The maximum one support.size should not be larger than the number of groups!")
    if (path_type == 2 & s_max > length(gi))
      stop("max(gs.range) is too large. Should be smaller than the number of groups!")
  }
  
  ## check covariance update
  stopifnot(is.logical(cov.update))
  if (model_type == 1) {
    covariance_update <- cov.update
  } else {
    covariance_update <- FALSE
  }
  
  ## check parameters for sub-optimization:
  # 1:
  if (length(newton) == 2) {
    if (family %in% c("binomial", "cox", "multinomial")) {
      newton <- "approx"
    }
  }
  newton <- match.arg(newton)
  # if (newton == "auto") {
  #   if (family == "cox") {
  #     newton <- "approx"
  #   } else if (family == "logistic") {
  #     newton <- "auto"
  #   }
  # }
  if (family %in% c("gaussian", "mgaussian", "poisson")) {
    newton <- "exact"
  }
  newton_type <- switch(
    newton,
    "exact" = 0,
    "approx" = 1,
    "auto" = 2
  )
  approximate_newton <- ifelse(newton_type == 1, TRUE, FALSE)
  # 2:
  if (!is.null(max.newton.iter)) {
    stopifnot(is.numeric(max.newton.iter) & max.newton.iter >= 1)
    max_newton_iter <- as.integer(max.newton.iter)
  } else {
    max_newton_iter <- ifelse(newton_type == 0, 10, 60)
  }
  # 3:
  stopifnot(is.numeric(newton.thresh) & newton.thresh > 0)
  newton_thresh <- as.double(newton.thresh)
  
  # tune support size method:
  tune.type <- match.arg(tune.type)
  ic_type <- switch(
    tune.type,
    "aic" = 1,
    "bic" = 2,
    "gic" = 3,
    "ebic" = 4,
    "cv" = 1
  )
  is_cv <- ifelse(tune.type == "cv", TRUE, FALSE)
  if (is_cv) {
    stopifnot(is.numeric(nfolds) & nfolds >= 2)
    nfolds <- as.integer(nfolds)
  }
  
  ## normalize strategy: 
  if (is.null(normalize)) {
    is_normal <- TRUE
    normalize <- switch(
      family,
      "gaussian" = 1,
      "binomial" = 2,
      "poisson" = 2,
      "cox" = 3, 
      "mgaussian" = 1, 
      "multinomial" = 2
    )
  } else {
    stopifnot(normalize %in% 0:3)
    if (normalize != 0) {
      # normalize <- as.character(normalize)
      # normalize <- switch (normalize,
      #                      '1' <- 2,
      #                      '2' <- 3,
      #                      '3' <- 1
      # )
      if (normalize == 1) {
        normalize <- 2
      } else if (normalize == 2) {
        normalize <- 3
      } else if (normalize == 3) {
        normalize <- 1
      } else {
      }
      is_normal <- TRUE
    } else {
      is_normal <- FALSE
      normalize <- 0
    }
  }
  
  if (is.null(screening.num)) {
    screening <- FALSE
    screening_num <- nvars
  } else {
    stopifnot(is.numeric(screening.num))
    stopifnot(screening.num >= 1)
    screening.num <- as.integer(screening.num)
    if (screening.num > nvars)
      stop("The number of screening features must be equal or less than that of the column of x!")
    if (path_type == 1) {
      if (screening.num < max(s_list))
        stop(
          "The number of screening features must be equal or greater than the maximum one in support.size!"
        )
    } else{
      if (screening.num < s_max)
        stop("The number of screening features must be equal or greater than the max(gs.range)!")
    }
    screening <- TRUE
    screening_num <- screening.num
  }
  
  # check always included variables:
  if (is.null(always.include)) {
    always_include <- numeric(0)
  } else {
    if (anyNA(always.include)) {
      stop("always.include has missing values.")
    }
    if (any(always.include <= 0)) {
      stop("always.include should be an vector containing variable indexes which is positive.")
    }
    always.include <- as.integer(always.include) - 1
    if (length(always.include) > screening_num)
      stop("The number of variables in always.include should not exceed the screening.num")
    if (path_type == 1) {
      if (length(always.include) > max(s_list))
        stop("always.include containing too many variables. 
             The length of it should not exceed the maximum in support.size.")
    } else{
      if (length(always.include) > s_max)
        stop("always.include containing too many variables. The length of it should not exceed the max(gs.range).")
    }
    always_include <- always.include
  }
  
  t1 <- proc.time()
  result <- abessCpp2(
    x = x,
    y = y,
    n = nobs,
    p = nvars,
    data_type = normalize,
    weight = weight, 
    sigma = matrix(0), 
    is_normal = is_normal,
    algorithm_type = 6,
    model_type = model_type,
    max_iter = max_splicing_iter,
    exchange_num = c_max,
    path_type = path_type,
    is_warm_start = warm.start,
    ic_type = ic_type,
    ic_coef = 1.0,
    is_cv = is_cv,
    Kfold = nfolds,
    status = c(0),
    sequence = as.vector(s_list),
    lambda_seq = lambda,
    s_min = s_min,
    s_max = s_max,
    K_max = as.integer(20),
    epsilon = 0.0001,
    lambda_max = 0,
    lambda_min = 0,
    nlambda = 10,
    is_screening = screening,
    screening_size = screening_num,
    powell_path = 1,
    g_index = g_index,
    always_select = always_include,
    tau = 0.0,
    primary_model_fit_max_iter = max_newton_iter,
    primary_model_fit_epsilon = newton_thresh,
    early_stop = early_stop,
    approximate_Newton = approximate_newton,
    thread = num_threads, 
    covariance_update = covariance_update,
    sparse_matrix = sparse_X, 
    splicing_type = splicing_type
  )
  t2 <- proc.time()
  # print(t2 - t1)
  
  ## process result
  
  ### process best model (abandon):
  # support.index <- which(result[["beta"]] != 0.0)
  # names(result[["beta"]]) <- vn
  # best_model <- list("beta" = result[["beta"]], 
  #                    "coef0" = result[["coef0"]], 
  #                    "support.index" = support.index,
  #                    "support.size" = sum(result[["beta"]] != 0.0), 
  #                    "dev" = result[["train_loss"]], 
  #                    "tune.value" = result[["ic"]])
  # result[["best.model"]] <- best_model
  
  result[["beta"]] <- NULL
  result[["coef0"]] <- NULL
  result[["train_loss"]] <- NULL
  result[["ic"]] <- NULL
  result[["lambda"]] <- NULL
  
  result[["nobs"]] <- nobs
  result[["nvars"]] <- nvars
  result[["family"]] <- family
  result[["tune.path"]] <- tune.path
  # result[["support.df"]] <- g_df
  result[["tune.type"]] <- ifelse(is_cv == TRUE, "cv", 
                                  c("AIC", "BIC", "GIC", "EBIC")[ic_type])  
  result[["gs.range"]] <- gs.range
  
  ## preprocessing result in "gsection"
  if (tune.path == "gsection") {
    ## change the order:
    reserve_order <- length(result[["sequence"]]):1
    result[["beta_all"]] <- result[["beta_all"]][reserve_order]
    result[["coef0_all"]] <- result[["coef0_all"]][reserve_order, , drop = FALSE]
    result[["train_loss_all"]] <- result[["train_loss_all"]][reserve_order, , drop = FALSE]
    result[["ic_all"]] <- result[["ic_all"]][reserve_order, , drop = FALSE]
    result[["test_loss_all"]] <- result[["test_loss_all"]][reserve_order, , drop = FALSE]
    result[["sequence"]] <- result[["sequence"]][reserve_order]
    gs_unique_index <- match(sort(unique(result[["sequence"]])), result[["sequence"]])
    
    ## remove replicate support size:
    result[["beta_all"]] <- result[["beta_all"]][gs_unique_index]
    result[["coef0_all"]] <- result[["coef0_all"]][gs_unique_index, , drop = FALSE]
    result[["train_loss_all"]] <- result[["train_loss_all"]][gs_unique_index, , drop = FALSE]
    result[["ic_all"]] <- result[["ic_all"]][gs_unique_index, , drop = FALSE]
    result[["test_loss_all"]] <- result[["test_loss_all"]][gs_unique_index, , drop = FALSE]
    result[["sequence"]] <- result[["sequence"]][gs_unique_index]
    result[["support.size"]] <- result[["sequence"]]
    s_list <- result[["support.size"]]
    result[["sequence"]] <- NULL
  } else {
    result[["support.size"]] <- s_list
  }
  
  names(result)[which(names(result) == "train_loss_all")] <- "dev"
  if (is_cv) {
    names(result)[which(names(result) == "test_loss_all")] <- "tune.value"
    result[["ic_all"]] <- NULL
  } else {
    names(result)[which(names(result) == "ic_all")] <- "tune.value"
    result[["test_loss_all"]] <- NULL
  }
  result[["best.size"]] <- s_list[which.min(result[["tune.value"]])]
  names(result)[which(names(result) == "coef0_all")] <- "intercept"
  if (family == "multinomial") {
    result[["intercept"]] <- lapply(result[["intercept"]], function(x) {
      x <- x[-y_dim]
    })
  }
  names(result)[which(names(result) == 'beta_all')] <- "beta"
  # names(result)[which(names(result) == 'screening_A')] <- "screening.index"
  # result[["screening.index"]] <- result[["screening.index"]] + 1
  
  if (multi_y) {
    if (screening) {
      for (i in 1:length(result[["beta"]])) {
        beta_all <- matrix(0, nrow = nvars, ncol = y_dim)
        beta_all[result[["screening_A"]] + 1, ] <- result[["beta"]][[i]]
        result[["beta"]][[i]] <- beta_all 
      }
    }
    names(result[["beta"]]) <- as.character(s_list)
    if (family == "mgaussian") {
      result[["beta"]] <- lapply(result[["beta"]], Matrix::Matrix, 
                                 sparse = TRUE, dimnames = list(vn, y_vn))
    } else {
      result[["beta"]] <- lapply(result[["beta"]], function(x) { 
        Matrix::Matrix(x[, -y_dim], sparse = TRUE, dimnames = list(vn, y_vn[-1]))
      })
    }
  } else {
    result[["beta"]] <- do.call("cbind", result[["beta"]])
    if (screening) {
      beta_all <- matrix(0, nrow = nvars, 
                         ncol = length(s_list))
      beta_all[result[["screening_A"]] + 1, ] <- result[["beta"]]
      result[["beta"]] <- beta_all
    }
    result[["beta"]] <- Matrix::Matrix(result[["beta"]], 
                                       sparse = TRUE, 
                                       dimnames = list(vn, as.character(s_list)))
  }
  
  result[["screening.vars"]] <- vn[result[["screening_A"]] + 1]
  result[["screening_A"]] <- NULL
  
  # if (s_list[0] == 0) {
  #   nulldev <- result[["dev"]][1]
  # } else {
  #   f <- switch(
  #     family,
  #     "gaussian" = gaussian(),
  #     "binomial" = binomial(),
  #     "poisson" = poisson()
  #   )
  #   if (family != "cox") {
  #     nulldev <- deviance(glm(y ~ ., 
  #                             data = cbind.data.frame(y, 1), 
  #                             family = f))
  #   } else {
  #     nulldev <- 0
  #   }
  # }
  # result[["nulldev"]] <- 0 
  
  result[["call"]] <- match.call()
  class(result) <- "abess"
  
  set.seed(NULL)
  
  return(result)
}

#' @rdname abess
#'
#' @param formula an object of class "\code{formula}": 
#' a symbolic description of the model to be fitted. 
#' The details of model specification are given in the "Details" section of "\code{\link{formula}}".
#' @param data a data frame containing the variables in the \code{formula}. 
#' @param subset an optional vector specifying a subset of observations to be used.
#' @param na.action a function which indicates 
#' what should happen when the data contain \code{NA}s. 
#' Defaults to \code{getOption("na.action")}.
#' @method abess formula
#' @export
#' @examples
#' \donttest{
#' ################  Formula interface  ################
#' data("trim32")
#' abess_fit <- abess(y ~ ., data = trim32)
#' abess_fit
#' }
abess.formula <- function(formula, data, subset, na.action, ...) {
  contrasts <- NULL   ## for sparse X matrix
  cl <- match.call()
  mf <- match.call(expand.dots = FALSE)
  m <- match(c("formula", "data", "subset", "na.action"), 
             names(mf), 0L)
  mf <- mf[c(1L, m)]
  mf$drop.unused.levels <- TRUE
  mf[[1L]] <- quote(stats::model.frame)
  mf <- eval(mf, parent.frame())
  mt <- attr(mf, "terms")
  
  y <- model.response(mf, "numeric")
  x <- abess_model_matrix(mt, mf, contrasts)[, -1]
  
  # all_name <- all.vars(mt)
  # if (abess_res[["family"]] == "cox") {
  #   response_name <- all_name[1:2]
  # } else {
  #   response_name <- all_name[1]
  # }
  
  abess_res <- abess.default(x, y, ...)
  abess_res[["call"]] <- cl
  
  # best_support <- abess_res[["best.model"]][["support.index"]]
  # support_name <- colnames(x)[best_support]
  # 
  # response_index <- match(response_name, all_name)
  # x_index <- match(support_name, all_name)
  # abess_res[["best.model"]][["support.index"]] <- x_index
  # names(abess_res[["best.model"]][["support.index"]]) <- support_name
  
  abess_res
}
