package gcov2covDB;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Vector;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.esotericsoftware.yamlbeans.YamlException;
import com.esotericsoftware.yamlbeans.YamlReader;
import com.opencsv.CSVWriter;

public class Gcov2FuncCoverageDB {
	private static final boolean verbose = false;
	private static final String TESTS_CSV = "tests.csv";
	private static final String TEST_GROUPS_CSV = "test_groups.csv";
	private static final String SOURCE_FILES_CSV = "source_files.csv";
	private static final String FUNCTIONS_CSV = "functions.csv";
	private static final String FUNCCOV_CSV = "funccov.csv";
	private static final String NEW_LINE_DELIMITER = "\n";

	Vector<Pattern> m_regex_func_patterns			  = new Vector<Pattern>();
	Map<String, Integer> m_source_files_map			  = new HashMap<String, Integer>();
	Map<String, FunctionsTableEntry> m_functions_map  = new HashMap<String, FunctionsTableEntry>();
	Map<String, String> m_mangled_func_map			  = new HashMap<String, String>();
	Map<String, Integer> m_test_mangled_to_id_map     = new HashMap<String, Integer>();
	Map<String, TestTableEntry> m_tests_map           = new HashMap<String, TestTableEntry>();
	Map<Integer, String> m_test_group_names_map       = new HashMap<Integer, String>();
	Pattern m_func_pattern = Pattern
			.compile("^function\\s+(.*?)\\s+called\\s+(\\d+)\\s+returned\\s+(\\d+)%\\s+blocks\\s+executed\\s+(\\d+)%");
	Pattern m_file_pattern = Pattern.compile("\\.cc\\.gcov$");

	int m_func_map_next_index = 1;
	int m_source_files_map_next_index =1 ;
	/*
	 * tests mira_summary.yaml function_map.csv func_filter.yaml
	 */
	public static void main(String[] args) {
		String testDataDirectory    = null;
		String mangled_tests_file = null;
		String mangled_func_file    = null;
		String filter_file		= null;
		if (args.length == 0 ) {
			System.err.println("No parameters passed. Running with default test values.");
			testDataDirectory    = "tests";
			mangled_tests_file = "mira_summary.yaml";
			mangled_func_file    = "function_map.csv";
			filter_file		= "func_filter.yaml";
		} else {
			if (args.length != 4) {
				System.err
						.println("usage: cmd testDataDirectory mangled_tests_file mangled_func_file filter_file");
				System.exit(1);
			}
			testDataDirectory = args[0];
			mangled_tests_file = args[1];
			mangled_func_file = args[2];
			filter_file = args[3];
		}
		System.out.println(" testDataDirectory("+testDataDirectory+"), mangled_tests_file("+mangled_tests_file+"), mangled_func_file("+mangled_func_file+"), filter_file("+filter_file+")");
		Gcov2FuncCoverageDB gcov2covDB = new Gcov2FuncCoverageDB(testDataDirectory, mangled_tests_file,
				mangled_func_file, filter_file);
		gcov2covDB.generateOtherCSVs();
	}

	public Gcov2FuncCoverageDB(
			String testDataDirectory,
			String mangled_tests_file, 
			String mangled_func_file,
			String filter_file){
		Vector<String> regexes = parseRegexYaml(filter_file);
		for (String regexp : regexes) {
			Pattern regex_func_pattern = Pattern.compile(regexp);
			m_regex_func_patterns.add(regex_func_pattern);
		}
		cleanCsvFiles();
		try {
			initMaps(testDataDirectory, mangled_tests_file, mangled_func_file);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	private void initMaps(String directory, String mangled_tests_file,
			String mangled_func_file)
			throws IOException {
		File folder = new File(directory);
		/* Table Column Headers */
		String test_mangled;
		/* File Reader variables */
		FileWriter funccovWriter = null;
		funccovWriter = new FileWriter(FUNCCOV_CSV);
		funccovWriter.append("test_id,function_id,visited");
		funccovWriter.append(NEW_LINE_DELIMITER);
		/* Fill the mangled-to-demangled test/function maps */
		parseTestInfoYaml(mangled_tests_file);
		parseFunctionMangledDemangledNameCsv(mangled_func_file);
		for (File subfolder : folder.listFiles()) {
			// Assumes directory name is test mangled name
			test_mangled = subfolder.getName();
			if (null == test_mangled){
				System.err.println("Could not get path for " + subfolder.toString());
				System.exit(1);
			}
			Integer tests_map_index = m_test_mangled_to_id_map.get(test_mangled);
			if (tests_map_index == null){
				System.err.println("Could not get test id for " + test_mangled);
				System.exit(1);
			}
			if (subfolder.isDirectory()) {
				/*
				 * Directory parser fills the other two hash maps and generates
				 * the funccov csv file
				 */
				processDirectoryAndSubdirectories(subfolder, tests_map_index,
						test_mangled, funccovWriter);
			}
		}
		funccovWriter.flush();
		funccovWriter.close();
		System.out.println(FUNCCOV_CSV + " created successfully.");
	}
	
	public void generateOtherCSVs() {
		generateTestGroupsCsv(TEST_GROUPS_CSV);
		generateTestsCsv(TESTS_CSV);
		generateSourceFilesCsv(SOURCE_FILES_CSV);
		generateFunctionsCsv(FUNCTIONS_CSV);
		System.out.print("\nDone!");
	}

	private void parseTestInfoYaml(String yamlFile) {
		try {
			int test_index = 0;
			int test_group_index = 0;
			YamlReader reader = new YamlReader(new FileReader(yamlFile));
			Object object = reader.read();
			ArrayList<Map> list = (ArrayList<Map>) object;
			ArrayList<Map> list_nested = null;
			for (int i = 0; i < list.size(); i++) {
				Object test_group_name = list.get(i).get("name");
				if ((null == test_group_name) ){
					System.err.println("No test group name for test group: Test #"+test_group_index+" in " + yamlFile);
					System.exit(1);
				}
				test_group_index++;
				m_test_group_names_map.put(test_group_index, test_group_name.toString());
				list_nested = (ArrayList<Map>) list.get(i).get("testcases");
				for (int j = 0; j < list_nested.size(); j++) {
					Object mangled_name = list_nested.get(j).get("mangled_name");
					Object name = list_nested.get(j).get("name");
					Object path = list_nested.get(j).get("path");
					Object execution_time_secs = list_nested.get(j).get("execution_time_secs");
					Object passed = list_nested.get(j).get("pass");
					Object failed = list_nested.get(j).get("fail");
					test_index++; // Unique Test ID for each entry.
					if ((null == mangled_name) || (null==name)|| (null==path)|| (null==execution_time_secs)|| (null==passed)|| (null==failed)){
						System.err.println("Test #"+test_index+", missing one of {mangled_name, name, path, execution_time_secs, pass, fail}  in " + yamlFile);
						System.exit(1);
					}
					TestTableEntry entry = new TestTableEntry(
							test_index,
							test_group_index,
							mangled_name.toString(),
							name.toString(), 
							path.toString(),
							execution_time_secs.toString(),
							passed.toString(),
							failed.toString()
							);
					m_tests_map.put(mangled_name.toString(), entry);
					m_test_mangled_to_id_map.put(mangled_name.toString(), test_index);
				}
			}
		} catch (FileNotFoundException e) {
			System.err.println("Error opening " + yamlFile);
			e.printStackTrace();
			System.exit(1);
		} catch (YamlException e) {
			System.err.println("Yaml Error encountered");
			e.printStackTrace();
			System.exit(1);
		}
	}

	/**
	 * 
	 * @param fileName
	 * @return vector of regular expression strings
 	 */
	private static Vector<String> parseRegexYaml(String fileName) {
		Vector<String> regexes = new Vector<String>();
		ArrayList<Map> list = null;
		HashMap<String, String> holder = null;

		try {
			YamlReader reader = new YamlReader(new FileReader(fileName));
			Object object = reader.read();
			list = (ArrayList<Map>) object;

			for (int i = 0; i < list.size(); i++) {
				holder = (HashMap<String, String>) list.get(i);
				String regexp = holder.get("regex");
				regexes.add(regexp);
				System.out.println("function name regexp("+regexp+")");
			}
		} catch (FileNotFoundException e) {
			System.err.println("Error opening " + fileName);
			System.exit(1);
		} catch (YamlException e) {
			System.err.println("Yaml Error encountered");
			System.exit(1);
		}

		return regexes;
	}

	private    void parseFunctionMangledDemangledNameCsv( String csvFile) {
		Integer count =0;
		Integer duplicateCount =0;
		try {// OpenCSV CSVReader doesn't handle large csv files and fails silently... Use BufferedReader instead.
			System.out.println("parsing:    " + csvFile );
			FileInputStream istream = new FileInputStream(csvFile);
			InputStreamReader iReader = new InputStreamReader(istream);
			BufferedReader buffReader = new BufferedReader(iReader);
			String line= null;
			while ((line = buffReader.readLine()) != null) {
				 	int secondQuotes =    line.indexOf('"', 1);
				 	String key = line.substring(1, secondQuotes);
				 	int thirdQuotes =    line.indexOf('"', secondQuotes+1); 
				 	String value = line.substring(thirdQuotes+1, line.length()-1); //-1 to exclude closing quotes
					String prevValue = m_mangled_func_map.put(key, value);
					//System.out.println("key("+key+")"+"value("+value+")" );
					if (null != prevValue){
						duplicateCount++;
					}
					count++;
			}
			buffReader.close();
		} catch (FileNotFoundException e) {
			System.err.println("Error opening " + csvFile);
			System.exit(1);
		} catch (IOException e) {
			System.err.println("Error parsing " + csvFile);
			System.exit(1);
		}
		System.out.println("parsed "+ count+ " lines from " + csvFile+ ", duplicate rows("+duplicateCount+")");
	}

	public void processDirectoryAndSubdirectories(File file,
			int test_id,
			String test_mangled, 
			FileWriter funccovWriter) throws IOException {
		if (file.isDirectory()) {
			for (File subfolder : file.listFiles()) {
				processDirectoryAndSubdirectories(subfolder,
						test_id,
						test_mangled, 
						funccovWriter);
			}
		} else /* if(file.isFile()) */{
			// normalize all file paths with "/" instead of "\" as a delimiter:
			String normalizedFileName = file.getPath().replaceAll("\\\\", "/");
			// ignore files that don't end with .cc.gcov:
			Matcher file_matcher = m_file_pattern.matcher(file.getAbsolutePath());
			if (file_matcher.find()) {
				Integer source_file_id = new Integer(0);
				// Remove .gcov suffix:
				String fullFileName = normalizedFileName.substring(0, normalizedFileName.lastIndexOf('.'));
				// Remove the prefix up to the mangled name (excluding the test name)
				String source_file = "."+fullFileName.substring(fullFileName.indexOf(test_mangled) + test_mangled.length());
				source_file_id = m_source_files_map.get(source_file);
				if (source_file_id == null){
					m_source_files_map.put(source_file, m_source_files_map_next_index);
					source_file_id = m_source_files_map_next_index;
					m_source_files_map_next_index++;
				}
				if (verbose){ System.err.println("Processing file("+ file.getPath() + "), source_file("+source_file+"), test_mangled("+test_mangled+"),");}
				BufferedReader inputStream = new BufferedReader(new FileReader(file));
				int source_line = 1;
				String line = null;
				while ((line = inputStream.readLine()) != null) {
					Matcher func_matcher = m_func_pattern.matcher(line);
					if (func_matcher.find()) {
						Integer visited = (Integer.parseInt(func_matcher.group(2))>0) ? 1: 0 ;
						String func_mangled = func_matcher.group(1);
						boolean ignoreFunc = false;
						for (Pattern regex_func_pattern: m_regex_func_patterns) {
							Matcher regex_func_matcher = regex_func_pattern.matcher(func_mangled);
							if (regex_func_matcher.find()) {
								ignoreFunc = true;
								break;
							}
						}
						if (!ignoreFunc) { 
							FunctionsTableEntry functionEntry =  m_functions_map.get(func_mangled);
							Integer function_id = null;
							if (null == functionEntry){
								String func_demangled = m_mangled_func_map
										.get(func_mangled);
								function_id = m_func_map_next_index;
								FunctionsTableEntry func_table_entry = new FunctionsTableEntry(function_id,
										source_file_id, source_line,
										func_mangled, func_demangled);
								m_functions_map.put(func_mangled, func_table_entry);
								m_func_map_next_index++;
							}else {
								function_id = functionEntry.id;
							}
							funccovWriter.append(test_id + "," + function_id + ","
									+ visited);
							funccovWriter.append(NEW_LINE_DELIMITER);
						}
					}
					source_line++;
				}
				inputStream.close();
			}else{
				if(verbose) {System.out.println("Ignoring file: " + file.getPath());}
			}
		}
	}

	public static void cleanCsvFiles() {
		File file = new File(TESTS_CSV);
		if (file.delete()) {
			System.out.println(file.getName() + " removed.");
		} 

		file = new File(SOURCE_FILES_CSV);
		if (file.delete()) {
			System.out.println(file.getName() + " removed.");
		} 
		
		file = new File(FUNCTIONS_CSV);
		if (file.delete()) {
			System.out.println(file.getName() + " removed.");
		} 
		file = new File(FUNCCOV_CSV);
		if (file.delete()) {
			System.out.println(file.getName() + " removed.");
		} 
	}

	public void generateTestsCsv(String fileName) {
		final String file_header = "id,group_id,mangled_name,name,path,execution_time_secs,passed,failed";
		CSVWriter writer = null;
		String[] record = file_header.split(",");
		try {
			writer = new CSVWriter(new FileWriter(fileName));
			writer.writeNext(record);
			for (Entry<String, TestTableEntry> entry : m_tests_map.entrySet()) {
				record[0] = entry.getValue().id.toString();
				record[1] = entry.getValue().group_id.toString();
				record[2] = entry.getValue().mangled_name;
				record[3] = entry.getValue().name;
				record[4] = entry.getValue().path;
				record[5] = entry.getValue().execution_time_secs;
				record[6] = entry.getValue().passed;
				record[7] = entry.getValue().failed;
				writer.writeNext(record);
			}
			System.out.println(fileName + " created successfully.");
		} catch (IOException e) {
			System.out.println("Error generating " + fileName);
			System.exit(1);
		} finally {
			try {
				writer.flush();
				writer.close();
			} catch (IOException e) {
				System.out.println("Error closing " + fileName);
				System.exit(1);
			}
		}
	}
	public void generateTestGroupsCsv(String fileName) {
		final String file_header = "id,name";
		CSVWriter writer = null;
		String[] record = file_header.split(",");
		try {
			writer = new CSVWriter(new FileWriter(fileName));
			writer.writeNext(record);
			for (Entry<Integer, String> entry : m_test_group_names_map.entrySet()) {
				record[0] = entry.getKey().toString();
				record[1] = entry.getValue();
				writer.writeNext(record);
			}
			System.out.println(fileName + " created successfully.");
		} catch (IOException e) {
			System.out.println("Error generating " + fileName);
			System.exit(1);
		} finally {
			try {
				writer.flush();
				writer.close();
			} catch (IOException e) {
				System.out.println("Error closing " + fileName);
				System.exit(1);
			}
		}
	}

	public void generateSourceFilesCsv(String fileName) {
		final String file_header = "id,name";
		CSVWriter writer = null;
		String[] record = file_header.split(",");
		try {
			writer = new CSVWriter(new FileWriter(fileName));
			writer.writeNext(record);
			for (Entry<String, Integer> entry : m_source_files_map.entrySet()) {
				record[0] = String.valueOf(entry.getValue());
				record[1] = entry.getKey();
				writer.writeNext(record);
			}
			System.out.println(fileName + " created successfully.");

		} catch (IOException e) {
			System.err.println("Error generating " + fileName);
			System.exit(1);
		} finally {
			try {
				writer.flush();
				writer.close();
			} catch (IOException e) {
				System.err.println("Error closing " + fileName);
				System.exit(1);
			}
		}
	}

	public void generateFunctionsCsv(String fileName) {
		final String file_header = "id,source_file_id,source_line,mangled_name,name";
		CSVWriter writer = null;
		String[] record = file_header.split(",");
		try {
			writer = new CSVWriter(new FileWriter(fileName));
			writer.writeNext(record);
			for (Entry<String, FunctionsTableEntry> entry : m_functions_map.entrySet()) {
				record[0] = String.valueOf(entry.getValue().id);
				record[1] = String.valueOf(entry.getValue().source_id);
				record[2] = String.valueOf(entry.getValue().line_number);
				record[3] = entry.getValue().mangled_name;
				record[4] = entry.getValue().demangled_name;
				writer.writeNext(record);
			}
			System.out.println(fileName + " created successfully.");
		} catch (IOException e) {
			System.err.println("Error generating " + fileName);
			System.exit(1);
		} finally {
			try {
				writer.flush();
				writer.close();
			} catch (IOException e) {
				System.err.println("Error closing " + fileName);
				System.exit(1);
			}
		}
	}

}
