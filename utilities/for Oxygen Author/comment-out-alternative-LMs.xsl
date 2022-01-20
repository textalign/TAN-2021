<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:oxy="http://www.oxygenxml.com/ns/author/xpath-extension-functions" 
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0" 
    exclude-result-prefixes="#all" default-mode="comment-out-alternative-LMs"
    version="3.0">

    <!-- Oxygen author action to remove alternative LMs in a TAN-A-lm's <ana> -->
    <!-- We presume that <_caret/> has been placed marking the <l> or <m> to keep, and that
        the node being initially processed is a tan:ana -->
    <xsl:mode name="comment-out-alternative-LMs" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:ana[descendant::_caret]" mode="comment-out-alternative-LMs">
        <xsl:variable name="element-to-preserve" as="element()*" select=".//*[_caret]"/>
        <xsl:variable name="name-of-element-to-preserve" as="xs:string?"
            select="name($element-to-preserve)"/>
        
        <xsl:variable name="error-message" as="xs:string?">
            <xsl:choose>
                <xsl:when test="not(exists($element-to-preserve))">No element has been marked for preservation</xsl:when>
                <xsl:when test="count($element-to-preserve) gt 1">Multiple elements have been marked for preservation</xsl:when>
                <xsl:when test="not($name-of-element-to-preserve = ('l', 'm'))">The element marked for change is not an l or m.</xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <!--<xsl:when test="true()">
                <xsl:message select="'element to preserve: ', $element-to-preserve"/>
                <xsl:message select="'name of element to preserve: ' || $name-of-element-to-preserve"/>
                <xsl:copy-of select="."/>
            </xsl:when>-->
            <xsl:when test="exists($error-message)">
                <xsl:message select="$error-message"/>
                <!--<xsl:copy-of select="."/>-->
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'Commenting out ' || string(count(tan:lm) - 1) || ' lm elements and ' 
                    || string(count(tan:lm[*/_caret]/*[name(.) eq $name-of-element-to-preserve]) - 1)
                    || ' ' || $name-of-element-to-preserve || ' elements.'"/>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="name-of-element-to-preserve" as="xs:string"
                            tunnel="yes" select="$name-of-element-to-preserve"/>
                    </xsl:apply-templates>
                </xsl:copy>
                <!-- Ordinarily you would want merely to replace <ana>. But there could be thousands of <ana>s
                    in a <group> or <body> and the replace action is very time consuming. Instead, we use the 
                    insert as last child operation, which is very fast. But it means that the XSLT needs some
                    work-arounds.
                -->
                <!--<_delete-preceding-lms/>-->
                <!--<_new-content>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="name-of-element-to-preserve" as="xs:string"
                            tunnel="yes" select="$name-of-element-to-preserve"/>
                    </xsl:apply-templates>
                
                </_new-content>-->
                <!--<xsl:apply-templates select="tan:lm" mode="#current">
                    <xsl:with-param name="name-of-element-to-preserve" as="xs:string"
                        tunnel="yes" select="$name-of-element-to-preserve"/>
                </xsl:apply-templates>-->
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="*[_caret]" priority="1" mode="comment-out-alternative-LMs">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:l | tan:m" mode="comment-out-alternative-LMs">
        <xsl:param name="name-of-element-to-preserve" as="xs:string" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="name(.) eq $name-of-element-to-preserve">
                <!-- Ironically, the name of the element to preserve is what is
                    used here to find elements to comment out. The element to be
                    preserved has already been processed because it has <_caret> 
                    inside. And as for the other element, the <l> if m is to be preserved
                    or <m> if the other way around, those items get preserved, because
                    properly speaking, they aren't alternatives to the original context
                    element.
                -->
                <xsl:copy-of select="tan:convert-to-comment(.)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="_caret" mode="comment-out-alternative-LMs">
        <xsl:value-of select="'${caret}'"/>
    </xsl:template>
    
    <xsl:template match="tan:lm[not(exists(descendant::_caret))]" mode="comment-out-alternative-LMs">
        <xsl:copy-of select="tan:convert-to-comment(.)"/>
    </xsl:template>
    
    <xsl:function name="tan:convert-to-comment" as="comment()?">
        <!-- Input: any nodes -->
        <!-- Output: the nodes converted to a comment -->
        <xsl:param name="nodes-to-convert" as="node()*"/>
        <xsl:variable name="serialization-pass-1" as="xs:string?">
            <xsl:apply-templates select="$nodes-to-convert" mode="squelch-namespaces"/>
            <!--<xsl:copy-of select="$nodes-to-convert" copy-namespaces="no"/>-->
        </xsl:variable>
        <xsl:variable name="output-params" as="element()">
            <output:serialization-parameters 
                xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                <!--<output:undeclare-prefixes value="yes"/>-->
            </output:serialization-parameters>
        </xsl:variable>
        <xsl:if test="exists($nodes-to-convert)">
            <!--<xsl:comment><xsl:sequence select="$nodes-without-namespace-stuff"/></xsl:comment>-->
            <xsl:comment><xsl:analyze-string select="$serialization-pass-1" regex="-(\\*-)">
            <xsl:matching-substring>
                <xsl:value-of select="'-\' || regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string></xsl:comment>
            <!--<xsl:comment><xsl:apply-templates select="$nodes-to-convert" mode="comment-out-tree"></xsl:apply-templates></xsl:comment>-->
        </xsl:if>
    </xsl:function>
    
    <xsl:mode name="squelch-namespaces" on-no-match="shallow-copy"/>
    
    <xsl:template match="comment() | processing-instruction()" mode="squelch-namespaces">
        <xsl:value-of select="serialize(.)"/>
    </xsl:template>
    <xsl:template match="*" mode="squelch-namespaces">
        <xsl:variable name="this-name" as="xs:string" select="name(.)"/>
        <xsl:variable name="this-prefix" as="xs:string" select="(reverse(tokenize($this-name, ':'))[2], '')[1]"/>
        <xsl:variable name="default-namespace" select="namespace-uri-for-prefix($this-prefix, .)"/>
        <xsl:variable name="this-element-serialized" as="xs:string" select="serialize(.)"/>
        <xsl:variable name="xmlns-name" as="xs:string" select="
                if ($this-prefix eq '') then
                    ' xmlns'
                else
                    (' xmlns:' || $this-prefix)"/>
        <xsl:variable name="this-search-regex" as="xs:string" select="'^&lt;' || $this-name || $xmlns-name || '=&quot;[^&quot;]*&quot;'"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Prefix: ' || $this-prefix"/>
            <xsl:message select="'Default namespace: ' || $default-namespace"/>
            <xsl:message select="'Element serialized: ' || $this-element-serialized"/>
            <xsl:message select="'Search regex: ' || $this-search-regex"/>
        </xsl:if>
        
        <!--<xsl:value-of
            select="replace($this-element-serialized, 'cert', 'hello')"
        />-->
        <xsl:value-of
            select="replace($this-element-serialized, $this-search-regex, '&lt;' || $this-name)"
        />
        <!--<xsl:element name="{name(.)}" namespace="">
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node()" copy-namespaces="no"/>
        </xsl:element>-->
    </xsl:template>
    
    <xsl:mode name="comment-out-tree" on-no-match="shallow-copy"/>
    
    <xsl:template match="element()" mode="comment-out-tree">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name(.)"/>
        <xsl:value-of select="serialize(namespace-node())"/>
        <xsl:text>></xsl:text>
    </xsl:template>
    <xsl:template match="comment()" mode="comment-out-tree">
        <xsl:text>&lt;!--</xsl:text>
        <xsl:analyze-string select="." regex="-(\\*-)">
            <xsl:matching-substring>
                <xsl:value-of select="'-\' || regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
        <xsl:text>--></xsl:text>
    </xsl:template>
    <xsl:template match="text()" mode="comment-out-tree">
        <xsl:analyze-string select="." regex="-(\\*-)">
            <xsl:matching-substring>
                <xsl:value-of select="'-\' || regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
</xsl:stylesheet>
