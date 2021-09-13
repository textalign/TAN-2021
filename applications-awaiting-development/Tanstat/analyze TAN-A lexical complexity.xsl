<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">

    <!-- Initial input: any TAN-A file -->
    <!-- Calculated input: the sources, grouped by work, tokenized, swapped with LM data, and merged -->
    <!-- Template: depends on whether requested output is html or docx -->
    <!-- Output: statistics analyzing lexical complexity; if a work group has more than one source, post-initial sources will be compared with the first source -->

    <xsl:import href="../get%20inclusions/statistic-core.xsl"/>
    
    <!-- ad hoc, temporary stricture -->
    <xsl:import href="../../../../../Google%20Drive/CLIO%20commons/TAN%20library/CLIO/clio%20output%20strictures%201.xsl"/>

    <xsl:param name="extra-tan-catalog-url-relative-to-catalyzing-input" select="'../TAN-A-lm/catalog.tan.xml'"/>
    <xsl:param name="extra-tan-collection" select="tan:collection($extra-tan-catalog, 'TAN-A-lm', (), ())"/>
    
    <xsl:param name="basis-of-datum" select="'distinct tokens per token count'"/>
    <xsl:param name="column-label-1">lex. cmpl. </xsl:param>

    <xsl:param name="html-preamble" as="element()*">
        <h1 xmlns="http://www.w3.org/1999/xhtml">Analysis of lexical complexity</h1>
        <div xmlns="http://www.w3.org/1999/xhtml">The tables below show the relative lexical
            complexity of each div in multiple versions of the same work. Lexical complexity is defined
            in this report as the number of distinct lexemes divided by the total number of words, multiplied
            by 100 for convenience.
        </div>
        <div xmlns="http://www.w3.org/1999/xhtml">Example: "I took him, he takes me." This sentence
            has three lexemes and six words, for a lexical complexity of 50 (= 3 / 6 * 100).</div>
        <div xmlns="http://www.w3.org/1999/xhtml">The lexical complexity scores in
            the leftmost source are the benchmark against which all other sources are compared. The
            data may be used to explore anomalies in alignment, to compare versions of the same
            work, or to analyze explicitation and implicitation across different translations of the
            same work. </div>
        <div xmlns="http://www.w3.org/1999/xhtml">Note, it is never advisable to draw conclusions
            from data without understanding thoroughly its basis. You are advised to consult the
            sources, which may have errors or anomalies. This report has been generated on the basis
            of TAN XML sources, via a TAN-A file supplied as input to an XSLT algorithm written by
            Joel Kalvesmaki.</div>
        <div xmlns="http://www.w3.org/1999/xhtml">For more on the TAN XML format, see <a
            href="http://textalign.net">textalign.net</a></div>
        <div xmlns="http://www.w3.org/1999/xhtml" class="warning">This algorithm excludes from
            consideration any tokens that either lack lexical data, or have multiple lexemes</div>
    </xsl:param>
    
    <!-- Input pass 1b: Replace <tok>s with <ana> <lm>s, strip <non-tok>s; drop <div> structure -->
    <!-- This analysis will be put back into the input via @q -->
    <xsl:variable name="input-pass-1b" as="document-node()*">
        <xsl:apply-templates select="$input-pass-1" mode="replace-tok-with-lm"/>
    </xsl:variable>
    <xsl:template match="tan:body" mode="replace-tok-with-lm">
        <xsl:variable name="this-id" select="../@id"/>
        <xsl:variable name="these-annotations" select="tan:get-1st-doc(../tan:head/tan:annotation)"/>
        <xsl:variable name="declared-tan-a-lms" select="$these-annotations[tan:TAN-A-lm]"/>
        <xsl:variable name="extra-tan-a-lms" select="$extra-tan-collection[tan:TAN-A-lm/tan:head/tan:source/tan:IRI = $this-id]"/>
        <xsl:variable name="these-tan-a-lms-resolved" select="tan:resolve-doc(($declared-tan-a-lms, $extra-tan-a-lms))"/>
        <xsl:variable name="these-tan-a-lms-adjusted" as="document-node()*">
            <xsl:apply-templates select="$these-tan-a-lms-resolved" mode="adjust-tan-a-lm"/>
        </xsl:variable>
        <xsl:variable name="diagnostics-on" select="true()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for template mode: replace-tok-with-lm'"/>
            <xsl:message select="'associated TAN-A-lms: ', tan:shallow-copy($these-tan-a-lms-resolved/*)"/>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="tan-a-lms" select="$these-tan-a-lms-adjusted" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:div[tan:tok]" mode="replace-tok-with-lm">
        <xsl:param name="tan-a-lms" tunnel="yes" as="document-node()*"/>
        <xsl:variable name="these-refs" select="tan:ref/text()"/>
        <xsl:variable name="these-ana-toks"
            select="
                $tan-a-lms/tan:TAN-A-lm/tan:body//tan:ana/tan:tok[not(exists(tan:ref))
                or tan:ref = $these-refs]"
        />
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for template mode: replace-tok-with-lm'"/>
            <xsl:message select="'fetching anas for refs: ', $these-refs"/>
            <xsl:message select="'these ana toks: ', $these-ana-toks"/>
        </xsl:if>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="ana-toks" select="$these-ana-toks"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:non-tok" mode="replace-tok-with-lm"/>
    <xsl:template match="tan:tok" mode="replace-tok-with-lm">
        <xsl:param name="ana-toks"/>
        <xsl:variable name="this-tok" select="text()"/>
        <xsl:variable name="this-pos" select="@pos"/>
        <xsl:variable name="these-ana-toks"
            select="
                $ana-toks[(@val = $this-tok) or (if (exists(@rgx)) then
                    matches($this-tok, concat('^', @rgx, '$'))
                else
                    false())][$this-pos = tan:pos]"
        />
        <xsl:variable name="these-ls" select="$these-ana-toks/following-sibling::tan:lm/tan:l"/>
        <xsl:variable name="distinct-ls" select="tan:distinct-items($these-ls)"/>
        <xsl:variable name="no-ana-toks-found" select="not(exists($these-ana-toks))"/>
        <xsl:variable name="skip-this-tok" select="$no-ana-toks-found or (count($distinct-ls) gt 1)"/>
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for template mode: replace-tok-with-lm'"/>
            <xsl:message select="'this tok: ', tan:shallow-copy($this-tok)"/>
            <xsl:message select="'these ana toks: ', $these-ana-toks"/>
            <xsl:message select="'these l elements: ', $these-ls"/>
            <xsl:message select="'skip this tok?: ', $skip-this-tok"/>
        </xsl:if>
        <xsl:if test="$no-ana-toks-found">
            <xsl:message select="$this-tok, ': no LM data found in provided source-specific TAN-A-lm files; search supplement not yet supported for this algorithm'"/>
        </xsl:if>
        <xsl:if test="not($skip-this-tok)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <!--<xsl:value-of select="."/>-->
                <xsl:value-of select="$these-ls[1]"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <!-- For this particular routine, we ignore the codes; we're interested only in lexemes -->
    <xsl:template match="tan:m" mode="adjust-tan-a-lm"/>
    <!-- Expand @ref to fetch it easier; normalize @rgx/@val and @pos -->
    <xsl:template match="tan:tok" mode="adjust-tan-a-lm">
        <xsl:variable name="this-ref" select="@ref"/>
        <xsl:variable name="this-ref-expanded" select="tan:analyze-sequence($this-ref, 'ref', true())"/>
        <xsl:copy>
            <xsl:copy-of select="@* except @pos"/>
            <xsl:if test="not(exists(@val)) and not(exists(@rgx))">
                <xsl:attribute name="rgx" select="'.+'"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="exists(@pos)">
                    <xsl:variable name="this-pos-expanded" select="tan:analyze-sequence(@pos, 'pos', true())"/>
                    <xsl:copy-of select="$this-pos-expanded/*"/>
                </xsl:when>
                <xsl:otherwise>
                    <pos>1</pos>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="$this-ref-expanded/tan:ref">
                <xsl:copy>
                    <xsl:value-of select="text()"/>
                </xsl:copy>
            </xsl:for-each>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Tether input pass 2 to the $input-pass-1b -->
    <xsl:param name="input-pass-2" as="item()*"
        select="tan:build-intermediate-step($input-pass-1b, $uris-input-pass-2, 'input pass 2')"/>
    
    <!--<xsl:template match="/">
        <!-\- diagnostics -\->
        <diagnostics>
            <!-\-<u><xsl:copy-of select="$extra-tan-catalog-url-resolved"/></u>-\->
            <!-\-<etc><xsl:copy-of select="$extra-tan-catalog"/></etc>-\->
            <!-\-<etc><xsl:copy-of select="$extra-tan-collection"/></etc>-\->
            <!-\-<i1><xsl:copy-of select="$input-pass-1"/></i1>-\->
            <!-\-<i1b><xsl:copy-of select="$input-pass-1b"/></i1b>-\->
            <!-\-<xsl:copy-of select="$input-pass-2"/>-\->
            <!-\-<i3><xsl:copy-of select="$input-pass-3"/></i3>-\->
            <i3b><xsl:copy-of select="$input-pass-3b"/></i3b>
            <i4><xsl:copy-of select="$input-pass-4"/></i4>
        </diagnostics>
    </xsl:template>-->
</xsl:stylesheet>
