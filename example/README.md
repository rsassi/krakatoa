
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






