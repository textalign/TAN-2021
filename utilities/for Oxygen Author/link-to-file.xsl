<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="tag:textalign.net,2015:ns"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" version="3.0"
    exclude-result-prefixes="#all">
    <!-- This stylesheet presumes that an href has been inserted into the <head> in a <link-to> and an element name in <element-name> -->
    <!-- The result is a fragment that the oXygen author action will place before the <vocabulary-key> -->
    <xsl:template match="*:link-to">
        <xsl:variable name="this-link-to-resolved" select="resolve-uri(., @xml:base)"/>
        <xsl:variable name="this-link-to-doc" select="doc($this-link-to-resolved)"/>
        <xsl:variable name="this-element-name" as="xs:string" select="@element-name"/>
        <xsl:element name="{$this-element-name}" namespace="tag:textalign.net,2015:ns">
            <xsl:copy-of select="@xml:id"/>
            <IRI>
                <xsl:value-of select="$this-link-to-doc/*/@id"/>
            </IRI>
            <xsl:copy-of select="$this-link-to-doc/*/tan:head/tan:name"/>
            <xsl:copy-of select="$this-link-to-doc/*/tan:head/tan:desc"/>
            <location href="{.}" accessed-when="{current-date()}"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
