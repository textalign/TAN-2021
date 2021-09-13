<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:file="http://expath.org/ns/file"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- This stylesheet takes variables and other components that have been run in the
      companion test file. Putting older material here helps declutter the stylesheet, 
      and make accessible previous routines. -->
   
   <xsl:variable name="this-model-expanded" select="tan:expand-doc($tan:model-resolved, 'terse', false())"/>
   
   <xsl:variable name="test-tree" as="document-node()" select="doc('test.xml')"/>
   <xsl:variable name="test-tree-seq" select="tan:tree-to-sequence($test-tree)" as="item()*"/>
   <xsl:variable name="test-tree-restored" select="tan:sequence-to-tree($test-tree-seq)" as="item()*"/>
   
   <xsl:variable name="ns-nodes" as="element()*">
      <xsl:apply-templates mode="tan:build-namespace-map"/>
   </xsl:variable>
   
   <!--<!-\- reserve as predefined two xsl:item-types bound to specially reserved signatures; I'm guessing at the syntax that will be used for default values within the proposed tuple(*) -\->
   <xsl:item-type name="map:entry" as="tuple(type as xs:QName select xs:QName('map:tuple'), key as xs:anyAtomicType, value as item()*)"/>
   <xsl:item-type name="array:member" as="tuple(type as xs:QName select xs:QName('array:tuple'), pos as xs:integer, member as item()*)"/>
   <!-\- If in a template the context is a map or array then the default @select value is as below -\->
   <xsl:template match=".[. instance of map(*)]">
      <xsl:apply-templates select="
            map:for-each(., function ($k, $v) {
               map {
                  'type': xs:NCName('map:tuple'),
                  'key': $k,
                  'value': $v
               }
            })" mode="#current"/>
   </xsl:template>
   <xsl:template match=".[. instance of array(*)]">
      <xsl:apply-templates select="
            for $i in (1 to array:size(.))
            return
               map {
                  'type': xs:NCName('array:tuple'),
                  'pos': $i,
                  'member': .($i)
               }" mode="#current"/>
   </xsl:template>
   <!-\- Maps and arrays would not by default have that type, only entries/members processed in an apply-templates action, or through explicit casting of a map to the type -\->
   <xsl:template match="type(map:entry)">
      <!-\- sequence constructor -\->
      <key>{?key}</key>
      <value>
         <xsl:apply-templates select="?value" mode="#current"/>
      </value>
   </xsl:template>
   <xsl:template match="type(array:member)">
      <!-\- sequence constructor -\->
      <pos>{?pos}</pos>
      <member>
         <xsl:apply-templates select="?member" mode="#current"/>
      </member>
   </xsl:template>-->
   
   
   <xsl:function name="tan:array-test" as="item()*" visibility="public">
      <xsl:param name="master-array" as="array(xs:integer+)"/>
      
      <xsl:variable name="master-array-size" as="xs:integer" select="array:size($master-array)"/>
      
      <xsl:message select="'master array size', $master-array-size"/>
      
      <xsl:variable name="start-array" as="array(xs:integer+)" select="[1]"/>
      <xsl:variable name="added-array" as="array(xs:integer+)" select="array:append([1], 2)"/>
      
      <xsl:message select="'size start', array:size($start-array)"/>
      <xsl:message select="'size next', array:size($added-array)"/>
      <!--<xsl:message select="'new array', tan:array-to-xml($added-array)"/>-->
      
      <!--<xsl:sequence select="array:subarray($master-array, 1)"/>-->
      <!--<xsl:sequence select="array:subarray(array:append([(1, 2), 3], 4), 1)"/>-->
      <!--<xsl:message select="'size subarray', array:size(array:subarray($added-array, 1))"/>-->
      
      <!--<xsl:iterate select="1 to $master-array-size">
         <xsl:param name="array-so-far" as="array(xs:integer+)?"/>
         
         <xsl:variable name="this-iteration" as="xs:integer" select="."/>
         <xsl:variable name="these-integers" as="xs:integer+" select="sort($master-array($this-iteration))"/>
         
         <xsl:message select="'iteration, integers:', $this-iteration, $these-integers"/>
         
         <xsl:variable name="new-array" as="array(xs:integer+)">
            <xsl:choose>
               <xsl:when test="not(exists($array-so-far))">
                  <xsl:sequence select="
                        for $i in $these-integers
                        return
                           [($this-iteration, $i)]"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="array:append($array-so-far, $these-integers)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>

         <xsl:if test="exists($new-array)">
            <xsl:message select="'new array size', array:size($new-array)"/>
            
            <xsl:sequence select="array:size(array:subarray($new-array, 1))"/>
         </xsl:if>
         
         <xsl:next-iteration>
            <xsl:with-param name="array-so-far" select="$new-array"/>
         </xsl:next-iteration>
      </xsl:iterate>-->
      
      
      
   </xsl:function>
   
   
   
   
   <xsl:variable name="string-a" as="xs:string">Classical models of string comparison have been difficult to implement in XSLT, in part because MATCH THEM those models are designed for imperative, stateful programming. In this article I introduce a new XSLT function, ns:diff(), which is built upon a different approach to string comparison, one more conducive to a declarative, stateless language. ns:diff() is efficient and fast, even on pairs of very long strings (100K to 1M characters), in part because of its staggered-sample approach, in part because of its optimization stategy for long strings. Its results are optimal, as the THEM POTATOES function normally returns a minimal diff, or shortest edit script.</xsl:variable>
   <xsl:variable name="string-b" as="xs:string">Classical models of string comparison have been difficult to implement in XSLT, in part because those models are designed for imperative, stateful programming. In this article I introduce a new XSLT function, ns:diff(), which is built upon a different approach to string comparison, one more conducive to a declarative, stateless language. ns:diff() is efficient and fast, even MATxCH THEM POTATOxES on pairs of very long strings (100K to 1M characters), in part because of its staggered-sample approach, in part because of its optimization stategy for long strings. Its results are optimal, as the function normally returns a minimal diff, or shortest edit script.</xsl:variable>
   <xsl:variable name="string-c-a" as="xs:string" select="'145236'"/>
   <xsl:variable name="string-c-o" as="xs:string" select="'123456'"/>
   <xsl:variable name="string-c-b" as="xs:string" select="'124536'"/>
   <xsl:variable name="str-diff" as="element()" select="tan:diff($string-a, $string-b, false())"/>
   
   <xsl:variable name="string-a1" as="xs:string"><xsl:value-of select="substring($string-a, 1, 10)"/></xsl:variable>
   <xsl:variable name="string-b1" as="xs:string"><xsl:value-of select="substring($string-b, 1, 10)"/></xsl:variable>
   
   <xsl:variable name="item-type" select="tan:data-type-check((), 'xs:string')"/>   
   
   <xsl:variable name="sample-map" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="1">
            <xsl:sequence select="1"/>
            <xsl:sequence select="2"/>
         </xsl:map-entry>
         <xsl:map-entry key="xs:QName('tan:div')">
            <tan:div n="4">div</tan:div>
            <tan:div n="5">div five</tan:div>
         </xsl:map-entry>
         <xsl:map-entry key="'2'">two</xsl:map-entry>
         <xsl:map-entry key="2">2</xsl:map-entry>
         <xsl:map-entry key="xs:decimal(-2.0)">-2.0</xsl:map-entry>
         <xsl:map-entry key="'map'">
            <xsl:map>
               <xsl:map-entry key="'array'" select="array {1, 1, 2, 'three', [(4.5, 5), [(), ()], 'six', (map{}, map{ 'array' : [(1, 2), 'three']})]}"/>
               <xsl:map-entry key="'deep'" select="'deeper'"/>
            </xsl:map>
         </xsl:map-entry>
         <xsl:map-entry key="'map2'">
            <xsl:map>
               <xsl:map-entry key="'deep'" select="'deeper2'"/>
            </xsl:map>
         </xsl:map-entry>
      </xsl:map>
   </xsl:variable>
   <!--<xsl:variable name="s-map-to-xml" as="element()" select="tan:map-to-xml($sample-map)"/>
   <xsl:variable name="s-back-to-map" as="map(*)" select="tan:xml-to-map($s-map-to-xml)"/>-->
   
   <xsl:variable name="test-int-seq" as="xs:integer+" select="1 to 10000000"/>
   <xsl:variable name="test-str-seq" as="xs:string+" select="
      for $i in $test-int-seq
      return
      string($i)"/>
   <xsl:variable name="test-dbl-seq" as="xs:double+" select="
      for $i in $test-str-seq
      return
      number($i)"/>
   <xsl:variable name="test-back-int-seq" as="xs:integer+" select="
      for $i in $test-str-seq
      return
      xs:integer($i)"/>
   
   <xsl:variable name="array-test" as="element()">
      <array xmlns="http://www.w3.org/2005/xpath-functions/array">
         <member type="xs:integer">1</member>
         <member type="xs:integer">2</member>
         <member type="xs:string">three</member>
         <array xmlns="http://www.w3.org/2005/xpath-functions/array">
            <member type="xs:decimal">4.5</member>
            <member type="xs:integer">5</member>
            <member type="xs:string">six</member>
         </array>
      </array>
   </xsl:variable>
   <xsl:variable name="sequence-a" as="item()*" select="1, 2, 'three', ()"/>
   <xsl:variable name="array-test2" as="array(*)" select="array {$sequence-a, ''}"/>
   <xsl:variable name="array-test3" as="array(*)" select="[$sequence-a, [$sequence-a], ()]"/>
   <!--<xsl:variable name="array-test3" as="array(*)" select="array{1, 2, 3}"/>-->
   <!--<xsl:variable name="array-test-to-array" as="array(*)" select="tan:xml-to-array($array-test)"/>-->
   
   <!--<xsl:variable name="las" select="tan:array-test([1, 3, 2])"/>-->
   
   <xsl:variable name="test-element1" as="element()*">
      <int>
         <item>7</item>
         <item>8</item>
         <item>9</item>
      </int>
      <int>
         <item>10</item>
      </int>
   </xsl:variable>
   
   <xsl:variable name="test-items" as="item()*" select="('1', 2, xs:decimal(3.0), [(4, 5)], $test-element1)"/>
   <xsl:variable name="test-item-array" as="array(*)*">
      <xsl:apply-templates select="$test-items" mode="tan:build-integer-arrays"/>
   </xsl:variable>
   
   <xsl:variable name="some-arrays" as="array(*)*" select="[(1, 2), 3], [(4, 5), 6]"/>
   <xsl:variable name="array-build" as="array(*)*">
      <xsl:iterate select="1 to 5">
         <xsl:iterate select="$some-arrays">
            <xsl:sequence select="array:subarray(., 1)"/>
         </xsl:iterate>
      </xsl:iterate>
   </xsl:variable>
   
   <xsl:variable name="test-string-a" as="xs:string"
      select="'καὶ τὸ Οὐκ ἔστιν δοῦναι, ἀλλ` οἷς τοῦ Πατρός. Τοῦτο γάρ'"/>
   <xsl:variable name="test-string-b" as="xs:string"
      select="'ἐξ εὐωνύμων οὐκ ἔστιν δοῦναι, ἀλλ’ οἷς τοῦ πατρός μου. Καὶ'"/>
   <xsl:variable name="test-collation" as="element()" select="tan:collate-pair-of-sequences(tokenize($test-string-a, '\W+'),
      tokenize($test-string-b, '\W+'))"/>
   
   <!--<xsl:variable name="morpheus-searches" select="for $i in tokenize($test-string-a, ' ')
      return
      tan:search-morpheus($i)"/>-->
   
   <xsl:variable name="tan-mor-1-uri" as="xs:string" select="'../../library-lm/grc/grc.perseus.tan-mor.xml'"/>
   <xsl:variable name="tan-mor-2-uri" as="xs:string" select="'../../library-lm/grc/grc.perseus.readable.tan-mor.xml'"/>
   <xsl:variable name="tan-mor-3-uri" as="xs:string" select="'../../library-lm/lat/lat.perseus.tan-mor.xml'"/>
   <xsl:variable name="tan-mor-4-uri" as="xs:string" select="'../../library-lm/eng/eng.brown.tan-mor.xml'"/>
   <xsl:variable name="tan-a-lm-uri" as="xs:string" select="'../../library-lm/grc/lm-perseus/grc-tan-a-lm-%CE%B1%CE%B2.xml'"/>
   
   <xsl:variable name="tan-mor-1-resolved" as="document-node()"
      select="tan:resolve-doc(doc(resolve-uri($tan-mor-1-uri, static-base-uri())))"/>
   <xsl:variable name="tan-mor-2-resolved" as="document-node()"
      select="tan:resolve-doc(doc(resolve-uri($tan-mor-2-uri, static-base-uri())))"/>
   <xsl:variable name="tan-mor-3-resolved" as="document-node()"
      select="tan:resolve-doc(doc(resolve-uri($tan-mor-3-uri, static-base-uri())))"/>
   <xsl:variable name="tan-mor-4-resolved" as="document-node()"
      select="tan:resolve-doc(doc(resolve-uri($tan-mor-4-uri, static-base-uri())))"/>
   
   <!--<xsl:variable name="mor-1-to-2-maps" as="map(*)*" select="tan:morphological-code-conversion-maps($tan-mor-1-resolved, $tan-mor-2-resolved)"/>
   <xsl:variable name="mor-2-to-1-maps" as="map(*)*" select="tan:morphological-code-conversion-maps($tan-mor-2-resolved, $tan-mor-1-resolved)"/>
   <xsl:variable name="mor-1-to-3-maps" as="map(*)*" select="tan:morphological-code-conversion-maps($tan-mor-1-resolved, $tan-mor-3-resolved)"/>
   <xsl:variable name="mor-1-to-4-maps" as="map(*)*" select="tan:morphological-code-conversion-maps($tan-mor-1-resolved, $tan-mor-4-resolved)"/>
   <xsl:variable name="mor-2-to-4-maps" as="map(*)*" select="tan:morphological-code-conversion-maps($tan-mor-2-resolved, $tan-mor-4-resolved)"/>
   
   <xsl:variable name="tan-a-lm-doc" as="document-node()" select="doc(resolve-uri($tan-a-lm-uri))"/>
   
   <xsl:variable name="tan-a-lm-to-mor2" as="document-node()" select="tan:convert-morphological-codes($tan-a-lm-doc, 'perseus-dik', $mor-1-to-2-maps)"/>
   <xsl:variable name="tan-a-lm-back-to-mor1" as="document-node()" select="tan:convert-morphological-codes($tan-a-lm-to-mor2, 'perseus-dik', $mor-2-to-1-maps)"/>

   <xsl:variable name="tan-a-lm-to-mor3" as="document-node()" select="tan:convert-morphological-codes($tan-a-lm-doc, 'perseus-dik', $mor-1-to-3-maps)"/>
   <xsl:variable name="tan-a-lm-to-mor2-then-mor4" as="document-node()" select="tan:convert-morphological-codes($tan-a-lm-to-mor2, 'perseus-dik', $mor-2-to-4-maps)"/>
   
   <xsl:variable name="tan-a-lm-to-mor4" as="document-node()" select="tan:convert-morphological-codes($tan-a-lm-doc, 'perseus-dik', $mor-1-to-4-maps)"/>-->
   
   <xsl:variable name="local-cat-doc" as="document-node()?" select="doc('file:/E:/Joel/Dropbox/TAN/library-arithmeticus/evagrius/catalog.tan.xml')"/>
   <xsl:variable name="local-cat-resolved" select="tan:resolve-doc($local-cat-doc)"/>
   
   <xsl:variable name="kg-uri-collection" as="xs:anyURI*" select="uri-collection(resolve-uri('../../library-arithmeticus/evagrius/cpg2432/', static-base-uri()))"/>   
   <xsl:variable name="kg-grc-files" as="document-node()*" select="
      for $i in $kg-uri-collection[matches(., '\.grc\.')][not(matches(., 'frankenberg'))]
      return
      doc($i)"/>
   
   <xsl:variable name="kg-frag-refs" as="xs:string+">
      <xsl:for-each-group select="$kg-grc-files//*:body/*:div" group-by="
         if (@n castable as xs:integer) then
         xs:integer(@n)
         else
         tan:rom-to-int(@n)">
         <xsl:sort select="current-grouping-key()"/>
         <xsl:variable name="this-n" select="current-grouping-key()"/>
         <xsl:for-each-group select="current-group()/*:div" group-by="number(@n)">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:value-of select="$this-n || ' ' || current-grouping-key()"/>
         </xsl:for-each-group>
      </xsl:for-each-group>
   </xsl:variable>
   
   
   
   <xsl:template match="/" priority="-1">
      
      <xsl:result-document format="xml" href="../output/{tan:cfn(/)}-diagnostics.xml">
         <test>
         <ellipses><xsl:copy-of select="tan:ellipses('abcdefghijk', 2)"/></ellipses>
         <!--<kg-uris>
            <xsl:for-each select="$kg-grc-files">
               <file><xsl:value-of select="base-uri(.)"/></file>
            </xsl:for-each>
         </kg-uris>-->
         <!--<kg count="{count(distinct-values($kg-frag-refs))}">
            <xsl:for-each select="distinct-values($kg-frag-refs)">
               <ref><xsl:value-of select="."/></ref>
            </xsl:for-each>
         </kg>-->
         <!--<map-invert><xsl:copy-of select="tan:map-to-xml(tan:map-invert(tan:array-to-map(tan:integer-groups((1, 2, 3, 6, 7)), false())))"/></map-invert>-->
         <!--<file><xsl:copy-of select="tan:open-file('file:/e:/eula.1028.txt')"/></file>-->
         <!--<local-cat><xsl:copy-of select="$local-cat-doc"/></local-cat>-->
         <!--<local-cat-res><xsl:copy-of select="$local-cat-resolved"/></local-cat-res>-->
         <!--<local-cat-exp><xsl:copy-of select="tan:expand-doc($local-cat-resolved)"/></local-cat-exp>-->
         <!--<xsl:copy-of select="tan:collate(($string-c-o, $string-c-a, $string-c-b), ('O', 'A', 'B'), false())"/>-->
         <!--<xsl:variable name="target-uri" as="xs:anyURI?" select="resolve-uri('test2.xml', static-base-uri())"/>-->
         <!--<doc-av><xsl:copy-of select="tan:doc-available($target-uri)"/></doc-av>-->
         <!--<xsl:result-document href="{$target-uri}">
            <test></test>
         </xsl:result-document>-->
         <!--<uri-collection><xsl:copy-of select="tan:uri-collection(tan:uri-directory(static-base-uri()))"/></uri-collection>-->
         <!--<mor4-res><xsl:copy-of select="$tan-mor-4-resolved"/></mor4-res>-->
         <!--<mor4-exp><xsl:copy-of select="tan:expand-doc($tan-mor-4-resolved, 'terse', true())"/></mor4-exp>-->
         <!--<tan-a-mor-1-resolved><xsl:copy-of select="$tan-a-mor-1-resolved"/></tan-a-mor-1-resolved>-->
         <!--<tan-a-mor-2-resolved><xsl:copy-of select="$tan-a-mor-2-resolved"/></tan-a-mor-2-resolved>-->
         <!--<mor-1-to-mor-2-maps><xsl:copy-of select="tan:map-to-xml($mor-1-to-2-maps)"/></mor-1-to-mor-2-maps>-->
         <!--<mor-1-to-mor-3-maps><xsl:copy-of select="tan:map-to-xml($mor-1-to-3-maps)"/></mor-1-to-mor-3-maps>-->
         <!--<mor-1-to-mor-4-maps><xsl:copy-of select="tan:map-to-xml($mor-1-to-4-maps)"/></mor-1-to-mor-4-maps>-->
         <!--<mor-2-to-mor-1-maps><xsl:copy-of select="tan:map-to-xml($mor-2-to-1-maps)"/></mor-2-to-mor-1-maps>-->
         <!--<mor-2-to-mor-4-maps><xsl:copy-of select="tan:map-to-xml($mor-2-to-4-maps)"/></mor-2-to-mor-4-maps>-->
         <!--<tan-a-lm-to-mor3><xsl:copy-of select="$tan-a-lm-to-mor3"/></tan-a-lm-to-mor3>-->
         <!--<tan-a-lm-to-mor4><xsl:copy-of select="$tan-a-lm-to-mor4"/></tan-a-lm-to-mor4>-->
         <!--<tan-a-lm-to-mor2-then-mor4><xsl:copy-of select="$tan-a-lm-to-mor2-then-mor4"/></tan-a-lm-to-mor2-then-mor4>-->
         <!--<tan-a-lm-to-mor2><xsl:copy-of select="$tan-a-lm-to-mor2"/></tan-a-lm-to-mor2>-->
         <!--<tan-a-lm-back-to-mor1><xsl:copy-of select="$tan-a-lm-back-to-mor1"/></tan-a-lm-back-to-mor1>-->
         <!--<tan-a-lm-diff><xsl:copy-of select="tan:diff(serialize($tan-a-lm-doc), serialize($tan-a-lm-back-to-mor1))"/></tan-a-lm-diff>-->
         <!--<xsl:copy-of select="$morpheus-searches"/>-->
         <!--<xsl:copy-of select="tan:search-results-to-IRI-name-pattern($morpheus-searches)"/>-->
         <!--<xsl:copy-of select="tan:search-results-to-claims($morpheus-searches, 'morpheus')"/>-->
         <!--<xsl:copy-of select="$test-collation"/>-->
         <!--<array-permutations><xsl:copy-of select="tan:array-to-xml(tan:array-permutations([(1, 2, 3), ('a', 'b', current-date())]))"/></array-permutations>-->
         <!--<fa><xsl:copy-of select="function-available('file:exists')"/></fa>-->
         <!--<xsl:copy-of select="tan:array-to-xml($array-build)"/>-->
         <!--<xsl:copy-of select="tan:array-to-xml(array:subarray([(1), (2, 3)], 2))"/>-->
         <!--<coll-str-seq><xsl:copy-of select="tan:collate-pair-of-sequences(tokenize($string-a, ' '), tokenize($string-b, ' '))"/></coll-str-seq>-->
         <!--<integer-array><xsl:copy-of select="tan:array-to-xml(array:join($test-item-array))"/></integer-array>-->
         <!--<las><xsl:copy-of select="$las"/></las>-->
         <!--<xsl:variable name="array-a" as="array(xs:integer+)" select="[1]"/>-->
         <!--<xsl:variable name="array-b" as="array(xs:integer+)" select="array:append($array-a, 2)"/>-->
         <!--<xsl:variable name="test-subarray" as="array(xs:integer+)" select="array:subarray($array-b, 1)"/>-->
         <!--<subarray><xsl:sequence select="array:size($test-subarray)"/></subarray>-->
         <!--<subarray><xsl:copy-of select="array:subarray(['a', 'b', 'c', 'd'], 2)"/></subarray>-->
         <!--<las><xsl:copy-of select="tan:array-to-xml($las)"/></las>-->
         <!--<xsl:copy-of select="tan:duplicate-items((xs:double(3.0), 3, '3'))"/>-->
         <!--<xsl:copy-of select="tan:map-entries-test($sample-map)"/>-->
         <!--<xsl:copy-of select="tan:array-to-xml(tan:map-to-array($sample-map))"/>-->
         <!--<array>
            <xsl:for-each select="1 to array:size($array-test-to-array)">
               <member><xsl:copy-of select="$array-test-to-array(current())"/></member>
            </xsl:for-each>
         </array>-->
         <!--<array2>
            <!-\-<xsl:copy-of select="array:size($array-test2)"/>-\->
            <xsl:for-each select="1 to array:size($array-test2)">
               <member><xsl:copy-of select="$array-test2(current())"/></member>
            </xsl:for-each>
         </array2>-->
         <!--<array3>
            <!-\-<xsl:copy-of select="array:size($array-test2)"/>-\->
            <xsl:for-each select="1 to array:size($array-test3)">
               <member><xsl:copy-of select="$array-test3(current())"/></member>
            </xsl:for-each>
         </array3>-->
         <!--<array-2-and-3><xsl:copy-of select="deep-equal($array-test2, $array-test3)"/></array-2-and-3>-->
         <!--<casting>
            <integers><xsl:copy-of select="avg($test-int-seq)"/></integers>
            <!-\-<strings><xsl:copy-of select="exists($test-str-seq)"/></strings>-\->
            <!-\-<doubles><xsl:copy-of select="avg($test-dbl-seq)"/></doubles>-\->
            <back-integers><xsl:copy-of select="avg($test-back-int-seq)"/></back-integers>
         </casting>-->
         <!--<map-contains><xsl:copy-of select="tan:map-contains($sample-map, 'deep')"/></map-contains>-->
         <!--<map-keys><xsl:copy-of select="tan:map-keys($sample-map)"/></map-keys>-->
         <!--<map-find><xsl:copy-of select="array:size(map:find($sample-map, 'deep'))"/></map-find>-->
         
         <!--<xsl:variable name="int-seq" as="xs:integer+" select="(1, 78, 5, 4, 79, -1, 0)"/>-->
         <!--<xsl:variable name="int-seq-array" as="array(xs:integer+)" select="tan:integer-groups($int-seq)"/>-->
         <!--<int-clusters>
            <xsl:for-each select="1 to array:size($int-seq-array)">
               <cluster><xsl:copy-of select="$int-seq-array(current())"/></cluster>
            </xsl:for-each>
         </int-clusters>-->
         <!--<int-clusters-2><xsl:copy-of select="tan:array-to-xml($int-seq-array)"/></int-clusters-2>-->
         <!--<map-keys><xsl:copy-of select="map:keys($sample-map)"/></map-keys>-->
         <!--<map-sorted>
            <xsl:for-each select="map:keys($sample-map)">
               <xsl:sort select="number()"/>
               <key type="{tan:node-type(.)}">
                  <xsl:value-of select="."/>
               </key>
            </xsl:for-each>
         </map-sorted>-->
         <!--<xsl:copy-of select="tan:map-to-xml($sample-map)"/>-->
         <!--<xsl:copy-of select="$s-map-to-xml"/>-->
         <!--<xsl:copy-of select="tan:map-to-xml($s-back-to-map)"/>-->
         <!--<samp-map>
            <xsl:for-each select="map:keys($sample-map)">
               <key><xsl:value-of select="tan:item-type(.)"/></key>
            </xsl:for-each>
         </samp-map>-->
         <!--<xsl:copy-of select="tan:get-diff-output-transpositions($str-diff, 5, 0.8)"/>-->
         <!--<xsl:copy-of select="tan:stamp-tree-with-text-data(tan:stamp-diff-with-text-data($str-diff), true())"/>-->
         <!--<xsl:copy-of select="tan:stamp-tree-with-text-data($str-diff, false())"/>-->
         <!--<slices>
            <xsl:copy-of select="tan:map-to-xml(tan:get-diff-output-slices($str-diff, 5, 0.8, 0, true()))"/>
         </slices>-->
         <!--<int-cl>
            <xsl:copy-of select="tan:integer-clusters((1, 4, 5, 7, 9), (6, 12))"/>
         </int-cl>-->
         <!--<xsl:for-each select="1 to count($values)">
            <xsl:sequence select="$values[current()]"/>    
         </xsl:for-each>-->
         <!--<s2-test><xsl:copy-of select="tan:resolve-doc(tan:get-1st-doc($tan:head/tan:source[2]), true(), tan:attr('src', ($tan:head/tan:source[2]/@xml:id, '1')[1]))"/></s2-test>-->
         <!--<xsl:copy-of select="tan:normalize-tree-space($tan:sources-resolved, true())"/>-->
         <!--<xsl:for-each select="$tan:self-expanded">
            <xsl:value-of select="tan:node-type(.)"/>
         </xsl:for-each>-->
         <!--<collate><xsl:sequence select="tan:collate(('abc', 'bcd', 'cde'), (), true())"></xsl:sequence></collate>-->
         <!--<card><xsl:sequence select="tan:cardinal(2001)"/></card>-->
         <!--<cfne><xsl:sequence select="tan:cfn('jar:file:/E:/Joel/Dropbox/TAN/library-arithmeticus/test/ring1951rev')"></xsl:sequence></cfne>-->
         <!--<uri-test><xsl:copy-of select="tan:uri-relative-to('file:/e:/COVID-19-analysis-tables/temperature.html', 'file:/e:/COVID-19-analysis-tables/test3.xml')"/></uri-test>-->
         <!--<ns-nodes><xsl:copy-of select="$ns-nodes"/></ns-nodes>-->
         <!--<namespace-test><xsl:copy-of select="//namespace-node()"/></namespace-test>-->
         <!--<html-test><xsl:copy-of select="tan:convert-to-html(/, true())"/></html-test>-->
         <!--<tree-to-seq><xsl:sequence select="$test-tree-seq"/></tree-to-seq>-->
         <!--<seq-to-tree><xsl:copy-of select="$test-tree-restored"/></seq-to-tree>-->
         <!--<href><xsl:copy-of select="tan:revise-hrefs(/, 'http://www.w3.org/2001/XMLSchema', 'http://www.w3.org/2001/XMLSchema2')"/></href>-->
         <!--<targ-el-names><xsl:copy-of select="tan:target-element-names($test-el/@which)"/></targ-el-names>-->
         <!--<voc-test><xsl:copy-of select="tan:vocabulary('normalization', 'no hyphens', $tan:head)"/></voc-test>-->
         <!--<el-attr-wh><xsl:copy-of select="string-join($TAN-elements-that-take-the-attribute-which/@name, ', ')"/></el-attr-wh>-->
         <!--<shallow-copy><xsl:copy-of select="tan:shallow-copy(/*/*[1], 2)"/></shallow-copy>-->
         <!--<TAN-vocabularies><xsl:copy-of select="$tan:TAN-vocabularies"/></TAN-vocabularies>-->
         <!--<vocab><xsl:copy-of select="$tan:all-vocabularies"/></vocab>-->
         <!--<cat><xsl:copy-of select="tan:catalogs(/, true())"/></cat>-->
         <!--<merged-docs>
            <xsl:copy-of select="tan:merge-expanded-docs(($tan:self-expanded, tan:expand-doc($tan:model-resolved, 'terse')))"/>
         </merged-docs>-->
      </test>
         <diagnostics>
            <!--<sources-resolved count="{count($tan:sources-resolved)}"><xsl:copy-of select="$tan:sources-resolved[2]"/></sources-resolved>-->
            <!--<source-norm><xsl:copy-of select="tan:normalize-tree-space($tan:sources-resolved[2], true())"/></source-norm>-->
            <self-expanded count="{count($tan:self-expanded)}"><xsl:copy-of select="$tan:self-expanded[3]"/></self-expanded>
         </diagnostics>
      </xsl:result-document>
   </xsl:template>
   
</xsl:stylesheet>
