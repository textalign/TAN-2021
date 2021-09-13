<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:value-of select="down/preceding-sibling::text()"/>
            <xsl:value-of select="up/following-sibling::text()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
