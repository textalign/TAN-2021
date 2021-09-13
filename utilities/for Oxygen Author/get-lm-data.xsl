<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="tan:ana">
        <xsl:variable name="detected-langs" as="xs:string*"
            select="
                if (exists(tan:for-lang)) then
                    tan:for-lang
                else
                    '*'"
        />
        <xsl:variable name="tok-vals-of-interest"
            select="
                if (exists(*:val)) then
                    *:val
                else
                    tan:tok/@val"
        />
        <xsl:variable name="distinct-toks" select="distinct-values($tok-vals-of-interest)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node() except (tan:for-lang, *:val)"/>
            <xsl:comment select="'Detected language', $detected-langs"/>
            <xsl:for-each select="$distinct-toks">
                <xsl:comment select="'lm data for', ."/>
                <xsl:copy-of select="tan:lm-data(., $detected-langs)//tan:lm"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
