<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="incl/Body%20Builder.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to Body Builder, the TAN application that converts structured texts to a TEI/TAN
      body based on user-specified rules-->
   
   <!-- Suppose you have texts, aspects of whose syntax, structure, or format correspond to TAN or
      TEI elements or markup. This application allows you to write regular-expression-based rules
      to convert that text into a TAN or TEI format. Input consists of one or more files in plain
      text, XML, or Word docx. The input is processed against each rule, in order of appearance,
      progressively structuring the text. Body Builder is intended for intermediate and advanced
      users who are comfortable with regular expressions and XML markup. The application is ideal
      for cases where complex, numerous, or lengthy documents need to be converted into TAN or TEI,
      as well as for developing workflows where live, ever-changing work needs to be regularly
      pushed into a TAN or TEI format.-->
   <!-- Version 2021-07-13-->

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

   <!-- Primary input: a TAN-T or TAN-TEI file that represents a target template for the parsed content
      coming from the secondary input -->
   <!-- Secondary input: one or more non-TAN files in plain text, XML, or Word format (docx); perhaps
      configuration files for the parameters -->
   <!-- Primary output: the primary output with its contents replaced by a tree parsed by applying rules to
      the source -->
   <!-- Secondary output: none -->

   <!-- This application is intended to help users convert a text to TAN-T, TAN-TEI, or TAN-A. This is
      a difficult task, mainly because the source text could be either plain text, an XML file, or a Word
      document, which requires either going from unstructured to structured text, or from one type of
      structure to another. If a Word document, the formatting might mean something, or it might not.
      Structure might be embedded in the text, or in formatting, or both. Users tend to be inconsistent
      and incomplete, and the docx format has challenges not apparent to the user. The XML structure in a
      Word file might break up adjacent text identically formatted, because it is preserving a record of
      editing history, or noting where the cursor was when the document was last edited. In sum, one
      should not take for granted the challenge of building a pipeline from pre-TAN/TEI files to TAN/TEI
      ones! -->
   <!-- The "plain" text itself poses challenges. We assume that there are in the text various 
      numerals or words that signal reference numbers. But there are thousands of ways an editor
      might choose to use those reference numbers. Some editors interleave into a single document 
      multiple overlapping or competing reference systems. A TAN file allows only one primary
      tree, so only one of those reference systems can be used. -->
   <!-- Body Builder handles these problems by allowing the editor to declare a sequence of patterns
      in the text that are the key to the textual hierarchy. To build that sequence of patterns properly,
      you must have a very good command of regular expressions. To get you started, some examples have
      been provided, based on actual conversions into TAN from challenging real-world documents. -->
   <!-- This utility has been designed based on select test cases, and there are no doubt many ways it
      could be developed and enhanced. If you encounter a problem, raise a ticket in the GitHub account. -->
   
   <!-- Some assumptions:
      * If the catalyzing input file is not a TAN file, then a fallback, generic TAN file should 
      be used; the specific one is determined by parameters below.
      * If the catalyzing input file is TAN-T, that means the output will be as well, and only the 
      structured but plain text will be returned, because TAN-T does not have any internal markup.
      * If the catalyzing input file is TAN-TEI, the TAN-TEI output will be structured text, with 
      select internal markup. To coordinate the features of your text with specific TEI markup may
      require testing with the parameters below.
      * If the catalyzing input is TAN-A, then output will consist of nothing, at the moment. When
      this feature is eventually supported, the output TAN-A file will contain structured annotations 
      on the text. This option will be supported only for Word files, whose comments will be 
      interpreted as TAN-A claims. 
   -->
   
   <!-- Some tips:
      * Build the parameters incrementally. You will find that two or three of the parameters below
      are a challenge to get right, especially for complicated documents. Begin with one or two 
      components, test the output, then add more components.
      * If building up the components in $main-text-to-markup, start with the most general rule
      first, but put it at the end of the list. Incrementally add more specific rules, placing
      them before the more general ones.
      * If you find that the output doesn't match what you intended, try commenting out some of the 
      elements in $main-text-to-markup.
      * Look out for problems in your source document. Sometimes this application results in erroneous
      output not because of the application, but because the input is not what you expected. In fact,
      if you are working with live documents that others are providing you, this application may help 
      you identify inconsistencies and problems in that input. 
      * If there are certain recurrent errors, you can actually plan for them. See the separate CLIO
      configuration file, which inserts the illegal <unexpected> to signal a problem.
   -->
   
   <!-- Nota bene:
        * Many input files will be full of internal inconsistency and error. Do not take results at face
      value. Scrutinize the output. Sometimes this will reveal that the problem originates with the
      input: typos, inconsistencies, bad formatting, etc. If you see errors in the input, you can either
      (1) fix the input or (2) customize this application to make those changes during processing. Option
      2 is definitely to be preferred if the source text is a live, working document that you have little
      control over, and there is even the slightest chance it might be revised, and need to be processed
      again.
        * This application works well with a TAN file that points to the source file in question, via
      <source> or <predecessor>. As that source file gets updated, the TAN file can be re-processed
      through this application, to refresh the results.
        * Currently, this application focuses only select Word docx components: the main text, comments,
      deletions, insertions. No support is yet provided for the header, footer, footnotes, endnotes.
        * This application was developed in tandem with two sets of actual workflows, whose results have
      been documented in the files in the config subdirectory. No doubt other concrete examples will 
      cause this application to grow and change, or bring out bugs. Feel free to register problems
      or feature requests via github.
 -->

   <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED -->
   <!-- * Anchor comments to gaps between characters, so they are not lost when the anchored text is lost. 
      * Support HTML input 
      * Support ODT input 
      * Let the default template be a document with the root element body. 
      * Support parsing of docx endnotes and footnotes.
      * Demonstrate how to convert a raw index to TAN-A.-->
   
   

   <!-- PARAMETERS -->
   
   <!-- SOURCE INPUT -->
   
   <!-- Where is the source input file? Any relative path will be resolved against this stylesheet. 
      You may wish to use for this parameter a resolved URI, e.g., "file:/c:/myfile.txt", or work with an 
      @href that is in the catalyzing file, making sure to resolve it. In many cases, a class 1 file that 
      is based upon live work being conducted in another file will ideally point to it through a linking
      element. Some suggestions:
         /*/tan:head/tan:source/tan:location/@href 
         /*/tan:head/tan:predecessor[1]/tan:location/@href 
      If the source input consists of multiple files, then the path can include glob-like wildcard
      characters, ? and *, to match filename patterns. Multiple files will be ordered alphabetically 
      by filename.
   -->
   <xsl:param name="relative-path-to-source-input" as="xs:string?"
      select="resolve-uri(
      (/*/tan:head/tan:predecessor/tan:location/@href, 
      /*/tan:head/tan:source/tan:location/@href)[1], 
      $tan:doc-uri)"/>

   <!-- TEMPLATE -->
   
   <!-- By default, the catalyzing input will be treated as the template TAN file to be used. If the 
      catalyzing input is not a TAN file, where is the TAN template file that should be used? Any 
      relative path will be resolved against this stylesheet. If this value is empty, or a TAN file 
      cannot be found, a generic TAN-T file will be used. -->
   <xsl:param name="relative-path-to-fallback-TAN-template" as="xs:string?"
      select="$tan:default-tan-t-template-uri-resolved"/>




   <!-- ADJUSTING AND INTERPRETING THE INPUT -->
   
   <!-- This begins the most complicated part of the application. You should be comfortable with 
      regular expressions before attempting to populate the values of these parameters. -->
   
   <!-- What initial adjustments, if any, should be made to the text? Expected is a sequence of elements. The
      element names do not matter, but each one must have attributes @pattern and @replacement. They may
      have @flags and @message. These attributes take the values one is supposed to provide to the XSLT
      function fn:replace(). The attribute @pattern must be a regular expression, and @replacement must be
      a corresponding replacement, using capture groups as needed. @flags must be zero or more of the
      letters ixqms, corresponding to case insensitive, ignore space, no special characters, multi-line
      mode, dot-all mode. For more on flags, see https://www.w3.org/TR/xpath-functions-31/#flags.
         Adjustments are made only to the main text. If input is a Word docx file, the comments will not
      be adjusted.
         These elements are processed by tan:batch-replace(), on which see documentation in the TAN
      library.
 -->
   <xsl:param name="initial-adjustments" as="element()*">
      <!-- Example of a replacement element. Note that capture groups in @replacement, per XSLT usage, are 
         marked with $ not \. -->
      <replace pattern="(1234)(wxyz)" replacement="$2$1" flags="i" message="Transposing $1 and $2."/>
      
      <!-- You can also invoke adjustments from a stand-off document. -->
      
      <!-- Example initial adjustments for Evagrius docx -->
      <!--<xsl:sequence select="doc('config/adjustments-evagrius.xml')/*/tan:initial-adjustments/tan:replace"/>-->
      <!-- Example initial adjustments for CLIO docx -->
      <!--<xsl:sequence select="doc('config/adjustments-clio.xml')/*/tan:initial-adjustments/tan:replace"/>-->
   </xsl:param>
   
   <!-- If the input is in the Word docx format, should any deletions be ignored? -->
   <xsl:param name="ignore-docx-deletions" as="xs:boolean" select="true()"/>
   
   <!-- If the input is Word docx, should any insertions be ignored? -->
   <xsl:param name="ignore-docx-insertions" as="xs:boolean" select="false()"/>
   
   <!-- What parts of the text signal divisions? This parameter takes a series of <markup> elements, each
      one containing one or more <where> elements followed by one or more <div> elements.
         The <where> element is used to identify spans of text in the source input. It must contain a
      @pattern, a @format, or both. @pattern is a regular expression matching text. @format applies only
      to docx input, and accepts a handful of keywords identifying one or more formats that the text must
      be rendered in. If the input is not a docx file, any <where> with a @format will be ignored.
         The <div> specifies the class 1 <div> element that should begin here. It must take @n and @type
      (which are required for the output TAN file) as well as @level, an integer that specifies how deep
      in the hierarchy the <div> should be. Both @n and @type are interpreted like @replacement in the
      parameter above. That is, you can use $1 to capture the first parenthesized subexpression in a
      given <where>'s @pattern. You can use $0 to the entire captured string. For more on this concept,
      see examples below and the discussion of the parameter replacement at
      https://www.w3.org/TR/xpath-functions-31/#func-replace.
         These elements are also processed by tan:batch-replace(), in sequential order. Every span of
      text that matches a <where> is replaced by the <div> anchors. After all markers are processed, the
      hierarchy will be constructed with tan:sequence-to-tree(), which rebuilds the hierarchy.
         All node insertions will be space-normalized.
 -->
   <xsl:param name="main-text-to-markup" as="element()*">
      <!-- Below is a simple example to get you started. For more complicated examples, see
         the configuration files. -->
      <markup>
         <!-- In this particular pattern, a set of three numbers, joined by periods, identifies the start of 
            a passage in the text, e.g., "1.2.4 As we said....". Each digit is captured in a group. -->
         <where pattern="(\d+)\.(\d+)\.(\d+)" exclude-format="center"/>
         <!-- Whenever a passage of text matching where/@pattern above is found, it is REPLACED by the following
            elements. -->
         <div level="1" type="book" n="$1"/>
         <div level="2" type="chapter" n="$2"/>
         <div level="3" type="section" n="$3"/>
         <ab level="4"/>
         
         <!-- Notes:
            - Each <div> is empty. These are empty anchors that will later be converted to a tree.
            - @level, required, specifies where in the hierarchy an element should belong.
            - In this example, each @n captures the digits that have been matched by where/@pattern.
            - <ab> is used because we're anticipating a TEI file, which does not allow <div>s to wrap text.
               We plan for an <ab>, at the fourth level. It could have been <p> or something else. If the input 
               file is TAN-T, then you shouldn't have anything but <div>s.
            - The algorithm is written to consolidate 
            - If you do not want the captured text to be dropped, you must place $0 (captures everything) in the
               intended place. See the example configuration files for an example.
         -->
         
         <!-- For example, the following text...
            
               ...1.2.3 Some text. 1.2.4 As we said...
               
            ...would be first be converted to look like the instructions...
            
               <div level="1" type="book" n="1"/>
               <div level="2" type="chapter" n="2"/>
               <div level="3" type="section" n="3"/>
               <ab level="4"/>
               Some text. 
               <div level="1" type="book" n="1"/>
               <div level="2" type="chapter" n="2"/>
               <div level="3" type="section" n="4"/>
               <ab level="4"/>
                As we said...
            
            ...which in turn would later be converted to look like this:
               
               <div type="book" n="1">
                  <div type="chapter" n="2">
                     . . . . . .
                     <div type="section" n="3">
                        <ab>Some text.</ab>
                     </div>
                     <div type="section" n="4">
                        <ab>As we said...</ab>
                     </div>
                  </div>
               </div>
            
         -->
      </markup>
      
      <!-- Example markup elements for Evagrius docx -->
      <!--<xsl:sequence select="doc('config/adjustments-evagrius.xml')/*/tan:main-text-to-markup/tan:markup"/>-->

      <!-- Example markup elements for CLIO docx -->
      <!--<xsl:sequence select="doc('config/adjustments-clio.xml')/*/tan:main-text-to-markup/tan:markup"/>-->

   </xsl:param>
   
   
   <!-- How do you wish to handle orphan text? Orphan text is any text that occurs before the first <div> marker 
      of a given level has been placed. The following options are supported:
      1 - delete orphan text
      2 - wrap orphan text in a <div type="section" n="orphan">
      3 - push orphan text down into the first leaf <div> (default)
   -->
   <xsl:param name="orphan-text-option" as="xs:integer" select="3"/>
   
   
   
   <!-- Do you wish to ignore comments? This option is relevant only for Word docx input. -->
   <xsl:param name="ignore-comments" as="xs:boolean" select="false()"/>


   <!-- Do you wish to be notified of any comments that are not addressed by 
      $comments-to-markup? This has effect only if there are instructions to
      look for comments.
   -->
   <xsl:param name="report-ignored-comments" as="xs:boolean" select="true()"/>



   <!-- Do any comments in an input Word document represent special markup? If so, provide 
      elements, similar to $main-text-to-markup, specifying how to convert the comment to 
      markup structure. This parameter is more complicated, because comments might overlap, 
      either with each other or with the tree that was just constructed via $main-text-to-markup. 
      Further, instead of a simple span of text to be replaced, handling a comment requires 
      one to manage four different components:
         1. The comment itself.
         2. The comment's opening anchor.
         3. The comment's closing anchor.
         4. The main text content between the opening and closing anchors. 
         
      Apologies for the number and detail of the following rules, but they are necessary, 
      because a comment is a stand-off entity, and integrating it into a single TEI document
      poses quite difficult problems.

      Rules:
         - The parameter consists of a sequence of <markup> elements. Each one has one or
            more <where> children, followed by any nodes (termed here replacement nodes).
         - The <where> elements must match the content of comments (#1), not the main text (#4). 
         - Items #1-3 will be REPLACED by the replacement nodes. Item #4 will be preserved by one 
            mandatory <maintext>, which specifies where it should be placed relative to the 
            new markup. This <maintext> may be placed as shallowly or deeply within the replacement
            sequence as you like. This allows you to convert comments to <milestone>s (a shallow
            replacement, where #4 precedes or follows the milestone) or to a <rdg> in an <app> 
            (a deep replacement, where #4 can be wrapped by the <app>'s <lem>). See examples in the
            CLIO configuration file.
         - It is assumed that all replacement elements represent TEI tags, so output will be 
            normalized to the TEI namespace.
         - A <markup> may have an attribute @cuts (default value false). If true, then if the 
            starting anchor or ending anchor (#2 or #3) fall within an element that its counterpart 
            anchor does not fall within, then host tree element may be cut in two, with the first 
            half preceding the new markup structure and the second half of it inside. If false 
            (default), then that <markup> instruction will be ignored because it calls for an 
            overlapping structure. See the example in the associated CLIO configuration file.
         - If main text (#4) to which a comment is anchored has been deleted by an earlier process, 
            then nothing will happen, because the comment no longer wraps any text. This rule may be
            adjusted in the future, to allow for comments wrapping zero length content.
         - If a <maintext> is the first or last item in the replacement node sequence, then the markup 
            will be treated as slicing the tree. The closing anchor (#3) will be ignored, and the 
            comment will be exempt from rules on overlapping comments (see next rule).
         - Comments will be processed in document order. If any comment A's wrapped content (#4) 
            includes an opening anchor (#2) for another comment B, and comment B has not been 
            marked to slice the text (see previous rule), then comment B will be ignored. This
            rule is necessary to avoid overlapping structures.
         - No checks will be made on whether the resultant TEI fragment is valid or not. Validate
            the results after the process.
         - The newly constructed markup will be applied as deep in the tree as possible, i.e., on 
            the text nodes in a leaf element. That is part of the nature of a comment: it annotates text. 
            If you want to build TEI elements at a more rootward level, use $main-text-to-markup.
         - The attribute @level is not used here, because the markup will be applied at the
            level of the hierarchy where the text match occurs. That level of depth is likely to be
            variable and unpredictable.
         - <markup> elements will be processed in order. Remember, though, each <markup> element
            merely fetches zero or more comments, and provides instructions on how to consume it.
            So a <markup> that matches a comment will prevent subsequent <markup> elements from
            acting on that comment. In general, put the most specific rules at the top. If you want
            a comment to do more than one thing in your new document, break them into separate comments.
   -->
   <xsl:param name="comments-to-markup" as="element()*">
      <!-- Here is a generic constructor you might want to use. -->
      <markup>
         <!-- Convert every comment into a note, inserted immediately after the main text content it
            anchors. -->
         <where pattern=".+"/>
         <maintext/>
         <note>$0</note>
      </markup>

      <!-- For examples of advanced use of this parameter, see the following file. -->
      <!--<xsl:sequence select="doc('config/adjustments-clio.xml')/*/tan:comments-to-markup/tan:markup"/>-->
   </xsl:param>
   
   
   
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/Body%20Builder%20core.xsl"/>
   <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
   <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>
   
</xsl:stylesheet>
