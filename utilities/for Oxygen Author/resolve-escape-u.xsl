<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:tan="tag:textalign.net,2015:ns" version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:param name="escape-u-regex" as="xs:string">\\u\{([^\}]+)\}</xsl:param>
    <xsl:template match="text()">
        <xsl:analyze-string select="." regex="{$escape-u-regex}">
            <xsl:matching-substring>
                <xsl:value-of select="tan:process-regex-escape-u(regex-group(1))"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
</xsl:stylesheet>
