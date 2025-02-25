// #define R_BUILD
// #define TEST
#ifdef R_BUILD

#include <Rcpp.h>
#include <RcppEigen.h>
//[[Rcpp::depends(RcppEigen)]]
using namespace Rcpp;

#else

#include <Eigen/Eigen>
#include "List.h"

#endif

#include <iostream>
#include "Data.h"
#include "Algorithm.h"
#include "Metric.h"
#include "path.h"
// #include "path.cpp"
#include "utilities.h"
#include "abess.h"
#include "screening.h"
#include <vector>

typedef Eigen::Triplet<double> triplet;

#ifdef _OPENMP
#include <omp.h>
// [[Rcpp::plugins(openmp)]]
#else
#ifndef DISABLE_OPENMP
// use pragma message instead of warning
#pragma message("Warning: OpenMP is not available, "                 \
                "project will be compiled into single-thread code. " \
                "Use OpenMP-enabled compiler to get benefit of multi-threading.")
#endif
inline int omp_get_thread_num()
{
  return 0;
}
inline int omp_get_num_threads() { return 1; }
inline int omp_get_num_procs() { return 1; }
inline void omp_set_num_threads(int nthread) {}
inline void omp_set_dynamic(int flag) {}
#endif

// #ifdef OTHER_ALGORITHM2
// #include "PrincipalBallAlgorithm.h"
// #endif

using namespace Eigen;
using namespace std;

// [[Rcpp::export]]
List abessCpp2(Eigen::MatrixXd x, Eigen::MatrixXd y, int n, int p,
               int data_type, Eigen::VectorXd weight, Eigen::MatrixXd sigma,
               bool is_normal,
               int algorithm_type, int model_type, int max_iter, int exchange_num,
               int path_type, bool is_warm_start,
               int ic_type, double ic_coef, bool is_cv, int Kfold,
               Eigen::VectorXi status,
               Eigen::VectorXi sequence,
               Eigen::VectorXd lambda_seq,
               int s_min, int s_max, int K_max, double epsilon,
               double lambda_min, double lambda_max, int nlambda,
               bool is_screening, int screening_size, int powell_path,
               Eigen::VectorXi g_index,
               Eigen::VectorXi always_select,
               double tau,
               int primary_model_fit_max_iter, double primary_model_fit_epsilon,
               bool early_stop, bool approximate_Newton,
               int thread,
               bool covariance_update,
               bool sparse_matrix,
               int splicing_type)
{
  bool is_parallel = thread != 1;

#ifdef _OPENMP
  // Eigen::initParallel();
  if (thread == 0)
  {
    thread = omp_get_max_threads();
  }
  Eigen::setNbThreads(thread);
  omp_set_num_threads(thread);
#ifdef TEST
  cout << Eigen::nbThreads() << " Threads for eigen." << endl;
  cout << omp_get_num_threads() << " Threads for omp." << endl;
#endif
#endif

  Algorithm<Eigen::VectorXd, Eigen::VectorXd, double, Eigen::MatrixXd> *algorithm_uni_dense = nullptr;
  Algorithm<Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::MatrixXd> *algorithm_mul_dense = nullptr;
  Algorithm<Eigen::VectorXd, Eigen::VectorXd, double, Eigen::SparseMatrix<double>> *algorithm_uni_sparse = nullptr;
  Algorithm<Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::SparseMatrix<double>> *algorithm_mul_sparse = nullptr;

  //////////////////// function generate_algorithm_pointer() ////////////////////////////
  // to do
  if (!sparse_matrix)
  {
    if (algorithm_type == 6)
    {
      if (model_type == 1)
      {
        algorithm_uni_dense = new abessLm<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
      }
      else if (model_type == 2)
      {
        algorithm_uni_dense = new abessLogistic<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 3)
      {
        algorithm_uni_dense = new abessPoisson<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 4)
      {
        algorithm_uni_dense = new abessCox<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 5)
      {
        algorithm_mul_dense = new abessMLm<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
      }
      else if (model_type == 6)
      {
        algorithm_mul_dense = new abessMultinomial<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 7)
      {
        algorithm_uni_dense = new abessPCA<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
    }
  }
  else
  {
    if (algorithm_type == 6)
    {
      if (model_type == 1)
      {
        algorithm_uni_sparse = new abessLm<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
      }
      else if (model_type == 2)
      {
        algorithm_uni_sparse = new abessLogistic<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 3)
      {
        algorithm_uni_sparse = new abessPoisson<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 4)
      {
        algorithm_uni_sparse = new abessCox<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 5)
      {
        algorithm_mul_sparse = new abessMLm<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
      }
      else if (model_type == 6)
      {
        algorithm_mul_sparse = new abessMultinomial<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
      else if (model_type == 7)
      {
        algorithm_uni_sparse = new abessPCA<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
      }
    }
  }

#ifdef TEST
  cout << "abesscpp2 1" << endl;
#endif

  vector<Algorithm<Eigen::VectorXd, Eigen::VectorXd, double, Eigen::MatrixXd> *> algorithm_list_uni_dense(max(Kfold, thread));
  vector<Algorithm<Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::MatrixXd> *> algorithm_list_mul_dense(max(Kfold, thread));
  vector<Algorithm<Eigen::VectorXd, Eigen::VectorXd, double, Eigen::SparseMatrix<double>> *> algorithm_list_uni_sparse(max(Kfold, thread));
  vector<Algorithm<Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::SparseMatrix<double>> *> algorithm_list_mul_sparse(max(Kfold, thread));
  if (is_cv)
  {
    for (int i = 0; i < max(Kfold, thread); i++)
    {
      if (!sparse_matrix)
      {
        if (algorithm_type == 6)
        {
          if (model_type == 1)
          {
            algorithm_list_uni_dense[i] = new abessLm<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
          }
          else if (model_type == 2)
          {
            algorithm_list_uni_dense[i] = new abessLogistic<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 3)
          {
            algorithm_list_uni_dense[i] = new abessPoisson<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 4)
          {
            algorithm_list_uni_dense[i] = new abessCox<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 5)
          {
            algorithm_list_mul_dense[i] = new abessMLm<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
          }
          else if (model_type == 6)
          {
            algorithm_list_mul_dense[i] = new abessMultinomial<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 7)
          {
            algorithm_list_uni_dense[i] = new abessPCA<Eigen::MatrixXd>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
        }
      }
      else
      {
        if (algorithm_type == 6)
        {
          if (model_type == 1)
          {
            algorithm_list_uni_sparse[i] = new abessLm<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
          }
          else if (model_type == 2)
          {
            algorithm_list_uni_sparse[i] = new abessLogistic<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 3)
          {
            algorithm_list_uni_sparse[i] = new abessPoisson<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 4)
          {
            algorithm_list_uni_sparse[i] = new abessCox<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 5)
          {
            algorithm_list_mul_sparse[i] = new abessMLm<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, covariance_update, splicing_type);
          }
          else if (model_type == 6)
          {
            algorithm_list_mul_sparse[i] = new abessMultinomial<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
          else if (model_type == 7)
          {
            algorithm_list_uni_sparse[i] = new abessPCA<Eigen::SparseMatrix<double>>(algorithm_type, model_type, max_iter, primary_model_fit_max_iter, primary_model_fit_epsilon, is_warm_start, exchange_num, approximate_Newton, always_select, splicing_type);
          }
        }
      }
    }
  }
#ifdef TEST
  cout << "abesscpp2 2" << endl;
#endif

  List out_result;
  if (!sparse_matrix)
  {
    if (y.cols() == 1)
    {
#ifdef TEST
      cout << "abesscpp2 4" << endl;
      cout << "uni_dense" << endl;
#endif
      Eigen::VectorXd y_vec = y.col(0).eval();

      out_result = abessCpp<Eigen::VectorXd, Eigen::VectorXd, double, Eigen::MatrixXd>(x, y_vec, n, p,
                                                                                       data_type, weight, sigma,
                                                                                       is_normal,
                                                                                       algorithm_type, model_type, max_iter, exchange_num,
                                                                                       path_type, is_warm_start,
                                                                                       ic_type, ic_coef, is_cv, Kfold,
                                                                                       status,
                                                                                       sequence,
                                                                                       lambda_seq,
                                                                                       s_min, s_max, K_max, epsilon,
                                                                                       lambda_min, lambda_max, nlambda,
                                                                                       is_screening, screening_size, powell_path,
                                                                                       g_index,
                                                                                       always_select,
                                                                                       tau,
                                                                                       primary_model_fit_max_iter, primary_model_fit_epsilon,
                                                                                       early_stop, approximate_Newton,
                                                                                       thread,
                                                                                       covariance_update,
                                                                                       sparse_matrix,
                                                                                       algorithm_uni_dense, algorithm_list_uni_dense);
#ifdef TEST
      cout << "abesscpp2 5" << endl;
#endif
    }
    else
    {
#ifdef TEST
      cout << "abesscpp2 5" << endl;
      cout << "mul_dense" << endl;
#endif
      out_result = abessCpp<Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::MatrixXd>(x, y, n, p,
                                                                                                data_type, weight, sigma,
                                                                                                is_normal,
                                                                                                algorithm_type, model_type, max_iter, exchange_num,
                                                                                                path_type, is_warm_start,
                                                                                                ic_type, ic_coef, is_cv, Kfold,
                                                                                                status,
                                                                                                sequence,
                                                                                                lambda_seq,
                                                                                                s_min, s_max, K_max, epsilon,
                                                                                                lambda_min, lambda_max, nlambda,
                                                                                                is_screening, screening_size, powell_path,
                                                                                                g_index,
                                                                                                always_select,
                                                                                                tau,
                                                                                                primary_model_fit_max_iter, primary_model_fit_epsilon,
                                                                                                early_stop, approximate_Newton,
                                                                                                thread,
                                                                                                covariance_update,
                                                                                                sparse_matrix,
                                                                                                algorithm_mul_dense, algorithm_list_mul_dense);
#ifdef TEST
      cout << "abesscpp2 6" << endl;
#endif
    }
  }
  else
  {
#ifdef TEST
    clock_t t1 = clock();
#endif
    Eigen::SparseMatrix<double> sparse_x(n, p);

    // std::vector<triplet> tripletList;
    // tripletList.reserve(x.rows());
    // for (int i = 0; i < x.rows(); i++)
    // {
    //   tripletList.push_back(triplet(int(x(i, 1)), int(x(i, 2)), x(i, 0)));
    // }
    // sparse_x.setFromTriplets(tripletList.begin(), tripletList.end());

    sparse_x.reserve(x.rows());
    for (int i = 0; i < x.rows(); i++)
    {
      sparse_x.insert(int(x(i, 1)), int(x(i, 2))) = x(i, 0);
    }
    sparse_x.makeCompressed();

#ifdef TEST
    cout << "sparse x nonZeros: " << sparse_x.nonZeros() << endl;
    clock_t t2 = clock();
    std::cout << "sparse X time: " << ((double)(t2 - t1) / CLOCKS_PER_SEC) << endl;
#endif

    if (y.cols() == 1)
    {
#ifdef TEST
      cout << "abesscpp2 3" << endl;
      cout << "uni_sparse" << endl;
#endif
      Eigen::VectorXd y_vec = y.col(0).eval();

      out_result = abessCpp<Eigen::VectorXd, Eigen::VectorXd, double, Eigen::SparseMatrix<double>>(sparse_x, y_vec, n, p,
                                                                                                   data_type, weight, sigma,
                                                                                                   is_normal,
                                                                                                   algorithm_type, model_type, max_iter, exchange_num,
                                                                                                   path_type, is_warm_start,
                                                                                                   ic_type, ic_coef, is_cv, Kfold,
                                                                                                   status,
                                                                                                   sequence,
                                                                                                   lambda_seq,
                                                                                                   s_min, s_max, K_max, epsilon,
                                                                                                   lambda_min, lambda_max, nlambda,
                                                                                                   is_screening, screening_size, powell_path,
                                                                                                   g_index,
                                                                                                   always_select,
                                                                                                   tau,
                                                                                                   primary_model_fit_max_iter, primary_model_fit_epsilon,
                                                                                                   early_stop, approximate_Newton,
                                                                                                   thread,
                                                                                                   covariance_update,
                                                                                                   sparse_matrix,
                                                                                                   algorithm_uni_sparse, algorithm_list_uni_sparse);
#ifdef TEST
      cout << "abesscpp2 5" << endl;
#endif
    }
    else
    {
#ifdef TEST
      cout << "abesscpp2 5" << endl;
      cout << "mul_sparse" << endl;
#endif

      out_result = abessCpp<Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::SparseMatrix<double>>(sparse_x, y, n, p,
                                                                                                            data_type, weight, sigma,
                                                                                                            is_normal,
                                                                                                            algorithm_type, model_type, max_iter, exchange_num,
                                                                                                            path_type, is_warm_start,
                                                                                                            ic_type, ic_coef, is_cv, Kfold,
                                                                                                            status,
                                                                                                            sequence,
                                                                                                            lambda_seq,
                                                                                                            s_min, s_max, K_max, epsilon,
                                                                                                            lambda_min, lambda_max, nlambda,
                                                                                                            is_screening, screening_size, powell_path,
                                                                                                            g_index,
                                                                                                            always_select,
                                                                                                            tau,
                                                                                                            primary_model_fit_max_iter, primary_model_fit_epsilon,
                                                                                                            early_stop, approximate_Newton,
                                                                                                            thread,
                                                                                                            covariance_update,
                                                                                                            sparse_matrix,
                                                                                                            algorithm_mul_sparse, algorithm_list_mul_sparse);
#ifdef TEST
      cout << "abesscpp2 6" << endl;
#endif
    }
  }

  delete algorithm_uni_dense;
  delete algorithm_mul_dense;
  delete algorithm_uni_sparse;
  delete algorithm_mul_sparse;
  for (unsigned int i = 0; i < algorithm_list_uni_dense.size(); i++)
  {
    delete algorithm_list_uni_dense[i];
  }
  for (unsigned int i = 0; i < algorithm_list_mul_dense.size(); i++)
  {
    delete algorithm_list_mul_dense[i];
  }
  for (unsigned int i = 0; i < algorithm_list_uni_sparse.size(); i++)
  {
    delete algorithm_list_uni_sparse[i];
  }
  for (unsigned int i = 0; i < algorithm_list_mul_sparse.size(); i++)
  {
    delete algorithm_list_mul_sparse[i];
  }
  return out_result;
};

//  T1 for y, XTy, XTone
//  T2 for beta
//  T3 for coef0
//  T4 for X
//  <Eigen::VectorXd, Eigen::VectorXd, double, Eigen::MatrixXd> for Univariate Dense
//  <Eigen::VectorXd, Eigen::VectorXd, double, Eigen::SparseMatrix<double> > for Univariate Sparse
//  <Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::MatrixXd> for Multivariable Dense
//  <Eigen::MatrixXd, Eigen::MatrixXd, Eigen::VectorXd, Eigen::SparseMatrix<double> > for Multivariable Sparse
template <class T1, class T2, class T3, class T4>
List abessCpp(T4 &x, T1 &y, int n, int p,
              int data_type, Eigen::VectorXd weight, Eigen::MatrixXd sigma,
              bool is_normal,
              int algorithm_type, int model_type, int max_iter, int exchange_num,
              int path_type, bool is_warm_start,
              int ic_type, double ic_coef, bool is_cv, int Kfold,
              Eigen::VectorXi status,
              Eigen::VectorXi sequence,
              Eigen::VectorXd lambda_seq,
              int s_min, int s_max, int K_max, double epsilon,
              double lambda_min, double lambda_max, int nlambda,
              bool is_screening, int screening_size, int powell_path,
              Eigen::VectorXi g_index,
              Eigen::VectorXi always_select,
              double tau,
              int primary_model_fit_max_iter, double primary_model_fit_epsilon,
              bool early_stop, bool approximate_Newton,
              int thread,
              bool covariance_update,
              bool sparse_matrix,
              Algorithm<T1, T2, T3, T4> *algorithm, vector<Algorithm<T1, T2, T3, T4> *> algorithm_list)
{
  // to do: -openmp
#ifdef TEST
  clock_t t1, t2;
  cout << "abessCpp 1" << endl;
#endif

#ifndef R_BUILD
  std::srand(123);
#endif

  bool is_parallel = thread != 1;

  Data<T1, T2, T3, T4> data(x, y, data_type, weight, is_normal, g_index, status, sparse_matrix);

  Eigen::VectorXi screening_A;
  if (is_screening)
  {
    screening_A = screening(data, model_type, screening_size, always_select, approximate_Newton, primary_model_fit_max_iter, primary_model_fit_epsilon);
  }

  int M = data.y.cols();

  Metric<T1, T2, T3, T4> *metric = new Metric<T1, T2, T3, T4>(ic_type, ic_coef, is_cv, Kfold);

  // For CV:
  // 1:mask
  // 2:warm start save
  // 3:group_XTX
  if (is_cv)
  {
    metric->set_cv_train_test_mask(data, data.get_n());
    metric->set_cv_init_fit_arg(data.p, data.M);
    // metric->set_cv_initial_model_param(Kfold, data.get_p());
    // metric->set_cv_initial_A(Kfold, data.get_p());
    // metric->set_cv_initial_coef0(Kfold, data.get_p());
    // if (model_type == 1)
    //   metric->cal_cv_group_XTX(data);
  }

  // calculate loss for each parameter parameter combination
#ifdef TEST
  t1 = clock();
  cout << "abessCpp 2" << endl;
#endif
  Result<T2, T3> result;
  vector<Result<T2, T3>> result_list(Kfold);
  if (path_type == 1)
  {
    if (is_cv)
    {
      //////////////////////////////////can parallel///////////////////////////////////
      if (is_parallel)
      {
#pragma omp parallel for
        for (int i = 0; i < Kfold; i++)
        {
          sequential_path_cv<T1, T2, T3, T4>(data, sigma, algorithm_list[i], metric, sequence, lambda_seq, early_stop, i, result_list[i]);
        }
      }
      else
      {
        for (int i = 0; i < Kfold; i++)
        {
          sequential_path_cv<T1, T2, T3, T4>(data, sigma, algorithm, metric, sequence, lambda_seq, early_stop, i, result_list[i]);
        }
      }
    }
    else
    {
      sequential_path_cv<T1, T2, T3, T4>(data, sigma, algorithm, metric, sequence, lambda_seq, early_stop, -1, result);
    }
  }
  else
  {
    // if (algorithm_type == 5 || algorithm_type == 3)
    // {
    //     double log_lambda_min = log(max(lambda_min, 1e-5));
    //     double log_lambda_max = log(max(lambda_max, 1e-5));

    //     result = pgs_path(data, algorithm, metric, s_min, s_max, log_lambda_min, log_lambda_max, powell_path, nlambda);
    // }
    gs_path(data, algorithm, algorithm_list, metric, s_min, s_max, sequence, lambda_seq, K_max, epsilon, is_parallel, result);
  }

#ifdef TEST
  t2 = clock();
  std::cout << "path time : " << ((double)(t2 - t1) / CLOCKS_PER_SEC) << endl;
#endif

  // Get bestmodel index && fit bestmodel
  int min_loss_index_row = 0, min_loss_index_col = 0, s_size = sequence.size(), lambda_size = lambda_seq.size();
  Eigen::Matrix<T2, Dynamic, Dynamic> beta_matrix(s_size, lambda_size);
  Eigen::Matrix<T3, Dynamic, Dynamic> coef0_matrix(s_size, lambda_size);
  Eigen::Matrix<VectorXd, Dynamic, Dynamic> bd_matrix(s_size, lambda_size);
  Eigen::MatrixXd ic_matrix(s_size, lambda_size);
  Eigen::MatrixXd test_loss_sum = Eigen::MatrixXd::Zero(s_size, lambda_size);
  Eigen::MatrixXd train_loss_matrix(s_size, lambda_size);

  if (path_type == 1)
  {
    if (is_cv)
    {
      Eigen::MatrixXd test_loss_tmp;
      for (int i = 0; i < Kfold; i++)
      {
        test_loss_tmp = result_list[i].test_loss_matrix;
        test_loss_sum = test_loss_sum + test_loss_tmp / Kfold;
      }
      test_loss_sum.minCoeff(&min_loss_index_row, &min_loss_index_col);

      Eigen::Matrix<T4, -1, -1> full_group_XTX = group_XTX(data.x, data.g_index, data.g_size, data.n, data.p, data.g_num, model_type);

      Eigen::MatrixXd covariance;
      T1 XTy;
      T1 XTone;
      if (covariance_update)
      {
        XTy = data.x.transpose() * data.y;
        XTone = data.x.transpose() * Eigen::MatrixXd::Ones(data.n, data.M);
      }

      if (is_parallel)
      {
        // cout << "cv parallel" << endl;
        for (int i = 0; i < max(Kfold, thread); i++)
        {
          if (covariance_update)
          {
            algorithm_list[i]->covariance_update_flag = Eigen::VectorXi::Zero(data.p);
            algorithm_list[i]->XTy = XTy;
            algorithm_list[i]->XTone = XTone;
          }

          algorithm_list[i]->update_group_XTX(full_group_XTX);
          algorithm_list[i]->PhiG = Eigen::Matrix<Eigen::MatrixXd, -1, -1>(0, 0);
        }
#pragma omp parallel for
        for (int i = 0; i < sequence.size() * lambda_seq.size(); i++)
        {
          int s_index = i / lambda_seq.size();
          int lambda_index = i % lambda_seq.size();
          int algorithm_index = omp_get_thread_num();

          T2 beta_init;
          T3 coef0_init;
          coef_set_zero(data.p, M, beta_init, coef0_init);
          Eigen::VectorXd bd_init = Eigen::VectorXd::Zero(data.p);

          for (int j = 0; j < Kfold; j++)
          {
            beta_init = beta_init + result_list[j].beta_matrix(s_index, lambda_index) / Kfold;
            coef0_init = coef0_init + result_list[j].coef0_matrix(s_index, lambda_index) / Kfold;
            bd_init = bd_init + result_list[j].bd_matrix(s_index, lambda_index) / Kfold;
          }

          algorithm_list[algorithm_index]->update_sparsity_level(sequence(s_index));
          algorithm_list[algorithm_index]->update_lambda_level(lambda_seq(lambda_index));
          algorithm_list[algorithm_index]->update_beta_init(beta_init);
          algorithm_list[algorithm_index]->update_coef0_init(coef0_init);
          algorithm_list[algorithm_index]->update_bd_init(bd_init);

          algorithm_list[algorithm_index]->fit(data.x, data.y, data.weight, data.g_index, data.g_size, data.n, data.p, data.g_num, data.status, sigma);

          beta_matrix(s_index, lambda_index) = algorithm_list[algorithm_index]->get_beta();
          coef0_matrix(s_index, lambda_index) = algorithm_list[algorithm_index]->get_coef0();
          train_loss_matrix(s_index, lambda_index) = algorithm_list[algorithm_index]->get_train_loss();
          ic_matrix(s_index, lambda_index) = metric->ic(data.n, data.M, data.g_num, algorithm_list[algorithm_index]);
        }
#ifdef TEST
        std::cout << "parallel cv 2 end--------" << std::endl;
#endif
      }
      else
      {
        if (covariance_update)
        {
          algorithm->covariance_update_flag = Eigen::VectorXi::Zero(data.p);
          algorithm->XTy = XTy;
          algorithm->XTone = XTone;
        }

        algorithm->update_group_XTX(full_group_XTX);

        algorithm->PhiG = Eigen::Matrix<Eigen::MatrixXd, -1, -1>(0, 0);
        for (int i = 0; i < sequence.size() * lambda_seq.size(); i++)
        {
          int s_index = i / lambda_seq.size();
          int lambda_index = i % lambda_seq.size();

          T2 beta_init;
          T3 coef0_init;
          coef_set_zero(data.p, M, beta_init, coef0_init);
          Eigen::VectorXd bd_init = Eigen::VectorXd::Zero(data.p);

          for (int j = 0; j < Kfold; j++)
          {
            beta_init = beta_init + result_list[j].beta_matrix(s_index, lambda_index) / Kfold;
            coef0_init = coef0_init + result_list[j].coef0_matrix(s_index, lambda_index) / Kfold;
            bd_init = bd_init + result_list[j].bd_matrix(s_index, lambda_index) / Kfold;
          }

          algorithm->update_sparsity_level(sequence(s_index));
          algorithm->update_lambda_level(lambda_seq(lambda_index));
          algorithm->update_beta_init(beta_init);
          algorithm->update_coef0_init(coef0_init);
          algorithm->update_bd_init(bd_init);

          algorithm->fit(data.x, data.y, data.weight, data.g_index, data.g_size, data.n, data.p, data.g_num, data.status, sigma);

          beta_matrix(s_index, lambda_index) = algorithm->get_beta();
          coef0_matrix(s_index, lambda_index) = algorithm->get_coef0();
          train_loss_matrix(s_index, lambda_index) = algorithm->get_train_loss();
          ic_matrix(s_index, lambda_index) = metric->ic(data.n, data.M, data.g_num, algorithm);
        }
      }
#ifdef TEST
      cout << "test_loss: " << test_loss_sum << endl;
#endif
    }
    else
    {
      beta_matrix = result.beta_matrix;
      coef0_matrix = result.coef0_matrix;
      ic_matrix = result.ic_matrix;
      train_loss_matrix = result.train_loss_matrix;
      ic_matrix.minCoeff(&min_loss_index_row, &min_loss_index_col);
#ifdef TEST
      std::cout << "train_loss: " << std::endl;
      std::cout << train_loss_matrix << std::endl;
      std::cout << "ic: " << std::endl;
      std::cout << ic_matrix << std::endl;
#endif
    }
  }
  else
  {
    beta_matrix = result.beta_matrix;
    coef0_matrix = result.coef0_matrix;
    ic_matrix = result.ic_matrix;
    train_loss_matrix = result.train_loss_matrix;
    Eigen::MatrixXd test_loss_matrix = result.test_loss_matrix;
    if (is_cv)
    {
      test_loss_matrix.minCoeff(&min_loss_index_row, &min_loss_index_col);
    }
    else
    {
      ic_matrix.minCoeff(&min_loss_index_row, &min_loss_index_col);
    }

#ifdef TEST
    std::cout << "test_loss: " << std::endl;
    std::cout << test_loss_matrix << std::endl;
    std::cout << "train_loss: " << std::endl;
    std::cout << train_loss_matrix << std::endl;
    std::cout << "ic: " << std::endl;
    std::cout << ic_matrix << std::endl;
#endif
  }

#ifdef TEST
  std::cout << "abesscpp 3 end --------" << std::endl;
#endif
  // fit best model
  // int best_s = sequence(min_loss_index_row);
  double best_lambda = lambda_seq(min_loss_index_col);

  T2 best_beta;
  T3 best_coef0;
  double best_train_loss, best_ic, best_test_loss;

  best_beta = beta_matrix(min_loss_index_row, min_loss_index_col);
  best_coef0 = coef0_matrix(min_loss_index_row, min_loss_index_col);
  best_train_loss = train_loss_matrix(min_loss_index_row, min_loss_index_col);
  best_ic = ic_matrix(min_loss_index_row, min_loss_index_col);
  best_test_loss = test_loss_sum(min_loss_index_row, min_loss_index_col);

  //////////////Restore best_fit_result for normal//////////////
  // to do
  if (data.is_normal && !sparse_matrix)
  {
    if (data.data_type == 1)
    {
      array_quotient(best_beta, data.x_norm, 1);
      best_beta = best_beta * sqrt(double(data.n));
      best_coef0 = data.y_mean - matrix_dot(best_beta, data.x_mean);
    }
    else if (data.data_type == 2)
    {
      array_quotient(best_beta, data.x_norm, 1);
      best_beta = best_beta * sqrt(double(data.n));
      best_coef0 = best_coef0 - matrix_dot(best_beta, data.x_mean);
    }
    else
    {
      array_quotient(best_beta, data.x_norm, 1);
      best_beta = best_beta * sqrt(double(data.n));
    }
  }

  ////////////// Restore all_fit_result for normal ////////////////////////
  // to do
  if (data.is_normal && !sparse_matrix)
  {
    if (data.data_type == 1)
    {
      for (int j = 0; j < beta_matrix.cols(); j++)
      {
        for (int i = 0; i < beta_matrix.rows(); i++)
        {
          array_quotient(beta_matrix(i, j), data.x_norm, 1);
          beta_matrix(i, j) = beta_matrix(i, j) * sqrt(double(data.n));
          coef0_matrix(i, j) = data.y_mean - matrix_dot(beta_matrix(i, j), data.x_mean);
        }
      }
    }
    else if (data.data_type == 2)
    {
      for (int j = 0; j < beta_matrix.cols(); j++)
      {
        for (int i = 0; i < beta_matrix.rows(); i++)
        {
          array_quotient(beta_matrix(i, j), data.x_norm, 1);
          beta_matrix(i, j) = beta_matrix(i, j) * sqrt(double(data.n));
          coef0_matrix(i, j) = coef0_matrix(i, j) - matrix_dot(beta_matrix(i, j), data.x_mean);
        }
      }
    }
    else
    {
      for (int j = 0; j < beta_matrix.cols(); j++)
      {
        for (int i = 0; i < beta_matrix.rows(); i++)
        {
          array_quotient(beta_matrix(i, j), data.x_norm, 1);
          beta_matrix(i, j) = beta_matrix(i, j) * sqrt(double(data.n));
        }
      }
    }
  }
  // cout << "abess 7" << endl;

  // List result;
  List out_result;
#ifdef R_BUILD
  out_result = List::create(Named("beta") = best_beta,
                            Named("coef0") = best_coef0,
                            Named("train_loss") = best_train_loss,
                            Named("ic") = best_ic,
                            Named("lambda") = best_lambda,
                            Named("beta_all") = beta_matrix,
                            Named("coef0_all") = coef0_matrix,
                            Named("train_loss_all") = train_loss_matrix,
                            Named("ic_all") = ic_matrix,
                            Named("test_loss_all") = test_loss_sum);
#else
  out_result.add("beta", best_beta);
  out_result.add("coef0", best_coef0);
  out_result.add("train_loss", best_train_loss);
  out_result.add("test_loss", best_test_loss);
  out_result.add("ic", best_ic);
  out_result.add("lambda", best_lambda);
  // out_result.add("beta_all", beta_matrix);
  // out_result.add("coef0_all", coef0_matrix);
  // out_result.add("train_loss_all", train_loss_matrix);
  // out_result.add("ic_all", ic_matrix);
  // out_result.add("test_loss_all", test_loss_sum);
#endif

  // Restore best_fit_result for screening
  if (is_screening)
  {
#ifdef TEST
    cout << "screening_A: " << screening_A << endl;
    cout << "p: " << x.cols() << endl;
#endif
    T2 beta_screening_A;
    T2 beta;
    T3 coef0;
    coef_set_zero(x.cols(), M, beta, coef0);

#ifndef R_BUILD
    out_result.get_value_by_name("beta", beta_screening_A);
    slice_restore(beta_screening_A, screening_A, beta);
    out_result.add("beta", beta);
    out_result.add("screening_A", screening_A);
#else
    beta_screening_A = out_result["beta"];
    slice_restore(beta_screening_A, screening_A, beta);
    out_result["beta"] = beta;
    out_result.push_back(screening_A, "screening_A");
#endif
  }

  delete metric;
  return out_result;
}

#ifndef R_BUILD

void pywrap_abess(double *x, int x_row, int x_col, double *y, int y_row, int y_col, int n, int p, int data_type, double *weight, int weight_len, double *sigma, int sigma_row, int sigma_col,
                  bool is_normal,
                  int algorithm_type, int model_type, int max_iter, int exchange_num,
                  int path_type, bool is_warm_start,
                  int ic_type, double ic_coef, bool is_cv, int Kfold,
                  int *gindex, int gindex_len,
                  int *status, int status_len,
                  int *sequence, int sequence_len,
                  double *lambda_sequence, int lambda_sequence_len,
                  int s_min, int s_max, int K_max, double epsilon,
                  double lambda_min, double lambda_max, int n_lambda,
                  bool is_screening, int screening_size, int powell_path,
                  int *always_select, int always_select_len, double tau,
                  int primary_model_fit_max_iter, double primary_model_fit_epsilon,
                  bool early_stop, bool approximate_Newton,
                  int thread,
                  bool covariance_update,
                  bool sparse_matrix,
                  int splicing_type,
                  double *beta_out, int beta_out_len, double *coef0_out, int coef0_out_len, double *train_loss_out,
                  int train_loss_out_len, double *ic_out, int ic_out_len, double *nullloss_out, double *aic_out,
                  int aic_out_len, double *bic_out, int bic_out_len, double *gic_out, int gic_out_len, int *A_out,
                  int A_out_len, int *l_out)
{
  Eigen::MatrixXd x_Mat;
  Eigen::MatrixXd y_Mat;
  Eigen::MatrixXd sigma_Mat;
  Eigen::VectorXd weight_Vec;
  Eigen::VectorXi gindex_Vec;
  Eigen::VectorXi status_Vec;
  Eigen::VectorXi sequence_Vec;
  Eigen::VectorXd lambda_sequence_Vec;
  Eigen::VectorXi always_select_Vec;

#ifdef TEST
  clock_t t1, t2;
#endif
  // t1 = clock();
  x_Mat = Pointer2MatrixXd(x, x_row, x_col);
  y_Mat = Pointer2MatrixXd(y, y_row, y_col);
  sigma_Mat = Pointer2MatrixXd(sigma, sigma_row, sigma_col);
  weight_Vec = Pointer2VectorXd(weight, weight_len);
  status_Vec = Pointer2VectorXi(status, status_len);
  gindex_Vec = Pointer2VectorXi(gindex, gindex_len);
  sequence_Vec = Pointer2VectorXi(sequence, sequence_len);
  lambda_sequence_Vec = Pointer2VectorXd(lambda_sequence, lambda_sequence_len);
  always_select_Vec = Pointer2VectorXi(always_select, always_select_len);
  // t2 = clock();
  // std::cout << "pointer to data: " << ((double)(t2 - t1) / CLOCKS_PER_SEC) << endl;
#ifdef TEST
  t1 = clock();
#endif
  List mylist = abessCpp2(x_Mat, y_Mat, n, p, data_type, weight_Vec, sigma_Mat,
                          is_normal,
                          algorithm_type, model_type, max_iter, exchange_num,
                          path_type, is_warm_start,
                          ic_type, ic_coef, is_cv, Kfold,
                          status_Vec,
                          sequence_Vec,
                          lambda_sequence_Vec,
                          s_min, s_max, K_max, epsilon,
                          lambda_min, lambda_max, n_lambda,
                          is_screening, screening_size, powell_path,
                          gindex_Vec,
                          always_select_Vec, tau,
                          primary_model_fit_max_iter, primary_model_fit_epsilon,
                          early_stop, approximate_Newton,
                          thread,
                          covariance_update,
                          sparse_matrix,
                          splicing_type);

#ifdef TEST
  t2 = clock();
  std::cout << "get result : " << ((double)(t2 - t1) / CLOCKS_PER_SEC) << endl;
#endif

  // t1 = clock();
  if (y_col == 1)
  {
    Eigen::VectorXd beta;
    double coef0 = 0;
    double train_loss = 0;
    double ic = 0;
    mylist.get_value_by_name("beta", beta);
    mylist.get_value_by_name("coef0", coef0);
    mylist.get_value_by_name("train_loss", train_loss);
    mylist.get_value_by_name("ic", ic);

    VectorXd2Pointer(beta, beta_out);
    *coef0_out = coef0;
    *train_loss_out = train_loss;
    *ic_out = ic;
  }
  else
  {
    Eigen::MatrixXd beta;
    Eigen::VectorXd coef0;
    double train_loss = 0;
    double ic = 0;
    mylist.get_value_by_name("beta", beta);
    mylist.get_value_by_name("coef0", coef0);
    mylist.get_value_by_name("train_loss", train_loss);
    mylist.get_value_by_name("ic", ic);
    // cout << "beta" << endl;
    // cout << beta << endl;
    // cout << "coef0" << endl;
    // cout << coef0 << endl;
    // cout << "train_loss" << endl;
    // cout << train_loss << endl;
    // cout << "ic" << endl;
    // cout << ic << endl;

    MatrixXd2Pointer(beta, beta_out);
    VectorXd2Pointer(coef0, coef0_out);
    train_loss_out[0] = train_loss;
    ic_out[0] = ic;
  }

  // t2 = clock();
  // std::cout << "result to pointer: " << ((double)(t2 - t1) / CLOCKS_PER_SEC) << endl;
}
#endif
