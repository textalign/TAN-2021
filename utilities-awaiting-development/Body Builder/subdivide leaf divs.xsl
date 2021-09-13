<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">
    <xsl:import href="../get%20inclusions/convert.xsl"/>

    <!-- Initial input: a TAN-T file -->
    <!-- Effective input: the same -->
    <!-- Template: the same -->
    <!-- Output: the same, with leaf divs subdivided into sentences and perhaps independent clauses, as defined below -->

    <!-- A regular expression that defines the end of a sentence -->
    <xsl:param name="sentence-end-regex" select="'[\.;][\s»]*'"/>
    <!-- Should independent clauses also be subdivided? -->
    <xsl:param name="process-clauses" as="xs:boolean" select="true()"/>
    <!-- A regular expression that defines the end of a clause -->
    <xsl:param name="clause-end-regex" select="'·[\s»]*'"/>
    <!-- Should nested clauses be preserved intact? E.g., should the following be treated as one sentence or two? 
            I said "Go!" to her. -->
    <xsl:param name="preserve-nested-clauses" as="xs:boolean" select="true()"/>


    <!-- About this template -->
    <xsl:variable name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:subdivide-leaf-divs'"/>
    <xsl:variable name="stylesheet-url" select="static-base-uri()"/>
    <xsl:variable name="change-message" as="xs:string">Subdivided leaf divs.</xsl:variable>


    <!-- INITIAL AND EFFECTIVE INPUT -->
    <xsl:param name="input-items" select="/" as="document-node()"/>

    <!-- Pass 1 -->
    <xsl:template match="tan:div[not(tan:div)]" mode="input-pass-1">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:variable name="sentences"
                select="tan:chop-string(string-join(text(), ''), $sentence-end-regex, $preserve-nested-clauses)"/>
            <xsl:for-each select="$sentences">
                <div type="sent" n="{position()}">
                    <xsl:variable name="independent-clauses"
                        select="tan:chop-string(., $clause-end-regex, $preserve-nested-clauses)"/>
                    <xsl:choose>
                        <xsl:when test="count($independent-clauses) gt 1">
                            <xsl:for-each select="$independent-clauses">
                                <div type="ic" n="{position()}">
                                    <xsl:value-of select="."/>
                                </div>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>


    <!-- TEMPLATE (= INITIAL INPUT) -->
    <xsl:param name="template-url-relative-to-actual-input" select="$doc-uri"/>
    <xsl:param name="template-infused-with-revised-input" select="$input-pass-1"/>


    <!-- OUTPUT -->
    <xsl:param name="output-url-relative-to-template" as="xs:string?"
        select="replace($doc-uri, '(\.[^\.]+)$', concat('-', $today-iso, '$1'))"/>


    <!--<xsl:template match="/" priority="5">
        <!-\- for testing, diagnostics -\->
        <!-\-<xsl:copy-of select="$input-items"/>-\->
        <!-\-<xsl:copy-of select="$input-pass-1"/>-\->
        <xsl:copy-of select="$infused-template-revised"/>
        <!-\-<xsl:copy-of select="$output-url-resolved"/>-\->
    </xsl:template>-->


</xsl:stylesheet>
