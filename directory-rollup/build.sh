rm -rf target/*
mvn clean compile assembly:single
cp target/perdircoverage-0.0.1-SNAPSHOT-jar-with-dependencies.jar perdircoverage.jar
