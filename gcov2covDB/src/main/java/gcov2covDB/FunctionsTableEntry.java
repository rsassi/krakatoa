package gcov2covDB;

public class FunctionsTableEntry {
	public int id;
	public int source_id;
	public int line_number;
	public String mangled_name;
	public String demangled_name;
	

	public FunctionsTableEntry(int id, int sourceId,  int line, String mangledName, String demangledName) {
		this.id = id;
		this.source_id = sourceId;
		this.line_number = line;
		this.mangled_name = mangledName;
		this.demangled_name = demangledName;
	}


}
