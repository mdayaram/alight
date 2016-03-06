Alight Anthology E-book
=======================

The purpose of this repo is to generate a single all-encompassing HTML file from
the collection of poems found in the `content` directory.

## Running

You will need Ruby 1.9.3 or higher to be able to run this script.
You can run the generator by running the following command:

```bash
$> ./bin/compose.rb
```

This will generate three files, `index.html`, `index.mobi`, and `manifest.txt`
in the root directory of the repo.

## How does it work?

The script first makes sure that you have the Nokogiri gem installed, and if you
don't, it installs it for you.  If this step fails, the script will exit.  At
this point you'll have to install the gem yourself and then come back to the
script.

After the dependency check, the `compose.rb` script will read the
`content/FrontMatter.html` file and create an internal Nokogiri HTML doc object
from it.  This file is used as our basis for building the final `index.html`
file.  All `<a>` tags are read and their `href` attributes are collected.

We then resolve all the `href` attributes by reading the links to their
corresponding files and including the contents of their `<body>` into the
internal document that we're building.

Finally, we output the internal doc as `index.html`.  We then run the
appropriate `kindlegen` binary for the system to generate the `index.mobi` ebook
out of the file.
