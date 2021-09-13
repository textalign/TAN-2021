<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:ti="http://chs.harvard.edu/xmlns/cts"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">

    <!-- Primary (catalyzing) input: A TAN-TEI file -->
    <!-- Secondary input: none -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: one TAN-T file per detectable divisions system (native, or milestones) -->
    <!-- Resultant output will need attention, because of how unpredictable TEI files are. -->

    <xsl:param name="output-diagnostics-on" static="yes" as="xs:boolean" select="false()"/>
    
    <xsl:output expand-text="false"/>

    <xsl:import href="../get%20inclusions/convert.xsl"/>
    <xsl:import href="../get%20inclusions/analysis%20of%20TEI.xsl"/>

    <!-- TEI files that use <lb> assume one knows there are line breaks at other elements; this parameter has relevance only if converting to a line-based reference system -->
    <xsl:param name="add-implicit-lb" as="xs:boolean" select="true()"/>


    <!-- THIS STYLESHEET -->
    <xsl:param name="stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:convert-tan-tei-to-tan-t'"/>
    <xsl:param name="stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="stylesheet-name" select="'TAN-TEI to TAN-T converter'"/>
    <xsl:param name="change-message" select="'Converted from TAN-TEI to TAN-T.'"/>
    <xsl:param name="stylesheet-is-core-tan-application" select="true()"/>
    

    <xsl:variable name="div-type-glossary" select="tan:vocabulary('div-type', '*', $doc-vocabulary)"/>
    <xsl:variable name="div-type-glossary-for-tei-element"
        select="$div-type-glossary/*[tan:name[matches(., '^tei ')]]"/>
    <xsl:variable name="TAN-div-type-vocabulary" select="$TAN-vocabularies[tan:TAN-voc/@id = 'tag:textalign.net,2015:tan-voc:div-types']"/>

    <!-- Input pre-analysis -->
    
    <xsl:variable name="milestoneLike-elements"
        select="/tei:TEI/tei:text/tei:body//*[local-name() = $milestoneLike-element-info//@name]"/>
    <xsl:variable name="milestoneLike-analysis" as="element()*">
        <xsl:for-each-group select="$milestoneLike-elements"
            group-by="
                if (exists(@type)) then
                    @type
                else
                    'untyped'">
            <xsl:variable name="this-milestone-type" select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()"
                group-by="$milestoneLike-element-info/tan:group[local-name(current()) = tan:element/@name]/@type">
                <xsl:variable name="this-milestone-group" select="current-grouping-key()"/>
                <group type="{$this-milestone-type}">
                    <!-- Why this?: if (exists(@n)) then @unit else () -->
                    <!-- Some people are using @unit instead of @n; @unit should be used only if it is a div type, not a counter -->
                    <xsl:for-each-group select="current-group()"
                        group-by="
                            string-join((if (exists(@n)) then
                                @unit
                            else
                                (), local-name()), ' ')">
                        <xsl:sort
                            select="index-of($milestoneLike-element-info//@name, local-name())"/>
                        <xsl:variable name="this-analysis-parts"
                            select="tokenize(current-grouping-key(), ' ')"/>
                        <xsl:variable name="this-element-name" select="$this-analysis-parts[last()]"/>
                        <xsl:variable name="this-element-unit"
                            select="
                                if (count($this-analysis-parts) gt 1) then
                                    $this-analysis-parts[1]
                                else
                                    ()"/>
                        <xsl:variable name="does-not-nest-in-leaf-divs" as="xs:boolean+">
                            <xsl:for-each-group select="current-group()"
                                group-by="string-join(ancestor::tei:div/@n, $separator-hierarchy)">
                                <xsl:variable name="preceding-text" as="xs:string?">
                                    <xsl:value-of
                                        select="current-group()[1]/preceding-sibling::node()"/>
                                </xsl:variable>
                                <!-- We presume that if the first milestone in a div comes after text content, it does not nest inside -->
                                <xsl:copy-of
                                    select="string-length(normalize-space($preceding-text)) gt 1"/>
                                <!-- We also presume that if is a sibling to other divs it does not nest inside -->
                                <xsl:copy-of select="exists(parent::tei:*[tei:div])"/>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <alt-div element-name="{$this-element-name}" level="{position()}"
                            nests-in-leaf-divs="{not($does-not-nest-in-leaf-divs = true())}">
                            <xsl:if test="exists($this-element-unit)">
                                <xsl:attribute name="unit" select="$this-element-unit"/>
                            </xsl:if>
                        </alt-div>
                    </xsl:for-each-group>

                </group>

            </xsl:for-each-group>
        </xsl:for-each-group>
    </xsl:variable>

    <xsl:variable name="this-doc" select="/"/>
    <xsl:variable name="primary-conversion" as="document-node()">
        <xsl:apply-templates select="/" mode="tan-tei-to-tan-t"/>
    </xsl:variable>
    <xsl:variable name="secondary-conversions" as="document-node()*">
        <xsl:for-each select="$milestoneLike-analysis">
            <xsl:apply-templates select="$this-doc" mode="tan-tei-to-tan-t">
                <xsl:with-param name="alt-div" select="." tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:variable>



    <xsl:template match="comment() | text()" mode="tan-tei-to-tan-t">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="document-node()" mode="tan-tei-to-tan-t">
        <xsl:document>
            <xsl:apply-templates mode="#current"/>
        </xsl:document>
    </xsl:template>

    <xsl:template match="tei:*" mode="tan-tei-to-tan-t" priority="-1">
        <xsl:variable name="this-name" select="name(.)"/>
        <xsl:element name="{$this-name}" namespace="tag:textalign.net,2015:ns">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="processing-instruction()" mode="tan-tei-to-tan-t">
        <xsl:text>&#xa;</xsl:text>
        <xsl:processing-instruction name="{name(.)}">
            <xsl:value-of select="replace(., 'TAN-TEI', 'TAN-T')"/>
        </xsl:processing-instruction>
    </xsl:template>

    <xsl:template match="tei:TEI" mode="tan-tei-to-tan-t">
        <xsl:text>&#xa;</xsl:text>
        <TAN-T>
            <xsl:copy-of select="@id, @TAN-version"/>
            <xsl:apply-templates mode="#current"/>
        </TAN-T>
    </xsl:template>

    <xsl:template match="tei:teiHeader" mode="tan-tei-to-tan-t"/>

    <xsl:template match="tei:text" mode="tan-tei-to-tan-t">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="tan:vocabulary-key" mode="tan-tei-to-tan-t">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:if test="count($milestoneLike-analysis) gt 0">
                <relationship which="resegmented copy" xml:id="resegmented"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tei:body" mode="tan-tei-to-tan-t">
        <xsl:param name="alt-div" as="element()?" tunnel="yes"/>
        <body>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when
                    test="not(exists($alt-div)) or not($alt-div/tan:alt-div/@nests-in-leaf-divs = false())">
                    <xsl:apply-templates select="tei:div" mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="tei-milestones-to-divs">
                        <xsl:with-param name="alt-div" select="$alt-div" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </xsl:template>

    <xsl:template match="tei:div[tei:div]" mode="tan-tei-to-tan-t">
        <div>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="tei:div" mode="#current"/>
        </div>
    </xsl:template>

    <xsl:template match="tei:div[not(tei:div)]" mode="tan-tei-to-tan-t">
        <xsl:param name="alt-div" as="element()?" tunnel="yes"/>
        <div>
            <xsl:copy-of select="@n, @type, @ed-who, @ed-when"/>
            <xsl:choose>
                <xsl:when test="not(exists($alt-div))">
                    <xsl:apply-templates mode="convert-tei-leaf-div-content">
                        <xsl:with-param name="is-in-mixed-content" select="exists(*) and exists(text()[matches(., '\S')])"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="tei-milestones-to-divs">
                        <xsl:with-param name="alt-div" select="$alt-div" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="tei:ab[not(@type)] | tei:lg[not(@type)]" mode="convert-tei-leaf-div-content">
        <!-- Untyped anonymous blocks should be skipped, since they lack obvious semantics -->
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="*" mode="convert-tei-leaf-div-content">
        <xsl:param name="is-in-mixed-content" as="xs:boolean?"/>
        <xsl:variable name="has-mixed-content" select="exists(*) and exists(text()[matches(., '\S')])"/>
        <xsl:variable name="this-element-name" select="local-name()"/>
        <xsl:variable name="this-tan-voc-entry" select="$TAN-div-type-vocabulary//*[tan:name = ('tei ' || $this-element-name)]"/>
        <xsl:variable name="this-div-type" as="xs:string">
            <xsl:choose>
                <xsl:when test="exists(@type) and $this-element-name = ('ab', 'lg')">
                    <xsl:value-of select="@type"/>
                </xsl:when>
                <xsl:when test="exists($this-tan-voc-entry)">
                    <xsl:value-of select="$this-tan-voc-entry[1]/tan:name[1]"/>
                </xsl:when>
                <xsl:when test="$this-element-name = 'l'">line</xsl:when>
                <xsl:when test="$this-element-name = 'quote' and not($is-in-mixed-content)">block-quote</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$this-element-name"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="diagnostics-on" select="false()"/>
        <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, template mode convert-tei-leaf-div-content'"/>
            <xsl:message select="'This element name: ' || $this-element-name"/>
            <xsl:message select="'Is in mixed content: ', $is-in-mixed-content"/>
            <xsl:message select="'Has mixed content: ', $has-mixed-content"/>
            <xsl:message select="'This TAN-voc entry:', $this-tan-voc-entry"/>
            <xsl:message select="'This div type: ' || $this-div-type"/>
        </xsl:if>
        
        <xsl:choose>
            <xsl:when
                test="$this-element-name = $milestoneLike-element-info/tan:group/tan:element/@name"/>
            <xsl:otherwise>
                <div type="{replace($this-div-type, ' ', '_')}" n="{@n}">
                    <xsl:choose>
                        <xsl:when test="$has-mixed-content">
                            <xsl:value-of select="normalize-space(string-join(.//text(), ''))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="#current">
                                <xsl:with-param name="is-in-mixed-content" select="$has-mixed-content"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="tei-milestones-to-divs">
        <xsl:param name="alt-div" as="element()?" tunnel="yes"/>
        <xsl:variable name="pass-1" as="item()*">
            <xsl:apply-templates mode="process-tei-milestones">
                <xsl:with-param name="alt-div" select="$alt-div" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:copy-of select="tan:sequence-to-tree($pass-1)"/>
    </xsl:template>
    
    <xsl:template match="*" mode="process-tei-milestones">
        <xsl:param name="alt-div" as="element()" tunnel="yes"/>
        <xsl:variable name="this-element-name" select="local-name()"/>
        <xsl:variable name="this-milestone-type" select="(@type, 'untyped')[1]"/>
        <!-- As above, we need to exclude cases where @unit refers to reference numbers, not types of units -->
        <xsl:variable name="this-milestone-unit"
            select="
                if (exists(@n)) then
                    @unit
                else
                    ()"
        />
        <xsl:variable name="this-alt-div"
            select="
                $alt-div[@type = $this-milestone-type]/tan:alt-div[@element-name = $this-element-name 
                and (if (exists($this-milestone-unit)) then
                    @unit = $this-milestone-unit
                else
                    true())]"
        />
        <xsl:variable name="lb-alt-div" select="$alt-div/tan:alt-div[@element-name = 'lb']"/>
        <xsl:choose>
            <xsl:when test="exists($this-alt-div)">
                <xsl:variable name="this-div-type" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="$this-element-name = 'milestone' and exists(@n)">
                            <xsl:value-of select="(@unit, @type)[1]"/>
                        </xsl:when>
                        <xsl:when test="$this-element-name = 'milestone'">
                            <!-- cases where a user has decided to let @unit do the work that should be given to @n -->
                            <xsl:value-of select="(@type, @unit)[1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$milestoneLike-element-info/tan:group/tan:element[@name = $this-element-name]/@idref"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="this-n" select="(@n, @unit)[1]"/>
                <div type="{$this-div-type}" n="{$this-n}">
                    <xsl:copy-of select="$this-alt-div/@level"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="preceding-element" select="preceding-sibling::*[1]"/>
                <xsl:if
                    test="
                        $add-implicit-lb and exists($lb-alt-div) and parent::tei:div[not(tei:div)]
                        and not(local-name($preceding-element) = $milestoneLike-element-info//@name)">
                    <div type="line" n="">
                        <xsl:copy-of select="$lb-alt-div/@level"/>
                    </div>
                </xsl:if>
                <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- INPUT -->
    <xsl:param name="input-items" select="$primary-conversion, $secondary-conversions"
        as="document-node()+"/>
    <xsl:param name="input-base-uri" select="$doc-uri"/>

    <xsl:template match="tan:div-type[1]" mode="input-pass-1">
        <xsl:variable name="all-div-types-used" select="root()/tan:TAN-T/tan:body//tan:div/@type"/>
        <xsl:variable name="all-div-types-defined" select="../tan:div-type/@xml:id"/>
        <xsl:for-each select="distinct-values($all-div-types-used[not(. = $all-div-types-defined)])">
            <xsl:variable name="this-div-type" select="."/>
            <xsl:variable name="default-match"
                select="$div-type-glossary[tan:name = $this-div-type]"/>
            <xsl:variable name="tei-match"
                select="$div-type-glossary-for-tei-element[tan:name = concat('tei ', $this-div-type)]"/>
            <xsl:variable name="milestone-match"
                select="$milestoneLike-element-info/tan:group/tan:element[@idref = $this-div-type]/@which"/>
            <xsl:variable name="this-which" as="xs:string">
                <xsl:choose>
                    <xsl:when test="exists($default-match)">
                        <xsl:value-of select="$default-match/tan:name[1]"/>
                    </xsl:when>
                    <xsl:when test="exists($tei-match)">
                        <xsl:value-of select="$tei-match/tan:name[1]"/>
                    </xsl:when>
                    <xsl:when test="exists($milestone-match)">
                        <xsl:value-of select="$milestone-match"/>
                    </xsl:when>
                    <xsl:when test="matches(.,'folio')">folio</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <div-type xml:id="{.}" which="{$this-which}"/>
        </xsl:for-each>
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="tan:div | tan:body" mode="input-pass-1">
        <xsl:param name="duplicate-ns" as="xs:string*"/>
        <xsl:param name="majority-type" as="xs:string*"/>
        <xsl:variable name="children-duplicate-ns" select="tan:duplicate-items(tan:div/@n)"/>
        <xsl:variable name="children-majority-type" select="tan:most-common-item(reverse(tan:div/@type))"/>
        <xsl:variable name="this-div-type" select="@type"/>
        <xsl:variable name="this-n-val" as="xs:string?">
            <xsl:choose>
                <xsl:when test="not(exists(@n))"/>
                <xsl:when test="string-length(@n) lt 1 and @type = $majority-type">
                    <xsl:value-of
                        select="count(preceding-sibling::tan:div[@type = $this-div-type]) + 1"/>
                </xsl:when>
                <xsl:when test="string-length(@n) lt 1">
                    <xsl:variable name="preceding-types" select="preceding-sibling::tan:div[@type = $this-div-type]"/>
                    <xsl:value-of
                        select="
                            concat($this-div-type, if (exists($preceding-types)) then
                                string(count($preceding-types) + 1)
                            else
                                ())"
                    />
                </xsl:when>
                <xsl:when test="@n = $duplicate-ns and not(@type = $majority-type)">
                    <xsl:value-of
                        select="
                            concat(replace(@type, 'tei-', ''), if (@n = '1') then
                                ()
                            else
                                @n)"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@n"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@* except @n"/>
            <xsl:if test="exists($this-n-val)">
                <xsl:attribute name="n" select="$this-n-val"/>
            </xsl:if>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="duplicate-ns" select="$children-duplicate-ns"/>
                <xsl:with-param name="majority-type" select="$children-majority-type"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>


    <!-- input pass 2 -->

    <xsl:param name="suffixes-for-multiple-output" as="xs:string+">
        <xsl:value-of select="'.ref-logical-native'"/>
        <xsl:for-each select="$input-pass-1[position() gt 1]">
            <xsl:variable name="this-pos" select="position()"/>
            <xsl:variable name="this-analysis" select="$milestoneLike-analysis[$this-pos]"/>
            <xsl:variable name="is-ambiguous"
                select="
                    some $i in $this-analysis//@element-name
                        satisfies count($milestoneLike-analysis//tan:alt-div[@element-name = $i]) gt 1"
            />
            <xsl:variable name="this-qualifier"
                select="
                    if ($is-ambiguous) then
                        concat($this-analysis/@type, '-')
                    else
                        ()"
            />
            <xsl:variable name="most-common-leaf-div-type"
                select="tan:most-common-item(root()/tan:TAN-T/tan:body//tan:div[not(tan:div)]/@type)"/>
            <xsl:variable name="mcldt-def"
                select="root()/tan:TAN-T/tan:head/tan:vocabulary-key/tan:div-type[@xml:id = $most-common-leaf-div-type]"/>
            <xsl:if test="not(exists($mcldt-def))">
                <xsl:message>Building suffixes failed</xsl:message>
                <xsl:message select="root()/tan:TAN-T/tan:body//tan:div[not(tan:div)]/@type" terminate="yes"></xsl:message>
            </xsl:if>
            <!--<xsl:variable name="this-gloss" select="tan:glossary($mcldt-def)"/>-->
            <xsl:variable name="this-gloss" select="$mcldt-def"/>
            <xsl:value-of
                select="
                    concat('.ref-',if ($this-gloss/../@type = ('scriptum', 'physical', 'material')) then
                        'scriptum'
                    else
                        'logical', '-native-by-', $this-qualifier, $most-common-leaf-div-type)"
            />
        </xsl:for-each>
    </xsl:param>
    <xsl:variable name="these-see-alsos" as="element()*">
        <xsl:if test="count($milestoneLike-analysis) gt 0">
            <see-also relationship="resegmented">
                <IRI>
                    <xsl:value-of select="$this-doc/tei:TEI/@id"/>
                </IRI>
                <xsl:copy-of select="$this-doc/tei:TEI/tan:head/tan:name[1]"/>
                <location href="{$doc-uri}" accessed-when="{current-date()}"/>
            </see-also>
            <xsl:for-each select="$suffixes-for-multiple-output">
                <xsl:variable name="this-pos" select="position()"/>
                <xsl:variable name="this-suffix" select="."/>
                <see-also relationship="resegmented">
                    <IRI>
                        <xsl:value-of select="concat($this-doc/tei:TEI/@id, .)"/>
                    </IRI>
                    <name>
                        <xsl:value-of select="$this-doc/tei:TEI/tan:head/tan:name[1]"/>
                        <xsl:text> as TAN-T </xsl:text>
                        <xsl:choose>
                            <xsl:when test="$this-pos = 1">
                                <xsl:text>following original leaf divs and converting nesting elements to &lt;div>s</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="this-milestone-analysis"
                                    select="$milestoneLike-analysis[$this-pos - 1]"/>
                                <xsl:text>resegmenting the text via </xsl:text>
                                <xsl:value-of
                                    select="string-join($this-milestone-analysis/(@type, tan:alt-div/(@element-name, @unit)), ' ')"
                                />
                            </xsl:otherwise>
                        </xsl:choose>
                    </name>
                    <location
                        href="{replace($output-url-resolved, '(.+)(\.[^\.]+)$', concat('$1', $this-suffix, '$2'))}"
                        accessed-when="{current-date()}"/>
                </see-also>
            </xsl:for-each>
        </xsl:if>
    </xsl:variable>

    <xsl:param name="input-pass-2" as="item()*">
        <xsl:for-each select="$input-pass-1">
            <xsl:variable name="this-pos" select="position()"/>
            <xsl:apply-templates select="." mode="input-pass-2">
                <xsl:with-param name="new-doc-id"
                    select="concat($doc-id, $suffixes-for-multiple-output[$this-pos])" tunnel="yes"
                />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:param>

    <xsl:template match="/*" mode="input-pass-2">
        <xsl:param name="new-doc-id" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@* except @id"/>
            <xsl:attribute name="id" select="$new-doc-id"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tan:source" mode="input-pass-2">
        <xsl:param name="new-doc-id" tunnel="yes"/>
        <xsl:copy-of select="."/>
        <xsl:copy-of select="$these-see-alsos[not(tan:IRI = $new-doc-id)]"/>
    </xsl:template>

    <xsl:variable name="names-of-attributes-allowed-in-tan-div" as="xs:string+"
        select="('n', 'type', 'help', 'xml:lang', 'ed-when', 'ed-who', 'include')"/>
    <xsl:template match="tan:div[tan:div]" mode="input-pass-2">
        <xsl:copy>
            <xsl:copy-of select="@*[name(.) = $names-of-attributes-allowed-in-tan-div]"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tan:div[not(tan:div)]" mode="input-pass-2">
        <xsl:choose>
            <xsl:when
                test="
                    some $i in text()
                        satisfies matches($i, '\S')">
                <xsl:copy>
                    <xsl:copy-of select="@*[name(.) = $names-of-attributes-allowed-in-tan-div]"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment><xsl:value-of select="tan:xml-to-string(tan:shallow-copy(.))"/></xsl:comment>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tan:div/text()" mode="input-pass-2">
        <xsl:value-of select="tan:normalize-div-text(.)"/>
    </xsl:template>

    <!-- Template -->
    <xsl:param name="template-infused-with-revised-input" select="$input-pass-2"/>

    <!-- Output -->
    <xsl:param name="output-url-relative-to-actual-input" as="xs:string?"
        select="concat(replace(tan:cfn(/), 'tan-tei', 'tan-t'), '-', $today-iso, '.xml')"/>

    <xsl:template match="/" use-when="$output-diagnostics-on">
        <diagnostics>
            <milestone-like-elements><xsl:copy-of select="$milestoneLike-elements"/></milestone-like-elements>
            <milestone-like-analysis><xsl:copy-of select="$milestoneLike-analysis"/></milestone-like-analysis>
            <suffixes-for-multiple-output><xsl:value-of select="$suffixes-for-multiple-output"/></suffixes-for-multiple-output>
            <see-alsos><xsl:copy-of select="$these-see-alsos"/></see-alsos>
            <primary-conversion><xsl:copy-of select="$primary-conversion"/></primary-conversion>
            <secondary-conversions><xsl:copy-of select="$secondary-conversions"/></secondary-conversions>
            <input-pass-1><xsl:copy-of select="$input-pass-1"/></input-pass-1>
            <input-pass-2><xsl:copy-of select="$input-pass-2"/></input-pass-2>
            <template-url-resolved><xsl:copy-of select="$template-url-resolved"/></template-url-resolved>
            <template-infused-with-revised-input><xsl:copy-of select="$template-infused-with-revised-input[1]"/></template-infused-with-revised-input>
            <infused-template-revised><xsl:copy-of select="$infused-template-revised"/></infused-template-revised>
            <output-url-resolved><xsl:copy-of select="$output-url-resolved"/></output-url-resolved>
        </diagnostics>
    </xsl:template>

</xsl:stylesheet>
