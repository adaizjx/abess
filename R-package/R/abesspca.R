#' Adaptive best subset selection for principal component analysis
#' 
#' @inheritParams abess.default
#' @param x A matrix object. It can be either the predictor matrix where each row is an observation and each column is 
#' a predictor or the sample covariance/correlation matrix. 
#' @param type If \code{type = "predictor"}, \code{x} is considered as the predictor matrix. 
#' If \code{type = "gram"}, \code{x} is considered as a sample covariance or correlation matrix.
#' @param sparse.type If \code{sparse.type = "fpc"}, then best subset selection performs on the first principal component; 
#' If \code{sparse.type = "kpc"}, then best subset selection performs on the first \eqn{K} principal components. 
#' @param cor A logical value. If \code{cor = TRUE}, perform PCA on the correlation matrix; 
#' otherwise, the covariance matrix. 
#' This option is available only if \code{type = "predictor"}. 
#' Default: \code{cor = FALSE}.
#' @param support.size An integer vector. It represents the alternative support sizes when \code{sparse.type = "fpc"}, 
#' while each support size controls the sparsity of a principal component when \code{sparse.type = "kpc"}. 
#' When \code{sparse.type = "fpc"} but \code{support.size} is not supplied, 
#' it is set as \code{support.size = 1:min(ncol(x), 100)} if \code{group.index = NULL};
#' otherwise, \code{support.size = 1:min(length(unique(group.index)), 100)}. 
#' When \code{sparse.type = "kpc"} but \code{support.size} is not supplied, 
#' then for 20\% principal components, 
#' it is set as \code{min(ncol(x), 100)} if \code{group.index = NULL};
#' otherwise, \code{min(length(unique(group.index)), 100)}. 
#' @param splicing.type Optional type for splicing. 
#' If \code{splicing.type = 1}, the number of variables to be spliced is 
#' \code{c.max}, ..., \code{1}; if \code{splicing.type = 2}, 
#' the number of variables to be spliced is \code{c.max}, \code{c.max/2}, ..., \code{1}.
#' Default: \code{splicing.type = 1}.
#' 
#' @details Adaptive best subset selection for principal component analysis aim 
#' to solve the non-convex optimization problem:
#' \deqn{\arg\max_{v} v^\top \Sigma v, s.t.\quad v^\top v=1, \|v\|_0 \leq s, }
#' where \eqn{s} is support size. A generic splicing technique is implemented to 
#' solve this problem. 
#' By exploiting the warm-start initialization, the non-convex optimization 
#' problem at different support size (specified by \code{support.size}) 
#' can be efficiently solved.
#' 
#' 
#' @return A S3 \code{abesspca} class object, which is a \code{list} with the following components:
#' \item{loadings}{A \eqn{p}-by-\code{length(support.size)} loading matrix of sparse principal components (PC), 
#' where each row is a variable and each column is a support size;}
#' \item{nvars}{The number of variables.}
#' \item{sparse.type}{The same as input.}
#' \item{support.size}{The actual support.size values used. Note that it is not necessary the same as the input if the later have non-integer values or duplicated values.}
#' \item{ev}{A vector with size \code{length(support.size)}. It records the explained variance at each support size.}
#' \item{pev}{A vector with the same length as \code{ev}. It records the percentage of explained variance at each support size.}
#' \item{var.all}{If \code{sparse.type = "fpc"}, 
#' it is the total variance of the explained by first principal component; 
#' otherwise, the total standard deviations of all principal components.}
#' \item{call}{The original call to \code{abess}.}
#' 
#' @author Jin Zhu, Junxian Zhu, Ruihuang Liu, Junhao Huang, Xueqin Wang 
#' 
#' @export
#' 
#' @seealso \code{\link{print.abesspca}}, 
#' \code{\link{loadings.abesspca}}, 
# \code{\link{plot.abesspca}}. 
#'
#' @examples
#' \donttest{
#' library(abess)
#' 
#' ## predictor matrix input:
#' head(USArrests)  
#' pca_fit <- abesspca(USArrests)
#' pca_fit
#' 
#' ## covariance matrix input:
#' pca_fit <- abesspca(stats::cov(USArrests), type = "gram")
#' pca_fit
#' 
#' ## robust covariance matrix input:
#' rob_cov <- MASS::cov.rob(USArrests)[["cov"]]
#' rob_cov <- (rob_cov + t(rob_cov)) / 2
#' pca_fit <- abesspca(rob_cov, type = "gram")
#' pca_fit
#' 
#' ## K-component principal component analysis
#' pca_fit <- abesspca(USArrests, sparse.type = "kpc", 
#'                     support.size = c(1, 2))
#' loadings(pca_fit)
#' }
abesspca <- function(x, 
                     type = c("predictor", "gram"), 
                     sparse.type = c("fpc", "kpc"), 
                     cor = FALSE, 
                     support.size = NULL, 
                     c.max = 2,
                     lambda = 0,
                     always.include = NULL,
                     group.index = NULL, 
                     splicing.type = 1, 
                     max.splicing.iter = 20,
                     warm.start = TRUE,
                     ...)
{
  support.num <- NULL
  
  ## check warm start:
  stopifnot(is.logical(warm.start))
  
  ## check splicing type
  stopifnot(length(splicing.type) == 1)
  stopifnot(splicing.type %in% c(1, 2))
  splicing_type <- as.integer(splicing.type)
  
  ## check max splicing iteration
  stopifnot(is.numeric(max.splicing.iter) & max.splicing.iter >= 1)
  max_splicing_iter <- as.integer(max.splicing.iter)
  
  ## check x matrix:
  stopifnot(!anyNA(x))
  if (!is.matrix(x)) {
    x <- as.matrix(x)
  }
  
  ## compute gram matrix
  cov_type <- match.arg(type)
  if (cov_type == "gram") {
    stopifnot(dim(x)[1] == dim(x)[2])
    stopifnot(all(t(x) == x))
  } else {
    stopifnot(length(cor) == 1)
    stopifnot(is.logical(cor))
    if (cor) {
      x <- stats::cor(x)
    } else {
      x <- stats::cov(x)
    }
  }
  nvars <- dim(x)[2]
  vn <- colnames(x)
  if (is.null(vn)) {
    vn <- paste0("x", 1:nvars)
  }
  
  ## check sparse.type
  sparse_type <- match.arg(sparse.type)
  
  ## total variance: 
  # svdobj <- svd(x)
  # stopifnot(all(svdobj[["d"]] > 0))
  # total_variance <- sum((svdobj[["d"]])^2)
  # v <- svdobj[["v"]]
  
  ## check C-max:
  stopifnot(is.numeric(c.max) & c.max >= 1)
  if (c.max >= nvars) {
    stop("c.max should smaller than the number of predictors!")
  }
  c_max <- as.integer(c.max)
  
  ## check lambda:
  stopifnot(!anyNA(lambda))
  stopifnot(all(lambda >= 0))
  
  ## group variable:
  group_select <- FALSE
  if (is.null(group.index)) {
    g_index <- 1:nvars - 1
    ngroup <- 1
  } else {
    group_select <- TRUE
    gi <- unique(group.index)
    g_index <- match(gi, group.index) - 1
    g_df <- c(diff(g_index), nvars - max(g_index))
    ngroup <- length(g_index)
    max_group_size <- max(g_df)
  }
  
  # sparse level list (sequence):
  if (group_select) {
    s_max <- ngroup
  } else {
    s_max <- nvars
  }
  
  if (is.null(support.size)) {
    if (sparse_type == "fpc") {
      if (is.null(support.num)) {
        if (group_select) {
          s_num <- min(ngroup, 100)
        } else {
          s_num <- min(nvars, 100)
        }
      } else {
        s_num <- support.num
        if (group_select) {
          stopifnot(s_num <= ngroup)
        } else {
          stopifnot(s_num <= nvars)
        }
      }
      s_list <-
        round(seq.int(
          from = 1,
          to = s_max,
          length.out = s_num
        ))
      s_list <- unique(s_list)
      k_num <- 1
    } else {
      if (group_select) {
        s_num <- min(ngroup, 100)
        k_num <- round(ngroup * 0.2)
      } else {
        s_num <- min(nvars, 100)
        k_num <- round(nvars * 0.2)
      }
      s_list <- rep(s_num, k_num)
    }
  } else {
    stopifnot(any(is.numeric(support.size) & support.size >= 0))
    if (group_select) {
      stopifnot(max(support.size) <= ngroup)
    } else {
      stopifnot(max(support.size) <= nvars)
    }
    if (sparse_type == "fpc") {
      support.size <- sort(support.size)
      support.size <- unique(support.size)
      k_num <- 1
    } else {
      k_num <- length(support.size)
    }
    s_list <- support.size
  }
  
  ## check always included variables:
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
    if (length(always.include) > max(s_list)) {
      stop("always.include containing too many variables. 
             The length of it should not exceed the maximum in support.size.")
    }

    always_include <- always.include
  }
  
  ## total variance:
  if (sparse_type == "fpc") {
    total_variance <- eigen(x, only.values = TRUE)[["values"]][1]
  } else {
    total_variance <- sum(eigen(x, only.values = TRUE)[["values"]])
  }
  
  ## Cpp interface:
  res_list <- list()
  k <- 0
  s_list_copy <- s_list
  while(k_num > 0) {
    k_num <- k_num - 1
    k <- k + 1
    if (sparse_type == "fpc") {
      s_list_tmp <- s_list_copy
    } else {
      s_list_tmp <- s_list_copy[1]
    }
    result <- abessCpp2(
      x = matrix(1, ncol = nvars, nrow = 2),
      y = matrix(0),
      n = 1,
      p = nvars,
      data_type = 1,
      weight = c(1), 
      sigma = x, 
      is_normal = FALSE,
      algorithm_type = 6,
      model_type = 7,
      max_iter = max_splicing_iter,
      exchange_num = c_max,
      path_type = 1,
      is_warm_start = warm.start,
      ic_type = 1,
      ic_coef = 1.0,
      is_cv = FALSE,
      Kfold = 2,
      status = c(0),
      sequence = as.vector(s_list_tmp),
      lambda_seq = lambda,
      s_min = 0,
      s_max = 10,
      K_max = as.integer(20),
      epsilon = 0.0001,
      lambda_max = 0,
      lambda_min = 0,
      nlambda = 10,
      is_screening = FALSE,
      screening_size = 0,
      powell_path = 1,
      g_index = g_index,
      always_select = always_include,
      tau = 0.0,
      primary_model_fit_max_iter = 1,
      primary_model_fit_epsilon = 1e-3,
      early_stop = FALSE,
      approximate_Newton = FALSE,
      thread = 1, 
      covariance_update = FALSE,
      sparse_matrix = FALSE, 
      splicing_type = splicing_type
    )

    if (sparse_type != "fpc") {
      direction_new <- result[["beta_all"]][[1]]
      x <- project_cov(x, direction_new)
    }
    res_list[[k]] <- result
    s_list_copy <- s_list_copy[-1]
  }
  
  result <- list()
  
  # result[["beta"]] <- NULL
  # result[["coef0"]] <- NULL
  # result[["train_loss"]] <- NULL
  # result[["ic"]] <- NULL
  # result[["coef0_all"]] <- NULL
  # result[["ic_all"]] <- NULL
  # result[["test_loss_all"]] <- NULL
  
  result[["nvars"]] <- nvars
  result[["support.size"]] <- s_list
  result[["sparse.type"]] <- sparse_type
  if (sparse_type == "fpc") {
    result[["loadings"]] <- res_list[[1]][["beta_all"]]
    result[["ev"]] <- - res_list[[1]][["train_loss_all"]][, 1]
    # names(result)[which(names(result) == "train_loss_all")] <- "ev"
    # result[["ev"]] <- - result[["ev"]][, 1]
  } else {
    result[["loadings"]] <- lapply(res_list, function(x) {
      x[["beta_all"]][[1]]
    })
    result[["ev"]] <- sapply(res_list, function(x) {
      - x[["train_loss_all"]][1, 1]
    })
    result[["ev"]] <- cumsum(result[["ev"]])
  }
  
  # names(result)[which(names(result) == 'beta_all')] <- "loadings"
  result[["loadings"]] <- do.call("cbind", result[["loadings"]])
  result[["loadings"]] <- Matrix::Matrix(result[["loadings"]], 
                                         sparse = TRUE, 
                                         dimnames = list(vn, 
                                                         as.character(s_list)))
  
  result[["pev"]] <- result[["ev"]] / total_variance
  result[["var.all"]] <- total_variance
  
  result[["call"]] <- match.call()
  out <- result
  
  class(out) <- "abesspca"
  out
}

variance_explained <- function(X, loading){
  Z <- qr(X %*% loading)
  result <- sum(diag(qr.R(Z))^2)
  return(result)
}

project_cov <- function(cov_mat, direction) {
  term2 <- (t(direction) %*% (cov_mat %*% as.matrix(direction)))[1, 1] * as.matrix(direction) %*% t(direction)
  term3 <- as.matrix(direction) %*% (t(direction) %*% cov_mat)
  term4 <- (cov_mat %*% as.matrix(direction)) %*% t(direction)
  cov_mat + term2 - term3 - term4
}
