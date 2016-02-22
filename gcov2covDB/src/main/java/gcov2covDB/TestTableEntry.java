package gcov2covDB;

public class TestTableEntry {
	
	private String mangled_name;
	private String demangled_name;
	private String path;
	
	public TestTableEntry(String mangled, String demangled, String path) {
		setMangledName(mangled);
		setDemangledName(demangled);
		setPath(path);
	}
	
	public String getMangledName() {
		return mangled_name;
	}
	
	public String getDemangledName() {
		return demangled_name;
	}
	
	public String toString() {
		return "Mangled Name: " + getMangledName() + "\n\tDemangled Name: " + getDemangledName() + "\n";
	}
	
	public void setMangledName(String name) {
		mangled_name = name;
	}
	
	public void setDemangledName(String name) {
		demangled_name = name;
	}

	public void setPath(String path) {
		this.path = path;
	}
	public String getPath() {
		return this.path;
	}


}
