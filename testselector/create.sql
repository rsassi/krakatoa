
use smarttestdb;

CREATE TABLE `testselector_usage` (
  `user` varchar(128) NOT NULL DEFAULT '',
  `host` varchar(128) NOT NULL DEFAULT '',
  `list_count` int(11) DEFAULT NULL,
  `commit_count` int(11) DEFAULT NULL,
  `function_count` int(11) DEFAULT NULL,
  `file_count` int(11) DEFAULT NULL,
  `first_visit_epoch` int(11) DEFAULT NULL,
  `last_visit_epoch` int(11) DEFAULT NULL,
  PRIMARY KEY (`user`, `host`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS tests_selected (
    id INT NOT NULL AUTO_INCREMENT,
    testrun_id INT,
    git_commit varchar(40), -- git hash of commit under test
    time_added_epoch  INT,
    total_count INT, 
    selected_count INT, 
    total_minutes INT, 
    selected_minutes INT, 
    savings_minutes INT, 
    build_url LONGTEXT, 
    PRIMARY KEY(id),
    FOREIGN KEY(testrun_id) REFERENCES testruns(id)
) ENGINE=INNODB;

