<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all" version="3.0">

    <xsl:include href="../../../functions/TAN-function-library.xsl"/>
    
    <xsl:param name="chop-at-regex" select="$tan:word-end-regex"/>
    <xsl:param name="keep" as="xs:string" select="'1 - last'"/>
    <xsl:param name="shallow-skip" as="xs:boolean" select="false()"/>
    
    <xsl:template match="*">
        <xsl:choose>
            <xsl:when test="not($shallow-skip)">
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="text()">
        <xsl:variable name="text-chopped" select="tan:chop-string(., $chop-at-regex)"/>
        <xsl:variable name="keep-nos" select="tan:expand-numerical-expression($keep, count($text-chopped))"/>
        <xsl:value-of select="string-join($text-chopped[position() = $keep-nos], '')"/>
    </xsl:template>
</xsl:stylesheet>
