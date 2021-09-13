<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library URIs read incognito -->
   
   <!-- This small file comes with the TAN function library, but is not included directly. It is 
      accessed through the tan:doc-available() function at TAN-fn-uris-extended via transform(), 
      intended to avoid I/O conflicts in case an application wishes to write to a file there. -->

   <xsl:function name="tan:doc-available" as="xs:boolean" visibility="private">
      <!-- Input: a string -->
      <!-- Output: true if an XML document is available at the URI, false otherwise -->
      <!-- This is a surrogate function to fn:doc-available, and behaves exactly the same, but avoids the possibility
         of read conflicts, so a file can be overwritten. -->
      <xsl:param name="uri" as="xs:string?"/>
      <xsl:sequence select="doc-available($uri)"/>
   </xsl:function>
   

</xsl:stylesheet>
