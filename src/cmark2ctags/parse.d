module cmark2ctags.parse;

import std.string : empty, strip;
import std.range.primitives : back;

import cmark2ctags.cmark;
import cmark2ctags.item : item, popItems;

item*[] findItems(immutable string filename, immutable string[] lines, cmark_node* doc) @trusted
{
	item*[] items;
	item*[] previousSections;

	bool isHeadingOpen = false;
	string content = "";
	size_t lineNumber = size_t.max;
	string line = "";
	size_t level = size_t.max;
	item* parent = null;
	cmark_iter* iter = cmark_iter_new(doc);
	for(cmark_event_type evType = cmark_iter_next(iter);
		evType != cmark_event_type.CMARK_EVENT_DONE;
		evType = cmark_iter_next(iter)
	   )
	{
		cmark_node* cur = cmark_iter_get_node(iter);
		immutable cmark_node_type curType = cmark_node_get_type(cur);
		if(curType == cmark_node_type.CMARK_NODE_HEADING)
		{
			if(evType == cmark_event_type.CMARK_EVENT_ENTER)
			{
				assert(!isHeadingOpen);
				isHeadingOpen = true;

				assert( content.empty() );

				immutable size_t endLine = cast(size_t)cmark_node_get_end_line(cur);
				assert(endLine != size_t.max);

				lineNumber = (cur.heading.setext) ?
				  			 ( (endLine == lines.length) ?  (endLine - 1) : (endLine - 2) ) :
				  			 (endLine);
				assert(lineNumber != size_t.max);
				assert( (cur.heading.setext) ? (endLine > 1) : (endLine > 0) );

				line = strip(lines[lineNumber - 1]);
				assert( !line.empty() );

				level = cast(size_t)cmark_node_get_heading_level(cur);
				assert(level != size_t.max);

				previousSections = popItems(previousSections, level);
				parent = ( !previousSections.empty() ) ? ( previousSections.back() ) : (null);
			}
			else if(evType == cmark_event_type.CMARK_EVENT_EXIT)
			{
				assert(isHeadingOpen);
				assert(lineNumber != size_t.max);
				assert( !line.empty() );
				assert(level != size_t.max);

				item* I = new item(level, 's', r"section", content, line, lineNumber, filename, parent);
				previousSections ~= I;
				items ~= I;

				isHeadingOpen = false;
				content = "";
				lineNumber = size_t.max;
				line = "";
				level = size_t.max;
				parent = null;
			}
		}
		else if(isHeadingOpen && curType == cmark_node_type.CMARK_NODE_TEXT)
		{
			assert(lineNumber != size_t.max);
			assert( !line.empty() );
			assert(level != size_t.max);
			content ~= strip( cast(string)cur.data[0..cast(size_t)cur.len] );
			assert( !content.empty() );
		}
	}
	cmark_iter_free(iter);

	return items;
}


