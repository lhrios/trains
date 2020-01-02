SHELL = bash
code_file=trAIns.tar

tar : include.nut
	mkdir /tmp/trAIns
	cp --parents COPYING include.nut info.nut main.nut `cat source.list | while read line; do echo -n $$line" "; done;` /tmp/trAIns
	tar cf $(code_file) -C /tmp trAIns
	rm -rf /tmp/trAIns

clean :
	rm -f $(code_file)

include.nut : source.list
	`cat source.list | while read line; do echo "require(\""$$line"\");"; done > include.nut`