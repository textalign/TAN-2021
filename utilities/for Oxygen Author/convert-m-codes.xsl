<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    
    <xsl:param name="new-TAN-mor-uri" as="xs:string"/>
    
    <!-- Oxygen action to convert <m>s to another morphological system -->
    
    <xsl:variable name="this-file-converted" as="document-node()?" select="tan:convert-TAN-A-lm-codes(/, $new-TAN-mor-uri)"/>
    
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="exists($this-file-converted/*)">
                <xsl:copy-of select="$this-file-converted/*"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="*"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
