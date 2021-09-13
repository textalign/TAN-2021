# Changes since version 2020

Below are listed significant changes that have been made since version 2020 to the Text Alignment Network. See the git log of the dev branch for a complete account of all changes.

## General

* Converted to XSLT 3.0
* Only one point of entry now to the TAN function library. That also means that Schematron validation relies only on a single file, but aliases for the different file types have been included.
* Function library files have been distributed in various subdolders pertaining to topics. Any files not necessary for validation have been sequestered with `@use-when`, so the footprint for validation is lighter than the whole function library.
* Scriptum and work vocabulary items are now available to all classes.
* The development branch of TAN now has root subdirectories `maintenance` and `tests`. The former are for applications that populate collection indexes and the guidelines. The latter are for XSpec and other tests. The error tests that were in the function library have been moved here.
* All global variables and template mode names are now in the TAN namespace.
* Every template is now defined with an `<xsl:mode>` that specifies what should happen in case no match is found. This will prevent any unwanted influence on an including stylesheets that may not want TAN's default shallow-copy method.
* Every function has a declared visibility, mainly public or private. Documentation will now present only the public functions.
* Some advanced features of 3.0, such as `xsl:function/@cache` have been marked with static attributes that determine whether advanced processing features are available.
* Included function library `open-and-save-archive` have been located in the main function library, without all the examples.
* Function library now subject to development schemas that check for best practices and other desiderata.
* The inclusions that populate the applications folder are being liquidated. They either go into the official TAN function library, or they are moved to the specific application. 
* New errors tan22, tan23
* Removed error wrn08
* Removed `@help`
* Added `@exceptions` in `numerals`, to prevent specific `@ref` and `@n` values from being interpreted as numerals.
* `<predecessor>` need not point to a TAN file, and they may use patterns to point to multiple files, since a TAN file might be based upon a number of previous files.

### Class 1

* Every reference system is now declared, explicitly or implicitly. A new optional element `<reference-system>` declares the type of reference system (logical or material) 
* Added `reference-system`, to allow class 1 files to be parsed by Writing Fragment Identifier URIs
* `div` may now take `@ref-alias`, which provides an alternative reference for the `div`. The number of steps in each reference must match exactly the depth of the `div` within `body`, and each step in each reference is assumed to inherit the corresponding type of the ancestor or self `div`. This feature was added particularly to support class 1 files representing scripta that preserve a work only fragmentarily (i.e., via quotation). In some cases, a quotation might be assigned to more than one place in the reference system of the target work, perhaps because that passage appears more than once in the work. In such cases, 
* added error tei01 to enforce @n syntax

### Class 2
* Fix: adjustment reference systems are converted into the target source file's preferred @n system before application.
* Class-1 sources now fetch all @n aliases, so that the host class 2 file can use synonyms. The concept here is that a class 2 file is a kind of extension of a class 1 file, which means that the former should be able to access the terminology of the latter.
* Deleted error code rea03 (superceded by cl219)
* TAN-A-lm morphological codes now evaluated via maps. 
* Removed element `div-ref`.
* In TAN-A claim, with `@scriptum` in an `object` or `subject`, removed `@work` and `@version` as extra filtering attributes.

### Class 3

* TAN-mor `@m-has-features` and `@m-has-how-many-features` changed to `*-codes`.
* `features` now moved out of vocabulary-key into body as `code`. In `category` each `feature` is now a `code`. This brings the format into conformity with all other TAN files' use of `vocabulary-key`.
* `code` can now take zero or more `desc`s and must take one `val`. That's because this is the one place where general grammatical terms can be brought to bear upon a specific language and the designated codes. 
* tmo01 removed (features allowed multiple codes, individually or in combination) 

#### Adjustments
* Permitted reassignments to be given priority values, so they can be placed in a target div in a requested order.
* Allowed nonvalidation routine to preserve a record in a source div of any passages moved out due to reassign. Marker is made via `<reassigned>`.
* Streamlined allocation of reassigned tokens
* Ranges can be declared of predictable compound numbers, e.g., 4a-4e (or its equivalent, 4a-e).
* Allowed adjustment actions to be interleaved

## Functions

Removed:
* `tan:div-to-div-transfer()` (replaced by `tan:infuse-tree()`)

Added: 
* `tan:stamp-tree-with-text-data()`, which efficiently inserts` @_pos` and `@_len` in elements to mark their string position and length. A related `tan:stamp-diff-with-text-data()` handles the process specifically for output from `tan:diff()`; same, mutatis mutandis, for `tan:stamp-collation-with-text-data()`. The process replaces `tan:analyze-leaf-div-string-length()` and `tan:analyze-string-length`, to make it more general purpose. The underscore attribute names are better for temporary stamping than `@string-pos` and `@string-length`.
* `tan:consolidate-identical-adjacent-divs()` to handle postprocessing the output of `tan:sequence-to-tree()`.
* `tan:greek-graves-to-acutes`. Changes Greek letters with grave accents to their counterparts with acutes.
* `tan:syriac-marks-to-mod-end()`. Shifts combining marks to the end of a word, and puts them in codepoint order, so that more relaxed string comparison can be performed.
* `tan:infuse-diff-and-collate-stats()`. Adds statistics to head of output of tan:diff() and tan:collate().
* `tan:diff-a-map()`. Converts the output of tan:diff() into a `map(xs:integer, item()*)`, where the keys are integers pointing to the position of an a, mapped to its corresponding b content. This function is an important dependency of the compare application, so that texts can be normalized before the comparison is made, then reverted to their original forms. 
* `tan:replace-diff()`. Changes the output of tan:diff() to match the original a and b strings.
* `tan:replace-collation()`. Changes the output of tan:collate() to match an original string of one's choice.
* `tan:normalize-tan-tei-divs()`. Changes TAN-TEI leaf divs so that their contents are space-normalized according to TAN rules.
* `tan:replace-expanded-class-1-body()`. Replaces the text content of an expanded file with another string. It is presumed that the replacement string is similar to the current text content, so `tan:diff()` is used to allocate the replacement.
* `tan:concat-and-sort-diff-output()`. Takes one or more outputs of `tan:diff()`, puts them together, and makes sure that the content follows the sequence a, b, common, with adjacent elements combined.
* `tan:filename-satisfies-regex(es)()` and `tan:satisfies-regex(es)()`: 2, 3, 4-param versions to check whether a string matches a given regex and does not match one. Useful for applications that need to filter values based on both matching and non-matching values. 
* `tan:map-put()`: 2-, 3-param versions of a function that inserts or replaces one or more map entries deep within a map. Useful for developming modules of maps for `fn:transform()`.
* `tan:reverse-string()`. Returns a string but in reverse order. 
* `tan:numbers-to-portions()`. Returns a sequence of doubles from 0 through 1 specifying where each input number stands in proportion to the sum of the whole sequence of input numbers. Used for proportionately distributing text that needs to be split. 
* `tan:segment-string()`. Takes a string and a series of decimals between 0 and 1, and a regular expression. Returns the string in segments split at each of the input decimal locaiions, allowing splits only where the regular expression allows. 
* `tan:chop-diff-output()`. Chops diff output according to input integers.
* `tan:absolutize-hrefs()`. Converts all relative hrefs to absolute ones, based on an input base uri.
* `tan:convert-to-html()`. Turns any XML file into HTML divs. Was part of the application suite.
* A much more robust set of numeric conversion functions have been introduced, for conversion across binary, decimal, hexadecimal, base64Binary. This has many new functions for converting from one type to another.
* A set of functions pertaining to octets have been introduced. This allows for conversion from codepoints to octets, and for conversion from 8-bit codepoints to and from UTF-8.
* A set of binary functions have been introduced. The `xs:boolean` type has been coopted as a binary data format. Functions of interest: `tan:pad-bits()`, `tan:bits-to-byte()`, `tan:bits-to-word()`, and a wide variety of conversions for bits to and from octets, 8-bit characters, hexBinary, and base64Binary. New bitwise functions: `tan:bitwise-not()`, `tan:bitwise-or()`, `tan:bitwise-and()`
* `tan:checksum-fletcher-16()` and counteraprts in 32 and 64, for returning a checksum value for a string/file.
* `tan:md5()` for returning and MD-5 hash. Efficient only on strings of, say, 20k or less.
* `tan:add-attributes()`. Inserts attributes within specified elements.
* `tan:get-namespace-map()`. Builds a namespace map coordinating URIs to prefixes.
* `tan:normalize-tree-space()` will space-normalize any tree fragment based on TAN rules. This function is especially important for TEI files, because all TEI elements, even those within leaf divs, will have their space fixed.
* `tan:substring-before()` and `tan:substring-after()`. These are shadow functions to the official functions of the same name, but now include 2-arity versions that let one work on the basis of the last match, not the first.
* `tan:parse-a-hrefs`. For wrapping text URLs in html &lt;a href="">
* `tan:wrap-text-nodes()` and `tan:make-non-mixed()` will wrap text nodes in `&lt;_text q="[generate-id() value]">`.
* `tan:get-ref()` retrieves all permutations of @n values in an element and its ancestors. Good for applications that do not want to expand a TAN file.
* `tan:chop-tree()`. Chops an XML fragment into slices according to input integers.
* `tan:has-vocab()`. Checks to see if an attribute points to a particular vocabulary item.
* `tan:sort-change-log()`. Reorders a change log in a TAN file. 
* `tan:array-to-xml()`. Renders an array in a tree.
* `tan:get-diff-output-transpositions()`. Looks in the output from `tan:diff()` for passages that represent transpositions of sizeable text.
* `tan:get-diff-output-slices()`. Returns slices of and output from `tan:diff()` that meet a particular threshold for similarity/dissimilarity. Useful for isolating passages where the two texts are quite alike, or quite different.
* `tan:TAN-A-lm-hrefs()`. Returns href URIs to language-specific TAN-A-lm files from the local catalog.
* `tan:morpoholgical-code-conversion-maps()`. Returns a mapping of codes from one TAN-mor file to another.
* `tan:convert-morphological-codes()`. Given a TAN-A-lm file, and the output of `tan:morpoholgical-code-conversion-maps()`, returns the TAN-A-lm file with codes changed. Very useful for changing lexico-morphological data from one scheme into another.
* `tan:ana-lm-arrays()`. Converts TAN-A-lm anas into singleton arrays of lm codes, with certainty. Useful for statistics and calibration.
* `tan:xml-to-array()` and `tan:xml-to-map()`: allows reversal of the output generated by `tan:array-to-xml()` and `tan:map-to-xml()`.
* `tan:map-to-array()`. Converts a map to an array.
* `tan:array-to-map()`. Converts an array to a map.
* `tan:map-keys()`. Surrogate of `map:keys()`, but looks for keys deep in the map.
* `tan:map-remove()`. Surrogate of `map:remove()`, but removes entries deep in the map, and allows multiple keys.
* `tan:trim-long-tree()`. Truncates long runs of siblings; excellent for handling diagnostic output.
* `tan:integer-groups()`. Takes a sequence of integers and returns them as sorted groups. Each group is a set of contiguous integers.
* `tan:restore-chopped-tree()`. Stitches together the output of `tan:chop-tree()`.
* Template named `tan:regex-group-count()`. Retrieves the current number of regex groups, without breaking the cycle of templates and tunnel parameters.
* `tan:log2()`. Returns the binary logarithm of the input.
* `tan:integers-to-sequence()` renamed `tan:integers-to-expression()`
* `tan:expand-numerical-sequence()` renamed `tan:expand-numerical-expression()`
* `tan:diff-to-delta()`. Converts `tan:diff()` output into a special delta format, to support two-way conversion.
* `tan:apply-deltas()`. Takes a string and one or more deltas, and returns the corresponding string, after applying all deltas.
* `tan:levenstein-distance()` and `tan:lcs-distance()`: calculates scores on the output of `tan:diff()`.

Altered:
* `tan:diff()` has been greatly simplified and improved. It runs about 40% faster, and easily handles pairs of strings 3M characters in length.
* `tan:text-join()` now has an option to insert a new line at each `<div>` (useful for string differences).
* `tan:get-1st-da` returns a resolved URI, uses XSLT 3.0 iteration.
* `tan:infuse-tree()` (formerly `-divs`) renamed, made more general purpose.
* `tan:strip-outer-indentation()`
* `tan:map-to-xml()`. Output is typed, better keyed to how it is presented in the XSLT specs.
* `tan:collate-pair-of-sequences()`. Better handling via maps.
* `tan:ellipses()`. Added 3- and 4-arity versions, to support mid-string ellipses, and an elision character count
* `tan:batch-replace-advanced()`. Supported the use of captured regular expressions, messaging.
* `tan:uri-collection-from-pattern()`. Same as `uri-collection()`, but allows glob syntax.

## Languages

Introduced batch replacements and functions for Latin, Greek, Syriac, for purposes of normalizing before string comparison.

## Applications

* Applications have been reorganized, so that the primary stylesheet opened up presents only parameters and documentation, so that public users have a better sense of what they are invited to change. Every folder now has an `incl` subfolder where the guts of the application are kept. Obviously, anyone can nad should feel free to adapt the stylesheets, but it reduces confusion for public users unaware of how the TAN library works.
* Major tests, refinement to compare class 1 file tool, display of merged sources
* Retired adjust file.xsl, the whole test suite, re-sort XSLT stylesheet, because they aren't really specifically TAN applications.
* Retired resolve hrefs.xsl and resolve TAN file because they are trivial (the output of a single standard TAN function).
* Converted relativize hrefs to an extended function.
* Conversions from previous versions of TAN are retired, replaced by a single application, upgrade TAN file, which can be developed for multiple versions in years to come.
* Restored the application that updates a class-1 file based on its predecessor. 
