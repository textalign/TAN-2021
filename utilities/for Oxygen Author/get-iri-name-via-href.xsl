<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="tag:textalign.net,2015:ns"
    xmlns:tan="tag:textalign.net,2015:ns" version="3.0" exclude-result-prefixes="#all">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="tan:*[@href or tan:location]">
        <xsl:variable name="referenced-doc" select="tan:get-1st-doc(.)"/>
        <xsl:variable name="this-href" select="(@href, tan:location/@href)[1]"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="$referenced-doc/*/@id"/>
            <xsl:copy-of select="$referenced-doc/*/tan:head/tan:name"/>
            <xsl:copy-of select="$referenced-doc/*/tan:head/tan:desc"/>
            <location accessed-when="{$tan:today-iso}" href="{$this-href}"/>
            <xsl:copy-of select="tan:location[position() gt 1]"/>
            <!-- tan:uri-relative-to(@href, $doc-uri) -->
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@id">
        <IRI>
            <xsl:value-of select="."/>
        </IRI>
    </xsl:template>
    <xsl:template match="@href"/>
</xsl:stylesheet>
