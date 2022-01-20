<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="#all" default-mode="remove-comments"
    version="3.0">

    <xsl:mode name="remove-comments" on-no-match="shallow-copy"/>
    <xsl:template match="comment()" mode="remove-comments"/>
    <xsl:template match="_caret" mode="remove-comments">
        <xsl:value-of select="'${caret}'"/>
    </xsl:template>
    
</xsl:stylesheet>
