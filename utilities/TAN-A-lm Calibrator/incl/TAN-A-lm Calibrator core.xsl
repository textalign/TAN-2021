<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for calibrating TAN-A-lm files. -->
    
    <xsl:include href="../../../functions/TAN-function-library.xsl"/>
    

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:calibrate-tan-a-lm-certainty'"/>
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-name" select="'TAN-A-lm Calibrator'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'recalibrates TAN-A-lm certainty'"/>
    <xsl:param name="tan:stylesheet-change-message" select="'Calibrated certainty in TAN-A-lm files.'"/>
    <xsl:param name="tan:stylesheet-description">This application is useful when editing TAN-A-lm
        files. Very frequently, when using local language resources to generate a fresh TAN-A-lm
        file for a class-1 file, the results are very dirty. Cleaning up the file normally involves
        deleting many entries, so that alternative options' certainty rates no longer add to a whole
        1.0. Or perhaps certainty has not even been set, and it needs to be added. This application
        will refresh the certainty rates of a TAN-A-lm, making it more useful for applications that
        rely on certainty rates for scoring, such Tangram. A second way this may be useful is for
        edits to language-specific TAN-A-lm file, where you might be recalibrating the certainty
        values of some lm combinations. Perhaps a wordform that has ten lexicomorphological
        resolutions, each one with a detailed @cert value. You want to promote one of the options as
        being slightly more probable, but you do not want to recalculate all the values so they add
        to 1.0. You can increase or decrease the @cert value of an option, then run the file through
        this application to recalibrate all entries so they add to 1.0 certainty.</xsl:param>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any TAN-A-lm file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">none</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">the TAN-A-lm file with
        certainty recalibrated</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>
    
    
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2021-04-20">Look at ways to adjust tok certainty</comment>
        </to-do>
    </xsl:param>
    

    <!-- The application -->
    
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:apply-templates select="/" mode="calibrate-lm-certainty"/>
    </xsl:variable>
    
    <xsl:mode name="calibrate-lm-certainty" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:ana" mode="calibrate-lm-certainty">
        <xsl:variable name="ana-without-certs" as="element()">
            <xsl:copy>
                <xsl:copy-of select="@* except (@cert, @cert2)"/>
                <xsl:copy-of select="node()"/>
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="certainty-arrays" as="array(*)*" select="tan:ana-lm-arrays(.)"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="certainty-arrays" tunnel="yes" select="$certainty-arrays"/>
                <xsl:with-param name="context-cert-sum" as="xs:decimal" select="
                        sum(for $i in $certainty-arrays
                        return
                            $i(3))"/>
                <xsl:with-param name="context-cert2-sum" as="xs:decimal" select="
                        sum(for $i in $certainty-arrays
                        return
                            $i(4))"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:lm | tan:l | tan:m" mode="calibrate-lm-certainty">
        <xsl:param name="certainty-arrays" tunnel="yes" as="array(*)*"/>
        <xsl:param name="context-cert-sum" as="xs:decimal"/>
        <xsl:param name="context-cert2-sum" as="xs:decimal"/>
        <xsl:variable name="this-id" as="xs:string" select="generate-id(.)"/>
        <xsl:variable name="this-name" as="xs:string" select="local-name(.)"/>
        <xsl:variable name="array-pos-of-interest" as="xs:integer"
            select="index-of(('lm', 'l', 'm'), $this-name) + 5"/>
        <xsl:variable name="these-certainty-arrays" as="array(*)*"
            select="$certainty-arrays[.($array-pos-of-interest) eq $this-id]"/>
        <xsl:variable name="this-cert" as="xs:decimal" select="
                sum(for $i in $these-certainty-arrays
                return
                    $i(3)) div $context-cert-sum"/>
        <xsl:variable name="this-cert2" as="xs:decimal" select="
                sum(for $i in $these-certainty-arrays
                return
                    $i(4)) div $context-cert2-sum"/>
        <xsl:copy>
            <xsl:copy-of select="@* except (@cert, @cert2)"/>
            <xsl:if test="$this-cert lt 1">
                <xsl:attribute name="cert" select="$this-cert"/>
            </xsl:if>
            <xsl:if test="$this-cert2 ne $this-cert">
                <xsl:attribute name="cert2" select="$this-cert2"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$this-name eq 'lm'">
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="certainty-arrays" as="array(*)*" tunnel="yes"
                            select="$these-certainty-arrays"/>
                        <xsl:with-param name="context-cert-sum" as="xs:decimal" select="
                                sum(for $i in $these-certainty-arrays
                                return
                                    $i(3))"/>
                        <xsl:with-param name="context-cert2-sum" as="xs:decimal" select="
                                sum(for $i in $these-certainty-arrays
                                return
                                    $i(4))"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:variable name="output-pass-2" as="document-node()" select="tan:update-TAN-change-log($output-pass-1)"/>

    <!-- Main output -->
    <xsl:param name="output-diagnostics-on" static="yes" as="xs:boolean" select="false()"/>
    <xsl:output indent="yes" use-character-maps="tan:see-special-chars" use-when="$output-diagnostics-on"/>
    
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Output diagnostics on for ' || static-base-uri()"/>
        <diagnostics>
            <output-pass-1><xsl:copy-of select="$output-pass-1"/></output-pass-1>
            <output-pass-2><xsl:copy-of select="$output-pass-2"/></output-pass-2>
        </diagnostics>
    </xsl:template>
    
    <xsl:mode default-mode="#unnamed" on-no-match="shallow-copy"/>
    <xsl:template match="/">
        <xsl:document>
            <xsl:apply-templates select="$output-pass-2/node()"/>
        </xsl:document>
    </xsl:template>
    <xsl:template match="/node()">
        <xsl:text>&#xa;</xsl:text>
        <xsl:next-match/>
    </xsl:template>
    
    
</xsl:stylesheet>
