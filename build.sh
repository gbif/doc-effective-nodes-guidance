#!/bin/bash -e

# Run in:
#   docker run --rm -it -v $PWD:/documents/ asciidoctor/docker-asciidoctor:1.5.7.1

# Enable the **/*.en.adoc below.
shopt -s globstar
# In case there are no translations.
shopt -s nullglob

# Produce the translated adoc source from the po-files.
echo "Translating sources"
po4a -v po4a.conf
for lang in translations/??.po; do
	langcode=$(basename $lang .po)
	echo "Processing index.en.adoc for $langcode"
	#for doc in **/*.en.adoc; do
	#	po4a-translate -f asciidoc -M utf-8 -m $doc -p $lang -k 0 -l $(dirname $doc)/$(basename $doc .en.adoc).$langcode.adoc
	#done
	# Convert some includes to refer to the translated versions (this needs improvement).
	perl -pi -e 's/([A-Za-z0-9_-]+).en.adoc/\1.'$langcode'.adoc/' index.$langcode.adoc
done
echo "Translating source files completed"
echo

# Generate the output HTML and PDF.
rm -f **/*.??.html **/*.??.pdf *.??.asis
for lang in en translations/??.po; do
	langcode=$(basename $lang .po)
	echo "Building language $langcode"
	mkdir -p $langcode

	# Document title for PDF filename
	title=$(grep -m 1 '^=[^=]' index.$langcode.adoc | tr / - | sed 's/^= *//; s/ /-/g; s/-+/-/g;' | tr '[:upper:]' '[:lower:]')
	echo "Document title in $langcode is “$title”"

	asciidoctor     -o $langcode/index.$langcode.html -a lang=$langcode index.$langcode.adoc
	asciidoctor-pdf -o $langcode/$title.$langcode.pdf -a lang=$langcode index.$langcode.adoc

	cat > index.$langcode.asis <<-EOF
		Status: 303 See Other
		Location: ./$langcode/
		Content-Type: text/html; charset=UTF-8
		Content-Language: $langcode
		Vary: negotiate,accept-language

		See <a href="./$langcode/">$langcode</a>.
	EOF

	echo "$langcode completed"
	echo
done

# Make translation template
# po4a-gettextize -f asciidoc -M utf-8 -m index.adoc -p translations/index.pot

# Update translation
# po4a-updatepo -f asciidoc -M utf-8 -m index.adoc -p translations/da.po

# po4a-normalize -f asciidoc -M utf-8 translations/da.po

# Translate
# po4a-translate -f asciidoc -M utf-8 -m index.adoc -p translations/da.po -k 0 -l index.da.adoc
