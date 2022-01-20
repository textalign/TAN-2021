<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="#all" version="3.0">


    <!-- Oxygen action to add one <lm> per <tok> with @val, to be inserted into
        <ana> as its last child -->

    <xsl:mode default-mode="#unnamed" on-no-match="shallow-skip"/>

    <xsl:template match="tan:ana[tan:tok[@val]]">
        <xsl:apply-templates select="tan:tok/@val => distinct-values()" mode="tok-to-lm"/>
    </xsl:template>

    <xsl:mode name="tok-to-lm" on-no-match="shallow-skip"/>

    <xsl:template match=".[. castable as xs:string]" mode="tok-to-lm">
        <lm>
            <l>
                <xsl:value-of select="."/>
            </l>
        </lm>
    </xsl:template>

</xsl:stylesheet>
