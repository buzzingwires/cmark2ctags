module cmark2ctags.main;

import std.stdio : stdout, stderr, File;
import std.exception : ErrnoException;
import std.string : empty, format, splitLines;
import std.algorithm.sorting : sort;
import std.algorithm.mutation : SwapStrategy;
import std.getopt : getopt;
import core.stdc.errno : EPERM, EACCES, ENOENT;
import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;

import cmark2ctags.cmark;
import cmark2ctags.tag : tag;
import cmark2ctags.item : item, items2tags;
import cmark2ctags.parse : findItems;

static immutable enum string NAME = r"cmark2ctags";
static immutable enum string VERSION = r"4";
static immutable enum string CTAG_NAME_STRING = format("!_TAG_PROGRAM_NAME\t%s\n", NAME);
static immutable enum string CTAG_VERSION_STRING = format("!_TAG_PROGRAM_VERSION\t%s\n", VERSION);

class exitException : Exception
{
	int status;
	this(int rc, string file = __FILE__, size_t line = __LINE__) @safe pure nothrow
	{
		super(null, file, line);
		this.status = status;
	}
}

void genTagsFile(File output, tag*[] tags, immutable string sort) @safe
{
	assert(sort == r"yes" || sort == r"foldcase" || sort == r"no");

	string outputString = "!_TAG_FILE_FORMAT\t2\n";
	if(sort == r"yes")
	{
		tags.sort!(r"a.strFmt < b.strFmt", SwapStrategy.stable);
		outputString ~= "!_TAG_FILE_SORTED\t1\n";
	}
	else if(sort == r"foldcase")
	{
		tags.sort!(r"toLower( a.strFmt ) < toLower( b.strFmt )", SwapStrategy.stable);
		outputString ~= "!_TAG_FILE_SORTED\t2\n";
	}
	else
	{
		outputString ~= "!_TAG_FILE_SORTED\t0\n";
	}
	outputString ~= CTAG_NAME_STRING;
	outputString ~= CTAG_VERSION_STRING;

	foreach(t; tags)
	{
		outputString ~= t.strFmt;
		outputString ~= "\n";
	}

	output.write(outputString);
}

File openFile(immutable string filename, immutable string mode) @trusted
{
	File openedFile;
	try
	{
		openedFile = File(filename, mode);
	}
	catch(ErrnoException ex)
	{
		switch(ex.errno)
		{
		case EPERM:
		case EACCES:
			stderr.writefln("Permission denied for file \"%s\".", filename);
			throw new exitException(EXIT_FAILURE);
		case ENOENT:
			stderr.writefln("File \"%s\" does not exist.", filename);
			throw new exitException(EXIT_FAILURE);
		default:
			stderr.writefln("Errno %d encountered for file \"%s\".", ex.errno, filename);
			throw new exitException(EXIT_FAILURE);
		}
		assert(false); //We should not reach this.
	}
	return openedFile;
}

int main(string[] args) @trusted
{ try {
	immutable string helpMsg = format("Usage: %s [options] file(s)

Options:
  -h, --help            Show this help message and exit.
  -v, --version         Show program's version number and exit.
  -f FILE, --file=FILE  Write tags into FILE (default: \"tags\").  Use \"-\" to
						write tags to stdout.
  -s [yes|foldcase|no], --sort=[yes|foldcase|no]
						Produce sorted output.  Acceptable values are \"yes\",
						\"no\", and \"foldcase\".  Default is \"yes\".
  -r SRO, --sro=SRO     Scope resolution operator, to specify item precedence
						in file. This parameter cannot be empty. Default is:
						'|', to retain backwards compatibility with the
						original markdown2ctags script. You might consider
						changing it to <sro>, as '|' can be included in normal
						MarkDown.
  -e SRO_ESCAPED, --sro-escaped=SRO_ESCAPED
						If the sequence specified by \"-r\" or \"--sro\" is
						found, it will be replaced by the character specified
						by this parameter, or deleted entirely if that
						it is left blank (default).", args[0]);

	immutable string versionMsg = format("%s version %s", args[0], VERSION);

	assert(args.length >= 1);
	if( args.length < 2 )
	{
		stderr.writeln(r"Use -h or --help for options.");
		throw new exitException(EXIT_SUCCESS);
	}
	else if(args[1] == r"-h" || args[1] == r"--help")
	{
		if(args.length > 2)
		{
			stderr.writeln(r"-h or --help do not take options.");
			throw new exitException(EXIT_FAILURE);
		}
		stderr.writeln(helpMsg);
		throw new exitException(EXIT_SUCCESS);
	}
	else if(args[1] == r"-v" || args[1] == r"--version")
	{
		if(args.length > 2)
		{
			stderr.writeln(r"-v or --version do not take options.");
			throw new exitException(EXIT_FAILURE);
		}
		stderr.writeln(versionMsg);
		throw new exitException(EXIT_SUCCESS);
	}

	string outputFilename = r"tags";
	string sro = r"|";
	void sroCallback(immutable string option, immutable string value) @trusted
	{
		if( value.empty() )
		{
			stderr.writefln(r"The SRO cannot be empty.");
			throw new exitException(EXIT_FAILURE);
		}
		if(value[0] == '\\')
		{
			stderr.writefln(r"The SRO cannot be '\'.");
			throw new exitException(EXIT_FAILURE);
		}
		sro = value;
	}
	string sroEscaped = r"";
	string sortMethod = r"yes";
	void sortCallback(immutable string option, immutable string value) @trusted
	{
		if(value != r"yes" && value != r"no" && value != r"foldcase")
		{
			stderr.writefln("Sort method \"%s\" is invalid.", value);
			throw new exitException(EXIT_FAILURE);
		}
		sortMethod = value;
	}
	getopt(args,
		   r"file|f", "Write tags into FILE (default: \"tags\").  Use \"-\" to write tags to stdout.", &outputFilename,
		   r"sro|r",  "Scope resolution operator, to specify item precedence in file. Default is: '|', to retain backwards compatibility with the original markdown2ctags script. It might be changed to '\\', as '|' can be included in normal MarkDown.", &sroCallback,
		   r"sro-escaped|e", "If the sequence specified by \"-r\" or \"--sro\" is found, it will be replaced by the character specified by this parameter, or deleted entirely if that it is left blank (default).", &sroEscaped,
		   r"sort|s", "Produce sorted output.  Acceptable values are \"yes\", \"no\", and \"foldcase\".  Default is \"yes\".", &sortCallback
		  );

	if(args.length == 1)
	{
		stderr.writefln("There are no MarkDown files to be parsed.");
		throw new exitException(EXIT_FAILURE);
	}

	File outputFile;
	if(outputFilename == r"-")
	{
		outputFile = stdout;
	}
	else
	{
		outputFile = openFile(outputFilename, r"w");
	}

	foreach(a; args[1..$])
	{
		File inputFile = openFile(a, r"rb");
		const byte[] inputBuf = inputFile.rawRead(new byte[inputFile.size]);
		immutable string[] inputLines = splitLines(cast(string)inputBuf);
		inputFile.close();

		cmark_node* inputDoc = cmark_parse_document(cast(byte*)inputBuf, inputBuf.length, CMARK_OPT_DEFAULT);
		item*[] items = findItems(a.idup(), inputLines, inputDoc);
		genTagsFile(outputFile, items2tags(items, sro, sroEscaped), sortMethod);
		cmark_node_free(inputDoc);
	}

	outputFile.flush();
	outputFile.close();
	throw new exitException(EXIT_SUCCESS);
/* try */} catch(exitException ex) { return ex.status; }
assert(false); //Ensure we only use exitException to quit.
}


