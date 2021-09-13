<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    <xsl:template match="tan:div[not(tan:div)]">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="tan:normalize-div-text(.)"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>