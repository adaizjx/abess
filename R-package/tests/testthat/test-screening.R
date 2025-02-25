library(abess)
library(testthat)

test_batch <- function(n, p, support_size, family, formula) {
  dataset <- generate.data(n, p, support_size, 
                           family = family, seed = 1)
  if (formula) {
    if (family == "mgaussian") {
      dat <- cbind.data.frame(dataset[["x"]], dataset[["y"]])
    } else if (family == "cox") {
      dat <- cbind.data.frame(dataset[["x"]], dataset[["y"]])
    } else {
      dat <- cbind.data.frame(dataset[["x"]][, 1:30], "y" = dataset[["y"]], 
                              dataset[["x"]][, 31:p])
    }
  }
  if (family %in% c("gaussian", "mgaussian")) {
    abess_fit <- abess(dataset[["x"]], dataset[["y"]], family = family, 
                       tune.type = "gic", screening.num = n, support.size = 0:1)
    if (formula) {
      if (family == "mgaussian") {
        abess_fit <- abess(cbind(y1, y2, y3) ~ ., data = dat, 
                           family = "mgaussian", tune.type = "gic", 
                           screening.num = n, support.size = 0:1)
      } else {
        abess_fit <- abess(y ~ ., data = dat, 
                           tune.type = "gic", 
                           screening.num = n, 
                           family = family, support.size = 0:1)
      }
    }
  } else {
    if (family == "poisson") {
      abess_fit <- abess(dataset[["x"]], dataset[["y"]], family = family, 
                         tune.type = "gic", screening.num = n, 
                         max.newton.iter = 50, support.size = 0:1, newton.thresh = 1e-8)      
    } else {
      abess_fit <- abess(dataset[["x"]], dataset[["y"]], family = family, 
                         tune.type = "gic", screening.num = n, 
                         newton = "approx", support.size = 0:1)
    }


    if (formula) {
      if (family == "cox") {
        abess_fit <- abess(cbind(time, status) ~ ., data = dat, 
                           tune.type = "gic", 
                           screening.num = n, 
                           family = family, 
                           newton = "approx", support.size = 0:1)
      } else if (family == "poisson") {
        abess_fit <- abess(y ~ ., data = dat, 
                           tune.type = "gic", 
                           screening.num = n, 
                           family = family, 
                           support.size = 0:1, 
                           max.newton.iter = 50)
      } else {
        abess_fit <- abess(y ~ ., data = dat, 
                           tune.type = "gic", 
                           screening.num = n, 
                           family = family, 
                           newton = "approx", support.size = 0:1)
      }
    }
  }
  
  ## support size
  screening_vars <- abess_fit[["screening.vars"]]
  if (family %in% c("mgaussian", "multinomial")) {
    true_index <- which(apply(dataset[["beta"]], 1, function(x) {
      all(x != 0)
    }))
  } else {
    true_index <- which(dataset[["beta"]] != 0)
  }
  true_vars <- paste0("x", true_index)
  expect_true(all(true_vars %in% screening_vars))
}

test_that("screening (gaussian) works", {
  n <- 200
  p <- 2000
  support_size <- 3
  
  ## default interface
  test_batch(n, p, support_size, "gaussian", FALSE)
  
  ## formula interface
  test_batch(n, p, support_size, "gaussian", TRUE)
})

test_that("screening (binomial) works", {
  n <- 200
  p <- 2000
  support_size <- 3
  
  ## default interface
  test_batch(n, p, support_size, "binomial", FALSE)
  
  ## formula interface
  test_batch(n, p, support_size, "binomial", TRUE)
})

test_that("screening (cox) works", {
  skip("skip cox now!")
  n <- 300
  p <- 1000
  support_size <- 3
  
  ## default interface
  test_batch(n, p, support_size, "cox", FALSE)
  
  ## formula interface
  test_batch(n, p, support_size, "cox", TRUE)
})

test_that("screening (poisson) works", {
  # skip("Skip poisson now!")
  n <- 200
  p <- 2500
  support_size <- 4
  
  ## default interface
  test_batch(n, p, support_size, "poisson", FALSE)
  
  ## formula interface
  test_batch(n, p, support_size, "poisson", TRUE)
})

test_that("screening (mgaussian) works", {
  n <- 200
  p <- 2000
  support_size <- 3
  
  ## default interface
  test_batch(n, p, support_size, "mgaussian", FALSE)
  
  ## formula interface
  test_batch(n, p, support_size, "mgaussian", TRUE)
})

test_that("screening (multinomial) works", {
  n <- 200
  p <- 2000
  support_size <- 3
  
  ## default interface
  test_batch(n, p, support_size, "multinomial", FALSE)
  
  ## formula interface
  test_batch(n, p, support_size, "multinomial", TRUE)
})
