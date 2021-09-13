<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Core application for creating a TAN-A-lm file. -->
    
    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    
    <xsl:output indent="yes"/>
    
    <!--<xsl:param name="tan:distribute-vocabulary" as="xs:boolean" select="not($retain-morphological-codes-as-is)"/>-->
    
    <!-- About this stylesheet -->
    
    <!-- The predecessor to this stylesheet is tag:textalign.net,2015:stylesheet:create-quotations-from-tan-a -->
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:application:convert-tan-file'"/>
    <xsl:param name="tan:stylesheet-name" as="xs:string" select="'Updater'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'converts TAN files from older versions to the current version'"/>
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any TAN file version 2020</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">none</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">the TAN file converted to
        the latest version</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>
    
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
        </to-do>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="'Converted ' || $tan:doc-id || ' to version 2021'"
    />
    
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:document>
            <xsl:apply-templates mode="convert-tan"/>
        </xsl:document>
    </xsl:variable>
    
    <xsl:mode name="convert-tan" on-no-match="shallow-copy"/>
    <xsl:mode name="tan-2020-to-2021" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*[@TAN-version eq '2020']" mode="convert-tan">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="tan-2020-to-2021"/>
            <xsl:apply-templates select="node()" mode="tan-2020-to-2021"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@TAN-version" mode="tan-2020-to-2021">
        <xsl:attribute name="TAN-version" select="'2021'"/>
    </xsl:template>
    
    <xsl:template match="tan:TAN-mor/tan:head/tan:vocabulary-key/tan:feature[not(tan:IRI)]"
        mode="tan-2020-to-2021"/>
    
    <xsl:template match="tan:TAN-mor/tan:body[not(tan:category)]" mode="tan-2020-to-2021">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates
                select="preceding-sibling::tan:head/tan:vocabulary-key/tan:feature[not(tan:IRI)]"
                mode="move-features-to-body"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@m-has-features" mode="tan-2020-to-2021">
        <xsl:attribute name="m-has-codes" select="."/>
    </xsl:template>
    <xsl:template match="@m-has-how-many-features" mode="tan-2020-to-2021">
        <xsl:attribute name="m-has-how-many-codes" select="."/>
    </xsl:template>
    <xsl:template match="tan:category/@type" mode="tan-2020-to-2021">
        <xsl:variable name="this-val" as="xs:string" select="."/>
        <xsl:variable name="this-vocab-key-item" as="element()?"
            select="root(.)/tan:TAN-mor/tan:head/tan:vocabulary-key/tan:feature[@xml:id eq $this-val]"/>
        <xsl:variable name="feature-value" as="xs:string" select="
                if (exists($this-vocab-key-item)) then
                    replace(($this-vocab-key-item/(@which, tan:name))[1], ' ', '_')
                else
                    ."/>
        <xsl:attribute name="feature" select="$feature-value"/>
    </xsl:template>
    <xsl:template match="tan:category/tan:feature" mode="tan-2020-to-2021">
        <xsl:variable name="this-type" as="xs:string" select="@type"/>
        <xsl:variable name="this-vocab-key-item" as="element()?"
            select="root(.)/tan:TAN-mor/tan:head/tan:vocabulary-key/tan:feature[@xml:id eq $this-type]"/>
        <xsl:variable name="feature-value" as="xs:string" select="
                if (exists($this-vocab-key-item)) then
                    replace(($this-vocab-key-item/(@which, tan:name))[1], ' ', '_')
                else
                    @type"/>
        <code>
            <xsl:attribute name="feature" select="$feature-value"/>
            <val>
                <xsl:value-of select="@code"/>
            </val>
        </code>
    </xsl:template>
    
    
    
    <xsl:mode name="move-features-to-body" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:feature" mode="move-features-to-body">
        <xsl:variable name="this-xmlid" select="@xml:id"/>
        <xsl:variable name="this-alias" select="../tan:alias[contains-token(@idrefs, $this-xmlid)]"/>
        <xsl:variable name="this-code" select="($this-alias/(@id, @xml:id), $this-xmlid)[1]"/>
        <code>
            <xsl:attribute name="feature" select="replace(@which, ' ', '_')"/>
            <val>
                <xsl:value-of select="$this-code"/>
            </val>
        </code>
    </xsl:template>
    
    
    <xsl:variable name="final-output" as="document-node()" select="tan:update-TAN-change-log($output-pass-1)"/>
    
    
    <xsl:template match="/">
        <!-- primary output -->
        <xsl:choose>
            <xsl:when test="not(exists(tan:*))">
                <xsl:message select="'This application may be applied only to TAN files'"/>
                <xsl:sequence select="."/>
            </xsl:when>
            <xsl:when test="not(tan:*/@TAN-version eq '2020')">
                <xsl:message select="'This application supports only TAN files version 2020'"/>
                <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$final-output" mode="tan:doc-nodes-on-new-lines"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
