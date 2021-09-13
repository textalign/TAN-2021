<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:tan="tag:textalign.net,2015:ns" version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="tan:name">
        <xsl:variable name="this-indent" select="preceding-sibling::node()[1]/self::text()"/>
        <xsl:variable name="viaf-search" select="tan:search-for-persons(., 10)"/>
        <xsl:variable name="viaf-results"
            select="tan:search-results-to-IRI-name-pattern($viaf-search)"/>
        <xsl:copy-of select="."/>
        <xsl:copy-of select="$viaf-results"/>
        <!--<xsl:if test="exists($viaf-results)">
            <xsl:value-of select="$this-indent"/>
            <xsl:comment>Viaf checks</xsl:comment>
            <xsl:value-of select="$this-indent"/>
            <xsl:for-each select="$viaf-results">
                <xsl:value-of select="$this-indent"/>
                <xsl:comment><xsl:text>Viaf result #</xsl:text><xsl:value-of select="position()"/></xsl:comment>
                <xsl:copy-of select="*"/>
                <xsl:value-of select="$this-indent"/>
            </xsl:for-each>
        </xsl:if>-->
    </xsl:template>
</xsl:stylesheet>
