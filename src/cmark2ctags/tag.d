module cmark2ctags.tag;

import std.string : empty, format;

struct field
{
	string type;
	string value;
	this(immutable string type, immutable string value) @safe pure
	{
		assert(type == r"line" || type == r"section");
		this.type = type;
		this.value = value;
	}
}

struct tag
{
	string name;
	string file;
	string address;
	char kind;
	string strFmt;
	field[] fields;
	this(immutable string name, immutable string file, immutable string address, immutable char kind) @safe pure
	{
		this.name = name;
		this.file = file;
		this.address = address;
		this.kind = kind;
		this.updateStrFmt();
		assert( fields.empty() );
		assert(fields.length == 0);
	}
	private string _formatFields() @safe pure
	{
		string output = "";
		foreach(f; this.fields)
		{
			assert( !f.type.empty() );
			assert(f.type == r"section" || f.type == r"line");
			output ~= format("\t%s:%s", f.type, f.value);
		}
		return output;
	}
	void addField(immutable string type, immutable string value) @safe pure
	{
		this.fields ~= field(type, value);
	}
	void updateStrFmt() @safe pure
	{
		this.strFmt = format( "%s\t%s\t%s;\"\t%c%s", this.name, this.file, this.address, this.kind, this._formatFields() );
	}
}


