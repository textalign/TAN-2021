<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Core application for creating a TAN-A-lm file. -->
    
    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    <!-- TODO: create function to make a TAN-A-lm file -->
    <!--<xsl:include href="make-TAN-A-lm.xsl"/>-->
    
    <xsl:output indent="yes"/>
    
    <!--<xsl:param name="tan:distribute-vocabulary" as="xs:boolean" select="not($retain-morphological-codes-as-is)"/>-->
    
    <!-- About this stylesheet -->
    
    <!-- The predecessor to this stylesheet is tag:textalign.net,2015:stylesheet:create-quotations-from-tan-a -->
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:create-tan-a-lm'"/>
    <xsl:param name="tan:stylesheet-name" as="xs:string" select="'TAN-A-lm Builder'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'creates a TAN-A-lm file for a class 1 file'"/>
    <xsl:param name="tan:stylesheet-description" as="xs:string">Well-curated lexico-morphological
        data is highly valuable for a variety of applications such as quotation detection,
        stylometric analysis, and machine translation. This application will process any TAN-T or
        TAN-TEI file through existing TAN-A-lm language libraries, and online search services,
        looking for the best lexico-morphological profiles for the file's tokens.</xsl:param>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">a class 1 file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">a TAN-A-lm template;
        language catalogs; perhaps language search services</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">a new TAN-A-lm file freshly
        populated with lexicomorphological data, sorted with unmatched tokens at the top, followed by 
        ambiguous ones, followed by non-ambiguous ones</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>
    
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2021-04-10">What if the @xml:lang of the input doesn't
                match TAN-mor or language catalog files?</comment>
            <comment who="kalvesmaki" when="2021-04-10">What if a morphology has @which? Will it
                still work?</comment>
            <comment who="kalvesmaki" when="2021-04-10">Ensure the responsible repopulation of the
                metadata of the template</comment>
            <comment who="kalvesmaki" when="2021-09-06">Support false value for
                $retain-morphological-codes-as-is</comment>
        </to-do>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="
            'Generated lexico-morphological data for ' || $tan:doc-id
            || ' based on the following sources:&#xa;' || string-join($output-pass-4/tan:claimants/tan:claimant, '&#xa;')"
    />
    
    <!-- TEMPLATE, TAN-MOR -->
    
    <xsl:variable name="template-tan-a-lm-is-ok" as="xs:boolean" select="doc-available($template-tan-a-lm-uri-resolved)"/>
    <xsl:variable name="template-tan-a-lm-uri-resolved-norm" select="
            if ($template-tan-a-lm-resolved) then
                $template-tan-a-lm-uri-resolved
            else
                $tan:default-tan-a-lm-template-uri-resolved"/>
    <xsl:variable name="template-tan-a-lm-original" as="document-node()?" select="doc($template-tan-a-lm-uri-resolved)"/>
    <xsl:variable name="template-tan-a-lm-resolved" as="document-node()?"
        select="tan:resolve-doc($template-tan-a-lm-original)"/>
    
    <xsl:variable name="template-doc-default-morphology" select="$template-tan-a-lm-resolved/tan:TAN-A-lm/tan:body/@morphology"/>
    <xsl:variable name="template-morphology-vocabulary" as="element()*"
        select="tan:vocabulary('morphology', tokenize($template-doc-default-morphology, ' ')[1], $template-tan-a-lm-resolved/tan:TAN-A-lm/tan:head)"
    />
    <xsl:variable name="template-source-vocabulary" as="element()*"
        select="tan:vocabulary('source', (), $template-tan-a-lm-resolved/tan:TAN-A-lm/tan:head)"/>
    <xsl:variable name="default-tan-mor-file" select="tan:get-1st-doc($template-morphology-vocabulary/*[tan:location])[tan:TAN-mor][1]"/>
    <xsl:variable name="default-tan-mor-file-resolved" as="document-node()*"
        select="tan:resolve-doc($default-tan-mor-file)"/>
    <xsl:variable name="default-tan-mor-file-has-categories" select="exists($default-tan-mor-file-resolved/tan:TAN-mor/tan:body/tan:category)"/>
    <xsl:variable name="default-feature-vocabulary" as="element()*"
        select="tan:vocabulary('feature', (), $default-tan-mor-file-resolved/tan:TAN-mor/tan:head)"
    />
    
    <xsl:variable name="template-tan-a-lm-prepped-for-output" as="document-node()"
        select="tan:update-TAN-change-log($template-tan-a-lm-original)"/>
    <xsl:variable name="new-source-element" as="element()?">
        <xsl:if test="not($tan:doc-id = $template-source-vocabulary//tan:IRI)">
            <source>
                <IRI><xsl:value-of select="$tan:doc-id"/></IRI>
                <xsl:copy-of select="*/tan:head/tan:name"/>
                <location accessed-when="{current-date()}" href="{base-uri(/)}"/>
            </source>
        </xsl:if>
    </xsl:variable>
    
    <xsl:variable name="default-tok-indentation" as="xs:string"
        select="tan:fill(' ', xs:integer(avg(tan:indent-value($template-tan-a-lm-original/*/*/*/*))))"/>
    
    <xsl:variable name="notices" as="element()">
        <notices>
            <input>
                <xsl:if test="not($template-tan-a-lm-is-ok)">
                    <xsl:message select="'Supplied resolved URI for TAN-A-lm template, ' || $template-tan-a-lm-uri-resolved 
                        || ', does not point to a valid file. Trying instead ' || $template-tan-a-lm-uri-resolved-norm"/>
                </xsl:if>
            </input>
        </notices>
    </xsl:variable>
    
    <!-- LANGUAGES, LANGUAGE CATALOG FILES -->
    
    <xsl:param name="lang-catalogs" select="tan:lang-catalog($tan:self-resolved/(tan:TAN-T, tei:TEI/tei:text)/*:body/@xml:lang)"
        as="document-node()*"/>
    
    
    <!-- PASS 1: TOKENIZE -->
    <xsl:variable name="token-definition" as="element()"
        select="(tan:element-vocabulary($template-tan-a-lm-resolved/*/tan:head/tan:token-definition[1])//tan:token-definition,
        $template-tan-a-lm-resolved/*/tan:head/tan:token-definition[1], $tan:token-definition-default)[1]"
    />
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:apply-templates select="$tan:self-expanded" mode="tan:tokenize-div">
            <xsl:with-param name="token-definition" tunnel="yes" select="$token-definition"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:template match="tan:head | tei:teiHeader | comment()" mode="tan:tokenize-div"/>
    
    
    <!-- PASS 2: BUILD TOKEN MAP AND SEARCH LOCAL LANGUAGE CATALOGS FOR LEXICOMORPHOLOGICAL DATA -->
    <xsl:variable name="output-pass-2" as="map(*)">
        <xsl:choose>
            <xsl:when test="$retain-morphological-codes-as-is">
                <xsl:message select="'Any morphological codes retrieved from local language TAN-A-lm files will be taken at face value, and not converted.'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'Any morphological codes retrieved from local language TAN-A-lm files will be converted to IRI values, then reconverted into the target coding system. This process may take a while.'"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:map>
            <xsl:for-each-group select="$output-pass-1//tan:tok"
                group-by="ancestor::*[@xml:lang][1]/@xml:lang">
                <xsl:variable name="this-lang" as="xs:string" select="current-grouping-key()"/>
                <xsl:variable name="these-lang-catalogs" select="tan:lang-catalog($this-lang)"
                    as="document-node()*"/>

                <xsl:variable name="tok-map-prelim" as="map(*)">
                    <xsl:map>
                        <xsl:map-entry key="1"/>
                        <xsl:for-each-group select="current-group()" group-by=".">
                            <xsl:map-entry key="string(current-grouping-key())">
                                <xsl:sequence select="
                                        array:join(for $i in current-group()
                                        return
                                            [(string($i/preceding-sibling::tan:ref/text()), tan:tok-context($i))])"
                                />
                            </xsl:map-entry>
                        </xsl:for-each-group>
                    </xsl:map>
                </xsl:variable>

                <xsl:map-entry key="$this-lang">
                    <!-- Map #1: one map entry per unique token, with value items being an array of strings
                        listing the references and perhaps the context. -->
                    <xsl:sequence select="$tok-map-prelim"/>
                    <!-- Map #2: one map entry per TAN-A-lm file, each containing a map whose entries are keyed to
                        token value with contents consisting of resolved <ana>s. -->
                    <xsl:map>
                        <xsl:map-entry key="2"/>
                        <xsl:for-each-group select="map:keys($tok-map-prelim)[. instance of xs:string]"
                            group-by="tan:TAN-A-lm-hrefs($this-lang, ., $these-lang-catalogs)">
                            <xsl:variable name="these-keys" as="xs:string+" select="current-group()"/>
                            <xsl:variable name="tan-a-lm-base-uri" select="current-grouping-key()"
                                as="xs:string"/>
                            <xsl:variable name="this-tan-a-lm" as="document-node()?"
                                select="doc($tan-a-lm-base-uri)"/>
                            <xsl:variable name="this-tan-a-lm-resolved" as="document-node()?" select="tan:resolve-doc($this-tan-a-lm)"/>
                            <xsl:variable name="primary-morphology-code" as="xs:string"
                                select="$this-tan-a-lm-resolved/tan:TAN-A-lm/tan:body/@morphology"/>
                            <xsl:variable name="primary-tan-mor-docs" as="document-node()*"
                                select="tan:get-1st-doc(tan:vocabulary('morphology', $primary-morphology-code, $this-tan-a-lm-resolved/tan:TAN-A-lm/tan:head)//*[tan:location])"
                            />
                            <xsl:variable name="primary-target-tan-mor-resolved" as="document-node()?" select="tan:resolve-doc($primary-tan-mor-docs[1])"/>
                            <xsl:variable name="re-map-these-codes" as="xs:boolean" select="not($retain-morphological-codes-as-is) 
                                and not($default-tan-mor-file-resolved/tan:TAN-mor/@id eq $primary-target-tan-mor-resolved/tan:TAN-mor/@id)"/>
                            <xsl:variable name="morphology-conversion-maps" as="map(*)*" select="
                                    if ($re-map-these-codes) then
                                        tan:morphological-code-conversion-maps($primary-target-tan-mor-resolved, $default-tan-mor-file-resolved)
                                    else
                                        ()"/>
                            <xsl:variable name="this-tan-a-lm-ready-to-search" as="document-node()?"
                                select="
                                    if ($retain-morphological-codes-as-is) then
                                        $this-tan-a-lm-resolved
                                    else
                                        tan:convert-morphological-codes($this-tan-a-lm-resolved, $primary-morphology-code, $morphology-conversion-maps)"
                            />

                            <xsl:message select="
                                    'Looking up lexemes for ' ||
                                    string(count(current-group())) || ' tokens, using language TAN-A-lm ' ||
                                    $tan-a-lm-base-uri"/>

                            <xsl:map-entry key="$tan-a-lm-base-uri">
                                <!-- Map #2, item A: map of tokens -->
                                <xsl:map>
                                    <xsl:map-entry key="3"/>
                                    <xsl:for-each-group select="current-group()" group-by=".">
                                        <xsl:variable name="this-tok" as="xs:string"
                                            select="current-grouping-key()"/>
                                        <xsl:variable name="this-tok-fallback" as="xs:string"
                                            select="
                                                if ($use-string-base-as-backup) then
                                                    tan:string-base($this-tok)
                                                else
                                                    $this-tok"
                                        />
                                        <xsl:variable name="ana-tok-matches-pass-1" as="element()*"
                                            select="$this-tan-a-lm-ready-to-search/tan:TAN-A-lm/tan:body//tan:ana/tan:tok[@val eq $this-tok or matches(@rgx, '^' || tan:escape($this-tok) || '$')]"/>
                                        <xsl:variable name="ana-tok-matches-pass-2" as="element()*"
                                            select="
                                                if (not(exists($ana-tok-matches-pass-1)) and $use-string-base-as-backup and ($this-tok ne $this-tok-fallback))
                                                then
                                                    $this-tan-a-lm-ready-to-search/tan:TAN-A-lm/tan:body//tan:ana/tan:tok[@val eq $this-tok-fallback or matches(@rgx, '^' || tan:escape($this-tok-fallback) || '$')]
                                                else
                                                    ()"
                                        />
                                        <xsl:if test="exists($ana-tok-matches-pass-1) or exists($ana-tok-matches-pass-2)">
                                            <xsl:map-entry key="$this-tok">
                                                <xsl:apply-templates select="$ana-tok-matches-pass-1, $ana-tok-matches-pass-2"
                                                  mode="resolve-anas"/>
                                            </xsl:map-entry>
                                        </xsl:if>
                                    </xsl:for-each-group>

                                </xsl:map>
                                <!-- Map #2, item B: tan:head, for vocabulary, to resolve values of @morphology, @claimant, etc. -->
                                <xsl:copy-of select="$this-tan-a-lm-resolved/tan:TAN-A-lm/tan:head"
                                />
                            </xsl:map-entry>
                        </xsl:for-each-group>
                    </xsl:map>
                </xsl:map-entry>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    
    <xsl:mode name="resolve-anas" on-no-match="shallow-copy"/>
    
    <xsl:template match="@q" mode="resolve-anas"/>
    
    <xsl:template match="tan:ana/tan:tok" mode="resolve-anas">
        <xsl:variable name="cert-resolved" as="xs:decimal?" select="
                tan:product(for $i in ancestor-or-self::*[@cert]
                return
                    xs:decimal($i/@cert))"/>
        <xsl:variable name="cert2-resolved" as="xs:decimal?" select="
                if (exists(ancestor-or-self::*/@cert2))
                then
                    tan:product(for $i in ancestor-or-self::*[@cert]
                    return
                        xs:decimal(($i/@cert2, $i/@cert)[1]))
                else
                    ()"/>
        <ana>
            <xsl:copy-of select="ancestor-or-self::*[@morphology][1]/@morphology"/>
            <xsl:copy-of select="ancestor-or-self::*[@claimant][1]/@claimant"/>
            <xsl:if test="exists($cert-resolved)">
                <xsl:attribute name="cert" select="$cert-resolved"/>
            </xsl:if>
            <xsl:if test="exists($cert2-resolved)">
                <xsl:attribute name="cert2" select="$cert-resolved"/>
            </xsl:if>
            <xsl:apply-templates select="following-sibling::tan:lm" mode="#current"/>
        </ana>
    </xsl:template>
    
    
    <xsl:function name="tan:tok-context" as="xs:string*" visibility="private">
        <!-- Input: a tok -->
        <!-- Output: if the value of insert-tok-context is greater than 0 then a string representing 
            the immediate context; nothing otherwise -->
        <xsl:param name="tok-to-process" as="element(tan:tok)*"/>
        <xsl:if test="$insert-tok-context gt 0">
            <xsl:for-each select="$tok-to-process">
                <xsl:variable name="this-n" as="xs:integer" select="xs:integer(@n)"/>
                <xsl:variable name="context-start" as="xs:string"
                    select="string($this-n - $insert-tok-context)"/>
                <xsl:variable name="context-end" as="xs:string"
                    select="string($this-n + $insert-tok-context)"/>
                <xsl:variable name="preceding-context" as="element()*"
                    select="(preceding-sibling::tan:tok | preceding-sibling::tan:non-tok) except preceding-sibling::tan:tok[@n eq $context-start]/preceding-sibling::*"/>
                <xsl:variable name="following-context" as="element()*"
                    select="(following-sibling::tan:tok | following-sibling::tan:non-tok) except following-sibling::tan:tok[@n eq $context-end]/following-sibling::*"/>
                <xsl:sequence
                    select="string-join($preceding-context) || '…' || string-join($following-context)"
                />
            </xsl:for-each>
        </xsl:if>
    </xsl:function>
    
    
    <!-- PASS 3: SEARCH SERVICES -->
    
    <xsl:variable name="output-pass-3" as="map(*)">
        <xsl:choose>
            
            <xsl:when test="$use-search-services">
                <xsl:apply-templates select="$output-pass-2" mode="search-lm-data"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$output-pass-2"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    

    <xsl:mode name="search-lm-data" on-no-match="shallow-copy"/>
    
    <xsl:template match=".[. instance of map(*)]" priority="-1" mode="search-lm-data">
        <xsl:variable name="context-map" as="map(*)" select="."/>
        <xsl:map>
            <xsl:for-each select="map:keys(.)">
                <xsl:map-entry key=".">
                    <xsl:apply-templates select="$context-map(current())" mode="#current">
                        <xsl:with-param name="containing-key" as="xs:anyAtomicType" select="."/>
                    </xsl:apply-templates>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match=".[. instance of map(*)][map:keys(.)[. instance of xs:string] = ('grc', 'lat')]" mode="search-lm-data">
        <xsl:variable name="context-map" as="map(*)" select="."/>
        <xsl:variable name="context-keys" as="xs:anyAtomicType" select="map:keys(.)"/>
        <xsl:map>
            <xsl:for-each select="$context-keys[not(. instance of xs:string) or not(. = ('grc', 'lat'))]">
                <xsl:map-entry key=".">
                    <xsl:apply-templates select="$context-map(current())" mode="#current">
                        <xsl:with-param name="containing-key" as="xs:anyAtomicType" select="."/>
                    </xsl:apply-templates>
                </xsl:map-entry>
            </xsl:for-each>
            <xsl:for-each select="$context-keys[. instance of xs:string and . = ('grc', 'lat')]">
                <xsl:variable name="this-key" as="xs:string" select="."/>
                <xsl:variable name="these-maps" as="map(*)*" select="$context-map($this-key)"/>
                <xsl:variable name="all-toks" as="xs:string*"
                    select="map:keys($these-maps[1])[. instance of xs:string]"/>
                <xsl:variable name="toks-already-found" as="xs:string*"
                    select="tan:map-keys($these-maps[2])[. instance of xs:string]"/>
                <xsl:variable name="toks-of-interest" as="xs:string*" select="
                        if ($use-search-services-only-as-backup) then
                            $all-toks[not(. = $toks-already-found)]
                        else
                            $all-toks"/>

                <xsl:map-entry key=".">
                    <xsl:copy-of select="$these-maps"/>
                    <xsl:map>
                        <xsl:map-entry key="4" select="'Morpheus online service'"/>
                        <xsl:for-each select="$toks-of-interest">
                            <xsl:map-entry key="." select="tan:search-results-to-claims(tan:search-morpheus(.), 'morpheus')"/>
                        </xsl:for-each>
                    </xsl:map>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
        
    </xsl:template>
    
    <xsl:variable name="output-pass-3-lang-keys" as="xs:string*" select="map:keys($output-pass-3)"/>
    
    
    <!-- PASS 4: START BUILDING THE OUTPUT BODY; MOVE FROM MAPS TO TREES -->
    
    <xsl:variable name="output-pass-4" as="element()">
        <body>
            <xsl:for-each select="$output-pass-3-lang-keys">
                <xsl:variable name="this-lang" as="xs:string" select="."/>
                <xsl:variable name="these-lang-data-maps" as="map(*)*" select="$output-pass-3($this-lang)"/>
                <xsl:variable name="these-toks" as="xs:string*" select="map:keys($these-lang-data-maps[1])[. instance of xs:string]"/>
                <xsl:variable name="local-lm-data-sources" as="xs:string*"
                    select="map:keys($these-lang-data-maps[2])[. instance of xs:string]"/>
                <xsl:variable name="searched-lm-data-sources" as="xs:string*"
                    select="$these-lang-data-maps[3](4)"/>
                <!-- We add this element to make it easier to populate t he output with credit/blame -->
                <claimants>
                    <xsl:for-each select="$local-lm-data-sources, $searched-lm-data-sources">
                        <xsl:sort/>
                        <claimant>
                            <xsl:value-of select="."/>
                        </claimant>
                    </xsl:for-each>
                </claimants>
                <lang xml:lang="{.}">
                    <xsl:for-each select="$these-toks">
                        <xsl:variable name="this-tok" as="xs:string" select="."/>
                        <xsl:variable name="this-tok-array" as="array(xs:string+)" select="$these-lang-data-maps[1]($this-tok)"/>
                        <xsl:variable name="these-local-result-keys" as="xs:string+" select="map:keys($these-lang-data-maps[2])[. instance of xs:string]"/>
                        <!--<xsl:variable name="local-result-keys-of-interest" as="xs:string+" select="for $i in $these-local-result-keys return
                            if () then () else ()"/>-->
                        <xsl:variable name="these-search-results" as="element()?" select="$these-lang-data-maps[3]($this-tok)"/>
                        
                        <ana>
                            <xsl:for-each-group select="1 to array:size($this-tok-array)" group-by="let $i := . return $this-tok-array($i)[1]">
                                <xsl:variable name="current-group-count" as="xs:integer" select="count(current-group())"/>
                                <xsl:for-each select="current-group()">
                                    <xsl:variable name="this-array-member-pos" as="xs:integer" select="."/>
                                    <xsl:variable name="this-context" as="xs:string?" select="$this-tok-array($this-array-member-pos)[2]"/>
                                    <xsl:if test="exists($this-context)">
                                        <xsl:text>&#xa;</xsl:text>
                                        <xsl:if test="position() eq 1">
                                            <xsl:sequence select="$default-tok-indentation"/>
                                        </xsl:if>
                                        <xsl:comment select="$this-context"/>
                                        <xsl:text>&#xa;</xsl:text>
                                    </xsl:if>
                                    <tok val="{$this-tok}" ref="{$this-tok-array($this-array-member-pos)[1]}">
                                        <xsl:if test="$current-group-count gt 1">
                                            <xsl:attribute name="pos" select="position()"/>
                                        </xsl:if>
                                    </tok>
                                </xsl:for-each>
                            </xsl:for-each-group> 
                            <xsl:for-each select="$these-local-result-keys">
                                <xsl:variable name="this-tan-a-lm-uri" as="xs:string" select="."/>
                                <xsl:variable name="this-lm-data" as="element()*" select="$these-lang-data-maps[2]($this-tan-a-lm-uri)[1]($this-tok)"/>
                                <xsl:if test="exists($this-lm-data)">
                                    <claims>
                                        <claimant href="{.}"/>
                                        <xsl:copy-of select="$this-lm-data"/>
                                    </claims>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:copy-of select="$these-search-results"/>
                        </ana>
                    </xsl:for-each>
                </lang>
            </xsl:for-each>
        </body>
    </xsl:variable>
    
    
    <!-- PASS 5: STANDARDIZE ALL MORPHOLOGICAL CODES -->
    
    <xsl:variable name="output-pass-5" as="element()">
        <xsl:apply-templates select="$output-pass-4" mode="standardize-m-codes"/>
    </xsl:variable>
    
    <xsl:mode name="standardize-m-codes" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:claims/tan:ana/tan:tok | tan:body/tan:claimants" mode="standardize-m-codes"/>
    
    <xsl:template match="tan:m[tan:feature]" mode="standardize-m-codes">
        <xsl:variable name="these-ids" as="element()*">
            <xsl:apply-templates select="tan:feature" mode="features-to-ids"/>
        </xsl:variable>
        
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="$default-tan-mor-file-has-categories">
                    <xsl:variable name="these-cat-nos" as="xs:integer*" select="
                            for $i in $these-ids
                            return
                                count($default-tan-mor-file-resolved/tan:TAN-mor/tan:body/tan:category[tan:feature[(@type, @code) = $i]]/preceding-sibling::tan:category) + 1"/>
                    <xsl:sequence select="
                            string-join(for $i in (1 to max($these-cat-nos)),
                                $j in $default-tan-mor-file-resolved/tan:TAN-mor/tan:body/tan:category[$i]
                            return
                                ($j/tan:feature[(@type, @code) = $these-ids]/@code, '-')[1], ' ')"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="string-join($these-ids, ' ')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="tan:m/text()" mode="standardize-m-codes">
        <xsl:sequence select="replace(., '(\s+-)+\s*$', '')"/>
    </xsl:template>
    
    
    <xsl:mode name="features-to-ids" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:feature[tan:IRI]" mode="features-to-ids">
        <xsl:variable name="these-iris" as="element()*" select="tan:IRI"/>
        <xsl:variable name="these-feature-vocab-items" as="element()*" select="$default-feature-vocabulary/*[tan:IRI = $these-iris]"/>
        <xsl:choose>
            <xsl:when test="not(exists($these-feature-vocab-items))">
                <xsl:message select="'Cannot find vocabulary for feature ', ."/>
            </xsl:when>
            <xsl:when test="not(exists($these-feature-vocab-items/tan:id))">
                <xsl:message select="'No ID available for feature vocabulary ', $these-feature-vocab-items"/>
            </xsl:when>
        </xsl:choose>
        <xsl:sequence select="$these-feature-vocab-items/tan:id"/>
    </xsl:template>
    
    
    <!-- PASS 6: INTEGRATE, EVALUATE CLAIMS -->
    
    <xsl:variable name="output-pass-6" as="element()">
        <xsl:apply-templates select="$output-pass-5" mode="integrate-lm-claims"/>
    </xsl:variable>
    
    <xsl:mode name="integrate-lm-claims" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:ana[tan:claims]" mode="integrate-lm-claims">
        
        <xsl:variable name="lm-arrays" as="array(*)*"
            select="tan:ana-lm-arrays(descendant::tan:ana)"/>
        <xsl:variable name="total-cert" as="xs:decimal?" select="
                sum(for $i in $lm-arrays
                return
                    $i(3))"/>
        <xsl:variable name="total-cert2" as="xs:decimal?" select="
                sum(for $i in $lm-arrays
                return
                    $i(4))"/>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:for-each-group select="$lm-arrays" group-by=".(1)">
                <xsl:sort select="
                        sum(for $i in current-group()
                        return
                            $i(3))" order="descending"/>
                <xsl:variable name="this-l" as="xs:string" select="current-grouping-key()"/>
                <xsl:variable name="this-cert-sum" as="xs:decimal" select="
                        sum(for $i in current-group()
                        return
                            $i(3))"/>
                <xsl:variable name="this-cert2-sum" as="xs:decimal" select="
                        sum(for $i in current-group()
                        return
                            $i(4))"/>
                <xsl:variable name="this-cert-adjusted" as="xs:decimal"
                    select="$this-cert-sum div $total-cert"/>
                <xsl:variable name="this-cert2-adjusted" as="xs:decimal"
                    select="$this-cert2-sum div $total-cert2"/>
                
                <lm cert="{$this-cert-adjusted}">
                    <xsl:if test="not($this-cert-adjusted eq $this-cert2-adjusted)">
                        <xsl:attribute name="cert2" select="$this-cert2-adjusted"/>
                    </xsl:if>
                    <l>
                        <xsl:value-of select="$this-l"/>
                    </l>
                    <xsl:for-each-group select="current-group()" group-by=".(2)">
                        <xsl:sort select="
                                sum(for $i in current-group()
                                return
                                    $i(3))" order="descending"/>
                        <xsl:variable name="this-m" as="xs:string" select="current-grouping-key()"/>
                        <xsl:variable name="this-m-cert-sum" as="xs:decimal" select="
                                sum(for $i in current-group()
                                return
                                    $i(3))"/>
                        <xsl:variable name="this-m-cert2-sum" as="xs:decimal" select="
                                sum(for $i in current-group()
                                return
                                    $i(4))"/>
                        <m cert="{$this-m-cert-sum div $this-cert-sum}">
                            <xsl:if test="$this-m-cert-sum ne $this-m-cert2-sum">
                                <xsl:attribute name="cert2"
                                    select="$this-m-cert2-sum div $this-cert2-sum"/>
                            </xsl:if>
                            <xsl:value-of select="$this-m"/>
                        </m>
                    </xsl:for-each-group>
                </lm>
            </xsl:for-each-group> 
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:ana/tan:claims" mode="integrate-lm-claims"/>
    
    
    
    <!-- PASS 7: SORT ANAS -->
    
    <xsl:variable name="output-pass-7" as="element()">
        <xsl:apply-templates select="$output-pass-6" mode="sort-anas"/>
    </xsl:variable>
    
    <xsl:mode name="sort-anas" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:lang" mode="sort-anas">
        <xsl:text>&#xa;&#xa;</xsl:text>
        <xsl:value-of select="$default-tok-indentation"/>
        <xsl:comment select="'Lexicomorphological data found for ' || string(count(tan:ana)) || ' tokens'"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:for-each-group select="tan:ana" group-by="
                let $i := count(tan:lm/tan:l) * count(tan:lm/tan:m)
                return
                    if ($i eq 0) then
                        1
                    else
                        if ($i eq 1) then
                            3
                        else
                            2">
            <!-- Three groups, sorted: missing, ambiguous, then unambiguous -->
            <xsl:sort select="current-grouping-key()"/>
            
            <xsl:variable name="group-count" as="xs:integer" select="count(current-group())"/>
            
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:value-of select="$default-tok-indentation"/>
            <xsl:choose>
                <xsl:when test="current-grouping-key() eq 1">
                    <xsl:comment select="string($group-count) || ' tokens lack any lexicomorphological data'"/>
                </xsl:when>
                <xsl:when test="current-grouping-key() eq 2">
                    <xsl:comment select="string($group-count) || ' tokens have ambiguous lexicomorphological data'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment select="string($group-count) || ' tokens have unambiguous lexicomorphological data'"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&#xa;</xsl:text>
            <xsl:apply-templates select="current-group()" mode="#current">
                <xsl:sort select="tan:string-base(lower-case(tan:tok[1]/@val))"/>
            </xsl:apply-templates>
        </xsl:for-each-group> 
    </xsl:template>
    
    
    <xsl:variable name="final-output" as="document-node()">
        <xsl:apply-templates select="$template-tan-a-lm-prepped-for-output" mode="infuse-final-output"/>
    </xsl:variable>
    
    <xsl:mode name="infuse-final-output" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:head/tan:source" mode="infuse-final-output">
        <xsl:choose>
            <xsl:when test="exists($new-source-element)">
                <xsl:message select="'Inserting new source element in output. Be certain to adjust /tan:TAN-A-lm/tan:head/tan:source/tan:location/@href if you want a relative URL.'"/>
                <xsl:apply-templates select="$new-source-element" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tan:body" mode="infuse-final-output">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!--<xsl:sequence
                select="tan:copy-indentation($output-pass-7/node(), preceding-sibling::tan:head/*[1])"
            />-->
            <xsl:apply-templates mode="#current" select="$output-pass-7/node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:param name="output-diagnostics-on" as="xs:boolean" static="yes" select="true()"/>
    
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Output diagnostics on for ' || static-base-uri()"/>
        <diagnostics>
            <!--<default-token-indentation><xsl:copy-of select="$default-tok-indentation"/></default-token-indentation>-->
            <!--<template-tan-a-lm-resolved><xsl:copy-of select="tan:trim-long-tree($template-tan-a-lm-resolved, 10, 20)"/></template-tan-a-lm-resolved>-->
            <!--<template-tan-a-lm-expanded><xsl:copy-of select="tan:trim-long-tree(tan:expand-doc($template-tan-a-lm-resolved), 50, 100)"/></template-tan-a-lm-expanded>-->
            <template-morphology-vocabulary><xsl:copy-of select="$template-morphology-vocabulary"/></template-morphology-vocabulary>
            <tan-mor-files-resolved><xsl:copy-of select="tan:trim-long-tree($default-tan-mor-file-resolved, 10, 20)"/></tan-mor-files-resolved>
            <token-definition><xsl:copy-of select="$token-definition"/></token-definition>
            <default-feature-vocabulary><xsl:copy-of select="$default-feature-vocabulary"/></default-feature-vocabulary>
            <output-pass-1><xsl:copy-of select="tan:trim-long-tree($output-pass-1, 10, 20)"/></output-pass-1>
            <output-pass-2><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($output-pass-2, true()), 10, 20)"/></output-pass-2>
            <output-pass-3><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($output-pass-3, true()), 10, 20)"/></output-pass-3>
            <output-pass-4><xsl:copy-of select="tan:trim-long-tree($output-pass-4, 10, 20)"/></output-pass-4>
            <output-pass-5><xsl:copy-of select="tan:trim-long-tree($output-pass-5, 10, 20)"/></output-pass-5>
            <output-pass-6><xsl:copy-of select="tan:trim-long-tree($output-pass-6, 10, 20)"/></output-pass-6>
            <output-pass-7><xsl:copy-of select="tan:trim-long-tree($output-pass-7, 10, 20)"/></output-pass-7>
            <template-prepped-for-output><xsl:copy-of select="tan:trim-long-tree($template-tan-a-lm-prepped-for-output, 10, 20)"/></template-prepped-for-output>
            <final-output><xsl:copy-of select="tan:trim-long-tree($final-output, 10, 20)"/></final-output>
        </diagnostics>
    </xsl:template>
    
    <xsl:template match="/">
        <!-- primary output -->
        <xsl:choose>
            <xsl:when test="$tan:doc-class ne 1">
                <xsl:message select="'Input must be a class 1 TAN file'"/>
            </xsl:when>
            <xsl:when test="not(exists($template-tan-a-lm-resolved))">
                <xsl:message select="'TAN-A-lm template does not exist'"/>
            </xsl:when>
            <xsl:when test="not(exists($default-tan-mor-file-resolved))">
                <xsl:message select="'No TAN-mor files exist'"/>
            </xsl:when>
            <xsl:when test="not($retain-morphological-codes-as-is)">
                <xsl:message select="'At this time, conversion of morphological codes from one system to another is not supported.'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$final-output"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
