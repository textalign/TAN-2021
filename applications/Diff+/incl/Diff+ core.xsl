<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    expand-text="yes"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for comparing texts. -->
    
    <xsl:include href="../../../functions/TAN-function-library.xsl"/>
    
    <xsl:variable name="output-directory-uri-resolved" as="xs:anyURI"
        select="resolve-uri(replace($output-directory-uri, '([^/])$', '$1/'), $calling-stylesheet-uri)"/>
    

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-name" select="'Diff+'"/>
    <xsl:param name="tan:stylesheet-activity" select="'finds and analyzes text differences'"/>
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:compare-texts'"/>
    <xsl:param name="tan:stylesheet-description" as="xs:string">Take any number of versions of a
        text, compare them, and view and study all the text differences in an HTML page. The HTML
        output allows you to see precisely where one version differs from the other. A small
        Javascript library allows you to change focus, remove versions, and explore statistics that
        show quantitatively how close the versions are to each other. Parameters allow you to make
        normalizations before making the comparison, and to weigh statistics accordingly. This
        application has been used not only for individual comparisons, but for more demanding needs:
        to analyze changes in documents passing through a multistep editorial workflow, to compare
        the quality of OCR results, and to study the relationship between ancient/medieval
        manuscripts (stemmatology).</xsl:param>
    
    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">any XML file, including this
        one (input is ignored)</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">one or more files</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">perhaps diagnostics</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">for each detectable
        language in the secondary input: (1) an XML file with the results of tan:diff() or
        tan:collate(), infused with select statistical analyses; (2) a rendering of #1 in an interactive,
        visually engaging HTML form</xsl:param>
    
    <xsl:param name="tan:stylesheet-output-examples" as="element()*">
        <example>
            <location>https://textalign.net/output/CFR-2017-title1-vol1-compared.xml</location>
            <description>XML master output file, comparing four years of the United States Code of Federal Regulations,
                vol. 1</description>
        </example>
        <example>
            <location>https://textalign.net/output/CFR-2017-title1-vol1-compared.html</location>
            <description>HTML comparison of four years of the United States Code of Federal Regulations,
                vol. 1</description>
        </example>
        <example>
            <location>https://textalign.net/output/diff-grc-2021-02-08-five-versions.html</location>
            <description>Comparison of results from four OCR processes against a benchmark,
                classical Greek</description>
        </example>
        <example>
            <location>https://textalign.net/clio/darwin-3diff.html</location>
            <description>Comparison of three editions of Darwin's works, sample</description>
        </example>
        <example>
            <location>https://textalign.net/clio/hom-01-coll-ignore-uv.html</location>
            <description>Comparison of five versions of Griffolini's translation of John Chrysostom's Homily 1 on 
            the Gospel of John</description>
        </example>
    </xsl:param>
    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-change-message" select="'Compared class 1 files.'"/>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-13">Debugged, esp. for
            space-normalization problems.</change>
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-07">Edited,
            prepared for TAN 2021 release.</change>
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2022-02-14">Added new functionality: serialization
        of input XML, to compare XML structures more closely; supported output suffixes; ellision of lengthy text in HTML output;
        finer control of location of target CSS and JavaScript libraries; more grouping options, based on adjusted filenames
        and languages.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2020-10-06">Revise process that reinfuses a class 1 file with a diff/collate into a standard extra TAN function.</comment>
        </to-do>
    </xsl:param>
    

    <!-- The application -->
    
    
    <!-- Adjusting input parameters -->

    <xsl:variable name="main-input-resolved-uri-directories" as="xs:string*" select="
            for $i in $tan:main-input-relative-uri-directories
            return
                string(resolve-uri($i, $calling-stylesheet-uri))"/>
    
    <xsl:variable name="main-input-resolved-uris" as="xs:string*">
        <xsl:for-each select="$main-input-resolved-uri-directories">
            <xsl:try select="uri-collection(.)">
                <xsl:catch>
                    <xsl:message select="'Unable to get a uri collection from ' || ."/>
                </xsl:catch>
            </xsl:try>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="mirus-chosen" as="xs:string*"
        select="$main-input-resolved-uris[tan:filename-satisfies-regexes(., $tan:input-filenames-must-match-regex, $tan:input-filenames-must-not-match-regex)]"
    />
    
    <xsl:variable name="check-top-level-div-ns" as="xs:boolean" select="string-length($exclude-top-level-divs-with-attr-n-matching-what) gt 0"/>
    
    <xsl:variable name="elision-trigger-point-norm" as="xs:integer" select="max(($elision-minimum-point, 5))"/>
    
    
    
    <!-- This application has many different parameters, and a slight change in one can radically alter the kind of results achieved. It is difficult
        to keep track of them all, so the following global variable collects the key items and prepares them for messaging.-->
    
    <xsl:variable name="notices" as="element()">
        <notices>
            <input_selection>
                <message><xsl:value-of select="'Main input directory: ' || string-join($main-input-resolved-uri-directories, ', ')"/></message>
                <xsl:if test="string-length($tan:input-filenames-must-match-regex) gt 0">
                    <message><xsl:value-of select="'Restricted to files with filenames matching: ' || $tan:input-filenames-must-match-regex"/></message>
                </xsl:if>
                <xsl:if test="string-length($tan:input-filenames-must-not-match-regex) gt 0">
                    <message><xsl:value-of select="'Avoiding any files with filenames matching: ' || $tan:input-filenames-must-not-match-regex"/></message>
                </xsl:if>
                <message><xsl:value-of select="'Found ' || string(count($mirus-chosen)) || ' input files: ' || string-join($mirus-chosen, '; ')"/></message>
                <xsl:if test="$check-top-level-div-ns">
                    <message><xsl:value-of select="'Excluding top-level divs whose @n values match ' || $exclude-top-level-divs-with-attr-n-matching-what"/></message>
                </xsl:if>
                <message><xsl:value-of select="'Exclude orphaned top-level divs? ' || $restrict-to-matching-top-level-div-attr-ns"/></message>
                <message><xsl:value-of select="'XML handling option ' || $xml-handling-option"/></message>
                <message><xsl:value-of select="'File group option ' || $file-group-option"/></message>
            </input_selection>
            <input_alteration>
                <xsl:if test="count($tan:diff-and-collate-input-batch-replacements) gt 0">
                    <message><xsl:value-of select="string(count($tan:diff-and-collate-input-batch-replacements)) || ' batch replacements applied globally, in this order:'"/></message>
                    <xsl:for-each select="$tan:diff-and-collate-input-batch-replacements">
                        <message><xsl:value-of select="'Global replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                    </xsl:for-each>
                </xsl:if>
                <message><xsl:value-of select="'Ignore case differences: ' || string($tan:ignore-case-differences)"/></message>
                <message><xsl:value-of select="'Ignore combining marks: ' || string($tan:ignore-combining-marks)"/></message>
                <message><xsl:value-of select="'Ignore character component differences: ' || string($tan:ignore-character-component-differences)"/></message>
                <message><xsl:value-of select="'Ignore punctuation differences: ' || string($tan:ignore-punctuation-differences)"/></message>
                <xsl:if test="$main-input-files-space-normalized/tan:TAN-T/tan:body/@xml:lang = 'grc'">
                    <message><xsl:value-of select="'Ignore differences in Greek between grave and acute accents: ' || string($ignore-greek-grave-acute-distinction)"/></message>
                </xsl:if>
                <xsl:if test="$main-input-files-space-normalized/tan:TAN-T/tan:body/@xml:lang = 'lat'">
                    <xsl:if test="$apply-to-latin-batch-replacement-set-1">
                        <message><xsl:value-of select="'Applying the following batch replacements to all Latin text: '"/></message>
                        <xsl:for-each select="$tan:latin-batch-replacements-1">
                            <message><xsl:value-of select="'Latin replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="$main-input-files-space-normalized/tan:TAN-T/tan:body/@xml:lang = 'syr'">
                    <message><xsl:value-of select="'Ignore differences in placement of Syriac marks: ' || string($ignore-syriac-dot-placement)"/></message>
                    <xsl:if test="$apply-to-syriac-batch-replacement-set-1">
                        <message><xsl:value-of select="'Applying the following batch replacements to all Syriac text: '"/></message>
                        <xsl:for-each select="$syriac-batch-replacements-1">
                            <message><xsl:value-of select="'Latin replacement ' || string(position()) || ': ' || tan:batch-replacement-messages(.)"/></message>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="string-length($input-attributes-to-remove-regex) gt 0">
                    <xsl:message select="'Removing attributes whose names match: ' || $input-attributes-to-remove-regex"/>
                </xsl:if>
                <xsl:if test="$inject-attr-n">
                    <message>Injecting @n values into the input before making comparisons.</message>
                </xsl:if>
            </input_alteration>
            <collation_handling>
                <message><xsl:value-of select="'Preoptimize string order for tan:collate()? ' || string($preoptimize-string-order)"/></message>
                <message><xsl:value-of select="'Treat differences word-for-word (not character-for-character)? ' || string($tan:snap-to-word)"/></message>
            </collation_handling>
            <statistics>
                <xsl:if test="matches($tan:unimportant-change-regex, '\S')">
                    <message><xsl:value-of select="'Characters ignored in statistics (regular expression): ' || $tan:unimportant-change-regex"/></message>
                </xsl:if>
                <xsl:if test="count($tan:unimportant-change-character-aliases) gt 0">
                    <message><xsl:value-of select="string(count($tan:unimportant-change-character-aliases)) || ' groups of changes will be ignored for the sake of statistical analysis.'"/></message>
                    <xsl:for-each select="$tan:unimportant-change-character-aliases">
                        <message><xsl:value-of select="'Character alias ' || string(position()) || ': ' || string-join('[' || * || ']', ' ')"/></message>
                    </xsl:for-each>
                </xsl:if>
            </statistics>
            <output>
                <message><xsl:value-of select="'Collate/diff results in the HTML file are replaced with their original form (e.g., ignored punctuation is restored, capitalization is restored): ' || string($replace-diff-results-with-pre-alteration-forms)"/></message>
            </output>
        </notices>
    </xsl:variable>
    
    
    
    
    
    
    <!-- Beginning of main input -->
    
    <xsl:variable name="main-input-files" as="document-node()*">
        <xsl:choose>
            <xsl:when test="$xml-handling-option eq 1">
                <xsl:for-each select="$mirus-chosen">
                    <xsl:choose>
                        <xsl:when test="doc-available(.)">
                            <xsl:document>
                                <unparsed-text>
                                    <xsl:attribute name="xml:base" select="."/>
                                    <xsl:value-of select="unparsed-text(.)"/>
                                </unparsed-text>
                            </xsl:document>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="tan:open-file(.)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="tan:open-file($mirus-chosen)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="main-input-files-filtered" as="document-node()*">
        <xsl:for-each select="$main-input-files">
            <xsl:choose>
                <xsl:when
                    test="$restrict-to-matching-top-level-div-attr-ns and not(exists(*/tan:head))"/>
                <xsl:when test="exists(*[@_archive-path][not(self::w:document)])"/>
                <xsl:when test="not(exists(/*/@TAN-version))">
                    <xsl:sequence select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="filter-input-files"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:mode name="filter-input-files" on-no-match="shallow-copy"/>
    
    <xsl:template match="*:body/*:div" mode="filter-input-files">
        <xsl:choose>
            <xsl:when
                test="$check-top-level-div-ns and matches(@n, $exclude-top-level-divs-with-attr-n-matching-what)"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>    
    
    <xsl:variable name="main-input-files-resolved" as="document-node()*" select="
            for $i in $main-input-files-filtered
            return
                if (exists($i/*/tan:head)) then
                    tan:resolve-doc($i, true(), ())
                else
                    $i"/>
    
    <!-- Get string value of other input text; no normalization occurs -->
    <xsl:variable name="main-input-files-prepped" as="document-node()*">
        <xsl:apply-templates select="$main-input-files-resolved" mode="prepare-input"/>
    </xsl:variable>
    
    
    <xsl:mode name="prepare-input" on-no-match="shallow-copy"/>
    
    <xsl:template match="@q" priority="1" mode="prepare-input">
        <!-- @q is used to re-infuse results; if it needs to be removed, that will happen later -->
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="@*" mode="prepare-input">
        <xsl:choose>
            <xsl:when test="string-length($input-attributes-to-remove-regex) lt 1 or not(tan:regex-is-valid($input-attributes-to-remove-regex))">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="matches(name(.), $input-attributes-to-remove-regex)"/>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Skip docx components that aren't documents -->
    <xsl:template match="document-node()[*/@_archive-path]" priority="-2" mode="prepare-input"/>
    <xsl:template match="document-node()[w:document]" mode="prepare-input">
        <xsl:document>
            <xsl:apply-templates mode="#current"/>
        </xsl:document>
    </xsl:template>
    
    <!-- Word documents get plain text only -->
    <xsl:template match="/w:document" priority="1" mode="prepare-input">
        <xsl:variable name="this-filename" as="xs:string" select="tan:cfn(@xml:base)"/>
        <xsl:variable name="filename-group" as="xs:string"
            select="tan:batch-replace($this-filename, $filename-adjustments-before-grouping)"/>
        <xsl:copy>
            <xsl:attribute name="xml:lang" select="$default-language"/>
            <xsl:attribute name="xml:base" select="replace(@xml:base, '^jar:|!/$', '')"/>
            <xsl:attribute name="grouping-key">
                <xsl:choose>
                    <xsl:when test="$file-group-option eq 2">
                        <xsl:sequence select="$filename-group"/>
                    </xsl:when>
                    <xsl:when test="$file-group-option eq 3">
                        <xsl:sequence select="$filename-group || ' ' || $default-language"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$default-language"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="sort-key" select="$this-filename"/>
            <xsl:attribute name="label" select="replace($this-filename, '(%20|\.)', '_')"/>
            <xsl:sequence select="tan:docx-to-text(.)"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- For unparsed text use default language; if XML look for the first @xml:lang -->
    <xsl:template match="/*" mode="prepare-input">
        <xsl:variable name="this-base-uri" as="xs:anyURI" select="tan:base-uri(.)"/>
        <xsl:variable name="this-filename" as="xs:string" select="tan:cfn($this-base-uri)"/>
        <xsl:variable name="filename-group" as="xs:string"
            select="tan:batch-replace($this-filename, $filename-adjustments-before-grouping)"/>
        <xsl:variable name="first-language" select="(descendant-or-self::*[@xml:lang][1]/@xml:lang)[1]" as="xs:string?"/>
        <xsl:copy>
            <xsl:attribute name="xml:base" select="$this-base-uri"/>
            <xsl:attribute name="xml:lang" select="($first-language, $default-language)[1]"/>
            <xsl:attribute name="grouping-key">
                <xsl:choose>
                    <xsl:when test="$file-group-option eq 2">
                        <xsl:sequence select="$filename-group"/>
                    </xsl:when>
                    <xsl:when test="$file-group-option eq 3">
                        <xsl:sequence select="$filename-group || ' ' || ($first-language, $default-language)[1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="($first-language, $default-language)[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="sort-key" select="$this-filename"/>
            <xsl:attribute name="label" select="replace($this-filename, '(%20|\.)', '_')"/>
            <xsl:attribute name="_orig-attr-names" select="
                    string-join((for $i in @*
                    return
                        name($i)), ' ')"/>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Ignore the tei header and tan header -->
    <xsl:template match="tan:head | tei:teiHeader" priority="2" mode="prepare-input tan:normalize-tree-space"/>
    
    <xsl:template match="*:div[@n]" mode="prepare-input">
        <xsl:copy>
            <xsl:if test="$inject-attr-n">
                <xsl:sequence select="@n || ' '"/>
            </xsl:if>
            <xsl:if test="not(exists(@q))">
                <xsl:attribute name="q" select="generate-id(.)"/>
            </xsl:if>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[$xml-handling-option ne 3][not(@q)]" priority="-1" mode="prepare-input">
        <!-- Add a @q, so that diff results can be replaced by the original material. But if the
            user wants to serialize, do not add this attribute. -->
        <xsl:copy>
            <xsl:attribute name="q" select="generate-id(.)"/>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Normalize spacing in TAN files, and perhaps serialize -->
    <!--<xsl:variable name="main-input-files-space-normalized" as="document-node()*" select="
            for $i in $main-input-files-prepped
            return
                if (
                (not(exists($i/*/@TAN-version)) and not($space-normalize-non-tan-input))
                or exists($i/*/@_archive-path) (: don't space-normalize docx components :)
                ) then
                    if ($xml-handling-option eq 3 and not(exists($i/*/@_archive-path)
                    and not(exists($i/*:unparsed-text))
                    and not(exists($i/*:base64Binary))
                    )) then
                        ()
                    else
                        $i
                else
                    tan:normalize-tree-space($i, true())"/>-->
    <xsl:variable name="main-input-files-space-normalized" as="document-node()*">
        <xsl:apply-templates select="$main-input-files-prepped"
            mode="space-normalize-or-serialize-input"/>
    </xsl:variable>
    
    <xsl:mode name="space-normalize-or-serialize-input" on-no-match="shallow-copy"/>
    
    <xsl:template match="document-node()[*/@_archive-path] | document-node()[tan:unparsed-text] 
        | document-node()[tan:base64Binary]" priority="2"
        mode="space-normalize-or-serialize-input">
        <!-- Do not space normalize or adjust any of the following: docx components, unparsed text,
            base-64 binary. -->
        <xsl:sequence select="."/>
    </xsl:template>
    <xsl:template match="document-node()[*/@TAN-version]" priority="2" mode="space-normalize-or-serialize-input">
        <xsl:sequence select="tan:normalize-tree-space(., true())"/>
    </xsl:template>
    <xsl:template match="document-node()[$space-normalize-non-tan-input]" priority="1" mode="space-normalize-or-serialize-input">
        <xsl:variable name="item-so-far" as="document-node()" select="tan:normalize-tree-space(., true())"/>
        <xsl:next-match>
            <xsl:with-param name="self-changed" as="document-node()?" tunnel="yes" select="$item-so-far"/>
        </xsl:next-match>
    </xsl:template>
    <xsl:template match="document-node()[$xml-handling-option eq 3]" mode="space-normalize-or-serialize-input">
        <xsl:param name="self-changed" as="document-node()?" tunnel="yes"/>
        <xsl:variable name="doc-with-orig-root-element-attrs-restored" as="document-node()">
            <xsl:apply-templates select="
                    if (exists($self-changed)) then
                        $self-changed
                    else
                        ." mode="revert-to-original-root-element-attributes"/>
        </xsl:variable>
        <xsl:document>
            <unparsed-text>
                <xsl:copy-of select="*/@*"/>
                <xsl:value-of select="serialize($doc-with-orig-root-element-attrs-restored)"/>
            </unparsed-text>
        </xsl:document>
    </xsl:template>
    <xsl:template match="document-node()" mode="space-normalize-or-serialize-input" priority="-1">
        <xsl:param name="self-changed" as="document-node()?" tunnel="yes"/>
        <xsl:sequence select="($self-changed, .)[1]"/>
    </xsl:template>
    
    <xsl:mode name="revert-to-original-root-element-attributes" on-no-match="shallow-copy"/>
    <xsl:template match="*[@_orig-attr-names]" mode="revert-to-original-root-element-attributes">
        <xsl:variable name="orig-attr-names" as="xs:string+" select="tokenize(@_orig-attr-names, ' ')"/>
        <xsl:copy>
            <xsl:apply-templates select="@*[name(.) = $orig-attr-names]" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@_orig-attr-names" mode="revert-to-original-root-element-attributes"/>
    
    <xsl:variable name="main-input-files-non-mixed" as="document-node()*" select="
            for $i in $main-input-files-space-normalized
            return
                tan:make-non-mixed($i)"/>


    <!-- This builds a series of XML documents with the diffs and collations, plus simple metadata on each file -->
    <xsl:variable name="file-groups-diffed-and-collated" as="document-node()*">
        <xsl:for-each-group select="$main-input-files-non-mixed" group-by="*/@grouping-key">
            <xsl:variable name="this-group-pos" select="position()"/>
            <xsl:variable name="this-group-name" as="xs:string" select="current-grouping-key()"/>
            <xsl:variable name="this-base-filename" as="xs:string">
                <xsl:choose>
                    <xsl:when test="string-length($output-base-filename) gt 0 and position() eq 1">
                        <xsl:sequence select="$output-base-filename || $output-filename-suffix"/>
                    </xsl:when>
                    <xsl:when test="string-length($output-base-filename) gt 0">
                        <xsl:sequence select="$output-base-filename || $output-filename-suffix || '-' || string(position())"/>
                    </xsl:when>
                    <xsl:when test="exists(current-group()[1]/*/@xml:base)">
                        <xsl:sequence select="tan:cfn(current-group()[1]/*/@xml:base) || $output-filename-suffix"/>
                    </xsl:when>
                    <xsl:when test="position() eq 1">
                        <xsl:sequence select="$this-group-name || $output-filename-suffix"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$this-group-name || $output-filename-suffix || '-' || string(position())"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="this-group-count" select="count(current-group())"/>
            <xsl:variable name="these-group-labels" select="current-group()/*/@label"/>
            <xsl:variable name="this-group" as="document-node()+">
                <xsl:for-each select="current-group()">
                    <xsl:sort select="*/@sort-key"/>
                    <xsl:sequence select="."/>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="duplicate-top-level-div-attr-ns" as="xs:string*">
                <xsl:if test="$restrict-to-matching-top-level-div-attr-ns">
                    <xsl:for-each-group select="$this-group//*:body/*:div/@n" group-by=".">
                        <xsl:if test="count(current-group()) ge $this-group-count">
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:if>
                    </xsl:for-each-group> 
                </xsl:if>
            </xsl:variable>
            
            <xsl:variable name="these-langs" as="xs:string*"
                select="distinct-values($this-group/*/@xml:lang)"/>
            <xsl:variable name="extra-batch-replacements" as="element()*">
                <xsl:if test="$these-langs = 'lat' and $apply-to-latin-batch-replacement-set-1">
                    <xsl:sequence select="$tan:latin-batch-replacements-1"/>
                </xsl:if>
                <xsl:if test="$these-langs = 'syr' and $apply-to-syriac-batch-replacement-set-1">
                    <xsl:sequence select="$syriac-batch-replacements-1"/>
                </xsl:if>
            </xsl:variable>   
            <xsl:variable name="all-batch-replacements" as="element()*"
                select="$tan:diff-and-collate-input-batch-replacements, $extra-batch-replacements, $additional-batch-replacements"
            />
            
            <xsl:variable name="these-raw-texts" as="xs:string*" select="
                    for $i in $this-group
                    return
                        if (exists($duplicate-top-level-div-attr-ns)) then
                            string-join($i//*:body/*:div[@n = $duplicate-top-level-div-attr-ns])
                        else
                            string($i)"/>
            <xsl:variable name="these-texts-normalized-1" as="xs:string*"
                select="
                    if (count($all-batch-replacements) gt 0) then
                        (for $i in $these-raw-texts
                        return
                            tan:batch-replace($i, $all-batch-replacements))
                    else
                        $these-raw-texts"
            />
            
            <xsl:variable name="these-texts-normalized-2" as="xs:string*"
                select="
                    if ($tan:ignore-character-component-differences) then
                        (for $i in $these-texts-normalized-1
                        return
                            tan:string-base($i))
                    else
                        $these-texts-normalized-1"
            />

            <xsl:variable name="these-texts-normalized-3" as="xs:string*">
                <xsl:choose>
                    <xsl:when test="$these-langs = 'grc' and $ignore-greek-grave-acute-distinction">
                        <xsl:sequence
                            select="
                                for $i in $these-texts-normalized-2
                                return
                                    tan:greek-graves-to-acutes($i)"
                        />
                    </xsl:when>
                    <xsl:when test="$these-langs = 'syr' and $ignore-syriac-dot-placement">
                        <xsl:sequence
                            select="
                                for $i in $these-texts-normalized-2
                                return
                                    tan:syriac-marks-to-word-end($i)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$these-texts-normalized-2"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            

            <xsl:variable name="finalized-texts-to-compare" as="xs:string*"
                select="
                    if ($tan:ignore-case-differences) then
                        (for $i in $these-texts-normalized-3
                        return
                            lower-case($i))
                    else
                        $these-texts-normalized-3"
            />
            
            <xsl:variable name="these-labels"
                select="
                    for $i in $this-group
                    return
                        ($i/*/@label, '')[1]"
            />
            <xsl:variable name="these-duplicate-labels" select="tan:duplicate-values($these-labels)"/>
            <xsl:variable name="these-labels-revised" as="xs:string*">
                <xsl:for-each select="$these-labels">
                    <xsl:variable name="this-pos" select="position()"/>
                    <xsl:choose>
                        <xsl:when test=". = ('', $these-duplicate-labels)">
                            <xsl:value-of select="string-join((., string($this-pos)), '_')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
            <xsl:if test="$diagnostics-on">
                <xsl:message select="'Diagnostics on, $file-groups-diffed-and-collated'"/>
                <xsl:message select="'Group pos, name, count:', $this-group-pos, $this-group-name, $this-group-count"
                />
                <xsl:message select="'Group labels: ' || string-join($these-group-labels, ', ')"/>
                <xsl:message select="'Duplicate top level ns: ' || string-join($duplicate-top-level-div-attr-ns, ', ')"/>
                <xsl:message select="'These langs: ' || string-join($these-langs, ', ')"/>
                <xsl:message select="'Extra batch replacements:', $extra-batch-replacements"/>
                <xsl:message select="'Raw texts: ' || string-join(tan:ellipses($these-raw-texts, 40), ' || ')"/>
                <xsl:message select="'Texts pass 1: ' || string-join(tan:ellipses($these-texts-normalized-1, 40), ' || ')"/>
                <xsl:message select="'Texts pass 2: ' || string-join(tan:ellipses($these-texts-normalized-2, 40), ' || ')"/>
                <xsl:message select="'Texts pass 3: ' || string-join(tan:ellipses($these-texts-normalized-3, 40), ' || ')"/>
                <xsl:message select="'Final texts: ' || string-join(tan:ellipses($finalized-texts-to-compare, 40), ' || ')"/>
                <xsl:message select="'Duplicate labels:', $these-duplicate-labels"/>
                <xsl:message select="'Labels (revised): ' || string-join($these-labels-revised, ', ')"/>
            </xsl:if>


            <!-- global variable's messaging, output -->
            <xsl:for-each select="$finalized-texts-to-compare">
                <xsl:variable name="this-pos" select="position()"/>
                <xsl:choose>
                    <xsl:when test="string-length(.) lt 1">
                        <xsl:message
                            select="$this-group[$this-pos]/*/@xml:base || ' is a zero-length string.'"
                        />
                    </xsl:when>
                    <xsl:when test="not(matches(., '\w'))">
                        <xsl:message
                            select="$this-group[$this-pos]/*/@xml:base || ' has no letters.'"
                        />
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>

            <xsl:choose>
                <!-- Ignore groups beyond the threshold -->
                <xsl:when test="count($this-group) lt 2">
                    <xsl:message
                        select="'Ignoring ' || $this-group/*/@xml:base || ' because it has no pair. Grouped as: ' || $this-group-name"
                    />
                </xsl:when>
                <xsl:when
                    test="
                        some $i in $finalized-texts-to-compare
                            satisfies ($i = ('', ()))">
                    <xsl:message
                        select="'Ignoring entire set of texts because at least one of them, after normalization, results in a zero-length string. Check: ' || string-join($this-group/*/@xml:base, ' ')"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:document>
                        <group cgk="{current-grouping-key()}" count="{count($this-group)}"
                            _target-format="xml-indent"
                            _target-uri="{$output-directory-uri-resolved || $this-base-filename || '.xml'}">
                            <group-name><xsl:value-of select="$this-group-name"/></group-name>
                            <group-label><xsl:value-of select="distinct-values($these-group-labels)"/></group-label>
                            <xsl:for-each select="$this-group">
                                <xsl:variable name="this-pos" select="position()"/>
                                <xsl:variable name="this-raw-text" select="$these-raw-texts[$this-pos]"/>
                                <xsl:variable name="this-text-finalized"
                                    select="$finalized-texts-to-compare[$this-pos]"/>
                                <xsl:variable name="this-id-ref"
                                    select="$these-labels-revised[$this-pos]"/>
                                <file orig-length="{string-length($this-raw-text)}"
                                    length="{string-length($this-text-finalized)}"
                                    uri="{*/@xml:base}" ref="{$this-id-ref}"/>
                            </xsl:for-each>
                            

                            <xsl:choose>
                                
                                <xsl:when test="count($finalized-texts-to-compare) eq 2">
                                    <xsl:copy-of
                                        select="tan:adjust-diff(tan:diff($finalized-texts-to-compare[1], $finalized-texts-to-compare[2], $tan:snap-to-word))"
                                    />
                                </xsl:when>
                                
                                <xsl:otherwise>
                                    <xsl:copy-of
                                        select="tan:collate($finalized-texts-to-compare, $these-labels-revised, $preoptimize-string-order, true(), true(), $tan:snap-to-word)"
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </group>
                    </xsl:document>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:variable>
    
    
    <!-- Next, build a statistical profile and weigh the results. -->
    
    <!-- This does the same as tan:infuse-diff-and-collate-stats() but retains
    the XML's document character -->
    <xsl:variable name="xml-output-pass-1" as="document-node()*">
        <xsl:apply-templates select="$file-groups-diffed-and-collated" mode="tan:infuse-diff-and-collate-stats">
            <xsl:with-param name="unimportant-change-character-aliases" as="element()*"
                select="$tan:unimportant-change-character-aliases" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:variable>
    
    
    <!-- At this point, the master XML data should be finished. From this point forward we deal with 
    presenting that data legibly via HTML. -->
    
    
    <!-- PREPARATION FOR HTML -->
    
    <!-- In each diff/collate report, find the primary input file. Remove the diff / collation results. Apply templates
        to the primary file with the diff/collation results as a tunnel parameter, to be infused into the text nodes
        of the primary file. That allows us to begin a basic structure of presenting the diff/collation results in the
        form of the primary document, to improve legibility.
    -->
    <!-- Remove temporary attributes we're not interested in -->
    <!-- We also insert the global notices, and replace the diff or collation, if required. -->
    
    
    <xsl:variable name="xml-to-html-prep" as="document-node()*">
        <xsl:apply-templates select="$xml-output-pass-1" mode="prep-for-html"/>
    </xsl:variable>
    
    
    <xsl:mode name="prep-for-html" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:group" mode="prep-for-html">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            
            <xsl:copy-of select="$notices"/>
            
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="last-wit-ref" tunnel="yes" as="xs:string?"
                    select="tan:stats/tan:witness[last()]/@ref"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:stats" mode="prep-for-html">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:if test="$replace-diff-results-with-pre-alteration-forms">
                <div xmlns="http://www.w3.org/1999/xhtml" class="note warning">There may be
                    discrepancies between the statistics and the displayed text. The original texts
                    may have been altered before the text comparison and statistics were generated
                    (see any attached notices), but for legibility the results styled according to
                    the original text form. To see the difference that justifies the statistics, see
                    the original input or any supplementary output.</div>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tan:diff[tan:common or tan:a or tan:b]" mode="prep-for-html">
        <xsl:variable name="diff-a-file-base-uri" select="../tan:stats/tan:witness[1]/tan:uri" as="element()?"/>
        <xsl:variable name="diff-b-file-base-uri" select="../tan:stats/tan:witness[2]/tan:uri" as="element()?"/>
        
        <xsl:variable name="diff-a-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $diff-a-file-base-uri]"
        />
        <xsl:variable name="diff-b-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $diff-b-file-base-uri]"
        />
        
        <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on, template mode prep-for-html on tan:diff'"/>
            <xsl:message select="'a base uri: ' || $diff-a-file-base-uri"/>
            <xsl:message select="'b base uri: ' || $diff-b-file-base-uri"/>
            <xsl:message select="'a text: ' || string($diff-a-prepped-file)"/>
            <xsl:message select="'b text: ' || string($diff-b-prepped-file)"/>
            <xsl:message select="'This diff (orig): ', ."/>
            <xsl:message select="'This diff replaced with a and b: ', tan:replace-diff(
                string($diff-a-prepped-file),
                string($diff-b-prepped-file),
                ., false())"/>
        </xsl:if>
        
        
        <xsl:choose>
            <xsl:when test="$replace-diff-results-with-pre-alteration-forms">
                <xsl:copy-of select="
                        tan:replace-diff(
                        string($diff-a-prepped-file),
                        string($diff-b-prepped-file),
                        ., false())"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="tan:collation[tan:witness]" mode="prep-for-html">
        <xsl:param name="last-wit-ref" tunnel="yes" as="xs:string"/>
        <xsl:variable name="primary-file-base-uri"
            select="../tan:stats/tan:witness[@ref eq $last-wit-ref]/tan:uri" as="element()"/>
        <xsl:variable name="primary-prepped-file" as="document-node()"
            select="($main-input-files-non-mixed)[*/@xml:base eq $primary-file-base-uri]"
        />
        
        <xsl:choose>
            <xsl:when test="$replace-diff-results-with-pre-alteration-forms">
                <xsl:sequence select="
                        tan:replace-collation(string($primary-prepped-file),
                        $last-wit-ref, .)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    


    <xsl:variable name="html-output-pass-1" as="document-node()*">
        <xsl:for-each select="$xml-to-html-prep/*">
            <xsl:variable name="primary-witness" as="element()"
                select="tan:stats/tan:witness[last()]"/>
            <xsl:variable name="primary-file-base-uri" select="$primary-witness/tan:uri" as="element()?"/>
            
            <xsl:variable name="primary-file-idref" select="$primary-witness/@ref" as="xs:string"/>
            <xsl:variable name="primary-prepped-file" as="document-node()"
                select="($main-input-files-non-mixed)[*/@xml:base eq $primary-file-base-uri]"
            />
            <xsl:variable name="primary-prepped-file-adjusted" as="document-node()">
                <xsl:apply-templates select="$primary-prepped-file"
                    mode="adjust-primary-tree-for-html"/>
            </xsl:variable>
            
            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
            <xsl:if test="$diagnostics-on">
                <xsl:message select="'Diagnostics on, Diff+, $html-output-pass-1'"/>
                <xsl:message select="'This xml to html prep: ', tan:trim-long-tree(., 10, 20)"/>
                <xsl:message select="'Primary witness: ', $primary-witness"/>
                <xsl:message select="'Primary file base uri: ' || $primary-file-base-uri"/>
                <xsl:message select="'Primary file idref: ' || $primary-file-idref"/>
                <xsl:message select="'Primary prepped file: ', tan:trim-long-tree($primary-prepped-file/*, 10, 20)"/>
                <xsl:message select="'Primary prepped file adjusted: ', tan:trim-long-tree($primary-prepped-file-adjusted, 10, 20)"/>
            </xsl:if>
            
            <xsl:document>
                <xsl:sequence
                    select="tan:diff-or-collate-to-html(., $primary-file-idref, $primary-prepped-file-adjusted/*)"
                />
            </xsl:document>
        </xsl:for-each>
    </xsl:variable>
    
    
    <xsl:mode name="adjust-primary-tree-for-html" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*/@*" mode="adjust-primary-tree-for-html"/>
    
    
    <xsl:variable name="html-output-pass-2" as="document-node()*">
        <xsl:apply-templates select="$html-output-pass-1" mode="html-output-pass-2"/>
        
    </xsl:variable>
    
    
    <xsl:mode name="html-output-pass-2" on-no-match="shallow-copy"/>
    
    <xsl:template match="/*" mode="html-output-pass-2">
        <xsl:variable name="this-title" as="xs:string?">
            <xsl:sequence
                select="'Comparison of ' || tan:cardinal(xs:integer(tan:find-class(., 'a-count')))
                || ' files'"
            />
        </xsl:variable>
        <xsl:variable name="this-subtitle" as="xs:string?" select="
                'String differences and analyses across ' ||
                replace(string-join(
                for $i in html:table[tan:has-class(., 'e-stats')]//html:tr[not(tan:has-class(., ('a-collation', 'a-diff', 'averages')))]/html:td[tan:has-class(., ('a-uri', 'e-uri'))]
                return
                    tan:cfne(string($i)), ', '), '%20', ' ')"/>
        <xsl:variable name="this-target-uri" select="replace(@_target-uri, '\w+$', 'html')"/>
        <html xmlns="http://www.w3.org/1999/xhtml">
            <xsl:attribute name="_target-format">xhtml-noindent</xsl:attribute>
            <xsl:attribute name="_target-uri" select="$this-target-uri"/>
            <head>
                <title>
                    <xsl:value-of select="string-join(($this-title, $this-subtitle), ': ')"/>
                </title>
                <!-- TAN css attend to some basic style issues common to TAN converted to HTML. -->
                <link rel="stylesheet"
                    href="{tan:uri-relative-to($resolved-uri-to-diff-css, $this-target-uri)}"
                    type="text/css">
                    <!-- Inserted comments ensure that the elements do not close and make them unreadable to the browser -->
                    <xsl:comment/>
                </link>
                <!-- The TAN JavaScript code uses jQuery. -->
                <script src="{tan:uri-relative-to($resolved-uri-to-jquery, $this-target-uri)}">
                    <xsl:comment/>
                </script>
                <!-- The d3js library is required for use of the Venn JavaScript library -->
                <script src="https://d3js.org/d3.v5.min.js">
                    <xsl:comment/>
                </script>
                <!-- The Venn JavaScript library: https://github.com/benfred/venn.js/ -->
                <script src="{tan:uri-relative-to($resolved-uri-to-venn-js, $this-target-uri)}">
                    <xsl:comment/>
                </script>
            </head>
            <body>
                <h1>
                    <xsl:value-of select="$this-title"/>
                </h1>
                <div class="subtitle">
                    <xsl:value-of select="$this-subtitle"/>
                </div>
                <div class="timedate">
                    <xsl:value-of
                        select="'Comparison generated ' || format-dateTime(current-dateTime(), '[MNn] [D], [Y], [h]:[m01] [PN]')"
                    />
                </div>
                <xsl:apply-templates mode="#current"/>
                
                <!-- TAN JavaScript comes at the end, to ensure the DOM is loaded. The file supports manipulation of the sources and their appearance. -->
                <script src="{tan:uri-relative-to($resolved-uri-to-diff-js, $this-target-uri)}"><!--  --></script>
                <!-- The TAN JavaScript library provides some generic functionality across all TAN HTML output -->
                <script src="{tan:uri-relative-to($resolved-uri-to-TAN-js, $this-target-uri)}"><!--  --></script>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="html:div[tan:has-class(., ('e-txt', 'e-a', 'e-b', 'e-common'))]/text()" mode="html-output-pass-2">
        <xsl:variable name="this-text-length" as="xs:integer" select="string-length(.)"/>
        <xsl:variable name="estimated-length-of-message" as="xs:integer" select="40"/>
        <xsl:variable name="elide-this-text" as="xs:boolean" select="$elide-lengthy-text and ($this-text-length gt $elision-trigger-point-norm + $estimated-length-of-message)"/>
        <xsl:variable name="text-parts" as="xs:string+" select="
                if ($elide-this-text)
                then
                    (substring(., 1, $elision-trigger-point-norm idiv 2), substring(., string-length(.) - $elision-trigger-point-norm idiv 2))
                else
                    ."/>
        <xsl:for-each select="$text-parts">
            <xsl:if test="$elide-this-text and position() gt 1">
                <div class="elision">…[{$this-text-length - (2 * ($elision-trigger-point-norm idiv 2))} chars]…</div>
            </xsl:if>
            <xsl:analyze-string select="." regex="\n">
                <xsl:matching-substring>
                    <xsl:text>¶</xsl:text>
                    <xsl:element name="br" namespace="http://www.w3.org/1999/xhtml"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:sequence select="tan:parse-a-hrefs(tan:controls-to-pictures(.))"/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template
        match="html:div[tan:has-class(., ('a-cgk', 'a-count', 'e-group-name', 'e-group-label', 'e-file', 'a-part', 'a-org',
        'a-sample', 'a-q'))]"
        mode="html-output-pass-2"/>
    
    
    <xsl:variable name="resolved-uri-to-css-dir" as="xs:string" select="
            if (string-length($output-css-library-directory-uri) gt 0 and matches($output-css-library-directory-uri, '\S'))
            then
                (resolve-uri(replace($output-css-library-directory-uri, '([^/])$', '$1/'), $calling-stylesheet-uri))
            else
                $output-directory-uri-resolved || 'css/'"/>
    <xsl:variable name="resolved-uri-to-js-dir" as="xs:string" select="
            if (string-length($output-javascript-library-directory-uri) gt 0 and matches($output-javascript-library-directory-uri, '\S'))
            then
                (resolve-uri(replace($output-javascript-library-directory-uri, '([^/])$', '$1/'), $calling-stylesheet-uri))
            else
                $output-directory-uri-resolved || 'js/'"/>
    
    <xsl:variable name="resolved-uri-to-diff-css" as="xs:string"
        select="($resolved-uri-to-css-dir || 'diff.css')"/>
    <xsl:variable name="resolved-uri-to-TAN-js" as="xs:string"
        select="($resolved-uri-to-js-dir || 'tan2020.js')"/>
    <xsl:variable name="resolved-uri-to-diff-js" as="xs:string"
        select="($resolved-uri-to-js-dir || 'diff.js')"/>
    <xsl:variable name="resolved-uri-to-jquery" as="xs:string"
        select="($resolved-uri-to-js-dir || 'jquery.js')"/>
    <xsl:variable name="resolved-uri-to-venn-js" as="xs:string"
        select="($resolved-uri-to-js-dir || 'venn.js/venn.js')"/>
    

    
    
    <xsl:mode name="return-final-messages" on-no-match="shallow-skip"/>
    
    <!-- The messages are handled by $notices, not the html file, and we do not want to check whether
        @href points to a file, because directories are referred to. Same with the stats table, which 
        simply derives from the input, or points to expected secondary output. -->
    <xsl:template match="html:div[tan:has-class(., 'e-message')] | html:table[tan:has-class(., 'e-stats')]" mode="return-final-messages"/>
    
    <xsl:template match="html:script/@src | @href" mode="return-final-messages">
        <xsl:variable name="target-uri" select="root(.)/*/@_target-uri" as="xs:string"/>
        <xsl:variable name="this-link-resolved" select="resolve-uri(., $target-uri)" as="xs:anyURI"/>
        <xsl:if test="not(unparsed-text-available($this-link-resolved))">
            <xsl:message select="'Unparsed text not available at ' || . || ' relative to ' || $target-uri || '. See ' || path(.)"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tan:global-notices/*" mode="return-final-messages">
        <xsl:message select="'= = = = ' || name(.) || ' = = = ='"/>
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="tan:message" mode="return-final-messages">
        <xsl:message select="string(.)"/>
    </xsl:template>
    
    
    

    <!-- Main output -->
    <xsl:param name="output-diagnostics-on" static="yes" as="xs:boolean" select="false()"/>
    <xsl:output indent="no" use-character-maps="tan:see-special-chars" use-when="not($output-diagnostics-on)"/>
    <xsl:output indent="yes" use-character-maps="tan:see-special-chars" use-when="$output-diagnostics-on"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:message select="'Output diagnostics on for ' || static-base-uri()"/>
        <xsl:apply-templates select="$notices" mode="return-final-messages"/>
        <diagnostics>
            <!--<input-directories count="{count($main-input-resolved-uri-directories)}"><xsl:sequence select="$main-input-resolved-uri-directories"/></input-directories>-->
            <!--<main-input-resolved-uris count="{count($main-input-resolved-uris)}"><xsl:sequence select="$main-input-resolved-uris"/></main-input-resolved-uris>-->
            <!--<MIRUs-chosen count="{count($mirus-chosen)}"><xsl:sequence select="$mirus-chosen"/></MIRUs-chosen>-->
            <!--<main-input-files count="{count($main-input-files)}"><xsl:copy-of select="tan:trim-long-tree($main-input-files, 10, 20)"/></main-input-files>-->
            <!--<main-input-files-filtered count="{count($main-input-files-filtered)}"><xsl:copy-of select="tan:trim-long-tree($main-input-files-filtered, 10, 20)"/></main-input-files-filtered>-->
            <!--<main-input-files-resolved count="{count($main-input-files-resolved)}"><xsl:sequence select="tan:trim-long-tree($main-input-files-resolved, 10, 20)"/></main-input-files-resolved>-->
            <!--<main-input-files-prepped count="{count($main-input-files-prepped)}"><xsl:sequence select="tan:trim-long-tree($main-input-files-prepped, 10, 20)"/></main-input-files-prepped>-->
            <!--<main-input-files-space-norm count="{count($main-input-files-space-normalized)}"><xsl:sequence select="tan:trim-long-tree($main-input-files-space-normalized, 10, 20)"/></main-input-files-space-norm>-->
            <!--<main-input-files-non-mixed count="{count($main-input-files-non-mixed)}"><xsl:sequence select="$main-input-files-non-mixed"/></main-input-files-non-mixed>-->
            <!--<output-dir><xsl:value-of select="$output-directory-uri-resolved"/></output-dir>-->
            <!--<file-groups-diffed-and-collated><xsl:copy-of select="tan:trim-long-tree($file-groups-diffed-and-collated, 10, 20)"/></file-groups-diffed-and-collated>-->
            <!--<xml-output-pass-1><xsl:copy-of select="tan:trim-long-tree($xml-output-pass-1, 10, 20)"/></xml-output-pass-1>-->
            <xml-to-html-prep><xsl:copy-of select="tan:trim-long-tree($xml-to-html-prep, 10, 20)"/></xml-to-html-prep>
            <html-output-pass-1><xsl:copy-of select="tan:trim-long-tree($html-output-pass-1, 10, 20)"/></html-output-pass-1>
            <html-output-pass-2><xsl:copy-of select="tan:trim-long-tree($html-output-pass-2, 10, 20)"/></html-output-pass-2>
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <!-- The main output template returns only secondary output, one HTML page per
            group of compared texts, plus messages. -->
        <xsl:apply-templates select="$notices, $xml-output-pass-1, $html-output-pass-2"
            mode="return-final-messages"/>
        <!--<xsl:for-each select="$global-notices">
            <xsl:message select="'= = = = ' || name(.) || ' = = = ='"/>
            <xsl:for-each select="tan:message">
                <xsl:message select="string(.)"/>
            </xsl:for-each>
        </xsl:for-each>-->
        <xsl:for-each select="$xml-output-pass-1, $html-output-pass-2">
            <xsl:call-template name="tan:save-as">
                <xsl:with-param name="document-to-save" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    
</xsl:stylesheet>
