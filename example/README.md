
This simple example shows how the data is generated and processed into CSV files.
In this example we have three tests. One test per executable.

Error handling is minimal so examine the output carefully for errors.


#Each step:
##1_clean.sh
 Removes all files created by running the following scripts.

##2_gen_gcda.sh
 Compile a little test program and execute 3 times each time generating gcov .gcda files.

##3_gen_gcov.sh
 Process .gcda files from each test and generate .gcov files.

##4_gen_test_summary.sh
 Create tests_summary.yaml (needed by 6_gen_csv.sh)

##5_gen_function_map.sh
 Create function_map.csv (needed by 6_gen_csv.sh)

##6_gen_csv.sh
 Create .csv using gcov2CovDB.jar

##7_load_mysql.sh
This step has been commented out since it requires DB information. 
However it should only have to be modified with the missing information to succeed.
The DB has to be created using the script ../mysql/create.sql
Output is stored in results/


##run ./all.sh to execute all the steps.


# Generating per test gcda files
##1) testing framework hooks to generate per test coverage

First you need to build your software using the following gcc options:
  -fprofile-arcs -ftest-coverage

Definition: test mangled name= the name of the test in a format that is compatible with a file name on your system. e.g. "TC #1 verify computation of x'." could have a mangled_name like this: "TC_#1_verify_computation_of_x_."

Multiple scenarios depending on your test setup:
###a) One test per executable. gcda written directly from executable.
After executing each test executable, mv the directory containing the gcda data to a directory named after the name of the test.

###b) Multiple tests per executable. gcda written directly from executable.
In order to capture per test data you will need to add hooks to your testing framework as follow:
Before each test: Clear the gcov data
    This is not mandatory but helps generate accurate coverage data
    For example, if there is no application code executed between tests then this step is redundant.
    This requires customizing the gcov library with a new function like this:
    gcov-client.c
    // clears any data accumulated up to this point
    void __gcov_clear(void)
    {
        struct gcov_info *info;
        for (info = gcov_list; info; info = info->next)
        {
            gcov_zero_counts(info);
        }
    }

After each test: dump the gcda data
  Call __gcov_flush()  (from the gcov lib declared in gcov-io.h)
  Call gcov_helper.sh (see usage)

###c) Multiple tests per executable. No file system available.
This is the same as #b but the gcov library has to be modfified to  save to data remotely.
radiosw in in this situation and we have modified gcov.
We also added commands to clear and dump the coverage data over ose xplink.
radiosw/sw/gcov/osegcov/

Input:
- gcov instrumented executable
Output:
- .gcov files

Dependencies:
- gcc
- gcov
- custom gcov (for #c)
- mangled test name strategy
- gcov_helper.sh


#Generating per test gcov files
By running postprocess_with_gcov.sh we invoke gcov on each of the test directory.
This generates .gcov files by invoking gcov like this:
  gcov --object-directory "${BINDIR}" -b -p *.cc
This is done by running postprocess_with_gcov.sh.

Then execute gcov2covDB.jar to produce a set of CSV files.
These files can then be loaded in MySQL.
Also produces an html file containing a collapsable per directory coverage report.

Input:
- Function coverage for each test (.gcov). Each set stored in a separate directory using the test mangled name as directory name.
- mira_summary.yaml
- function_map.csv
- fun_filter.yaml

Dependencies:
- nm  (used to generate function_map.csv)
- Ruby
- Java
- gcov2covDB.jar




