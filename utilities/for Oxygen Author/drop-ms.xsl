<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="#all"
    version="3.0">
    <!--<xsl:import href="../../functions/TAN-function-library.xsl"/>-->
    
    <!-- Oxygen action to convert <m>s with  -->
    
    <xsl:mode default-mode="#unnamed" on-no-match="shallow-skip"/>
    
    <xsl:template match="*[_refactor]">
        <xsl:apply-templates select="." mode="tan:drop-ms"/>
    </xsl:template>
    
    <xsl:mode name="tan:drop-ms" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:lm[not(tan:m/*:_keep)] | tan:m[not(*:_keep)]" mode="tan:drop-ms">
        <xsl:comment select="serialize(.)"/>
    </xsl:template>
    
    <xsl:template match="_refactor | _keep" mode="#all"/>
    
</xsl:stylesheet>
