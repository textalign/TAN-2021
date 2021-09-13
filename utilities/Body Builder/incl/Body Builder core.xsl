<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="tag:textalign.net,2015:ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for remodeling a text. -->
    
    <xsl:include href="Body%20Builder%20docx.xsl"/>
    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:convert-to-tan'"/>
    <xsl:param name="tan:stylesheet-name" select="'Body Builder'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'converts structured texts to a TEI/TAN body based on user-specified rules'"/>
    <xsl:param name="tan:stylesheet-description">Suppose you have texts, aspects of whose syntax,
        structure, or format correspond to TAN or TEI elements or markup. This application allows
        you to write regular-expression-based rules to convert that text into a TAN or TEI format.
        Input consists of one or more files in plain text, XML, or Word docx. The input is processed
        against each rule, in order of appearance, progressively structuring the text. Body Builder
        is intended for intermediate and advanced users who are comfortable with regular expressions
        and XML markup. The application is ideal for cases where complex, numerous, or lengthy
        documents need to be converted into TAN or TEI, as well as for developing workflows where live,
        ever-changing work needs to be regularly pushed into a TAN or TEI format. 
    </xsl:param>

    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">a TAN-T or TAN-TEI file that
        represents a target template for the parsed content coming from the secondary
        input</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">one or more non-TAN files
        in plain text, XML, or Word format (docx); perhaps configuration files for the
        parameters</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">the primary output with its
        contents replaced by a tree parsed by applying rules to the source</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>
    
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-change-message" select="'Converting text from the following ' || 
        string(count($source-input-uris-resolved)) || ' files to TAN, using ' ||
        $source-input-uri-resolved || ' as the basis for the source text'"/>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2021-07-13">Anchor comments to gaps between characters, so they are not lost when the anchored text is lost.</comment>
            <comment who="kalvesmaki" when="2021-07-13">Support HTML input</comment>
            <comment who="kalvesmaki" when="2021-07-13">Support ODT input</comment>
            <comment who="kalvesmaki" when="2021-07-13">Let the default template be a document with
                the root element body.</comment>
            <comment who="kalvesmaki" when="2021-07-13">Support parsing of docx endnotes and footnotes.</comment>
            <comment who="kalvesmaki" when="2021-07-13">Demonstrate how to convert a raw index to TAN-A.</comment>
        </to-do>
    </xsl:param>


    <!-- Normalize the parameters -->
    
    <xsl:variable name="source-input-uri-resolved" as="xs:anyURI?"
        select="resolve-uri($relative-path-to-source-input, $calling-stylesheet-uri)"/>
    
    <xsl:variable name="source-input-uris-resolved" as="xs:anyURI*" select="
            if (matches($source-input-uri-resolved, '[?*]')) then
                sort(tan:uri-collection-from-pattern($source-input-uri-resolved))
            else
                resolve-uri($relative-path-to-source-input, $calling-stylesheet-uri)"/>
    
    <xsl:variable name="some-source-input-is-docx" as="xs:boolean" select="
            some $i in $source-input-uris-resolved
                satisfies tan:docx-file-available($i)"/>
    
    <xsl:variable name="source-input-files" as="document-node()*"
        select="tan:open-file($source-input-uris-resolved)"/>
    
    <xsl:variable name="fallback-tan-template-uri-resolved" as="xs:anyURI?" select="
            if (matches($relative-path-to-fallback-TAN-template, '\S'))
            then
                resolve-uri($relative-path-to-fallback-TAN-template, $calling-stylesheet-uri)
            else
                ()"/>
    <xsl:variable name="fallback-template" as="document-node()?" select="
            if (doc-available($fallback-tan-template-uri-resolved)) then
                doc($fallback-tan-template-uri-resolved)
            else
                ()"/>
    
    <xsl:variable name="tan-template" as="document-node()">
        <xsl:choose>
            <xsl:when test="exists(/tei:TEI) or exists(tan:TAN-T) or exists(tan:TAN-A)">
                <xsl:sequence select="/"/>
            </xsl:when>
            <xsl:when test="exists($fallback-template/tei:TEI) or exists($fallback-template/tan:TAN-T) 
                or exists($fallback-template/tan:TAN-A)">
                <xsl:sequence select="$fallback-template"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="doc($tan:default-tan-t-template-uri-resolved)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="orphan-text-option-norm" as="xs:integer">
        <xsl:choose>
            <xsl:when test="$orphan-text-option = (1, 2, 3)">
                <xsl:sequence select="$orphan-text-option"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'Orphan text option should be 1, 2, or 3, not ' || xs:string($orphan-text-option) || '; using default option 3.'"/>
                <xsl:sequence select="3"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="template-is-tei" as="xs:boolean" select="exists($tan-template/tei:*)"/>
    <xsl:variable name="output-namespace" as="xs:string" select="
            if ($template-is-tei) then
                $tan:TEI-namespace
            else
                $tan:TAN-namespace"/>
    
    
    <!-- Format types -->
    
    <xsl:variable name="formats-of-interest" as="xs:string*" select="
            distinct-values(for $i in ($main-text-to-markup/tan:where/@format, $comments-to-markup/tan:where/@format)
            return
                tokenize(normalize-space(lower-case($i)), ' '))"/>
    
    
    
    <!-- NORMALIZE MARKUP -->
    
    <xsl:variable name="main-text-markup-to-replace-elements" as="element()*">
        <xsl:apply-templates select="$main-text-to-markup" mode="normalize-markup-instructions"/>
    </xsl:variable>
    
    <xsl:variable name="comments-to-markup-normalized" as="element()*">
        <xsl:apply-templates select="$comments-to-markup" mode="normalize-markup-instructions"/>
    </xsl:variable>
    
    <xsl:mode name="normalize-markup-instructions" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:markup" mode="normalize-markup-instructions">
        <!-- We convert each markup into a sequence of <replace>s, based on <where> children -->
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!-- Skip the replacement nodes. They will be tucked into the <where>, changed to <replace> -->
    <xsl:template match="tan:markup/node()" mode="normalize-markup-instructions" priority="-1"/>
    
    <xsl:template match="tan:where" mode="normalize-markup-instructions">
        <xsl:choose>
            <xsl:when test="not($some-source-input-is-docx) and exists(@format)"/>
            <xsl:otherwise>
                <replace>
                    <xsl:copy-of select="@*"/>
                    <!-- If @cuts appears in the parent, we want that -->
                    <xsl:copy-of select="parent::*/@*"/>
                    <xsl:if test="not(exists(@pattern))">
                        <xsl:attribute name="pattern" select="'.+'"/>
                    </xsl:if>
                    <xsl:attribute name="id" select="generate-id(.)"/>
                    <xsl:apply-templates select="following-sibling::node()"
                        mode="normalize-special-anchor-replacements"/>
                </replace>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:mode name="normalize-special-anchor-replacements" on-no-match="shallow-copy"/>
    
    <xsl:template match="text()" mode="normalize-special-anchor-replacements">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <xsl:template match="*" mode="normalize-special-anchor-replacements">
        <xsl:choose>
            <xsl:when test="$template-is-tei">
                <xsl:element name="{local-name(.)}" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy copy-namespaces="no">
                    <xsl:apply-templates select="@*" mode="#current"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:where" mode="normalize-special-anchor-replacements"/>
    <xsl:template match="@level" mode="normalize-special-anchor-replacements">
        <xsl:attribute name="_level" select="."/>
    </xsl:template>
    
    
    
    
    <!-- SOURCE INPUT -->
    
    <xsl:variable name="source-input-map" as="map(*)">
        <xsl:map>
            <xsl:map-entry key="'text'">
                <xsl:choose>
                    <xsl:when test="$some-source-input-is-docx">
                        <text>
                            <xsl:value-of select="xs:string($input-docx-text)"/>
                        </text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="xs:string($source-input-files)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:map-entry>
            <xsl:if test="$some-source-input-is-docx">
                <xsl:map-entry key="'format'" select="$input-docx-format-map"/>
            </xsl:if>
        </xsl:map>
    </xsl:variable>
    
    
    <xsl:variable name="source-input-pass-1-map" as="map(*)">
        <xsl:choose>
            <xsl:when test="not(exists($initial-adjustments))">
                <xsl:sequence select="$source-input-map"/>
            </xsl:when>
            <xsl:when test="not($some-source-input-is-docx)">
                <xsl:map>
                    <xsl:map-entry key="'text'"
                        select="tan:batch-replace($source-input-map('text'), $initial-adjustments)"
                    />
                </xsl:map>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence
                    select="tan:batch-replace-docx($source-input-map, $initial-adjustments)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>


    <xsl:variable name="source-input-pass-2-map" as="map(*)">
        <xsl:choose>
            <xsl:when test="not(exists($main-text-to-markup))">
                <xsl:message select="'No instructions have been provided on converting main text to markup.'"/>
                <xsl:sequence select="$source-input-pass-1-map"/>
            </xsl:when>
            <xsl:when test="not($some-source-input-is-docx)">
                <xsl:map>
                    <xsl:map-entry key="'text'"
                        select="tan:batch-replace-advanced($source-input-pass-1-map('text'), $main-text-markup-to-replace-elements)"
                    />
                </xsl:map>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence
                    select="tan:batch-replace-docx($source-input-pass-1-map, $main-text-markup-to-replace-elements)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="source-input-pass-2-map-format-keys" as="xs:integer*" select="
            if (exists($source-input-pass-2-map('format'))) then
                map:keys($source-input-pass-2-map('format'))
            else
                ()"/>
    
    <xsl:variable name="comment-codes-of-interest" as="xs:string*" select="
            for $i in $comments-of-interest/w:comments/w:comment/@id
            return
                'comment#' || $i"/>
    
    <xsl:variable name="source-input-pass-2-map-format-keys-for-comments" as="xs:integer*" select="
            for
            $i in sort($source-input-pass-2-map-format-keys)
            return
                if ($source-input-pass-2-map('format')($i) = $comment-codes-of-interest) then
                    $i
                else
                    ()"/>
    
    
    <!-- handle the comments -->
    
    <xsl:variable name="comments-of-interest-pos-group-array" as="array(xs:integer+)?"
        select="tan:integer-groups($source-input-pass-2-map-format-keys[exists($source-input-pass-2-map('format')(.)[starts-with(., 'comment#')])])"
    />
    
    <xsl:variable name="comments-of-interest-pos-to-group-map" as="map(xs:integer,xs:integer)?">
        <!-- Create a reverse lookup tool: if you know the position, get the group number it's in. -->
        <xsl:if test="exists($comments-of-interest-pos-group-array)">
            <xsl:map>
                <xsl:for-each select="1 to array:size($comments-of-interest-pos-group-array)">
                    <xsl:variable name="this-array-member-no" as="xs:integer" select="."/>
                    <xsl:variable name="these-array-member-items" as="xs:integer+" select="$comments-of-interest-pos-group-array($this-array-member-no)"/>
                    <xsl:for-each select="$these-array-member-items">
                        <xsl:map-entry key="." select="$this-array-member-no"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:map>
            
        </xsl:if>
    </xsl:variable>
    
    <xsl:variable name="comments-of-interest-id-to-pos-map" as="map(xs:string,xs:integer+)">
        <xsl:map>
            <xsl:for-each-group select="$source-input-pass-2-map-format-keys"
                group-by="$source-input-pass-2-map('format')(current())[starts-with(., 'comment#')]">
                <xsl:map-entry key="replace(current-grouping-key(), 'comment#', '')"
                    select="sort(current-group())"/>
            </xsl:for-each-group> 
        </xsl:map>
    </xsl:variable>
    
    <xsl:variable name="comments-of-interest-placement-arrays" as="array(*)*">
        <!-- Each array has four singleton members, and perhaps five: the id of the comment with 
            the markup, the starting position, the length of the cut, a boolean indicating whether 
            the markup can cut through (break up) markup. Any nestable comments feature in the fifth
            member position, recursively applied. -->
        <xsl:for-each-group select="map:keys($comments-of-interest-id-to-pos-map)" group-by="
                let $i := $comments-of-interest-id-to-pos-map(current())
                return
                    $comments-of-interest-pos-to-group-map($i[1])">
            <xsl:sort select="current-grouping-key()"/>
            
            <xsl:variable name="these-ids" as="xs:string+">
                <xsl:for-each select="current-group()">
                    <!-- sort ascending by first placement mark -->
                    <xsl:sort select="$comments-of-interest-id-to-pos-map(current())[1]"/>
                    <!-- then by the last one, from largest to smallest, to encompass as many as possible -->
                    <xsl:sort select="$comments-of-interest-id-to-pos-map(current())[last()]"
                        order="descending"/>
                    <xsl:sequence select="."/>
                </xsl:for-each>
            </xsl:variable>

            <!--<xsl:variable name="current-group-as-arrays" as="array(*)+" select="
                    for $i in $these-ids
                    return
                        array {$i, $comments-of-interest-id-to-pos-map($i)[1], $comments-of-interest-id-to-pos-map($i)[last()]}"/>-->
            <xsl:variable name="current-group-as-arrays" as="array(*)+">
                <xsl:for-each select="$these-ids">
                    <xsl:variable name="this-id" as="xs:string" select="."/>
                    <xsl:variable name="this-comment-markup" as="element()"
                        select="$comments-of-interest/w:comments/w:comment[@id eq $this-id]/tan:markup[1]"/>
                    <xsl:variable name="this-is-starting-slice" as="xs:boolean"
                        select="$this-comment-markup/@slice = 'start'"/>
                    <xsl:variable name="this-is-ending-slice" as="xs:boolean"
                        select="$this-comment-markup/@slice = 'end'"/>
                    <xsl:variable name="this-can-cut" as="xs:boolean"
                        select="$this-comment-markup/@cuts = 'true'"/>
                    
                    <xsl:variable name="comment-start-pos" as="xs:integer" select="$comments-of-interest-id-to-pos-map($this-id)[1]"/>
                    
                    <xsl:variable name="starting-pos-norm" as="xs:integer">
                        <xsl:choose>
                            <xsl:when test="$this-is-ending-slice">
                                <xsl:sequence
                                    select="$comments-of-interest-id-to-pos-map($this-id)[last()]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="$comment-start-pos"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:variable name="length-of-maintext" as="xs:integer">
                        <!-- Zero signals markup that takes zero width -->
                        <xsl:choose>
                            <xsl:when test="$this-is-starting-slice or $this-is-ending-slice">
                                <xsl:sequence select="0"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence
                                    select="$comments-of-interest-id-to-pos-map($this-id)[last()] - $starting-pos-norm + 1"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:sequence select="array {$this-id, $starting-pos-norm, $length-of-maintext, $this-can-cut}"/>
                </xsl:for-each>
            </xsl:variable>

            <xsl:sequence select="tan:nest-placement-arrays($current-group-as-arrays)"/>
        </xsl:for-each-group> 
    </xsl:variable>
    
    <xsl:function name="tan:nest-placement-arrays" as="array(*)*" visibility="private">
        <!-- Input: a sequence of placement arrays -->
        <!-- Output: an array in which the arrays nest inside one another -->
        <!-- Example: 
                input: {'d278e7', 31, 4, true()}, {'d278e9', 31, 2, true()}
                output: {'d278e7', 31, 4, true(), {'d278e7', 31, 2, true()}}
        -->
        <xsl:param name="arrays-to-place" as="array(*)*"/>
        
        <xsl:variable name="arrays-to-place-sorted" as="array(*)*">
            <xsl:for-each select="$arrays-to-place">
                <xsl:sort select=".(2)"/>
                <xsl:sort select=".(3)" order="descending"/>
                <xsl:sequence select="."/>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="not(exists($arrays-to-place-sorted))"/>
            <xsl:otherwise>
                <xsl:variable name="first-array" as="array(*)" select="$arrays-to-place-sorted[1]"/>
                <xsl:variable name="first-array-lower-limit" as="xs:integer" select="$first-array(2)"/>
                <xsl:variable name="first-array-length" as="xs:integer" select="$first-array(3)"/>
                <xsl:variable name="first-array-upper-limit" as="xs:integer"
                    select="max(($first-array-lower-limit + $first-array-length - 1, $first-array-lower-limit))"
                />
                <xsl:variable name="arrays-to-place" as="array(*)*" select="tail($arrays-to-place-sorted)"/>
                
                <xsl:variable name="arrays-that-should-be-prepended" as="array(*)*">
                    <xsl:for-each select="$arrays-to-place">
                        <xsl:sort select="current()(2)"/>
                        <xsl:sort select="current()(3)" order="descending"/>
                        <xsl:if test=".(2) lt $first-array-lower-limit and (.(2) + .(3)) le $first-array-lower-limit">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="arrays-that-should-be-nested" as="array(*)*">
                    <xsl:for-each select="$arrays-to-place">
                        <xsl:sort select="current()(2)"/>
                        <xsl:sort select="current()(3)" order="descending"/>
                        <xsl:if test=".(2) ge $first-array-lower-limit and (.(2) + .(3) - 1) le $first-array-upper-limit">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="arrays-that-should-be-appended" as="array(*)*">
                    <xsl:for-each select="$arrays-to-place">
                        <xsl:sort select="current()(2)"/>
                        <xsl:sort select="current()(3)" order="descending"/>
                        <xsl:if test=".(2) gt $first-array-upper-limit">
                            <xsl:sequence select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- report on comments that must be rejected because they overlap with other comments -->
                <xsl:for-each select="$arrays-to-place">
                    <xsl:if test="
                            (.(2) lt $first-array-lower-limit and (.(2) + .(3)) gt $first-array-lower-limit)
                            or (.(2) le $first-array-upper-limit and (.(2) + .(3) - 1) gt $first-array-upper-limit)">
                        <xsl:variable name="comment-id" as="xs:string" select=".(1)"/>
                        <xsl:variable name="comment-item" as="element()" select="$comments-of-interest/w:comments/w:comment[@id eq $comment-id]"/>
                        <xsl:variable name="diag-message" as="element()">
                            <test11a>
                                <first-array><xsl:copy-of select="array:flatten($first-array)"/></first-array>
                                <this-array><xsl:copy-of select="array:flatten(.)"/></this-array>
                                <fa-ll><xsl:copy-of select="$first-array-lower-limit"/></fa-ll>
                                <fa-ul><xsl:copy-of select="$first-array-upper-limit"/></fa-ul>
                            </test11a>
                        </xsl:variable>
                        <xsl:message
                            select="'comment ' || $comment-item/@w:id || ' cannot be placed, because it overlaps another comment; ignored comment: ' || string-join($comment-item/tan:text)"/>
                        <xsl:message select="$diag-message"/>
                    </xsl:if>
                </xsl:for-each>
                
                
                <xsl:sequence select="tan:nest-placement-arrays($arrays-that-should-be-prepended)"/>
                <xsl:sequence
                    select="array:append($first-array, tan:nest-placement-arrays($arrays-that-should-be-nested))"
                />
                <xsl:sequence select="tan:nest-placement-arrays($arrays-that-should-be-appended)"/>
                
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:mode name="nest-placement-arrays" on-no-match="shallow-copy"/>
    
    <xsl:template match=".[. instance of array(*)]" mode="nest-placement-arrays"></xsl:template>
    
    
    <!-- Sometimes the reconstructed hierarchy winds up in the middle of a structure
      that it should govern. For example, if italics are first turned to <quote>s, then 
      something in the quote becomes part of the hierarchy, the <quote> should be split,
      with its parts pushed to the inner area. Put another way, if any element is 
      introduced in the earlier stage without an explicit @level (changed to @_level per
      specs of tan:sequence-to-tree()), then it is intended to be at the leafmost part
      of the tree.
   -->
    <xsl:variable name="source-input-pass-2b" as="element()?">
        <xsl:apply-templates select="$source-input-pass-2-map('text')"
            mode="fix-constructed-hierarchy"/>
    </xsl:variable>
    
    <xsl:mode name="fix-constructed-hierarchy" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:text" priority="1" mode="fix-constructed-hierarchy">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[@_level][descendant::*[@_level]]" priority="1" mode="fix-constructed-hierarchy">
        <xsl:copy-of select="tan:shallow-copy(.)"/>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="*[@_level]" mode="fix-constructed-hierarchy">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="*[not(@_level)][descendant::*[@_level]]" mode="fix-constructed-hierarchy">
        <xsl:param name="leafmost-element-sequence" tunnel="yes" as="element()*"/>
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="leafmost-element-sequence" tunnel="yes"
                select="$leafmost-element-sequence, tan:shallow-copy(.)"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="text()" mode="fix-constructed-hierarchy">
        <xsl:param name="leafmost-element-sequence" tunnel="yes" as="element()*"/>
        <xsl:variable name="this-text" as="text()" select="."/>
        <xsl:choose>
            <xsl:when test="exists($leafmost-element-sequence)">
                <xsl:apply-templates select="$leafmost-element-sequence[1]" mode="rebuild-hierarchy">
                    <xsl:with-param name="shallow-elements" as="element()*"
                        select="tail($leafmost-element-sequence)" tunnel="yes"/>
                    <xsl:with-param name="innermost-content" tunnel="yes" select="."/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:mode name="rebuild-hierarchy" on-no-match="shallow-copy"/>
    
    <xsl:template match="*" mode="rebuild-hierarchy">
        <xsl:param name="shallow-elements" as="element()*" tunnel="yes"/>
        <xsl:param name="innermost-content" tunnel="yes" as="item()*"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
                <xsl:choose>
                    <xsl:when test="exists($shallow-elements)">
                        <xsl:apply-templates select="$shallow-elements[1]" mode="#current">
                            <xsl:with-param name="shallow-elements" as="element()*"
                                select="tail($shallow-elements)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$innermost-content"/>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:copy>
    </xsl:template>



    <xsl:variable name="source-input-pass-3" as="element()?"
        select="tan:sequence-to-tree($source-input-pass-2b)"/>
    




    <xsl:variable name="source-input-pass-3b" as="element()?">
        <xsl:apply-templates select="$source-input-pass-3" mode="apply-comment-markup">
            <xsl:with-param name="comment-placement-arrays" tunnel="yes" select="$comments-of-interest-placement-arrays"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:mode name="apply-comment-markup" on-no-match="shallow-copy"/>
    
    <xsl:template match="*[not(text())]" mode="apply-comment-markup">
        <xsl:param name="starting-pos" tunnel="yes" as="xs:integer" select="1"/>
        <xsl:param name="comment-placement-arrays" tunnel="yes" as="array(*)*"/>
        
        <xsl:variable name="context-length" as="xs:integer" select="tan:string-length(.)"/>
        <xsl:variable name="next-sibling-starting-pos" as="xs:integer" select="$starting-pos + $context-length"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode apply-comment-markup, at ', tan:shallow-copy(.)"/>
            <xsl:message select="'Comment placement arrays: ', $comment-placement-arrays"/>
            <xsl:message select="'Starting pos: ', $starting-pos"/>
            <xsl:message select="'Context length: ', $context-length"/>
        </xsl:if>
        
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:iterate select="node()">
                <xsl:param name="current-starting-pos" as="xs:integer" select="$starting-pos"/>
                
                <xsl:variable name="current-length" as="xs:integer" select="tan:string-length(.)"/>
                <xsl:variable name="next-starting-pos" as="xs:integer" select="$current-starting-pos + $current-length"/>
                
                <xsl:variable name="placement-arrays-to-send-through" as="array(*)*">
                    <xsl:for-each select="$comment-placement-arrays">
                        <xsl:variable name="this-array-begins-here" as="xs:boolean"
                            select=".(2) ge $current-starting-pos and .(2) lt $next-starting-pos"/>
                        <xsl:variable name="this-array-can-cut" as="xs:boolean" select=".(4)"/>
                        <xsl:choose>
                            <xsl:when test="not($this-array-begins-here)"/>
                            <!-- If the array begins here, but ends beyond, well, oops, that's a problem. -->
                            <xsl:when test=".(3) gt $current-length and not($this-array-can-cut)">
                                <xsl:message select="'comment ' || .(1) || ' cannot be applied because it overlaps the constructed hierarchy.'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:variable>
                
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'Node iteration: ', position()"/>
                    <xsl:message select="'Node type: ', tan:item-type(.)"/>
                    <xsl:message select="'Current starting pos: ', $current-starting-pos"/>
                    <xsl:message select="'Current length: ', $current-length"/>
                    <xsl:message select="'Placement arrays to send through: ', $placement-arrays-to-send-through"/>
                </xsl:if>
                
                <xsl:choose>
                    <xsl:when test=". instance of element()">
                        
                        
                        <xsl:apply-templates select="." mode="#current">
                            <xsl:with-param name="comment-placement-arrays" tunnel="yes" select="$placement-arrays-to-send-through"/>
                            <xsl:with-param name="starting-pos" tunnel="yes" select="$current-starting-pos"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:next-iteration>
                    <xsl:with-param name="current-starting-pos" select="$current-starting-pos + $current-length"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="*[text()]" mode="apply-comment-markup">
        <xsl:param name="starting-pos" tunnel="yes" as="xs:integer" select="1"/>
        <xsl:param name="comment-placement-arrays" tunnel="yes" as="array(*)*"/>
        
        <xsl:variable name="context-element" as="element()" select="."/>
        <xsl:variable name="next-pos" as="xs:integer" select="$starting-pos + tan:string-length(.)"/>
        
        <xsl:variable name="all-text-positions" as="xs:integer+">
            <xsl:iterate select="node()">
                <xsl:param name="current-starting-pos" as="xs:integer" select="$starting-pos"/>
                <xsl:variable name="current-length" as="xs:integer" select="tan:string-length(.)"/>
                
                <xsl:if test=". instance of text() and $current-length gt 0">
                    <xsl:sequence select="
                            for $i in (1 to $current-length)
                            return
                                ($current-starting-pos + $i - 1)"/>
                </xsl:if>
                
                <xsl:next-iteration>
                    <xsl:with-param name="current-starting-pos"
                        select="$current-starting-pos + $current-length"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        <xsl:variable name="all-element-positions" as="array(xs:integer+)?">
            <xsl:iterate select="node()">
                <xsl:param name="current-starting-pos" as="xs:integer" select="$starting-pos"/>
                <xsl:param name="array-so-far" as="array(xs:integer+)?"/>
                
                <xsl:on-completion select="$array-so-far"/>
                
                <xsl:variable name="current-length" as="xs:integer" select="tan:string-length(.)"/>
                
                <xsl:variable name="new-sequence" as="xs:integer*" select="
                        if ($current-length gt 0) then
                            (for $i in (1 to $current-length)
                            return
                                ($current-starting-pos + $i - 1))
                        else
                            ()"/>
                <xsl:variable name="new-array" as="array(xs:integer+)?" select="
                        if (. instance of element() and $current-length gt 0) then
                            if (not(exists($array-so-far))) then
                                [($new-sequence)]
                            else
                                array:append($array-so-far, $new-sequence)
                        else
                            $array-so-far"/>
                
                <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message select="'iteration ', position()"/>
                    <xsl:message select="'node type: ' || tan:item-type(.)"/>
                    <xsl:message select="'string length:', $current-length"/>
                    <xsl:message select="'new sequence: ', $new-sequence"/>
                    <xsl:message select="'new array: ', $new-array"/>
                </xsl:if>
                
                <xsl:next-iteration>
                    <xsl:with-param name="current-starting-pos"
                        select="$current-starting-pos + $current-length"/>
                    <xsl:with-param name="array-so-far" select="$new-array"/>
                </xsl:next-iteration>
            </xsl:iterate>
            
        </xsl:variable>
        <xsl:variable name="all-elements-pos-to-group-no" as="map(xs:integer,xs:integer)">
            <xsl:map>
                <xsl:if test="exists($all-element-positions)">
                    <xsl:for-each select="1 to array:size($all-element-positions)">
                        <xsl:variable name="this-array-member-no" as="xs:integer" select="."/>
                        <xsl:for-each select="$all-element-positions($this-array-member-no)">
                            <xsl:map-entry key="." select="$this-array-member-no"/>
                        </xsl:for-each>
                    </xsl:for-each> 
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        
        <xsl:variable name="placement-arrays-to-use" as="array(*)*">
            <xsl:for-each select="$comment-placement-arrays">
                <xsl:variable name="comm-start-pos" as="xs:integer" select=".(2)"/>
                <xsl:variable name="comm-length" as="xs:integer" select=".(3)"/>
                <!-- If the length is zero, we don't want the end position less than the starting one, at least for this
                    exercise. -->
                <xsl:variable name="comm-end-pos" as="xs:integer" select="max(($comm-start-pos + $comm-length - 1, $comm-start-pos))"/>
                <xsl:variable name="comm-markup-can-cut" as="xs:boolean" select=".(4)"/>
                <xsl:variable name="this-begins-here" as="xs:boolean"
                    select="$comm-start-pos ge $starting-pos and $comm-start-pos lt $next-pos"/>
                <xsl:variable name="this-begins-inside-text" as="xs:boolean"
                    select="$comm-start-pos = $all-text-positions"/>
                <xsl:variable name="this-ends-inside-text" as="xs:boolean"
                    select="$comm-end-pos = $all-text-positions"/>
                <xsl:variable name="this-begins-in-an-element" as="xs:boolean"
                    select="$comm-start-pos = array:flatten($all-element-positions)"/>
                <xsl:variable name="this-ends-in-an-element" as="xs:boolean"
                    select="$comm-end-pos = array:flatten($all-element-positions)"/>
                <xsl:variable name="this-begins-and-ends-inside-the-same-element" as="xs:boolean"
                    select="
                        $this-begins-in-an-element
                        and $this-ends-in-an-element
                        and $all-elements-pos-to-group-no($comm-start-pos) eq $all-elements-pos-to-group-no($comm-end-pos)"
                />
                <xsl:choose>
                    <xsl:when test="not($this-begins-here)"/>
                    <xsl:when test="$this-begins-and-ends-inside-the-same-element">
                        <!-- We append to the array a value that specifies whether or not the array in question
                            starts and ends within the same element. These need special treatment in output, because 
                            they nest within, and do not wrap, the element in question. -->
                        <xsl:sequence select="array:append(., true())"/>
                    </xsl:when>
                    <xsl:when test="$comm-markup-can-cut">
                        <xsl:sequence select="array:append(., false())"/>
                    </xsl:when>
                    <xsl:when test="$this-begins-inside-text and $this-ends-inside-text">
                        <xsl:sequence select="array:append(., false())"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="this-comment-id" as="xs:string?" select=".(1)"/>
                        <xsl:variable name="this-comment" as="element()?"
                            select="$comments-of-interest/w:comments/w:comment[@id eq $this-comment-id]"/>
                        <xsl:message select="'Cannot apply markup for comment ' || $this-comment/@w:id || ' because it overlaps parts of the tree hierarchy. Problematic comment: ', $this-comment/tan:text/node()"/>
                        <xsl:message select="'Context element: ', $context-element"/>
                        <xsl:message select="'Comment anchor start, end position: ', $comm-start-pos, $comm-end-pos"/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="these-chop-points" as="xs:integer*" select="
                for $i in $placement-arrays-to-use
                return
                    ($i(2) - $starting-pos + 1, ($i(2) + $i(3)) - $starting-pos + 1)"/>
        
        <xsl:variable name="context-chopped-map" as="map(*)?" select="tan:chop-tree(., $these-chop-points)"/>
        
        <xsl:variable name="result-container" as="element()">
            <xsl:copy copy-namespaces="no">
                <xsl:copy-of select="@*"/>
                <xsl:choose>
                    <xsl:when test="not(exists($placement-arrays-to-use))">
                        <xsl:copy-of select="node()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="map:keys($context-chopped-map)">
                            <xsl:sort/>
                            <xsl:variable name="this-slice-starting-number" as="xs:integer"
                                select="."/>
                            <xsl:variable name="this-placement-array" as="array(*)?" select="
                                    for $i in $placement-arrays-to-use
                                    return
                                        (if ($i(2) eq ($this-slice-starting-number + $starting-pos - 1)) then
                                            $i
                                        else
                                            ())"/>
                            <!-- We remove the last entry in the array, because it only temporarily indicated whether the
                                comment markup needed to nest within the element. -->
                            <xsl:variable name="this-placement-array-restored" as="array(*)?"
                                select="
                                    if (exists($this-placement-array)) then
                                        array:remove($this-placement-array, array:size($this-placement-array))
                                    else
                                        ()"/>
                            
                            <xsl:variable name="this-comment-id" as="xs:string?" select="
                                    if (exists($this-placement-array)) then
                                        $this-placement-array(1)
                                    else
                                        ()"/>
                            <xsl:variable name="this-comment" as="element()?"
                                select="$comments-of-interest/w:comments/w:comment[@id eq $this-comment-id]"/>
                            <xsl:variable name="markup-to-apply" as="element()*" select="$this-comment/tan:markup"/>
                            <xsl:variable name="this-markup-must-nest" as="xs:boolean"
                                select="exists($this-placement-array) and (array:head(array:reverse($this-placement-array)) eq true())"
                            />
                            
                            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
                            <xsl:if test="$diagnostics-on">
                                <xsl:message select="'Diagnostics on, $result-container, iteration #' || string(position())"/>
                                <xsl:message select="'This slice starting number: ', $this-slice-starting-number"/>
                                <xsl:message select="'This placement array: ', $this-placement-array"/>
                                <xsl:message select="'This placement array restored: ', $this-placement-array-restored"/>
                                <xsl:message select="'This comment id: ' || $this-comment-id"/>
                                <xsl:message select="'This comment: ', $this-comment"/>
                                <xsl:message select="'Markup to apply: ', $markup-to-apply"/>
                                <xsl:message select="'Markup must nest?', $this-markup-must-nest"/>
                                <xsl:message select="'Map slice picked: ', $context-chopped-map($this-slice-starting-number)"/>
                            </xsl:if>
                            
                            <xsl:choose>
                                <xsl:when test="exists($this-placement-array) and exists($this-comment) and $this-markup-must-nest">
                                    <!-- If the comment-markup is supposed to nest, it can do so only within an element. Therefore
                                        the current context map slice must begin with a single element, followed perhaps by other 
                                        nodes, especially if the context element is mixed. The nesting instruction is injected into 
                                        the first element, and any following nodes are copied. -->
                                    <xsl:apply-templates select="$context-chopped-map($this-slice-starting-number)/*" mode="#current">
                                        <xsl:with-param name="comment-placement-arrays" tunnel="yes" select="$this-placement-array-restored"/>
                                        <xsl:with-param name="starting-pos" tunnel="yes"
                                            select="$this-slice-starting-number + $starting-pos - 1"
                                        />
                                    </xsl:apply-templates>
                                    <xsl:copy-of select="$context-chopped-map($this-slice-starting-number)/*/following-sibling::node()"/>
                                </xsl:when>
                                <xsl:when
                                    test="exists($this-placement-array) and exists($this-comment)">
                                    <xsl:apply-templates select="$markup-to-apply/node()"
                                        mode="apply-comment-markup-instance">
                                        <xsl:with-param name="starting-pos" tunnel="yes"
                                            as="xs:integer"
                                            select="$this-slice-starting-number + $starting-pos - 1"/>
                                        <!-- Pass the nested placement arrays through -->
                                        <xsl:with-param name="comment-placement-arrays" tunnel="yes"
                                            as="array(*)*" select="$this-placement-array-restored(5)"/>
                                        <xsl:with-param name="maintext-substitute" tunnel="yes" select="$context-chopped-map($this-slice-starting-number)/node()"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of
                                        select="$context-chopped-map($this-slice-starting-number)/node()"
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:copy>
        </xsl:variable>
        
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode apply-comment-markup, on element ', tan:shallow-copy(.)"/>
            <xsl:message select="'Starting pos: ', $starting-pos"/>
            <xsl:message select="'Comment placement arrays: ', $comment-placement-arrays"/>
            <xsl:message select="'Next pos:', $next-pos"/>
            <xsl:message select="'All text positions:', $all-text-positions"/>
            <xsl:message select="'All element positions: ', array:flatten($all-element-positions)"/>
            <xsl:message select="'All elements, pos to group number: ', tan:map-to-xml($all-elements-pos-to-group-no)"/>
            <xsl:message select="'Placement arrays to use: ', $placement-arrays-to-use"/>
            <xsl:message select="'Chop points: ', $these-chop-points"/>
            <xsl:message select="'Context chopped map: ', tan:map-to-xml($context-chopped-map, true())"/>
            <xsl:message select="'Result container: ', $result-container"/>
            <xsl:message select="'Result container restored:', tan:restore-chopped-tree($result-container)"/>
        </xsl:if>
        
        <xsl:copy-of select="tan:restore-chopped-tree($result-container)"/>
        
    </xsl:template>
    
    <xsl:template match="text()" mode="apply-comment-markup">
        <!-- The preceding, very long template, dealt with complex mixed-content demands. Here the 
            arrays are in a simple text node, and processing should be more straightforward. -->
        <xsl:param name="comment-placement-arrays" tunnel="yes" as="array(*)*"/>
        <xsl:param name="starting-pos" tunnel="yes" as="xs:integer" select="1"/>
        <xsl:choose>
            <xsl:when test="exists($comment-placement-arrays)">
                <!-- This produces a sequence of integers, one per placement array, with its 
                    starting position. -->
                <xsl:variable name="comment-placement-starting-poses" as="xs:integer+" select="
                        for $i in $comment-placement-arrays
                        return
                            $i(2)"/>
                <xsl:iterate select="string-to-codepoints(.)">
                    <xsl:param name="text-so-far" as="xs:string" select="''"/>
                    <xsl:param name="current-pos" as="xs:integer" select="$starting-pos"/>
                    <xsl:param name="array-being-processed" as="array(*)?"/>
                    <xsl:param name="array-finishes-at" as="xs:integer?"/>
                    
                    <xsl:on-completion select="$text-so-far"/>
                    
                    <xsl:variable name="this-pos" as="xs:integer" select="position()"/>
                    <xsl:variable name="matching-array-nos" as="xs:integer*"
                        select="index-of($comment-placement-starting-poses, $this-pos)"/>
                    <xsl:variable name="first-matching-array" as="array(*)?" select="$comment-placement-arrays[$this-pos[1]]"/>
                    <xsl:variable name="first-matching-array-length" as="xs:integer?" select="
                            if (exists($first-matching-array)) then
                                $first-matching-array(3)
                            else
                                ()"/>
                    
                    <xsl:variable name="finish-array-being-processed" as="xs:boolean"
                        select="exists($array-being-processed) and ($current-pos + 1 eq $array-finishes-at)"
                    />
                    <xsl:variable name="do-first-matching-array-now" as="xs:boolean"
                        select="exists($first-matching-array) and ($first-matching-array-length lt 2)"
                    />
                    
                    <xsl:variable name="new-text" as="xs:string?" select="
                            if ($finish-array-being-processed or $do-first-matching-array-now) then
                                ''
                            else
                                ($text-so-far || codepoints-to-string(.))"/>
                    
                    <xsl:variable name="next-array" as="array(*)?" select="
                            if (exists($first-matching-array) and not($do-first-matching-array-now))
                            then
                                $first-matching-array
                            else
                                if ($finish-array-being-processed) then
                                    ()
                                else
                                    $array-being-processed"/>
                    <xsl:variable name="new-array-finishes-at" as="xs:integer?" select="
                            if (exists($first-matching-array) and not($do-first-matching-array-now))
                            then
                                ($first-matching-array-length + $current-pos)
                            else
                                if ($finish-array-being-processed) then
                                    ()
                                else
                                    $array-finishes-at"/>
                    
                    
                    <xsl:if test="count($matching-array-nos) gt 1">
                        <xsl:message select="'Error: ' || string(count($matching-array-nos)) 
                            || ' correspond to position ' || string($current-pos + 1) 
                            || ', which should not happen if the comment arrays have been properly nested.'"/>
                    </xsl:if>
                    
                    <xsl:if test="$finish-array-being-processed or $do-first-matching-array-now">
                        <xsl:variable name="array-in-question" as="array(*)" select="$array-being-processed, $first-matching-array"/>
                        <xsl:variable name="this-comment-id" as="xs:string" select="$array-in-question(1)"/>
                        <xsl:variable name="this-comment" as="element()?"
                            select="$comments-of-interest/w:comments/w:comment[@id eq $this-comment-id]"/>
                        <xsl:variable name="markup-to-apply" as="element()*" select="$this-comment/tan:markup"/>
                        <xsl:variable name="text-placeholder" as="element()">
                            <text>
                                <xsl:value-of select="$text-so-far || codepoints-to-string(.)"/>
                            </text>
                        </xsl:variable>
                        <xsl:apply-templates select="$markup-to-apply/node()"
                            mode="apply-comment-markup-instance">
                            <xsl:with-param name="starting-pos" tunnel="yes" as="xs:integer"
                                select="$array-in-question(2)"/>
                            <!-- Pass through the nested placement arrays -->
                            <xsl:with-param name="comment-placement-arrays" tunnel="yes"
                                as="array(*)*" select="$array-in-question(5)"/>
                            <xsl:with-param name="maintext-substitute" tunnel="yes" select="$text-placeholder/text()"/>
                        </xsl:apply-templates>
                    </xsl:if>
                    
                    <xsl:next-iteration>
                        <xsl:with-param name="current-pos" select="$current-pos + 1"/>
                        <xsl:with-param name="text-so-far" select="$new-text"/>
                        <xsl:with-param name="array-being-processed" select="$next-array"/>
                        <xsl:with-param name="array-finishes-at" select="$new-array-finishes-at"/>
                    </xsl:next-iteration>
                </xsl:iterate>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:mode name="apply-comment-markup-instance" on-no-match="shallow-copy"/>
    
    <xsl:template match="tei:*" mode="apply-comment-markup-instance">
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="*:maintext" priority="1" mode="apply-comment-markup-instance">
        <xsl:param name="maintext-substitute" tunnel="yes" as="item()*"/>
        <xsl:choose>
            <xsl:when test="exists($maintext-substitute)">
                <xsl:apply-templates select="$maintext-substitute" mode="apply-comment-markup"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'Element maintext found, but no substitute has been supplied.'"/>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    
    <xsl:variable name="source-input-pass-4" as="element()?">
        <xsl:apply-templates select="tan:normalize-tree-space($source-input-pass-3b, false())"
            mode="consolidate-adjacent-identical-divs"/>
    </xsl:variable>
    
    <xsl:mode name="consolidate-adjacent-identical-divs" on-no-match="shallow-copy"/>
    
    <!-- Get shallow skip the containers that were placed in the previous round -->
    <xsl:template match="*[@container]" priority="1" mode="consolidate-adjacent-identical-divs">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*[*:div]" mode="consolidate-adjacent-identical-divs">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:for-each-group select="node()" group-adjacent="name(.) || '#' || @type || '#' || @n">
                <xsl:choose>
                    <xsl:when test="exists(current-group()/self::*:div)">
                        <xsl:variable name="this-consolidated" as="element()">
                            <xsl:element name="div" namespace="{$output-namespace}">
                                <xsl:copy-of select="current-group()/@*"/>
                                <xsl:copy-of select="current-group()/node()"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:apply-templates select="$this-consolidated" mode="#current"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="current-group()" mode="#current"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group> 
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:variable name="source-input-pass-5" as="element()?">
        <xsl:apply-templates select="$source-input-pass-4" mode="handle-orphan-text"/>
    </xsl:variable>
    
    <xsl:mode name="handle-orphan-text" on-no-match="shallow-copy"/>
    
    <xsl:template match="*[*:div][text()[matches(., '\S')]]" mode="handle-orphan-text">
        <xsl:param name="orphan-text" tunnel="yes" as="xs:string?"/>
        <xsl:variable name="context-orphan-text" as="text()+" select="text()[matches(., '\S')]"/>
        <xsl:if test="$orphan-text-option-norm eq 3">
            <xsl:message select="'Pushing to first leaf div the following orphaned text: ' || $context-orphan-text"/>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="orphan-text" tunnel="yes" select="
                        if ($orphan-text-option-norm eq 3) then
                            ($orphan-text || string-join($context-orphan-text))
                        else
                            ()"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[*:div]/text()[matches(., '\S')]" mode="handle-orphan-text">
        <xsl:if test="$orphan-text-option-norm eq 1">
            <xsl:message select="'Deleting the following orphaned text: ' || ."/>
        </xsl:if>
        <xsl:if test="$orphan-text-option-norm eq 2">
            <xsl:message select="'Wrapping in ad hoc div the following orphaned text: ' || ."/>
            <div type="section" n="orphan">
                <xsl:value-of select="."/>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="*:div[not(*:div)]" mode="handle-orphan-text">
        <xsl:param name="orphan-text" tunnel="yes" as="xs:string?"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="not(preceding-sibling::*:div)">
                <xsl:copy-of select="$orphan-text"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:apply-templates select="$tan-template" mode="infuse-template-with-new-body"/>
    </xsl:variable>
    
    <xsl:mode name="infuse-template-with-new-body" on-no-match="shallow-copy"/>
    
    <xsl:template match="*:body" mode="infuse-template-with-new-body">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="tan:copy-indentation($source-input-pass-5, .)/node()"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:variable name="output-pass-2" as="document-node()" select="tan:update-TAN-change-log($output-pass-1)"/>
    


    <!-- RESULT TREE -->
    <xsl:param name="output-diagnostics-on" static="yes" select="false()" as="xs:boolean"/>
    <xsl:output indent="yes" use-when="$output-diagnostics-on"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message
            select="'Using diagnostic output for application ' || $tan:stylesheet-name || ' (' || static-base-uri() || ')'"
        />
        <diagnostics>
            <source-input-uri-resolved><xsl:copy-of select="$source-input-uri-resolved"/></source-input-uri-resolved>
            <source-input-uris-resolved count="{count($source-input-uris-resolved)}"><xsl:copy-of select="$source-input-uris-resolved"/></source-input-uris-resolved>
            <!--<source-input-files count="{count($source-input-files)}"><xsl:copy-of select="$source-input-files"/></source-input-files>-->
            <!--<tan-template><xsl:copy-of select="$tan-template"/></tan-template>-->
            <main-text-markup-normalized><xsl:copy-of select="$main-text-markup-to-replace-elements"/></main-text-markup-normalized>
            <comments-to-markup-normalized><xsl:copy-of select="$comments-to-markup-normalized"/></comments-to-markup-normalized>
            <formats-of-interest count="{count($formats-of-interest)}"><xsl:value-of select="$formats-of-interest"/></formats-of-interest>
            <input-to-format-tree><xsl:copy-of select="$input-to-format-tree"/></input-to-format-tree>
            <input-formats-available count="{count($input-formats-available)}"><xsl:copy-of select="$input-formats-available"/></input-formats-available>
            <input-to-main-text-and-format-tree><xsl:copy-of select="$input-to-main-text-and-format-tree"/></input-to-main-text-and-format-tree>
            <input-to-comment-text-and-format-tree><xsl:copy-of select="$input-to-comment-text-and-format-tree"/></input-to-comment-text-and-format-tree>
            <comments-of-interest><xsl:copy-of select="$comments-of-interest"/></comments-of-interest>
            <input-main-text-and-format-tree-fused><xsl:copy-of select="$main-text-and-format-trees-fused"/></input-main-text-and-format-tree-fused>
            <input-main-text-and-format-trees-with-format-anchors-resolved><xsl:copy-of select="$main-text-and-format-trees-with-format-anchors-resolved"/></input-main-text-and-format-trees-with-format-anchors-resolved>
            <input-main-text-and-format-tree-stamped><xsl:copy-of select="$main-text-and-format-tree-stamped"/></input-main-text-and-format-tree-stamped>
            <!--<input-docx-format><xsl:copy-of select="tan:map-to-xml($input-docx-format-map, true())"/></input-docx-format>-->
            <!--<source-input-map><xsl:copy-of select="tan:map-to-xml($source-input-map, true())"/></source-input-map>-->
            <source-input-pass-1-map><xsl:copy-of select="tan:map-to-xml($source-input-pass-1-map, true())"/></source-input-pass-1-map>
            <source-input-pass-2-map><xsl:copy-of select="tan:map-to-xml($source-input-pass-2-map, true())"/></source-input-pass-2-map>
            <!--<source-input-pass-2-map-format-keys count="{count($source-input-pass-2-map-format-keys)}"><xsl:copy-of select="$source-input-pass-2-map-format-keys"/></source-input-pass-2-map-format-keys>-->
            <!--<comment-codes-of-interest count="{count($comment-codes-of-interest)}"><xsl:copy-of select="$comment-codes-of-interest"/></comment-codes-of-interest>-->
            <!--<source-input-pass-2-map-format-keys-for-comments count="{count($source-input-pass-2-map-format-keys-for-comments)}"><xsl:copy-of select="$source-input-pass-2-map-format-keys-for-comments"/></source-input-pass-2-map-format-keys-for-comments>-->
            <!--<comments-of-interest-pos-group-array><xsl:copy-of select="tan:array-to-xml($comments-of-interest-pos-group-array)"/></comments-of-interest-pos-group-array>-->
            <!--<comments-of-interest-pos-to-group-map><xsl:copy-of select="tan:map-to-xml($comments-of-interest-pos-to-group-map)"/></comments-of-interest-pos-to-group-map>-->
            <!--<comments-of-interest-id-to-pos-map><xsl:copy-of select="tan:map-to-xml($comments-of-interest-id-to-pos-map)"/></comments-of-interest-id-to-pos-map>-->
            <!--<comments-of-interest-placement-arrays><xsl:copy-of select="tan:array-to-xml($comments-of-interest-placement-arrays)"/></comments-of-interest-placement-arrays>-->
            <source-input-pass-2b><xsl:copy-of select="$source-input-pass-2b"/></source-input-pass-2b>
            <source-input-pass-3><xsl:copy-of select="$source-input-pass-3"/></source-input-pass-3>
            <source-input-pass-3b><xsl:copy-of select="$source-input-pass-3b"/></source-input-pass-3b>
            <source-input-pass-4><xsl:copy-of select="$source-input-pass-4"/></source-input-pass-4>
            <source-input-pass-5><xsl:copy-of select="$source-input-pass-5"/></source-input-pass-5>
            <!--<output-pass-1-template-infused><xsl:copy-of select="$output-pass-1"/></output-pass-1-template-infused>-->
            <!--<output-pass-2-credited><xsl:copy-of select="$output-pass-2"/></output-pass-2-credited>-->
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:if test="count($source-input-uris-resolved) gt 1">
            <xsl:message
                select="$source-input-uri-resolved || ' resolves into ' || string(count($source-input-uris-resolved)) || ' uris: ' || string-join($source-input-uris-resolved, ', ')"
            />
        </xsl:if>
        <xsl:if test="string-length(normalize-space($source-input-uri-resolved)) lt 1">
            <xsl:message select="'No source URI has been supplied; output will have an empty body'"/>
        </xsl:if>
        <xsl:if test="$some-source-input-is-docx">
            <xsl:message select="'Source docx input detected.'"/>
            <xsl:message select="'Ignore deletions:', $ignore-docx-deletions"/>
            <xsl:message select="'Ignore insertions: ', $ignore-docx-insertions"/>
            <xsl:message select="'Ignore comments: ', $ignore-comments"/>
            <xsl:message select="'Input formats available: ' || string-join($input-formats-available, ', ')"/>
            <xsl:message select="'Formats of interest: ' || string-join($formats-of-interest, ', ')"/>
            <xsl:message select="'Report any comments that are ignored?', $report-ignored-comments"/>
        </xsl:if>
        <xsl:message select="'Orphan text option:', $orphan-text-option-norm"/>
        <xsl:message select="$tan:stylesheet-change-message"/>
        
        <xsl:apply-templates select="$output-pass-2" mode="tan:doc-nodes-on-new-lines"/>
        
    </xsl:template>

</xsl:stylesheet>
