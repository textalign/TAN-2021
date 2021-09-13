<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   version="3.0">
   
   <!-- TAN Function Library: extended functions on nodes -->
   
   <xsl:function name="tan:pluck" as="item()*" visibility="public">
      <!-- Input: any document fragment or element; a number indicating a level in the hierarchy of the fragment; a boolean indicating whether leaf elements that fall short of the previous parameter should be included -->
      <!-- Output: the fragment of the tree that is beyond the point indicated, and perhaps (depending upon the third parameter) with other leafs that are not quite at that level -->
      <!-- This function was written primarily to serve tan:convert-ref-to-div-fragment(), to get a slice of divs that correspond to a range, without the ancestry of those divs -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="fragment" as="item()*"/>
      <xsl:param name="pluck-beyond-level" as="xs:integer"/>
      <xsl:param name="keep-short-branch-leaves" as="xs:boolean"/>
      <xsl:apply-templates select="$fragment" mode="tan:pluck">
         <xsl:with-param name="prune-above-level" select="$pluck-beyond-level" tunnel="yes"/>
         <xsl:with-param name="keep-short-branch-leaves" select="$keep-short-branch-leaves"
            tunnel="yes"/>
         <xsl:with-param name="currently-at" select="1"/>
      </xsl:apply-templates>
   </xsl:function>
   

   <xsl:mode name="tan:pluck" on-no-match="shallow-skip"/>
   
   <xsl:template match="*" mode="tan:pluck">
      <xsl:param name="currently-at" as="xs:integer"/>
      <xsl:param name="prune-above-level" as="xs:integer" tunnel="yes"/>
      <xsl:param name="keep-short-branch-leaves" as="xs:boolean" tunnel="yes"/>
      <xsl:choose>
         <xsl:when test="$prune-above-level = $currently-at">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:when test="not(exists(*))">
            <xsl:if test="$keep-short-branch-leaves = true()">
               <xsl:copy-of select="."/>
            </xsl:if>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="currently-at" select="$currently-at + 1"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="text()" mode="tan:pluck">
      <xsl:if test="matches(., '\S')">
         <xsl:value-of select="."/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="comment() | processing-instruction()" mode="tan:pluck"/>
   
   
   <xsl:function name="tan:insert-as-first-child" as="item()*" visibility="public">
      <!-- Input: items to be changed; items to be inserted; strings representing the names of the elements that should receive the insertion -->
      <!-- Output: the first items, with the second items inserted in the appropriate place -->
      <!-- This function allows the deep insertion of content -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="items-to-be-changed" as="item()*"/>
      <xsl:param name="items-to-insert-as-first-child" as="item()*"/>
      <xsl:param name="names-of-elements-to-receive-action" as="xs:string*"/>
      <xsl:apply-templates select="$items-to-be-changed" mode="tan:insert-content">
         <xsl:with-param name="items-to-insert-as-first-child"
            select="$items-to-insert-as-first-child" tunnel="yes"/>
         <xsl:with-param name="names-of-elements-to-receive-action"
            select="$names-of-elements-to-receive-action" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:function name="tan:insert-as-last-child" as="item()*" visibility="public">
      <!-- Input: items to be changed; items to be inserted; strings representing the names of 
         the elements that should receive the insertion -->
      <!-- Output: the first items, with the second items inserted in the appropriate place -->
      <!-- This function allows the deep insertion of content -->
      <!-- This function was first written to aid a 2019 version of tan:vocabulary() -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="items-to-be-changed" as="item()*"/>
      <xsl:param name="items-to-insert-as-last-child" as="item()*"/>
      <xsl:param name="names-of-elements-to-receive-action" as="xs:string*"/>
      <xsl:apply-templates select="$items-to-be-changed" mode="tan:insert-content">
         <xsl:with-param name="items-to-insert-as-last-child"
            select="$items-to-insert-as-last-child" tunnel="yes"/>
         <xsl:with-param name="names-of-elements-to-receive-action"
            select="$names-of-elements-to-receive-action" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:insert-content" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:insert-content">
      <xsl:param name="names-of-elements-to-receive-action" tunnel="yes"/>
      <xsl:param name="items-to-insert-as-first-child" tunnel="yes"/>
      <xsl:param name="items-to-insert-as-last-child" tunnel="yes"/>
      <xsl:variable name="allow-insertion" select="name() = $names-of-elements-to-receive-action"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$allow-insertion">
            <xsl:copy-of select="$items-to-insert-as-first-child"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
         <xsl:if test="$allow-insertion">
            <xsl:copy-of select="$items-to-insert-as-last-child"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:strip-text" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:strip-text"/>
   
   
   <xsl:mode name="tan:text-only" on-no-match="text-only-copy"/>
   
   
   <xsl:mode name="tan:prepend-line-break"/>
   
   <xsl:template match="* | processing-instruction() | comment()" mode="tan:prepend-line-break">
      <!-- Useful for breaking up XML content that is not indented -->
      <xsl:text>&#xa;</xsl:text>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   
   <xsl:function name="tan:consolidate-identical-adjacent-divs" as="item()*" visibility="private">
      <!-- Input: various items -->
      <!-- Output: the items, but with any adjacent divs with exactly the same values of @type and @n consolidated -->
      <!-- This function was developed to clean up the results of tan:sequence-to-tree() -->
      <xsl:param name="items-with-divs-to-consolidate" as="item()*"/>
      <xsl:apply-templates select="$items-with-divs-to-consolidate"
         mode="tan:consolidate-identical-adjacent-divs"/>
   </xsl:function>
   
   <xsl:mode name="tan:consolidate-identical-adjacent-divs"/>
   
   <xsl:template match="*[*:div]" mode="tan:consolidate-identical-adjacent-divs">
      <xsl:variable name="these-divs" select="*:div"/>
      <xsl:variable name="this-div-namespace" select="namespace-uri(*:div[1])"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node() except ($these-divs | $these-divs/preceding-sibling::node()[1]/self::text())"/>
         <xsl:for-each-group select="$these-divs"
            group-adjacent="string-join((@type, @n), '#')">
            <xsl:variable name="new-group" as="element()">
               <xsl:element name="div" namespace="{$this-div-namespace}">
                  <xsl:copy-of select="current-group()[1]/@*"/>
                  <xsl:copy-of select="current-group()/node()"/>
               </xsl:element>
            </xsl:variable>
            <xsl:copy-of select="current-group()[1]/preceding-sibling::node()[1]/text()"/>
            <xsl:apply-templates select="$new-group" mode="#current"/>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   
   
   
   <xsl:function name="tan:remove-duplicate-siblings" as="item()*" visibility="public">
      <!-- one-parameter version of larger one, below -->
      <xsl:param name="items-to-process" as="item()*"/>
      <xsl:sequence select="tan:remove-duplicate-siblings($items-to-process, ())"/>
   </xsl:function>
   
   <xsl:function name="tan:remove-duplicate-siblings" as="item()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the same documents after removing duplicate elements whose names match the second parameter. -->
      <!-- This function is applied during document resolution, to prune duplicate elements that might have been included -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="items-to-process" as="document-node()*"/>
      <xsl:param name="element-names-to-check" as="xs:string*"/>
      <xsl:apply-templates select="$items-to-process" mode="tan:remove-duplicate-siblings">
         <xsl:with-param name="element-names-to-check" select="$element-names-to-check"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:remove-duplicate-siblings" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:remove-duplicate-siblings">
      <xsl:param name="element-names-to-check" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="check-this-element" select="not(exists($element-names-to-check))
         or ($element-names-to-check = '*')
         or ($element-names-to-check = name(.))"/>
      <xsl:choose>
         <xsl:when test="
               ($check-this-element = true()) and (some $i in preceding-sibling::*
                  satisfies deep-equal(., $i))"/>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   

   <xsl:function name="tan:reset-hierarchy" as="document-node()*" visibility="private">
      <!-- Input: any expanded class-1 documents whose <div>s may be in the wrong place, because 
         <rename> or <reassign> have altered the <ref> values; a boolean indicating whether misplaced 
         leaf divs should be flagged -->
      <!-- Output: the same documents, with <div>s restored to their proper place in the hierarchy -->
      <!-- This function's templates are in the standard file corresponding to this one; the function 
         wrapper is in the extended set of functions, in case functionality is needed. -->
      <xsl:param name="expanded-class-1-docs" as="document-node()*"/>
      <xsl:param name="flag-misplaced-leaf-divs" as="xs:boolean?"/>
      <xsl:apply-templates select="$expanded-class-1-docs" mode="tan:reset-hierarchy">
         <xsl:with-param name="flag-misplaced-leaf-divs" select="$flag-misplaced-leaf-divs"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   
   <xsl:function name="tan:make-non-mixed" as="item()*" visibility="public">
      <!-- Input: any items that need to be converted to non-mixed content -->
      <!-- Output: the input, but with any text nodes that have siblings and are not outer 
         indentations wrapped in <_text> elements, with a @q containing the value
         of generate-id() for the text node in question. The identifier can be used
         to facilitate comparison with the original.
      -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="input-to-adjust" as="item()*"/>
      <xsl:apply-templates select="$input-to-adjust" mode="tan:make-non-mixed"/>
   </xsl:function>
   

   <xsl:mode name="tan:make-non-mixed" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[text()]" mode="tan:make-non-mixed">
      <xsl:param name="non-space-text-encountered" as="xs:boolean" select="false()"/>
      <xsl:variable name="non-space-text-nodes" as="text()*" select="text()[matches(., '\S')]"/>
      <xsl:variable name="text-children-are-indentation-only" as="xs:boolean" select="not(exists($non-space-text-nodes))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="text-is-indentation" as="xs:boolean" select="$text-children-are-indentation-only"/>
            <xsl:with-param name="non-space-text-encountered"
               select="$non-space-text-encountered or exists($non-space-text-nodes)"/>
            <xsl:with-param name="text-has-no-siblings" as="xs:boolean" select="count(text()) eq 1"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="text()" mode="tan:make-non-mixed">
      <xsl:param name="text-is-indentation" as="xs:boolean" select="not(matches(., '\S'))"/>
      <xsl:param name="text-has-no-siblings" as="xs:boolean"
         select="not(exists(preceding-sibling::node())) and not(exists(following-sibling::node()))"
      />
      <xsl:param name="add-q-id" as="xs:boolean" tunnel="yes" select="true()"/>
      <xsl:choose>
         <xsl:when test="$text-is-indentation or $text-has-no-siblings">
            <xsl:sequence select="."/>
         </xsl:when>
         <xsl:otherwise>
            <_text>
               <xsl:if test="$add-q-id">
                  <xsl:attribute name="q" select="generate-id(.)"/>
               </xsl:if>
               <xsl:sequence select="."/>
            </_text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:function name="tan:wrap-text-nodes" as="item()*" visibility="public">
      <!-- Input: any items where the text should be wrapped -->
      <!-- Output: the items with text nodes wrapped in <_text> with a @q
         containing the value of generate-id() for the text node in question. -->
      <!-- This function is similar to tan:make-non-mixed() but applies wrapping
         universally -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="input-to-adjust" as="item()*"/>
      <xsl:apply-templates select="$input-to-adjust" mode="tan:wrap-text-nodes"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:wrap-text-nodes" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:wrap-text-nodes">
      <_text q="{generate-id(.)}">
         <xsl:sequence select="."/>
      </_text>
   </xsl:template>
   
   
   <xsl:function name="tan:replace-expanded-class-1-body" as="document-node()?" visibility="public">
      <!-- Input: An expanded class-1 file; a string -->
      <!-- Output: the class-1 file, but with the body text replaced with the string, allocated 
         according to tan:diff() -->
      <!-- This function was written to replace a text with a very similar version of itself, perhaps
         altered via normalization, or selective changes. -->
      <!--kw: nodes, diff -->
      <xsl:param name="expanded-class-1-file" as="document-node()?"/>
      <xsl:param name="new-body-text" as="xs:string?"/>
      <xsl:variable name="current-text"
         select="string-join($expanded-class-1-file/tan:TAN-T/tan:body//tan:div[not(tan:div)]/(text() | tan:tok | tan:non-tok))"
      />
      <xsl:variable name="text-diff" select="tan:diff($current-text, $new-body-text, false())"/>
      <xsl:variable name="text-diff-map" select="tan:diff-a-map($text-diff)"/>
      
      <xsl:variable name="input-file-marked" select="tan:stamp-class-1-tree-with-text-data($expanded-class-1-file, true())" as="document-node()?"/>
      
      <xsl:variable name="output-pass-1" as="document-node()?">
         <xsl:apply-templates select="$input-file-marked" mode="tan:replace-expanded-class-1">
            <xsl:with-param name="div-diff-map" tunnel="yes" select="$text-diff-map"/>
         </xsl:apply-templates>
      </xsl:variable>
      
      
      <xsl:variable name="output-diagnostics-on" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Output for tan:replace-expanded-class-1-body() being replaced by diagnostic output.'"/>
            <xsl:document>
               <diagnostics>
                  <current-text><xsl:value-of select="$current-text"/></current-text>
                  <new-body-text><xsl:value-of select="$new-body-text"/></new-body-text>
                  <text-diff><xsl:copy-of select="$text-diff"/></text-diff>
                  <!--<wit2-to-wit-map><xsl:value-of select="map:for-each($text-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></wit2-to-wit-map>-->
                  <input-file-marked><xsl:copy-of select="$input-file-marked"/></input-file-marked>
                  <output-pass-1><xsl:copy-of select="$output-pass-1"/></output-pass-1>
               </diagnostics>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$output-pass-1"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   <xsl:mode name="tan:replace-expanded-class-1" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[@_pos]" mode="tan:replace-expanded-class-1">
      <xsl:copy>
         <xsl:copy-of select="@* except (@_pos | @_len)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div[not(tan:div)]" priority="1" mode="tan:replace-expanded-class-1">
      <xsl:param name="div-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:variable name="this-start" select="xs:integer(@_pos)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:variable name="this-map-value" as="item()*" select="
            for $i in ($this-start to $this-end)
            return
               map:get($div-diff-map, $i)"/>
      <xsl:copy>
         <xsl:copy-of select="@* except (@_pos | @_len)"/>
         <xsl:copy-of select="node() except (text() | tan:tok | tan:non-tok)"/>
         <xsl:value-of select="string-join($this-map-value)"/>
      </xsl:copy>
      
   </xsl:template>
   

   
   <xsl:function name="tan:infuse-tree" as="item()*" visibility="public">
      <!-- Input: a string; an XML fragment that should be infused with the text; a string -->
      <!-- Output: the XML fragment's text nodes replaced with the text proportionate to the 
         length of each text being replaced -->
      <!-- Before applying this function, make sure the tree you send is appropriately
         normalized. No space-normalization will occur, and infusion will occur wherever there
         are indentations. To avoid this behavior, first run tan:strip-outer-indentation()
         or tan:normalize-tree-space()
      -->
      <!-- Document nodes will be ignored. -->
      <!-- Note: if the regular expression allows breaks within words, then a word may be broken
      across two <div>s, which, because of space normalization rules, then winds up inserting a
      space that was not there before. Be sure to use a good regular expression to avoid bad breaks.-->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="string-to-infuse" as="xs:string?"/>
      <xsl:param name="tree-to-infuse" as="item()*"/>
      <xsl:param name="break-at-regex" as="xs:string"/>
      
      <xsl:variable name="break-at-regex-resolved" select="
            if (string-length($break-at-regex) lt 1 or not(tan:regex-is-valid($break-at-regex))) then
               '\s+'
            else
               $break-at-regex"/>
      
      
      <xsl:variable name="mold-adjusted" as="element()">
         <mold>
            <xsl:sequence select="tan:make-non-mixed($tree-to-infuse)"/>
         </mold>
      </xsl:variable>

      <xsl:variable name="mold-stamped" as="element()"
         select="tan:stamp-tree-with-text-data($mold-adjusted, false())"/>
      
      <xsl:variable name="mold-text-wrappers" as="element()*" select="$mold-stamped//*[text()]"/>
      
      <xsl:variable name="mold-text-lengths" as="xs:integer+" select="
            for $i in $mold-text-wrappers/@_len
            return
               xs:integer($i)"/>
      
      <xsl:variable name="new-string-segmented" as="xs:string*"
         select="tan:segment-string($string-to-infuse, tan:numbers-to-portions($mold-text-lengths), $break-at-regex-resolved)"
      />
      
      <xsl:variable name="text-replacement-map" as="map(xs:string,xs:string)">
         <xsl:map>
            <xsl:for-each select="$mold-text-wrappers">
               <xsl:variable name="this-pos" select="position()"/>
               <xsl:map-entry key="string(@_pos)" select="$new-string-segmented[$this-pos]"/>
            </xsl:for-each>
         </xsl:map>
      </xsl:variable>
      

      <xsl:variable name="mold-infused" as="element()">
         <xsl:apply-templates select="$mold-stamped" mode="tan:infuse-tokenized-text">
            <xsl:with-param name="text-replacement-map" tunnel="yes" select="$text-replacement-map"
            />
            <xsl:with-param name="total-length" select="string-length($mold-stamped)" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on tan:infuse-divs()'"/>
         <xsl:message select="'String to infuse: ' || tan:ellipses($string-to-infuse, 50)"/>
         <xsl:message select="'Break at (regex): ' || $break-at-regex-resolved"/>
         <xsl:message select="'Mold adjusted:', $mold-adjusted"/>
         <xsl:message select="'Mold stamped:', $mold-stamped"/>
         <xsl:message select="'Mold text lengths (' || string(count($mold-text-lengths)) || '):', $mold-text-lengths"/>
         <xsl:message select="'String segments (' || string(count($new-string-segmented)) || '): ' || string-join($new-string-segmented, ' ||&#xa;')"/>
         <xsl:message select="'Mold infused: ', $mold-infused"/>
      </xsl:if>
      
      <xsl:copy-of select="$mold-infused/node()" copy-namespaces="no"/>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:infuse-tokenized-text" on-no-match="shallow-copy"/>

   <xsl:template match="@_pos | @_len" mode="tan:infuse-tokenized-text"/>
   <xsl:template match="*[@_pos][text()]" mode="tan:infuse-tokenized-text">
      <xsl:param name="text-replacement-map" as="map(xs:string,xs:string)" tunnel="yes"/>
      <xsl:variable name="this-replacement" select="$text-replacement-map(@_pos)" as="xs:string"/>
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@* except (@_pos | @_len)"/>
         <xsl:value-of select="$this-replacement"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:_text" priority="1" mode="tan:infuse-tokenized-text">
      <xsl:param name="text-replacement-map" as="map(xs:string,xs:string)" tunnel="yes"/>
      <xsl:variable name="this-replacement" select="$text-replacement-map(@_pos)" as="xs:string"/>
      <xsl:value-of select="$this-replacement"/>
   </xsl:template>
   
   
   
   
   
   <xsl:function name="tan:get-namespace-map" as="map(*)" visibility="public">
      <!-- Input: any XML tree fragment -->
      <!-- Output: a map with two entries per namespace, one with the key as the prefix and value
      of the URI, the other with the two items reversed. -->
      <!-- Items are collected deeply through the tree structure, with precedence, in case of contradiction,
      given to the namespaces closest to the root -->
      <!--kw: nodes, namespaces -->
      <xsl:param name="input-tree-fragment" as="item()*"/>
      
      <xsl:variable name="pass-1" as="element()">
         <namespaces>
            <xsl:apply-templates select="$input-tree-fragment" mode="tan:build-namespace-map"/>
         </namespaces>
      </xsl:variable>
      
      <xsl:map>
         <xsl:for-each-group select="$pass-1/*" group-by="@prefix">
            <xsl:variable name="this-prefix" as="xs:string" select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()" group-by="@uri">
               <xsl:if test="position() eq 1">
                  <xsl:map-entry key="$this-prefix" select="current-grouping-key()"/>
               </xsl:if>
            </xsl:for-each-group> 
         </xsl:for-each-group> 
         <xsl:for-each-group select="$pass-1/*" group-by="@uri">
            <xsl:variable name="this-uri" as="xs:string" select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()" group-by="@prefix">
               <xsl:if test="position() eq 1">
                  <xsl:map-entry key="$this-uri" select="current-grouping-key()"/>
               </xsl:if>
            </xsl:for-each-group> 
         </xsl:for-each-group> 
      </xsl:map>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:build-namespace-map" on-no-match="shallow-skip"/>
   
   <xsl:template match="*" mode="tan:build-namespace-map">
      <xsl:variable name="context-el" select="." as="element()"/>
      <xsl:variable name="context-depth" as="xs:integer" select="count(ancestor-or-self::*)"/>
      <xsl:variable name="context-prefixes" select="in-scope-prefixes(.)" as="xs:string*"/>
      <xsl:for-each select="$context-prefixes">
         <ns prefix="{.}" uri="{namespace-uri-for-prefix(., $context-el)}"
            depth="{$context-depth}"/>
      </xsl:for-each>
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   
   <xsl:function name="tan:get-ref" as="xs:string*" visibility="public">
      <!-- Input: any element -->
      <!-- Output: every possible combination of @n values from the self-and-ancestor nodes,
      string-joined by the hierarchy separator. -->
      <!-- This function is useful for handling raw or resolved class 1 files, and you need to 
         get references -->
      <!--kw: nodes, pointers, identifiers -->
      <xsl:param name="class-1-element" as="element()?"/>
      <xsl:variable name="these-attr-ns" as="attribute()*" select="$class-1-element/ancestor-or-self::*/@n"/>
      <xsl:iterate select="$these-attr-ns[matches(., '\S')]">
         <xsl:param name="combinations-so-far" as="xs:string*"/>
         <xsl:on-completion select="$combinations-so-far"/>
         <xsl:variable name="these-vals" select="tokenize(normalize-space(.), ' ')"/>
         <xsl:variable name="current-combinations" as="xs:string*" select="
               if (not(exists($combinations-so-far))) then
                  $these-vals
               else
                  (for $i in $combinations-so-far, $j in $these-vals return $i || $tan:separator-hierarchy || $j)"/>
         <xsl:next-iteration>
            <xsl:with-param name="combinations-so-far" select="$current-combinations"/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:function>
   
   
   
   <xsl:function name="tan:sort-change-log" as="item()*" visibility="public">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="TAN-fragment" as="item()*"/>
      <xsl:sequence select="tan:sort-change-log($TAN-fragment, true(), false())"/>
   </xsl:function>
   
   <xsl:function name="tan:sort-change-log" as="item()*" visibility="public">
      <!-- Input: a TAN fragment; two booleans -->
      <!-- Output: the TAN fragment but with the change log sorted, either by time or agent (1st boolean)
      and either ascending or descending (2nd boolean) -->
      <!--kw: nodes, versioning -->
      <xsl:param name="TAN-fragment" as="item()*"/>
      <xsl:param name="sort-by-time-then-agent" as="xs:boolean?"/>
      <xsl:param name="sort-ascending" as="xs:boolean?"/>
      <xsl:apply-templates select="$TAN-fragment" mode="tan:sort-change-log">
         <xsl:with-param name="sort-by-time-then-agent" tunnel="yes" as="xs:boolean?" select="$sort-by-time-then-agent"/>
         <xsl:with-param name="sort-ascending" tunnel="yes" as="xs:boolean?" select="$sort-ascending"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:sort-change-log" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:head[tan:change]" mode="tan:sort-change-log">
      <xsl:param name="sort-by-time-then-agent" tunnel="yes" as="xs:boolean?" select="true()"/>
      <xsl:param name="sort-ascending" tunnel="yes" as="xs:boolean?" select="false()"/>
      <xsl:variable name="sort-order-val" as="xs:string" select="
            if ($sort-ascending) then
               'ascending'
            else
               'descending'"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="node()" group-adjacent="self::tan:change or (preceding-sibling::tan:change and following-sibling::tan:change)">
            <xsl:choose>
               <xsl:when test="current-grouping-key()">
                  <xsl:for-each-group select="current-group()" group-starting-with="tan:change">
                     <xsl:sort select="
                           if ($sort-by-time-then-agent) then
                              (tan:dateTime-to-decimal(@when))
                           else
                              (sort(tokenize(normalize-space(@who), ' ')))[1]" order="{$sort-order-val}"/>
                     <xsl:sort select="
                           if (not($sort-by-time-then-agent)) then
                              (tan:dateTime-to-decimal(@when))
                           else
                              (sort(tokenize(normalize-space(@who), ' ')))[1]" order="{$sort-order-val}"/>
                     <xsl:copy-of select="current-group()"/>
                  </xsl:for-each-group> 
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="current-group()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:function name="tan:trim-long-tree" as="item()*" visibility="public">
      <!-- Input: an XML tree, two integers -->
      <!-- Output: the tree, anything beyond the shallow-copy point will be shallow-copied
            and anything beyond the deep skip point will be deep-skipped. Comments will always 
            indicate how many nodes were shallow-copied or deep-skipped.
        -->
      <!-- This function was written to truncate large diagnostic output -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="tree-to-trim" as="item()*"/>
      <xsl:param name="shallow-copy-point" as="xs:integer"/>
      <xsl:param name="deep-skip-point" as="xs:integer"/>
      <xsl:apply-templates select="$tree-to-trim" mode="tan:trim-long-tree">
         <xsl:with-param name="shallow-copy-point" tunnel="yes" as="xs:integer" select="$shallow-copy-point"/>
         <xsl:with-param name="deep-skip-point" tunnel="yes" as="xs:integer" select="$deep-skip-point"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:trim-long-tree" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:trim-long-tree">
      <xsl:param name="shallow-copy-point" tunnel="yes" as="xs:integer"/>
      <xsl:param name="deep-skip-point" tunnel="yes" as="xs:integer"/>
      <xsl:variable name="children-to-process" as="node()*" select="node()[position() le $shallow-copy-point]"/>
      <xsl:variable name="children-to-deep-skip" as="node()*" select="node()[position() gt $deep-skip-point]"/>
      <xsl:variable name="children-to-shallow-copy" as="node()*" select="node() except ($children-to-process | $children-to-deep-skip)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="$children-to-process" mode="#current"/>
         <xsl:if test="exists($children-to-shallow-copy)">
            <xsl:text>&#xa;</xsl:text>
            <xsl:comment select="'Trimming next ' || string(count($children-to-shallow-copy)) || ' nodes (shallow copy)'"/>
            <xsl:text>&#xa;</xsl:text>
            <xsl:copy-of select="tan:shallow-copy($children-to-shallow-copy)"/>
         </xsl:if>
         <xsl:if test="exists($children-to-deep-skip)">
            <xsl:text>&#xa;</xsl:text>
            <xsl:comment select="'Trimming next ' || string(count($children-to-deep-skip)) || ' nodes (deep skip)'"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   
   
   <xsl:function name="tan:restore-chopped-tree" as="item()*" visibility="public">
      <!-- Input: a sequence of items -->
      <!-- Output: sequence that attempts to restore the items in a single tree -->
      <!-- This function reverses the effects of tan:chop-tree(), but does so on
         the basis of the chopped fragments, not a map. By default, adjacent items 
         of the same node type are fused into a single node of the same type, except
         for elements, which must have the same name, namespace, and attributes for
         them to be fused. -->
      <!-- kw: nodes, tree manipulation -->
      <xsl:param name="tree-slices" as="item()*"/>
      
      <xsl:for-each-group select="$tree-slices" group-adjacent="tan:item-type(.)">
         <xsl:choose>
            <xsl:when test="current-grouping-key() eq 'document-node'">
               <xsl:document>
                  <xsl:sequence select="tan:restore-chopped-tree(current-group()/node())"/>
               </xsl:document>
            </xsl:when>
            <xsl:when test="current-grouping-key() eq 'comment'">
               <xsl:comment>
                  <xsl:value-of select="string-join(current-group())"/>
               </xsl:comment>
            </xsl:when>
            <xsl:when test="current-grouping-key() eq 'processing-instruction'">
               <xsl:for-each-group select="current-group()" group-adjacent="name(.)">
                  <xsl:processing-instruction name="{current-grouping-key()}">
                     <xsl:value-of select="string-join(current-group())"/>
                  </xsl:processing-instruction>
               </xsl:for-each-group> 
            </xsl:when>
            <xsl:when test="current-grouping-key() eq 'element'">
               <xsl:for-each-group select="current-group()" group-adjacent="tan:element-fingerprint(tan:shallow-copy(.))">
                  <xsl:for-each select="current-group()[1]">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:sequence select="tan:restore-chopped-tree(current-group()/node())"/>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:for-each-group> 
            </xsl:when>
            <xsl:when test="current-grouping-key() eq 'text'">
               <xsl:value-of select="string-join(current-group())"/>
            </xsl:when>
            <xsl:when test="current-grouping-key() eq 'map'">
               <xsl:sequence select="map:merge(current-group())"/>
            </xsl:when>
            <xsl:when test="current-grouping-key() eq 'array'">
               <xsl:sequence select="array:join(current-group())"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="current-group()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each-group> 
      
   </xsl:function>
   
   
   
   
   

   
</xsl:stylesheet>