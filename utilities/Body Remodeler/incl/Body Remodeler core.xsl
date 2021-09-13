<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">

    <!-- Core application for remodeling a text. -->

    <xsl:import href="../../../functions/TAN-function-library.xsl"/>
    

    <!-- About this stylesheet -->
    
    <xsl:param name="tan:stylesheet-iri"
        select="'tag:textalign.net,2015:stylesheet:remodel-text'"/>
    <xsl:param name="tan:stylesheet-name" select="'Body Remodeler'"/>
    <xsl:param name="tan:stylesheet-activity"
        select="'remodels a text to resemble the existing div structure of the body of a TAN-T text'"
    />
    <xsl:param name="tan:stylesheet-description">Suppose you have a text in a well-structured TAN-T
        file, and you want to use it to model the structure of another version of that same work.
        This application will take the input, and infuse the text into the structure of the model,
        using the proportionate lengths of the model's text as a guide where to break the new text.
        Any two versions of a single work, particularly translations, paraphrases, and other
        versions, rarely correlate. A translator may begin a work being relatively verbose, and
        become more economical in later parts. Such uneven correlation means that one-to-one
        modeling is not a good strategy for aligning the new text. Rather, one should start with the
        topmost structures and working progressively toward the smallest levels. Body Remodeler
        supports such an incremental approach, and allows you to restrict the remodeling activity to
        certain parts of a text. When used in tandem with the TAN editing tools for Oxygen, which
        allow you to push and pull words, clauses, and sentences from one leaf div to another, you
        will find that Body Builder can save you hours of editorial work. </xsl:param>

    <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string">preferably a TAN-T or TAN-TEI
        file</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string">a TAN-T or TAN-TEI file
        that has model div and reference system</xsl:param>
    <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string">the model, with its div
        structure intact, but the text replaced with the text of the input, allocated
        to the new div structure proportionate to the model's text length</xsl:param>
    <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string">none</xsl:param>

    <xsl:param name="tan:stylesheet-url" select="static-base-uri()"/>
    <xsl:param name="tan:stylesheet-change-message"
        select="'Remodeling ' || $tan:doc-uri || ' against ' || $current-model-uri-resolved"/>
    <xsl:param name="tan:stylesheet-change-log">
        <change xmlns="tag:textalign.net,2015:ns" who="kalvesmaki" when="2021-07-13">Edited,
            prepared for TAN 2021 release.</change>
    </xsl:param>
    <xsl:param name="tan:stylesheet-is-core-tan-application" select="true()"/>
    <xsl:param name="tan:stylesheet-to-do-list">
        <to-do xmlns="tag:textalign.net,2015:ns">
            <comment who="kalvesmaki" when="2021-07-13">Support the complete-the-square method
                (model has a redivision that matches the input's div structure)</comment>
            <comment who="kalvesmaki" when="2021-07-13">Test, troubleshoot against various TEI models</comment>
        </to-do>
    </xsl:param>


    <!-- Normalize the parameters -->
    
    <xsl:variable name="br-material-regex" as="xs:string" select="
            if (tan:regex-is-valid($break-text-at-material-divs-regex)) then
                $break-text-at-material-divs-regex
            else
                $tan:word-end-regex"/>
    <xsl:variable name="br-logical-regex" as="xs:string" select="
            if (tan:regex-is-valid($break-text-at-logical-divs-regex)) then
                $break-text-at-logical-divs-regex
            else
                $tan:clause-end-regex"/>
    
    <xsl:variable name="break-at-regex" select="
            if ($model-has-scriptum-oriented-reference-system) then
                $br-material-regex
            else
                $br-logical-regex"/>
    
    <xsl:variable name="current-model-uri-resolved" as="xs:anyURI?"
        select="resolve-uri($model-uri-relative-to-catalyzing-input, $tan:doc-uri)"/>
    
    <xsl:variable name="check-model-top-attr-n" as="xs:boolean"
        select="tan:regex-is-valid($exclude-from-model-top-level-divs-with-attr-n-values-regex) 
        and string-length($exclude-from-model-top-level-divs-with-attr-n-values-regex) gt 0"
    />
    <xsl:variable name="check-model-attr-type" as="xs:boolean"
        select="tan:regex-is-valid($exclude-from-model-divs-with-attr-type-values-regex)
        and string-length($exclude-from-model-divs-with-attr-type-values-regex) gt 0"/>
    
    <xsl:variable name="check-input-top-attr-n" as="xs:boolean"
        select="tan:regex-is-valid($exclude-from-input-top-level-divs-with-attr-n-values-regex) 
        and string-length($exclude-from-input-top-level-divs-with-attr-n-values-regex) gt 0"
    />
    <xsl:variable name="check-input-attr-type" as="xs:boolean"
        select="tan:regex-is-valid($exclude-from-input-divs-with-attr-type-values-regex)
        and string-length($exclude-from-input-divs-with-attr-type-values-regex) gt 0"/>
    
    <xsl:variable name="check-div-level" as="xs:boolean"
        select="$preserve-matching-ref-structures-up-to-what-level gt 0"/>
    
    
    

    <!-- The application -->
    

    <!-- STEP 1: SET UP THE MODEL AND THE INPUT -->

    <!-- The model -->

    <xsl:variable name="current-model-doc" select="tan:open-file($current-model-uri-resolved)" as="document-node()?"/>
    <xsl:variable name="current-model-doc-resolved" select="tan:resolve-doc($current-model-doc)" as="document-node()?"/>
    <xsl:variable name="current-model-doc-norm"
        select="tan:normalize-tree-space($current-model-doc-resolved, true())" as="document-node()?"/>
    
    <!--<xsl:variable name="current-model-doc-expanded" select="tan:expand-doc($current-model-doc-resolved)"/>-->
    <xsl:variable name="current-model-doc-expanded-and-pruned" as="document-node()?">
        <xsl:apply-templates select="$current-model-doc-norm" mode="prune-model-doc"/>
    </xsl:variable>
    
    <xsl:mode name="prune-model-doc" on-no-match="shallow-copy"/>
    
    <xsl:template match="tan:div" mode="prune-model-doc">
       <xsl:choose>
            <xsl:when
                test="
                    parent::tan:body
                    and ($check-model-top-attr-n)
                    and matches(@n, $exclude-from-model-top-level-divs-with-attr-n-values-regex)"
            />
            <xsl:when
                test="
                    $check-model-attr-type
                    and matches(@type, $exclude-from-model-divs-with-attr-type-values-regex)"
            />
           <xsl:otherwise>
               <xsl:copy>
                   <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
               </xsl:copy>
           </xsl:otherwise>
       </xsl:choose> 
    </xsl:template>
    
    <xsl:variable name="current-model-body" as="element()*"
        select="$current-model-doc-expanded-and-pruned/(tan:TAN-T | tei:TEI/tei:text)/*:body"
    />
    
    
    
    <!-- The input -->
    
    <xsl:variable name="input-is-class-1" as="xs:boolean" select="exists(/tan:TAN-T) or exists(/tei:TEI)"/>
    <xsl:variable name="input-body-space-norm" as="element()" select="
            if ($input-is-class-1) then
                $tan:self-resolved-plus/(tan:TAN-T | tei:TEI/tei:text)/*:body
            else
                tan:normalize-tree-space(tan:stamp-q-id(/*), true())"/>
    
    <xsl:variable name="input-body-with-exceptions-bookmarked" as="element()">
        <xsl:apply-templates select="$input-body-space-norm" mode="bookmark-exceptions"/>
    </xsl:variable>
    
    <xsl:mode name="bookmark-exceptions" on-no-match="shallow-copy"/>
    
    <xsl:template match="*" mode="bookmark-exceptions">
        <xsl:param name="current-level" as="xs:integer" select="0"/>
        <xsl:variable name="is-top-level-div" select="$current-level eq 1"/>
        <xsl:choose>
            <xsl:when test="($check-input-attr-type and matches(@type, $exclude-from-input-divs-with-attr-type-values-regex))
                or ($is-top-level-div and $check-input-top-attr-n and matches(@n, $exclude-from-input-top-level-divs-with-attr-n-values-regex))">
                <_bookmark _level="1">
                    <xsl:copy-of select="@*"/>
                </_bookmark>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="current-level" select="$current-level + 1"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:variable name="input-body-pass-2" as="element()">
        <xsl:apply-templates select="$input-body-with-exceptions-bookmarked" mode="remodel-revision"/>
    </xsl:variable>
    
    <xsl:mode name="remodel-revision" on-no-match="shallow-copy"/>
    
    <xsl:template match="*" mode="remodel-revision">
        <xsl:param name="current-level" as="xs:integer" select="0"/>
        <xsl:variable name="rebuild-this-content" as="xs:boolean" select="$current-level eq $preserve-matching-ref-structures-up-to-what-level"/>
        <xsl:variable name="these-refs" select="tan:get-ref(.)" as="xs:string*"/>
        
        <xsl:variable name="matching-model-divs" as="element()*" select="
                if ($current-level eq 0) then
                    $current-model-body/*:div
                else
                    key('tan:div-via-calculated-ref', $these-refs, $current-model-body)"/>
        <xsl:variable name="these-bookmarks" as="element()*" select="descendant::tan:_bookmark"/>
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$rebuild-this-content and not(exists($matching-model-divs))">
                    <xsl:message select="'Unable to find a counterpart in the model for refs ' || string-join($these-refs, '; ')"/>
                    <xsl:copy-of select="node()"/>
                </xsl:when>
                <xsl:when test="$rebuild-this-content">
                    <xsl:variable name="infusion-pass-1" as="element()*" select="tan:infuse-tree(string(.), $matching-model-divs, $break-at-regex)"/>
                    <xsl:choose>
                        <xsl:when test="exists($these-bookmarks)">
                            <xsl:message select="'Reinserting exemptions'"/>
                            <xsl:variable name="context-stamped" as="element()*" select="tan:stamp-tree-with-text-data(., true())"/>
                            <xsl:variable name="stamped-bookmarks" select="$context-stamped//tan:_bookmark" as="element()+"/>
                            <xsl:variable name="chops-to-make" as="xs:integer+" select="
                                    for $i in $stamped-bookmarks
                                    return
                                        xs:integer($i/@_pos)"/>
                            <xsl:variable name="infusion-pass-2-chopped"
                                as="map(xs:integer, item()*)"
                                select="tan:chop-tree($infusion-pass-1, $chops-to-make)"/>
                            
                            <!--<test06a>
                                <inf-1><xsl:copy-of select="$infusion-pass-1"/></inf-1>
                                <inf-2><xsl:copy-of select="tan:map-to-xml($infusion-pass-2-chopped)"/></inf-2>
                            </test06a>-->
                            
                            <xsl:for-each select="distinct-values((1, $chops-to-make))">
                                <xsl:sort/>
                                <xsl:variable name="this-chop" select="."/>
                                <xsl:variable name="these-bookmarks" select="$stamped-bookmarks[@_pos eq string($this-chop)]"/>
                                <xsl:sequence
                                    select="key('tan:q-ref', $these-bookmarks/@q, $input-body-space-norm)"
                                />
                                <xsl:sequence select="$infusion-pass-2-chopped($this-chop)"/>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$infusion-pass-1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="current-level" select="$current-level + 1"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    
    
    <xsl:variable name="input-body-pass-3" as="element()">
        <xsl:apply-templates select="$input-body-pass-2" mode="clean-up-infusion"/>
    </xsl:variable>
    
    
    <xsl:mode name="clean-up-infusion" on-no-match="shallow-copy"/>
    
    <xsl:template match="@q" mode="clean-up-infusion"/>
    
    <xsl:template match="*[@orig-n]" mode="clean-up-infusion">
        <xsl:copy>
            <xsl:copy-of select="@* except (@n | @orig-n | @q)"/>
            <xsl:attribute name="n" select="@orig-n"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    
    <!-- Restore output -->
    
    <xsl:variable name="output-pass-1" as="document-node()">
        <xsl:choose>
            <xsl:when test="$input-is-class-1">
                <xsl:apply-templates select="/" mode="output-pass-1">
                    <xsl:with-param name="new-body" tunnel="yes" select="$input-body-pass-3"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$current-model-doc" mode="output-pass-1">
                    <xsl:with-param name="new-body" tunnel="yes" select="$input-body-pass-3"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    <xsl:mode name="output-pass-1" on-no-match="shallow-copy"/>
    <xsl:mode name="output-pass-1-indent" on-no-match="shallow-copy"/>
    
    <xsl:template match="/tan:TAN-T" mode="output-pass-1">
        <xsl:param name="new-body" tunnel="yes" as="element()"/>
        <xsl:variable name="must-convert-to-tan-tei" select="exists($new-body/tei:*)" as="xs:boolean"/>
        
        <xsl:choose>
            <xsl:when test="$must-convert-to-tan-tei">
                <xsl:message select="'The model is a TAN-TEI file. To preserve all inner markup, the TAN-T file is being converted to TAN-TEI, and results will require attention.'"/>
                <xsl:variable name="empty-teiHeader" as="element()">
                    <teiHeader>
                        <fileDesc>
                            <titleStmt>
                                <title/>
                            </titleStmt>
                            <publicationStmt>
                                <p/>
                            </publicationStmt>
                            <sourceDesc>
                                <p/>
                            </sourceDesc>
                        </fileDesc>
                    </teiHeader>
                </xsl:variable>
                <TEI xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="tan:copy-indentation($empty-teiHeader, tan:head[1])"/>
                    <xsl:apply-templates mode="#current">
                        <xsl:with-param name="convert-to-tei" as="xs:boolean" tunnel="yes" select="true()"/>
                    </xsl:apply-templates>
                </TEI>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template match="*:body" mode="output-pass-1">
        <xsl:param name="new-body" tunnel="yes" as="element()"/>
        <xsl:param name="convert-to-tei" tunnel="yes" as="xs:boolean" select="false()"/>

        <xsl:variable name="average-indentation" select="avg(tan:indent-value(*:div)) idiv 2" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$convert-to-tei">
                <text xmlns="http://www.tei-c.org/ns/1.0">
                    <body>
                        <xsl:copy-of select="$new-body/@*"/>
                        <xsl:apply-templates select="$new-body/node()" mode="output-pass-1-indent">
                            <xsl:with-param name="average-indentation" as="xs:integer" tunnel="yes" select="$average-indentation"/>
                            <xsl:with-param name="depth" as="xs:integer" select="2"/>
                        </xsl:apply-templates>
                        
                    </body>
                </text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="$new-body/@*"/>
                    <xsl:apply-templates select="$new-body/node()" mode="output-pass-1-indent">
                        <xsl:with-param name="average-indentation" as="xs:integer" tunnel="yes" select="$average-indentation"/>
                        <xsl:with-param name="depth" as="xs:integer" select="2"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
   
    <xsl:template match="@_removed" mode="output-pass-1-indent"/> 
    
    <xsl:template match="*" mode="output-pass-1-indent">
        <xsl:param name="average-indentation" as="xs:integer?" tunnel="yes" select="0"/>
        <xsl:param name="depth" as="xs:integer" select="2"/>
        <xsl:copy-of select="'&#xa;' || tan:fill(' ', $average-indentation * $depth)"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current">
                <xsl:with-param name="depth" select="$depth + 1"/>
            </xsl:apply-templates>
        </xsl:copy>
        <xsl:if test="not(exists(following-sibling::node()))">
            <xsl:copy-of select="'&#xa;' || tan:fill(' ', $average-indentation * ($depth - 1))"/>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:variable name="output-pass-2" as="document-node()" select="tan:update-TAN-change-log($output-pass-1)"/>
    

    
    <!-- RESULT TREE -->
    <xsl:param name="output-diagnostics-on" static="yes" select="false()"/>
    <xsl:output indent="yes" use-when="$output-diagnostics-on"/>
    <xsl:template match="/" priority="1" use-when="$output-diagnostics-on">
        <xsl:variable name="text-in" as="xs:string" select="string($input-body-space-norm)"/>
        <xsl:variable name="text-out" as="xs:string" select="string($input-body-pass-3)"/>
        <xsl:variable name="text-has-been-preserved" as="xs:boolean" select="$text-in eq $text-out"/>
        <xsl:variable name="text-diff" as="element()" select="tan:diff($text-in, $text-out, false())"/>
        <xsl:message
            select="'Using diagnostic output for application ' || $tan:stylesheet-name || ' (' || static-base-uri() || ')'"
        />
        <xsl:message select="'Is the output text identical to the normalized input text?', $text-has-been-preserved"/>
        <diagnostics>
            <model-uri-relative-to-catalyzing-input><xsl:sequence select="$model-uri-relative-to-catalyzing-input"></xsl:sequence></model-uri-relative-to-catalyzing-input>
            <current-model-doc-norm><xsl:copy-of select="$current-model-doc-norm"/></current-model-doc-norm>
            <current-model-doc-pruned><xsl:copy-of select="$current-model-doc-expanded-and-pruned"/></current-model-doc-pruned>
            <current-model-body><xsl:copy-of select="$current-model-body"/></current-model-body>
            <input-class-1><xsl:sequence select="$input-is-class-1"></xsl:sequence></input-class-1>
            <input-body-space-norm><xsl:sequence select="$input-body-space-norm"></xsl:sequence></input-body-space-norm>
            <input-body-exc-bookmarked><xsl:sequence select="$input-body-with-exceptions-bookmarked"/></input-body-exc-bookmarked>
            <input-body-pass-2><xsl:sequence select="$input-body-pass-2"/></input-body-pass-2>
            <input-body-pass-3><xsl:sequence select="$input-body-pass-3"/></input-body-pass-3>
            <text-has-been-preserved><xsl:copy-of select="$text-has-been-preserved"/></text-has-been-preserved>
            <xsl:if test="not($text-has-been-preserved)">
                <text-diff><xsl:copy-of select="$text-diff"/></text-diff>    
            </xsl:if>
            
            <output-pass-1><xsl:copy-of select="$output-pass-1"/></output-pass-1>
            <output-pass-2><xsl:copy-of select="$output-pass-2"/></output-pass-2>
            
        </diagnostics>
    </xsl:template>
    <xsl:template match="/">
        <xsl:message select="$tan:stylesheet-change-message"/>
        <xsl:message
            select="
                'Model reference system is indicated to be ' || (if ($model-has-scriptum-oriented-reference-system) then
                    'scriptum-oriented'
                else
                    'logical') || '. Allowing breaks only at the end of the following regular expression: ' || $break-at-regex"
        />
        <xsl:choose>
            <xsl:when test="$check-model-attr-type">
                <xsl:message
                    select="'Excluding model div types matching ' || $exclude-from-model-divs-with-attr-type-values-regex"
                />
            </xsl:when>
            <xsl:when test="$check-model-attr-type and string-length($exclude-from-model-divs-with-attr-type-values-regex) gt 0">
                <xsl:message
                    select="$exclude-from-model-divs-with-attr-type-values-regex || ' is not a valid regular expression.'"
                />
            </xsl:when>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="$check-model-top-attr-n">
                <xsl:message
                    select="'Excluding model div types matching ' || $exclude-from-model-top-level-divs-with-attr-n-values-regex"
                />
            </xsl:when>
            <xsl:when test="$check-model-top-attr-n and string-length($exclude-from-model-top-level-divs-with-attr-n-values-regex) gt 0">
                <xsl:message
                    select="$exclude-from-model-top-level-divs-with-attr-n-values-regex || ' is not a valid regular expression.'"
                />
            </xsl:when>
        </xsl:choose>
        
        <xsl:if test="$input-is-class-1">
            <xsl:if test="$check-model-top-attr-n"><xsl:message select="'Excluding top level input divs with @n matching ' || $exclude-from-input-top-level-divs-with-attr-n-values-regex"/></xsl:if>
            <xsl:if test="$check-div-level"><xsl:message select="'Preserving input div structures up to level ' || xs:string($preserve-matching-ref-structures-up-to-what-level)"/></xsl:if>
        </xsl:if>

        <xsl:apply-templates select="$output-pass-2" mode="tan:doc-nodes-on-new-lines"/>

    </xsl:template>

</xsl:stylesheet>
