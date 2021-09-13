<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="3.0">

   <!-- TAN Function Library extended boolean functions. -->
   
   <xsl:function name="tan:true" as="xs:boolean*" visibility="public">
      <!-- Input: a sequence of strings representing truth values -->
      <!-- Output: the same number of booleans; if the string is some approximation 
         of y, yes, 1, or true, then it is true, and false otherwise -->
      <!-- kw: binary, booleans -->
      <xsl:param name="string" as="xs:string*"/>
      <xsl:for-each select="$string">
         <xsl:choose>
            <xsl:when test="matches(., '^(y(es)?|1|t(rue)?)$', 'i')">
               <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:when test="matches(., '^(n(o)?|0|f(alse)?)$', 'i')">
               <xsl:value-of select="false()"/>
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>
