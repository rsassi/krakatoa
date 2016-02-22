USE smarttest;

-- test the CASCADE deletion when testruns are deleted: (all tables expected to be empty)
DELETE FROM testruns ;
SELECT count(*) AS test_count FROM tests;
SELECT count(*) AS file_count FROM source_files;
SELECT count(*) AS functions_count FROM functions;
SELECT count(*) AS func_cov_count FROM funccov;

