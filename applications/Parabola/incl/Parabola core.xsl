<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for remodeling a text. -->

    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    
    <!-- Note: this stylesheet's default namespace is HTML, because it builds only HTML output. -->

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:display-merged-sources-as-html'"/>
    <xsl:param name="tan:stylesheet-name" as="xs:string" select="'Parabola'"/>
    <xsl:param name="tan:stylesheet-activity" as="xs:string"
        select="'arranges work versions in parallel for the web'"/>
    <xsl:param name="tan:stylesheet-description" as="xs:string">This application allows you to take
        a library of TAN/TEI files with multiple versions of each work and present them in an
        interactive HTML page.</xsl:param>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">a TAN-A file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">its sources expanded</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">an interactive HTML page
        with the versions of the chosen work grouped and arranged in parallel, with
        annotations</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>
    
    <xsl:param name="tan:stylesheet-output-examples" as="element()*">
        <example>
            <location>http://textalign.net/output/aristotle-categories-ref-bekker-page-col-line.html</location>
            <description>Aristotle, Categories, in eight versions, six languages</description>
        </example>
        <example>
            <location>https://textalign.net/output/cpg%204425.TAN-A-div-2018-03-09.html</location>
            <description>Homilies on the Gospel of John, John Chrysostom, four versions, two languages</description>
        </example>
        <example>
            <location>https://evagriusponticus.net/cpg2430/cpg2430-full-for-reading.html</location>
            <description>The Praktikos by Evagrius of Pontus, three languages, with Bible quotations</description>
        </example>
        <example>
            <location>https://textalign.net/quran/quran.ara+grc+syr+lat+deu+eng.html</location>
            <description>Qur'an in eighteen versions, six languages</description>
        </example>
    </xsl:param>
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2021-03-09">Simplify the routine. This was converted
                from an inferior workflow, and still takes too many passes to get to the output.
            </comment>
            <comment who="kalvesmaki" when="2021-03-10">Annotations need a lot of work. They should
                be placed into the merge early. In fact, the whole workflow needs to be revised,
                with most structural work finished before attempting to convert to HTML.</comment>
            <comment who="kalvesmaki" when="2020-07-28">Develop output option using nested HTML
                divs, to parallel the existing output that uses HTML tables</comment>
            <comment who="kalvesmaki" when="2020-09-23">Integrate diff/collate into cells, on both
                the global and local level.</comment>
            <comment who="kalvesmaki" when="2020-09-23">Develop the css bar to allow users to click
                source id labels on and off.</comment>
            <comment who="kalvesmaki" when="2020-09-23">Add labels for divs higher than version
                wrappers.</comment>
            <comment who="kalvesmaki" when="2021-07-20">Consider merging based upon the resolved
                file, not its expansion.</comment>
        </to-do>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="'Converted merged TAN-A sources to HTML'"/>
    

    <!-- Normalize the parameters -->
    
    <xsl:variable name="primary-color-array-size" select="array:size($primary-color-array)"/>
    
    <xsl:variable name="output-directory-uri-resolved" as="xs:string"
        select="tan:uri-directory(resolve-uri($output-directory-uri, $calling-stylesheet-uri))"/>
    

    <!-- The application -->
    
    
    <!-- START OF THE PROCESS -->
    
    <!-- PRELIMINARIES -->
    
    <!-- Get rid of comments -->
    <xsl:template match="comment() | processing-instruction()"
        mode="tan:core-expansion-ad-hoc-pre-pass tan:dependency-adjustments-pass-1"/>
    
    <!-- Group the TAN-A sources by work. Currently only the first source's work group will be processed. We do not use TAN-A/head/vocabulary-key/work 
    because the latter is built upon a generous view of allowing aliases to determine several different works in one fell swoop, but that might be
    more than the current user wants, namely, choosing to group works according to selective alias(es). -->
    <xsl:variable name="valid-src-work-vocab" as="element()*">
        <xsl:for-each select="$tan:sources-resolved/*">
            <xsl:sort select="index-of($tan:src-ids, @src)"/>
            <xsl:variable name="this-src-id" select="@src"/>
            <xsl:variable name="this-work" select="tan:head/tan:work" as="element()?"/>
            <xsl:variable name="this-work-vocab" select="tan:element-vocabulary($this-work)"/>
            <work xmlns="tag:textalign.net,2015:ns">
                <xsl:copy-of select="$this-src-id"/>
                <xsl:copy-of select="$this-work-vocab/(tan:item, tan:work)/*"/>
            </work>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="valid-srcs-by-work" select="tan:group-elements-by-IRI($valid-src-work-vocab)"/>
    
    <!-- We accept as valid source ids for the primary merge only candidates from the first work group. -->
    <xsl:variable name="valid-first-work-src-ids"
        select="$valid-srcs-by-work[1]/*/@src[tan:filename-satisfies-regexes(., $src-ids-must-match-regex, $src-ids-must-not-match-regex)]"/>
    
    <!-- First, go through any <alias>es and build a grouping pattern for the chosen work. -->
    <xsl:variable name="alias-based-group-and-sort-pattern" as="element()">
        <source-pattern xmlns="tag:textalign.net,2015:ns">
            <xsl:apply-templates select="$tan:head/tan:vocabulary-key"
                mode="build-source-group-and-sort-pattern">
                <xsl:with-param name="idrefs-to-process" select="$sort-and-group-by-what-alias-idrefs"/>
            </xsl:apply-templates>
        </source-pattern>
    </xsl:variable>

    <!-- Now add the alias-based grouping pattern to any sources for the chosen work that already aren't
    covered by alias groups. -->
    <xsl:variable name="source-group-and-sort-pattern" as="element()">
        <!-- This variable creates a master pattern that will be used to group and sort table columns -->
        <source-pattern xmlns="tag:textalign.net,2015:ns">
            <xsl:apply-templates select="$alias-based-group-and-sort-pattern/*"
                mode="build-source-group-and-sort-pattern"/>
            <xsl:for-each
                select="$valid-first-work-src-ids[not(. = $alias-based-group-and-sort-pattern//tan:idref)]">
                <xsl:variable name="this-pos" select="position()"/>
                <idref>
                    <xsl:if test="$imprint-color-css">
                        <xsl:variable name="this-color-position"
                            select="((count($alias-based-group-and-sort-pattern/*) + $this-pos) mod $primary-color-array-size) + 1"
                        />
                        <xsl:variable name="this-color" select="array:get($primary-color-array, $this-color-position)"/>
                        <xsl:attribute name="color"
                            select="
                                'rgba(' || string-join((for $i in $this-color
                                return
                                    format-number($i, '0.0')), ', ') || ')'"
                        />
                    </xsl:if>
                    <xsl:value-of select="."/>
                </idref>
            </xsl:for-each>
        </source-pattern>
    </xsl:variable>

    <xsl:variable name="alias-names" as="element()*" select="$source-group-and-sort-pattern//tan:alias"/>
    <xsl:variable name="src-id-sequence" as="element()*" select="$source-group-and-sort-pattern//tan:idref"/>


    <xsl:mode name="build-source-group-and-sort-pattern" on-no-match="shallow-copy"/>

    <xsl:template match="tan:vocabulary-key" mode="build-source-group-and-sort-pattern">
        <!-- This template turns the <alias>es in a <vocabulary-key> into a structured hierarchy consisting of <group> + <alias> and <idref> -->
        <xsl:param name="idrefs-to-process" as="xs:string*"/>
        <xsl:param name="idrefs-already-processed" as="xs:string*"/>
        <xsl:variable name="this-element" select="."/>
        <xsl:variable name="these-aliases" select="tan:alias"/>
        <xsl:for-each select="$idrefs-to-process">
            <xsl:variable name="this-idref" select="."/>
            <xsl:variable name="next-alias" select="$these-aliases[(@xml:id, @id) = $this-idref][1]"/>
            <xsl:variable name="next-idrefs"
                select="tokenize(normalize-space($next-alias/@idrefs), ' ')"/>
            <xsl:choose>
                <xsl:when test="not(exists($next-alias)) and 
                    ($this-idref = $valid-first-work-src-ids or $let-alias-groups-equate-works)">
                    <idref xmlns="tag:textalign.net,2015:ns">
                        <xsl:value-of select="."/>
                    </idref>
                </xsl:when>
                <xsl:when test="not(exists($next-alias))"/>
                <xsl:when test="exists($next-idrefs)">
                    <group xmlns="tag:textalign.net,2015:ns">
                        <alias>
                            <xsl:value-of select="$this-idref"/>
                        </alias>
                        <xsl:apply-templates select="$this-element" mode="#current">
                            <xsl:with-param name="idrefs-to-process" select="$next-idrefs"/>
                            <xsl:with-param name="idrefs-already-processed"
                                select="$idrefs-already-processed, $this-idref"/>
                        </xsl:apply-templates>
                    </group>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    <!-- Deeply skip groups that have no valid idrefs -->
    <xsl:template match="tan:group[not($let-alias-groups-equate-works) 
        and not(descendant::tan:idref[. = $valid-first-work-src-ids])]"
        priority="1"
        mode="build-source-group-and-sort-pattern"/>
    <!-- Add a standard alias id, and perhaps color value, to assist later processing -->
    <xsl:template match="tan:group[tan:alias] | tan:idref" mode="build-source-group-and-sort-pattern">
        <xsl:param name="inherited-color" as="xs:double*"/>
        <xsl:variable name="this-pos" select="count(preceding-sibling::*[not(self::tan:alias)]) + 1"/>
        <xsl:variable name="this-color-array" as="array(*)">
            <xsl:choose>
                <xsl:when test="self::tan:idref and exists($inherited-color)">
                    <xsl:sequence select="$terminal-color-array"/>
                </xsl:when>
                <xsl:when test="exists($inherited-color)">
                    <xsl:sequence select="$secondary-color-array"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$primary-color-array"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="this-color-position"
            select="$this-pos mod array:size($this-color-array) + 1"/>
        <xsl:variable name="this-color" select="array:get($this-color-array, $this-color-position)"
        />
        <xsl:variable name="new-color"
            select="
                if (exists($inherited-color)) then
                    tan:blend-colors($inherited-color, $this-color, $color-blend-midpoint)
                else
                    $this-color"
        />
        <xsl:variable name="group-pos-values"
            as="xs:string+"
            select="
                for $i in ancestor-or-self::tan:group
                return
                    string(count($i/preceding-sibling::*[not(self::tan:alias)]) + 1)"
        />
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="self::tan:group">
                <xsl:attribute name="alias-id"
                    select="concat('alias--', string-join($group-pos-values, '--'))"/>
            </xsl:if>
            <xsl:if test="$imprint-color-css">
                <xsl:attribute name="color"
                    select="
                        'rgba(' || string-join((for $i in $new-color
                        return
                            format-number($i, '0.0')), ', ') || ')'"
                />
            </xsl:if>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="inherited-color" select="$new-color"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    

    <!-- PASS 1 -->
    <!-- This pass is devoted to anything that needs to be dealt with before merging: filtering out 
        content; dealing with TEI; making the sources look like the original. If you have to filter stuff
        out you might want to consider using <adjustments> in the class 2 file.
    -->
    
    <xsl:variable name="input-pass-1" as="document-node()*">
        <xsl:apply-templates select="$tan:self-expanded[tan:TAN-T]" mode="input-pass-1"/>
    </xsl:variable>


    <xsl:mode name="input-pass-1" on-no-match="shallow-copy"/>

    <xsl:template match="/" mode="input-pass-1">
        <xsl:variable name="this-src-id" select="*/@src"/>
        <xsl:variable name="this-lang" select="*/tan:body/@xml:lang"/>
        <xsl:variable name="src-is-ok" select="$this-src-id = $source-group-and-sort-pattern//tan:idref"/>
        <xsl:variable name="lang-is-ok"
            select="tan:satisfies-regexes($this-lang, $main-langs-must-match-regex, $main-langs-must-not-match-regex)"/>
        <xsl:variable name="this-class" select="tan:class-number(.)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'src id: ', $this-src-id"/>
            <xsl:message select="'lang: ', $this-lang"/>
            <xsl:message select="'src is ok: ', $src-is-ok"/>
            <xsl:message select="'lang is ok: ', $lang-is-ok"/>
        </xsl:if>
        
        <xsl:if test="$src-is-ok and $lang-is-ok and ($this-class = 1)">
            <xsl:document>
                <xsl:apply-templates mode="#current"/>
            </xsl:document>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:source[not(*)]" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of
                select="tan:element-vocabulary(.)/tan:item/(tan:IRI, tan:name[not(@norm)], tan:desc)"
            />
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:name[@norm]" mode="input-pass-1"/>
    <xsl:template match="tan:vocabulary" mode="input-pass-1">
        <xsl:comment><xsl:value-of select="concat(name(.), ' has been truncated')"/></xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <xsl:copy-of select="tan:shallow-copy(.)"/>
    </xsl:template>
    <xsl:template match="tan:skip | tan:rename | tan:equate | tan:reassign" mode="input-pass-1">
        <xsl:if test="not($suppress-display-of-adjustment-actions = true())">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <!--<xsl:template match="tan:body/tan:div" priority="1" mode="input-pass-1">
        <xsl:variable name="these-ns" select="tan:n"/>
        <xsl:variable name="these-div-types" as="xs:string+"
            select="tan:type, tokenize(normalize-space(@type), ' ')"/>
        <xsl:variable name="ns-are-ok" as="xs:boolean"
            select="
                some $i in $these-ns
                    satisfies tan:satisfies-regexes($i, $level-1-div-ns-must-match-regex, $level-1-div-ns-must-not-match-regex)"/>
        <xsl:variable name="div-types-are-ok" as="xs:boolean"
            select="
                not(exists($these-div-types))
                or
                ((some $i in $these-div-types
                    satisfies tan:satisfies-regexes($i, $div-types-must-match-regex, ()))
                and
                (every $j in $these-div-types
                    satisfies tan:satisfies-regexes($j, (), $div-types-must-not-match-regex)))"
        />
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'ns: ', $these-ns"/>
            <xsl:message select="'div types: ', $these-div-types"/>
            <xsl:message select="'some @n is ok: ', $ns-are-ok"/>
            <xsl:message select="'some @type is ok: ', $div-types-are-ok"/>
        </xsl:if>
        
        <xsl:if test="$ns-are-ok and $div-types-are-ok">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:copy-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                <xsl:choose>
                    <xsl:when test="not(tei:*)">
                        <xsl:apply-templates mode="#current"/>
                    </xsl:when>
                    <xsl:when test="$tei-should-be-plain-text">
                        <xsl:apply-templates select="node() except tei:*" mode="#current"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="node() except text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:copy>
        </xsl:if>
    </xsl:template>-->
    
    <xsl:template match="tan:div" mode="input-pass-1">
        <xsl:variable name="this-depth" as="xs:integer" select="count(ancestor-or-self::tan:div)"/>
        <xsl:variable name="these-ns" select="tan:n"/>
        <xsl:variable name="ns-are-ok" as="xs:boolean" select="
                ($this-depth ne 1) or
                (some $i in $these-ns
                    satisfies tan:satisfies-regexes($i, $level-1-div-ns-must-match-regex, $level-1-div-ns-must-not-match-regex))"
        />
        
        <xsl:variable name="these-div-types" as="xs:string+"
            select="tan:type, tokenize(normalize-space(@type), ' ')"/>
        <xsl:variable name="div-types-are-ok" as="xs:boolean" select="
                not(exists($these-div-types))
                or
                ((some $i in $these-div-types
                    satisfies tan:satisfies-regexes($i, $div-types-must-match-regex, ()))
                and
                (every $j in $these-div-types
                    satisfies tan:satisfies-regexes($j, (), $div-types-must-not-match-regex)))"
        />
        <xsl:variable name="is-leaf" as="xs:boolean" select="not(exists(tan:div))"/>
        <xsl:variable name="these-refs" as="xs:string+" select="tan:ref/text()"/>
        <xsl:variable name="refs-are-ok" as="xs:boolean" select="
                not($is-leaf) or
                (some $i in $these-refs
                    satisfies tan:satisfies-regexes($i, $leaf-div-refs-must-match-regex, ())
                    and
                    (every $j in $these-refs
                        satisfies tan:satisfies-regexes($j, (), $leaf-div-refs-must-not-match-regex)))"
        />
        
        <xsl:variable name="this-is-tei" as="xs:boolean" select="exists(tei:*)"/>
        
        <xsl:if test="$ns-are-ok and $div-types-are-ok and $refs-are-ok">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:copy-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
                <xsl:if test="$this-is-tei">
                    <xsl:apply-templates select="node() except (tei:* | text())" mode="#current"/>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="not($this-is-tei)">
                        <xsl:apply-templates mode="#current"/>
                    </xsl:when>
                    <xsl:when test="$tei-should-be-plain-text">
                        <xsl:value-of select="text()"/>
                    </xsl:when>
                    <xsl:when test="$omit-tei-elements-without-text">
                        <xsl:variable name="tei-revised" as="element()*">
                            <xsl:apply-templates select="tei:*" mode="omit-tei-without-text"/>
                        </xsl:variable>
                        <tei xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:apply-templates select="$tei-revised" mode="#current"/>
                        </tei>
                    </xsl:when>
                    <xsl:otherwise>
                        <tei xmlns="http://www.tei-c.org/ns/1.0">
                            <xsl:apply-templates select="tei:*" mode="#current"/>
                        </tei>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:div/tan:type/*" mode="input-pass-1">
        <xsl:if test="not($proportionately-reallocate-copied-divs)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!--<xsl:template match="tan:div[tei:*]" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
            <xsl:apply-templates select="node() except (tei:* | text())" mode="#current"/>
            <xsl:choose>
                <xsl:when test="$tei-should-be-plain-text">
                    <xsl:value-of select="text()"/>
                </xsl:when>
                <xsl:when test="$omit-tei-elements-without-text">
                    <xsl:variable name="tei-revised" as="element()*">
                        <xsl:apply-templates select="tei:*" mode="omit-tei-without-text"/>
                    </xsl:variable>
                    <tei xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:apply-templates select="$tei-revised" mode="#current"/>
                    </tei>
                </xsl:when>
                <xsl:otherwise>
                    <tei xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:apply-templates select="tei:*" mode="#current"/>
                    </tei>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>-->
    
    
    <xsl:mode name="omit-tei-without-text" on-no-match="shallow-copy"/>
    
    <xsl:template match="tei:*[not(descendant::text())]" mode="omit-tei-without-text"/>
    
    
    <xsl:template match="tei:app[not(tei:lem)]" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <lem xmlns="http://www.tei-c.org/ns/1.0">
                <xsl:value-of select="$marker-for-tei-app-without-lem"/>
            </lem>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:note | tei:add" mode="input-pass-1">
        <div class="wrapper">
            <div class="signal hideNext">
                <xsl:choose>
                    <xsl:when test="name(.) = 'add'">
                        <xsl:value-of select="$tei-add-signal-default"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$tei-note-signal-default"/>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:*[@cRef][@rend]" mode="input-pass-1">
        <!-- @cRef is normally worth promoting to an element, but not if there is already a 
            competing rendition in @rend -->
        <xsl:copy>
            <xsl:copy-of select="@* except @cRef"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>



    <!-- PASS 1b: eliminate any divs whose leaf divs have been eliminated -->
    <xsl:variable name="input-pass-1b" as="document-node()*">
        <xsl:apply-templates select="$input-pass-1" mode="delete-divs-without-leaf-divs"/>
    </xsl:variable>
    
    
    <xsl:mode name="delete-divs-without-leaf-divs" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:div | tan:body" mode="delete-divs-without-leaf-divs">
        <xsl:variable name="divs-from-here-down" select="descendant-or-self::tan:div"/>
        <xsl:variable name="tei-marker" select="descendant::tei:*"/>
        <xsl:variable name="text-marker" select="matches(., '\S')"/>
        <xsl:variable name="is-or-has-leaf-div" select="exists($tei-marker) or exists($text-marker)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'processing: ', tan:shallow-copy(.)"/>
            <xsl:message select="'is or has leaf div: ', $is-or-has-leaf-div"/>
            <xsl:message select="'tei marker: ', $tei-marker"/>
            <xsl:message select="'text marker: ', $text-marker"/>
        </xsl:if>
        
        <xsl:if test="$is-or-has-leaf-div">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    
    

    <!-- PASS 2: Merge the sources -->

    <xsl:variable name="input-pass-2" as="document-node()?">
        <xsl:choose>
            <xsl:when test="(count($input-pass-1b) lt 2) and $terminate-if-fewer-than-two-sources">
                <xsl:message select="'Fewer than two input documents detected, so terminating.'"
                    terminate="yes"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="tan:merge-expanded-docs($input-pass-1b)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- PASS 2B: REALLOCATE DISTRIBUTED DIVS -->
    <xsl:variable name="input-pass-2b" as="document-node()?">
        <xsl:choose>
            <xsl:when test="$preserve-distributed-copies-of-divs">
                <xsl:sequence select="$input-pass-2"/>
            </xsl:when>
            <xsl:when test="$proportionately-reallocate-copied-divs">
                <xsl:variable name="proportional-reallocation-map-1" as="map(*)">
                    <xsl:map>
                        <xsl:apply-templates select="$input-pass-2"
                            mode="proportional-reallocation-map"/>
                    </xsl:map>
                </xsl:variable>
                <xsl:variable name="pr1-map-keys" select="map:keys($proportional-reallocation-map-1)" as="xs:string*"/>
                <xsl:variable name="proportional-reallocation-map-2" as="map(*)">
                    <xsl:map>
                        <xsl:for-each-group select="$pr1-map-keys[contains(., '-')]" group-by="tokenize(., '-')[1]">
                            <xsl:variable name="this-id" select="current-grouping-key()"/>
                            <xsl:variable name="these-avg-string-lengths" as="xs:decimal*" select="
                                    for $i in (1 to count(current-group()))
                                    return
                                        $proportional-reallocation-map-1($this-id || '-' || string($i))"
                            />
                            <xsl:variable name="string-length-sum" select="sum($these-avg-string-lengths)" as="xs:decimal?"/>
                            <xsl:variable name="these-portions" select="tan:numbers-to-portions($these-avg-string-lengths)" as="xs:decimal*"/>
                            <!--<xsl:variable name="these-portions" as="xs:decimal*" select="
                                    for $i in $these-string-lengths
                                    return
                                        $i div $string-length-sum"/>-->
                            <xsl:variable name="this-text" select="$proportional-reallocation-map-1($this-id)" as="xs:string?"/>
                            <xsl:variable name="these-text-fragments" as="xs:string*" select="
                                    tan:segment-string($this-text, $these-portions)"
                            />
                            <xsl:map-entry key="current-grouping-key()">
                                <xsl:map>
                                    <xsl:for-each select="$these-text-fragments">
                                        <xsl:map-entry key="position()" select="."/>
                                    </xsl:for-each>
                                </xsl:map>
                            </xsl:map-entry>
                        </xsl:for-each-group> 
                    </xsl:map>
                </xsl:variable>
                <xsl:apply-templates select="$input-pass-2" mode="apply-proportional-reallocation">
                    <xsl:with-param name="allocation-map" tunnel="yes" as="map(*)" select="$proportional-reallocation-map-2"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$input-pass-2" mode="skip-copied-divs"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:mode name="proportional-reallocation-map" on-no-match="shallow-skip"/>
    
    <xsl:template match="*[tan:div[@copy]]" priority="1"  mode="proportional-reallocation-map">
        <xsl:variable name="all-text-lengths" as="xs:integer*">
            <xsl:for-each select="tan:div[not(@copy)]">
                <xsl:variable name="this-text" select="descendant-or-self::tan:div/(text() | tan:tok | tan:non-tok)" as="item()*"/>
                <xsl:sequence select="string-length(string-join($this-text))"/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:for-each select="tan:div[@copy]">
            <xsl:variable name="this-text" select="descendant-or-self::tan:div/(text() | tan:tok | tan:non-tok)" as="item()*"/>
            <xsl:map-entry key="@q || '-' || @copy" select="avg($all-text-lengths)"/>
            <xsl:if test="@copy eq '1'">
                <xsl:map-entry key="@q" select="string-join($this-text)"/>
            </xsl:if>
        </xsl:for-each>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    
    <xsl:mode name="apply-proportional-reallocation" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:div[@copy]" mode="apply-proportional-reallocation">
        <xsl:param name="allocation-map" tunnel="yes" as="map(*)"/>
        <xsl:variable name="this-q" select="@q"/>
        <xsl:variable name="this-copy" select="xs:integer(@copy)" as="xs:integer"/>
        <xsl:variable name="this-map-entry" select="$allocation-map($this-q)" as="map(*)"/>
        <xsl:variable name="this-new-text" select="$this-map-entry($this-copy)" as="xs:string?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- Create an id, so that segments can link to each other -->
            <xsl:attribute name="id" select="@q || '-' || @copy"/>
            <xsl:apply-templates select="node() except (text() | tan:tok | tan:non-tok)"
                mode="#current"/>
            <xsl:value-of select="$this-new-text"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:mode name="skip-copied-divs" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:div[xs:integer(@copy) gt 1]" mode="skip-copied-divs">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="node() except (text() | tan:tok | tan:non-tok | tei:*)"
                mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    

    <!-- PASS 3 -->
    <!-- This pass is devoted to adjusting the merge before the migration to HTML elements. The most
        important part is getting aligned sources into the correct order, and creating the appropriate group 
        labels. -->
    <!-- The heads are constructed hierarchically, because they will form the control that allows the 
        user to hide/show or re-sort sources or groups of sources. But the leafmost texts (versions) in the 
        body are rearranged like a table row (even if we're using <div>s, not <tr>s). We do not want them 
        in a hierarchy. If a user chooses to hide a source, we do not want to see if there are no more 
        shown blocks in a group before deciding whether to turn off the whole group. 
    -->

    <xsl:variable name="input-pass-3" as="document-node()?">
        <xsl:apply-templates select="$input-pass-2b" mode="input-pass-3"/>
    </xsl:variable>
    
    
    <xsl:mode name="input-pass-3" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:TAN-T_merge" mode="input-pass-3">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-- control mechanism -->
            <div class="control">
                <xsl:apply-templates select="$source-group-and-sort-pattern"
                    mode="regroup-and-re-sort-heads">
                    <xsl:with-param name="items-to-group-and-sort" tunnel="yes" select="tan:head"/>
                </xsl:apply-templates>
            </div>
            <xsl:apply-templates select="tan:body" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Let the reader know that a non-leaf div has been renamed. -->
    <xsl:template match="tan:div/tan:adjustments/tan:rename" mode="input-pass-3">
        <div class="{name(.)}">
            <xsl:value-of select="tan:src || ': ' || tan:ref/text()"/>
        </div>
    </xsl:template>
    <xsl:template match="tan:equate[1]" mode="input-pass-3">
        <div class="equate">
            <xsl:value-of select="string-join(../tan:equate/tan:n, ' = ')"/>
        </div>
    </xsl:template>
    <xsl:template match="tan:equate[position() gt 1]" mode="input-pass-3"/>
    
    <!-- Build the version wrapper. -->
    <xsl:template match="tan:div[tan:div[@type = '#version']]" mode="input-pass-3">
        <!-- This template finds a parent of a version, then groups and re-sorts the descendant versions 
            according to the master $source-group-and-sort-pattern -->
        <!-- Such a version wrapper will wind up being table-like or table-row-like, whether that is executed as 
            an html <table> or through CSS. That decision cannot be made at this point. -->
        <!-- This element wraps one or more versions, which are sorted and grouped in the predefined order. -->
        <!-- In addition, descendant class-2 anchors are pulled up and moved to the end. -->
        <xsl:variable name="children-divs" select="tan:div"/>
        <xsl:variable name="sources-to-process" select="distinct-values(tan:src)"/>
        <xsl:variable name="skip-this-div"
            select="
                exists($leaf-div-must-have-at-least-how-many-versions)
                and (count($sources-to-process) lt $leaf-div-must-have-at-least-how-many-versions)"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'This div: ', tan:shallow-copy(.)"/>
            <xsl:message select="'Sources to process: ', $sources-to-process"/>
            <xsl:message select="'Div should be skipped: ', $skip-this-div"/>
        </xsl:if>
        
        <xsl:if test="not($skip-this-div)">
            <xsl:variable name="pre-div-elements-except-n" select="* except (tan:n | tan:div)"/>
            <xsl:variable name="class-2-ref-anchors" select="$children-divs/tan:ref[@q][not(text())]"/>
            <xsl:variable name="class-2-ref-anchors-to-move-here" as="element()*">
                <!-- We do not worry at this point whether the anchor pertains to a work in general or only a specific source. That gets handled later. -->
                <xsl:for-each-group select="$class-2-ref-anchors" group-by="@q">
                    <xsl:sequence select="current-group()[1]"/>
                </xsl:for-each-group> 
            </xsl:variable>
            <xsl:variable name="most-common-div-type" select="
                    if ($add-div-type-to-display-n) then
                        tan:most-common-item(descendant::tan:type)
                    else
                        ()" as="element()*"/>
            
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="class" select="$version-wrapper-class-name"/>
                
                <xsl:apply-templates select="node() except $children-divs" mode="#current">
                    <xsl:with-param name="most-common-div-type" tunnel="yes" select="$most-common-div-type"/>
                </xsl:apply-templates>
                
                <xsl:apply-templates select="$source-group-and-sort-pattern"
                    mode="regroup-and-re-sort-divs">
                    <xsl:with-param name="items-to-group-and-sort" tunnel="yes"
                        select="$children-divs"/>
                    <!--<xsl:with-param name="n-pattern" tunnel="yes" select="$n-pattern"/>-->
                    <xsl:with-param name="qs-to-anchors-to-drop" tunnel="yes"
                        select="$class-2-ref-anchors-to-move-here/@q"/>
                </xsl:apply-templates>
                
                <!-- Class 2 anchors correspond to annotations. Because annotations generally
                fall beside or after the main text (i.e., the main text comes first), we move 
                the ref anchors to the end, here. -->
                <xsl:copy-of select="$class-2-ref-anchors-to-move-here"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    

    <xsl:mode name="place-sorted-div" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:ref[not(tan:n)][@q]" mode="input-pass-3 place-sorted-div">
        <!-- between the version wrapper <div> and this template, we calculate @qs for anchors that
        pertain to works, not merely, versions, and we drop them from here, their version location. -->
        <xsl:param name="qs-to-anchors-to-drop" tunnel="yes" as="xs:string*"/>
        <xsl:if test="not(@q = $qs-to-anchors-to-drop)">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:ref[tan:n] | tan:orig-ref" mode="input-pass-3 place-sorted-div">
        <xsl:variable name="this-is-version" select="../@type = '#version'" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="$suppress-refs"/>
            <xsl:when test="$suppress-version-refs and $this-is-version"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tan:div/tan:n" mode="input-pass-3 place-sorted-div">
        <xsl:param name="most-common-div-type" tunnel="yes" select="../tan:type[1]" as="element()?"/>
        <xsl:choose>
            <xsl:when test="$suppress-ns"/>
            <xsl:otherwise>
                <xsl:if test="not(exists(preceding-sibling::tan:n)) and $add-display-n">
                    <display-n xmlns="tag:textalign.net,2015:ns">
                        <xsl:if test="$add-div-type-to-display-n">
                            <xsl:value-of select="$most-common-div-type || ' '"/>
                        </xsl:if>
                        <xsl:value-of select="(../(@orig-n, @n)[1], .)[1]"/>
                    </display-n>
                </xsl:if>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tan:body/text() | tan:div/text()" mode="input-pass-3 place-sorted-div">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="tan:ref/text()" mode="input-pass-3 place-sorted-div">
        <xsl:variable name="constituent-ns" select="../tan:n"/>
        <xsl:variable name="new-ns" as="xs:string*">
            <xsl:for-each select="$constituent-ns">
                <xsl:variable name="this-pos" select="position()"/>
                <xsl:variable name="this-n" select="."/>
                <xsl:choose>
                    <xsl:when
                        test="$this-pos = $levels-to-convert-to-aaa and $this-n castable as xs:integer">
                        <xsl:value-of select="tan:int-to-aaa(xs:integer($this-n))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($new-ns, ' ')"/>
    </xsl:template>
    
    
    
    <!-- Grouping and sorting sources: place aligned source-specific parts of a TAN-A_merge file into a particular grouping or sort order -->
    <!-- This set of templates is supposed to apply to $source-group-and-sort-pattern, which is an XML fragment consisting of <group>, <alias>, and <idref> -->
    <!-- <idref> contains the idref to a source; <alias> is essentially just the name of the <group> it is a child of -->
    
    
    <xsl:mode name="regroup-and-re-sort-divs" on-no-match="shallow-copy"/>
    <xsl:mode name="regroup-and-re-sort-heads" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:source-pattern" mode="regroup-and-re-sort-divs regroup-and-re-sort-heads">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:group" mode="regroup-and-re-sort-heads">
        <xsl:param name="items-to-group-and-sort" tunnel="yes" as="element()*"/>
        
        <xsl:variable name="these-idrefs" select="tan:idref"/>
        
        <xsl:variable name="descendant-idrefs" select=".//tan:idref"/>
        <xsl:variable name="items-yet-to-place"
            select="$items-to-group-and-sort[(tan:src, @src) = $descendant-idrefs]"/>
        <xsl:variable name="these-class-values" select="string-join((@alias-id), ' ')"/>
        
        <xsl:if test="exists($items-yet-to-place) or $fill-defective-merges">
            <xsl:copy>
                <xsl:if test="string-length($these-class-values) gt 0">
                    <xsl:attribute name="class" select="$these-class-values"/>
                </xsl:if>
                <xsl:copy-of select="tan:alias"/>
                <div class="group-items">
                    <xsl:apply-templates select="* except tan:alias" mode="#current">
                        <xsl:with-param name="items-to-group-and-sort" tunnel="yes"
                            select="$items-yet-to-place"/>
                    </xsl:apply-templates>
                </div>

            </xsl:copy>
        </xsl:if>

    </xsl:template>
    
    <xsl:template match="tan:group" mode="regroup-and-re-sort-divs">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:alias" mode="regroup-and-re-sort-heads">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="tan:alias" mode="regroup-and-re-sort-divs"/>
    
    <xsl:template match="tan:idref" mode="regroup-and-re-sort-heads">
        <xsl:param name="items-to-group-and-sort" as="element()*" tunnel="yes"/>
        <xsl:variable name="this-idref" select="."/>
        <xsl:variable name="those-items" select="$items-to-group-and-sort[(tan:src, @src) = $this-idref]"/>
        <xsl:variable name="filler-element" as="element()">
            <head type="#version" class="filler" xmlns="tag:textalign.net,2015:ns">
                <src>
                    <xsl:value-of select="$this-idref"/>
                </src>
                <xsl:text> </xsl:text>
            </head>
        </xsl:variable>
        <xsl:apply-templates select="$those-items" mode="#current"/>
        <xsl:if test="not(exists($those-items))">
            <xsl:copy-of select="$filler-element"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:idref" mode="regroup-and-re-sort-divs">
        <xsl:param name="items-to-group-and-sort" as="element()*" tunnel="yes"/>
        <!--<xsl:param name="n-pattern" as="element()*" tunnel="yes"/>-->
        <xsl:variable name="this-idref" select="."/>
        <xsl:variable name="those-divs" select="$items-to-group-and-sort[(tan:src, @src) = $this-idref]"/>
        <xsl:variable name="filler-element" as="element()">
            <div type="#version" class="filler" xmlns="tag:textalign.net,2015:ns">
                <src>
                    <xsl:value-of select="$this-idref"/>
                </src>
                <xsl:text> </xsl:text>
            </div>
        </xsl:variable>
        <xsl:variable name="items-to-group-and-sort" as="element()*"
            select="
                if (exists($those-divs)) then
                    $those-divs
                else
                    $filler-element"
        />
        <xsl:variable name="these-alias-ids" select="ancestor::*[@alias-id]/@alias-id"/>
        
        <xsl:if test="exists($those-divs) or $fill-defective-merges">
            <!-- Within a version-wrapper, a given source could easily have many <div>s, so we wrap them up (even singletons) as an <item> -->
            <!-- Each item is given a class value not just for the source id, but for all alias ids, to facilitate toggling divs. -->
            <item xmlns="tag:textalign.net,2015:ns">
                <xsl:attribute name="class" select="string-join(($this-idref, $these-alias-ids), ' ')"/>
                <src>
                    <xsl:value-of select="$this-idref"/>
                </src>
                <xsl:apply-templates select="$items-to-group-and-sort" mode="place-sorted-div">
                    <xsl:with-param name="src-idref" tunnel="yes" select="$this-idref"/>
                    <xsl:with-param name="item-group-count" tunnel="yes" select="count($items-to-group-and-sort)"/>
                </xsl:apply-templates>
            </item>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="tan:div" mode="place-sorted-div">
        <xsl:param name="extra-divs-of-interest" tunnel="yes" as="element()*"/>
        <xsl:param name="src-idref" tunnel="yes" as="xs:string"/>
        <xsl:param name="context-ns" tunnel="yes" as="element()*"/>
        <xsl:param name="item-group-count" tunnel="yes" as="xs:integer" select="1"/>
        
        <!-- Filter out any deeper <div>s that are not germane to the source being processed. -->
        <xsl:variable name="discard-this-div" select="exists(@src) and not(@src eq $src-idref)"/>
        <xsl:variable name="this-copy" as="xs:integer?" select="xs:integer(@copy)"/>
        <xsl:variable name="this-copy-count" as="xs:integer?" select="xs:integer(@copy-count)"/>
        <xsl:variable name="prev-frag-link" as="element()?">
            <xsl:if test="$this-copy gt 1">
                <div xmlns="http://www.w3.org/1999/xhtml" class="prevFrag">
                    <a href="#{@q}-{$this-copy - 1}">…</a>
                </div>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="next-frag-link" as="element()?">
            <xsl:if test="$this-copy lt $this-copy-count">
                <div xmlns="http://www.w3.org/1999/xhtml" class="prevFrag">
                    <a href="#{@q}-{$this-copy + 1}">…</a>
                </div>
            </xsl:if>
        </xsl:variable>
        
        <!-- If a div was subject to an equate action, because it's a specific version, retreive that info. -->
        <xsl:variable name="this-q" select="@q"/>
        <xsl:variable name="fetch-src-qualifier" as="xs:boolean" select="($item-group-count gt 1) and (count(tan:ref) gt 1)"/>
        <!-- Normally this would be element()?, but there is the possibility that
            a class 1 source is fed in multiple times, in which q-ref would hit multiple
            targets. TODO: disallow the same source to appear multiple times. -->
        <xsl:variable name="this-div-rewound" select="
                if ($fetch-src-qualifier) then
                    (for $i in $input-pass-1
                    return
                        key('tan:q-ref', $this-q, $i))
                else
                    ()" as="element()*"/>
        <xsl:variable name="these-equate-original-ns"
            select="$this-div-rewound/ancestor-or-self::tan:div[tan:equate]/(@orig-n, @n)[1]"/>
        
        <xsl:if test="not($discard-this-div)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:if test="count($these-equate-original-ns) gt 0">
                    <xsl:attribute name="src-qualifier"
                        select="string-join($these-equate-original-ns, ', ')"/>
                </xsl:if>
                <xsl:choose>
                    <!-- If we're dealing with a div deeper than the <td> level, there are one or more <div>s that 
                        need to be consolidated. The first one, the context here, contains the <n> value of the next
                        level down. It is going to get wrapped with its siblings, represented as $extra-divs-of-interest.
                        So we need to signal that the material has been consolidated via a @class value, then we need
                        to insert the tan:n value that corresponds to what is going to be in the <td>.
                    -->
                    <xsl:when test="exists($extra-divs-of-interest)">
                        <xsl:attribute name="class" select="'consolidated'"/>
                        <xsl:choose>
                            <xsl:when test="tan:n = $context-ns">
                                <xsl:apply-templates select="tan:n" mode="#current"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="$context-ns" mode="#current"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:apply-templates select="tan:* except (tan:div | tan:n)" mode="#current"/>
                        <xsl:copy-of select="$prev-frag-link"/>
                        <xsl:for-each select="self::*, $extra-divs-of-interest">
                            <!-- In this method, we make sure to drop <n> and other metadata that could be misleading in the next step -->
                            <xsl:copy>
                                <xsl:copy-of select="@*"/>
                                <xsl:apply-templates select="(tan:div, text(), tei:*)"
                                    mode="#current">
                                    <xsl:with-param name="extra-divs-of-interest" tunnel="yes"
                                        select="()"/>
                                </xsl:apply-templates>
                            </xsl:copy>
                        </xsl:for-each>
                        <xsl:copy-of select="$next-frag-link"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="text-content-nodes" select="text() | tan:div | tan:tok | tan:non-tok" as="item()*"/>
                        
                        <xsl:apply-templates select="node() except $text-content-nodes"
                            mode="#current"/>
                        <xsl:copy-of select="$prev-frag-link"/>
                        <xsl:apply-templates select="$text-content-nodes" mode="#current"/>
                        <xsl:copy-of select="$next-frag-link"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:src" mode="place-sorted-div">
        <xsl:param name="src-idref" tunnel="yes" as="xs:string"/>
        <xsl:if test=". eq $src-idref">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:rename" mode="place-sorted-div">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="'(' || string-join(tan:ref/tan:n, ' ') || ')'"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:reassigned" mode="place-sorted-div">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="tan:reassigned/tan:to" mode="place-sorted-div"/>
    <xsl:template match="tan:passage" mode="place-sorted-div">
        <!-- We need to treat a <passage> as a notification that text has moved from one place to another. -->
        <!-- We assume that we're interested only in a notification for the HTML page, not all the data that
        is inside the passage, so we pare down here. -->
        <xsl:variable name="is-missing-text-marker" select="parent::tan:reassigned"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>

            <!-- If this is where text has been reassigned, indicate that it has come from somewhere else -->
            <xsl:if test="not($is-missing-text-marker)">
                <xsl:value-of select="'+ ' || @ref || ': '"/>
            </xsl:if>
            
            <!-- express in succinct form the range of text that has been moved -->
            <xsl:apply-templates select="tan:from-tok | tan:through-tok" mode="#current"/>
            
            <!-- If this marks text that has been removed, indicate where it has gone -->
            <xsl:if test="$is-missing-text-marker">
                <xsl:value-of select="' → ' || following-sibling::tan:to/@ref"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:from-tok | tan:through-tok" mode="place-sorted-div">
        <xsl:variable name="best-pos"
            select="
                if (self::tan:from-tok) then
                    tan:pos[1]
                else
                    tan:pos[last()]"
        />
        <xsl:choose>
            <xsl:when test="self::tan:from-tok and $best-pos eq '1' and tan:rgx = '.+'">
                <xsl:value-of select="'[start] '"/>
            </xsl:when>
            <xsl:when test="self::tan:through-tok and $best-pos eq 'last' and tan:rgx = '.+'">
                <xsl:value-of select="' [end]'"/>
            </xsl:when>
            <xsl:when test="$best-pos castable as xs:integer and xs:integer($best-pos) gt 1">
                <xsl:value-of select="(tan:val, tan:rgx)[1] || ' (' || tan:pos || ')'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="(tan:val, tan:rgx)[1]"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="self::tan:from-tok">
            <xsl:text> … </xsl:text>
        </xsl:if>
    </xsl:template>
    
    
    
    

    <!-- PASS 3 -->
    <!-- make adjustments in the conversion from TAN to HTML -->
    
    
    <xsl:variable name="input-pass-3a" as="document-node()?">
        <xsl:apply-templates select="$input-pass-3" mode="tan-to-html-prepass-1"/>
    </xsl:variable>
    
    
    <xsl:mode name="tan-to-html-prepass-1" on-no-match="shallow-copy"/>
    
    <xsl:template match="*" mode="tan-to-html-prepass-1">
        <!-- Prepare html @class -->
        <xsl:variable name="this-namespace" select="namespace-uri(.)"/>
        <xsl:variable name="parent-namespace" select="namespace-uri(..)"/>
        <xsl:variable name="other-class-values-to-add" as="xs:string*">
            <xsl:if test="tan:regex-is-valid($elements-to-be-given-class-hidden-regex)
                and matches(name(.), $elements-to-be-given-class-hidden-regex)">hidden</xsl:if>
            <xsl:for-each select="tan:cf, tan:see-q">
                <xsl:sequence select="'idref--' || ."/>
            </xsl:for-each>
            <xsl:for-each select="distinct-values(tan:src)">
                <xsl:sequence select="'src--' || ."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="all-class-attribute-values" as="xs:string*"
            select="tokenize(@class, ' '), $other-class-values-to-add"/>
        <!-- get rid of illegal characters for the @class attribute, make sure there's no repetition -->
        <xsl:variable name="all-class-attribute-values-normalized" select="
                distinct-values(for $i in $all-class-attribute-values
                return
                    replace($i, $tan:excluded-class-characters-regex, ''))"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="exists($all-class-attribute-values)">
                <xsl:attribute name="class" select="string-join($all-class-attribute-values-normalized, ' ')"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
        
    </xsl:template>
    
    <!-- Skip select attributes that have already had vocabulary imprinted -->
    <xsl:template match="*[tan:licensor]/@licensor" mode="tan-to-html-prepass-1"/>
    <!-- Get rid of other unnecessary attributes -->
    <xsl:template match="@attr | tan:tok/@n | tan:non-tok/@n | tan:tok/@pos | tan:non-tok/@pos |
        tan:ref/@src"
        mode="tan-to-html-prepass-1"/>
    
    
    
    
    <xsl:variable name="input-pass-3b" as="document-node()?" select="tan:prepare-to-convert-to-html($input-pass-3a)"/>
    
    <xsl:variable name="input-pass-3c" as="document-node()?">
        <xsl:apply-templates select="$input-pass-3b" mode="tan-to-html-prepass-2"/>
    </xsl:variable>
    
    

    <!-- It will be a common practice to tag an html <div> according to the class types of the source id; the following functions expedite that process -->
    <xsl:function name="tan:class-val-for-src-id" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: all relevant class values -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:variable name="results" as="xs:string*">
            <!--<xsl:value-of select="tan:class-val-for-alias-group($src-id)"/>-->
            <xsl:value-of select="tan:class-val-for-source($src-id)"/>
            <xsl:value-of select="tan:class-val-for-group-item-number($src-id)"/>
        </xsl:variable>
        <xsl:value-of select="string-join($results, ' ')"/>
    </xsl:function>
    <xsl:function name="tan:class-val-for-alias-group" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: the class marking the alias name and position number -->
        <!-- If no alias can be found, nothing is returned -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:variable name="this-pattern-match" select="tan:get-pattern-match($src-id)"/>
        <!-- There should only be one value of $this-alias, but we set it up as if there 
        might be more, just in case we wish to expand to multiple aliases in the future. -->
        <xsl:variable name="this-alias"
            select="
                for $i in $this-pattern-match/preceding-sibling::tan:alias
                return
                    'alias--' || $i"
        />
        <!--<xsl:variable name="this-alias-pos" select="index-of($alias-names, $this-alias)"/>-->
        <xsl:variable name="this-alias-id" select="$this-pattern-match/../@alias-id"/>
        <!--<xsl:if test="exists($this-alias)">
            <!-\-<xsl:value-of
                select="concat('alias-\\-', string($this-alias-pos), ' alias-\\-', $this-alias)"/>-\->
            <xsl:value-of
                select="concat('alias-\-', string($this-alias-pos), ' alias-\-', $this-alias)"/>
        </xsl:if>-->
        <!--<xsl:value-of select="string-join(($this-alias, $this-alias-id), ' ')"/>-->
        <xsl:value-of select="string-join($this-alias-id, ' ')"/>
    </xsl:function>
    <xsl:function name="tan:class-val-for-group-item-number" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: the class marking the item's position in the group -->
        <!-- If no pattern idref can be found, nothing is returned -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:variable name="this-pattern-match" select="tan:get-pattern-match($src-id)"/>
        <xsl:variable name="preceding-items"
            select="$this-pattern-match/preceding-sibling::tan:idref"/>
        <xsl:if test="exists($this-pattern-match)">
            <xsl:value-of select="concat('groupitem--', string(count($preceding-items) + 1))"/>
        </xsl:if>
    </xsl:function>
    <xsl:function name="tan:class-val-for-source" as="xs:string?">
        <!-- Input: a source id -->
        <!-- Output: the class marking the alias name and position number -->
        <!-- If no idref can be found, nothing is returned -->
        <xsl:param name="src-id" as="xs:string?"/>
        <xsl:value-of select="concat('src--', $src-id)"/>
    </xsl:function>
    <xsl:function name="tan:get-pattern-match" as="item()*">
        <!-- Input: source ids -->
        <!-- Output: the corresponding <idref> nodes in the source group and sort pattern -->
        <xsl:param name="src-ids" as="xs:string*"/>
        <xsl:sequence select="$source-group-and-sort-pattern//tan:idref[. = $src-ids]"/>
    </xsl:function>


    <xsl:mode name="tan-to-html-prepass-2" on-no-match="shallow-copy"/>

    <xsl:template match="tan:TAN-T_merge" mode="tan-to-html-prepass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="$tan:self-resolved/*/tan:head/tan:name[not(@norm)]"
                mode="tan-to-html-prepass-2-title"/>
            <xsl:apply-templates select="$tan:self-resolved/*/tan:head/tan:desc"
                mode="tan-to-html-prepass-2-title"/>
            <xsl:if test="$add-bibliography">
                <xsl:copy-of select="$source-bibliography"/>
            </xsl:if>
            <hr/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!--<xsl:template match="@q | @id" mode="tan-to-html-prepass-2">
        <xsl:attribute name="id" select="."/>
    </xsl:template>-->
    
    
    
    
    
    <xsl:mode name="tan-to-html-prepass-2-title"/>
    
    
    <xsl:template match="tan:head/tan:name[1]" mode="tan-to-html-prepass-2-title">
        <h1>
            <xsl:if test="exists(@xml:lang)">
                <xsl:attribute name="lang" select="@xml:lang"/>
            </xsl:if>
            <xsl:value-of
                select="
                    if (string-length($preferred-html-title) gt 0) then
                        $preferred-html-title
                    else
                        ."
            />
        </h1>
        <xsl:if test="string-length($preferred-html-subtitle) gt 0">
            <h2>
                <xsl:value-of select="$preferred-html-subtitle"/>
            </h2>
        </xsl:if>
        <xsl:apply-templates select="$introductory-text" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:head/tan:name[position() gt 1]" mode="tan-to-html-prepass-2"/>
    
    <xsl:template match="tan:head/tan:desc" mode="tan-to-html-prepass-2-title">
        <div class="desc title">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>

    <xsl:variable name="source-bibliography" as="element()">
        <div class="bibl">
            <h2 class="label">Bibliography</h2>
            <!-- first, the key -->
            <div class="bibl-key">
                <xsl:for-each select="$src-id-sequence">
                    <xsl:variable name="this-src-id" select="."/>
                    <div class="bibl-key-item">
                        <div class="{tan:class-val-for-alias-group($this-src-id)}">
                            <div class="{tan:class-val-for-src-id($this-src-id)}">
                                <xsl:value-of select="$this-src-id"/>
                            </div>
                        </div>
                        <div class="name">
                            <xsl:value-of
                                select="$input-pass-1/tan:TAN-T[@src = $this-src-id]/tan:head/tan:source/tan:name[not(@common)][1]"
                            />
                        </div>
                    </div>
                </xsl:for-each>
            </div>
            <!-- second, the sorted bibliography -->
            <div class="bibl-body">
                <xsl:for-each-group select="$input-pass-1/tan:TAN-T/tan:head/tan:source"
                    group-by="tan:name[not(@common)][1]">
                    <xsl:sort select="current-grouping-key()"/>
                    <div class="bibl-item">
                        <div class="name">
                            <xsl:value-of select="current-grouping-key()"/>
                        </div>
                        <xsl:for-each-group select="current-group()/tan:desc" group-by=".">
                            <div class="desc">
                                <xsl:value-of select="."/>
                            </div>
                        </xsl:for-each-group>
                    </div>
                </xsl:for-each-group>
            </div>
        </div>
    </xsl:variable>

    <!-- The source controller, now wrapped in a larger options section. -->
    <xsl:template match="html:div[contains-token(@class, 'control')]" mode="tan-to-html-prepass-2"
        priority="1">
        <div class="options">
            <div class="label">Options</div>
            <xsl:copy>
                <xsl:attribute name="class" select="'control-wrapper'"/>
                <div class="label">Sources</div>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="class" select="string-join((@class, 'sortable'), ' ')"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:copy>
            <!-- Display  -->
            <xsl:if test="$add-display-options">
                <div id="display-options-placeholder"/>
            </xsl:if>
            <div class="help">
                <div class="label">Help</div>
                <div>Above, under Sources, are blocks representing the sources, or groups of
                    sources, that make up this parallel edition. Click a box to expand it and
                    see what other groups or sources are included. To put sources in a different
                    order, drag the appropriate box. Click any checkbox to turn a group of
                    sources, or an individual source, on and off; click on any source id to
                    learn more about it.</div>
                <xsl:if test="$add-display-options">
                    <div>Click Display options to adjust your reading experience.</div>
                </xsl:if>
                <xsl:if
                    test="$render-as-diff-threshhold gt 0 and $render-as-diff-threshhold lt 1">
                    <div>If at any point in the transcription, a group of sources have text that
                        is <xsl:value-of
                            select="format-number($render-as-diff-threshhold, '0%')"/> in
                        common, they are collapsed into a single presentation format, with
                        differences shown, if any. These are distinguished by the source names
                        joined by a +. If you click the ... in the cell, you will get a table of
                        statistics and a source controller. Click a box to turn a source off or
                        on within the div. Click the formatted Tt to apply a format to a
                        different version. When you hover your mouse over a highlighted change,
                        a tooltip will appear showing you which sources attest to that
                        reading.</div>
                </xsl:if>
                <div>This HTML page was generated on <xsl:value-of select="$tan:today-MDY"/> on the
                    basis of <a href="{$tan:stylesheet-url}">
                        <xsl:value-of select="$tan:stylesheet-name"/></a>, an application of the <a
                        href="http://textalign.net">Text Alignment Network</a>.</div>
    
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:head/tan:src | tan:group/tan:alias" mode="tan-to-html-prepass-2">
        <!-- For filtering and reording the merged contents -->
        <div class="switch">
            <div class="on">☑</div>
            <div class="off" style="display:none">☐</div>
        </div>
        <div class="label">
            <xsl:value-of select="replace(., '_', ' ')"/>
        </div>
    </xsl:template>

    <xsl:template match="tan:desc" mode="tan-to-html-prepass-2">
        <div class="desc"><xsl:value-of select="."/></div>
    </xsl:template>
    
    <!-- tan:TAN-T_merge/*[@class = 'control']//tan:group[not(tan:alias)] -->
    <xsl:template match="tan:TAN-T_merge/*[@class = 'control']//tan:group" mode="tan-to-html-prepass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
             <xsl:attribute name="draggable" select="'true'"/> 
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[@class = 'group-items']" mode="tan-to-html-prepass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="string-join((@class, 'sortable'), ' ')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:head" mode="tan-to-html-prepass-2">
        <xsl:variable name="extra-class-values" as="xs:string*">
            <xsl:value-of
                select="concat('groupitem--', string(count(preceding-sibling::tan:head) + 1))"
            />
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="draggable" select="'true'"/>
            <xsl:attribute name="class" select="string-join((@class, $extra-class-values), ' ')"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:body" mode="tan-to-html-prepass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$tables-via-css">
                    <xsl:apply-templates mode="tan-to-html-prepass-2-css-tables"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="tan-to-html-prepass-2-html-tables"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>


    <xsl:mode name="tan-to-html-prepass-2-css-tables" on-no-match="shallow-copy"/>
    <xsl:mode name="tan-to-html-prepass-2-html-tables" on-no-match="shallow-copy"/>

    <xsl:template match="text()" mode="tan-to-html-prepass-2-html-tables tan-to-html-prepass-2-css-tables">
        <xsl:value-of select="replace(., '_', ' ')"/>
    </xsl:template>
    <xsl:template match="tan:n | tan:src | tan:ref[tan:n]" mode="tan-to-html-prepass-2-html-tables tan-to-html-prepass-2-css-tables">
        <xsl:variable name="this-name" select="name(.)"/>
        <xsl:variable name="preceding-siblings" select="preceding-sibling::*[name(.) = $this-name]"/>
        <xsl:if test="not(. = $preceding-siblings)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:mode name="tan-to-html-prepass-2-html-tables-pre-table" on-no-match="shallow-skip"/>
    <xsl:mode name="tan-to-html-prepass-2-html-tables-post-table" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:div/tan:ref[not(tan:n)][@q or @id]" mode="tan-to-html-prepass-2-html-tables-post-table">
        <!-- This <ref> is an anchor to a class-2 annotation, which we now process for display -->
        <xsl:variable name="this-corresponding-annotation-ref" as="element()*"
            select="key('tan:q-ref', (@q, @id), $tan:self-expanded/tan:TAN-A)"/>
        <xsl:variable name="this-claim" select="$this-corresponding-annotation-ref/ancestor::tan:claim"/>
        <xsl:variable name="this-claim-component-context"
            select="$this-corresponding-annotation-ref/ancestor::*[parent::tan:claim][1]"/>
        <xsl:variable name="this-claim-component-name" select="name($this-claim-component-context)"/>
        <xsl:variable name="this-claim-component-position"
            select="count($this-claim-component-context/preceding-sibling::*[name() eq $this-claim-component-name]) + 1"
        />
        <xsl:choose>
            <xsl:when test="exists($this-corresponding-annotation-ref)">
                <xsl:apply-templates select="$this-claim" mode="annotation-to-html">
                    <xsl:with-param name="originating-qs" select="@q | @id"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:mode name="annotation-to-html" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:claim" mode="annotation-to-html">
        <xsl:param name="originating-qs" as="xs:string*"/>
        <xsl:variable name="this-claim" select="."/>
        <!-- subject, adverb, verb, object, everything else : all the preceding except items where the context is known -->
        <xsl:variable name="annotation-sequence" select="('subject', 'adverb', 'verb', 'object', 'where', 'when', 'claimant')"/>
        <xsl:variable name="originating-claim-component" select="*[descendant-or-self::*[@q = $originating-qs]][1]"/>
        <xsl:variable name="originating-claim-component-name" select="name($originating-claim-component)"/>
        <xsl:variable name="comparable-claim-components"
            select="*[name(.) = $originating-claim-component-name] except $originating-claim-component"
        />
        <xsl:variable name="applicable-to-only-some-versions" select="exists($originating-claim-component/@src)"/>
        <xsl:variable name="this-claim-resolved" as="element()">
            <xsl:copy>
                <xsl:if test="not($tan:distribute-vocabulary)">
                    <xsl:copy-of select="@*"/>
                </xsl:if>
                <xsl:if test="$applicable-to-only-some-versions">
                    <div class="{$originating-claim-component-name}">
                        <xsl:value-of select="$originating-claim-component/@src || ': '"/>
                    </div>
                </xsl:if>
                <xsl:if test="exists(@cert)">
                    <xsl:variable name="this-cert" select="number(@cert)"/>
                    <div class="certainty">
                        <xsl:choose>
                            <xsl:when test="$this-cert lt 0.25">
                                <xsl:text>(??)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>(?)</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </div>
                </xsl:if>
                <xsl:if test="exists($comparable-claim-components)">
                    <div class="{$originating-claim-component-name} see-also">
                        <xsl:apply-templates select="$comparable-claim-components" mode="#current"/>
                    </div>
                </xsl:if>
                <xsl:for-each-group
                    select="* except ($originating-claim-component, $comparable-claim-components)"
                    group-by="
                    (: If we're dealing with a claim component that is a text reference, group by source :)
                        if (exists(@src) or exists(@work) or exists(@scriptum)) then
                            string-join((@src, @work, @scriptum, name(.)), ' ')
                        else
                            name(.)">
                    <xsl:sort
                        select="(index-of($annotation-sequence, current-grouping-key()), 99)[1]"/>
                    <xsl:variable name="this-component-name" select="current-grouping-key()"/>
                    <xsl:variable name="matching-claim-attribute"
                        select="$this-claim/@*[name(.) = $this-component-name]"/>
                    <xsl:variable name="label-strings" as="xs:string*">
                        <xsl:for-each select="current-group()">
                            <xsl:choose>
                                <xsl:when test="position() eq 1">
                                    <xsl:value-of
                                        select="string-join(((@work, @src, @scriptum)[1], @ref), ' ')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@ref"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:variable name="this-label" as="xs:string?">
                        <xsl:choose>
                            <xsl:when test="exists($matching-claim-attribute)">
                                <xsl:value-of
                                    select="replace($matching-claim-attribute, '[_-]', ' ')"/>
                            </xsl:when>
                            <xsl:when
                                test="exists(current-group()[@*]) and not(exists(current-group()/@attr))">
                                <xsl:value-of select="tan:commas-and-ands($label-strings)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$this-component-name"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="there-are-multiple-refs"
                        select="count(current-group()//tan:ref) gt 1"/>
                    <xsl:variable name="these-refs" select="current-group()/tan:ref[@q]"/>

                    <div class="{$this-component-name}">
                        <div class="label">
                            <xsl:value-of
                                select="tan:batch-replace($this-label, $claim-component-batch-replacements)"
                            />
                        </div>
                        <xsl:if test="exists($these-refs)">
                            <xsl:variable name="these-classes" as="xs:string*" select="
                                    ('ref',
                                    (if ($table-layout-fixed) then
                                        'layout-fixed'
                                    else
                                        ()))"/>
                            <table class="{string-join($these-classes, ' ')}">
                                <tbody>
                                    <tr>
                                        <xsl:for-each select="$tan:self-expanded/tan:TAN-T">
                                            <xsl:sort select="(index-of($tan:src-ids, @src), 999999)[1]"/>
                                            <xsl:variable name="these-anchors"
                                                select="key('tan:q-ref', $these-refs/@q, tan:body)"/>
                                            <!--<xsl:variable name="these-divs-prepped-for-html"
                                                as="element()*">
                                                <xsl:apply-templates
                                                  select="$these-anchors/ancestor::tan:div[1]"
                                                  mode="tan-to-html-pass-1"/>
                                            </xsl:variable>-->
                                            <xsl:variable name="these-divs-prepped-for-html"
                                                as="element()*"
                                                select="tan:prepare-to-convert-to-html($these-anchors/ancestor::tan:div[1])"
                                            />
                                            <xsl:variable name="this-src" select="@src"/>
                                            <xsl:variable name="this-lang"
                                                select="tan:body/@xml:lang"/>
                                            
                                            <xsl:if test="exists($these-anchors)">
                                                <td class="src--{$this-src}">
                                                  <div class="label">
                                                  <xsl:value-of select="$this-src"/>
                                                  </div>
                                                  <div class="content" lang="{$this-lang}">
                                                  <xsl:apply-templates
                                                  select="$these-divs-prepped-for-html"
                                                  mode="#current"/>
                                                  </div>
                                                </td>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </tr>
                                </tbody>
                            </table>
                        </xsl:if>
                        <xsl:apply-templates select="current-group()/* except $these-refs"
                            mode="#current">
                            <xsl:with-param name="retain-ref-label" tunnel="yes"
                                select="$there-are-multiple-refs"/>
                        </xsl:apply-templates>
                    </div>
                </xsl:for-each-group>
            </xsl:copy>
        </xsl:variable>
        <!-- The material hasn't had any HTML formatting, and the context document into which it 
            is being inserted has had pass 1 already, so we need to run pass 1 on the new material. -->
        <!--<xsl:apply-templates select="$this-claim-resolved" mode="tan-to-html-pass-1"/>-->
        <xsl:copy-of select="tan:prepare-to-convert-to-html($this-claim-resolved)"/>
    </xsl:template>
    
    <!-- These are items we've already set up in a label, and don't need to be processed further -->
    <xsl:template
        match="tan:object/tan:work | tan:object/tan:scriptum | tan:object/tan:src | tan:subject/tan:work | tan:subject/tan:scriptum | tan:subject/tan:src"
        mode="annotation-to-html"/>
    
    <!-- Drop class 2 anchor <ref>s in class 1 sources -->
    <xsl:template match="tan:div/tan:ref[not(tan:n)]" priority="1" mode="annotation-to-html"/>
    
    <xsl:template match="tan:div" mode="annotation-to-html">
        <xsl:param name="label-to-insert" as="xs:string?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="string-length($label-to-insert) gt 0">
                <div class="label">
                    <xsl:value-of select="$label-to-insert"/>
                </div>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <!-- We have provided for the reference system in the claim's <subject> or <object>'s label. -->
    <xsl:template match="tan:div/tan:ref | tan:div/tan:n | tan:div/tan:type" mode="annotation-to-html"/>
    
    <xsl:template match="tan:div/text()[matches(., '\S')]" mode="annotation-to-html">
        <div>
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    
    <!-- End of annotation builder -->



    <!-- Build a version wrapper, adjust HTML content -->
    
    <xsl:template match="tan:div" priority="1" mode="tan-to-html-prepass-2-html-tables">
        <xsl:variable name="context-refs" as="xs:string*" select="tan:ref/text()"/>
        <xsl:variable name="these-insertions-before" as="element()*" select="$ad-hoc-insertions[@before-ref = $context-refs]"/>
        <xsl:variable name="these-insertions-after" as="element()*" select="$ad-hoc-insertions[@after-ref = $context-refs]"/>
        <xsl:copy-of select="$these-insertions-before/node()"/>
        <xsl:next-match/>
        <xsl:copy-of select="$these-insertions-after/node()"/>
    </xsl:template>
    
    <!-- For table-based comparison of versions, here begins the creation of the table that wraps merge leaves. A merge leaf
        is identified as one that contains at least one #version. Many times what is enclosed will be mostly or all #versions,
        but there may be versions that are further subdivided. Non-leaf merge fragments have to be grouped into the version, 
        for the <td>s of the table to be correctly sorted. The rows are shaped by the n patterns, because there may be 
        defective or combined @n values for a set of versions, in which case we need to calculate @rowspan values. Once that 
        grid is formed, the versions are brought together at the <td> level, further into the template mode. -->
    <xsl:template match="tan:div[tokenize(@class, ' ') = $version-wrapper-class-name]"
        mode="tan-to-html-prepass-2-html-tables">
        <xsl:variable name="n-pattern" as="element()*"
            select="(tan:primary-ns, tan:n[not(contains(@class, 'rebuilt'))])"/>
        <!--<xsl:variable name="these-div-versions"
            select=".//tan:div[tokenize(@class, ' ') = 'version']"/>-->
        <xsl:variable name="these-div-versions" select="tan:item/tan:div"/>
        <xsl:variable name="these-divs-diffed" as="element()*">
            <xsl:choose>
                <xsl:when test="$render-as-diff-threshhold gt 0 and $render-as-diff-threshhold lt 1">
                    <!-- group by alias group, and then by language -->
                    <xsl:for-each-group select="$these-div-versions"
                        group-by="
                            (for $i in ancestor-or-self::*[tan:src][1]/tan:src[1]
                            return
                                ($source-group-and-sort-pattern//tan:group[tan:idref = $i]/tan:alias, '#no-group')[1])
                            || '#' || (@lang, @xml:lang, '#no-lang')[1]">
                        <xsl:variable name="current-group-count" select="count(current-group())"/>
                        <xsl:variable name="is-diff" select="$current-group-count eq 2"/>
                        <xsl:variable name="these-raw-texts" as="xs:string*"
                            select="
                                if ($current-group-count eq 1) then
                                    ()
                                else
                                    for $i in current-group()
                                    return
                                        string-join($i/descendant-or-self::tan:div/(text() | tei:*))"
                        />
                        <xsl:variable name="these-texts-normalized-1"
                            select="
                                if (count(($tan:diff-and-collate-input-batch-replacements)) gt 0) then
                                    (for $i in $these-raw-texts
                                    return
                                        tan:batch-replace($i, ($tan:diff-and-collate-input-batch-replacements)))
                                else
                                    $these-raw-texts"/>

                        <xsl:variable name="finalized-texts-to-compare" as="xs:string*"
                            select="
                                if ($tan:ignore-case-differences) then
                                    (for $i in $these-texts-normalized-1
                                    return
                                        lower-case($i))
                                else
                                    $these-texts-normalized-1"/>

                        <xsl:variable name="these-idrefs"
                            select="current-group()/ancestor-or-self::*[tan:src][1]/tan:src[1]"/>
                        <xsl:variable name="this-diff-or-collation" as="element()?">
                            <xsl:choose>
                                <xsl:when
                                    test="
                                        some $i in $finalized-texts-to-compare
                                            satisfies not(matches($i, '\S'))"/>
                                <xsl:when test="$is-diff">
                                    <xsl:sequence
                                        select="tan:adjust-diff(tan:diff($finalized-texts-to-compare[1], $finalized-texts-to-compare[2], $tan:snap-to-word))"
                                    />
                                </xsl:when>
                                <xsl:when test="count(current-group()) gt 2">
                                    <xsl:sequence
                                        select="tan:collate($finalized-texts-to-compare, $these-idrefs, true(), true(), true(), $tan:snap-to-word)"
                                    />
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="this-common-text"
                            select="$this-diff-or-collation/(tan:common | tan:c/tan:txt)"/>
                        <xsl:variable name="this-full-text"
                            select="$this-diff-or-collation/(tan:common | tan:a | tan:b | */tan:txt)"/>
                        <xsl:variable name="common-text-length"
                            select="string-length(string-join($this-common-text))"/>
                        <xsl:variable name="full-text-length"
                            select="string-length(string-join($this-full-text))"/>
                        <xsl:variable name="this-ratio-of-commonality"
                            select="
                                if ($full-text-length gt 0) then
                                    $common-text-length div $full-text-length
                                else
                                    0"/>
                        
                        <xsl:variable name="diagnostics-on" select="false()"/>
                        <xsl:if test="$diagnostics-on">
                            <xsl:message select="'Diagnostics on, $these-divs-diffed'"/>
                            <xsl:message select="'Current group count: ', $current-group-count"/>
                            <xsl:message select="'Current group key: ' || current-grouping-key()"/>
                        </xsl:if>
                        
                        <xsl:choose>
                            <xsl:when test="$current-group-count eq 1">
                                <xsl:sequence select="current-group()"/>
                            </xsl:when>
                            <xsl:when
                                test="$this-ratio-of-commonality gt $render-as-diff-threshhold">

                                <xsl:variable name="this-diff-or-collation-statted"
                                    select="tan:infuse-diff-and-collate-stats($this-diff-or-collation, (), $include-venns)"/>

                                <!--<xsl:variable name="this-diff-or-collate-as-htmlold" as="element()">
                                    <xsl:apply-templates select="$this-diff-or-collation-statted"
                                        mode="diff-and-collate-to-html">
                                        <xsl:with-param name="last-wit-idref" tunnel="yes"
                                            select="
                                                if ($first-version-is-of-primary-interest) then
                                                    $these-idrefs[1]
                                                else
                                                    $these-idrefs[last()]"/>
                                        <xsl:with-param name="raw-texts" tunnel="yes"
                                            select="
                                                if ($is-diff) then
                                                    $these-raw-texts
                                                else
                                                    if ($first-version-is-of-primary-interest) then
                                                        $these-raw-texts[1]
                                                    else
                                                        $these-raw-texts[last()]"
                                        />
                                        <xsl:with-param name="diff-a-ref" tunnel="yes" as="xs:string" select="$these-idrefs[1]"/>
                                        <xsl:with-param name="diff-b-ref" tunnel="yes" as="xs:string" select="$these-idrefs[2]"/>
                                    </xsl:apply-templates>
                                </xsl:variable>-->
                                <xsl:variable name="primary-version-ref" as="xs:string" select="
                                        if ($is-diff) then
                                            'b'
                                        else
                                            if ($first-version-is-of-primary-interest)
                                            then
                                                $these-idrefs[1]
                                            else
                                                $these-idrefs[last()]"
                                />
                                <xsl:variable name="this-diff-or-collate-as-html" as="element()"
                                    select="
                                        tan:diff-or-collate-to-html($this-diff-or-collation-statted,
                                        $primary-version-ref, ())"
                                />

                                <div n="{position()}"
                                    class="version {string-join($these-idrefs, ' ')} {string-join($these-idrefs, '+')}"
                                    colspan="{count(current-group())}">
                                    <xsl:copy-of select="$these-idrefs"/>
                                    <xsl:copy-of select="current-group()[1]/*"/>
                                    <xsl:apply-templates select="$this-diff-or-collate-as-html"
                                        mode="adjust-diff-or-collate-for-merged-display"/>
                                </div>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="current-group()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$these-div-versions"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <div>
            <xsl:copy-of select="@*[name(.) = $tan:global-html-attributes]"/>
            <div class="meta">
                <xsl:apply-templates select="* except tan:group" mode="tan-to-html-prepass-2-html-tables-pre-table"/>
            </div>
            <table class="parallel-edition">
                <xsl:if test="$table-layout-fixed">
                    <xsl:attribute name="class" select="'layout-fixed'"/>
                </xsl:if>
                
                <tbody>
                    <tr>
                        <td class="label">
                            <xsl:apply-templates select="tan:display-n | tan:n | tan:ref"
                                mode="#current"/>
                        </td>
                        
                        <xsl:apply-templates select="$these-divs-diffed" mode="tan-to-html-pass-2-build-version-table"/>
                    </tr>
                    <!-- Dec 2020 delete, relic of @n handling -->
                    <!--<xsl:apply-templates select="$n-pattern"
                        mode="tan-to-html-pass-2-html-tables-tr">
                        <xsl:with-param name="div-versions" select="$these-divs-diffed" tunnel="yes"/>
                    </xsl:apply-templates>-->
                </tbody>
            </table>
            <div class="meta">
                <xsl:apply-templates select="* except tan:group" mode="tan-to-html-prepass-2-html-tables-post-table"/>
            </div>
        </div>
    </xsl:template>
    
    
    <xsl:mode name="adjust-diff-or-collate-for-merged-display" on-no-match="shallow-copy"/>
    
    <!-- Get rid of the <h2>Comparison header, as well as the 2nd column in the statistics table, with the URI -->
    <xsl:template match="html:h2 | html:table[@class = 'e-stats']/html:thead/html:tr/html:th[2] | 
        html:table[@class = 'e-stats']/html:tbody/html:tr/html:td[2]" 
        mode="adjust-diff-or-collate-for-merged-display"/>
    <xsl:template match="html:*[html:div[@class = ('collation', 'e-diff')]]" mode="adjust-diff-or-collate-for-merged-display">
        <xsl:variable name="this-collation" select="html:div[@class = ('collation', 'e-diff')]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <div class="collation-head">
                <div class="label">...</div>
                <xsl:apply-templates select="$this-collation/preceding-sibling::node()" mode="#current"/>
            </div>
            <xsl:apply-templates select="$this-collation/(self::*, following-sibling::node())" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- We're in the process of building the <td>s of a <tr>, so skip until we get the version that we need (see below) -->
    <xsl:mode name="tan-to-html-pass-2-build-version-table" on-no-match="shallow-skip"/>
    <!--<xsl:template match="node()" mode="tan-to-html-pass-2-build-version-table">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>-->
    
    <!-- Build a version wrapper. This template is for the leaf divs. -->
    <xsl:template
        match="*:div[tokenize(@class, ' ') = ('version', 'filler', 'consolidated')]"
        mode="tan-to-html-pass-2-build-version-table">
        <!--<xsl:variable name="is-continuation" select="tokenize(@class, ' ') = 'continuation'"/>-->
        <xsl:variable name="these-srcs" select="ancestor-or-self::*[tan:src][1]/tan:src"/>
        <xsl:variable name="these-src-qualifiers" select="@src-qualifier" as="xs:string*"/>
        <xsl:variable name="this-pattern-marker"
            select="$source-group-and-sort-pattern//tan:idref[. = $these-srcs]"/>
        <xsl:variable name="top-level-pattern" select="$source-group-and-sort-pattern/*[descendant-or-self::tan:idref[. = $these-srcs]]"/>
        <xsl:variable name="following-siblings" select="following-sibling::tan:div"/>
        <xsl:variable name="first-following-noncontinuation-sibling"
            select="$following-siblings[not(tokenize(@class, ' ') = 'continuation')][1]"/>
        <xsl:variable name="following-continuations"
            select="$following-siblings except $first-following-noncontinuation-sibling/(self::*, following-sibling::*)"/>
        <xsl:variable name="these-alias-ids" select="ancestor::tan:group/tan:alias"/>
        
        
        <!-- A <td> class should have at least the source class and the groupitem class, e.g., 
        class="src-/-grc-xyz groupitem-/-1" (double hyphens escaped, to keep this comment valid). 
        The first makes sure that the <td> changes position if the
        user changes the sequence of the sources. The second makes sure that the right opacity is applied
        to the background color, determined by the corresponding <col> in <colgroup>. The groupitem number
        has to do with what position the source is within its alias group. -->
        
        <xsl:variable name="these-src-classes"
            select="
                for $i in $these-srcs
                return
                    tan:class-val-for-source($i)"
        />
        <!-- We once needed this variable, but not now; but there may be a time when we need it again -->
        <!--<xsl:variable name="these-group-classes"
            select="
                for $i in $these-srcs
                return
                    tan:class-val-for-group-item-number($i)"
        />-->

        <xsl:variable name="these-class-additions" as="xs:string*" select="$these-src-classes, $top-level-pattern/@alias-id"/>
        <xsl:variable name="this-has-text"
            select="exists(descendant-or-self::tan:div/text()[matches(., '\S')])
            or exists(descendant::tan:tok)
            or exists(descendant-or-self::tei:*) 
            or exists(html:div/html:div[tokenize(@class,'\s+') = ('collation', 'e-diff')])"
        />
        
        <xsl:variable name="diagnostics" select="false()"/>
        <xsl:if test="$diagnostics">
            <xsl:message select="'Diagnostics on, template mode tan-to-html-pass-2-html-tables on tan:div'"/>
            <xsl:message select="'This element: ', tan:shallow-copy(., 4)"/>
            <!--<xsl:message select="'This is continuation:', $is-continuation"/>-->
            <xsl:message select="'These srcs: ' || $these-srcs"/>
            <xsl:message select="'This pattern marker:', $this-pattern-marker"/>
            <xsl:message select="'Top-level pattern:', $top-level-pattern"/>
            <xsl:message select="'These alias ids:', $these-alias-ids"/>
            <xsl:message select="'This has text:', $this-has-text"/>
            <xsl:message select="'This src class:', $these-src-classes"/>
            <xsl:message select="'Class additions:', $these-class-additions"/>
        </xsl:if>
        
        <td>
            <xsl:copy-of select="@*[name(.) = $tan:global-html-attributes]"/>
            <xsl:attribute name="class"
                select="string-join((@class, $these-class-additions), ' ')"/>
            <!--<xsl:if test="exists($following-continuations)">
                <xsl:attribute name="rowspan" select="count($following-continuations) + 1"/>
            </xsl:if>-->
            <xsl:choose>
                <xsl:when test="$this-has-text and exists($top-level-pattern)">
                    <xsl:apply-templates select="$top-level-pattern" mode="build-td-divs">
                        <xsl:with-param name="stop-at" tunnel="yes" select="$these-srcs"/>
                        <xsl:with-param name="version-div" tunnel="yes" select="."/>
                        <xsl:with-param name="src-id" tunnel="yes" select="$these-srcs"/>
                        <xsl:with-param name="src-qualifiers" tunnel="yes" select="$these-src-qualifiers"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="node() except (tan:type | tan:display-n | tan:n)"/>
                </xsl:otherwise>
            </xsl:choose>
        </td>
        
    </xsl:template>
    
    <xsl:mode name="build-td-divs" on-no-match="shallow-skip"/>
    
    <!--<xsl:template match="* | text()"
        mode="build-td-divs tan-to-html-prepass-2-html-tables-pre-table 
        tan-to-html-prepass-2-html-tables-post-table">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>-->
    
    <xsl:template match="tan:group" mode="build-td-divs">
        <xsl:param name="src-id" tunnel="yes" as="element()*"/>
        <xsl:param name="version-div" tunnel="yes" as="element()?"/>
        <xsl:variable name="this-idref" select="tan:idref[. = $src-id]"/>
        <xsl:if test="exists(descendant::tan:idref[. = $src-id])">
            <div class="{@alias-id}">
                <xsl:apply-templates mode="#current"/>
            </div>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="tan:idref" mode="build-td-divs">
        <xsl:param name="version-div" tunnel="yes" as="element()?"/>
        <xsl:param name="src-id" tunnel="yes" as="element()*"/>
        <xsl:param name="src-qualifiers" tunnel="yes" as="xs:string*" select="()"/>
        <xsl:variable name="this-is-collate-or-diff" select="count($src-id) gt 1"/>
        <xsl:variable name="src-id-of-interest"
            select="
                if (not($this-is-collate-or-diff)) then
                    $src-id
                else
                    if ($first-version-is-of-primary-interest) then
                        $src-id[1]
                    else
                        $src-id[last()]"
        />
        <xsl:variable name="build-this" select=". = $src-id-of-interest"/>
        <xsl:variable name="this-pos" select="count(preceding-sibling::*/(self::tan:idref | self::tan:group)) + 1"/>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode build-td-divs for tan:idref'"/>
            <xsl:message select="'This element:', ."/>
            <xsl:message select="'version div: ', $version-div"/>
            <xsl:message select="'src id(s):', $src-id"/>
            <xsl:message select="'src id of interest: ', $src-id-of-interest"/>
            <xsl:message select="'Build this element?', $build-this"/>
            <xsl:message select="'This pos:', $this-pos"/>
        </xsl:if>
        
        <xsl:if test="$build-this">
            <!-- We don't copy the source class identifier because we've done that on the ancestral <td>. But we do copy
            the src id as a label -->
            <div class="groupitem--{$this-pos}">

                <div class="label">
                    <xsl:value-of select="string-join($src-id, ' + ')"/>
                    <xsl:if test="count($src-qualifiers) gt 0">
                        <xsl:value-of select="' (' || string-join($src-qualifiers, ', ') || ')'"/>
                    </xsl:if>
                </div>
                <xsl:choose>
                    <xsl:when test="$this-is-collate-or-diff">
                        <!-- Inside a version difference are some preliminary <src>, <type>, <n> elements, but the 
                            main meat of the diff or collation is inside an html <div> -->
                        <xsl:copy-of select="$version-div/html:div"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <div class="text">
                            <xsl:apply-templates
                                select="$version-div/(node() except (tan:type | tan:display-n | tan:n | tan:src))"
                                mode="wrap-leaf-text"/>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
                
            </div>
        </xsl:if>
        
    </xsl:template>
    
    
    <xsl:mode name="wrap-leaf-text" on-no-match="shallow-copy"/>
    
    <xsl:template match="text()[matches(., '\S')]" mode="wrap-leaf-text">
        <!-- We wrap leaf text, in order to do some styling... -->
        <div class="inline">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    <xsl:template match="tan:tok/text() | tan:non-tok/text()" priority="1" mode="wrap-leaf-text">
        <!-- ...but we don't worry about tokenized text, already wrapped. -->
        <xsl:value-of select="."/>
    </xsl:template>
    
    
    <xsl:template
        match="tan:div[tokenize(@class, ' ') = ($version-wrapper-class-name)]"
        mode="tan-to-html-prepass-2-css-tables">
        <xsl:variable name="table-row-cells" select="tan:item"/>
        <xsl:variable name="width-needs-to-be-allocated" select="count($table-row-cells) gt 1"/>
        <xsl:variable name="these-text-nodes"
            select="
                if ($calculate-width-at-td-or-leaf-div-level) then
                    descendant-or-self::tan:div[tokenize(@class, ' ') = 'version']/(text(), tei:*, tan:common, tan:a, tan:b, tan:u, tan:c)
                else
                    ()"
        />
        <xsl:variable name="all-text-norm" select="normalize-space(string-join($these-text-nodes))"/>
        <xsl:variable name="this-string-length" select="string-length($all-text-norm)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="containing-text-string-length" tunnel="yes"
                    select="
                        if ($width-needs-to-be-allocated) then
                            $this-string-length
                        else
                            ()"
                />
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:item" mode="tan-to-html-prepass-2-css-tables">
        <xsl:param name="containing-text-string-length" tunnel="yes"/>
        <xsl:variable name="these-text-nodes"
            select="
                if ($calculate-width-at-td-or-leaf-div-level) then
                    descendant-or-self::tan:div[tokenize(@class, ' ') = 'version']/(text(), tei:*, tan:common, tan:a, tan:b, tan:u, tan:c)
                else
                    ()"
        />
        <xsl:variable name="all-text-norm" select="normalize-space(string-join($these-text-nodes))"/>
        <xsl:variable name="this-string-length" select="string-length($all-text-norm)"/>
        <xsl:variable name="this-group-item-class"
            select="tan:class-val-for-group-item-number(tan:src)"/>
        <xsl:variable name="these-alias-class-values" select="tokenize(@class, ' ')[matches(., '^alias--')]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="$calculate-width-at-td-or-leaf-div-level and $containing-text-string-length gt 0">
                <xsl:attribute name="style"
                    select="concat('width: ', format-number(($this-string-length div $containing-text-string-length), '0.0%'))"
                />
            </xsl:if>
            <!-- Sept. 2020: the impetus for the following comment has been revised, but the nested div
            structure has not been touched. -->
            <!-- When we use tables, we can achieve overlays of two background colors simply
            by assigning one background color to <colgroup> and then another to a <td> 
            inside that column. But to achieve this with <div> and css tables, the two overlays 
            must be created through a pair of <div>s, one nesting in the other. We cannot use
            the <div> that has a width value in @style, because the height of the nested <div>
            might be shorter than its parent, and so leave unmasked background color.
            -->
            <div class="{string-join($these-alias-class-values, ' ')}">
                <div class="{$this-group-item-class}">
                    <xsl:apply-templates mode="#current"/>
                </div>
            </div>
        </xsl:copy>
    </xsl:template>
    
    
    
    <xsl:variable name="input-pass-4" select="tan:convert-to-html($input-pass-3c, true())" as="document-node()?"/>
    
    <!-- Overwrite the default template tha converts attributes to elements -->
    <xsl:template match="@draggable" mode="tan:tree-to-html" priority="1">
        <xsl:copy-of select="."/>
    </xsl:template>
    

    <xsl:variable name="html-template-doc" as="document-node()?" select="doc($html-template-uri-resolved)"/>
    
    
    <xsl:variable name="template-infused-with-revised-input" as="document-node()?">
        <xsl:apply-templates select="$html-template-doc" mode="infuse-html-template"/>
    </xsl:variable>
    
    
    <xsl:mode name="infuse-html-template" on-no-match="shallow-copy"/>
    
    <xsl:template match="html:body/node()[1]" mode="infuse-html-template">
        <xsl:apply-templates select="$input-pass-4" mode="#current"/>
    </xsl:template>
    
    <xsl:variable name="src-count-width-css" as="xs:string*">td.version { width: <xsl:value-of
            select="format-number((1 div count($input-pass-1)), '0.0%')"/>}</xsl:variable>
    <xsl:variable name="src-length-width-css" as="xs:string*">
        <xsl:variable name="total-length"
            select="string-length(tan:text-join($input-pass-1/tan:TAN-T/tan:body))"/>
        <xsl:for-each select="$input-pass-1">
            <xsl:variable name="this-src-id" select="*/@src"/>
            <xsl:variable name="this-length"
                select="string-length(tan:text-join(tan:TAN-T/tan:body))"/>
            <xsl:value-of
                select="concat('td.src--', $this-src-id, '{ width: ', format-number(($this-length div $total-length), '0.0%'), '}')"
            />
        </xsl:for-each>
    </xsl:variable>
    <xsl:template match="html:head" mode="infuse-html-template">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <style>
                table{
                    table-layout: auto;
                }
                .layout-fixed {
                    table-layout: fixed;
                }
                <xsl:if test="$imprint-color-css">
                    <xsl:apply-templates select="$source-group-and-sort-pattern" mode="source-group-and-sort-pattern-to-css-colors"/>
                </xsl:if>
            </style>
            <xsl:choose>
                <xsl:when test="$td-widths-proportionate-to-td-count">
                    <style><xsl:value-of select="$src-count-width-css"/></style>
                </xsl:when>
                <xsl:when test="$td-widths-proportionate-to-string-length">
                    <style><xsl:value-of select="$src-length-width-css"/></style>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:mode name="source-group-and-sort-pattern-to-css-colors" on-no-match="shallow-skip"/>
    
    <!--<xsl:template match="node()" mode="source-group-and-sort-pattern-to-css-colors">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>-->
    <xsl:template match="*[@color]" mode="source-group-and-sort-pattern-to-css-colors">
        <xsl:variable name="this-id" select="(@alias-id, text())[1]"/>
        <xsl:value-of select="'.' || $this-id || '{background-color:' || @color || '}&#xa;'"/>
        <xsl:value-of select="'td.' || $this-id || '{border:2px solid ' || @color || '}&#xa;'"/>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:variable name="final-tei-divs" as="element()*"
        select="
            if ($tei-should-be-plain-text) then
                ()
            else
                $input-pass-4//html:div[contains-token(@class, 'tei')]"
    />
    <xsl:variable name="tei-classes-to-ignore" as="xs:string+" select="('p', 'ab', 'text')"/>
    <xsl:variable name="tei-classes-that-remain" as="xs:string*">
        <xsl:for-each-group
            select="
                for $i in $final-tei-divs//*[@class][matches(., '\S')]/@class
                return
                    tokenize($i, ' ')"
            group-by=".">
            <xsl:sequence select="current-grouping-key()"/>
        </xsl:for-each-group>
    </xsl:variable>
    
    <xsl:function name="tan:add-class-switch" as="element()?">
        <!-- Input: three strings and a boolean -->
        <!-- Output: an html switch with a div.elementName for the first string, a div.className for the second,
            a plain div for the third, then an on/off switch set to the default value of the boolean. The effect is that
            an accompanying JavaScript algorithm targets elements that match the selector and toggles the class name. 
        -->
        <xsl:param name="elementSelector" as="xs:string"/>
        <xsl:param name="className" as="xs:string"/>
        <xsl:param name="label" as="xs:string"/>
        <xsl:param name="default-on" as="xs:boolean"/>
        <div class="option-item">
            <div class="classSwitch">
                <div class="elementName" style="display:none">
                    <xsl:value-of select="$elementSelector"/>
                </div>
                <div class="className" style="display:none">
                    <xsl:value-of select="$className"/>
                </div>
                <div>
                    <xsl:value-of select="$label"/>
                </div>
                <div class="on">
                    <xsl:if test="$default-on = false()">
                        <xsl:attribute name="style">display:none</xsl:attribute>
                    </xsl:if>
                    <xsl:text>☑</xsl:text>
                </div>
                <div class="off">
                    <xsl:if test="$default-on = true()">
                        <xsl:attribute name="style">display:none</xsl:attribute>
                    </xsl:if>
                    <xsl:text>☐</xsl:text>
                </div>
            </div>
        </div>
    </xsl:function>
    
    <xsl:template match="html:div[@id = 'display-options-placeholder']" mode="infuse-html-template">
        <div class="options">
            <div class="label">Display options</div>
            <div class="option-group">
                <div class="options">
                    <div class="label">Tables</div>
                    <div class="option-group">
                        <xsl:copy-of
                            select="tan:add-class-switch('table', 'layout-fixed', 'Table layout fixed', $table-layout-fixed)"/>
                        <div class="option-item">
                            <div>Table width <input id="tableWidth" type="number" min="50" max="10000"
                                value="100"/>%</div>
                        </div>
                    </div>
                </div>
                <div class="options">
                    <div class="label">TEI</div>
                    <div class="description">The following TEI elements or attributes have been
                        retained, and may be turned on and off here. Some checkboxes may have no
                        effect, if CSS styling or other factors have already suppressed the
                        content.</div>
                    <div class="option-group">
                        <xsl:for-each select="$tei-classes-that-remain[not(. = $tei-classes-to-ignore)]">
                            <xsl:copy-of
                                select="tan:add-class-switch('.' || ., 'hidden', ., true())"/>
                        </xsl:for-each>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    
    
    <xsl:variable name="output-revised" 
        select="tan:revise-hrefs($template-infused-with-revised-input, $html-template-uri-resolved, $output-directory-uri-resolved)"/>
    

    

    
    <!-- RESULT TREE -->
    <xsl:param name="output-diagnostics-on" static="yes" select="false()"/>
    <xsl:output indent="yes" use-when="$output-diagnostics-on"/>
    <xsl:output indent="no" method="html" use-when="not($output-diagnostics-on)"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message
            select="'Using diagnostic output for application ' || $tan:stylesheet-name || ' (' || static-base-uri() || ')'"
        />
        <diagnostics>
            <!--<template-url-resolved><xsl:value-of select="$template-url-resolved"/></template-url-resolved>-->
            <!--<out-dir-rel-cat-input><xsl:value-of select="$output-directory-relative-to-catalyzing-input"/></out-dir-rel-cat-input>-->
            <!--<out-dir-rel-actual-input><xsl:value-of select="$output-directory-relative-to-actual-input"/></out-dir-rel-actual-input>-->
            <!--<out-dir-rel-template><xsl:value-of select="$output-directory-relative-to-template"/></out-dir-rel-template>-->
            <!--<out-dir-default><xsl:value-of select="$default-output-directory-resolved"/></out-dir-default>-->
            <!--<target-output-dir-resolved><xsl:value-of select="$target-output-directory-resolved"/></target-output-dir-resolved>-->
            <!--<output-url-resolved><xsl:value-of select="$output-url-resolved"/></output-url-resolved>-->
            <!--<valid-src-work-vocab><xsl:copy-of select="$valid-src-work-vocab"/></valid-src-work-vocab>-->
            <!--<valid-srcs-by-work><xsl:copy-of select="$valid-srcs-by-work"/></valid-srcs-by-work>-->
            <!--<alias-based-group-and-sort-pattern><xsl:copy-of select="$alias-based-group-and-sort-pattern"/></alias-based-group-and-sort-pattern>-->
            <!--<src-id-sequence><xsl:value-of select="$src-id-sequence"/></src-id-sequence>-->
            <!--<sort-and-group-by-what-alias><xsl:value-of select="$sort-and-group-by-what-alias-idrefs"/></sort-and-group-by-what-alias>-->
            <!--<self-resolved><xsl:copy-of select="$self-resolved"/></self-resolved>-->
            <sources-resolved><xsl:copy-of select="$tan:sources-resolved"/></sources-resolved>
            <!--<source-group-and-sort-pattern><xsl:copy-of select="$source-group-and-sort-pattern"/></source-group-and-sort-pattern>-->
            <!--<TAN-A-self-expanded><xsl:copy-of select="$self-expanded[tan:TAN-A]"/></TAN-A-self-expanded>-->
            <!--<src-ids><xsl:value-of select="$src-ids"/></src-ids>-->
            <!--<src-ids-from-sources><xsl:for-each select="$self-expanded/tan:TAN-T/@src">
                <xsl:value-of select=". || ' '"/>
            </xsl:for-each></src-ids-from-sources>-->
            <!--<self-head-expanded><xsl:copy-of select="$head"/></self-head-expanded>-->
            <!--<sources-expanded count="{count($tan:self-expanded[tan:TAN-T])}"><xsl:copy-of select="$tan:self-expanded[tan:TAN-T]"/></sources-expanded>-->
            <!--<input-pass-1><xsl:copy-of select="$input-pass-1"/></input-pass-1>-->
            <!--<input-pass-1b><xsl:copy-of select="$input-pass-1b"/></input-pass-1b>-->
            <!--<input-pass-1b-shallow><xsl:copy-of select="tan:shallow-copy($input-pass-1b, 3)"/></input-pass-1b-shallow>-->
            <!--<input-pass-1b-heads><xsl:copy-of select="$input-pass-1b/*/tan:head"/></input-pass-1b-heads>-->
            <!--<input-pass-2><xsl:copy-of select="$input-pass-2"/></input-pass-2>-->
            <!--<input-pass-2b><xsl:copy-of select="$input-pass-2b"/></input-pass-2b>-->
            <!--<input-pass-3><xsl:copy-of select="$input-pass-3"/></input-pass-3>-->
            <!--<input-pass-3a><xsl:copy-of select="$input-pass-3a"/></input-pass-3a>-->
            <!--<input-pass-3b><xsl:copy-of select="$input-pass-3b"/></input-pass-3b>-->
            <!--<input-pass-3c><xsl:copy-of select="$input-pass-3c"/></input-pass-3c>-->
            <!--<source-bibliography><xsl:copy-of select="$source-bibliography"/></source-bibliography>-->
            <!--<input-pass-4><xsl:copy-of select="$input-pass-4"/></input-pass-4>-->
            <!--<html-template-url-resolved><xsl:value-of select="$html-template-uri-resolved"/></html-template-url-resolved>-->
            <!--<html-template-doc><xsl:copy-of select="$html-template-doc"/></html-template-doc>-->
            <!--<template-infused><xsl:copy-of select="$template-infused-with-revised-input"/></template-infused>-->
            <!--<output-revised><xsl:copy-of select="$output-revised"/></output-revised>-->
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:message select="$tan:stylesheet-change-message"/>
        <xsl:copy-of select="$output-revised"/>
        
    </xsl:template>

</xsl:stylesheet>
