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
	cmark_iter* iter = cmark_iter_new(doc);
	for(cmark_event_type evType = cmark_iter_next(iter);
		evType != cmark_event_type.CMARK_EVENT_DONE;
		evType = cmark_iter_next(iter)
	   )
	{
		cmark_node* cur = cmark_iter_get_node(iter);
		immutable cmark_node_type curType = cmark_node_get_type(cur);
		if(curType != cmark_node_type.CMARK_NODE_HEADING)
		{
			continue;
		}
		if(isHeadingOpen == true)
		{
			isHeadingOpen = false;
			continue;
		}
		immutable size_t endLine = cast(size_t)cmark_node_get_end_line(cur);
		immutable size_t lineNumber = (cur.heading.setext) ?
									  ( (endLine == lines.length) ?  (endLine - 1) : (endLine - 2) ) :
									  (endLine);
		assert( (cur.heading.setext) ? (endLine > 1) : (endLine > 0) );

		immutable string content = strip( cast(string)cur.content.ptr[0..cast(size_t)cur.content.size] );
		immutable string line = strip(lines[lineNumber - 1]);
		assert( !content.empty() );
		assert( !line.empty() );

		immutable size_t level = cast(size_t)cmark_node_get_heading_level(cur);
		previousSections = popItems(previousSections, level);
		item* parent = ( !previousSections.empty() ) ? ( previousSections.back() ) : (null);

		item* I = new item(level, 's', r"section", content, line, lineNumber, filename, parent);
		previousSections ~= I;
		items ~= I;
		isHeadingOpen = true;
	}
	cmark_iter_free(iter);

	return items;
}


