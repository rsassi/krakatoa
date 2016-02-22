package gcov2covDB;

public class SourceFileTableEntry {
	
	private String name;

	public SourceFileTableEntry(String name) {
		setName(name);
	}
	
	public String getName() {
		return name;
	}
	
	public String toString() {
		return "Name: " + getName() + "\n";
	}
	
	public void setName(String name) {
		this.name = name;
	}

}
