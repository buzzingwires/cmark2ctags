module cmark2ctags.cmark;

import std.typecons : Typedef;

extern(C) @nogc nothrow
{

/**
 * ## Options
 */

/** Default options.
 */
enum int CMARK_OPT_DEFAULT = 0;

alias bufsize_t = Typedef!int;

enum cmark_event_type
{
	CMARK_EVENT_NONE,
	CMARK_EVENT_DONE,
	CMARK_EVENT_ENTER,
	CMARK_EVENT_EXIT
}

enum cmark_node_type
{
	/* Error status */
	CMARK_NODE_NONE,

	/* Block */
	CMARK_NODE_DOCUMENT,
	CMARK_NODE_BLOCK_QUOTE,
	CMARK_NODE_LIST,
	CMARK_NODE_ITEM,
	CMARK_NODE_CODE_BLOCK,
	CMARK_NODE_HTML_BLOCK,
	CMARK_NODE_CUSTOM_BLOCK,
	CMARK_NODE_PARAGRAPH,
	CMARK_NODE_HEADING,
	CMARK_NODE_THEMATIC_BREAK,

	CMARK_NODE_FIRST_BLOCK = CMARK_NODE_DOCUMENT,
	CMARK_NODE_LAST_BLOCK = CMARK_NODE_THEMATIC_BREAK,

	/* Inline */
	CMARK_NODE_TEXT,
	CMARK_NODE_SOFTBREAK,
	CMARK_NODE_LINEBREAK,
	CMARK_NODE_CODE,
	CMARK_NODE_HTML_INLINE,
	CMARK_NODE_CUSTOM_INLINE,
	CMARK_NODE_EMPH,
	CMARK_NODE_STRONG,
	CMARK_NODE_LINK,
	CMARK_NODE_IMAGE,

	CMARK_NODE_FIRST_INLINE = CMARK_NODE_TEXT,
	CMARK_NODE_LAST_INLINE = CMARK_NODE_IMAGE,
}

struct cmark_mem
{
	void* function(size_t, size_t) calloc;
	void* function(void*, size_t) realloc;
	void function(void*) free;
}

struct cmark_list
{
	int marker_offset;
	int padding;
	int start;
	ubyte list_type;
	ubyte delimiter;
	ubyte bullet_char;
	bool tight;
}

struct cmark_code
{
	ubyte* info;
	ubyte fence_length;
	ubyte fence_offset;
	ubyte fence_char;
	byte fenced;
}

struct cmark_heading
{
	int level;
	bool setext;
}

struct cmark_link
{
	ubyte* url;
	ubyte* title;
}

struct cmark_custom
{
	ubyte* on_enter;
	ubyte* on_exit;
}

struct cmark_node
{
	cmark_mem* mem;

	cmark_node* next;
	cmark_node* prev;
	cmark_node* parent;
	cmark_node* first_child;
	cmark_node* last_child;

	void* user_data;

	ubyte* data;
	bufsize_t len;

	int start_line;
	int start_column;
	int end_line;
	int end_column;
	int internal_offset;
	ushort type;
	ushort flags;

	union
	{
		cmark_list list;
		cmark_code code;
		cmark_heading heading;
		cmark_link link;
		cmark_custom custom;
		int html_block_type;
	};
}

struct cmark_iter_state
{
	cmark_event_type ev_type;
	cmark_node* node;
}

struct cmark_iter
{
	cmark_mem* mem;
	cmark_node* root;
	cmark_iter_state cur;
	cmark_iter_state next;
}

/** Parse a CommonMark document in 'buffer' of length 'len'.
 * Returns a pointer to a tree of nodes.  The memory allocated for
 * the node tree should be released using 'cmark_node_free'
 * when it is no longer needed.
 */
cmark_node* cmark_parse_document(const byte* buffer, size_t len, int options);

/** Frees the memory allocated for a node and any children.
 */
void cmark_node_free(cmark_node* node);

/**
 * ## Tree Traversal
 */

/** Creates a new iterator starting at 'root'.  The current node and event
 * type are undefined until 'cmark_iter_next' is called for the first time.
 * The memory allocated for the iterator should be released using
 * 'cmark_iter_free' when it is no longer needed.
 */
cmark_iter* cmark_iter_new(cmark_node* root);

/** Frees the memory allocated for an iterator.
 */
void cmark_iter_free(cmark_iter* iter);

/** Advances to the next node and returns the event type (`CMARK_EVENT_ENTER`,
 * `CMARK_EVENT_EXIT` or `CMARK_EVENT_DONE`).
 */
cmark_event_type cmark_iter_next(cmark_iter* iter);

/** Returns the current node.
 */
cmark_node* cmark_iter_get_node(cmark_iter* iter);

/**
 * ## Accessors
 */

/** Returns the type of 'node', or `CMARK_NODE_NONE` on error.
 */
cmark_node_type cmark_node_get_type(cmark_node* node);

/** Returns the heading level of 'node', or 0 if 'node' is not a heading.
 */
int cmark_node_get_heading_level(cmark_node* node);

///** Returns the line on which 'node' begins.
// */
//int cmark_node_get_start_line(cmark_node* node);
///** Returns the col at which 'node' begins.
// */
//int cmark_node_get_start_column(cmark_node* node);

/** Returns the line on which 'node' ends.
 */
int cmark_node_get_end_line(cmark_node* node);
///** Returns the col at which 'node' ends.
// */
//int cmark_node_get_end_column(cmark_node* node);

} /* extern(C) */


