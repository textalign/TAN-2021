<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://docbook.org/ns/docbook" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:docbook="http://docbook.org/ns/docbook" 
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">
    
    <xsl:mode name="app-and-utils-to-docbook" on-no-match="shallow-skip"/>
    
    
    <xsl:template match="/*" mode="app-and-utils-to-docbook">
        <xsl:variable name="stop-comments" as="comment()*" select="/*/comment()[contains(., 'PARAMETERS')]"/>
        <xsl:variable name="current-base-uri" as="xs:anyURI" select="base-uri(.)"/>
        <xsl:variable name="uri-from-guidelines" as="xs:string"
            select="tan:uri-relative-to($current-base-uri, $target-base-uri-for-guidelines)"/>
        <section xml:id="{replace(tan:cfn(.), '(%20|\+)', '_')}">
            <title><xsl:value-of select="replace(tan:cfn(.), '%20', ' ')"/></title>
            <para>
                <emphasis>Location: </emphasis>
                <link xlink:href="{$uri-from-guidelines}">
                    <xsl:value-of select="replace($current-base-uri, '.+(applications|utilities)(/.+)', '$1$2')"/>
                </link>
            </para>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="stop-comments" tunnel="yes" select="$stop-comments"/>
            </xsl:apply-templates>
        </section>
    </xsl:template>
    
    <xsl:template match="/*/comment()" priority="3" mode="app-and-utils-to-docbook">
        <xsl:param name="stop-comments" tunnel="yes" as="comment()*"/>
        <xsl:variable name="this-comment" as="comment()" select="."/>
        <xsl:if test="
            not((some $i in $stop-comments
            satisfies $this-comment >> $i))">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="/*/comment()[matches(., '^\s*(Welcome to|This is the public interface|PARAMETERS)')]" priority="4"
        mode="app-and-utils-to-docbook"/>

    <!--<xsl:variable name="app-util-emphasis-regex" as="xs:string" select="'^\s*(((Primary|Secondary) (in|out)put)|Version): '"/>-->
    
    <xsl:template match="/*/comment()[matches(., '^[A-Z :-]+$')]" mode="app-and-utils-to-docbook" priority="1">
        <para>
            <emphasis role="bold">
                <xsl:value-of select="tan:initial-upper-case(.)"/>
            </emphasis>
        </para>
    </xsl:template>
    
    <xsl:template match="/*/comment()" mode="app-and-utils-to-docbook">
        <xsl:param name="stop-comments" tunnel="yes" as="comment()*"/>
        <xsl:variable name="output-pass-1" as="element()" select="tan:text-to-structure(.)"/>
        <xsl:variable name="output-pass-2" as="element()">
            <xsl:apply-templates select="$output-pass-1"
                mode="adjust-docbook-output-for-apps-and-utils"/>
        </xsl:variable>

        <para>
            <xsl:apply-templates select="$output-pass-2/node()" mode="tan:prep-string-for-docbook"/>
        </para>

    </xsl:template>
    
    <xsl:mode name="adjust-docbook-output-for-apps-and-utils" on-no-match="shallow-copy"/>
    <xsl:template match="text()[1]" mode="adjust-docbook-output-for-apps-and-utils">
        <xsl:analyze-string select="." regex="^\s*([a-zA-Z -]+:) ">
            <xsl:matching-substring>
                <emphasis>
                    <xsl:value-of select="regex-group(1)"/>
                </emphasis>
                <xsl:value-of select="' '"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    <!--<xsl:template match="text()" mode="adjust-docbook-output-for-apps-and-utils">
        <xsl:analyze-string select="." regex="\n\s*(\*|\d+\.) ">
            
        </xsl:analyze-string>
    </xsl:template>-->
    
    <xsl:function name="tan:text-to-structure" as="element()" visibility="private">
        <!-- Input: any string -->
        <!-- Output: the string parsed for any structures, wrapped in an element -->
        <xsl:param name="input-string" as="xs:string"/>
        <xsl:variable name="pass-1" as="element()">
            <pass-1>
                <xsl:analyze-string select="$input-string" regex="(\n|^) *\* ">
                    <xsl:matching-substring>
                        <itemizedlist _level="1"/>
                        <listitem _level="2"/>
                        <para _level="3"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="(\n|^) *\d+\. ">
                            <xsl:matching-substring>
                                <orderedlist _level="1"/>
                                <listitem _level="2"/>
                                <para _level="3"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </pass-1>
        </xsl:variable>
        <xsl:variable name="pass-2" as="element()">
            <xsl:apply-templates select="$pass-1" mode="remove-extra-docbook-anchors"/>
        </xsl:variable>
        <xsl:variable name="pass-3" as="item()*" select="tan:sequence-to-tree($pass-2/node())"/>
        <structure>
            <xsl:copy-of select="$pass-3"/>
        </structure>
    </xsl:function>
    
    <xsl:mode name="remove-extra-docbook-anchors" on-no-match="shallow-copy"/>
    
    <xsl:template match="docbook:itemizedlist" mode="remove-extra-docbook-anchors">
        <xsl:if test="not(exists(preceding-sibling::docbook:itemizedlist))">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="docbook:orderedlist" mode="remove-extra-docbook-anchors">
        <xsl:if test="not(exists(preceding-sibling::docbook:orderedlist))">
            <xsl:copy-of select="."/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
