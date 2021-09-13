<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   version="3.0">
   
   <!-- TAN Function Library: functions for TAN output -->
   
   <xsl:function name="tan:update-TAN-change-log" as="document-node()?" visibility="public">
      <!-- one-parameter version of fuller one, below -->
      <xsl:param name="TAN-file" as="document-node()?"/>
      <xsl:sequence select="tan:update-TAN-change-log($TAN-file, $tan:stylesheet-iri,
         $tan:stylesheet-name, $tan:stylesheet-url, 'algorithm', 'stylesheet', $tan:stylesheet-change-message, $tan:doc-uri)"/>
   </xsl:function>
   
   <xsl:function name="tan:update-TAN-change-log" as="document-node()?" visibility="public">
      <!-- Input: a TAN file; assorted parameters pertaining to the agent that created or
      changed the file -->
      <!-- Output: The TAN file with appropriate credit/blame given -->
      <!-- It is presumed that the TAN file is in its raw state, and that indentation
         should be respected. -->
      <!-- If an agent type is not recognized, the default will be algorithm. -->
      <!--kw: nodes, versioning -->
      <xsl:param name="TAN-file" as="document-node()?"/>
      <xsl:param name="agent-IRIs" as="xs:string+"/>
      <xsl:param name="agent-names" as="xs:string+"/>
      <xsl:param name="agent-base-uri-resolved" as="xs:string?"/>
      <xsl:param name="agent-type" as="xs:string"/>
      <xsl:param name="agent-responsibility" as="xs:string"/>
      <xsl:param name="change-message" as="xs:string"/>
      <!-- The source base uri is either the uri that the TAN file is coming from, or the one where
         it is going. Many times the TAN file that gets passed into this function is the result of
         a stylesheet's alteration, which means that the original or target base URI has been lost
         to the static base uri. A re-set source base uri allows us to calculate the relative path
         of the agent URI against the input or output, as needed. -->
      <xsl:param name="source-base-uri" as="xs:string"/>

      <xsl:variable name="file-is-TAN" select="tan:class-number($TAN-file) gt 0" as="xs:boolean"/>
      <xsl:variable name="file-is-resolved" select="exists($TAN-file/*/tan:resolved)"
         as="xs:boolean"/>
      
      <xsl:variable name="agent-names-norm" select="tan:normalize-name($agent-names)"
         as="xs:string+"/>
      
      <xsl:variable name="file-resolved" as="document-node()" select="
            if ($file-is-resolved) then
               $TAN-file
            else
               tan:resolve-doc($TAN-file)"/>
      <xsl:variable name="agent-element-names" as="xs:string+" select="'algorithm', 'person', 'organization'"/>
      <xsl:variable name="agent-type-resolved" as="xs:string" select="
            if (lower-case($agent-type) = $agent-element-names)
            then
               lower-case($agent-type)
            else
               $agent-element-names[1]"/>
      
      <xsl:variable name="current-agent-vocabulary" as="element()*"
         select="tan:vocabulary($agent-element-names, (), $file-resolved/(*/tan:head | tan:TAN-voc/tan:body))"
      />
      
      <xsl:variable name="matching-vocabulary-item-by-iri" as="element()*" select="$current-agent-vocabulary/*[tan:IRI = $agent-IRIs]"/>
      <xsl:variable name="matching-vocabulary-item-by-name" as="element()*" select="$current-agent-vocabulary/*[tan:name = $agent-names-norm]"/>
      
      <xsl:variable name="matching-vocabulary-items" as="element()*" select="$matching-vocabulary-item-by-iri | $matching-vocabulary-item-by-name"/>
      <xsl:variable name="first-matching-vocabulary-item" as="element()*" select="$matching-vocabulary-items[1]"/>
      <xsl:variable name="first-matching-internal-vocab-item"
         select="($TAN-file//*[tan:IRI = $first-matching-vocabulary-item/tan:IRI])[1]"
         as="element()?"/>
      <xsl:variable name="vocab-item-is-in-this-document" as="xs:boolean"
         select="exists($first-matching-internal-vocab-item)"/>
      <xsl:variable name="names-to-insert" as="xs:string*"
         select="$agent-names[not(tan:normalize-name(.) = $first-matching-internal-vocab-item/tan:name)]"
      />
      <xsl:variable name="iris-to-insert" as="xs:string*"
         select="$agent-IRIs[not(. = $first-matching-internal-vocab-item/tan:IRI)]"/>
      
      
      <xsl:variable name="unexpected-vocabulary-items" as="element()*"
         select="$matching-vocabulary-items[not(name(.) eq $agent-type-resolved)]"/>
      
      <xsl:variable name="new-vocabulary-item" as="element()?">
         <xsl:if test="not(exists($first-matching-vocabulary-item))">
            <xsl:variable name="previously-used-id-numbers" as="xs:integer*" select="
                  for $i in $matching-vocabulary-items/tan:id[matches(., '^' || $agent-type-resolved || '\d+$')]
                  return
                     xs:integer(replace($i, '\D+', ''))"/>
            <xsl:variable name="new-id" select="$agent-type-resolved || string(max((0, $previously-used-id-numbers)) + 1)" as="xs:string"/>
            <xsl:element name="{$agent-type-resolved}">
               <xsl:attribute name="xml:id" select="$new-id"/>
               <xsl:for-each select="$agent-IRIs">
                  <IRI>
                     <xsl:value-of select="."/>
                  </IRI>
               </xsl:for-each>
               <xsl:for-each select="$agent-names">
                  <name>
                     <xsl:value-of select="."/>
                  </name>
               </xsl:for-each>
               <xsl:if test="$agent-type-resolved eq 'algorithm'">
                  <location href="{tan:uri-relative-to($agent-base-uri-resolved, $source-base-uri)}"
                     accessed-when="{current-dateTime()}"/>
               </xsl:if>
            </xsl:element>
         </xsl:if>
      </xsl:variable>
      
      <xsl:variable name="agent-id" as="xs:string"
         select="replace(($new-vocabulary-item/@xml:id, $first-matching-vocabulary-item/(tan:id | tan:name))[1], ' ', '_')"
      />
      
      <xsl:variable name="new-change-message" as="element()">
         <change who="{$agent-id}" when="{current-dateTime()}">
            <xsl:value-of select="$change-message"/>
         </change>
      </xsl:variable>
      
      <xsl:variable name="current-role-vocabulary" as="element()*"
         select="tan:vocabulary('role', $agent-responsibility, $file-resolved/(*/tan:head | tan:TAN-voc/tan:body))"
      />
      <xsl:variable name="fallback-role-vocabulary" as="element()*"
         select="tan:vocabulary('role', $agent-responsibility, $tan:TAN-vocabularies/tan:TAN-voc/tan:body)"
      />
      
      <xsl:variable name="existing-resp-statement" as="element()?"
         select="$TAN-file/*/tan:head/tan:resp[tan:has-vocab(@roles, $agent-responsibility)][1]"/>
      
      <xsl:variable name="new-resp-statement" as="element()?">
         <xsl:if test="not(exists($existing-resp-statement))">
            <resp who="{$agent-id}" roles="{$agent-responsibility}"/>
         </xsl:if>
      </xsl:variable>
      
      
      
      <!-- Messaging -->
      
      <xsl:if test="exists($unexpected-vocabulary-items)">
         <xsl:message select="
               'Vocabulary item should be ' || $agent-type-resolved || ' but matching vocabulary is: ' || 
               string-join(distinct-values(for $i in $unexpected-vocabulary-items
               return
                  name($i)))"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="exists($names-to-insert) and $vocab-item-is-in-this-document">
            <xsl:message select="'Target file has a matching internal vocabulary item that lacks the specified name ' || string-join($names-to-insert) || ', which will be inserted in the output.'"/>
         </xsl:when>
         <xsl:when test="exists($names-to-insert) and exists($first-matching-vocabulary-item)">
            <xsl:message select="'Target file has a matching external vocabulary item. It lacks the specified name ' || string-join($names-to-insert) || ', but because it is external it cannot be fixed here.'"/>
         </xsl:when>
      </xsl:choose>
      <xsl:choose>
         <xsl:when test="exists($iris-to-insert) and $vocab-item-is-in-this-document">
            <xsl:message select="'Target file has a matching internal vocabulary item that lacks the specified IRI ' || string-join($iris-to-insert) || ', which will be inserted in the output.'"/>
         </xsl:when>
         <xsl:when test="exists($iris-to-insert) and exists($first-matching-vocabulary-item)">
            <xsl:message select="'Target file has a matching external vocabulary item. It lacks the specified IRI ' || string-join($iris-to-insert) || ', but because it is external it cannot be fixed here.'"/>
         </xsl:when>
      </xsl:choose>
      
      <xsl:choose>
         <xsl:when test="count($matching-vocabulary-items) gt 1">
            <xsl:message select="string(count($matching-vocabulary-items)) || ' were found in the target file; using only the first vocabulary item.'"/>
         </xsl:when>
         <xsl:when test="count($matching-vocabulary-items) eq 1">
            <xsl:message select="'Matching vocabulary item found for ' || string-join($agent-names, ', ')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message select="'[tan:update-TAN-change-log()] No matching vocabulary item found for ' || string-join($agent-names, ', ') || '. New vocabulary item will be added.'"/>
         </xsl:otherwise>
      </xsl:choose>
      
      <xsl:if test="not(exists($current-role-vocabulary)) and not(exists($fallback-role-vocabulary))">
         <xsl:message select="'No role vocabulary identified for ' || $agent-responsibility || '; be sure to add vocabulary for this term.'"/>
      </xsl:if>
      
      
      <xsl:variable name="diagnostic-output" as="xs:boolean" select="false()"/>
      <xsl:choose>
         <xsl:when test="$diagnostic-output">
            <xsl:message select="'Replacing output of tan:update-TAN-change-log() with diagnostic output.'"/>
            <xsl:document>
               <diagnostics>
                  <file-is-TAN><xsl:copy-of select="$file-is-TAN"/></file-is-TAN>
                  <file-is-resolved><xsl:copy-of select="$file-is-resolved"/></file-is-resolved>
                  <file-resolved><xsl:copy-of select="$file-resolved"/></file-resolved>
                  <current-agent-vocabulary><xsl:copy-of select="$current-agent-vocabulary"/></current-agent-vocabulary>
                  <first-matching-internal-voc-item><xsl:copy-of select="$first-matching-internal-vocab-item"/></first-matching-internal-voc-item>
                  <new-vocabulary-item><xsl:copy-of select="$new-vocabulary-item"/></new-vocabulary-item>
                  <current-role-vocabulary><xsl:copy-of select="$current-role-vocabulary"/></current-role-vocabulary>
                  <fallback-role-vocabulary><xsl:copy-of select="$fallback-role-vocabulary"/></fallback-role-vocabulary>
                  <existing-resp-statement><xsl:copy-of select="$existing-resp-statement"/></existing-resp-statement>
                  <new-resp-statement><xsl:copy-of select="$new-resp-statement"/></new-resp-statement>
                  <new-change-statement><xsl:copy-of select="$new-change-message"/></new-change-statement>
               </diagnostics>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="$TAN-file" mode="tan:update-TAN-change-log">
               <!-- vocabulary -->
               <xsl:with-param name="first-matching-vocabulary-item" as="element()?" tunnel="yes"
                  select="($first-matching-internal-vocab-item, $first-matching-vocabulary-item)[1]"
               />
               <xsl:with-param name="names-to-insert" tunnel="yes" as="xs:string*" select="$names-to-insert"/>
               <xsl:with-param name="iris-to-insert" tunnel="yes" as="xs:string*" select="$iris-to-insert"/>
               <xsl:with-param name="new-vocabulary-item" tunnel="yes" as="element()?" select="$new-vocabulary-item"/>
               <!-- resp -->
               <xsl:with-param name="first-matching-resp" tunnel="yes" as="element()?" select="$existing-resp-statement[1]"/>
               <xsl:with-param name="new-resp-statement" tunnel="yes" as="element()?" select="$new-resp-statement"/>
               <!-- change -->
               <xsl:with-param name="new-change-message" tunnel="yes" as="element()" select="$new-change-message"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
      
      
   </xsl:function>
   
   
   <xsl:mode name="tan:update-TAN-change-log" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:person | tan:organization | tan:algorithm" mode="tan:update-TAN-change-log">
      <xsl:param name="first-matching-vocabulary-item" tunnel="yes" as="element()?"/>
      <xsl:param name="names-to-insert" tunnel="yes" as="xs:string*"/>
      <xsl:param name="iris-to-insert" tunnel="yes" as="xs:string*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="apply-new-content" as="xs:boolean?" select=". is $first-matching-vocabulary-item"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template
      match="tan:person/tan:name[last()] | tan:organization/tan:name[last()] | tan:algorithm/tan:name[last()]"
      mode="tan:update-TAN-change-log">
      <xsl:param name="apply-new-content" as="xs:boolean?" select="false()"/>
      <xsl:param name="names-to-insert" tunnel="yes" as="xs:string*"/>

      <xsl:variable name="preceding-indentation" as="text()?"
         select="preceding-sibling::node()[1]/self::text()"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      <xsl:if test="$apply-new-content">
         <xsl:for-each select="$names-to-insert">
            <xsl:sequence select="$preceding-indentation"/>
            <name>
               <xsl:value-of select="."/>
            </name>
         </xsl:for-each>
      </xsl:if>
   </xsl:template>
   
   <xsl:template
      match="tan:person/tan:IRI[last()] | tan:organization/tan:IRI[last()] | tan:algorithm/tan:IRI[last()]"
      mode="tan:update-TAN-change-log">
      <xsl:param name="apply-new-content" as="xs:boolean?" select="false()"/>
      <xsl:param name="iris-to-insert" tunnel="yes" as="xs:string*"/>

      <xsl:variable name="preceding-indentation" as="text()?"
         select="preceding-sibling::node()[1]/self::text()"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      <xsl:if test="$apply-new-content">
         <xsl:for-each select="$iris-to-insert">
            <xsl:sequence select="$preceding-indentation"/>
            <IRI>
               <xsl:value-of select="."/>
            </IRI>
         </xsl:for-each>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary-key/*[last()]" mode="tan:update-TAN-change-log">
      <xsl:param name="new-vocabulary-item" tunnel="yes" as="element()?"/>
      
      <xsl:variable name="preceding-indentation" as="text()?"
         select="preceding-sibling::node()[1]/self::text()"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      <xsl:if test="exists($new-vocabulary-item)">
         <xsl:sequence select="$preceding-indentation"/>
         <xsl:sequence select="$new-vocabulary-item"/>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary-key[not(*)]" mode="tan:update-TAN-change-log">
      <xsl:param name="new-vocabulary-item" tunnel="yes" as="element()?"/>
      <xsl:variable name="preceding-indentation" as="text()?"
         select="preceding-sibling::node()[1]/self::text()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($new-vocabulary-item)">
            <xsl:copy-of select="$preceding-indentation || substring($preceding-indentation, 1, string-length($preceding-indentation) idiv 2)"/>
            <xsl:copy-of select="$new-vocabulary-item"/>
            <xsl:copy-of select="$preceding-indentation"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:resp" mode="tan:update-TAN-change-log">
      <xsl:param name="first-matching-resp" tunnel="yes" as="element()?"/>
      <xsl:choose>
         <xsl:when test=". is $first-matching-resp">
            <xsl:copy>
               <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="tan:resp/@who" mode="tan:update-TAN-change-log">
      <xsl:param name="new-change-message" tunnel="yes" as="element()"/>
      <xsl:attribute name="who" select=". || ' ' || $new-change-message/@who"/>
   </xsl:template>
   
   <xsl:template match="tan:head/tan:change[1] | tan:head[not(tan:change)]/tan:to-do" mode="tan:update-TAN-change-log">
      <xsl:param name="new-change-message" tunnel="yes" as="element()"/>
      <xsl:copy-of select="preceding-sibling::node()[1]/self::text()"/>
      <xsl:copy-of select="$new-change-message"/>
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:head/tan:resp[last()] | tan:head[not(tan:resp)]/tan:file-resp" priority="1" mode="tan:update-TAN-change-log">
      <xsl:param name="new-resp-statement" tunnel="yes" as="element()?"/>
      
      <xsl:variable name="preceding-indentation" select="preceding-sibling::node()[1]/text()" as="text()?"/>
      <xsl:choose>
         <xsl:when test="exists($new-resp-statement)">
            <xsl:copy-of select="."/>
            <xsl:copy-of select="$preceding-indentation"/>
            <xsl:copy-of select="$new-resp-statement"/>
         </xsl:when>
         <xsl:when test="self::tan:resp">
            <xsl:next-match/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   
</xsl:stylesheet>