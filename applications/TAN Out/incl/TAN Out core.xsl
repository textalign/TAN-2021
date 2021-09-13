<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for remodeling a text. -->

    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    
    <!-- Note: this stylesheet's default namespace is HTML, because it exclusively builds HTML output. -->

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:display-tan-as-html'"/>
    <xsl:param name="tan:stylesheet-name" as="xs:string" select="'TAN Out'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'exports TAN / TEI files'"/>
    <xsl:param name="tan:stylesheet-description">This utility exports a TAN or TEI file to
        other media. Currently only HTML is supported, optimized for JavaScript and CSS within the
        output/js and output/css directories in the TAN file structure.</xsl:param>
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any TAN or TEI
        file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">none</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">if no destination filename
        is specified, an HTML file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">if a destination filename
        is specified, an HTML file at the target location</xsl:param>
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2020-07-28">Need to wholly overhaul the default CSS and JavaScript files in output/css and output/js</comment>
            <comment who="kalvesmaki" when="2020-07-28">Need to build parameters to allow users to drop elements from the HTML DOM.</comment>
            <comment who="kalvesmaki" when="2020-09-05">Need to enrich output message with parameter settings.</comment>
            <comment who="kalvesmaki" when="2020-09-06">Need to support export to odt.</comment>
            <comment who="kalvesmaki" when="2020-09-06">Need to support export to docx.</comment>
            <comment who="kalvesmaki" when="2020-09-06">Need to support export to plain text.</comment>
        </to-do>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-09-05">Tested for TAN
            2021 release</change>
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-09-06">Changed name,
            adjusted descriptions</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="'Converted TAN ' || $tan:doc-uri || ' to HTML'"/>
    
    <xsl:variable name="output-directory-uri-resolved" as="xs:string"
        select="tan:uri-directory(resolve-uri($output-directory-uri, $calling-stylesheet-uri))"/>
    
    <xsl:variable name="target-secondary-output-destination" as="xs:string?" select="
            if (matches($output-target-filename, '\S')) then
                ($output-directory-uri-resolved || normalize-space($output-target-filename))
            else
                ()"/>
    
    
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:choose>
            <xsl:when test="$TAN-file-state eq 'expanded'">
                <xsl:apply-templates select="$tan:self-expanded[1]" mode="output-pass-1"/>
            </xsl:when>
            <xsl:when test="$TAN-file-state eq 'resolved'">
                <xsl:apply-templates select="$tan:self-resolved" mode="output-pass-1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not($TAN-file-state eq 'raw')">
                    <xsl:message select="'Unknown value ' || $TAN-file-state || ' for $TAN-file-state. Using default value, raw'"/>
                </xsl:if>
                <xsl:apply-templates select="$tan:orig-self" mode="output-pass-1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:mode name="output-pass-1" on-no-match="shallow-copy"/>
    
    <!-- Drop processing instructions -->
    <xsl:template match="processing-instruction()" mode="output-pass-1"/>
    
    
    <xsl:variable name="output-pass-2" as="document-node()"
        select="tan:revise-hrefs($output-pass-1, $tan:doc-uri, $html-template-uri-resolved)"/>
    
    <xsl:variable name="output-pass-3" as="document-node()" select="
            if ($use-function-prepare-to-convert-to-html) then
                tan:prepare-to-convert-to-html($output-pass-2)
            else
                $output-pass-2"/>
    
    <xsl:variable name="output-pass-4" as="document-node()"
        select="tan:convert-to-html($output-pass-3, $parse-text-for-urls)"/>
    
    <xsl:variable name="html-template-doc" as="document-node()"
        select="doc($html-template-uri-resolved)"/>
    <xsl:variable name="template-infused" as="document-node()">
        <xsl:apply-templates select="$html-template-doc" mode="infuse-html-template"/>
    </xsl:variable>
    
    <xsl:mode name="infuse-html-template" on-no-match="shallow-copy"/>
    
    <xsl:template match="html:body" mode="infuse-html-template">
        <xsl:variable name="matching-target-node" as="element()*" select="descendant::*[@id eq $target-id-for-html-content]"/>
        <xsl:if test="count($matching-target-node) gt 1">
            <xsl:message select="'There are ' || string(count($matching-target-node)) || ' matching target nodes in the HTML output.'"/>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="not(exists($matching-target-node))">
                <xsl:copy-of select="$output-pass-4"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="html:*[@id]" mode="infuse-html-template">
        <xsl:choose>
            <xsl:when test="@id eq $target-id-for-html-content">
                <xsl:copy-of select="$output-pass-4"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:variable name="output-pass-5" as="document-node()"
        select="tan:revise-hrefs($template-infused, $html-template-uri-resolved, $output-directory-uri-resolved)"
    />

    
    <!-- RESULT TREE -->
    <xsl:param name="output-diagnostics-on" static="yes" select="false()"/>
    <xsl:output method="xml" indent="yes" use-when="$output-diagnostics-on"/>
    <xsl:output indent="no" method="html" use-when="not($output-diagnostics-on)"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message
            select="'Using diagnostic output for application ' || $tan:stylesheet-name || ' (' || static-base-uri() || ')'"
        />
        <diagnostics>
            
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:message select="$tan:stylesheet-change-message"/>
        <xsl:if test="$tan:validation-mode-on">
            <xsl:message select="'Validation mode on; output will focus on errors and omit content'"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="exists($output-target-filename)">
                <xsl:result-document href="{$output-target-filename}">
                    <xsl:message select="'Saving to target ' || $output-target-filename"/>
                    <xsl:copy-of select="$output-pass-5"/>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$output-pass-5"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
