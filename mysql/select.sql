USE smarttestdb;

-- ----------------------------------------------------------------------
SELECT * FROM testruns;
SELECT * FROM tests;
SELECT * FROM source_files;
SELECT * FROM functions;
SELECT * FROM funccov;

SELECT 
testruns.id,  FROM_UNIXTIME(testruns.time_added_epoch) as time_added, testruns.test_results_id test_results_id, testruns.framework as framework, testruns.git_commit as git_commit,  
tests.name as test, tests.mangled_name as test_mangled, 
source_files.name as source_file, 
functions.source_line as source_line, functions.name as function, functions.mangled_name as func_mangled, 
funccov.visited
FROM 
testruns 
INNER JOIN tests ON testruns.id = tests.testrun_id 
INNER JOIN source_files ON source_files.testrun_id = testruns.id
INNER JOIN functions ON functions.testrun_id  = testruns.id and functions.source_file_id = source_files.id
INNER JOIN funccov ON funccov.testrun_id = testruns.id and funccov.test_id = tests.id and funccov.function_id = functions.id
WHERE testruns.id =1
;

