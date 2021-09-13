<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Welcome to TAN Out, the TAN application that exports TAN / TEI files -->
   <!-- Version 2021-09-06 -->
   <!-- This utility exports a TAN or TEI file to other media. Currently only HTML is supported, optimized
      for JavaScript and CSS within the output/js and output/css directories in the TAN file structure. -->

   <!-- This utility quickly renders a TAN or TEI file as HTML. It has been optimized for JavaScript and CSS
      within the output/js and output/css in the TAN file structure. -->

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

   <!-- Primary input: any TAN or TEI file -->
   <!-- Secondary input: none -->
   <!-- Primary output: if no destination filename is specified, an HTML file -->
   <!-- Secondary output: if a destination filename is specified, an HTML file at the target location -->

   <!-- Nota bene:
      * This application can be used to generate primary or secondary output, depending upon how
      parameters are configured (see below).
   -->
   
   <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED -->
   <!-- * Need to wholly overhaul the default CSS and JavaScript files in output/css and output/js 
      * Need to build parameters to allow users to drop elements from the HTML DOM.
      * Need to enrich output message with parameter settings.
      * Need to support export to odt. 
      * Need to support export to docx. 
      * Need to support export to plain text.
   -->
   

   <!-- PARAMETERS -->
   
   <!-- INPUT ADJUSTMENT -->
   
   <!-- In what state would you like the TAN/TEI file rendered? Options: 'raw', 'resolved', 
      or 'expanded'. If the value is not recognized 'raw' will be used. -->
   <xsl:param name="TAN-file-state" as="xs:string?" select="'raw'"/>
   
   <!-- If rendering an expanded TAN/TEI file, what level of expansion do you want? Options: 'terse',
      'normal', 'verbose'. -->
   <xsl:param name="tan:validation-phase" select="'terse'"/>
   
   <!-- Do you want to treat the file as if being validated or not? This does not affect either a raw
      or a resolved file, but it will affect the expanded file. In validation mode, only errors 
      are returned. -->
   <xsl:param name="tan:validation-mode-on" as="xs:boolean" select="false()"/>
   
   
   <!-- OUTPUT -->
   
   <!-- Where is the HTML file that should be used as a template for the output? -->
   <xsl:param name="html-template-uri-resolved" select="$tan:default-html-template-uri-resolved"/>
   
   
   <!-- Should the file be sent through a preparatory stage before being converted to HTML? If true,
      then tan:prepare-to-convert-to-html() will be invoked, which relies extensively upon the
        global parameters specified at ../../parameters/params-application-html-output.xsl -->
   <xsl:param name="use-function-prepare-to-convert-to-html" as="xs:boolean" select="true()"/>
   
   <!-- Should any hrefs in the text of the source file be converted to hyperlinks in the output? -->
   <xsl:param name="parse-text-for-urls" as="xs:boolean" select="true()"/>
   
   <!-- Where specifically do you want the output inserted? Expected is a string naming the @id value 
      of some HTML element in the template. If this value is missing or is a zero-length string,
      then the content will be inserted as the first child of the HTML template document's <body> -->
   <xsl:param name="target-id-for-html-content" as="xs:string?"/>
   
   
   <!-- For what directory is the output intended? This is important to reconcile any relative
      links. If you provide a relative path, that path will be resolved relative to the location
      of this application file. -->
   <xsl:param name="output-directory-uri" as="xs:string"
      select="$tan:default-output-directory-resolved"/>
   
   
   <!-- What should be the local name of the output file? If this value is null, empty, or only
      space, then the HTML file will be returned as primary output, and it is up to the user to 
      direct it to the proper location. Otherwise it is appended to the value of 
      $output-directory-uri (see above) and returned as secondary output in that location. -->
   <xsl:param name="output-target-filename" as="xs:string?"/>
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/TAN%20Out%20core.xsl"/>
   <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
   <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>
   
</xsl:stylesheet>
