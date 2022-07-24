<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">

    <!-- TAN Function Library TEI functions. -->
    
    <!-- A great deal of the TAN function library already applies to TEI files, insofar
        as they fit the TAN-TEI profile. In many cases, however, one wishes to do things
        with TEI as part of a larger workflow. This library is devoted to TEI-specific
        functionality that falls outside the strict scope of validation.
    -->

    <!-- Frequently the output of tan:diff() and tan:collate() will want to be
        rendered in one of TEI's methods for critical apparatus
        https://www.tei-c.org/release/doc/tei-p5-doc/en/html/TC.html
        viewed
    -->


    <xsl:function name="tan:diff-or-collate-to-tei" as="item()*" visibility="public">
        <!-- One-param version of the fuller one, below -->
        <xsl:param name="diff-or-collate-results" as="element()?"/>
        <xsl:sequence select="tan:diff-or-collate-to-tei($diff-or-collate-results, 1)"/>
    </xsl:function>
    
    <xsl:function name="tan:diff-or-collate-to-tei" as="item()*" visibility="public">
        <!-- Input: the results of tan:diff() or tan:collate(); an integer representing a particular
            method of TEI encoding -->
        <!-- Output: the results converted to TEI -->
        <!-- One can encode an apparatus criticus in numerous ways in TEI. A set of configuration
            profiles are offered here, to anticipate common needs. If you do not see a particular
            configuration to your taste, you may request one, or use the examples below to write
            your own. -->
        <!-- Configuration profiles:
            1 (default) - each 
        -->
        <!--kw: html, diff, tei -->
        <xsl:param name="diff-or-collate-results" as="element()?"/>
        <xsl:param name="configuration-profile" as="xs:integer"/>

    </xsl:function>


</xsl:stylesheet>
