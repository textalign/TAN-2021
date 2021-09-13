<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns="tag:textalign.net,2015:ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:fn="http://www.w3.org/2005/xpath-functions" 
    xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- TAN Function Library diagnostic functions for schemas. -->
    
    <!--Functions for analyzing the TAN schemas, using ../../schemas/*.rng for analysis. This
                stylesheet is used primarily to generate the documentation, not for core validation,
                but it may be useful in other contexts.-->
    <xsl:variable name="tan:schema-uri-collection" as="xs:anyURI+"
        select="uri-collection('../../schemas'), uri-collection('../../schemas/incl')"/>
    <xsl:variable name="tan:schema-collection" as="document-node()+"
        select="
            for $i in $tan:schema-uri-collection
            return
                if (doc-available($i)) then
                    doc($i)
                else
                    ()"
    />
    <xsl:variable name="tan:rng-collection" select="$tan:schema-collection[rng:*]" as="document-node()+"/>
    <xsl:variable name="tan:rng-collection-without-TEI" as="document-node()+"
        select="$tan:rng-collection[not(matches(base-uri(.), 'TAN-TEI'))]"/>
    
    <xsl:function name="tan:get-parent-elements" as="element()*" visibility="private">
        <!-- requires as input some rng: element from $rng-collection, oftentimes an rng:element or rng:attribute -->
        <xsl:param name="current-elements" as="element()*"/>
        <xsl:variable name="elements-to-define" select="$current-elements[self::rng:define]"/>
        <xsl:choose>
            <xsl:when test="exists($elements-to-define)">
                <xsl:variable name="new-elements"
                    select="
                        for $i in $elements-to-define/@name
                        return
                            $tan:rng-collection-without-TEI//rng:ref[@name = $i]//(ancestor::rng:define,
                            ancestor::rng:element)[last()]"/>
                <xsl:copy-of
                    select="
                        tan:get-parent-elements((($current-elements except $current-elements[name(.) = 'define']),
                        $new-elements))"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$current-elements"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
</xsl:stylesheet>
