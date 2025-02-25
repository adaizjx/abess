Welcome to abess's documentation!
==========================================================================

.. raw:: html

   <!-- badges: start -->

|Codacy| |Travis build status| |codecov| |docs| |cran| |pypi| |pyversions| |License|

**abess** (Adaptive BEst Subset Selection) aims to find a small subset of predictors such
that the resulting linear model is expected to have the most desirable
prediction accuracy. This project implements a polynomial algorithm proposed to solve these problems. It supports:

-  various model:
-  linear regression
-  classification (binary or multi-class)
-  counting-response modeling
-  censored-response modeling
-  multi-response modeling (multi-tasks learning)
-  sure independence screening
-  nuisance penalized regression

Quick Start
============

- R 

- Python

You can install the newest version of abess from
`pypi <https://pypi.org>`__ with:

.. code-block:: console

    $pip install abess

Import abess in a Python project:

.. code-block:: console

    import abess

Reference
=========

| Junxian Zhu, Canhong Wen, Jin Zhu, Heping Zhang, and Xueqin Wang. A polynomial algorithm for best-subset selection problem. Proceedings of the National Academy of Sciences, 117(52):33117-33123, 2020.

| Fan, J. and Lv, J. (2008), Sure independence screening for ultrahigh dimensional feature space. Journal of the Royal Statistical Society: Series B (Statistical Methodology), 70: 849-911. https://doi.org/10.1111/j.1467-9868.2008.00674.x

| Qiang Sun & Heping Zhang (2020) Targeted Inference Involving High-Dimensional Data Using Nuisance Penalized Regression, Journal of the American Statistical Association, DOI: 10.1080/01621459.2020.1737079


.. |Codacy| image:: https://app.codacy.com/project/badge/Grade/3f6e60a3a3e44699a033159633981b76 
   :target: https://www.codacy.com/gh/abess-team/abess/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=abess-team/abess&amp;utm_campaign=Badge_Grade
.. |Travis build status| image:: https://travis-ci.com/abess-team/abess.svg?branch=master
   :target: https://travis-ci.com/abess-team/abess
.. |codecov| image:: https://codecov.io/gh/abess-team/abess/branch/master/graph/badge.svg?token=LK56LHXV00
   :target: https://codecov.io/gh/abess-team/abess
.. |docs| image:: https://readthedocs.org/projects/abess/badge/?version=latest
   :target: https://abess.readthedocs.io/en/latest/?badge=latest
   :alt: Documentation Status
.. |cran| image:: https://img.shields.io/cran/v/abess?logo=R
   :target: https://cran.r-project.org/package=abess
.. |pypi| image:: https://badge.fury.io/py/abess.svg
   :target: https://badge.fury.io/py/abess
.. |pyversions| image:: https://img.shields.io/pypi/pyversions/abess
.. |License| image:: https://img.shields.io/badge/License-GPL%20v3-blue.svg 
   :target: http://www.gnu.org/licenses/gpl-3.0

    
