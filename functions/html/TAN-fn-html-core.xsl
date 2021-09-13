<?xml version="1.1" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">

    <!-- TAN Function Library core html functions. -->
    
    
    <xsl:variable name="tan:global-html-attributes" as="xs:string+"
        select="'accesskey', 'aria-activedescendant', 'aria-atomic', 'aria-autocomplete', 
        'aria-busy', 'aria-controls', 'aria-current', 'aria-describedby', 'aria-details', 
        'aria-disabled', 'aria-dropeffect', 'aria-errormessage', 'aria-expanded', 'aria-flowto', 
        'aria-grabbed', 'aria-haspopup', 'aria-hidden', 'aria-invalid', 'aria-keyshortcuts', 
        'aria-label', 'aria-labelledby', 'aria-live', 'aria-orientation', 'aria-owns', 
        'aria-readonly', 'aria-relevant', 'aria-required', 'aria-roledescription', 'autocapitalize', 
        'autofocus', 'class', 'contenteditable', 'dir', 'draggable', 'enterkeyhint', 'hidden', 'id', 
        'inputmode', 'is', 'itemid', 'itemprop', 'itemref', 'itemscope', 'itemtype', 'lang', 'nonce', 
        'onabort', 'onauxclick', 'onblur', 'oncancel', 'oncanplay', 'oncanplaythrough', 'onchange', 
        'onclick', 'onclose', 'oncontextmenu', 'oncopy', 'oncuechange', 'oncut', 'ondblclick', 
        'ondrag', 'ondragend', 'ondragenter', 'ondragleave', 'ondragover', 'ondragstart', 'ondrop', 
        'ondurationchange', 'onemptied', 'onended', 'onerror', 'onfocus', 'onformdata', 'oninput', 
        'oninvalid', 'onkeydown', 'onkeypress', 'onkeyup', 'onload', 'onloadeddata', 
        'onloadedmetadata', 'onloadstart', 'onmousedown', 'onmouseenter', 'onmouseleave', 
        'onmousemove', 'onmouseout', 'onmouseover', 'onmouseup', 'onpaste', 'onpause', 'onplay', 
        'onplaying', 'onprogress', 'onratechange', 'onreset', 'onresize', 'onscroll', 
        'onsecuritypolicyviolation', 'onseeked', 'onseeking', 'onselect', 'onslotchange', 
        'onstalled', 'onsubmit', 'onsuspend', 'ontimeupdate', 'ontoggle', 'onvolumechange', 
        'onwaiting', 'onwheel', 'slot', 'spellcheck', 'style', 'tabindex', 'title', 'translate'"
    />
    
    
    <xsl:function name="tan:has-class" as="xs:boolean" visibility="private">
        <!-- Input: any element; a sequence of strings -->
        <!-- Output: a boolean specifying whether the element has any of the strings as a value 
        in its attribute class -->
        <xsl:param name="context" as="element()?"/>
        <xsl:param name="class-names" as="xs:string*"/>
        <xsl:sequence select="
                some $i in $class-names
                    satisfies
                    contains-token($context/@class, $i)"/>
    </xsl:function>
    
    <xsl:function name="tan:find-class" as="element()*" visibility="private">
        <!-- Input: an XML tree; a sequence of strings -->
        <!-- Output: the rootward-most elements in the tree that have a @class with a token matching
        the input strings. -->
        <!-- Once an element is found, the entire element is returned, without checking also its
        descendants. -->
        <!-- This function was written to more concisely pick HTML elements by class. It will work,
        however, on non-HTML elements as well. -->
        <xsl:param name="context" as="item()*"/>
        <xsl:param name="class-names" as="xs:string*"/>
        <xsl:apply-templates select="$context" mode="tan:html-class">
            <xsl:with-param name="class-names" select="$class-names" tunnel="yes" as="xs:string*"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:mode name="tan:html-class" on-no-match="shallow-skip"/>
    
    <xsl:template match="*[@class]" mode="tan:html-class">
        <xsl:param name="class-names" as="xs:string*" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="
                    some $i in $class-names
                        satisfies contains-token(@class, $i)">
                <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    
    <xsl:variable name="tan:excluded-class-characters-regex" 
        as="xs:string">[&#1;-&#xff;-[\s0-9a-zA-Z_-]]</xsl:variable>
    
    <xsl:function name="tan:prepare-to-convert-to-html" as="item()*" visibility="private">
        <!-- Input: a tree fragment that is destined for HTML output -->
        <!-- Output: the same tree fragment, but with all changes applied -->
        <!-- Although this function has only one parameter, it relies extensively upon the
        global parameters specified at ../../parameters/params-application-html-output.xsl -->
        <xsl:param name="tree-to-convert" as="item()*"/>
        <!-- First, wrap element with an @href in an html <a href=""/>, -->
        <xsl:variable name="pass-1" as="item()*">
            <xsl:apply-templates select="$tree-to-convert" mode="tan:prepare-to-convert-to-html-pass-1"/>
        </xsl:variable>
        <xsl:variable name="pass-2" as="item()*">
            <xsl:apply-templates select="$pass-1" mode="tan:prepare-to-convert-to-html-pass-2"/>
        </xsl:variable>
        <xsl:variable name="pass-3" as="item()*">
            <xsl:apply-templates select="$pass-2" mode="tan:prepare-to-convert-to-html-pass-3"/>
        </xsl:variable>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, tan:prepare-to-convert-to-html()'"/>
            <xsl:message select="'Pass 1:', $pass-1"/>
            <xsl:message select="'Pass 2:', $pass-2"/>
            <xsl:message select="'Pass 3:', $pass-3"/>
        </xsl:if>
        
        <xsl:sequence select="$pass-3"/>
    </xsl:function>
    
    
    <xsl:mode name="tan:prepare-to-convert-to-html-pass-1" on-no-match="shallow-copy"/>
    <xsl:mode name="tan:prepare-to-convert-to-html-pass-2" on-no-match="shallow-copy"/>
    <xsl:mode name="tan:prepare-to-convert-to-html-pass-3" on-no-match="shallow-copy"/>
    
    <xsl:template match="*[@href]" priority="1" mode="tan:prepare-to-convert-to-html-pass-1">
        <a>
            <xsl:copy-of select="@href"/>
            <xsl:next-match/>
        </a>
    </xsl:template>
    
    <xsl:template match="*" mode="tan:prepare-to-convert-to-html-pass-1">
        <xsl:variable name="attrs-to-add-to-class" as="attribute()*" select="
                @class,
                (if (tan:regex-is-valid($tan:html-out.attributes-whose-values-should-be-added-to-attr-class-regex)) then
                    @*[matches(name(.), $tan:html-out.attributes-whose-values-should-be-added-to-attr-class-regex)]
                else
                    ())"/>
        <xsl:variable name="has-id" as="xs:boolean" select="exists(@id) or exists(@xml:id)"/>
        <xsl:variable name="attribute-to-replace-id"
            select="@*[name(.) eq $tan:html-out.attribute-to-convert-to-id]" as="attribute()?"/>
        
        
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="exists($attribute-to-replace-id) or $has-id">
                    <xsl:apply-templates select="@* except (@id | @xml:id | $attribute-to-replace-id)"
                        mode="#current"/>
                    <xsl:attribute name="id" select="($attribute-to-replace-id, @id, @xml:id)[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
            <!--<xsl:copy-of select="@*"/>-->
            <xsl:if test="count($attrs-to-add-to-class) gt 0">
                <xsl:attribute name="class"
                    select="replace(string-join(distinct-values($attrs-to-add-to-class), ' '), 
                    $tan:excluded-class-characters-regex, '')"
                />
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:variable name="attributes-to-preserve" as="xs:string+" select="('id', 'class', 'draggable')"/>
    <xsl:template match="@*" mode="tan:prepare-to-convert-to-html-pass-2">
        <xsl:variable name="context-name" select="name(.)" as="xs:string"/>
        <xsl:variable name="name-regex-is-ok" select="tan:regex-is-valid($tan:html-out.remove-what-attributes-regex)"/>
        <xsl:if
            test="not($name-regex-is-ok and matches($context-name, $tan:html-out.remove-what-attributes-regex)) 
            or ($context-name = $attributes-to-preserve)">
            <xsl:attribute name="{name(.)}" select="."/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="*" mode="tan:prepare-to-convert-to-html-pass-2">
        <xsl:variable name="context-name" select="name(.)" as="xs:string"/>
        <xsl:variable name="name-regex-is-ok"
            select="tan:regex-is-valid($tan:html-out.remove-what-elements-regex)" as="xs:boolean"/>
        <xsl:if test="not($name-regex-is-ok) or not(matches($context-name, $tan:html-out.remove-what-elements-regex))">
            <xsl:copy>
                <xsl:apply-templates select="@* | node()" mode="#current"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    
    
    <xsl:template match="*" mode="tan:prepare-to-convert-to-html-pass-3">
        <xsl:variable name="regex-1-is-ok" as="xs:boolean" select="tan:regex-is-valid($tan:html-out.elements-whose-children-should-be-grouped-and-labeled-regex)"/>
        <xsl:variable name="regex-2-is-ok" as="xs:boolean" select="tan:regex-is-valid($tan:html-out.children-that-should-not-be-grouped-and-labeled-regex)"/>
        <xsl:variable name="regex-3-is-ok" as="xs:boolean" select="tan:regex-is-valid($tan:html-out.elements-that-should-be-labeled-regex)"/>
        
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            
            <xsl:if test="$regex-3-is-ok and matches(name(.), $tan:html-out.elements-that-should-be-labeled-regex)">
                <div class="label">
                    <xsl:sequence select="name(.)"/>
                </div>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$regex-1-is-ok and matches(name(.), $tan:html-out.elements-whose-children-should-be-grouped-and-labeled-regex)">
                    <xsl:apply-templates select="node() except *" mode="#current"/>
                    <xsl:for-each-group select="*" group-adjacent="name(.)">
                        <xsl:variable name="this-count" select="count(current-group())"/>
                        <xsl:variable name="this-suffix" select="
                                if ($this-count gt 1) then
                                    concat('s (', string($this-count), ')')
                                else
                                    ()"/>
                        <xsl:variable name="group-this-group" as="xs:boolean"
                            select="not($regex-2-is-ok) 
                            or not(matches(current-grouping-key(), $tan:html-out.children-that-should-not-be-grouped-and-labeled-regex))"
                        />
                        <xsl:choose>
                            <xsl:when test="$group-this-group">
                                <div class="group">
                                    <div class="label">
                                        <xsl:sequence
                                            select="current-grouping-key() || $this-suffix"/>
                                    </div>
                                    <xsl:apply-templates select="current-group()" mode="#current"/>
                                </div>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="current-group()" mode="#current"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each-group> 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    
    
    
    <xsl:function name="tan:convert-to-html" as="item()*" visibility="public">
        <!-- 2-param version of fuller one, below -->
        <xsl:param name="fragment-to-convert" as="item()*"/>
        <xsl:param name="parse-text-for-urls" as="xs:boolean"/>
        <xsl:sequence
            select="tan:convert-to-html($fragment-to-convert, $parse-text-for-urls, 
            $tan:html-out.attributes-to-retain-regex, $tan:html-out.keep-attributes-named-after-global-html-attributes)"
        />
    </xsl:function>
    
    <xsl:function name="tan:convert-to-html" as="item()*" visibility="public">
        <!-- Input: Any XML tree fragment; a boolean; a string -->
        <!-- Output: The fragment converted to HTML (described below); if the boolean is true, text will be parsed 
            for URLs and wrapped in <a href="">; if the third parameter is a valid regular expression, attributes 
            whose names match the pattern will be retained unchanged. -->
        <!-- Every element is converted to an HTML <div>, with the name of the element or attribute being
        placed inside the @class as a value: e-[NAME] for elements and a-[NAME] for attributes. In addition,
        if the element or attribute is in a namespace, the namespace is included as a class value, 
        ns-[NAMESPACE PREFIX]. Comments and processing instructions are preserved intact. -->
        <!-- Any element already in the HTML namespace will be left as-is, with templates continued to
            be applied to its descendants. -->
        <!-- Some attributes are handled specially:
            Every @xml:* is retained, but with only the local name, no prefix.
            Every attribute in an html element is retained as-is.
            No attribute @class is rendered as an element.
            No attribute beginning with _ is rendered as an element, and it is retained as-is. (It is your responsibility
                to get rid of temporary attributes you do not want, either before or after this function runs.)
        -->
        <!--kw: html, nodes, tree manipulation -->
        
        <xsl:param name="fragment-to-convert" as="item()*"/>
        <xsl:param name="parse-a-hrefs" as="xs:boolean"/>
        <xsl:param name="attributes-to-retain-regex" as="xs:string"/>
        <xsl:param name="keep-attributes-named-after-global-html-attributes" as="xs:boolean"/>
        
        <xsl:variable name="namespace-map" as="map(*)"
            select="tan:get-namespace-map($fragment-to-convert)"/>
        
        <xsl:variable name="output-1" as="item()*">
            <xsl:apply-templates select="$fragment-to-convert" mode="tan:tree-to-html">
                <xsl:with-param name="namespace-map" tunnel="yes" select="$namespace-map"/>
                <xsl:with-param name="attributes-to-retain-regex" tunnel="yes" select="
                        if (tan:regex-is-valid($attributes-to-retain-regex))
                        then
                            $attributes-to-retain-regex
                        else
                            ()"/>
                <xsl:with-param name="keep-attributes-named-after-global-html-attributes"
                    tunnel="yes" select="$keep-attributes-named-after-global-html-attributes"
                    as="xs:boolean"/>
                
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="output-2" as="item()*">
            <xsl:choose>
                <xsl:when test="$parse-a-hrefs">
                    <xsl:apply-templates select="$output-1" mode="tan:parse-a-hrefs"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$output-1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message>diagnostics turned on for tan:convert-to-html()</xsl:message>
        </xsl:if>
        
        <xsl:sequence select="$output-2"/>
    </xsl:function>
    
    <xsl:mode name="tan:tree-to-html" on-no-match="shallow-copy"/>
    <xsl:mode name="tan:tree-to-html-for-attr" on-no-match="shallow-copy"/>

    <!-- Any HTML structures should be preserved intact. -->
    <xsl:template match="html:*" priority="1" mode="tan:tree-to-html">
        <xsl:copy copy-namespaces="false">
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="html:*/@*" priority="1" mode="tan:tree-to-html">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="@xml:*" mode="tan:tree-to-html-for-attr">
        <xsl:attribute name="{name(.)}" select="."/>
    </xsl:template>
    
    <xsl:template match="*" mode="tan:tree-to-html">
        <xsl:param name="first-ancestor-non-html-namespace-uri" as="xs:anyURI?"
            select="namespace-uri(ancestor-or-self::*[not(namespace-uri(.) eq 'http://www.w3.org/1999/xhtml')][1])"
        />
        <xsl:param name="namespace-map" tunnel="yes" as="map(*)?"/>
        <xsl:param name="attributes-to-retain-regex" tunnel="yes" as="xs:string?"/>
        <xsl:param name="keep-attributes-named-after-global-html-attributes"
            tunnel="yes" select="$tan:html-out.keep-attributes-named-after-global-html-attributes"
            as="xs:boolean"/>

        <xsl:variable name="this-ns-uri" as="xs:anyURI" select="namespace-uri()"/>
        <xsl:variable name="this-prefix" select="$namespace-map($this-ns-uri)" as="xs:string"/>
        <xsl:variable name="this-prefix-adjusted" select="
                if ((string-length($this-ns-uri) gt 0) and
                (string-length($this-prefix) lt 1)) then
                    $tan:namespaces-and-prefixes/tan:ns[@uri eq $this-ns-uri]/@prefix
                else
                    $this-prefix"/>
        <xsl:variable name="these-classes" as="xs:string+">
            <xsl:sequence select="'e-' || local-name(.)"/>
            <!-- Copy the namespace as a prefix if there has been a change. -->
            <xsl:if
                test="(string-length($this-ns-uri) gt 0) and not($this-ns-uri eq $first-ancestor-non-html-namespace-uri)">
                <xsl:sequence select="'ns-' || $this-prefix-adjusted"/>
            </xsl:if>
            <!-- We presume that an attribute called @class has values that should be inherited. -->
            <xsl:sequence select="string(@class)"/>
        </xsl:variable>
        <xsl:variable name="attr-class-val" as="xs:string" select="normalize-space(string-join((@class, $these-classes), ' '))"/>
        <xsl:variable name="attributes-to-preserve" as="attribute()*" select="
                @xml:* | @*[(string-length($attributes-to-retain-regex) gt 0) and matches(local-name(.), $attributes-to-retain-regex)] |
                @*[$keep-attributes-named-after-global-html-attributes and (name(.) = $tan:global-html-attributes)]"
        />
        
        <div>
            <xsl:apply-templates select="$attributes-to-preserve" mode="tan:tree-to-html-for-attr"/>
            <xsl:if test="string-length($attr-class-val) gt 0">
                <xsl:attribute name="class" select="$attr-class-val"/>
            </xsl:if>
            <xsl:apply-templates select="(@* | node()) except $attributes-to-preserve" mode="#current">
                <xsl:with-param name="first-ancestor-non-html-namespace-uri" as="xs:anyURI" select="
                        if ($this-ns-uri eq 'http://www.w3.org/1999/xhtml')
                        then
                            $first-ancestor-non-html-namespace-uri
                        else
                            $this-ns-uri"/>
            </xsl:apply-templates>
        </div>

    </xsl:template>
    
    <xsl:template match="@*" mode="tan:tree-to-html">
        <xsl:variable name="this-prefix" select="substring-before(name(.), ':')" as="xs:string"/>
        <xsl:variable name="these-classes" as="xs:string+">
            <xsl:sequence select="'a-' || local-name(.)"/>
            <!-- Copy the namespace as a prefix if there has been a change. -->
            <xsl:if test="(string-length($this-prefix) gt 0)">
                <xsl:sequence select="'ns-' || $this-prefix"/>
            </xsl:if>
        </xsl:variable>
        
        <div class="{string-join($these-classes, ' ')}">
            <xsl:sequence select="string(.)"/>
        </div>
        
    </xsl:template>
    
    
    <xsl:function name="tan:parse-a-hrefs" as="item()*" visibility="public">
        <!-- Input: a string -->
        <!-- Output: a sequence mixing text nodes and elements, with elements
            being HTML <a href=""/> wrappers for URIs.
        -->
        <!--kw: html, strings, filenames -->
        <xsl:param name="string-to-parse" as="xs:string?"/>
        <xsl:analyze-string select="$string-to-parse" regex="(file|https?|ftp)://?\S+">
            <xsl:matching-substring>
                <!-- Pull back from any characters at the end that aren't part of the URL proper. -->
                <xsl:analyze-string select="." regex="(&lt;[^&gt;]+&gt;|[&lt;\)\].;&quot;”&apos;])+$">
                    <xsl:matching-substring>
                        <xsl:sequence select="."/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:variable name="href-norm" select="replace(., '\.$', '')"/>
                        <a href="{$href-norm}">
                            <xsl:sequence select="."/>
                        </a>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
        
    </xsl:function>
    
    <xsl:mode name="tan:parse-a-hrefs" on-no-match="shallow-copy"/>
    
    <xsl:template match="html:a" mode="tan:parse-a-hrefs">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match=".[. instance of xs:string]" mode="tan:parse-a-hrefs">
        <xsl:sequence select="tan:parse-a-hrefs(.)"/>
    </xsl:template>
    <xsl:template match="text()" mode="tan:parse-a-hrefs">
        <xsl:sequence select="tan:parse-a-hrefs(.)"/>
    </xsl:template>

</xsl:stylesheet>
