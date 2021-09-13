<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">
    <!-- Input: any RELAX-NG xml format file or fragment-->
    <!-- Output: a text representation of the input -->
    <!-- This spreadsheet was written primarily to populate the TAN guidelines -->
    
    <xsl:mode name="formaldef" on-no-match="shallow-skip"/>
    
    <!--<xsl:template match="*" mode="formaldef"/>-->
    <xsl:template match="text()[not(matches(., '\S'))]" mode="formaldef"/>
    <xsl:template match="rng:optional" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>?</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:zeroOrMore" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>*</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:oneOrMore" mode="formaldef">
        <xsl:apply-templates mode="formaldef"/>
        <xsl:text>+</xsl:text>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <!-- options/branches/joins -->
    <xsl:template match="rng:group | rng:choice | rng:interleave | rng:define" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:variable name="is-complex" select="not(self::rng:define)" as="xs:boolean"/>
        <xsl:variable name="has-complex-children"
            select="exists((rng:group, rng:interleave, rng:choice))"/>
        <xsl:variable name="has-siblings"
            select="exists((preceding-sibling::rng:*, following-sibling::rng:*))"/>
        <xsl:variable name="new-indent"
            select="
                if ($has-complex-children = true())
                then
                    concat($current-indent, $indent)
                else
                    $current-indent"/>
        <xsl:if test="$has-complex-children = true()">
            <xsl:value-of select="$lf || $current-indent"/>
            <!--<xsl:value-of select="name()"/>-->
        </xsl:if>
        <xsl:if test="$is-complex = true()">
            <xsl:text>(</xsl:text>
        </xsl:if>
        <!--<xsl:variable name="this-connector" as="xs:string?">
            <xsl:choose>
                <xsl:when test="self::rng:group">, </xsl:when>
                <xsl:when test="self::rng:choice"> | </xsl:when>
                <xsl:when test="self::rng:interleave"> &amp; </xsl:when>
            </xsl:choose>
        </xsl:variable>-->
        <xsl:choose>
            <xsl:when test="count(rng:*) gt 1">
                <xsl:for-each select="rng:*">
                    <xsl:variable name="pos" select="position()"/>
                    <xsl:if test="$has-complex-children = true() and $pos gt 1">
                        <xsl:value-of select="$lf || $current-indent"/>
                    </xsl:if>
                    <xsl:apply-templates mode="formaldef" select=".">
                        <xsl:with-param name="current-indent" select="$new-indent" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="formaldef">
                    <xsl:with-param name="current-indent" select="$new-indent" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$is-complex = true()">
            <xsl:text>)</xsl:text>
            <xsl:if test="$has-siblings = true()">
                <xsl:call-template name="comma-check"/>
            </xsl:if>
        </xsl:if>

    </xsl:template>
    <xsl:template match="rng:ref" mode="formaldef">
        <xsl:param name="module-depth" as="xs:integer" select="1" tunnel="yes"/>
        <xsl:variable name="this-ref" select="."/>
        <xsl:variable name="this-name" select="@name"/>
        <xsl:variable name="this-cfn" select="tan:cfn(.)"/>
        <xsl:variable name="this-seq-of-secs" select="$sequence-of-sections/descendant-or-self::*[@n = $this-cfn]"/>
        <xsl:variable name="this-indent"
            select="
                string-join(for $i in (1 to ($module-depth - 1))
                return
                    '  ')"/>
        <xsl:variable name="this-prefix"
            select="
                string-join(for $i in (1 to $module-depth)
                return
                    '{')"/>
        <xsl:variable name="this-suffix"
            select="
                string-join(for $i in (1 to $module-depth)
                return
                    '}')"/>
        <xsl:variable name="defs" as="element()*"
            select="$tan:rng-collection-without-TEI[tan:cfn(*) = $this-seq-of-secs/(ancestor-or-self::*, descendant::*)/@n]//rng:define[@name = $this-name]"/>
        <xsl:for-each select="$defs">
            <xsl:if test="position() gt 1"> OR &#xa;</xsl:if>
            <xsl:if test="count($defs) gt 1">
                <xsl:value-of select="$lf || $this-indent || $this-prefix || '[' || replace(base-uri(.), '.+/(.+)\.rng$', '$1') || ' ('"/>
                <xsl:copy-of select="tan:prep-string-for-docbook('~' || $this-name)"/>
                <xsl:value-of select="'):]   '"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="count(rng:*) lt 2">
                    <xsl:apply-templates select="." mode="formaldef">
                        <xsl:with-param name="module-depth" select="$module-depth + 1" tunnel="yes"
                        />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of
                        select="tan:prep-string-for-docbook('~' || ($this-name, '[ANY]')[1])"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="count($defs) gt 1">
                <xsl:value-of select="$this-suffix"/>
            </xsl:if>
        </xsl:for-each>
        <!--<xsl:variable name="defs-without-duplicates" as="element()*">
            <xsl:for-each select="$defs">
                <xsl:variable name="pos" select="position()"/>
                <xsl:if test="not(some $i in $defs[position() lt $pos] satisfies deep-equal($i,.))">
                    <xsl:sequence select="."/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>-->
        <!--<xsl:if test="$is-new-line = true()">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>-->
        <!--<xsl:if test="$parent-position gt 1">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>-->
        <!--<xsl:choose>
            <xsl:when
                test="
                    exists($defs-without-duplicates) and
                    (every $i in $defs-without-duplicates
                        satisfies count($i/rng:*) lt 2)">
                <!-\-<xsl:if test="count($defs-without-duplicates) gt 1"><xsl:text>(</xsl:text></xsl:if>-\->
                <xsl:apply-templates select="$defs-without-duplicates/rng:*" mode="formaldef"/>
                <!-\-<xsl:if test="count($defs-without-duplicates) gt 1"><xsl:text>)</xsl:text></xsl:if>-\->
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="tan:prep-string-for-docbook('~' || ($this-name, '[ANY]')[1])"/>
            </xsl:otherwise>
        </xsl:choose>-->
        <xsl:if test="exists($defs)">
            <xsl:call-template name="comma-check"/>
        </xsl:if>
    </xsl:template>

    <!--<xsl:template match="rng:define" mode="formaldef-temp-disable">
        <xsl:param name="current-indent" tunnel="yes"/>

        <xsl:choose>
            <!-\-  or not(rng:element or rng:attribute) -\->
            <xsl:when test="count(rng:*) gt 1">
                <xsl:for-each select="rng:*">
                    <xsl:variable name="pos" select="position()"/>

                    <xsl:apply-templates mode="formaldef" select=".">
                        <xsl:with-param name="parent-position" select="$pos"/>
                    </xsl:apply-templates>
                </xsl:for-each>

                <!-\-<xsl:apply-templates mode="formaldef" select="rng:*[position() gt 1]">
                    <xsl:with-param name="is-new-line" select="true()"/>
                    <xsl:with-param name="is-part-of-a-series" select="true()"/>
                </xsl:apply-templates>-\->
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="formaldef"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    <!--<xsl:template match="rng:define[count(rng:*) le 1]" mode="formaldef">
        <xsl:apply-templates mode="formaldef"></xsl:apply-templates>
    </xsl:template>-->
    <xsl:template match="rng:element" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <!--<xsl:param name="is-new-line" select="false()" as="xs:boolean" tunnel="yes"/>-->
        <!--<xsl:if test="$is-new-line = true()">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>-->
        <!--<test><xsl:value-of select="@name"/></test>-->
        <xsl:copy-of select="tan:prep-string-for-docbook('&lt;' || (@name, '[ANY]')[1] || '>')"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:attribute" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:param name="parent-position" as="xs:integer?"/>
        <!--<xsl:param name="is-new-line" select="false()" as="xs:boolean" tunnel="yes"/>-->
        <!--<xsl:if test="$is-new-line = true()">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>-->
        <xsl:if test="exists($parent-position)">
            <xsl:copy-of select="$lf || $current-indent"/>
        </xsl:if>
        <xsl:copy-of select="tan:prep-string-for-docbook('@' || (@name, '[ANY]')[1])"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:param" mode="formaldef">
        <xsl:value-of select="'(' || @name || ' ' || . || ')'"/>
    </xsl:template>
    <xsl:template match="rng:data | rng:value" mode="formaldef">
        <xsl:param name="current-indent" tunnel="yes"/>
        <xsl:value-of
            select="
                if (parent::rng:group | parent::rng:choice | parent::rng:interleave) then
                    $lf || $current-indent
                else
                    ()"/>
        <xsl:value-of select="@type || ' ' || string-join(text(), ' ')"/>
        <xsl:apply-templates mode="formaldef"/>
        <xsl:call-template name="comma-check"/>
    </xsl:template>
    <xsl:template match="rng:text" mode="formaldef">
        <xsl:text>text</xsl:text>
    </xsl:template>
    <xsl:template match="rng:empty" mode="formaldef">
        <xsl:text>{empty}</xsl:text>
    </xsl:template>
    <xsl:template match="text()" mode="formaldef"/>

    <xsl:function name="tan:comma-check" as="xs:string*" visibility="private">
        <xsl:param name="rng-nodes" as="element()*"/>
        <xsl:for-each select="$rng-nodes">
            <xsl:call-template name="comma-check"/>
        </xsl:for-each>
    </xsl:function>
    <xsl:template name="comma-check">
        <xsl:choose>
            <xsl:when test="parent::rng:choice and following-sibling::rng:*">
                <xsl:text> | </xsl:text>
            </xsl:when>
            <xsl:when test="parent::rng:interleave and following-sibling::rng:*">
                <xsl:text> &amp; </xsl:text>
            </xsl:when>
            <xsl:when test="following-sibling::rng:*">
                <xsl:text>, </xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
