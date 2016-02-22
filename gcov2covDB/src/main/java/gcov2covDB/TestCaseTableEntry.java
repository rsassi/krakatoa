package gcov2covDB;

public class TestCaseTableEntry {
	
	private String mangled_name_hash;
	private String name;
	private String path;
	
	public TestCaseTableEntry() {
		setMangledNameHash(null);
		setName(null);
		setPath(null);
	}
	
	public TestCaseTableEntry(String hash, String nom, String full_path) {
		setMangledNameHash(hash);
		setName(nom);
		setPath(full_path);
	}
	
	public String getMangledNameHash() {
		return mangled_name_hash;
	}
	
	public String getName() {
		return name;
	}
	
	public String getPath() {
		return path;
	}
	
	public String toString() {
		return "Name: " + getName() + "\n\tHash: " + getMangledNameHash()  + "\n\tPath: " + getPath() + "\n";
	}
	
	public void setMangledNameHash(String hash) {
		mangled_name_hash = hash;
	}
	
	public void setName(String nom) {
		name = nom;
	}
	
	public void setPath(String full_path) {
		path = full_path;
	}
}
