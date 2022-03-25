<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xhtml="http://www.w3.org/1999/xhtml"
   xmlns:mods="http://www.loc.gov/mods/v3" 
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
   xmlns:oac="http://www.openannotation.org/ns/" 
   xmlns:dcterms="http://purl.org/dc/terms/"
   xmlns:tan="tag:textalign.net,2015:ns" 
   xmlns:foaf="http://xmlns.com/foaf/0.1/" 
   xmlns:cnt="http://www.w3.org/2008/content#"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended search functions. -->

   <xsl:variable name="search-services" select="doc('search-services.xml')" as="document-node()"/>

   <xsl:function name="tan:search-for-scripta" as="item()*" visibility="public">
      <!-- Input: a search expression, an integer indicating the number of records requested -->
      <!-- Output: that number of records using the search expression in the Library of Congress -->
      <!--kw: search, vocabulary -->
      <xsl:param name="search-expression" as="xs:string?"/>
      <xsl:param name="max-records" as="xs:integer"/>
      <!--<xsl:variable name="search-parsed" select=""/>-->
      <xsl:variable name="params" as="element()+">
         <param name="query" value="{encode-for-uri($search-expression)}"/>
         <param name="recordSchema"/>
         <param name="maximumRecords"
            value="{max((1, min(($tan:search-record-maximum, $max-records))))}"/>
      </xsl:variable>
      <xsl:copy-of select="tan:search-for-entities('loc', $params)"/>
   </xsl:function>

   <xsl:function name="tan:search-for-persons" as="item()*" visibility="public">
      <!-- Input: a search expression, an integer indicating the number of records requested -->
      <!-- Output: that number of records using the search expression in the Virtual International Authority File -->
      <!--kw: search, vocabulary -->
      <xsl:param name="search-expression" as="xs:string?"/>
      <xsl:param name="max-records" as="xs:integer"/>
      <xsl:variable name="params" as="element()+">
         <param name="query"
            value="{'cql.any+%3D+%22' || encode-for-uri($search-expression) || '+%22'}"/>
         <param name="recordSchema"/>
         <param name="maximumRecords"
            value="{max((1, min(($tan:search-record-maximum, $max-records))))}"/>
      </xsl:variable>
      <xsl:copy-of select="tan:search-for-entities('viaf', $params)"/>
   </xsl:function>

   <xsl:function name="tan:search-wikipedia" as="item()*" visibility="public">
      <!-- Input: a search expression, an integer indicating the number of records requested -->
      <!-- Output: that number of records using the search expression in Wikipedia -->
      <!--kw: search, vocabulary -->
      <xsl:param name="search-expression" as="xs:string?"/>
      <xsl:param name="max-records" as="xs:integer"/>
      <xsl:variable name="params" as="element()+">
         <param name="search" value="{replace($search-expression,'\s+','+')}"/>
         <param name="limit" value="{max((1, min(($tan:search-record-maximum, $max-records))))}"/>
         <param name="fulltext"/>
      </xsl:variable>
      <xsl:copy-of select="tan:search-for-entities('wikipedia', $params)"/>
   </xsl:function>

   <xsl:function name="tan:search-morpheus" as="document-node()?" visibility="public">
      <!-- Input: a token in Greek or Latin -->
      <!-- Output: lexico-morphological data using Morpheus's service -->
      <!--kw: search, lexicomorphology -->
      <xsl:param name="search-expression" as="xs:string?"/>
      <xsl:variable name="lang-code" as="xs:string">
         <xsl:choose>
            <xsl:when test="matches($search-expression, '[\p{IsGreek}\p{IsGreekExtended}]')"
               >grc</xsl:when>
            <xsl:otherwise>lat</xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="params" as="element()+">
         <param name="lang" value="{$lang-code}"/>
         <param name="engine" value="morpheus{$lang-code}"/>
         <param name="word" value="{$search-expression}"/>
      </xsl:variable>
      <xsl:variable name="morpheus-results" select="tan:search-for-entities('morpheus', $params)"/>
      <xsl:variable name="morpheus-results-norm" as="document-node()?">
         <xsl:choose>
            <xsl:when test="
                  not(some $i in $morpheus-results
                     satisfies tan:item-type($i) = 'document')">
               <xsl:document>
                  <xsl:copy-of select="$morpheus-results"/>
               </xsl:document>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$morpheus-results"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:copy-of select="$morpheus-results-norm"/>
      <!--<xsl:copy-of select="json-to-xml($morpheus-json)"/>-->
   </xsl:function>

   <xsl:function name="tan:search-for-entities" as="item()*" visibility="public">
      <!-- Input: a sequence of strings (search keywords), a string (options: loc), a string (options: marcxml, dc, mods), a positive integer -->
      <!-- Output: up to N records (N = integer parameter) in the protocol of the 3rd paramater, using the SRU protocol of the library catalog specified in the 2nd parameter based on search words in the 1st -->
      <!--kw: search, lexicomorphology -->
      <xsl:param name="server-idref" as="xs:string"/>
      <xsl:param name="params" as="element()+"/>
      <xsl:variable name="server-info" select="$search-services/*/service[name = $server-idref]"/>
      <xsl:variable name="server-url-base" select="$server-info/url-base"/>
      <xsl:variable name="server-params"
         select="$server-info/(param, root()/*/protocol[@xml:id = $server-info/protocol]/param)"/>
      <xsl:variable name="these-params" as="xs:string*">
         <xsl:for-each select="$params">
            <xsl:variable name="this-param-name" select="@name"/>
            <xsl:variable name="this-param-val" select="@value"/>
            <xsl:variable name="this-param-rule" select="$server-params[name = $this-param-name]"/>
            <xsl:choose>
               <xsl:when test="not(exists($this-param-rule))">
                  <xsl:message
                     select="$this-param-name || ' is not an expected parameter for this service'"
                  />
               </xsl:when>
               <xsl:when test="exists($this-param-rule/val[@type = 'regex'])">
                  <!-- cases where the expected input should match a regular expression -->
                  <xsl:choose>
                     <xsl:when test="string-length($this-param-val) lt 1">
                        <xsl:message select="'empty string cannot be evaluated'"/>
                     </xsl:when>
                     <xsl:when test="not(matches($this-param-val, $this-param-rule/val[1]))">
                        <xsl:message
                           select="$this-param-val || ' does not match expression ' || ($this-param-rule/val/@regex)[1]"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="$this-param-name || '=' || $this-param-val"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <xsl:otherwise>
                  <!-- cases where the expected input is meant to match specific options -->
                  <xsl:choose>
                     <xsl:when test="not(exists($this-param-val))">
                        <xsl:value-of
                           select="$this-param-name || '=' || $this-param-rule/val[1]"/>
                     </xsl:when>
                     <xsl:when test="not($this-param-val = $this-param-rule/val)">
                        <xsl:message
                           select="$this-param-val || ' is invalid option; must be: ' || string-join($this-param-rule/val, ', ')"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:value-of select="$this-param-name || '=' || $this-param-val"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="this-search-url"
         select="$server-url-base || string-join($these-params,'&amp;')"/>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:search-for-entities()'"/>
         <xsl:message select="'server info: ', $server-info"/>
         <xsl:message select="'server url base: ', $server-url-base"/>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="not($tan:internet-available)"/>
         <xsl:when test="doc-available($this-search-url)">
            <xsl:message select="'Success: ' || $this-search-url"/>
            <xsl:copy-of select="doc($this-search-url)"/>
         </xsl:when>
         <xsl:when test="unparsed-text-available($this-search-url)">
            <xsl:message
               select="'XML not returned, but unparsed text available from', $this-search-url"/>
            <xsl:copy-of select="unparsed-text($this-search-url)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message select="'Nothing retrieved from ' || $this-search-url"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>

   <xsl:function name="tan:search-results-to-IRI-name-pattern" as="item()*" visibility="public">
      <!-- One-parameter version of the fuller one, below -->
      <xsl:param name="search-results" as="item()*"/>
      <xsl:copy-of select="tan:search-results-to-IRI-name-pattern($search-results, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:search-results-to-IRI-name-pattern" as="item()*" visibility="public">
      <!-- Input: search results from tan:search-for-entities() -->
      <!-- Output: for every entity found, an <item> with <IRI>, <name>, and perhaps <desc> -->
      <!-- Note, this is intended to format results from searches that result in identifiers and descriptions of entities, not claims. -->
      <!--kw: search, vocabulary -->
      <xsl:param name="search-results" as="item()*"/>
      <xsl:param name="format-results" as="xs:boolean"/>
      <xsl:variable name="iri-name-results" as="item()*">
         <xsl:apply-templates select="$search-results/*" mode="tan:get-IRI-name"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$format-results">
            <xsl:text>&#xa;</xsl:text>
            <xsl:comment>Search results</xsl:comment>
            <xsl:text>&#xa;</xsl:text>
            <xsl:for-each select="$iri-name-results">
               <xsl:text>&#xa;</xsl:text>
               <xsl:comment><xsl:text>Result #</xsl:text><xsl:value-of select="position()"/></xsl:comment>
               <xsl:copy-of select="*"/>
               <xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$iri-name-results"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:mode name="tan:get-IRI-name" on-no-match="shallow-skip"/>

   <xsl:template match="xhtml:a | a[@href]" mode="tan:get-IRI-name" priority="2">
      <!-- viaf results yield html in no namespace -->
      <!--<xsl:message>xhtml:a found</xsl:message>
      <xsl:message select="tan:shallow-copy(.)"/>-->
      <xsl:choose>
         <xsl:when test="matches(@href, '/viaf/\d+')">
            <xsl:variable name="possible-desc"
               select="parent::*:td/following-sibling::*:td[@class = 'recAnnotation']"/>
            <item>
               <IRI>
                  <xsl:analyze-string select="@href" regex="/viaf/\d+">
                     <xsl:matching-substring>
                        <xsl:value-of select="'http://viaf.org' || ."/>
                     </xsl:matching-substring>
                  </xsl:analyze-string>
               </IRI>
               <xsl:for-each select="text()[matches(., '\S')]">
                  <name>
                     <xsl:value-of select="normalize-space(normalize-unicode(.))"/>
                  </name>
               </xsl:for-each>
               <xsl:if test="exists($possible-desc)">
                  <desc>
                     <xsl:value-of
                        select="normalize-space(normalize-unicode(string-join(distinct-values($possible-desc//text()), ' ')))"
                     />
                  </desc>
               </xsl:if>
            </item>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:template>
   
   <xsl:template match="mods:mods" mode="tan:get-IRI-name" priority="2">
      <item>
         <xsl:for-each select="mods:identifier[@type = 'lccn']">
            <IRI>
               <xsl:value-of select="'http://lccn.loc.gov/' || ."/>
            </IRI>
         </xsl:for-each>
         <xsl:for-each select="mods:identifier[@type = 'isbn']">
            <xsl:variable name="this-isbn">
               <xsl:analyze-string select="." regex="[\dxX-]+">
                  <xsl:matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:matching-substring>
               </xsl:analyze-string>
            </xsl:variable>
            <IRI>
               <xsl:value-of select="'urn:isbn:' || $this-isbn"/>
            </IRI>
         </xsl:for-each>
         <xsl:variable name="possible-names" as="xs:string*">
            <xsl:for-each select="mods:titleInfo/(self::*, mods:title)">
               <xsl:value-of
                  select="normalize-space(normalize-unicode((string-join(.//text(), ' '))))"/>
            </xsl:for-each>
         </xsl:variable>
         <xsl:for-each select="distinct-values($possible-names)">
            <name>
               <xsl:value-of select="."/>
            </name>
         </xsl:for-each>
         <xsl:variable name="possible-desc"
            select="mods:abstract, mods:tableOfContents, mods:note, mods:subject"/>
         <xsl:if test="exists($possible-desc)">
            <desc>
               <xsl:value-of
                  select="normalize-space(normalize-unicode(string-join(distinct-values($possible-desc//text()), ' ')))"
               />
            </desc>
         </xsl:if>
      </item>

   </xsl:template>
   
   <xsl:template match="ul[@class = 'mw-search-results']/li" mode="tan:get-IRI-name">
      <!-- wikipedia hits -->
      <xsl:variable name="first-best-link" select="(.//a[matches(@href, '/wiki/')])[1]"/>
      <item>
         <IRI>
            <xsl:value-of
               select="'http://dbpedia.org' || replace($first-best-link/@href, '/wiki/', '/resource/')"
            />
         </IRI>
         <name>
            <xsl:value-of select="child::div[1]"/>
         </name>
         <desc>
            <xsl:value-of select="child::div[2]"/>
         </desc>
      </item>
   </xsl:template>


   <xsl:function name="tan:search-results-to-claims" as="item()*" visibility="public">
      <!-- Input: XML representing a search result that is a claim; a string indicating which vendor supplied the results -->
      <!-- Output: the claim represented in TAN elements -->
      <!-- This experimental function, so far only supporting results from tan:search-morpheus() -->
      <!--kw: search, lexicomorphology -->
      <xsl:param name="search-results" as="item()*"/>
      <xsl:param name="results-vendor" as="xs:string"/>
      <xsl:choose>
         <xsl:when test="$results-vendor = ('morpheus', 'perseus')">
            <xsl:apply-templates select="$search-results" mode="tan:claims-morpheus"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message select="'Vendor not supported for these results; try: morpheus'"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:variable name="morpheus-map" as="map(xs:string, xs:string)">
      <xsl:map>
         <xsl:map-entry key="'numeral'" select="'number cardinal'"/>
         <xsl:map-entry key="'verb participle'" select="'verb'"/>
         <xsl:map-entry key="'dative'" select="'case dative'"/>
         <xsl:map-entry key="'genitive'" select="'case genitive'"/>
         <xsl:map-entry key="'vocative'" select="'case vocative'"/>
         <xsl:map-entry key="'active'" select="'voice active'"/>
         <xsl:map-entry key="'middle'" select="'voice middle'"/>
         <xsl:map-entry key="'passive'" select="'voice passive'"/>
         <xsl:map-entry key="'imperative'" select="'verb imperative'"/>
         <xsl:map-entry key="'pluperfect'" select="'tense pluperfect'"/>
         <xsl:map-entry key="'indicative'" select="'mood indicative'"/>
         <xsl:map-entry key="'optative'" select="'mood optative'"/>
         <xsl:map-entry key="'subjunctive'" select="'modality subjunctive'"/>
         <xsl:map-entry key="'masculine/feminine'" select="'gender common'"/>
         <xsl:map-entry key="'irregular'" select="'noun'"/>
         <!-- See the standard features TAN-voc file @ unique for an interesting discussion about the place of particles, and an argument that they should be treated as unique -->
         <xsl:map-entry key="'particle'" select="'unique'"/>
         <xsl:map-entry key="'adverbial'" select="'adjectival adverb'"/>
         <xsl:map-entry key="'ablative'" select="'case ablative'"/>
      </xsl:map>
   </xsl:variable>
   
   
   <xsl:mode name="tan:claims-morpheus" on-no-match="shallow-skip"/>
   <xsl:mode name="tan:claims-morpheus-desc" on-no-match="shallow-skip"/>
   <xsl:mode name="tan:build-morpheus-ana" on-no-match="shallow-skip"/>
   <xsl:mode name="tan:build-morpheus-lex" on-no-match="shallow-skip"/>
   

   <xsl:template match="/*" mode="tan:claims-morpheus">
      <xsl:variable name="this-tok"
         select="replace(oac:Annotation/oac:hasTarget/rdf:Description/@rdf:about, 'urn:word:', '')"/>
      <xsl:variable name="this-agent" select="oac:Annotation/dcterms:creator/foaf:Agent/@rdf:about"/>
      <xsl:variable name="when-returned" select="oac:Annotation/dcterms:created/text()"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode: claims-morpheus'"/>
         <xsl:message select="'this tok: ', $this-tok"/>
         <xsl:message select="'this agent: ', $this-agent"/>
         <xsl:message select="'data returned when: ', $when-returned"/>
      </xsl:if>
      <claims>
         <!-- We use the element name that will appear in the <key>, to expedite processing. -->
         <claimant>
            <algorithm>
               <IRI>
                  <xsl:value-of select="'tag:textalign.net,2015:algorithm:' || $this-agent"/>
               </IRI>
               <name>Tufts morphology service</name>
            </algorithm>
         </claimant>
         <claim-when>
            <xsl:value-of select="$when-returned"/>
         </claim-when>
         <xsl:apply-templates mode="tan:build-morpheus-ana">
            <xsl:with-param name="this-tok" select="$this-tok" tunnel="yes"/>
         </xsl:apply-templates>
         <xsl:apply-templates mode="tan:build-morpheus-lex"/>
      </claims>
   </xsl:template>
   
   <xsl:template match="oac:Body" mode="tan:build-morpheus-ana">
      <xsl:param name="this-tok" tunnel="yes"/>
      <xsl:variable name="this-primary-language" select="cnt:rest/entry/dict/hdwd/@xml:lang"/>
      <xsl:variable name="these-dials" select="cnt:rest/entry/infl/dial"/>
      <xsl:variable name="distinct-dialects" select="
            distinct-values(for $i in $these-dials
            return
               tokenize($i, ' '))"/>
      <xsl:variable name="these-lang-codes" as="xs:string*" select="
            if (exists($distinct-dialects)) then
               for $i in $distinct-dialects
               return
                  string-join(($this-primary-language, $i), '-')
            else
               $this-primary-language"/>
      <xsl:if test="exists($these-lang-codes)">
         <ana>
            <xsl:for-each select="$these-lang-codes">
               <for-lang>
                  <xsl:value-of select="."/>
               </for-lang>
            </xsl:for-each>
            <tok val="{$this-tok}"/>
            <lm>
               <xsl:apply-templates mode="#current"/>
            </lm>
         </ana>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="entry" mode="tan:build-morpheus-ana">
      <xsl:variable name="this-headword" select="dict/hdwd/text()"/>
      <xsl:variable name="this-infl-count" select="count(infl)"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode: build-morpheus-ana'"/>
         <xsl:message select="'this headword: ', $this-headword"/>
      </xsl:if>
      <l>
         <xsl:value-of select="$this-headword"/>
      </l>
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="infl-count" select="$this-infl-count"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="dict" mode="tan:build-morpheus-ana"/>
   <xsl:template match="infl" mode="tan:build-morpheus-ana">
      <xsl:param name="infl-count"/>
      <m>
         <xsl:if test="$infl-count gt 1">
            <xsl:attribute name="cert" select="1 div $infl-count"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </m>
   </xsl:template>

   <xsl:template match="pofs | case | gend | num | mood | tense | voice | comp"
      mode="tan:build-morpheus-ana tan:build-morpheus-lex">
      <xsl:variable name="this-val" select="text()"/>
      <xsl:variable name="has-multiple-vals" select="false()"/>
      <xsl:variable name="these-vals" select="
            if ($has-multiple-vals) then
               tokenize($this-val, ' ')
            else
               $this-val"/>
      <xsl:variable name="these-vals-norm" select="
            for $i in $these-vals
            return
               (map:get($morpheus-map, $i), $i)[1]"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode build-morpheus-ana'"/>
      </xsl:if>
      
      <xsl:for-each select="$these-vals-norm">
         <xsl:variable name="this-atomic-val" select="."/>
         <xsl:variable name="this-feature-vocabulary"
            select="$tan:TAN-feature-vocabulary/tan:TAN-voc/tan:body//tan:item[tan:name = $this-atomic-val]"/>
         <xsl:choose>
            <xsl:when test="exists($this-feature-vocabulary)">
               <feature>
                  <xsl:copy-of select="$this-feature-vocabulary[1]/(* except tan:desc)"/>
               </feature>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message select="'Uncertain meaning of ', ."/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:if test="count($this-feature-vocabulary) gt 1">
            <xsl:message
               select="'Ambiguous meaning of', ., ':', string-join($this-feature-vocabulary/tan:name[1]/text(), ' OR ')"
            />
         </xsl:if>
      </xsl:for-each>
   </xsl:template>

   <xsl:template match="infl" mode="tan:build-morpheus-lex"/>
   <xsl:template match="dict" mode="tan:build-morpheus-lex">
      <lex>
         <xsl:comment>No standard TAN format exists for lexical information</xsl:comment>
         <xsl:apply-templates mode="#current"/>
      </lex>
   </xsl:template>
   
   <xsl:template match="hdwd" mode="tan:build-morpheus-lex">
      <xsl:apply-templates select="@xml:lang" mode="#current"/>
      <headword>
         <xsl:value-of select="."/>
      </headword>
   </xsl:template>
   
   <xsl:template match="@xml:lang" mode="tan:build-morpheus-lex">
      <for-lang>
         <xsl:value-of select="."/>
      </for-lang>
   </xsl:template>


</xsl:stylesheet>
