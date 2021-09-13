<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" exclude-result-prefixes="#all" version="3.0">

   <xsl:function name="tan:resolve-doc" as="document-node()?" visibility="public">
      <!-- One-parameter version of fuller one below -->
      <xsl:param name="TAN-document" as="document-node()?"/>
      <xsl:copy-of select="tan:resolve-doc($TAN-document, true(), ())"/>
   </xsl:function>
   
   <xsl:function name="tan:resolve-doc" as="document-node()?" visibility="public">
      <!-- Input: any TAN document; a boolean indicating whether each element should be stamped with a unique id in @q; attributes that should be added to the root element -->
      <!-- Output: the TAN document, resolved, as explained in the associated loop function below -->
      <!--kw: resolution, files -->
      <xsl:param name="TAN-document" as="document-node()?"/>
      <xsl:param name="add-q-ids" as="xs:boolean"/>
      <xsl:param name="attributes-to-add-to-root-element" as="attribute()*"/>
      <xsl:sequence
         select="tan:resolve-doc-loop($TAN-document, $add-q-ids, $attributes-to-add-to-root-element, (), (), (), (), 0)"
      />
   </xsl:function>
   

   <xsl:function name="tan:get-and-resolve-dependency" as="document-node()*" visibility="private">
      <!-- Input: elements pointing to a dependency, e.g., <source>, <morphology>, <vocabulary> -->
      <!-- Output: documents, if available, minimally resolved and space normalized -->
      <!-- This function was written principally to expedite the processing of class-2 sources -->
      <xsl:param name="TAN-elements" as="element()*"/>
      
      <xsl:apply-templates select="$TAN-elements" mode="tan:get-and-resolve-dependency"/>
      
   </xsl:function>
   
   <xsl:mode name="tan:get-and-resolve-dependency" on-no-match="shallow-skip"/>
   
   <!-- tan:key is retained for older TAN versions -->
   <xsl:template match="tan:source | tan:morphology | tan:vocabulary | tan:key | tan:inclusion" mode="tan:get-and-resolve-dependency">

      <xsl:variable name="this-element-expanded" select="
            if (exists(tan:location)) then
               .
            else
               tan:element-vocabulary(.)/(tan:item, tan:verb)"/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <!-- We intend to imprint in the new document an attribute with the name of the element that invoked it, so that we can easily 
            identify what kind of relationship the dependency enjoys with the dependent. It is so customary to abbreviate "source" 
            as "src" that we make the transition now. -->
      <xsl:variable name="this-name-norm" select="replace($this-element-name, 'source', 'src')"/>
      <xsl:variable name="this-id" select="@xml:id"/>
      <xsl:variable name="this-first-doc" as="document-node()?"
         select="tan:get-1st-doc($this-element-expanded)[1]"/>
      <xsl:variable name="these-attrs-to-stamp" as="attribute()*">
         <xsl:attribute name="{$this-name-norm}"
            select="($this-id, $this-element-expanded/(@xml:id, tan:id), '1')[1]"/>
      </xsl:variable>
      <xsl:variable name="this-source-must-be-adjusted" select="
            ($this-element-name = 'source') and
            exists(following-sibling::tan:adjustments[(self::*, tan:where)/@src[tokenize(., ' ') = ($this-id, '*')]]/(tan:equate, tan:rename, tan:reassign, tan:skip))"/>
      <xsl:variable name="add-q-ids" as="xs:boolean" select="$this-source-must-be-adjusted"/>

      <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="false()"/>

      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Output diagnostics on for tan:get-and-resolve-dependency()'"/>
            <xsl:document>
               <get-and-resolve-dependency>
                  <element-expanded><xsl:copy-of select="$this-element-expanded"/></element-expanded>
                  <element-name-norm><xsl:copy-of select="$this-name-norm"/></element-name-norm>
                  <first-doc><xsl:copy-of select="tan:shallow-copy($this-first-doc/*)"/></first-doc>
                  <attrs-to-stamp><xsl:copy-of select="$these-attrs-to-stamp"/></attrs-to-stamp>
                  <source-must-be-adjusted><xsl:copy-of select="$this-source-must-be-adjusted"/></source-must-be-adjusted>
                  <add-q-ids><xsl:copy-of select="$add-q-ids"/></add-q-ids>
               </get-and-resolve-dependency>
            </xsl:document>
         </xsl:when>
         <xsl:when test="not(exists($this-first-doc))">
            <xsl:sequence select="$tan:empty-doc"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of
               select="tan:normalize-tree-space(tan:resolve-doc($this-first-doc, $add-q-ids, $these-attrs-to-stamp), true())"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:function name="tan:resolve-doc-loop" as="document-node()?" visibility="private" exclude-result-prefixes="#all">
      <!-- Input: any TAN document and a variety of other parameters -->
      <!-- Output: the document resolved according to specifications -->
      <!-- $element-filters is sequence of elements specifying conditions for whether an element should be fetched, e.g.,:
            <filter type="vocabulary">
               <element-name>item</element-name>
               <element-name>verb</element-name>
               <name norm="">vocab name</name>
            </filter>
            <filter inclusion="idref">
                <element-name>license</element-name>
                <element-name>div</element-name>
            </filter>
      -->
      <xsl:param name="TAN-document" as="document-node()?"/>
      <xsl:param name="add-q-ids" as="xs:boolean"/>
      <xsl:param name="attributes-to-add-to-root-element" as="attribute()*"/>
      <xsl:param name="urls-already-visited" as="xs:string*"/>
      <xsl:param name="doc-ids-already-visited" as="xs:string*"/>
      <xsl:param name="relationship-to-prev-doc" as="xs:string?"/>
      <xsl:param name="element-filters" as="element()*"/>
      <xsl:param name="loop-counter" as="xs:integer"/>
      
      <xsl:variable name="this-doc-id" select="$TAN-document/*/@id"/>
      <xsl:variable name="this-doc-base-uri" as="xs:anyURI" select="tan:base-uri($TAN-document)"/>
      <xsl:variable name="this-is-collection-document" as="xs:boolean" select="exists($TAN-document/collection)"/>
      <xsl:variable name="this-is-class-1-source-for-class-2-file" as="xs:boolean" select="
            some $i in $attributes-to-add-to-root-element
               satisfies name($i) eq 'src'"/>
      
      <xsl:choose>
         <xsl:when test="$this-is-collection-document">
            <xsl:apply-templates select="$TAN-document" mode="tan:first-stamp-shallow-copy">
               <xsl:with-param name="add-q-ids" select="$add-q-ids" tunnel="yes"/>
               <xsl:with-param name="root-element-attributes" tunnel="yes"
                  select="$attributes-to-add-to-root-element"/>
               <xsl:with-param name="doc-base-uri" tunnel="yes" select="$this-doc-base-uri"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:when test="(exists($TAN-document/*) and not(namespace-uri($TAN-document/*) = ($tan:TAN-namespace, $tan:TEI-namespace)))">
            <xsl:sequence select="$TAN-document"/>
         </xsl:when>
         <xsl:when test="$loop-counter gt $tan:loop-tolerance">
            <xsl:message select="'tan:resolve-doc-loop-new() has repeated itself more than ', $tan:loop-tolerance, ' times and must halt.'"/>
         </xsl:when>
         <xsl:when test="not(exists($TAN-document/(tan:*, tei:*[@TAN-version], collection)))">
            <xsl:document>
               <xsl:copy-of
                  select="tan:error('lnk07', ('Document requested to be resolved at ' || $this-doc-base-uri 
                  || ' is not a TAN file, but is in the namespace ' || namespace-uri($TAN-document/*)))"
               />
            </xsl:document>
         </xsl:when>
         <xsl:when test="$this-doc-id = $doc-ids-already-visited">
            <xsl:document>
               <xsl:copy-of
                  select="tan:error('inc03', ('The document ' || $this-doc-id || ' may not include, directly or indirectly, another document with that same id.'))"
               />
            </xsl:document>
         </xsl:when>
         <xsl:when test="$this-doc-base-uri = $urls-already-visited">
            <xsl:document>
               <xsl:copy-of
                  select="tan:error('inc03', ('The document at ' || $this-doc-base-uri || ' may not include, directly or indirectly, another document at that same location.'))"
               />
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <!-- If all is well, proceed -->
            
            <!-- Step 1: Stamp root element, resolve @hrefs, convert @xml:id to <id> and include alias names, normalize <name>, 
               insert into <vocabulary> full IRI + name pattern (if missing), add constructed IRI + name patterns for elements that imply them,
               if a TAN-voc file, make sure <item> and <verb> retain <affects-element>, <affects-attribute>, <group>
               if there are element filters, get rid of any element that does not match the filter, but retain a root element and a <head type="vocab"/> to contain vocabulary explaining the elements of interest.
            -->
            <!-- Neither vocabularies nor inclusions are dealt with at this stage. We first need to find out what kinds of filters need to be 
               applied to the vocabularies and inclusions before trying to fetch them. -->

            <!-- Step 1a: resolve <alias> -->
            <xsl:variable name="doc-aliases-resolved" select="tan:resolve-alias($TAN-document/*/tan:head/tan:vocabulary-key/tan:alias)"/>
            
            <!-- Stepb 1b: stamp the document, inserting the resolved aliases as a tunnel parameter -->
            <xsl:variable name="doc-stamped" as="document-node()?">
               <xsl:choose>
                  <xsl:when test="exists($element-filters)">
                     <xsl:apply-templates select="$TAN-document" mode="tan:first-stamp-shallow-skip">
                        <xsl:with-param name="add-q-ids" select="$add-q-ids" tunnel="yes"/>
                        <xsl:with-param name="root-element-attributes" tunnel="yes"
                           select="$attributes-to-add-to-root-element"/>
                        <xsl:with-param name="doc-base-uri" tunnel="yes" select="$this-doc-base-uri"/>
                        <xsl:with-param name="resolved-aliases" tunnel="yes" as="element()*"
                           select="$doc-aliases-resolved"/>
                        <xsl:with-param name="element-filters" as="element()+" tunnel="yes"
                           select="$element-filters"/>
                     </xsl:apply-templates>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates select="$TAN-document" mode="tan:first-stamp-shallow-copy">
                        <xsl:with-param name="add-q-ids" select="$add-q-ids" tunnel="yes"/>
                        <xsl:with-param name="root-element-attributes" tunnel="yes"
                           select="$attributes-to-add-to-root-element"/>
                        <xsl:with-param name="doc-base-uri" tunnel="yes" select="$this-doc-base-uri"/>
                        <xsl:with-param name="resolved-aliases" tunnel="yes" as="element()*"
                           select="$doc-aliases-resolved"/>
                     </xsl:apply-templates>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>


            <!-- Step 2: build element filters for vocabulary and inclusions -->
            <!-- Step 2a: inclusion element filters -->
            <xsl:variable name="elements-with-attr-include"
               select="
                  if (exists($doc-stamped/*/tan:head/tan:inclusion)) then
                     key('tan:elements-with-attrs-named', 'include', $doc-stamped)
                  else
                     ()"
            />
            <xsl:variable name="element-filters-for-inclusions" as="element()*">
               <xsl:for-each-group select="$elements-with-attr-include"
                  group-by="tokenize(@include, '\s+')">
                  <xsl:variable name="this-inclusion" select="current-grouping-key()"/>
                  <xsl:for-each-group select="current-group()" group-by="name(.)">
                     <xsl:if test="exists(current-group()[not(tan:filter)])">
                        <filter type="inclusion" inclusion="{$this-inclusion}">
                           <element-name>
                              <xsl:value-of select="current-grouping-key()"/>
                           </element-name>
                        </filter>
                     </xsl:if>
                     <xsl:for-each select="current-group()/tan:filter">
                        <xsl:copy>
                           <xsl:copy-of select="@*"/>
                           <xsl:attribute name="inclusion" select="$this-inclusion"/>
                           <xsl:copy-of select="*"/>
                        </xsl:copy>
                     </xsl:for-each>
                  </xsl:for-each-group>
               </xsl:for-each-group> 
            </xsl:variable>
            
            <!-- Step 2b: vocabulary element filters -->
            
            <!-- We add @n only if it's a non-dependent class-1 file. Dependent class-1 files (i.e., sources of class-2 files)
            will have ALL their @n vocabulary retrieved, because a class-2 file needs to be able to access the entire library of
            synonyms. -->
            <xsl:variable name="names-of-attributes-that-take-vocab-based-aliases" as="xs:string*"
               select="
                  if (exists($TAN-document/(tei:TEI | tan:TAN-T)/tan:head/tan:vocabulary) and not($this-is-class-1-source-for-class-2-file)) then
                     'n'
                  else
                     ()"
            />
            <xsl:variable name="attributes-that-take-vocabulary" select="key('tan:attrs-by-name', ($tan:names-of-attributes-that-take-idrefs, 'which', $names-of-attributes-that-take-vocab-based-aliases), $doc-stamped)"/>
            <xsl:variable name="attributes-that-take-vocab-based-aliases"
               select="$attributes-that-take-vocabulary[name(.) = $names-of-attributes-that-take-vocab-based-aliases]"
            />
            
            <xsl:variable name="element-filters-for-vocabularies-pass-1" as="element()*">
               <xsl:for-each-group select="$attributes-that-take-vocabulary except $attributes-that-take-vocab-based-aliases" 
                  group-by="name(.)">
                  <xsl:variable name="this-attr-name" as="xs:string" select="current-grouping-key()"/>
                  <xsl:variable name="is-attr-which" as="xs:boolean" select="$this-attr-name eq 'which'"/>
                  <xsl:choose>
                     <xsl:when test="$is-attr-which">
                        <xsl:for-each-group select="current-group()" group-by="name(..)">
                           <xsl:variable name="this-parent-name" select="current-grouping-key()"/>
                           <xsl:for-each-group select="current-group()"
                              group-by="tan:normalize-name(.)">
                              <xsl:variable name="this-val" select="current-grouping-key()"/>
                              <filter type="vocabulary">
                                 <element-name>
                                    <xsl:value-of select="$this-parent-name"/>
                                 </element-name>
                                 <name norm="">
                                    <xsl:value-of select="$this-val"/>
                                 </name>
                                 <xsl:copy-of select="current-group()/../(tan:id, tan:alias)"/>
                              </filter>
                           </xsl:for-each-group>
                        </xsl:for-each-group>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:variable name="target-element-names" as="xs:string*"
                           select="tan:target-element-names(current-grouping-key())"/>
                        <xsl:for-each-group select="current-group()" group-by="tokenize(., '\s+')">
                           <xsl:variable name="this-val" select="current-grouping-key()"/>
                           <filter type="vocabulary">
                              <xsl:for-each select="$target-element-names">
                                 <element-name>
                                    <xsl:value-of select="."/>
                                 </element-name>
                              </xsl:for-each>
                              <idref>
                                 <xsl:value-of select="$this-val"/>
                              </idref>
                              <xsl:if test="not($this-val eq '*')">
                                 <name norm="">
                                    <xsl:value-of select="tan:normalize-name($this-val)"/>
                                 </name>
                              </xsl:if>
                           </filter>
                        </xsl:for-each-group> 
                        
                     </xsl:otherwise>
                  </xsl:choose>
                  
               </xsl:for-each-group>
            </xsl:variable>
            
            <xsl:variable name="vocabulary-heads"
               select="$doc-stamped/*/tan:head, $doc-stamped/(tan:TAN-voc, tan:TAN-A)/tan:body"
               as="element()*"/>
            <xsl:variable name="element-filters-for-vocabularies-pass-2" as="element()*">
               <!-- tan:distinct-items($element-filters-for-vocabularies-pass-1) -->
               <xsl:for-each select="$element-filters-for-vocabularies-pass-1">
                  <xsl:variable name="these-element-names" select="tan:element-name"/>
                  <xsl:variable name="these-name-vals" select="tan:name"/>
                  <xsl:variable name="these-idref-vals" select="tan:idref"/>

                  <!-- A local vocabulary item overrides any TAN defaults, but it must not be pointing elsewhere -->
                  <xsl:variable name="local-vocab-item-candidates"
                     select="
                        $doc-stamped/*/tan:head/(self::* | tan:vocabulary-key)/*[not(@which)][name(.) = $these-element-names]"
                  />
                  <xsl:variable name="local-tan-a-claims"
                     select="
                        if ($these-element-names = 'claim') then
                           $doc-stamped/tan:TAN-A/tan:body//tan:claim
                        else
                           ()"
                  />
                  <xsl:variable name="local-tan-voc-items" select="$doc-stamped/tan:TAN-voc/tan:body//*[(name(.), tan:affects-element) = $these-element-names]"/>
                  <xsl:variable name="local-resolved-vocab-item-matches"
                     select="
                        $local-vocab-item-candidates[tan:IRI or @pattern][((tan:id, tan:alias) = $these-idref-vals)],
                        $local-tan-a-claims[((tan:id, tan:alias) = $these-idref-vals)],
                        $local-tan-voc-items[(tan:name = $these-name-vals)]"
                  />
                  <xsl:if test="not(exists($local-resolved-vocab-item-matches))">
                     <xsl:copy-of select="."/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="attribute-filters-for-vocabularies" as="element()*">
               <xsl:for-each-group select="$attributes-that-take-vocab-based-aliases" group-by="name(.)">
                  <xsl:variable name="this-attr-name" select="current-grouping-key()"/>
                  <xsl:for-each-group select="current-group()" group-by="tokenize(., '\s+')">
                     <xsl:variable name="this-val" select="current-grouping-key()"/>
                     <filter type="vocabulary">
                        <attribute-name>
                           <xsl:value-of select="$this-attr-name"/>
                        </attribute-name>
                        <!-- Because we are looking only for aliases in attribute values, we do not
                        have idrefs, as with element filters, only values to correspond to vocabulary
                        names -->
                        <name norm="">
                           <xsl:value-of select="tan:normalize-name($this-val)"/>
                        </name>
                     </filter>
                  </xsl:for-each-group> 
               </xsl:for-each-group>
               <!-- We add all possible n-vocabulary items for class-1 sources of class-2 files, because an
                  adjustment action might push a particular <div> into a value of @n not anticipated by the 
                  source. Plus, some class-1 sources are so large, it's not worth fetching every value of @n
                  from the body to filter out the vocabulary.
               -->
               <xsl:if test="$this-is-class-1-source-for-class-2-file">
                  <filter type="vocabulary">
                     <attribute-name>n</attribute-name>
                     <name norm="">*</name>
                  </filter>
               </xsl:if>
            </xsl:variable>


            <!-- Step 3. Selectively resolve each vocabulary and inclusion, the two most critical dependencies -->
            
            <!-- Although <vocabulary> and <inclusion> behave differently in their host file, they
               are extracted by the same process: the host file queries another TAN file and asks for 
               only a subset of its elements. Hence, neither one has priority over the other, because they are 
               part of the same process; it also means that errors of circular reference make no distinction 
               between inclusions and vocabularies.
            -->
            <xsl:variable name="doc-with-critical-dependencies-resolved" as="document-node()?">
               <xsl:apply-templates select="$doc-stamped" mode="tan:resolve-critical-dependencies-loop">
                  <xsl:with-param name="inclusion-element-filters" tunnel="yes"
                     select="$element-filters-for-inclusions"/>
                  <xsl:with-param name="vocabulary-element-filters" tunnel="yes"
                     select="$element-filters-for-vocabularies-pass-2"/>
                  <xsl:with-param name="vocabulary-attribute-filters" tunnel="yes"
                     select="$attribute-filters-for-vocabularies"/>
                  <xsl:with-param name="doc-id" tunnel="yes" select="$this-doc-id"/>
                  <xsl:with-param name="doc-ids-already-visited" tunnel="yes" select="$doc-ids-already-visited"/>
                  <xsl:with-param name="doc-base-uri" tunnel="yes" select="$this-doc-base-uri"/>
                  <xsl:with-param name="urls-already-visited" as="xs:string*" tunnel="yes" select="$urls-already-visited"/>
                  <xsl:with-param name="loop-counter" tunnel="yes" as="xs:integer" select="$loop-counter"/>
               </xsl:apply-templates>
            </xsl:variable>


            <!-- Step 4: embed within every *[@include] the substitutes from the appropriate <include>; 
               strip away from every <inclusion>'s <TAN-*> element anything that is not a vocabulary item, or an <inclusion>;
               reduce vocabulary elements
            -->
            <xsl:variable name="imprinted-inclusions" select="$doc-with-critical-dependencies-resolved/*/tan:head/tan:inclusion"/>
            <xsl:variable name="doc-with-inclusions-applied-and-vocabulary-adjusted" as="document-node()?">
               <xsl:apply-templates select="$doc-with-critical-dependencies-resolved" mode="tan:apply-inclusions-and-adjust-vocabulary">
                  <xsl:with-param name="imprinted-inclusions" select="$imprinted-inclusions" tunnel="yes"/>
                  <xsl:with-param name="element-filters" tunnel="yes" select="$element-filters-for-inclusions"/>
                  <xsl:with-param name="vocabulary-element-filters" tunnel="yes"
                     select="$element-filters-for-vocabularies-pass-2"/>
                  <xsl:with-param name="vocabulary-attribute-filters" tunnel="yes"
                     select="$attribute-filters-for-vocabularies"/>
               </xsl:apply-templates>
            </xsl:variable>
            

            <!-- Step 5. convert numerals to Arabic -->
            <xsl:variable name="doc-with-n-and-ref-converted" as="document-node()">
               <xsl:choose>
                  <xsl:when test="tan:class-number($doc-with-inclusions-applied-and-vocabulary-adjusted) = 1">
                     <xsl:apply-templates select="$doc-with-inclusions-applied-and-vocabulary-adjusted"
                        mode="tan:resolve-numerals"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="$doc-with-inclusions-applied-and-vocabulary-adjusted"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            
            
            <xsl:variable name="diagnostics-on" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Diagnostics on, tan:resolve-doc-loop()'"/>
               <xsl:message select="'add @q ids?', $add-q-ids"/>
               <xsl:message select="'attributes to add to root element:', $attributes-to-add-to-root-element"/>
               <xsl:message select="'urls already visited:', $urls-already-visited"/>
               <xsl:message select="'doc ids already visited:', $doc-ids-already-visited"/>
               <xsl:message select="'relationship to previous doc:', $relationship-to-prev-doc"/>
               <xsl:message select="'Inbound element filters:', $element-filters"/>
               <xsl:message select="'loop counter:', $loop-counter"/>
               <xsl:message select="'Doc stamped: ', $doc-stamped"/>
               <xsl:message select="'Outbound element filters for inclusions:', $element-filters-for-inclusions"/>
               <xsl:message select="'Outbound element filters for vocabularies pass 1:', $element-filters-for-vocabularies-pass-1"/>
               <xsl:message select="'Outbound element filters for vocabularies pass 2:', $element-filters-for-vocabularies-pass-2"/>
               <xsl:message select="'Doc with inclusions applied and vocabulary adjusted: ', $doc-with-inclusions-applied-and-vocabulary-adjusted"/>
               <xsl:message select="'Doc with n and ref converted', $doc-with-n-and-ref-converted"/>
            </xsl:if>

            <xsl:choose>
               <xsl:when test="false()">
                  <!-- For hard diagnostics -->
                  <xsl:message
                     select="'Replacing output of tan:resolve-doc() with diagnostic content'"/>
                  <xsl:document>
                     <diagnostics>
                        <doc-stamped><xsl:copy-of select="$doc-stamped"/></doc-stamped>
                        <elements-with-attr-include><xsl:copy-of select="$elements-with-attr-include"/></elements-with-attr-include>
                        <element-filters-incl><xsl:copy-of select="$element-filters-for-inclusions"/></element-filters-incl>
                        <attrs-that-take-vocab count="{count($attributes-that-take-vocabulary)}">
                           <xsl:for-each-group select="$attributes-that-take-vocabulary" group-by="name(.)">
                              <group count="{count(current-group())}"><xsl:value-of select="current-grouping-key()"/></group>
                           </xsl:for-each-group> 
                        </attrs-that-take-vocab>
                        <element-filters-vocab-1><xsl:copy-of select="$element-filters-for-vocabularies-pass-1"/></element-filters-vocab-1>
                        <element-filters-vocab-2><xsl:copy-of select="$element-filters-for-vocabularies-pass-2"/></element-filters-vocab-2>
                        <attribute-filters-vocab><xsl:copy-of select="$attribute-filters-for-vocabularies"/></attribute-filters-vocab>
                        <element-filters-for-inclusions><xsl:copy-of select="$element-filters-for-inclusions"/></element-filters-for-inclusions>
                        <doc-and-crit-dep-resolved><xsl:copy-of select="$doc-with-critical-dependencies-resolved"/></doc-and-crit-dep-resolved>
                        <doc-and-inclusions-applied-and-vocabulary-adjusted><xsl:copy-of select="$doc-with-inclusions-applied-and-vocabulary-adjusted"/></doc-and-inclusions-applied-and-vocabulary-adjusted>
                        <doc-with-n-and-ref-converted><xsl:copy-of select="$doc-with-n-and-ref-converted"/></doc-with-n-and-ref-converted>
                     </diagnostics>
                  </xsl:document>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="$doc-with-n-and-ref-converted"/>
               </xsl:otherwise>
            </xsl:choose>
            
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>


   <!-- Resolving, step 1 templates, functions -->
   
   <xsl:function name="tan:resolve-alias" as="element()*" visibility="private">
      <!-- Input: one or more <alias>es -->
      <!-- Output: those elements with children <idref>, each containing a single value that the alias stands for -->
      <!-- It is assumed that <alias>es are still embedded in an XML structure that allows one to reference sibling <alias>es -->
      <!-- Note, this function only resolves idrefs, but does not check to see if they target anything -->
      <xsl:param name="aliases" as="element()*"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:resolve-alias()'"/>
      </xsl:if>
      <xsl:for-each select="$aliases">
         <xsl:variable name="other-aliases" select="../tan:alias"/>
         <xsl:variable name="this-id" select="(@xml:id, @id)[1]"/>
         <xsl:variable name="these-idrefs" select="tokenize(normalize-space(@idrefs), ' ')"/>
         <xsl:variable name="this-alias-check"
            select="tan:resolve-alias-loop($these-idrefs, $this-id, $other-aliases, 0)"/>
         <xsl:if test="$diagnostics-on">
            <xsl:message select="'this alias: ', ."/>
            <xsl:message select="'this alias checked: ', $this-alias-check"/>
         </xsl:if>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <alias>
               <xsl:value-of select="$this-id"/>
            </alias>
            <xsl:copy-of select="$this-alias-check"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:resolve-alias-loop" as="element()*" visibility="private">
      <!-- Function associated with the master one, above; returns only <id-ref> and <error> children -->
      <xsl:param name="idrefs-to-process" as="xs:string*"/>
      <xsl:param name="alias-ids-already-processed" as="xs:string*"/>
      <xsl:param name="other-aliases" as="element()*"/>
      <xsl:param name="loop-counter" as="xs:integer"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:resolve-alias-loop()'"/>
         <xsl:message select="'loop number: ', $loop-counter"/>
         <xsl:message select="'idrefs to process: ', $idrefs-to-process"/>
         <xsl:message select="'alias ids already processed: ', $alias-ids-already-processed"/>
         <xsl:message select="'other aliases: ', $other-aliases"/>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="count($idrefs-to-process) lt 1"/>
         <xsl:when test="$loop-counter gt $tan:loop-tolerance">
            <xsl:message select="'loop exceeds tolerance'"/>
            <xsl:copy-of select="$other-aliases"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="next-idref" select="$idrefs-to-process[1]"/>
            <xsl:variable name="next-idref-norm" select="tan:help-extracted($next-idref)"/>
            <xsl:variable name="other-alias-picked"
               select="$other-aliases[(@xml:id, @id) = $next-idref-norm]" as="element()?"/>
            <xsl:choose>
               <xsl:when test="$next-idref-norm = $alias-ids-already-processed">
                  <xsl:copy-of select="tan:error('tan14')"/>
                  <xsl:copy-of
                     select="tan:resolve-alias-loop($idrefs-to-process[position() gt 1], $alias-ids-already-processed, $other-aliases, $loop-counter + 1)"
                  />
               </xsl:when>
               <xsl:when test="exists($other-alias-picked)">
                  <xsl:variable name="new-idrefs"
                     select="tokenize(normalize-space($other-alias-picked/@idrefs), ' ')"/>
                  <xsl:copy-of
                     select="tan:resolve-alias-loop(($new-idrefs, $idrefs-to-process[position() gt 1]), ($alias-ids-already-processed, $next-idref-norm), $other-aliases, $loop-counter + 1)"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <idref>
                     <xsl:copy-of select="$next-idref-norm/@help"/>
                     <xsl:value-of select="$next-idref-norm"/>
                  </idref>
                  <xsl:copy-of
                     select="tan:resolve-alias-loop($idrefs-to-process[position() gt 1], $alias-ids-already-processed, $other-aliases, $loop-counter + 1)"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:mode name="tan:first-stamp-shallow-skip" on-no-match="shallow-skip"/>
   <xsl:mode name="tan:first-stamp-shallow-copy" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:resolve-href" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:expand-standard-tan-voc" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:resolve-critical-dependencies-loop" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:apply-inclusions-and-adjust-vocabulary" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:resolve-numerals" on-no-match="shallow-copy"/>
   
   <xsl:template match="/" mode="tan:first-stamp-shallow-skip">
      <xsl:document>
         <xsl:apply-templates mode="#current"/>
      </xsl:document>
   </xsl:template>
   
   <xsl:template match="*" mode="tan:first-stamp-shallow-skip">
      <xsl:param name="element-filters" as="element()+" tunnel="yes"/>
      
      <xsl:variable name="this-attr-include" select="@include"/>
      <xsl:variable name="these-affects-elements" select="self::tan:item/ancestor-or-self::*[@affects-element][1]/@affects-element"/>
      <xsl:variable name="these-affects-attributes" select="self::tan:item/ancestor-or-self::*[@affects-attribute][1]/@affects-attribute"/>
      <xsl:variable name="these-element-names" as="xs:string+" select="name(.), tokenize($these-affects-elements, '\s+')"/>
      <xsl:variable name="these-attribute-names" as="xs:string*" select="tokenize($these-affects-attributes, '\s+')"/>
      <xsl:variable name="these-normalized-name-children"
         select="
            for $i in tan:name
            return
               tan:normalize-name($i)"
      />
      <xsl:variable name="matching-element-filters" as="element()*">
         <xsl:for-each select="$element-filters">
            <xsl:choose>
               <!-- Ignore element filters that do not correspond to the element or attribute name -->
               <xsl:when test="not(tan:element-name = $these-element-names) and not(tan:attribute-name = $these-attribute-names)"/>
               <!-- Ignore element filters that do not have a <name> element; these sometimes happen in
                  the course of building a joker element filter, but in those cases it's only an idref that
                  can match, not a name. -->
               <xsl:when test="@type eq 'vocabulary' and not(exists(tan:name))"/>
               <!-- If the filter is asking for everything that matches a given element or attribute, then return it. -->
               <xsl:when test="tan:name = '*'">
                  <xsl:sequence select="."/>
               </xsl:when>
               <xsl:when test="
                     @type eq 'vocabulary' and
                     not(tan:name = $these-normalized-name-children)
                     and not(exists($this-attr-include))"/>
               <xsl:otherwise>
                  <xsl:sequence select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each>
         <xsl:if test="exists($this-attr-include)">
            <filter type="inclusion" inclusion="{$this-attr-include}">
               <element-name>
                  <xsl:value-of select="name(.)"/>
               </element-name>
            </filter>
         </xsl:if>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode first-stamp-shallow-skip'"/>
         <xsl:message select="'This element (shallow): ', tan:shallow-copy(., 3)"/>
         <xsl:message select="'These element names:', $these-element-names"/>
         <xsl:message select="'Element filters: ', $element-filters"/>
         <xsl:message select="'Exist matching element filters? ', exists($matching-element-filters)"/>
         <xsl:message select="'Matching element filters: ', $matching-element-filters"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="exists($matching-element-filters)">
            <xsl:apply-templates select="." mode="tan:first-stamp-shallow-copy">
               <!-- When building the vocabulary filter, we pushed ahead the <id> and <alias> values, so they could be
                  inserted into the relevant full vocabulary item
               -->
               <xsl:with-param name="children-to-append" select="$matching-element-filters/(tan:id, tan:alias)"/>
               <xsl:with-param name="inclusion-filters" select="$matching-element-filters"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates mode="#current"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="tan:head" mode="tan:first-stamp-shallow-skip">
      <xsl:param name="element-filters" as="element()+" tunnel="yes"/>
      <!-- When resolving only part of a document (i.e. fetching only select elements), we still need access to the entire file's vocabulary. -->
      <!-- This template prepares a special container for the vocabulary -->
      <xsl:variable name="this-is-inclusion-search" select="exists($element-filters/@inclusion)"/>
      <!-- If it is not an inclusion search (i.e., if it is a vocabulary search, which targets the body of a tan:TAN-voc file), we skip the head altogether -->
      <xsl:choose>
         <xsl:when test="$this-is-inclusion-search">
            <head vocabulary="">
               <!-- keep a copy of the current head -->
               <xsl:apply-templates mode="tan:first-stamp-shallow-copy"/>
               <!-- we must be certain to retain vocabulary items that are allowed in the body. -->
               <xsl:apply-templates select="parent::tan:TAN-A/tan:body//tan:claim[@xml:id]"
                  mode="tan:first-stamp-shallow-copy"/>
               <xsl:apply-templates select="parent::tan:TAN-voc/tan:body//(tan:item, tan:verb)"
                  mode="tan:first-stamp-shallow-copy"/>
            </head>
            <!-- With the special head in place, we can now continue shallow skipping, looking for desired elements, provided
               that the filters are calling for elements to include. If this file is being searched purely for vocabulary, then the body,
               not the head, is of primary interest.
            -->
            <xsl:apply-templates mode="#current"/>
         </xsl:when>
         <xsl:when test="exists(tan:inclusion)">
            <!-- A file being fetched qua vocabulary might have inclusions that need to play a factor -->
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates select="tan:inclusion" mode="tan:first-stamp-shallow-copy"/>
            </xsl:copy>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   
   <!-- The following template works for both modes on the root element, because even with shallow skipping, we at least want a root element, so the document is well formed -->
   <xsl:template match="/*" mode="tan:first-stamp-shallow-skip tan:first-stamp-shallow-copy tan:resolve-href">
      <xsl:param name="add-q-ids" as="xs:boolean" tunnel="yes"/>
      <xsl:param name="root-element-attributes" as="attribute()*" tunnel="yes"/>
      <xsl:param name="doc-base-uri" tunnel="yes"/>
      
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$root-element-attributes"/>
         <xsl:if test="not(exists(@xml:base))">
            <xsl:attribute name="xml:base" select="$doc-base-uri"/>
         </xsl:if>
         <xsl:if test="$add-q-ids">
            <xsl:attribute name="q" select="generate-id(.)"/>
         </xsl:if>
         <stamped/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      
   </xsl:template>
   
   <xsl:template match="/*" mode="tan:expand-standard-tan-voc">
      <xsl:variable name="this-base-uri" select="base-uri(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="xml:base" select="$this-base-uri"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="base-uri" tunnel="yes" select="$this-base-uri"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:body" mode="tan:expand-standard-tan-voc">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="affects" as="element()*" tunnel="yes">
               <xsl:for-each select="@affects-element">
                  <affects-element>
                     <xsl:value-of select="."/>
                  </affects-element>
               </xsl:for-each>
               <xsl:for-each select="@affects-attribute">
                  <affects-attribute>
                     <xsl:value-of select="."/>
                  </affects-attribute>
               </xsl:for-each>
            </xsl:with-param>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:item | tan:verb" mode="tan:expand-standard-tan-voc">
      <xsl:param name="affects" as="element()*" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$affects"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <!-- templates for retaining, stamping elements of interest -->
   <xsl:template match="processing-instruction()" mode="tan:resolve-href tan:first-stamp-shallow-copy">
      <xsl:param name="base-uri" as="xs:anyURI?" tunnel="yes"/>
      <xsl:variable name="this-base-uri"
         select="
            if (exists($base-uri)) then
               $base-uri
            else
               tan:base-uri(.)"/>
      <xsl:variable name="href-regex" as="xs:string">(href=['"])([^'"]+)(['"])</xsl:variable>
      <xsl:processing-instruction name="{name(.)}">
            <xsl:analyze-string select="." regex="{$href-regex}">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1) || resolve-uri(regex-group(2), $this-base-uri) || regex-group(3)"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:processing-instruction>
   </xsl:template>
   
   <xsl:template match="*" mode="tan:first-stamp-shallow-copy">
      <xsl:param name="add-q-ids" as="xs:boolean" tunnel="yes"/>
      <xsl:param name="doc-base-uri" tunnel="yes"/>
      <xsl:param name="resolved-aliases" tunnel="yes" as="element()*"/>
      <xsl:param name="children-to-append" as="element()*"/>
      <xsl:param name="inclusion-filters" as="element()*"/>

      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:variable name="this-href" select="@href"/>
      <xsl:variable name="this-id" as="xs:string?" select="(@xml:id, @id)[1]"/>
      <xsl:variable name="copy-id-to-element" as="xs:boolean" select="exists(self::tan:*)"/>
      
      <!-- Some elements are the kind that would be suited to IRI + name patterns, but don't need them because
      of native conventions used within the attributes. For those elements, we construct an IRI + name pattern,
      to facilitate vocabulary searches. -->
      <xsl:variable name="elements-to-insert" as="element()*">
         <xsl:choose>
            <xsl:when test="self::tan:period">
               <IRI>
                  <xsl:value-of select="'tag:textalign.net,2015:ns:period:from' || @from || ':to' || @to"/>
               </IRI>
               <name>
                  <xsl:value-of select="'From ' || @from || ' to ' || @to"/>
               </name>
            </xsl:when>
            <xsl:when test="self::tan:item[ancestor::tan:TAN-voc][tan:name]">
               <!-- If it's a vocab item of a TAN-voc file, imprint any @xml:ids found in the <vocabulary-key> -->
               <xsl:variable name="these-names-normalized" select="tan:normalize-name(tan:name)"/>
               <xsl:variable name="this-vocabulary-key"
                  select="root(.)/tan:TAN-voc/tan:head/tan:vocabulary-key"/>
               <xsl:variable name="matching-vocab-items"
                  select="$this-vocabulary-key/*[tan:normalize-name(@which) = $these-names-normalized]"/>
               <xsl:if test="exists($matching-vocab-items/@xml:id)">
                  <id>
                     <xsl:value-of select="$matching-vocab-items/@xml:id"/>
                  </id>
               </xsl:if>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@* except @href"/>
         <xsl:if test="$add-q-ids">
            <xsl:attribute name="q" select="generate-id(.)"/>
         </xsl:if>
         <xsl:if test="exists($this-href)">
            <xsl:variable name="revised-href"
               select="
                  if (tan:is-valid-uri($this-href)) then
                     resolve-uri($this-href, $doc-base-uri)
                  else
                     ()"
            />
            <xsl:attribute name="href" select="$revised-href"/>
            <xsl:if test="not($this-href eq $revised-href)">
               <xsl:attribute name="orig-href" select="@href"/>
            </xsl:if>
            <!-- Division point between attributes (above) and elements (below) -->
            <xsl:if test="$revised-href eq $doc-base-uri">
               <xsl:copy-of select="tan:error('tan17')"/>
            </xsl:if>
         </xsl:if>
         <xsl:if test="string-length($this-id) gt 0 and $copy-id-to-element">
            <xsl:variable name="matching-aliases" select="$resolved-aliases[tan:idref = $this-id]"/>
            <id>
               <xsl:value-of select="$this-id"/>
            </id>
            <xsl:copy-of select="$matching-aliases/tan:alias"/>
         </xsl:if>
         <xsl:if test="$this-element-name = ('item', 'verb')">
            <xsl:variable name="attributes-of-interest"
               select="
                  self::tan:item/ancestor-or-self::*[@affects-element][1]/@affects-element,
                  self::tan:item/ancestor-or-self::*[@affects-attribute][1]/@affects-attribute,
                  ancestor::tan:group[1]/@type"/>
            <xsl:for-each select="$attributes-of-interest">
               <xsl:variable name="this-attr-name" select="name(.)"/>
               <xsl:for-each select="tokenize(., '\s+')">
                  <xsl:element name="{$this-attr-name}">
                     <xsl:value-of select="."/>
                  </xsl:element>
               </xsl:for-each>
            </xsl:for-each>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
         <xsl:copy-of select="$elements-to-insert"/>
         <xsl:copy-of select="$children-to-append"/>
         <!-- An inclusion filter here will make sure that only certain elements get copied during the inclusion process -->
         <xsl:if test="exists(@include)">
            <xsl:copy-of select="$inclusion-filters"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   <!-- We add tan:head to the match pattern below to avoid catching collection files -->
   <xsl:template match="tan:head/tan:vocabulary[@which]" mode="tan:first-stamp-shallow-copy">
      <xsl:param name="add-q-ids" as="xs:boolean" tunnel="yes"/>
      <xsl:variable name="this-which-norm" select="tan:normalize-name(@which)"/>
      <xsl:variable name="this-item"
         select="$tan:TAN-vocabularies/tan:TAN-voc/tan:body[@affects-element = 'vocabulary']/tan:item[tan:name = $this-which-norm]"/>
      <xsl:copy>
         <!-- We drop @which because this is a special, immediate substitution -->
         <xsl:copy-of select="@* except @which"/>
         <xsl:if test="$add-q-ids">
            <xsl:attribute name="q" select="generate-id(.)"/>
         </xsl:if>
         <xsl:copy-of select="$this-item/*"/>
         <xsl:if test="not(exists($this-item))">
            <xsl:copy-of select="tan:error('whi04')"/>
            <xsl:copy-of select="tan:error('whi05')"/>
         </xsl:if>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:name" mode="tan:first-stamp-shallow-copy">
      <xsl:param name="add-q-ids" as="xs:boolean" tunnel="yes"/>
      
      <xsl:variable name="this-name" select="text()"/>
      <xsl:variable name="this-name-normalized" select="tan:normalize-name($this-name)"/>
      
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:if test="$add-q-ids">
            <xsl:attribute name="q" select="generate-id(.)"/>
         </xsl:if>
         <xsl:value-of select="."/>
      </xsl:copy>
      <xsl:if test="not($this-name = $this-name-normalized)">
         <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <!-- we add a normalized form (marked by @norm) to accelerate name checking -->
            <xsl:attribute name="norm"/>
            <xsl:value-of select="$this-name-normalized"/>
         </xsl:copy>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tan:alias" mode="tan:first-stamp-shallow-copy">
      <xsl:param name="add-q-ids" as="xs:boolean" tunnel="yes"/>
      <xsl:param name="resolved-aliases" tunnel="yes" as="element()*"/>
      <xsl:variable name="this-id" select="(@xml:id, @id)[1]"/>
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:if test="$add-q-ids">
            <xsl:attribute name="q" select="generate-id(.)"/>
         </xsl:if>
         <xsl:copy-of select="$resolved-aliases[tan:alias = $this-id]/*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   <!-- Resolving, step 2 templates: gets handled in the function -->

   
   <!-- Resolving, step 3 templates -->

   <xsl:template match="tan:inclusion[tan:location] | tan:vocabulary[tan:location]" mode="tan:resolve-critical-dependencies-loop">
      <xsl:param name="inclusion-element-filters" tunnel="yes"/>
      <xsl:param name="vocabulary-element-filters" tunnel="yes"/>
      <xsl:param name="vocabulary-attribute-filters" tunnel="yes"/>
      <xsl:param name="doc-id" tunnel="yes"/>
      <xsl:param name="doc-ids-already-visited" as="xs:string*" tunnel="yes"/>
      <xsl:param name="doc-base-uri" tunnel="yes"/>
      <xsl:param name="urls-already-visited" as="xs:string*" tunnel="yes"/>
      <xsl:param name="loop-counter" tunnel="yes" as="xs:integer"/>
      
      <xsl:variable name="is-inclusion" as="xs:boolean" select="name(.) eq 'inclusion'"/>
      <xsl:variable name="this-id" as="xs:string?" select="@xml:id"/>
      <xsl:variable name="first-doc-available" as="document-node()?" select="tan:get-1st-doc(.)"/>
      <xsl:variable name="first-doc-base-uri" select="tan:base-uri($first-doc-available)"/>
      
      <xsl:variable name="filters-chosen"
         select="
            if ($is-inclusion) then
               $inclusion-element-filters[@inclusion eq $this-id]
            else
               ($vocabulary-element-filters, $vocabulary-attribute-filters)"
      />
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode resolve-critical-dependencies'"/>
         <xsl:message select="'This inclusion/vocabulary:', ."/>
         <xsl:message select="'This doc id:', string($doc-id)"/>
         <xsl:message select="'Doc ids already visited:', $doc-ids-already-visited"/>
         <xsl:message select="'This doc base uri:', $doc-base-uri"/>
         <xsl:message select="'URLs previously visited:', $urls-already-visited"/>
         <xsl:message select="'Loop counter:', $loop-counter"/>
         <xsl:message
            select="'First inclusion/vocabulary doc available (shallow):', tan:shallow-copy($first-doc-available/*)"
         />
         <xsl:message select="'First doc available base uri:', $first-doc-base-uri"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:choose>
            <!-- If an inclusion isn't invoked with @include then there's no need to process it. -->
            <xsl:when test="not(exists($filters-chosen)) and $is-inclusion"/>
            <xsl:when test="not(exists($first-doc-available)) and $is-inclusion">
               <xsl:copy-of select="tan:error('inc04')"/>
            </xsl:when>
            <xsl:when test="not(exists($first-doc-available))">
               <xsl:copy-of select="tan:error('whi04')"/>
            </xsl:when>
            <xsl:when test="exists($first-doc-available/(tan:error, tan:fatal))">
               <xsl:copy-of select="$first-doc-available"/>
            </xsl:when>
            <!-- The error for a TAN file attempting to include itself, directly or indirectly, will be placed in <location>... -->
            <xsl:when test="$first-doc-base-uri = ($doc-base-uri, $urls-already-visited)"/>
            <!-- ...or in <IRI> -->
            <xsl:when test="tan:IRI = ($doc-id, $doc-ids-already-visited)"/>
            <xsl:when test="($first-doc-available/*/@id = $doc-id)">
               <xsl:copy-of
                  select="tan:error('inc03', ('Target ' || name(.) || ' has an id that matches the id of the dependent document: ' || $doc-id))"
               />
            </xsl:when>
            <xsl:when test="($first-doc-available/*/@id = $doc-ids-already-visited)">
               <xsl:copy-of
                  select="tan:error('inc03', ('Target ' || name(.) || ' has an id (' || $first-doc-available/*/@id || ') that matches the id of a document that includes (directly or indirectly) this one'))"
               />
            </xsl:when>
            <xsl:when test="not(exists($first-doc-available/(tan:*, tei:*[@TAN-version])))">
               <xsl:copy-of
                  select="tan:error('lnk07', ('Target ' || name(.) || ' is not a TAN file, but is in the namespace ' || namespace-uri($first-doc-available/*)))"
               />
            </xsl:when>
            <xsl:when test="not($is-inclusion) and not(exists($first-doc-available/tan:TAN-voc))">
               <xsl:copy-of select="tan:error('lnk05', ('Vocabulary targets ' || name($first-doc-available/*)))"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="attributes-to-add" as="attribute()*">
                  <xsl:attribute name="{name(.)}" select="@xml:id"/>
               </xsl:variable>
               <xsl:if test="not($first-doc-available/*/@TAN-version = $tan:TAN-version)">
                  <xsl:copy-of select="tan:error('inc06', ('Target document is version: ' || $first-doc-available/*/@TAN-version))"/>
               </xsl:if>
               <xsl:copy-of
                  select="tan:resolve-doc-loop($first-doc-available, false(), $attributes-to-add, ($urls-already-visited, $doc-base-uri), ($doc-ids-already-visited, $doc-id), name(.), $filters-chosen, ($loop-counter + 1))"
               />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:inclusion/tan:IRI | tan:vocabulary/tan:IRI" mode="tan:resolve-critical-dependencies-loop">
      <xsl:param name="doc-id" tunnel="yes"/>
      <xsl:param name="doc-ids-already-visited" as="xs:string*" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test=". = $doc-id">
            <xsl:copy-of
               select="tan:error('inc03', ('TAN document with id ' || $doc-id || ' should not attempt to include another TAN file by the same id.'))"
            />
         </xsl:if>
         <xsl:if test=". = $doc-ids-already-visited">
            <xsl:copy-of
               select="tan:error('inc03', ('TAN document with id ' || $doc-id || ' is already included by another TAN file with the id ', .))"
            />
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:inclusion/tan:location[@href] | tan:vocabulary/tan:location[@href]" mode="tan:resolve-critical-dependencies-loop">
      <xsl:param name="doc-base-uri" tunnel="yes"/>
      <xsl:param name="urls-already-visited" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="href-resolved"
         select="
            if (tan:is-valid-uri(@href)) then
               resolve-uri(@href, $doc-base-uri)
            else
               ()"
      />
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$doc-base-uri = $href-resolved">
            <xsl:copy-of
               select="tan:error('inc03', ('TAN document at ' || $doc-base-uri || ' should not attempt to include itself.'))"
            />
         </xsl:if>
         <xsl:if test="$href-resolved = $urls-already-visited">
            <xsl:copy-of
               select="tan:error('inc03', ('TAN document at ' || $href-resolved || ' has already been included'))"
            />
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary-key" mode="tan:resolve-critical-dependencies-loop">
      <!-- We send all vocabulary filters through the official TAN vocabularies; these will come 
         out as <TAN-voc> elements, which will get fixed in the next step -->
      <xsl:param name="vocabulary-element-filters" tunnel="yes"/>
      <xsl:param name="vocabulary-attribute-filters" tunnel="yes"/>
      <!-- Copy current node as-is -->
      <xsl:copy-of select="."/>
      <!-- Grab the vocabulary of importance -->
      <xsl:apply-templates select="$tan:TAN-vocabularies" mode="tan:extract-essential-TAN-vocabulary">
         <xsl:with-param name="element-filters" select="$vocabulary-element-filters, $vocabulary-attribute-filters" tunnel="yes"/>
         <xsl:with-param name="add-q-ids" tunnel="yes" select="false()"/>
      </xsl:apply-templates>
   </xsl:template>
   
   <xsl:mode name="tan:extract-essential-TAN-vocabulary" on-no-match="shallow-skip"/>
   
   <xsl:template match="/tan:TAN-voc" mode="tan:extract-essential-TAN-vocabulary">
      <xsl:param name="element-filters" tunnel="yes" as="element()*"/>
      <xsl:variable name="attr-affects-element" as="xs:string?" select="tan:body/@affects-element"/>
      <xsl:variable name="attr-affects-attribute" as="xs:string?" select="tan:body/@affects-attribute"/>
      <xsl:variable name="element-filters-of-interest" as="element()*"
         select="$element-filters[(tan:element-name = $attr-affects-element) or (tan:attribute-name = $attr-affects-attribute)]"
      />
      <xsl:if test="exists($element-filters-of-interest)">
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="tan:body/*" mode="tan:first-stamp-shallow-skip">
               <xsl:with-param name="element-filters" tunnel="yes" select="$element-filters-of-interest"/>
            </xsl:apply-templates>
         </xsl:copy>
      </xsl:if>
   </xsl:template>
   
   
   
   
   

   <!-- Resolving, step 4 templates -->
   
   <xsl:template match="tan:inclusion/*[tan:head]" mode="tan:apply-inclusions-and-adjust-vocabulary">
      <xsl:param name="element-filters" as="element()*" tunnel="yes"/>
      <!-- Every <inclusion>, after the requisite <IRI>, <name>, <desc>, has the root element of
      the target document, and that root element has <head vocabulary="">, followed by elements that
      are intended to be substitutes in the host/dependent file. Everything but the vocabulary for the
      substitutes and nested inclusions should be discarded (including the substitutes, which in this
      same template mode are being grafted into the document). -->
      <xsl:variable name="this-incl-id" select="../@xml:id"/>
      <xsl:variable name="these-element-filters" select="$element-filters[@inclusion = $this-incl-id]"/>
      <xsl:variable name="this-inclusion-without-inclusions" as="document-node()">
         <xsl:document>
            <xsl:copy-of select="tan:copy-of-except(., ('inclusion'), (), ())"/>
         </xsl:document>
      </xsl:variable>
      <xsl:variable name="these-substitutes" select="key('tan:elements-by-name', $these-element-filters/tan:element-name, $this-inclusion-without-inclusions)"/>
      <xsl:variable name="this-vocabulary" select="tan:element-vocabulary($these-substitutes)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!-- retain only the vocabulary for the substitutes -->
         <xsl:copy-of select="$this-vocabulary"/>
         <!-- retain the inclusions -->
         <xsl:copy-of select="tan:head/tan:inclusion"/>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:template match="*[@include]" mode="tan:apply-inclusions-and-adjust-vocabulary">
      <xsl:param name="imprinted-inclusions" tunnel="yes"/>

      <xsl:variable name="this-element" select="."/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:variable name="this-attr-include-val-norm" select="tan:help-extracted(@include)"/>
      <xsl:variable name="these-include-idrefs" select="tokenize($this-attr-include-val-norm, ' ')"/>
      <xsl:for-each select="$these-include-idrefs">
         <!-- We need to distribute according to individual values of @include, so that vocabulary can be resolved accurately. -->
         <xsl:variable name="this-idref" select="."/>
         <xsl:variable name="relevant-inclusions" select="$imprinted-inclusions[@xml:id = $this-idref]/*/*[name(.) = $this-element-name]"/>
         <xsl:if test="not(exists($relevant-inclusions))">
            <xsl:variable name="invoking-file-id-for-this-file" select="root($this-element)/*/@inclusion"/>
            <xsl:element name="{$this-element-name}">
               <xsl:copy-of select="$this-element/(@* except @include)"/>
               <xsl:attribute name="include" select="$this-idref"/>
               <xsl:choose>
                  <xsl:when test="exists($invoking-file-id-for-this-file)">
                     <xsl:copy-of
                        select="tan:error('inc02', ('Included file ' || $invoking-file-id-for-this-file || ' cannot find elements named ' || $this-element-name || ' in target doc ' || $this-idref))"
                     />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of
                        select="tan:error('inc02', ('Cannot find elements named ' || $this-element-name || ' in target doc ' || $this-idref))"
                     />
                     <xsl:apply-templates select="$this-element/node()" mode="#current"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:element>
         </xsl:if>
         <xsl:for-each select="$relevant-inclusions">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:copy-of select="$this-element/(@* except @include)"/>
               <xsl:attribute name="include" select="$this-idref"/>
               <xsl:apply-templates select="node()" mode="tan:prefix-attr-include">
                  <xsl:with-param name="inclusion-id-prefix" tunnel="yes"
                     select="$this-idref || '_'"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:for-each>
         
      </xsl:for-each>
   </xsl:template>
   
   <xsl:mode name="tan:prefix-attr-include" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[@include]" mode="tan:prefix-attr-include">
      <xsl:param name="inclusion-id-prefix" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @include"/>
         <xsl:attribute name="include" select="$inclusion-id-prefix || @include"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:vocabulary/tan:TAN-voc" mode="tan:apply-inclusions-and-adjust-vocabulary">
      <!-- We already know that <vocabulary> targets a TAN-voc file, so we can skip the root element, 
      and even the <head type="vocabulary">, and merely report back the <item>s and <verb>s, provided
      the match the types of vocabulary originally requested. Because of inclusion, there may be an
      excess of vocabulary items. -->
      <xsl:apply-templates select="tan:item | tan:verb" mode="#current"/>
   </xsl:template>

   <xsl:template match="tan:vocabulary/tan:TAN-voc/tan:item | tan:vocabulary/tan:TAN-voc/tan:verb" priority="1"
      mode="tan:apply-inclusions-and-adjust-vocabulary">
      <xsl:param name="vocabulary-element-filters" tunnel="yes" as="element()*"/>
      <xsl:param name="vocabulary-attribute-filters" tunnel="yes" as="element()*"/>
      <xsl:variable name="these-element-names" select="name(.), tan:affects-element"/>
      <xsl:variable name="these-attribute-names" select="tan:affects-attribute"/>
      <xsl:variable name="filter-matches" select="$vocabulary-element-filters[(tan:element-name = $these-element-names)], 
         $vocabulary-attribute-filters[(tan:attribute-name = $these-attribute-names)]"/>
      <xsl:if test="exists($filter-matches)">
         <xsl:choose>
            <xsl:when test="$tan:validation-mode-on">
               <!-- If validating, we want all options for a given category, to supply help for errors -->
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="$filter-matches/tan:idref = '*' and exists($filter-matches/tan:idref)">
               <!-- If the <idref> is a joker character, it means any vocabulary item with an id. -->
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="$filter-matches/tan:name = '*'">
               <!-- We want all options if the <name> is a joker character -->
               <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="((tan:name | tan:id | tan:alias) = $filter-matches/(tan:name | tan:idref | tan:alias))">
               <!-- Otherwise, we want only relevant vocabulary items -->
               <xsl:copy-of select="."/>
            </xsl:when>
         </xsl:choose>
         
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="tan:head/tan:TAN-voc" mode="tan:apply-inclusions-and-adjust-vocabulary">
      <!-- We retain those standard TAN vocabulary items only if they fetched something that matched a vocabulary filter -->
      <xsl:variable name="vocab-items" select="tan:item, tan:verb"/>
      <xsl:if test="exists($vocab-items)">
         <tan-vocabulary>
            <IRI>
               <xsl:value-of select="@id"/>
            </IRI>
            <name>
               <xsl:value-of select="'Standard TAN vocabulary for ' || replace(@id, '.+:([^:]+)$', '$1')"/>
            </name>
            <location href="{@xml:base}" accessed-when="{current-dateTime()}"/>
            <xsl:copy-of select="$vocab-items"/>
         </tan-vocabulary>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="tan:resolve-href" as="node()?" visibility="public">
      <!-- One-parameter version of the full one, below -->
      <xsl:param name="xml-node" as="node()?"/>
      <xsl:copy-of select="tan:resolve-href($xml-node, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:resolve-href" as="node()?" visibility="public">
      <!-- Two-parameter version of the full one, below -->
      <xsl:param name="xml-node" as="node()?"/>
      <xsl:param name="add-q-ids" as="xs:boolean"/>
      <xsl:variable name="this-base-uri" select="tan:base-uri($xml-node)"/>
      <xsl:copy-of select="tan:resolve-href($xml-node, $add-q-ids, $this-base-uri)"/>
   </xsl:function>
   
   <xsl:function name="tan:resolve-href" as="node()?" visibility="public">
      <!-- Input: any XML node, a boolean, a string -->
      <!-- Output: the same node, but with @href in itself and all descendant elements resolved to absolute form, with @orig-href inserted preserving the original if there is a change -->
      <!-- The second parameter is provided because this function works closely with tan:resolve-doc(). -->
      <!--kw: resolution, uris, filenames -->
      <xsl:param name="xml-node" as="node()?"/>
      <xsl:param name="add-q-ids" as="xs:boolean"/>
      <xsl:param name="this-base-uri" as="xs:string"/>
      <xsl:apply-templates select="$xml-node" mode="tan:resolve-href">
         <xsl:with-param name="base-uri" select="xs:anyURI($this-base-uri)" tunnel="yes"/>
         <xsl:with-param name="add-q-ids" select="$add-q-ids" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:template match="*[@href]" mode="tan:resolve-href tan:expand-standard-tan-voc">
      <xsl:param name="base-uri" as="xs:anyURI?" tunnel="yes"/>
      <xsl:param name="add-q-ids" as="xs:boolean" tunnel="yes" select="true()"/>
      <xsl:variable name="attr-href-is-absolute" select="@href = string(resolve-uri(@href, static-base-uri()))"/>
      <xsl:variable name="this-base-uri"
         select="
            if (exists($base-uri)) then
               $base-uri
            else
               tan:base-uri(.)"
      />
      <xsl:variable name="new-href" select="resolve-uri(@href, xs:string($this-base-uri))"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @href"/>
         <xsl:choose>
            <xsl:when test="$attr-href-is-absolute or (string-length($this-base-uri) gt 0)">
               <xsl:attribute name="href" select="$new-href"/>
               <xsl:if test="not($new-href = @href) and $add-q-ids">
                  <xsl:attribute name="orig-href" select="@href"/>
               </xsl:if>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message select="'No base uri detected for ', tan:shallow-copy(.)"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   
   <!-- Resolving, step 5 templates -->
   
   <xsl:template match="/*" priority="1" mode="tan:resolve-numerals">
      <xsl:variable name="numerals-element" as="element()?" select="tan:head/tan:numerals"/>
      <xsl:variable name="ambig-is-roman" as="xs:boolean" select="not($numerals-element/@priority = 'letters')"/>
      <xsl:variable name="numeral-exceptions" as="xs:string*" select="
            if (exists($numerals-element/@exceptions)) then
               tokenize(normalize-space(lower-case($numerals-element/@exceptions)), ' ')
            else
               ()"/>
      <xsl:variable name="n-alias-items"
         select="tan:head/tan:vocabulary/tan:item[tan:affects-attribute = 'n']"/>
      <xsl:variable name="n-alias-constraints" select="tan:head/tan:n-alias"/>
      <xsl:variable name="n-alias-div-type-constraints"
         select="
            for $i in $n-alias-constraints
            return
               tokenize($i/@div-type, '\s+')"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <resolved>numerals</resolved>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="ambig-is-roman" select="$ambig-is-roman" tunnel="yes"/>
            <xsl:with-param name="numeral-exceptions" select="$numeral-exceptions" tunnel="yes"/>
            <xsl:with-param name="n-alias-items" select="$n-alias-items" tunnel="yes"/>
            <xsl:with-param name="n-alias-div-type-constraints"
               select="$n-alias-div-type-constraints" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[@include] | tan:inclusion" priority="1" mode="tan:resolve-numerals">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="*:div[@n]" mode="tan:resolve-numerals">
      <xsl:param name="ambig-is-roman" as="xs:boolean?" tunnel="yes" select="true()"/>
      <xsl:param name="numeral-exceptions" as="xs:string*" tunnel="yes"/>
      <xsl:param name="n-alias-items" as="element()*" tunnel="yes"/>
      <xsl:param name="n-alias-div-type-constraints" as="xs:string*" tunnel="yes"/>
      
      <xsl:variable name="these-n-vals" select="tokenize(normalize-space(@n), ' ')" as="xs:string*"/>
      <xsl:variable name="these-div-types" select="tokenize(@type, '\s+')" as="xs:string+"/>
      <xsl:variable name="n-aliases-should-be-checked" as="xs:boolean"
         select="not(exists($n-alias-div-type-constraints)) or ($these-div-types = $n-alias-div-type-constraints)"/>
      <xsl:variable name="n-aliases-to-process" as="element()*"
         select="
            if ($n-aliases-should-be-checked) then
               $n-alias-items
            else
               ()"/>
      <xsl:variable name="vals-normalized"
         select="
            for $i in $these-n-vals
            return
               tan:string-to-numerals(lower-case($i), $ambig-is-roman, false(), $n-aliases-to-process, $numeral-exceptions)"/>
      <xsl:variable name="n-val-rebuilt" select="string-join($vals-normalized, ' ')"/>
      
      <xsl:variable name="these-ref-alias-vals" select="tokenize(normalize-space(@ref-alias), ' ')" as="xs:string*"/>
      <xsl:variable name="ref-alias-vals-normalized" as="xs:string*" select="
            for $i in $these-ref-alias-vals
            return
               tan:string-to-numerals(lower-case($i), $ambig-is-roman, false(), $n-aliases-to-process, $numeral-exceptions)"
      />
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode resolve-numerals, for: ', ."/>
         <xsl:message select="'ambig #s are roman: ', $ambig-is-roman"/>
         <xsl:message select="'Qty n aliases: ', count($n-alias-items)"/>
         <xsl:message select="'n alias constraints: ', $n-alias-div-type-constraints"/>
         <xsl:message select="'n aliases should be checked: ', $n-aliases-should-be-checked"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="n" select="$n-val-rebuilt"/>
         <xsl:if test="not(@n = $n-val-rebuilt)">
            <xsl:attribute name="orig-n" select="@n"/>
         </xsl:if>
         <xsl:if test="exists(@ref-alias)">
            <xsl:variable name="ref-alias-val-rebuilt" select="string-join($ref-alias-vals-normalized, ' ')"/>
            <xsl:attribute name="ref-alias" select="$ref-alias-val-rebuilt"/>
            <xsl:if test="not($ref-alias-val-rebuilt eq @ref-alias)">
               <xsl:attribute name="orig-ref-alias" select="@ref-alias"/>
            </xsl:if>
         </xsl:if>
         
         <xsl:if
            test="
               some $i in $these-n-vals
                  satisfies matches($i, '^0\d')">
            <xsl:copy-of select="tan:error('cl117')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:ref | tan:n" mode="tan:resolve-numerals" priority="1">
      <!-- This part of resolve numerals handles class 2 references that have already been expanded from attributes to elements. -->
      <!-- Because class-2 @ref and @n are never tethered to a div type, we cannot enforce the constraints in the source class-1 file's <n-alias> -->
      <xsl:param name="ambig-is-roman" as="xs:boolean?" tunnel="yes" select="true()"/>
      <xsl:param name="numeral-exceptions" as="xs:string*" tunnel="yes"/>
      <xsl:param name="n-alias-items" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-element-name" select="name(.)"/>
      <xsl:variable name="val-normalized"
         select="tan:string-to-numerals(lower-case(text()), $ambig-is-roman, false(), $n-alias-items, $numeral-exceptions)"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on, template mode resolve-numerals, for: ', ."/>
         <xsl:message select="'ambig #s are roman: ', $ambig-is-roman"/>
         <xsl:message select="'Qty n aliases: ', count($n-alias-items)"/>
         <xsl:message select="'Numeral exceptions: ' || string-join($numeral-exceptions, ', ')"/>
      </xsl:if>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="$val-normalized"/>
         <xsl:choose>
            <xsl:when test="not($val-normalized = text()) and ($this-element-name = 'ref')">
               <xsl:for-each select="tokenize($val-normalized, ' ')">
                  <n>
                     <xsl:value-of select="."/>
                  </n>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy-of select="*"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   

</xsl:stylesheet>
