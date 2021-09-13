<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">
    <!-- Input (direct and calculated): any TAN-A-lm file specific to a particular source -->
    <!-- Template: the input -->
    <!-- Output: a TAN-A-lm file converted to a generic, language-based TAN-A-lm -->

    <!-- Language-specific TAN-A-lm files require things optional or missing in a text-specific TAN-A-lm:
    - Every <tok/> must have a @val
    - To weigh statistical probability, <tok>s need to be itemized, so they can be counted 
    - Each <tok> must be associated with a language code
    -->
    <!-- In a source-specific TAN-A-lm, a @val might be missing, or broken up across multiple <ana>s. In a 
        language-specific TAN-A-lm file, those @vals need to be explicit, and they need to be grouped, with
        <lm> and its children reflecting how likely one combination is above the other.
    -->
    <!-- We assume that a change in @morphology is a change in language, so the output results in one file per morphology -->

    <xsl:import href="../get%20inclusions/convert.xsl"/>
    <xsl:output indent="yes" use-character-maps="tan"/>

    <xsl:param name="validation-phase" select="'terse'"/>
    
    <xsl:param name="save-intermediate-steps" select="true()" as="xs:boolean"/>
    <xsl:param name="save-intermediate-steps-location-relative-to-initial-input" select="'tmp2'"/>
    <xsl:param name="use-saved-intermediate-steps" select="true()" as="xs:boolean"/>

    <!-- THIS STYLESHEET -->

    <xsl:variable name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:convert-text-tan-a-lm-to-lang-tan-a-lm'"/>
    <xsl:variable name="stylesheet-url" select="static-base-uri()"/>
    <xsl:variable name="change-message"
        select="
            concat('Converted source-based TAN-A-lm', $doc-id,
            'into a language specific one. Morphological data based on', $sources-resolved/*/tan:head/tan:name)"/>


    <!-- SOURCE PROCESSED -->

    <xsl:variable name="this-token-definition"
        select="$head/tan:token-definition[1]"/>

    <xsl:param name="uri-source-tokenized"
        select="resolve-uri(concat('source-tokenized-', $doc-filename), $temp-directory)"/>
    <xsl:param name="source-tokenized" as="item()*">
        <xsl:choose>
            <xsl:when test="$use-saved-intermediate-steps and doc-available($uri-source-tokenized)">
                <xsl:sequence select="doc($uri-source-tokenized)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="this-source-tokenized"
                    select="tan:tokenize-div($self-expanded[2], $this-token-definition)"/>
                <xsl:choose>
                    <xsl:when test="$save-intermediate-steps">
                        <xsl:copy-of
                            select="tan:mark-save-as($this-source-tokenized, $uri-source-tokenized)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$this-source-tokenized"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <xsl:param name="uri-concordance-pass-1"
        select="resolve-uri(concat('concordance-pass-1-', $doc-filename), $temp-directory)"/>
    <xsl:param name="source-to-concordance-1" as="document-node()?">
        <xsl:choose>
            <xsl:when
                test="$use-saved-intermediate-steps and doc-available($uri-concordance-pass-1)">
                <xsl:sequence select="doc($uri-concordance-pass-1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$save-intermediate-steps">
                        <xsl:apply-templates
                            select="tan:mark-save-as($source-tokenized, $uri-concordance-pass-1)"
                            mode="build-concordance-step-1"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$source-tokenized"
                            mode="build-concordance-step-1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <xsl:template match="tan:div" mode="build-concordance-step-1">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="tan:n | tan:ref | tan:non-tok" mode="build-concordance-step-1"/>
    <xsl:template match="tan:tok" mode="build-concordance-step-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="ref" select="preceding-sibling::tan:ref[1]/text()"/>
            <xsl:value-of select="."/>
        </xsl:copy>
    </xsl:template>


    <xsl:param name="uri-concordance-pass-2"
        select="resolve-uri(concat('concordance-pass-2-', $doc-filename), $temp-directory)"/>
    <xsl:param name="source-to-concordance-2" as="document-node()?">
        <xsl:choose>
            <xsl:when
                test="$use-saved-intermediate-steps and doc-available($uri-concordance-pass-2)">
                <xsl:sequence select="doc($uri-concordance-pass-2)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$save-intermediate-steps">
                        <xsl:apply-templates
                            select="tan:mark-save-as($source-to-concordance-1, $uri-concordance-pass-2)"
                            mode="build-concordance-step-2"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$source-to-concordance-1"
                            mode="build-concordance-step-2"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <xsl:template match="tan:body" mode="build-concordance-step-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each-group select="tan:tok" group-by=".">
                <tok val="{current-grouping-key()}">
                    <xsl:for-each select="current-group()">
                        <item>
                            <xsl:copy-of select="@ref, @n"/>
                        </item>
                    </xsl:for-each>
                </tok>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>


    <!-- CALCULATED INPUT -->
    <xsl:param name="input-items" select="/"/>

    <!-- Pass 1: itemize <tok>, add @val (if not present), add <for-lang>; resolve relative @hrefs -->

    <xsl:template match="node() | @*" mode="input-pass-1">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@href" mode="input-pass-1">
        <xsl:attribute name="href" select="resolve-uri(., $doc-uri)"/>
    </xsl:template>
    <xsl:template match="tan:source" mode="input-pass-1"/>
    <xsl:template match="tan:body" mode="input-pass-1">
        <xsl:variable name="for-langs"
            select="tan:distinct-items($morphologies-resolved/tan:TAN-mor/tan:body/tan:for-lang)"/>
        <xsl:if
            test="
                some $i in $morphologies-resolved
                    satisfies ($i/tan:TAN-mor/tan:body/tan:for-lang != $for-langs)">
            <xsl:message terminate="yes"
                select="'Input TAN-A-lm file must have morphologies that cover exactly the same languages.'"
            />
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="$for-langs"/>
            <xsl:apply-templates select="$self-expanded/tan:TAN-A-lm/tan:body/(tan:group, tan:ana)"
                mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:ana | tan:lm | tan:l | tan:m" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@* except @q"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:ana/tan:tok" mode="input-pass-1">
        <xsl:variable name="this-val" select="@val"/>
        <xsl:variable name="this-ref" select="@ref"/>
        <xsl:variable name="this-rgx" select="@rgx"/>
        <xsl:variable name="these-tok-refs" select="tan:tok-ref"/>
        <xsl:variable name="concordance-tok-matches"
            select="
                $source-to-concordance-2/tan:TAN-T/tan:body/tan:tok[(@val = $this-val) or
                (if (string-length(@rgx) gt 0) then
                    tan:matches(@rgx, $this-rgx)
                else
                    false())]"/>
        <xsl:variable name="tok-rebuilt" as="element()*">
            <xsl:choose>
                <xsl:when test="exists(tan:tok-ref/tan:tok)">
                    <!-- <tok>s with @ref should be itemized -->
                    <xsl:for-each select="tan:tok-ref/tan:tok">
                        <xsl:copy>
                            <xsl:copy-of select="$this-val"/>
                            <xsl:if test="not(exists($this-val))">
                                <xsl:attribute name="val" select="."/>
                            </xsl:if>
                            <xsl:copy-of select="$this-ref"/>
                            <xsl:attribute name="counted"/>
                        </xsl:copy>
                    </xsl:for-each>
                </xsl:when>
                <!-- Bad @refs (<tok>s that don't have a <tok-ref>, checked in the previous step) should be skipped -->
                <xsl:when test="exists(@ref)"/>
                <!-- It's generically true (it doesn't have a @ref); but do the counting only if it's a sibling to <tok>s with @refs -->
                <xsl:when test="exists(../tan:tok/@ref)">
                    <xsl:if test="not(exists($concordance-tok-matches/tan:item))">
                        <xsl:message select="'no tok matches', $this-rgx, $this-val"/>
                    </xsl:if>
                    <xsl:for-each select="$concordance-tok-matches/tan:item">
                        <tok>
                            <xsl:copy-of select="../@val"/>
                            <xsl:attribute name="counted"/>
                        </tok>
                    </xsl:for-each>
                </xsl:when>
                <!-- Generic @ref-less <tok>s just get copied -->
                <xsl:when test="exists(@val)">
                    <xsl:copy>
                        <xsl:copy-of select="@val"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="'Not sure what to do with:', tan:xml-to-string(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy-of select="$tok-rebuilt"/>
    </xsl:template>


    <!-- Pass 2: group <ana>s by <tok> @val -->



    <xsl:template match="*[tan:ana]" mode="input-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node() except tan:ana"/>
            <xsl:for-each-group select="tan:ana" group-by="tan:tok/@val">
                <xsl:if
                    test="exists(current-group()/tan:tok[@counted]) and exists(current-group()/tan:tok[not(@counted)])">
                    <!-- flag cases where some tokens have been itemized but others haven't -->
                    <xsl:message select="'Please count all toks'"/>
                </xsl:if>
                <xsl:variable name="this-rev-group" select="tan:merge-anas(current-group(), current-grouping-key())"/>
                <xsl:apply-templates select="$this-rev-group" mode="#current"/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:ana" mode="input-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each select="distinct-values(tan:tok/@val)">
                <tok val="{.}"/>
            </xsl:for-each>
            <xsl:apply-templates select="tan:lm" mode="#current"/>
        </xsl:copy>
    </xsl:template>



    <!-- Pass 3: Finish grouping by consolidating <ana>s that have identical <lm> combos -->

    <xsl:template match="*[tan:ana]" mode="input-pass-3">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node() except tan:ana"/>
            <xsl:for-each-group select="tan:ana"
                group-by="
                    string-join(for $i in tan:lm,
                        $j in $i/tan:l,
                        $k in $i/tan:m
                    return
                        ($j || ' ' || $k), ' ')">
                <xsl:copy-of select="tan:merge-anas(current-group(), current-group()/tan:tok/@val)"/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>

    <!-- TEMPLATE -->
    <xsl:param name="template-infused-with-revised-input" select="$input-pass-3"/>

    <!-- OUTPUT -->
    <xsl:param name="output-url-relative-to-actual-input"
        select="concat(tan:cfn(/), '-', $today-iso, '.xml')"/>

    <!--<xsl:template match="/" priority="5">
        <diagnostics>
            <!-\-<xsl:variable name="temp-1">
                <body>
                    <xsl:copy-of select="/tan:TAN-A-lm/tan:body/tan:ana[tan:tok[@val = 'τί']]"/>
                </body>
            </xsl:variable>-\->
            <!-\-<xsl:variable name="temp-2">
                <xsl:apply-templates select="$temp-1" mode="input-pass-2"/>
            </xsl:variable>-\->
            <!-\-<temp-2>
                <xsl:copy-of select="$temp-2"/>
            </temp-2>-\->
            <!-\-<xsl:apply-templates select="$temp-2" mode="input-pass-3"/>-\->
            <!-\-<xsl:copy-of select="$source-langs"/>-\->
            <!-\-<xsl:copy-of select="$morphologies-resolved"/>-\->
            <!-\-<xsl:copy-of select="$self-resolved"/>-\->
            <!-\-<xsl:copy-of select="$source-tokenized"/>-\->
            <!-\-<xsl:copy-of select="$source-to-concordance-1"/>-\->
            <!-\-<xsl:copy-of select="$source-to-concordance-2"/>-\->
            <!-\-<xsl:copy-of select="$self-expanded[1]"/>-\->
            <!-\-<xsl:copy-of select="$input-pass-1"/>-\->
            <!-\-<xsl:copy-of select="$input-pass-2"/>-\->
            <!-\-<xsl:copy-of select="$input-pass-3"/>-\->
            <!-\-<xsl:copy-of select="$input-pass-4"/>-\->
            <!-\-<xsl:copy-of select="$template-infused-with-revised-input"/>-\->
            <xsl:copy-of select="$output-url-resolved"/>
        </diagnostics>
        <xsl:if test="$save-intermediate-steps">
            <xsl:apply-templates select="$source-tokenized" mode="save-file"/>
            <xsl:apply-templates select="$source-to-concordance-1" mode="save-file"/>
            <xsl:apply-templates select="$source-to-concordance-2" mode="save-file"/>
        </xsl:if>
    </xsl:template>-->
</xsl:stylesheet>
