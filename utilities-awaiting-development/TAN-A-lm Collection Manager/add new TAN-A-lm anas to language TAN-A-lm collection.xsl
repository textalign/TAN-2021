<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">

    <!-- Initial input: a text-specific TAN-A-lm file -->
    <!-- Effective input: a TAN-A-lm collection for a language -->
    <!-- Template: the effective input -->
    <!-- Output: each relevant language TAN-A-lm file updated, saved to a parallel directory with today's date -->

    <!-- This stylesheet finds in a text-specific TAN-A-lm file any <ana>s that are new or have new data for a language-specific TAN-A-lm collection. -->
    <!-- Caveats: the text-specific TAN-A-lm file must use @val (sorry, in the interests of efficiency, we're not tracking down @pos-only refs) -->
    <!-- See tan:copy-data() for other assumptions -->


    <xsl:import href="../get%20inclusions/convert.xsl"/>
    <xsl:import href="../get%20inclusions/copy-TAN-data.xsl"/>
    <xsl:output indent="yes" use-character-maps="tan"/>

    <xsl:param name="validation-phase" select="'terse'"/>

    <!-- THIS STYLESHEET -->
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:add-tan-a-lm-to-language-tan-a-lm-collection'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="change-message" select="'added data from', $doc-uri, concat('(', $doc-id, ')')"/>


    <!-- CATALYZING INPUT -->

    <xsl:variable name="source-tan-a-lm" select="/"/>
    <!--<xsl:variable name="anas-to-add" select="/tan:TAN-A-lm/tan:body//tan:ana"/>-->
    <xsl:variable name="anas-to-add" as="element()*">
        <xsl:apply-templates select="/tan:TAN-A-lm/tan:body//tan:ana" mode="assign-resp">
            <xsl:with-param name="default-resp" select="$primary-agents" tunnel="yes"/>
            <xsl:with-param name="first-edit-date" select="$doc-history/*[last()]" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:variable>


    <!-- EFFECTIVE INPUT -->

    <xsl:param name="input-items" select="$lang-catalogs"/>

    <!-- Pass 1: process language files -->

    <!-- Default pass 1 behavior: shallow skip, to turn the catalog into a collection of documents -->
    <xsl:template match="document-node() | node() | processing-instruction()" mode="input-pass-1">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:function name="tan:lm-codes">
        <!-- Input: an ancestor with <lm>s -->
        <!-- Output: all lm code permutations -->
        <!-- The values of <l> and <m> are delimited by '#' -->
        <xsl:param name="lm-ancestor" as="element()*"/>
        <xsl:for-each select="$lm-ancestor//tan:lm">
            <xsl:variable name="this-lm" select="."/>
            <xsl:for-each select="tan:l">
                <xsl:variable name="this-l" select="."/>
                <xsl:for-each select="$this-lm/tan:m">
                    <xsl:value-of select="concat($this-l, '#', .)"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="doc[position() lt 100][@root = 'TAN-A-lm']" mode="input-pass-1">
        <xsl:variable name="this-id" select="@id"/>
        <xsl:variable name="starts-should-be-ises" as="xs:boolean"
            select="exists($input-items/collection/doc[matches(@id, concat($this-id, '.+'))])"/>
        <xsl:variable name="these-starts" select="(tan:tok-starts-with, tan:tok-is)"/>
        <xsl:variable name="new-ana-candidates"
            select="
                $anas-to-add[
                if ($starts-should-be-ises) then
                    (@val = $these-starts)
                else
                    (some $i in $these-starts
                        satisfies tan:tok[starts-with(@val, $i)])]"/>
        <xsl:variable name="target-tan-a-lm" select="doc(resolve-uri(@href, tan:base-uri(.)))"/>
        <xsl:variable name="new-anas" as="element()*">
            <xsl:for-each-group select="$new-ana-candidates" group-by="tan:tok/@val">
                <xsl:variable name="this-val" select="current-grouping-key()"/>
                <xsl:variable name="these-ana-candidates" select="current-group()"/>
                <xsl:variable name="ana-matches-based-on-val-or-rgx"
                    select="$target-tan-a-lm/tan:TAN-A-lm/tan:body//tan:ana[tan:tok[(@val = $this-val) or tan:matches($this-val, @rgx)]]"
                />
                <xsl:variable name="target-lms" select="tan:lm-codes($ana-matches-based-on-val-or-rgx)"/>
                <xsl:variable name="candidate-lms" select="tan:lm-codes($these-ana-candidates)"/>
                <xsl:variable name="unique-lms" select="$candidate-lms[not(. = $target-lms)]"/>
                <xsl:variable name="unique-lm-count" select="count($unique-lms)"/>
                <xsl:variable name="candidate-tok-count"
                    select="count($these-ana-candidates/tan:tok[@val = $this-val])"/>
                <xsl:if test="exists($unique-lms)">
                    <ana>
                        <xsl:copy-of select="current-group()/@*"/>
                        <xsl:if test="exists(current-group()/tan:tok/@ref)">
                            <xsl:comment select="current-group()/tan:tok/@ref"/>
                        </xsl:if>
                        <tok val="{$this-val}"/>
                        <xsl:for-each-group select="$unique-lms" group-by="tokenize(., '#')[1]">
                            <xsl:variable name="this-lm-count" select="count(current-group())"/>
                            <xsl:variable name="this-l" select="current-grouping-key()"/>
                            <xsl:variable name="these-anas-matching-this-l"
                                select="$these-ana-candidates[tan:lm[tan:l = $this-l]]"/>
                            <xsl:variable name="these-anas-matching-this-l-tok-count"
                                select="count($these-anas-matching-this-l/tan:tok[@val = $this-val])"/>
                            <lm>
                                <!-- If there are multiple <lm>s then assign certainty based on the number of <tok>s populate each lm combo -->
                                <xsl:if test="$this-lm-count lt $unique-lm-count">
                                    <xsl:attribute name="cert"
                                        select="$these-anas-matching-this-l-tok-count div $candidate-tok-count"
                                    />
                                </xsl:if>
                                <l>
                                    <xsl:value-of select="current-grouping-key()"/>
                                </l>
                                <xsl:for-each select="current-group()">
                                    <xsl:variable name="this-m" select="tokenize(., '#')[2]"/>
                                    <xsl:variable name="these-anas"
                                        select="$these-anas-matching-this-l[tan:lm[tan:l = $this-l][tan:m = $this-m]]"/>
                                    <xsl:variable name="this-tok-count"
                                        select="count($these-anas/tan:tok[@val = $this-val])"/>
                                    <m>
                                        <xsl:if test="$this-lm-count gt 1">
                                            <xsl:attribute name="cert"
                                                select="$this-tok-count div $these-anas-matching-this-l-tok-count"
                                            />
                                        </xsl:if>
                                        <xsl:value-of select="$this-m"/>
                                    </m>
                                </xsl:for-each>
                            </lm>
                        </xsl:for-each-group>
                    </ana>
                </xsl:if>
                <!--<xsl:choose>
                    <!-\- Is the @val already in the language TAN-A-lm? -\->
                    <!-\- exists($ana-matches-based-on-val) -\->
                    <xsl:when test="true()">
                    </xsl:when>
                    <xsl:otherwise>
                        <ana>
                            <xsl:copy-of select="current-group()/@*"/>
                            <tok val="{$this-val}"/>
                            <xsl:comment select="current-group()/tan:tok/@ref"/>
                            <xsl:copy-of select="current-group()/tan:lm"/>
                        </ana>
                    </xsl:otherwise>
                </xsl:choose>-->
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:if test="exists($new-anas)">
            <test13>
                <xsl:copy-of select="$new-anas"/>
                <!--<xsl:copy-of select="tan:copy-data($source-tan-a-lm, $target-tan-a-lm, $new-anas)"/>-->
            </test13>
            <!--<xsl:apply-templates select="$this-tan-a-lm" mode="revise-content">
                <xsl:with-param name="new-anas" select="$new-anas" tunnel="yes"/>
                <xsl:with-param name="starts-should-be-ises" select="$starts-should-be-ises"
                    tunnel="yes"/>
            </xsl:apply-templates>-->
        </xsl:if>
    </xsl:template>

    <xsl:template match="tan:TAN-A-lm" mode="revise-content">
        <xsl:param name="new-anas" tunnel="yes"/>
        <!-- questions of responsibility are rather complicated to process. The incoming <ana>s may be the responsibility of different agents, 
            and those agents might already be logged in the incoming TAN-A-lm file, and even then they may have different or conflicting
            @xml:id values.
        -->
        <xsl:variable name="these-agents"
            select="tan:head/tan:vocabulary-key/(tan:person, tan:organization, tan:algorithm)"/>
        <!--<xsl:variable name="this-doc-resolved"
            select="tan:resolve-doc(root(.), false(), (), (), ('person', 'organization', 'algorithm'), ())"/>-->
        <!--<xsl:variable name="this-doc-resolved"
            select="tan:resolve-doc(root(.), false())"/>-->
        <xsl:variable name="this-doc-resolved"
            select="tan:resolve-doc(root(.), false(), ())"/>
        <xsl:variable name="current-agents-that-match-resp" as="element()*">
            <xsl:choose>
                <xsl:when test="exists($these-agents[not(exists(tan:IRI))])">
                    <xsl:copy-of
                        select="$this-doc-resolved/tan:TAN-A-lm/tan:head/tan:vocabulary-key/(tan:person, tan:organization, tan:algorithm)[tan:IRI = $primary-agents/tan:IRI]"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$these-agents[tan:IRI = $primary-agents/tan:IRI]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="default-resp"
            select="($current-agents-that-match-resp, $primary-agents)[1]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="default-resp" select="$default-resp" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:body" mode="revise-content">
        <xsl:param name="new-anas" tunnel="yes"/>
        <xsl:param name="default-resp" tunnel="yes"/>
        <xsl:apply-templates mode="#current"/>
        <xsl:apply-templates select="$new-anas" mode="add-anas">
            <xsl:with-param name="current-anas" select=".//tan:ana"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tan:tok-starts-with" mode="revise-content">
        <xsl:param name="starts-should-be-ises" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$starts-should-be-ises">
                <xsl:message select="tan:cfn(.), 'tok-starts-with changed to tok-is'"/>
                <tok-is>
                    <xsl:value-of select="."/>
                </tok-is>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tan:ana" mode="add-anas">
        <xsl:param name="current-anas" as="element()*"/>
        <xsl:variable name="these-toks" select="tan:tok"/>
        <xsl:variable name="these-lm-codes" select="tan:lm-codes(.)"/>
        <xsl:variable name="anas-with-tok-matches"
            select="
                $current-anas[tan:tok[($these-toks/@val = @val) or
                (some $i in $these-toks
                    satisfies tan:matches($i/@val, @rgx))]]"
        />
        <xsl:variable name="matching-ana-lm-codes" select="tan:lm-codes($anas-with-tok-matches)"/>
        <xsl:variable name="new-lm-codes" select="$these-lm-codes[not(. = $matching-ana-lm-codes)]"/>
        <xsl:if test="exists($new-lm-codes)">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:attribute name="ed-when" select="$today-iso"/>
                <!--<xsl:attribute name="ed-who" select="$blame-whom"/>-->
                <xsl:choose>
                    <xsl:when test="exists($anas-with-tok-matches)">
                        <xsl:comment select="'Addendum to', tan:xml-to-string($anas-with-tok-matches/tan:tok)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:comment>New data</xsl:comment>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:copy-of select="tan:tok"/>
                <xsl:for-each-group select="$new-lm-codes" group-by="tokenize(., '#')[1]">
                    <lm>
                        <l>
                            <xsl:value-of select="current-grouping-key()"/>
                        </l>
                        <xsl:for-each select="current-group()">
                            <m>
                                <xsl:value-of select="tokenize(., '#')[2]"/>
                            </m>
                        </xsl:for-each>
                    </lm>
                </xsl:for-each-group>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:variable name="results" as="document-node()">
        <xsl:apply-templates select="/" mode="add-anas"/>
    </xsl:variable>
    <xsl:variable name="anas-added"
        select="$results/tan:TAN-A-lm/tan:body/tan:ana[@ed-when = $today-iso]"/>

    <xsl:template match="/" priority="5">
        <xsl:if test="not(exists(/tan:TAN-A-lm/tan:head/tan:source))">
            <xsl:message terminate="yes" select="'Input must be a text-specific TAN-A-lm file'"/>
        </xsl:if>
        <!--<xsl:choose>
            <xsl:when
                test="exists($anas-added) or exists($other-filenames-that-are-start-with-supersets)">
                <xsl:message select="count($anas-added), 'entries added to', $doc-uri"/>
                <xsl:apply-templates select="$results" mode="credit-stylesheet"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="'No additions to', $doc-uri"/>
                <xsl:sequence select="."/>
            </xsl:otherwise>
        </xsl:choose>-->
        <!-- diagnostics -->
        <diagnostics>
            <!--<xsl:copy-of select="$self-resolved"/>-->
            <!--<xsl:copy-of select="$local-catalog"/>-->
            <xsl:copy-of select="$input-pass-1"/>
            <!--<xsl:copy-of select="$self-expanded"/>-->
            <!--<xsl:copy-of select="$new-data-uri-resolved"/>-->
            <!--<xsl:copy-of select="$new-data"/>-->
            <!--<xsl:copy-of select="$tok-starts-withs"/>-->
            <!--<xsl:copy-of select="$anas-of-interest"/>-->
            <!--<xsl:copy-of select="$current-anas"/>-->
            <!--<xsl:copy-of select="$new-anas"/>-->
            <!--<xsl:copy-of select="$familiar-anas"/>-->
        </diagnostics>
    </xsl:template>
</xsl:stylesheet>
