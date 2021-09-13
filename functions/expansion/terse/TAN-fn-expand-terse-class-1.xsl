<xsl:stylesheet
   exclude-result-prefixes="#all"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library, terse expansion, class 1 files. -->

   
   <xsl:template match="tan:redivision | /tan:TAN-T/tan:head/tan:companion-version | /tei:TEI/tan:head/tan:companion-version" 
      mode="tan:core-expansion-terse">
      <xsl:variable name="these-iris" select="tan:IRI"/>
      <xsl:variable name="this-doc-work" select="/*/tan:head/tan:work"/>
      <xsl:variable name="this-doc-work-vocab"
         select="tan:vocabulary('work', $this-doc-work/@which, parent::tan:head)"/>
      <xsl:variable name="this-doc-source" select="/*/tan:head/tan:source"/>
      <xsl:variable name="this-doc-source-vocab"
         select="tan:vocabulary(('source', 'scriptum'), $this-doc-source/@which, parent::tan:head)"/>
      <xsl:variable name="this-redivision-doc-resolved"
         select="$tan:redivisions-resolved[*/@id = $these-iris]"/>
      <xsl:variable name="target-1st-da" select="tan:get-1st-doc(.)"/>
      <xsl:variable name="target-doc-resolved"
         select="
            if (exists($this-redivision-doc-resolved)) then
               $this-redivision-doc-resolved
            else
               tan:resolve-doc($target-1st-da)"/>
      <xsl:variable name="target-doc-work" select="$target-doc-resolved/*/tan:head/tan:work"/>
      <xsl:variable name="target-doc-work-vocab"
         select="tan:vocabulary('work', $target-doc-work/@which, $target-doc-resolved/*/tan:head)"/>
      <xsl:variable name="target-doc-source" select="$target-doc-resolved/*/tan:head/tan:source"/>
      <xsl:variable name="target-doc-source-vocab"
         select="tan:vocabulary(('source', 'scriptum'), $target-doc-source/@which, $target-doc-resolved/*/tan:head)"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:redivision or tan:companion-version, template mode core-expansion-terse'"/>
         <xsl:message select="'Target doc resolved (shallow:) ', tan:shallow-copy($target-doc-resolved/*)"/>
         <xsl:message select="'This work vocab:', $this-doc-work-vocab"/>
         <xsl:message select="'This source vocab:', $this-doc-source-vocab"/>
         <xsl:message select="'Target doc work vocab:', $target-doc-work-vocab"/>
         <xsl:message select="'Target doc source vocab: ', $target-doc-source-vocab"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="not(($target-doc-source, $target-doc-source-vocab)//tan:IRI = ($this-doc-source, $this-doc-source-vocab)//tan:IRI)">
            <xsl:copy-of select="tan:error('cl101')"/>
         </xsl:if>
         <xsl:if
            test="not(($target-doc-work, $target-doc-work-vocab)//tan:IRI = ($this-doc-work, $this-doc-work-vocab)//tan:IRI)">
            <xsl:copy-of select="tan:error('cl102')"/>
         </xsl:if>
         <xsl:if
            test="
               not(self::tan:companion-version) and
               exists(root()/*/tan:head/tan:version) and
               exists($target-doc-resolved/*/tan:head/tan:version)">
            <xsl:variable name="this-doc-version" select="/*/tan:head/tan:version"/>
            <xsl:variable name="this-doc-version-vocab"
               select="tan:vocabulary('version', $this-doc-version/@which, parent::tan:head)"/>
            <xsl:variable name="target-doc-version"
               select="$target-doc-resolved/*/tan:head/tan:version"/>
            <xsl:variable name="target-doc-version-vocab"
               select="tan:vocabulary('version', $target-doc-version/@which, $target-doc-resolved/*/tan:head)"/>
            <xsl:if
               test="not(($target-doc-version, $target-doc-version-vocab)//tan:IRI = ($this-doc-version, $this-doc-version-vocab)/tan:IRI)">
               <xsl:copy-of select="tan:error('cl103')"/>
            </xsl:if>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:reference-system" mode="tan:core-expansion-terse">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(../tan:model)">
            <xsl:copy-of select="tan:error('cl120')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:model" mode="tan:core-expansion-terse">
      <xsl:variable name="these-iris" select="tan:IRI"/>
      <xsl:variable name="this-doc-work" select="/*/tan:head/tan:work"/>
      <xsl:variable name="this-doc-work-vocab"
         select="tan:vocabulary('work', $this-doc-work/@which, parent::tan:head)"/>
      <xsl:variable name="this-model-doc-resolved" select="$tan:model-resolved[*/@id = $these-iris]"/>
      <xsl:variable name="target-1st-da" select="tan:get-1st-doc(.)"/>
      <xsl:variable name="target-doc-resolved"
         select="
            if (exists($this-model-doc-resolved)) then
               $this-model-doc-resolved
            else
               tan:resolve-doc($target-1st-da)"/>
      <xsl:variable name="target-doc-work" select="$target-doc-resolved/*/tan:head/tan:work"/>
      <xsl:variable name="target-doc-work-vocab"
         select="tan:vocabulary('work', $target-doc-work/@which, $target-doc-resolved/*/tan:head)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="not(($target-doc-work, $target-doc-work-vocab)//tan:IRI = ($this-doc-work, $this-doc-work-vocab)/tan:IRI)">
            <xsl:copy-of select="tan:error('cl102')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tei:div[not(tei:div)]/tei:*" priority="1"
      mode="tan:resolve-numerals tan:core-expansion-terse-attributes">
      <xsl:copy-of select="."/>
   </xsl:template>

   <xsl:template match="/" mode="tan:dependency-adjustments-pass-1">
      <xsl:document>
         <xsl:choose>
            <xsl:when test="$tan:distribute-vocabulary">
               <xsl:variable name="dependency-with-vocab-expanded" as="document-node()">
                  <xsl:apply-templates select="." mode="tan:core-expansion-terse-attributes"/>
               </xsl:variable>
               <xsl:apply-templates select="$dependency-with-vocab-expanded/node()" mode="#current"
               />
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:document>
   </xsl:template>

   <xsl:template match="tan:TAN-T | tei:TEI"
      mode="tan:core-expansion-terse tan:dependency-adjustments-pass-1">
      <!-- Homogenize tei:TEI to tan:TAN-T -->
      <xsl:param name="class-2-doc" tunnel="yes" as="document-node()?"/>
      <!-- Div filters are a reference tree -->
      <xsl:param name="div-filters" as="element()*" tunnel="yes"/>
      
      <xsl:variable name="vocabulary" select="$class-2-doc/*/tan:head/tan:vocabulary-key"/>
      <xsl:variable name="this-src-id" select="@src"/>
      <xsl:variable name="is-self" select="@id = $tan:doc-id" as="xs:boolean"/>
      <xsl:variable name="this-work-group"
         select="$vocabulary/tan:group[tan:work/@src = $this-src-id]"/>

      <xsl:variable name="this-last-change-agent" select="tan:last-change-agent(root(.))"/>

      <xsl:variable name="ambig-is-roman"
         select="not($class-2-doc/*/tan:head/tan:numerals/@priority = 'letters')"/>
      <xsl:variable name="these-adjustments"
         select="$class-2-doc/*/tan:head/tan:adjustments[(tan:src/text(), tan:where/tan:src/text()) = ($this-src-id, $tan:all-selector)]"/>
      
      
      <xsl:variable name="n-alias-items"
         select="
            if (exists($these-adjustments)) then
               tan:head/tan:vocabulary/tan:item[tan:affects-attribute = 'n']
            else
               ()"
      />

      <xsl:variable name="div-filters-for-this-source" as="element()*"
         select="$div-filters[not(tan:src/text()) or (tan:src/text() = $this-src-id)]"/>
      
      <xsl:variable name="these-adjustments-adjusted" as="element()*">
         <xsl:choose>
            <xsl:when test="exists($n-alias-items)">
               <xsl:apply-templates select="$these-adjustments" mode="tan:resolve-reference-tree-numerals">
                  <xsl:with-param name="n-alias-items" tunnel="yes" select="$n-alias-items"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$these-adjustments"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode: core-expansion-terse and dependency-adjustments-pass-1'"/>
         <xsl:message select="'this root element: ', tan:shallow-copy(.)"/>
         <xsl:message select="'ambig is roman: ', $ambig-is-roman"/>
         <xsl:message select="'picked adjustments: ', $these-adjustments"/>
         <xsl:message select="'n alias items: ', $n-alias-items"/>
         <xsl:message select="'adjustments adjusted: ', $these-adjustments-adjusted"/>
         <xsl:message select="'div filters for this source count: ', count($div-filters-for-this-source)"/>
      </xsl:if>
      
      <TAN-T>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($this-work-group)">
            <xsl:attribute name="work" select="$this-work-group/@n"/>
         </xsl:if>
         <xsl:if test="exists($this-last-change-agent/self::tan:algorithm)">
            <xsl:copy-of select="tan:error('wrn07', 'The last change was made by an algorithm.')"/>
         </xsl:if>
         <xsl:if test="(@TAN-version eq $tan:TAN-version) and $tan:TAN-version-is-under-development">
            <xsl:copy-of select="tan:error('wrn04')"/>
         </xsl:if>
         <xsl:if test="not(@TAN-version = $tan:TAN-version)">
            <xsl:variable name="conversion-tools-uri" select="'../../applications/convert/'"/>
            <xsl:variable name="this-message" as="xs:string*">
               <xsl:text>Should be version </xsl:text>
               <xsl:value-of select="$tan:TAN-version"/>
               <xsl:if test="@TAN-version = $tan:previous-TAN-versions">
                  <xsl:value-of
                     select="'; to convert older versions to the current one, try ' || resolve-uri($conversion-tools-uri, static-base-uri())"
                  />
               </xsl:if>
            </xsl:variable>
            <xsl:copy-of select="tan:error('tan20', string-join($this-message, ''))"/>
         </xsl:if>
         <expanded>terse</expanded>
         <!-- If there are no div filters at all, that's a general request to expand/adjust the entire thing; if there are
            div filters for this source, then the request is to restrict expansion to only those divs in the reference tree. -->
         <xsl:if test="not(exists($div-filters)) or exists($div-filters-for-this-source)">

            <xsl:apply-templates mode="#current">
               <xsl:with-param name="adjustment-actions-resolved" tunnel="yes"
                  select="$these-adjustments-adjusted/(tan:skip, tan:rename, tan:equate)"/>
               <!-- because div filters are reference trees, we push ahead the first level of <div>s -->
               <xsl:with-param name="div-filters" tunnel="yes" select="$div-filters-for-this-source/tan:div"/>
               <xsl:with-param name="drop-divs" tunnel="yes" select="exists($div-filters-for-this-source)"/>
            </xsl:apply-templates>
         </xsl:if>
      </TAN-T>
   </xsl:template>
   
   <xsl:template match="*:body" mode="tan:core-expansion-terse tan:dependency-adjustments-pass-1">
      <!-- Rebuild any divs with @ref-alias by making a copy of them, reconstructing a single-link hierarchy chain,
      and sending them as last children of body through the current template -->
      <xsl:variable name="divs-with-ref-alias" select="descendant::*:div[@ref-alias]" as="element()*"/>
      <xsl:variable name="divs-with-ref-aliases-rebuilt" as="element()*">
         <xsl:apply-templates select="$divs-with-ref-alias" mode="tan:rebuild-divs-with-ref-aliases"/>
      </xsl:variable>
      
      <xsl:variable name="anchor-reference" as="element()?">
         <xsl:if test="self::tei:*">
            <anchors>
               <xsl:apply-templates select="." mode="tan:build-anchor-reference"/>
            </anchors>
         </xsl:if>
      </xsl:variable>

      <body>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="anchor-reference" as="element()?" tunnel="yes" select="$anchor-reference"/>
         </xsl:apply-templates>
         <xsl:apply-templates select="$divs-with-ref-aliases-rebuilt" mode="#current">
            <xsl:with-param name="anchor-reference" as="element()?" tunnel="yes" select="$anchor-reference"/>
         </xsl:apply-templates>
      </body>
   </xsl:template>
   
   <xsl:mode name="tan:rebuild-divs-with-ref-aliases" on-no-match="shallow-copy"/>
   
   <xsl:template match="*:div[@ref-alias]" mode="tan:rebuild-divs-with-ref-aliases">
      <xsl:variable name="this-div" select="." as="element()"/>
      <xsl:variable name="div-chain" select="ancestor-or-self::*:div" as="element()*"/>
      <xsl:variable name="depth-level" as="xs:integer" select="count($div-chain)"/>
      <xsl:variable name="ref-alias-components" select="tokenize(@ref-alias, ' ')" as="xs:string+"/>
      <xsl:variable name="ref-alias-errors" as="element()*">
         <xsl:if test="count($ref-alias-components) mod $depth-level ne 0">
            <xsl:copy-of select="tan:error('cl119')"/>
         </xsl:if>
      </xsl:variable>
      
      <xsl:for-each-group select="$ref-alias-components"
         group-by="ceiling(position() div $depth-level)">
         <xsl:variable name="these-n-vals" select="current-group()" as="xs:string+"/>
         
         <xsl:apply-templates select="$this-div" mode="tan:rebuild-div-chain">
            <xsl:with-param name="divs-to-model" as="element()+" select="$div-chain"/>
            <xsl:with-param name="n-components" as="xs:string+" select="$these-n-vals"/>
            <xsl:with-param name="ref-alias-errors" tunnel="yes" as="element()*" select="$ref-alias-errors"/>
         </xsl:apply-templates>
      </xsl:for-each-group>

   </xsl:template>
   
   <xsl:mode name="tan:rebuild-div-chain" on-no-match="shallow-copy"/>
   
   <xsl:template match="*:div" mode="tan:rebuild-div-chain">
      <xsl:param name="divs-to-model" as="element()*"/>
      <xsl:param name="n-components" as="xs:string*"/>
      <xsl:param name="ref-alias-errors" tunnel="yes" as="element()*"/>

      <xsl:choose>
         <!-- Keep going, but only if there are more divs AND n components -->
         <xsl:when test="count($divs-to-model) gt 1 and count($n-components) gt 1">
            <xsl:copy>
               <xsl:copy-of select="$divs-to-model[1]/@type"/>
               <xsl:attribute name="n" select="$n-components[1]"/>
               <xsl:apply-templates select="." mode="#current">
                  <xsl:with-param name="divs-to-model" as="element()*" select="tail($divs-to-model)"/>
                  <xsl:with-param name="n-components" as="xs:string*" select="tail($n-components)"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@* except @n"/>
               <xsl:attribute name="n" select="$n-components[1]"/>
               <xsl:attribute name="alias-copy" select="true()"/>
               <xsl:copy-of select="$ref-alias-errors"/>
               <xsl:copy-of select="node()"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   <xsl:template match="tei:text" mode="tan:core-expansion-terse tan:dependency-adjustments-pass-1">
      <!-- Makes sure tei:body rises rootward one level, as is customary for <body> in TAN and HTML -->
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   <!-- remove space-only nodes -->
   <xsl:template match="*:body/text() | *:div[*:div]/text()" mode="tan:dependency-adjustments-pass-1">
      <xsl:if test="matches(., '\S')">
         <xsl:message select="string(root(.)/*/@id), ' has illegal text at', tan:path(.)"/>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tan:div | tei:div" mode="tan:core-expansion-terse">
      <xsl:param name="parent-new-refs" as="element()*" select="$tan:empty-element"/>
      
      <xsl:variable name="is-tei" select="namespace-uri() eq 'http://www.tei-c.org/ns/1.0'"
         as="xs:boolean"/>
      <xsl:variable name="expand-n" select="not(exists(ancestor::tan:claim))"/>
      
      <xsl:variable name="this-n-analyzed" as="element()">
         <analysis>
            <!-- A resolved file is already space- and syntax-normalized -->
            <xsl:for-each select="tokenize(@n, ' ')">
               <xsl:choose>
                  <xsl:when test="contains(., '-')">
                     <xsl:variable name="this-analyzed"
                        select="tan:analyze-sequence(., 'n', $expand-n)" as="element()"/>
                     <xsl:copy-of select="$this-analyzed/*"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <n attr="">
                        <xsl:value-of select="."/>
                     </n>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </analysis>
      </xsl:variable>
      
      <xsl:variable name="new-refs" as="element()*">
         <xsl:for-each select="$parent-new-refs">
            <xsl:variable name="this-ref" select="."/>
            <xsl:for-each select="$this-n-analyzed/*[not(self::tan:error)]">
               <ref>
                  <xsl:value-of select="string-join(($this-ref/text(), .), $tan:separator-hierarchy)"/>
                  <xsl:copy-of select="$this-ref/*"/>
                  <n>
                     <xsl:value-of select="."/>
                  </n>
               </ref>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="is-leaf-div" select="not(exists(*:div))"/>
      
      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode core-expansion-terse, for: ', ."/>
         <xsl:message select="'This @n analyzed: ', $this-n-analyzed"/>
      </xsl:if>
      
      <div>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$this-n-analyzed/*"/>
         <xsl:copy-of select="$new-refs"/>
         <xsl:if
            test="
               some $i in $this-n-analyzed/*
                  satisfies matches(., '^0\d')">
            <xsl:copy-of select="tan:error('cl117')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="parent-new-refs" select="$new-refs"/>
         </xsl:apply-templates>
         <xsl:if test="$is-leaf-div and $is-tei">
            <xsl:value-of select="string-join(tei:*)"/>
         </xsl:if>
         
      </div>
   </xsl:template>

   
   <xsl:function name="tan:imprint-adjustment-locator" as="element()*" visibility="private">
      <!-- one-parameter version of the full one below -->
      <xsl:param name="adjustment-action-locators" as="element()*"/>
      <xsl:copy-of select="tan:imprint-adjustment-locator($adjustment-action-locators, ())"/>
   </xsl:function>
   
   <xsl:function name="tan:imprint-adjustment-locator" as="element()*" visibility="private">
      <!-- Input: any locator from an adjustment action (ref, n, div-type, from-tok, through-tok); any errors to report -->
      <!-- Output: the locator wrapped in its ancestral element and wrapping any errors -->
      <!-- This function is used to mark class 1 files with a record of locators in class 2 adjustments -->
      <xsl:param name="adjustment-action-locators" as="element()*"/>
      <xsl:param name="errors-to-report" as="element()*"/>
      <xsl:for-each select="$adjustment-action-locators">
         <xsl:variable name="this-locators-adjustment-action-ancestor"
            select="ancestor::*[name() = ('skip', 'rename', 'equate', 'reassign')]"/>
         <xsl:choose>
            <xsl:when test="exists($this-locators-adjustment-action-ancestor)">
               <xsl:element name="{name($this-locators-adjustment-action-ancestor)}">
                  <xsl:copy-of select="$this-locators-adjustment-action-ancestor/@*"/>
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:copy-of select="$errors-to-report"/>
                     <xsl:copy-of select="node()"/>
                     <!--<xsl:apply-templates mode="imprint-adjustment-action"/>-->
                  </xsl:copy>
               </xsl:element>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message select="'no adjustment ancestor is found for ', ."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   

   <xsl:template match="tan:div | tei:div" mode="tan:dependency-adjustments-pass-1">
      <!-- This template applies <skip>, <rename>, and <equate> in class 2 <adjustments> upon a dependency class 1 file,
         and expands <n> and <ref> -->
      <!-- Errors in <adjustments> are embedded to report back to the dependent class 2 file. In those cases, the error is associated not with the specific instruction but its locator, i.e., the element + @q version of the the expanded forms of @div-type, @n, @ref. -->
      <xsl:param name="adjustment-actions-resolved" tunnel="yes" as="element()*"/>
      <xsl:param name="parent-orig-refs" as="element()*" select="$tan:empty-element"/>
      <xsl:param name="parent-new-refs" as="element()*" select="$tan:empty-element"/>
      <xsl:param name="div-filters" as="element()*" tunnel="yes"/>
      <xsl:param name="drop-divs" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="use-validation-mode" as="xs:boolean?" tunnel="yes" select="$tan:validation-mode-on"/>
      
      <xsl:variable name="these-div-types" select="tokenize(normalize-space(@type), ' ')"/>
      
      <xsl:variable name="these-adjustment-actions" select="
            $adjustment-actions-resolved[if (exists(parent::tan:adjustments/(tan:div-type | tan:where/tan:div-type)))
            then
               (parent::tan:adjustments/(tan:div-type | tan:where/tan:div-type) = $these-div-types)
            else
               true()]"/>

      
      <xsl:variable name="this-n-analyzed" as="element()">
         <analysis>
            <!-- A resolved file's @n is already space- and syntax-normalized -->
            <xsl:for-each select="tokenize(@n, ' ')">
               <xsl:choose>
                  <xsl:when test="contains(., '-')">
                     <xsl:variable name="this-analyzed"
                        select="tan:analyze-sequence(., 'n', true())" as="element()"/>
                     <xsl:copy-of select="$this-analyzed/*"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <n attr="">
                        <xsl:value-of select="."/>
                     </n>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each>
         </analysis>
      </xsl:variable>
      
      <xsl:variable name="equate-n-aliases" select="$these-adjustment-actions/self::tan:equate[tan:n = $this-n-analyzed/*]" as="element()*"/>
      
      <xsl:variable name="these-orig-refs-analyzed" as="element()*">
         <xsl:for-each select="$parent-orig-refs">
            <xsl:variable name="this-ref" select="."/>
            <xsl:for-each select="$this-n-analyzed/*, $equate-n-aliases/tan:n[not(. = $this-n-analyzed/*)]">
               <ref>
                  <xsl:value-of select="string-join(($this-ref/text(), .), $tan:separator-hierarchy)"/>
                  <xsl:copy-of select="$this-ref/*"/>
                  <xsl:copy-of select="."/>
               </ref>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>

      <!-- When fetching the appropriate adjustment actions, first check to see if one of a div-type filter is relevant. Then look for the three
      other types of locators: div-type, n, ref -->
      <xsl:variable name="these-adjustment-action-locators" select="
            $these-adjustment-actions/(tan:div-type[. = $these-div-types],
            tan:n[. = $this-n-analyzed/*], tan:ref[text() = $these-orig-refs-analyzed/text()])"
      />
      
      
      <xsl:variable name="skip-locators"
         select="$these-adjustment-action-locators[parent::tan:skip]"/>
      <xsl:variable name="rename-ref-locators"
         select="$these-adjustment-action-locators[parent::tan:rename][self::tan:ref]"/>
      <xsl:variable name="rename-n-locators"
         select="$these-adjustment-action-locators[parent::tan:rename][self::tan:n]"/>
      <xsl:variable name="equate-locators"
         select="$these-adjustment-action-locators[parent::tan:equate]"/>
      <xsl:variable name="actionable-adjustments" as="element()*">
         <xsl:choose>
            <xsl:when test="exists($skip-locators)">
               <!-- A skip locator overrides every other adjustment action -->
               <xsl:sequence select="$skip-locators[1]"/>
            </xsl:when>
            <xsl:when test="exists($rename-ref-locators)">
               <!-- A ref-based rename locator overrides every adjustment action except skip -->
               <xsl:sequence select="$rename-ref-locators[1]"/>
            </xsl:when>
            <xsl:otherwise>
               <!-- There may be multiple rename n actions or equate actions, but only one per value of n -->
               <xsl:for-each select="distinct-values($this-n-analyzed/*)">
                  <xsl:variable name="this-n" select="."/>
                  <xsl:sequence select="($rename-n-locators[. = $this-n], $equate-locators[. = $this-n])[1]"/>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="not-actionable-adjustments" select="$these-adjustment-action-locators except $actionable-adjustments"/>
      <xsl:variable name="notices-to-imprint" as="element()*">
         <xsl:copy-of select="tan:imprint-adjustment-locator($actionable-adjustments)"/>
         <xsl:if test="exists($not-actionable-adjustments)">
            <xsl:variable name="adjustment-error-message"
               select="
                  ('At src ' || root()/*/@src || ' ref ' || $these-orig-refs-analyzed[1]/text() || ' this adjustment action overridden by: ' ||
                  string-join((for $i in $actionable-adjustments
                  return
                     (name($i/parent::*) || ' ' || string-join(for $j in $i/(@n, @ref, @div-type)
                     return
                        (name($j) || '=`' || $j || '`'), ' '))), '; '))"/>
            <xsl:copy-of
               select="tan:imprint-adjustment-locator($not-actionable-adjustments, tan:error('cl219', $adjustment-error-message))"
            />
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="is-tei" select="namespace-uri() eq 'http://www.tei-c.org/ns/1.0'"
         as="xs:boolean"/>
      <xsl:variable name="is-leaf-div" as="xs:boolean" select="not(exists(*:div))"/>
      <xsl:variable name="this-text" as="xs:string?" select="
            if ($is-leaf-div) then
               string-join((tei:* | text()))
            else
               ()"/>

      <xsl:variable name="text-end-is-fragmentary" as="xs:boolean"
         select="exists(@_removed)"/>

      <xsl:variable name="element-with-rest-of-fragment" as="element()?"
         select="
            if ($text-end-is-fragmentary) then
               following::*:div[not(*:div)][1]
            else
               ()"
      />
      <xsl:variable name="that-text" as="xs:string?" select="
            if ($is-leaf-div) then
               string($element-with-rest-of-fragment)
            else
               ()"/>

      <xsl:variable name="missing-fragment" as="xs:string?">
         <xsl:if test="string-length($that-text) gt 0">
            <xsl:value-of select="tokenize($that-text, ' ')[1]"/>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="this-text-norm"
         select="
            if ($text-end-is-fragmentary) then
               ($this-text || $missing-fragment || ' ')
            else
               $this-text"
      />

      <xsl:choose>
         <xsl:when test="exists($skip-locators)">
            <!-- Before any other adjustment, we deal with skips, the highest-priority action. -->
            <!-- if it's a shallow skip, keep going; otherwise drop out -->
            <xsl:copy-of select="$notices-to-imprint"/>
            <xsl:if
               test="not(exists($actionable-adjustments/../@shallow)) or $actionable-adjustments/../@shallow = true()">
               <xsl:apply-templates select="*:div" mode="#current">
                  <!-- original refs retain this node's properties, even if it is being skipped, to trace refs based on the legacy system -->
                  <xsl:with-param name="parent-orig-refs" select="$these-orig-refs-analyzed"/>
                  <xsl:with-param name="parent-new-refs" select="$parent-new-refs"/>
               </xsl:apply-templates>
            </xsl:if>
         </xsl:when>
         <xsl:when test="exists($rename-ref-locators)">
            <!-- A ref-based rename is a hard rename with high priority, so it eliminates alternative @n values, native or inherited -->
            
            <xsl:variable name="this-new" select="$actionable-adjustments/../tan:new"/>
            <xsl:variable name="this-by" select="$actionable-adjustments/../tan:by"/>
            <xsl:variable name="this-new-ref" as="element()?">
               <xsl:choose>
                  <xsl:when test="exists($this-new)">
                     <xsl:variable name="this-ref-pos" select="count($actionable-adjustments/preceding-sibling::tan:ref) + 1"/>
                     <xsl:for-each select="$this-new/tan:ref[$this-ref-pos]">
                        <xsl:copy>
                           <xsl:copy-of select="@*"/>
                           <xsl:attribute name="reset"/>
                           <xsl:copy-of select="node()"/>
                        </xsl:copy>
                     </xsl:for-each>
                     <!--<xsl:copy-of select="$this-new/tan:ref"/>-->
                  </xsl:when>
                  <xsl:when test="exists($this-by)">
                     <xsl:variable name="last-n" select="$actionable-adjustments/tan:n[last()]"/>
                     <xsl:variable name="ns-are-ok" select="($this-by castable as xs:integer) and ($last-n castable as xs:integer)"/>
                     <xsl:variable name="new-n"
                        select="
                           if ($ns-are-ok) then
                              string(xs:integer($last-n) + xs:integer($this-by))
                           else
                              $last-n"
                     />
                     <ref>
                        <xsl:attribute name="reset"/>
                        <xsl:value-of select="string-join((($actionable-adjustments/tan:n except $last-n), $new-n),$tan:separator-hierarchy)"/>
                        <xsl:copy-of select="$actionable-adjustments/tan:n except $last-n"/>
                        <n>
                           <xsl:value-of select="$new-n"/>
                        </n>
                     </ref>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:message select="'ref rename missing @new and @by'"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            
            <div>
               <xsl:copy-of select="@*"/>
               <xsl:if test="$text-end-is-fragmentary">
                  <xsl:attribute name="frag-from" select="$element-with-rest-of-fragment/@q"/>
               </xsl:if>
               <xsl:copy-of select="tan:type"/>
               <!-- new n -->
               <xsl:copy-of select="$this-new-ref/tan:n[last()]"/>
               <!-- new ref -->
               <xsl:copy-of select="$this-new-ref"/>
               <xsl:copy-of select="$notices-to-imprint"/>
               <xsl:choose>
                  <xsl:when test="$is-leaf-div and $is-tei">
                     <xsl:if test="not($use-validation-mode)">
                        <!-- In validation of class-2 sources we are not interested in evaluating the validity of the TEI nodes, so we drop them altogether -->
                        <xsl:apply-templates select="*" mode="#current"/>
                     </xsl:if>
                        <!-- If this is TEI, we add a plain text version of the text -->
                     <xsl:value-of select="$this-text-norm"/>
                  </xsl:when>
                  <xsl:when test="$is-leaf-div">
                     <xsl:value-of select="$this-text-norm"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates mode="#current">
                        <xsl:with-param name="parent-orig-refs" select="$these-orig-refs-analyzed"/>
                        <xsl:with-param name="parent-new-refs" select="$this-new-ref"/>
                     </xsl:apply-templates>
                  </xsl:otherwise>
               </xsl:choose>
            </div>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="new-ns" as="element()*">
               <xsl:choose>
                  <xsl:when test="exists($actionable-adjustments)">
                     <xsl:for-each select="$this-n-analyzed/*">
                        <xsl:variable name="this-n" select="."/>
                        <xsl:variable name="this-adjustment" select="$actionable-adjustments[. = $this-n]"/>
                        <xsl:choose>
                           <xsl:when test="exists($this-adjustment/parent::tan:equate)">
                              <xsl:copy-of select="$this-adjustment/../tan:n"/>
                           </xsl:when>
                           <xsl:when test="exists($this-adjustment/../tan:new)">
                              <xsl:copy-of select="$this-adjustment/../tan:new/tan:n"/>
                           </xsl:when>
                           <xsl:when test="exists($this-adjustment/../tan:by)">
                              <xsl:variable name="ns-are-ok" select="($this-adjustment/../tan:by castable as xs:integer) and ($this-n castable as xs:integer)"/>
                              <n>
                                 <xsl:value-of
                                    select="
                                       if ($ns-are-ok) then
                                          string(xs:integer($this-n) + xs:integer($this-adjustment/../tan:by))
                                       else
                                          $this-n"/>
                              </n>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of select="."/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="$this-n-analyzed/*"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="new-refs" as="element()*">
               <xsl:choose>
                  <xsl:when test="parent::*:body and not(exists($actionable-adjustments))">
                     <xsl:sequence select="$these-orig-refs-analyzed"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:for-each select="$parent-new-refs">
                        <xsl:variable name="this-ref" select="."/>
                        <xsl:for-each select="$new-ns">
                           <ref>
                              <xsl:value-of select="string-join(($this-ref/text(), .), $tan:separator-hierarchy)"/>
                              <xsl:copy-of select="$this-ref/*"/>
                              <xsl:copy-of select="."/>
                           </ref>
                        </xsl:for-each>
                     </xsl:for-each>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="this-n-level" select="count($new-refs[1]/tan:n)"/>
            <xsl:variable name="next-n-level" select="$this-n-level + 1"/>
            <!--<xsl:variable name="filters-for-this-div" select="$div-filters[tan:ref[tan:n[$this-n-level] = $new-ns]]"/>-->
            <xsl:variable name="filters-for-this-div" select="$div-filters[tan:n = $new-ns]"/>
            <!--<xsl:variable name="div-filters-to-pass-to-children"
               select="$filters-for-this-div[tan:ref[tan:n[$next-n-level]]]"/>-->
            <xsl:variable name="div-filters-to-pass-to-children"
               select="$filters-for-this-div/tan:div"/>
            <xsl:variable name="deep-skip-this-element" select="not(exists($adjustment-actions-resolved)) and $drop-divs and not(exists($filters-for-this-div))"/>
            <xsl:variable name="deep-skip-children" select="not(exists($adjustment-actions-resolved)) and $drop-divs and not(exists($div-filters-to-pass-to-children))"/>
            
            <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="false()"/>
            
            <xsl:if test="$output-diagnostics-on">
               <diagnostics-for-dependency-adjustments-pass-1>
                  <self-shallow><xsl:copy-of select="tan:shallow-copy(.)"/></self-shallow>
                  <adj-actions-resolved><xsl:copy-of select="$adjustment-actions-resolved"/></adj-actions-resolved>
                  <parent-orig-refs><xsl:copy-of select="$parent-orig-refs"/></parent-orig-refs>
                  <parent-new-refs><xsl:copy-of select="$parent-new-refs"/></parent-new-refs>
                  <div-filters><xsl:copy-of select="$div-filters"/></div-filters>
                  <drop-divs><xsl:copy-of select="$drop-divs"/></drop-divs>
                  <use-validation-mode><xsl:copy-of select="$use-validation-mode"/></use-validation-mode>
                  <these-adjustment-actions><xsl:copy-of select="$these-adjustment-actions"/></these-adjustment-actions>
                  <this-n-analyzed><xsl:copy-of select="$this-n-analyzed"/></this-n-analyzed>
                  <equate-n-aliases><xsl:copy-of select="$equate-n-aliases"/></equate-n-aliases>
                  <these-orig-refs-analyzed><xsl:copy-of select="$these-orig-refs-analyzed"/></these-orig-refs-analyzed>
                  <adjustment-action-locators><xsl:copy-of select="$these-adjustment-action-locators"/></adjustment-action-locators>
                  <is-tei><xsl:copy-of select="$is-tei"/></is-tei>
                  <is-leaf-div><xsl:copy-of select="$is-leaf-div"/></is-leaf-div>
                  <this-text><xsl:copy-of select="$this-text"/></this-text>
                  <this-text-norm><xsl:copy-of select="$this-text-norm"/></this-text-norm>
                  <new-ns><xsl:copy-of select="$new-ns"/></new-ns>
                  <new-refs><xsl:copy-of select="$new-refs"/></new-refs>
                  <filters-for-this-div><xsl:copy-of select="$filters-for-this-div"/></filters-for-this-div>
                  <div-filters-to-pass-to-children><xsl:copy-of select="$div-filters-to-pass-to-children"/></div-filters-to-pass-to-children>
                  <deep-skip-this-element><xsl:copy-of select="$deep-skip-this-element"/></deep-skip-this-element>
               </diagnostics-for-dependency-adjustments-pass-1>
            </xsl:if>
            
            <xsl:if test="not($deep-skip-this-element)">
               
               
               <div>
                  <xsl:copy-of select="@*"/>
                  <xsl:if test="$text-end-is-fragmentary">
                     <xsl:attribute name="frag-from" select="$element-with-rest-of-fragment/@q"/>
                     <xsl:attribute name="frag-appended" select="$missing-fragment"/>
                  </xsl:if>
                  <xsl:copy-of select="tan:type"/>
                  <xsl:copy-of select="$new-ns"/>
                  <xsl:copy-of select="$new-refs"/>
                  <xsl:copy-of select="$notices-to-imprint"/>
                  <xsl:if
                     test="
                        some $i in $new-ns
                           satisfies matches($i, '^0')">
                     <xsl:copy-of select="tan:error('cl117')"/>
                  </xsl:if>
                  <xsl:choose>
                     <xsl:when test="$is-leaf-div and $is-tei">
                        <xsl:apply-templates select="*" mode="#current"/>
                        <!-- If this is TEI, we add a plain text version of the text -->
                        <xsl:value-of
                           select="$this-text-norm"/>
                     </xsl:when>
                     <xsl:when test="$is-leaf-div or $deep-skip-children">
                        <xsl:value-of select="$this-text-norm"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:apply-templates mode="#current">
                           <xsl:with-param name="parent-orig-refs"
                              select="$these-orig-refs-analyzed"/>
                           <xsl:with-param name="parent-new-refs" select="$new-refs"/>
                           <xsl:with-param name="div-filters" tunnel="yes"
                              select="$div-filters-to-pass-to-children"/>
                        </xsl:apply-templates>
                     </xsl:otherwise>
                  </xsl:choose>

               </div>
            </xsl:if>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:template>

   
   <xsl:mode name="tan:build-anchor-reference" on-no-match="text-only-copy"/>
   
   <xsl:template match="tei:lb | tei:pb | tei:cb | tei:milestone" mode="tan:build-anchor-reference">
      <xsl:copy-of select="."/>
   </xsl:template>

   <!-- Ignore text generated by attributes-cum-elements -->
   <xsl:template match="tan:ref | tan:n | tan:type | tan:ed-who" mode="tan:build-anchor-reference"/>
   
   <xsl:template match="tei:teiHeader" mode="tan:core-expansion-terse tan:dependency-adjustments-pass-1">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tei:lb | tei:pb | tei:cb"
      mode="tan:core-expansion-terse tan:dependency-adjustments-pass-1">
      <xsl:param name="anchor-reference" tunnel="yes" as="element()"/>
      
      <xsl:variable name="leaf-div" select="ancestor::tei:div[1]"/>

      <xsl:variable name="this-q" as="attribute()" select="@q"/>
      <xsl:variable name="this-anchor-counterpart" as="element()"
         select="$anchor-reference/*[@q eq $this-q]"/>

      <xsl:variable name="prev-text-joined" as="xs:string?"
         select="string-join($this-anchor-counterpart/preceding-sibling::text())"/>
      <xsl:variable name="next-text-joined" as="xs:string?"
         select="string-join($this-anchor-counterpart/following-sibling::text())"/>
      
      <xsl:variable name="break-mark-check" as="element()?">
         <xsl:if test="string-length($prev-text-joined) gt 0">
            <xsl:analyze-string select="$prev-text-joined" regex="{$tan:break-marker-regex}\s*$"
               flags="x">
               <xsl:matching-substring>
                  <match>
                     <xsl:value-of select="."/>
                  </match>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:if>
         <xsl:if test="string-length($next-text-joined) gt 0">
            <xsl:analyze-string select="$next-text-joined" regex="^\s*{$tan:break-marker-regex}"
               flags="x">
               <xsl:matching-substring>
                  <match>
                     <xsl:value-of select="."/>
                  </match>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="text-should-be-joined" select="@break = ('no', 'n', 'false')"
         as="xs:boolean"/>
      <xsl:variable name="element-has-adjacent-space"
         select="
            (if (string-length($prev-text-joined) lt 1) then
               true()
            else
               matches($prev-text-joined, '\s$'))
            or (if (string-length($next-text-joined) lt 1) then
               true()
            else
               matches($next-text-joined, '^\s'))"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($break-mark-check) and not(exists(@rend))">
            <xsl:variable name="this-message"
               select="$break-mark-check/tan:match || ' looks like a break mark'"/>
            <xsl:copy-of select="tan:error('tei04', $this-message)"/>
         </xsl:if>
         <xsl:if test="not($text-should-be-joined) and not($element-has-adjacent-space)">
            <xsl:copy-of
               select="tan:error('tei05', ('prev text: [' || tan:ellipses($prev-text-joined, 0, $tan:validation-context-string-length-max) 
               || ']; next text: [' || tan:ellipses($next-text-joined, $tan:validation-context-string-length-max) || ']'))"
            />
         </xsl:if>
         <xsl:if test="$text-should-be-joined and $element-has-adjacent-space">
            <xsl:copy-of select="tan:error('tei06')"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div/comment()" mode="tan:dependency-adjustments-pass-1"/>

   <!-- ADJUSTMENTS PASS 1: EXTRA READJUSTMENTS  -->
   
   <!-- For class-2 sources that have had token fragments adjusted -->
   
   <xsl:template match="tan:div[not(tan:div)]" mode="tan:remove-first-token">
      <xsl:param name="remove-first-token-from" tunnel="yes" as="xs:string*"/>
      <xsl:variable name="remove-token-here" select="@q = $remove-first-token-from"/>
      <xsl:choose>
         <xsl:when test="$remove-token-here">
            <xsl:variable name="text-parts" as="xs:string*">
               <xsl:analyze-string select="text()" regex="^\S+ ">
                  <xsl:matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:variable>
            <xsl:variable name="text-part-count" select="count($text-parts)"/>
            <xsl:variable name="text-to-drop" select="$text-parts[$text-part-count - 1]"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:if test="exists($text-to-drop)">
                  <xsl:attribute name="frag-dropped" select="$text-to-drop"/>
               </xsl:if>
               <xsl:copy-of select="node() except text()"/>
               <xsl:value-of select="$text-parts[$text-part-count]"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Especially for class-2 sources: reset hierarchy -->

   <xsl:key name="tan:divs-to-reset" match="tan:div" use="tan:ref/@reset"/>

   <xsl:template match="/" mode="tan:reset-hierarchy">
      <xsl:param name="divs-to-reset" tunnel="yes" as="element()*"/>
      <xsl:param name="process-entire-document" tunnel="yes" as="xs:boolean?"/>
      <xsl:variable name="this-src" select="*/@src"/>
      <xsl:variable name="these-divs-to-reset" select="$divs-to-reset[root()/*/@src = $this-src]"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode: reset-hierarchy'"/>
         <xsl:message select="'divs to reset: ', $these-divs-to-reset"/>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="($process-entire-document = true()) or exists($these-divs-to-reset)">
            <xsl:document>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="divs-to-reset" select="$these-divs-to-reset" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="tan:head" mode="tan:reset-hierarchy">
      <xsl:copy-of select="."/>
   </xsl:template>

   <!-- We need to get rid of any nested divs marked for resetting -->
   <xsl:template match="tan:div[tan:ref/@reset]" mode="tan:reset-hierarchy tan:clean-reset-divs-2"/>

   <xsl:template match="tan:body | tan:div" mode="tan:reset-hierarchy">
      <!-- divs to reset fall into three categories:
      1. those that should be merged with the current div, because there's an exact match on the ref 
      2. those that should be passed on to children because of a match on the n in the next level children 
      3. those that should be appended as last children 
      Any attempts to merge leaf divs with non-leaf divs should trigger an error message, to be imprinted
      in the adjustment action marker that caused the reset. -->
      <xsl:param name="divs-to-reset" tunnel="yes"/>
      <xsl:param name="remove-first-token-from" tunnel="yes" as="xs:string*"/>
      
      <xsl:variable name="these-ns" select="tan:n"/>
      <xsl:variable name="these-refs"
         select="
            if (self::tan:body) then
               ''
            else
               tan:ref/text()"
      />
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="children-divs-to-keep" select="tan:div[not(tan:ref/@reset)]"/>
      <xsl:variable name="children-div-refs" select="$children-divs-to-keep/tan:ref/text()"/>
      <xsl:variable name="this-n-level" select="count(tan:ref[1]/tan:n)"/>
      <xsl:variable name="next-n-level" select="$this-n-level + 1"/>
      <xsl:variable name="next-ns" select="tan:div[not(tan:ref/@reset)]/tan:n"/>
      <xsl:variable name="text-items" select="tan:tok | tan:non-tok | text()"/>
      <xsl:variable name="is-leaf-div" select="not(exists($children-divs-to-keep)) and exists($text-items)" as="xs:boolean"/>
      
      <xsl:variable name="divs-to-merge" select="$divs-to-reset[tan:ref/text() = $these-refs]"/>
      <xsl:variable name="divs-to-merge-first"
         select="
            $divs-to-merge[if (@priority castable as xs:integer) then
               xs:integer(@priority) gt 0
            else
               false()]"
      />
      <xsl:variable name="divs-to-merge-last" select="$divs-to-merge except $divs-to-merge-first"/>
      <xsl:variable name="divs-to-pass-on" select="$divs-to-reset[tan:ref[tan:n[$next-n-level] = $next-ns]]"/>
      <xsl:variable name="divs-to-append" select="$divs-to-reset except ($divs-to-merge | $divs-to-pass-on)"/>
      
      <xsl:variable name="adjust-this-text" select="$this-q = $remove-first-token-from"/>
      <xsl:variable name="text-parts" as="xs:string*">
         <xsl:if test="$adjust-this-text">
            <xsl:analyze-string select="text()" regex="^\S+ ">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="."/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="text-part-count" select="count($text-parts)"/>
      <xsl:variable name="text-to-drop" select="$text-parts[$text-part-count - 1]"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$adjust-this-text">
            <xsl:attribute name="frag-dropped" select="$text-to-drop"/>
         </xsl:if>

         <xsl:copy-of select="node() except (tan:div | $text-items)"/>
         
         <!-- children to keep, plus reset divs to pass to children -->
         <xsl:copy-of select="tan:reset-hierarchy-loop($children-divs-to-keep, $divs-to-pass-on, $next-n-level)"/>
         
         <!-- divs to merge part 1: non-text components -->
         <xsl:apply-templates select="$divs-to-merge" mode="tan:process-merged-div">
            <xsl:with-param name="host-is-leaf-div" tunnel="yes" select="$is-leaf-div"/>
         </xsl:apply-templates>
         
         <!-- divs to merge part 2a: text nodes -->
         <xsl:for-each select="$divs-to-merge-first">
            <xsl:sort select="xs:integer(@priority)" order="descending"/>
            <xsl:copy-of select="tan:tok | tan:non-tok | text()"/>
         </xsl:for-each>
         
         <!-- the host's text nodes -->
         <xsl:choose>
            <xsl:when test="$adjust-this-text">
               <xsl:value-of select="$text-parts[$text-part-count]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="$text-items"/>
            </xsl:otherwise>
         </xsl:choose>
         
         <!-- divs to merge part 2b: text nodes -->
         <!--<xsl:copy-of select="$divs-to-merge/(tan:tok | tan:non-tok | text())"/>-->
         <xsl:for-each select="$divs-to-merge-last">
            <xsl:sort select="(xs:integer(@priority), 0)[1]" order="descending"/>
            <xsl:copy-of select="tan:tok | tan:non-tok | text()"/>
         </xsl:for-each>
         
         <!-- reset divs to append -->
         <!-- In a perfect world, there will be no preceding text nodes, because if you are appending a div,
         it shouldn't be at the level of the leaf node. But if you must do such appending, it must come after
         the text nodes. Thus, this process is saved for last -->
         <xsl:if test="exists($divs-to-append)">
            <xsl:variable name="groups-to-append" as="element()*">
               <xsl:for-each-group select="$divs-to-append" group-by="tan:ref[1]/tan:n[$next-n-level]">
                  <group>
                     <xsl:copy-of select="current-group()"/>
                  </group>
               </xsl:for-each-group> 
            </xsl:variable>
            <xsl:variable name="first-adjustment-actions" select="$divs-to-append/*[name(.) = ('rename', 'reassign')][1]"/>
            <xsl:variable name="imprint-mix-error-at" as="xs:string*"
               select="
                  if ($is-leaf-div) then
                     $first-adjustment-actions/@q
                  else
                     ()"
            />

            <xsl:apply-templates select="$groups-to-append" mode="tan:process-appended-div">
               <xsl:with-param name="level" select="$next-n-level"/>
               <xsl:with-param name="imprint-mix-error-at" tunnel="yes" select="$imprint-mix-error-at"/>
            </xsl:apply-templates>
            
         </xsl:if>
      </xsl:copy>
      
   </xsl:template>
   
   
   <xsl:mode name="tan:process-appended-div" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:group" mode="tan:process-appended-div">
      <xsl:param name="level" as="xs:integer"/>
      <xsl:variable name="next-level" select="$level + 1"/>
      <xsl:for-each-group select="tan:div" group-by="tan:ref[1]/tan:n[$level]">
         <xsl:variable name="divs-to-process-now" select="current-group()[tan:ref[1][not(exists(tan:n[$next-level]))]]"/>
         <xsl:variable name="divs-to-process-now-sorted" as="element()*">
            <xsl:for-each select="$divs-to-process-now">
               <xsl:sort select="(xs:integer((.//@priority)[1]), 0)[1]" order="descending"/>
               <xsl:sequence select="."/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="divs-to-re-group" select="current-group() except $divs-to-process-now"/>
         
         <!--<xsl:apply-templates select="$divs-to-process-now" mode="#current"/>-->
         <xsl:apply-templates select="$divs-to-process-now-sorted[1]" mode="#current">
            <xsl:with-param name="divs-to-insert" select="$divs-to-process-now-sorted[position() gt 1]"/>
         </xsl:apply-templates>
         
         <xsl:if test="exists($divs-to-re-group)">
            <!-- If there are divs that go deeper than the current level, keep processing, within a shell
            <div> with mock <ref> for the group. -->
            <xsl:variable name="these-ns" select="$divs-to-re-group[1]/tan:ref[1]/tan:n[position() le $level]"/>
            <xsl:variable name="new-group" as="element()">
               <group>
                  <xsl:copy-of select="$divs-to-re-group"/>
               </group>
            </xsl:variable>
            <div>
               <xsl:copy-of select="$these-ns[last()]"/>
               <ref>
                  <xsl:value-of select="string-join($these-ns, $tan:separator-hierarchy)"/>
                  <xsl:copy-of select="$these-ns"/>
               </ref>
               <xsl:apply-templates select="$new-group" mode="#current">
                  <xsl:with-param name="level" select="$next-level"/>
               </xsl:apply-templates>
            </div>
         </xsl:if>
      </xsl:for-each-group> 
      
   </xsl:template>
   
   <xsl:template match="tan:div" mode="tan:process-appended-div">
      <xsl:param name="divs-to-insert" as="element()*"/>
      <xsl:variable name="these-text-nodes" select="tan:tok | tan:non-tok | text()"/>
      <xsl:variable name="insertion-text-nodes" select="$divs-to-insert/(tan:tok | tan:non-tok | text())"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="has-been-reset"/>
         <xsl:apply-templates select="node() except $these-text-nodes" mode="tan:strip-divs-to-reset"/>
         <xsl:apply-templates select="$divs-to-insert/node() except $insertion-text-nodes" mode="tan:strip-divs-to-reset"/>
         <xsl:apply-templates select="$these-text-nodes" mode="tan:strip-divs-to-reset"/>
         <xsl:apply-templates select="$insertion-text-nodes" mode="tan:strip-divs-to-reset"/>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:process-merged-div" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:div" mode="tan:process-merged-div">
      <xsl:param name="host-is-leaf-div" tunnel="yes" as="xs:boolean"/>
      <xsl:variable name="this-is-leaf-div" select="not(exists(tan:div))"/>
      <xsl:variable name="rename-and-reassign-adjustment-actions" select="tan:rename | tan:reassign | tan:passage"/>
      <xsl:variable name="imprint-mix-error-at" as="xs:string*"
         select="
            if (not($host-is-leaf-div eq $this-is-leaf-div)) then
               $rename-and-reassign-adjustment-actions/@q
            else
               ()"/>
      <xsl:variable name="ref-nodes" select="tan:n | tan:ref"/>
      <xsl:variable name="text-nodes" select="tan:tok | tan:non-tok | text()"/>

      <!-- unlike appended divs, which can take @has-been-reset, there is no placeholder for annotation,
         so we use comments just before the text nodes -->
      <xsl:comment><xsl:value-of select="'div ' || @q || ' ' || @type || ' ' || @n || ' has been merged below with ' || tan:ref[1]/text()"/></xsl:comment>

      <xsl:apply-templates select="* except ($ref-nodes | $text-nodes)" mode="tan:strip-divs-to-reset">
         <xsl:with-param name="imprint-mix-error-at" tunnel="yes" select="$imprint-mix-error-at"/>
      </xsl:apply-templates>
   </xsl:template>
   
   
   <xsl:mode name="tan:strip-divs-to-reset" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:rename | tan:reassign | tan:passage" mode="tan:strip-divs-to-reset">
      <xsl:param name="imprint-mix-error-at" tunnel="yes" as="xs:string*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node()"/>
         <xsl:if test="@q = $imprint-mix-error-at">
            <xsl:copy-of select="tan:error('cl217')"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:ref[@reset]" mode="tan:strip-divs-to-reset">
      <xsl:copy>
         <xsl:copy-of select="@* except @reset"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:div[tan:ref[@reset]]" mode="tan:strip-divs-to-reset"/>
   
   <xsl:function name="tan:reset-hierarchy-loop" as="element()*" visibility="private">
      <!-- Input: <div>s to process; <div>s to merge -->
      <!-- Output: any <div>s in the first group with <div>s in the second group that should be merged or passed
      to children will be passed through template mode reset-hierarchy; all others will be copied in place -->
      <!-- We presume that only the first tan:ref is the one to match against -->
      <xsl:param name="divs-to-process" as="element()*"/>
      <xsl:param name="divs-to-integrate" as="element()*"/>
      <xsl:param name="level-of-interest" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="count($divs-to-process) lt 1">
            <xsl:copy-of select="$divs-to-integrate"/>
         </xsl:when>
         <xsl:when test="count($divs-to-integrate) lt 1">
            <xsl:apply-templates select="$divs-to-process" mode="tan:strip-divs-to-reset"/>
         </xsl:when>
         <xsl:otherwise>
            <!-- We go in reverse order, because if there are many divs with the same ref, we want any new divs to be 
            merged with the last one, not the first. -->
            <xsl:variable name="next-div-to-process" select="$divs-to-process[last()]"/>
            <xsl:variable name="next-div-integrations" select="$divs-to-integrate[tan:ref[1][tan:n[$level-of-interest] = $next-div-to-process/tan:n]]"/>
            <!--<xsl:variable name="matching-divs-to-process" select="$divs-to-process[tan:n = $divs-to-integrate[tan:ref/tan:n[$level-of-interest]]]"/>-->
            <xsl:choose>
               <xsl:when test="not(exists($next-div-integrations))">
                  <xsl:sequence
                     select="tan:reset-hierarchy-loop(($divs-to-process except $next-div-to-process), $divs-to-integrate, $level-of-interest)"
                  />
                  <!-- because this is the last div, it gets templates applied after the re-loop -->
                  <xsl:apply-templates select="$next-div-to-process" mode="tan:strip-divs-to-reset"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence
                     select="tan:reset-hierarchy-loop(($divs-to-process except $next-div-to-process), ($divs-to-integrate except $next-div-integrations), $level-of-interest)"
                  />
                  <xsl:apply-templates select="$next-div-to-process" mode="tan:reset-hierarchy">
                     <xsl:with-param name="divs-to-reset" tunnel="yes" select="$next-div-integrations"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
            
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>


   
   <xsl:mode name="tan:clean-reset-divs-1" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:clean-reset-divs-2" on-no-match="shallow-copy"/>

   <xsl:template match="tan:div" mode="tan:clean-reset-divs-1">
      <xsl:param name="level" as="xs:integer"/>
      <xsl:choose>
         <!-- If an orphaned div is say 4 levels deep and has been placed as a child of the first level, then some dummy <div>s need to be built up to represent the hierarchy -->
         <xsl:when test="count(tan:ref[1]/tan:n) gt $level">
            <div>
               <xsl:for-each select="tan:ref">
                  <xsl:copy>
                     <xsl:value-of select="text()"/>
                     <xsl:copy-of select="tan:n[position() le $level]"/>
                  </xsl:copy>
               </xsl:for-each>
               <xsl:apply-templates select="." mode="#current">
                  <xsl:with-param name="level" select="$level + 1"/>
               </xsl:apply-templates>
            </div>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="has-been-reset"/>
               <xsl:apply-templates mode="tan:clean-reset-divs-2"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Remove any @reset or temporarily added attribute -->
   <xsl:template match="tan:ref" mode="tan:clean-reset-divs-2">
      <xsl:copy>
         <xsl:copy-of select="@* except (@reset)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>


   <!-- 2nd pass of adjustments for class-2 sources: tokenize selectively, apply <reassign>s -->

   <xsl:template match="/" mode="tan:dependency-adjustments-pass-2">
      <xsl:param name="class-2-doc" tunnel="yes" as="document-node()?"/>
      <xsl:variable name="this-src-id" select="*/@src"/>
      <xsl:variable name="this-token-definition"
         select="($class-2-doc/*/tan:head/tan:token-definition[tan:src/text() = $this-src-id], $tan:token-definition-default)[1]"/>

      <xsl:variable name="these-reassigns"
         select="$class-2-doc/*/tan:head/tan:adjustments[(tan:src/text(), tan:where/tan:src/text()) = ($this-src-id, $tan:all-selector)]/tan:reassign"/>
      
      
      <xsl:variable name="n-alias-items"
         select="
            if (exists($these-reassigns)) then
               tan:TAN-T/tan:head/tan:vocabulary/tan:item[tan:affects-attribute = 'n']
            else
               ()"
      />
      <xsl:variable name="these-reassigns-adjusted" as="element()*">
         <xsl:choose>
            <xsl:when test="exists($n-alias-items)">
               <xsl:apply-templates select="$these-reassigns" mode="tan:resolve-reference-tree-numerals">
                  <xsl:with-param name="n-alias-items" tunnel="yes" select="$n-alias-items"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$these-reassigns"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      
      

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode dependency-adjustments-pass-2, for: ', tan:shallow-copy(*)"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="exists($these-reassigns)">
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'applying reassigns to ', string($this-src-id)"/>
               <xsl:message select="'reassigns: ', $these-reassigns"/>
               <xsl:message select="'n alias items: ', $n-alias-items"/>
               <xsl:message select="'reassigns adjusted: ', $these-reassigns-adjusted"/>
               <xsl:message select="'token definition: ', $this-token-definition"/>
            </xsl:if>
            <xsl:document>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="adjustment-reassigns" select="$these-reassigns-adjusted"
                     tunnel="yes"/>
                  <xsl:with-param name="token-definition" select="$this-token-definition"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="tan:head" mode="tan:dependency-adjustments-pass-2">
      <xsl:copy-of select="."/>
   </xsl:template>

   <xsl:template match="tan:div" mode="tan:dependency-adjustments-pass-2">
      <!-- We do not break the template out according to leaf divs and non-leaf divs because in the course of renaming, mixed <div>s might have been created -->
      <xsl:param name="adjustment-reassigns" as="element()*" tunnel="yes"/>
      <xsl:param name="token-definition" as="element()*" tunnel="yes"/>
      <xsl:param name="use-validation-mode" as="xs:boolean?" tunnel="yes" select="$tan:validation-mode-on"/>
      
      <xsl:variable name="this-div" select="."/>
      <xsl:variable name="these-ns" select="tan:n"/>
      <xsl:variable name="this-n-level" select="count(tan:ref[1]/tan:n)"/>
      <xsl:variable name="next-n-level" select="$this-n-level + 1"/>
      <xsl:variable name="next-ns" select="tan:div[not(tan:ref/@reset)]/tan:n"/>
      <!-- During adjustments pass 1, it is possible that non-leaf <div>s were moved into leaf <div>s or vice versa, 
         so the test is not whether there is text or <tok>s but whether there are <div>s -->
      <xsl:variable name="is-leaf-div" select="not(exists(tan:div))"/>
      <xsl:variable name="these-refs" select="tan:ref/text()"/>
      <xsl:variable name="these-reassign-adjustments"
         select="$adjustment-reassigns[tan:passage/tan:ref/text() = $these-refs]"/>
      <xsl:variable name="reassigns-to-pass-to-children"
         select="$adjustment-reassigns[tan:passage/tan:ref[tan:n[$this-n-level] = $these-ns][tan:n[$next-n-level] = $next-ns]]"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message
            select="'diagnostics on, template mode dependency-adjustments-pass-2, for: ', $these-refs"/>
         <xsl:message select="('these reassigns (' || string(count($these-reassign-adjustments)) || '): '), $these-reassign-adjustments"/>
         <xsl:message select="('reassigns to pass to children (' || string(count($reassigns-to-pass-to-children)) || '): '), $reassigns-to-pass-to-children"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="count($adjustment-reassigns) lt 1">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:when test="not($is-leaf-div)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of
                  select="tan:imprint-adjustment-locator($these-reassign-adjustments/tan:passage/tan:ref[text() = $these-refs], tan:error('rea04'))"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="adjustment-reassigns" tunnel="yes"
                     select="$reassigns-to-pass-to-children"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
         <xsl:when test="not(exists($these-reassign-adjustments))">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="text-tokenized"
               select="tan:tokenize-text(text(), $token-definition, true())"/>
            <xsl:variable name="previous-ref-renames" select="$this-div/tan:rename"/>
            <xsl:variable name="reassigns-with-passages-expanded" as="element()*">
               <xsl:apply-templates select="$these-reassign-adjustments" mode="tan:expand-reassigns">
                  <xsl:with-param name="text-tokenized" select="$text-tokenized" tunnel="yes"/>
                  <xsl:with-param name="restrict-to-refs" select="$these-refs" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:variable>
            <xsl:variable name="duplicate-tok-ns"
               select="
                  tan:duplicate-items(for $i in $reassigns-with-passages-expanded/tan:passage
                  return
                     distinct-values($i//tan:tok/@n))"
            />
            <xsl:variable name="passages-with-faulty-locators"
               select="$reassigns-with-passages-expanded/tan:passage[exists(.//tan:error)]"/>
            <xsl:variable name="overlapping-passages"
               select="$reassigns-with-passages-expanded/tan:passage[.//tan:tok/@n = $duplicate-tok-ns]"/>
            <xsl:variable name="actionable-passages"
               select="$reassigns-with-passages-expanded/tan:passage except ($passages-with-faulty-locators, $overlapping-passages)"/>
            <xsl:variable name="text-tokenized-and-marked" as="element()*">
               <!-- imprint <passage q=""/> within each <tok> and <non-tok>, a simple grouping key for the next stage -->
               <xsl:apply-templates select="$text-tokenized" mode="tan:mark-reassigns">
                  <xsl:with-param name="reassign-passages-expanded" select="$actionable-passages"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:variable>
            <xsl:variable name="text-to-retain" select="$text-tokenized-and-marked/*[tan:reassign/@q = 'none']"/>
            <xsl:variable name="text-to-reassign" select="$text-tokenized-and-marked/* except $text-to-retain"/>
            
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'text tokenized: ', $text-tokenized"/>
               <xsl:message select="'previous renames: ', $previous-ref-renames"/>
               <xsl:message select="'reassigns expanded: ', $reassigns-with-passages-expanded"/>
               <xsl:message select="'duplicates of tok @n: ', $duplicate-tok-ns"/>
               <xsl:message
                  select="'reassign passages with faulty locators: ', $passages-with-faulty-locators"/>
               <xsl:message select="'overlapping reassign passages: ', $overlapping-passages"/>
               <xsl:message
                  select="'reassign passages that can be acted upon: ', $actionable-passages"/>
               <xsl:message select="'text marked: ', $text-tokenized-and-marked"/>
            </xsl:if>
            
            <!-- First, reprint the main <div>, with any text that should be retained -->
            <div>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$this-div/(* except (tan:tok | tan:non-tok))"/>
               
               <xsl:copy-of
                  select="tan:imprint-adjustment-locator($passages-with-faulty-locators/*)"/>
               <xsl:copy-of
                  select="tan:imprint-adjustment-locator($overlapping-passages, tan:error('rea02'))"
               />
               
               <!-- For non-validation purposes, leave a marker to indicate the text has been reassigned. -->
               <xsl:if test="not($use-validation-mode)">
                  <xsl:for-each-group select="$text-to-reassign" group-by="tan:reassign/@q">
                     <xsl:variable name="this-reassign-q-val" select="current-grouping-key()"/>
                     <xsl:variable name="this-actionable-passage" select="$actionable-passages[parent::tan:reassign[@q = $this-reassign-q-val]]"/>
                     <xsl:for-each select="$this-actionable-passage">
                        <reassigned>
                           <xsl:copy-of select="../*"/>
                        </reassigned>
                     </xsl:for-each>
                  </xsl:for-each-group> 
               </xsl:if>
               
               <xsl:apply-templates select="$text-to-retain" mode="tan:unmark-tokens"/>
               
            </div>
            
            <!-- Second, distribute the text to reassign in groups -->
            <xsl:for-each-group select="$text-to-reassign" group-by="tan:reassign/@q">
               <xsl:variable name="this-reassign-q-val" select="current-grouping-key()"/>
               <xsl:variable name="this-actionable-passage" select="$actionable-passages[parent::tan:reassign[@q = $this-reassign-q-val]]"/>
               <xsl:variable name="this-reassign"
                  select="$this-actionable-passage/parent::tan:reassign"/>
               
               <div>
                  <xsl:copy-of select="$this-div/@*"/>
                  <xsl:copy-of select="$this-reassign/@priority"/>
                  
                  <xsl:apply-templates select="$this-actionable-passage" mode="#current"/>
                  
                  <xsl:copy-of select="$this-reassign/tan:to/tan:ref/tan:n[last()]"/>
                  
                  <xsl:for-each select="$this-reassign/tan:to/tan:ref">
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:attribute name="reset"/>
                        <xsl:copy-of select="node()"/>
                     </xsl:copy>
                  </xsl:for-each>
                  
                  <xsl:apply-templates select="current-group()" mode="tan:unmark-tokens"/>
                  
               </div>
            </xsl:for-each-group> 
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="tan:passage/tan:tok" mode="tan:dependency-adjustments-pass-2"/>
   
   
   <xsl:mode name="tan:expand-reassigns" on-no-match="shallow-copy"/>

   <xsl:template match="tan:passage" mode="tan:expand-reassigns">
      <xsl:param name="restrict-to-refs" tunnel="yes"/>
      <xsl:if test="tan:ref/text() = $restrict-to-refs">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
         </xsl:copy>
      </xsl:if>
   </xsl:template>
   <xsl:template match="tan:from-tok" mode="tan:expand-reassigns">
      <xsl:param name="text-tokenized" tunnel="yes" as="element()"/>
      <!--<xsl:param name="priority" tunnel="yes" as="xs:string?"/>-->
      <!-- The strategy here is to find the tokens referred to by a <from-tok> + <through-tok> locatorr pair -->
      <!-- Reference errors are embedded in the locator elements; the tokens referred to are embedded within the locators; tokens between them are copied between them -->
      <!-- We do not copy <non-tok>s because we are interested only in @n values, to later determine if there are any duplicates, to detect overlapping passages -->
      <xsl:variable name="this-from" select="."/>
      <xsl:variable name="this-through" select="following-sibling::tan:through-tok[1]"/>
      <xsl:variable name="possible-toks-for-this-from-tok"
         select="
            $text-tokenized/tan:tok[if (exists($this-from/tan:rgx)) then
               tan:matches(., $this-from/tan:rgx)
            else
               . = $this-from/tan:val]"/>
      <xsl:variable name="pos-for-this-from-tok"
         select="tan:expand-pos-or-chars($this-from/tan:pos, count($possible-toks-for-this-from-tok))"/>
      <xsl:variable name="that-from-tok"
         select="$possible-toks-for-this-from-tok[position() = $pos-for-this-from-tok]"/>

      <xsl:variable name="possible-toks-for-this-through-toks"
         select="
            $text-tokenized/tan:tok[if (exists($this-through/tan:rgx)) then
               tan:matches(., $this-through/tan:rgx)
            else
               . = $this-through/tan:val]"/>
      <xsl:variable name="pos-for-this-through-tok"
         select="tan:expand-pos-or-chars($this-through/tan:pos, count($possible-toks-for-this-through-toks))"/>
      <xsl:variable name="that-through-tok"
         select="$possible-toks-for-this-through-toks[position() = $pos-for-this-through-tok]"/>

      <xsl:variable name="those-ns"
         select="xs:integer($that-from-tok/@n), xs:integer($that-through-tok/@n)"/>
      <xsl:variable name="that-min-n" select="min($those-ns)"/>
      <xsl:variable name="that-max-n" select="max($those-ns)"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$that-from-tok"/>
         <xsl:if test="not(exists($that-from-tok))">
            <xsl:copy-of select="tan:error('tok01')"/>
         </xsl:if>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
      <xsl:for-each select="($that-min-n + 1) to ($that-max-n - 1)">
         <xsl:variable name="this-median-n" select="."/>
         <xsl:copy-of select="$text-tokenized/tan:tok[@n = $this-median-n]"/>
      </xsl:for-each>
      <through-tok>
         <xsl:copy-of select="$this-through/@*"/>
         <xsl:if test="not(exists($that-through-tok))">
            <xsl:copy-of select="tan:error('tok01')"/>
         </xsl:if>
         <xsl:if test="$those-ns[2] lt $those-ns[1]">
            <xsl:copy-of select="tan:error('rea01')"/>
         </xsl:if>
         <xsl:copy-of select="$that-through-tok"/>
         <xsl:copy-of select="$this-through/node()"/>
      </through-tok>
   </xsl:template>
   <xsl:template match="tan:through-tok" mode="tan:expand-reassigns"/>
   
   
   <xsl:mode name="tan:mark-reassigns" on-no-match="shallow-copy"/>

   <xsl:template match="tan:tok | tan:non-tok" mode="tan:mark-reassigns">
      <xsl:param name="reassign-passages-expanded" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:variable name="this-reassign-passage-locator"
         select="$reassign-passages-expanded//descendant-or-self::*[tan:tok/@n = $this-n]"/>
      <xsl:variable name="this-tok-n" select="self::tan:tok/@n"/>
      <xsl:variable name="is-passage-start" select="self::tan:tok and $this-reassign-passage-locator/self::tan:from-tok"/>
      <xsl:variable name="is-passage-end" select="$this-reassign-passage-locator/self::tan:through-tok and not(exists(following-sibling::*[1][@n = $this-n]))"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!-- Add a @q id if one doesn't exist -->
         <xsl:if test="not(exists(@q))">
            <xsl:attribute name="q" select="generate-id(.)"/>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="$is-passage-start">
               <xsl:variable name="this-passage-marker"
                  select="tan:imprint-adjustment-locator($this-reassign-passage-locator/ancestor-or-self::tan:passage/tan:ref)"/>
               <xsl:copy-of
                  select="tan:copy-of-except($this-passage-marker, ('from-tok', 'through-tok'), (), ())"/>
               <xsl:copy-of select="tan:imprint-adjustment-locator($this-reassign-passage-locator)"/>
               <xsl:copy-of select="node()"/>
            </xsl:when>
            <xsl:when test="$is-passage-end">
               <xsl:copy-of select="node()"/>
               <xsl:copy-of select="tan:imprint-adjustment-locator($this-reassign-passage-locator)"
               />
            </xsl:when>
            <xsl:when test="not(exists($this-reassign-passage-locator))">
               <reassign q="none"/>
               <xsl:copy-of select="node()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="tan:shallow-copy($this-reassign-passage-locator/ancestor::tan:reassign)"/>
               <xsl:copy-of select="node()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>


   <xsl:mode name="tan:unmark-tokens" on-no-match="shallow-copy"/>

   <!-- we get rid of grouping keys that were implanted in the tokens -->
   <xsl:template match="tan:tok/* | tan:non-tok/*" mode="tan:unmark-tokens"/>

   

   <xsl:template match="/" priority="1" mode="tan:mark-dependencies-pass-1">
      <xsl:param name="class-2-doc" tunnel="yes" as="document-node()?"/>
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      <xsl:param name="use-validation-mode" tunnel="yes" as="xs:boolean?" select="$tan:validation-mode-on"/>
      
      <xsl:variable name="this-src-id" select="*/@src"/>
      <xsl:variable name="this-token-definition"
         select="$class-2-doc/*/tan:head/tan:token-definition[tan:src/text() = $this-src-id][1]"/>
      <xsl:variable name="this-token-definition-vocabulary" select="tan:vocabulary('token-definition', $this-token-definition/@which, $class-2-doc/*/tan:head)"/>
      <xsl:variable name="this-token-definition-resolved" as="element()">
         <xsl:choose>
            <xsl:when test="exists($this-token-definition/@pattern)">
               <xsl:sequence select="$this-token-definition"/>
            </xsl:when>
            <xsl:when test="$this-token-definition-vocabulary">
               <xsl:copy-of select="($this-token-definition-vocabulary/(tan:item, tan:token-definition))[1]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$tan:token-definition-default"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="this-doc-node" select="." as="document-node()"/>

      <xsl:variable name="these-reference-trees" select="$reference-trees[tan:src/text() = $this-src-id]" as="element()*"/>
      <xsl:variable name="tokenize-here-universally" select="exists($these-reference-trees/tan:tok)"/>
      
      <xsl:variable name="n-alias-items"
         select="
            if (exists($these-reference-trees)) then
               tan:TAN-T/tan:head/tan:vocabulary/tan:item[tan:affects-attribute = 'n']
            else
               ()"
      />
      <xsl:variable name="these-reference-trees-adjusted" as="element()*">
         <xsl:choose>
            <xsl:when test="exists($n-alias-items)">
               <xsl:apply-templates select="$these-reference-trees" mode="tan:resolve-reference-tree-numerals">
                  <xsl:with-param name="n-alias-items" tunnel="yes" select="$n-alias-items"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$these-reference-trees"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message
            select="'diagnostics on for template mode mark-dependencies-pass-1, treating dependency document @src = ', xs:string($this-src-id)"/>
         <xsl:message select="'Using validation mode?', $use-validation-mode"/>
         <xsl:message select="'Class 2 token definitions ', $class-2-doc/*/tan:head/tan:token-definition"/>
         <xsl:message select="'Resolved token definition: ', $this-token-definition-resolved"/>
         <xsl:message select="'tokenize universally?', $tokenize-here-universally"/>
         <xsl:message select="'n alias items: ', $n-alias-items"/>
         <xsl:message select="'Reference trees adjusted: ', $these-reference-trees-adjusted"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="not(tan:TAN-T)">
            <xsl:document>
               <xsl:apply-templates mode="#current"/>
            </xsl:document>
         </xsl:when>
         <xsl:when test="$use-validation-mode">
            <xsl:document>
               <xsl:apply-templates mode="tan:mark-dependencies-for-validation">
                  <xsl:with-param name="reference-trees" tunnel="yes" select="$these-reference-trees-adjusted"/>
                  <xsl:with-param name="token-definition" select="$this-token-definition-resolved"
                     tunnel="yes"/>
                  <xsl:with-param name="please-tokenize" tunnel="yes" as="xs:boolean?" select="$tokenize-here-universally"/>
                  <xsl:with-param name="src-id" tunnel="yes" select="$this-src-id"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:when>
         <!-- Next cases are for non-validating expansion, where the source should be retained or enhanced -->
         <xsl:when test="exists($these-reference-trees-adjusted) or $tokenize-here-universally">
            <xsl:document>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="reference-trees" tunnel="yes" select="$these-reference-trees-adjusted"/>
                  <xsl:with-param name="token-definition" select="$this-token-definition-resolved"
                     tunnel="yes"/>
                  <xsl:with-param name="src-id" tunnel="yes" select="$this-src-id"/>
                  <xsl:with-param name="please-tokenize" tunnel="yes" as="xs:boolean?" select="$tokenize-here-universally"/>
               </xsl:apply-templates>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:mode name="tan:resolve-reference-tree-numerals" on-no-match="shallow-copy"/>
   
   <xsl:template match="comment()" mode="tan:resolve-reference-tree-numerals"/>
   
   <xsl:template match="tan:n | tan:ref" mode="tan:resolve-reference-tree-numerals">
      <xsl:param name="n-alias-items" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-val-rechecked" as="xs:string*">
         <xsl:for-each select="tokenize(text(), ' ')">
            <xsl:variable name="this-val" select="."/>
            <xsl:variable name="this-matching-item" select="$n-alias-items[tan:name = $this-val]"/>
            <xsl:choose>
               <xsl:when test="exists($this-matching-item)">
                  <xsl:value-of select="replace($this-matching-item[1]/tan:name[1], ' ', '_')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="string-join($this-val-rechecked, $tan:separator-hierarchy)"/>
         <xsl:apply-templates select="*" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:mark-dependencies-for-validation" on-no-match="shallow-copy"/>
   <!--<xsl:mode name="tan:mark-dependencies-for-validation-skip-divs" on-no-match="shallow-copy"/>-->
   <xsl:mode name="tan:mark-dependencies-for-validation-skip-divs" on-no-match="shallow-skip"/>
   
   <!-- Default behavior for validation is to dispense with elements... -->
   <!--<xsl:template priority="-1" match="* | text()" mode="tan:mark-dependencies-for-validation-skip-divs">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>-->
   <!-- ...except for anchors... -->
   <xsl:template match="tan:reassign | tan:equate | tan:skip | tan:rename | tan:passage" mode="tan:mark-dependencies-for-validation tan:mark-dependencies-for-validation-skip-divs">
      <xsl:copy-of select="."/>
   </xsl:template>
   <!-- ...and the root element -->
   <xsl:template match="/*" mode="tan:mark-dependencies-for-validation">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <marked/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <!-- If no more markers are necessary divs can be shallow-skipped. -->
   <xsl:template match="tan:div" mode="tan:mark-dependencies-for-validation-skip-divs">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   
   <xsl:template match="tan:TAN-T/tan:body" mode="tan:mark-dependencies-for-validation">
      <xsl:param name="src-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="token-definition" tunnel="yes" as="element()"/>
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="exists($reference-trees)">
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="reference-trees" tunnel="yes" select="$reference-trees/tan:div"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="tan:mark-dependencies-for-validation-skip-divs"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:template match="tan:body" mode="tan:mark-dependencies-pass-1">
      <xsl:param name="src-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="token-definition" tunnel="yes" as="element()"/>
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      
      <xsl:variable name="universal-token-refs" select="$reference-trees/tan:tok"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($universal-token-refs)">
            <!-- We leave a placeholder for global tokens -->
            <hold>
               <xsl:copy-of select="$universal-token-refs"/>
            </hold>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="reference-trees" tunnel="yes" select="$reference-trees/tan:div"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
      
   <xsl:template match="tan:div" mode="tan:mark-dependencies-for-validation">
      <xsl:param name="src-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      <xsl:param name="token-definition" tunnel="yes" as="element()*"/>
      <xsl:param name="please-tokenize" tunnel="yes" as="xs:boolean?"/>
      
      <xsl:variable name="these-ns" select="tan:n"/>
      <xsl:variable name="this-n-level" select="count(tan:ref[1]/tan:n)"/>
      <xsl:variable name="next-n-level" select="$this-n-level + 1"/>
      <xsl:variable name="these-refs" select="tan:ref/text()"/>
      <xsl:variable name="is-leaf-div" select="not(exists(tan:div))"/>
      
      <xsl:variable name="these-reference-trees" select="$reference-trees[tan:ref/text() = $these-refs]"/>
      <xsl:variable name="these-ref-parents" select="$these-reference-trees/(* except (tan:n | tan:div | tan:ref))"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode mark-dependencies-for-validation, for: ', tan:xml-to-string(tan:shallow-copy(.))"/>
         <xsl:message select="'this n level: ', $this-n-level"/>
         <xsl:message select="'ref parents that match this div: ', $these-ref-parents"/>
      </xsl:if>
      
      <!-- copy only the anchors that match, with any <ref> (div anchor) and <pos> (token anchors) nested -->
      <xsl:if test="exists($these-ref-parents)">

         <xsl:for-each select="$these-ref-parents">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:ref[text() = $these-refs]"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:if>

      <xsl:variable name="these-pos-parents" select="$these-ref-parents/descendant-or-self::*[tan:pos]"/>
      <xsl:variable name="tokenize-this" select="$please-tokenize or exists($these-pos-parents)"/>
      
      <xsl:choose>
         <xsl:when test="$is-leaf-div and not($tokenize-this)">
            <xsl:apply-templates mode="tan:mark-dependencies-for-validation-skip-divs"/>
         </xsl:when>
         <xsl:when test="$is-leaf-div">
            
            
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="node() except text()"/>
               <xsl:copy-of select="tan:tokenize-text(text(), $token-definition, false(), false(), false())/*"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="reference-trees" tunnel="yes"
                     select="$these-reference-trees/tan:div"/>
                  <xsl:with-param name="please-tokenize" tunnel="yes" select="$tokenize-this"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:template>
   
   <xsl:template match="tan:div" mode="tan:mark-dependencies-pass-1">
      <xsl:param name="src-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      <xsl:param name="please-tokenize" tunnel="yes" as="xs:boolean?"/>

      <!--<xsl:variable name="is-leaf-div" select="not(exists(tan:div))"/>-->
      <!--<xsl:variable name="these-ns" select="tan:n"/>-->
      <!--<xsl:variable name="this-n-level" select="count(tan:ref[1]/tan:n)"/>-->
      <!--<xsl:variable name="next-n-level" select="$this-n-level + 1"/>-->
      <!--<xsl:variable name="next-ns" select="tan:div[not(tan:ref/@reset)]/tan:n"/>-->
      <xsl:variable name="these-refs" select="tan:ref/text()"/>

      <xsl:variable name="these-reference-trees"
         select="$reference-trees[tan:ref/text() = $these-refs]"/>
      <xsl:variable name="these-ref-parents"
         select="$these-reference-trees/(* except (tan:n | tan:div | tan:ref))"/>
      
      <xsl:variable name="these-pos-parents"
         select="$these-ref-parents/descendant-or-self::*[tan:pos]"/>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message
            select="'diagnostics on, template mode mark-dependencies-pass-1, for: ', tan:xml-to-string(tan:shallow-copy(.))"/>
      </xsl:if>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!-- Leave a marker for any div claims -->
         <xsl:copy-of select="tan:shallow-copy($these-ref-parents/tan:ref[text() = $these-refs])"/>
         <!-- Leave a holding area for token claims, to be shifted leafward in the next pass -->
         <xsl:if test="exists($these-pos-parents)">
            <hold>
               <xsl:copy-of select="$these-pos-parents"/>
            </hold>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="reference-trees" tunnel="yes"
               select="$these-reference-trees/tan:div"/>
            <xsl:with-param name="please-tokenize" tunnel="yes"
               select="$please-tokenize or exists($these-pos-parents)"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:template match="tan:div[not(tan:div)]/text()" mode="tan:mark-dependencies-pass-1">
      <xsl:param name="please-tokenize" tunnel="yes" as="xs:boolean?"/>
      <xsl:param name="token-definition" tunnel="yes" as="element()*"/>
      <xsl:choose>
         <xsl:when test="$please-tokenize">
            <xsl:copy-of select="tan:tokenize-text(., $token-definition, true(), true(), true())/*"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:template match="/" priority="1" mode="tan:mark-dependencies-pass-2-for-validation">
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-src-id" select="(*/@src, '1')[1]"/>
      <xsl:variable name="these-reference-trees" select="$reference-trees[tan:src/text() = $this-src-id]"/>
      <xsl:document>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="reference-trees" tunnel="yes" select="$these-reference-trees"/>
            <xsl:with-param name="src-id" tunnel="yes" select="$this-src-id"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:template>
   
   <!-- We're winding down at this point, during validation, so we can jettison elements that will not be evaluated later -->
   <xsl:template match="tan:div/tan:n | tan:div/tan:ref | tan:non-tok | tan:div/tan:tok[not(*)]" mode="tan:mark-dependencies-pass-2-for-validation"/>
   
   <xsl:template match="tan:body" mode="tan:mark-dependencies-pass-2-for-validation">
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      <xsl:param name="src-id" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="these-universal-token-refs" select="$reference-trees/tan:tok"/>
      <xsl:variable name="these-toks"
         select="
            if (exists($these-universal-token-refs[tan:rgx])) then
               descendant::tan:tok
            else
               ()"
      />
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         
         <xsl:for-each select="$these-universal-token-refs[tan:val]">
            <xsl:variable name="this-val" select="tan:val"/>
            <xsl:variable name="these-hits" select="key('tan:tok-via-val', $this-val, $this-element)"/>
            <xsl:if test="exists($these-hits)">
               <xsl:variable name="hit-count" select="count($these-hits)"/>
               <xsl:variable name="this-val-length" select="string-length($this-val)"/>
               <xsl:variable name="these-poses" select="tan:pos"/>
               <xsl:for-each select="$these-poses">
                  <xsl:variable name="this-pos-value"
                     select="tan:expand-numerical-expression(., $hit-count)"/>
                  <xsl:variable name="this-tok-match" select="$these-hits[$this-pos-value]"/>
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:if test="not(exists($this-tok-match))">
                        <xsl:copy-of
                           select="tan:error('tok01', ('Source ' || $src-id || ' has ' || string($hit-count) || ' instances of ' || $this-val))"
                        />
                     </xsl:if>
                     <xsl:copy-of select="tan:sequence-error($this-pos-value)"/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:if>
         </xsl:for-each>
         
         <xsl:for-each select="$these-universal-token-refs[tan:rgx]">
            <xsl:variable name="this-rgx" select="tan:rgx"/>
            <xsl:variable name="these-hits" select="$these-toks[matches(., ('^' || $this-rgx || '$'))]"/>
            <xsl:if test="exists($these-hits)">
               <xsl:variable name="hit-count" select="count($these-hits)"/>
               <xsl:variable name="this-val-length" select="string-length($this-rgx)"/>
               <xsl:variable name="these-poses" select="tan:pos"/>
               <xsl:variable name="these-chars" select="tan:chars"/>
               <xsl:for-each select="$these-poses">
                  <xsl:variable name="this-pos-value"
                     select="tan:expand-numerical-expression(., $hit-count)"/>
                  <xsl:variable name="this-tok-match" select="$these-hits[$this-pos-value]"/>
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:if test="not(exists($this-tok-match))">
                        <xsl:copy-of
                           select="tan:error('tok01', ('Source ' || $src-id || ' has ' || string($hit-count) || ' instances of ' || $this-rgx))"
                        />
                     </xsl:if>
                     <xsl:copy-of select="tan:sequence-error($this-pos-value)"/>
                  </xsl:copy>
                  
                  <xsl:if test="exists($this-tok-match)">
                     <xsl:variable name="this-tok-match-length" select="string-length($this-tok-match)"/>
                     <xsl:for-each select="$these-chars">
                        <xsl:variable name="this-char-int"
                           select="tan:expand-numerical-expression(., $this-tok-match-length)"/>
                        <xsl:copy>
                           <xsl:copy-of select="@*"/>
                           <xsl:if test="$this-char-int le 0">
                              <xsl:copy-of select="tan:error('chr01', ('Source ' || $src-id || ' matches ' || $this-tok-match || 
                                 ' (length ' || string($this-tok-match-length) || ' characters) '))"/>
                           </xsl:if>
                        </xsl:copy>
                     </xsl:for-each>
                  </xsl:if>
                  
               </xsl:for-each>
               
            </xsl:if>
         </xsl:for-each>
         
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="reference-trees" tunnel="yes" select="$reference-trees/tan:div"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div" mode="tan:mark-dependencies-pass-2-for-validation">
      <!-- This is quite close to the one for tan:body, but it's a shallow skip, and token references are a bit trickier. -->
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      <xsl:param name="src-id" tunnel="yes"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="these-ns" select="tan:n"/>
      <xsl:variable name="these-trees-of-interest" select="$reference-trees[tan:n = $these-ns]"/>
      <xsl:variable name="these-token-refs"
         select="$these-trees-of-interest/(* except tan:div)/descendant-or-self::*[tan:pos]"/>
      <xsl:variable name="these-toks"
         select="
            if (exists($these-token-refs[tan:rgx])) then
               descendant::tan:tok
            else
               ()"/>
      

      <xsl:for-each select="$these-token-refs[tan:val]">
         <xsl:variable name="this-val" select="tan:val"/>
         <xsl:variable name="these-hits" select="key('tan:tok-via-val', $this-val, $this-element)"/>
         <xsl:if test="exists($these-hits)">
            <xsl:variable name="hit-count" select="count($these-hits)"/>
            <xsl:variable name="this-val-length" select="string-length($this-val)"/>
            <xsl:variable name="these-poses" select="tan:pos"/>
            <xsl:for-each select="$these-poses">
               <xsl:variable name="this-pos-value"
                  select="tan:expand-numerical-expression(., $hit-count)"/>
               <xsl:variable name="this-tok-match" select="$these-hits[$this-pos-value]"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:if test="not(exists($this-tok-match))">
                     <xsl:copy-of
                        select="tan:error('tok01', ('Source ' || $src-id || ' has ' || string($hit-count) || ' instances of ' || $this-val))"
                     />
                  </xsl:if>
                  <xsl:copy-of select="tan:sequence-error($this-pos-value)"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="$these-token-refs[tan:rgx]">
         <xsl:variable name="this-rgx" select="tan:rgx"/>
         <xsl:variable name="these-hits"
            select="$these-toks[matches(., ('^' || $this-rgx || '$'))]"/>
         <xsl:if test="exists($these-hits)">
            <xsl:variable name="hit-count" select="count($these-hits)"/>
            <xsl:variable name="this-val-length" select="string-length($this-rgx)"/>
            <xsl:variable name="these-poses" select="tan:pos"/>
            <xsl:variable name="these-chars" select="tan:chars"/>
            <xsl:for-each select="$these-poses">
               <xsl:variable name="this-pos-value"
                  select="tan:expand-numerical-expression(., $hit-count)"/>
               <xsl:variable name="this-tok-match" select="$these-hits[$this-pos-value]"/>
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:if test="not(exists($this-tok-match))">
                     <xsl:copy-of
                        select="tan:error('tok01', ('Source ' || $src-id || ' has ' || string($hit-count) || ' instances of ' || $this-rgx))"
                     />
                  </xsl:if>
                  <xsl:copy-of select="tan:sequence-error($this-pos-value)"/>
               </xsl:copy>

               <xsl:if test="exists($this-tok-match)">
                  <xsl:variable name="this-tok-match-length" select="string-length($this-tok-match)"/>
                  <xsl:for-each select="$these-chars">
                     <xsl:variable name="this-char-int"
                        select="tan:expand-numerical-expression(., $this-tok-match-length)"/>
                     <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:if test="$this-char-int le 0">
                           <xsl:copy-of
                              select="
                                 tan:error('chr01', ('Source ' || $src-id || ' matches ' || $this-tok-match ||
                                 ' (length ' || string($this-tok-match-length) || ' characters) '))"
                           />
                        </xsl:if>
                     </xsl:copy>
                  </xsl:for-each>
               </xsl:if>

            </xsl:for-each>

         </xsl:if>
      </xsl:for-each>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode mark-dependencies-pass-2-for-validation'"/>
         <xsl:message select="'Reference trees:', $reference-trees"/>
         <xsl:message select="'Reference trees of interest:', $these-trees-of-interest"/>
         <xsl:message select="'Token refs:', $these-token-refs"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="not(exists($these-trees-of-interest))">
            <xsl:apply-templates mode="tan:mark-dependencies-for-validation-skip-divs"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current">
               <xsl:with-param name="reference-trees" tunnel="yes" select="$these-trees-of-interest/tan:div"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
      

   </xsl:template>
   
   <xsl:template match="document-node()[tan:TAN-T]" mode="tan:mark-dependencies-pass-2">
      <xsl:param name="reference-trees" tunnel="yes" as="element()*"/>
      
      <xsl:variable name="this-doc-node" select="." as="document-node()"/>
      <xsl:variable name="this-src" select="*/@src" as="attribute()"/>
      <xsl:variable name="these-reference-trees" select="$reference-trees[tan:src/text() = $this-src]" as="element()*"/>
      <xsl:variable name="these-ref-tree-froms" as="element()*" select="$these-reference-trees//*[@from][@alter-q]"/>
      <xsl:variable name="this-insertion-key" as="element()*">
         <!-- The goal is to find out at what point each from-to pair diverge in the tree. All other values can be ignored. -->
         <xsl:for-each select="$these-ref-tree-froms">
            <xsl:variable name="this-q" select="@q"/>
            <xsl:variable name="this-alter-q" select="@alter-q"/>
            <xsl:variable name="these-markers" select="key('tan:q-ref', $this-q, $this-doc-node)"
               as="element()*"/>
            <xsl:variable name="these-alter-markers"
               select="key('tan:q-ref', $this-alter-q, $this-doc-node)" as="element()*"/>

            <xsl:variable name="these-from-qs" as="array(xs:string+)*">
               <xsl:for-each select="$these-markers">
                  <xsl:variable name="these-ancestral-divs" select="ancestor::tan:div"
                     as="element()*"/>
                  <xsl:if test="exists($these-ancestral-divs)">
                     <xsl:sequence select="
                           array {
                              for $i in $these-ancestral-divs
                              return
                                 string($i/@q)
                           }"/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="these-to-qs" as="array(xs:string+)*">
               <xsl:for-each select="$these-alter-markers">
                  <xsl:variable name="these-ancestral-divs" select="ancestor::tan:div"
                     as="element()*"/>
                  <xsl:if test="exists($these-ancestral-divs)">
                     <xsl:sequence select="
                           array {
                              for $i in $these-ancestral-divs
                              return
                                 string($i/@q)
                           }"/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="marker-to-implant" as="element()?">
               <xsl:for-each select="$these-markers[1]">
                  <xsl:copy>
                     <xsl:copy-of select="@q | @attr"/>
                     <xsl:attribute name="cont"/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:variable>

            <xsl:variable name="max-length" as="xs:integer?" select="
                  max((for $i in ($these-from-qs, $these-to-qs)
                  return
                     array:size($i)))"/>



            <xsl:if test="exists($max-length)">
               <xsl:iterate select="1 to $max-length">
                  <xsl:variable name="this-level" select="."/>
                  <xsl:variable name="these-start-qs" select="
                        for $i in $these-from-qs[array:size(.) gt 0]
                        return
                           $i($this-level)" as="xs:string+"/>
                  <xsl:variable name="these-end-qs" select="
                        for $i in $these-to-qs[array:size(.) gt 0]
                        return
                           $i($this-level)" as="xs:string+"/>
                  <xsl:variable name="sets-differ" as="xs:boolean" select="
                        (some $i in $these-start-qs
                           satisfies not($i = $these-end-qs)) or (some $i in $these-end-qs
                           satisfies not($i = $these-start-qs))"/>
                  <xsl:choose>
                     <xsl:when test="$sets-differ">
                        <insert>
                           <what>
                              <xsl:copy-of select="$marker-to-implant"/>
                           </what>
                           <xsl:for-each select="$these-from-qs">
                              <between>
                                 <xsl:for-each
                                    select="array:flatten(array:subarray(., $this-level))">
                                    <q>
                                       <xsl:value-of select="."/>
                                    </q>
                                 </xsl:for-each>
                              </between>
                           </xsl:for-each>
                           <xsl:for-each select="$these-to-qs">
                              <and>
                                 <xsl:for-each
                                    select="array:flatten(array:subarray(., $this-level))">
                                    <q>
                                       <xsl:value-of select="."/>
                                    </q>
                                 </xsl:for-each>
                              </and>
                           </xsl:for-each>
                        </insert>
                        <xsl:break/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:next-iteration/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:iterate>
            </xsl:if>



         </xsl:for-each>

      </xsl:variable>
      
      <xsl:variable name="this-doc-with-from-to-pairs-prepped" as="document-node()">
         <xsl:document>
            <xsl:choose>
               <xsl:when test="exists($this-insertion-key)">
                  <xsl:apply-templates mode="tan:mark-dependencies-pass-2-from-tos">
                     <xsl:with-param name="insertions-to-process" as="element()*" select="$this-insertion-key" tunnel="yes"/>
                  </xsl:apply-templates>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:document>
      </xsl:variable>
      
      <xsl:document>
         <xsl:apply-templates select="$this-doc-with-from-to-pairs-prepped/node()" mode="#current"/>
      </xsl:document>
      
   </xsl:template>
   
   
   <xsl:mode name="tan:mark-dependencies-pass-2-from-tos" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:body | tan:div" mode="tan:mark-dependencies-pass-2-from-tos">
      <xsl:param name="insertions-to-process" as="element()*" tunnel="yes"/>
      <xsl:param name="nodes-to-insert" as="element()*"/>
      <xsl:param name="insertions-for-starting-children" as="element()*"/>
      <xsl:param name="insertions-for-ending-children" as="element()*"/>
      
      <xsl:variable name="these-children-qs" select="*/@q"/>
      
      <xsl:variable name="new-insertions-to-be-applied" select="$insertions-to-process[*/tan:q = $these-children-qs]"/>
      <xsl:variable name="insertions-to-process-to-pass-on" select="$insertions-to-process except $new-insertions-to-be-applied" as="element()*"/>
      
      <xsl:variable name="new-insertions-revised" as="element()*">
         <xsl:for-each select="$new-insertions-to-be-applied">
            <xsl:variable name="matching-betweens" select="tan:between[tan:q[1] = $these-children-qs]"/>
            <xsl:variable name="matching-ands" select="tan:and[tan:q[1] = $these-children-qs]"/>
            <xsl:variable name="first-betweens" as="element()?">
               <xsl:for-each-group select="$matching-betweens" group-by="tan:q[1]">
                  <xsl:sort select="index-of($these-children-qs, current-grouping-key())"/>
                  <xsl:if test="position() eq 1">
                     <xsl:copy-of select="current-group()"/>
                  </xsl:if>
               </xsl:for-each-group> 
            </xsl:variable>
            <xsl:variable name="last-ands" as="element()?">
               <xsl:for-each-group select="$matching-ands" group-by="tan:q[1]">
                  <xsl:sort select="index-of($these-children-qs, current-grouping-key())" order="descending"/>
                  <xsl:if test="position() eq 1">
                     <xsl:copy-of select="current-group()"/>
                  </xsl:if>
               </xsl:for-each-group> 
            </xsl:variable>
            
            <xsl:copy>
               <xsl:copy-of select="tan:what"/>
               <xsl:copy-of select="$first-betweens"/>
               <xsl:copy-of select="$last-ands"/>
            </xsl:copy>
            
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$nodes-to-insert"/>
         <xsl:iterate select="node()">
            <xsl:param name="new-insertions-to-process" as="element()*" select="$new-insertions-revised"/>
            <xsl:param name="insertions-to-place" as="element()*"/>
            <xsl:param name="starting-insertions" as="element()*" select="$insertions-for-starting-children"/>
            <xsl:param name="ending-insertions" as="element()*"/>
            
            <xsl:variable name="this-q" select="self::tan:div/@q"/>
            <xsl:variable name="these-new-insertion-froms"
               select="$new-insertions-to-process[tan:between/tan:q = $this-q]" as="element()*"/>
            <xsl:variable name="these-new-insertion-tos"
               select="$insertions-to-place[tan:and/tan:q = $this-q]" as="element()*"/>
            <xsl:variable name="these-starting-insertions-to-end" select="$starting-insertions[tan:and/tan:q = $this-q]"/>
            <xsl:variable name="these-ending-insertions-to-start" select="$ending-insertions[tan:between/tan:q = $this-q]"/>
            
            <xsl:choose>
               <xsl:when test="not(exists($this-q))">
                  <xsl:copy-of select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="." mode="#current">
                     <xsl:with-param name="insertions-to-process" tunnel="yes" select="$insertions-to-process-to-pass-on"/>
                     <xsl:with-param name="nodes-to-insert" select="($starting-insertions except $these-starting-insertions-to-end)/tan:what/node(),
                        $ending-insertions/tan:what/node(),
                        ($insertions-to-place except $these-new-insertion-tos)/tan:what/node()"/>
                     <xsl:with-param name="insertions-for-starting-children" as="element()*" select="$insertions-for-starting-children, $these-new-insertion-tos"/>
                     <xsl:with-param name="insertions-for-ending-children" as="element()*" select="$insertions-for-ending-children, $these-new-insertion-froms"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:next-iteration>
               <xsl:with-param name="new-insertions-to-process" select="$new-insertions-to-process except $these-new-insertion-froms"/>
               <xsl:with-param name="insertions-to-place" select="($insertions-to-place, $these-new-insertion-froms) except $these-new-insertion-tos"/>
               <xsl:with-param name="starting-insertions" as="element()*" select="$starting-insertions except $these-starting-insertions-to-end"/>
               <xsl:with-param name="ending-insertions" as="element()*" select="$ending-insertions, $these-ending-insertions-to-start"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:copy>
      
   </xsl:template>
   
   <xsl:template match="tan:div[not(tan:hold)]" mode="tan:mark-dependencies-pass-2">
      <xsl:param name="items-to-push" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-string-val" as="xs:string" select="string(.)"/>
      <xsl:variable name="items-to-drop" as="element()*" select="
            $items-to-push[not(tan:to)][if (tan:rgx) then
               not(matches($this-string-val, tan:rgx))
            else
               not(contains($this-string-val, tan:val))]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="items-to-push" tunnel="yes" select="$items-to-push except $items-to-drop"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[tan:hold]" mode="tan:mark-dependencies-pass-2">
      <xsl:param name="items-to-push" tunnel="yes" as="element()*"/>
      <!-- <hold> preserves token references, i.e., parents of <pos> + <val>/<rgx> and perhaps <chars>; these are to
         be pushed down to the <tok> or <char> level -->
      <!-- Make sure to check only those <tok>s that are leaf elements, so as not to catch <tok>s that are preserved in <hold> -->
      <xsl:variable name="these-leaf-toks" select="descendant::tan:tok[not(*)]"/>
      <xsl:variable name="global-items-held" as="element()*"
         select="tan:hold/*[tan:pos = '1'][tan:pos = 'last']"/>
      <xsl:variable name="specific-items-held" as="element()*"
         select="tan:hold/* except $global-items-held"/>

      <xsl:variable name="token-refs-prepped-for-push" as="element()*">
         
         <xsl:apply-templates select="$global-items-held" mode="tan:convert-tok-to-push">
            <xsl:with-param name="push-is-global" select="true()"/>
         </xsl:apply-templates>

         <xsl:for-each select="$specific-items-held[tan:val or tan:rgx]">
            <xsl:variable name="this-pos-parent" select="."/>
            <xsl:variable name="this-val" select="tan:val"/>
            <xsl:variable name="this-rgx" select="tan:rgx"/>
            <xsl:variable name="toks-of-interest" select="
                  $these-leaf-toks[if (exists($this-val)) then
                     (text() = $this-val)
                  else
                     matches(text()[1], '^' || $this-rgx || '$')]"/>
            <xsl:variable name="these-chars" select="tan:chars"/>
            <xsl:variable name="toks-of-interest-count" select="count($toks-of-interest)"
               as="xs:integer"/>

            <xsl:for-each select="tan:pos[not(@to)]">
               <xsl:variable name="this-corresponding-to" select="
                     if (exists(@from)) then
                        following-sibling::tan:pos[@to][1]
                     else
                        ()"/>
               <!--<xsl:variable name="get-everything"
                  select=". eq '1' and $this-corresponding-to eq 'last'"/>-->
               <xsl:variable name="these-poses" select="tan:expand-pos-or-chars((., $this-corresponding-to), $toks-of-interest-count)"/>
               <xsl:variable name="this-target-tok" select="$toks-of-interest[position() = $these-poses]"/>
               <xsl:apply-templates select="$this-target-tok" mode="tan:convert-tok-to-push">
                  <xsl:with-param name="insertions" select="., $these-chars"/>
                  <xsl:with-param name="push-is-global" select="false()"/>
               </xsl:apply-templates>
               <xsl:if test="exists($this-corresponding-to)">
                  <xsl:apply-templates select="$this-target-tok[last()]"
                     mode="tan:convert-tok-to-push">
                     <xsl:with-param name="insertions" select="$this-corresponding-to"/>
                     <xsl:with-param name="push-is-global" select="false()"/>
                  </xsl:apply-templates>
               </xsl:if>
               <!--<xsl:if test="exists($this-target-tok)">
                     <push>
                        <xsl:for-each select="$this-target-tok/@q">
                           <to>
                              <xsl:value-of select="."/>
                           </to>
                        </xsl:for-each>
                        <xsl:copy-of select="."/>
                        <xsl:copy-of select="$these-chars"/>
                     </push>
                     <xsl:if test="exists($this-corresponding-to)">
                        <push>
                           <to>
                              <xsl:value-of select="($this-target-tok/@q)[last()]"/>
                           </to>
                           <xsl:copy-of select="$this-corresponding-to"/>
                        </push>
                     </xsl:if>
                  </xsl:if>-->
               <xsl:copy-of
                  select="tan:sequence-error($these-poses, ('Only ' || string($toks-of-interest-count) || ' tokens match ' || $this-val || $this-rgx))"
               />
            </xsl:for-each>
         </xsl:for-each>

      </xsl:variable>
      
      <xsl:variable name="this-q" as="attribute()" select="@q"/>
      <xsl:variable name="this-string-val" as="xs:string" select="string(.)"/>
      <xsl:variable name="items-to-drop" as="element()*" select="
            $items-to-push[not(tan:to)][if (tan:rgx) then
               not(matches($this-string-val, tan:rgx))
            else
               not(contains($this-string-val, tan:val))]"/>
      <!--<xsl:variable name="items-to-keep-pushing" as="element()*" select="$items-to-push[tan:q[. eq $this-q]]"/>-->
      
      
      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="path(.)"/>
         <xsl:message select="'global items ' || string(count($global-items-held))"/>
         <xsl:message select="'specific items ' || string(count($specific-items-held))"/>
         <xsl:message select="'token refs prepped for push: ', $token-refs-prepped-for-push"/>
         <xsl:message select="'items to drop ' || string(count($items-to-drop))"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$token-refs-prepped-for-push/self::tan:error"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="items-to-push" tunnel="yes" select="($items-to-push except $items-to-drop), $token-refs-prepped-for-push/self::tan:push"/>
            <!--<xsl:with-param name="items-to-push" tunnel="yes" select="$items-to-keep-pushing, $token-refs-processed/self::tan:push"/>-->
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:convert-tok-to-push" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:tok" mode="tan:convert-tok-to-push">
      <xsl:param name="insertions" as="element()*"/>
      <xsl:param name="push-is-global" as="xs:boolean" select="true()"/>
      <push>
         <!--<xsl:for-each select="ancestor::tan:div/@q">
            <q><xsl:value-of select="."/></q>
         </xsl:for-each>-->
         <xsl:choose>
            <xsl:when test="$push-is-global">
               <!-- No sense in copying the last <pos> -->
               <xsl:copy-of select="* except tan:pos[position() gt 1]"/>
            </xsl:when>
            <xsl:otherwise>
               <to><xsl:value-of select="@q"/></to>
            </xsl:otherwise>
         </xsl:choose>
         <!--<xsl:copy-of select="*"/>-->
         <xsl:copy-of select="$insertions"/>
      </push>
   </xsl:template>
   
   
   <!-- In this pass we can drop <hold>s -->
   <xsl:template match="tan:hold" mode="tan:mark-dependencies-pass-2"/>
   
   <xsl:template match="tan:tok" mode="tan:mark-dependencies-pass-2">
      <xsl:param name="items-to-push" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="this-val" select="text()" as="xs:string"/>
      <xsl:variable name="items-of-interest" select="$items-to-push[(tan:to eq $this-q) or 
         (tan:val eq $this-val) or matches($this-val, '^' || tan:rgx || '$')]"/>
      <xsl:variable name="chars-to-parse" select="$items-of-interest/tan:chars"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="exists($chars-to-parse)">
               <xsl:variable name="these-letters" select="tan:chop-string(.)"/>
               <xsl:variable name="letter-count" select="count($these-letters)"/>
               <xsl:variable name="chars-grouped" as="element()*">
                  <xsl:for-each-group select="$chars-to-parse"
                     group-by="tan:expand-pos-or-chars(., $letter-count)">
                     <xsl:sort select="current-grouping-key()"/>
                     <xsl:variable name="this-cgk" select="current-grouping-key()"/>
                     <group n="{$this-cgk}">
                        <xsl:choose>
                           <xsl:when test="current-grouping-key() le 0">
                              <xsl:for-each select="current-group()">
                                 <xsl:copy>
                                    <xsl:copy-of select="@*"/>
                                    <xsl:copy-of select="node()"/>
                                    <xsl:copy-of select="tan:sequence-error($this-cgk)"/>
                                 </xsl:copy>
                              </xsl:for-each>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of select="current-group()"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </group>
                  </xsl:for-each-group>
               </xsl:variable>
               <xsl:copy-of select="$chars-grouped/tan:chars[tan:error]"/>
               <xsl:for-each select="$these-letters">
                  <xsl:variable name="this-letter-pos" select="position()"/>
                  <c>
                     <xsl:value-of select="."/>
                     <!-- copy char anchors inside the tok -->
                     <xsl:copy-of select="$chars-grouped[@n = string($this-letter-pos)]/*"/>
                  </c>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
         <!-- copy token anchors inside the tok -->
         <xsl:copy-of select="$items-of-interest/tan:pos"/>
      </xsl:copy>
   </xsl:template>
   

   <xsl:mode name="tan:mark-tok-pos" on-no-match="shallow-copy"/>

   <xsl:template match="tan:pos" mode="tan:mark-tok-pos">
      <xsl:param name="src-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="refs" tunnel="yes" as="element()+"/>
      <xsl:param name="tok-elements" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-parent" select=".."/>
      <xsl:variable name="these-possible-toks"
         select="
            $tok-elements[text()[if (exists($this-parent/tan:rgx)) then
               tan:matches(., $this-parent/tan:rgx)
            else
               . = $this-parent/tan:val]]"/>
      <xsl:variable name="this-pos" select="tan:expand-pos-or-chars(., count($these-possible-toks))"/>
      <xsl:variable name="this-tok" select="$these-possible-toks[$this-pos]"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for: ', ."/>
         <xsl:message select="'possible toks: ', $these-possible-toks"/>
         <xsl:message select="'this pos: ', $this-pos"/>
         <xsl:message select="'chosen tok: ', $this-tok"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="exists($this-tok)">
               <xsl:copy-of select="$this-tok"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="poss-tok-count" select="count($these-possible-toks)"/>
               <xsl:variable name="this-message-parts" as="xs:string+">
                  <xsl:text>Source</xsl:text>
                  <xsl:value-of select="$src-id"/>
                  <xsl:text>at</xsl:text>
                  <xsl:value-of select="$refs/text()"/>
                  <xsl:text>has</xsl:text>
                  <xsl:value-of select="$poss-tok-count"/>

                  <xsl:choose>
                     <xsl:when test="$poss-tok-count = 1">
                        <xsl:text>token matching</xsl:text>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:text>tokens matching</xsl:text>
                     </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                     <xsl:when test="exists($this-parent/tan:rgx)">
                        <xsl:text>regular expression</xsl:text>
                        <xsl:value-of select="$this-parent/tan:rgx"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:text>value</xsl:text>
                        <xsl:value-of select="$this-parent/tan:val"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <xsl:copy-of select="tan:error('tok01', string-join($this-message-parts, ' '))"/>
               <xsl:if test="exists($these-possible-toks)">
                  <xsl:if test="$this-pos gt count($these-possible-toks)">
                     <xsl:copy-of select="tan:error('seq02')"/>
                  </xsl:if>
                  <xsl:if test="$this-pos lt count($these-possible-toks)">
                     <xsl:copy-of select="tan:error('seq01')"/>
                  </xsl:if>
               </xsl:if>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>


   <xsl:mode name="tan:mark-tok-chars" on-no-match="shallow-copy"/>

   <xsl:template match="tan:chars" mode="tan:mark-tok-chars">
      <xsl:param name="c-elements" tunnel="yes" as="element()+"/>
      <xsl:variable name="this-chars" select="tan:expand-pos-or-chars(., count($c-elements))"/>
      <xsl:variable name="this-c" select="$c-elements[$this-chars]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$this-c"/>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>


   <!-- Stripping dependencies to just the markers allows faster assessment of class-2 pointers -->
   <xsl:template match="tan:head | text()" mode="tan:strip-dependencies-to-markers"/>
   <xsl:template match="/*" mode="tan:strip-dependencies-to-markers">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*" mode="tan:strip-dependencies-to-markers">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template
      match="tan:skip | tan:rename | tan:equate | tan:reassign | tan:passage | tan:ref | tan:pos | tan:chars | tan:tok[@val]"
      mode="tan:strip-dependencies-to-markers">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <points-to>
            <xsl:attribute name="element" select="name(parent::*)"/>
            <xsl:copy-of select="../@*"/>
         </points-to>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   



      
</xsl:stylesheet>
