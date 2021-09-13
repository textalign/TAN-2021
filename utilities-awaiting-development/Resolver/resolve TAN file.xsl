<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">

    <!-- Input: any TAN file -->
    <!-- Output: the file resolved, except for attributes and elements that would be invalid -->

    <xsl:import href="../get%20inclusions/convert.xsl"/>
    <xsl:output indent="no" use-character-maps="tan"/>
    
    <!-- THIS STYLESHEET -->

    <xsl:variable name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:resolve-tan-file'"/>
    <xsl:variable name="stylesheet-url" select="static-base-uri()"/>
    <xsl:variable name="change-message">Resolved file.</xsl:variable>

    <xsl:template match="node() | @*" mode="remove-undefined-nodes">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/" mode="remove-undefined-nodes">
        <xsl:document>
            <xsl:for-each select="node()">
                <xsl:text>&#xa;</xsl:text>
                <xsl:apply-templates select="." mode="#current"/>
            </xsl:for-each>
        </xsl:document>
    </xsl:template>

    <xsl:template
        match="@xml:base | @which | @orig-group | @orig-href | @orig-n | @q | 
        tan:name[@norm] | tan:token-definition/node() | tan:error"
        mode="remove-undefined-nodes"/>
    
    <xsl:template match="@n" mode="remove-undefined-nodes">
        <xsl:variable name="orig-val" select="(../@orig-n, .)[1]"/>
        <xsl:attribute name="n" select="$orig-val"/>
    </xsl:template>

    <xsl:template match="/">
        <xsl:apply-templates select="$self-resolved" mode="remove-undefined-nodes"/>
    </xsl:template>
    
</xsl:stylesheet>
