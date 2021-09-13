<xsl:stylesheet exclude-result-prefixes="#all" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="3.0">
   <!-- TAN Function Library, verbose expansion. -->
   
   
   <!-- Class 1 files -->
   
      <!-- Pass 1: fetch <redivision> normalized text and imprint a <diff> against the current base text; fetch <model> div structure -->
   <xsl:template match="tan:head" mode="tan:class-1-expansion-verbose-pass-1">
      <xsl:variable name="base-text" select="string-join(../tan:body//tan:div[not(tan:div)]/text(), '')"/>
      <!-- TODO: investigate an SQF to replace children of the root element with a master location's corresponding one -->
      <!--<xsl:variable name="errant-master-locations" as="element()*" select="tan:master-location[tan:*[@xml:id eq 'tan18']]"/>-->
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="base-text" select="$base-text"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:redivision" mode="tan:class-1-expansion-verbose-pass-1">
      <xsl:param name="base-text" as="xs:string?"/>
      <xsl:variable name="this-redivision-number" select="count(preceding-sibling::tan:redivision) + 1"/>
      <xsl:variable name="this-redivision-resolved" as="document-node()?">
         <xsl:choose>
            <xsl:when test="root()/*/@id = $tan:doc-id">
               <xsl:sequence select="$tan:redivisions-resolved[$this-redivision-number]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-1st-da" select="tan:get-1st-doc(.)"/>
               <xsl:copy-of select="tan:resolve-doc($this-1st-da)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="that-rediv-text" select="tan:text-join($this-redivision-resolved)"/>
      <xsl:variable name="this-diff" select="tan:diff($base-text, $that-rediv-text, true())"/>
      <xsl:variable name="this-diff-analyzed" select="tan:stamp-diff-with-text-data($this-diff)"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode: class-1-expansion-verbose-pass-1'"/>
         <xsl:message select="'this redivision doc resolved: ', $this-redivision-resolved"/>
         <xsl:message select="'differences between base text and redivision text: ', $this-diff"/>
         <xsl:message select="'differences analyzed: ', $this-diff-analyzed"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:if test="exists($this-diff-analyzed/(tan:a | tan:b))">
            <xsl:copy-of select="tan:error('cl104')"/>
         </xsl:if>
         <!-- The <diff> output is placed here, but not evaluated against individual <div>s until
         pass 3. -->
         <xsl:copy-of select="$this-diff-analyzed"/>
      </xsl:copy>
      
   </xsl:template>
   
   <xsl:template match="tan:model" mode="tan:class-1-expansion-verbose-pass-1">
      <xsl:variable name="this-model-resolved" as="document-node()?">
         <xsl:choose>
            <xsl:when test="root()/*/@id = $tan:doc-id">
               <xsl:sequence select="$tan:model-resolved"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-1st-da" select="tan:get-1st-doc(.)"/>
               <xsl:copy-of select="tan:resolve-doc($this-1st-da)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="this-model-expanded" select="tan:expand-doc($this-model-resolved, 'terse', false())"/>
      <xsl:variable name="this-base-and-model-merged" select="tan:merge-expanded-docs((root(.), $this-model-expanded))"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:copy-of select="tan:copy-of-except($this-base-and-model-merged/tan:TAN-T_merge/tan:body, ('error', 'warning'), 'q', ())"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:body" mode="tan:class-1-expansion-verbose-pass-1">
      <!-- Anticipate the next pass, which will check redivisions against the current text, by analyzing the leaf div string length -->
      <xsl:variable name="redivisions-exist" select="exists(../tan:head/tan:redivision)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="$redivisions-exist">
               <xsl:copy-of select="tan:stamp-class-1-tree-with-text-data(*, true())"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   
   <!-- Verbose pass 2: evaluate the model -->
   
   <xsl:template match="tan:model" mode="tan:class-1-expansion-verbose-pass-2">
      <xsl:variable name="all-divs" select="tan:body//tan:div[tan:div]"/>
      <xsl:variable name="defective-divs" select="$all-divs[count(tan:src) eq 1]"/>
      <xsl:variable name="these-defective-divs" select="$defective-divs[tan:src = '1']"/>
      <xsl:variable name="those-defective-divs" select="$defective-divs[tan:src = '2']"/>
      <xsl:variable name="this-message" as="xs:string*">
         <xsl:text>This file and its model diverge: </xsl:text>
         <xsl:value-of
            select="
               if (exists($these-defective-divs)) then
                  concat('uniquely here: ', string-join($these-defective-divs/tan:ref/text(), '; '), ' ')
               else
                  ()"/>
         <xsl:value-of
            select="
               if (exists($those-defective-divs)) then
                  concat('unique to model: ', string-join($those-defective-divs/tan:ref/text(), '; '), ' ')
               else
                  ()"
         />
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode: class-1-expansion-verbose-pass-2'"/>
         <xsl:message select="'defective divs: ', $defective-divs"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($defective-divs)">
            <xsl:copy-of select="tan:error('cl107', string-join($this-message))"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:model/tan:body" mode="tan:class-1-expansion-verbose-pass-2">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:TAN-T/tan:body | tei:TEI/tan:body" mode="tan:class-1-expansion-verbose-pass-2">
      <xsl:variable name="self-and-model-merged" select="../tan:head/tan:model[1]/tan:body"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="self-and-model-merged" tunnel="yes"
               select="$self-and-model-merged"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div" mode="tan:class-1-expansion-verbose-pass-2">
      <xsl:param name="self-and-model-merged" tunnel="yes" as="element()?"/>
      <xsl:variable name="is-leaf-div" select="not(exists(tan:div))"/>
      <xsl:variable name="matching-merged-div"
         select="
            if (exists($self-and-model-merged)) then
               key('tan:div-via-ref', tan:ref/text(), $self-and-model-merged)
            else
               ()"
      />
      <xsl:variable name="this-id" select="root()/*/@id"/>
      <xsl:variable name="this-is-defective" as="xs:boolean"
         select="exists($self-and-model-merged) and (count($matching-merged-div/tan:src) lt 2)"/>
      <xsl:variable name="model-children-missing-here" as="element()*"
         select="$matching-merged-div/tan:div[not(@type = '#version')][not(tan:src = $this-id)]"/>
      <xsl:variable name="n-needs-help" select="exists(tan:n/@help)"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode: class-1-expansion-verbose-pass-2'"/>
         <xsl:message select="'checking: ', tan:shallow-copy(.)"/>
         <xsl:message select="'exists self and model merged? ', exists($self-and-model-merged)"/>
         <xsl:message select="'matching merged div: ', $matching-merged-div"/>
         <xsl:message select="'model children missing here: ', $model-children-missing-here"/>
         <xsl:message select="'this is defective?', $this-is-defective"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$this-is-defective">
            <xsl:copy-of select="tan:error('cl107', 'no div with this ref appears in the model')"/>
         </xsl:if>
         <xsl:if test="exists($model-children-missing-here)">
            <xsl:copy-of
               select="tan:error('cl107', concat('children in model missing here: ', string-join($model-children-missing-here//tan:ref/text(), ', ')))"
            />
         </xsl:if>
         <xsl:if test="$n-needs-help or $this-is-defective">
            <xsl:variable name="unmatched-model-leaf-siblings-in-model"
               select="$matching-merged-div/(preceding-sibling::tan:div, following-sibling::tan:div)[@type = '#version'][tan:src = '2']"/>
            <xsl:variable name="unmatched-model-non-leaf-siblings-in-model"
               select="$matching-merged-div/(preceding-sibling::tan:div, following-sibling::tan:div)[not(@type = '#version')][not(tan:src = '1')]"/>
            
            <xsl:variable name="this-message">
               <xsl:choose>
                  <xsl:when test="exists($unmatched-model-leaf-siblings-in-model)">
                     <xsl:value-of select="'The parent of this element in the model is a leaf div.'"/>
                  </xsl:when>
                  <xsl:when test="exists($unmatched-model-non-leaf-siblings-in-model)">
                     <xsl:value-of
                        select="concat('The model has siblings not yet used here, @n = ', string-join($unmatched-model-non-leaf-siblings-in-model/tan:ref/tan:n[last()], ', '))"
                     />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:text>No siblings in the model suggest themselves as alternatives</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:variable name="this-fix" as="element()*">
               <xsl:for-each select="$unmatched-model-non-leaf-siblings-in-model/tan:ref">
                  <element n="{tan:n[last()]}"/>
               </xsl:for-each>
            </xsl:variable>
            
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'unused siblings in the model: ', $unmatched-model-non-leaf-siblings-in-model"/>
            </xsl:if>
            <xsl:copy-of select="tan:help($this-message, $this-fix, 'copy-attributes')"/>
         </xsl:if>
         <!-- Check to see if the values of @n or @ref are present -->
         <xsl:if test="$is-leaf-div">
            <xsl:variable name="this-text" as="xs:string" select="text()"/>
            <!-- The following is an arbitrary value that may be converted to a parameter one day -->
            <xsl:variable name="go-up-to" as="xs:integer" select="20"/>
            <xsl:variable name="opening-text" as="xs:string" select="substring($this-text, 1, $go-up-to)"/>
            <xsl:variable name="opening-text-analyzed" as="element()*"
               select="tan:analyze-numbers-in-string($opening-text, true(), (), ())"/>
            <xsl:variable name="opening-text-as-numerals" as="xs:string?"
               select="tan:string-to-numerals($opening-text, true(), true(), (), ())"/>
            <xsl:variable name="opening-text-replacement" as="xs:string"
               select="string-join($opening-text-analyzed/text(), '')"/>
            <xsl:variable name="is-tei" as="xs:boolean" select="exists(tei:*)"/>

            <xsl:if test="$diagnostics-on">
               <xsl:message select="'opening text: ', $opening-text"/>
               <xsl:message select="'opening text analyzed: ', $opening-text-analyzed"/>
               <xsl:message select="'opening text as numerals: ', $opening-text-as-numerals"/>
               <xsl:message select="'opening text replacement: ', $opening-text-replacement"/>
               <xsl:message select="'first ota tok:', ($opening-text-analyzed/self::tan:tok)[1]"/>
            </xsl:if>
            
            <xsl:if test="($opening-text-analyzed/self::tan:tok)[1] = tan:n">
               <xsl:choose>
                  <xsl:when test="$is-tei">
                     <xsl:copy-of select="tan:error('cl115', 'opening seems to duplicate @n ')"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="tan:error('cl115', 'opening seems to duplicate @n ', $opening-text-replacement || substring($this-text, $go-up-to + 1), 'replace-text')"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:if>
            <xsl:for-each select="tan:ref[tan:n]">
               <xsl:variable name="n-qty" select="count(tan:n)"/>
               <xsl:variable name="this-ref" select="text()"/>
               <xsl:if
                  test="
                     ($n-qty gt 1) and
                     (every $i in (1 to $n-qty)
                        satisfies tan:n[$i] = ($opening-text-analyzed[@number])[$i])">
                  <xsl:choose>
                     <xsl:when test="$is-tei">
                        <xsl:copy-of
                           select="tan:error('cl116', concat('opening seems to duplicate the reference for this &lt;div>: ', $this-ref))"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of
                           select="tan:error('cl116', concat('opening seems to duplicate the reference for this &lt;div>: ', $this-ref), concat($opening-text-replacement, substring($this-text, $go-up-to + 1)), 'replace-text')"
                        />
                     </xsl:otherwise>
                  </xsl:choose>
                  
               </xsl:if>
            </xsl:for-each>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   <!-- Pass 3: register redivision errors in each leaf div; register errors in <redivision> -->
   
   <xsl:template match="tan:model/tan:body" mode="tan:class-1-expansion-verbose-pass-3">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:TAN-T/tan:body | tei:TEI/tan:body" mode="tan:class-1-expansion-verbose-pass-3">

      <xsl:variable name="redivision-diffs-to-process" select="../tan:head/tan:redivision/tan:diff"
      as="element()*"/>
      <xsl:variable name="rediv-diff-chop-points" as="xs:integer+" select="
            for $i in
            descendant::tan:div/@_pos
            return
               xs:integer($i)"/>
      <xsl:variable name="rediv-diff-maps" as="map(*)*" select="for $i in $redivision-diffs-to-process
         return tan:chop-diff-output($i, $rediv-diff-chop-points, true(), $tan:char-regex)"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="rediv-diff-maps" tunnel="yes" select="$rediv-diff-maps"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div[not(tan:div)][@_pos]" mode="tan:class-1-expansion-verbose-pass-3">
      <xsl:param name="rediv-diff-maps" tunnel="yes" as="map(*)*"/>
      
      <xsl:variable name="this-string-pos" select="xs:integer(@_pos)" as="xs:integer"/>
      <xsl:variable name="these-diff-entries" as="element()*" select="
            for $i in $rediv-diff-maps
            return
               $i($this-string-pos)"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each select="$these-diff-entries">
            <xsl:variable name="rediv-number" as="xs:integer" select="position()"/>
            <xsl:variable name="this-replacement-text" select="string-join(* except tan:a)" as="xs:string?"/>
            <xsl:variable name="this-diff-stripped" as="element()*">
               <xsl:apply-templates mode="tan:strip-attributes"/>
            </xsl:variable>
            <xsl:variable name="this-diff-truncated" as="element()*">
               <xsl:apply-templates select="$this-diff-stripped" mode="tan:ellipses"/>
            </xsl:variable>
            <xsl:if test="exists(tan:a) or exists(tan:b)">
               <xsl:copy-of
                  select="tan:error('cl104', 'Differs with redivision #' || $rediv-number || ' (a = text here alone; b = text in redivision alone; common = shared text): '
                  || tan:xml-to-string($this-diff-truncated), $this-replacement-text, 'replace-text')"
               />
               
            </xsl:if>
         </xsl:for-each>

         <xsl:apply-templates mode="#current"/>

      </xsl:copy>
   </xsl:template>


   <xsl:mode name="tan:dependency-expansion-verbose" on-no-match="shallow-copy"/>

   <xsl:template match="/tan:TAN-T | /tei:TEI" mode="tan:dependency-expansion-verbose">
      <xsl:param name="class-2-claims" tunnel="yes"/>
      <xsl:variable name="this-src" select="(@src, tan:head/@src)"/>
      <xsl:variable name="this-work" select="(@work)"/>
      <xsl:variable name="this-format" select="name(.)"/>
      <xsl:variable name="relevant-claims"
         select="
            $class-2-claims[if ($this-format = 'TAN-T_merge') then
               (../tan:work = $this-work)
            else
               ((tan:src, tan:tok-ref/tan:src) = $this-src)]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <expansion>verbose</expansion>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="class-2-claims" select="$relevant-claims" tunnel="yes"/>
            <xsl:with-param name="doc-format" select="$this-format" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div" mode="tan:dependency-expansion-verbose">
      <xsl:param name="class-2-claims" tunnel="yes"/>
      <xsl:variable name="this-ref" select="tan:ref/text()"/>
      <xsl:variable name="is-leaf-div" select="not(exists(tan:div))"/>
      <xsl:variable name="these-div-claims"
         select="$class-2-claims/self::tan:div-ref[tan:ref/text() = $this-ref]"/>
      <!-- If it's a leaf div, pass on exact ref matches; if it isn't a leaf div, pass on only references that go deeper -->
      <!-- In all cases, pass it on if there's no div ref -->
      <xsl:variable name="claims-to-pass-to-children"
         select="
            $class-2-claims[if (exists(tan:ref)) then
               tan:ref[if ($is-leaf-div) then
                  (text() = $this-ref)
               else
                  matches(text(), concat($this-ref, '\W'))]
            else
               true()]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="exists($claims-to-pass-to-children)">
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="class-2-claims" select="$claims-to-pass-to-children"
                     tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="node()"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:for-each select="$these-div-claims">
            <see-q>
               <xsl:value-of select="(ancestor-or-self::*/@q)[last()]"/>
            </see-q>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:tok | tan:non-tok" mode="tan:dependency-expansion-verbose">
      <xsl:param name="class-2-claims" tunnel="yes"/>
      <xsl:variable name="this-n" select="@n"/>
      <xsl:variable name="this-val" select="."/>
      <xsl:variable name="relevant-claims"
         select="
            $class-2-claims/self::tan:tok[if (exists(tan:tok-ref)) then
               (tan:tok-ref/tan:tok/@n = $this-n)
            else
               if (exists(tan:val)) then
                  tan:val = $this-val
               else
                  if (exists(tan:rgx)) then
                     (tan:matches($this-val, tan:rgx))
                  else
                     false()]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each select="$relevant-claims">
            <see-q>
               <xsl:value-of select="@q"/>
            </see-q>
         </xsl:for-each>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="text()" mode="tan:dependency-expansion-verbose">
      <xsl:param name="token-definition" as="element()?" tunnel="yes"/>
      <xsl:choose>
         <xsl:when test="exists(parent::tan:div[not(tan:div)])">
            <xsl:copy-of select="tan:tokenize-text(., $token-definition, true())/*"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   
   
   <!-- Class 2 -->
   
   <xsl:template match="tan:source" mode="tan:class-2-expansion-verbose">
      <xsl:variable name="this-first-da" select="tan:get-1st-doc(.)"/>
      <xsl:variable name="this-master-location" select="$this-first-da/*/tan:head/tan:master-location[1]"/>
      <xsl:variable name="this-first-da-master" select="tan:get-1st-doc($this-master-location)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if
            test="exists($this-master-location) and not(deep-equal($this-first-da/*, $this-first-da-master/*))">
            <xsl:copy-of
               select="tan:error('tan18', 'Source differs from the version found at the master location')"
            />
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   

   
</xsl:stylesheet>
