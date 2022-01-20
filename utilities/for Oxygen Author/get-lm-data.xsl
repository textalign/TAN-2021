<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="#all"
    version="3.0">
    
    <!-- Oxygen Author action to be applied to an <ana> that has a <_mark> that
        should be refactored with LM data. -->
    
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    
    <xsl:mode default-mode="#unnamed" on-no-match="shallow-skip"/>
    
    <!-- There are problems with the Oxygen element; see https://www.oxygenxml.com/forum/topic23394.html -->
    <!--<xsl:param name="use-fn-oxy-current-element" as="xs:boolean" select="false()"/>-->
    
    <xsl:template match="/ | /*" priority="1">
        
        <xsl:variable name="mark-holder" as="element()?" select="descendant::*[*:_mark]"/>

        <xsl:apply-templates select="descendant-or-self::*:_mark" mode="mark-to-lm-data"/>
        
    </xsl:template>
    
    <xsl:variable name="morphology-base-uri" as="xs:anyURI" select="tan:base-uri($tan:morphologies-resolved[1])"/>
    <xsl:variable name="for-langs" as="element()*" select="root()/tan:TAN-A-lm/tan:head/tan:for-lang"/>
    <xsl:variable name="source-lang" as="xs:string*" select="
            if (exists($for-langs)) then
                $for-langs
            else
                tan:get-1st-doc(root()/tan:TAN-A-lm/tan:head/tan:source)/*/(tei:text/tei:body, tan:body)/@xml:lang"
    />
    
    <xsl:mode name="mark-to-lm-data" on-no-match="shallow-copy"/>
    
    <xsl:template match="*:_mark" mode="mark-to-lm-data">
        <xsl:variable name="detected-langs" as="xs:string*" select="
                if (exists($source-lang)) then
                    $source-lang
                else
                    '*'"/>
        <xsl:variable name="preceding-siblings" as="element()*" select="preceding-sibling::*"/>
        <xsl:variable name="tok-vals-of-interest" as="xs:string*" select="
                if (matches(@val, '\S')) then
                    tokenize(normalize-space(@val), ' ')
                else
                    $preceding-siblings/self::tan:tok/@val"/>
        <xsl:variable name="distinct-toks" select="distinct-values($tok-vals-of-interest)"/>

        <xsl:message select="
                'Detected language ' || string-join(for $i in $detected-langs
                return
                    $i || ' (' || tan:lang-name($i) || ')', ', ') || ', searching for: ' || string-join($distinct-toks, ', ')"/>
        <xsl:for-each select="$distinct-toks">
            <xsl:variable name="lm-data" as="element()*" select="tan:lm-data(., $detected-langs)"/>
            <xsl:variable name="lm-data-converted" as="element()*"
                select="tan:convert-lm-data-output($lm-data, $morphology-base-uri)"/>
            
            <xsl:apply-templates select="$lm-data-converted" mode="trim-lm-output"/>
        </xsl:for-each>

    </xsl:template>
    
    <xsl:mode name="trim-lm-output" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:lm" mode="trim-lm-output">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="parent::tan:ana/comment()"/>
            <xsl:copy-of select="node()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
