<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tan="tag:textalign.net,2015:ns" 
   xmlns="tag:textalign.net,2015:ns" 
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="#all"
   version="3.0">

   <!-- Core application for synchronizing a class 1 file's text with its redivision. -->
   
   <xsl:include href="../../../functions/TAN-function-library.xsl"/>
   
   <!-- About this stylesheet -->

   <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
   <xsl:param name="tan:stylesheet-iri"
      select="'tag:textalign.net,2015:stylesheet:update-tan-t-text-to-redivision'"/>
   <xsl:param name="tan:stylesheet-name" select="'Body Sync'"/>
   <xsl:param name="tan:stylesheet-activity"
      select="'updates a transcription in a class 1 file to match that in a redivision'"/>
   
   <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">a class 1 file with a
      redivision element in the head</xsl:param>
   <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">the redivision</xsl:param>
   <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">the primary input, with the text
      of its body revised to match the text in the chosen redivision</xsl:param>
   <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>
   
   <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
   <xsl:param name="tan:stylesheet-change-log">
      <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
         prepared for TAN 2021 release.</change>
   </xsl:param>
   <xsl:param name="tan:stylesheet-change-message"
      select="concat('Replaced body text with redivision ', xs:string($redivision-number))"/>
   
   <xsl:output indent="true" use-character-maps="tan:see-special-chars"/>
   
   <!-- The application -->
   
   <xsl:function name="tan:synchronize-class-1-text" as="document-node()">
      <!-- Input: a class 1 file; an integer; a boolean -->
      <!-- Output: the file with the text replaced by the Nth <redivision>, where
      N is the 2nd parameter. If the third parameter is true, deletions will be retained
      as comments. -->
      <!-- The output file will have a body that is space-normalized, so output indentations in 
         leaf divs may differ from the input. -->
      <xsl:param name="class-1-file" as="document-node()"/>
      <xsl:param name="redivision-pick" as="xs:integer"/>
      <xsl:param name="annotate-deletions" as="xs:boolean"/>
      
      <xsl:variable name="input-resolved" as="document-node()" select="tan:resolve-doc($class-1-file)"/>
      
      <xsl:variable name="input-marked-for-special-end-chars" as="document-node()">
         <xsl:apply-templates select="$class-1-file" mode="tan:signal-special-end-chars"/>
      </xsl:variable>
      
      <xsl:variable name="input-space-normalized" as="document-node()" select="tan:normalize-tree-space($input-marked-for-special-end-chars, true())"/>

      <xsl:variable name="redivision" as="element()?" select="$input-resolved/*/tan:head/tan:redivision[$redivision-pick]"/>
      <xsl:variable name="redivision-resolved" select="tan:resolve-doc(tan:get-1st-doc($redivision))" as="document-node()?"/>
      <xsl:variable name="redivision-space-normalized" select="tan:normalize-tree-space($redivision-resolved, true())" as="document-node()?"/>
      
      <xsl:variable name="this-text"
         select="string-join($input-space-normalized/(tan:TAN-T | tei:TEI/tei:text)/*:body//*:div[not(*:div)])"
         as="xs:string?"/>
      <xsl:variable name="redivision-text"
         select="string-join($redivision-space-normalized/(tan:TAN-T | tei:TEI/tei:text)/*:body//*:div[not(*:div)])"
         as="xs:string?"/>
      
      <xsl:variable name="doc-rediv-diff" select="tan:diff($this-text, $redivision-text, false())"
         as="element()"/>
      
      <!-- Analyze length -->
      <xsl:variable name="input-body-analyzed-1" select="tan:stamp-tree-with-text-data($input-space-normalized/(tan:TAN-T | tei:TEI/tei:text)/*:body, true())"
         as="element()?"/>
      
      <xsl:variable name="input-body-analyzed-2" as="element()?">
         <xsl:apply-templates select="$input-body-analyzed-1" mode="add-text-pos"/>
      </xsl:variable>
      
      <xsl:variable name="positions" as="xs:integer*" select="
            for $i in $input-body-analyzed-2//(@_pos | @_pos-text),
               $j in tokenize($i, ' ')
            return
               xs:integer($j)"/>
      
      <xsl:variable name="doc-rediv-diff-chopped" as="map(*)"
         select="tan:chop-diff-output($doc-rediv-diff, $positions, true(), $tan:word-end-regex)"/>
      
      
      <xsl:choose>
         <!-- diagnostics -->
         <xsl:when test="false()">
            <xsl:message select="'Diagnostics on, tan:synchronize-class-1-text()'"/>
            <xsl:document>
               <diagnostics>
                  <self-expanded><xsl:copy-of select="tan:expand-doc($tan:self-resolved, 'verbose', true())"/></self-expanded>
                  <!--<input-space-norm><xsl:copy-of select="$input-space-normalized"/></input-space-norm>-->
                  <!--<rediv-sp-norm><xsl:copy-of select="$redivision-space-normalized"/></rediv-sp-norm>-->
                  <this-text><xsl:copy-of select="$this-text"/></this-text>
                  <rediv-text><xsl:copy-of select="$redivision-text"/></rediv-text>
                  <diff><xsl:copy-of select="$doc-rediv-diff"/></diff>
                  <!--<input-body-analyzed-1><xsl:copy-of select="$input-body-analyzed-1"/></input-body-analyzed-1>-->
                  <!--<input-body-analyzed-2><xsl:copy-of select="$input-body-analyzed-2"/></input-body-analyzed-2>-->
                  <diff-chopped-map><xsl:copy-of select="tan:map-to-xml($doc-rediv-diff-chopped)"/></diff-chopped-map>
               </diagnostics>
            </xsl:document>
         </xsl:when>
         <xsl:when test="not(exists($class-1-file/(tan:TAN-T | tei:TEI)))">
            <xsl:message select="'File is not a class 1 file; returning input unchanged.'"/>
            <xsl:sequence select="$class-1-file"/>
         </xsl:when>
         <xsl:when test="not(exists($redivision))">
            <xsl:message
               select="'The file has ' || string(count($input-resolved/*/tan:head/tan:redivision)) || ' redivisions. There is no ' || tan:ordinal($redivision-pick) || ' redivision in the file.'"
            />
            <xsl:sequence select="$class-1-file"/>
         </xsl:when>
         <xsl:when test="exists($class-1-file/(tan:TAN-T | tei:TEI/tei:text)/*:body//*:div[@include])">
            <xsl:message select="'This function may not be performed on a file that has divs that are included from another file. Replace the relevant divs with the actual content, then run the application.'"/>
            <xsl:sequence select="$class-1-file"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="$class-1-file" mode="sync-body-text">
               <xsl:with-param name="chopped-diff-map" as="map(*)" tunnel="yes" select="$doc-rediv-diff-chopped"/>
               <xsl:with-param name="body-space-normalized-and-analyzed" tunnel="yes" select="$input-body-analyzed-2"/>
               <xsl:with-param name="annotate-deletions" tunnel="yes" select="$annotate-deletions"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:signal-special-end-chars" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:div[not(tan:div)][text()[last()][matches(., $tan:special-end-div-chars-regex)]]" mode="tan:signal-special-end-chars">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="_end-char"
            select="analyze-string(text()[last()], $tan:special-end-div-chars-regex)/*:match"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tei:*[text()[last()][matches(., $tan:special-end-div-chars-regex)]]" mode="tan:signal-special-end-chars">
      <xsl:variable name="this-element" select="." as="element()"/>
      <xsl:variable name="host-leaf-div" select="ancestor-or-self::tei:div[1]" as="element()?"/>
      <xsl:variable name="locally-following-nodes" as="item()*"
         select="$host-leaf-div//node()[. >> $this-element] except descendant-or-self::node()"/>
      <xsl:choose>
         <xsl:when test="not(some $i in $locally-following-nodes satisfies matches($i, '\S'))">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="_end-char"
                  select="analyze-string(text()[last()], $tan:special-end-div-chars-regex)/*:match"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:mode name="add-text-pos" on-no-match="shallow-copy"/>
   
   <xsl:template match="tei:div[tei:div] | tei:body" priority="1" mode="add-text-pos">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tei:*[@_pos][text()]" mode="add-text-pos">
      <xsl:variable name="context-pos" as="xs:integer" select="xs:integer(@_pos)"/>
      <!-- Get the position of every text node -->
      <xsl:variable name="text-poses" as="xs:integer+">
         <xsl:iterate select="node()">
            <xsl:param name="current-pos" as="xs:integer" select="$context-pos"/>
            <xsl:variable name="this-len" as="xs:integer">
               <xsl:choose>
                  <xsl:when test="exists(@_len)">
                     <xsl:sequence select="xs:integer(@_len)"/>
                  </xsl:when>
                  <xsl:when test=". instance of text()">
                     <xsl:sequence select="tan:string-length(.)"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="0"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:if test=". instance of text()">
               <xsl:sequence select="$current-pos"/>
            </xsl:if>
            <xsl:next-iteration>
               <xsl:with-param name="current-pos" select="$current-pos + $this-len"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="_pos-text" select="$text-poses"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   
   <xsl:mode name="sync-body-text" on-no-match="shallow-copy"/>
   <xsl:mode name="sync-body-text-2" on-no-match="shallow-copy"/>
   
   
   <xsl:template match="/node()" mode="sync-body-text">
      <xsl:sequence select="'&#xa;'"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tei:body | tan:body" mode="sync-body-text">
      <xsl:param name="body-space-normalized-and-analyzed" tunnel="yes" as="element()"/>
      <xsl:apply-templates select="$body-space-normalized-and-analyzed" mode="sync-body-text-2"/>
   </xsl:template>
   
   <xsl:template match="tan:body | tei:body | *:div[*:div]" priority="1" mode="sync-body-text-2">
      <xsl:param name="annotate-deletions" as="xs:boolean" select="$mark-alterations"/>
      
      <xsl:if test="$annotate-deletions and (local-name(.) eq 'body') and exists(descendant::comment()[matches(., ' ?(ins|del):')])">
         <xsl:message select="'Input currently has insertions and deletions marked, which will be indistinguishable from marks made in this process.'"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@* except (@_pos | @_len | @_pos-text | @q)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[@_pos]" mode="sync-body-text-2">
      <xsl:param name="chopped-diff-map" tunnel="yes" as="map(*)"/>
      
      <xsl:variable name="this-start" select="xs:integer(@_pos)" as="xs:integer"/>
      <xsl:variable name="this-map-entry" as="element()?" select="$chopped-diff-map($this-start)"/>
      
      <xsl:copy>
         <xsl:copy-of select="@* except (@_len | @_pos | @_pos-text | @q | @_end-char)"/>
         <xsl:choose>
            <xsl:when test="exists(@_pos-text)">
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="text-poses" as="xs:integer+" select="
                        for $i in tokenize(@_pos-text, ' ')
                        return
                           xs:integer($i)"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="exists(*[@_pos])">
               <xsl:apply-templates mode="#current"/>
            </xsl:when>
            <xsl:when test="exists($this-map-entry)">
               <xsl:apply-templates select="$this-map-entry" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message select="'No difference map entry found for ' || path(.)"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
         
      </xsl:copy>
      
   </xsl:template>
   
   <xsl:template match="*[@_pos-text]/text()" mode="sync-body-text-2">
      <xsl:param name="text-poses" as="xs:integer+"/>
      <xsl:param name="chopped-diff-map" tunnel="yes" as="map(*)"/>
      <xsl:variable name="text-number" select="count(preceding-sibling::text()) + 1" as="xs:integer"/>
      <xsl:variable name="this-start" select="$text-poses[$text-number]" as="xs:integer"/>
      <xsl:variable name="this-map-entry" as="element()?" select="$chopped-diff-map($this-start)"/>
      
      <xsl:choose>
         <xsl:when test="exists($this-map-entry)">
            <xsl:apply-templates select="$this-map-entry" mode="#current"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message select="'No difference map entry found for ' || path(.)"/>
            <xsl:value-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:template>
   
   <xsl:template match="tan:diff" mode="sync-body-text-2">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="tan:a" mode="sync-body-text-2">
      <xsl:param name="annotate-deletions" as="xs:boolean" select="$mark-alterations"/>
      <xsl:if test="$mark-alterations">
         <xsl:comment select="'del:' || text()"/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tan:common" mode="sync-body-text-2">
      <xsl:sequence select="text()"/>
   </xsl:template>
   <xsl:template match="tan:b" mode="sync-body-text-2">
      <xsl:param name="annotate-deletions" as="xs:boolean" select="$mark-alterations"/>
      <xsl:if test="$mark-alterations">
         <xsl:comment select="'ins:'"/>
      </xsl:if>
      <xsl:sequence select="text()"/>
      <xsl:if test="$mark-alterations">
         <xsl:comment/>
      </xsl:if>
   </xsl:template>
   
   
   <!-- Main output -->
   <xsl:template match="/">
      <xsl:sequence select="tan:synchronize-class-1-text(., $redivision-number, $mark-alterations)"
      />
   </xsl:template>
   
</xsl:stylesheet>