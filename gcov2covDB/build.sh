rm -rf target/*
mvn clean compile assembly:single
cp target/gcov2covDB-0.0.1-SNAPSHOT-jar-with-dependencies.jar gcov2covDB.jar


