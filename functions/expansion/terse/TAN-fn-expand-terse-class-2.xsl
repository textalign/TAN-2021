<xsl:stylesheet exclude-result-prefixes="#all"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library, terse expansion, class 2 files. -->
   
   <!-- Class-2 -->
   
   <xsl:template match="tan:source | tan:morphology[not(@attr)]" mode="tan:core-expansion-terse">
      <xsl:variable name="is-first-link-element" select="not(exists(preceding-sibling::tan:source))"/>
      <xsl:if test="$is-first-link-element">
         <xsl:variable name="other-token-definitions" select="preceding-sibling::tan:token-definition"/>
         <xsl:variable name="src-ids-not-defined" select="../tan:source[not(@xml:id = $other-token-definitions/tan:src)]/@xml:id"/>
         <xsl:if test="exists($src-ids-not-defined)">
            <token-definition>
               <xsl:copy-of select="$tan:token-definition-default/@*"/>
               <xsl:for-each select="$src-ids-not-defined">
                  <src>
                     <xsl:value-of select="."/>
                  </src>
               </xsl:for-each>
            </token-definition>
         </xsl:if>
      </xsl:if>
      <!-- dependencies must be evaluated at the terse stage -->
      <xsl:apply-templates select="." mode="tan:check-referred-doc"/>
   </xsl:template>

   <xsl:template match="tan:rename" mode="tan:core-expansion-terse">
      <xsl:variable name="these-refs" select="tan:ref"/>
      <xsl:variable name="these-news" select="tan:new"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="@new = (tan:n, $these-refs)">
            <xsl:copy-of select="tan:error('cl203')"/>
         </xsl:if>
         <xsl:if
            test="exists($these-refs) and exists($these-news) and not(count($these-refs) = count($these-news/tan:ref))">
            <xsl:copy-of select="tan:error('cl216')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:rename/tan:by" mode="tan:core-expansion-terse">
      <xsl:variable name="these-ns" select="../tan:n, ../tan:ref/tan:n[last()]"/>
      <xsl:variable name="these-n-types" select="for $i in $these-ns return 
         tan:analyze-numbers-in-string($i, true(), (), ())"/>
      <xsl:if test="exists($these-n-types/@non-number)">
         <xsl:copy-of select="tan:error('cl213')"/>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="tan:tok[not(tan:from)] | tan:tok/tan:from | tan:tok/tan:to |
      tan:from-tok | tan:through-tok"
      mode="tan:core-expansion-terse">
      <xsl:param name="is-tan-a-lm" tunnel="yes"/>
      <xsl:param name="is-for-lang" tunnel="yes"/>
      <xsl:param name="use-validation-mode" tunnel="yes" as="xs:boolean?" select="$tan:validation-mode-on"/>
      <xsl:variable name="is-general-tok-claim" select="self::tan:tok[not(@ref)] and $is-tan-a-lm"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!-- The <tok> in a TAN-A-lm file needs to have a <src> added if it is source-specific, and a <result> added if it is not -->
         <xsl:if test="$is-tan-a-lm">
            <xsl:choose>
               <xsl:when test="$is-for-lang">
                  <result>
                     <xsl:value-of select="@val, @rgx"/>
                  </result>
               </xsl:when>
               <xsl:otherwise>
                  <src>1</src>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:if>
         <xsl:if test="not(exists(@pos))">
            <!-- <pos> becomes the prime way to identify any token @rgx/@val + @pos combo, so needs a @q -->
            <!-- For universal <tok>s found in TAN-A-lm files, i.e., those without @ref, the implication is 1-last -->
            <pos attr="" q="{generate-id()}" from="">1</pos>
            <xsl:if test="not($use-validation-mode)">
               <xsl:variable name="this-extra-pos" as="element()">
                  <pos/>
               </xsl:variable>
               <xsl:for-each select="$this-extra-pos">
                  <xsl:copy>
                     <xsl:attribute name="attr"/>
                     <xsl:attribute name="to"/>
                     <xsl:attribute name="q" select="generate-id()"/>
                     <xsl:text>last</xsl:text>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:if>
         </xsl:if>
         <xsl:if test="not(exists(@val)) and not(exists(@rgx))">
            <rgx attr="">.+</rgx>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template
      match="
         tan:adjustments/tan:skip/tan:div-type |
         tan:adjustments/tan:*/tan:ref | tan:adjustments/tan:*/tan:n | tan:passage/tan:ref[not(@q)]"
      mode="tan:core-expansion-terse">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="q" select="generate-id(.)"/>
         <xsl:if test="parent::tan:to">
            <!-- We prime the reset-hierarchy operation for reassign/to/ref -->
            <xsl:attribute name="reset"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:ref[@q][@from]" priority="1" mode="tan:core-expansion-terse">
      <xsl:param name="use-validation-mode" select="$tan:validation-mode-on" tunnel="yes"/>
      <xsl:variable name="companion-to" select="following-sibling::tan:ref[1][@to]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not($use-validation-mode) and exists($companion-to)">
            <xsl:attribute name="alter-q" select="$companion-to/@q"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:ref[@q][@to]" priority="1" mode="tan:core-expansion-terse">
      <xsl:param name="use-validation-mode" select="$tan:validation-mode-on" tunnel="yes"/>
      <xsl:variable name="companion-to" select="preceding-sibling::tan:ref[1][@from]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not($use-validation-mode) and exists($companion-to)">
            <xsl:attribute name="alter-q" select="$companion-to/@q"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:skip/tan:div-type | tan:skip/tan:n | tan:rename/tan:n | tan:passage
      | tan:from-tok | tan:through-tok | tan:rename | tan:reassign"
      mode="tan:class-2-expansion-terse tan:class-2-expansion-terse-for-validation">
      <xsl:param name="dependencies-adjusted-and-marked" as="document-node()*" tunnel="yes"/>
      <!-- This is the generic, default template to flag class 2 elements that must be marked in the source class 1 files -->
      <xsl:variable name="these-src-id-nodes" select="ancestor-or-self::*[tan:src][1]"/>
      <xsl:variable name="these-src-ids" select="$these-src-id-nodes/tan:src/text()"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="these-errors" as="element()*">
         <xsl:for-each select="$dependencies-adjusted-and-marked[*/@src = $these-src-ids]">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="these-markers" select="key('tan:q-ref', $this-q, .)"/>
            <xsl:choose>
               <xsl:when test="exists($these-markers)"/>
               <xsl:when test="$this-name = 'div-type'">
                  <xsl:copy-of select="tan:error('dty01')"/>
               </xsl:when>
               <xsl:when test="$this-name = 'n'">
                  <xsl:copy-of select="tan:error('cl215')"/>
               </xsl:when>
               <!-- we don't bother to signal a missing <passage>, which gets flagged at the from/through-tok level -->
            </xsl:choose>
            <xsl:copy-of select="$these-markers/(tan:error, tan:warning)"/>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:if test="exists(@attr)">
         <xsl:copy-of select="$these-errors"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(exists(@attr))">
            <xsl:copy-of select="$these-errors"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:equate" mode="tan:class-2-expansion-terse tan:class-2-expansion-terse-for-validation">
      <!-- equate locators should be more forgiving than other adjustment locators: you do not want every value of @n to match each source, only one combination -->
      <xsl:param name="dependencies-adjusted-and-marked" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="these-src-id-nodes" select="ancestor-or-self::*[tan:src][1]"/>
      <xsl:variable name="these-src-ids" select="$these-src-id-nodes/tan:src/text()"/>
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="these-ns" select="tan:n"/>
      <xsl:variable name="duplicate-ns" select="tan:duplicate-items($these-ns)"/>
      <xsl:variable name="these-equate-markers" as="element()*">
         <xsl:for-each select="$dependencies-adjusted-and-marked[*/@src = $these-src-ids]">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="these-markers" select="key('tan:q-ref', $this-q, .)"/>
            <xsl:sequence select="$these-markers"/>
            <xsl:if test="not(exists($these-markers))">
               <missing>
                  <xsl:value-of select="$this-src-id"/>
               </missing>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode: class-2-expansion-terse'"/>
         <xsl:message select="'this equate: ', ."/>
         <xsl:message select="'src ids: ', $these-src-ids"/>
         <xsl:message select="'equate markers: ', $these-equate-markers"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($these-equate-markers/self::tan:missing)">
               <xsl:copy-of select="tan:error('cl207', (string-join($these-equate-markers/self::tan:missing, ', ') || ' lack(s) any div whose @n = ' || string-join($these-ns, ', ')))"/>
         </xsl:if>
         <xsl:if test="exists($duplicate-ns)">
            <xsl:copy-of select="tan:error('cl205', ('Duplicates: ' || string-join(distinct-values($duplicate-ns), ', ')))"/>
         </xsl:if>
         <xsl:copy-of select="$these-equate-markers/(descendant-or-self::tan:error, descendant-or-self::tan:warning)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:to/tan:ref | tan:new/tan:ref" mode="tan:class-2-expansion-terse tan:class-2-expansion-terse-for-validation">
      <!-- these refs do not assume the ref exists in the target sources -->
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:ref"
      mode="tan:class-2-expansion-terse tan:class-2-expansion-terse-for-validation">
      <xsl:param name="dependencies-adjusted-and-marked" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="this-work-node-parent" select="ancestor-or-self::*[tan:work][1]"/>
      <xsl:variable name="this-src-node-parent" select="ancestor-or-self::*[tan:src][1]"/>
      <xsl:variable name="these-work-ids" select="$this-work-node-parent/tan:work/text()"/>
      <xsl:variable name="these-src-ids" select="$this-src-node-parent/tan:src/text()"/>
      <xsl:variable name="is-from" select="exists(@from)"/>
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="this-ref" select="text()"/>
      <xsl:variable name="this-is-in-adjustment-action" select="exists(ancestor::tan:head)"/>
      <xsl:variable name="supplemental-messages" as="xs:string*">
         <xsl:if test="parent::tan:passage and exists(ancestor::tan:head//tan:rename)">perhaps the passage has been renamed</xsl:if>
      </xsl:variable>
      <xsl:variable name="ref-markers" as="element()*">
         <xsl:for-each
            select="$dependencies-adjusted-and-marked[*/(@work, @src) = ($these-work-ids, $these-src-ids)]">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="these-ref-markers" select="key('tan:q-ref', $this-q, .)"/>
            <xsl:variable name="this-message" as="xs:string"
               select="string-join((($this-src-id || ' lacks @ref ' || $this-ref), $supplemental-messages), ';')"/>
            <xsl:choose>
               <xsl:when test="exists($these-ref-markers)">
                  <xsl:sequence select="$these-ref-markers"/>
               </xsl:when>
               <xsl:when test="exists($these-work-ids)">
                  <xsl:copy-of select="tan:error('ref02', $this-message)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="tan:error('ref01', $this-message)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for ', ."/>
         <xsl:message select="'work node parent: ', $this-work-node-parent"/>
         <xsl:message select="'src node parent: ', $this-src-node-parent"/>
         <xsl:message select="'work id: ', $these-work-ids"/>
         <xsl:message select="'source ids: ', $these-src-ids"/>
         <xsl:message select="'found ', count($ref-markers), 'ref markers: ', $ref-markers"/>
      </xsl:if>

      <xsl:if test="$is-from and not($this-is-in-adjustment-action)">
         <!-- We do not do adjustment actions, because any faults in the ranges will be picked up by expanding them early on,
         and a sequence error will result in a nonsense range. -->
         <xsl:variable name="matching-to" select="following-sibling::tan:ref[@to][1]"/>
         <xsl:if test="$diagnostics-on">
            <xsl:message select="'matching to: ', $matching-to"/>
         </xsl:if>

         <xsl:for-each
            select="$dependencies-adjusted-and-marked[*/(@work, @src) = ($these-work-ids, $these-src-ids)]">
            <xsl:variable name="these-ref-markers" select="key('tan:q-ref', $this-q, .)"/>
            <xsl:variable name="these-to-markers" select="key('tan:q-ref', $matching-to/@q, .)"/>
            <xsl:variable name="this-src-id" select="*/@src"/>
            
            <xsl:if test="$diagnostics-on">
               <xsl:message select="('Source ' || $this-src-id || ' from markers:'), $these-ref-markers"/>
               <xsl:message select="('Source ' || $this-src-id || ' to markers:'), $these-to-markers"/>
            </xsl:if>
            <xsl:if test="
                  exists($these-ref-markers) and exists($these-to-markers) and (some $i in $these-to-markers,
                     $j in $these-ref-markers
                     satisfies ($j >> $i))">
               <xsl:variable name="this-message"
                  select="'In src', $this-src-id, ' ', $this-ref, ' comes after ', $matching-to/text()"/>
               <xsl:copy-of select="tan:error('ref03', string-join($this-message, ' '))"/>
            </xsl:if>

         </xsl:for-each>
         
      </xsl:if>
      <xsl:copy-of
         select="$ref-markers/(descendant-or-self::tan:error, descendant-or-self::tan:warning)"/>
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:pos" mode="tan:class-2-expansion-terse tan:class-2-expansion-terse-for-validation">
      <!-- Tokens are identified by a combination of rgx/val plus pos. Because the latter is the only constant, we monitor identified 
         tokens through tan:pos, not tan:rgx or tan:val -->
      <xsl:param name="dependencies-adjusted-and-marked" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="these-src-id-nodes" select="ancestor-or-self::*[tan:src][1]"/>
      <xsl:variable name="these-src-ids" select="$these-src-id-nodes/tan:src"/>
      <xsl:variable name="this-ordinal"
         select="
            if (. castable as xs:integer) then
               tan:ordinal(.)
            else
               ."
         as="xs:string"/>
      <xsl:variable name="this-val-or-rgx" select="../tan:rgx, ../tan:val"/>
      <xsl:variable name="is-from" select="exists(@from)"/>
      <xsl:variable name="matching-to" select="following-sibling::tan:pos[@to][1]"/>
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="this-pos" select="."/>
      <xsl:variable name="pos-markers" as="element()*">
         <!-- look for markers for this pos that have been left in the source document -->
         <xsl:for-each select="$dependencies-adjusted-and-marked[*/@src = $these-src-ids]">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="these-pos-markers" select="key('tan:q-ref', $this-q, .)"/>
            <xsl:choose>
               <xsl:when test="not(exists($these-pos-markers))">
                  <xsl:variable name="this-message" as="xs:string+"
                     select="'Target ref in source ', $this-src-id, ' lacks a ', $this-ordinal, ' token with ', name($this-val-or-rgx), ' ', $this-val-or-rgx/text()"
                  />
                  <xsl:copy-of select="tan:error('tok01', string-join($this-message, ''))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$these-pos-markers"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="erroneous-pos-markers" select="$pos-markers[descendant-or-self::tan:error or descendant-or-self::tan:warning]"/>
      <xsl:variable name="successful-pos-markers" select="$pos-markers except $erroneous-pos-markers"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for ', ."/>
         <xsl:message select="'is from?: ', $is-from"/>
         <xsl:message select="'matching to: ', $matching-to"/>
         <xsl:message select="count($pos-markers), ' found token markers: ', $pos-markers"/>
      </xsl:if>
      
      <xsl:copy-of select="$erroneous-pos-markers/(descendant-or-self::tan:error, descendant-or-self::tan:warning)"/>
      <xsl:copy-of select="$successful-pos-markers/tan:points-to"/>
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:chars" mode="tan:class-2-expansion-terse tan:class-2-expansion-terse-for-validation">
      <xsl:param name="dependencies-adjusted-and-marked" as="document-node()*" tunnel="yes"/>
      <xsl:variable name="these-src-id-nodes" select="ancestor-or-self::*[tan:src][1]"/>
      <xsl:variable name="these-src-ids" select="$these-src-id-nodes/tan:src"/>
      <xsl:variable name="this-ordinal"
         select="
            if (. castable as xs:integer) then
               tan:ordinal(.)
            else
               ."
         as="xs:string"/>
      <xsl:variable name="is-from" select="exists(@from)"/>
      <xsl:variable name="matching-to" select="following-sibling::tan:chars[@to][1]"/>
      <xsl:variable name="this-q" select="@q"/>
      <xsl:variable name="this-c" select="."/>
      <xsl:variable name="c-markers" as="element()*">
         <xsl:for-each select="$dependencies-adjusted-and-marked[*/@src = $these-src-ids]">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="these-c-markers" select="key('tan:q-ref', $this-q, .)"/>
            <xsl:choose>
               <xsl:when test="not(exists($these-c-markers))">
                  <xsl:variable name="this-message" as="xs:string+"
                     select="'Target token in source ', $this-src-id, ' lacks a ', $this-ordinal, ' character'"
                  />
                  <xsl:copy-of select="tan:error('chr01', string-join($this-message, ''))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$these-c-markers"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:copy-of select="$c-markers/(descendant-or-self::tan:error | descendant-or-self::tan:warning)"/>
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <!-- TAN-A -->
   
   
      <!-- TAN-A files have one idref that cannot be fully resolved in the traditional resolve phase, and that's taking care
      of @work. We rectify that by building <work> vocabulary and (1) copying it to the <vocabulary-key> and (2) passing
      it to every claim's <work> to copy all aliases.
   -->
   <xsl:template match="/" mode="tan:core-expansion-terse">
      <xsl:param name="dependencies" as="document-node()*" tunnel="yes"/>
      <xsl:param name="use-validation-mode" as="xs:boolean" tunnel="yes" select="$tan:validation-mode-on"/>
      <xsl:variable name="this-head" select="tan:TAN-A/tan:head"/>
      <xsl:variable name="token-definition-source-duplicates"
         select="tan:duplicate-items(tan:token-definition/tan:src)"/>
      <xsl:variable name="work-elements-pass-1" as="element()*">
         <xsl:for-each select="$dependencies/*/tan:head/tan:work">
            <xsl:variable name="this-src" select="root(.)/*/@src"/>
            <xsl:variable name="attr-which-vocabulary" select="tan:attribute-vocabulary(@which)"/>
            <xsl:variable name="this-vocabulary-item"
               select="
                  if (exists(tan:IRI)) then
                     .
                  else
                     $attr-which-vocabulary/tan:item"
            />
            <xsl:variable name="these-equate-works"
               select="$this-head/tan:vocabulary-key/tan:alias[tan:idref = $this-src]"/>
            <xsl:variable name="vocab-info-to-include"
               select="
                  $this-vocabulary-item/(tan:IRI, tan:name),
                  (if ($use-validation-mode) then
                     ()
                  else
                     $this-vocabulary-item/tan:desc)"
            />
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:for-each select="$vocab-info-to-include">
                  <xsl:copy>
                     <xsl:copy-of select="@norm, @xml:lang"/>
                     <xsl:value-of select="."/>
                  </xsl:copy>
               </xsl:for-each>
               <id>
                  <xsl:value-of select="$this-src"/>
               </id>
               <xsl:for-each select="$these-equate-works/tan:idref">
                  <id>
                     <xsl:value-of select="."/>
                  </id>
               </xsl:for-each>
               <xsl:copy-of select="$these-equate-works/tan:alias"/>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="work-elements-pass-2" as="element()*"
         select="tan:group-elements-by-shared-node-values($work-elements-pass-1, 'IRI|id')"/>
      <xsl:variable name="work-elements-pass-3" as="element()*">
         <xsl:apply-templates select="$work-elements-pass-2" mode="#current"/>
      </xsl:variable>
      <xsl:variable name="these-vocab-items" select="$this-head/tan:vocabulary/tan:item"/>
      <xsl:variable name="work-elements-to-integrate-with-existing-vocab-items"
         select="$work-elements-pass-3[tan:IRI = $these-vocab-items/tan:IRI]"/>
      <xsl:variable name="work-elements-to-add-as-new-vocab-items"
         select="$work-elements-pass-3 except $work-elements-to-integrate-with-existing-vocab-items"
      />
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode core-expansion-terse() for TAN-A document node'"/>
         <xsl:message select="'token definition source duplicates: ', $token-definition-source-duplicates"/>
         <xsl:message select="'work elements pass 1: ', $work-elements-pass-1"/>
         <xsl:message select="'work elements pass 2: ', $work-elements-pass-2"/>
         <xsl:message select="'work elements pass 3: ', $work-elements-pass-3"/>
         <xsl:message select="'work elements to integrate with existing vocab items: ', $work-elements-to-integrate-with-existing-vocab-items"/>
         <xsl:message select="'work elements to add as new vocab items: ', $work-elements-to-add-as-new-vocab-items"/>
      </xsl:if>
      
      <xsl:document>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="extra-vocabulary"
               select="$work-elements-to-add-as-new-vocab-items" tunnel="yes"/>
            <!-- vocab to integrate gets picked up in the check-referred-doc template just below -->
            <xsl:with-param name="vocabulary-to-integrate" tunnel="yes"
               select="$work-elements-to-integrate-with-existing-vocab-items"/>
            <xsl:with-param name="token-definition-errors"
               select="$token-definition-source-duplicates"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:template>
   
   <xsl:template match="tan:claim/tan:work | tan:object/tan:work | tan:subject/tan:work"
      mode="tan:core-expansion-terse">
      <!-- This template targets <work> elements in the body, not the head -->
      <!-- Such a step would ordinarily have been taken in the previous expansion pass,
      on attributes, but it didn't have the extra vocabulary. -->
      <xsl:param name="extra-vocabulary" tunnel="yes" as="element()*"/>
      <xsl:param name="vocabulary-to-integrate" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-work-id" select="text()"/>
      <xsl:variable name="this-vocab"
         select="($extra-vocabulary, $vocabulary-to-integrate)[self::tan:work][(tan:id | tan:name | tan:alias) = $this-work-id]"/>

      <xsl:copy-of select="."/>
      <xsl:for-each select="$this-vocab/tan:id[not(. = $this-work-id)]">
         <work attr="">
            <xsl:value-of select="."/>
         </work>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary/tan:item" priority="2" mode="tan:check-referred-doc">
      <!-- This template overrides the one in TAN-core-expand-functions.xsl -->
      <xsl:param name="vocabulary-to-integrate" tunnel="yes" as="element()*"/>
      <xsl:variable name="these-iris" select="tan:IRI"/>
      <xsl:variable name="this-vocabulary-to-integrate" select="$vocabulary-to-integrate[tan:IRI = $these-iris]"/>
      <xsl:variable name="these-nodes" select="node()"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="exists($this-vocabulary-to-integrate)">
               <xsl:copy-of select="tan:distinct-items((node(), $this-vocabulary-to-integrate/node()))"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="node()"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:group[tan:work]" mode="tan:core-expansion-terse">
      <work>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="tan:distinct-items(tan:work/*)"/>
      </work>
   </xsl:template>

   <xsl:template match="tan:TAN-A/tan:body" mode="tan:core-expansion-terse">
      <xsl:variable name="this-vocabulary"
         select="preceding-sibling::tan:head/(tan:vocabulary-key, tan:tan-vocabulary, tan:vocabulary)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="vocabulary" select="$this-vocabulary" tunnel="yes"/>
            <xsl:with-param name="inherited-subjects" select="tan:subject" tunnel="yes"/>
            <xsl:with-param name="inherited-verbs" select="tan:verb" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:claim" mode="tan:core-expansion-terse">
      <!-- subjects and verbs are the only two elements of a claim that are inheritable, since they are the only ones expected to be the basis for grouping claims -->
      <xsl:param name="inherited-subjects" tunnel="yes"/>
      <xsl:param name="inherited-verbs" tunnel="yes"/>
      <xsl:variable name="vocabulary-parents" select="root()/*/*"/>
      <xsl:variable name="immediate-subject-refs" select="tan:subject"/>
      <xsl:variable name="immediate-verb-refs" select="tan:verb/text()"/>

      <!-- subjects -->
      <xsl:variable name="these-subject-refs"
         select="
            if (exists($immediate-subject-refs)) then
               $immediate-subject-refs
            else
               $inherited-subjects"/>
      <xsl:variable name="these-entity-subject-refs" select="$these-subject-refs[@attr]/text(), $these-subject-refs/(@work, @src, @scriptum, @which)"/>
      <xsl:variable name="these-textual-passage-subject-refs"
         select="$these-subject-refs[@ref]"/>
      <xsl:variable name="this-entity-subject-vocab" select="
            for $i in $these-entity-subject-refs
            return
               tan:vocabulary($tan:names-of-elements-targeted-by-subjects, $i, $vocabulary-parents)"
      />
      <xsl:variable name="these-entity-subject-vocab-items"
         select="$this-entity-subject-vocab/(* except (tan:IRI, tan:name, tan:desc, tan:location, tan:comment))"/>
      <xsl:variable name="these-subject-textual-entities"
         select="$these-entity-subject-vocab-items[(name(.), tan:affects-element) = $tan:names-of-elements-that-describe-textual-entities]"/>
      <xsl:variable name="these-subject-nontextual-entities"
         select="$these-entity-subject-vocab-items except $these-subject-textual-entities"/>
      <xsl:variable name="these-subject-textual-artefact-entities"
         select="$these-subject-textual-entities[(name(.), tan:affects-element) = $tan:names-of-elements-that-describe-text-bearers]"/>
      <xsl:variable name="these-subject-nontextual-artefact-entities"
         select="$these-entity-subject-vocab-items except $these-subject-textual-artefact-entities"/>

      <!-- verbs -->
      <xsl:variable name="these-verb-refs"
         select="
            if (exists($immediate-verb-refs)) then
               $immediate-verb-refs
            else
               $inherited-verbs"/>
      <xsl:variable name="this-verb-vocab"
         select="
            for $i in $these-verb-refs
            return
               tan:vocabulary('verb', $i, $vocabulary-parents)"
      />
      <xsl:variable name="these-verb-vocab-items"
         select="$this-verb-vocab/(* except (tan:IRI, tan:name, tan:desc, tan:location, tan:comment))"/>
      <xsl:variable name="verbs-that-disallow-subjects" select="$these-verb-vocab-items[tan:constraints/tan:subject/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-subjects" select="$these-verb-vocab-items[tan:constraints/tan:subject/@status = 'required' or not(exists(tan:constraints/tan:subject))]"/>
      <xsl:variable name="verbs-that-disallow-objects" select="$these-verb-vocab-items[tan:constraints/tan:object/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-objects" select="$these-verb-vocab-items[tan:constraints/tan:object/@status = 'required' or not(exists(tan:constraints/tan:object))]"/>
      <xsl:variable name="verbs-expecting-subject-content-units" select="$these-verb-vocab-items[tan:constraints/tan:subject/@content-datatype = $tan:datatypes-that-require-unit-specification]"/>
      <xsl:variable name="verbs-expecting-object-content-units" select="$these-verb-vocab-items[tan:constraints/tan:object/@content-datatype = $tan:datatypes-that-require-unit-specification]"/>
      <xsl:variable name="verbs-that-disallow-at-ref" select="$these-verb-vocab-items[tan:constraints/tan:at-ref/@status = 'disallowed' or not(exists(tan:constraints/tan:at-ref))]"/>
      <xsl:variable name="verbs-that-require-at-ref" select="$these-verb-vocab-items[tan:constraints/tan:at-ref/@status = 'required']"/>
      <xsl:variable name="verbs-that-disallow-in-lang" select="$these-verb-vocab-items[tan:constraints/tan:in-lang/@status = 'disallowed' or not(exists(tan:constraints/tan:in-lang))]"/>
      <xsl:variable name="verbs-that-require-in-lang" select="$these-verb-vocab-items[tan:constraints/tan:in-lang/@status = 'required']"/>
      <xsl:variable name="verbs-that-disallow-period" select="$these-verb-vocab-items[tan:constraints/tan:period/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-period" select="$these-verb-vocab-items[tan:constraints/tan:period/@status = 'required']"/>
      <xsl:variable name="verbs-that-disallow-place" select="$these-verb-vocab-items[tan:constraints/tan:place/@status = 'disallowed']"/>
      <xsl:variable name="verbs-that-require-place" select="$these-verb-vocab-items[tan:constraints/tan:place/@status = 'required']"/>
      


      <xsl:variable name="these-verbs-with-general-constraints"
         select="$these-verb-vocab-items[tan:group]"/>
      <xsl:variable name="these-verbs-with-data-for-object"
         select="$these-verb-vocab-items[@object-datatype]"/>
      <xsl:variable name="these-verbs-whose-objects-require-unit-specification"
         select="$these-verb-vocab-items[@object-datatype = $tan:datatypes-that-require-unit-specification]"/>
      <xsl:variable name="verbal-groups" select="$these-verbs-with-general-constraints/tan:group"/>


      <!-- objects -->
      <xsl:variable name="these-object-refs" select="(tan:object, tan:claim)"/>
      <xsl:variable name="these-entity-object-refs" select="$these-object-refs[@attr]"/>
      <xsl:variable name="these-textual-passage-object-refs"
         select="$these-object-refs[tan:src or tan:work]"/>
      <xsl:variable name="this-entity-object-vocab" select="
            for $i in $these-entity-object-refs
            return
               tan:vocabulary($tan:names-of-elements-targeted-by-objects, $i, $vocabulary-parents)"
      />
      <xsl:variable name="these-entity-object-vocab-items"
         select="$this-entity-object-vocab/(* except (tan:IRI, tan:name, tan:desc, tan:location, tan:comment))"/>
      <xsl:variable name="these-object-textual-entities"
         select="$these-entity-object-vocab-items[(name(.), tan:affects-element) = $tan:names-of-elements-that-describe-textual-entities]"/>
      <xsl:variable name="these-object-nontextual-entities"
         select="$these-entity-object-vocab-items except $these-object-textual-entities"/>
      <xsl:variable name="these-object-textual-artefact-entities" 
         select="$these-object-textual-entities[(name(.), tan:affects-element) = $tan:names-of-elements-that-describe-text-bearers]"/>
      <xsl:variable name="these-object-nontextual-artefact-entities"
         select="$these-entity-object-vocab-items except $these-object-textual-artefact-entities"/>
      <xsl:variable name="these-data-object-refs"
         select="$these-object-refs except ($these-entity-object-refs, $these-textual-passage-object-refs)"/>


      <!-- at-refs -->
      <xsl:variable name="these-at-refs" select="tan:at-ref"/>
      
      <!-- special elements that must be explicitly allowed -->
      <!-- in-lang -->
      <xsl:variable name="these-in-langs" select="tan:in-lang"/>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode core-expansion-terse, for: ', ."/>
         <xsl:message select="'subjects inherited: ', $inherited-subjects"/>
         <xsl:message select="'subjects: entities: ', $these-entity-subject-vocab-items"/>
         <xsl:message select="'subjects: textual passages: ', $these-textual-passage-subject-refs"/>
         <xsl:message select="'verbs inherited: ', $inherited-verbs"/>
         <xsl:message select="'verb refs actual: ', $these-verb-refs"/>
         <xsl:message select="'verb vocab items: ', $these-verb-vocab-items"/>
         <xsl:message
            select="'verbs with object constraints: ', $these-verbs-whose-objects-require-unit-specification"/>
         <xsl:message select="'verbal groups: ', $verbal-groups"/>
         <xsl:message select="'objects: entities: ', $these-entity-object-vocab-items"/>
         <xsl:message select="'objects: textual passages: ', $these-textual-passage-object-refs"/>
         <xsl:message select="'objects: data: ', $these-data-object-refs"/>
      </xsl:if>
      
      <xsl:variable name="errors-that-should-be-ignored"
         as="element()*">
         <xsl:if test="exists($these-verbs-with-data-for-object)">
            <xsl:sequence select="tan:error[*/tan:id = $these-data-object-refs]"/>
         </xsl:if>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         
         <!-- subject problems -->
         <xsl:if test="exists($verbs-expecting-subject-content-units) and exists($these-subject-refs[not(@units)])">
            <xsl:copy-of select="tan:error('clm01')"/>
         </xsl:if>
         <xsl:if test="$these-verb-vocab-items[tan:constraints/tan:subject/@content-datatype] and (count($these-verb-vocab-items) gt 1)">
            <xsl:copy-of select="tan:error('clm02')"/>
         </xsl:if>
         <xsl:if test="not(exists($these-subject-refs)) and exists($verbs-that-require-subjects)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-subjects/tan:name[1], ', ') || ' requires a subject'))"/>
         </xsl:if>
         <xsl:if test="exists($these-subject-refs) and exists($verbs-that-disallow-subjects)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-disallow-subjects/tan:name[1], ', ') || ' disallows a subject'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-subjects) and exists($verbs-that-require-subjects)">
            <xsl:copy-of
               select="tan:error('clm09', ('The verb ' || string-join($verbs-that-disallow-subjects/tan:name[1], ', ') || ' must not have subjects; the verb ' || string-join($verbs-that-require-subjects/tan:name[1], ', ') || ' must have them'))"
            />
         </xsl:if>

         <!-- verb problems -->
         <!-- verb data constraint problems -->
         <xsl:if test="exists($these-verbs-whose-objects-require-unit-specification)">
            <!-- if data is expected, no object should be an entity or a textual passage -->
            <xsl:if test="exists(tan:object[not(@units)])">
               <xsl:copy-of select="tan:error('clm01')"/>
            </xsl:if>
            <xsl:if test="count($these-verb-vocab-items) gt 1">
               <xsl:copy-of select="tan:error('clm02')"/>
            </xsl:if>
         </xsl:if>
         <xsl:if test="not(exists($these-verb-refs)) and not(exists(tan:claim))">
            <xsl:copy-of select="tan:error('clm07')"/>
         </xsl:if>
         
         
         <!-- object problems -->
         <xsl:if test="exists($verbs-expecting-object-content-units) and exists($these-object-refs[not(@units)])">
            <xsl:copy-of select="tan:error('clm01')"/>
         </xsl:if>
         <xsl:if test="$these-verb-vocab-items[tan:constraints/tan:object/@content-datatype] and (count($these-verb-vocab-items) gt 1)">
            <xsl:copy-of select="tan:error('clm02')"/>
         </xsl:if>
         <xsl:if test="not(exists($these-object-refs)) and exists($verbs-that-require-objects)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-objects/tan:name[1], ', ') || ' must take an object'))"/>
         </xsl:if>
         <xsl:if test="exists($these-object-refs) and exists($verbs-that-disallow-objects)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-disallow-objects/tan:name[1], ', ') || ' must not take an object'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-objects) and exists($verbs-that-require-objects)">
            <xsl:copy-of
               select="tan:error('clm09', ('The verb ' || string-join($verbs-that-disallow-objects/tan:name[1], ', ') || ' must not have objects; the verb ' || string-join($verbs-that-require-objects/tan:name[1], ', ') || ' must have them'))"
            />
         </xsl:if>
         
         <!-- other claim element problems -->
         <xsl:if test="exists($verbs-that-require-in-lang) and not(exists(tan:in-lang))">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-in-lang/tan:name[1], ', ') || ' must have in-lang'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-in-lang) and exists(tan:in-lang)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-disallow-in-lang/tan:name[1], ', ') || ' must not have in-lang'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-in-lang) and exists($verbs-that-disallow-in-lang)">
            <xsl:copy-of
               select="tan:error('clm09', ('The verb ' || string-join($verbs-that-disallow-in-lang/tan:name[1], ', ') || ' must not have in-lang; the verb ' || string-join($verbs-that-require-in-lang/tan:name[1], ', ') || ' must have it'))"
            />
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-at-ref) and not(exists(tan:at-ref))">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-at-ref/tan:name[1], ', ') || ' must have at-ref'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-at-ref) and exists(tan:at-ref)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-at-ref/tan:name[1], ', ') || ' must not have at-ref'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-at-ref) and exists($verbs-that-disallow-at-ref)">
            <xsl:copy-of
               select="tan:error('clm09', ('The verb ' || string-join($verbs-that-disallow-at-ref/tan:name[1], ', ') || ' must not have at-ref; the verb ' || string-join($verbs-that-require-at-ref/tan:name[1], ', ') || ' must have it'))"
            />
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-period) and not(exists(tan:period))">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-period/tan:name[1], ', ') || ' must have a temporal period'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-period) and exists(tan:period)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-period/tan:name[1], ', ') || ' must not have a temporal period'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-period) and exists($verbs-that-disallow-period)">
            <xsl:copy-of
               select="tan:error('clm09', ('The verb ' || string-join($verbs-that-disallow-period/tan:name[1], ', ') || ' must not have period; the verb ' || string-join($verbs-that-require-period/tan:name[1], ', ') || ' must have it'))"
            />
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-place) and not(exists(tan:where))">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-place/tan:name[1], ', ') || ' must have place'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-disallow-place) and exists(tan:where)">
            <xsl:copy-of select="tan:error('clm08', ('The verb ' || string-join($verbs-that-require-place/tan:name[1], ', ') || ' must not have place'))"/>
         </xsl:if>
         <xsl:if test="exists($verbs-that-require-place) and exists($verbs-that-disallow-place)">
            <xsl:copy-of
               select="tan:error('clm09', ('The verb ' || string-join($verbs-that-disallow-place/tan:name[1], ', ') || ' must not have place; the verb ' || string-join($verbs-that-require-place/tan:name[1], ', ') || ' must have it'))"
            />
         </xsl:if>
         
         <xsl:apply-templates select="node() except $errors-that-should-be-ignored" mode="#current">
            <xsl:with-param name="verbs" select="$these-verb-vocab-items"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:subject | tan:object" mode="tan:core-expansion-terse">
      <xsl:param name="verbs" as="element()*"/>
      <xsl:variable name="vocabulary-parents" as="element()*" select="root()/*/*"/>
      <xsl:variable name="this-name" as="xs:string" select="name(.)"/>
      <xsl:variable name="target-element-names" as="xs:string*" select="tan:target-element-names($this-name)"/>
      <xsl:variable name="these-constraint-rules" select="$verbs/tan:constraints/*[name(.) = $this-name]"/>
      <xsl:variable name="these-content-constraints" select="$these-constraint-rules[exists(@content-datatype)]"/>
      <xsl:variable name="these-item-type-constraints" select="$these-constraint-rules[@item-type]"/>
      <xsl:variable name="this-text" as="xs:string" select="normalize-space(string-join(text(), ''))"/>
      <xsl:variable name="this-ref" as="xs:string?" select="@ref"/>
      <xsl:variable name="this-idref" as="xs:string?"
         select="
            if (exists(@attr)) then
               text()
            else
               (@which | @scriptum | @work | @version)"
      />
      <xsl:variable name="this-vocabulary" as="element()*"
         select="
            if (exists($this-idref)) then
               tan:vocabulary($target-element-names, $this-idref, $vocabulary-parents)
            else
               ()"
      />
      <xsl:variable name="vocabulary-target-element-names" as="xs:string*"
         select="
            for $i in $this-vocabulary/*[tan:IRI or self::tan:claim]
            return
               (name($i), $i/(tan:affects-element, tan:affects-attribute))"
      />
      <xsl:for-each select="$these-item-type-constraints">
         <xsl:variable name="these-types-allowed" select="tokenize(normalize-space(@item-type), ' ')"/>
         <xsl:variable name="ref-allowed-and-found" as="xs:boolean" select="exists($this-ref) and $these-types-allowed = 'ref'"/>
         <xsl:variable name="acceptable-vocabulary" as="element()*"
            select="tan:vocabulary($these-types-allowed, '*', $vocabulary-parents)"/>
         <xsl:if test="not($these-types-allowed = '*') and not($ref-allowed-and-found) and not($these-types-allowed = $vocabulary-target-element-names)">
            <xsl:copy-of
               select="
                  tan:error('clm08', ('Every ' || $this-name || ' of the verb ' || parent::tan:constraints/../tan:name[1] || ' must be one of the following types: ' ||
                  string-join($these-types-allowed, ', ') || (if (exists($target-element-names)) then
                     ('; ' || $this-idref || ' is a ' || string-join(distinct-values($target-element-names[not(. = 'item')]), ', '))
                  else
                     ()) || (if (exists($acceptable-vocabulary)) then
                     ('; try: ' || string-join($acceptable-vocabulary/*/(tan:id/text(), tan:name[1])[1], ', '))
                  else
                     ('; no vocabulary is available for ' || string-join($these-types-allowed, ', ')))))"
            />
         </xsl:if>
      </xsl:for-each>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists(@units) and exists($these-constraint-rules[not(@content-datatype = $tan:datatypes-that-require-unit-specification)])">
            <xsl:copy-of select="tan:error('clm05')"/>
         </xsl:if>
         <xsl:for-each select="$these-content-constraints">
            <xsl:variable name="this-datatype" select="@content-datatype"/>
            <xsl:variable name="this-lexical-constraint" select="@content-lexical-constraint"/>
            <xsl:if test="not(tan:data-type-check($this-text, $this-datatype))">
               <xsl:variable name="help-message"
                  select="'value must match data type ' || $this-datatype"/>
               <xsl:copy-of select="tan:error('clm03', $help-message)"/>
            </xsl:if>
            <xsl:if
               test="exists($this-lexical-constraint) and not(matches($this-text, $this-lexical-constraint))">
               <xsl:variable name="help-message"
                  select="'value must match pattern ' || $this-lexical-constraint"/>
               <xsl:copy-of select="tan:error('clm04', $help-message)"/>
            </xsl:if>
         </xsl:for-each>

         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>


   <!-- TAN-A-lm -->
   
   <xsl:template match="tan:adjustments" mode="tan:core-expansion-terse">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <src>1</src>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:TAN-A-lm/tan:body" mode="tan:core-expansion-terse">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="is-for-lang" select="exists(root()/*/tan:head/tan:for-lang)"
               tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:tok" mode="tan:core-expansion-terse">
      <xsl:param name="is-for-lang" tunnel="yes" as="xs:boolean"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$is-for-lang = false()">
            <src>1</src>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:m" mode="tan:core-expansion-terse">
      <!-- This step breaks down the <m> into constituent <f>s with @n indicating position, and the values normalized (lowercase) -->
      <xsl:variable name="this-text-norm" select="normalize-space(lower-case(text()))"/>
      <xsl:variable name="this-code" select="tan:help-extracted($this-text-norm)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$this-code/@help"/>
         <xsl:value-of select="$this-code"/>
         <xsl:for-each select="tokenize($this-text-norm, ' ')">
            <xsl:variable name="this-val-checked" select="tan:help-extracted(.)"/>
            <xsl:variable name="this-val" select="$this-val-checked/text()"/>
            <f n="{position()}">
               <xsl:copy-of select="$this-val-checked/@help"/>
               <xsl:choose>
                  <xsl:when test="$this-val = ('-', '') and exists($this-val-checked/@help)">
                     <xsl:text> </xsl:text>
                  </xsl:when>
                  <xsl:when test="$this-val = ('-', '')"/>
                  <xsl:otherwise>
                     <xsl:value-of select="$this-val"/>
                  </xsl:otherwise>
               </xsl:choose>
            </f>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:tan-vocabulary/tan:item[tan:affects-element = 'feature']/tan:id" mode="tan:dependency-adjustments-pass-1">
      <!-- ids for features are not allowed to be case-sensitive -->
      <xsl:variable name="this-id-lowercase" select="lower-case(.)"/>
      <xsl:if test="not(. = $this-id-lowercase)">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="$this-id-lowercase"/>
         </xsl:copy>
      </xsl:if>
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary-key/tan:feature[@xml:id][tan:IRI]"
      mode="tan:dependency-adjustments-pass-1">
      <!-- We copy @xml:id for an internally defined vocab key feature, to make it easier to match vocab items to feature codes -->
      <xsl:variable name="this-id" select="@xml:id"/>
      <xsl:variable name="this-id-lc" select="lower-case($this-id)"/>
      <xsl:variable name="these-aliases" select="../tan:alias[tan:idref = ($this-id-lc, $this-id)]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:if test="not(exists(tan:ID))">
            <id>
               <xsl:value-of select="@xml:id"/>
            </id>
         </xsl:if>
         <xsl:if test="not(@xml:id = $this-id-lc)">
            <id>
               <xsl:value-of select="$this-id-lc"/>
            </id>
         </xsl:if>
         <xsl:for-each select="$these-aliases/@id">
            <id alias="">
               <xsl:value-of select="."/>
            </id>
         </xsl:for-each>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:TAN-A-lm/tan:body" mode="tan:tan-a-lm-expansion-terse">
      <xsl:param name="dependencies" tunnel="yes" as="document-node()*"/>
      <xsl:variable name="vocabulary-head" as="element()" select="preceding-sibling::tan:head"/>
      <xsl:variable name="is-lang-specific"
         select="not(../tan:head/tan:source) and ../tan:head/tan:for-lang"/>
      <xsl:variable name="these-morphology-attrs" as="xs:string*" select="key('tan:attrs-by-name','morphology', .)"/>
      <xsl:variable name="these-morphology-ids" as="xs:string*" select="
            for $i in $these-morphology-attrs
            return
               tokenize(normalize-space($i), ' ')"/>

      <xsl:variable name="morphology-rule-map" as="map(*)">
         <!-- This variable contains a map with one map entry per morphology (keyed by id).
            The corresponding value are all rules for the morphology. -->
         <xsl:map>
            <xsl:for-each select="distinct-values($these-morphology-ids)">
               <xsl:variable name="this-morphology-id" as="xs:string" select="."/>
               <xsl:variable name="this-morphology" as="document-node()?">
                  <xsl:choose>
                     <xsl:when
                        test="exists($dependencies[tan:TAN-mor/@morphology = $this-morphology-id])">
                        <xsl:sequence
                           select="$dependencies[tan:TAN-mor/@morphology = $this-morphology-id]"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:variable name="this-vocab"
                           select="tan:vocabulary('morphology', ., $vocabulary-head)"/>
                        <xsl:variable name="this-tan-mor"
                           select="$dependencies[tan:TAN-mor/@id = $this-vocab/tan:item/tan:IRI]"/>
                        <xsl:sequence select="$this-tan-mor[1]"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <xsl:variable name="mor-body" as="element()?" select="$this-morphology/tan:TAN-mor/tan:body"/>
               <xsl:map-entry key=".">
                  <xsl:sequence select="$mor-body/tan:rule"/>
               </xsl:map-entry>
            </xsl:for-each>
         </xsl:map>
      </xsl:variable>
      
      <xsl:variable name="morphology-code-map" as="map(*)">
         <!-- This builds map with one map entry per morphology (keyed by id). Each of those
            map entries contains one map per category (or just one map, if no categories), with
            one map entry per code, pointing to the vocabulary that it corresponds to. -->
         <!-- The map we build proceeds: [morphology key]/[integer] -->
         <xsl:map>
            <xsl:for-each select="distinct-values($these-morphology-ids)">
               <xsl:variable name="this-morphology-id" as="xs:string" select="."/>
               <xsl:variable name="this-morphology" as="document-node()?">
                  <xsl:choose>
                     <xsl:when
                        test="exists($dependencies[tan:TAN-mor/@morphology = $this-morphology-id])">
                        <xsl:sequence
                           select="$dependencies[tan:TAN-mor/@morphology = $this-morphology-id]"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:variable name="this-vocab"
                           select="tan:vocabulary('morphology', ., $vocabulary-head)"/>
                        <xsl:variable name="this-tan-mor"
                           select="$dependencies[tan:TAN-mor/@id = $this-vocab/tan:item/tan:IRI]"/>
                        <xsl:sequence select="$this-tan-mor[1]"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <xsl:variable name="mor-body" as="element()?" select="$this-morphology/tan:TAN-mor/tan:body"/>
               <xsl:variable name="mor-categories" as="element()*" select="$mor-body/tan:category"/>
               <xsl:variable name="mor-vocab-head" as="element()?" select="$this-morphology/tan:TAN-mor/tan:head"/>

               <xsl:map-entry key=".">
                  <xsl:for-each select="
                        if (exists($mor-categories)) then
                           $mor-categories
                        else
                           $mor-body">
                     <xsl:variable name="this-code-parent" as="element()" select="."/>

                     <xsl:map>
                        <xsl:for-each-group select="$this-code-parent/tan:code" group-by="lower-case(string(tan:val/text()))">
                           <xsl:map-entry key="current-grouping-key()">
                              <xsl:copy-of
                                 select="tan:vocabulary('feature', current-group()/@feature, $mor-vocab-head)"/>
                              <xsl:copy-of select="current-group()/tan:desc"/>
                           </xsl:map-entry>
                        </xsl:for-each-group>
                     </xsl:map>

                  </xsl:for-each>

               </xsl:map-entry>
            </xsl:for-each>
         </xsl:map>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="is-lang-specific" tunnel="yes" select="$is-lang-specific"/>
            <xsl:with-param name="morphology-code-map" tunnel="yes" as="map(*)" select="$morphology-code-map"/>
            <xsl:with-param name="morphology-rule-map" tunnel="yes" as="map(*)" select="$morphology-rule-map"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:m" mode="tan:tan-a-lm-expansion-terse">
      <xsl:param name="morphology-code-map" tunnel="yes" as="map(*)"/>
      <xsl:param name="morphology-rule-map" tunnel="yes" as="map(*)"/>
      
      <xsl:variable name="this-m" as="element()" select="."/>
      <xsl:variable name="morphology-ids" select="ancestor-or-self::*[tan:morphology][1]/tan:morphology/text()"/>
      <xsl:variable name="these-morph-code-map-cat-counts" as="xs:integer+" select="
            for $i in $morphology-ids
            return
               count($morphology-code-map($i))"/>
      <xsl:variable name="these-fs" as="element()*" select="tan:f"/>
      
      <xsl:variable name="relevant-rules" as="element()*" select="
            for $i in $morphology-ids
            return
               $morphology-rule-map($i)[some $j in (if (exists(tan:where)) then
                  tan:where
               else
                  self::*)
                  satisfies tan:all-conditions-hold($j, $this-m, (), true())]"/>
      <xsl:variable name="disobeyed-asserts" as="element()*"
         select="$relevant-rules/tan:assert[not(tan:all-conditions-hold(., $this-m, (), true()))]"/>
      <xsl:variable name="disobeyed-reports" as="element()*"
         select="$relevant-rules/tan:report[tan:all-conditions-hold(., $this-m, (), true())]"/>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'= = Diagnostics on, template mode tan:TAN-a-lm-expansion-terse on element ', ."/>
         <xsl:message select="'Morphology ids:', $morphology-ids"/>
         <xsl:message select="'f elements:', $these-fs"/>
         <xsl:message select="'Relevant rules: ', $relevant-rules"/>
         <xsl:message select="'Disobeyed asserts:', $disobeyed-asserts"/>
         <xsl:message select="'Disobeyed reports:', $disobeyed-reports"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each select="$these-morph-code-map-cat-counts[. gt 1]">
            <xsl:if test="count($these-fs) gt .">
               <xsl:copy-of select="tan:error('tlm02', ('max ' || string(.)))"/>
            </xsl:if>
         </xsl:for-each>
         <xsl:apply-templates select="($disobeyed-asserts, $disobeyed-reports)"
            mode="tan:element-to-error">
            <xsl:with-param name="error-id" select="'tlm04'"/>
         </xsl:apply-templates>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="morphology-ids" select="$morphology-ids"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   
   
   
   <xsl:template match="tan:f[text()]" mode="tan:tan-a-lm-expansion-terse">
      <xsl:param name="morphology-code-map" tunnel="yes" as="map(*)"/>
      <xsl:param name="morphology-ids" as="xs:string*"/>

      <xsl:variable name="this-f" as="xs:string" select="string(.)"/>
      <xsl:variable name="help-requested" select="exists(@help)"/>
      <xsl:variable name="this-pos" select="xs:integer(@n)"/>

      <xsl:variable name="these-voc-and-desc-items" as="element()*" select="
            for $i in $morphology-ids
            return
               let $j := $morphology-code-map($i),
                  $k := count($j), (: if count is greather than one, it's a categorized morphology :)
                  $m := (if ($k gt 1) then
                     min(($this-pos, $k))
                  else
                     $k)
               return
                  $j[$m]($this-f)
            "/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan-a-lm-expansion-terse'"/>
         <xsl:message select="'this pos: ', $this-pos"/>
         <xsl:message select="'these voc items: ', $these-voc-and-desc-items"/>
      </xsl:if>
      
      <!-- these errors are set as following siblings of the errant element because we need to tether it as a child 
         to an element that was in the original. -->
      <xsl:if test="not(exists($these-voc-and-desc-items)) or $help-requested = true()">
         <xsl:variable name="this-message" as="xs:string*">
            <xsl:choose>
               <xsl:when test="$help-requested eq true() and exists($these-voc-and-desc-items)">
                  <xsl:value-of select="
                        $this-f || ': ' || (if (exists($these-voc-and-desc-items/self::tan:desc)) then
                           string-join($these-voc-and-desc-items/self::tan:desc, '; ')
                        else
                           string-join($these-voc-and-desc-items/(tan:name | tan:desc), ', '))"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="
                        ($this-f || ' not found; try: ') || (for $i in $morphology-ids,
                           $j in $morphology-code-map($i)[position() = ($this-pos, 1)][1]
                        return
                           string-join(($i, map:keys($j)), ', '))"/>
                  
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:copy-of select="tan:error('tlm03', $this-message)"/>
      </xsl:if>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:if test="$tan:distribute-vocabulary">
            <xsl:copy-of select="$these-voc-and-desc-items/(tan:item | tan:feature)"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   
      
</xsl:stylesheet>
