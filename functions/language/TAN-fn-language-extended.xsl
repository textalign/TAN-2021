<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="3.0">

   <!-- TAN Function Library extended language functions. -->

   <xsl:function name="tan:lm-data" as="element()*" visibility="public">
      <!-- Input: token value; a language code -->
      <!-- Output: <lm> data for that token value from any available resources -->
      <!--kw: language, lexicomorphology -->
      <xsl:param name="token-value" as="xs:string?"/>
      <xsl:param name="lang-codes" as="xs:string*"/>

      <!-- First, look in the local language catalog and get relevant TAN-A-lm files -->
      <xsl:variable name="lang-catalogs" select="tan:lang-catalog($lang-codes)"
         as="document-node()*"/>
      <xsl:variable name="these-tan-a-lm-files" as="document-node()*">
         <xsl:for-each select="$lang-catalogs">
            <xsl:variable name="this-base-uri" select="tan:base-uri(.)"/>
            <xsl:for-each select="
                  collection/doc[(not(exists(tan:tok-is)) and not(exists(tan:tok-starts-with)))
                  or
                  (tan:tok-is = $token-value)
                  or (some $i in tan:tok-starts-with
                     satisfies starts-with($token-value, $i))]">
               <xsl:variable name="this-uri" select="resolve-uri(@href, string($this-base-uri))"/>
               <xsl:if test="doc-available($this-uri)">
                  <xsl:sequence select="doc($this-uri)"/>
               </xsl:if>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>

      <!-- Look for easy, exact matches -->
      <xsl:variable name="lex-val-matches" select="
            for $i in $these-tan-a-lm-files
            return
               key('tan:get-ana', $token-value, $i)"/>

      <!-- If there's no exact match, look for a near match -->
      <xsl:variable name="this-string-approx" select="tan:string-base($token-value)"/>
      <xsl:variable name="lex-rgx-and-approx-matches" select="
            $these-tan-a-lm-files/tan:TAN-A-lm/tan:body/tan:ana[tan:tok[@val = $this-string-approx or (if (string-length(@rgx) gt 0)
            then
               matches($token-value, @rgx)
            else
               false())]]"/>

      <!-- If there's not even a near match, see if there's a search service -->
      <xsl:variable name="lex-matches-via-search" as="element()*">
         <xsl:if test="matches($lang-codes, '^(lat|grc)')">
            <xsl:variable name="this-raw-search" select="tan:search-morpheus($token-value)"/>
            <xsl:copy-of select="tan:search-results-to-claims($this-raw-search, 'morpheus')/*"/>
         </xsl:if>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="exists($lex-val-matches)">
            <xsl:sequence select="$lex-val-matches"/>
         </xsl:when>
         <xsl:when test="exists($lex-rgx-and-approx-matches)">
            <xsl:sequence select="$lex-rgx-and-approx-matches"/>
         </xsl:when>
         <xsl:when test="exists($lex-matches-via-search)">
            <xsl:sequence select="$lex-matches-via-search"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="not(exists($these-tan-a-lm-files))">
               <xsl:message select="'No local TAN-A-lm files found for', $lang-codes"/>
            </xsl:if>
            <xsl:message select="'No data found for', $token-value, 'in language', $lang-codes"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>


   
   <xsl:function name="tan:merge-anas" as="element()?" visibility="private">
      <!-- Input: a set of <ana>s that should be merged; a list of strings to which <tok>s should be restricted -->
      <!-- Output: the merger of the <ana>s, with @cert recalibrated and all <tok>s merged -->
      <!-- This function presumes that every relevant <tok> has a @val, and that values of <l> and <m> have been normalized -->
      
      <xsl:param name="anas-to-merge" as="element(tan:ana)*"/>
      <xsl:param name="regard-only-those-toks-that-have-what-vals" as="xs:string*"/>
      <xsl:variable name="ana-tok-counts" as="xs:integer*">
         <xsl:for-each select="$anas-to-merge">
            <xsl:variable name="toks-of-interest"
               select="tan:tok[@val = $regard-only-those-toks-that-have-what-vals]"/>
            <xsl:choose>
               <xsl:when test="exists(@tok-pop)">
                  <xsl:value-of select="@tok-pop"/>
               </xsl:when>
               <xsl:when test="exists($toks-of-interest)">
                  <xsl:value-of select="count($toks-of-interest)"/>
               </xsl:when>
               <xsl:when test="exists(tan:lm)">
                  <xsl:value-of
                     select="
                     sum(for $i in tan:lm
                     return
                     (count($i/tan:l) * count($i/tan:m)))"
                  />
               </xsl:when>
               <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="ana-certs" select="
            for $i in $anas-to-merge
            return
               if ($i/@cert) then
                  number($i/@cert)
               else
                  1"/>
      <xsl:variable name="lms-itemized" as="element()*">
         <xsl:apply-templates select="$anas-to-merge" mode="tan:itemize-lms">
            <xsl:with-param name="ana-cert-sum" select="sum($ana-certs)" tunnel="yes"/>
            <xsl:with-param name="context-tok-count" select="sum($ana-tok-counts)"/>
            <xsl:with-param name="tok-val" select="$regard-only-those-toks-that-have-what-vals"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="lms-grouped" as="element()*">
         <xsl:for-each-group select="$lms-itemized" group-by="tan:l">
            <xsl:variable name="this-lm-cert" select="
                  sum(for $i in current-group()
                  return
                     number($i/@cert))"/>
            <xsl:variable name="this-l-group-count" select="count(current-group())"/>
            <lm>
               <xsl:if
                  test="($this-l-group-count lt count($lms-itemized)) and $this-lm-cert lt 0.9999">
                  <xsl:attribute name="cert" select="$this-lm-cert"/>
               </xsl:if>
               <xsl:copy-of select="current-group()[1]/tan:l"/>
               <xsl:for-each-group select="current-group()" group-by="tan:m">
                  <xsl:variable name="this-m-cert" select="
                        sum(for $i in current-group()
                        return
                           number($i/@cert))"/>
                  <xsl:variable name="this-m-group-count" select="count(current-group())"/>
                  <m>
                     <xsl:if test="$this-m-group-count lt $this-l-group-count">
                        <xsl:attribute name="cert" select="$this-m-cert div $this-lm-cert"/>
                     </xsl:if>
                     <xsl:value-of select="current-grouping-key()"/>
                  </m>
               </xsl:for-each-group>
            </lm>
         </xsl:for-each-group>
      </xsl:variable>
      <ana tok-pop="{sum($ana-tok-counts)}">
         <xsl:copy-of
            select="tan:distinct-items($anas-to-merge/tan:tok[@val = $regard-only-those-toks-that-have-what-vals])"/>
         <xsl:for-each select="$lms-grouped">
            <xsl:sort
               select="
               if (@cert) then
               number(@cert)
               else
               1"
               order="descending"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="tan:l"/>
               <xsl:for-each select="tan:m">
                  <xsl:sort select="
                        if (@cert) then
                           number(@cert)
                        else
                           1" order="descending"/>
                  <xsl:copy-of select="."/>
               </xsl:for-each>
            </xsl:copy>
         </xsl:for-each>
      </ana>
   </xsl:function>
   
   <xsl:mode name="tan:itemize-lms" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:ana" mode="tan:itemize-lms">
      <xsl:param name="ana-cert-sum" as="xs:double?"/>
      <xsl:param name="context-tok-count" as="xs:integer"/>
      <xsl:param name="tok-val" as="xs:string*"/>
      <xsl:variable name="toks-of-interest" select="tan:tok[@val = $tok-val]"/>
      <xsl:variable name="this-tok-count" as="xs:integer">
         <xsl:choose>
            <xsl:when test="exists(@tok-pop)">
               <xsl:value-of select="@tok-pop"/>
            </xsl:when>
            <xsl:when test="exists($toks-of-interest)">
               <xsl:value-of select="count($toks-of-interest)"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:apply-templates select="tan:lm" mode="#current">
         <xsl:with-param name="ana-cert" tunnel="yes"
            select="$this-tok-count div $context-tok-count"/>
         <!--<xsl:with-param name="lm-count" tunnel="yes" select="$this-lm-combo-count"/>-->
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:l" mode="tan:itemize-lms">
      <xsl:param name="ana-cert" as="xs:double" tunnel="yes"/>
      <!--<xsl:param name="lm-count" as="xs:integer" tunnel="yes"/>-->
      <xsl:variable name="this-l" select="."/>
      <xsl:variable name="this-lm-cert" select="number((../@cert, 1)[1])"/>
      <xsl:variable name="this-l-cert" select="number((@cert, 1)[1])"/>
      <!--<xsl:variable name="this-l-pop" select="count(../tan:l)"/>-->
      <xsl:variable name="sibling-ms" select="following-sibling::tan:m"/>
      <!--<xsl:variable name="this-m-pop" select="count($sibling-ms)"/>-->
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode itemize-lms, for: ', ."/>
         <xsl:message select="'ana certainty: ', $ana-cert"/>
         <xsl:message select="'lm certainty: ', $this-lm-cert"/>
         <xsl:message select="'this certainty: ', $this-l-cert"/>
         <xsl:message select="'these m certainties: ', $sibling-ms/@cert"/>
      </xsl:if>
      <xsl:for-each select="$sibling-ms">
         <xsl:variable name="this-m-cert" select="number((@cert, 1)[1])"/>
         <xsl:variable name="this-itemized-lm-cert"
            select="($ana-cert * $this-lm-cert * $this-l-cert * $this-m-cert)"/>
         <lm>
            <xsl:if test="$this-itemized-lm-cert lt 0.9999">
               <xsl:attribute name="cert" select="$this-itemized-lm-cert"/>
            </xsl:if>
            <l>
               <xsl:value-of select="$this-l"/>
            </l>
            <m>
               <xsl:copy-of select="@* except @cert"/>
               <xsl:value-of select="."/>
            </m>
         </lm>
      </xsl:for-each>
   </xsl:template>
   
   
   <xsl:function name="tan:lang-code" as="xs:string*" visibility="public">
      <!-- Input: the name of a language -->
      <!-- Output: the 3-letter code for the language -->
      <!-- If no exact match is found, the parameter will be treated as a regular expression, and all case-insensitive matches will be returned -->
      <!--kw: language -->
      <xsl:param name="lang-name" as="xs:string?"/>
      <xsl:variable name="lang-match"
         select="$tan:iso-639-3/tan:iso-639-3/tan:l[@name = $lang-name]/@id"/>
      <xsl:choose>
         <xsl:when test="not(exists($lang-match)) and (string-length($lang-name) gt 0)">
            <xsl:value-of
               select="
               for $i in $tan:iso-639-3/tan:iso-639-3/tan:l[matches(@name, $lang-name, 'i')]
               return
               string($i/@id)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$lang-match"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:lang-name" as="xs:string*" visibility="public">
      <!-- Input: the code of a language -->
      <!-- Output: the name of the language -->
      <!-- If no exact match is found, the parameter will be treated as a regular expression, and all case-insensitive matches will be returned -->
      <!--kw: language -->
      <xsl:param name="lang-code" as="xs:string?"/>
      <xsl:variable name="lang-match"
         select="$tan:iso-639-3/tan:iso-639-3/tan:l[@id = $lang-code]/@name"/>
      <xsl:choose>
         <xsl:when test="not(exists($lang-match)) and (string-length($lang-code) gt 0)">
            <xsl:value-of
               select="
               for $i in $tan:iso-639-3/tan:iso-639-3/tan:l[matches(@id, $lang-code, 'i')]
               return
               string($i/@name)"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$lang-match"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:lang-catalog" as="document-node()*" visibility="public">
      <!-- Input: language codes -->
      <!-- Output: the catalogs for those languages -->
      <!--kw: language -->
      <xsl:param name="lang-codes" as="xs:string*"/>
      <xsl:variable name="lang-codes-rev" select="
            if ((count($lang-codes) lt 1) or $lang-codes = '*') then
               '*'
            else
               $lang-codes"/>
      <xsl:for-each select="$lang-codes-rev">
         <xsl:variable name="this-lang-code" select="."/>
         <xsl:variable name="these-catalog-uris" select="
               if ($this-lang-code = '*') then
                  (for $i in $languages-supported
                  return
                     $tan:lang-catalog-map($i))
               else
                  $tan:lang-catalog-map($this-lang-code)"/>
         <xsl:if test="not(exists($these-catalog-uris))">
            <xsl:message select="'No catalogs defined for', $this-lang-code"/>
         </xsl:if>
         <xsl:for-each select="$these-catalog-uris">
            <xsl:variable name="this-uri" select="."/>
            <xsl:choose>
               <xsl:when test="doc-available($this-uri)">
                  <xsl:sequence select="doc($this-uri)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:message select="'Language catalog not available at ', $this-uri"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:variable name="languages-supported" select="map:keys($tan:lang-catalog-map)"/>
   
   
   <xsl:function name="tan:TAN-A-lm-hrefs" as="xs:string*" visibility="private">
      <!-- Input: two strings; catalog documents -->
      <!-- Output: the @href values of any documents in the catalog that both support the language specified (1st 
            param) and either lack <tok-starts-with> or <tok-is>, or has one that comports with the 2nd parameter. -->
      <!-- If there is no match, then the empty string (not null!) will be returned. -->
      <!-- This function was written to support two applications, one for quotation detection and the other for
         creating TAN-A-lm files. -->
      <xsl:param name="language-of-interest" as="xs:string"/>
      <xsl:param name="token-of-interest" as="xs:string"/>
      <xsl:param name="language-catalogs" as="document-node()*"/>
      <xsl:variable name="these-lang-entries" as="element()*" select="$language-catalogs/collection/doc[tan:for-lang = $language-of-interest]"/>
      <xsl:variable name="matching-entries" as="xs:string*">
         <xsl:for-each select="$language-catalogs">
            <xsl:variable name="this-base-uri" select="tan:base-uri(.)" as="xs:anyURI"/>
            <xsl:for-each select="collection/doc[tan:for-lang eq $language-of-interest]">
               <xsl:choose>
                  <xsl:when test="not(exists(tan:tok-starts-with)) and not(exists(tan:tok-is))">
                     <xsl:value-of select="resolve-uri(@href, $this-base-uri)"/>
                  </xsl:when>
                  <xsl:when test="tan:tok-is = $token-of-interest">
                     <xsl:value-of select="resolve-uri(@href, $this-base-uri)"/>
                  </xsl:when>
                  <xsl:when test="exists(tan:tok-starts-with[starts-with($token-of-interest, .)])">
                     <xsl:value-of select="resolve-uri(@href, $this-base-uri)"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="good-hrefs" select="$matching-entries[doc-available(.)]" as="xs:string*"/>
      
      <xsl:choose>
         <xsl:when test="exists($good-hrefs)">
            <xsl:sequence select="$good-hrefs"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="''"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:function name="tan:morphological-code-conversion-maps" as="map(*)*" visibility="public" 
      _cache="{$tan:advanced-processing-available}">
      <!-- Input: two TAN-mor files, resolved -->
      <!-- Output: a sequence of one or more maps, one per category in the first TAN-mor file. If the first 
         TAN-mor file lacks categories, then only one map is returned. Each map's map entries have keys corresponding 
         to the morphological codes allowed for that category. The values consists of an array. Each array member
         is a sequence of two items: an integer and a string. The integer specifies the position of the target
         morphological category and the string, the morphological code. The order of the array members corresponds
         to apparent preference. -->
      <!-- Non-categorized morphologies can take advantage of <alias> to build complex grammatical features, which
         complicates the output of this function somewhat. Mapping from simple feature to simple feature is 
         straightforward. Mapping from complex feature to simple feature requires a one-to-many map, and if 
         a complex feature in the source morphology does not have a counterpart in the target for every simple
         feature that makes up the complex one, then no match exists and the code is not supported. 
            It gets a bit tougher for mapping to a complex feature in the target morphology. Preleminary work
         is done to find those complex features, then detect every mapping of simple or complex objects that 
         could be translated into that target complex feature. If the source morphology is category-based, the
         result is a regular expression to match against <m>. If the source morphology lacks categories, then
         an alphabetized list of codes becomes the key to the target complex feature. A map of to all target
         complex features is inserted in the first output map. These can be found simply by looking for the
         presence of space or the opening ^ in the key name. -->
      <!-- Because TAN-mor was designed to enable a wide range of grammatical constructions, and because 
         designers have different views on language and categories, converting from one morphological code
         system to another can be messy, with features in either the source or target that lack any counterpart
         in the other. Or there may be overlapping results when assessing complex features. For example, in the
         Perseus system for Greek, a word marked as a singular personal pronoun will have at least three 
         grammatical categories that will result in a mapping to the Brown system for English as both NN 
         (singular noun) and NP (proper noun), both of which are true. It is up to users to discern on a
         case-by-case basis the best way to resolve ambiguity and incommensurability.
      -->
      <!--kw: language, lexicomorphology -->
      <xsl:param name="source-TAN-mor-resolved" as="document-node()"/>
      <xsl:param name="target-TAN-mor-resolved" as="document-node()"/>
      
      <xsl:variable name="source-feature-vocabulary" as="element()*"
         select="tan:vocabulary('feature', (), $source-TAN-mor-resolved/tan:TAN-mor/tan:head)"
      />
      <xsl:variable name="target-feature-vocabulary" as="element()*"
         select="tan:vocabulary('feature', (), $target-TAN-mor-resolved/tan:TAN-mor/tan:head)"
      />
      
      <xsl:variable name="sf-vocab-with-categories" as="element()*">
         <xsl:apply-templates select="$source-feature-vocabulary" mode="tan:add-category-position">
            <xsl:with-param name="categories" as="element()*" tunnel="yes"
               select="$source-TAN-mor-resolved/tan:TAN-mor/tan:body/tan:category"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:variable name="tf-vocab-with-categories" as="element()*">
         <xsl:apply-templates select="$target-feature-vocabulary" mode="tan:add-category-position">
            <xsl:with-param name="categories" as="element()*" tunnel="yes"
               select="$target-TAN-mor-resolved/tan:TAN-mor/tan:body/tan:category"/>
         </xsl:apply-templates>
      </xsl:variable>
      <!-- Aliases combining features implies "and" not "or", so every category
         must be true. Complex aliases for features is supported only in TAN-mor files without
         categories. -->
      <xsl:variable name="complex-target-aliases" as="element()*"
         select="tan:duplicate-items($target-feature-vocabulary//tan:alias)"/>
      
      <xsl:variable name="complex-target-alias-map-entries" as="map(*)*">
         <xsl:for-each select="distinct-values($complex-target-aliases)">
            <xsl:variable name="this-alias" as="xs:string" select="."/>
            <xsl:variable name="these-vocab-items" as="element()*"
               select="$target-feature-vocabulary//*[tan:alias = $this-alias]"/>
            <xsl:variable name="number-of-features-expected" as="xs:integer"
               select="count($these-vocab-items)"/>
            
            <xsl:choose>
               <xsl:when test="exists($source-TAN-mor-resolved/tan:TAN-mor/tan:body/tan:category)">
                  <!-- If the source is categorized, the key will be a regular expression matching the code -->
                  <xsl:variable name="source-id-array" as="array(*)" select="
                        array:join(for $i in $these-vocab-items
                        return
                           [
                              (for $j in $sf-vocab-with-categories//*[tan:IRI = $i/tan:IRI]/tan:category
                              return
                                 (xs:integer($j), string($j/@code)))
                           ])"/>
                  <xsl:variable name="these-code-positions" as="xs:integer*" select="
                        for $i in (1 to array:size($source-id-array))
                        return
                           $source-id-array($i)[1]"/>
                  <xsl:variable name="max-pos" as="xs:integer?" select="max($these-code-positions)"/>
                  <xsl:variable name="reg-exp-pieces" as="xs:string*" select="
                        for $i in (1 to $max-pos)
                        return
                           let $matches := (for $j in (1 to array:size($source-id-array))
                           return
                              if ($source-id-array($j)[1] eq $i) then
                                 tan:escape($source-id-array($j)[2])
                              else
                                 ())
                           return
                              if (count($matches) gt 0) then '(' || string-join($matches, '|') || ')'
                              else '\S+'
                        "/>
                  
                  <xsl:if test="count(distinct-values($these-code-positions)) eq $number-of-features-expected">
                     <xsl:map-entry key="'^' || string-join($reg-exp-pieces, ' ') || '( |$)'" select="$this-alias"/>
                  </xsl:if>
                  
                  
               </xsl:when>
               <xsl:otherwise>
                  <!-- If the source is non-categorized, the key will be a space-delimited joining of the relevant codes, alphabetized -->
                  <xsl:variable name="source-id-array" as="array(*)" select="
                        array:join(for $i in $these-vocab-items
                        return
                           [
                              (for $j in $sf-vocab-with-categories//*[tan:IRI = $i/tan:IRI]/(tan:id, tan:alias)
                              return
                                 string($j))
                           ])"/>
                  <xsl:variable name="source-id-permutations" as="array(*)" select="tan:array-permutations($source-id-array)"/>
                  <xsl:variable name="id-combos-arranged" as="xs:string*" select="
                        for $i in (1 to array:size($source-id-permutations))
                        return
                           string-join(sort($source-id-permutations($i)), ' ')"/>
                  <xsl:for-each select="distinct-values($id-combos-arranged)">
                     <xsl:map-entry key="." select="$this-alias"/>
                  </xsl:for-each>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         
      </xsl:variable>
      
      <xsl:variable name="output-pass-1" as="map(*)*">
         <xsl:for-each-group select="$sf-vocab-with-categories//*[tan:category]" group-by="tan:category">
            <xsl:sort select="xs:integer(current-grouping-key())"/>
            
            <xsl:map>
               <!-- Build the complex map entries. Here, every key will consist of two or more strings,
                  space-joined, and point to a simple string that represents the id of a complex feature 
                  alias in the target morphology. -->
               <xsl:if test="position() eq 1">
                  <xsl:sequence select="$complex-target-alias-map-entries"/>
               </xsl:if>
               <!-- Now build the regular map entries, where keys are simple. -->
               <xsl:for-each-group select="current-group()" group-by="
                     if (exists(tan:category/@code)) then
                        tan:category/@code
                     else
                        (tan:id | tan:alias)">
                  <xsl:variable name="this-id" as="xs:string"
                     select="string(current-grouping-key())"/>
                  <xsl:variable name="these-iris" as="element()*" select="current-group()/tan:IRI"/>
                  <xsl:variable name="these-names" as="element()*" select="current-group()/tan:name"/>
                  <xsl:variable name="target-feature-vocab-matches" as="element()*"
                     select="$tf-vocab-with-categories//*[tan:IRI = $these-iris]"/>
                  <xsl:choose>
                     <xsl:when test="exists($target-feature-vocab-matches) and count(current-group()) eq 1">
                        <xsl:map-entry key="$this-id" select="
                              array:join(for $i in $target-feature-vocab-matches,
                                 $j in $i/tan:category
                              return
                                 [(xs:integer($j), string(($j/@code, $i/tan:alias[not(. = $complex-target-aliases)], $i/tan:id)[1]))])"
                        />
                     </xsl:when>
                     <xsl:when test="exists($target-feature-vocab-matches)">
                        <!-- An alias might entail two or more grammatical features, in which case, there
                           should be one array per feature. -->
                        <xsl:map-entry key="$this-id" select="
                              for $a in current-group()
                              return
                                 let $b := $tf-vocab-with-categories//*[tan:IRI = $a/tan:IRI]
                                 return
                                    array:join(for $i in $b,
                                       $j in $i/tan:category
                                    return
                                       [(xs:integer($j), string(($j/@code, $i/tan:alias[not(. = $complex-target-aliases)], $i/tan:id)[1]))])"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:message
                           select="'Unable to find a target feature that corresponds to the source feature with id ' || $this-id || ' (' || $these-names[1] || ')'"
                        />
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each-group>
            </xsl:map>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="true()"/>
      
      <xsl:sequence select="$output-pass-1"/>
      <xsl:if test="$output-diagnostics-on">
         <xsl:message select="'Inserting diagnostic output as last map in the output of tan:morphological-code-conversion-maps()'"/>
         <xsl:map>
            <xsl:map-entry key="'diagnostics'">
               <source-feature-vocabulary><xsl:copy-of select="$source-feature-vocabulary"/></source-feature-vocabulary>
               <target-feature-vocabulary><xsl:copy-of select="$target-feature-vocabulary"/></target-feature-vocabulary>
               <source-categories><xsl:copy-of select="$source-TAN-mor-resolved/tan:TAN-mor/tan:body/tan:category"/></source-categories>
               <target-categories><xsl:copy-of select="$target-TAN-mor-resolved/tan:TAN-mor/tan:body/tan:category"/></target-categories>
               <sf-vocab-with-categories><xsl:copy-of select="$sf-vocab-with-categories"/></sf-vocab-with-categories>
               <tf-vocab-with-categories><xsl:copy-of select="$tf-vocab-with-categories"/></tf-vocab-with-categories>
            </xsl:map-entry>
         </xsl:map>
      </xsl:if>
   </xsl:function>
   
   <xsl:mode name="tan:add-category-position" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:feature | tan:item[tan:affects-element = 'feature']" mode="tan:add-category-position">
      <xsl:param name="categories" as="element()*" tunnel="yes"/>
      <xsl:variable name="these-ids" select="tan:id | tan:alias"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <xsl:when test="not(exists($categories))">
               <!-- Zero means that the code is not place-dependent -->
               <category>0</category>
            </xsl:when>
            <xsl:otherwise>
               <xsl:for-each select="$categories">
                  <xsl:variable name="this-pos" as="xs:integer" select="position()"/>
                  <xsl:variable name="feature-of-interest" as="element()*" select="tan:feature[tokenize(@type, ' ') = $these-ids]"/>
                  <xsl:for-each select="$feature-of-interest">
                     <category>
                        <xsl:copy-of select="@code"/>
                        <xsl:value-of select="$this-pos"/>
                     </category>
                  </xsl:for-each>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:function name="tan:convert-morphological-codes" as="document-node()?" visibility="public">
      <!-- Input: a TAN-A-lm file, a sequence of strings, maps that are the result of tan:morphological-code-conversion-maps() -->
      <!-- Output: the TAN-A-lm file, with relevant <m> codes converted. This will be applied only to <m> whose closest
         @morphology is one of the strings from the second parameter, and codes will be converted from the source to the 
         target according to the maps supplied. -->
      <!-- The second parameter can be empty; If so, then the default with be the values in /tan:TAN-A-lm/tan:body/@morphology -->
      <!-- This function does not change the vocabulary or @morphology codes. That must be done separately. -->
      <!-- See comments at tan:morphological-code-conversion-maps() regarding difficulties inherent in mapping 
         grammatical systems to each other. -->
      <!--kw: language, lexicomorphology -->
      <xsl:param name="TAN-A-lm-to-convert" as="document-node()?"/>
      <xsl:param name="morphology-ids-to-convert" as="xs:string"/>
      <xsl:param name="morphology-code-conversion-maps" as="map(*)*"/>
      <xsl:variable name="morph-ids-norm" as="xs:string*" select="
            if (not(exists($morphology-ids-to-convert[matches(., '\S')])))
            then
               tokenize(normalize-space($TAN-A-lm-to-convert/tan:TAN-A-mor/tan:body/@morphology), ' ')
            else
               $morphology-ids-to-convert"/>
      <xsl:apply-templates select="$TAN-A-lm-to-convert" mode="tan:convert-morphological-codes">
         <xsl:with-param name="morphology-ids" as="xs:string*" tunnel="yes" select="$morph-ids-norm"
         />
         <xsl:with-param name="morphology-code-conversion-maps" as="map(*)*" tunnel="yes"
            select="$morphology-code-conversion-maps[map:size(.) gt 1 or not(map:keys(.) eq 'diagnostics')]"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:convert-morphological-codes" on-no-match="shallow-copy"/>
   
   
   <xsl:template match="tan:m" mode="tan:convert-morphological-codes">
      <xsl:param name="morphology-ids" as="xs:string*" tunnel="yes"/>
      <xsl:param name="morphology-code-conversion-maps" as="map(*)*" tunnel="yes"/>
      <xsl:variable name="governing-morphologies" as="xs:string*"
         select="tokenize(ancestor-or-self::*[@morphology][1]/@morphology, ' ')"/>
      <xsl:variable name="convert-these-codes" as="xs:boolean" select="$governing-morphologies = $morphology-ids"/>
      <xsl:variable name="source-codes-are-categorized" as="xs:boolean" select="count($morphology-code-conversion-maps) gt 1"/>
      <xsl:variable name="this-code-norm" as="xs:string" select="normalize-space(lower-case(string-join(text())))"/>
      <xsl:variable name="these-codes" as="xs:string*" select="tokenize($this-code-norm, ' ')"/>
      
      <xsl:variable name="keys-to-complex-constructions" as="xs:string*" select="map:keys($morphology-code-conversion-maps[1])[contains(., ' ')
         or matches(., '^^.+\( \|\$\)')]"/>
      
      <xsl:variable name="matching-keys-to-complex-constructions" as="array(*)*">
         <!-- Establish a nexus between the current codes and the target code they should be replaced by. We use
            a sequence of arrays. Each array has two members. The first member contains the integers in the source 
            code. The second member contains the string that is to replace them. -->
         <xsl:for-each select="$keys-to-complex-constructions">
            <xsl:variable name="this-regex" as="xs:string" select="."/>
            <xsl:choose>
               <xsl:when test="$source-codes-are-categorized">
                  <xsl:variable name="code-test" as="element()"
                     select="analyze-string($this-code-norm, $this-regex)"/>
                  <xsl:if test="exists($code-test/*:match/*:group)">
                     <xsl:variable name="code-test-rev" as="element()">
                        <xsl:apply-templates select="$code-test" mode="tan:add-code-test-toks"/>
                     </xsl:variable>
                     <xsl:sequence select="
                           [
                              (for $i in $code-test-rev/*:group[matches(., '\S')]
                              return
                                 count($i/preceding-sibling::*) + 1), $morphology-code-conversion-maps[1]($this-regex)
                           ]"/>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="these-key-codes" select="tokenize(., ' ')"/>
                  <xsl:if test="every $i in $these-key-codes satisfies $i = $these-codes">
                     <xsl:sequence select="
                           [
                              (for $i in $these-key-codes
                              return
                                 index-of($these-codes, $i)), $morphology-code-conversion-maps[1]($this-regex)
                           ]"/>
                  </xsl:if>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="omit-which-code-numbers" as="xs:integer*" select="
            for $i in $matching-keys-to-complex-constructions
            return
               $i(1)"/>
      <xsl:variable name="insert-what-codes" as="xs:string*" select="
            for $i in $matching-keys-to-complex-constructions
            return
               $i(2)"/>
      
      <xsl:variable name="these-codes-adjusted" as="xs:string*">
         <xsl:for-each select="$these-codes">
            <xsl:variable name="omit-this-position" as="xs:boolean" select="position() = $omit-which-code-numbers"/>
            <xsl:choose>
               <xsl:when test="not($omit-this-position)">
                  <xsl:copy-of select="."/>
               </xsl:when>
               <xsl:when test="$source-codes-are-categorized">
                  <xsl:copy-of select="'-'"/>
               </xsl:when>
               <!-- non-categorized codes are dropped if they've matched a complex alias -->
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      
      
      <xsl:variable name="these-code-conversions" as="array(*)" select="
            if (not($source-codes-are-categorized))
            then
               array:join(for $i in $these-codes-adjusted
               return
               if (map:keys($morphology-code-conversion-maps) = $i)
               then
               (for $k in $morphology-code-conversion-maps($i) return
                  [$k(1)])
               else [])
            else
               array:join(for $i in (1 to count($these-codes-adjusted)),
                  $j in $these-codes-adjusted[$i]
               return
                  if (map:keys($morphology-code-conversion-maps[$i]) = $j)
                  then
                  (for $k in $morphology-code-conversion-maps[$i]($j) return
                  [$k(1)])
                  else [])"/>
      <xsl:variable name="these-code-positions" as="xs:integer*" select="
            for $i in (1 to array:size($these-code-conversions))
            return
               $these-code-conversions($i)[1]"/>
      <xsl:variable name="conflicting-positions" as="xs:integer*" select="tan:duplicate-values($these-code-positions[. gt 0])"/>
      <xsl:variable name="max-pos" as="xs:integer?" select="max($these-code-positions)"/>
      <xsl:variable name="converted-code" as="xs:string*">
         
         <xsl:choose>
            <xsl:when test="not($convert-these-codes)"/>
            <xsl:when test="not($source-codes-are-categorized) and ($max-pos gt 0)">
               <!-- going from non-categories to categories -->
               <xsl:value-of select="
                     for $i in (1 to $max-pos)
                     return
                        ((for $j in (1 to array:size($these-code-conversions))
                        return
                           if ($these-code-conversions($j)[1] eq $i)
                           then
                              $these-code-conversions($j)[2]
                           else
                              ()), '-')[1]"/>
            </xsl:when>
            <xsl:when test="not($source-codes-are-categorized)">
               <!-- going from non-categories to non-categories -->
               <xsl:value-of select="
                     for $i in (1 to array:size($these-code-conversions))
                     return
                        $these-code-conversions($i)[2]"/>
            </xsl:when>
            <xsl:when test="$source-codes-are-categorized and ($max-pos gt 0)">
               <!-- going from categories to categories -->
               <xsl:value-of select="
                     for $i in (1 to $max-pos)
                     return
                        ((for $j in (1 to array:size($these-code-conversions))
                        return
                           if ($these-code-conversions($j)[1] eq $i)
                           then
                              $these-code-conversions($j)[2]
                           else
                              ()), '-')[1]"/>
            </xsl:when>
            <xsl:when test="$source-codes-are-categorized">
               <!-- going from categories to non-categories -->
               <xsl:value-of select="
                     for $i in (1 to array:size($these-code-conversions))
                     return
                        $these-code-conversions($i)[2]"/>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode tan:convert-morphological-codes on m'"/>
         <xsl:message select="'Matching keys to complex constructions: ', $matching-keys-to-complex-constructions"/>
         <xsl:message select="'Current code:', $this-code-norm"/>
         <xsl:message select="'Omit which code numbers:', $omit-which-code-numbers"/>
         <xsl:message select="'Insert what codes:', $insert-what-codes"/>
         <xsl:message select="'Codes adjusted:', $these-codes-adjusted"/>
         <xsl:message select="'These code conversions:', $these-code-conversions"/>
         <xsl:message select="'These code positions:', $these-code-positions"/>
      </xsl:if>
      
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($conflicting-positions)">
            <xsl:message
               select="'There are multiple entries for the following positions: ', $conflicting-positions"
            />
         </xsl:if>
         <xsl:choose>
            <xsl:when test="string-length($converted-code) gt 0 or exists($insert-what-codes)">
               <xsl:value-of
                  select="normalize-space(string-join(($insert-what-codes, $converted-code), ' '))"
               />
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:add-code-test-toks" on-no-match="shallow-copy"/>
   
   <xsl:template match="*:match | *:non-match" mode="tan:add-code-test-toks">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="*:match/text()" mode="tan:add-code-test-toks">
      <xsl:analyze-string select="." regex="\S+">
         <xsl:matching-substring>
            <tok>
               <xsl:value-of select="."/>
            </tok>
         </xsl:matching-substring>
         <xsl:non-matching-substring>
            <xsl:value-of select="."/>
         </xsl:non-matching-substring>
      </xsl:analyze-string>
   </xsl:template>
   
   
   <xsl:function name="tan:ana-lm-arrays" as="array(*)*" visibility="private">
      <!-- Input: tree fragments from any TAN-A-lm -->
      <!-- Output: one singleton array per combination of <l> and <m> within the <lm>
         of any <ana>. The first member is the string value of <l>; the second is the
         string value of the code in <m>; the third is a decimal reflecting the derived
         value of @cert whether explicit or implicit); the fourth is the decimal for the
         derived value of @cert2. Members 5-8 preserve the values of generate-id()
         for the <ana>, <lm>, <l>, and <m>, respectively. -->
      <!-- This function was written to support the applications for creating a TAN-A-lm
         file and for calibrating the certainty value. -->
      <xsl:param name="TAN-A-lm-fragment" as="item()*"/>
      <xsl:apply-templates select="$TAN-A-lm-fragment" mode="tan:build-lm-arrays"/>
   </xsl:function>
   
   <xsl:mode name="tan:build-lm-arrays" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:ana" mode="tan:build-lm-arrays">
      <xsl:variable name="context-cert" as="xs:decimal" select="(xs:decimal(@cert), 1.0)[1]"/>
      <xsl:variable name="context-cert2" as="xs:decimal" select="(xs:decimal(@cert2), $context-cert)[1]"/>
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="inherited-cert" select="$context-cert"/>
         <xsl:with-param name="inherited-cert2" select="$context-cert2"/>
         <xsl:with-param name="ana-id" tunnel="yes" select="generate-id(.)"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:lm" mode="tan:build-lm-arrays">
      <xsl:param name="inherited-cert" as="xs:decimal"/>
      <xsl:param name="inherited-cert2" as="xs:decimal"/>
      <xsl:variable name="context-cert" as="xs:decimal" select="(xs:decimal(@cert), 1.0)[1]"/>
      <xsl:variable name="context-cert2" as="xs:decimal" select="(xs:decimal(@cert2), $context-cert)[1]"/>
      <xsl:apply-templates select="tan:l" mode="#current">
         <xsl:with-param name="inherited-cert" select="$context-cert * $inherited-cert"/>
         <xsl:with-param name="inherited-cert2" select="$context-cert2 * $inherited-cert2"/>
         <xsl:with-param name="lm-id" tunnel="yes" select="generate-id(.)"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:l" mode="tan:build-lm-arrays">
      <xsl:param name="inherited-cert" as="xs:decimal"/>
      <xsl:param name="inherited-cert2" as="xs:decimal"/>
      <xsl:variable name="context-cert" as="xs:decimal" select="(xs:decimal(@cert), 1.0)[1]"/>
      <xsl:variable name="context-cert2" as="xs:decimal" select="(xs:decimal(@cert2), $context-cert)[1]"/>
      <xsl:apply-templates select="following-sibling::tan:m" mode="#current">
         <xsl:with-param name="inherited-cert" select="$context-cert * $inherited-cert"/>
         <xsl:with-param name="inherited-cert2" select="$context-cert2 * $inherited-cert2"/>
         <xsl:with-param name="l-id" tunnel="yes" select="generate-id(.)"/>
         <xsl:with-param name="l" select="."/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="tan:m" mode="tan:build-lm-arrays">
      <xsl:param name="inherited-cert" as="xs:decimal"/>
      <xsl:param name="inherited-cert2" as="xs:decimal"/>
      <xsl:param name="ana-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="lm-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="l-id" tunnel="yes" as="xs:string"/>
      <xsl:param name="l" as="xs:string"/>
      <xsl:variable name="context-cert" as="xs:decimal" select="(xs:decimal(@cert), 1.0)[1]"/>
      <xsl:variable name="context-cert2" as="xs:decimal" select="(xs:decimal(@cert2), $context-cert)[1]"/>
      <xsl:sequence select="
            array {
               (string($l), string(.), $context-cert * $inherited-cert, $context-cert2 * $inherited-cert2),
               $ana-id, $lm-id, $l-id, generate-id(.)
            }"/>
   </xsl:template>
   
   
   
   
   <!-- LANGUAGE-SPECIFIC -->
   
   <!-- Greek -->
   
   <xsl:variable name="tan:grc-tokens-without-accents" select="doc('grc-tokens-without-accents.xml')/*/*"/>
   
   <xsl:function name="tan:greek-graves-to-acutes" as="xs:string?" visibility="public">
      <!-- Input: text with Greek -->
      <!-- Output: the same, but with grave accents changed to acutes -->
      <!--kw: language, Greek -->
      <xsl:param name="greek-to-change" as="xs:string?"/>
      <xsl:variable name="this-text-nfkd" select="normalize-unicode($greek-to-change, 'nfkd')"/>
      <xsl:variable name="this-text-fixed" select="replace($this-text-nfkd, '&#x300;', '&#x301;')"/>
      <xsl:sequence select="normalize-unicode($this-text-fixed)"/>
   </xsl:function>
   
   <!-- Syriac -->
   
   <xsl:function name="tan:syriac-marks-to-word-end" as="xs:string?" visibility="public">
      <!-- Input: a string -->
      <!-- Output: the string with Syriac marks placed at the end, in codepoint order -->
      <!-- This function was written to assist in comparing Syriac words that match. Which letter a 
         particular dot is placed should not matter, in most cases. -->
      <!--kw: language, Syriac -->
      <xsl:param name="input-syriac-text" as="xs:string?"/>
      <xsl:variable name="output-parts" as="xs:string*">
         <xsl:analyze-string select="$input-syriac-text" regex="[\p{{L}}\p{{M}}]+">
            <xsl:matching-substring>
               <xsl:variable name="these-marks" select="replace(., '\p{L}+', '')"/>
               <xsl:variable name="these-mark-codepoints-sorted" select="sort(string-to-codepoints($these-marks))"/>
               <xsl:variable name="these-letters" select="replace(., '\p{M}+', '')"/>
               <xsl:value-of select="$these-letters"/>
               <xsl:value-of select="codepoints-to-string($these-mark-codepoints-sorted)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:value-of select="string-join($output-parts)"/>
   </xsl:function>
   
   
   
   


</xsl:stylesheet>
