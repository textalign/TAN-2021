<xsl:stylesheet exclude-result-prefixes="#all"  
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- Core general variables for the TAN function library. -->
   
   <xsl:variable name="tan:TAN-version" as="xs:string">2021</xsl:variable>
   <xsl:variable name="tan:TAN-version-is-under-development" as="xs:boolean" select="false()"/>
   <xsl:variable name="tan:previous-TAN-versions" select="('1 dev', '2018', '2020')"/>
   <xsl:variable name="tan:internet-available" as="xs:boolean">
      <xsl:choose>
         <xsl:when test="$tan:do-not-access-internet eq true()">
            <xsl:value-of select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of
               select="unparsed-text-available('https://google.com') or unparsed-text-available('https://www.w3.org')"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>
   <xsl:variable name="tan:regex-characters-not-permitted" as="xs:string"
      >[&#xA0;&#x2000;-&#x200a;]</xsl:variable>
   <xsl:variable name="tan:regex-name-space-characters" as="xs:string">[_-]</xsl:variable>
   <xsl:variable name="tan:char-regex" as="xs:string">\P{M}\p{M}*</xsl:variable>
   <xsl:variable name="tan:quot" as="xs:string">"</xsl:variable>
   <xsl:variable name="tan:apos" as="xs:string">'</xsl:variable>
   <xsl:variable name="tan:zwsp" as="xs:string">&#x200b;</xsl:variable>
   <xsl:variable name="tan:zwj" as="xs:string">&#x200d;</xsl:variable>
   <!-- discretionary hyphens and soft hyphens are synonymous. -->
   <xsl:variable name="tan:dhy" as="xs:string">&#xad;</xsl:variable>
   <xsl:variable name="tan:shy" as="xs:string" select="$tan:dhy"/>
   <xsl:variable name="tan:special-end-div-chars" select="($tan:zwj, $tan:dhy, $tan:zwsp)" as="xs:string+"/>
   <xsl:variable name="tan:special-end-div-chars-regex"
      select="'([' || string-join($tan:special-end-div-chars) || '])\s*$'" as="xs:string"/>
   
   <!-- Parts of a transcription that specify a line, column, or page break; these should be excluded from transcriptions and be rendered with markup -->
   <xsl:variable name="tan:break-marker-regex" as="xs:string">[\|‖  ⁣￺]</xsl:variable>
   
   <xsl:variable name="tan:hex-key" as="xs:string+"
      select="('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')"/>
   <xsl:variable name="tan:base26-key" as="xs:string+"
      select="('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z')"/>
   <xsl:variable name="tan:base64-key" as="xs:string+"
      select="($tan:base26-key, 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/')"/>
   
   
   
   
   <xsl:variable name="tan:datatypes-that-require-unit-specification" as="xs:string+" select="('decimal', 'float', 'double', 'integer', 'nonPositiveInteger', 'negativeInteger', 'long', 'nonNegativeInteger', 'positiveInteger')"/>
   
   
   <xsl:variable name="tan:empty-doc" as="document-node()">
      <xsl:document/>
   </xsl:variable>
   
   <xsl:variable name="tan:empty-element" as="element()">
      <empty/>
   </xsl:variable>
   <xsl:variable name="tan:erroneously-looped-doc" as="document-node()">
      <xsl:document>
         <xsl:copy-of select="tan:error('inc03')"/>
      </xsl:document>
   </xsl:variable>
   
   <xsl:variable name="tan:now" select="tan:dateTime-to-decimal(current-dateTime())"/>
   
   <xsl:variable name="tan:tan-classes" as="element()">
      <tan>
         <class n="1">
            <root>TAN-T</root>
            <root>TEI</root>
         </class>
         <class n="2">
            <root>TAN-A</root>
            <root>TAN-A-tok</root>
            <root>TAN-A-lm</root>
         </class>
         <class n="3">
            <root>TAN-mor</root>
            <root>TAN-voc</root>
         </class>
      </tan>
   </xsl:variable>
   
   
   <xsl:variable name="tan:names-of-attributes-that-take-idrefs" as="xs:string+" select="$tan:id-idrefs/tan:id-idrefs/tan:id/tan:idrefs/@attribute"/>
   <xsl:variable name="tan:names-of-attributes-that-may-take-multiple-space-delimited-values" as="xs:string+"
      select="$tan:names-of-attributes-that-take-idrefs, ('affects-element', 'affects-attribute', 'item-type')"/>
   <xsl:variable name="tan:names-of-attributes-that-permit-keyword-last" as="xs:string+" select="('pos', 'chars', 'm-has-how-many-features')"/>
   <xsl:variable name="tan:names-of-attributes-that-are-case-indifferent" as="xs:string+" select="('n', 'ref', 'affects-element', 'affects-attribute', 'item-type', 'in-lang')"/>
   <xsl:variable name="tan:names-of-elements-that-take-idrefs" as="xs:string+" select="$tan:id-idrefs/tan:id-idrefs/tan:id/tan:idrefs/@element"/>
   <xsl:variable name="tan:names-of-elements-that-take-which" as="xs:string+"
      select="('object', 'unit', 'lexicon', 'license', 'see-also', 'work', 'role', 'source', 'group-type', 'morphology', 'source', 'work', 'verb', 'scriptum', 'relationship', 'person', 'period', 'organization', 'div-type', 'algorithm', 'vocabulary', 'successor', 'source', 'predecessor', 'inclusion', 'companion-version', 'token-definition', 'bitext-relation', 'checksum', 'redivision', 'model', 'annotation', 'version', 'normalization', 'item', 'feature', 'version', 'reuse-type', 'topic', 'place', 'modal', 'subject', 'at-ref')"
   />
   <xsl:variable name="tan:names-of-elements-that-must-always-refer-to-tan-files" as="xs:string+"
      select="('morphology', 'inclusion', 'vocabulary', 'redivision', 'model', 'successor', 'annotation')"/>
   <xsl:variable name="tan:names-of-elements-that-describe-text-creators" as="xs:string+" select="('person', 'organization')"/>
   <xsl:variable name="tan:names-of-elements-that-describe-text-bearers" as="xs:string+" select="('scriptum', 'work', 'version', 'source')"/>
   <xsl:variable name="tan:names-of-elements-that-make-adjustments" as="xs:string+" select="('skip', 'rename', 'equate', 'reassign')"/>
   <xsl:variable name="tan:names-of-elements-that-describe-textual-entities"
      select="$tan:names-of-elements-that-describe-text-creators, $tan:names-of-elements-that-describe-text-bearers"/>
   <xsl:variable name="tan:names-of-elements-targeted-by-subjects"
      select="$tan:id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@attribute = 'subject']]/tan:element"/>
   <xsl:variable name="tan:names-of-elements-targeted-by-objects"
      select="$tan:id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@attribute = 'object']]/tan:element"/>
   
   <xsl:variable name="tan:tag-urn-regex-pattern" as="xs:string"
      select="'tag:([\-a-zA-Z0-9._%+]+@)?[\-a-zA-Z0-9.]+\.[A-Za-z]{2,4},\d{4}(-(0\d|1[0-2]))?(-([0-2]\d|3[01]))?:\S+'"/>
   <xsl:variable name="tan:attr-n-regex" as="xs:string" select="'^[\w/_]+([\- ,;]+[\w/_]+)*$'"/>
   
   <!-- The next variable contains the map between elements and attributes that may point to names or ids of those elements -->
   <xsl:variable name="tan:id-idrefs" as="document-node()" select="doc('TAN-idrefs.xml')"/>
   
   <xsl:variable name="tan:TAN-namespace" select="'tag:textalign.net,2015:ns'"/>
   <xsl:variable name="tan:TEI-namespace" select="'http://www.tei-c.org/ns/1.0'"/>
   <xsl:variable name="tan:TAN-id-namespace" select="'tag:textalign.net,2015'"/>
   
   <xsl:variable name="tan:validation-phase-names" select="('terse', 'normal', 'verbose')"
      as="xs:string+"/>
   <xsl:variable name="tan:stated-validation-phase" as="xs:string?">
      <xsl:analyze-string select="string-join(/processing-instruction(), '')"
         regex="phase\s*=\s*.([a-z]+)">
         <xsl:matching-substring>
            <xsl:value-of select="lower-case(regex-group(1))"/>
         </xsl:matching-substring>
      </xsl:analyze-string>
   </xsl:variable>
   
   <!-- A major separator is meant to delimit hierarchies from each other, e.g., source, ref, and token-->
   <xsl:variable name="tan:separator-major" select="'##'" as="xs:string"/>
   <!-- A hierarchy separator is meant to delimit levels in a reference hierarchy, e.g., within @ref -->
   <xsl:variable name="tan:separator-hierarchy" select="' '" as="xs:string"/>
   <!-- A hierarchy separator is meant to delimit parts of a complex number, e.g., a letter + numeral combined, e.g., 7b becomes 7#2  -->
   <xsl:variable name="tan:separator-hierarchy-minor" select="'#'" as="xs:string"/>
   <xsl:variable name="tan:all-selector" select="'*'" as="xs:string+"/>
   
   
   <!-- URN namespaces come from the Official IANA Registry of URN Namespaces, 
      https://www.iana.org/assignments/urn-namespaces/urn-namespaces.xhtml, accessed 2021-09-04 -->
   <xsl:variable name="tan:official-urn-namespaces" as="xs:string+"
      select="('3gpp', '3gpp2', 'adid', 'alert', 'bbf', 'broadband-forum-org', 'cablelabs', 'ccsds', 'cgi', 'clei', 'ddi', 'dev', 
      'dgiwg', 'dslforum-org', 'dvb', 'ebu', 'eidr', 'epc', 'epcglobal', 'etsi', 'eurosystem', 'example', 'fdc', 'fipa', 'geant', 
      'globus', 'gsma', 'hbbtv', 'ieee', 'ietf', 'iptc', 'isan', 'isbn', 'iso', 'issn', 'itu', 'ivis', 'liberty', 'mace', 'mef', 
      'mpeg', 'mrn', 'nato', 'nbn', 'nena', 'newsml', 'nfc', 'nzl', 'oasis', 'ogc', 'ogf', 'oid', 'oipf', 'oma', 'onf', 'pin', 
      'publicid', 'reso', 's1000d', 'schac', 'service', 'smpte', 'swift', 'tva', 'uci', 'ucode', 'uuid', 'web3d', 'xmlorg', 'xmpp', 
      'urn-1', 'urn-2', 'urn-3', 'urn-4', 'urn-5', 'urn-6', 'urn-7')"
   />
   
   <xsl:variable name="tan:drop-self-content" as="xs:boolean"
      select="$tan:validation-mode-on and $tan:validation-is-empty"/>
   
   <!-- TAN file components -->
   
   <!-- self -->
   <!-- We make a copy of the original, because much later in the process we will need to compare it against target files. -->
   <xsl:variable name="tan:orig-self" select="/" as="document-node()"/>
   <xsl:variable name="tan:self-resolved" select="
         if ($tan:drop-self-content) then
            $tan:empty-doc
         else
            tan:resolve-doc(/)" as="document-node()"/>
   <!-- More than one document is allowed in self expansions, because class-2 expansions must go hand-in-hand with the expansion of their class-1 dependencies. -->
   <xsl:variable name="tan:self-expanded" select="tan:expand-doc($tan:self-resolved)" as="document-node()+"/>
   
   <xsl:variable name="tan:head" as="element()?" select="
         if (exists(/*/tan:head)) then
            $tan:self-resolved/*/tan:head
         else
            /*/*:head"/>
   
   <xsl:variable name="tan:body" as="element()?" select="
         if ($tan:doc-namespace = $tan:TAN-namespace) then
            $tan:self-resolved/*/(tan:body, tei:text/tei:body)
         else
            //*:body"/>
   <xsl:variable name="tan:doc-id" select="/*/@id" as="attribute(id)?"/>
   <xsl:variable name="tan:doc-is-error-test" select="matches($tan:doc-id, '^tag:textalign.net,\d+:error-test')"/>
   <xsl:variable name="tan:doc-type" select="local-name(/*)" as="xs:string"/>
   <xsl:variable name="tan:doc-class" select="tan:class-number($tan:self-resolved)" as="xs:integer?"/>
   <xsl:variable name="tan:doc-uri" select="base-uri(/*)" as="xs:anyURI"/>
   <xsl:variable name="tan:doc-parent-directory" as="xs:string"
      select="tan:uri-directory(string($tan:doc-uri))"/>
   <xsl:variable name="tan:source-ids" as="xs:string*" select="
         if (exists($tan:head/tan:source/@xml:id)) then
            $tan:head/tan:source/@xml:id
         else
            for $i in (1 to count($tan:head/tan:source))
            return
               string($i)"/>
   
   <xsl:variable name="tan:all-head-iris" as="element(tan:IRI)*"
      select="$tan:head/(* except (tan:inclusion | tan:vocabulary | tan:tan-vocabulary))//tan:IRI[not(ancestor::tan:error)]"/>
   <xsl:variable name="tan:duplicate-head-iris" as="element(tan:IRI)*" select="tan:duplicate-items($tan:all-head-iris)"/>
   <xsl:variable name="tan:doc-namespace" as="xs:anyURI" select="namespace-uri(/*)"/>
   <xsl:variable name="tan:doc-id-namespace" as="xs:string?" select="tan:doc-id-namespace($tan:self-resolved)"/>
   <xsl:variable name="tan:primary-agents" select="$tan:head/tan:file-resp" as="element(tan:file-resp)*"/>
   <xsl:variable name="tan:src-ids" as="xs:string*">
      <xsl:for-each select="$tan:head/tan:source">
         <xsl:value-of select="(@xml:id, string(position()))[1]"/>
      </xsl:for-each>
   </xsl:variable>
   
   <!-- catalogs -->
   <xsl:variable name="tan:doc-catalog-uris" select="tan:catalog-uris(/)" as="xs:string*"/>
   <xsl:variable name="tan:doc-catalogs" select="tan:catalogs(/, $tan:default-validation-phase eq 'verbose')"
      as="document-node()*"/>
   <xsl:variable name="tan:local-catalog" select="$tan:doc-catalogs[1]" as="document-node()?"/>
   
   <!-- inclusions -->
   <xsl:variable name="tan:inclusions-resolved"
      select="tan:get-and-resolve-dependency(/*/tan:head/tan:inclusion)" as="document-node()*"/>
   
   <!-- vocabularies -->

   <!-- What elements are not covered by TAN files -->
   <xsl:variable name="tan:elements-supported-by-TAN-vocabulary-files" as="xs:string+"
      select="
      ('bitext-relation', 'div-type', 'feature', 'group-type', 'license', 'modal', 'normalization',
      'reuse-type', 'role', 'token-definition', 'verb', 'vocabulary')"/>
   <!-- vocabularies: explicit, non-standard; we retain tan:key to handle older versions of TAN -->
   <xsl:variable name="tan:vocabularies-resolved" as="document-node()*"
      select="tan:get-and-resolve-dependency($tan:head/(tan:vocabulary, tan:key[tan:location]))"/>
   <!-- vocabularies: standard TAN -->
   <xsl:variable name="tan:TAN-vocabulary-files" as="document-node()*"
      select="collection('../../vocabularies/collection.xml')"/>
   <!-- We do not have $TAN-vocabularies-resolved since tan:resolve-doc() depends upon standard vocabularies already prepared independently -->
   <!-- TAN vocabularies are already written so as to need minimal resolution or expansion -->
   <xsl:variable name="tan:TAN-vocabularies" as="document-node()*">
      <xsl:apply-templates select="$tan:TAN-vocabulary-files[tan:TAN-voc]" mode="tan:expand-standard-tan-voc">
         <xsl:with-param name="add-q-ids" tunnel="yes" select="false()"/>
         <xsl:with-param name="is-reserved" select="true()" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:variable>
   <xsl:variable name="tan:all-vocabularies" select="($tan:vocabularies-resolved, $tan:TAN-vocabularies)"
      as="document-node()*"/>
   <xsl:variable name="tan:TAN-vocabularies-vocabulary" as="document-node()*"
      select="$tan:TAN-vocabularies[tan:TAN-voc/tan:body[@affects-element = 'vocabulary']]"/>
   <xsl:variable name="tan:extra-vocabulary-files" as="document-node()*" select="
         for $i in $tan:TAN-vocabularies-vocabulary/tan:TAN-voc/tan:body/tan:item[tan:location]
         return
            tan:get-1st-doc($i)"/>
   <!-- The following variable fetches vocabulary available after resolution. But TAN-A files attract as <work> vocabulary
   the items from their sources, and that happens only after expansion. -->
   <xsl:variable name="tan:doc-vocabulary" as="element()*"
      select="tan:vocabulary((), (), ($tan:head, $tan:self-resolved/(tan:TAN-A, tan:TAN-voc)/tan:body))"/>
   
   <!-- redivisions -->
   <xsl:variable name="tan:redivisions-1st-da" select="tan:get-1st-doc($tan:head/tan:redivision)"
      as="document-node()*"/>
   <xsl:variable name="tan:redivisions-resolved" as="document-node()*" select="
         for $i in $tan:redivisions-1st-da
         return
            tan:resolve-doc($i, false(), tan:attr('relationship', 'redivision'))"/>
   
   <!-- models -->
   <xsl:variable name="tan:model-1st-da" select="tan:get-1st-doc($tan:head/tan:model[1])"/>
   <xsl:variable name="tan:model-resolved"
      select="tan:resolve-doc($tan:model-1st-da, false(), tan:attr('relationship', 'model'))"/>
   
   
   
   <!-- sources -->
   <xsl:variable name="tan:sources-resolved" as="document-node()*" select="
         for $i in $tan:head/tan:source
         return
            tan:resolve-doc(tan:get-1st-doc($i), true(), tan:attr('src', ($i/@xml:id, '1')[1]))"
   />
   
   <!-- morphologies -->
   <xsl:variable name="tan:morphologies-resolved" as="document-node()*" select="
         for $i in $tan:head/tan:vocabulary-key/tan:morphology
         return
            tan:resolve-doc(tan:get-1st-doc($i), true(), tan:attr('morphology', ($i/@xml:id, '1')[1]))"
   />
   
   <!-- token definitions -->
   <xsl:variable name="tan:token-definitions-reserved" as="element()*"
      select="$tan:TAN-vocabularies//tan:token-definition"/>
   <xsl:variable name="tan:token-definition-letters-only" as="element()?"
      select="$tan:token-definitions-reserved[../tan:name = 'letters only']"/>
   <xsl:variable name="tan:token-definition-letters-and-punctuation" as="element()?"
      select="$tan:token-definitions-reserved[../tan:name = 'letters and punctuation']"/>
   <xsl:variable name="tan:token-definition-nonspace" as="element()?"
      select="$tan:token-definitions-reserved[../tan:name = 'nonspace']"/>
   <xsl:variable name="tan:token-definition-default" as="element()?"
      select="$tan:token-definitions-reserved[1]" use-when="$tan:validation-mode-on"/>
   
   
   
   

</xsl:stylesheet>
