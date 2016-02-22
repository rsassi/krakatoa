
main class: DirectoryCoverageHtmlReport


Updates all null directory_cov_html column in testruns table.

-------------------
How to use:

5 parameters:
		report.dbhost = "localhost";
		report.dbport = "3306";
		report.dbname = "smarttestdb";
		report.dbuser = "root";
		report.dbpassword = "toto";

Also expects the following files to be located in the current working directory:
 srcdir.txt
 collapsing_list.prologue.html 
 collapsing_list.epilogue.html

Output:
 directoryFuncCov.csv
 function_coverage.html
 
To generate srcdir.txt do this:
cd radiosw/sw/app
find . -name src | grep -v unitTest | sed -E 's/\/src//g' | sort > ~/srcdir.txt


To build:
  cd smarttest/DirectoryRollup
  ./build.sh
  git commit -a
  git push origin HEAD:refs/for/master

To deploy:
  The Jenkins job always pickups up the latest from master before each SmartTest run.


To invoke:

java -jar perdircoverage-0.0.1-SNAPSHOT-jar-with-dependencies.jar localhost 3306 smarttestdb root toto 
