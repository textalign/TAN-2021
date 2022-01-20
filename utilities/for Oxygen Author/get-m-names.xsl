<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:import href="../../functions/TAN-function-library.xsl"/>
    
    <!-- Oxygen action to convert <m>s with  -->
    
    <xsl:mode default-mode="#unnamed" on-no-match="shallow-skip"/>
    
    <!-- There are problems with the Oxygen element; see https://www.oxygenxml.com/forum/topic23394.html -->
    <xsl:param name="use-fn-oxy-current-element" as="xs:boolean" select="false()"/>
    
    <!--<xsl:template match="/ | /*" priority="1">
        <xsl:apply-templates select="descendant::*[_mark]"/>
    </xsl:template>-->
    
    <xsl:variable name="for-langs" as="element()*" select="root()/tan:TAN-A-lm/tan:head/tan:for-lang"/>
    <xsl:variable name="source-lang" as="xs:string*" select="
            if (exists($for-langs)) then
                $for-langs
            else
                tan:get-1st-doc(root()/tan:TAN-A-lm/tan:head/tan:source)/*/(tei:text/tei:body, tan:body)/@xml:lang"
    />
    
    <xsl:template match="*[@morphology]" priority="1">
        <xsl:variable name="current-morphology" as="xs:string*"
            select="@morphology => normalize-space() => tokenize(' ')"/>
        <xsl:variable name="morph-voc" as="element()*" select="tan:vocabulary('morphology', $current-morphology)"/>
        <xsl:variable name="current-tan-mor" as="document-node()*" select="tan:get-1st-doc($morph-voc/tan:item)"/>
        <xsl:variable name="current-tan-mor-resolved" as="document-node()*" select="
                for $i in $current-tan-mor
                return
                    tan:resolve-doc($i)"/>
        <xsl:next-match>
            <xsl:with-param name="tan-mors-resolved" tunnel="yes" select="$current-tan-mor-resolved"/>
        </xsl:next-match>
        
    </xsl:template>
    
    <xsl:template match="*[_refactor]">
        <!--<xsl:param name="tan-mors-resolved" tunnel="yes" as="document-node()*"/>
        
        <xsl:variable name="current-morphology" as="xs:string*"
            select="ancestor-or-self::*[@morphology][1]/@morphology => normalize-space() => tokenize(' ')"
        />
        <xsl:variable name="morph-voc" as="element()*" select="tan:vocabulary('morphology', $current-morphology)"/>
        <xsl:variable name="current-tan-mor" as="document-node()*" select="tan:get-1st-doc($morph-voc/tan:item)"/>
        <xsl:variable name="current-tan-mor-resolved" as="document-node()*" select="
                for $i in $current-tan-mor
                return
                    tan:resolve-doc($i)"/>-->
        <!--<xsl:copy>
            <xsl:copy-of select="@*"/>
            <!-\-<xsl:comment>
                <xsl:value-of select="'morphology: ' || $current-morphology"/>
            </xsl:comment>-\->
            <!-\-<xsl:comment>
                <xsl:value-of select="'voc item: ' || serialize($morph-voc)"/>
            </xsl:comment>-\->
            <!-\-<xsl:comment>
                <xsl:value-of select="'morphologies: ' || serialize(tan:shallow-copy($current-tan-mor-resolved, 4))"/>
            </xsl:comment>-\->
            <!-\-<xsl:apply-templates mode="tan:get-m-names">
                <!-\\-<xsl:with-param name="tan-mors-resolved" tunnel="yes" select="$current-tan-mor-resolved"/>-\\->
            </xsl:apply-templates>-\->
        </xsl:copy>-->
        <xsl:apply-templates select="." mode="tan:get-m-names"/>
    </xsl:template>
    
    <xsl:mode name="tan:get-m-names" on-no-match="shallow-copy"/>
    <xsl:mode name="tan:get-m-names-2" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:m" mode="tan:get-m-names">
        <xsl:param name="tan-mors-resolved" tunnel="yes" as="document-node()*"/>
        <xsl:comment><xsl:apply-templates select="$tan-mors-resolved" mode="tan:get-m-names-2">
            <xsl:with-param name="codes" tunnel="yes" as="xs:string*" select="normalize-space(.) => tokenize(' ')"/>
        </xsl:apply-templates></xsl:comment>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:TAN-mor[tan:body[not(tan:category)]]" priority="1" mode="tan:get-m-names-2">
        <xsl:value-of select="'no category'"/>
    </xsl:template>
    
    <xsl:template match="tan:TAN-mor" mode="tan:get-m-names-2">
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="voc-head" tunnel="yes" select="tan:head"/>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="tan:category" mode="tan:get-m-names-2">
        <xsl:param name="codes" tunnel="yes" as="xs:string*"/>
        <xsl:param name="voc-head" tunnel="yes" as="element()"/>
        
        <xsl:variable name="this-cat-no" as="xs:integer" select="count(preceding-sibling::tan:category) + 1"/>
        <xsl:variable name="source-code" as="xs:string?" select="$codes[$this-cat-no]"/>
        <xsl:variable name="target-code" as="element()*" select="tan:code[tan:val = $source-code]"/>
        <xsl:for-each select="$target-code/@feature">
            <xsl:variable name="current-voc" as="element()*" select="tan:vocabulary('feature', for $i in $target-code/@feature return string($i), $voc-head)"/>
            <!--<xsl:variable name="current-voc" as="element()*" select="tan:attribute-vocabulary($target-code/@code)"/>-->
            
            <!--<xsl:value-of select="'category ' || string(position())"/>-->
            <!--<xsl:value-of select="'source code: ' || $source-code"/>-->
            <!--<xsl:value-of select="'target code: ' || $target-code => serialize()"/>-->
            <!--<xsl:value-of select="string-join($target-code/@feature, ' ')"/>-->
            <!--<xsl:value-of select="'current voc: ' || serialize($current-voc)"/>-->
            
            <xsl:value-of select="$current-voc/tan:item/tan:name[1] || '  '"/>
            
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="_refactor" mode="#all"/>
    
</xsl:stylesheet>
