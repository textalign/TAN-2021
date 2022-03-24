<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">

    <!-- TAN Function Library html functions for diff and collate. -->

    <!-- Frequently the output of tan:diff() and tan:collate() will want to be viewed
        in HTML format. Perhaps that output will have been supplemented with comparative 
        statistics, 3-way venn statistics, or other elements. This file is devoted to 
        turning such material into HTML snippets that can then be injected into select
        parts of another HTML file, or become the body proper. It has been written in
        concert with diff.cs and diff.js files that are in the output/css and output/js
        directories. It has also been written to support the following core TAN
        applications:
            * Diff+
            * Parabola
    -->


    <xsl:function name="tan:diff-or-collate-to-html" as="item()*" visibility="public">
        <!-- Input: the results of tan:diff() or tan:collate(), ideally when given
        wrapped by <group> along with statistics; perhaps a string; perhaps a tree 
        structure (see below) -->
        <!-- Output: the results converted to HTML divs, with the following provisos:
        * Any adjustments to the text of the diff/collate output should be run beforehand,
        optimally via tan:replace-diff() or tan:replace-collation().
        * The second parameter points to an idref. If the main input is a diff, then the expected 
        value is 'a' or 'b' (default). If it is a collation, then it is a label that points
        to tan:collation/tan:witness/@id (default: the last one, if no match). The resolved
        parameter points to the primary version.
        * The third parameter is a tree structure of elements with the primary version. This is
        structure that will become the primary way to view the diff/collation. The diff/collation
        will be chopped proportionally to be infused into the text nodes of the tree. This allows
        the HTML file to be structured not as a flat diff/collate, but in a hierarchy that
        is native to one of the versions.
        * Collation ids are case-sensitive; diffs, however, must be simply a or b.
        * Any notices or other elements must be inserted before processing.
        -->
        <!--kw: html, diff, tree manipulation -->
        <xsl:param name="diff-or-collate-results" as="element()?"/>
        <xsl:param name="primary-version-ref" as="xs:string?"/>
        <xsl:param name="primary-version-tree" as="element()*"/>

        <xsl:variable name="main-diff-node" as="element()?"
            select="$diff-or-collate-results/(tan:diff | self::tan:diff)"/>
        <xsl:variable name="main-collation-node" as="element()?"
            select="$diff-or-collate-results/(tan:collation | self::tan:collation)"/>

        <xsl:variable name="is-diff" as="xs:boolean" select="exists($main-diff-node)"/>

        <xsl:variable name="collation-refs" as="attribute()*"
            select="$main-collation-node/tan:witness/@id"/>

        <xsl:variable name="primary-version-ref-adjusted" as="xs:string">
            <xsl:choose>
                <xsl:when test="$is-diff and not(lower-case($primary-version-ref) = ('a', 'b'))"
                    >b</xsl:when>
                <xsl:when test="$is-diff">
                    <xsl:value-of select="lower-case($primary-version-ref)"/>
                </xsl:when>
                <xsl:when test="not($collation-refs = $primary-version-ref)">
                    <xsl:value-of select="$primary-version-ref[last()]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$primary-version-ref"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- The next two variables are used only to check for potential problems, not to
            adjust the input or output. -->
        <xsl:variable name="primary-text" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$is-diff and $primary-version-ref eq 'a'">
                    <xsl:value-of select="string-join($main-diff-node/(tan:a | tan:common))"/>
                </xsl:when>
                <xsl:when test="$is-diff">
                    <xsl:value-of select="string-join($main-diff-node/(tan:b | tan:common))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of
                        select="string-join($main-collation-node/(tan:c | tan:u[tan:wit/@ref = $primary-version-ref-adjusted]))"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="primary-version-tree-text" as="xs:string?"
            select="string-join($primary-version-tree)"/>

        <!-- Messages -->
        <xsl:if
            test="exists($primary-version-tree) and not($primary-text eq $primary-version-tree-text)">
            <xsl:message
                select="'The diff input for the primary version differs from the tree that has been supplied: ', tan:diff($primary-text, $primary-version-tree-text)"
            />
        </xsl:if>


        <!-- Steps and output -->

        <xsl:variable name="html-output-pass-1" as="element()?">
            <!-- TODO: simplify, clarify the logic in processing this version, which has many
                twists and turns. -->
            <xsl:apply-templates select="$diff-or-collate-results" mode="diff-or-collate-to-html-output-pass-1">
                <xsl:with-param name="last-wit-idref" tunnel="yes" as="xs:string?"
                    select="$primary-version-ref-adjusted"/>
                <xsl:with-param name="primary-version-tree" as="element()*" tunnel="yes"
                    select="$primary-version-tree"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="html-output-pass-2" as="element()*" select="tan:prepare-to-convert-to-html($html-output-pass-1)"/>
        
        <xsl:variable name="html-output-pass-3" as="element()*" select="tan:convert-to-html($html-output-pass-2, true())"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, tan:diff-or-collate-to-html()'"/>
            <xsl:message select="'Diff or collate results: ', tan:trim-long-tree($diff-or-collate-results, 10, 20)"/>
            <xsl:message select="'Primary version ref: ' || $primary-version-ref"/>
            <xsl:message select="'Primary version ref adjusted (last wit ref): ' || $primary-version-ref-adjusted"/>
            <xsl:message select="'Primary version tree: ', tan:trim-long-tree($primary-version-tree, 10, 20)"/>
            <xsl:message select="'Primary version tree text: ' || tan:ellipses($primary-version-tree-text, 30, 30)"/>
            <xsl:message select="'Main diff node: ', tan:shallow-copy($main-diff-node)"/>
            <xsl:message select="'Main collation node: ', tan:shallow-copy($main-collation-node)"/>
            <xsl:message select="'Collation refs: ', $collation-refs"/>
            <xsl:message select="'Is diff?', $is-diff"/>
            <xsl:message select="'output pass 1: ', tan:trim-long-tree($html-output-pass-1, 10, 20)"/>
            <xsl:message select="'output pass 2: ', tan:trim-long-tree($html-output-pass-2, 10, 20)"/>
            <xsl:message select="'output pass 3: ', tan:trim-long-tree($html-output-pass-3, 10, 20)"/>
        </xsl:if>
        
        <xsl:sequence select="$html-output-pass-3"/>



    </xsl:function>



    <!-- Pass 1 goal: insert notices, set up stats as an html table, replace diff results with the 
        content of the primary file, do some preliminary filtering of the primary file. -->
    <xsl:mode name="diff-or-collate-to-html-output-pass-1" on-no-match="shallow-copy"/>




    <xsl:template match="tan:stats" mode="diff-or-collate-to-html-output-pass-1">
        <xsl:variable name="witness-ids" as="xs:string*" select="../tan:collation/tan:witness/@id"/>

        <table>
            <xsl:attribute name="class" select="'e-stats'"/>
            <thead>
                <tr>
                    <th/>
                    <th/>
                    <th/>
                    <th colspan="3">Differences</th>
                </tr>
                <tr>
                    <th/>
                    <th>URI</th>
                    <th>Length</th>
                    <th>Number</th>
                    <th>Length</th>
                    <th>Portion</th>
                </tr>
            </thead>
            <tbody>
                <xsl:apply-templates mode="#current"/>
            </tbody>
        </table>

        <xsl:if test="exists(../tan:collation/tan:witness/tan:commonality)">
            <div>
                <div class="label">Pairwise Similarity</div>
                <div class="explanation">The table below shows the percentage of similarity of each
                    pair of versions, starting with the version that shows the least divergence from
                    the entire group and proceeding to versions that are most divergent. This table
                    is useful for identifying clusters and pairs of versions that are closest to
                    each other.</div>
                <table>
                    <xsl:attribute name="class" select="'e-' || name(.)"/>
                    <thead>
                        <tr>
                            <th/>
                            <xsl:for-each select="$witness-ids">
                                <th>
                                    <xsl:value-of select="."/>
                                </th>
                            </xsl:for-each>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- The following witnesses will normally be in order from most common to
                        the group to least common -->
                        <xsl:apply-templates select="../tan:collation/tan:witness" mode="build-pairwise-similarity-table">
                            <xsl:with-param name="witness-ids" select="$witness-ids"/>
                        </xsl:apply-templates>
                    </tbody>
                </table>
            </div>
        </xsl:if>

    </xsl:template>
    
    <xsl:mode name="build-pairwise-similarity-table" on-no-match="shallow-copy"/>
    <xsl:template match="tan:witness" mode="build-pairwise-similarity-table">
        <!-- This template completes the <table> designed to show pairwise similarity, currently
        placed just after <stats> -->
        <xsl:param name="witness-ids"/>
        <xsl:variable name="commonality-children" select="tan:commonality"/>
        <tr>
            <td>
                <xsl:value-of select="@id"/>
            </td>
            <xsl:for-each select="$witness-ids">
                <xsl:variable name="this-id" select="."/>
                <xsl:variable name="this-commonality"
                    select="$commonality-children[@with = $this-id]"/>
                <td>
                    <xsl:if test="exists($this-commonality)">
                        <xsl:variable name="this-commonality-number"
                            select="number($this-commonality)"/>
                        <xsl:attribute name="style"
                            select="'background-color: rgba(0, 128, 0, ' || string($this-commonality-number * $this-commonality-number * 0.6) || ')'"/>
                        <xsl:value-of select="format-number($this-commonality-number * 100, '0.0')"
                        />
                    </xsl:if>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>

    <xsl:template match="tan:stats/tan:witness | tan:stats/tan:collation | tan:stats/tan:diff" 
        mode="diff-or-collate-to-html-output-pass-1">
        <xsl:param name="last-wit-idref" tunnel="yes" as="xs:string?"/>
        <xsl:param name="diff-a-ref" tunnel="yes" as="xs:string?" select="@ref"/>
        <xsl:param name="diff-b-ref" tunnel="yes" as="xs:string?" select="@ref"/>

        <xsl:variable name="this-ref" as="xs:string">
            <xsl:choose>
                <xsl:when test="@id = 'a' and string-length($diff-a-ref) gt 0">
                    <xsl:sequence select="$diff-a-ref"/>
                </xsl:when>
                <xsl:when test="@id = 'b' and string-length($diff-b-ref) gt 0">
                    <xsl:sequence select="$diff-b-ref"/>
                </xsl:when>
                <xsl:when test="exists(@ref)">
                    <xsl:sequence select="@ref"/>
                </xsl:when>
                <xsl:otherwise>aggregate</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="is-last-witness" as="xs:boolean" select="
                if (string-length($last-wit-idref) gt 0) then
                    (($this-ref, @id) = $last-wit-idref)
                else
                    (following-sibling::*[1]/(self::tan:collation | self::tan:diff))"/>
        <xsl:variable name="is-summary" as="xs:boolean" select="self::tan:collation or self::tan:diff"/>
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode diff-or-collate-to-html-output-pass-1 on element ', tan:shallow-copy(.)"/>
            <xsl:message select="'Last witness idref: ' || $last-wit-idref"/>
            <xsl:message select="'Diff a ref: ' || $diff-a-ref"/>
            <xsl:message select="'Diff b ref: ' || $diff-b-ref"/>
            <xsl:message select="'This ref: ' || $this-ref"/>
            <xsl:message select="'Is last witness? ', $is-last-witness"/>
            <xsl:message select="'Is summary? ', $is-summary"/>
        </xsl:if>
        
        <xsl:if test="$is-summary">
            <xsl:variable name="prec-wits" select="preceding-sibling::tan:witness"/>
            <tr class="averages">
                <td>
                    <div>averages</div>
                </td>
                <td/>
                <td class="e-length">
                    <xsl:value-of select="
                            format-number(avg(for $i in $prec-wits/tan:length
                            return
                                number($i)), '0.0')"/>
                </td>
                <td class="e-diff-count">
                    <xsl:value-of select="
                            format-number(avg(for $i in $prec-wits/tan:diff-count
                            return
                                number($i)), '0.0')"/>
                </td>
                <td class="e-diff-length">
                    <xsl:value-of select="
                            format-number(avg(for $i in $prec-wits/tan:diff-length
                            return
                                number($i)), '0.0')"/>
                </td>
                <td class="e-diff-portion">
                    <xsl:value-of select="
                            format-number(avg(for $i in $prec-wits/tan:diff-portion
                            return
                                number(replace($i, '%', '')) div 100), '0.0%')"
                    />
                </td>
            </tr>
        </xsl:if>
        <tr>
            <xsl:copy-of select="@class"/>
            <!-- The name of the witness, and the first column, for selection -->
            <td>
                <div>
                    <xsl:value-of select="$this-ref"/>
                </div>
                <!-- Do not perform the following if it is the last row of the table, a summary of
                the collation/diff. -->
                <xsl:if test="not(self::tan:collation) and not(self::tan:diff)">
                    <div>
                        <xsl:attribute name="class" select="
                                'last-picker' || (if ($is-last-witness) then
                                    ' a-last'
                                else
                                    ())"/>
                        <div>
                            <xsl:text>Tt</xsl:text>
                        </div>
                    </div>
                    <div>
                        <xsl:attribute name="class" select="
                                'other-picker' || (if ($is-last-witness) then
                                    ' a-other'
                                else
                                    ())"/>
                        <div>
                            <xsl:text>Tt</xsl:text>
                        </div>
                    </div>
                    <div class="switch">
                        <div class="on">☑</div>
                        <div class="off" style="display:none">☐</div>
                    </div>
                </xsl:if>
            </td>
            <xsl:apply-templates mode="#current"/>
        </tr>
    </xsl:template>

    <xsl:template match="tan:stats/tan:witness/* | tan:stats/tan:collation/* | tan:stats/tan:diff/*" mode="diff-or-collate-to-html-output-pass-1">
        <td>
            <xsl:attribute name="class" select="'e-' || name(.)"/>
            <xsl:apply-templates mode="#current"/>
        </td>
    </xsl:template>

    <xsl:template match="tan:note" mode="diff-or-collate-to-html-output-pass-1" priority="1">
        <div class="note explanation">
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>

    <xsl:template match="tan:venns" priority="1" mode="diff-or-collate-to-html-output-pass-1">
        <div class="venns">
            <div class="label">Three-way Venns and Analysis</div>
            <div class="explanation">Versions are presented below in sets of three, with a Venn
                diagram for visualization. Numbers refer to the quantity of characters that diverge
                from common, shared text (that is, shared by all three, regardless of any other
                version).</div>
            <div class="explanation">The diagrams are useful for thinking about how a document was
                revised. The narrative presumes that versions A, B, and C represent consecutive
                editing stages in a document, and an interest in the position of B relative to the
                path from A to C. The diagrams also depict wasted work. Whatever is in B that is in
                neither A nor C represents text that B added that C deleted. Whatever is in A and C
                but not in B represent text deleted by B that was restored by C.</div>
            <div class="explanation">Although ideal for describing an editorial path where A, B, and
                C stand in direct relation to each other, the scenarios can be profitably used to
                study three versions whose relationship is unknown.</div>
            <div class="explanation">Note, some data combinations are impossible to draw accurately
                with a 3-circle Venn diagram (e.g., a 3-circle Venn diagram for items in the set
                {[a, z], [b, z], [c, z]} will always incorrectly show overlap for each pair of
                items).</div>
            <div class="explanation">The colors are fixed according to the A, B, and C components of
                the Venn diagram, not to the version labels, which change color from one Venn
                diagram to the next.</div>
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>

    <xsl:template match="tan:venns/tan:venn" priority="1" mode="diff-or-collate-to-html-output-pass-1">
        <xsl:variable name="letter-sequence" select="('a', 'b', 'c')"/>
        <xsl:variable name="these-keys" select="tan:a | tan:b | tan:c"/>
        <xsl:variable name="this-id" select="'venn-' || string-join((tan:a, tan:b, tan:c), '-')"/>
        <xsl:variable name="common-part" select="tan:part[tan:a][tan:b][tan:c]"/>
        <xsl:variable name="other-parts" select="tan:part except $common-part"/>
        <xsl:variable name="single-parts" select="$other-parts[count((tan:a, tan:b, tan:c)) eq 1]"/>
        <xsl:variable name="double-parts" select="$other-parts[count((tan:a, tan:b, tan:c)) eq 2]"/>
        <xsl:variable name="common-length" select="number($common-part/tan:length)"/>
        <xsl:variable name="all-other-lengths" select="
                for $i in $other-parts/tan:length
                return
                    number($i)"/>
        <xsl:variable name="max-sliver-length" select="max($all-other-lengths)"/>
        <xsl:variable name="reduce-common-section-by" select="
                if ($common-length gt $max-sliver-length) then
                    ($common-length - $max-sliver-length)
                else
                    0"/>
        <xsl:variable name="these-labels" as="element()+">
            <div class="venn-a">
                <xsl:value-of select="tan:a"/>
            </div>
            <div class="venn-b">
                <xsl:value-of select="tan:b"/>
            </div>
            <div class="venn-c">
                <xsl:value-of select="tan:c"/>
            </div>
        </xsl:variable>
        <div class="venn">
            <div class="label">
                <xsl:copy-of select="$these-labels"/>
            </div>
            <xsl:for-each select="'b'">
                <xsl:variable name="this-letter" select="."/>
                <xsl:variable name="other-letters" select="$letter-sequence[not(. = $this-letter)]"/>
                <xsl:variable name="start-letter" select="$other-letters[1]"/>
                <xsl:variable name="end-letter" select="$other-letters[2]"/>
                <xsl:variable name="this-letter-label" select="$these-keys[name(.) = $this-letter]"/>
                <xsl:variable name="start-letter-label"
                    select="$these-keys[name(.) = $start-letter]"/>
                <xsl:variable name="end-letter-label" select="$these-keys[name(.) = $end-letter]"/>
                <xsl:variable name="this-div-label" select="$these-labels[. = $this-letter-label]"/>
                <xsl:variable name="start-div-label" select="$these-labels[. = $start-letter-label]"/>
                <xsl:variable name="end-div-label" select="$these-labels[. = $end-letter-label]"/>

                <xsl:variable name="this-nixed-insertions"
                    select="$single-parts[*[name(.) = $this-letter]]"/>
                <xsl:variable name="this-nixed-deletions"
                    select="$double-parts[not(*[name(.) = $this-letter])]"/>
                <xsl:variable name="start-unique" select="$single-parts[*[name(.) = $start-letter]]"/>
                <xsl:variable name="not-in-end"
                    select="$double-parts[not(*[name(.) = $end-letter])]"/>
                <xsl:variable name="not-in-start"
                    select="$double-parts[not(*[name(.) = $start-letter])]"/>
                <xsl:variable name="end-unique" select="$single-parts[*[name(.) = $end-letter]]"/>

                <xsl:variable name="journey-deletions"
                    select="number($start-unique/tan:length) + number($not-in-end/tan:length)"/>
                <xsl:variable name="journey-insertions"
                    select="number($not-in-start/tan:length) + number($end-unique/tan:length)"/>
                <xsl:variable name="journey-distance"
                    select="$journey-deletions + $journey-insertions"/>
                <xsl:variable name="this-traversal"
                    select="number($start-unique/tan:length) + number($not-in-start/tan:length)"/>
                <xsl:variable name="these-mistakes"
                    select="number($this-nixed-insertions/tan:length) + number($this-nixed-deletions/tan:length)"/>
                <xsl:variable name="these-likely-false-mistakes" as="xs:string*">
                    <xsl:analyze-string
                        select="string-join(($this-nixed-insertions/tan:texts/*/tan:txt, $this-nixed-deletions/tan:texts/*/tan:txt))"
                        regex="{string-join(((for $i in $tan:unimportant-change-character-aliases/tan:c return tan:escape($i)), $tan:unimportant-change-regex), '|')}"
                        flags="s">
                        <xsl:matching-substring>
                            <xsl:value-of select="."/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:variable name="this-likely-false-mistake-count" as="xs:integer"
                    select="string-length(string-join($these-likely-false-mistakes))"/>

                <xsl:variable name="diagnostics-on" select="false()"/>
                <xsl:if test="$diagnostics-on">
                    <xsl:message
                        select="'Diagnostics on, calculating relative distance of intermediate version between start and end.'"/>
                    <xsl:message select="'Start unique length ' || $start-unique/tan:length"/>
                    <xsl:message select="'Not in end length ' || $not-in-end/tan:length"/>
                    <xsl:message select="'Not in start length ' || $not-in-start/tan:length"/>
                    <xsl:message select="'End unique length ' || $end-unique/tan:length"/>
                    <xsl:message select="'End unique length ' || $end-unique/tan:length"/>
                </xsl:if>

                <div>
                    <xsl:text>The distance from </xsl:text>
                    <xsl:copy-of select="$start-div-label"/>
                    <xsl:text> to </xsl:text>
                    <xsl:copy-of select="$end-div-label"/>
                    <xsl:text> is </xsl:text>
                    <xsl:value-of
                        select="string($journey-distance) || ' (' || string($journey-deletions) || ' characters deleted and ' || string($journey-insertions) || ' inserted). Intermediate version '"/>
                    <xsl:copy-of select="$this-div-label"/>
                    <xsl:value-of
                        select="' contributed ' || string($this-traversal) || ' characters to the end result (' || format-number(($this-traversal div $journey-distance), '0.0%') || '). '"/>
                    <xsl:if test="$these-mistakes gt 0">
                        <xsl:value-of
                            select="'But it inserted ' || $this-nixed-insertions/tan:length || ' characters that were deleted by '"/>
                        <xsl:copy-of select="$end-div-label"/>
                        <xsl:value-of
                            select="', and deleted ' || $this-nixed-deletions/tan:length || ' characters that were restored by '"/>
                        <xsl:copy-of select="$end-div-label"/>
                        <xsl:text>. </xsl:text>
                        <xsl:if test="number($this-nixed-insertions/tan:length) gt 0">
                            <xsl:text>Nixed insertions: </xsl:text>
                            <xsl:for-each-group select="$this-nixed-insertions/tan:texts/*/tan:txt"
                                group-by=".">
                                <xsl:sort select="count(current-group())" order="descending"/>
                                <xsl:if test="position() gt 1">
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                                <div class="fragment">
                                    <xsl:value-of select="current-grouping-key()"/>
                                </div>
                                <xsl:value-of select="' (' || string(count(current-group())) || ')'"
                                />
                            </xsl:for-each-group>
                            <xsl:text>. </xsl:text>
                        </xsl:if>
                        <xsl:if test="number($this-nixed-deletions/tan:length) gt 0">
                            <xsl:text>Nixed deletions: </xsl:text>
                            <xsl:for-each-group select="$this-nixed-deletions/tan:texts/*/tan:txt"
                                group-by=".">
                                <xsl:sort select="count(current-group())" order="descending"/>
                                <xsl:if test="position() gt 1">
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                                <div class="fragment">
                                    <xsl:value-of select="current-grouping-key()"/>
                                </div>
                                <xsl:value-of select="' (' || string(count(current-group())) || ')'"
                                />
                            </xsl:for-each-group>
                            <xsl:text>. </xsl:text>
                        </xsl:if>
                    </xsl:if>
                    <div class="bottomline">
                        <xsl:value-of select="
                                'Aggregate progress was ' || string($this-traversal - $these-mistakes + $this-likely-false-mistake-count) ||
                                ' (' || format-number((($this-traversal - $these-mistakes + $this-likely-false-mistake-count) div $journey-distance), '0.0%')"/>
                        <xsl:if test="$this-likely-false-mistake-count gt 0">
                            <xsl:text>, after adjusting for </xsl:text>
                            <xsl:value-of select="$this-likely-false-mistake-count"/>
                            <xsl:text> nixed deletions and insertions that seem negligible</xsl:text>
                        </xsl:if>
                        <xsl:text>). </xsl:text>
                    </div>
                </div>
            </xsl:for-each>
            <div id="{$this-id}" class="diagram"><!--  --></div>
            <xsl:if test="$common-length gt $max-sliver-length">
                <div class="explanation">
                    <xsl:text>*To show more accurately the differences between the three versions, the proportionate size of the central common section has been reduced by </xsl:text>
                    <xsl:value-of select="string($reduce-common-section-by)"/>
                    <xsl:text>, to match the size of the largest sliver. All other non-common slivers are rendered proportionate to one another.</xsl:text>
                </div>
            </xsl:if>
            <xsl:apply-templates select="tan:note" mode="#current"/>
        </div>
        <script>
            <xsl:text>
var sets = [</xsl:text>
            <xsl:apply-templates select="tan:part" mode="#current">
                <xsl:with-param name="reduce-results-by" select="$reduce-common-section-by"/>
            </xsl:apply-templates>
            <xsl:text>
    ];

var chart = venn.VennDiagram()
    chart.wrap(false) 
    .width(320)
    .height(320);

var div = d3.select("#</xsl:text>
            <xsl:value-of select="$this-id"/>
            <xsl:text>").datum(sets).call(chart);
div.selectAll("text").style("fill", "white");
div.selectAll(".venn-circle path").style("fill-opacity", .6);

</xsl:text>
        </script>
    </xsl:template>

    <xsl:template match="tan:venn/tan:part" mode="diff-or-collate-to-html-output-pass-1">
        <xsl:param name="reduce-results-by" as="xs:numeric?"/>
        <xsl:variable name="this-parent" select=".."/>
        <xsl:variable name="these-letters" select="
                for $i in (tan:a, tan:b, tan:c)
                return
                    name($i)"/>
        <xsl:variable name="these-labels" select="../*[name(.) = $these-letters]"/>
        <!-- unfortunately, the javascript library we use doesn't look at intersections but unions,
        so lengths need to be recalculated -->
        <xsl:variable name="these-relevant-parts" select="
                ../tan:part[every $i in $these-letters
                    satisfies *[name(.) = $i]]"/>
        <xsl:variable name="these-relevant-lengths" select="$these-relevant-parts/tan:length"/>

        <xsl:variable name="total-length" select="
                sum(for $i in ($these-relevant-lengths)
                return
                    number($i)) - $reduce-results-by"/>
        <xsl:variable name="this-part-length" select="tan:length"/>

        <xsl:text>{sets:[</xsl:text>
        <xsl:value-of select="
                string-join((for $i in $these-labels
                return
                    ('&quot;' || $i || '&quot;')), ', ')"/>
        <xsl:text>], size: </xsl:text>
        <xsl:value-of select="$total-length"/>

        <xsl:value-of select="
                ', label: &quot;' || (if (count($these-letters) eq 3) then
                    '*'
                else
                    ()) || string($this-part-length) || '&quot;'"/>

        <xsl:text>}</xsl:text>
        <xsl:if test="exists(following-sibling::tan:part)">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&#xa;            </xsl:text>
    </xsl:template>




    <xsl:template match="tan:diff | tan:collation" mode="diff-or-collate-to-html-output-pass-1">
        <!-- group/stats/witness sorts them according to label order whereas group/collation/witness (if a collation) 
            puts the least divergent witness at the top. We presume the former is the one of interest, and that 
            because many labels include numbers that allow them to be sorted in chronological order, the last witness 
            is the most interesting. -->
        <xsl:param name="primary-version-tree" as="element()*" tunnel="yes"/>
        <xsl:param name="last-wit-idref" tunnel="yes" as="xs:string?"
            select="(tan:witness[last()]/@id, 'b')[1]"/>
        
        <!-- We presume that the primary tree has already been space-normalized or not, according to parameters/settings
            established before the input arrives in this template. -->
        <xsl:variable name="primary-tree-analyzed" as="element()*"
            select="tan:stamp-tree-with-text-data($primary-version-tree, false())"/>

        <xsl:variable name="split-collation-where"
            select="$primary-tree-analyzed/descendant-or-self::*[not(*) or exists(text()[matches(., '\S')])]" as="element()*"/>
        <xsl:variable name="split-count" select="count($split-collation-where)" as="xs:integer"/>

        <!-- The strings may have been normalized before being processed in the diff/collate function.
            This next variable allows us to inject the results of the tan/diff with the pre-altered
            form of the primary string. If it's a diff we can do the same with the parts that are
            exclusively <b>. -->
        
        <xsl:variable name="this-diff-or-collation-stamped" as="element()" select="
                if (self::tan:diff)
                then
                    tan:stamp-diff-with-text-data(.)
                else
                    ."/>

        <xsl:variable name="leaf-element-replacements" as="element()*">
            <xsl:choose>
                <!--<xsl:when test="not(exists($split-collation-where))">
                    <xsl:sequence select="$this-diff-or-collation-stamped"/>
                </xsl:when>-->
                <xsl:when test="self::tan:diff">
                    <xsl:iterate select="$split-collation-where">
                        <xsl:param name="diff-so-far" as="element()"
                            select="$this-diff-or-collation-stamped"/>
                        <xsl:variable name="this-string-last-pos"
                            select="xs:integer(@_pos) + xs:integer(@_len) - 1"/>
                        <xsl:variable name="first-diff-element-not-of-interest" select="
                                if ($last-wit-idref eq 'b') then
                                    $diff-so-far/(tan:b | tan:common)[xs:integer(@_pos-b) gt $this-string-last-pos][1]
                                else
                                    $diff-so-far/(tan:a | tan:common)[xs:integer(@_pos-a) gt $this-string-last-pos][1]"/>
                        <xsl:variable name="diff-elements-not-of-interest"
                            select="$first-diff-element-not-of-interest | $first-diff-element-not-of-interest/following-sibling::*"/>
                        <xsl:variable name="diff-elements-of-interest"
                            select="$diff-so-far/(* except $diff-elements-not-of-interest)"/>
                        <xsl:variable name="last-diff-element-of-interest-with-this-witness"
                            select="
                                if ($last-wit-idref eq 'b') then
                                    $diff-elements-of-interest[self::tan:b or self::tan:common][last()]
                                else
                                    $diff-elements-of-interest[self::tan:a or self::tan:common][last()]
                                "/>
                        <xsl:variable name="last-deoiwtw-pos" select="
                                if ($last-wit-idref eq 'b') then
                                    xs:integer($last-diff-element-of-interest-with-this-witness/@_pos-b)
                                else
                                    xs:integer($last-diff-element-of-interest-with-this-witness/@_pos-a)"
                        />
                        <xsl:variable name="last-deoiwtw-length"
                            select="xs:integer($last-diff-element-of-interest-with-this-witness/@_len)"/>
                        <xsl:variable name="amount-needed"
                            select="$this-string-last-pos - $last-deoiwtw-pos + 1"/>
                        <xsl:variable name="fragment-to-keep" as="element()*">
                            <xsl:if test="exists($last-diff-element-of-interest-with-this-witness)">
                                <xsl:element namespace="tag:textalign.net,2015:ns"
                                    name="{name($last-diff-element-of-interest-with-this-witness)}">
                                    <xsl:value-of
                                        select="substring($last-diff-element-of-interest-with-this-witness, 1, ($amount-needed, 0)[1])"
                                    />
                                </xsl:element>
                                <!-- If what follows is simply a <b> and the whole of the last diff element is desired, then that
                                <b> should be kept as well. We don't worry about cases where the next sibling is an <a> or <common>
                                because that is already accounted for by $first-diff-element-not-of-interest. -->
                                <xsl:if test="not($last-deoiwtw-length gt $amount-needed)">
                                    <xsl:copy-of select="
                                            if ($last-wit-idref eq 'b')
                                            then
                                                $last-diff-element-of-interest-with-this-witness/following-sibling::*[1]/self::tan:a
                                            else
                                                $last-diff-element-of-interest-with-this-witness/following-sibling::*[1]/self::tan:b
                                            "/>
                                </xsl:if>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="fragment-to-push-to-next-iteration" as="element()*">
                            <xsl:if
                                test="($last-deoiwtw-length gt $amount-needed) and exists($last-diff-element-of-interest-with-this-witness)">
                                <xsl:element namespace="tag:textalign.net,2015:ns"
                                    name="{name($last-diff-element-of-interest-with-this-witness)}">
                                    <xsl:attribute name="_len"
                                        select="$last-deoiwtw-length - $amount-needed"/>
                                    <xsl:attribute name="_pos-{$last-wit-idref}"
                                        select="$last-deoiwtw-pos + $amount-needed"/>

                                    <xsl:value-of
                                        select="substring($last-diff-element-of-interest-with-this-witness, ($amount-needed, 0)[1] + 1)"
                                    />
                                </xsl:element>
                                <!-- If only part of the last element of interest is kept, then if the next item is a <b>, it
                                should be pushed to the next iteration. -->
                                <xsl:copy-of select="
                                        if ($last-wit-idref eq 'b') then
                                            $last-diff-element-of-interest-with-this-witness/following-sibling::*[1]/self::tan:a
                                        else
                                            $last-diff-element-of-interest-with-this-witness/following-sibling::*[1]/self::tan:b"
                                />
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="next-diff" as="element()">
                            <diff xmlns="tag:textalign.net,2015:ns">
                                <xsl:copy-of select="$fragment-to-push-to-next-iteration"/>
                                <xsl:copy-of select="$diff-elements-not-of-interest"/>
                            </diff>
                        </xsl:variable>

                        <xsl:variable name="diagnostics-on" select="false()"/>
                        <xsl:if test="$diagnostics-on">
                            <xsl:message select="'Iterating over ', tan:shallow-copy(.)"/>
                            <xsl:message select="'This string, last pos:', $this-string-last-pos"/>
                            <xsl:message
                                select="'First diff element not of interest: ', $first-diff-element-not-of-interest"/>
                            <xsl:message
                                select="'Diff elements of interest: ', $diff-elements-of-interest"/>
                            <xsl:message
                                select="'Last diff element of interest with this witness: ', $last-diff-element-of-interest-with-this-witness"/>
                            <xsl:message
                                select="'Last diff element of interest with this witness pos: ', $last-deoiwtw-pos"/>
                            <xsl:message
                                select="'Last diff element of interest with this witness length: ', $last-deoiwtw-length"/>
                            <xsl:message select="'Amount needed:', $amount-needed"/>
                            <xsl:message select="'Fragment to keep: ', $fragment-to-keep"/>
                            <xsl:message
                                select="'Fragment to push to next iteration: ', $fragment-to-push-to-next-iteration"
                            />
                        </xsl:if>

                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="node() except (text() | tei:*)"/>
                            <xsl:if
                                test="not(exists($last-diff-element-of-interest-with-this-witness))">
                                <xsl:for-each select="$diff-elements-of-interest">
                                    <xsl:copy>
                                        <xsl:value-of select="."/>
                                    </xsl:copy>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:for-each select="
                                    $last-diff-element-of-interest-with-this-witness/preceding-sibling::*, $fragment-to-keep">
                                <xsl:copy>
                                    <xsl:value-of select="."/>
                                </xsl:copy>
                            </xsl:for-each>
                        </xsl:copy>

                        <xsl:choose>
                            <xsl:when test="not(exists($next-diff))">
                                <xsl:break/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:next-iteration>
                                    <xsl:with-param name="diff-so-far" select="$next-diff"/>
                                </xsl:next-iteration>
                            </xsl:otherwise>
                        </xsl:choose>


                    </xsl:iterate>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:iterate select="$split-collation-where">
                        <xsl:param name="collation-so-far" as="element()"
                            select="$this-diff-or-collation-stamped"/>
                        <xsl:variable name="this-string-last-pos"
                            select="xs:integer(@_pos) + xs:integer(@_len) - 1"/>
                        <!-- In collation output the attribute is @pos not @_pos -->
                        <xsl:variable name="first-collation-element-not-of-interest"
                            select="$collation-so-far/*[tan:wit[@ref = $last-wit-idref][xs:integer(@pos) gt $this-string-last-pos]][1]"/>
                        <xsl:variable name="collation-elements-not-of-interest"
                            select="$first-collation-element-not-of-interest | $first-collation-element-not-of-interest/following-sibling::*"/>
                        <xsl:variable name="collation-elements-of-interest"
                            select="$collation-so-far/(* except $collation-elements-not-of-interest)"/>
                        <xsl:variable name="last-collation-element-of-interest-with-this-witness"
                            select="$collation-elements-of-interest[tan:wit[@ref = $last-wit-idref]][last()]"/>
                        <xsl:variable name="last-ceoiwtw-pos"
                            select="xs:integer($last-collation-element-of-interest-with-this-witness/tan:wit[@ref = $last-wit-idref]/@pos)"/>
                        <xsl:variable name="last-ceoiwtw-length"
                            select="string-length($last-collation-element-of-interest-with-this-witness/tan:txt)"/>
                        <xsl:variable name="amount-needed"
                            select="$this-string-last-pos - $last-ceoiwtw-pos + 1"/>
                        <xsl:variable name="fragment-to-keep" as="element()*">
                            <xsl:if
                                test="exists($last-collation-element-of-interest-with-this-witness)">
                                <xsl:element namespace="tag:textalign.net,2015:ns"
                                    name="{name($last-collation-element-of-interest-with-this-witness)}">
                                    <txt xmlns="tag:textalign.net,2015:ns">
                                        <xsl:value-of
                                            select="substring($last-collation-element-of-interest-with-this-witness, 1, $amount-needed)"
                                        />
                                    </txt>
                                    <xsl:copy-of
                                        select="$last-collation-element-of-interest-with-this-witness/tan:wit"
                                    />
                                </xsl:element>
                                <xsl:if test="not($last-ceoiwtw-length gt $amount-needed)">
                                    <xsl:copy-of
                                        select="$last-collation-element-of-interest-with-this-witness/(following-sibling::* except $collation-elements-not-of-interest)"
                                    />
                                </xsl:if>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="fragment-to-push-to-next-iteration" as="element()*">
                            <xsl:if
                                test="$last-ceoiwtw-length gt $amount-needed and exists($last-collation-element-of-interest-with-this-witness)">
                                <xsl:element namespace="tag:textalign.net,2015:ns"
                                    name="{name($last-collation-element-of-interest-with-this-witness)}">
                                    <txt xmlns="tag:textalign.net,2015:ns">
                                        <xsl:value-of
                                            select="substring($last-collation-element-of-interest-with-this-witness, $amount-needed + 1)"
                                        />
                                    </txt>
                                    <xsl:for-each
                                        select="$last-collation-element-of-interest-with-this-witness/tan:wit">
                                        <xsl:copy>
                                            <xsl:copy-of select="@ref"/>
                                            <xsl:attribute name="pos"
                                                select="xs:integer(@pos) + $amount-needed"/>
                                        </xsl:copy>
                                    </xsl:for-each>
                                </xsl:element>
                                <xsl:copy-of
                                    select="$last-collation-element-of-interest-with-this-witness/(following-sibling::* except $collation-elements-not-of-interest)"
                                />
                            </xsl:if>
                        </xsl:variable>
                        <xsl:variable name="next-collation" as="element()">
                            <collation xmlns="tag:textalign.net,2015:ns">
                                <xsl:copy-of select="$fragment-to-push-to-next-iteration"/>
                                <xsl:copy-of select="$collation-elements-not-of-interest"/>
                            </collation>
                        </xsl:variable>

                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="node() except (text() | tei:*)"/>
                            <xsl:copy-of
                                select="$last-collation-element-of-interest-with-this-witness/preceding-sibling::*[not(self::tan:witness)]"/>
                            <xsl:copy-of select="$fragment-to-keep"/>
                        </xsl:copy>

                        <xsl:choose>
                            <xsl:when test="not(exists($next-collation))">
                                <xsl:break/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:next-iteration>
                                    <xsl:with-param name="collation-so-far" select="$next-collation"
                                    />
                                </xsl:next-iteration>
                            </xsl:otherwise>
                        </xsl:choose>


                    </xsl:iterate>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <xsl:variable name="primary-file-adjusted"
            select="tan:prepare-to-convert-to-html($primary-version-tree)" as="element()*"/>

        <xsl:variable name="witness-ids" as="xs:string*" select="tan:witness/@id"/>

        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message
                select="'Diagnostics on, template mode diff-or-collate-to-html-output-pass-1'"/>
            <xsl:message select="'Primary version tree: ', tan:trim-long-tree($primary-version-tree, 10, 20)"/>
            <xsl:message select="'Primary version tree analyzed: ', tan:trim-long-tree($primary-tree-analyzed, 10, 20)"/>
            <xsl:message select="'Last wit id ref: ' || $last-wit-idref"/>
            <xsl:message
                select="'Split diff or collation where? ' || string-join($split-collation-where/@_pos, ', ')"/>
            <xsl:message select="'Diff/collation stamped: ', tan:trim-long-tree($this-diff-or-collation-stamped, 10, 20)"/>
            <xsl:message select="'Leaf elements infused: ', tan:trim-long-tree($leaf-element-replacements, 10, 20)"/>
            <xsl:message select="'Primary file adjusted, prepared for infusion: ', tan:trim-long-tree($primary-file-adjusted, 10, 20)"/>
        </xsl:if>

        <h2>Comparison</h2>
        <xsl:copy>
            <xsl:if test="not(exists($primary-version-tree))">
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="adjust-diff-infusion"/>
            </xsl:if>
            <xsl:apply-templates select="$primary-file-adjusted"
                mode="infuse-primary-file-with-diff-results">
                <xsl:with-param name="element-replacements" tunnel="yes"
                    select="$leaf-element-replacements"/>
            </xsl:apply-templates>
        </xsl:copy>

    </xsl:template>
    
    <!-- The collation witnesses have been moved up into the statistics section and the pairwise 
        similarity table. -->
    <xsl:template match="tan:collation/tan:witness"
        mode="diff-or-collate-to-html-output-pass-1 adjust-diff-infusion"/>



    <xsl:mode name="infuse-primary-file-with-diff-results" on-no-match="shallow-copy"/>

    <xsl:template match="comment() | processing-instruction()"
        mode="infuse-primary-file-with-diff-results"/>

    <xsl:template match="*[@q or @id]" priority="1" mode="infuse-primary-file-with-diff-results">
        <xsl:param name="element-replacements" tunnel="yes" as="element()*"/>
        <xsl:variable name="context-q" as="xs:string" select="(@q, @id)[1]"/>
        <xsl:variable name="this-substitute" select="$element-replacements[@q eq $context-q]"/>
        <xsl:choose>
            <xsl:when test="exists($this-substitute)">
                <xsl:apply-templates select="$this-substitute" mode="adjust-diff-infusion"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tan:unparsed-text | w:document" mode="infuse-primary-file-with-diff-results">
        <!-- TODO: support the bare bones of a Word docx structure -->
        <xsl:param name="element-replacements" tunnel="yes" as="element()*"/>
        <xsl:apply-templates select="$element-replacements" mode="adjust-diff-infusion"/>
    </xsl:template>

    <!-- get rid of attributes we will not use for the rest of the process, and do not want
    displayed in the HTML -->
    <xsl:template match="
            @q | tei:*/@part | tei:*/@org | tei:*/@sample |
            /tei:TEI/@* | tan:TAN-T/@*" mode="infuse-primary-file-with-diff-results"/>


    <xsl:mode name="adjust-diff-infusion" on-no-match="shallow-copy"/>

    <xsl:template match="tan:_text" mode="adjust-diff-infusion">
        <!-- drop the elements temporarily wrapping text -->
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <!-- February 2022: adding second template mode, infuse-primary-file-with-diff-results, 
        to deal with material not substituted -->
    
    <xsl:template match="tan:c | tan:u" mode="adjust-diff-infusion infuse-primary-file-with-diff-results">
        <xsl:param name="last-wit-idref" as="xs:string?" tunnel="yes"/>
        <xsl:variable name="wit-refs" as="xs:string*" select="tan:wit/@ref"/>
        <xsl:variable name="class-values" as="xs:string*" select="
                (for $i in $wit-refs
                return
                    'a-w-' || $i),
                (if ($last-wit-idref = $wit-refs) then
                    ('a-last', 'a-other')
                else
                    ())"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="string-join($class-values, ' ')"/>
            <!-- This is to populate a tooltip hover device to show which versions attest to the reading -->
            <div class="wits">
                <xsl:for-each select="$wit-refs">
                    <div class="siglum a-w-{.}">
                        <xsl:value-of select=". || ' '"/>
                    </div>
                </xsl:for-each>
                <!--<xsl:sequence select="string-join($wit-refs, ' ')"/>-->
            </div>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:b" mode="adjust-diff-infusion infuse-primary-file-with-diff-results">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="class" select="'a-last a-other'"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <!-- We don't need the witnesses in the HTML file because a tooltip lets the reader know which 
    witnesses attest to a given reading. But this could be adapted in the future, esp. to make use of
    @pos -->
    <xsl:template match="tan:wit" mode="adjust-diff-infusion infuse-primary-file-with-diff-results"/>

    <xsl:template match="tan:a/text() | tan:b/text() | tan:common/text() | tan:u/tan:txt/text()" mode="adjust-diff-infusion infuse-primary-file-with-diff-results">
        <!-- We're getting this ready for HTML, and spaces should be preserved -->
        <xsl:analyze-string select="." regex="  +">
            <xsl:matching-substring>
                <xsl:variable name="len" as="xs:integer" select="string-length(.)"/>
                <xsl:value-of select="' ' || tan:fill('&#xa0;', $len - 1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>



</xsl:stylesheet>
