go
==

`pushd`/`popd`/`dirs`, only with a dictionary instead of a stack, and in one command.

_or_, navigate the file system by naming folders.


installation
------------

Put this in your `~/.profile`:

	alias go='source /path/to/go.sh "$@"'

Feel free to choose another name for the alias. The author happens not to use the [go language](https://golang.org).


usage
-----

	Usage: go folder-alias
	       go --command [arguments]
	
	Commands:
		-l or --list       Lists all defined aliases, sorted
		-a or --add x y    Add/replace alias x for folder y to the list. y is optional (pwd is used when omitted) 
		-d or --del x      Remove alias x from the list
		-h, -? or --help   Show this text


file format
-----------

Data is stored in '/Users/doekman/.go_config' (color `:` seperated), structure:

	alias1:~/path/to/folder-alias-1
	alias2:/path/to/folder-alias-2

known issues
------------

Lots. The source code is only kept here for historical purposes, and is not intended to be used on any system.
