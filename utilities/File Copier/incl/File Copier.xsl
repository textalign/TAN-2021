<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for copying a file. -->
    
    <!-- July 2020: When you use this application in the context of an oXygen dialogue, you might prefer to type the 
        path directly into the bar. If you use the navigation feature you will be required to select a file that you wish 
        to overwrite. -->

    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    <xsl:output indent="no" use-character-maps="tan:see-special-chars"/>
    
    <xsl:variable name="target-uri-resolved" as="xs:anyURI" select="resolve-uri($target-uri, $tan:doc-uri)"/>
    

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:copy-tan-file'"/>
    <xsl:param name="tan:stylesheet-name" select="'File Copier'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'copies a file to a location, updating internal relative URLs'"/>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any XML file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">none</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">none</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">the file copied to the
        target location, but with all relative @hrefs revised in light of the target
        location</xsl:param>
    
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-change-message" select="'Copied file from', $tan:doc-uri, 'to', $target-uri-resolved"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>


    <!-- The application -->
    
    <xsl:variable name="self-pass-1" as="document-node()" select="
            if ($convert-relative-links-to-absolute) then
                tan:absolutize-hrefs(/, $tan:doc-uri)
            else
                /"/>
    
    <xsl:variable name="self-pass-2" select="
            if ($relativize-links-to-target)
            then
                tan:relativize-hrefs($self-pass-1, $target-uri-resolved)
            else
                $self-pass-1" as="document-node()"/>


    <!-- Main output -->
    
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="false()">
                <!-- reserved for error reporting -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="tan:save-as">
                    <xsl:with-param name="document-to-save" select="$self-pass-2"/>
                    <xsl:with-param name="target-uri" select="$target-uri-resolved"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
