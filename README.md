# Text Alignment Network 

[http://textalign.net](http://textalign.net)

Version 2021 (alpha release)

New to TAN? Start here:

* [home page](http://textalign.net)
* `examples/`: A small library of assorted TAN files.
* `guidelines/`: the main documentation for TAN (PDF and XHTML available at [the TAN website](http://textalign.net)).

Want to do something practical? Start here:

* `applications/`: XSLT applications for doing cutting-edge publishing, research, and analysis with TAN / TEI files.
* `utilities/`: XSLT applications for creating, editing, and converting TAN / TEI files.

Want configure, develop, and explore TAN?

* `functions/`: The TAN function library, the heart of validation, applications, and utilities.
* `parameters/`: settings to configure TAN validation, applications, and utilities.
* `schemas/`: validates TAN files.
* `templates/`: blank files in various formats, both TAN and non-TAN, used by the applications and utilities.
* `vocabularies/`: standard TAN vocabulary files (TAN-voc).

If you want to incorporate the TAN library into your XSLT applications, you need only one line: `<xsl:include href="functions/TAN-function-library.xsl"/>` 

TAN has optional submodules for JavaScript dependencies in the output and maintenance subdirectories. To get these, use:
`git clone --recurse-submodules [GIT_SOURCE_PATH]`

Many new features and enhancements are planned for TAN. Participation is welcome. If you create or maintain a library of TAN files, share it.