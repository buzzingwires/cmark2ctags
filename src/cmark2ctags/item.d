module cmark2ctags.item;

import std.conv : text;
import std.string : empty, format, join, replace;
import std.range.primitives : back, popBack;
import std.algorithm.mutation : reverse;

import cmark2ctags.tag : tag;

private string ctagNameEscape(immutable string input, immutable string sro, immutable string sroEscaped) @safe pure
{
	return input.replace(sro, sroEscaped).replace("\t", r" ").replace("\r", r" ").replace("\n", r" ");
}
@safe pure unittest
{
	immutable string output1 = ctagNameEscape("\t\r\n<sro>", r"<sro>", r"<sro_escaped>");
	immutable string output2 = ctagNameEscape("\t\r\n<sro>", r"<sro>", r"");
	immutable string output3 = ctagNameEscape("\t\r\n<sro>", r"<sro>", "\n");
	assert(output1 == r"   <sro_escaped>");
	assert(output2 == r"   ");
	assert(output3 == r"    ");
}

private string ctagSearchEscape(immutable string input) @safe pure
{
	return input.replace("\\", r"\\").replace("\t", r"\t").replace("\r", r"\r").replace("\n", r"\n");
}
@safe pure unittest
{
	immutable string output = ctagSearchEscape("\\\t\r\n");
	assert(output == r"\\\t\r\n");
}

struct item
{
	size_t level;
	char kind;
	string[] Scopes;
	string name;
	string line;
	size_t lineNumber;
	string filename;
	item*[] parents;

	this(immutable size_t level, immutable char kind, immutable string Scope, immutable string name, immutable string line, immutable size_t lineNumber, immutable string filename, item* parent) @safe pure
	{
		assert(level >= 1);
		assert(kind == 's');
		assert(Scope == r"section");
		assert( !line.empty() );
		assert(lineNumber >= 1);
		assert( !filename.empty() );
		this.level = level;
		this.kind = kind;
		this.Scopes ~= Scope;
		assert(this.Scopes[0] == Scope);
		this.name = name;
		this.line = line;
		this.lineNumber = lineNumber;
		this.filename = filename;
		this.parents ~= parent;
		assert(this.parents[0] == parent);
	}
	tag* toTag(immutable string sro, immutable string sroEscaped) @safe pure
	{
		immutable string tagName = ctagNameEscape(this.name, sro, sroEscaped);
		immutable string tagAddress = format( "/^%s$/", ctagSearchEscape(this.line) );
		tag* t = new tag(tagName, this.filename, tagAddress, this.kind);
		t.addField( r"line", text(this.lineNumber) );

		assert(this.Scopes.length == this.parents.length);
		for(size_t i = 0; i < this.Scopes.length; ++i)
		{
			immutable string s = this.Scopes[i];
			item* p = this.parents[i];

			assert( s != r"" );
			if(p is null)
			{
				continue;
			}
			string[] parentNames = new string[0];
			//cp is short for CurrentParent.
			for(item* cp = p; !(cp is null);)
			{
				parentNames ~= ctagNameEscape(cp.name, sro, sroEscaped);
				assert( (i < cp.Scopes.length) ? (cp.Scopes[i] == s) : (true) );
				cp = ( i < cp.parents.length ) ? (cp.parents[i]) : (null);
			}
			if( !parentNames.empty() )
			{
				parentNames.reverse();
				t.addField( s, parentNames.join(sro) );
			}
		}

		t.updateStrFmt();
		return t;
	}
}

item*[] popItems(item*[] items, immutable size_t level) @safe pure
{
	while( !items.empty() )
	{
		const item* i = items.back();
		if( !(i is null) && i.level < level )
		{
			return items;
		}
		items.popBack();
	}
	return items;
}

tag*[] items2tags(item*[] items, immutable string sro, immutable string sroEscaped) @safe pure
{
	tag*[] tags;
	foreach(i; items)
	{
		tags ~= i.toTag(sro, sroEscaped);
	}
	return tags;
}


