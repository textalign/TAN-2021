<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tan="tag:textalign.net,2015:ns" 
    version="3.0">
    <xsl:import href="incl/chop-string.xsl"/>
    <xsl:param name="chop-at-regex" select="$tan:clause-end-regex"/>
    <xsl:param name="keep" select="'2 - last'"/>
</xsl:stylesheet>
