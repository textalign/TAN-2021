<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" exclude-result-prefixes="#all" version="3.0">

   <!-- The parameters in this file are to be used in the core validation function files. -->

   <!-- What string in an attribute value should be interpreted as a request for help? -->
   <xsl:param name="tan:help-trigger" select="'???'"/>
   
   <!-- How many loops should be tolerated in a recursive function before exiting? -->
   <xsl:param name="tan:loop-tolerance" as="xs:integer" select="550"/>
   
   <!-- Should validation routines avoid checking non-local files (those available only on the Internet)? -->
   <xsl:param name="tan:do-not-access-internet" as="xs:boolean" select="false()"/>
   
   <!-- What should the default whitespace indentation value be? -->
   <xsl:param name="tan:default-indent-value" select="3"/>
   
   <!-- During expansion, should every value for every attribute that points to a vocabulary item 
      have the vocabulary imprinted with the value? This is used primarily in non-validation applications, 
      where immediate, quick access to the vocabulary is required. Caution: setting this value to true may 
      result in very large files. -->
   <xsl:param name="tan:distribute-vocabulary" select="false() and $tan:validation-mode-on"/>
   
   <!-- If an item is invalid, what is the maximum number of suggestions that should be offered? -->
   <xsl:param name="tan:help-suggestions-maximum" select="50"/>
   
   <!-- If providing textual context in an error or help, what is the maximum number of characters that 
      should be returned? If a text has more characters than this number, then it will be truncated, with
      the omitted text replaced by ellipses. -->
   <xsl:param name="tan:validation-context-string-length-max" as="xs:integer" select="50"/>
   
   <!-- Should any elided text (see above) be replaced with a number indicating how many characters have 
      been elided? -->
   <xsl:param name="tan:validation-context-supply-length-of-elision" as="xs:boolean" select="true()"/>
   
</xsl:stylesheet>
