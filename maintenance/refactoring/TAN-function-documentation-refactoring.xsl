<xsl:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="true">
   
   <xsl:mode default-mode="#unnamed" on-no-match="shallow-copy"/>
   
   <xsl:variable name="xref-indicator-regex" as="xs:string" select="'(-param(eter)?|short|arity) version.+below|surrogate function|supporting loop|Alias for the function below'"/>
   
   <xsl:template match="xsl:function[comment()[matches(., $xref-indicator-regex)]]">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="xsl:function[@visibility eq 'public']/*[1]">
      <xsl:variable name="indentation" as="text()" select="preceding-sibling::text()[1]"/>
      <xsl:variable name="initial-comments" as="comment()*" select="preceding-sibling::comment()"/>
      <xsl:variable name="input-comment" as="comment()*" select="$initial-comments[matches(., '^\s*Input:')]"/>
      <xsl:variable name="output-comment" as="comment()*" select="$initial-comments[matches(., '^\s*Input:')]"/>
      <xsl:variable name="keyword-comment" as="comment()*" select="$initial-comments[matches(., '^\s*kw:')]"/>
      <xsl:variable name="parent-directory-name" as="xs:string"
         select="tokenize(base-uri(.), '/')[last() - 1]"/>
      <xsl:if test="not(exists($input-comment))">
         <xsl:comment>Input: </xsl:comment>
         <xsl:copy-of select="$indentation"/>
      </xsl:if>
      <xsl:if test="not(exists($output-comment))">
         <xsl:comment>Output: </xsl:comment>
         <xsl:copy-of select="$indentation"/>
      </xsl:if>
      <xsl:if test="not(exists($keyword-comment))">
         <xsl:comment>kw: {$parent-directory-name} </xsl:comment>
         <xsl:copy-of select="$indentation"/>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
</xsl:stylesheet>