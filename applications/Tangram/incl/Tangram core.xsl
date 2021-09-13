<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="tag:textalign.net,2015:ns" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for exploring text parallels. -->

    <xsl:include href="Tangram%20html.xsl"/>
    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    
    <xsl:variable name="output-directory-uri-resolved" as="xs:anyURI"
        select="resolve-uri($output-directory-uri, $calling-stylesheet-uri)"/>
    
    <!-- 0 or less to turn off; 1 or more to cap the number of tokens analyzed -->
    <xsl:variable name="diagnostics-tok-ceiling" as="xs:integer?" select="0"/>
    
    
    
    <!-- About this stylesheet -->
    
    <!-- The predecessor to this stylesheet is tag:textalign.net,2015:stylesheet:create-quotations-from-tan-a -->
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:explore-text-parallels'"/>
    <xsl:param name="tan:stylesheet-name" as="xs:string" select="'Tangram'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'finds and scores clusters of words (ngrams) shared across two groups of texts'"
    />
    <xsl:param name="tan:stylesheet-description">This application searches for and scores clusters
        of words shared across two groups of texts, allowing you to look for quotations,
        paraphrases, or shared topics. When configured correctly, Tangram can also find idioms and
        collocations. Each input file, which may come in a variety of formats (TAN, TEI, other XML
        formats, plain text, Word documents) must be assigned to one or both of two groups, each
        group representing a work. Members of a work-group can be from different languages. Users
        can specify how many ngrams ("words") should be found, and how far apart they can be from
        each other. Ngram order is disregarded (e.g., ngram "shear", "blue", "sheep" would match
        ngram "sheep", "blue", "shear"). Tangram first normalizes and tokenizes each text according
        to language rules. Each token is converted to one or more aliases. If lexico-morphological
        data is available through a TAN-A-lm file, or if there is a TAN-A-lm language library for
        the language of the text being processed, a token may be replaced by multiple lexemes (e.g.,
        "rung" would attract aliases "ring" and "rung"); otherwise, a case-insensitive generic form
        of the word is used. Then each text in group 1 is compared to each text in group 2 that
        shares the same language. For each pair of texts, Tangram identifies clusters of tokens that
        share the same alias. It then consolidates adjacent clusters of ngrams, and scores the
        results based upon several criteria. Grouped clusters are then converted into a primitive
        TAN-A file consisting of claims that identify parallel passages of each pair of texts, and
        the output is rendered as sortable HTML, to facilitate better study of the results. Tangram
        was written primarily to support quotation detection in ancient Greek and Latin texts, which
        has rather demanding requirements. Because of these objectives, Tangram frequently operates
        in quadratic or cubic time, so can be quite time-consuming to run. A feature allows the user
        to save intermediate stages as temporary files, to reduce processing time.
    </xsl:param>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any XML file, including this
        one (input is ignored)</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">one or more files allocated
        to two groups; perhaps temporary files; perhaps TAN-A-lm files, either associated with
        secondary input, or part of a language catalog</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">perhaps diagnostics</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string"> (1) an XML file with
        TAN-A claims identifying quotations or parallels, with the most likely at the top; (2) an
        HTML file that renders #1 in a more legible format. </xsl:param>
    
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2021-03-10">Support the method pioneered by Shmidman,
                Koppel, and Porat: https://arxiv.org/abs/1602.08715v2</comment>
            <comment who="kalvesmaki" when="2021-03-11">Make sure texts run against themselves work.</comment>
            <comment who="kalvesmaki" when="2021-09-06">Incorporate simpler tablesorter javascript</comment>
        </to-do>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="'Exploring text parallels'"/>
    
    
    <!-- MANIFEST HANDLING -->
    
    <!-- The following templates are used for saving and retrieving temporary files. -->
    <!-- For select global variables that take document nodes, a result that includes a <manifest>
        as a child of the root element is a file that should be saved as a temporary, intermediate
        result to the temporary directory, using @checksum in the <manifest> as the base name. -->
    
    <xsl:function name="tan:stamp-manifest" as="element(tan:manifest)?" visibility="private">
        <!-- Input: a manifest element and a checksum as a string -->
        <!-- Output: the <manifest> imprinted with @checksum and the value -->
        <!-- The @checksum in a manifest refers to the Fletcher-32 checksum of the string value of 
            the element, which is not affected by inserting @checksum -->
        <xsl:param name="manifest" as="element(tan:manifest)?"/>
        <xsl:param name="checksum" as="xs:string"/>
        <xsl:apply-templates select="$manifest" mode="stamp-manifest">
            <xsl:with-param name="manifest-checksum" tunnel="yes" select="$checksum"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:mode name="stamp-manifest" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:manifest" mode="stamp-manifest">
        <xsl:param name="manifest-checksum" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="checksum" select="$manifest-checksum"/>
            <xsl:copy-of select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- When saving a document with a <manifest> as the child of the root element, the
        document is split into two: one for the manifest and the other for the document
        without the manifest. -->
    <xsl:mode name="save-temp-file-and-manifest" on-no-match="shallow-skip"/>
    
    <xsl:template match=".[. instance of map(*)][exists(.('manifest'))]" mode="save-temp-file-and-manifest">
        <xsl:variable name="this-manifest" as="element()" select="map:get(., 'manifest')"/>
        <xsl:variable name="target-checksum" select="$this-manifest/@checksum" as="xs:string?"/>
        <xsl:variable name="base1" as="xs:string?" select="map:get(., 'base1')"/>
        <xsl:variable name="base2" as="xs:string?" select="map:get(., 'base2')"/>
        <xsl:variable name="base" as="xs:string?" select="map:get(., 'xml:base')"/>
        
        <xsl:if test="exists($target-checksum)">
            <xsl:variable name="target-uri-for-manifest"
                select="resolve-uri($target-checksum || '.xml', $temporary-file-directory-norm)"
                as="xs:anyURI"/>
            <xsl:variable name="target-uri-for-output"
                select="resolve-uri($target-checksum || '-result.xml', $temporary-file-directory-norm)"
                as="xs:anyURI"/>
            <xsl:variable name="output-source-filenames" as="xs:string" select="
                    if (exists($base1) or exists($base2))
                    then
                        string-join((tan:cfn($base1), tan:cfn($base2)), ' + ')
                    else
                        tan:cfn($base)"/>
            
            <xsl:try>
                <xsl:result-document href="{$target-uri-for-manifest}" format="xml-indent">
                    <xsl:document>
                        <xsl:copy-of select="$this-manifest"/>
                    </xsl:document>
                </xsl:result-document>
                <xsl:catch>
                    <xsl:message select="'Unable to save manifest to ' || $target-uri-for-manifest"/>
                </xsl:catch>
            </xsl:try>
            <xsl:try>
                <xsl:result-document href="{$target-uri-for-output}" format="xml">
                    <xsl:document>
                        <xsl:copy-of select="tan:map-to-xml(map:remove(., 'manifest'), true())"/>
                    </xsl:document>
                    <xsl:message select="'Intermediate results of ' || $output-source-filenames || ' saved to ' || $target-uri-for-output"/>
                </xsl:result-document>
                <xsl:catch>
                    <xsl:message select="'Unable to save results of ' || $output-source-filenames || ' to ' || $target-uri-for-output"/>
                </xsl:catch>
            </xsl:try>
            
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="document-node()" mode="save-temp-file-and-manifest">
        <xsl:if test="count(*/tan:manifest) gt 1">
            <xsl:message select="'Problem with multiple manifests at ', tan:shallow-copy(*)"/>
            <xsl:message select="*/tan:manifest"/>
        </xsl:if>
        
        <xsl:variable name="target-checksum" select="*/tan:manifest/@checksum" as="xs:string?"/>
        <!-- Nothing will happen to a document, unless it has a root-element child <manifest> 
            with a @checksum -->
        <xsl:if test="exists($target-checksum)">
            <xsl:variable name="target-uri-for-manifest"
                select="resolve-uri($target-checksum || '.xml', $temporary-file-directory-norm)"
                as="xs:anyURI"/>
            <xsl:variable name="target-uri-for-output"
                select="resolve-uri($target-checksum || '-result.xml', $temporary-file-directory-norm)"
                as="xs:anyURI"/>
            <xsl:variable name="output-source-filenames" as="xs:string" select="
                    if (exists(@base1) or exists(@base2))
                    then
                        string-join((tan:cfn(@base1), tan:cfn(@base2)), ' + ')
                    else
                        tan:cfn(tan:base-uri(.))"/>
            
            <xsl:try>
                <xsl:result-document href="{$target-uri-for-manifest}" format="xml-indent">
                    <xsl:document>
                        <xsl:copy-of select="*/tan:manifest"/>
                    </xsl:document>
                </xsl:result-document>
                <xsl:catch>
                    <xsl:message select="'Unable to save manifest to ' || $target-uri-for-manifest"/>
                </xsl:catch>
            </xsl:try>
            <xsl:try>
                <xsl:result-document href="{$target-uri-for-output}" format="xml">
                    <xsl:document>
                        <xsl:apply-templates mode="drop-manifest"/>
                    </xsl:document>
                    <xsl:message select="'Intermediate results of ' || $output-source-filenames || ' saved to ' || $target-uri-for-output"/>
                </xsl:result-document>
                <xsl:catch>
                    <xsl:message select="'Unable to save results of ' || $output-source-filenames || ' to ' || $target-uri-for-output"/>
                </xsl:catch>
            </xsl:try>
            
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="tan:drop-manifest" as="item()*">
        <!-- Input: any fragment -->
        <!-- Output: the same, but without the manifest or map entries intended for diagnostics -->
        <!-- Manifests should be dropped both when saving an intermediate result, and when
            evaluating a newly constructed intermediate result that should be saved, but
            needs to be evaluated by a subsequent process.
        -->
        <xsl:param name="input" as="item()*"/>
        <xsl:apply-templates select="$input" mode="drop-manifest"/>
    </xsl:function>
    
    <xsl:mode name="drop-manifest" on-no-match="shallow-copy"/>
    
    <!-- Drop the manifest from the output -->
    <xsl:template match="tan:manifest" mode="save-temp-file-and-manifest drop-manifest"/>
    
    <xsl:template match=".[. instance of map(*)]" mode="drop-manifest">
        <xsl:sequence select="tan:map-remove(., ('manifest', 'diagnostics', 'diagnostics-2'))"/>
    </xsl:template>
    
    <xsl:function name="tan:insert-manifest" as="document-node()?">
        <!-- Input: a document and a manifest element -->
        <!-- Output: the document with the manifest inserted -->
        <xsl:param name="doc-to-change" as="document-node()?"/>
        <xsl:param name="manifest-to-insert" as="element(tan:manifest)?"/>
        <xsl:apply-templates select="$doc-to-change" mode="tan:insert-manifest">
            <xsl:with-param name="manifest" tunnel="yes" select="$manifest-to-insert"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:mode name="tan:insert-manifest" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*" mode="tan:insert-manifest">
        <xsl:param name="manifest" tunnel="yes" as="element(tan:manifest)?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$manifest"/>
            <xsl:copy-of select="node() except tan:manifest"/>
        </xsl:copy>
    </xsl:template>
    
    
    
    
    
    <!-- PRELIMINARIES -->
    
    <!-- Adjusting input parameters -->
    
    <xsl:variable name="temporary-file-directory-norm" as="xs:string"
        select="replace($tan:temporary-file-directory, '([^/])$', '$1/')"/>
    
    <xsl:variable name="main-input-resolved-uri-directories" as="xs:string*" select="
            for $i in $tan:main-input-relative-uri-directories
            return
                string(resolve-uri($i, $calling-stylesheet-uri))"/>
    
    <xsl:variable name="main-input-resolved-uris" as="xs:string*">
        <xsl:for-each select="$main-input-resolved-uri-directories">
            <xsl:try select="uri-collection(.)">
                <xsl:catch>
                    <xsl:message select="'Unable to get a uri collection from ' || ."/>
                </xsl:catch>
            </xsl:try>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="mirus-chosen" as="xs:string*"
        select="sort($main-input-resolved-uris[tan:filename-satisfies-regexes(., $tan:input-filenames-must-match-regex, $tan:input-filenames-must-not-match-regex)])"
    />
    
    <xsl:variable name="mirus-g1" as="xs:string*" select="
            if (string-length($group-one-filenames-regex) gt 0 and tan:regex-is-valid($group-one-filenames-regex))
            then
                $mirus-chosen[matches(., $group-one-filenames-regex, 'i')]
            else
                $mirus-chosen"/>
    <xsl:variable name="mirus-g2" as="xs:string*" select="
            if (string-length($group-two-filenames-regex) gt 0 and tan:regex-is-valid($group-two-filenames-regex))
            then
                $mirus-chosen[matches(., $group-two-filenames-regex, 'i')]
            else
                $mirus-chosen"/>
    <xsl:variable name="mirus-duplicated" select="tan:duplicate-values(($mirus-g1, $mirus-g2))" as="xs:string?"/>
    
    <xsl:variable name="target-ngram-n-norm" as="xs:integer" select="max((1, $target-ngram-n))"/>
    
    <xsl:variable name="ngram-auras-norm" as="xs:integer+">
        <xsl:sequence select="$ngram-auras[1]"/>
        <xsl:for-each select="2 to $target-ngram-n">
            <xsl:variable name="this-pos" select="position()" as="xs:integer"/>
            <xsl:variable name="first-choice" select="$ngram-auras[$this-pos]" as="xs:integer?"/>
            <xsl:variable name="second-choice" select="$ngram-auras[last()]" as="xs:integer"/>
            <xsl:variable name="this-choice" select="($first-choice, $second-choice)[1]" as="xs:integer"/>
            <xsl:sequence select="max(($this-choice, $this-pos))"/>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="ngram-aura-max" select="max($ngram-auras-norm)" as="xs:integer"/>

    <xsl:variable name="ngram-aura-diameters-norm" as="xs:integer+">
        <xsl:sequence select="$ngram-aura-diameters[1]"/>
        <xsl:for-each select="2 to $target-ngram-n">
            <xsl:variable name="this-pos" select="position()" as="xs:integer"/>
            <xsl:variable name="first-choice" select="$ngram-aura-diameters[$this-pos]" as="xs:integer?"/>
            <xsl:variable name="second-choice" select="$ngram-aura-diameters[last()]" as="xs:integer"/>
            <xsl:variable name="this-choice" select="($first-choice, $second-choice)[1]" as="xs:integer"/>
            <xsl:sequence select="max(($this-choice, $this-pos))"/>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="ngram-aura-diameter-max" select="max($ngram-aura-diameters-norm)" as="xs:integer"/>
    
    
    <xsl:variable name="head-chop-norm" as="xs:decimal+">
        <!-- There should be one head chop per N in Ngram, in decreasing order -->
        <xsl:for-each select="$cut-most-frequent-aliases-per-ngram">
            <xsl:sort order="descending"/>
            <xsl:variable name="this-pos" select="position()"/>
            <xsl:variable name="this-val" select="max((min((., 1)), 0))" as="xs:decimal"/>
            <xsl:sequence select="$this-val"/>
            <xsl:if test="$this-pos eq count($cut-most-frequent-aliases-per-ngram) and $this-pos lt $target-ngram-n-norm">
                <xsl:for-each select="$this-pos + 1 to $target-ngram-n-norm">
                    <xsl:sequence select="$this-val"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    
    
    
    <!-- INPUT AND INPUT PREPARATION -->
    
    <xsl:template match="comment() | processing-instruction()"
        mode="tan:core-expansion-ad-hoc-pre-pass"/>
    
    <xsl:template match="tan:TAN-A-lm/tan:head/tan:source" mode="tan:core-expansion-ad-hoc-pre-pass">
        <xsl:param name="expected-source-element" tunnel="yes" as="element()?"/>
        <xsl:choose>
            <xsl:when test="exists($expected-source-element)">
                <xsl:copy-of select="$expected-source-element"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Original, raw input -->
    <xsl:variable name="group-1-files" select="tan:open-file($mirus-g1)" as="document-node()*"/>
    <xsl:variable name="group-2-files" select="tan:open-file($mirus-g2)" as="document-node()*"/>
    
    <!-- Input prep 1: resolve files -->
    <xsl:variable name="files-resolved-g1" as="document-node()*">
        <xsl:apply-templates select="$group-1-files" mode="resolve-input-files"/>
    </xsl:variable>
    <xsl:variable name="files-resolved-g2" as="document-node()*">
        <xsl:apply-templates select="$group-2-files" mode="resolve-input-files"/>
    </xsl:variable>
    
    <xsl:mode name="resolve-input-files" on-no-match="shallow-copy"/>
    
    <!-- Get rid of any Word document components that aren't the main document -->
    <xsl:template match="document-node()[*[@_archive-path][not(self::w:document)]]" mode="resolve-input-files"/>
    <xsl:template match="document-node()[*/tan:head]" mode="resolve-input-files">
        <xsl:sequence select="tan:resolve-doc(.)"></xsl:sequence>
    </xsl:template>
    
    
    
    <!-- Input prep 1, appendix: look for files with associated TAN-A-lm annotations, and convert them -->
    <xsl:variable name="files-with-tan-a-lm-annotations" as="document-node()*">
        <xsl:apply-templates select="$files-resolved-g1, $files-resolved-g2"
            mode="parse-annotations"/>
    </xsl:variable>
    
    <xsl:mode name="parse-annotations" on-no-match="shallow-skip"/>
    
    <xsl:template match="/*[tan:head[tan:annotation]]" mode="parse-annotations">
        <!-- The <source> in the target TAN-A-lm might point to a file other than the current one. This fixes that possibility. -->
        <xsl:variable name="expected-source-element" as="element()">
            <source>
                <IRI><xsl:value-of select="@xml:id"/></IRI>
                <xsl:copy-of select="tan:head/tan:name"/>
                <location href="{@xml:base}" accessed-when="{current-date()}"/>
            </source>
        </xsl:variable>
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="expected-source-element" tunnel="yes" select="$expected-source-element"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="tan:annotation" mode="parse-annotations" priority="1" use-when="$tan:save-and-use-intermediate-steps">
        <xsl:variable name="annotation-doc" as="document-node()?" select="tan:get-1st-doc(.)"/>
        <xsl:message select="'Building annotation manifest'"/>
        <xsl:variable name="manifest" as="element()?">
            <xsl:if test="exists($annotation-doc/tan:TAN-A-lm)">
                <manifest>
                    <predecessor-base-uri><xsl:value-of select="root(.)/*/@xml:base"/></predecessor-base-uri>
                    <predecessor>
                        <!-- We are interested only in the string values -->
                        <xsl:value-of select="
                                if ($verify-intermediate-steps-strictly) then
                                    tan:checksum-fletcher-32(string(root(.)))
                                else
                                    ('length ' || string(string-length(root(.))))"
                        />
                    </predecessor>
                    <annotation-base-uri><xsl:value-of select="base-uri($annotation-doc)"/></annotation-base-uri>
                    <annotation>
                        <xsl:value-of select="
                                if ($verify-intermediate-steps-strictly) then
                                    tan:checksum-fletcher-32(string($annotation-doc))
                                else
                                    ('length ' || string(string-length($annotation-doc)))"
                        />
                    </annotation>
                    <xsl:if test="$diagnostics-tok-ceiling gt 0">
                        <diagnostics-ceiling>
                            <xsl:value-of select="$diagnostics-tok-ceiling"/>
                        </diagnostics-ceiling>
                    </xsl:if>
                </manifest>
                
            </xsl:if>
        </xsl:variable>
        <xsl:message select="'Creating annotation checksum'"/>
        <xsl:variable name="this-manifest-checksum" select="tan:checksum-fletcher-32(string($manifest))" as="xs:string"/>
        <xsl:variable name="expected-temp-file-location" as="xs:anyURI"
            select="resolve-uri($this-manifest-checksum || '-result.xml', $temporary-file-directory-norm)"
        />
        <xsl:variable name="manifest-stamped" as="element()?"
            select="tan:stamp-manifest($manifest, $this-manifest-checksum)"/>
        
        <xsl:choose>
            <xsl:when test="not(exists($annotation-doc/tan:TAN-A-lm))"/>
            <xsl:when test="doc-available($expected-temp-file-location)">
                <xsl:message select="tan:cfn(tan:base-uri(.)) || ' TAN-A-lm annotation: fetching intermediate file from ' || $expected-temp-file-location"/>
                <xsl:sequence select="doc($expected-temp-file-location)"/>

            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="tan:cfn(tan:base-uri(.)) || ' TAN-A-lm annotation: no intermediate file found at ' || $expected-temp-file-location"/>
                <xsl:next-match>
                    <xsl:with-param name="manifest" as="element()" tunnel="yes" select="$manifest-stamped"/>
                    <!--<xsl:with-param name="manifest-checksum" tunnel="yes" as="xs:string" select="$this-manifest-checksum"/>-->
                </xsl:next-match>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="tan:annotation" mode="parse-annotations">
        <xsl:variable name="annotation-resolved" as="document-node()?" select="tan:resolve-doc(tan:get-1st-doc(.))"/>
        <xsl:choose>
            <xsl:when test="exists($annotation-resolved/tan:TAN-A-lm/tan:head/tan:adjustments/(tan:skip | tan:reassign))">
                <xsl:message select="'In this application, no TAN-A-lm annotation can be applied if it includes skipping and reassignments.'"/>
            </xsl:when>
            <xsl:when test="exists($annotation-resolved/tan:TAN-A-lm)">
                <xsl:variable name="annotation-expanded" select="tan:expand-doc($annotation-resolved, 'terse')" as="document-node()*"/>
                <!--<xsl:variable name="annotation-tok-population" as="xs:integer?" select="
                        sum(for $i in $annotation-expanded/tan:TAN-A-lm/tan:body/tan:ana/@tok-pop
                        return
                            xs:integer($i))"/>-->
                <xsl:apply-templates select="$annotation-expanded[tan:TAN-T]" mode="build-source-specific-tan-a-lm-annotations">
                    <xsl:with-param name="tan-a-lm" tunnel="yes" as="document-node()" select="$annotation-expanded[tan:TAN-A-lm]"/>
                    <!--<xsl:with-param name="tok-pop-sum" as="xs:integer?" select="$annotation-tok-population"/>-->
                </xsl:apply-templates>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:mode name="build-source-specific-tan-a-lm-annotations" on-no-match="shallow-copy"/>
    
    <xsl:template match="comment() | processing-instruction()" mode="build-source-specific-tan-a-lm-annotations"/>
    
    <xsl:template match="tan:TAN-T" mode="build-source-specific-tan-a-lm-annotations">
        <xsl:param name="manifest" as="element()" tunnel="yes"/>
        <!--<xsl:param name="manifest-checksum" tunnel="yes" as="xs:string"/>-->
        
        <xsl:variable name="toks-resolved" as="element()*">
            <xsl:apply-templates select="tan:body" mode="resolve-toks"/>
        </xsl:variable>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="tan:body/@xml:lang"/>
            <xsl:attribute name="src" select="tan:cfn(string(@xml:base))"/>
            
            <xsl:copy-of select="$manifest"/>
            
            <xsl:iterate select="$toks-resolved">
                <xsl:param name="pos-so-far" as="xs:integer" select="1"/>
                <xsl:param name="tok-n-so-far" as="xs:integer" select="1"/>
                <xsl:variable name="this-str-len" as="xs:integer" select="string-length(string-join(text()))"/>
                <xsl:copy>
                    <xsl:attribute name="n" select="$tok-n-so-far"/>
                    <xsl:attribute name="_pos" select="$pos-so-far"/>
                    <xsl:attribute name="_len" select="$this-str-len"/>
                    <xsl:copy-of select="node()"/>
                </xsl:copy>
                <xsl:choose>
                    <xsl:when test="$tok-n-so-far eq $diagnostics-tok-ceiling">
                        <xsl:message select="'Terminating at token ' || string($tok-n-so-far) || ' for diagnostics.'"/>
                        <xsl:break/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:next-iteration>
                            <xsl:with-param name="pos-so-far" select="$pos-so-far + $this-str-len"/>
                            <xsl:with-param name="tok-n-so-far" select="
                                    if (self::tan:tok) then
                                        $tok-n-so-far + 1
                                    else
                                        $tok-n-so-far"/>
                        </xsl:next-iteration>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:iterate>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:mode name="resolve-toks" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:non-tok" mode="resolve-toks">
        <x>
            <xsl:value-of select="."/>
        </x>
    </xsl:template>
    
    <xsl:template match="tan:tok" mode="resolve-toks">
        <xsl:copy>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:tok/text() | tan:c/text()" mode="resolve-toks">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <!-- Character-based annotations will be ignored -->
    <xsl:template match="tan:c/tan:pos" mode="resolve-toks"/>
    
    <xsl:template match="tan:tok/tan:pos[@q]" mode="resolve-toks">
        <xsl:param name="tan-a-lm" tunnel="yes" as="document-node()"/>
        <xsl:variable name="this-q" select="@q" as="xs:string"/>
        <xsl:variable name="these-class-2-anchors" select="key('tan:q-ref', $this-q, $tan-a-lm)" as="element()*"/>
        <xsl:for-each select="$these-class-2-anchors">
            <xsl:variable name="this-seed-cert" as="xs:decimal" select="(xs:decimal(ancestor::tan:tok/@cert), 1.0)[1]"/>
            
            <xsl:apply-templates select="ancestor::tan:ana" mode="simplify-ana">
                <xsl:with-param name="seed-cert" as="xs:decimal" select="$this-seed-cert"/>
                <xsl:with-param name="seed-cert2" as="xs:decimal" select="(xs:decimal(ancestor::tan:tok/@cert2), $this-seed-cert)[1]"/>
            </xsl:apply-templates>
            
        </xsl:for-each>
    </xsl:template>
    
    <xsl:mode name="simplify-ana" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:ana" mode="simplify-ana">
        <xsl:param name="seed-cert" as="xs:decimal"/>
        <xsl:param name="seed-cert2" as="xs:decimal"/>
        <xsl:variable name="this-cert" as="xs:decimal" select="(xs:decimal(@cert), 1.0)[1]"/>
        <xsl:variable name="this-cert2" as="xs:decimal" select="(xs:decimal(@cert2), $this-cert)[1]"/>
        <xsl:variable name="new-cert" select="$this-cert * $seed-cert" as="xs:decimal"/>
        <xsl:variable name="new-cert2" select="$this-cert2 * $seed-cert2" as="xs:decimal"/>
        <xsl:copy>
            <xsl:copy-of select="@* except (@cert | @cert2 | @q | @tok-pop)"/>
            <xsl:attribute name="cert" select="$new-cert"/>
            <xsl:attribute name="cert2" select="$new-cert2"/>
            <xsl:apply-templates select="tan:lm" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Currently the application relies exclusively on lexemes, not morphological forms, so we drop those. -->
    <xsl:template match="tan:m" mode="simplify-ana"/>
    

    <!-- Input prep 2: normalize space, imprint language codes -->
    <!-- The result document will have a root element with @xml:base and @xml:lang, and any other attributes present
        in the original root element. That root element effectively acts as a body, and contains only the <div>-based
        text structure, space-normalized. -->
    <xsl:variable name="files-normalized-g1" as="document-node()*">
        <xsl:message select="'normalizing group 1 texts'"/>
        <xsl:apply-templates select="$files-resolved-g1" mode="normalize-input"/>
    </xsl:variable>
    <xsl:variable name="files-normalized-g2" as="document-node()*">
        <xsl:message select="'normalizing group 2 texts'"/>
        <xsl:apply-templates select="$files-resolved-g2" mode="normalize-input"/>
    </xsl:variable>
    
    
    <xsl:mode name="normalize-input" on-no-match="shallow-skip"/>
    
    <xsl:template match="document-node()" mode="normalize-input">
        <xsl:document>
            <xsl:apply-templates mode="#current"/>
        </xsl:document>
    </xsl:template>
    
    <xsl:template match="/tan:* | /tei:TEI | /w:document" mode="normalize-input">
        <xsl:variable name="primary-lang-attr" select="tei:text/tei:body/@xml:lang, tan:body/@xml:lang" as="attribute()?"/>
        <xsl:element name="{local-name(.)}" namespace="{namespace-uri(.)}">
            <xsl:copy-of select="@*[substring-before(name(.), ':') = ('', 'xml')]"/>
            <xsl:copy-of select="$primary-lang-attr"/>
            <xsl:if test="not(exists($primary-lang-attr))">
                <xsl:attribute name="xml:lang" select="$fallback-language"/>
            </xsl:if>
            <!-- Add a @src identifier for building the class 2 output. -->
            <xsl:attribute name="src" select="tan:cfn(string(@xml:base))"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="/tan:unparsed-text" mode="normalize-input">
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="normalize-unicode(normalize-space(.))"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:body" mode="normalize-input">
        <xsl:copy-of select="tan:normalize-tree-space(tan:normalize-unicode(.), true())/node()"/>
    </xsl:template>

    <xsl:template match="tei:body" mode="normalize-input">
        <xsl:copy-of
            select="tan:make-non-mixed(tan:normalize-tree-space(tan:normalize-unicode(.), true())/node())"
        />
    </xsl:template>
    
    <xsl:template match="w:p" mode="normalize-input">
        <!-- Convert the Word document's <p> to a TAN div -->
        <div type="paragraph" n="{position()}">
            <xsl:sequence select="normalize-unicode(normalize-space(tan:docx-to-text(.))) || ' '"/>
        </div>
    </xsl:template>
    
    
    
    <xsl:variable name="tokenization-map-normalized" as="map(xs:string,xs:string)">
        <xsl:map>
            <xsl:for-each-group select="$files-normalized-g1/*/@xml:lang, $files-normalized-g2/*/@xml:lang" group-by="string(.)">
                <xsl:variable name="current-tok-pattern" select="$tokenization-map(current-grouping-key())" as="xs:string?"/>
                <xsl:variable name="current-tok-pattern-norm" select="
                        if (string-length($current-tok-pattern) lt 1 or not(tan:regex-is-valid($current-tok-pattern)))
                        then
                            string($tan:token-definition-default/@pattern)
                        else
                            $current-tok-pattern"/>
                <xsl:map-entry key="current-grouping-key()" select="$current-tok-pattern-norm"/>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    
    
    
    <!-- Input prep 3: tokenize -->
    
    <xsl:variable name="files-tokenized-g1" as="document-node()*">
        <xsl:message select="'tokenizing group 1 texts'"/>
        <xsl:apply-templates select="$files-normalized-g1" mode="tokenize-text"/>
    </xsl:variable>
    <xsl:variable name="files-tokenized-g2" as="document-node()*">
        <xsl:message select="'tokenizing group 2 texts'"/>
        <xsl:apply-templates select="$files-normalized-g2" mode="tokenize-text"/>
    </xsl:variable>
    
    <xsl:mode name="tokenize-text" on-no-match="shallow-copy"/>
    
    <xsl:template match="document-node()" mode="tokenize-text">
        <xsl:variable name="this-xml-base" as="attribute()" select="*/@xml:base"/>
        <xsl:variable name="annotations-already-parsed" as="document-node()*"
            select="$files-with-tan-a-lm-annotations[*/@xml:base eq $this-xml-base]"/>
        <xsl:if test="count($annotations-already-parsed) gt 1">
            <xsl:message select="'There are ' || string(count($annotations-already-parsed)) || ' TAN-A-lm annotations for ' || $this-xml-base || '; using only the first.'"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="exists($annotations-already-parsed)">
                <xsl:sequence select="$annotations-already-parsed[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:document>
                    <xsl:apply-templates mode="#current"/>
                </xsl:document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- At this point /* should be equivalent to *[@xml:lang] -->
    <xsl:template match="*[@xml:lang]" mode="tokenize-text">
        
        <xsl:variable name="this-lang" select="@xml:lang" as="xs:string"/>
        
        <xsl:variable name="text-tokenized" as="element()*">
            <xsl:analyze-string select="." regex="{$tokenization-map-normalized($this-lang)}">
                <xsl:matching-substring>
                    <tok>
                        <xsl:value-of select="."/>
                    </tok>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <x>
                        <xsl:value-of select="."/>
                    </x>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:iterate select="$text-tokenized">
                <xsl:param name="tok-number" as="xs:integer" select="1"/>
                <xsl:param name="current-pos" as="xs:integer" select="1"/>
                
                <xsl:variable name="this-len" select="string-length(.)" as="xs:integer"/>
                
                <xsl:copy copy-namespaces="no">
                    <xsl:attribute name="n" select="$tok-number"/>
                    <!-- We stamp with @_pos and @_len to facilitate infusion into the original. -->
                    <xsl:attribute name="_pos" select="$current-pos"/>
                    <xsl:attribute name="_len" select="$this-len"/>
                    <xsl:value-of select="."/>
                </xsl:copy>
                
                <xsl:choose>
                    <xsl:when test="$tok-number eq $diagnostics-tok-ceiling">
                        <xsl:message select="'For diagnostics, capping the number of tokens at ' || string($diagnostics-tok-ceiling)"/>
                        <xsl:break/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:next-iteration>
                            <xsl:with-param name="tok-number" select="
                                    if (self::tan:tok) then
                                        $tok-number + 1
                                    else
                                        $tok-number"/>
                            <xsl:with-param name="current-pos" select="$current-pos + $this-len"/>
                        </xsl:next-iteration>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:iterate>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:variable name="input-tokenization-map" as="map(*)">
        <xsl:map>
            <xsl:apply-templates select="$files-tokenized-g1, $files-tokenized-g2"
                mode="build-tokenization-map"/>
        </xsl:map>
    </xsl:variable>
    
    <xsl:mode name="build-tokenization-map" on-no-match="shallow-skip"/>
    
    <xsl:template match="/*" mode="build-tokenization-map">
        <xsl:variable name="tok-count" as="xs:integer" select="count(tan:tok)"/>
        <xsl:variable name="simple-tok-groups" as="array(*)*">
            <xsl:for-each-group select="tan:tok" group-by="tan:string-base(lower-case(text()))">
                <xsl:variable name="this-count" as="xs:integer" select="count(current-group())"/>
                <xsl:sequence select="array {current-grouping-key(), $this-count}"/>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="simple-tok-counts" as="xs:integer*" select="
                for $i in $simple-tok-groups
                return
                    $i(2)"/>
        <xsl:variable name="simple-tok-median" as="xs:decimal"
            select="tan:median($simple-tok-counts)"/>
        <xsl:variable name="simple-tok-avg" as="xs:decimal" select="avg($simple-tok-counts)"/>
        <xsl:map-entry key="@xml:base">
            <!-- build a map going from token number to tok + non-tok -->
            <xsl:map>
                <xsl:for-each-group select="*" group-by="@n">
                    <xsl:map-entry key="xs:integer(current-grouping-key())">
                        <xsl:sequence select="current-group()"/>
                    </xsl:map-entry>
                </xsl:for-each-group>
            </xsl:map>
            <!-- build a map going from simplified token to its count, average -->
            <xsl:map>
                <xsl:for-each select="$simple-tok-groups">
                    <xsl:variable name="this-count" as="xs:integer" select=".(2)"/>
                    <xsl:map-entry key=".(1)">
                        <!-- count, per-median, per-average, per-total -->
                        <xsl:sequence select="$this-count"/>
                        <xsl:sequence select="$this-count div $simple-tok-median"/>
                        <xsl:sequence select="$this-count div $simple-tok-avg"/>
                        <xsl:sequence select="$this-count div $tok-count"/>
                    </xsl:map-entry>
                </xsl:for-each>
            </xsl:map>
        </xsl:map-entry>
    </xsl:template>
    
    
    
    
    
    <xsl:variable name="skp-alphabet-map" as="map(xs:string,xs:string+)">
        <xsl:map>
            <xsl:if test="$use-skp-fallback-alias-routine">
                <xsl:for-each-group select="$files-tokenized-g1" group-by="*/@xml:lang">
                    <xsl:variable name="this-text" as="xs:string"
                        select="tan:string-base(lower-case(string-join(current-group()/*/tan:tok/text())))"
                    />
                    <xsl:map-entry key="current-grouping-key()"
                        select="tan:build-skp-sequence($this-text)"/>
                </xsl:for-each-group> 
            </xsl:if>
        </xsl:map>
    </xsl:variable>
    
    
    <!-- CONVERTING TOKENS TO ALIAS VALUES -->
    <!-- Alias values provide for better matching from one text to the other. -->
    
    <xsl:variable name="tok-aliases-g1" as="document-node()*">
        <xsl:message select="'Building group 1 token aliases'"/>
        <xsl:apply-templates select="$files-tokenized-g1" mode="build-tok-aliases"/>
    </xsl:variable>
    <xsl:variable name="tok-aliases-g2" as="document-node()*">
        <xsl:message select="'Building group 2 token aliases'"/>
        <xsl:apply-templates select="$files-tokenized-g2" mode="build-tok-aliases"/>
    </xsl:variable>
    
    
    
    <xsl:mode name="build-tok-aliases" on-no-match="shallow-copy"/>
    
    <!-- This is the first stage at which one can get genuine gains in performance via temporary files. It still
        requires some time for long files, if the checksum routine is strict and needs to be applied to large
        files. -->
    
    <xsl:template match="/" mode="build-tok-aliases" priority="1" use-when="$tan:save-and-use-intermediate-steps">
        
        <xsl:variable name="current-lang" as="xs:string" select="*/@xml:lang"/>
        <xsl:variable name="these-lang-catalogs" select="tan:lang-catalog(*/@xml:lang)" as="document-node()*"/>
        <xsl:variable name="lang-catalog-values" as="xs:string+" select="
                if ($verify-intermediate-steps-strictly) then
                    $these-lang-catalogs/collection/doc/@href
                else
                    (for $i in $these-lang-catalogs
                    return
                        string(base-uri($i)))"/>
        <xsl:message select="'Building token alias manifest'"/>
        <xsl:variable name="manifest" as="element()">
            <manifest>
                <base-uri><xsl:value-of select="*/@xml:base"/></base-uri>
                <predecessor>
                    <xsl:value-of select="
                            if ($verify-intermediate-steps-strictly) then
                                tan:checksum-fletcher-32(serialize(tan:drop-manifest(.)))
                            else
                                'length ' || string(string-length(tan:drop-manifest(.)))"
                    />
                </predecessor>
                <tokenization-regex>
                    <xsl:value-of select="$tokenization-map-normalized(*/@xml:lang)"/>
                </tokenization-regex>
                <lang-catalogs>
                    <xsl:value-of select="string-join($lang-catalog-values, ' ')"/>
                </lang-catalogs>
                <xsl:if test="$use-skp-fallback-alias-routine">
                    <skp-alphabet-map><xsl:value-of select="$skp-alphabet-map($current-lang)"/></skp-alphabet-map>
                    <skp-letter-max><xsl:value-of select="$skp-letter-maximum"/></skp-letter-max>
                    <skp-most-frequent><xsl:value-of select="$skp-use-most-frequent-letters"/></skp-most-frequent>
                </xsl:if>
            </manifest>
        </xsl:variable>
        <xsl:message select="'Building token alias checksum'"/>
        <xsl:variable name="this-manifest-checksum" select="tan:checksum-fletcher-32(string($manifest))" as="xs:string"/>
        <xsl:variable name="expected-temp-file-location" as="xs:anyURI"
            select="resolve-uri($this-manifest-checksum || '-result.xml', $temporary-file-directory-norm)"
        />
        <xsl:variable name="manifest-stamped" as="element()"
            select="tan:stamp-manifest($manifest, $this-manifest-checksum)"/>
        
        <xsl:choose>
            <xsl:when test="doc-available($expected-temp-file-location)">
                <xsl:message select="tan:cfn(*/@xml:base) || ' token alias creation: fetching intermediate file from ' || $expected-temp-file-location"/>
                <xsl:sequence select="doc($expected-temp-file-location)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="tan:cfn(*/@xml:base) || ' token alias creation: no intermediate file found at ' || $expected-temp-file-location"/>
                <xsl:next-match>
                    <xsl:with-param name="manifest" as="element()" tunnel="yes" select="$manifest-stamped"/>
                    <!--<xsl:with-param name="manifest-checksum" tunnel="yes" as="xs:string" select="$this-manifest-checksum"/>-->
                </xsl:next-match>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="*[@xml:lang]" mode="build-tok-aliases">

        <xsl:param name="manifest" tunnel="yes" as="element()?"/>

        <xsl:variable name="this-lang" select="@xml:lang" as="xs:string"/>

        <xsl:variable name="toks-defined-by-source-specific-tan-a-lms" as="element()*"
            select="tan:tok[tan:ana]"/>
        <xsl:variable name="toks-to-check-against-general-lang-catalogs" as="element()*"
            select="tan:tok except $toks-defined-by-source-specific-tan-a-lms"/>
        
        <xsl:variable name="these-lang-catalogs" select="tan:lang-catalog($this-lang)" as="document-node()*"/>
        
        
        <xsl:message select="'Converting ' || string(count(tan:tok)) || ' tokens to token aliases in ' || @xml:base"/>
        
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>

            <xsl:copy-of select="$manifest"/>
            
            <!-- The tokens that have already been checked for lexicomorphological data specific to the
                file -->
            <xsl:apply-templates select="$toks-defined-by-source-specific-tan-a-lms"
                mode="lm-to-gram">
                <xsl:with-param name="method" tunnel="yes" as="xs:string" select="'tan-a-lm-annotation'"/>
            </xsl:apply-templates>
            
            <xsl:for-each-group select="$toks-to-check-against-general-lang-catalogs"
                group-by="tan:TAN-A-lm-hrefs($this-lang, ., $these-lang-catalogs)">
                
                <xsl:variable name="tan-a-lm-base-uri" select="current-grouping-key()" as="xs:string"/>
                <xsl:variable name="this-tan-a-lm" as="document-node()?"
                    select="doc($tan-a-lm-base-uri)"/>

                <xsl:choose>
                    <xsl:when test="$tan-a-lm-base-uri eq '' and $use-skp-fallback-alias-routine">
                        <!-- If there are no TAN-A-lm files the best we can do is go for a bland version of the
                        token, in this case an SKP token (the token reduced to the two or three letters that
                        are most/least frequently used un the language). 
                        -->
                        <xsl:for-each-group select="current-group()"
                            group-by="tan:skp-reduce(lower-case(tan:string-base(.)), $skp-alphabet-map($this-lang), $skp-use-most-frequent-letters, $skp-letter-maximum)">
                            <alias r="{current-grouping-key()}">
                                <xsl:for-each select="current-group()">
                                    <xsl:copy>
                                        <xsl:copy-of select="@*"/>
                                        <!-- skp = lower-case, string base, Shmidman, Koppel, and Porat method -->
                                        <resp method="skp" cert="1" cert2="1"/>
                                        <xsl:copy-of select="node()"/>
                                    </xsl:copy>
                                </xsl:for-each>
                                <xsl:copy-of select="current-group()"/>
                            </alias>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:when test="$tan-a-lm-base-uri eq ''">
                        <!-- If SKP hasn't been chosen, we go with the standar lowercase, without diacriticals. -->
                        <xsl:for-each-group select="current-group()"
                            group-by="lower-case(tan:string-base(.))">
                            <alias r="{current-grouping-key()}">
                                <xsl:for-each select="current-group()">
                                    <xsl:copy>
                                        <xsl:copy-of select="@*"/>
                                        <!-- lcsb = lower-case, string base -->
                                        <resp method="lcsb" cert="1" cert2="1"/>
                                        <xsl:copy-of select="node()"/>
                                    </xsl:copy>
                                </xsl:for-each>
                                <xsl:copy-of select="current-group()"/>
                            </alias>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message select="'Looking up lexemes for ' || string(count(current-group())) || ' tokens, using language TAN-A-lm ' || current-grouping-key()"/>
                        <xsl:for-each-group select="current-group()" group-by=".">
                            <xsl:variable name="this-tok" select="current-grouping-key()"/>
                            <xsl:variable name="lex-matches" as="element()*"
                                select="$this-tan-a-lm/tan:TAN-A-lm/tan:body/tan:ana[tan:tok[@val eq $this-tok or matches(@rgx, '^' || tan:escape($this-tok) || '$')]]"
                            />
                            <xsl:apply-templates select="$lex-matches" mode="lm-to-gram">
                                <xsl:with-param name="toks-to-embed" select="current-group()" tunnel="yes" as="element()*"/>
                                <xsl:with-param name="tan-a-lm-base-uri" tunnel="yes" select="$tan-a-lm-base-uri"/>
                            </xsl:apply-templates>
                        </xsl:for-each-group> 
                        
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each-group> 
        </xsl:copy>
    </xsl:template>
    
    
    
    
    
    <xsl:mode name="lm-to-gram" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:tok[tan:ana[not(tan:lm)]]" priority="1" mode="lm-to-gram">
        <xsl:param name="current-lang" as="xs:string?" select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
        <xsl:choose>
            <xsl:when test="$use-skp-fallback-alias-routine">
                <alias
                    r="{tan:skp-reduce(lower-case(tan:string-base(.)), $skp-alphabet-map($current-lang), $skp-use-most-frequent-letters, $skp-letter-maximum)}">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <resp method="skp" cert="1" cert2="1"/>
                        <xsl:value-of select="text()"/>
                    </xsl:copy>
                </alias>
            </xsl:when>
            <xsl:otherwise>
                <alias r="{lower-case(tan:string-base(.))}">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <resp method="lcsb" cert="1" cert2="1"/>
                        <xsl:value-of select="text()"/>
                    </xsl:copy>
                </alias>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    <xsl:template match="tan:tok[tan:ana]" mode="lm-to-gram">
        <!-- This is for cases where a source-specific TAN-A-lm's results have been infused into the
            tokenized text. -->
        <xsl:variable name="this-tok-to-embed" as="element()">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:value-of select="text()[matches(., '\S')]"/>
            </xsl:copy>
        </xsl:variable>
        
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="toks-to-embed" select="$this-tok-to-embed" tunnel="yes" as="element()*"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="*[@cert or @cert2]" mode="lm-to-gram">
        <xsl:param name="current-cert" tunnel="yes" as="xs:decimal?"/>
        <xsl:param name="current-cert2" tunnel="yes" as="xs:decimal?"/>
        <xsl:param name="toks-to-embed" tunnel="yes" as="element()*"/>
        
        <xsl:variable name="c-cert" as="xs:decimal" select="($current-cert, 1.0)[1]"/>
        <xsl:variable name="c-cert2" as="xs:decimal" select="($current-cert2, $c-cert)[1]"/>
        <xsl:variable name="this-tok" select="string($toks-to-embed[1])" as="xs:string"/>
        <!-- In a language-based TAN-A-lm there should just be one matching <tok>, but
            just in case... -->
        <xsl:variable name="toks-of-interest" as="element()*"
            select="self::tan:ana/tan:tok[@val eq $this-tok or matches(@rgx, '^' || $this-tok || '$')]"
        />
        <xsl:variable name="tok-cert" as="xs:decimal" select="
                if (exists($toks-of-interest)) then
                    (avg(for $i in $toks-of-interest
                    return
                        xs:decimal(($i/@cert, 1.0)[1])))
                else
                    1.0"/>
        <xsl:variable name="tok-cert2" as="xs:decimal" select="
                if (exists($toks-of-interest)) then
                    (avg(for $i in $toks-of-interest
                    return
                        xs:decimal(($i/@cert2, $i/@cert, 1.0)[1])))
                else
                    1.0"/>
        
        
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="current-cert" tunnel="yes" select="$c-cert * $tok-cert * xs:decimal((@cert, 1.0)[1])"/>
            <xsl:with-param name="current-cert2" tunnel="yes" select="$c-cert2 * $tok-cert2 * xs:decimal((@cert2, @cert, 1.0)[1])"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="tan:l" priority="1" mode="lm-to-gram">
        <xsl:param name="tan-a-lm-base-uri" as="xs:string?" tunnel="yes" select="tan:base-uri(.)"/>
        <xsl:param name="toks-to-embed" tunnel="yes" as="element()*"/>
        <xsl:param name="current-cert" tunnel="yes" as="xs:decimal?"/>
        <xsl:param name="current-cert2" tunnel="yes" as="xs:decimal?"/>
        <xsl:param name="method" tunnel="yes" as="xs:string?" select="'tan-a-lm-language'"/>
        
        <xsl:variable name="c-cert" as="xs:decimal" select="($current-cert, 1.0)[1]"/>
        <xsl:variable name="c-cert2" as="xs:decimal" select="($current-cert2, $c-cert)[1]"/>
        
        <xsl:variable name="new-cert" select="$c-cert * xs:decimal((@cert, 1.0)[1])" as="xs:decimal"/>
        <xsl:variable name="new-cert2" select="$c-cert2 * xs:decimal((@cert2, @cert, 1.0)[1])" as="xs:decimal"/>
        <xsl:variable name="context-l" select="." as="element()"/>
        <alias r="{$context-l}">

            <xsl:for-each select="$toks-to-embed">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <resp method="{$method}" source="{$tan-a-lm-base-uri}" cert="{$new-cert}" cert2="{$new-cert2}"/>
                    <xsl:copy-of select="node()"/>
                </xsl:copy>
            </xsl:for-each>
        </alias>
    </xsl:template>
    
    
    <xsl:variable name="token-alias-maps-g1" as="map(*)*">
        <xsl:message select="'building group 1 token alias maps'"/>
        <xsl:apply-templates select="$tok-aliases-g1" mode="build-tok-alias-map"/>
    </xsl:variable>
    <xsl:variable name="token-alias-maps-g2" as="map(*)*">
        <xsl:message select="'building group 2 token alias maps'"/>
        <xsl:apply-templates select="$tok-aliases-g2" mode="build-tok-alias-map"/>
    </xsl:variable>
    
    <xsl:mode name="build-tok-alias-map" on-no-match="shallow-skip"/>
    
    <xsl:template match="*[tan:alias]" mode="build-tok-alias-map">
        
        <xsl:variable name="pass-1" as="map(*)">
            <xsl:map>
                <xsl:for-each-group select="tan:alias" group-by="@r">
                    <xsl:sort select="count(distinct-values(current-group()/tan:tok/@n))"
                        order="descending"/>
                    <xsl:variable name="this-r" select="current-grouping-key()" as="xs:string"/>
                    
                    <xsl:map-entry key="position()">
                        <xsl:map>
                            <xsl:map-entry key="'r'" select="$this-r"/>
                            <xsl:for-each-group select="current-group()/tan:tok" group-by="@n">
                                <xsl:variable name="these-certs" as="xs:decimal*" select="
                                        for $i in current-group()/*/@cert
                                        return
                                            xs:decimal($i)"/>
                                <xsl:variable name="these-cert2s" as="xs:decimal*" select="
                                        for $i in current-group()/*/@cert2
                                        return
                                            xs:decimal($i)"/>
                                <xsl:map-entry key="xs:integer(current-grouping-key())">
                                    <xsl:map>
                                        <xsl:map-entry key="'val'"
                                            select="string(current-group()[1])"/>
                                        <xsl:map-entry key="'cert'" select="$these-certs"/>
                                        <xsl:map-entry key="'cert2'" select="$these-cert2s"/>
                                        <!-- If in the future the averages should be weighted depending upon source,
                                            this is where that process should be built. -->
                                        <xsl:map-entry key="'cert-avg'"
                                            select="avg(($these-certs, $these-cert2s))"/>
                                    </xsl:map>
                                </xsl:map-entry>
                            </xsl:for-each-group>
                        </xsl:map>
                    </xsl:map-entry>
                </xsl:for-each-group>
                
            </xsl:map>
        </xsl:variable>
        
        <xsl:variable name="token-alias-count" select="map:size($pass-1)" as="xs:integer"/>
        <xsl:variable name="every-token-alias-tok-pop" select="
                for $i in map:keys($pass-1)
                return
                    count(map:keys($pass-1($i)))" as="xs:integer+"/>
        
        <xsl:variable name="median-token-alias-tok-pop" select="tan:median($every-token-alias-tok-pop)" as="xs:decimal"/>
        <xsl:variable name="average-token-alias-tok-pop" select="avg($every-token-alias-tok-pop)" as="xs:decimal"/>
        <xsl:variable name="total-token-alias-tok-pop" select="sum($every-token-alias-tok-pop)" as="xs:integer"/>
        
        
        <xsl:map>
            <xsl:apply-templates select="@*" mode="attr-to-map-entry"/>
            <xsl:map-entry key="'token-alias-count'" select="$token-alias-count"/>
            
            <!-- Build statistical profiles for each token alias. -->
            <xsl:map-entry key="'stats'">
                <xsl:map>
                    <xsl:for-each select="1 to $token-alias-count">
                        <xsl:variable name="this-n" as="xs:integer" select="."/>
                        <xsl:variable name="this-map-entry" select="$pass-1($this-n)" as="map(*)"/>
                        <xsl:variable name="this-map-size" select="map:size($this-map-entry) - 1"
                            as="xs:integer"/>
                        <xsl:variable name="this-r" as="xs:string" select="$this-map-entry('r')"/>

                        <!-- Map entries keys in the statistics are bound to the token alias value,
                        to facilitate lookup -->
                        <xsl:map-entry key="$this-r">
                            <xsl:map>
                                <xsl:map-entry key="'tok-count'" select="$this-map-size"/>
                                <xsl:map-entry key="'tok-count-per-median'"
                                    select="$this-map-size div $median-token-alias-tok-pop"/>
                                <xsl:map-entry key="'tok-count-per-average'"
                                    select="$this-map-size div $average-token-alias-tok-pop"/>
                                <xsl:map-entry key="'tok-count-per-total'"
                                    select="$this-map-size div $total-token-alias-tok-pop"/>
                            </xsl:map>
                        </xsl:map-entry>

                    </xsl:for-each>
                </xsl:map>
            </xsl:map-entry>
            
            <!-- The map entry keys are numbered 1 onward, from most frequent to least, so that if requested the most 
            common can be chopped off. -->
            <xsl:for-each select="1 to $token-alias-count">
                <xsl:map-entry key=".">
                    <xsl:sequence select="map:get($pass-1, .)"/>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:template>
    
    
    <xsl:mode name="attr-to-map-entry" on-no-match="shallow-skip"/>
    
    <xsl:template match="@*" mode="attr-to-map-entry">
        <xsl:map-entry key="name(.)" select="string(.)"/>
    </xsl:template>
    
    
    
    
    <!-- Consolidate <gram>s by @r (grouping key), with the most common at the top -->
    <xsl:variable name="tok-aliases-consolidated-g1" as="document-node()*">
        <xsl:apply-templates select="$tok-aliases-g1" mode="consolidate-tok-aliases"/>
    </xsl:variable>
    <xsl:variable name="tok-aliases-consolidated-g2" as="document-node()*">
        <xsl:apply-templates select="$tok-aliases-g2" mode="consolidate-tok-aliases"/>
    </xsl:variable>
    
    <xsl:mode name="consolidate-tok-aliases" on-no-match="shallow-copy"/>
    
    <xsl:template match="*[tan:alias]" mode="consolidate-tok-aliases">
        
        <xsl:variable name="pass-1" as="element()*">
            <xsl:for-each-group select="tan:alias" group-by="@r">
                <xsl:sort select="count(distinct-values(current-group()/tan:tok/@n))"
                    order="descending"/>
                <xsl:variable name="this-r" select="current-grouping-key()" as="xs:string"/>
                <alias r="{$this-r}" alias-pos="{position()}">
                    <xsl:apply-templates select="node() except tan:tok" mode="#current"/>
                    <xsl:for-each-group select="current-group()/tan:tok" group-by="@n">
                        <xsl:variable name="this-cert" as="xs:double*" select="
                                for $i in current-group()/*/@cert
                                return
                                    xs:double($i)"/>
                        <xsl:variable name="this-cert2" as="xs:double*" select="
                                for $i in current-group()/*/@cert2
                                return
                                    xs:double($i)"/>
                        <tok>
                            <xsl:copy-of select="current-group()[1]/@*"/>
                            <xsl:copy-of select="current-group()/*"/>
                            <xsl:value-of select="current-group()[1]"/>
                        </tok>
                    </xsl:for-each-group>
                </alias>
            </xsl:for-each-group>
        </xsl:variable>
        
        <xsl:variable name="alias-count" select="count($pass-1)" as="xs:integer"/>
        <xsl:variable name="every-token-alias-pop" select="
                for $i in $pass-1
                return
                    count($i/tan:tok)" as="xs:integer+"/>
        <xsl:variable name="median-alias" select="$pass-1[$alias-count idiv 2]" as="element()"/>
        <xsl:variable name="median-alias-tok-pop" select="tan:median($every-token-alias-pop)" as="xs:decimal"/>
        <xsl:variable name="average-alias-tok-pop" select="avg($every-token-alias-pop)" as="xs:decimal"/>
        <xsl:variable name="total-alias-tok-pop" select="sum($every-token-alias-pop)" as="xs:integer"/>
        
        
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="$pass-1" mode="#current">
                <xsl:with-param name="median-alias-tok-pop" tunnel="yes" as="xs:integer" select="$median-alias-tok-pop"/>
                <xsl:with-param name="average-alias-tok-pop" tunnel="yes" as="xs:decimal" select="$average-alias-tok-pop"/>
                <xsl:with-param name="total-alias-tok-pop" tunnel="yes" as="xs:integer" select="$total-alias-tok-pop"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="tan:alias" mode="consolidate-tok-aliases">
        <xsl:param name="median-alias-tok-pop" tunnel="yes" as="xs:integer"/>
        <xsl:param name="average-alias-tok-pop" tunnel="yes" as="xs:decimal"/>
        <xsl:param name="total-alias-tok-pop" tunnel="yes" as="xs:integer"/>
        
        <xsl:variable name="tok-count" as="xs:integer" select="count(tan:tok)"/>
        
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <!-- Embed frequency statistics; score and interpret them later -->
            <alias-tok-frequency>
                <xsl:attribute name="count" select="$tok-count"/>
                <xsl:attribute name="per-median" select="$tok-count div $median-alias-tok-pop"/>
                <xsl:attribute name="per-average" select="$tok-count div $average-alias-tok-pop"/>
                <xsl:attribute name="per-total" select="$tok-count div $total-alias-tok-pop"/>
            </alias-tok-frequency>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    
    <xsl:function name="tan:build-paired-1gram-map" as="map(*)?" visibility="private" _cache="{$tan:advanced-processing-available}">
        <!-- Input: two token alias maps, a double, a boolean -->
        <!-- Output: a paired 1gram, i.e., where there are common token aliases between the two texts -->
        <!-- The double represents the portion of the most frequent aliases that should be excluded. The
            boolean specifies whether any chopped aliases must be frequent in both texts. -->
        <xsl:param name="group-1-token-alias-map" as="map(*)"/>
        <xsl:param name="group-2-token-alias-map" as="map(*)"/>
        <!--<xsl:param name="aura-diameter" as="xs:integer?"/>-->
        <xsl:param name="drop-most-frequent" as="xs:decimal?"/>
        <xsl:param name="drop-must-be-frequent-in-both" as="xs:boolean?"/>
        
        <xsl:variable name="current-lang" as="xs:string" select="$group-1-token-alias-map('xml:lang')"/>
        <xsl:variable name="alias-values-to-skip" as="xs:string*" select="
                if ($apply-skip-token-alias-map) then
                    ($skip-token-alias-map('*'), $skip-token-alias-map($current-lang))
                else
                    ()"/>
        
        
        <xsl:variable name="g1-token-alias-count" select="$group-1-token-alias-map('token-alias-count')" as="xs:integer"/>
        <xsl:variable name="g1-floor" select="xs:integer(floor($drop-most-frequent * $g1-token-alias-count))" as="xs:integer"/>
        <xsl:variable name="g1-frequent-token-aliases-to-ignore" as="map(*)*" select="
                for $i in (1 to $g1-floor)
                return
                    $group-1-token-alias-map($i)"/>
        <!-- We take the rest of the candidate integer keys, and if the token alias should be ignored, we mark it by
            negating it, so that we can report the omission -->
        <xsl:variable name="g1-other-token-alias-keys-checked" as="xs:integer*" select="
                for $i in (($g1-floor + 1) to $g1-token-alias-count)
                return
                    if ($group-1-token-alias-map($i)('r') = $alias-values-to-skip) then
                        ($i * -1)
                    else
                        $i"/>
        <xsl:variable name="g1-keys-to-omit" as="xs:integer*"
            select="$g1-other-token-alias-keys-checked[. lt 0]"/>
        <xsl:variable name="g1-token-aliases-to-process" as="map(*)*" select="
                for $i in $g1-other-token-alias-keys-checked[. gt 0]
                return
                    $group-1-token-alias-map($i)"/>
        
        
        <xsl:variable name="g2-token-alias-count" select="$group-2-token-alias-map('token-alias-count')" as="xs:integer"/>
        <xsl:variable name="g2-floor" select="xs:integer(floor($drop-most-frequent * $g2-token-alias-count))" as="xs:integer"/>
        <xsl:variable name="g2-frequent-token-aliases-to-ignore" as="map(*)*" select="
                for $i in (1 to $g2-floor)
                return
                    $group-2-token-alias-map($i)"/>
        <xsl:variable name="g2-other-token-alias-keys-checked" as="xs:integer*" select="
                for $i in (($g2-floor + 1) to $g2-token-alias-count)
                return
                    if ($group-2-token-alias-map($i)('r') = $alias-values-to-skip) then
                        ($i * -1)
                    else
                        $i"/>
        <xsl:variable name="g2-keys-to-omit" as="xs:integer*"
            select="$g2-other-token-alias-keys-checked[. lt 0]"/>
        <xsl:variable name="g2-token-aliases-to-process" as="map(*)*" select="
                for $i in $g2-other-token-alias-keys-checked[. gt 0]
                return
                    $group-2-token-alias-map($i)"/>
        
        

        <xsl:if test="exists($g1-frequent-token-aliases-to-ignore)">
            <xsl:message select="
                    tan:cfn($group-1-token-alias-map('xml:base')) || ' (group 1): in building 1gram, cutting the following most frequent token aliases (' || string(count($g1-frequent-token-aliases-to-ignore)) || '): ' || string-join((for $i in $g1-frequent-token-aliases-to-ignore
                    return
                        $i('r')), ', ')"/>
        </xsl:if>
        <xsl:if test="exists($g2-frequent-token-aliases-to-ignore)">
            <xsl:message select="
                    tan:cfn($group-2-token-alias-map('xml:base')) || ' (group 2): in building 1gram, cutting the following most frequent token aliases (' || string(count($g2-frequent-token-aliases-to-ignore)) || '): ' || string-join((for $i in $g2-frequent-token-aliases-to-ignore
                    return
                        $i('r')), ', ')"/>
        </xsl:if>
        <xsl:if test="exists($g1-keys-to-omit)">
            <xsl:message select="
                    tan:cfn($group-1-token-alias-map('xml:base')) || ' (group 1): in building 1gram, skipping these token aliases (' || string(count($g1-keys-to-omit)) || '): ' || string-join((for $i in $g1-keys-to-omit
                    return
                        $group-1-token-alias-map($i * -1)('r')), ', ')"/>
        </xsl:if>
        <xsl:if test="exists($g1-keys-to-omit)">
            <xsl:message select="
                    tan:cfn($group-2-token-alias-map('xml:base')) || ' (group 2): in building 1gram, skipping these token aliases (' || string(count($g2-keys-to-omit)) || '): ' || string-join((for $i in $g2-keys-to-omit
                    return
                        $group-2-token-alias-map($i * -1)('r')), ', ')"/>
        </xsl:if>
        
        
        
        <xsl:map>
            <xsl:map-entry key="'n'" select="1"/>
            <xsl:map-entry key="'lang'" select="$current-lang"/>
            <xsl:map-entry key="'base1'" select="$group-1-token-alias-map('xml:base')"/>
            <xsl:map-entry key="'base2'" select="$group-2-token-alias-map('xml:base')"/>
            <xsl:map-entry key="'src1'" select="$group-1-token-alias-map('src')"/>
            <xsl:map-entry key="'src2'" select="$group-2-token-alias-map('src')"/>
            <xsl:map-entry key="'ngrams'">
                <xsl:map>
                    <xsl:for-each-group select="
                            $g1-token-aliases-to-process, $g2-token-aliases-to-process"
                        group-by=".('r')">
                        <!--<xsl:sort select="current-grouping-key()"/>-->
                        <!-- ignore any aliases that are attested in only one source -->
                        <xsl:if test="count(current-group()) gt 1">
                            <!-- The key becomes the token alias that is alphabetically first within
                                the ngram; in the case of a paired one-gram, the ngram's key becomes
                                identical with its grandchildren map keys. -->
                            <xsl:map-entry key="current-grouping-key()">
                                <!-- Copy the two maps in sequence order, one for text 1, the other for text 2 -->
                                <xsl:map>
                                    <!-- Map #1 is for text 1 grams -->
                                    <xsl:map-entry key="current-grouping-key()">
                                        <xsl:sequence select="current-group()[1]"/>
                                    </xsl:map-entry>
                                </xsl:map>
                                <xsl:map>
                                    <!-- This is for text 2 -->
                                    <xsl:map-entry key="current-grouping-key()">
                                        <xsl:sequence select="current-group()[2]"/>
                                    </xsl:map-entry>
                                </xsl:map>
                            </xsl:map-entry>
                        </xsl:if>
                    </xsl:for-each-group>
                </xsl:map>
            </xsl:map-entry>
        </xsl:map>
        
    </xsl:function>
    
    
    <xsl:function name="tan:build-paired-1gram" as="document-node()?" visibility="private" _cache="{$tan:advanced-processing-available}">
        <!-- Input: two documents with token aliases, a double, a boolean -->
        <!-- Output: a paired 1gram, i.e., where there are common token aliases between the two texts -->
        <!-- The double represents the portion of the most frequent aliases that should be excluded. The
            boolean specifies whether any chopped aliases must be frequent in both texts. -->
        <xsl:param name="group-1-aliases" as="document-node()"/>
        <xsl:param name="group-2-aliases" as="document-node()"/>
        <xsl:param name="aura" as="xs:integer?"/>
        <xsl:param name="drop-most-frequent" as="xs:decimal?"/>
        <xsl:param name="drop-must-be-frequent-in-both" as="xs:boolean?"/>
        <xsl:apply-templates select="$group-2-aliases" mode="build-paired-1gram">
            <xsl:with-param name="aliases-to-merge" tunnel="yes" as="document-node()" select="$group-1-aliases"/>
            <xsl:with-param name="aura" tunnel="yes" select="$aura"/>
            <xsl:with-param name="drop-most-frequent" tunnel="yes" select="$drop-most-frequent"/>
            <xsl:with-param name="drop-must-be-frequent-in-both" tunnel="yes" select="$drop-must-be-frequent-in-both"/>
        </xsl:apply-templates>
    </xsl:function>
    
    
    <xsl:mode name="build-paired-1gram" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*" mode="build-paired-1gram">
        <!-- group 1 = context element; group 2 = aliases to merge -->
        <!-- The structure of the resultant document is:-->
        <!--
        <ngrams>
            <ngram>
                <gram r="key">
                    <text xml:base="base">
                        <alias-tok-frequency count="" per-median="" per-average="" per-total=""/>
                        <tok>
                            <a></a>
                            <a></a>
                            <!-\- aura points as needed; it can change from one Ngram to the next -\->
                            <resp method="" source="" cert="" cert2=""/>tokvalue
                        </tok>
                    </text>
                    <!-\- Repeat <text>, but for group 2's text -\->
                </gram>
            </ngram>
        </ngrams>-->
        <xsl:param name="aliases-to-merge" tunnel="yes" as="document-node()"/>
        <xsl:param name="drop-most-frequent" tunnel="yes" select="$cut-most-frequent-aliases-per-ngram" as="xs:decimal?"/>
        <xsl:param name="drop-must-be-frequent-in-both" tunnel="yes" select="$cut-frequent-aliases-only-if-frequent-in-both-texts" as="xs:boolean?"/>
        
        <xsl:variable name="current-lang" as="xs:string" select="@xml:lang"/>
        
        <xsl:variable name="alias-values-to-skip" as="xs:string*" select="
                if ($apply-skip-token-alias-map) then
                    ($skip-token-alias-map('*'), $skip-token-alias-map($current-lang))
                else
                    ()"/>
        
        <xsl:variable name="g1-alias-count" select="count($aliases-to-merge/*/tan:alias)" as="xs:integer"/>
        <xsl:variable name="g1-floor" select="$drop-most-frequent * $g1-alias-count" as="xs:decimal"/>
        <xsl:variable name="g1-frequent-aliases-to-ignore" as="element()*"
            select="$aliases-to-merge/*/tan:alias[position() le $g1-floor]"/>
        
        <xsl:variable name="g2-alias-count" select="count(tan:alias)" as="xs:integer"/>
        <xsl:variable name="g2-floor" select="$drop-most-frequent * $g2-alias-count" as="xs:decimal"/>
        <xsl:variable name="g2-frequent-aliases-to-ignore" as="element()*"
            select="tan:alias[position() le $g2-floor]"/>
        
        <xsl:variable name="common-frequent-rs" as="attribute()*"
            select="tan:duplicate-items(($g1-frequent-aliases-to-ignore/@r, $g2-frequent-aliases-to-ignore/@r))"/>
        <xsl:variable name="frequent-aliases-excepted" select="
                if ($drop-must-be-frequent-in-both) then
                    ($g1-frequent-aliases-to-ignore | $g2-frequent-aliases-to-ignore)[not(@r = $common-frequent-rs)]
                else
                    ()"
        />
        <xsl:variable name="frequent-g1-aliases-to-drop" as="element()*"
            select="$g1-frequent-aliases-to-ignore except $frequent-aliases-excepted"/>
        <xsl:variable name="frequent-g2-aliases-to-drop" as="element()*"
            select="$g2-frequent-aliases-to-ignore except $frequent-aliases-excepted"/>
        
        <xsl:variable name="other-g1-aliases-to-drop" as="element()*"
            select="($aliases-to-merge/*/tan:alias except $frequent-g1-aliases-to-drop)[@r = $alias-values-to-skip]"
        />
        <xsl:variable name="other-g2-aliases-to-drop" as="element()*"
            select="(tan:alias except $frequent-g2-aliases-to-drop)[@r = $alias-values-to-skip]"
        />
        
        
        <xsl:if test="exists($frequent-g1-aliases-to-drop)">
            <xsl:message select="tan:cfn($aliases-to-merge/*/@xml:base) || ' (group 1): in building 1gram, cutting the following most frequent token aliases (' || string(count($frequent-g1-aliases-to-drop)) || '): ' || string-join($frequent-g1-aliases-to-drop/@r, ', ')"/>
        </xsl:if>
        <xsl:if test="exists($frequent-g2-aliases-to-drop)">
            <xsl:message select="tan:cfn(@xml:base) || ' (group 2): in building 1gram, cutting the following most frequent token aliases (' || string(count($frequent-g2-aliases-to-drop)) || '): ' || string-join($frequent-g2-aliases-to-drop/@r, ', ')"/>
        </xsl:if>
        <xsl:if test="exists($other-g1-aliases-to-drop)">
            <xsl:message select="tan:cfn($aliases-to-merge/*/@xml:base) || ' (group 1): in building 1gram, skipping these token aliases (' || string(count($other-g1-aliases-to-drop)) || '): ' || string-join($other-g1-aliases-to-drop/@r, ', ')"/>
        </xsl:if>
        <xsl:if test="exists($other-g2-aliases-to-drop)">
            <xsl:message select="tan:cfn($aliases-to-merge/*/@xml:base) || ' (group 2): in building 1gram, skipping these token aliases (' || string(count($other-g2-aliases-to-drop)) || '): ' || string-join($other-g2-aliases-to-drop/@r, ', ')"/>
        </xsl:if>
        
        <ngrams n="1" base1="{$aliases-to-merge/*/@xml:base}" base2="{@xml:base}" src1="{$aliases-to-merge/*/@src}" src2="{@src}">
            <xsl:copy-of select="@xml:lang"/>
            <xsl:for-each-group select="
                    ($aliases-to-merge/*/tan:alias except ($frequent-g1-aliases-to-drop, $other-g1-aliases-to-drop)),
                    (tan:alias except ($frequent-g2-aliases-to-drop, $other-g2-aliases-to-drop))"
                group-by="@r">
                <!-- ignore any aliases that are attested in only one source -->
                <xsl:if test="count(current-group()) gt 1">
                    <ngram>
                        <gram r="{current-grouping-key()}">
                            <xsl:apply-templates select="current-group()" mode="#current"/>
                        </gram>
                    </ngram>
                </xsl:if>
            </xsl:for-each-group>
            
        </ngrams>
        
    </xsl:template>
    
    <xsl:template match="tan:alias" mode="build-paired-1gram">
        <text>
            <xsl:copy-of select="ancestor::*/@xml:base"/>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </text>
    </xsl:template>
    
    <xsl:template match="tan:tok" mode="build-paired-1gram">
        <xsl:param name="aura" tunnel="yes" as="xs:integer?" select="$ngram-auras-norm[1]"/>
        <xsl:variable name="this-seq" select="xs:integer(@n)"/>
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:for-each
                select="($this-seq - $aura) to ($this-seq + $aura)">
                <!-- you might think this works... ($this-seq - $aura) to ($this-seq - 1), ($this-seq + 1) to ($this-seq + $aura)
                    ... but this means that adjacent tokens with an aura of 1 will always miss each other. -->
                <a>
                    <!-- a for aura -->
                    <xsl:value-of select="."/>
                </a>
            </xsl:for-each>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
        
    </xsl:template>
    
    
    <xsl:variable name="all-1gram-maps" as="map(*)*">
        <xsl:for-each select="$token-alias-maps-g1">
            <xsl:variable name="g1-alias-map" select="." as="map(*)"/>
            <xsl:variable name="g1-lang" select="$g1-alias-map('xml:lang')"/>
            <xsl:variable name="corresponding-g2-alias-maps" as="map(*)*"
                select="$token-alias-maps-g2[map:get(., 'xml:lang') eq $g1-lang]"/>
            <xsl:if test="not(exists($corresponding-g2-alias-maps))">
                <xsl:message select="'Group 1 file ' || $g1-alias-map('xml:base') || ' has language ' || $g1-lang || ' but there are no texts of that language in group 2.'"/>
            </xsl:if>
            <xsl:sequence select="
                    for $i in $corresponding-g2-alias-maps
                    return
                        tan:build-paired-1gram-map($g1-alias-map, $i, $head-chop-norm[1], $cut-frequent-aliases-only-if-frequent-in-both-texts)"
            />
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="all-1grams" as="document-node()*">
        <!-- This builds the seed paired 1grams that will populate 2grams, 3grams, etc. -->
        <!-- Paired 1grams are relatively quick to make, because they simply put into an
            Ngram structure only those consolidated aliases that appear in both texts. The
            time is linear, but subsuquent grams are quadratic. Hence, not much is gained by
            saving 1grams as temporary files.
        -->
        <xsl:for-each select="$tok-aliases-consolidated-g1">
            <xsl:variable name="g1-aliases" select="." as="document-node()"/>
            <xsl:variable name="g1-lang" select="*/@xml:lang"/>
            <xsl:variable name="corresponding-g2-aliases" as="document-node()*"
                select="$tok-aliases-consolidated-g2[*/@xml:lang eq $g1-lang]"/>
            <xsl:if test="not(exists($corresponding-g2-aliases))">
                <xsl:message select="'Group 1 file ' || */@xml:base || ' has language ' || $g1-lang || ' but there are no texts of that language in group 2.'"/>
            </xsl:if>
            <xsl:sequence select="
                    for $i in $corresponding-g2-aliases
                    return
                        tan:build-paired-1gram($g1-aliases, $i, $ngram-auras-norm[1], $head-chop-norm[1], $cut-frequent-aliases-only-if-frequent-in-both-texts)"
            />
        </xsl:for-each>
    </xsl:variable>
    
    
    <!-- At this point we have all the base 1grams, rather large files. As we go from 1grams to 2grams and 
        onward, the result should get progressively smaller. The process involves adding a 1gram to an Ngram.
    -->
    
    <xsl:function name="tan:add-1gram-map" as="map(*)?" visibility="private">
        <!-- Input: an Ngram; a 1gram -->
        <!-- Output: an N+1gram -->
        <xsl:param name="base-ngram-map" as="map(*)?"/>
        <xsl:param name="incoming-1gram-map" as="map(*)?"/>
        <xsl:param name="aura-diameter" as="xs:integer"/>
        
        <xsl:variable name="ngram-distinct-tok-alias-count" as="xs:integer" select="map:size($base-ngram-map)"/>
        <xsl:variable name="src1-id" as="xs:string" select="$base-ngram-map('src1')"/>
        <xsl:variable name="src2-id" as="xs:string" select="$base-ngram-map('src2')"/>
        
        <xsl:variable name="base-ngram-keys" as="xs:string*" select="
                if (exists($base-ngram-map('ngrams'))) then
                    map:keys($base-ngram-map('ngrams'))
                else
                    ()"/>
        <xsl:variable name="base-ngram-count" as="xs:integer" select="count($base-ngram-keys)"/>
        <xsl:variable name="incoming-ngram-keys" as="xs:string*" select="
                if (exists($incoming-1gram-map('ngrams'))) then
                    map:keys($incoming-1gram-map('ngrams'))
                else
                    ()"/>
        
        <xsl:message select="'Adding 1gram with ' || string(map:size($incoming-1gram-map('ngrams'))) || ' distinct alias tokens to ' || 
            string($base-ngram-map('n')) || 'gram with ' || string($ngram-distinct-tok-alias-count) || ' distinct alias tokens for ' || 
            $src1-id || ' and ' || $src2-id || '.'"/>
        
        <xsl:map>
            <xsl:map-entry key="'n'" select="$base-ngram-map('n') + 1"/>
            <xsl:for-each select="('lang', 'src1', 'src2', 'base1', 'base2')">
                <xsl:map-entry key="." select="map:get($base-ngram-map, .)"/>
            </xsl:for-each>
            <xsl:map-entry key="'ngrams'">
                <xsl:map>
                    <xsl:for-each select="$base-ngram-keys">
                        <!--<xsl:sort/>-->
                        <xsl:variable name="this-base-key" as="xs:string" select="."/>
                        <xsl:variable name="base-ngram-texts" as="map(*)+"
                            select="$base-ngram-map('ngrams')($this-base-key)"/>
                        <xsl:variable name="base-ngram-token-aliases" as="xs:string+"
                            select="map:keys($base-ngram-texts[1])"/>
                        <xsl:variable name="existing-text-1-tok-ns" as="xs:integer+" select="
                                for $i in $base-ngram-token-aliases
                                return
                                    map:keys($base-ngram-texts[1]($i))[. instance of xs:integer]"/>
                        <xsl:variable name="existing-text-2-tok-ns" as="xs:integer+" select="
                                for $i in $base-ngram-token-aliases
                                return
                                    map:keys($base-ngram-texts[2]($i))[. instance of xs:integer]"/>
                        <xsl:variable name="text-1-aura-points" as="xs:integer+" select="
                                distinct-values(for $i in $existing-text-1-tok-ns,
                                    $j in (1 to $aura-diameter)
                                return
                                    (($i - $j), ($i + $j)))[not(. = $existing-text-1-tok-ns)]"/>
                        <xsl:variable name="text-2-aura-points" as="xs:integer+" select="
                                distinct-values(for $i in $existing-text-2-tok-ns,
                                    $j in (1 to $aura-diameter)
                                return
                                    (($i - $j), ($i + $j)))[not(. = $existing-text-2-tok-ns)]"/>

                        <xsl:variable name="relevant-incoming-keys" as="xs:string*"
                            select="$incoming-ngram-keys[. lt $this-base-key][not(. = $base-ngram-token-aliases)]"/>
                        
                        <xsl:message select="
                                'At ngram # ' || string(position()) || ' of ' || string($base-ngram-count) || ' with distinct token alias' || (if (count($base-ngram-token-aliases) gt 1) then
                                    'es '
                                else
                                    ' ') || string-join($base-ngram-token-aliases, ', ') || ' checking ' || string(count($relevant-incoming-keys)) ||
                                ' token aliases from incoming 1gram.'"/>


                        <xsl:for-each select="$relevant-incoming-keys">
                            <xsl:variable name="this-inc-key" as="xs:string" select="."/>
                            <xsl:variable name="incoming-ngram-texts" as="map(*)+"
                                select="$incoming-1gram-map('ngrams')($this-inc-key)"/>
                            <xsl:variable name="matching-text-1-tok-ns" as="xs:integer*"
                                select="map:keys($incoming-ngram-texts[1]($this-inc-key))[. instance of xs:integer][. = $text-1-aura-points]"/>
                            <xsl:variable name="matching-text-2-tok-ns" as="xs:integer*"
                                select="map:keys($incoming-ngram-texts[2]($this-inc-key))[. instance of xs:integer][. = $text-2-aura-points]"/>


                            <xsl:if
                                test="exists($matching-text-1-tok-ns) and exists($matching-text-2-tok-ns)">

                                <!-- filter base, to retain only those tokens within the aura of the incoming gram -->
                                <xsl:variable name="incoming-text-1-aura-points" as="xs:integer+"
                                    select="tan:integer-clusters(($existing-text-1-tok-ns, $text-1-aura-points), $matching-text-1-tok-ns)"/>
                                <xsl:variable name="incoming-text-2-aura-points" as="xs:integer+"
                                    select="tan:integer-clusters(($existing-text-2-tok-ns, $text-2-aura-points), $matching-text-2-tok-ns)"/>


                                <xsl:message select="
                                        '✔ ' || $this-inc-key || ' from incoming 1gram falls in the aura of each text in the base ngram.'"/>

                                <xsl:map-entry key="$this-inc-key || ' ' || $this-base-key">
                                    <!-- Text 1 new ngram -->
                                    <xsl:map>
                                        <xsl:map-entry key="$this-inc-key">
                                            <xsl:map>
                                                <xsl:for-each select="$matching-text-1-tok-ns">
                                                  <xsl:map-entry key="."
                                                  select="map:get($incoming-ngram-texts[1]($this-inc-key), .)"
                                                  />
                                                </xsl:for-each>
                                            </xsl:map>
                                        </xsl:map-entry>
                                        <xsl:for-each select="$base-ngram-token-aliases">
                                            <xsl:variable name="this-base-tok-map"
                                                select="map:get($base-ngram-texts[1], .)"/>
                                            <xsl:variable name="these-keys-of-choice"
                                                as="xs:integer+"
                                                select="map:keys($this-base-tok-map)[. instance of xs:integer][. = $incoming-text-1-aura-points]"/>
                                            <xsl:map-entry key=".">
                                                <!--<test03a>
                                                    <keys><xsl:copy-of select="map:keys($this-base-tok-map)"/></keys>
                                                </test03a>-->
                                                <xsl:map>
                                                  <xsl:for-each select="$these-keys-of-choice">
                                                  <xsl:map-entry key="."
                                                  select="map:get($this-base-tok-map, .)"/>
                                                  </xsl:for-each>
                                                </xsl:map>
                                            </xsl:map-entry>
                                        </xsl:for-each>
                                    </xsl:map>
                                    <!-- Text 2 new ngram -->
                                    <xsl:map>
                                        <xsl:map-entry key="$this-inc-key">
                                            <xsl:map>
                                                <xsl:for-each select="$matching-text-2-tok-ns">
                                                  <xsl:map-entry key="."
                                                  select="map:get($incoming-ngram-texts[2]($this-inc-key), .)"
                                                  />
                                                </xsl:for-each>
                                            </xsl:map>
                                        </xsl:map-entry>
                                        <xsl:for-each select="$base-ngram-token-aliases">
                                            <xsl:variable name="this-base-tok-map"
                                                select="map:get($base-ngram-texts[2], .)"/>
                                            <xsl:variable name="these-keys-of-choice"
                                                as="xs:integer+"
                                                select="map:keys($this-base-tok-map)[. instance of xs:integer][. = $incoming-text-2-aura-points]"/>
                                            <xsl:map-entry key=".">
                                                <xsl:map>
                                                  <xsl:for-each select="$these-keys-of-choice">
                                                  <xsl:map-entry key="."
                                                  select="map:get($this-base-tok-map, .)"/>
                                                  </xsl:for-each>
                                                </xsl:map>
                                            </xsl:map-entry>
                                        </xsl:for-each>
                                    </xsl:map>
                                </xsl:map-entry>

                            </xsl:if>

                        </xsl:for-each>


                    </xsl:for-each>
                </xsl:map>
            </xsl:map-entry>
        </xsl:map>
        
    </xsl:function>
    
    <xsl:function name="tan:add-1gram" as="document-node()?" visibility="private">
        <!-- Input: an Ngram; a 1gram -->
        <!-- Output: an N+1gram -->
        <xsl:param name="ngram" as="document-node()?"/>
        <xsl:param name="_1gram" as="document-node()?"/>
        
        <xsl:variable name="ngram-distinct-tok-alias-count" as="xs:integer" select="count($ngram/*/tan:ngram)"/>
        <xsl:message select="'Adding 1gram with ' || string(count($_1gram/*/tan:ngram)) || ' distinct alias tokens (' || 
            string(count($_1gram/*/tan:ngram/tan:gram/tan:text/tan:tok)) ||
            ' total) to ' || $ngram/*/@n || 'gram with ' || string($ngram-distinct-tok-alias-count) || ' distinct alias tokens (' || 
            string(count($ngram/*/tan:ngram/tan:gram/tan:text/tan:tok)) ||
            ' total) for ' || $ngram/*/@src1 || ' and ' || $ngram/*/@src2 || ''"/>
        
        <xsl:apply-templates select="$ngram" mode="add-1gram">
            <xsl:with-param name="_1gram" tunnel="yes" as="document-node()?" select="$_1gram"/>
            <xsl:with-param name="ngram-total" tunnel="yes" select="$ngram-distinct-tok-alias-count"/>
        </xsl:apply-templates>
    </xsl:function>
    
    
    <xsl:mode name="add-1gram" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:ngrams" mode="add-1gram">
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="n" select="xs:integer(@n) + 1"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="src1-id" select="@src1"/>
                <xsl:with-param name="src2-id" select="@src2"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:key name="ngram-by-r" match="tan:ngram" use="tan:gram/@r"/>
    <xsl:key name="gram-by-text-1-tok-aura" match="tan:gram" use="tan:text[1]/tan:tok/tan:a"/>
    <xsl:key name="gram-by-text-2-tok-aura" match="tan:gram" use="tan:text[2]/tan:tok/tan:a"/>
    
    <xsl:template match="tan:ngram" mode="add-1gram">
        <xsl:param name="_1gram" tunnel="yes" as="document-node()"/>
        <xsl:param name="ngram-total" tunnel="yes" as="xs:integer"/>
        
        <xsl:variable name="target-count" select="count(tan:gram) + 1" as="xs:integer"/>
        <xsl:variable name="these-grams" select="tan:gram" as="element()+"/>
        <xsl:variable name="first-r" as="xs:string" select="tan:gram[1]/@r"/>
        <xsl:variable name="these-rs" select="tan:gram/@r" as="xs:string+"/>
        

        <xsl:variable name="text-1-aura-points" as="xs:string+" select="tan:gram/tan:text[1]/tan:tok/tan:a"/>
        <xsl:variable name="text-2-aura-points" as="xs:string+" select="tan:gram/tan:text[2]/tan:tok/tan:a"/>
        

        <xsl:variable name="_1gram-adjusted" as="document-node()">
            <xsl:apply-templates select="$_1gram" mode="drop-toks">
                <xsl:with-param name="text-1-ns-to-drop" tunnel="yes" as="xs:string+" select="tan:gram/tan:text[1]/tan:tok/@n"/>
                <xsl:with-param name="text-2-ns-to-drop" tunnel="yes" as="xs:string+" select="tan:gram/tan:text[2]/tan:tok/@n"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="first-1gram-match" select="key('ngram-by-r', $first-r, $_1gram-adjusted)"
            as="element()?"/>
        
        <!-- To avoid multiple processes that produce the same Ngram, each gram in the Ngram is built starting from the
            end, from the least frequent to the most. Because each added _1gram goes from most frequent aliases to least, 
            we focus only on those aliases that precede the first common @r value, but we make sure to put any new grams
            at the beginning of the new ngram. -->
        <xsl:variable name="_1grams-to-check" as="element()*" select="
                if (exists($first-1gram-match)) then
                    $first-1gram-match/preceding-sibling::tan:ngram
                else 
                    $_1gram-adjusted/tan:ngrams/tan:ngram"/>
        
        <xsl:variable name="_1gram-grams-in-aura" as="element()*" select="
                for $i in $_1grams-to-check,
                    $j in key('gram-by-text-1-tok-aura', $text-1-aura-points, $i)
                return
                    key('gram-by-text-2-tok-aura', $text-2-aura-points, $j)"/>
        
        <xsl:variable name="distinct-t1-aura-points" select="distinct-values($text-1-aura-points)" as="xs:string*"/>
        <xsl:variable name="distinct-t2-aura-points" select="distinct-values($text-2-aura-points)" as="xs:string*"/>
        
        
        <xsl:if test="not(exists($first-1gram-match))">
            <xsl:message select="'Unexpected: there is no match on ' || string-join($these-rs, ', ') || ' in the incoming 1gram; processing will continue'"/>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when test="exists($_1gram-grams-in-aura)">
                <xsl:message select="
                        '✔ At ngram # ' || string(position()) || ' (of ' || string($ngram-total) || ') with distinct token alias' || (if (count($these-rs) gt 1) then
                            'es'
                        else
                            ()) || ' ' || string-join($these-rs, ', ') || ' incoming 1gram has ' || string(count($_1gram-grams-in-aura)) ||
                        ' token aliases ' || string-join($_1gram-grams-in-aura/@r, ', ') || ' in the aura of each text in the base ngram.'"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="
                        '✘ Dropping ngram # ' || string(position()) || ' (of ' || string($ngram-total) || ') with distinct token alias' || (if (count($these-rs) gt 1) then
                            'es'
                        else
                            ()) || ' ' || string-join($these-rs, ', ') || '; no nearby matches from incoming 1gram.'"
                />
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- We apply templates to the matching incoming 1gram grams, because we need to distribute the results, one ngram
            per matching incoming 1gram gram. Because this is expressed as a template, if there are no matching 1gram grams, 
            then the current ngram gets dropped: it does not meet the requirements for the next level of Ngram. -->
        <xsl:apply-templates select="$_1gram-grams-in-aura" mode="merge-1gram-in-aura">
            <xsl:with-param name="ngram-to-infuse" tunnel="yes" as="element()" select="."/>
            <xsl:with-param name="text-1-aura-points" as="xs:string+" select="$distinct-t1-aura-points" tunnel="yes"/>
            <xsl:with-param name="text-2-aura-points" as="xs:string+" select="$distinct-t2-aura-points" tunnel="yes"/>
        </xsl:apply-templates>
        
        
    </xsl:template>
    
    
    <xsl:mode name="drop-toks" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:text[1]/tan:tok" mode="drop-toks">
        <xsl:param name="text-1-ns-to-drop" as="xs:string+" tunnel="yes"/>
        <xsl:if test="not(@n = $text-1-ns-to-drop)">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tan:text[2]/tan:tok" mode="drop-toks">
        <xsl:param name="text-2-ns-to-drop" as="xs:string+" tunnel="yes"/>
        <xsl:if test="not(@n = $text-2-ns-to-drop)">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    
    
    
    
    <xsl:mode name="merge-1gram-in-aura" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:gram" mode="merge-1gram-in-aura">
        <xsl:param name="ngram-to-infuse" tunnel="yes" as="element()"/>
        <xsl:param name="text-1-aura-points" as="xs:string+" tunnel="yes"/>
        <xsl:param name="text-2-aura-points" as="xs:string+" tunnel="yes"/>
        
        <xsl:variable name="matching-text-1-toks" select="tan:text[1]/tan:tok[tan:a = $text-1-aura-points]" as="element()+"/>
        <xsl:variable name="matching-text-2-toks" select="tan:text[2]/tan:tok[tan:a = $text-2-aura-points]" as="element()+"/>
        
        <xsl:variable name="text-1-aura-points" as="xs:integer+" select="
                tan:integer-clusters((for $i in $text-1-aura-points
                return
                    xs:integer($i)), (for $i in $matching-text-1-toks/tan:a
                return
                    xs:integer($i)))"/>
        <xsl:variable name="text-2-aura-points" as="xs:integer+" select="
                tan:integer-clusters((for $i in $text-2-aura-points
                return
                    xs:integer($i)), (for $i in $matching-text-2-toks/tan:a
                return
                    xs:integer($i)))"/>
        
        <xsl:message select="'  ↢ ' || @r || ': adding ' || string(count($matching-text-1-toks)) 
            || ' tokens (of ' || string(count(tan:text[1]/tan:tok)) || ') from text 1 and ' || string(count($matching-text-2-toks)) 
            || ' tokens (of ' || string(count(tan:text[2]/tan:tok)) || ') from text 2.'"/>
        
        <ngram>
            
            <!-- This is a more common gram, so it appears at the beginning of the series -->
            <xsl:copy copy-namespaces="no">
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates select="*" mode="filter-incoming-ngram">
                    <xsl:with-param name="text-1-toks-to-keep" as="element()+" tunnel="yes" select="$matching-text-1-toks"/>
                    <xsl:with-param name="text-2-toks-to-keep" as="element()+" tunnel="yes" select="$matching-text-2-toks"/>
                    <!--<xsl:with-param name="incoming-ts-to-keep" as="element()+" tunnel="yes" select="$matching-text-1-toks | $matching-text-2-toks"/>-->
                </xsl:apply-templates>
            </xsl:copy>
            <xsl:apply-templates select="$ngram-to-infuse/*" mode="filter-merged-ngram">
                <xsl:with-param name="required-text-1-aura-points" tunnel="yes" select="
                        for $i in $text-1-aura-points
                        return
                            string($i)"/>
                <xsl:with-param name="required-text-2-aura-points" tunnel="yes" select="
                        for $i in $text-2-aura-points
                        return
                            string($i)"/>
            </xsl:apply-templates>
        </ngram>
        
    </xsl:template>
    
    <xsl:mode name="filter-merged-ngram" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:text[1]" mode="filter-merged-ngram">
        <xsl:param name="required-text-1-aura-points" tunnel="yes" as="xs:string+"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="tan:alias-tok-frequency"/>
            <xsl:copy-of select="tan:tok[tan:a = $required-text-1-aura-points]"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:text[2]" mode="filter-merged-ngram">
        <xsl:param name="required-text-2-aura-points" tunnel="yes" as="xs:string+"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="tan:alias-tok-frequency"/>
            <xsl:copy-of select="tan:tok[tan:a = $required-text-2-aura-points]"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:mode name="filter-incoming-ngram" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:text[1]" mode="filter-incoming-ngram">
        <xsl:param name="text-1-toks-to-keep" as="element()+" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node() except tan:tok"/>
            <xsl:copy-of select="tan:tok intersect $text-1-toks-to-keep"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:text[2]" mode="filter-incoming-ngram">
        <xsl:param name="text-2-toks-to-keep" as="element()+" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node() except tan:tok"/>
            <xsl:copy-of select="tan:tok intersect $text-2-toks-to-keep"/>
        </xsl:copy>
    </xsl:template>
    
    
    
    
    <xsl:variable name="all-cumulative-ngram-maps" as="map(*)*">
        <xsl:choose>
            <xsl:when test="$target-ngram-n-norm lt 2">
                <xsl:sequence select="$all-1gram-maps"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$all-1gram-maps" mode="build-target-ngram"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="all-cumulative-ngrams" as="document-node()*">
        <xsl:choose>
            <xsl:when test="$target-ngram-n-norm lt 2">
                <xsl:sequence select="$all-1grams"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$all-1grams" mode="build-target-ngram"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:mode name="build-target-ngram" on-no-match="shallow-copy"/>
    
    <xsl:template match=".[. instance of map(*)]" mode="build-target-ngram">
        <xsl:param name="text-1-base" as="xs:string" select="map:get(., 'base1')"/>
        <xsl:param name="text-2-base" as="xs:string" select="map:get(., 'base2')"/>
        
        <xsl:variable name="context-map" as="map(*)" select="."/>
        <xsl:variable name="context-lang" as="xs:string" select="map:get(., 'lang')"/>
        <xsl:variable name="consolidated-tok-aliases-text-1" as="map(*)" select="$token-alias-maps-g1[.('xml:base') eq $text-1-base]"/>
        <xsl:variable name="consolidated-tok-aliases-text-2" as="map(*)" select="$token-alias-maps-g2[.('xml:base') eq $text-2-base]"/>
        
        <xsl:iterate select="2 to $target-ngram-n-norm">
            <xsl:param name="results-so-far" as="map(*)?" select="$context-map"/>
            
            <xsl:variable name="this-n" select="." as="xs:integer"/>
            
            <xsl:variable name="manifest" as="element()?">
                <xsl:if test="$tan:save-and-use-intermediate-steps">
                    <xsl:message select="'Building ' || string(.) || 'gram manifest'"/>
                    <manifest>
                        <n><xsl:value-of select="$this-n"/></n>
                        <t1base><xsl:value-of select="$text-1-base"/></t1base>
                        <t2base><xsl:value-of select="$text-2-base"/></t2base>
                        <previous-step>
                            <xsl:value-of select="
                                    if ($verify-intermediate-steps-strictly) then
                                        (tan:checksum-fletcher-32(tan:map-to-xml(tan:drop-manifest($results-so-far), true())))
                                    else
                                        ('length ' || string-length(tan:map-to-xml(tan:drop-manifest($results-so-far), true())))"
                            />
                        </previous-step>
                        <aura><xsl:value-of select="$ngram-aura-diameters-norm[$this-n]"/></aura>
                        <chop><xsl:value-of select="$head-chop-norm[$this-n]"/></chop>
                        <xsl:if test="$apply-skip-token-alias-map">
                            <skip-aliases>
                                <xsl:value-of select="sort($skip-token-alias-map('*'))"/>
                                <xsl:value-of select="sort($skip-token-alias-map($context-lang))"/>
                            </skip-aliases>
                        </xsl:if>
                        <cut-only-common><xsl:value-of select="$cut-frequent-aliases-only-if-frequent-in-both-texts"/></cut-only-common>
                        <consolidated-tok-aliases-text-1>
                            <xsl:value-of select="
                                    if ($verify-intermediate-steps-strictly) then
                                        (tan:checksum-fletcher-32(tan:map-to-xml(tan:drop-manifest($consolidated-tok-aliases-text-1), true())))
                                    else
                                        ('length ' || string-length(tan:map-to-xml(tan:drop-manifest($consolidated-tok-aliases-text-1), true())))"
                            />
                        </consolidated-tok-aliases-text-1>
                        <consolidated-tok-aliases-text-2>
                            <xsl:value-of select="
                                    if ($verify-intermediate-steps-strictly) then
                                        (tan:checksum-fletcher-32(tan:map-to-xml(tan:drop-manifest($consolidated-tok-aliases-text-2), true())))
                                    else
                                        ('length ' || string-length(tan:map-to-xml(tan:drop-manifest($consolidated-tok-aliases-text-2), true())))"
                            />
                        </consolidated-tok-aliases-text-2>
                    </manifest>
                </xsl:if>
            </xsl:variable>
            <xsl:if test="$tan:save-and-use-intermediate-steps">
                <xsl:message select="'Building ' || string(.) || 'gram checksum'"/>
            </xsl:if>
            <xsl:variable name="this-manifest-checksum" select="
                    if (exists($manifest)) then
                        tan:checksum-fletcher-32(string($manifest))
                    else
                        ()" as="xs:string?"/>
            <xsl:variable name="expected-temp-file-location" as="xs:anyURI?" select="
                    if (exists($manifest)) then
                        resolve-uri($this-manifest-checksum || '-result.xml', $temporary-file-directory-norm)
                    else
                        ()"/>
            <xsl:variable name="manifest-stamped" as="element()?"
                select="tan:stamp-manifest($manifest, $this-manifest-checksum)"/>
            
            <xsl:variable name="new-results" as="map(*)">
                <xsl:choose>
                    <xsl:when test="exists($manifest) and doc-available($expected-temp-file-location)">
                        <xsl:message select="'Building ' || string($this-n) || 'gram map for ' || 
                            tan:cfn($text-1-base) || ' and ' || tan:cfn($text-2-base) || ': fetching intermediate file from ' || 
                            $expected-temp-file-location"/>
                        <xsl:sequence select="map:remove(tan:xml-to-map(doc($expected-temp-file-location)), 'manifest')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$tan:save-and-use-intermediate-steps">
                            <xsl:message select="'Building ' || string($this-n) || 'gram map for ' || 
                                tan:cfn($text-1-base) || ' and ' || tan:cfn($text-2-base) || ': no intermediate file found at ' || 
                                $expected-temp-file-location || '. Building afresh.'"/>
                            
                        </xsl:if>
                        <xsl:variable name="new-1gram" as="map(*)"
                            select="tan:build-paired-1gram-map($consolidated-tok-aliases-text-1, $consolidated-tok-aliases-text-2, 
                            $head-chop-norm[$this-n], 
                            $cut-frequent-aliases-only-if-frequent-in-both-texts)"
                        />
                        <xsl:variable name="new-plus-gram" as="map(*)"
                            select="tan:add-1gram-map($results-so-far, $new-1gram, $ngram-aura-diameters-norm[$this-n])"/>
                        
                        <xsl:sequence
                            select="map:put($new-plus-gram, 'manifest', $manifest-stamped)"/>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:sequence select="$new-results"/>
            
            <xsl:next-iteration>
                <xsl:with-param name="results-so-far" select="$new-results"/>
            </xsl:next-iteration>
        </xsl:iterate>
        
    </xsl:template>
    
    <xsl:template match="/" mode="build-target-ngram">
        <xsl:param name="text-1-base" as="xs:string" select="*/@base1"/>
        <xsl:param name="text-2-base" as="xs:string" select="*/@base2"/>
        
        <xsl:variable name="context-lang" as="xs:string" select="*/@xml:lang"/>
        <xsl:variable name="consolidated-tok-aliases-text-1" as="document-node()" select="$tok-aliases-consolidated-g1[*/@xml:base eq $text-1-base]"/>
        <xsl:variable name="consolidated-tok-aliases-text-2" as="document-node()" select="$tok-aliases-consolidated-g2[*/@xml:base eq $text-2-base]"/>

        <xsl:iterate select="2 to $target-ngram-n-norm">
            <xsl:param name="results-so-far" as="document-node()?" select="root(.)"/>
            
            <xsl:variable name="this-n" select="." as="xs:integer"/>
            
            <xsl:variable name="manifest" as="element()?">
                <xsl:if test="$tan:save-and-use-intermediate-steps">
                    <xsl:message select="'Building ' || string(.) || 'gram manifest'"/>
                    <manifest>
                        <n><xsl:value-of select="$this-n"/></n>
                        <t1base><xsl:value-of select="$text-1-base"/></t1base>
                        <t2base><xsl:value-of select="$text-2-base"/></t2base>
                        <previous-step>
                            <xsl:value-of select="
                                    if ($verify-intermediate-steps-strictly) then
                                        (tan:checksum-fletcher-32(serialize(tan:drop-manifest($results-so-far))))
                                    else
                                        ('length ' || string-length(serialize(tan:drop-manifest($results-so-far))))"
                            />
                        </previous-step>
                        <aura><xsl:value-of select="$ngram-auras-norm[$this-n]"/></aura>
                        <chop><xsl:value-of select="$head-chop-norm[$this-n]"/></chop>
                        <xsl:if test="$apply-skip-token-alias-map">
                            <skip-aliases>
                                <xsl:value-of select="sort($skip-token-alias-map('*'))"/>
                                <xsl:value-of select="sort($skip-token-alias-map($context-lang))"/>
                            </skip-aliases>
                        </xsl:if>
                        <cut-only-common><xsl:value-of select="$cut-frequent-aliases-only-if-frequent-in-both-texts"/></cut-only-common>
                        <consolidated-tok-aliases-text-1>
                            <xsl:value-of select="
                                    if ($verify-intermediate-steps-strictly) then
                                        (tan:checksum-fletcher-32(serialize(tan:drop-manifest($consolidated-tok-aliases-text-1))))
                                    else
                                        ('length ' || string-length(serialize(tan:drop-manifest($consolidated-tok-aliases-text-1))))"
                            />
                        </consolidated-tok-aliases-text-1>
                        <consolidated-tok-aliases-text-2>
                            <xsl:value-of select="
                                    if ($verify-intermediate-steps-strictly) then
                                        (tan:checksum-fletcher-32(serialize(tan:drop-manifest($consolidated-tok-aliases-text-2))))
                                    else
                                        ('length ' || string-length(serialize(tan:drop-manifest($consolidated-tok-aliases-text-2))))"
                            />
                        </consolidated-tok-aliases-text-2>
                    </manifest>
                </xsl:if>
            </xsl:variable>
            
            <xsl:if test="$tan:save-and-use-intermediate-steps">
                <xsl:message select="'Building ' || string(.) || 'gram checksum'"/>
            </xsl:if>
            <xsl:variable name="this-manifest-checksum" select="
                    if (exists($manifest)) then
                        tan:checksum-fletcher-32(string($manifest))
                    else
                        ()" as="xs:string?"/>
            <xsl:variable name="expected-temp-file-location" as="xs:anyURI?" select="
                    if (exists($manifest)) then
                        resolve-uri($this-manifest-checksum || '-result.xml', $temporary-file-directory-norm)
                    else
                        ()"/>
            <xsl:variable name="manifest-stamped" as="element()?"
                select="tan:stamp-manifest($manifest, $this-manifest-checksum)"/>
            
            <xsl:variable name="new-results" as="document-node()">
                <xsl:choose>
                    <xsl:when test="exists($manifest) and doc-available($expected-temp-file-location)">
                        <xsl:message select="'Building ' || string($this-n) || 'gram for ' || 
                            tan:cfn($text-1-base) || ' and ' || tan:cfn($text-2-base) || ': fetching intermediate file from ' || 
                            $expected-temp-file-location"/>
                        <xsl:sequence select="doc($expected-temp-file-location)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$tan:save-and-use-intermediate-steps">
                            <xsl:message select="'Building ' || string($this-n) || 'gram for ' || 
                                tan:cfn($text-1-base) || ' and ' || tan:cfn($text-2-base) || ': no intermediate file found at ' || 
                                $expected-temp-file-location || '. Building afresh.'"/>
                            
                        </xsl:if>
                        <xsl:variable name="new-1gram" as="document-node()"
                            select="tan:build-paired-1gram($consolidated-tok-aliases-text-1, $consolidated-tok-aliases-text-2, 
                            $ngram-auras-norm[$this-n], $head-chop-norm[$this-n], 
                            $cut-frequent-aliases-only-if-frequent-in-both-texts)"
                        />
                        <xsl:variable name="new-plus-gram" as="document-node()"
                            select="tan:add-1gram($results-so-far, $new-1gram)"/>
                        
                        <xsl:sequence
                            select="tan:insert-manifest($new-plus-gram, $manifest-stamped)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:sequence select="$new-results"/>
            
            <xsl:next-iteration>
                <xsl:with-param name="results-so-far" select="$new-results"/>
            </xsl:next-iteration>
        </xsl:iterate>
    </xsl:template>
    
    
    
    <xsl:variable name="all-target-ngram-maps" as="map(*)*"
        select="$all-cumulative-ngram-maps[.('n') eq $target-ngram-n-norm]"/>
    
    <xsl:variable name="all-target-ngrams" as="document-node()*"
        select="$all-cumulative-ngrams[*[@n eq string($target-ngram-n-norm)]]"/>
    
    
    
    
    <!-- SIMPLIFYING, CONSOLIDATING THE TARGET NGRAMS -->
    
    <!-- Some ngrams will be within each others' auras, and can be grouped into clusters -->
    
    <xsl:variable name="common-output-pass-1-maps" as="map(*)*">
        <xsl:apply-templates select="$all-target-ngram-maps"
            mode="group-and-sort-ngrams-by-group-1-text-clusters"/>
    </xsl:variable>
    
    <xsl:variable name="common-output-pass-1" as="document-node()*">
        <xsl:apply-templates select="$all-target-ngrams" mode="group-and-sort-ngrams-by-group-1-text-clusters"/>
    </xsl:variable>
    
    <xsl:mode name="group-and-sort-ngrams-by-group-1-text-clusters" on-no-match="shallow-copy"/>
    
    <xsl:template match=".[. instance of map(*)]" mode="group-and-sort-ngrams-by-group-1-text-clusters">
        <xsl:variable name="context-map" as="map(*)" select="."/>
        <xsl:variable name="ngrams" select="map:get(., 'ngrams')" as="map(*)?"/>
        <xsl:variable name="base1" as="xs:string" select="map:get(., 'base1')"/>
        <xsl:variable name="base2" as="xs:string" select="map:get(., 'base2')"/>
        <xsl:variable name="tok-maps-g1" as="map(*)+" select="$input-tokenization-map($base1)"/>
        <xsl:variable name="tok-maps-g2" as="map(*)+" select="$input-tokenization-map($base2)"/>
        <xsl:variable name="ngram-keys" as="xs:string*" select="
                if (map:size($ngrams) gt 0) then
                    map:keys($ngrams)
                else
                    ()"/>
        <xsl:variable name="all-g1-maps" as="map(*)*" select="
                for $i in $ngram-keys
                return
                    $ngrams($i)[1]"/>
        <xsl:variable name="g1-tok-ns" as="xs:integer*" select="
                for $i in $all-g1-maps[map:size(.) gt 0],
                    $j in map:keys($i)
                return
                    map:keys($i($j)[map:size(.) gt 0])[. instance of xs:integer]"/>
        <xsl:variable name="g1-tok-auras" as="xs:integer*" select="
                for $i in $g1-tok-ns,
                    $j in (1 to $ngram-aura-diameters-norm[1])
                return
                    (($i + $j), ($i - $j))"/>
        <xsl:variable name="g1-aura-groups" as="array(xs:integer+)?" select="tan:integer-groups(($g1-tok-ns, $g1-tok-auras))"/>
        
        <xsl:variable name="token-alias-map-1" as="map(*)"
            select="$token-alias-maps-g1[map:get(., 'xml:base') eq $base1]"/>
        <xsl:variable name="token-alias-map-2" as="map(*)"
            select="$token-alias-maps-g2[map:get(., 'xml:base') eq $base2]"/>
        
        <xsl:map>
            <xsl:map-entry key="'diagnostics'">
                <!--<xsl:for-each select="$ngram-keys">
                    <xsl:message select="'iteration, ngram key, group 1 keys: ', position(), tan:map-keys($ngrams(current())[1])"/>
                </xsl:for-each>-->
                <ngram-keys><xsl:copy-of select="$ngram-keys"/></ngram-keys>
                <g1-tok-ns><xsl:copy-of select="$g1-tok-ns"/></g1-tok-ns>
                <g1-aura-groups>
                    <!--<xsl:message select="array:flatten($g1-aura-groups)"/>-->
                    <xsl:for-each select="1 to array:size($g1-aura-groups)">
                        <group><xsl:copy-of select="$g1-aura-groups(current())"/></group>
                    </xsl:for-each>
                </g1-aura-groups>
            </xsl:map-entry>
            
            <xsl:for-each select="('lang', 'src1', 'src2', 'base1', 'base2')">
                <xsl:map-entry key="." select="map:get($context-map, .)"/>
            </xsl:for-each>

            <xsl:map-entry key="'clusters'">
                <xsl:map>
                    <xsl:for-each select="1 to array:size($g1-aura-groups)">
                        <xsl:variable name="this-g1-tok-sequence" as="xs:integer+" select="$g1-aura-groups(current())"/>
                        <xsl:variable name="relevant-g1-maps" as="map(*)*" select="
                                for $i in $ngram-keys
                                return
                                    $ngrams($i)[1][tan:map-contains(., $this-g1-tok-sequence)]
                                "/>
                        <!--<xsl:variable name="relevant-g1-maps" as="map(*)+" select="
                                for $i in $ngram-keys,
                                    $j in $ngrams($i)[1],
                                    $k in map:keys($j),
                                    $l in $j($k)
                                return
                                    $l[some $i in $this-g1-tok-sequence
                                        satisfies map:contains(., $i)]
                                "/>-->
                        <xsl:variable name="relevant-g2-maps" as="map(*)*" select="
                                for $i in $ngram-keys
                                return
                                    (if (tan:map-contains($ngrams($i)[1], $this-g1-tok-sequence)) then
                                        $ngrams($i)[2]
                                    else
                                        ())"/>
                        <!--<xsl:message select="'iteration', ."/>
                        <xsl:message select="'g1 tok sequence', $this-g1-tok-sequence"/>
                        <xsl:message select="'Relevant g1 map keys ', tan:map-keys($relevant-g1-maps)"/>
                        <xsl:message select="'Relevant g2 map keys ', tan:map-keys($relevant-g2-maps)"/>-->
                        <!--<xsl:variable name="relevant-g2-maps" as="map(*)+" select="
                                for $i in $ngram-keys
                                return
                                    if (map:for-each($ngrams($i)[1], function ($k, $v) {
                                        map:keys($v)
                                    }) = $this-g1-tok-sequence) then
                                        $ngrams($i)[2]
                                    else
                                        ()"/>-->
                        <xsl:variable name="g2-tok-ns" as="xs:integer*" select="
                                for $i in $relevant-g2-maps[map:size(.) gt 0],
                                    $j in map:keys($i)
                                return
                                    map:keys($i($j)[map:size(.) gt 0])[. instance of xs:integer]"
                        />
                        <xsl:variable name="g2-tok-auras" as="xs:integer*" select="
                                for $i in $g2-tok-ns,
                                    $j in (1 to $ngram-aura-diameters-norm[1])
                                return
                                    (($i + $j), ($i - $j))"/>
                        <xsl:variable name="g2-aura-groups" as="array(xs:integer+)*" select="tan:integer-groups(($g2-tok-ns, $g2-tok-auras))"/>
                        
                        <!-- cluster number -->
                        <xsl:map-entry key=".">
                            <xsl:map>
                                <xsl:map-entry key="'type'" select="'cluster'"/>
                                <xsl:map-entry key="'diagnostics'">
                                    <g2-tok-ns><xsl:copy-of select="$g2-tok-ns"/></g2-tok-ns>
                                    <g2-aura-groups>
                                        <xsl:for-each select="1 to array:size($g2-aura-groups)">
                                            <group><xsl:copy-of select="$g2-aura-groups(current())"/></group>
                                        </xsl:for-each>
                                    </g2-aura-groups>
                                </xsl:map-entry>
                                <xsl:for-each select="$this-g1-tok-sequence">
                                    <!-- one map entry per text 1 token -->
                                    <xsl:variable name="this-tok-no" as="xs:integer" select="."/>
                                    <xsl:variable name="these-g1-token-aliases" as="xs:string*" select="
                                            for $i in $all-g1-maps,
                                                $j in map:keys($i)
                                            return
                                                if (exists($i($j)($this-tok-no))) then
                                                    $j
                                                else
                                                    ()"/>
                                    <xsl:variable name="these-g1-token-alias-statistics"
                                        as="map(*)*" select="
                                            for $i in $these-g1-token-aliases
                                            return
                                                $token-alias-map-1('stats')($i)"
                                    />
                                    
                                    <!-- text 1 tok number -->
                                    <xsl:map-entry key=".">
                                        <xsl:if test="not(exists($these-g1-token-aliases))">
                                            <xsl:sequence select="string($tok-maps-g1[1]($this-tok-no)/self::tan:tok/text())"/>
                                        </xsl:if>
                                        <xsl:for-each select="distinct-values($these-g1-token-aliases)">
                                            <xsl:variable name="this-token-alias" select="."/>
                                            <xsl:variable name="this-tok-entry-map" as="map(*)*"
                                                select="
                                                    for $i in $relevant-g1-maps,
                                                        $j in $i($this-token-alias)
                                                    return
                                                        $j($this-tok-no)"
                                            />
                                            <xsl:variable name="other-token-nos" as="xs:integer*"
                                                select="
                                                    for $i in $relevant-g2-maps,
                                                        $j in $i($this-token-alias)
                                                    return
                                                        map:keys($j)[. = $g2-tok-ns]"
                                            />
                                            <xsl:variable name="this-token-alias-map" as="map(*)" select="$token-alias-map-1('stats')($this-token-alias)"/>
                                            <!--<xsl:if test="exists($this-tok-entry-map[2])">
                                                <xsl:message select="count($this-tok-entry-map), ' token entries found'"/>
                                                <xsl:message select="tan:map-to-xml($this-tok-entry-map)"/>
                                            </xsl:if>-->
                                            <xsl:map>
                                                <xsl:map-entry key="'r'" select="$this-token-alias"/>
                                                <xsl:map-entry key="'counterpart-ns'"
                                                  select="distinct-values($other-token-nos)"/>
                                                <xsl:sequence
                                                  select="tan:map-entries($this-token-alias-map)"/>
                                                <xsl:sequence
                                                  select="tan:map-entries($this-tok-entry-map[1])"/>
                                            </xsl:map>
                                        </xsl:for-each>
                                    </xsl:map-entry>
                                </xsl:for-each>
                                <xsl:for-each select="1 to array:size($g2-aura-groups)">
                                    <xsl:variable name="this-g2-tok-sequence" as="xs:integer+" select="$g2-aura-groups(current())"/>
                                    <!-- one map entry per corresponding group 2 text cluster, with keys enumerated 'g2-1', 'g2-2', etc. -->
                                    <xsl:map-entry key="'g2-' || string(.)">
                                        <xsl:map>
                                            <xsl:for-each select="$this-g2-tok-sequence">
                                                <!-- one map entry per text 2 token -->
                                                <xsl:variable name="this-tok-no" as="xs:integer"
                                                  select="."/>
                                                <xsl:variable name="these-g2-token-aliases"
                                                  as="xs:string*" select="
                                                        for $i in $relevant-g2-maps,
                                                            $j in map:keys($i)
                                                        return
                                                            if (exists($i($j)($this-tok-no))) then
                                                                $j
                                                            else
                                                                ()"/>
                                                
                                                <xsl:variable name="these-g2-token-alias-statistics"
                                                  as="map(*)*" select="
                                                        for $i in $these-g2-token-aliases
                                                        return
                                                            $token-alias-map-2('stats')($i)"
                                                />
                                                
                                                <!-- text 2 tok number -->
                                                <xsl:map-entry key=".">
                                                    <xsl:if test="not(exists($these-g2-token-aliases))">
                                                        <xsl:sequence select="string($tok-maps-g2[1]($this-tok-no)/self::tan:tok/text())"/>
                                                    </xsl:if>
                                                  <xsl:for-each select="$these-g2-token-aliases">
                                                  <xsl:variable name="this-token-alias" select="."/>
                                                  <xsl:variable name="this-tok-entry-map"
                                                  as="map(*)*" select="
                                                                for $i in $relevant-g2-maps,
                                                                    $j in $i($this-token-alias)
                                                                return
                                                                    $j($this-tok-no)"/>
                                                  <xsl:variable name="other-token-nos"
                                                  as="xs:integer*" select="
                                                                for $i in $relevant-g1-maps,
                                                                    $j in $i($this-token-alias)
                                                                return
                                                                    map:keys($j)[. = $this-g1-tok-sequence]"/>
                                                  <xsl:variable name="this-token-alias-map"
                                                  as="map(*)"
                                                  select="$token-alias-map-2('stats')($this-token-alias)"/>
                                                  <!--<xsl:if test="exists($this-tok-entry-map[2])">
                                                  <xsl:message
                                                  select="count($this-tok-entry-map), ' token entries found'"/>
                                                  <xsl:message
                                                  select="tan:map-to-xml($this-tok-entry-map)"/>
                                                  </xsl:if>-->
                                                  <xsl:map>
                                                  <xsl:map-entry key="'r'"
                                                  select="$this-token-alias"/>
                                                  <xsl:map-entry key="'counterpart-ns'"
                                                  select="distinct-values($other-token-nos)"/>
                                                  <xsl:sequence
                                                  select="tan:map-entries($this-token-alias-map)"/>
                                                  <xsl:sequence
                                                  select="tan:map-entries($this-tok-entry-map[1])"/>
                                                  </xsl:map>
                                                  </xsl:for-each>
                                                </xsl:map-entry>

                                            </xsl:for-each>
                                        </xsl:map>
                                    </xsl:map-entry>
                                </xsl:for-each>
                            </xsl:map>
                            
                        </xsl:map-entry>
                    </xsl:for-each>
                </xsl:map>
            </xsl:map-entry>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match="/tan:ngrams" mode="group-and-sort-ngrams-by-group-1-text-clusters">
        <xsl:variable name="context-ngrams" as="element()*" select="tan:ngram"/>
        <xsl:variable name="g1-tok-groups" as="element()*"
            select="tan:group-elements-by-shared-node-values($context-ngrams/tan:gram/tan:text[1]/tan:tok, '^a$')"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on template mode group-and-sort-ngrams-by-group-1-text-clusters'"/>
            <xsl:message select="'Group 1 token groups: ', $g1-tok-groups"/>
        </xsl:if>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="$g1-tok-groups">
                <xsl:sort select="xs:integer(tan:tok[1]/tan:a[1])"/>
                <xsl:variable name="g1-ns" as="xs:string+" select="tan:tok/@n"/>
                <xsl:variable name="ngrams-of-interest-with-g1-toks" as="element()*"
                    select="$context-ngrams[tan:gram/tan:text[1]/tan:tok/@n = $g1-ns]"/>
                <xsl:variable name="g2-tok-groups" as="element()*"
                    select="tan:group-elements-by-shared-node-values($ngrams-of-interest-with-g1-toks/tan:gram/tan:text[2]/tan:tok, '^a$')"/>
                
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'g1 tok ns: ' || string-join($g1-ns, ', ')"/>
                    <xsl:message select="'Group 2 token groups: ', $g2-tok-groups"/>
                </xsl:if>
                <xsl:for-each select="$g2-tok-groups">
                    <xsl:sort select="xs:integer(tan:tok[1]/tan:a[1])"/>
                    
                    <xsl:variable name="g2-ns" as="xs:string+" select="tan:tok/@n"/>
                    <xsl:variable name="ngrams-of-interest-with-g2-toks" as="element()*"
                        select="$ngrams-of-interest-with-g1-toks[tan:gram/tan:text[2]/tan:tok/@n = $g2-ns]"/>
                    
                    <xsl:if test="$diagnostics-on">
                        <xsl:message select="'g2 tok ns: ' || string-join($g2-ns, ', ')"/>
                    </xsl:if>
                    
                    <cluster>
                        <text>
                            <xsl:for-each-group select="$g1-ns" group-by=".">
                                <xsl:sort select="xs:integer(current-grouping-key())"/>
                                
                                <xsl:variable name="this-g1-n" select="current-grouping-key()"
                                    as="xs:string"/>
                                <xsl:variable name="these-g1-toks" as="element()*"
                                    select="$ngrams-of-interest-with-g2-toks/tan:gram/tan:text[1]/tan:tok[@n eq $this-g1-n]"/>
                                <xsl:variable name="corresponding-g2-toks" as="element()*"
                                    select="$these-g1-toks/ancestor::tan:gram/tan:text[2]/tan:tok[@n = $g2-ns]"
                                />
                                
                                <xsl:if test="exists($these-g1-toks)">
                                    <tok>
                                        <xsl:copy-of select="$these-g1-toks[1]/@*"/>
                                        <!-- Rebulid the alias profiles -->
                                        <xsl:for-each select="tan:distinct-items($these-g1-toks/ancestor::tan:gram)">
                                            <alias>
                                                <xsl:copy-of select="@*"/>
                                                <xsl:copy-of
                                                    select="tan:text[1]/tan:alias-tok-frequency"/>
                                                <xsl:copy-of
                                                    select="tan:text[1]/tan:tok[@n eq $this-g1-n]/tan:resp"
                                                />
                                            </alias>
                                        </xsl:for-each>
                                        <xsl:for-each select="distinct-values($corresponding-g2-toks/@n)">
                                            <other-n>
                                                <xsl:value-of select="."/>
                                            </other-n>
                                        </xsl:for-each>
                                        <xsl:value-of select="$these-g1-toks[1]/text()"/>
                                    </tok>
                                </xsl:if>
                            </xsl:for-each-group>
                        </text>
                        <text>
                            <xsl:for-each-group select="$g2-ns" group-by=".">
                                <xsl:sort select="xs:integer(current-grouping-key())"/>
                                <xsl:variable name="this-g2-n" select="current-grouping-key()"
                                    as="xs:string"/>
                                <xsl:variable name="these-g2-toks" as="element()*"
                                    select="$ngrams-of-interest-with-g2-toks/tan:gram/tan:text[2]/tan:tok[@n eq $this-g2-n]"/>
                                <xsl:variable name="corresponding-g1-toks" as="element()*"
                                    select="$these-g2-toks/ancestor::tan:gram/tan:text[1]/tan:tok[@n = $g1-ns]"
                                />
                                
                                <xsl:if test="exists($these-g2-toks)">
                                    <tok>
                                        <xsl:copy-of select="$these-g2-toks[1]/@*"/>
                                        <!-- Rebulid the alias profiles -->
                                        <xsl:for-each select="tan:distinct-items($these-g2-toks/ancestor::tan:gram)">
                                            <alias>
                                                <xsl:copy-of select="@*"/>
                                                <xsl:copy-of
                                                    select="tan:text[2]/tan:alias-tok-frequency"/>
                                                <xsl:copy-of
                                                    select="tan:text[2]/tan:tok[@n eq $this-g2-n]/tan:resp"
                                                />
                                            </alias>
                                        </xsl:for-each>
                                        <xsl:for-each select="distinct-values($corresponding-g1-toks/@n)">
                                            <other-n>
                                                <xsl:value-of select="."/>
                                            </other-n>
                                        </xsl:for-each>
                                        <xsl:value-of select="$these-g2-toks[1]/text()"/>
                                    </tok>
                                </xsl:if>
                            </xsl:for-each-group>
                        </text>

                    </cluster>
                    
                </xsl:for-each>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Now, score the clusters; we opt for multiple methods of scoring, to be filtered later -->
    
    <xsl:variable name="common-output-pass-2-maps" as="map(*)*">
        <xsl:apply-templates select="$common-output-pass-1-maps" mode="score-clusters"/>
    </xsl:variable>
    
    <xsl:variable name="common-output-pass-2" as="document-node()*">
        <xsl:apply-templates select="$common-output-pass-1" mode="score-clusters"/>
    </xsl:variable>
    
    <xsl:mode name="score-clusters" on-no-match="shallow-copy"/>
    
    <xsl:template match=".[. instance of map(*)]" priority="-1" mode="score-clusters">
        <xsl:variable name="this-map" select="." as="map(*)"/>
        <xsl:map>
            <xsl:for-each select="map:keys(.)">
                <xsl:map-entry key=".">
                    <xsl:apply-templates select="$this-map(current())" mode="#current"/>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match=".[. instance of map(*)][map:contains(., 'base1') and map:contains(., 'base2')]" mode="score-clusters">
        <xsl:variable name="this-map" select="." as="map(*)"/>
        <xsl:variable name="base1" as="xs:string?" select="map:get(., 'base1')"/>
        <xsl:variable name="base2" as="xs:string?" select="map:get(., 'base2')"/>
        
        <xsl:variable name="tok-maps-g1" as="map(*)*" select="$input-tokenization-map($base1)"/>
        <xsl:variable name="tok-maps-g2" as="map(*)*" select="$input-tokenization-map($base2)"/>
        <xsl:map>
            <xsl:for-each select="map:keys(.)">
                <xsl:map-entry key=".">
                    <xsl:apply-templates select="$this-map(current())" mode="#current">
                        <xsl:with-param name="tok-maps-g1" tunnel="yes" select="$tok-maps-g1"/>
                        <xsl:with-param name="tok-maps-g2" tunnel="yes" select="$tok-maps-g2"/>
                        
                    </xsl:apply-templates>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match=".[. instance of map(*)][.?type = 'cluster']" mode="score-clusters">
        <xsl:param name="tok-maps-g1" tunnel="yes" as="map(*)*"/>
        <xsl:param name="tok-maps-g2" tunnel="yes" as="map(*)*"/>
        
        <xsl:variable name="this-map" select="." as="map(*)"/>
        <!--<xsl:variable name="this-map-as-array" as="array(*)" select="tan:map-to-array(., true())"/>-->
        
        <xsl:variable name="these-keys" as="item()*" select="map:keys(.)"/>
        <xsl:variable name="these-g1-keys" as="xs:integer+"
            select="$these-keys[. instance of xs:integer]"/>
        <xsl:variable name="these-g2-cluster-keys" as="xs:string+" select="$these-keys[starts-with(string(.), 'g2-')]"/>
        
        
        <xsl:variable name="these-g1-gram-keys" as="xs:integer+" select="
                for $i in $these-g1-keys
                return
                    if ($this-map($i)[1] instance of map(*)) then
                        $i
                    else
                        ()"/>
        
        <!--<xsl:if test="count($these-g1-gram-keys) eq 0">
            <xsl:message select="'unexpected lack of g1 keys'"/>
            <xsl:message select="'keys:', $these-keys"/>
            <xsl:for-each select="sort($these-g1-keys)">
                <xsl:message select="., $this-map(current())"/>
            </xsl:for-each>
        </xsl:if>-->
        <!--<xsl:variable name="these-g1-gram-keys" as="xs:integer+" select="
                for $i in $these-g1-keys
                return
                    let $j := $this-map($i)
                    return
                        if ($j instance of map(*)) then
                            $i
                        else
                            ()"/>-->
        <xsl:variable name="these-g2-gram-keys" as="array(xs:integer*)" select="
                array:join(for $i in $these-g2-cluster-keys
                return
                    let $j := $this-map($i)
                    return
                        [
                            (for $k in map:keys($j)[. instance of xs:integer]
                            return
                                if ($j($k)[1] instance of map(*)) then
                                    $k
                                else
                                    ())
                        ]
                )"/>
        
        <xsl:variable name="unmatched-g1-token-array" as="array(*)" select="
                array:join(for $i in $these-g1-keys,
                    $j in $this-map($i)
                return
                    (if ($j instance of xs:string) then
                        [($i, $j)]
                    else
                        ()))"/>
        <xsl:variable name="unmatched-g2-token-arrays" as="array(*)+" select="
                for $i in $these-g2-cluster-keys,
                    $j in $this-map($i)
                return
                    array:join(for $k in map:keys($j)[. instance of xs:integer],
                        $l in $j($k)
                    return
                        (if ($l instance of xs:string) then
                            [($k, $l)]
                        else
                            ()))"/>
        <xsl:variable name="unmatched-g1-strings-simplified" as="xs:string*" select="
                for $i in (1 to array:size($unmatched-g1-token-array))
                return
                    tan:string-base(lower-case($unmatched-g1-token-array($i)[2]))"/>
        <xsl:variable name="unmatched-token-comparison" as="element()*">
            <xsl:for-each select="$unmatched-g2-token-arrays">
                <xsl:variable name="these-strings-simplified" as="xs:string*" select="
                        for $i in (1 to array:size(current()))
                        return
                            tan:string-base(lower-case(.($i)[2]))"/>
                <xsl:copy-of select="tan:collate-pair-of-sequences($unmatched-g1-strings-simplified, $these-strings-simplified)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="counterpart-positions" as="array(xs:integer*)*" select="
                for $i in $unmatched-token-comparison
                return
                    array:join(for $j in $i/tan:common
                    return
                        [(count($j/preceding-sibling::*[not(self::tan:b)]) + 1, count($j/preceding-sibling::*[not(self::tan:a)]) + 1)])"
        />
        <xsl:variable name="counterpart-positions-absolute" as="array(xs:integer+)?" select="
                array:join(for $i in (1 to count($counterpart-positions))
                return
                    let $j := $counterpart-positions[$i],
                        $k := array:size($j)
                    return
                        for $m in (1 to $k)
                        return
                            let $memb := $j($m)
                            return
                                [($unmatched-g1-token-array($memb[1])[1], $unmatched-g2-token-arrays[$i]($memb[2])[1])])"
        />

        <xsl:variable name="counterpart-g1-to-g2-map" as="map(*)">
            <xsl:map>
                <xsl:for-each-group select="1 to array:size($counterpart-positions-absolute)"
                    group-by="
                        let $i := .
                        return
                            $counterpart-positions-absolute($i)[1]">
                    <xsl:variable name="these-pos" as="xs:integer+" select="current-group()"/>
                    <xsl:map-entry key="current-grouping-key()" select="
                            for $i in $these-pos
                            return
                                $counterpart-positions-absolute($i)[2]"/>
                </xsl:for-each-group> 
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="counterpart-g2-to-g1-map" as="map(*)">
            <xsl:map>
                <xsl:for-each-group select="1 to array:size($counterpart-positions-absolute)"
                    group-by="
                        let $i := .
                        return
                            $counterpart-positions-absolute($i)[2]">
                    <xsl:variable name="these-pos" as="xs:integer+" select="current-group()"/>
                    <xsl:map-entry key="current-grouping-key()" select="
                            for $i in $these-pos
                            return
                                $counterpart-positions-absolute($i)[1]"/>
                </xsl:for-each-group>
            </xsl:map>
        </xsl:variable>
        <!-- The scores for newly added matches is the inversion of the token count per average token count. Common words add little to
            the score. -->
        <xsl:variable name="bonus-g1-scores" as="xs:decimal*" select="
                for $i in $unmatched-token-comparison/tan:common
                return
                    (1 div $tok-maps-g1[2]($i)[3])"/>
        <xsl:variable name="bonus-g2-scores" as="array(xs:decimal*)*">
            <xsl:for-each select="$unmatched-token-comparison">
                <xsl:variable name="decimal-sequence" as="xs:decimal*" select="
                        for $i in tan:common
                        return
                            (1 div $tok-maps-g2[2]($i)[3])"/>
                <xsl:sequence select="array {$decimal-sequence}"/>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- Invert the ratios, so that rare items score above 1, and common ones below -->
        <!-- Any given <tok> might have more than one map, reflecting different sources of TAN-A-lm data,
            so the average is taken. In the future more sophisticated methods of parsing the different data
            might be taken into account. -->
        <xsl:variable name="g1-per-medians" as="xs:decimal+" select="
                for $i in $these-g1-gram-keys
                return
                    (1 div avg(for $j in $this-map($i)
                    return
                        $j('tok-count-per-median')))"/>
        <xsl:variable name="g1-per-averages" as="xs:decimal+" select="
                for $i in $these-g1-gram-keys
                return
                    (1 div avg(for $j in $this-map($i)
                    return
                        $j('tok-count-per-average')))"/>
        <xsl:variable name="g1-per-totals" as="xs:decimal+" select="
                for $i in $these-g1-gram-keys
                return
                    (1 div avg(for $j in $this-map($i)
                    return
                        $j('tok-count-per-total')))"/>
        <xsl:variable name="g1-cert-avgs" as="xs:decimal+" select="
                for $i in $these-g1-gram-keys
                return
                    avg(for $j in $this-map($i)
                    return
                        $j('cert-avg'))"/>
        <xsl:variable name="g2-counter" as="xs:integer+" select="1 to count($these-g2-cluster-keys)"/>
        <xsl:variable name="g2-per-medians" as="array(xs:decimal*)" select="
                array:join(for $i in $g2-counter
                return
                    let $j := $this-map($these-g2-cluster-keys[$i])
                    return
                        [
                            (for $k in $these-g2-gram-keys($i)
                            return
                                (1 div avg(for $m in $j($k)
                                return
                                    $m('tok-count-per-median'))))
                        ]
                )"/>
        <xsl:variable name="g2-per-averages" as="array(xs:decimal*)" select="
                array:join(for $i in $g2-counter
                return
                    let $j := $this-map($these-g2-cluster-keys[$i])
                    return
                        [
                            (for $k in $these-g2-gram-keys($i)
                            return
                                (1 div avg(for $m in $j($k)
                                return
                                    $m('tok-count-per-average'))))
                        ]
                )"/>
        <xsl:variable name="g2-per-totals" as="array(xs:decimal*)" select="
                array:join(for $i in $g2-counter
                return
                    let $j := $this-map($these-g2-cluster-keys[$i])
                    return
                        [
                            (for $k in $these-g2-gram-keys($i)
                            return
                                (1 div avg(for $m in $j($k)
                                return
                                    $m('tok-count-per-total'))))
                        ]
                )"/>
        <xsl:variable name="g2-cert-avgs" as="array(xs:decimal*)" select="
                array:join(for $i in $g2-counter
                return
                    let $j := $this-map($these-g2-cluster-keys[$i])
                    return
                        [
                            (for $k in $these-g2-gram-keys($i)
                            return
                                avg(for $m in $j($k)
                                return
                                    $m('cert-avg')))
                        ]
                )"/>
        
        
        
        <xsl:map>
            <xsl:map-entry key="'diagnostics-2'">
                <g1-gram-keys><xsl:copy-of select="$these-g1-gram-keys"/></g1-gram-keys>
                <g2-gram-keys><xsl:copy-of select="$these-g2-gram-keys"/></g2-gram-keys>
                <unmatched-g1-tokens><xsl:copy-of select="tan:array-to-xml($unmatched-g1-token-array)"/></unmatched-g1-tokens>
                <unmatched-g2-tokens><xsl:copy-of select="tan:array-to-xml($unmatched-g2-token-arrays)"/></unmatched-g2-tokens>
                <unmatched-token-comparison><xsl:copy-of select="$unmatched-token-comparison"/></unmatched-token-comparison>
                <counterpart-positions><xsl:copy-of select="tan:array-to-xml($counterpart-positions)"/></counterpart-positions>
                <counterpart-positions-absolute><xsl:copy-of select="tan:array-to-xml($counterpart-positions-absolute)"/></counterpart-positions-absolute>
                <!--<tok-maps-g1><xsl:value-of select="map:size($tok-maps-g1[2])"/></tok-maps-g1>-->
                <bonus-g1-scores><xsl:copy-of select="$bonus-g1-scores"/></bonus-g1-scores>
                <bonus-g2-scores><xsl:copy-of select="array:flatten($bonus-g2-scores)"/></bonus-g2-scores>
                <g1-per-medians><xsl:copy-of select="$g1-per-medians"/></g1-per-medians>
                <g1-per-averages><xsl:copy-of select="$g1-per-averages"/></g1-per-averages>
                <g1-per-totals><xsl:copy-of select="$g1-per-totals"/></g1-per-totals>
                <g1-cert-avgs><xsl:copy-of select="$g1-cert-avgs"/></g1-cert-avgs>
                <g2-per-medians><xsl:copy-of select="array:flatten($g2-per-medians)"/></g2-per-medians>
                <g2-per-averages><xsl:copy-of select="array:flatten($g2-per-averages)"/></g2-per-averages>
                <g2-per-totals><xsl:copy-of select="array:flatten($g2-per-totals)"/></g2-per-totals>
                <g2-cert-avgs><xsl:copy-of select="array:flatten($g2-cert-avgs)"/></g2-cert-avgs>
            </xsl:map-entry>
            <xsl:map-entry key="'scores'">
                <score method="text 1 sum of avg freq"
                    about="The sum of each text 1 token alias frequency (higher than 1 = less common) adjusted by certainty, supplemented by bonus match frequencies.">
                    <xsl:sequence select="
                            sum(for $i in (1 to count($g1-per-averages))
                            return
                                $g1-per-averages[$i] * $g1-cert-avgs[$i]) + sum($bonus-g1-scores)"/>
                </score>
                <score method="text 2 top sum of avg freq"
                    about="The top sum of each text 2 cluster's token alias frequency (higher than 1 = less common) adjusted by certainty, supplemented by bonus match frequencies.">
                    <xsl:sequence select="
                            max((for $i in $g2-counter
                            return
                                let $j := $g2-per-averages($i)
                                return
                                    (sum(for $k in (1 to count($j))
                                    return
                                        $j[$k] * $g2-cert-avgs($i)[$k])
                                        + sum($bonus-g2-scores[$i])
                                        )
                            ))"/>
                </score>
            </xsl:map-entry>
            <xsl:map-entry key="'counterparts'">
                <xsl:sequence select="$counterpart-g1-to-g2-map"/>
                <xsl:sequence select="$counterpart-g2-to-g1-map"/>
            </xsl:map-entry>
            <!--<xsl:for-each select="$counterpart-positions">
                <xsl:variable name="this-pos" as="xs:integer+" select="position()"/>
                <xsl:variable name="this-g2-token-array" as="array(*)" select="$unmatched-g2-token-arrays[$this-pos]"/>
                <xsl:variable name="this-array" as="array(xs:integer*)" select="."/>
                <xsl:if test="exists($unmatched-token-comparison[$this-pos]/tan:common)">
                    <xsl:map-entry key="'counterparts-g2-' || string($this-pos)">
                        <xsl:sequence select="
                                array:join(for $i in (1 to array:size($this-array))
                                return
                                    let $j := $this-array($i)
                                    return
                                        [($unmatched-g1-token-array($j[1])[1], $this-g2-token-array($j[2])[1])])"
                        />

                    </xsl:map-entry>
                </xsl:if>
            </xsl:for-each>-->
            <xsl:for-each select="map:keys(.)">
                <xsl:map-entry key=".">
                    <xsl:apply-templates select="$this-map(current())" mode="#current"/>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:template>
    
    <!-- In redistributing clusters, there may be cases where some defective clustures appear -->
    <xsl:template match="tan:cluster[tan:text[count(tan:tok) lt $target-ngram-n-norm]]" priority="1"
        mode="score-clusters"/>
    
    <xsl:template match="tan:cluster" mode="score-clusters">
        <xsl:variable name="g1-tok-alias-stats" as="array(xs:decimal+)*">
            <xsl:apply-templates select="tan:text[1]/tan:tok" mode="tok-to-stat-array"/>
        </xsl:variable>
        
        <xsl:variable name="g2-tok-alias-stats" as="array(xs:decimal+)*">
            <xsl:apply-templates select="tan:text[2]/tan:tok" mode="tok-to-stat-array"/>
        </xsl:variable>
        
        
        <!-- Invert the ratios, so that rare items score above 1, and common ones below -->
        <xsl:variable name="g1-per-medians" as="xs:decimal*" select="
                for $i in $g1-tok-alias-stats
                return
                    1 div $i(1)"/>
        <xsl:variable name="g2-per-medians" as="xs:decimal*" select="
                for $i in $g2-tok-alias-stats
                return
                    1 div $i(1)"/>
        <xsl:variable name="g1-per-averages" as="xs:decimal*" select="
                for $i in $g1-tok-alias-stats
                return
                    1 div $i(2)"/>
        <xsl:variable name="g2-per-averages" as="xs:decimal*" select="
                for $i in $g2-tok-alias-stats
                return
                    1 div $i(2)"/>
        <xsl:variable name="g1-per-totals" as="xs:decimal*" select="
                for $i in $g1-tok-alias-stats
                return
                    1 div $i(3)"/>
        <xsl:variable name="g2-per-totals" as="xs:decimal*" select="
                for $i in $g2-tok-alias-stats
                return
                    1 div $i(3)"/>
        <xsl:variable name="g1-cert-avg" as="xs:decimal*" select="
                for $i in $g1-tok-alias-stats
                return
                    avg(($i(4), $i(5)))"/>
        <xsl:variable name="g2-cert-avg" as="xs:decimal*" select="
                for $i in $g2-tok-alias-stats
                return
                    avg(($i(4), $i(5)))"/>
        <xsl:variable name="g1-n-gaps" select="
                for $i in (xs:integer(tan:text[1]/tan:tok[1]/@n) + 1 to xs:integer(tan:text[1]/tan:tok[last()]/@n) - 1)
                return
                    if (exists(tan:text[1]/tan:tok[@n eq string($i)])) then
                        ()
                    else
                        $i" as="xs:integer*"/>
        <xsl:variable name="g2-n-gaps" select="
                for $i in (xs:integer(tan:text[2]/tan:tok[1]/@n) + 1 to xs:integer(tan:text[2]/tan:tok[last()]/@n) - 1)
                return
                    if (exists(tan:text[2]/tan:tok[@n eq string($i)])) then
                        ()
                    else
                        $i" as="xs:integer*"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <scores>
                <score method="top avg of freq avgs"
                    about="In each text, take the average of each token alias's frequency (less than 1 = below average) adjusted by certainty. The top score of the two texts is retained.">
                    <xsl:sequence select="
                            max((
                            avg(for $i in (1 to count($g1-per-averages))
                            return
                                $g1-per-averages[$i] * $g1-cert-avg[$i])
                                ,
                            avg(for $i in (1 to count($g2-per-averages))
                            return
                                $g2-per-averages[$i] * $g2-cert-avg[$i])
                            ))"/>
                </score>
                <score method="weighted top avg of freq avgs"
                    about="In each text, take the average of each token alias's frequency (less than 1 = below average) squared and adjusted by certainty. The top score of the two texts is retained.">
                    <xsl:sequence select="
                            max((
                            avg(for $i in (1 to count($g1-per-averages))
                            return
                                math:pow($g1-per-averages[$i], 2) * $g1-cert-avg[$i])
                            ,
                            avg(for $i in (1 to count($g2-per-averages))
                            return
                                math:pow($g2-per-averages[$i], 2) * $g2-cert-avg[$i])
                            ))"/>
                </score>
                <score method="top avg of freq medians"
                    about="In each text, take the average of each token alias's frequency (less than 1 = below median) adjusted by certainty. The top score of the two texts is retained.">
                    <xsl:sequence select="
                            max((
                            avg(for $i in (1 to count($g1-per-medians))
                            return
                                $g1-per-medians[$i] * $g1-cert-avg[$i])
                                ,
                            avg(for $i in (1 to count($g2-per-medians))
                            return
                                $g2-per-medians[$i] * $g2-cert-avg[$i])
                            ))"/>
                </score>
                <score method="weighted top avg of freq medians"
                    about="In each text, take the average of each token alias's frequency (less than 1 = below median) squared and adjusted by certainty. The top score of the two texts is retained.">
                    <xsl:sequence select="
                            max((
                            avg(for $i in (1 to count($g1-per-medians))
                            return
                                math:pow($g1-per-medians[$i], 2) * $g1-cert-avg[$i])
                            ,
                            avg(for $i in (1 to count($g2-per-medians))
                            return
                                math:pow($g2-per-medians[$i], 2) * $g2-cert-avg[$i])
                            ))"/>
                </score>
                <score method="adjusted length"
                    about="The average of the length of the matching segments, less gaps.">
                    <xsl:sequence
                        select="(count(tan:text/tan:tok) - count($g1-n-gaps) - count($g2-n-gaps)) div 2"
                    />
                </score>
            </scores>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:mode name="tok-to-stat-array" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:tok[tan:alias]" mode="tok-to-stat-array">
        <xsl:variable name="alias-stats" as="array(xs:decimal+)+">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:variable name="alias-stat-size" as="xs:integer" select="array:size($alias-stats[1])"/>
        <xsl:variable name="stat-averages" as="xs:decimal+" select="
                for $i in (1 to $alias-stat-size)
                return
                    avg(for $j in $alias-stats
                    return
                        $j($i))"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on, template mode tok-to-stat-array, at ', ."/>
            <xsl:message select="'alias stat size: ' || string($alias-stat-size)"/>
            <xsl:message select="'stat averages (' || string(count($stat-averages)) || '):', $stat-averages"/>
        </xsl:if>
        
        <xsl:sequence select="array{$stat-averages}"/>
    </xsl:template>
    
    <xsl:template match="tan:alias" mode="tok-to-stat-array">
        <xsl:variable name="atf" as="element()" select="tan:alias-tok-frequency"/>
        <xsl:variable name="these-resp-certs" as="xs:decimal+" select="
                for $i in tan:resp
                return
                    xs:decimal($i/@cert)"/>
        <xsl:variable name="these-resp-cert2s" as="xs:decimal+" select="
                for $i in tan:resp
                return
                    xs:decimal($i/@cert2)"/>
        <xsl:sequence select="
                [
                    xs:decimal($atf/@per-median), xs:decimal($atf/@per-average), xs:decimal($atf/@per-total),
                    xs:decimal(avg($these-resp-certs)), xs:decimal(avg($these-resp-cert2s))
                ]"/>
    </xsl:template>
    
    
    
    
    <!-- Now that statistics and number-based collation is finished, we can convert the maps to trees -->
    <xsl:variable name="common-output-pass-3" as="document-node()*">
        <xsl:apply-templates select="$common-output-pass-2-maps" mode="sort-and-fill-out-results"/>
        <!--<xsl:apply-templates select="$common-output-pass-2" mode="sort-and-fill-out-results"/>-->
    </xsl:variable>
    
    <xsl:mode name="sort-and-fill-out-results" on-no-match="shallow-copy"/>
    
    <xsl:template match=".[. instance of map(*)][map:contains(., 'base1')]" mode="sort-and-fill-out-results">
        <xsl:variable name="this-map" as="map(*)" select="."/>
        <xsl:variable name="this-cluster-map" as="map(*)" select="$this-map('clusters')"/>
        <xsl:variable name="b1" as="xs:string" select="$this-map('base1')"/>
        <xsl:variable name="b2" as="xs:string" select="$this-map('base2')"/>
        <xsl:variable name="t1-map" as="map(*)" select="$input-tokenization-map($b1)[1]"/>
        <xsl:variable name="t2-map" as="map(*)" select="$input-tokenization-map($b2)[1]"/>
        <xsl:document>
            <ngrams>
                <xsl:for-each select="('n', 'base1', 'base2', 'src1', 'src2', 'lang')">
                    <xsl:attribute name="{.}" select="$this-map(current())"/>
                </xsl:for-each>
                <xsl:for-each select="map:keys($this-cluster-map)">
                    <xsl:sort select="let $i := . return
                        xs:decimal($this-cluster-map($i)('scores')[1])" order="descending"/>
                    <xsl:variable name="this-key" as="item()" select="."/>
                    <xsl:apply-templates select="$this-cluster-map($this-key)" mode="#current">
                        <xsl:with-param name="t1-map" tunnel="yes" select="$t1-map"/>
                        <xsl:with-param name="t2-map" tunnel="yes" select="$t2-map"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </ngrams>
        </xsl:document>
    </xsl:template>
    
    <xsl:template match=".[. instance of map(*)][map:contains(., 'scores')]" mode="sort-and-fill-out-results">
        <xsl:param name="t1-map" tunnel="yes" as="map(*)"/>
        <xsl:param name="t2-map" tunnel="yes" as="map(*)"/>
        
        <xsl:variable name="this-cluster-map" as="map(*)" select="."/>
        <xsl:variable name="these-keys" as="item()*" select="map:keys(.)"/>
        <xsl:variable name="these-g1-text-keys" as="xs:integer+" select="sort($these-keys[. instance of xs:integer])"/>
        <xsl:variable name="these-counterpart-maps" as="map(*)+" select="$this-cluster-map('counterparts')"/>
        <xsl:variable name="these-g2-text-passage-keys" as="xs:string+" select="sort($these-keys[. instance of xs:string][starts-with(., 'g2-')])"/>
        <cluster>
            <scores>
                <xsl:copy-of select=".('scores')"/>
            </scores>
            <text>
                <xsl:for-each
                    select="($these-g1-text-keys[1] - $extra-context-token-count) to ($these-g1-text-keys[last()] + $extra-context-token-count)">
                    <xsl:variable name="this-t1-key" as="xs:integer" select="."/>
                    <xsl:variable name="these-tok-items" as="item()*" select="$this-cluster-map($this-t1-key)"/>
                    <xsl:apply-templates select="$t1-map($this-t1-key)" mode="#current">
                        <xsl:with-param name="counterparts" tunnel="yes" as="xs:integer*"
                            select="$these-counterpart-maps[1]($this-t1-key)"/>
                        <xsl:with-param name="tok-alias-content" as="map(*)*" tunnel="yes"
                            select="$these-tok-items[. instance of map(*)]"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </text>
            <text>
                <xsl:for-each select="$these-g2-text-passage-keys">
                    <xsl:variable name="this-g2-passage-key" as="xs:string" select="."/>
                    <xsl:variable name="this-g2-passage-map" as="map(*)" select="$this-cluster-map($this-g2-passage-key)"/>
                    <xsl:variable name="these-g2-keys" as="item()*" select="map:keys($this-g2-passage-map)"/>
                    <xsl:variable name="these-g2-text-keys" as="xs:integer+" select="sort($these-g2-keys[. instance of xs:integer])"/>
                    <passage>
                        <xsl:for-each
                            select="($these-g2-text-keys[1] - $extra-context-token-count) to ($these-g2-text-keys[last()] + $extra-context-token-count)">
                            <xsl:variable name="this-t2-key" as="xs:integer" select="."/>
                            <xsl:variable name="these-tok-items" as="item()*" select="$this-g2-passage-map($this-t2-key)"/>
                            <xsl:apply-templates select="$t2-map($this-t2-key)" mode="#current">
                                <xsl:with-param name="counterparts" as="xs:integer*" tunnel="yes"
                                    select="$these-counterpart-maps[2]($this-t2-key)"/>
                                <xsl:with-param name="tok-alias-content" as="map(*)*" tunnel="yes"
                                    select="$these-tok-items[. instance of map(*)]"/>
                            </xsl:apply-templates>
                        </xsl:for-each>
                    </passage>
                    
                    
                </xsl:for-each>
            </text>
        </cluster>
    </xsl:template>
    
    <xsl:template match="tan:tok" mode="sort-and-fill-out-results">
        <xsl:param name="counterparts" tunnel="yes" as="xs:integer*"/>
        <xsl:param name="tok-alias-content" tunnel="yes" as="map(*)*"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="$tok-alias-content">
                <alias r="{.('r')}">
                    <alias-tok-frequency>
                        <xsl:attribute name="count" select=".('tok-count')"/>
                        <xsl:attribute name="per-median" select=".('tok-count-per-median')"/>
                        <xsl:attribute name="per-average" select=".('tok-count-per-average')"/>
                        <xsl:attribute name="per-total" select=".('tok-count-per-total')"/>
                    </alias-tok-frequency>
                </alias>
                <xsl:for-each select=".('counterpart-ns')">
                    <counterpart><xsl:value-of select="."/></counterpart>
                </xsl:for-each>
            </xsl:for-each>
            <xsl:for-each select="$counterparts">
                <counterpart><xsl:value-of select="."/></counterpart>
            </xsl:for-each>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/*" mode="sort-and-fill-out-results">
        <xsl:variable name="b1" as="xs:string" select="@base1"/>
        <xsl:variable name="b2" as="xs:string" select="@base2"/>
        <!--<xsl:variable name="t1-tok" as="document-node()" select="$files-tokenized-g1[*/@xml:base eq $b1]"/>-->
        <!--<xsl:variable name="t2-tok" as="document-node()" select="$files-tokenized-g2[*/@xml:base eq $b2]"/>-->
        <xsl:variable name="t1-map" as="map(*)" select="$input-tokenization-map($b1)[1]"/>
        <xsl:variable name="t2-map" as="map(*)" select="$input-tokenization-map($b2)[1]"/>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:sort select="number(tan:scores/tan:score[1])" order="descending"/>
                <xsl:with-param name="tok-maps" tunnel="yes" select="$t1-map, $t2-map" as="map(*)+"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:text" mode="sort-and-fill-out-results">
        <xsl:param name="tok-maps" tunnel="yes" as="map(*)+"/>
        
        <xsl:variable name="text-pos" as="xs:integer" select="count(preceding-sibling::tan:text) + 1"/>
        <xsl:variable name="first-tok-n" as="xs:integer" select="xs:integer(tan:tok[1]/@n)"/>
        <xsl:variable name="last-tok-n" as="xs:integer" select="xs:integer(tan:tok[last()]/@n)"/>
        <xsl:variable name="tok-children" as="element()+" select="tan:tok"/>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="($first-tok-n - $extra-context-token-count) to ($last-tok-n + $extra-context-token-count)">
                <xsl:variable name="this-n" select="."/>
                <xsl:variable name="context-toks" as="element()*" select="$tok-maps[$text-pos]($this-n)"/>
                <xsl:variable name="current-tok" as="element()?" select="$tok-children[@n eq string($this-n)]"/>
                <xsl:apply-templates select="$context-toks/self::tan:x" mode="#current"/>
                <xsl:apply-templates select="($current-tok, $context-toks/self::tan:tok)[1]"
                    mode="#current"/>
            </xsl:for-each>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="tan:tok/tan:ana" mode="sort-and-fill-out-results"/>
    
    
    
    
    
    <!-- stamp the normalized input files -->
    <xsl:variable name="files-normalized-and-stamped-g1" as="document-node()*"
        select="tan:stamp-tree-with-text-data($files-normalized-g1, true())"/>
    <xsl:variable name="files-normalized-and-stamped-g2" as="document-node()*"
        select="tan:stamp-tree-with-text-data($files-normalized-g2, true())"/>
    
    
    <xsl:variable name="common-output-pass-4" as="document-node()*">
        <xsl:apply-templates select="$common-output-pass-3" mode="infuse-div-structures"/>
    </xsl:variable>
    
    <xsl:mode name="infuse-div-structures" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*" mode="infuse-div-structures">
        <xsl:variable name="b1" as="xs:string" select="@base1"/>
        <xsl:variable name="b2" as="xs:string" select="@base2"/>
        <xsl:variable name="t1-norm" as="document-node()" select="$files-normalized-and-stamped-g1[*/@xml:base eq $b1]"/>
        <xsl:variable name="t2-norm" as="document-node()" select="$files-normalized-and-stamped-g2[*/@xml:base eq $b2]"/>
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="input-normalized" tunnel="yes" select="$t1-norm, $t2-norm" as="document-node()+"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:text[not(tan:passage)]" mode="infuse-div-structures">
        <xsl:param name="input-normalized" tunnel="yes" as="document-node()+"/>
        <xsl:copy>
            <xsl:apply-templates select="$input-normalized[1]" mode="get-div-fragment">
                <xsl:with-param name="tok-chain" as="element()*" tunnel="yes" select="*"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:text/tan:passage" mode="infuse-div-structures">
        <xsl:param name="input-normalized" tunnel="yes" as="document-node()+"/>
        <xsl:copy>
            <xsl:apply-templates select="$input-normalized[2]" mode="get-div-fragment">
                <xsl:with-param name="tok-chain" as="element()*" tunnel="yes" select="*"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:mode name="get-div-fragment" on-no-match="shallow-skip"/>
    
    <xsl:template match="/*" mode="get-div-fragment">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*" mode="get-div-fragment">
        <xsl:param name="tok-chain" tunnel="yes" as="element()*"/>
        <xsl:variable name="start-pos" as="xs:integer" select="xs:integer(@_pos)"/>
        <xsl:variable name="end-pos" as="xs:integer" select="$start-pos + xs:integer(@_len)"/>
        <xsl:variable name="toks-of-interest" select="$tok-chain[xs:integer(@_pos) ge $start-pos][xs:integer(@_pos) lt $end-pos]"/>
        <xsl:choose>
            <xsl:when test="not(exists($toks-of-interest))"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:if test="not(*:div)">
                        <xsl:attribute name="ref" select="tan:get-ref(.)"/>
                    </xsl:if>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="tok-chain" as="element()*" tunnel="yes" select="$toks-of-interest"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="text()" mode="get-div-fragment">
        <xsl:param name="tok-chain" tunnel="yes" as="element()*"/>
        <xsl:copy-of select="$tok-chain"/>
    </xsl:template>
    
    
    
    
    <xsl:variable name="common-output-pass-5" as="document-node()*">
        <xsl:apply-templates select="$common-output-pass-4" mode="build-tan-a-claims"/>
    </xsl:variable>
    
    <xsl:mode name="build-tan-a-claims" on-no-match="shallow-copy"/>
    
    
    <xsl:template match="/*" mode="build-tan-a-claims">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="src1" as="xs:string" tunnel="yes" select="@src1"/>
                <xsl:with-param name="src2" as="xs:string" tunnel="yes" select="@src2"/>
                <xsl:with-param name="max-score" tunnel="yes" select="xs:decimal(tan:cluster[1]/tan:scores/tan:score[1])"/>
            </xsl:apply-templates>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="tan:cluster" mode="build-tan-a-claims">
        <xsl:param name="src1" tunnel="yes" as="xs:string"/>
        <xsl:param name="src2" tunnel="yes" as="xs:string"/>
        <xsl:param name="max-score" tunnel="yes" as="xs:decimal"/>
        <xsl:variable name="subject-leaf-divs" select="tan:text[1]//*:div[not(*:div)]" as="element()+"/>
        <xsl:variable name="object-leaf-divs" select="tan:text[2]//*:div[not(*:div)]" as="element()+"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <claim verb="quotes" cert="{xs:decimal(tan:scores/tan:score[1]) div $max-score}">
                <subject src="{$src1}" ref="{string-join($subject-leaf-divs/@ref, ' - ')}"/>
                <object src="{$src2}" ref="{string-join($object-leaf-divs/@ref, ' - ')}"/>
            </claim>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:_text" mode="build-tan-a-claims">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    
    
    
    
    <!-- Some important functions -->
    
    <xsl:function name="tan:integer-clusters" as="xs:integer*">
        <!-- Input: two sequences of integers -->
        <!-- Output: all of the integers from the second parameter, as well as all integers from the first that
            form a chain of one or more consecutive integers from any member of the second sequence. Output will
            be sorted in ascending order. -->
        <!-- Example: (1, 4, 5, 7, 9) and (6, 12) - > (4, 5, 6, 7, 12) -->
        <!-- This function was written to differentiate between aura points of interest and those not of interest,
            given the insertion of new aura points. -->
        <xsl:param name="integers-to-filter" as="xs:integer*"/>
        <xsl:param name="cluster-cores" as="xs:integer*"/>
        
        <xsl:variable name="unique-cluster-cores" select="distinct-values($cluster-cores)" as="xs:integer*"/>
        <xsl:variable name="unique-all-sorted" as="xs:integer*" select="sort(distinct-values(($integers-to-filter, $unique-cluster-cores)))"/>
        
        <!--<xsl:variable name="seq-start" as="xs:integer?" select="$unique-all-sorted[1]"/>
        <xsl:variable name="seq-end" as="xs:integer?" select="$unique-all-sorted[2]"/>-->
        <xsl:variable name="false-int" as="xs:integer?" select="$unique-all-sorted[1] - 1"/>
        <!--<xsl:variable name="new-sequence" as="xs:integer*" select="
                for $i in ($seq-start to $seq-end)
                return
                    (if ($i = $unique-all-sorted) then
                        $i
                    else
                        $false-int)"/>-->
        <xsl:variable name="new-sequence" as="xs:integer*">
            <xsl:iterate select="$unique-all-sorted">
                <xsl:param name="prev" as="xs:integer" select="$false-int"/>
                <xsl:variable name="diff" as="xs:integer" select=". - $prev"/>
                <xsl:for-each select="1 to $diff - 1">
                    <xsl:sequence select="$false-int"/>
                </xsl:for-each>
                <xsl:sequence select="."/>
                <xsl:next-iteration>
                    <xsl:with-param name="prev" select="."/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        
        <xsl:for-each-group select="$new-sequence" group-adjacent=". gt $false-int">
            <xsl:if test="current-grouping-key() and (current-group() = $unique-cluster-cores)">
                <xsl:sequence select="current-group()"/>
            </xsl:if>
        </xsl:for-each-group> 
        <!--<xsl:sequence select="$integers-to-filter"/>-->
        
    </xsl:function>
    
    
    
    <xsl:function name="tan:build-skp-sequence" as="xs:string*">
        <!-- Input: a string -->
        <!-- Output: distinct characters in the string, most frequent first -->
        <!-- This function was written to support the method developed by Schmidman, Koppel, and Porat. -->
        <xsl:param name="in-string" as="xs:string?"/>
        <xsl:for-each-group select="string-to-codepoints($in-string)" group-by=".">
            <xsl:sort select="count(current-group())" order="descending"/>
            <xsl:sequence select="codepoints-to-string(current-grouping-key())"/>
        </xsl:for-each-group> 
    </xsl:function>
    
    <xsl:function name="tan:skp-reduce" as="xs:string?">
        <!-- Input: a string; a sequence of strings (letters); an integer; a boolean -->
        <!-- Output: the first string reduced to a string of length N, where N is the integer.
            The new string are the two most common letters in the original input, if the boolean
            is true, and the least common if false. This function supports, and enhances, the 
            method developed by Schmidman, Koppel, and Porat. -->
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="skp-sequence" as="xs:string+"/>
        <xsl:param name="use-most-common" as="xs:boolean"/>
        <xsl:param name="max-letters-to-return" as="xs:integer"/>
        
        <xsl:variable name="skp-seq-cps" as="xs:integer" select="
                if ($use-most-common) then
                    string-to-codepoints($skp-sequence)
                else
                    reverse(string-to-codepoints($skp-sequence))"/>
        
        <xsl:choose>
            <xsl:when test="not(every $i in $skp-sequence satisfies (string-length($i) eq 1))">
                <xsl:message
                    select="'tan:skp-reduce(): the SKP sequence must be a sequence of individual characters, most common first.'"
                />
            </xsl:when>
            <xsl:when test="$max-letters-to-return lt 1">
                <xsl:message select="'tan:skp-reduce(): the number of letters to return must be 1 or greater.'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="token-cps" as="xs:integer*" select="string-to-codepoints($token)"/>
                <xsl:variable name="token-cps-sorted" as="xs:integer*">
                    <xsl:for-each select="$token-cps">
                        <xsl:sort select="index-of($skp-seq-cps, .)"/>
                        <xsl:if test="position() le $max-letters-to-return">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="good-token-cps" as="xs:integer*" select="$token-cps[. = $token-cps-sorted]"/>
                <xsl:sequence
                    select="codepoints-to-string(subsequence($good-token-cps, 1, $max-letters-to-return))"
                />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <!-- RESULT TREE -->
    <xsl:param name="output-diagnostics-on" static="yes" select="true()"/>
    <xsl:output indent="yes" use-when="$output-diagnostics-on"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <!--<xsl:variable name="tan-a-lm-doc" select="tan:get-1st-doc($files-resolved-g2[1]/*/tan:head/tan:annotation[1])"/>-->
        <!--<xsl:variable name="tan-a-lm-res" select="tan:resolve-doc($tan-a-lm-doc)"/>-->
        <!--<xsl:variable name="tan-a-lm-exp" select="tan:expand-doc($tan-a-lm-res, 'terse')"/>-->
        <xsl:message
            select="'Using diagnostic output for application ' || $tan:stylesheet-name || ' (' || static-base-uri() || ')'"
        />
        <diagnostics>
            <!--<miru-candidates count="{count($main-input-resolved-uris)}"/>-->
            <mirus-chosen count="{count($mirus-chosen)}"><xsl:value-of select="$mirus-chosen"/></mirus-chosen>
            <mirus-group-1 count="{count($mirus-g1)}"><xsl:copy-of select="$mirus-g1"/></mirus-group-1>
            <mirus-group-2 count="{count($mirus-g2)}"><xsl:copy-of select="$mirus-g2"/></mirus-group-2>
            <!--<g1-resolved><xsl:copy-of select="$files-resolved-g1"/></g1-resolved>-->
            <!--<g2-resolved><xsl:copy-of select="$files-resolved-g2"/></g2-resolved>-->
            <!--<files-with-tan-a-lm-annotations><xsl:copy-of select="$files-with-tan-a-lm-annonations"/></files-with-tan-a-lm-annotations>-->
            <files-norm-g1><xsl:copy-of select="tan:trim-long-tree($files-normalized-g1, 5, 10)"/></files-norm-g1>
            <files-norm-g2><xsl:copy-of select="tan:trim-long-tree($files-normalized-g2, 5, 10)"/></files-norm-g2>
            <!--<files-norm-special><xsl:copy-of select="$files-normalized-g2[1]"/></files-norm-special>-->
            <!--<g2-tan-a-lm><xsl:copy-of select="$tan-a-lm-doc"/></g2-tan-a-lm>-->
            <!--<g2-tan-a-lm-res><xsl:copy-of select="$tan-a-lm-res"/></g2-tan-a-lm-res>-->
            <!--<g2-tan-a-lm-exp><xsl:copy-of select="$tan-a-lm-exp"/></g2-tan-a-lm-exp>-->
            <files-tokenized-g1><xsl:copy-of select="tan:trim-long-tree($files-tokenized-g1, 30, 100)"/></files-tokenized-g1>
            <files-tokenized-g2><xsl:copy-of select="tan:trim-long-tree($files-tokenized-g2, 30, 100)"/></files-tokenized-g2>
            <!--<input-tokenization-map><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($input-tokenization-map, true()), 20, 100)"/></input-tokenization-map>-->
            <tok-aliases-g1><xsl:copy-of select="tan:trim-long-tree($tok-aliases-g1, 20, 100)"/></tok-aliases-g1>
            <tok-aliases-g2><xsl:copy-of select="tan:trim-long-tree($tok-aliases-g2, 20, 100)"/></tok-aliases-g2>
            <!--<token-alias-maps-g1><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($token-alias-maps-g1, true()), 20, 100)"/></token-alias-maps-g1>-->
            <!--<token-alias-maps-g2><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($token-alias-maps-g2, true()), 20, 100)"/></token-alias-maps-g2>-->
            <!--<tok-aliases-cons-g1><xsl:copy-of select="tan:trim-long-tree($tok-aliases-consolidated-g1, 20, 100)"/></tok-aliases-cons-g1>-->
            <!--<tok-aliases-cons-g2><xsl:copy-of select="tan:trim-long-tree($tok-aliases-consolidated-g2, 20, 100)"/></tok-aliases-cons-g2>-->
            <!--<tok-aliases-cons-special><xsl:copy-of select="($tok-aliases-consolidated-g1, $tok-aliases-consolidated-g2)/*/*[@r eq 'μέλλω']"/></tok-aliases-cons-special>-->
            <!--<all-1gram-maps><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($all-1gram-maps, true()), 20, 100)"/></all-1gram-maps>-->
            <!--<all-1grams><xsl:copy-of select="tan:trim-long-tree($all-1grams, 20, 100)"/></all-1grams>-->
            <!--<all-1grams-special><xsl:copy-of select="$all-1grams/*/*/*[@r eq 'μέλλω']"/></all-1grams-special>-->
            <!--<all-cumulative-ngram-maps><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($all-cumulative-ngram-maps, true()), 20, 100)"/></all-cumulative-ngram-maps>-->
            <!--<all-cumulative-ngrams><xsl:copy-of select="tan:trim-long-tree($all-cumulative-ngrams, 20, 100)"/></all-cumulative-ngrams>-->
            <!--<all-target-ngram-maps><xsl:copy-of select="tan:map-to-xml($all-target-ngram-maps, true())"/></all-target-ngram-maps>-->
            <!--<all-target-ngrams><xsl:copy-of select="$all-target-ngrams"/></all-target-ngrams>-->
            <!--<common-output-pass-1-maps><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($common-output-pass-1-maps, true()), 20, 40)"/></common-output-pass-1-maps>-->
            <!--<common-output-pass-1><xsl:copy-of select="tan:trim-long-tree($common-output-pass-1, 20, 40)"/></common-output-pass-1>-->
            <!--<common-output-pass-2-maps><xsl:copy-of select="tan:trim-long-tree(tan:map-to-xml($common-output-pass-2-maps, true()), 20, 40)"/></common-output-pass-2-maps>-->
            <!--<common-output-pass-2><xsl:copy-of select="tan:trim-long-tree($common-output-pass-2, 20, 40)"/></common-output-pass-2>-->
            <!--<common-output-pass-3><xsl:copy-of select="tan:trim-long-tree($common-output-pass-3, 20, 40)"/></common-output-pass-3>-->
            <!--<files-norm-and-stamped-g1><xsl:copy-of select="tan:trim-long-tree($files-normalized-and-stamped-g1, 5, 10)"/></files-norm-and-stamped-g1>-->
            <!--<files-norm-and-stamped-g2><xsl:copy-of select="tan:trim-long-tree($files-normalized-and-stamped-g2, 5, 10)"/></files-norm-and-stamped-g2>-->
            <!--<common-output-pass-4><xsl:copy-of select="tan:trim-long-tree($common-output-pass-4, 20, 40)"/></common-output-pass-4>-->
            <!--<common-output-pass-5><xsl:copy-of select="tan:trim-long-tree($common-output-pass-5, 20, 40)"/></common-output-pass-5>-->
            <!--<html-output-pass-1><xsl:copy-of select="tan:trim-long-tree($html-output-pass-1, 10, 20)"/></html-output-pass-1>-->
            <!--<html-output-pass-2><xsl:copy-of select="tan:trim-long-tree($html-output-pass-2, 10, 20)"/></html-output-pass-2>-->
        </diagnostics>
        <!--<xsl:apply-templates select="$files-with-tan-a-lm-annotations"
            mode="save-temp-file-and-manifest"/>-->
        <!--<xsl:apply-templates select="$tok-aliases-g1, $tok-aliases-g2"
            mode="save-temp-file-and-manifest"/>-->
        <!--<xsl:apply-templates select="$all-cumulative-ngram-maps"
            mode="save-temp-file-and-manifest"/>-->
        <!--<xsl:apply-templates select="$all-cumulative-ngrams"
            mode="save-temp-file-and-manifest"/>-->
        
        <!--<xsl:result-document href="{$output-directory-uri-resolved}{$output-base-filename}.html"
            format="html-noindent" use-character-maps="keep-javascript-chars">
            <xsl:message
                select="'Saving HTML output to ' || $output-directory-uri-resolved || $output-base-filename || '.html'"/>
            <xsl:sequence select="$html-output-pass-2"/>
        </xsl:result-document>-->
    </xsl:template>
    <xsl:template match="/">
        <xsl:message select="$tan:stylesheet-change-message"/>
        
    </xsl:template>
    
    
</xsl:stylesheet>
