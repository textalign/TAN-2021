<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- Core global parameters for TAN applications. -->
   
   <!-- These parameters apply to both TAN applications and utilities. Not all settings below are used by
      every application/utility. -->
   
   <!-- START-OF-PROCESS PARAMETERS -->
   
   <!-- In some applications the main input is not the catalyzing initial input, but one or more other files.
      In such cases, one needs to start with one or more directories, then filter down by filename masks to 
      the files of interest. -->
   
   <!-- What directory or directories has the main input files? Any relative path will be calculated relative 
        to the master application file (i.e., not this parameter file). Multiple directories may be 
        supplied. Results can be filtered below. -->
   <xsl:param name="tan:main-input-relative-uri-directories" as="xs:string+"
      select="resolve-uri('../examples', static-base-uri())"/>
   
   <!-- What pattern must each input filename match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, only those whose names match this pattern will be included. A null 
        or empty string means ignore this parameter. -->
   <xsl:param name="tan:input-filenames-must-match-regex" as="xs:string?" select="''"/>
   
   <!-- What pattern must each filename NOT match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, any whose names match this pattern will be excluded. A null 
        or empty string means ignore this parameter. -->
   <xsl:param name="tan:input-filenames-must-not-match-regex" as="xs:string?" select="''"/>
   
   
   
   
   <!-- MID-PROCESS PARAMETERS -->

   <!-- During expansion, should every value for every attribute that points to a vocabulary item 
      have the vocabulary imprinted with the value? This is used primarily in non-validation applications, 
      where immediate, quick access to the vocabulary is required. Caution: setting this value to true may 
      result in very large files. -->
   <xsl:param name="tan:distribute-vocabulary" select="false()"/>
   
   <!-- If a file to be opened cannot be read as Unicode, what is the preferred default encoding that should be tried? -->
   <xsl:param name="tan:fallback-encoding" as="xs:string?" select="'cp1252'"/>
   
   <!-- Saving and retrieving intermediate steps -->

   <!-- Should select intermediate results be saved along the way? Note, this is a 
      static parameter, so that XSLT components can be added or removed as needed. -->
   <xsl:param name="tan:save-and-use-intermediate-steps" static="yes"
      select="false()" as="xs:boolean"/>

   <!-- Where should temporary files such as intermediate results be saved? -->
   <xsl:param name="tan:temporary-file-directory" as="xs:anyURI"
      select="resolve-uri('../output/temp', static-base-uri())"/>

   <!-- Shall error elements placed in TAN files during the validation process also be passed on messages? -->
   <xsl:param name="tan:error-messages-on" as="xs:boolean" select="false()"/>
   
   
   
   <!-- END-OF-PROCESS PARAMETERS -->

   <!-- What directory is the default for saving output? -->
   <xsl:param name="tan:default-output-directory-resolved" as="xs:string"
      select="resolve-uri('../output/', static-base-uri())"/>
   
   <!-- Where is the default TAN-T template? -->
   <xsl:param name="tan:default-tan-t-template-uri-resolved" as="xs:string" select="resolve-uri('../templates/template-tan-t.xml', static-base-uri())"/>
   
   <!-- Where is the default TAN-A-lm template? -->
   <xsl:param name="tan:default-tan-a-lm-template-uri-resolved" as="xs:string" select="resolve-uri('../templates/template-tan-a-lm.xml', static-base-uri())"/>
   
   <!-- Where is the default HTML template? -->
   <xsl:param name="tan:default-html-template-uri-resolved" as="xs:string" select="resolve-uri('../templates/template.html', static-base-uri())"/>

   <!-- What should be the default output method? May be overwritten by specific applications. -->
   <xsl:param name="tan:default-output-method" as="xs:string" select="'xml'"/>
   
   <!-- In any output do you wish top-level nodes to each appear on their own line? If false, then output may result in many nodes collapsed on line 1. -->
   <xsl:param name="tan:set-each-doc-node-on-new-line" as="xs:boolean" select="true()"/>
   
   
   
   

</xsl:stylesheet>
