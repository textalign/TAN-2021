<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:err="http://www.w3.org/2005/xqt-errors"
   version="3.0">

   <!-- TAN Function Library output file functions. -->

   <!-- This is a special set of functions for generating secondary output. -->
   
   <!-- templates for marking documents to be saved, and for saving them as well -->
   <xsl:output name="xml" method="xml" use-character-maps="tan:see-special-chars"/>
   <xsl:output name="xml-indent" method="xml" indent="yes" use-character-maps="tan:see-special-chars"/>
   <xsl:output name="html" method="html"/>
   <xsl:output name="html-noindent" method="html" indent="no"/>
   <xsl:output name="xhtml" method="xhtml"/>
   <xsl:output name="xhtml-noindent" method="xhtml" indent="no"/>
   <xsl:output name="text" method="text"/>
   
   <!-- SAVING FILES -->
   <!-- Note, due to security concerns, functions cannot be used to save documents -->
   <!-- Saving can happen only through a named or moded template -->
   <!-- The mode save-file is completely consumptive; no output is returned -->
   
   <xsl:mode name="tan:save-file" on-no-match="shallow-copy"/>

   <xsl:template match="/" mode="tan:save-file">
      <xsl:param name="target-uri" as="xs:string?" select="(*/@save-as, */@_target-uri)[1]"/>
      <xsl:param name="target-format" as="xs:string?" select="(*/@_target-format, $tan:default-output-method)[1]"/>

      <xsl:choose>
         <xsl:when test="string-length($target-uri) lt 1">
            <xsl:message select="'Unable to save file ' || base-uri(.) || ' because no target uri has been specified.'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message select="'Saving file to target ' || $target-uri"/>
            <xsl:if test="exists(*/@save-as) and not($target-uri eq */@save-as)">
               <xsl:message select="'Attribute @save-as ' || */@save-as || ' overridden by supplied target uri ' || $target-format"/>
            </xsl:if>
            <xsl:if test="exists(*/@_target-uri) and not($target-uri eq */@_target-uri)">
               <xsl:message select="'Attribute @_target-uri ' || */@_target-uri || ' overridden by supplied target uri ' || $target-format"/>
            </xsl:if>
            <xsl:if test="exists(*/@_target-format) and not(*/@_target-format eq $target-format)">
               <xsl:message select="'Attribute @_target-format ' || */@_target-format || ' overridden by supplied target format ' || $target-format"/>
            </xsl:if>
            <xsl:try>
               <xsl:result-document href="{$target-uri}" format="{$target-format}">
                  <xsl:document>
                     <xsl:apply-templates mode="#current"/>
                  </xsl:document>
               </xsl:result-document>
               <xsl:catch>
                  <xsl:message select="'Unable to save to ' || $target-uri"/>
                  <xsl:message select="'[' || $err:code || '] ' || $err:description"/>
               </xsl:catch>
            </xsl:try>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="/node()" priority="1" mode="tan:save-file">

      <xsl:param name="set-each-doc-node-on-new-line" tunnel="yes" as="xs:boolean?" select="true()"/>
      <xsl:if test="$set-each-doc-node-on-new-line">
         <xsl:value-of select="'&#xa;'"/>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>

   <xsl:template match="/*[@save-as | @_target-uri | @_target-format]" priority="2" mode="tan:save-file">
      <xsl:param name="set-each-doc-node-on-new-line" tunnel="yes" as="xs:boolean?" select="true()"/>
      <xsl:if test="$set-each-doc-node-on-new-line">
         <xsl:value-of select="'&#xa;'"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@* except (@save-as | @xml:base | @_target-uri |@_target-format)"/>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template name="tan:save-as" visibility="public">
      <!-- Input: any document, perhaps a target URI and target format, and a boolean indicating whether every 
      top-level item should appear on its own line. -->
      <!-- The root element's attribute @_target-uri or @save-as supplies the default value, which may be overwritten. -->
      <xsl:param name="document-to-save" as="document-node()" required="yes"/>
      <xsl:param name="target-uri" as="xs:string?"/>
      <xsl:param name="target-format" as="xs:string?"/>
      <xsl:param name="set-each-doc-node-on-new-line" tunnel="yes" as="xs:boolean?"
         select="$tan:set-each-doc-node-on-new-line"/>
      
      <xsl:variable name="target-uri-adjusted" as="xs:string" select="
            if (string-length($target-uri) lt 1)
            then
               ($document-to-save/*/@save-as, $document-to-save/*/@_target-uri)[1]
            else
               $target-uri"/>
      <xsl:variable name="target-format-adjusted" select="
            if (string-length($target-format) lt 1)
            then
               ($document-to-save/*/@_target-format, $tan:default-output-method)[1]
            else
               $target-format"/>
      
      <xsl:apply-templates select="$document-to-save" mode="tan:save-file">
         <xsl:with-param name="target-uri" select="$target-uri-adjusted"/>
         <xsl:with-param name="target-format" select="$target-format-adjusted"/>
      </xsl:apply-templates>
   </xsl:template>
   
   
   <xsl:mode name="tan:doc-nodes-on-new-lines" on-no-match="shallow-copy"/>
   
   <xsl:template match="/node()" mode="tan:doc-nodes-on-new-lines">
      <xsl:text>&#xa;</xsl:text>
      <xsl:copy-of select="."/>
   </xsl:template>

</xsl:stylesheet>
