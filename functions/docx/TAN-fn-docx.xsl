<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:prop="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
   xmlns:ssh="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
   xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
   version="3.0">

   <!-- TAN Function Library docx functions. -->
   
   <xsl:function name="tan:docx-to-text" as="xs:string?" visibility="public">
      <!-- Input: docx component as document nodes -->
      <!-- Output: the string value of the component -->
      <!--kw: docx, files, strings, tree manipulation -->
      <xsl:param name="docx-component" as="item()*"/>
      <xsl:variable name="pass-1" as="xs:string*">
         <xsl:apply-templates select="$docx-component" mode="tan:archive-to-plain-text"/>
      </xsl:variable>
      <xsl:sequence select="string-join($pass-1)"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:archive-to-plain-text" on-no-match="text-only-copy"/>
   
   <xsl:template match="w:p" mode="tan:archive-to-plain-text">
      <xsl:apply-templates mode="#current"/>
      <xsl:text>&#xa;</xsl:text>
   </xsl:template>
   <xsl:template match="ssh:c[not(@t)]" mode="tan:archive-to-plain-text">
      <xsl:apply-templates mode="#current"/>
      <xsl:text>&#x9;</xsl:text>
   </xsl:template>
   <xsl:template match="w:tab" mode="tan:archive-to-plain-text">
      <xsl:text>&#x9;</xsl:text>
   </xsl:template>
   <xsl:template match="w:br" mode="tan:archive-to-plain-text">
      <xsl:text>&#xd;</xsl:text>
   </xsl:template>
   <xsl:template match="w:noBreakHyphen" mode="tan:archive-to-plain-text">
      <xsl:text>&#x2011;</xsl:text>
   </xsl:template>
   <xsl:template match="w:softHyphen" mode="tan:archive-to-plain-text">
      <xsl:text>&#xad;</xsl:text>
   </xsl:template>
   <!-- items to suppress -->
   <xsl:template match="w:instrText | prop:Properties | cp:coreProperties | w:pPr" mode="tan:archive-to-plain-text"/>
   
   

</xsl:stylesheet>
