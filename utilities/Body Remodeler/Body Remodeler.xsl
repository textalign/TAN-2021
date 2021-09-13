<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to Body Remodeler, the TAN application that remodels a text to resemble the
      existing div structure of the body of a TAN-T text-->
   
   <!-- Suppose you have a text in a well-structured TAN-T file, and you want to use it to model
      the structure of another version of that same work. This application will take the input, and
      infuse the text into the structure of the model, using the proportionate lengths of the
      model's text as a guide where to break the new text. Any two versions of a single work,
      particularly translations, paraphrases, and other versions, rarely correlate. A translator
      may begin a work being relatively verbose, and become more economical in later parts. Such
      uneven correlation means that one-to-one modeling is not a good strategy for aligning the new
      text. Rather, one should start with the topmost structures and working progressively toward
      the smallest levels. Body Remodeler supports such an incremental approach, and allows you to
      restrict the remodeling activity to certain parts of a text. When used in tandem with the TAN
      editing tools for Oxygen, which allow you to push and pull words, clauses, and sentences from
      one leaf div to another, you will find that Body Builder can save you hours of editorial
      work.-->
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
   <!-- Primary input: preferably a TAN-T or TAN-TEI file -->
   <!-- Secondary input: a TAN-T or TAN-TEI file that has model div and reference system -->
   <!-- Primary output: the model, with its div structure intact, but the text replaced with the text of the
      input, allocated to the new div structure proportionate to the model's text length -->
   <!-- Secondary output: none -->

   <!-- Nota bene:
      * If the catalyzing input file is not a class-1 file, but just an XML file, it will be read
      for its string value. The output will be a copy of the model with the string proportionately
      allocated to its body components.
      * If you remodel a set of sibling leaf divs but exclude certain intervening leaf divs from 
      being remodeled, the entire remodel will be placed at the location of the first leaf div only. 
      That is, that area of the remodel will be consolidated, and the text will no longer
      reflect the original order. 
      * Because this application produces TAN output, metadata will be supplied to the output, along
      with a change entry, crediting/blaming the application.
      * Comparison is made with the model on the basis of resolved, not expanded, class 1 files, and
      any matches involving @n or @n-built references will be on the basis of resolved numerals. 
      * Although the model can be a TAN-TEI file, refining the output will not be possible using 
      the TAN Oxygen editor tools, because pushing a word, clause, or sentence from one leaf div to
      another will inevitably require splitting and rejoining the host elements. Such a utility is
      possible, but would require resources for development. 
   -->
   
   <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED -->
   <!-- * Support the complete-the-square method (model has a redivision that matches the input's div 
      structure) 
      * Test, troubleshoot against various TEI models -->
   
   <!-- STRATEGIES FOR USE -->
   <!-- Method: gentle increments -->
   <!-- Use this method in tandem with the TAN editing tools in Oxygen, where you can easily push and 
    pull entire words, clauses, and sentences from one leaf div to another. When you are editing 
    (##2, 5), place the model in a parallel window.
    --> 
   <!-- 
    1. Run plain text against the model.
    2. Edit the output, focusing only on getting the top-level divisions correct.
    3. Change the parameter $preserve-matching-ref-structures-up-to-what-level to 1.
    4. Run the edited input against the model again. Your top-level divisions should remain intact.
    5. Edit the output, focusing only on getting the 2nd-level divisions correct.
    6. Repeat ##3-5 through the rest of the hierarchy. -->


   <!-- Working with non-XML input: You might have text from some non-XML source that you want to feed
      into this method. If you can get down to the plain text, put it into any XML file, and run it
      through this application, changing the parameter $model-uri-relative-to-catalyzing-input to specify
      exactly where the model is. You'll get the model with the text infused. It will need a lot of
      metadata editing, but at least you'll have a good start for structuring the body. -->
   

   <!-- PARAMETERS -->
   
   <!-- STEP 1: THE MODEL -->
   
   <!-- Where is the model relative to the catalyzing input? Default is the @href for the first <model>
      within the input file. -->
   <xsl:param name="model-uri-relative-to-catalyzing-input" as="xs:string?"
      select="tan:first-loc-available(/*/tan:head/tan:model[1])"/>
   
   <!-- What top-level divs should be excluded (kept intact) from the input? Expected: a regular expression
      matching @n. If blank, this has no effect. -->
   <xsl:param name="exclude-from-model-top-level-divs-with-attr-n-values-regex" as="xs:string?" select="''"/>
   
   <!-- What div types should be excluded from the remodel? Expected: a regular expression matching @type.
      If blank, this has no effect. -->
   <xsl:param name="exclude-from-model-divs-with-attr-type-values-regex" as="xs:string?" select="''"/>
   
   
   <!-- STEP 2: THE INPUT -->

   <!-- Many of the following parameters assume input of a class-1 file. -->

   <!-- What top-level divs should be excluded (preserved intact) from the remodeling? Expected: a 
      regular expression matching @n. If blank, this has no effect. -->
   <xsl:param name="exclude-from-input-top-level-divs-with-attr-n-values-regex" as="xs:string?" select="''"/>
   
   <!-- What div types should be excluded from the remodel? Expected: a regular expression matching @type. 
      If blank, this has no effect. -->
   <xsl:param name="exclude-from-input-divs-with-attr-type-values-regex" as="xs:string?" select="''"/>
   
   <!-- At what level should remodeling begin? By setting this value to 1 or greater, you will 
      preserve existing <div> structures, and remodeling will occur starting only at the next tier
      deeper. At the first acceptable level, remodeling will be performed in concert with <div>s
      in the model whose ref value matches the current input <div>s calculated ref value (where a
      <div>s ref value are all the permutations of combining the values of @ns in itself and all its
      ancestors). If there is no corresponding match in the model, that div will be deep copied, and
      rendered exempt from the remodelling. This feature is extremely helpful for incremental modeling,
      e.g., where a class 1 file preserves only the topmost hierarchy of its model, and needs to be 
      subdivide further, or where a class 1 file needs to be recalibrated but only at a certain depth. -->
   <xsl:param name="preserve-matching-ref-structures-up-to-what-level" as="xs:integer?" select="0"/>
   
   <!-- Does the model have a material (scriptum-oriented) reference system or a logical one? -->
   <xsl:param name="model-has-scriptum-oriented-reference-system" as="xs:boolean" select="true()"/>
   
   <!-- What regular expression should be used to decide where breaks are allowed if the model has 
      a scriptum-based structure? -->
   <xsl:param name="break-text-at-material-divs-regex" as="xs:string"
      select="$tan:word-end-regex"/>
   
   <!-- What regular expression should be used to decide where breaks are allowed if the model has a logical
      (non-scriptum) reference system? See parameters/params-application-language.xsl for parameters
      whose regular expressions could be used: sentence-end-regex will likely result in too rough an
      alignment; clause-end-regex is good for texts with ample punctuation; if a language makes use of
      word spaces, word-end-regex will prevent individual words from being divided. -->
   <xsl:param name="break-text-at-logical-divs-regex" as="xs:string" select="$tan:clause-end-regex"
   />
   
   <!-- If chopping up segments of text, should parenthetical clauses be preserved intact? -->
   <xsl:param name="do-not-chop-parenthetical-clauses" as="xs:boolean" select="false()"/>
   
   
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/Body%20Remodeler%20core.xsl"/>

</xsl:stylesheet>
