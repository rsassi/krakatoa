package gcov2covDB;

public class TestTableEntry {
public	
     Integer id;
     Integer group_id;
	 String mangled_name;
	 String name;
	 String path;
	 String execution_time_secs;
	 String passed;
	 String failed;
	 
		public TestTableEntry(
				Integer the_id,
				Integer the_group_id,
				String the_mangled_name,
				String the_name, 
				String full_path,
				String the_execution_time_secs,
				String did_pass,
				String did_fail
				) {
			id  = the_id;
			group_id  = the_group_id;
			mangled_name= the_mangled_name;
			name = the_name;
			path = full_path;
			execution_time_secs = the_execution_time_secs;
			passed = did_pass;
			failed = did_fail;
		}
}
