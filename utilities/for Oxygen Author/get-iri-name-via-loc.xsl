<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:tan="tag:textalign.net,2015:ns" version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="tan:name">
        <xsl:variable name="this-indent" select="preceding-sibling::node()[1]/self::text()"/>
        <xsl:variable name="loc-search" select="tan:search-for-scripta(., 10)"/>
        <xsl:variable name="loc-results"
            select="tan:search-results-to-IRI-name-pattern($loc-search)"/>
        <xsl:copy-of select="."/>
        <xsl:copy-of select="$loc-results"/>
    </xsl:template>
</xsl:stylesheet>
