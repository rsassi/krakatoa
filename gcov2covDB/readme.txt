
This Java application replaces the scripts in the gcov_test2func git repo initially used to parse gcov data and generate CSV files that can then be imported 
into a database.

WHAT IS IT FOR:
---------------
The purpose of this program is to traverse a directory structure, parse gcov files it encounters and generate four '.csv' files:
	- 'tests.csv'         one row per test.
	- 'source_files.csv'  one row per source file
	- 'functions.csv'     one row per function
	- 'funccov.csv'       one row per function coverage statement (one row for each function for each test)
All IDs are allocated by the application and are only unique within the execution of the java program.
Then the csv can be loaded into MySQL tables using the scripts found in the mysql/ directory.

HOW IT IS CALLED:
-----------------
This application requires 4 arguments:
	- the root directory where the gcov files are located
	- a yaml file that has a mapping from test mangled to demangled names
	- a csv file that has a mapping from function mangled to demangled names
	- a yaml file containing a list of regular expressions to match functions that should not be included in the outputted '.csv' files

To run the application from the gcov2covDB directory, execute the following command (with parameters):

java -jar target/gcov2cov-0.0.1-SNAPSHOT-jar-dependencies.jar <root_directory> <tests_demangling_yaml> <function_demangling_csv> <regex_function_filter_yaml>

HOW IT IS BUILT AND DEPLOYED:
-----------------------------
  
1) Build 
  cd smarttest/gcov2covDB
  ./buils.sh
  git commit -a
  git push origin HEAD:refs/for/master

2) Deploy
  Just merge your changes into master. The Jenkins job will always pickup the latest changes before each SmartTest run.


# on target:
module add

java -jar /home/eseprud/share/gcov2covDB/gcov2covDB.jar /local/scratch/eswradio/radio_SmartTest_00/gcov/ gcov_results/mira_summary.yaml gcov_results/function_map.csv /home/eseprud/share/gcov2covDB/func_filter.yaml

# to test on sample data: 
java -jar gcov2covDB.jar tests mira_summary.yaml function_map.csv func_filter.yaml

