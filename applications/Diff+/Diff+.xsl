<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to Diff+, the TAN application that finds and analyzes text differences-->
    <!-- Version 2022-03-24 -->
    <!-- Take any number of versions of a text, compare them, and view and study all the text
        differences in an HTML page. The HTML output allows you to see precisely where one version
        differs from the other. A small Javascript library allows you to change focus, remove
        versions, and explore statistics that show quantitatively how close the versions are to each
        other. Parameters allow you to make normalizations before making the comparison, and to weigh
        statistics accordingly. This application has been used not only for individual comparisons,
        but for more demanding needs: to analyze changes in documents passing through a multistep
        editorial workflow, to compare the quality of OCR results, and to study the relationship
        between ancient/medieval manuscripts (stemmatology).-->
    
    <!-- Examples of output:
        * https://textalign.net/output/CFR-2017-title1-vol1-compared.xml
            XML master output file, comparing four years of the United States Code of Federal Regulations,
            vol. 1
        * https://textalign.net/output/CFR-2017-title1-vol1-compared.html
            HTML comparison of four years of the United States Code of Federal Regulations, vol. 1
        * https://textalign.net/output/diff-grc-2021-02-08-five-versions.html
            Comparison of results from four OCR processes against a benchmark,
            classical Greek
        * https://textalign.net/clio/darwin-3diff.html
            Comparison of three editions of Darwin's works, sample
        * https://textalign.net/clio/hom-01-coll-ignore-uv.html
            Comparison of five versions of Griffolini's translation of John Chrysostom's Homily 1 on 
            the Gospel of John
    -->
    
    <!-- This master stylesheet is the public interface for the application. The parameters you will most
      likely want to change are listed and documented below, to help you customize the application to suit
      your needs. If you are relatively new to XSLT, or TAN applications, see Using TAN Applications and
      Utilities in the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and edit and
      run it directly. Or create and configure a transformation scenario in Oxygen, defining the relevant
      parameters as you like. If you are comfortable with XSLT, try creating your own stylesheet, then
      import this one, and customize the process. To access the code base, follow the link in the
      <xsl:include> at the bottom of this file. -->
    
    
    <!-- DESCRIPTION -->
    
    <!-- This is a MIRU Stylesheet (MIRU = Main Input Resolved URIs) -->
    <!-- Primary input: any XML file, including this one (input is ignored) -->
    <!-- Secondary input: one or more files -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: for each detectable language in the secondary input: (1) an XML file with
      the results of tan:diff() or tan:collate(), infused with select statistical analyses; (2) a
      rendering of #1 in an interactive, visually engaging HTML form -->

    <!-- Nota bene: -->
    <!-- * This application is useful only if the input files have different versions of the same text 
        in the same language. -->
    <!-- * The XML output is a straightforward result of tan:diff() or tan:collate(), perhaps wrapped by
        an element that also includes prepended statistical analysis. --> 
    <!-- * The HTML output has been designed to work with specific JavaScript and CSS files, and the HTML 
        output will not render correctly unless you have set up dependencies correctly. Currently, the 
        HTML output is directed to the TAN output subdirectory, with the HTML pointing to the appropriate
        javascript and CSS files in the js and css directories. -->
    
    <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED-->
    <!-- * Revise process that reinfuses a class 1 file with a diff/collate into a standard extra
        TAN function.
    -->
    
    <!-- This application currently just scratches the surface of what is possible. New features are
        planned! Some desiderata:
        1. Support a single TAN-A as the catalyst or MIRU provider, allowing <alias> to define the groups.
        2. Support MIRUs that point to non-TAN files, e.g., plain text, docx, xml.
        3. Allow one to decide whether Venn diagrams should adjust the common area or not.
        4. Enhance options on statistics.
    -->

    <!-- PARAMETERS -->
    <!-- Many parameters relevant to this application are to be found at:
        ../../parameters/params-application.xsl
        ../../parameters/params-application-diff.xsl
        ../../parameters/params-application-language.xsl
        Any parameter in this file that begins "tan:" has a corresponding parameter in one of the
      files above, and will overwrite the default value given there. You might want to alter other
      parameters in the files above for this application. All you need to do is paste a copy of the
      element in this file, replacing the value with the one you prefer. The local parameter will
      overwrite the general one. For example, if you want differences between two texts to be
      letter-for-letter, not word-for-word, then paste the following into this file: <xsl:param
      name="tan:snap-to-word" as="xs:boolean" select="false()"/> Study the parameters to see what options
      are available.
 -->


    <!-- STEP ONE: PICK YOUR DIRECTORIES AND FILES -->

    <!-- What directories of interest hold the target files? The following parameters are provided as examples,
      and for convenince, in case you want to have several commonly used directories handy. See below for
      the main parameter to pick via variable name the directory or directories you want. -->
    <xsl:param name="directory-1-uri" select="'../../examples'" as="xs:string?"/>
    <xsl:param name="directory-2-uri" select="'../../../library-arithmeticus/evagrius/cpg2455'" as="xs:string?"/>
    <xsl:param name="directory-3-uri" select="'../../../library-arithmeticus/bible'" as="xs:string?"/>
    <xsl:param name="directory-4-uri" select="'../../../library-arithmeticus/test/ring1'" as="xs:string?"/>
    <xsl:param name="directory-5-uri" select="'../../../library-arithmeticus/test/ring2'" as="xs:string?"/>
    
    <!-- What directory or directories has the main input files? Any relative path will be calculated
      against the location of this application file. Multiple directories may be supplied. Too many files?
      Results can be filtered below. -->
    <xsl:param name="tan:main-input-relative-uri-directories" as="xs:string*" select="$directory-4-uri"/>
    
    <!-- Alternatively, you can point to one or more plain text files, each with list of paths to files 
        that should be processed. Every path must start with "file:" and use regular slashes, e.g.,
        e.g., file:/d:/test/item.docx. This parameter is used by command line utilities, so if it is
        populated, the previous parameter will be ignored. The regular expression filters (see below)
        are still enforced. -->
    <xsl:param name="resolved-uris-to-lists-of-main-input-resolved-uris" as="xs:string*"/>

    <!-- What pattern must each filename match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, only those whose names match this pattern will be included. A null 
        or empty string means ignore this parameter. -->
    <xsl:param name="tan:input-filenames-must-match-regex" as="xs:string?" select="''"/>

    <!-- What pattern must each filename NOT match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, any whose names match this pattern will be excluded. A null 
        or empty string means ignore this parameter. -->
    <xsl:param name="tan:input-filenames-must-not-match-regex" as="xs:string?" select="''"/>
    
    <!-- Each diff or collation is performed against a group of files, and there may be one or more
        groups. How shall groups be created? Options:
        1. Detected language (default). Group by detected @xml:lang value; if not present in a particular
        file, assume it belongs to the predefined default language (see parameter $default-language).
        2. Filename only. Group by the filename of the files, perhaps after replacements (see parameter
        $filename-adjustments-before-grouping below).
        3. Filename and language, a synthesis of the previous two options.
    -->
    <xsl:param name="file-group-option" as="xs:integer" select="1"/>
    
    <!-- What changes if any should be made to a filename before attempting to group it with other files? The
      desired changes must be expressed as batch replacements. A batch replacement consists of a sequence
      of elements, each one with attributes @pattern and @replacement and perhaps attributes @flags and
      @message. For examples of batch replacements, see ../../parameters/params-application-language.xsl.
      Note, in most systems filenames are fundamentally not case-sensitive, but have mixed case.
      Therefore in this parameter an attribute flags="i" is normally desirable.
 -->
    <xsl:param name="filename-adjustments-before-grouping" as="element()*">
        <!-- The next example removes an ISO-style date-time stamp from the filename. -->
        <!--<replace pattern="\d{{8}}" replacement="" flags="i" message="stripping date-time stamp from filename"/>-->
        <!-- The next example ignores filename extensions. -->
        <!--<replace pattern="\.\w+$" replacement="" flags="i" message="stripping filename extension"/>-->
    </xsl:param>


    <!-- STEP TWO: REFINE INPUT FILES -->
    
    <!-- Adjust class 1 files -->
    <!-- If you have pointed to TAN class 1 files, you can do quite a lot of adjustments ahead of time, to 
    refine your results, and create natural groups. -->
    
    <!-- What top-level divs, if any, should be excluded (regular expression)? If empty, this parameter 
        will be ignored. -->
    <xsl:param name="exclude-top-level-divs-with-attr-n-matching-what" as="xs:string?" select="''"/>

    <!-- In a given group of collations/diffs, should input be restricted to only top-level 
        divs whose @ns match? Note, this will automatically remove any input that is not a
        class 1 TAN(-TEI) file.
    -->
    <xsl:param name="restrict-to-matching-top-level-div-attr-ns" as="xs:boolean" select="false()"/>
    
    <!-- What language should be assumed for any input text that does not have a language associated with it?
      Please use a standard 3-letter ISO code, e.g., eng for English, grc for ancient Greek, deu for
      German, etc. -->
    <xsl:param name="default-language" as="xs:string?" select="'eng'"/>
    
    <!-- Should non-TAN input be space-normalized before processing? Note, all TAN files will be space
        normalized before processing. -->
    <xsl:param name="space-normalize-non-tan-input" as="xs:boolean" select="false()"/>
    
    <!-- How do you wish to handle input files that are XML? Options:
        1. (default) Compare only the text values of the XML files. If a TAN or TAN-TEI file,
        only the normalized body text will be compared. For all other XML structures, the entire
        text will be taken into account.
        2. Treat the XML file as plain text. Choose this option if you are interested
        in comparing XML structures to each other. Each XML file will be serialized as a string and 
        compared.
        3. Load an XML file, convert to plain text later. Choose this option if you want to normalize
        your XML input, and perhaps adjust them, before they are compared later as strings. To do that
        adjustment, it is recommended you add templates to the mode prepare-input, keeping in mind that
        an important template is applied by Diff+ to the root element, to prepare it for grouping.
    -->
    <xsl:param name="xml-handling-option" as="xs:integer" select="1"/>
    
    
    
    
    
    <!-- STEP THREE: NORMALIZE INPUT STRINGS -->
    
    <!-- Adjustments to diff/collate input strings -->
    <!-- Additional settings at:
        ../../parameters/params-application-diff.xsl 
        ../../parameters/params-application-language.xsl 
    -->
    
    <!-- You can make normalizations to the string before it goes through the comparison. The XML
      output will show the normalized results, and statistics will be based on it. But when building the
      HTML output, this application will try to reinject the original text into the adjusted difference.
      This is oftentimes an imperfect process, because any restoration must broker between differences
      across versions. In general, the first version will predominate. -->
    
    
    <!-- ~ ~ ~ All languages in general -->
    
    <!-- Should <div> @ns be injected into the text? Normally you do not want to do this, but it can be
      helpful when you want to indentify differences in reference systems. -->
    <xsl:param name="inject-attr-n" as="xs:boolean" select="false()"/>
    
    <!-- Should differences in case be ignored? -->
    <xsl:param name="tan:ignore-case-differences" as="xs:boolean?" select="true()"/>
    
    <!-- Should punctuation be ignored? -->
    <xsl:param name="tan:ignore-punctuation-differences" as="xs:boolean" select="true()"/>
    
    <!-- What additional batch replacements if any should be applied? On batch replacements see
        above. These ad-hoc batch replacements will be applied before any other batch replacements 
        invoked by the parameters above.
    -->
    <xsl:param name="additional-batch-replacements" as="element()*">
        <!-- Here's what an example batch replacement element looks like. Remember, these will be processed
            in order, so watch out for conflicts. -->
        <!--<replace pattern="(abc)(def)" replacement="$2$1" message="example batch replacement"/>-->
    </xsl:param>
    
    
    <!-- ~ ~ ~ Specific languages -->
    
    <!-- ~ ~ ~ ~ ~ ~ Greek -->
    
    <!-- Should differences between the Greek grave and acute be ignored? -->
    <xsl:param name="ignore-greek-grave-acute-distinction" as="xs:boolean" select="true()"/>
    
    <!-- ~ ~ ~ ~ ~ ~ Latin -->
    
    <!-- If Latin (body's @xml:lang = 'lat'), should batch replacement set 1 be used? -->
    <xsl:param name="apply-to-latin-batch-replacement-set-1" as="xs:boolean" select="true()"/>
    
    <!-- ~ ~ ~ ~ ~ ~ Syriac -->
    
    <!-- Should placement of marks in Syriac be ignored? -->
    <xsl:param name="ignore-syriac-dot-placement" as="xs:boolean" select="true()"/>
    
    <!-- If Syriac (body's @xml:lang = 'syr'), should batch replacement set 1 be used? -->
    <xsl:param name="apply-to-syriac-batch-replacement-set-1" as="xs:boolean" select="true()"/>
    
    


    <!-- STEP FOUR: ADJUST THE DIFF/COLLATION PROCESS -->
    <!-- Additional settings at ../../parameters/params-application-diff.xsl. -->
    
    <!-- Collation/diff handling -->
    
    <!-- Should tan:collate() be allowed to re-sort the strings to take advantage of optimal matches? True
      produces better results, but could take longer than false. -->
    <xsl:param name="preoptimize-string-order" as="xs:boolean" select="true()"/>
    
    
    
    <!-- STEP FIVE: ADJUST OUTPUT -->
    
    <!-- Additional settings at ../../parameters/params-application.xsl -->
    
    
    <!-- In what directory should the output be saved? -->
    <xsl:param name="output-directory-uri" as="xs:string" select="$tan:default-output-directory-resolved"/>
    
    <!-- What should the base output filename be? If missing, the name of each group will be used, 
        perhaps with a suffix, and the extensions ".xml" and ".html". If the output base filename
        exists, and there is more than one of comparisons group, each set of output will be numerically 
        incremented. This process will overwrite any files already present. -->
    <xsl:param name="output-base-filename" as="xs:string?"/>
    
    <!-- What suffix, if any, should be appended to output filenames? -->
    <xsl:param name="output-filename-suffix" as="xs:string?" select="'-compared'"/>
    
    
    <!-- Statistics -->
    
    <!-- See ../../parameters/params-application-diff.xsl -->
    
    
    
    <!-- HTML output -->
    
    <!-- Important settings also at ../../parameters/params-application-html-output.xsl -->
    
    <!-- TAN Diff+'s HTML output relies upon a small core of javascript and css assets, currently in the TAN 
        package in the folders output/css and output/js, with the assumption that multiple files in the parent 
        directory will point to those libraries. But you may want another configuration. -->
    
    <!-- Where are the javascript assets? If this parameter is blank, the default directory will be the
        subdirectory js off $output-directory-uri. -->
    <xsl:param name="output-javascript-library-directory-uri" as="xs:string?"/>
    
    <!-- Where are the CSS assets? If this parameter is blank, the default directory will be the
        subdirectory css off $output-directory-uri. -->
    <xsl:param name="output-css-library-directory-uri" as="xs:string?"/>
    
    <!-- In the HTML output, should an attempt be made to convert resultant diffs back to their pre-adjustment 
        forms or not? -->
    <xsl:param name="replace-diff-results-with-pre-alteration-forms" as="xs:boolean" select="true()"/>
    
    <!-- For any input files that are XML, should any attributes be removed before processing? The value 
        must be a regular expression matching attribute names. These input attributes play no factor at 
        all in the text that will be compared. Rather, this makes sure they do not feature in the HTML 
        output. -->
    <xsl:param name="input-attributes-to-remove-regex" as="xs:string?" select="''"/>
    
    <!-- Should long stretches of text be elided in the HTML output? This is useful for cases where you want 
        to quickly identify differences, particularly in long texts. -->
    <xsl:param name="elide-lengthy-text" as="xs:boolean" select="false()"/>
    
    <!-- If text should be elided, at what point should elision be introduced? Because the elision message
        might be more than the amount elided, the elision message, estimated at forty characters, will be silently 
        added to the number below. Any number below five will be normalized to five. This parameter has no
        effect if the parameter $elide-lengthy-text is not true. So if the following value is 5 or less,
        elision will not occur unless the text is longer than 45 charaters (but only five characters will
        be retained in the output). -->
    <xsl:param name="elision-minimum-point" as="xs:integer?" select="1000"/>
    
    
    
    
    <!-- THE APPLICATION -->
    
    <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
    <xsl:include href="incl/Diff+%20core.xsl"/>
    <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
    <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>


</xsl:stylesheet>
