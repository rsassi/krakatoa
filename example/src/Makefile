
GCC=g++
GCCOPTS=-c -fprofile-arcs -ftest-coverage -Iinc


#disable built-in rules:
.SUFFIXES:


bin/%.o: dir1/%.cc
	make -p bin
	$(GCC) -c $(GCCOPTS) $^ -o $@

bin/%.o: dir2/%.cc
	make -p bin
	$(GCC) -c $(GCCOPTS) $^ -o $@

testapp: bin bin/test1.o bin/test2.o	
	$(GCC) -O -ftest-coverage -g -o $@ bin/test1.o bin/test2.o -lstdc++ -lgcov

bin:
	mkdir -p bin

.PHONY: testa
testa: testapp
	./testapp AAA AAA > $@.log
    
.PHONY: testb
testb: testapp
	./testapp XYZ > $@.log

.PHONY: testc
testc: testapp
	./testapp CCC DDD  > $@.log

.PHONY: clean
clean: 
	rm -rf testapp testapp.exe
	rm -rf bin
	find . -type f -name "*.o" -delete
	find . -type f -name "*.gcda" -delete
	find . -type f -name "*.gcno" -delete
	find . -type f -name "*.gcov" -delete
	find . -type f -name "*.log" -delete

