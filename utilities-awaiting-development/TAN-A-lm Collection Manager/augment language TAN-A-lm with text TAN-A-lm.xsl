<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">

    <!-- Initial input: a TAN-A-lm file that is for a given language -->
    <!-- Secondary input: a TAN-A-lm for a specific text -->
    <!-- Template: the initial input -->
    <!-- Output: the language TAN-A-lm file updated -->

    <!-- This stylesheet looks through a text-specific TAN-A-lm file for any assertions that are relevant to the initiating language-specific TAN-A-lm file. -->
    <!-- If relevant entries are found, they are put into one of several categories. 
        1. If there already is an entry for a token and its lm combo, it is thrown out. 
        2. If there already is an entry for the token, but there's no lm combo, the lm combo is added in a new <ana>.
        3. If there is no entry for the token, a new <ana> is built.
    -->
    <!-- Caveats: the text-specific TAN-A-lm file must use @val (sorry, in the interests of efficiency, we're not tracking down @pos-only refs) -->


    <xsl:import href="../get%20inclusions/convert.xsl"/>
    <xsl:output indent="yes"/>

    <xsl:param name="validation-phase" select="'terse'"/>

    <!-- THIS STYLESHEET -->
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:augment-language-tan-a-lm'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="change-message" select="'augmented from', $new-data-uri-resolved"/>

    <xsl:param name="text-specific-tan-a-lm-uri-relative-to-actual-input" as="xs:string"
        >../../../library-arithmeticus/bible/TAN-A-lm/nt.grc-sbl-2010-TAN-A-lm-2018-04-10.xml</xsl:param>

    <xsl:param name="blame-whom" as="xs:string">kalvesmaki</xsl:param>

    <xsl:variable name="new-data-uri-resolved"
        select="resolve-uri($text-specific-tan-a-lm-uri-relative-to-actual-input, $doc-uri)"/>
    <xsl:variable name="new-data" select="doc($new-data-uri-resolved)" as="document-node()?"/>

    <xsl:variable name="tok-starts-withs" select="/tan:TAN-A-lm/tan:body/tan:tok-starts-with"/>
    <xsl:variable name="tok-ises" select="/tan:TAN-A-lm/tan:body/tan:tok-is"/>

    <xsl:variable name="anas-of-interest" as="element()*">
        <xsl:choose>
            <xsl:when test="exists($tok-starts-withs) or exists($tok-ises)">
                <xsl:sequence
                    select="
                        $new-data/tan:TAN-A-lm/tan:body//tan:ana[tan:tok[(@val = $tok-ises)
                        or (some $i in $tok-starts-withs
                            satisfies starts-with(@val, $i))]]"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$new-data/tan:TAN-A-lm/tan:body//tan:ana"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="current-anas" select="/tan:TAN-A-lm/tan:body//tan:ana"/>

    <xsl:variable name="other-filenames-that-are-start-with-supersets"
        select="
            $local-catalog/collection/doc[matches(@id, concat($doc-id, '.+'))]"/>

    <xsl:template match="tan:body" mode="add-anas">

        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="revise-content"/>
            <xsl:apply-templates select="$anas-of-interest" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="tan:lm-codes">
        <!-- Input: an ancestor with <lm>s -->
        <!-- Output: all lm code permutations -->
        <!-- The values of <l> and <m> are delimited by '#' -->
        <xsl:param name="lm-ancestor" as="element()*"/>
        <xsl:for-each select="$lm-ancestor//tan:lm">
            <xsl:variable name="this-lm" select="."/>
            <xsl:for-each select="tan:l">
                <xsl:variable name="this-l" select="."/>
                <xsl:for-each select="$this-lm/tan:m">
                    <xsl:value-of select="concat($this-l, '#', .)"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="tan:tok-starts-with" mode="revise-content">
        <xsl:choose>
            <xsl:when test="exists($other-filenames-that-are-start-with-supersets)">
                <xsl:message select="tan:cfn(/), 'tok-starts-with changed to tok-is'"/>
                <tok-is>
                    <xsl:value-of select="."/>
                </tok-is>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tan:ana" mode="add-anas">
        <xsl:variable name="these-toks" select="tan:tok"/>
        <xsl:variable name="these-lm-codes" select="tan:lm-codes(.)"/>
        <xsl:variable name="anas-with-tok-matches"
            select="
                $current-anas[tan:tok[($these-toks/@val = @val) or
                (some $i in $these-toks
                    satisfies tan:matches($i/@val, @rgx))]]"
        />
        <xsl:variable name="matching-ana-lm-codes" select="tan:lm-codes($anas-with-tok-matches)"/>
        <xsl:variable name="new-lm-codes" select="$these-lm-codes[not(. = $matching-ana-lm-codes)]"/>
        <xsl:if test="exists($new-lm-codes)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="ed-when" select="$today-iso"/>
                <xsl:attribute name="ed-who" select="$blame-whom"/>
                <xsl:choose>
                    <xsl:when test="exists($anas-with-tok-matches)">
                        <xsl:comment select="'Addendum to', tan:xml-to-string($anas-with-tok-matches/tan:tok)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment>New data</xsl:comment>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:copy-of select="tan:tok"/>
                <xsl:for-each-group select="$new-lm-codes" group-by="tokenize(., '#')[1]">
                    <lm>
                        <l>
                            <xsl:value-of select="current-grouping-key()"/>
                        </l>
                        <xsl:for-each select="current-group()">
                            <m>
                                <xsl:value-of select="tokenize(., '#')[2]"/>
                            </m>
                        </xsl:for-each>
                    </lm>
                </xsl:for-each-group>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:variable name="results" as="document-node()">
        <xsl:apply-templates select="/" mode="add-anas"/>
    </xsl:variable>
    <xsl:variable name="anas-added"
        select="$results/tan:TAN-A-lm/tan:body/tan:ana[@ed-when = $today-iso]"/>

    <xsl:template match="/" priority="5">
        <xsl:if test="not(exists(/tan:TAN-A-lm/tan:body/tan:for-lang))">
            <xsl:message terminate="yes" select="'Input must be a language-specific TAN-A-lm file'"
            />
        </xsl:if>
        <xsl:choose>
            <xsl:when test="exists($anas-added) or exists($other-filenames-that-are-start-with-supersets)">
                <xsl:message select="count($anas-added), 'entries added to', $doc-uri"/>
                <xsl:apply-templates select="$results" mode="credit-stylesheet"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'No additions to', $doc-uri"/>
                <xsl:sequence select="."/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- diagnostics -->
        <!--<diagnostics>
            <!-\-<xsl:copy-of select="$local-catalog"/>-\->
            <xsl:copy-of select="$local-catalog-start-with-matches"/>
            <!-\-<xsl:copy-of select="$self-expanded"/>-\->
            <!-\-<xsl:copy-of select="$new-data-uri-resolved"/>-\->
            <!-\-<xsl:copy-of select="$new-data"/>-\->
            <!-\-<xsl:copy-of select="$tok-starts-withs"/>-\->
            <!-\-<xsl:copy-of select="$anas-of-interest"/>-\->
            <!-\-<xsl:copy-of select="$current-anas"/>-\->
            <!-\-<xsl:copy-of select="$new-anas"/>-\->
            <!-\-<xsl:copy-of select="$familiar-anas"/>-\->
        </diagnostics>-->
    </xsl:template>
</xsl:stylesheet>
