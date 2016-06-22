-- usage:
-- $BUILD_URL is set by jenkins
-- mysql -u smartuser -ppassword -P 3520 -h esekilx0007-sql8.rnd.ki.sw.ericsson.se -e "set @build_url='${BUILD_URL}'; source load_selected_tests.sql ;"


USE smarttestdb;

LOAD DATA LOCAL INFILE 'selected_test_count.csv'
INTO TABLE tests_selected
COLUMNS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES -- ignore header
(testrun_id, git_commit, total_count, selected_count, total_minutes, selected_minutes, savings_minutes)
SET 
time_added_epoch =unix_timestamp(now()),
build_url = @build_url
;

