
use smarttestdb;

CREATE TABLE `testselector_usage` (
  `user` varchar(128) NOT NULL DEFAULT '',
  `host` varchar(128) NOT NULL DEFAULT '',
  `list_count` int(11) DEFAULT NULL,
  `commit_count` int(11) DEFAULT NULL,
  `function_count` int(11) DEFAULT NULL,
  `first_visit_epoch` int(11) DEFAULT NULL,
  `last_visit_epoch` int(11) DEFAULT NULL,
  PRIMARY KEY (`user`, `host`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

