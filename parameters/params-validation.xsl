<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" exclude-result-prefixes="#all" version="3.0">

   <!-- Use the parameters in this file to configure Schematron validation. -->

   <!-- What string in an attribute value should be interpreted as a request for help? -->
   <xsl:param name="tan:help-trigger" select="'???'"/>
   
   <!-- How many loops should be tolerated in a recursive function before exiting? -->
   <xsl:param name="tan:loop-tolerance" as="xs:integer" select="550"/>
   
   <!-- Should validation routines avoid checking non-local files (those available only on the Internet)? -->
   <xsl:param name="tan:do-not-access-internet" as="xs:boolean" select="false()"/>
   
   <!-- What should the default whitespace indentation value be? This value primarily affects
      tree fragments that are inserted via Schematron Quick Fixes, when the local indentation
      cannot be easily detected.
   -->
   <xsl:param name="tan:default-indent-value" select="3"/>
   
   <!-- If an item is invalid, what is the maximum number of suggestions that should be offered? -->
   <xsl:param name="tan:help-suggestions-maximum" select="50"/>
   
   <!-- If providing textual context in an error or help, what is the maximum number of characters that 
      should be returned? If a text has more characters than this number, then it will be truncated, with
      the omitted text replaced by ellipses. -->
   <xsl:param name="tan:validation-context-string-length-max" as="xs:integer" select="50"/>
   
   <!-- Should any elided text in the validation context (see above) be replaced with a number indicating 
      how many characters have been elided? -->
   <xsl:param name="tan:validation-context-supply-length-of-elision" as="xs:boolean" select="true()"/>
   
   <!-- Long files can be time-consuming to validate. What is the maximum number of siblings that should
      be validated? The default value below finds the declaration of the Schematron validation file,
      and looks for a pseudo-parameter called truncate. That allows you to control truncation directly
      within a file. This setting affects only the immediate children of a file's <body>.
   -->
   <xsl:param name="tan:validation-truncation-point" as="xs:integer?">
      <xsl:analyze-string select="/processing-instruction()[matches(., 'schematron')]" regex="truncate=.(\d+)">
         <xsl:matching-substring>
            <xsl:sequence select="regex-group(1) => xs:integer()"/>
         </xsl:matching-substring>
      </xsl:analyze-string>
   </xsl:param>
   
</xsl:stylesheet>
