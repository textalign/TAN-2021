<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:file="http://expath.org/ns/file"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- This stylesheet allows users to quickly test a TAN file or components of the TAN library. Alter as you like. -->
   
   <xsl:param name="tan:validation-mode-on" static="yes" select="true()"/>
   <xsl:param name="tan:distribute-vocabulary" select="false()"/>
   
   <!--<xsl:import href="../../TAN-2020/functions/TAN-A-functions.xsl"/>-->
   <!--<xsl:import href="../../TAN-2020/functions/TAN-extra-functions.xsl"/>-->
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   <xsl:include href="test%20TAN%20function%20library%20previous.xsl"/>

   <xsl:output method="xml" indent="yes"/>
   
   <xsl:param name="tan:stylesheet-change-message">Assorted tests on the TAN Function Library</xsl:param>
   <xsl:param name="tan:stylesheet-iri">tag:textalign.net,2015:algorithm:tan-library-test</xsl:param>
   <xsl:param name="tan:stylesheet-url" as="xs:string" select="static-base-uri()"/>
   
   <xsl:param name="tan:default-validation-phase">terse</xsl:param>
   
   <xsl:variable name="string-1" as="xs:string" select="'Once again, we have much to thank you for.'"/>
   <xsl:variable name="string-2" as="xs:string" select="'nce again, have we weirdness uch to ank u for.'"/>
   <xsl:variable name="string-3" as="xs:string" select="'Finally, we have much to thank you for!'"/>
   <xsl:variable name="string-4" as="xs:string" select="codepoints-to-string((10, 48))"/>
   <xsl:variable name="string-5" as="xs:string" select="codepoints-to-string((10, 49))"/>
   <xsl:variable name="diff-1" as="element()" select="tan:diff($string-1, $string-2, false())"/>
   <xsl:variable name="diff-2" as="element()" select="tan:diff($string-2, $string-3, false())"/>
   <!--<xsl:variable name="delta-1" as="document-node()" select="tan:diff-to-delta($diff-1)"/>-->
   <!--<xsl:variable name="delta-2" as="document-node()" select="tan:diff-to-delta($diff-2)"/>-->
   
   
   <xsl:variable name="TAN-A-lm-uri-1" as="xs:anyURI"
      select="resolve-uri('../examples/TAN-A-lm/ar.cat.grc.1949.minio-paluello-sem-TAN-A-lm-sample.xml', static-base-uri())"
   />
   <xsl:variable name="TAN-A-lm-uri-2" as="xs:anyURI"
      select="resolve-uri('../../library-arithmeticus/evagrius/cpg2455/cpg2455.grc.2021.rondeau.TAN-A-lm.working.sample.xml', static-base-uri())"
   />
   
   <xsl:variable name="TAN-A-lm-doc-1" as="document-node()?" select="doc($TAN-A-lm-uri-1)"/>
   <xsl:variable name="TAN-A-lm-doc-2" as="document-node()?" select="doc($TAN-A-lm-uri-2)"/>
   
   
   <xsl:variable name="tan-mor-grc-orig-uri" as="xs:anyURI" select="resolve-uri('../../library-lm/grc/grc.perseus.tan-mor.xml', static-base-uri())"/>
   <xsl:variable name="tan-mor-grc-readable-uri" as="xs:anyURI" select="resolve-uri('../../library-lm/grc/grc.perseus.readable.tan-mor.xml', static-base-uri())"/>
   <xsl:variable name="tan-mor-lat-orig" as="document-node()"
      select="tan:resolve-doc(doc(resolve-uri('../../library-lm/lat/lat.perseus.tan-mor.xml', static-base-uri())))"
   />
   <xsl:variable name="tan-mor-lat-readable" as="document-node()"
      select="tan:resolve-doc(doc(resolve-uri('../../library-lm/lat/lat.perseus.readable.tan-mor.xml', static-base-uri())))"
   />
   <xsl:variable name="tan-mor-grc-orig" as="document-node()"
      select="tan:resolve-doc(doc($tan-mor-grc-orig-uri))"/>
   <xsl:variable name="tan-mor-grc-readable" as="document-node()"
      select="tan:resolve-doc(doc($tan-mor-grc-readable-uri))"/>
   
   <!--<xsl:variable name="tan-mor-lat-orig-feature-and-rule-tree" as="document-node()" select="tan:tan-mor-feature-and-rule-tree($tan-mor-lat-orig)"/>
   <xsl:variable name="tan-mor-lat-readable-feature-and-rule-tree" as="document-node()" select="tan:tan-mor-feature-and-rule-tree($tan-mor-lat-readable)"/>
   <xsl:variable name="tan-mor-grc-orig-feature-and-rule-tree" as="document-node()" select="tan:tan-mor-feature-and-rule-tree($tan-mor-grc-orig)"/>
   <xsl:variable name="tan-mor-grc-readable-feature-and-rule-tree" as="document-node()" select="tan:tan-mor-feature-and-rule-tree($tan-mor-grc-readable)"/>
   
   
   <xsl:variable name="tan-mor-grcX-to-grc1" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-grc-orig, $tan-mor-grc-readable)"/>
   <xsl:variable name="tan-mor-grc1-to-grcX" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-grc-readable, $tan-mor-grc-orig)"/>
   <xsl:variable name="tan-mor-grc1-to-lat1" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-grc-readable, $tan-mor-lat-readable)"/>
   <xsl:variable name="tan-mor-lat1-to-grc1" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-lat-readable, $tan-mor-grc-readable)"/>
   <xsl:variable name="tan-mor-grcX-to-latX" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-grc-orig, $tan-mor-lat-orig)"/>
   <xsl:variable name="tan-mor-latX-to-grcX" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-lat-orig, $tan-mor-grc-orig)"/>
   <xsl:variable name="tan-mor-grc1-to-latX" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-grc-readable, $tan-mor-lat-orig)"/>
   <xsl:variable name="tan-mor-latX-to-grc1" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-lat-orig, $tan-mor-grc-readable)"/>
   <xsl:variable name="tan-mor-grcX-to-lat1" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-grc-orig, $tan-mor-lat-readable)"/>
   <xsl:variable name="tan-mor-lat1-to-grcX" as="document-node()"
      select="tan:tan-mor-conversion($tan-mor-lat-readable, $tan-mor-grc-orig)"/>
   
   <xsl:variable name="conversion-1" as="document-node()?" select="tan:convert-TAN-A-lm-codes($TAN-A-lm-doc-2, $tan-mor-grc-readable-uri)"/>
   <xsl:variable name="conversion-2" as="document-node()?" select="tan:convert-TAN-A-lm-codes($conversion-1, $tan-mor-grc-orig-uri)"/>
   -->
   <xsl:variable name="search-results-1" as="element()*">
      <claims xmlns="tag:textalign.net,2015:ns">
         <claimant>
            <algorithm>
               <IRI>tag:textalign.net,2015:algorithm:org.perseus:tools:morpheus.v1</IRI>
               <name>Tufts morphology service</name>
            </algorithm>
         </claimant>
         <claim-when>2020-01-01T00:00:00.000000</claim-when>
         <ana>
            <for-lang>grc-Attic</for-lang>
            <for-lang>grc-epic</for-lang>
            <for-lang>grc-Ionic</for-lang>
            <tok val="ἀγάπη"/>
            <lm>
               <l>ἀγάπη</l>
               <m cert="0.5">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Noun</IRI>
                     <IRI>tag:textalign.net,2015:feature:Noun</IRI>
                     <name>noun</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Nominative</IRI>
                     <IRI>tag:textalign.net,2015:feature:Nominative</IRI>
                     <name>nominative</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Feminine</IRI>
                     <IRI>tag:textalign.net,2015:feature:Feminine</IRI>
                     <name>feminine</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
               </m>
               <m cert="0.5">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Noun</IRI>
                     <IRI>tag:textalign.net,2015:feature:Noun</IRI>
                     <name>noun</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#VocativeCase</IRI>
                     <IRI>tag:textalign.net,2015:feature:VocativeCase</IRI>
                     <name>case vocative</name>
                     <name>vocative case</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Feminine</IRI>
                     <IRI>tag:textalign.net,2015:feature:Feminine</IRI>
                     <name>feminine</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
               </m>
            </lm>
         </ana>
         <ana>
            <for-lang>grc-Doric</for-lang>
            <for-lang>grc-Aeolic</for-lang>
            <for-lang>grc-epic</for-lang>
            <for-lang>grc-Ionic</for-lang>
            <for-lang>grc-Homeric</for-lang>
            <tok val="ἀγάπη"/>
            <lm>
               <l>ἀγαπάω</l>
               <m cert="0.2">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Verb</IRI>
                     <IRI>tag:textalign.net,2015:feature:Verb</IRI>
                     <name>verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#IndicativeMood</IRI>
                     <IRI>tag:textalign.net,2015:feature:IndicativeMood</IRI>
                     <name>mood indicative</name>
                     <name>indicative mood</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Imperfect</IRI>
                     <IRI>tag:textalign.net,2015:feature:Imperfect</IRI>
                     <name>imperfect</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ActiveVoice</IRI>
                     <IRI>tag:textalign.net,2015:feature:ActiveVoice</IRI>
                     <name>voice active</name>
                     <name>active voice</name>
                  </feature>
               </m>
               <m cert="0.2">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Verb</IRI>
                     <IRI>tag:textalign.net,2015:feature:Verb</IRI>
                     <name>verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ImperativeVerb</IRI>
                     <IRI>tag:textalign.net,2015:feature:ImperativeVerb</IRI>
                     <name>verb imperative</name>
                     <name>imperative verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Present</IRI>
                     <IRI>tag:textalign.net,2015:feature:Present</IRI>
                     <name>present</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ActiveVoice</IRI>
                     <IRI>tag:textalign.net,2015:feature:ActiveVoice</IRI>
                     <name>voice active</name>
                     <name>active voice</name>
                  </feature>
               </m>
               <m cert="0.2">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Verb</IRI>
                     <IRI>tag:textalign.net,2015:feature:Verb</IRI>
                     <name>verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#IndicativeMood</IRI>
                     <IRI>tag:textalign.net,2015:feature:IndicativeMood</IRI>
                     <name>mood indicative</name>
                     <name>indicative mood</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Imperfect</IRI>
                     <IRI>tag:textalign.net,2015:feature:Imperfect</IRI>
                     <name>imperfect</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ActiveVoice</IRI>
                     <IRI>tag:textalign.net,2015:feature:ActiveVoice</IRI>
                     <name>voice active</name>
                     <name>active voice</name>
                  </feature>
               </m>
               <m cert="0.2">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Verb</IRI>
                     <IRI>tag:textalign.net,2015:feature:Verb</IRI>
                     <name>verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ImperativeVerb</IRI>
                     <IRI>tag:textalign.net,2015:feature:ImperativeVerb</IRI>
                     <name>verb imperative</name>
                     <name>imperative verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Present</IRI>
                     <IRI>tag:textalign.net,2015:feature:Present</IRI>
                     <name>present</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ActiveVoice</IRI>
                     <IRI>tag:textalign.net,2015:feature:ActiveVoice</IRI>
                     <name>voice active</name>
                     <name>active voice</name>
                  </feature>
               </m>
               <m cert="0.2">
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Verb</IRI>
                     <IRI>tag:textalign.net,2015:feature:Verb</IRI>
                     <name>verb</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#IndicativeMood</IRI>
                     <IRI>tag:textalign.net,2015:feature:IndicativeMood</IRI>
                     <name>mood indicative</name>
                     <name>indicative mood</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Singular</IRI>
                     <IRI>tag:textalign.net,2015:feature:Singular</IRI>
                     <name>singular</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#Imperfect</IRI>
                     <IRI>tag:textalign.net,2015:feature:Imperfect</IRI>
                     <name>imperfect</name>
                  </feature>
                  <feature>
                     <affects-element>feature</affects-element>
                     <IRI>http://purl.org/olia/olia.owl#ActiveVoice</IRI>
                     <IRI>tag:textalign.net,2015:feature:ActiveVoice</IRI>
                     <name>voice active</name>
                     <name>active voice</name>
                  </feature>
               </m>
            </lm>
         </ana>
         <lex><!--No standard TAN format exists for lexical information-->
            <for-lang>grc</for-lang>
            <headword>ἀγάπη</headword>
            <feature>
               <affects-element>feature</affects-element>
               <IRI>http://purl.org/olia/olia.owl#Noun</IRI>
               <IRI>tag:textalign.net,2015:feature:Noun</IRI>
               <name>noun</name>
            </feature>
            <feature>
               <affects-element>feature</affects-element>
               <IRI>http://purl.org/olia/olia.owl#Feminine</IRI>
               <IRI>tag:textalign.net,2015:feature:Feminine</IRI>
               <name>feminine</name>
            </feature>
         </lex>
         <lex><!--No standard TAN format exists for lexical information-->
            <for-lang>grc</for-lang>
            <headword>ἀγαπάω</headword>
            <feature>
               <affects-element>feature</affects-element>
               <IRI>http://purl.org/olia/olia.owl#Verb</IRI>
               <IRI>tag:textalign.net,2015:feature:Verb</IRI>
               <name>verb</name>
            </feature>
         </lex>
      </claims>
   </xsl:variable>
   
   <!--<xsl:variable name="search-results-2" as="element()*" select="tan:lm-data('ἀγάπη', 'grc')"/>-->
   
   <xsl:template match="tei:s/text()" mode="tan:core-expansion-ad-hoc-pre-pass"/>
   
   <xsl:variable name="testStr" as="xs:string" select="'SV9hZG1pcmU6eW91cl9za2lsbHM='"/>
   
   <xsl:template match="/">
      <xsl:variable name="values" select="(1,2,3,4,5)" as="xs:double+"/>
      <test-common>
         <!--<xsl:copy-of select="tan:base64Binary-to-eight-bit-chars(xs:base64Binary($testStr))"/>-->
         <!--<xsl:copy-of select="tan:base64-to-base64Binary($testStr), tan:base64-to-hex($testStr)"/>-->
        <!--<morph-search><xsl:copy-of select="tan:search-morpheus('ἀγάπη')"/></morph-search>--> 
        <!--<morph-search><xsl:copy-of select="tan:search-morpheus('ἀγάπη') => tan:search-results-to-claims('morpheus')"/></morph-search>--> 
        <!--<morph-search-2><xsl:copy-of select="$search-results-2"/></morph-search-2>--> 
         <!--<tan-mor-grc-orig><xsl:copy-of select="$tan-mor-grc-orig"/></tan-mor-grc-orig>-->
         <!--<tan-mor-grc-readable><xsl:copy-of select="$tan-mor-grc-readable"/></tan-mor-grc-readable>-->
         <!--<tan-mor-feature-and-rule-tree-1><xsl:copy-of select="$tan-mor-grc-orig-feature-and-rule-tree"/></tan-mor-feature-and-rule-tree-1>-->
         <!--<tan-mor-feature-and-rule-tree-2><xsl:copy-of select="$tan-mor-grc-readable-feature-and-rule-tree"/></tan-mor-feature-and-rule-tree-2>-->
         <!--<get-lm-data-conversion><xsl:copy-of select="tan:convert-lm-data-output($search-results-1, $tan-mor-grc-readable-uri)"/></get-lm-data-conversion>-->
         <!--<get-lm-data-conversion><xsl:copy-of select="tan:convert-lm-data-output($search-results-2, $tan-mor-grc-readable-uri)"/></get-lm-data-conversion>-->
         <!--<tan-mor-grcX-to-grc1><xsl:copy-of select="$tan-mor-grcX-to-grc1"/></tan-mor-grcX-to-grc1>
         <tan-mor-grc1-to-grcX><xsl:copy-of select="$tan-mor-grc1-to-grcX"/></tan-mor-grc1-to-grcX>
         <tan-mor-grc1-to-lat1><xsl:copy-of select="$tan-mor-grc1-to-lat1"/></tan-mor-grc1-to-lat1>
         <tan-mor-lat1-to-grc1><xsl:copy-of select="$tan-mor-lat1-to-grc1"/></tan-mor-lat1-to-grc1>-->
         <!--<tan-mor-grcX-to-latX><xsl:copy-of select="$tan-mor-grcX-to-latX"/></tan-mor-grcX-to-latX>-->
         <!--<tan-mor-latX-to-grcX><xsl:copy-of select="$tan-mor-latX-to-grcX"/></tan-mor-latX-to-grcX>-->
         <!--<tan-mor-grc1-to-latX><xsl:copy-of select="$tan-mor-grc1-to-latX"/></tan-mor-grc1-to-latX>-->
         <!--<tan-mor-latX-to-grc1><xsl:copy-of select="$tan-mor-latX-to-grc1"/></tan-mor-latX-to-grc1>-->
         <!--<tan-mor-grcX-to-lat1><xsl:copy-of select="$tan-mor-grcX-to-lat1"/></tan-mor-grcX-to-lat1>-->
         <!--<tan-mor-lat1-to-grcX><xsl:copy-of select="$tan-mor-lat1-to-grcX"/></tan-mor-lat1-to-grcX>-->
         <!--<TAN-A-mor-1-resolved><xsl:copy-of select="tan:resolve-doc($TAN-A-lm-doc-2) => tan:trim-long-tree(20, 40)"/></TAN-A-mor-1-resolved>-->
         <!--<TAN-A-mor-1-converted><xsl:copy-of select="$conversion-1 => tan:trim-long-tree(20, 40)"/></TAN-A-mor-1-converted>-->
         <!--<TAN-A-mor-2-converted><xsl:copy-of select="$conversion-2 => tan:trim-long-tree(20, 40)"/></TAN-A-mor-2-converted>-->
         <!--<conversion-1-and-2-compared><xsl:copy-of select="tan:diff(serialize($TAN-A-lm-doc-2), serialize($conversion-2))"/></conversion-1-and-2-compared>-->
         <!--<diff-test>
            <s4><xsl:value-of select="$string-4"/></s4>
            <s5><xsl:value-of select="$string-5"/></s5>
            <xsl:copy-of select="tan:diff($string-4, $string-5, false())"/>
         </diff-test>-->
         <!--<diff-1><xsl:copy-of select="$diff-1"/></diff-1>
         <diff-1-common><xsl:value-of select="string-join($diff-1/tan:common)"/></diff-1-common>
         <delta-1><xsl:copy-of select="$delta-1"/></delta-1>
         <diff-2><xsl:copy-of select="$diff-2"/></diff-2>
         <diff-2-common><xsl:value-of select="string-join($diff-2/tan:common)"/></diff-2-common>
         <delta-2><xsl:copy-of select="$delta-2"/></delta-2>
         <apply-deltas><xsl:copy-of select="tan:apply-deltas($string-3, ($delta-1, $delta-2))"/></apply-deltas>-->
         <!--<unique-char><xsl:copy-of select="tan:unique-char(('abcd', '!@#$', 'βψγ'))"/></unique-char>-->
         <!--<voc><xsl:copy-of select="tan:vocabulary('person', '*')"/></voc>-->
         <self-resolved><xsl:copy-of select="$tan:self-resolved"/></self-resolved>
         <!--<self-expanded count="{count($tan:self-expanded)}"><xsl:copy-of select="$tan:self-expanded"/></self-expanded>-->
         <!--<vocabularies-resolved><xsl:copy-of select="$tan:vocabularies-resolved"/></vocabularies-resolved>-->
         <!--<source-docs><xsl:copy-of select="tan:get-1st-doc($tan:head/tan:source)"/></source-docs>-->
         <!--<sources-resolved-plus><xsl:copy-of select="tan:get-and-resolve-dependency($tan:self-resolved/*/tan:head/tan:source)"/></sources-resolved-plus>-->
         <!--<sources-resolved count="{count($tan:sources-resolved)}"><xsl:copy-of select="tan:shallow-copy($tan:sources-resolved/*)"/></sources-resolved>-->
         <!--<redivisions-resolved count="{count($tan:redivisions-resolved)}"><xsl:copy-of select="$tan:redivisions-resolved"/></redivisions-resolved>-->
         <!--<model><xsl:copy-of select="$tan:model-resolved"/></model>-->
      </test-common>
      
      
   </xsl:template>
   
</xsl:stylesheet>
