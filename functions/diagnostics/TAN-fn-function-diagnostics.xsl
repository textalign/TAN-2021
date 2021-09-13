<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- TAN Function Library diagnostic functions on the TAN Function Library itself. -->
   
   <!-- This is a special set of functions for evaluating the TAN functions themselves -->
   
   <xsl:variable name="tan:function-collection" select="doc('../collection.xml')" as="document-node()"/>
   <xsl:variable name="tan:function-collection-base-uri" select="base-uri($tan:function-collection)" as="xs:anyURI"/>
   
   <xsl:variable name="tan:all-functions" select="
         for $i in $tan:function-collection/collection/doc/@href,
            $j in resolve-uri($i, $tan:function-collection-base-uri)
         return
            if (doc-available($j)) then
               doc($j)
            else
               ()" as="document-node()+"/>
   
   <xsl:function name="tan:errors-checked-where" as="element()*" visibility="private">
      <!-- Input: error ids -->
      <!-- Output: the top-level templates, stylesheets, and variables that use that error code -->
      <!-- Used primarily by schematron validation for TAN-errors.xml -->
      <xsl:param name="error-ids" as="xs:string*"/>
      <xsl:variable name="error-id-regex"
         select="'[' || $tan:quot || $tan:apos || '](' || string-join($error-ids, '|') || ')'"/>
      <xsl:sequence select="$tan:all-functions//*[matches(@select, $error-id-regex)]"/>
   </xsl:function>
   
   <xsl:function name="tan:variables-checked-where" as="element()*" visibility="private">
      <!-- Input: name of a variable -->
      <!-- Output: the top-level templates, stylesheets, and variables that use that error code -->
      <!-- Used primarily by schematron validation for TAN-errors.xml -->
      <xsl:param name="error-ids" as="xs:string*"/>
      <xsl:variable name="error-id-regex"
         select="'[' || $tan:quot || $tan:apos || '](' || string-join($error-ids, '|') || ')'"/>
      <xsl:sequence
         select="$tan:all-functions//*[matches(@select, $error-id-regex)]/ancestor::*[last() - 1]"/>
   </xsl:function>
   
</xsl:stylesheet>
