<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library vocabulary functions. -->
   
   <xsl:function name="tan:element-vocabulary" as="element()*" visibility="public">
      <!-- Input: elements, assumed to be tethered to their resolved document context -->
      <!-- Output: the vocabulary items for that element's attributes (@which, etc.) -->
      <!-- See full tan:vocabulary() function below -->
      <!--kw: vocabulary, nodes -->
      <xsl:param name="element" as="element()*"/>
      <xsl:choose>
         <xsl:when test="exists($element/tan:IRI) and exists($element/tan:name)">
            <local>
               <xsl:copy-of select="$element"/>
            </local>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="tan:attribute-vocabulary($element/@*)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:attribute-vocabulary" as="element()*" visibility="public">
      <!-- Input: attributes, assumed to be still tethered to their resolved document context -->
      <!-- Output: the vocabulary items for that element's attributes (@which, etc.) -->
      <!-- See full tan:vocabulary() function below -->
      <!--kw: vocabulary, attributes -->
      <xsl:param name="attributes" as="attribute()*"/>
      <xsl:variable name="pass-1" as="element()*">
         <xsl:for-each-group select="$attributes[tan:takes-idrefs(.)]" group-by="tan:base-uri(.)">
            <!-- Group attributes first by document... -->
            <xsl:variable name="this-base-uri" select="current-grouping-key()"/>
            <xsl:variable name="this-root" select="current-group()/root()"/>
            <xsl:variable name="this-local-head" select="$this-root/*/tan:head"/>
            <xsl:for-each-group select="current-group()"
               group-by="
                  if (exists(ancestor::*[@include]) and not(name(.) = 'include')) then
                     tokenize(ancestor::*[@include][last()]/@include, '\s+')
                  else
                     ''">
               <!-- ...and then by inclusion... -->
               <!-- (inclusion is key because an included idref value might mean something completely different than what it means in the host document) -->
               <xsl:variable name="this-include-id" select="current-grouping-key()"/>
               <!-- Only TAN-A files (so far) allow @xml:id in the body, making them candidates for vocabulary;
               a TAN-voc file's body is itself vocabulary so it too is allowed. -->
               <xsl:variable name="vocabulary-nodes" select="$this-local-head, $this-root/(tan:TAN-A | tan:TAN-voc)/tan:body"/>
               <xsl:variable name="these-vocabulary-nodes" as="element()*">
                  <xsl:choose>
                     <xsl:when test="string-length($this-include-id) gt 0">
                        <xsl:apply-templates select="$vocabulary-nodes" mode="tan:remove-inclusions">
                           <xsl:with-param name="idref-exceptions" tunnel="yes"
                              select="$this-include-id"/>
                        </xsl:apply-templates>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="$vocabulary-nodes"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               <xsl:for-each-group select="current-group()" group-by="name(.)">
                  <!-- ...and then by the attribute name -->
                  <xsl:variable name="this-attribute-name" select="current-grouping-key()"/>
                  <xsl:variable name="this-is-which" select="$this-attribute-name eq 'which'"/>
                  <!-- @which allows only one value, and spaces are allowed; in all other attributes a space separates distinct values (an underbar replacing a space in a <name>)-->
                  <xsl:variable name="these-attribute-values"
                     select="
                        if ($this-is-which) then
                           tan:normalize-name(current-group())
                        else
                           current-group()"
                  />
                  <xsl:variable name="target-element-names"
                     select="distinct-values(tan:target-element-names(current-group()))"/>
                  
                  <xsl:variable name="diagnostics-on" select="false()"/>
                  <xsl:if test="$diagnostics-on">
                     <xsl:message select="'diagnostics on for tan:attribute-vocabulary()'"/>
                     <xsl:message select="'base uri: ', $this-base-uri"/>
                     <xsl:message select="'include id (if any): ', $this-include-id"/>
                     <xsl:message select="'attribute name: ', $this-attribute-name"/>
                     <xsl:message select="'attribute values: ', distinct-values(current-group())"/>
                     <xsl:message select="'target element names: ', $target-element-names"/>
                     <xsl:message select="'vocabulary nodes (shallow copy): ', tan:shallow-copy($these-vocabulary-nodes, 2)"/>
                  </xsl:if>
                  
                  <xsl:sequence
                     select="tan:vocabulary($target-element-names, $these-attribute-values, $these-vocabulary-nodes)"
                  />
               </xsl:for-each-group>
            </xsl:for-each-group>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:copy-of select="tan:distinct-items($pass-1)"/>
   </xsl:function>

   <xsl:function name="tan:vocabulary" as="element()*" visibility="public">
      <!-- 2-param version of fuller one below -->
      <xsl:param name="target-element-names" as="xs:string*"/>
      <xsl:param name="target-values" as="xs:string*"/>
      <xsl:copy-of select="tan:vocabulary($target-element-names, $target-values, $tan:doc-vocabulary)"/>
   </xsl:function>

   <xsl:function name="tan:vocabulary" as="element()*" visibility="public">
      <!-- Input: two sequences of zero or more strings; a sequence of elements representing the ancestor of vocabulary in a resolved TAN file-->
      <!-- Output: the vocabulary items for the particular elements whose names match the first sequence and whose id, alias, or
         name values match the second sequence, found in descendants of the elements provided by the third sequence -->
      <!-- If either of the first two sequences are empty, or have an *, it is assumed that all possible values
         are sought. Therefore if the first two parameters are empty, the entire vocabulary will be returned -->
      <!-- The second parameter is assumed to have one value per item in the sequence. This is mandatory because it is designed 
         to take two different types of values: @which (which is a single value and permits spaces) and other attributes 
         (can be multiple values, space-delimited) -->
      <!-- If you approach this function with an attribute that points to elements, and you must first to retrieve that attribute's 
         elements, you should run tan:target-element-names() beforehand to generate a list of element names that should be targeted -->
      <!-- It is assumed that the elements are the result of a fully resolved TAN file. -->
      <!-- If a value matches id or alias, no matches on name will be sought (locally redefined ids override name values) -->
      <!-- This function does not mark apparant errors, e.g., vocabulary items missing, or more than one for a single value -->
      <!-- If you are trying to work with vocabulary from an included document, the $resolved-vocabulary-ancestors should point 
         exclusively to content (not self) of the appropriate resolved tan:include -->
      <!--kw: vocabulary -->
      <xsl:param name="target-element-names" as="xs:string*"/>
      <xsl:param name="target-values" as="xs:string*"/>
      <xsl:param name="resolved-vocabulary-ancestors" as="element()*"/>

      <xsl:variable name="fetch-elements-named-whatever"
         select="(count($target-element-names) lt 1) or ($target-element-names = '*')"/>

      <xsl:variable name="values-space-normalized"
         select="
            for $i in $target-values
            return
               normalize-space($i)"
      />
      <xsl:variable name="fetch-all-values"
         select="(count($values-space-normalized) lt 1) or ($target-values = ('')) or ($values-space-normalized = '*')"
      />
      
      <xsl:variable name="vocabulary-pass-1" as="element()*">
         <xsl:choose>
            <xsl:when test="$fetch-all-values">
               <xsl:apply-templates select="$resolved-vocabulary-ancestors"
                  mode="tan:vocabulary-all-vals">
                  <xsl:with-param name="element-names" tunnel="yes" as="xs:string*"
                     select="
                        if ($fetch-elements-named-whatever) then
                           ()
                        else
                           $target-element-names"
                  />
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="$resolved-vocabulary-ancestors" mode="tan:vocabulary-by-id">
                  <xsl:with-param name="element-names" tunnel="yes" as="xs:string*"
                     select="
                        if ($fetch-elements-named-whatever) then
                           ()
                        else
                           $target-element-names"
                  />
                  <xsl:with-param name="idrefs" tunnel="yes" as="xs:string*"
                     select="$values-space-normalized"/>
               </xsl:apply-templates>
               
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="values-not-yet-matched" select="$values-space-normalized[not(. = $vocabulary-pass-1//tan:match/tan:idref)]"/>
      <xsl:variable name="remaining-values-normalized-as-names" select="tan:normalize-name($values-not-yet-matched)"/>
      <xsl:variable name="vocabulary-pass-2" as="element()*">
         <xsl:if test="not($fetch-all-values) and exists($values-not-yet-matched)">
            <xsl:apply-templates select="$resolved-vocabulary-ancestors" mode="tan:vocabulary-by-name">
               <xsl:with-param name="element-names" tunnel="yes" as="xs:string*"
                  select="
                     if ($fetch-elements-named-whatever) then
                        ()
                     else
                        $target-element-names"/>
               <xsl:with-param name="name-values" tunnel="yes" as="xs:string*"
                  select="$remaining-values-normalized-as-names"/>
            </xsl:apply-templates>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="element-name-priority" as="xs:string+" select="('match', 'vocabulary', 'tan-vocabulary', 'inclusion')"/>
      <xsl:variable name="vocabulary-synthesis" as="element()*">
         <xsl:for-each-group select="$vocabulary-pass-1, $vocabulary-pass-2" group-by="name(.)">
            <xsl:sort select="index-of($element-name-priority, current-grouping-key())"/>
            <xsl:choose>
               <xsl:when test="current-grouping-key() = 'match'">
                  <local>
                     <xsl:copy-of select="tan:distinct-items(current-group()/(* except (tan:idref, tan:name-value)))"
                     />
                  </local>
               </xsl:when>
               <xsl:when test="current-grouping-key() = $element-name-priority">
                  <xsl:for-each-group select="current-group()[tan:match]" group-by="tan:IRI[1]">
                     <xsl:element name="{name(current-group()[1])}"
                        namespace="tag:textalign.net,2015:ns">
                        <xsl:copy-of select="current-group()[1]/(tan:IRI, tan:name, tan:desc)"/>
                        <xsl:copy-of
                           select="tan:distinct-items(current-group()/tan:match/(* except (tan:idref, tan:name-value)))"
                        />
                     </xsl:element>
                  </xsl:for-each-group>
               </xsl:when>
               <xsl:when test="current-grouping-key() = ('error', 'warning', 'fatal', 'help', 'fix')"/>
               <xsl:otherwise>
                  <xsl:message select="'In key ' || current-grouping-key() || ' unclear what to do with these: ' || string-join(tan:distinct-items(current-group()), ', ')"/>
                  <miscellaneous>
                     <xsl:copy-of select="tan:distinct-items(current-group())"/>
                  </miscellaneous>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on for tan:vocabulary()'"/>
         <xsl:message select="'Target element names: ', $target-element-names"/>
         <xsl:message select="'Target values:', $target-values"/>
         <xsl:message select="'Resolved vocabulary ancestors:', $resolved-vocabulary-ancestors"/>
         <xsl:message select="'Fetch elements no matter their name?', $fetch-elements-named-whatever"/>
         <xsl:message select="'Target all values?', $fetch-all-values"/>
         <xsl:message select="'Values space-normalized:', $values-space-normalized"/>
         <xsl:message select="'Vocabulary pass 1 matches: ', $vocabulary-pass-1//tan:match"/>
         <xsl:message select="'Values not yet matched: ', $values-not-yet-matched"/>
         <xsl:message select="'Remaining values normalized: ', $remaining-values-normalized-as-names"/>
         <xsl:message select="'Vocabulary pass 2 matches: ', $vocabulary-pass-2//tan:match"/>
         <xsl:message select="'Vocabulary synthesis: ', $vocabulary-synthesis"/>
      </xsl:if>
      
      <xsl:copy-of select="$vocabulary-synthesis"/>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:vocabulary-all-vals" on-no-match="shallow-skip"/>
   <xsl:mode name="tan:vocabulary-by-id" on-no-match="shallow-skip"/>
   <xsl:mode name="tan:vocabulary-by-name" on-no-match="shallow-skip"/>

   <xsl:template match="text() | comment() | processing-instruction()"
      mode="tan:vocabulary-all-vals tan:vocabulary-by-id tan:vocabulary-by-name"/>
   <xsl:template priority="1" match="tan:vocabulary | tan:tan-vocabulary"
      mode="tan:vocabulary-all-vals tan:vocabulary-by-id tan:vocabulary-by-name">
      <xsl:copy>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template priority="1"
      match="tan:vocabulary/tan:IRI | tan:vocabulary/tan:name | tan:vocabulary/tan:location | 
                    tan:tan-vocabulary/tan:IRI | tan:tan-vocabulary/tan:name | tan:tan-vocabulary/tan:location"
      mode="tan:vocabulary-all-vals tan:vocabulary-by-id tan:vocabulary-by-name">
      <xsl:copy>
         <xsl:copy-of select="@* except @q"/>
         <xsl:value-of select="."/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="*[tan:IRI] | tan:token-definition | tan:item[tan:token-definition] | tan:claim" mode="tan:vocabulary-all-vals">
      <xsl:param name="element-names" tunnel="yes" as="xs:string*"/>
      <xsl:variable name="element-name-matches" select="not(exists($element-names)) or (name(.), tan:affects-element) = $element-names"/>
      <xsl:if test="$element-name-matches">
         <match>
            <xsl:copy-of select="."/>
         </match>
      </xsl:if>
      <xsl:if test="self::tan:inclusion">
         <xsl:apply-templates mode="#current"/>
      </xsl:if>
   </xsl:template>
   <!-- In the next template do not include *[tan:alias] in @match, as that will trip up on tan:vocabulary-key -->
   <xsl:template match="*[tan:id][tan:IRI] | tan:claim[tan:id]" mode="tan:vocabulary-by-id">
      <xsl:param name="element-names" tunnel="yes" as="xs:string*"/>
      <xsl:param name="idrefs" tunnel="yes" as="xs:string*"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="element-name-matches" select="not(exists($element-names)) or (name(.), tan:affects-element) = $element-names"/>
      <!-- nonexistent parameters means anything for that value is allowed -->
      <xsl:variable name="matching-idrefs" select="$idrefs[. = $this-element/(tan:id, tan:alias)]"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode vocabulary-by-id'"/>
         <xsl:message select="'This element: ', $this-element"/>
         <xsl:message select="'Idrefs: ', $idrefs"/>
         <xsl:message select="'Element names: ', $element-names"/>
         <xsl:message select="'Element name match?', $element-name-matches"/>
         <xsl:message select="'Matching idrefs:', $matching-idrefs"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="$element-name-matches and (not(exists($idrefs)) or exists($matching-idrefs))">
            <match>
               <xsl:for-each select="$matching-idrefs">
                  <idref>
                     <xsl:value-of select="."/>
                  </idref>
               </xsl:for-each>
               <xsl:copy-of select="."/>
            </match>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="*[tan:IRI][tan:name] | tan:token-definition | tan:item[tan:token-definition]" mode="tan:vocabulary-by-name">
      <xsl:param name="element-names" tunnel="yes" as="xs:string*"/>
      <xsl:param name="name-values" tunnel="yes" as="xs:string*"/>
      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="element-name-matches" as="xs:boolean"
         select="not(exists($element-names)) or (name(.), tan:affects-element) = $element-names"/>
      <xsl:variable name="matching-name-values" as="xs:string*" select="$name-values[. = $this-element/tan:name]"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode vocabulary-by-name'"/>
         <xsl:message select="'This element: ', $this-element"/>
         <xsl:message select="'Target element names: ', $element-names"/>
         <xsl:message select="'Current element name matches target?', $element-name-matches"/>
         <xsl:message select="'Name values (' || string(count($name-values)) || '): ', $name-values"/>
         <xsl:message select="'Matching name values:', $matching-name-values"/>
      </xsl:if>
      
      <xsl:if test="$element-name-matches and (not(exists($name-values)) or exists($matching-name-values))">
         <match>
            <xsl:for-each select="$matching-name-values">
               <name-value>
                  <xsl:value-of select="."/>
               </name-value>
            </xsl:for-each>
            <xsl:copy-of select="."/>
         </match>
      </xsl:if>
      <xsl:if test="self::tan:inclusion">
         <xsl:apply-templates mode="#current"/>
      </xsl:if>
      
   </xsl:template>
   
   
   
   
   <xsl:function name="tan:has-vocab" as="xs:boolean" visibility="public">
      <!-- Input: an attribute; a string -->
      <!-- Output: true if at least one value of the attribute points to vocabulary items that have an <id> or <name> that
         is identical to the 2nd parameter.
      -->
      <!-- The local vocabulary will be checked. If no vocabulary is returned, a check will be made based upon the standard
      TAN vocabulary -->
      <!-- This was written to make XPath predicate expressions easier. -->
      <!--kw: vocabulary -->
      <xsl:param name="attr-to-check" as="attribute()?"/>
      <xsl:param name="ids-and-names" as="xs:string*"/>
      
      <xsl:variable name="attr-local-vocabulary" as="element()*" select="tan:attribute-vocabulary($attr-to-check)"/>
      <xsl:variable name="attr-vocabulary-revised" as="element()*" select="
            if (not(exists($attr-local-vocabulary))) then
               tan:vocabulary(name($attr-to-check/parent::*), tokenize($attr-to-check, ' '), $tan:TAN-vocabularies/tan:TAN-voc/tan:body)
            else
               $attr-local-vocabulary"/>
      
      <xsl:variable name="ids-and-names-norm" as="xs:string*" select="tan:normalize-name($ids-and-names)"/>
      
      <xsl:variable name="matching-vocab-items" select="$attr-vocabulary-revised/*[(tan:name = $ids-and-names-norm) or
         (tan:IRI = $ids-and-names)]" as="element()*"/>
      
      <xsl:sequence select="exists($matching-vocab-items)"/>
      
   </xsl:function>
   
</xsl:stylesheet>
