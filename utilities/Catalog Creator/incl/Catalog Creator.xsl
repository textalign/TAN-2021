<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Core application for creating a TAN-A-lm file. -->
    
    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    
    <xsl:output indent="yes"/>
    
    <!-- About this stylesheet -->
    
    <!-- The predecessor to this stylesheet is tag:textalign.net,2015:stylesheet:create-quotations-from-tan-a -->
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:create-catalog-file'"/>
    <xsl:param name="tan:stylesheet-name" as="xs:string" select="'Catalog Creator'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'creates an XML or TAN catalog of files'"/>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any XML file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">none</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">perhaps diagnostics</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">a new catalog file for
        select files in the input file's directory, and perhaps subdirectories; if the collection is
        TAN-only, the filename will be catalog.tan.xml, otherwise it will be catalog.xml</xsl:param>

    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
        </to-do>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="'Built catalog file.'"/>
    
    
    
    <!-- THE PROCESS -->
    
    <xsl:variable name="catalog-file-name" select="
            if ($tan-only) then
                'catalog.tan.xml'
            else
                'catalog.xml'"/>
    <xsl:variable name="target-base-relative-uri" select="tan:cfn(/)" as="xs:string"/>
    <xsl:variable name="target-base-resolved-uri" select="resolve-uri($target-base-relative-uri, base-uri(/*))" as="xs:string"/>
    <!-- We add one more / to the base directory, to trick the processor into thinking that the URI 
        for a catalog has not been read, even if it has. Without this extra touch, the processor will
        warn that the file has already been read. -->
    <xsl:variable name="target-base-directory" select="replace($target-base-resolved-uri, '[^/]+$', '/')"/>
    <xsl:variable name="target-url-resolved" select="resolve-uri($catalog-file-name,$target-base-resolved-uri)"/>
    
    <xsl:variable name="rnc-schema-uri-relative-to-this-stylesheet" as="xs:string"
        select="'../../../schemas/catalog.tan.rnc'"/>
    <xsl:variable name="sch-schema-uri-relative-to-this-stylesheet" as="xs:string"
        select="'../../../schemas/tan.sch'"/>
    
    <xsl:variable name="collection-search-param" select="
            '?select=*.' ||
            (if ($tan-only) then
                'xml'
            else
                '*') || (if ($index-deeply) then
                ';recurse=yes;on-error=ignore'
            else
                ())"/>
    
    <xsl:variable name="discovered-uri-collection" as="xs:anyURI*" select="
            uri-collection($target-base-directory || $collection-search-param)[not(matches(., '^catalog\.(tan\.)?xml$', 'i'))][if
            (matches($exclude-filenames-that-match-what-pattern, '\S')) then
                not(matches(., $exclude-filenames-that-match-what-pattern, 'i'))
            else
                true()][doc-available(.)]"/>
    
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:document>
            <xsl:if test="$tan-only">
                <xsl:processing-instruction name="xml-model"><xsl:text>href ="</xsl:text><xsl:value-of select="tan:uri-relative-to($rnc-schema-uri-relative-to-this-stylesheet, $target-base-resolved-uri)"/><xsl:text>" type="application/relax-ng-compact-syntax"</xsl:text></xsl:processing-instruction>
                <xsl:processing-instruction name="xml-model"><xsl:text>href ="</xsl:text><xsl:value-of select="tan:uri-relative-to($sch-schema-uri-relative-to-this-stylesheet, $target-base-resolved-uri)"/><xsl:text>" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:text></xsl:processing-instruction>
            </xsl:if>
            <collection stable="true" _target-format="xml-indent" _target-uri="{$target-base-directory || $catalog-file-name}">
                <xsl:attribute name="metadata-resolved" select="$include-fully-resolved-metadata"/>
                <xsl:message select="'Creating catalog file by searching for files in this directory: ', $target-base-directory"/>
                <xsl:message select="'Metadata should be fully resolved? ', $include-fully-resolved-metadata"/>
                <xsl:message select="'TAN files only: ', $tan-only"/>
                <xsl:if test="string-length($exclude-filenames-that-match-what-pattern) gt 0">
                    <xsl:message select="'Excluding filenames that match this pattern: ', $exclude-filenames-that-match-what-pattern"/>
                </xsl:if>
                <xsl:message select="string(count($discovered-uri-collection)) || ' URIs found'"/>

                <xsl:apply-templates select="$discovered-uri-collection" mode="uri-collection-to-doc"
                />
            </collection>
        </xsl:document>
    </xsl:variable>
    
    <xsl:mode name="uri-collection-to-doc" on-no-match="shallow-skip"/>
    
    <xsl:template match=".[. instance of xs:anyURI]" mode="uri-collection-to-doc">
        <xsl:variable name="this-base-uri" as="xs:anyURI" select="."/>
        <xsl:variable name="this-doc" as="document-node()" select="doc(.)"/>
        <xsl:variable name="this-is-tan" select="exists($this-doc/tan:*)"/>
        <xsl:if test="not($tan-only) or exists($this-doc/*/tan:head)">
            <doc href="{tan:uri-relative-to($this-base-uri, $target-base-directory)}">
                <xsl:copy-of select="$this-doc/*/@*"/>
                <xsl:copy-of select="$this-doc/*/tan:body/@*"/>
                <xsl:attribute name="root" select="name($this-doc/*)"/>
                <xsl:variable name="head-pass-1" as="node()*">
                    <xsl:choose>
                        <xsl:when test="$include-fully-resolved-metadata">
                            <xsl:variable name="this-doc-resolved" select="
                                    if ($this-is-tan) then
                                        tan:resolve-doc($this-doc, false(), ())
                                    else
                                        $this-doc"/>
                            <xsl:copy-of
                                select="$this-doc-resolved/(tei:TEI/tei:text, tan:*)/tei:body/@*"/>
                            <xsl:copy-of select="$this-doc-resolved/*/tan:head/*"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates
                                select="$this-doc/*/tan:head/tan:vocabulary-key/preceding-sibling::*"
                                mode="tan:resolve-href"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:copy-of select="
                        for $i in $head-pass-1
                        return
                            tan:revise-hrefs($i, $this-base-uri, $target-base-directory || $catalog-file-name)"
                />
            </doc>
        </xsl:if>
    </xsl:template>
    
    <xsl:output indent="yes"/>
    <xsl:template match="/">
        <xsl:call-template name="tan:save-as">
            <xsl:with-param name="document-to-save" select="$output-pass-1"/>
        </xsl:call-template>
    </xsl:template>
    
    
</xsl:stylesheet>
