<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
    <!-- Catalyzing input: any file (including this one) -->
    <!-- Main input: key uri directories, collections in the TAN suite -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: master catalog files (collection.xml) at schemas/, functions/, and TAN-voc -->
    <!-- The resultant files are important for the function library and validation, which can use fn:collection() only in connection with an XML file listing the XML files available. -->
    <xsl:output indent="yes"/>
    <xsl:include href="../functions/TAN-function-library.xsl"/>
    
    <xsl:param name="tan:stylesheet-iri" select="'tag:textalign.net,2015:algorithm:collection-generator'"/>
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:change-message">Generating new collection.xml files for key TAN directories</xsl:param>
    
    <xsl:variable name="tan:tan-fl-master-file" as="document-node()" select="doc('../functions/TAN-function-library.xsl')"/>
    
    <xsl:variable name="tan:function-base-dir" select="tan:uri-directory(base-uri($tan:tan-fl-master-file))"
        as="xs:string"/>
    <xsl:variable name="tan:project-base-dir" select="tan:uri-directory(resolve-uri('..', static-base-uri()))"
        as="xs:string"/>
    
    <xsl:variable name="tan:all-include-or-import-hrefs" as="xs:string+">
        <xsl:apply-templates select="doc('')" mode="tan:include-and-import-hrefs"/>
    </xsl:variable>
    
    <xsl:mode name="tan:include-and-import-hrefs" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:error | tan:help | tan:warning | tan:fix | tan:fatal | tan:info"
        mode="tan:include-and-import-hrefs"/>
    <xsl:template match="xsl:include | xsl:import" mode="tan:include-and-import-hrefs">
        <xsl:sequence select="string(resolve-uri(@href, base-uri(.)))"/>
        <xsl:apply-templates mode="#current" select="doc(resolve-uri(@href, base-uri(.)))"/>
    </xsl:template>

    <xsl:variable name="tan:function-directories"
        select="distinct-values(tan:uri-directory($tan:all-include-or-import-hrefs))[starts-with(., $tan:function-base-dir)]"
        as="xs:string*"/>
    <xsl:variable name="tan:schema-directories" as="xs:string+" select="
            for $i in ('../schemas/', '../schemas/incl/')
            return
                resolve-uri($i, static-base-uri())"/>
    <xsl:variable name="tan:vocabulary-directories" as="xs:string+" select="
            for $i in ('../vocabularies/', '../vocabularies/extra/')
            return
                resolve-uri($i, static-base-uri())"/>

    <xsl:template match="/">
        <xsl:for-each-group
            select="$tan:function-directories, $tan:schema-directories, $tan:vocabulary-directories"
            group-by="analyze-string(., tan:escape($tan:project-base-dir) || '([^/]+/)')/*:match/*:group">
            <xsl:sort/>
            <xsl:variable name="this-base-dir"
                select="$tan:project-base-dir || current-grouping-key()" as="xs:string"/>
            <xsl:result-document href="{$this-base-dir}collection.xml">
                <collection stable="true">
                    <xsl:for-each select="current-group()">
                        <xsl:sort/>
                        <xsl:for-each
                            select="uri-collection(.)[not(matches(., '/collection\.xml$', 'i'))]">
                            <xsl:sort/>
                            <doc href="{tan:uri-relative-to(., $this-base-dir)}"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </collection>
            </xsl:result-document>
        </xsl:for-each-group> 
    </xsl:template>
</xsl:stylesheet>
