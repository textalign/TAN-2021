<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="tag:textalign.net,2015:ns"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0"
    exclude-result-prefixes="#all">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="/tan:TAN-A-lm">
        <xsl:variable name="for-langs" select="*/tan:for-lang"/>
        <xsl:variable name="this-src" select="tan:get-1st-doc(tan:head/tan:source)"/>
        <xsl:variable name="src-lang"
            select="$this-src/*/(tei:text/tei:body, tan:body)/@xml:lang"/>
        <xsl:variable name="detected-langs" as="xs:string*">
            <xsl:choose>
                <xsl:when test="exists($for-langs)">
                    <xsl:value-of select="$for-langs"/>
                </xsl:when>
                <xsl:when test="exists($src-lang)">
                    <xsl:value-of select="$src-lang"/>
                </xsl:when>
                <xsl:otherwise>*</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:for-each select="$detected-langs">
            <for-lang>
                <xsl:value-of select="."/>
            </for-lang>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
