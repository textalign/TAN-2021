<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://docbook.org/ns/docbook" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xpath = "http://www.w3.org/2005/xpath-functions"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:docbook="http://docbook.org/ns/docbook" 
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:function name="tan:examples" as="element()*" visibility="private">
        <!-- Input: any element or attribute name; a parameter indicating whether it is an attribute (true) or an element (false) -->
        <!-- Output: a docbook representation of the context of specific examples drawn from the TAN examples directory -->
        <!-- Used primarily to populate the TAN guidelines with examples -->
        <xsl:param name="element-or-attribute-name" as="xs:string?"/>
        <xsl:param name="is-attribute" as="xs:boolean?"/>
        <xsl:param name="include-catalog-examples" as="xs:boolean"/>
        <xsl:variable name="example-elements" as="element()*"
            select="
                (if ($is-attribute = true()) then
                    $ex-collection[$include-catalog-examples or not(matches(base-uri(.), 'catalog|Copy'))]//*[@*[name(.) = $element-or-attribute-name]]
                else
                    $ex-collection[$include-catalog-examples or not(matches(base-uri(.), 'catalog|Copy'))]//tan:*[name(.) = $element-or-attribute-name])[position() le $max-examples]"
        />
        
        <xsl:if test="not(exists($example-elements))">
            <xsl:message select="
                    (if ($is-attribute) then
                        'attribute '
                    else
                        'element ') || $element-or-attribute-name || ' lacks any examples.'"/>
        </xsl:if>
        
        <xsl:for-each-group select="$example-elements" group-by="root(.)">
            <xsl:variable name="text" select="tan:element-to-example-text(current-group())"/>
            <xsl:variable name="text-to-emphasize"
                select="concat('\s', $element-or-attribute-name, '=&quot;[^&quot;]+&quot;|&lt;/?', $element-or-attribute-name, '(/?>|\s+[^&gt;]*>)')"/>
            <xsl:variable name="text-emphasized" select="analyze-string($text, $text-to-emphasize)"/>
            <xsl:variable name="this-example-uri" select="base-uri(current-group()[1])"/>
            <!-- In the following, static base uri works, only because it is, like the guidelines inclusions, two levels deeper than the TAN-2019 directory -->
            <xsl:variable name="this-example-relative-url" select="tan:uri-relative-to($this-example-uri, static-base-uri())"/>
            <!--<xsl:variable name="example-file-name" select="replace($this-example-uri,'.+/([^/]+)$','$1')"/>-->
            <!--<xsl:variable name="example-uri-old" select="'../../examples/' || $example-file-name"/>-->
            <xsl:variable name="docbook-example" as="element()">
                <para>
                    <example>
                        <title>
                            <code>
                                <xsl:value-of
                                    select="
                                        tan:string-representation-of-component($element-or-attribute-name,
                                        if ($is-attribute = true()) then
                                            'attribute'
                                        else
                                            'element')"
                                />
                            </code>
                        </title>
                        <programlisting><xsl:apply-templates select="$text-emphasized" mode="emph-string-for-docbook"/></programlisting>
                    </example>
                    <note>
                        <para>
                            <xsl:text>Taken from </xsl:text>
                            <link xlink:href="{$this-example-relative-url}">
                                <xsl:value-of select="tan:cfn(current-group()[1])"/>
                            </link>
                        </para>
                    </note>
                </para>
            </xsl:variable>
            <xsl:if test="string-length($docbook-example/docbook:example/docbook:programlisting) le $max-example-size">
                <xsl:sequence select="$docbook-example"/>
            </xsl:if>
        </xsl:for-each-group>
    </xsl:function>
    
    <xsl:mode name="emph-string-for-docbook" on-no-match="shallow-copy"/>
    <xsl:template match="xpath:analyze-string-result | xpath:group | xpath:non-match" mode="emph-string-for-docbook">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="xpath:match" mode="emph-string-for-docbook">
        <emphasis><xsl:apply-templates mode="#current"/></emphasis>
    </xsl:template>
    
    
    <xsl:function name="tan:element-to-example-text" as="xs:string?" visibility="private">
        <!-- Input: XML elements -->
        <!-- Output: a text representation -->
        <xsl:param name="example-elements" as="element()*"/>
        <xsl:variable name="lca-element" as="element()?" select="tan:lca($example-elements)"/>
        <xsl:variable name="context-element"
            select="
                if (deep-equal(root($lca-element), $lca-element/..)) then
                    $lca-element
                else
                    $lca-element/.."/>
        <xsl:variable name="raw" as="xs:string*">
            <xsl:apply-templates mode="tree-to-text" select="$context-element">
                <xsl:with-param name="example-elements" select="$example-elements" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:value-of select="string-join($raw, '')"/>
    </xsl:function>
    <xsl:function name="tan:lca" as="node()?" visibility="private">
        <!-- Input: any nodes -->
        <!-- Output: the least (first) common ancestor to the nodes -->
        <xsl:param name="pSet" as="node()*"/>
        <xsl:sequence
            select="
                if (not($pSet))
                then
                    ()
                else
                    if (not($pSet[2]))
                    then
                        $pSet[1]
                    else
                        if ($pSet intersect $pSet/ancestor::node())
                        then
                            tan:lca($pSet[not($pSet intersect ancestor::node())])
                        else
                            tan:lca($pSet/..)"
        />
    </xsl:function>
    
    <xsl:mode name="tree-to-text" on-no-match="shallow-copy"/>
    <xsl:template match="*" mode="tree-to-text" as="xs:string*">
        <xsl:param name="example-elements" as="element()*" tunnel="yes"/>
        <xsl:param name="is-contextual-sibling" as="xs:boolean" select="false()"/>
        <xsl:param name="is-contextual-child" as="xs:boolean" select="false()"/>
        <xsl:variable name="is-example" as="xs:boolean"
            select="
                some $i in $example-elements
                    satisfies deep-equal($i, .)"
        />
        <xsl:choose>
            <!-- if the element or a descendant is an example, then do a shallow copy, then check to see what should be processed -->
            <xsl:when
                test="
                    $is-example = true() or
                    (some $i in $example-elements
                        satisfies some $j in descendant::*
                            satisfies deep-equal($i, $j))">
                <xsl:variable name="pos-of-contextual-children" as="xs:integer*"
                    select="
                        if ($is-example = true()) then
                            (1 to $qty-contextual-children)
                        else
                            ()"
                />
                <xsl:variable name="pos-of-example-children" as="xs:integer*">
                    <xsl:for-each select="*">
                        <xsl:if
                            test="
                                some $i in $example-elements
                                    satisfies deep-equal(., $i)">
                            <xsl:copy-of select="position()"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="pos-of-example-childrens-contextual-siblings" as="xs:integer*"
                    select="
                        if (exists($pos-of-example-children)) then
                            for $i in $pos-of-example-children,
                                $j in (1 to $qty-contextual-siblings)
                            return
                                ($i + $j, $i - $j)
                        else
                            ()"
                />
                <xsl:variable name="pos-of-children-with-example-descendants" as="xs:integer*">
                    <xsl:for-each select="*">
                        <xsl:if
                            test="
                                if (position() = ($pos-of-contextual-children, $pos-of-example-children, $pos-of-example-childrens-contextual-siblings)) then
                                    false()
                                else
                                    (some $i in $example-elements
                                        satisfies some $j in descendant::*
                                            satisfies deep-equal($i, $j))">
                            <xsl:copy-of select="position()"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="pos-of-all-children-to-process" as="xs:integer*"
                    select="($pos-of-contextual-children, $pos-of-example-children, $pos-of-example-childrens-contextual-siblings, $pos-of-children-with-example-descendants)"
                />
                <xsl:value-of select="tan:first-tag-to-text(.)"/>
                <xsl:choose>
                    <!-- if there are children to process, do so, eliding the others -->
                    <xsl:when test="exists($pos-of-all-children-to-process)">
                        <xsl:for-each select="*">
                            <xsl:choose>
                                <xsl:when
                                    test="position() = ($pos-of-all-children-to-process)">
                                    <xsl:apply-templates select="." mode="tree-to-text">
                                        <xsl:with-param name="is-contextual-sibling"
                                            select="
                                                if (position() = $pos-of-example-childrens-contextual-siblings and not(position() = $pos-of-example-children)) then
                                                    true()
                                                else
                                                    false()"
                                        />
                                        <xsl:with-param name="is-contextual-child"
                                            select="
                                                if (position() = $pos-of-contextual-children and not(position() = ($pos-of-children-with-example-descendants, $pos-of-example-children))) then
                                                    true()
                                                else
                                                    false()"
                                        />
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!-- if it's the first element to be elided, replace it with ellipses; all others get skipped -->
                                    <xsl:if
                                        test="position() - 1 = (0, $pos-of-all-children-to-process)">
                                        <xsl:value-of select="concat(tan:indent(.), $ellipses)"/>
                                    </xsl:if>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:when>
                    <!-- if there aren't even any children, then we at least process the text -->
                    <xsl:when test="not(exists(*))">
                        <xsl:apply-templates mode="tree-to-text"/>
                    </xsl:when>
                    <!-- if neither whens above are true, the element has children, but none that should be processed so we elide them -->
                    <xsl:otherwise>
                        <xsl:value-of select="concat(tan:indent(.), $ellipses)"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="text() | *">
                    <xsl:value-of select="tan:last-tag-to-text(.)"/>
                </xsl:if>
            </xsl:when>
            <!-- the node is neither an example nor an ancestor of an example, so we should ignore it unless if it is a contextual sibling or contextual child, in which case we shallow copy it -->
            <xsl:otherwise>
                <xsl:if test="$is-contextual-sibling = true() or $is-contextual-child = true()">
                    <xsl:value-of select="tan:guidelines-shallow-copy(.)"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@*" mode="tree-to-text" as="xs:string?">
        <xsl:value-of select="concat(' ', name(.), '=&quot;', replace(.,'\s(\s+)','&#xa;$1'), '&quot;')"/>
    </xsl:template>

    <xsl:function name="tan:indent" as="xs:string?" visibility="private">
        <xsl:param name="element" as="element()?"/>
        <xsl:value-of
            select="
                string-join(
                for $i in (1 to count($element/ancestor::*))
                return
                    $indent)"
        />
    </xsl:function>
    <xsl:function name="tan:first-tag-to-text" as="xs:string?" visibility="private">
        <xsl:param name="element" as="element()?"/>
        <xsl:variable name="raw" as="xs:string*">
            <xsl:value-of select="concat(tan:indent($element), '&lt;', name($element))"/>
            <xsl:apply-templates select="$element/@*" mode="tree-to-text"/>
            <xsl:choose>
                <xsl:when test="$element/child::*">
                    <!-- element has children -->
                    <xsl:text>>&#xA;</xsl:text>
                </xsl:when>
                <xsl:when test="$element/text()">
                    <!-- element has no children, but does have text -->
                    <xsl:text>></xsl:text>
                    <xsl:value-of select="$element/text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- empty element -->
                    <xsl:text>/>&#xA;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="string-join($raw)"/>
    </xsl:function>
    <xsl:function name="tan:last-tag-to-text" as="xs:string?" visibility="private">
        <xsl:param name="element" as="element()?"/>
        <xsl:value-of
            select="
                concat(if ($element/*) then
                    tan:indent($element)
                else
                    (), '&lt;/', name($element), '>&#xA;')"
        />
    </xsl:function>
    <xsl:function name="tan:guidelines-shallow-copy" as="xs:string?" visibility="private">
        <xsl:param name="element" as="element()?"/>
        <xsl:variable name="raw" as="xs:string*">
            <xsl:value-of select="tan:first-tag-to-text($element)"/>
            <xsl:if test="$element/*">
                <xsl:value-of select="tan:indent($element/*[1])"/>
                <xsl:value-of select="$ellipses"/>
            </xsl:if>
            <xsl:if test="$element/(*, text())">
                <xsl:value-of select="tan:last-tag-to-text($element)"/>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="string-join($raw)"/>
    </xsl:function>

</xsl:stylesheet>
