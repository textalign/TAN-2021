<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Global parameters pertaining to TAN applications making use of tan:diff() and tan:collate(). 
      Not all parameters in this file will be used by a given TAN application. -->
   
   
   <!-- DIFF/COLLATE INPUT ADJUSTMENT -->

   <!-- Should punctuation be ignored? -->
   <xsl:param name="tan:ignore-punctuation-differences" as="xs:boolean" select="false()"/>
   
   <!-- Should texts be reduced to their string base when comparing them? E.g., should ö and o be treated 
        as identical? -->
   <xsl:param name="tan:ignore-character-component-differences" as="xs:boolean" select="false()"/>
   
   <!-- Should combining marks be ignored? -->
   <xsl:param name="tan:ignore-combining-marks" as="xs:boolean?" select="false()"/>
   
   <!-- Should differences in case be ignored? -->
   <xsl:param name="tan:ignore-case-differences" as="xs:boolean?" select="false()"/>
   
   
   <!-- DIFF/COLLATE STATISTICS -->
   
   <!-- Should Venn diagrams be inserted for collations of 3 or more versions? If true, processing will take 
      longer, and the HTML file will be larger. -->
   <xsl:param name="tan:include-venns" as="xs:boolean" select="false()"/>
   
   <!-- Adjustment of statistics -->
   
   <!-- What text differences should be ignored when compiling difference statistics? Example, [\r\n] ignores 
      any deleted or inserted line endings, wherever found. Such differences will still be present
      in the output, but they will be ignored when calculating statistics. -->
   <xsl:variable name="tan:unimportant-change-regex" as="xs:string" select="'[\r\n]'"/>
   
   <!-- What combinations of differences should be ignored when compiling statistics? These must be 
      supplied as a series of elements that group <c>s. For example, <alias><c>'</c><c>"</c></alias> 
      would, for statistical purposes, ignore variations of a single apostrophe and quotation mark
      across all versions in the diff/compare. This affects only statistics. The original text will
      still be visible in the diff/collation. Unlike $tan:unimportant-change-regex, which ignores all
      characters matching a regular expression, whether in a <c> or <common> or in a <u>, <a>, or 
      <b>, this particular expression looks only at <u>, <a>, and <b>, and has effect only if every
      single u or a or b in a given cluster has one of the variations. Otherwise the characters are
      included in the statistics.
   -->
   <xsl:param name="tan:unimportant-change-character-aliases" as="element()*"/>
   
   
   

</xsl:stylesheet>
