<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array" exclude-result-prefixes="#all"
   version="3.0">

   <!-- Welcome to Parabola, the TAN application that arranges work versions in parallel for the
      web -->
   
   <!-- Version 2021-07-20-->
   <!-- This application allows you to take a library of TAN/TEI files with multiple versions of
      each work and present them in an interactive HTML page.-->

   <!-- This master stylesheet is the public interface for the application. The parameters you will most
      likely want to change are listed and documented below, to help you customize the application to suit
      your needs. If you are relatively new to XSLT, or TAN applications, see Using TAN Applications and
      Utilities in the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and edit and
      run it directly. Or create and configure a transformation scenario in Oxygen, defining the relevant
      parameters as you like. If you are comfortable with XSLT, try creating your own stylesheet, then
      import this one, and customize the process. To access the code base, follow the link in the
      <xsl:include> at the bottom of this file. -->

   <!-- Examples of output: 
      * http://textalign.net/output/aristotle-categories-ref-bekker-page-col-line.html
         Aristotle, Categories, in eight versions, six languages
      * https://textalign.net/output/cpg%204425.TAN-A-div-2018-03-09.html
         Homilies on the Gospel of John, John Chrysostom, four versions, two languages
      * https://evagriusponticus.net/cpg2430/cpg2430-full-for-reading.html
         The Praktikos by Evagrius of Pontus, three languages, with Bible quotations
      * https://textalign.net/quran/quran.ara+grc+syr+lat+deu+eng.html
         Qur'an in eighteen versions, six languages-->

   <!-- DESCRIPTION -->

   <!-- Primary input: a TAN-A file -->
   <!-- Secondary input: its sources expanded -->
   <!-- Primary output: an interactive HTML page with the versions of the chosen work grouped and arranged
      in parallel, with annotations -->
   <!-- Secondary output: none -->

   <!-- This flagship TAN application was the catalyst for TAN itself. It was developed not only for
      highly polished, finalized web publication, but to support complex editorial processes. The impetus
      was a project of five scholars translating into English an ancient text that survives only
      fragmentarily in its original Greek, and that was translated into Syriac several times. The team
      intended to translate into English the Greek fragments that survive, as well as the Syriac
      translations, and to do so with rigorous consistency. In passages where the author (Evagrius of
      Pontus) quoted from Scripture or Aristotle, they needed to be able to consult the Greek or Syriac
      text behind the quoted source. Such demands required a shared digital infrastructure to coordinate
      roughly forty different versions, including the team's working English translations, which were
      changing week to week. Parabola was indispensible.
 -->

   <!-- Nota bene:
      * This application has many fine-tuned configuration options. Read through the whole file
      to see what is available.
      * This application processes a single work, assumed to be that of the first <source> in the
      catalyzing TAN-A file. If you want a different source, move the relevant <source> to the first
      position.
   -->

   <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED -->
   <!-- * Simplify the routine. This was converted from an inferior workflow, and still takes too many
      passes to get to the output. 
      * Annotations need a lot of work. They should be placed into the merge early. In fact, the whole
      workflow needs to be revised, with most structural work finished before attempting to convert to
      HTML. 
      * Develop output option using nested HTML divs, to parallel the existing output that uses HTML
      tables 
      * Integrate diff/collate into cells, on both the global and local level. 
      * Develop the css bar to allow users to click source id labels on and off. 
      * Add labels for divs higher than version wrappers. 
      * Consider merging based upon the resolved file, not its expansion. -->
   
   <!-- PARAMETERS -->

   <!-- Any parameter below whose name begins "tan:" is a global parameter. It is repeated here from
      the master location in the parameters subdirectory, because one commonly wishes to adjust them
      for this particular application. -->

   <!-- STEP 1: PICK, PRUNE, AND ARRANGE THE SOURCES -->

   <!-- Which sources do you want? Expected is a regular expression, matching against the
      @xml:id of a <source>. If blank, every source for the work will be fetched. -->
   <xsl:param name="src-ids-must-match-regex" as="xs:string?"/>
   <!-- Which sources do you want to exclude? Expected is a regular expression, matching against the
      @xml:id of a <source>. If blank, every source for the work will be fetched. -->
   <xsl:param name="src-ids-must-not-match-regex" as="xs:string?"/>
   <!-- Which language versions do you want? Expected is a regular expression, matching
      against the @xml:lang of the <body>. If blank, no sources will be excluded. -->
   <xsl:param name="main-langs-must-match-regex" as="xs:string?"/>
   <!-- Which language versions do you want to exclude? Expected is a regular expression, matching
      against the @xml:lang of the <body>. If blank, no sources will be excluded. -->
   <xsl:param name="main-langs-must-not-match-regex" as="xs:string?"/>

   <!-- Selective removal of source content. -->
   <!-- For the following parameters, you may find the process more efficient if you use <adjustments> 
      in the TAN-A file -->

   <!-- Which <div>s do you want? Expected is a regular expression, matching the @type of every
      <div> in each selected source. If blank, no <div>s will be excluded. -->
   <xsl:param name="div-types-must-match-regex" as="xs:string?"/>
   <!-- Which <div>s do you want to exclude? Expected is a regular expression, matching the @type 
      of every <div> in each selected source. If blank, no <div>s will be excluded. -->
   <xsl:param name="div-types-must-not-match-regex" as="xs:string?"/>
   <!-- Which top-level <div>s do you want? Expected is a regular expression, matching the @n of 
      every <div> child of <body> in each selected source. If blank, no <div>s will be excluded. -->
   <xsl:param name="level-1-div-ns-must-match-regex" as="xs:string?"/>
   <!-- Which top-level <div>s do you want to exclude? Expected is a regular expression, matching 
      the @n of every <div> child of <body> in each selected source. If blank, no <div>s will be 
      excluded. -->
   <xsl:param name="level-1-div-ns-must-not-match-regex" as="xs:string?"/>
   <!-- Which leaf divs do you want? Expected is a regular expression, matching any calculated 
      ref of every leaf <div> in each selected source. If blank, no leaf <div>s will be excluded. -->
   <xsl:param name="leaf-div-refs-must-match-regex" as="xs:string?"/>
   <!-- Which leaf divs do you want to exclude? Expected is a regular expression, matching any 
      calculated ref of every leaf <div> in each selected source. If blank, no leaf <div>s will 
      be excluded. -->
   <xsl:param name="leaf-div-refs-must-not-match-regex" as="xs:string?"/>
   <!-- Do you want to exclude any leaf divs that do not have a certain number of counterparts
      in the other versions? Anything 1 or below will be ignored. -->
   <xsl:param name="leaf-div-must-have-at-least-how-many-versions" as="xs:integer?" select="()"/>

   <!-- Should the process terminate if there are fewer than two sources? -->
   <xsl:param name="terminate-if-fewer-than-two-sources" as="xs:boolean" select="true()"/>

   <!-- The following parameter is very important, allowing you to pick an <alias> that should be
      used to build sequences and groups of sources. An <alias> may point to other <alias>es that
      allow you to create nested sorted groups. The result is an alias tree, with sources in 
      nested groups, and re-sorted. -->

   <!-- What sequence of alias idrefs should be used to group and sort sources? If an alias is
      not pointed to, the ordinary sequence of <source>s will be adopted, treated as a single
      flat group. -->
   <xsl:param name="sort-and-group-by-what-alias-idrefs" as="xs:string*"
      select="tokenize(/*/tan:head/tan:vocabulary-key/tan:alias[1]/@idrefs, '\s+')"/>
   <!-- If, when grouping and sorting by aliases, should every source encountered be treated as 
      belonging to the primary work, regardless of whether its <work> declaration says it is? 
      This is useful for including things like commentaries, which may follow the primary reference 
      system but be defined as a different work. -->
   <xsl:param name="let-alias-groups-equate-works" as="xs:boolean" select="true()"/>




   <!-- STEP TWO: EXCLUDE, INCLUDE, OR ADJUST MERGE INPUT -->

   <!-- Many of these parameters add, remove, or change content from the output of 
      tan:merge-expanded-docs(). That function has extensive commentary on what happens when one 
      merges multiple class 1 documents. See ../../functions/merging/TAN-fn-merging.xsl
         In general, the result has one <head> per merged source, and the <body> consists of a 
      superstructure of <div>s that reconcile all the competing systems. All that remains of 
      the source text are their leaf <div>s, which are placed in the appropriate part of the
      superstructure as children <div>s with types marked as "#version."
         The parameters below allow you to make major adjustments to the merge results before they
      are converted to HTML. Once a component is removed, it will not be available in the HTML file. 
      If you are not certain about whether to remove a component, consider keeping it. Hiding or 
      changing content can be accomplished later via CSS or JavaScript invoked by the output HTML file. 
      You can add content in CSS and JavaScript as well, but that can be a real chore, relative to XSLT, 
      so it is recommended that you delete content only if you really think it is unnecessary. On the
      other hand, in some HTML files where absolutely no TAN components have been dropped, writing 
      good CSS can be a challenge, so preliminary elimination can be very useful.
         You may need to set up copies of this file for different situations, or configure Oxygen 
      transformation secnarios. It can be difficult to make a firm decision on whether a section of text 
      should be labeled by @n, by ref, or some other text, because needs changes from situation to 
      situation. 
   -->

   <!-- Source adjustments -->

   <!-- Keep in mind, you may be working with work versions that adopt different conventions for @n. A
      merge file reconciles all detectable numerical schemes to Arabic numerals, and strings are retained
      as-is. This applies not only to @n but calculated ref values (which concatenate @n of any div and
      its ancestors). -->

   <!-- What levels in the hierarchy should have numeral types converted to letters? Any non-positive 
      integers will be ignored. -->
   <xsl:param name="levels-to-convert-to-aaa" as="xs:integer*" select="()"/>
   <!-- Should any <ref> that is a child of <div> be suppressed? This affects the merge structure, not
      individual versions within any given leaf merge group (versions), on which see below. -->
   <xsl:param name="suppress-refs" as="xs:boolean?" select="false()"/>
   <!-- Should any <ref> that is a child of a <div> that is a version be suppressed? -->
   <xsl:param name="suppress-version-refs" as="xs:boolean?" select="true()"/>
   <!-- Should any <n> that is a child of <div> be suppressed? -->
   <xsl:param name="suppress-ns" as="xs:boolean?" select="false()"/>
   <!-- Should a <display-n> be added to a <div>, reflecting either the original n (if present) or the 
      calculated n? -->
   <xsl:param name="add-display-n" as="xs:boolean" select="false()"/>
   <!-- Should the most common value for @type (div type) be added to a display n? -->
   <xsl:param name="add-div-type-to-display-n" as="xs:boolean" select="true()"/>


   <!-- Should any references to vocabulary items (by idref or by name) be supplemented with the 
      actual IRI + name vocabulary? Note, this can lead to much larger files, since every <div> @type will
      include IRI + name vocabulary. Such information can be filtered and controlled by CSS. -->
   <xsl:param name="tan:distribute-vocabulary" as="xs:boolean" select="false()"/>

   <!-- Merge anomalies -->

   <!-- If a merge has defective leaf divs (those that do not have every source) should they be filled 
      with a filler place-holder? -->
   <xsl:param name="fill-defective-merges" as="xs:boolean" select="true()"/>
   <!-- If a <div> has multiple numeric values of @n it will be distributed across the merge in the 
      raw XML version of the merge. What should happen to such a <div> that spans multiple merge points?
      Should every copy be left as-is? If not (false), then only one copy will be retained. See next 
      parameter. -->
   <xsl:param name="preserve-distributed-copies-of-divs" as="xs:boolean" select="false()"/>
   <!-- If copied <div>s are not to be preserved, should the one copy that remains be reallocated 
      proportionally across its copied parts? If not (false), only the first copy will be retained 
      and the other copied divs will be emptied of content. -->
   <xsl:param name="proportionately-reallocate-copied-divs" as="xs:boolean" select="true()"/>
   <!-- Should a leaf div with multiple numerical values be retained in whole at the first reference, or 
      should it be proportionately distributed? -->
   <xsl:param name="distribute-spanning-divs-proportionately" as="xs:boolean" select="true()"/>



   <!-- TEI adjustments -->

   <!-- Do you want to ignore internal TEI markup and treat it as plain text? -->
   <xsl:param name="tei-should-be-plain-text" as="xs:boolean" select="false()"/>
   <!-- Do you wish to omit any TEI elements that have no text nodes? If false, the output may include 
      text or other items that break up the main text, making searching difficult. -->
   <xsl:param name="omit-tei-elements-without-text" as="xs:boolean"
      select="$tei-should-be-plain-text"/>

   <!-- Some TEI elements are of variable interest in the output. You may want to signal that a particular
      element is available, but hide it with some siglum that the user can click to get more details. -->

   <!-- What replacement character should mark a TEI <app> that has no lemma? -->
   <xsl:param name="marker-for-tei-app-without-lem" as="xs:string?">+</xsl:param>
   <!-- What replacement character should mark a TEI <note>? -->
   <xsl:param name="tei-note-signal-default" as="xs:string?">n</xsl:param>
   <!-- What replacement character should mark a TEI <add>? -->
   <xsl:param name="tei-add-signal-default" as="xs:string?">+</xsl:param>


   <!-- TAN-A components -->

   <!-- Should TAN-A adjustment actions be suppressed in the results? -->
   <xsl:param name="suppress-display-of-adjustment-actions" select="false()"/>
   <!-- Do you wish to convert leaf-div TEI items to plain text? If false, the display will be populated 
      with TEI elements instead of plain text, but this may result in unexpected appearance of the HTML.
      Normally this can be attended to through CSS. -->

   <!-- What batch replacements should be applied to claim components? Batch replacements are a sequence of
      elements (any name), each with @pattern, @replacement, and perhaps @flags and @message. The
      attributes imitate the behavior of fn:replace(). -->
   <xsl:param name="claim-component-batch-replacements" as="element()*"/>





   <!-- STEP THREE: ADJUST THE HTML OUTPUT -->


   <!-- Where is the HTML template that should be used as the basis for the output? Expected: a 
      resolved uri, e.g., file:/c:/users/~user/documents/my-template.html -->
   <xsl:param name="html-template-uri-resolved" select="$tan:default-html-template-uri-resolved"/>

   <!-- What is the preferred title to put in the HTML page? If no value is supplied, head/name[1] 
      will be used. -->
   <xsl:param name="preferred-html-title" as="xs:string?"/>
   <!-- What is the preferred subtitle to put in the HTML page? -->
   <xsl:param name="preferred-html-subtitle" as="xs:string?" select="'Parallel reading edition'"/>
   <!-- What introductory material should be supplied after the title/subtitle? Can be text, html, 
      among other things. -->
   <xsl:param name="introductory-text" as="item()*"/>
   <!-- Should a bibliography be added? If true, there will be a section inserted collecting
      information on the publications behind the sources. -->
   <xsl:param name="add-bibliography" as="xs:boolean" select="false()"/>

   <!-- Should controller options be added? The controller will let users toggle TEI features on and off,
      or change the width. -->
   <xsl:param name="add-display-options" as="xs:boolean" select="true()"/>
   <!-- Each cluster of versions needs to be rendered in some fashion. Should it be via <div>s that will 
      later be styled (true), or via <table>? The advantage to the latter is the possibility of using 
      @rowspan and @colspan. -->
   <xsl:param name="tables-via-css" as="xs:boolean" select="false()"/>
   <!-- If aligning leaf divs through tables, should the table layout be fixed? -->
   <xsl:param name="table-layout-fixed" as="xs:boolean" select="false()"/>
   <!-- Should the relative width of each <td> be determined according to string length? If not, no
      width will be specified, and CSS must be used to set the width of columns. -->
   <xsl:param name="calculate-width-at-td-or-leaf-div-level" as="xs:boolean" select="false()"/>
   <!-- What elements should be given the CSS class 'hidden'? Expected: a regular expression
      matching an element name. This does not override any other parameter, and does not mean
      that the element in question will actually be hidden. That is up to the CSS -->
   <xsl:param name="elements-to-be-given-class-hidden-regex" as="xs:string?"/>

   <!-- What special insertions if any should be made into the output HTML? Expected are a series of 
      elements with attributes @before-ref or @after-ref. Anything inside those elements will be inserted 
      either before or after a <div> with a matching reference. Ideally, what's inside should be HTML, 
      but it doesn't have to be. -->
   <xsl:param name="ad-hoc-insertions" as="element()*">
      <!--<tan:insertion before-ref="2">
         <h2>Chapter...</h2>
      </tan:insertion>-->
   </xsl:param>


   <!-- When converting the merge to HTML, the process is a simple, straightforward conversion until
      reaching a place in the merge superstructure where the next level deeper has one or more versions.
      At that point we have a leaf merge, which will certain have leaf divs from one or more versions,
      but may include some versions that go deeper (they aren't leaf divs yet). Nevertheless, for
      comparison sake, the *leaf merge* not the leaf divs are the key factor in building the HTML file. -->

   <!-- What class name should be applied to a <div> that wraps a leaf merge? -->
   <xsl:param name="version-wrapper-class-name" select="'version-wrapper'"/>

   <!-- string differences -->
   <!-- For other related parameters, see:
      ../../parameters/params-function-diff.xsl
      ../../parameters/params-application-diff.xsl -->

   <!-- In a group within a leaf merge, tan:diff() and tan:collate() can be turned on. If the versions are close
      enough to each other, they will be collapsed into a single reading that shows through markup where
      each version differs from the others. This is a very powerful benefit for comparative reading,
      because it lets readers see exactly where versions differ from each other. But because intermingled
      text illustrating differences breaks up words and phrases, it interferes with browser-based
      searches, one of the more important utilities of this output format. So if you prioritize text
      searches over reading, do not turn on the diff/collate. -->

   <!-- How similar should a group of versions in a div be before they are rendered as a difference or collation?
      Anything other than a number between 0 and 1 will be ignored. If the aggregate difference of a
      group of versions is less than the decimal provided, no diff/collate will be substituted. -->
   <xsl:param name="render-as-diff-threshhold" as="xs:decimal?" select="0.6"/>
   <!-- What text differences should be ignored when compiling difference statistics? These are built 
      into a series of elements that group <c>s, e.g. <alias><c>'</c><c>"</c></alias> would, for 
      statistical purposes, ignore differences merely of a single apostrophe and quotation mark. 
      This affects only statistics. The difference would still be visible in the diff/collation. -->
   <xsl:param name="unimportant-change-character-aliases" as="element()*"/>
   <!-- Should diffs be rendered word-for-word (true) or character-for-character? -->
   <xsl:param name="tan:snap-to-word" as="xs:boolean" select="true()"/>
   <!-- A diff or collation must give visual priority to one of the versions. Should the first version be
      given that focus? If false, then the last version will be chosen. -->
   <xsl:param name="first-version-is-of-primary-interest" as="xs:boolean" select="true()"/>
   <!-- Should Venn diagrams be inserted for collations of 3 or more versions? If true, processing will 
      take longer, and the HTML file will be larger. -->
   <xsl:param name="include-venns" as="xs:boolean" select="false()"/>


   <!-- Should the width of each <td> be fixed according to their number? This will create even columns, but
      perhaps leave large gaps where versions are short or missing. -->
   <xsl:param name="td-widths-proportionate-to-td-count" as="xs:boolean" select="false()"/>
   <!-- Should the width of each <td> be fixed according to string length? This will create uneven columns, 
      but balance space. Normally this can be handled by the browser via CSS. -->
   <xsl:param name="td-widths-proportionate-to-string-length" as="xs:boolean" select="false()"/>


   <!-- Should color schemes for sources and their groups be imprinted in the HTML file? If false, then 
      color will be determined according to any external CSS files. -->
   <xsl:param name="imprint-color-css" as="xs:boolean" select="true()"/>

   <!-- If the preceding parameter is true, then the following five parameters have force; if false, they are
      ignored.
         The color schemes below are based upon array. The primary color array will be used to allocate
      colors in the topmost groups. Groups inside, from the second tier down, will take the inherited
      color and blend it with the appropriate item from the secondary color array. At the very end, when
      colors are assigned to individual sources, the terminal color array will be applied. In each array,
      the second item will be applied first.
         Note, three of these parameters are arrays, which are special data constructions introduced to
      XPath and XSLT.
 -->

   <!-- What should the primary color scheme be? The primary color array refers to the background
      color that will be applied to first group of sources. Expected: an array, each member consisting of
      three integers from 0 through 255, e.g., [(0,0,0), (255,255,255)], representing red, green, blue
      values. If the parameter points to variables of whose names begin tan:ryb- note that these too are
      red, green, blue integer sequences, but they summon one of the twelve colors made from the three
      primary colors (red, yellow, blue), the three secondary colors (orange, green, purple), and the
      mixture of adjacent primary and secondary colors. -->
   <xsl:param name="primary-color-array" as="array(xs:integer+)"
      select="[$tan:ryb-red, $tan:ryb-red-orange, $tan:ryb-orange, $tan:ryb-yellow-orange, $tan:ryb-yellow, $tan:ryb-yellow-green, $tan:ryb-green, $tan:ryb-blue-green, $tan:ryb-blue, $tan:ryb-blue-purple, $tan:ryb-purple, $tan:ryb-red-purple]"/>
   <!-- What should the secondary color scheme be? The secondary color array refers to the background
      color that will be applied to groups of sources after the first. Expected: an array, each member
      consisting of three integers from 0 through 255. -->
   <xsl:param name="secondary-color-array" as="array(xs:integer+)"
      select="[$tan:ryb-yellow-green, $tan:ryb-green, $tan:ryb-blue-green, $tan:ryb-blue, $tan:ryb-blue-purple, $tan:ryb-purple, $tan:ryb-red-purple, $tan:ryb-red, $tan:ryb-red-orange, $tan:ryb-orange, $tan:ryb-yellow-orange, $tan:ryb-yellow]"/>
   <!-- What should the terminal color scheme be? The terminal color scheme refers to the background
      color that will be applied to versions of texts within a final group of sources. Expected: an
      array, each member consisting of three integers from 0 through 255 and a fourth that is a decimal
      between 0 and 1 (opacity). -->
   <xsl:param name="terminal-color-array" as="array(xs:double+)"
      select="[$tan:white-mask-a70, $tan:white-mask-a60, $tan:white-mask-a50, $tan:white-mask-a40, $tan:white-mask-a30, $tan:white-mask-a20, $tan:white-mask-a10]"/>

   <!-- When two colors are blended, what midpoint should be adopted? Should be a decimal between 0 and 1.
      A value less than 0.5 will give greater emphasis to the first color. -->
   <xsl:param name="color-blend-midpoint" select="0.4" as="xs:decimal"/>



   <!-- For what directory is the output intended? This is important to reconcile any relative
      links. -->
   <xsl:param name="output-directory-uri" as="xs:string"
      select="$tan:default-output-directory-resolved"/>




   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/Parabola%20core.xsl"/>
   <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
   <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>

</xsl:stylesheet>
