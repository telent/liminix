check:
	./output-template ./example-output/ '{{' '}}' < example.ini > output
	diff -u output example.ini.expected
