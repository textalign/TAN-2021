<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- This subsidiary stylesheet changes common core output from the explore text function into an
        HTML page -->
    
    <xsl:character-map name="keep-javascript-chars">
        <!-- For retaining JavaScript characters -->
        <xsl:output-character character="&lt;" string="&lt;"/>
        <xsl:output-character character="&gt;" string="&gt;"/>
        <xsl:output-character character="&amp;" string="&amp;"/>
        <xsl:output-character character="&#xd;" string=""/>
    </xsl:character-map>
    
    <xsl:variable name="html-template-prepped" as="document-node()">
        <xsl:choose>
            <xsl:when test="doc-available($html-template-uri-resolved)">
                <xsl:apply-templates select="doc($html-template-uri-resolved)"
                    mode="embed-css-and-js"/>
            </xsl:when>
            <xsl:when test="doc-available('text-parallel-template.html')">
                <xsl:apply-templates select="doc('text-parallel-template.html')"
                    mode="embed-css-and-js"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:document>
                    <html>
                        <head>
                            <title>Text Parallels</title>
                        </head>
                        <body/>
                    </html>
                </xsl:document>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:mode name="embed-css-and-js" on-no-match="shallow-copy"/>
    
    <xsl:template match="html:script" mode="embed-css-and-js">
        <xsl:copy>
            <xsl:copy-of select="@* except @src"/>
            <xsl:value-of select="unparsed-text(resolve-uri(@src, base-uri(.)))"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="html:link[@rel eq 'stylesheet']" mode="embed-css-and-js">
        <style>
            <xsl:value-of select="unparsed-text(resolve-uri(@href, base-uri(.)))"/>
        </style>
    </xsl:template>
    
    
    
    <xsl:variable name="html-output-pass-1" as="document-node()">
        <xsl:apply-templates select="$html-template-prepped" mode="html-output-pass-1">
            <xsl:with-param name="final-results" as="document-node()*" tunnel="yes" select="$common-output-pass-5"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:mode name="html-output-pass-1" on-no-match="shallow-copy"/>
    
    <xsl:template match="html:body" mode="html-output-pass-1">
        <xsl:param name="final-results" as="document-node()*" tunnel="yes"
            select="$common-output-pass-5"/>
        
        <xsl:variable name="g1-ids" as="xs:string*" select="distinct-values($final-results/*/@src1)"
        />
        <xsl:variable name="g2-ids" as="xs:string*" select="distinct-values($final-results/*/@src2)"
        />
        
        <xsl:variable name="results-prepped-1" as="element()">
            <table id="results">
                <thead>
                    <xsl:apply-templates select="($final-results/*/tan:cluster[1])[1]" mode="results-to-thead-trs"/>
                </thead>
                <tbody>
                    <xsl:apply-templates select="$final-results" mode="results-to-trs"/>
                </tbody>
            </table>
        </xsl:variable>
        
        <!--<xsl:variable name="results-prepped-2" as="document-node()*"
            select="tan:prepare-to-convert-to-html($final-results)"/>-->
        
        <!--<xsl:variable name="results-html" as="document-node()*"
            select="tan:convert-to-html($results-prepped-2, true())"/>-->
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <div class="title"><xsl:value-of select="$preferred-html-title"/></div>
            <div class="subtitle"><xsl:value-of select="$preferred-html-subtitle"/></div>
            <div>
                <xsl:value-of select="$tan:stylesheet-name || ' run ' || $tan:today-MDY || ', ' || string(current-time())"/>
            </div>
            <h1>Summary</h1>
            <table id="summary">
                <thead>
                    <tr>
                        <th></th>
                        <xsl:for-each select="$g2-ids">
                            <th>
                                <xsl:value-of select="."/>
                            </th>
                        </xsl:for-each>
                    </tr>
                </thead>
                <tbody>
                    <xsl:for-each select="$g1-ids">
                        <xsl:variable name="this-g1-id" select="." as="xs:string"/>
                        <tr>
                            <td>
                                <xsl:value-of select="."/>
                            </td>
                            <xsl:for-each select="$g2-ids">
                                <xsl:variable name="this-g2-id" select="." as="xs:string"/>
                                <xsl:variable name="these-results" as="element()*"
                                    select="$final-results/*[@src1 eq $this-g1-id][@src2 eq $this-g2-id]"
                                />
                                <td>
                                    <xsl:choose>
                                        <xsl:when test="exists($these-results)">
                                            <xsl:value-of select="count($these-results/tan:cluster)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>—</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </td>
                            </xsl:for-each>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
            
            <h1>Results</h1>
            <div class="about-results">
                <div class="scores">
                    <xsl:apply-templates select="($final-results/*/tan:cluster/tan:scores)[1]" mode="build-html-about-results"/>
                </div>
            </div>
            
            <xsl:apply-templates select="$results-prepped-1" mode="#current"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:mode name="results-to-thead-trs" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:cluster[1]" mode="results-to-thead-trs">
        <tr>
            <th>Group 1</th>
            <th>Group 2</th>
            <xsl:apply-templates mode="#current"/>
        </tr>
    </xsl:template>
    
    <xsl:template match="tan:score/@method" mode="results-to-thead-trs">
        <th class="decimal">
            <xsl:value-of select="."/>
        </th>
    </xsl:template>
    
    <xsl:template match="tan:text" mode="results-to-thead-trs">
        <th>
            <xsl:value-of select="'text ' || string(count(preceding-sibling::tan:text) + 1)"/>
        </th>
    </xsl:template>
    
    <xsl:template match="tan:claim" mode="results-to-thead-trs">
        <th>
            <xsl:value-of select="'TAN-A claim'"/>
        </th>
    </xsl:template>
    
    
    <xsl:mode name="results-to-trs" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:cluster" mode="results-to-trs">
        <xsl:param name="g1-ids" tunnel="yes" as="xs:string?" select="parent::tan:ngrams/@src1"/>
        <xsl:param name="g2-ids" tunnel="yes" as="xs:string?" select="parent::tan:ngrams/@src2"/>
        <tr>
            <td>
                <xsl:value-of select="replace($g1-ids, '([.])', '$1&#x200B;')"/></td>
            <td>
                <xsl:value-of select="replace($g2-ids, '([.])', '$1&#x200B;')"/></td>
            <xsl:apply-templates mode="#current"/>
        </tr>
    </xsl:template>
    
    <xsl:template match="tan:score" mode="results-to-trs">
        <td>
            <xsl:apply-templates mode="#current"/>
        </td>
    </xsl:template>
    
    <xsl:template match="tan:text" mode="results-to-trs">
        <td>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="textno" as="xs:integer" tunnel="yes"
                    select="count(preceding-sibling::tan:text) + 1"/>
            </xsl:apply-templates>
        </td>
    </xsl:template>
    
    <xsl:template match="*:div | tan:tok" mode="results-to-trs">
        <div class="e-{name(.)}">
            <xsl:apply-templates select="@ref" mode="#current"/>
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:x/text() | tan:tok/text()" mode="results-to-trs">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <xsl:template match="@ref" mode="results-to-trs">
        <div class="a-ref">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:tok[tan:alias]" priority="1" mode="results-to-trs">
        <xsl:param name="textno" as="xs:integer?" tunnel="yes"
            select="count(ancestor::tan:text/preceding-sibling::tan:text) + 1"/>
        <xsl:variable name="this-n" select="xs:integer(@n)" as="xs:integer"/>
        <!-- If 1 then 2; if 2 then 1 --><!-- xs:integer(ceiling((1 div $this-n) + 0.1)) -->
        <xsl:variable name="other-text-no" select="
                if ($textno eq 1) then
                    't2'
                else
                    't1'"/>
        <xsl:variable name="those-ns" as="xs:integer*" select="
                for $i in (tan:other-n | tan:counterpart)
                return
                    xs:integer($i)"/>
        <div
            class="gram t{$textno}-{$this-n} {if (count($those-ns) gt 0) then 'counterparts' else ()}">
            <div class="e-tok" onclick="toggleNext(this)">
                <xsl:value-of select="text()"/>

            </div>
            <div class="e-aliases hide">
                <xsl:apply-templates select="tan:alias" mode="full-html"/>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:tok[tan:counterpart]" mode="results-to-trs">
        <xsl:param name="textno" as="xs:integer?" tunnel="yes"
            select="count(ancestor::tan:text/preceding-sibling::tan:text) + 1"/>
        <div class="counterparts t{$textno}-{@n}">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>
    
    <xsl:template match="tan:tok/tan:counterpart" mode="results-to-trs"/>
    
    <xsl:template match="tan:x" mode="results-to-trs">
        <xsl:variable name="next-tok" as="element()?" select="following-sibling::tan:tok[1]"/>
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::tan:tok[1]/tan:counterpart) and 
                (exists($next-tok/tan:counterpart) or not(exists($next-tok)))">
                <div class="counterparts e-x">
                    <xsl:value-of select="."/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div class="e-x">
                    <xsl:value-of select="."/>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    
    <xsl:variable name="this-stylesheet" as="document-node()" select="doc('')"/>
    <xsl:template match="tan:claim" mode="results-to-trs">
        <xsl:variable name="this-indented" as="item()*"
            select="tan:copy-indentation(., $this-stylesheet/*/*[1])"/>
        <td class="code">
            <xsl:value-of select="replace(serialize($this-indented), '&lt;', '&#x3c;')"/>
        </td>
    </xsl:template>
    
    <xsl:template match="tan:score/text()" mode="results-to-trs">
        <xsl:value-of select="format-number(., '0.000')"/>
    </xsl:template>
    
    
    
    <xsl:mode name="full-html" on-no-match="shallow-copy"/>
    
    <xsl:template match="*" mode="full-html">
        <div class="e-{name(.)}">
            <div class="label" onclick="toggleNext(this)">
                <xsl:value-of select="replace(name(.), '[_.-]|%20', ' ')"/>
            </div>
            <div class="val hide">
                <div class="attrs">
                    <xsl:apply-templates select="@*" mode="#current"/>
                </div>
                <xsl:apply-templates mode="#current"/>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="@*" mode="full-html">
        <div class="a-{name(.)}">
            <div class="label" onclick="toggleNext(this)">
                <xsl:value-of select="replace(name(.), '[_.-]|%20', ' ')"/>
            </div>
            <div class="val hide">
                <xsl:value-of select="."/>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="@source" mode="full-html">
        <div class="a-source">
            <div class="label">source</div>
            <div class="val"><a href="{.}"><xsl:value-of select="tan:cfne(string(.))"/></a></div>
        </div>
    </xsl:template>
    
    
    
    <xsl:mode name="build-html-about-results" on-no-match="shallow-skip"/>
    
    <xsl:template match="tan:score" mode="build-html-about-results">
        <div class="e-score">
            <xsl:apply-templates select="@method, @about" mode="#current"/>
        </div>
    </xsl:template>
    <xsl:template match="@method" mode="build-html-about-results">
        <div class="a-{name(.)}">
            <xsl:value-of select=". || ': '"/>
        </div>
    </xsl:template>
    <xsl:template match="@about" mode="build-html-about-results">
        <div class="a-{name(.)}">
            <xsl:value-of select="."/>
        </div>
    </xsl:template>
    
    
    
    <xsl:variable name="html-output-pass-2" as="document-node()">
        <xsl:apply-templates select="$html-output-pass-1" mode="html-output-pass-2"/>
    </xsl:variable>
    
    <xsl:mode name="html-output-pass-2" on-no-match="shallow-copy"/>
    
    <xsl:template match="html:th[@class = 'decimal']" priority="1" mode="html-output-pass-2">
        <th onclick="sortTableByNumber({count(preceding-sibling::html:th)},'{ancestor::html:table/@id}')">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </th>
    </xsl:template>
    
    <xsl:template match="html:th" mode="html-output-pass-2">
        <th onclick="sortTable({count(preceding-sibling::html:th)},'{ancestor::html:table/@id}')">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </th>
    </xsl:template>
    
    <xsl:template match="text()" mode="html-output-pass-2">
        <xsl:analyze-string select="." regex="%20">
            <xsl:matching-substring>
                <xsl:value-of select="' '"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    
    
    
    
</xsl:stylesheet>
