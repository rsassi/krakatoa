# krakatoa
Test selection and other reports using code coverage data.
<br/>

For large testsuites it often becomes impossible to run all the tests on each code change.
<br/>
Although the only supported source of coverage data is gcov, this approach and tool set can be integrated with any system that can generate function coverage.
<br/>
This system was originally aimed at C++ applications but can be used with any language and testing framwork.
<br/>
This tool leverages per test function coverage data to determine which tests should be updated and executed for a given change set.
<br/>
The rule used to select tests is very simple and conservative:
* select all tests that call at least one function in one of the modified files in the specified git changeset.
<br/>

Another alternative is to use this:
* select all tests that call a certain list of functions



# This project includes
* A MySQL schema to store function coverage effciently
* An example on how per test coverage data can be generated with gcov and loaded into MySQL
* A gcov2covDB.jar with source to convert .gcov files into .csv files that can be loaded into MySQL
* A testselector script to select a subset of tests based on coverage and either a function name or files modified in a git commit.


