<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   version="3.0">
   
   <!-- TAN Function Library: standard functions on nodes -->
   
   <xsl:function name="tan:shallow-copy" as="item()*" visibility="public">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="items" as="item()*"/>
      <xsl:copy-of select="tan:shallow-copy($items, 1)"/>
   </xsl:function>
   <xsl:function name="tan:shallow-copy" as="item()*" visibility="public">
      <!-- Input: any document fragment; boolean indicating whether attributes should be kept -->
      <!-- Output: a shallow copy of the fragment -->
      <!-- Attributes will be preserved in a shallow-copied element. -->
      <!-- Maps and arrays will be discarded. -->
      <!-- This function was written to truncate large trees for output to messages and diagnostic
         result trees. -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="items" as="item()*"/>
      <xsl:param name="depth" as="xs:integer"/>
      <xsl:apply-templates select="$items" mode="tan:fn-shallow-copy">
         <xsl:with-param name="levels-to-go" select="$depth"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:fn-shallow-copy" on-no-match="shallow-skip"/>
   
   <xsl:template match="node() | document-node()" mode="tan:fn-shallow-copy">
      <xsl:param name="levels-to-go" as="xs:integer?"/>
      <xsl:if test="$levels-to-go gt 0">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="levels-to-go" select="$levels-to-go - 1"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="tan:xml-to-string" as="xs:string?" visibility="public">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="fragment" as="item()*"/>
      <xsl:value-of select="tan:xml-to-string($fragment, false())"/>
   </xsl:function>
   
   <xsl:function name="tan:xml-to-string" as="xs:string?" visibility="public">
      <!-- Input: any fragment of XML; boolean indicating whether whitespace nodes should be ignored -->
      <!-- Output: a string representation of the fragment -->
      <!-- This function is a proxy of serialize(), used to represent XML fragments in plain text, useful in validation reports or in generating guidelines -->
      <!--kw: nodes, serialization, strings -->
      <xsl:param name="fragment" as="item()*"/>
      <xsl:param name="ignore-whitespace-text-nodes" as="xs:boolean"/>
      <xsl:variable name="results" as="xs:string*">
         <xsl:apply-templates select="$fragment" mode="tan:fragment-to-text">
            <xsl:with-param name="ignore-whitespace-text-nodes"
               select="$ignore-whitespace-text-nodes" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:value-of select="string-join($results, '')"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:fragment-to-text" on-no-match="shallow-skip"/>
   
   <xsl:template match="*" mode="tan:fragment-to-text">
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:choose>
         <xsl:when test="exists(node())">
            <xsl:text>></xsl:text>
            <xsl:apply-templates select="node()" mode="#current"/>
            <xsl:text>&lt;/</xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>></xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text> /></xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="@*" mode="tan:fragment-to-text">
      <xsl:text> </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>='</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>'</xsl:text>
   </xsl:template>
   <xsl:template match="comment()" mode="tan:fragment-to-text">
      <xsl:text>&lt;!--</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>--></xsl:text>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="tan:fragment-to-text">
      <xsl:text>&lt;?</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>?></xsl:text>
   </xsl:template>
   <xsl:template match="text()" mode="tan:fragment-to-text">
      <xsl:param name="ignore-whitespace-text-nodes" tunnel="yes" as="xs:boolean"/>
      <xsl:if test="not($ignore-whitespace-text-nodes) or matches(., '\S')">
         <xsl:value-of select="."/>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="tan:trim-long-text" as="item()*" visibility="public">
      <!-- Input: an XML fragment; an integer -->
      <!-- Output: the fragment with text nodes longer than the integer value abbreviated with an ellipsis -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="xml-fragment" as="item()*"/>
      <xsl:param name="too-long" as="xs:integer"/>
      <xsl:variable name="input-as-node" as="element()">
         <node>
            <xsl:copy-of select="$xml-fragment"/>
         </node>
      </xsl:variable>
      <xsl:apply-templates select="$input-as-node/node()" mode="tan:trim-long-text">
         <xsl:with-param name="too-long" select="$too-long" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:trim-long-text" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:trim-long-text">
      <xsl:param name="too-long" as="xs:integer" tunnel="yes"/>
      <xsl:variable name="this-length" select="string-length(.)"/>
      <xsl:choose>
         <xsl:when test="$this-length ge $too-long and $too-long ge 3">
            <xsl:variable name="portion-length" select="($too-long - 1) idiv 2"/>
            <xsl:value-of select="substring(., 1, $portion-length)"/>
            <xsl:text>…</xsl:text>
            <xsl:value-of select="substring(., ($this-length - $portion-length))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:function name="tan:copy-of-except" as="item()*" visibility="public">
      <!-- short version of the full function, below -->
      <xsl:param name="doc-fragment" as="item()*"/>
      <xsl:param name="exclude-elements-named" as="xs:string*"/>
      <xsl:param name="exclude-attributes-named" as="xs:string*"/>
      <xsl:param name="exclude-elements-with-attributes-named" as="xs:string*"/>
      <xsl:copy-of
         select="tan:copy-of-except($doc-fragment, $exclude-elements-named, $exclude-attributes-named, $exclude-elements-with-attributes-named, (), ())"
      />
   </xsl:function>
   
   <xsl:function name="tan:copy-of-except" as="item()*" visibility="public">
      <!-- Input: any document fragment; sequences of strings specifying names of elements to exclude, names of attributes to exclude, and names of attributes whose parent elements should be excluded; an integer beyond which depth copies should not be made -->
      <!-- Output: the same fragment, altered -->
      <!-- This function was written primarily to service the merge of TAN-A sources, where realigned divs could be extracted from their source documents -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="doc-fragment" as="item()*"/>
      <xsl:param name="exclude-elements-named" as="xs:string*"/>
      <xsl:param name="exclude-attributes-named" as="xs:string*"/>
      <xsl:param name="exclude-elements-with-attributes-named" as="xs:string*"/>
      <xsl:param name="exclude-elements-beyond-what-depth" as="xs:integer?"/>
      <xsl:param name="shallow-skip-elements-named" as="xs:string*"/>

      <xsl:apply-templates select="$doc-fragment" mode="tan:copy-of-except">
         <xsl:with-param name="exclude-elements-named" as="xs:string*"
            select="$exclude-elements-named" tunnel="yes"/>
         <xsl:with-param name="exclude-attributes-named" as="xs:string*"
            select="$exclude-attributes-named" tunnel="yes"/>
         <xsl:with-param name="exclude-elements-with-attributes-named" as="xs:string*"
            select="$exclude-elements-with-attributes-named" tunnel="yes"/>
         <xsl:with-param name="exclude-elements-beyond-what-depth"
            select="$exclude-elements-beyond-what-depth" tunnel="yes"/>
         <xsl:with-param name="current-depth" select="0"/>
         <xsl:with-param name="shallow-skip-elements-named" select="$shallow-skip-elements-named"
            tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:copy-of-except" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:copy-of-except">
      <xsl:param name="exclude-elements-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="exclude-elements-named-regex" as="xs:string?" tunnel="yes"/>
      <xsl:param name="exclude-elements-not-named-regex" as="xs:string?" tunnel="yes"/>
      <xsl:param name="exclude-attributes-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="exclude-elements-with-attributes-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="exclude-elements-beyond-what-depth" as="xs:integer?" tunnel="yes"/>
      <xsl:param name="shallow-skip-elements-named" as="xs:string*" tunnel="yes"/>
      <xsl:param name="current-depth" as="xs:integer?"/>
      
      <xsl:variable name="this-local-name" select="local-name(.)"/>
      <xsl:choose>
         <xsl:when test="$this-local-name = $exclude-elements-named"/>
         <xsl:when
            test="string-length($exclude-elements-named-regex) gt 0 and matches($this-local-name, $exclude-elements-named-regex)"
         />
         <xsl:when
            test="string-length($exclude-elements-not-named-regex) gt 0 and not(matches($this-local-name, $exclude-elements-not-named-regex))"
         />
         <xsl:when test="$this-local-name = $shallow-skip-elements-named">
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="current-depth" select="
                     if (exists($current-depth)) then
                        $current-depth + 1
                     else
                        ()"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:when test="
               not(some $i in @*
                  satisfies local-name($i) = $exclude-elements-with-attributes-named)
               and not($current-depth ge $exclude-elements-beyond-what-depth)">
            <xsl:copy>
               <xsl:copy-of select="@*[not(local-name() = $exclude-attributes-named)]"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="current-depth" select="
                        if (exists($current-depth)) then
                           $current-depth + 1
                        else
                           ()"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:mode name="tan:strip-attributes" on-no-match="shallow-copy"/>
   
   <xsl:template match="@*" mode="tan:strip-attributes"/>
   
   
   <xsl:mode name="tan:strip-duplicate-children-by-attribute-value" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:strip-duplicate-children-by-attribute-value">
      <xsl:param name="attribute-to-check" as="xs:string"/>
      <xsl:param name="keep-last-duplicate" as="xs:boolean"/>
      <!-- This template is used for merging sets of elements. -->
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="*" group-by="
               if (exists(@*[name(.) = $attribute-to-check])) then
                  @*[name(.) = $attribute-to-check]
               else
                  generate-id()">
            <xsl:choose>
               <xsl:when
                  test="(string-length(current-grouping-key()) gt 0) and (count(current-group()) gt 1)">
                  <xsl:copy-of select="
                        current-group()[if ($keep-last-duplicate) then
                           last()
                        else
                           1]"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="current-group()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:function name="tan:group-elements-by-shared-node-values" as="element()*" visibility="public">
      <!-- One-parameter version of the fuller one below.  -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:copy-of select="tan:group-elements-by-shared-node-values($elements-to-group, ())"/>
   </xsl:function>
   <xsl:function name="tan:group-elements-by-IRI" as="element()*" visibility="private">
      <!-- One-parameter version of the fuller one below.  -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:copy-of select="tan:group-elements-by-shared-node-values($elements-to-group, '^IRI$')"/>
   </xsl:function>
   <xsl:function name="tan:group-divs-by-ref" as="element()*" visibility="private">
      <!-- One-parameter version of the fuller one below.  -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:copy-of select="tan:group-elements-by-shared-node-values($elements-to-group, '^ref$')"/>
   </xsl:function>
   <xsl:function name="tan:group-elements-by-shared-node-values" as="element()*" visibility="public">
      <!-- Two-parameter version of the fuller one below -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:param name="regex-of-names-of-nodes-to-group-by" as="xs:string?"/>
      <xsl:copy-of select="tan:group-elements-by-shared-node-values($elements-to-group, $regex-of-names-of-nodes-to-group-by, false())"/>
   </xsl:function>
   <xsl:function name="tan:group-elements-by-shared-node-values" as="element()*" visibility="public">
      <!-- Input: a sequence of elements; an optional string representing the name of children in the elements -->
      <!-- Output: the same elements, but grouped in <group> according to whether the text contents of the child elements specified are equal -->
      <!-- Each <group> will have an @n stipulating the position of the first element put in the group. That way the results can be sorted in 
         order of their original elements -->
      <!-- Transitivity is assumed. Suppose elements X, Y, and Z have children values A and B; B and C; and C and D, respectively. All 
         three elements will be grouped, even though Y and Z do not directly share children values.  -->
      <!--kw: nodes, grouping -->
      <xsl:param name="elements-to-group" as="element()*"/>
      <xsl:param name="regex-of-names-of-nodes-to-group-by" as="xs:string?"/>
      <xsl:param name="group-by-shallow-node-value" as="xs:boolean"/>
      
      <xsl:variable name="group-by-all-children" as="xs:boolean"
         select="string-length($regex-of-names-of-nodes-to-group-by) lt 1 or $regex-of-names-of-nodes-to-group-by = '*' 
         or not(tan:regex-is-valid($regex-of-names-of-nodes-to-group-by))"
      />
      <xsl:variable name="elements-prepped-pass-1" as="element()*">
         <xsl:for-each select="$elements-to-group">
            <xsl:variable name="these-grouping-key-nodes" select="descendant::node()[matches(name(.), $regex-of-names-of-nodes-to-group-by)]"/>
            <item n="{position()}">
               <xsl:choose>
                  <xsl:when test="$group-by-all-children">
                     <xsl:apply-templates select="node()" mode="tan:build-grouping-key">
                        <xsl:with-param name="group-by-shallow-node-value"
                           select="$group-by-shallow-node-value"/>
                     </xsl:apply-templates>
                  </xsl:when>
                  <xsl:when test="not(exists($these-grouping-key-nodes))">
                     <grouping-key/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates
                        select="$these-grouping-key-nodes"
                        mode="tan:build-grouping-key">
                        <xsl:with-param name="group-by-shallow-node-value"
                           select="$group-by-shallow-node-value"/>
                     </xsl:apply-templates>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:copy-of select="."/>
            </item>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="duplicate-grouping-keys" select="tan:duplicate-items($elements-prepped-pass-1/tan:grouping-key)"/>
      <xsl:variable name="elements-prepped-pass-2" as="element()*">
         <xsl:for-each select="$elements-prepped-pass-1">
            <xsl:choose>
               <xsl:when test="tan:grouping-key = $duplicate-grouping-keys">
                  <xsl:copy-of select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <group>
                     <xsl:copy-of select="@n"/>
                     <xsl:copy-of select="*"/>
                  </group>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable> 
      <xsl:variable name="items-with-duplicatative-keys-grouped" select="tan:group-elements-by-shared-node-values-loop($elements-prepped-pass-2/self::tan:item, (), 0)"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:group-elements-by-shared-node-values()'"/>
         <xsl:message select="'elements to group: ', $elements-to-group"/>
         <xsl:message select="'name of node to group by (regular expression): ', $regex-of-names-of-nodes-to-group-by"/>
         <xsl:message select="'group by the shallow value of the node?', $group-by-shallow-node-value"/>
         <xsl:message select="'group by all children?', $group-by-all-children"/>
         <xsl:message select="'pass 1: ', $elements-prepped-pass-1"/>
         <xsl:message select="'duplicate grouping keys: ', $duplicate-grouping-keys"/>
         <xsl:message select="'pass 2 (pregrouped items that have unique keys): ', $elements-prepped-pass-2"/>
         <xsl:message select="'pass 3 (items with duplicative keys grouped): ', $items-with-duplicatative-keys-grouped"/>
      </xsl:if>
      
      <xsl:for-each select="$elements-prepped-pass-2/self::tan:group, $items-with-duplicatative-keys-grouped">
         <xsl:sort select="number(@n)"/>
         <xsl:copy>
            <xsl:copy-of select="@n"/>
            <xsl:copy-of select="* except tan:grouping-key"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:mode name="tan:build-grouping-key" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:build-grouping-key">
      <grouping-key>
         <xsl:value-of select="."/>
      </grouping-key>
   </xsl:template>
   
   <xsl:template match="*" mode="tan:build-grouping-key">
      <xsl:param name="group-by-shallow-node-value" as="xs:boolean?"/>
      <xsl:choose>
         <xsl:when test="$group-by-shallow-node-value">
            <xsl:apply-templates select="text()" mode="#current"/>
         </xsl:when>
         <xsl:otherwise>
            <grouping-key>
               <xsl:value-of select="."/>
            </grouping-key>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:function name="tan:group-elements-by-shared-node-values-loop" as="element()*" visibility="private">
      <!-- supporting loop for the function above -->
      <xsl:param name="items-to-group" as="element()*"/>
      <xsl:param name="groups-so-far" as="element()*"/>
      <xsl:param name="loop-count" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="count($items-to-group) lt 1">
            <xsl:copy-of select="$groups-so-far"/>
         </xsl:when>
         <xsl:when test="$loop-count gt $tan:loop-tolerance">
            <xsl:message select="'loop exceeds tolerance'"/>
            <xsl:copy-of select="$groups-so-far"/>
            <xsl:for-each select="$items-to-group">
               <group>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="*"/>
               </group>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="next-item" select="$items-to-group[1]"/>
            <xsl:variable name="related-items" select="$items-to-group[tan:grouping-key = $next-item/tan:grouping-key]"/>
            <xsl:variable name="groups-that-match" select="$groups-so-far[tan:grouping-key = $related-items/tan:grouping-key]"/>
            <xsl:variable name="new-group" as="element()">
               <group>
                  <xsl:copy-of select="($groups-that-match/@n, $related-items/@n)[1]"/>
                  <xsl:copy-of select="$groups-that-match/*, $related-items/*"/>
               </group>
            </xsl:variable>
            <xsl:copy-of
               select="tan:group-elements-by-shared-node-values-loop(($items-to-group except $related-items), (($groups-so-far except $groups-that-match), $new-group), $loop-count +1)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:function name="tan:element-fingerprint" as="xs:string*" visibility="public">
      <!-- Input: any elements -->
      <!-- Output: for each element the string value of its name, its namespace, its attributes, and all descendant nodes -->
      <!-- This function is useful for determining whether any number of elements are deeply equal -->
      <!-- The built-in function deep-equal() works for pairs of elements; this looks for a way to evaluate sequences of elements -->
      <!--kw: nodes, identifiers -->
      <xsl:param name="element" as="element()*"/>
      <xsl:for-each select="$element">
         <xsl:variable name="results" as="xs:string*">
            <xsl:apply-templates select="$element" mode="tan:element-fingerprint"/>
         </xsl:variable>
         <xsl:value-of select="string-join($results, '')"/>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:mode name="tan:element-fingerprint" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:element-fingerprint">
      <xsl:text>e#</xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>ns#</xsl:text>
      <xsl:value-of select="namespace-uri()"/>
      <xsl:text>aa#</xsl:text>
      <xsl:for-each select="@*">
         <xsl:sort select="name()"/>
         <xsl:text>a#</xsl:text>
         <xsl:value-of select="name()"/>
         <xsl:text>#</xsl:text>
         <xsl:value-of select="normalize-space(.)"/>
         <xsl:text>#</xsl:text>
      </xsl:for-each>
      <xsl:apply-templates select="node()" mode="#current"/>
   </xsl:template>
   <!-- We presume (perhaps wrongly) that comments and pi's in an element don't matter -->
   <xsl:template match="comment() | processing-instruction()" mode="tan:element-fingerprint"/>
   <xsl:template match="text()" mode="tan:element-fingerprint">
      <xsl:if test="matches(., '\S')">
         <xsl:text>t#</xsl:text>
         <xsl:value-of select="normalize-space(.)"/>
         <xsl:text>#</xsl:text>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="tan:stamp-q-id" as="item()*" visibility="public">
      <!-- 1-param version of the full one below -->
      <xsl:param name="items-to-stamp" as="item()*"/>
      <xsl:copy-of select="tan:stamp-q-id($items-to-stamp, false())"/>
   </xsl:function>
   <xsl:function name="tan:stamp-q-id" as="item()*" visibility="public">
      <!-- Input: any XML fragments -->
      <!-- Output: the fragments with @q added to each element via generate-id() -->
      <!--kw: nodes, identifiers -->
      <xsl:param name="items-to-stamp" as="item()*"/>
      <xsl:param name="stamp-shallowly" as="xs:boolean"/>
      <xsl:apply-templates select="$items-to-stamp" mode="tan:stamp-q-id">
         <xsl:with-param name="stamp-shallowly" select="$stamp-shallowly" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode on-no-match="shallow-copy" name="tan:stamp-q-id"/>
   
   <xsl:template match="*" mode="tan:stamp-q-id">
      <xsl:param name="stamp-shallowly" as="xs:boolean" tunnel="yes" select="false()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="q" select="generate-id(.)"/>
         <xsl:choose>
            <xsl:when test="$stamp-shallowly">
               <xsl:copy-of select="node()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:function name="tan:indent-value" as="xs:integer*" visibility="private">
      <!-- Input: elements -->
      <!-- Output: the length of their indentation -->
      <xsl:param name="elements" as="element()*"/>
      <xsl:variable name="ancestor-preceding-text-nodes" as="xs:string*">
         <xsl:for-each select="$elements">
            <xsl:variable name="this-preceding-white-space-text-node"
               select="preceding-sibling::node()[1]/self::text()[not(matches(., '\S'))]"/>
            <xsl:choose>
               <xsl:when test="string-length($this-preceding-white-space-text-node) gt 0">
                  <!-- strip away the line feed and anything preceding it -->
                  <xsl:value-of select="replace($this-preceding-white-space-text-node, '.*\n', '')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="''"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:sequence select="
            for $i in $ancestor-preceding-text-nodes
            return
               string-length($i)"/>
   </xsl:function>
   
   <xsl:function name="tan:copy-indentation" as="item()*" visibility="public">
      <!-- 2-parameter version of fuller one below -->
      <xsl:param name="items-to-indent" as="item()*"/>
      <xsl:param name="model-element" as="element()"/>
      <xsl:sequence select="tan:copy-indentation($items-to-indent, $model-element, 'short')"/>
   </xsl:function>
   <xsl:function name="tan:copy-indentation" as="item()*" visibility="public">
      <!-- Input: items that should be indented; an element whose indentation should be imitated; a string: 'full', 'short', or 'none' -->
      <!-- Output: the items, indented according to the pattern -->
      <!-- If the third parameter is 'full', the last indentation after the series will be like the first; if it is 'short', it will
      be one indentation less than full (appropriate for the last child of a wrapping element); if it is 'none' no final indentation
      will be supplied. This parameter affects only the topmost sequence, not the children, which are formatted as demanded. -->
      <!--kw: nodes, tree manipulation, spacing-->
      <xsl:param name="items-to-indent" as="item()*"/>
      <xsl:param name="model-element" as="element()"/>
      <xsl:param name="tail-indentation-type" as="xs:string?"/>
      <!-- short tail indentation is the default -->
      <xsl:variable name="tail-type-norm" select="($tail-indentation-type[. = ('full', 'none')], 'short')[1]"/>
      <xsl:variable name="model-ancestors" select="$model-element/ancestor-or-self::*"/>
      <xsl:variable name="inherited-indentation-quantities" select="tan:indent-value($model-ancestors)"/>
      <xsl:variable name="this-default-indentation" select="
            if (count($model-ancestors) gt 1) then
               ceiling($inherited-indentation-quantities[last()] idiv (count($model-ancestors) - 1))
            else
               $tan:default-indent-value"/>
      <xsl:apply-templates select="$items-to-indent[not(position() eq last())]" mode="tan:indent-items">
         <xsl:with-param name="current-context-average-indentation" select="$inherited-indentation-quantities[last()]"/>
         <xsl:with-param name="default-indentation-increase" select="$this-default-indentation" tunnel="yes"/>
         <xsl:with-param name="tail-indentation-type" select="'none'"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="$items-to-indent[last()]" mode="tan:indent-items">
         <xsl:with-param name="current-context-average-indentation" select="$inherited-indentation-quantities[last()]"/>
         <xsl:with-param name="default-indentation-increase" select="$this-default-indentation" tunnel="yes"/>
         <xsl:with-param name="tail-indentation-type" select="$tail-type-norm"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:indent-items" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:indent-items">
      <xsl:param name="current-context-average-indentation" as="xs:integer"/>
      <xsl:param name="default-indentation-increase" as="xs:integer" tunnel="yes"/>
      <xsl:param name="tail-indentation-type" as="xs:string" select="'short'"/>
      <xsl:variable name="has-mixed-content" select="exists(*) and exists(text()[matches(., '\S')])"/>
      
      <xsl:value-of select="'&#xa;' || tan:fill(' ', $current-context-average-indentation)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="$has-mixed-content">
               <xsl:copy-of select="node()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="current-context-average-indentation"
                     select="$current-context-average-indentation + $default-indentation-increase"/>
               </xsl:apply-templates>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
      <xsl:if test="not(exists(following-sibling::*))">
         <xsl:choose>
            <xsl:when test="$tail-indentation-type eq 'none'"/>
            <xsl:when test="$tail-indentation-type eq 'full'">
               <xsl:value-of select="'&#xa;' || tan:fill(' ', ($current-context-average-indentation))"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="'&#xa;' || tan:fill(' ', ($current-context-average-indentation - $default-indentation-increase))"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="text()" mode="tan:indent-items">
      <xsl:if test="matches(., '\S')">
         <xsl:value-of select="."/>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="tan:attr" as="attribute()?" visibility="public">
      <!-- Input: two strings -->
      <!-- Output: an attribute by the name of the first string, with the value of the second -->
      <!--kw: nodes, attributes -->
      <xsl:param name="attribute-name" as="xs:string?"/>
      <xsl:param name="attribute-value" as="xs:string?"/>
      <xsl:choose>
         <xsl:when test="$attribute-name castable as xs:NCName">
            <xsl:attribute name="{$attribute-name}" select="$attribute-value"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message select="$attribute-name, ' is not a legal attribute name'"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:path" as="xs:string*" visibility="public">
      <!-- Input: any nodes -->
      <!-- Output: the path of each node -->
      <!--kw: nodes -->
      <xsl:param name="nodes" as="node()*"/>
      <xsl:for-each select="$nodes">
         <xsl:variable name="this-node" select="."/>
         <xsl:variable name="these-steps" as="xs:string*">
            <xsl:for-each select="ancestor-or-self::node()">
               <xsl:variable name="this-step" select="."/>
               <xsl:variable name="this-name" select="name(.)"/>
               <xsl:variable name="preceding-siblings-with-same-name"
                  select="preceding-sibling::node()[name() = $this-name]"/>
               <xsl:variable name="this-filter" as="xs:string?">
                  <xsl:if test="string-length($this-name) gt 0">
                     <xsl:value-of
                        select="'[' || string(count($preceding-siblings-with-same-name) + 1) || ']'"
                     />
                  </xsl:if>
               </xsl:variable>
               <xsl:value-of select="$this-name || $this-filter"/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:value-of select="string-join($these-steps, '/')"/>
      </xsl:for-each>
   </xsl:function>
   
   
   <!-- TAN-specific -->
   
   <xsl:function name="tan:tan-type" as="xs:string*" visibility="private">
      <!-- Input: any nodes -->
      <!-- Output: the names of the root elements; if not present, a zero-length string is returned -->
      <xsl:param name="nodes" as="node()*"/>
      <xsl:for-each select="$nodes/root()/*">
         <xsl:value-of select="local-name(.)"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:class-number" as="xs:integer*" visibility="private">
      <!-- Input: any nodes of a TAN document -->
      <!-- Output: one integer per node, specifying the TAN class for the file, based on the name of the root element. If no match is found in the root element, 0 is returned -->
      <xsl:param name="nodes" as="node()*"/>
      <xsl:for-each select="$nodes">
         <xsl:variable name="this-root-name" select="tan:tan-type(.)"/>
         <xsl:variable name="this-class" as="xs:integer?"
            select="xs:integer($tan:tan-classes/tan:class[tan:root = $this-root-name]/@n)"/>
         <xsl:sequence select="
               if (exists($this-class)) then
                  $this-class
               else
                  0"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:must-refer-to-external-tan-file" as="xs:boolean" visibility="private">
      <!-- Input: node in a TAN document. -->
      <!-- Output: boolean value indicating whether the node or its parent must name or refer to a TAN file. -->
      <xsl:param name="node" as="node()"/>
      <xsl:variable name="class-2-elements-that-must-always-refer-to-tan-files" select="('source')"/>
      <xsl:variable name="this-class" select="tan:class-number($node)"/>
      <xsl:value-of select="
            if (
               ((name($node),
               name($node/parent::node())) = $tan:names-of-elements-that-must-always-refer-to-tan-files)
               or ((((name($node),
               name($node/parent::node())) = $class-2-elements-that-must-always-refer-to-tan-files)
               )
               and $this-class = 2)
            )
            then
               true()
            else
               false()"/>
   </xsl:function>
   
   <xsl:function name="tan:doc-id-namespace" as="xs:string?" visibility="private">
      <!-- Input: an item from a TAN file -->
      <!-- Output: the namespace of the doc's @id -->
      <xsl:param name="TAN-doc" as="item()?"/>
      <xsl:variable name="this-id" select="root($TAN-doc)/*/@id"/>
      <xsl:if test="string-length($this-id) gt 0">
         <xsl:analyze-string select="$this-id" regex="^tag:[^:]+">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:last-change-agent" as="element()*" visibility="public">
      <!-- Input: any TAN document -->
      <!-- Output: the <person>, <organization>, or <algorithm> who made the last change -->
      <!--kw: nodes-->
      <xsl:param name="TAN-doc" as="document-node()*"/>
      <xsl:for-each select="$TAN-doc">
         <xsl:variable name="this-doc" select="."/>
         <xsl:variable name="this-doc-history" select="tan:get-doc-history(.)"/>
         <xsl:variable name="this-doc-head" select="$this-doc/*/tan:head"/>
         <xsl:variable name="last-change" select="$this-doc-history/*[@who][1]"/>
         <xsl:if test="exists($this-doc-head)">
            <xsl:copy-of
               select="tan:vocabulary(('person', 'organization', 'algorithm'), $last-change/@who, $this-doc/*/tan:head)/*"
            />
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:all-conditions-hold" as="xs:boolean?" visibility="private">
      <!-- 2-param version of the master one, below -->
      <xsl:param name="element-with-condition-attributes" as="element()?"/>
      <xsl:param name="context-to-evaluate-against" as="item()*"/>
      <xsl:copy-of
         select="tan:all-conditions-hold($element-with-condition-attributes, $context-to-evaluate-against, (), true())"
      />
   </xsl:function>
   <xsl:function name="tan:all-conditions-hold" as="xs:boolean" visibility="private">
      <!-- Input: a TAN element with attributes that should be checked for their truth value; a context against which to check the values; an optional sequence of strings indicates the names of elements that should be processed and in what order; a boolean indicating what value to return by default -->
      <!-- Output: true, if every condition holds; false otherwise -->
      <!-- If no conditions are found, the output reverts to the default -->
      <xsl:param name="element-with-condition-attributes" as="element()?"/>
      <xsl:param name="context-to-evaluate-against" as="item()*"/>
      <xsl:param name="evaluation-sequence" as="xs:string*"/>
      <xsl:param name="default-value" as="xs:boolean"/>
      <xsl:variable name="element-with-condition-attributes-sorted-and-distributed" as="element()*">
         <xsl:for-each select="$element-with-condition-attributes/@*">
            <xsl:sort select="(index-of($evaluation-sequence, name(.)), 999)[1]"/>
            <where>
               <xsl:copy-of select="."/>
            </where>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="loop-results" as="xs:boolean"
         select="tan:all-conditions-hold-evaluation-loop($element-with-condition-attributes-sorted-and-distributed, $context-to-evaluate-against, $default-value)"
      />
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:conditions-hold()'"/>
         <xsl:message select="'element with condition attributes: ', $element-with-condition-attributes"/>
         <xsl:message select="'context to evaluate against: ', $context-to-evaluate-against"/>
         <xsl:message select="'evaluation sequence: ', $evaluation-sequence"/>
         <xsl:message select="'conditions sorted and distributed: ', $element-with-condition-attributes-sorted-and-distributed"/>
         <xsl:message select="'loop results: ', $loop-results"/>
      </xsl:if>
      <xsl:value-of select="$loop-results"/>
   </xsl:function>
   <xsl:function name="tan:all-conditions-hold-evaluation-loop" as="xs:boolean" visibility="private">
      <!-- Companion function to the one above, indicating whether every condition holds -->
      <!-- This loop function iterates through elements with condition attributes and checks each against the context; if a false is found, the loop ends returning false; if no conditions are found the default value is returned; otherwise it returns true -->
      <!-- We use a loop function to avoid evaluating conditions that might be time-consuming -->
      <xsl:param name="elements-with-condition-attributes-to-be-evaluated" as="element()*"/>
      <xsl:param name="context-to-evaluate-against" as="item()*"/>
      <xsl:param name="current-value" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when test="not(exists($elements-with-condition-attributes-to-be-evaluated))">
            <xsl:value-of select="$current-value"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="next-element-to-evaluate"
               select="$elements-with-condition-attributes-to-be-evaluated[1]"/>
            <xsl:variable name="this-analysis" as="element()">
               <xsl:apply-templates select="$next-element-to-evaluate" mode="tan:evaluate-conditions">
                  <xsl:with-param name="context" select="$context-to-evaluate-against" tunnel="yes"
                  />
               </xsl:apply-templates>
            </xsl:variable>
            <xsl:choose>
               <xsl:when test="$this-analysis/@* = false()">
                  <xsl:copy-of select="false()"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of
                     select="tan:all-conditions-hold-evaluation-loop($elements-with-condition-attributes-to-be-evaluated[position() gt 1], $context-to-evaluate-against, true())"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:mode name="tan:evaluate-conditions" on-no-match="shallow-skip"/>
   
   <xsl:template match="*" mode="tan:evaluate-conditions">
      <xsl:copy>
         <xsl:apply-templates select="@*" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <!-- If an unknown attribute is encountered, skip it -->
   <xsl:template match="@*" mode="tan:evaluate-conditions"/>
   
   <!-- Otherwise execute the following. -->
   <!-- TAN-A-lm -->
   <xsl:template match="@m-matches" mode="tan:evaluate-conditions">
      <xsl:param name="context" tunnel="yes"/>
      <xsl:attribute name="{name()}">
         <xsl:value-of select="matches($context/text()[1], .)"/>
      </xsl:attribute>
   </xsl:template>
   
   <xsl:template match="@m-has-how-many-features | @m-has-how-many-codes" mode="tan:evaluate-conditions">
      <!-- @m-has-how-many-features was renamed @m-has-how-many-codes in 2021; the older name is 
         retained for legacy -->
      <xsl:param name="context" tunnel="yes"/>
      <xsl:variable name="this-val" select="tan:expand-numerical-expression(., 999)"/>
      <xsl:attribute name="{name()}">
         <xsl:value-of select="count($context/tan:f[text()]) = $this-val"/>
      </xsl:attribute>
   </xsl:template>
   
   <xsl:template match="@m-has-features | @m-has-codes" mode="tan:evaluate-conditions">
      <!-- @m-has-features was renamed @m-has-codes in 2021; the older name is retained for legacy -->
      <xsl:param name="context" tunnel="yes"/>
      <xsl:variable name="these-conditions" as="element()*">
         <xsl:analyze-string select="." regex="(\+ )?\S+">
            <xsl:matching-substring>
               <xsl:variable name="this-item" as="xs:string+" select="tokenize(., ' ')"/>
               <xsl:element name="{if (count($this-item) gt 1) then 'and' else 'feature'}">
                  <xsl:value-of select="$this-item[last()]"/>
               </xsl:element>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="these-conditions-pass-2" as="element()*">
         <xsl:for-each-group select="$these-conditions" group-starting-with="tan:feature">
            <group>
               <xsl:for-each select="current-group()">
                  <feature>
                     <xsl:value-of select="."/>
                  </feature>
               </xsl:for-each>
            </group>
         </xsl:for-each-group>
      </xsl:variable>

      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'= = Diagnostics on template mode tan:evaluate-conditions on @' || name(.) || ' with value ' || string(.)"/>
         <xsl:message select="'Context: ', $context"/>
         <xsl:message select="'Conditions pass 1:', $these-conditions"/>
         <xsl:message select="'Conditions pass 2:', $these-conditions-pass-2"/>
         
      </xsl:if>
      <xsl:attribute name="{name(.)}">
         <xsl:value-of select="
               some $i in $these-conditions-pass-2
                  satisfies
                  every $j in $i/tan:feature
                     satisfies
                     $context/tan:f = $j"/>
      </xsl:attribute>
   </xsl:template>
   
   <xsl:template match="@tok-matches" mode="tan:evaluate-conditions">
      <xsl:param name="context" tunnel="yes"/>
      <xsl:variable name="this-val" select="."/>
      <xsl:attribute name="{name()}">
         <xsl:value-of select="
               some $i in $context/ancestor::tan:ana//tan:tok/tan:result
                  satisfies tan:matches($i, tan:escape($this-val))"/>
      </xsl:attribute>
   </xsl:template>
   
   
   <xsl:function name="tan:data-type-check" as="xs:boolean" visibility="public">
      <!-- Input: an item and a string naming a data type -->
      <!-- Output: a boolean indicating whether the item can be cast into that data type -->
      <!-- If the first parameter doesn't match a data type, the function returns false -->
      <!--kw: nodes, datatypes -->
      <xsl:param name="item" as="item()?"/>
      <xsl:param name="data-type" as="xs:string"/>
      <xsl:choose>
         <xsl:when test="$data-type eq 'string'">
            <xsl:sequence select="$item castable as xs:string"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'boolean'">
            <xsl:sequence select="$item castable as xs:boolean"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'decimal'">
            <xsl:sequence select="$item castable as xs:decimal"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'float'">
            <xsl:sequence select="$item castable as xs:float"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'double'">
            <xsl:sequence select="$item castable as xs:double"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'duration'">
            <xsl:sequence select="$item castable as xs:duration"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'dateTime'">
            <xsl:sequence select="$item castable as xs:dateTime"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'time'">
            <xsl:sequence select="$item castable as xs:time"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'date'">
            <xsl:sequence select="$item castable as xs:date"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'gYearMonth'">
            <xsl:sequence select="$item castable as xs:gYearMonth"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'gYear'">
            <xsl:sequence select="$item castable as xs:gYear"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'gMonthDay'">
            <xsl:sequence select="$item castable as xs:gMonthDay"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'gDay'">
            <xsl:sequence select="$item castable as xs:gDay"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'gMonth'">
            <xsl:sequence select="$item castable as xs:gMonth"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'hexBinary'">
            <xsl:sequence select="$item castable as xs:hexBinary"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'base64Binary'">
            <xsl:sequence select="$item castable as xs:base64Binary"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'anyURI'">
            <xsl:sequence select="$item castable as xs:anyURI"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'QName'">
            <xsl:sequence select="$item castable as xs:QName"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'normalizedString'">
            <xsl:sequence select="$item castable as xs:normalizedString"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'token'">
            <xsl:sequence select="$item castable as xs:token"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'language'">
            <xsl:sequence select="$item castable as xs:language"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'NMTOKEN'">
            <xsl:sequence select="$item castable as xs:NMTOKEN"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'NMTOKENS'">
            <xsl:sequence select="$item castable as xs:NMTOKENS"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'Name'">
            <xsl:sequence select="$item castable as xs:Name"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'NCName'">
            <xsl:sequence select="$item castable as xs:NCName"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'ID'">
            <xsl:sequence select="$item castable as xs:ID"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'IDREF'">
            <xsl:sequence select="$item castable as xs:IDREF"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'IDREFS'">
            <xsl:sequence select="$item castable as xs:IDREFS"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'ENTITY'">
            <xsl:sequence select="$item castable as xs:ENTITY"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'ENTITIES'">
            <xsl:sequence select="$item castable as xs:ENTITIES"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'integer'">
            <xsl:sequence select="$item castable as xs:integer"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'nonPositiveInteger'">
            <xsl:sequence select="$item castable as xs:nonPositiveInteger"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'negativeInteger'">
            <xsl:sequence select="$item castable as xs:negativeInteger"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'long'">
            <xsl:sequence select="$item castable as xs:long"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'int'">
            <xsl:sequence select="$item castable as xs:int"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'short'">
            <xsl:sequence select="$item castable as xs:short"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'byte'">
            <xsl:sequence select="$item castable as xs:byte"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'nonNegativeInteger'">
            <xsl:sequence select="$item castable as xs:nonNegativeInteger"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'unsignedLong'">
            <xsl:sequence select="$item castable as xs:unsignedLong"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'unsignedInt'">
            <xsl:sequence select="$item castable as xs:unsignedInt"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'unsignedShort'">
            <xsl:sequence select="$item castable as xs:unsignedShort"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'unsignedByte'">
            <xsl:sequence select="$item castable as xs:unsignedByte"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'positiveInteger'">
            <xsl:sequence select="$item castable as xs:positiveInteger"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'IDREF'">
            <xsl:sequence select="count(root($item)//id($item)) eq 1"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'IDREFS'">
            <xsl:sequence select="exists(root($item)//id($item))"/>
         </xsl:when>
         <xsl:when test="$data-type eq 'language'">
            <xsl:sequence select="matches($item, '^[a-z]{2,3}(-[A-Z]{2,3}(-[a-zA-Z]{4})?)?$')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="false()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   
   <xsl:function name="tan:stamp-class-1-tree-with-text-data" as="item()*" visibility="private">
      <!-- Input: a tree fragment; a boolean -->
      <!-- Output: the tree stamped with @_pos and @_len; if the boolean is true then the
      scope is restricted to the body without children; if false, it is presumed to be merely
      raw or resolved, and the count is done deeply, excluding head and teiHeader -->
      <xsl:param name="class-1-fragment" as="item()*"/>
      <xsl:param name="class-1-is-expanded" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when test="$class-1-is-expanded">
            <xsl:sequence
               select="tan:stamp-tree-with-text-data($class-1-fragment, true(), (), '^(TAN-.+|TEI|text|body|div|(non-)?tok)$', 1)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="tan:stamp-tree-with-text-data($class-1-fragment, true(), '^(teiHeader|head|tail)$', (), 1)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:stamp-tree-with-text-data" as="item()*" visibility="private">
      <!-- 2-parameter version for the main one below -->
      <xsl:param name="tree-fragment" as="item()*"/>
      <xsl:param name="ignore-outer-indentations" as="xs:boolean"/>
      <xsl:sequence select="tan:stamp-tree-with-text-data($tree-fragment, $ignore-outer-indentations, (), (), 1)"/>
   </xsl:function>
   
   <xsl:function name="tan:stamp-tree-with-text-data" as="item()*" visibility="private">
      <!-- Input: any tree fragment; a boolean; an integer -->
      <!-- Output: the same tree fragment, but with @_pos stamped in every element specifying the position of the
      next enclosed text character, and @_len specifying the string length of the text. If the second parameter 
      is true, space-only text nodes will be ignored. The third parameter specifies the starting digit for the 
      next character. -->
      <!-- Input items will be treated as part of the same whole, not as separate items. If you wish to apply
      this function to several items independently, the function should be iterated upon. -->
      <xsl:param name="tree-fragment" as="item()*"/>
      <xsl:param name="ignore-outer-indentations" as="xs:boolean"/>
      <xsl:param name="exclude-from-count-elements-whose-names-match" as="xs:string?"/>
      <xsl:param name="exclude-from-count-elements-whose-names-do-not-match" as="xs:string?"/>
      <xsl:param name="next-char-number" as="xs:integer"/>
      
      <xsl:variable name="some-text-nodes-are-not-space-only" as="xs:boolean" select="
            some $i in $tree-fragment[. instance of text()]
               satisfies matches($i, '\S')"/>
      <xsl:variable name="continue-to-ignore-indentations"
         select="$ignore-outer-indentations and not($some-text-nodes-are-not-space-only)"
         as="xs:boolean"/>
      
      <xsl:iterate select="$tree-fragment">
         <xsl:param name="current-char-pos" as="xs:integer" select="$next-char-number"/>
         
         <xsl:variable name="this-element-prepped-1" as="element()?">
            <xsl:if test="(. instance of element()) and $ignore-outer-indentations">
               <xsl:apply-templates select="."
                  mode="tan:temp-mark-and-remove-outer-indentations"/>
            </xsl:if>
         </xsl:variable>
         
         <xsl:variable name="this-element-prepped-2" as="element()?">
            <xsl:if test=". instance of element()">
               <xsl:apply-templates select="($this-element-prepped-1, .)[1]" mode="tan:copy-of-except">
                  <xsl:with-param name="exclude-elements-named-regex" tunnel="yes" select="$exclude-from-count-elements-whose-names-match"/>
                  <xsl:with-param name="exclude-elements-not-named-regex" tunnel="yes" select="$exclude-from-count-elements-whose-names-do-not-match"/>
               </xsl:apply-templates>
            </xsl:if>
         </xsl:variable>
         
         
         <xsl:variable name="this-fragment-length" as="xs:integer">
            <xsl:choose>
               <xsl:when
                  test=". instance of text() and 
                  (not($ignore-outer-indentations) or $some-text-nodes-are-not-space-only)">
                  <xsl:sequence select="tan:string-length(.)"/>
               </xsl:when>
               <xsl:when test=". instance of element() or . instance of document-node()">
                  <xsl:sequence
                     select="tan:string-length($this-element-prepped-2)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="0"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         
         <xsl:variable name="next-char-pos" as="xs:integer"
            select="$current-char-pos + $this-fragment-length"/>
         
         <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
         <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, tan:stamp-tree-with-text-data()'"/>
            <xsl:message select="'Current node type, name:', tan:item-type(.), name(.)" use-when="not($tan:validation-mode-on)"/>
            <xsl:message select="'Current char pos:', $current-char-pos"/>
            <xsl:message select="'Ignore outer indentations?', $ignore-outer-indentations"/>
            <xsl:message select="'Exclude from count elements whose names match: ' || string-join($exclude-from-count-elements-whose-names-match)"/>
            <xsl:message select="'Exclude from count elements whose names do not match: ' || string-join($exclude-from-count-elements-whose-names-do-not-match)"/>
            <xsl:message select="'Element prepped 1: ', $this-element-prepped-1"/>
            <xsl:message select="'Element prepped 2: ', $this-element-prepped-2"/>
            <xsl:message select="'Fragment length:', $this-fragment-length"/>
            <xsl:message select="'Next char pos:', $next-char-pos"/>
         </xsl:if>
         
         
         
         <xsl:choose>
            <xsl:when test=". instance of document-node()">
               <xsl:document>
                  <xsl:sequence
                     select="tan:stamp-tree-with-text-data(node(), $ignore-outer-indentations, 
                     $exclude-from-count-elements-whose-names-match, $exclude-from-count-elements-whose-names-do-not-match, 
                     $current-char-pos)"
                  />
               </xsl:document>
            </xsl:when>
            <xsl:when test=". instance of element()">
               <xsl:choose>
                  <xsl:when
                     test="string-length($exclude-from-count-elements-whose-names-match) gt 0 and matches(name(.), $exclude-from-count-elements-whose-names-match)"
                  >
                     <xsl:copy-of select="."/>
                  </xsl:when>
                  <xsl:when
                     test="string-length($exclude-from-count-elements-whose-names-do-not-match) gt 0 and not(matches(name(.), $exclude-from-count-elements-whose-names-do-not-match))"
                  >
                     <xsl:copy-of select="."/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:attribute name="_pos" select="$current-char-pos"/>
                        <xsl:attribute name="_len" select="$this-fragment-length"/>
                        <xsl:sequence
                           select="tan:stamp-tree-with-text-data(node(), $continue-to-ignore-indentations, $exclude-from-count-elements-whose-names-match, $exclude-from-count-elements-whose-names-do-not-match, $current-char-pos)"
                        />
                     </xsl:copy>
                  </xsl:otherwise>
               </xsl:choose>
               
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="."/>
            </xsl:otherwise>
         </xsl:choose>
         
         <xsl:next-iteration>
            <xsl:with-param name="current-char-pos" select="$next-char-pos"/>
         </xsl:next-iteration>
      </xsl:iterate>
      
   </xsl:function>
   
   
   
   <xsl:mode name="tan:temp-mark-and-remove-outer-indentations" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[text()]" mode="tan:temp-mark-and-remove-outer-indentations">
      <xsl:variable name="texts-are-outer-indentations" as="xs:boolean" select="
            every $i in text()
               satisfies
               not(matches($i, '\S'))"/>
      <xsl:choose>
         <xsl:when test="$texts-are-outer-indentations">
            <xsl:copy>
               <xsl:sequence select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="text()[not(matches(., '\S'))]" mode="tan:temp-mark-and-remove-outer-indentations">
      <xsl:processing-instruction name="outer-indent" select="."/>
   </xsl:template>
   
   
   
   
   
   
   <xsl:function name="tan:add-attributes" as="element()*" visibility="public">
      <!-- Input: a sequence of elements; a sequence of attributes -->
      <!-- Output: each element with a copy of the attributes -->
      <!-- This function helps simplify code where one wishes merely to return a copy of an element with perhaps
      diagnostic information in an attribute -->
      <!--kw: nodes, attributes, tree manipulation -->
      <xsl:param name="elements-to-adjust" as="element()*"/>
      <xsl:param name="attributes-to-insert" as="attribute()*"/>
      <xsl:for-each select="$elements-to-adjust">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$attributes-to-insert"/>
            <xsl:copy-of select="node()"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   
   
   
   <xsl:function name="tan:tree-to-sequence" as="item()*" visibility="public">
      <!-- Input: any XML fragment -->
      <!-- Output: a flattened sequence of XML nodes representing the original fragment. Each element is given a new @_level 
         specifying the level of hierarchy the element had in the original. Closing tags are specified by <_close-at id=""/>
         with a corresponding @_close-at in the opening tag. Empty elements are retained as-is. -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="xml-fragment" as="item()*"/>
      <xsl:apply-templates select="$xml-fragment" mode="tan:tree-to-sequence">
         <xsl:with-param name="current-level" select="1"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:tree-to-sequence" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[node()]" mode="tan:tree-to-sequence">
      <xsl:param name="current-level" as="xs:integer" select="1"/>
      <xsl:variable name="this-id" select="generate-id(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="_level" select="$current-level"/>
         <xsl:attribute name="_close-at" select="$this-id"/>
      </xsl:copy>
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="current-level" select="$current-level + 1"/>
      </xsl:apply-templates>
      <_close-at id="{$this-id}"/>
   </xsl:template>
   
   
   
   <xsl:function name="tan:sequence-to-tree" as="item()*" visibility="public">
      <!-- One-parameter version of the more complete one below -->
      <xsl:param name="sequence-to-reconstruct" as="item()*"/>
      <xsl:sequence select="tan:sequence-to-tree($sequence-to-reconstruct, false())"/>
   </xsl:function>
   
   <xsl:function name="tan:sequence-to-tree" as="item()*" visibility="public">
      <!-- Input: a result of tan:tree-to-sequence(); a boolean -->
      <!-- Output: the original tree; if the boolean is true, then any first children that precede the next level 
         will be wrapped in an element like the first child element. -->
      <!-- If a given opening tag has a corresponding <_close-at> then what is between will become the children
         of the element, and what comes after its following siblings. -->
      <!-- This is the inverse of the function tan:tree-to-sequence(). That is, tan:sequence-to-tree($i) => 
         tan:tree-to-sequence() should result in a copy of $i. -->
      <!-- This function is especially helpful for a raw text transcription that needs to be converted to a
         class-1 body via the inline numerical references. The technique is to replace the numerical references 
         with empty <div>s, each one with @n and @type correctly assessed based on the match, and a @_level to 
         specify where in the hierarchy it should sit. -->
      <!-- You may wish to run the results of this output through tan:consolidate-identical-adjacent-divs() -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="sequence-to-reconstruct" as="item()*"/>
      <xsl:param name="fix-orphan-text" as="xs:boolean"/>
      <xsl:variable name="sequence-prepped" as="element()">
         <tree>
            <xsl:copy-of select="$sequence-to-reconstruct"/>
         </tree>
      </xsl:variable>
      <xsl:variable name="results" as="element()">
         <xsl:apply-templates select="$sequence-prepped" mode="tan:sequence-to-tree">
            <xsl:with-param name="level-so-far" select="0"/>
            <xsl:with-param name="fix-orphan-text" select="$fix-orphan-text" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:copy-of select="$results/node()"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:sequence-to-tree" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[*[@_level]]" mode="tan:sequence-to-tree">
      <xsl:param name="level-so-far" as="xs:integer"/>
      <xsl:param name="fix-orphan-text" as="xs:boolean" tunnel="yes"/>
      
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="first-child-element" as="element()" select="*[1]"/>
      <xsl:variable name="level-to-process" select="$level-so-far + 1"/>
      <xsl:variable name="first-target-child-element" as="element()?"
         select="*[xs:integer(@_level) eq $level-to-process][1]"/>
      
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="not(exists($first-target-child-element))">
               <xsl:variable name="all-levels" as="xs:integer+" select="
                     for $i in */@_level
                     return
                        xs:integer($i)"/>
               <xsl:variable name="next-level" as="xs:integer" select="min($all-levels)"/>
               <xsl:if test="$next-level le $level-so-far">
                  <xsl:message select="'Problem in template mode tan:sequence-to-tree, jumping from '
                     || string($level-so-far) || ' to ' || string($next-level) || '. Current context: ', ."/>
               </xsl:if>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="level-so-far" select="$next-level - 1"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:for-each-group select="node()" group-starting-with="*[xs:integer(@_level) eq $level-to-process]">
                  <xsl:variable name="this-head" as="node()" select="current-group()[1]"/>
                  <xsl:variable name="this-is-new-group" as="xs:boolean"
                     select="(xs:integer($this-head/@_level) eq $level-to-process, false())[1]"/>
                  <!-- There may be cases where the nodes before the first node of interest (the level
                     to process) include elements targeting deeper levels. In that case, we respect the
                     instruction in @_level and wrap the orphaned nodes in an element that replicates
                     the first element of interest. -->
                  <xsl:variable name="this-orphan-has-orphaned-levels" as="xs:boolean" select="
                        not($this-is-new-group)
                        and exists(current-group()/@_level)"/>
                  <xsl:variable name="this-close-at-id" select="$this-head/@_close-at"/>
                  <xsl:variable name="new-group" as="item()*">
                     <xsl:if test="$this-is-new-group">
                        <xsl:for-each-group select="current-group()" group-starting-with="tan:_close-at[@id = $this-close-at-id]">
                           <xsl:choose>
                              <xsl:when test="current-group()[1][@id eq $this-close-at-id]">
                                 <xsl:copy-of select="tail(current-group())"/>
                              </xsl:when>
                              <xsl:otherwise>
                                 <xsl:element name="{name($this-head)}" namespace="{namespace-uri($this-head)}">
                                    <xsl:copy-of select="$this-head/(@* except (@_level | @_close-at))"/>
                                    <!-- Yes, the anchor does not necessarily have to be empty. -->
                                    <xsl:copy-of select="$this-head/node()"/>
                                    <xsl:copy-of select="tail(current-group())"/>
                                 </xsl:element>
                              </xsl:otherwise>
                           </xsl:choose>
                        </xsl:for-each-group> 
                     </xsl:if>
                     <xsl:if test="$this-orphan-has-orphaned-levels">
                        <xsl:element name="{name($first-target-child-element)}" namespace="{namespace-uri($first-target-child-element)}">
                           <xsl:copy-of select="$first-target-child-element/(@* except (@_level | @_close-at))"/>
                           <xsl:copy-of select="current-group()"/>
                        </xsl:element>
                     </xsl:if>
                  </xsl:variable>
                  
                  <xsl:choose>
                     <xsl:when
                        test="not($this-is-new-group) and (($this-head instance of text()) and $fix-orphan-text)">
                        <xsl:element name="{name(($first-target-child-element, $first-child-element)[1])}"
                           namespace="{namespace-uri($first-child-element)}">
                           <xsl:copy-of select="$first-child-element/(@* except (@_level | @_close-at))"/>
                           <xsl:value-of select="$this-head"/>
                           <xsl:apply-templates select="tail(current-group())" mode="#current">
                              <xsl:with-param name="level-so-far" select="$level-to-process"/>
                           </xsl:apply-templates>
                        </xsl:element>
                     </xsl:when>
                     <xsl:when test="$this-orphan-has-orphaned-levels">
                        <xsl:message select="
                              'Orphaned nodes found while processing template mode tan:sequence-to-tree. Currently processing level '
                              || string($level-to-process) || ' but need to process nodes of depth ' ||
                              string-join(distinct-values(current-group()/@_level), ', ') ||
                              '. Wrapping them in a replica of the first element of the current target level. Orphaned nodes: ', current-group()"
                        />
                        <xsl:apply-templates select="$new-group" mode="#current">
                           <xsl:with-param name="level-so-far" select="$level-to-process"/>
                        </xsl:apply-templates>
                     </xsl:when>
                     <xsl:when test="not($this-is-new-group) or not(exists($new-group))">
                        <xsl:copy-of select="current-group()"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:apply-templates select="$new-group" mode="#current">
                           <xsl:with-param name="level-so-far" select="$level-to-process"/>
                        </xsl:apply-templates>
                     </xsl:otherwise>
                  </xsl:choose>
                  
               </xsl:for-each-group>
               
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   
   
   
   
   <xsl:function name="tan:strip-outer-indentation" as="item()*" visibility="public">
      <!-- Input: any XML fragment -->
      <!-- Output: the same, but without outer indentation -->
      <!--kw: nodes, tree manipulation, spacing -->
      <xsl:param name="tree-fragment" as="item()*"/>
      <xsl:apply-templates select="$tree-fragment" mode="tan:strip-outer-indentation"/>
   </xsl:function>
   
   <xsl:mode name="tan:strip-outer-indentation" on-no-match="shallow-copy"/>
   
   <!-- Remove indentations that first enter the template -->
   <xsl:template match="text()[not(matches(., '\S'))]" mode="tan:strip-outer-indentation"/>
   
   <xsl:template match="tei:cl | tei:m | tei:pc | tei:phr | tei:s | tei:seg | tei:w" priority="1" 
      mode="tan:strip-outer-indentation">
      <!-- In some TEI elements, the lack of a text node with non-space text may be confused
         as indentation. We draw from model.segLike for the list of elements whose enclosed
         white space should not be interpreted as indentation:
         https://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-model.segLike.html
      -->
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="*[text()]" mode="tan:strip-outer-indentation">
      <xsl:variable name="text-children-are-indentation-only" as="xs:boolean" select="
         every $i in text()
         satisfies not(matches($i, '\S'))"/>
      <xsl:choose>
         <xsl:when test="$text-children-are-indentation-only">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates select="node() except text()" mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:mode name="tan:normalize-non-mixed-content-space" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:normalize-non-mixed-content-space">
      <xsl:sequence select="normalize-space(.)"/>
   </xsl:template>
   
   
   <xsl:function name="tan:normalize-tree-space" as="item()*" visibility="public">
      <!-- Input: any XML tree; boolean -->
      <!-- Output: the same, but space-normalized:
         - all outer indentations are removed
         - if an element is known to contain only non-mixed content, all inner
            text nodes are space-normalized
         - otherwise any element that contains non-space text will be space-normalized:
            - initial space is removed
            - in the text from the first through last non-space character (excluding special
            end-div characters) any sequence of consecutive space characters will be
            replaced by a single word space; that single word space will be placed in the 
            first text node only, and any other text nodes that contain the consecutive
            space character block will have all initial space removed
            - any final space characters in the string value of the element will be removed
            - if the last non-space character is not a special end-div character, a single
            word space will be added at the end
            - if the 2nd parameter is true, any special end-div characters will be removed 
      -->
      <!-- Because this function attends to space normalization as a mixed-content problem, it
         will space-normalize select TEI constructions. -->
      <!-- Expanded TAN files are space normalized via this function, so there is no sense in 
         running them again. In fact, it can introduce errors (because special div-end characters 
         have already been removed).
      -->
      <!--kw: nodes, spacing, tree manipulation -->
      <xsl:param name="input-tree" as="item()*"/>
      <xsl:param name="remove-special-end-div-chars" as="xs:boolean"/>
      
      <xsl:variable name="pass-1" as="item()*">
         <xsl:apply-templates select="$input-tree" mode="tan:strip-outer-indentation"/>
      </xsl:variable>

      <xsl:variable name="pass-2" as="item()*">
         <xsl:apply-templates select="$pass-1" mode="tan:normalize-tree-space">
            <xsl:with-param name="remove-special-end-div-chars" select="$remove-special-end-div-chars" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:variable>

      <xsl:variable name="pass-3" as="item()*">
         <xsl:apply-templates select="$pass-2" mode="tan:selectively-adjust-tei-space"/>
      </xsl:variable>

      <xsl:sequence select="$pass-3"/>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:normalize-tree-space" on-no-match="shallow-copy"/>
   
   <!-- Any element known to contain non-mixed content should be diverted
   to straight-forward normalization of every text node. -->
   <xsl:template match="tan:head | tan:TAN-voc | tan:TAN-A | tan:TAN-A-tok | tan:TAN-A-lm | 
      tan:TAN-mor" priority="1" mode="tan:normalize-tree-space">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="tan:normalize-non-mixed-content-space"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:TAN-T[tan:expanded]" mode="tan:normalize-tree-space">
      <xsl:message select="'Expanded files have already had their divs space normalized; tan:normalize-space-class-1() unnecessary.'"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[@xml:space eq 'preserve']" priority="1" mode="tan:normalize-tree-space tan:selectively-adjust-tei-space">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <!-- The pattern *[text()[matches(., '\S')]] ensures that any outer indentations are ignored, and that
      the process begins only at an element that has a non-space text node. Special characters will be
      removed only once, in the last text node for the context. That principle will not be applied to any 
      descendants. Once a TEI element that is phrase-like is reached, the search should go no deeper, lest 
      its constituent parts get spaces added at the end.
   -->
   <xsl:template match="*:div[not(*:div)] | *[text()[matches(., '\S')]] | 
      tei:cl | tei:m | tei:pc | tei:phr | tei:s | tei:seg | tei:w" mode="tan:normalize-tree-space">
      <xsl:param name="remove-special-end-div-chars" tunnel="yes" as="xs:boolean"/>
      
      <!-- Convert the tree to a sequence of nodes -->
      <xsl:variable name="this-tree-as-sequence" as="element()">
         <sequence>
            <xsl:copy-of select="tan:tree-to-sequence(.)"/>
         </sequence>
      </xsl:variable>
      
      <!-- Normalize every text node, but mark where there was initial and terminal space. -->
      <xsl:variable name="output-pass-1" as="element()">
         <output>
            <xsl:iterate select="$this-tree-as-sequence/node()">
               <xsl:choose>
                  <xsl:when test=". instance of text()">
                     <!-- Initial space markers are placed only if the node has non-space content. -->
                     <xsl:if test="matches(., '^\s+\S')">
                        <_space/>
                     </xsl:if>
                     <xsl:value-of select="normalize-space(.)"/>
                     <xsl:if test="matches(., '\s$')">
                        <_space/>
                     </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="."/>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:next-iteration/>
            </xsl:iterate>
         </output>
      </xsl:variable>
      
      <xsl:variable name="last-text-node" select="$output-pass-1/text()[last()]" as="text()?"/>
      
      
      <xsl:variable name="output-pass-2" as="element()">
         <output>
            <xsl:iterate select="$output-pass-1/node()">
               <xsl:param name="last-text-ended-in-space" as="xs:boolean" select="true()"/>
               <xsl:param name="ignore-subsequent-space" as="xs:boolean" select="false()"/>
               
               <xsl:variable name="this-is-last-text-node" as="xs:boolean?"
                  select=". is $last-text-node"/>
               <xsl:variable name="this-ends-with-special-char" as="xs:boolean"
                  select="matches(., $tan:special-end-div-chars-regex)"/>
               <xsl:variable name="current-text-ends-in-space" as="xs:boolean">
                  <xsl:choose>
                     <xsl:when test="self::tan:_space">
                        <xsl:sequence select="true()"/>
                     </xsl:when>
                     <xsl:when test="$this-is-last-text-node and not($this-ends-with-special-char)">
                        <xsl:sequence select="true()"/>
                     </xsl:when>
                     <xsl:when test="self::text()">
                        <xsl:sequence select="false()"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="$last-text-ended-in-space"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               
               <xsl:variable name="diagnostics-on" select="false()"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'This item: ' || serialize(.)"/>
                  <xsl:message select="'Last text ended in space? ', $last-text-ended-in-space"/>
                  <xsl:message select="'This is last text node? ', $this-is-last-text-node"/>
                  <xsl:message select="'Supplied last text node: ' || $last-text-node"/>
                  <xsl:message select="'This ends in special char? ', $this-ends-with-special-char"/>
                  <xsl:message select="'Current text ends in space? ', $current-text-ends-in-space"/>
               </xsl:if>
               
               <!-- output -->
               <xsl:choose>
                  <xsl:when test="self::tan:_space and $last-text-ended-in-space"/>
                  <xsl:when test="self::tan:_space and $ignore-subsequent-space"/>
                  <xsl:when test="self::tan:_space and not($last-text-ended-in-space)">
                     <xsl:value-of select="' '"/>
                  </xsl:when>
                  <xsl:when
                     test="
                     $this-is-last-text-node and $this-ends-with-special-char
                     and $remove-special-end-div-chars">
                     <xsl:analyze-string select="." regex="{$tan:special-end-div-chars-regex || '$'}">
                        <xsl:matching-substring>
                           <_removed cp="{string-to-codepoints(regex-group(1))}"/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                           <xsl:value-of select="."/>
                        </xsl:non-matching-substring>
                     </xsl:analyze-string>
                  </xsl:when>
                  <xsl:when test="$this-is-last-text-node and $this-ends-with-special-char">
                     <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:when test="$this-is-last-text-node">
                     <xsl:value-of select=". || ' '"/>
                  </xsl:when>
                  <xsl:when test="self::text()">
                     <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="."/>
                  </xsl:otherwise>
               </xsl:choose>
               
               <xsl:next-iteration>
                  <xsl:with-param name="last-text-ended-in-space" select="$current-text-ends-in-space"/>
                  <xsl:with-param name="ignore-subsequent-space" select="($this-is-last-text-node and $this-ends-with-special-char) or $ignore-subsequent-space"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </output>
      </xsl:variable>
      
      <!-- Turn the sequence back into a tree -->
      <xsl:variable name="output-pass-3" select="tan:sequence-to-tree($output-pass-2/node())" as="element()"/>
      
      <!-- Push <_remove> into parent -->
      <xsl:variable name="output-pass-4" as="element()">
         <xsl:choose>
            <xsl:when test="$remove-special-end-div-chars and exists($output-pass-2/tan:_removed)">
               <xsl:apply-templates select="$output-pass-3" mode="tan:mark-removed-characters"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$output-pass-3"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode tan:normalize-class-1-div-space on leaf div ' || path(.)"/>
         <xsl:message select="'Output pass 1:', $output-pass-1"/>
         <xsl:message select="'String value 1: [' || string($output-pass-1) || ']'"/>
         <xsl:message select="'Output pass 2:', $output-pass-2"/>
         <xsl:message select="'String value 2: [' || string($output-pass-2) || ']'"/>
         <xsl:message select="'Output pass 3:', $output-pass-3"/>
         <xsl:message select="'String value 3: [' || string($output-pass-3) || ']'"/>
         <xsl:message select="'Output pass 4:', $output-pass-3"/>
         <xsl:message select="'String value 4: [' || string($output-pass-3) || ']'"/>
      </xsl:if>
      
      <xsl:sequence select="$output-pass-4"/>
      
   </xsl:template>
   
   
   
   <xsl:mode name="tan:mark-removed-characters" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:_removed" mode="tan:mark-removed-characters"/>
   
   <xsl:template match="*[tan:_removed]" mode="tan:mark-removed-characters">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="_removed" select="tan:_removed/@cp"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:selectively-adjust-tei-space" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()[matches(., '\S')]" priority="-1" mode="tan:selectively-adjust-tei-space">
      <!-- Sometimes tei space should be fully normalized, other times not; it is difficult
         to lay down a policy. This is the fallback, a kind of soft space normalization upon
         text nodes that have non-space text. -->
      <xsl:if test="matches(., '^\s')">
         <xsl:value-of select="' '"/>
      </xsl:if>
      <xsl:value-of select="normalize-space(.)"/>
      <xsl:if test="matches(., '\S\s+$')">
         <xsl:value-of select="' '"/>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tei:div[not(tei:div)]/node()[last()]/node()[last()]/self::tei:*"
      mode="tan:selectively-adjust-tei-space" priority="2">
      <!-- given a tei leaf div, if the final grandchild is an element, not a text node, make sure it is followed by the titular space
         marking the end of a div. We do it in the grandchild position, because technically no text is allowed as a child of 
         a tei div, even a leaf one. We try a next match, in case that final grandchild element needs to have its space adjusted. -->
      <xsl:next-match/>
      <xsl:value-of select="' '"/>
   </xsl:template>
   
   <xsl:template match="*[tei:app/tei:lem[matches(., '^\s|\s$')]]/node()" priority="1"
      mode="tan:selectively-adjust-tei-space">
      <!-- A <tei:lem> should not be anchored to text that begins with or ends with space, because apparatus critici are
         not concerned with initial or trailing space. -->
      <!-- We pull in the space from <lem>, but further down we also make sure <rdg> does not have initial or terminal space. -->
      
      <xsl:variable name="follows-rdg-with-appended-space" as="xs:boolean"
         select="exists(preceding-sibling::node()[1]/self::tei:app/tei:lem[matches(., '\s$')])"/>
      <xsl:variable name="precedes-rdg-with-prepended-space" as="xs:boolean"
         select="exists(following-sibling::node()[1]/self::tei:app/tei:lem[matches(., '^\s')])"/>
      
      <xsl:if test="$follows-rdg-with-appended-space">
         <xsl:value-of select="' '"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      <xsl:if test="$precedes-rdg-with-prepended-space">
         <xsl:value-of select="' '"/>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tei:app/tei:lem | tei:app/tei:rdg" mode="tan:selectively-adjust-tei-space">
      <!-- No tei <lem> or <rdg> should begin with or end with space -->
      <xsl:apply-templates select="." mode="tan:trim-initial-and-terminal-space"/>
   </xsl:template>
   
   <xsl:mode name="tan:trim-initial-and-terminal-space" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:trim-initial-and-terminal-space">
      <!-- These tests permit comments and processing instructions to be inserted inside initial
   or final indentations, without affecting the results. -->
      <xsl:variable name="preceding-nodes-of-interest" as="node()*" select="(preceding-sibling::* | preceding-sibling::text())"/>
      <xsl:variable name="following-nodes-of-interest" as="node()*" select="(following-sibling::* | following-sibling::text())"/>
      <xsl:variable name="is-not-initial-indentation" as="xs:boolean" select="
         exists($preceding-nodes-of-interest) and
         (some $i in $preceding-nodes-of-interest
         satisfies matches($i, '\S'))"/>
      <xsl:variable name="is-not-final-indentation" as="xs:boolean" select="
         exists($following-nodes-of-interest) and
         (some $i in $following-nodes-of-interest
         satisfies matches($i, '\S'))"/>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode tan:trim-initial-and-terminal-space'"/>
         <xsl:message select="'preceding nodes of interest count: ', count($preceding-nodes-of-interest)"/>
         <xsl:message select="'following nodes of interest count: ', count($following-nodes-of-interest)"/>
         <xsl:message select="'has initial indentation?', not($is-not-initial-indentation)"/>
         <xsl:message select="'has final indentation?', not($is-not-final-indentation)"/>
      </xsl:if>
      
      <xsl:if test="$is-not-initial-indentation and matches(., '^\s')">
         <xsl:value-of select="' '"/>
      </xsl:if>
      <xsl:value-of select="normalize-space(.)"/>
      <xsl:if test="$is-not-final-indentation and matches(., '\S\s+$')">
         <xsl:value-of select="' '"/>
      </xsl:if>
   </xsl:template>
   
   
   
   
   
   
   
   
   
   <xsl:function name="tan:chop-tree" as="map(xs:integer, item()*)" visibility="public">
      <!-- Input: any XML fragment; a sequence of integers -->
      <!-- Output: a map, with the XML fragment chopped into portions supplied by the integers, interpreted
         as string positions at which to chop the tree. Thus, each map entry has a key of an integer and 
         content/value consisting of the corresponding slice of the tree. -->
      <!-- The integer 1 is always inferred, and returned. Any integers greater than the string length of the
         tree will be ignored. -->
      <!-- For a similar, but more complex function, see tan:chop-diff-output() -->
      <!--kw: nodes, tree manipulation -->
      <xsl:param name="tree-to-chop" as="item()*"/>
      <xsl:param name="chop-points" as="xs:integer*"/>
      
      <xsl:variable name="chops-simplified" as="xs:integer*" select="distinct-values($chop-points[. gt 1])"/>
      
      <xsl:variable name="tree-pass-1" as="item()*" select="tan:tree-to-sequence($tree-to-chop)"/>
      
      <xsl:variable name="tree-pass-2" as="item()*">
         <_map-entry key="1"/>
         <xsl:iterate select="$tree-pass-1">
            <xsl:param name="current-text-pos" as="xs:integer" select="1"/>
            <xsl:param name="chops-to-place" as="xs:integer*" select="$chops-simplified"/>
            <xsl:param name="unclosed-elements" as="element()*"/>
            
            <xsl:on-completion>
               <xsl:if test="exists($chops-to-place)">
                  <xsl:message select="'tan:chop-tree() ignoring chop points that exceed the length of the input:', $chops-to-place"/>
               </xsl:if>
            </xsl:on-completion>
            
            <!-- Assess the state of things, prepare the next parameters -->
            <xsl:variable name="next-text-pos" as="xs:integer" select="
               if (. instance of text()) then
               $current-text-pos + string-length(.)
               else
               $current-text-pos"/>
            
            <xsl:variable name="these-chops-to-place" as="xs:integer*"
               select="$chops-to-place[. le $next-text-pos]"/>
            <xsl:variable name="next-chops-to-place" as="xs:integer*"
               select="$chops-to-place[. gt $next-text-pos]"/>
            
            <xsl:variable name="this-close-at" select="
               if (. instance of element()) then
               self::tan:_close-at
               else
               ()" as="element()?"/>
            <xsl:variable name="next-unclosed-elements" as="element()*"
               select="$unclosed-elements[not(@_close-at eq $this-close-at/@id)], self::*[@_close-at]"
            />
            
            <!-- Write the output -->
            <xsl:choose>
               <xsl:when test="exists($these-chops-to-place) and (. instance of text())">
                  <xsl:for-each select="string-to-codepoints(.)">
                     <xsl:variable name="str-pos" select="position() + $current-text-pos"/>
                     <xsl:value-of select="codepoints-to-string(.)"/>
                     <xsl:if test="$these-chops-to-place = $str-pos">
                        <!-- close and reopen all unclosed elements -->
                        <xsl:for-each select="reverse($unclosed-elements)">
                           <_close-at id="{@_close-at}"/>
                        </xsl:for-each>
                        <!-- mark the beginning of a new map entry -->
                        <_map-entry key="{$str-pos}"/>
                        <!--<xsl:sequence select="$unclosed-elements"/>-->
                        <xsl:for-each select="$unclosed-elements">
                           <xsl:copy>
                              <xsl:copy-of select="@*"/>
                              <!-- We add @_recheck, because in closing an element then reopening it up,
                                 and the chop comes at the end of the text string, we might be creating 
                                 a phantom starting element as the start of the next tree. There are
                                 complications involved in evaluating that scenario now. It's best handled
                                 once the sequence is turned into a tree. So newly inserted unclosed elements
                                 are noted with this @_recheck, where we can easily get rid of starting phantoms. -->
                              <xsl:attribute name="_recheck"/>
                           </xsl:copy>
                        </xsl:for-each>
                     </xsl:if>
                  </xsl:for-each>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="."/>
               </xsl:otherwise>
            </xsl:choose>
            
            <xsl:next-iteration>
               <xsl:with-param name="current-text-pos" select="$next-text-pos"/>
               <xsl:with-param name="chops-to-place" select="$next-chops-to-place"/>
               <xsl:with-param name="unclosed-elements" select="$next-unclosed-elements"/>
            </xsl:next-iteration>
            
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:map>
         <xsl:for-each-group select="$tree-pass-2" group-starting-with="tan:_map-entry">
            
            <xsl:variable name="preliminary-results" as="item()*"
               select="tan:sequence-to-tree(tail(current-group()))"/>
            
            <xsl:map-entry key="xs:integer(current-group()[1]/@key)">
               <xsl:apply-templates select="$preliminary-results" mode="tan:recheck-chopped-tree"/>
            </xsl:map-entry>
         </xsl:for-each-group> 
      </xsl:map>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:recheck-chopped-tree" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[@_recheck]" mode="tan:recheck-chopped-tree">
      <xsl:variable name="keep-this" as="xs:boolean"
         select="string-length(.) gt 0 or exists(descendant::comment()) or exists(descendant::processing-instruction())"
      />
      <xsl:if test="$keep-this">
         <xsl:copy>
            <xsl:copy-of select="@* except @_recheck"/>
            <xsl:apply-templates mode="#current"/>
         </xsl:copy>
      </xsl:if>
   </xsl:template>
   
   
   
   
</xsl:stylesheet>