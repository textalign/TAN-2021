<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
   exclude-result-prefixes="#all"
   version="3.0">
   
   <!-- Supporting stylesheet, to focus on changes to docx input. -->
   
   <!-- FORMAT TREE -->
   <!-- The format tree is a summary of the formats that are available in a given docx file. We exclude
      the docx component that treats effects. -->
   
   <xsl:variable name="input-to-format-tree" as="document-node()*">
      <xsl:apply-templates
         select="$source-input-files[w:styles][not(matches(*/@_archive-path, 'stylesWithEffects'))]"
         mode="docx-style-tree"/>
   </xsl:variable>
   
   <!-- Find all the possible values in the given docx files, except those that
      have #, which is reserved for comments. -->
   <xsl:variable name="input-formats-available" as="xs:string*" select="
         sort(distinct-values(($input-to-format-tree//tan:format,
         $input-to-main-text-and-format-tree//tan:format))[not(contains(., '#'))])"/>
   
   <xsl:variable name="html-color-file" as="document-node()"
      select="doc('../../../functions/html/TAN-fn-html-colors.xsl')"/>
   
   <!-- The docx style tree consists of various elements, but especially important are any
      descendant <format>s, which dictate the properties that can be accessed by the parameters
      in the TAN application. -->
   <xsl:mode name="docx-style-tree" on-no-match="shallow-skip"/>
   
   <xsl:template match="document-node()" mode="docx-style-tree">
      <xsl:document>
         <xsl:apply-templates mode="#current"/>
      </xsl:document>
   </xsl:template>
   
   <xsl:template match="w:styles | w:pPr | w:rPr" mode="docx-style-tree">
      <xsl:element name="{local-name(.)}" namespace="tag:textalign.net,2015:ns">
         <xsl:apply-templates select="@* | node()" mode="#current"/>
      </xsl:element>
   </xsl:template>
   <xsl:template match="w:style" mode="docx-style-tree">
      <style>
         <xsl:if test="exists(@w:styleId)">
            <xsl:attribute name="id" select="@w:styleId"/>
         </xsl:if>
         <xsl:apply-templates select="@*" mode="#current"/>
         <xsl:apply-templates mode="#current"/>
      </style>
   </xsl:template>
   <xsl:template match="w:style/@w:type" priority="-1" mode="docx-style-tree">
      <type>
         <xsl:value-of select="lower-case(.)"/>
      </type>
   </xsl:template>
   
   <xsl:template match="w:basedOn/@w:val" mode="docx-style-tree">
      <format>
         <xsl:value-of select="'basedon=' || lower-case(.)"/>
      </format>
   </xsl:template>
   
   <xsl:template match="w:pStyle/@w:val" mode="docx-style-tree">
      <!-- Here and below we insert para="true" to identify every format that necessarily affects 
         every character in the paragraph. -->
      <format para="true">
         <xsl:value-of select="lower-case(.)"/>
      </format>
      <format para="true">
         <xsl:value-of select="'pstyle=' || lower-case(.)"/>
      </format>
   </xsl:template>
   
   <xsl:template match="w:b[not(@w:val eq '0')]" mode="docx-style-tree">
      <format>bold</format>
   </xsl:template>
   <xsl:template match="w:b[@w:val eq '0']" mode="docx-style-tree">
      <nixformat>bold</nixformat>
   </xsl:template>
   <xsl:template match="w:i[not(@w:val eq '0')]" mode="docx-style-tree">
      <format>italic</format>
   </xsl:template>
   <xsl:template match="w:i[@w:val eq '0']" mode="docx-style-tree">
      <nixformat>italic</nixformat>
   </xsl:template>
   <xsl:template match="w:jc[@w:val = 'center']" mode="docx-style-tree">
      <!-- para="true" because you can't have a paragraph that has some
         characters centered but others not. -->
      <format para="true">center</format>
   </xsl:template>
   <xsl:template match="w:jc[@w:val = 'right']" mode="docx-style-tree">
      <format para="true">right</format>
   </xsl:template>
   <xsl:template match="w:jc[@w:val = 'left']" mode="docx-style-tree">
      <format para="true">left</format>
   </xsl:template>
   <xsl:template match="w:sz[@w:val]" mode="docx-style-tree">
      <xsl:variable name="this-size" select="xs:integer(@w:val) div 2"/>
      <format>
         <xsl:value-of select="$this-size || 'pt'"/>
      </format>
      <format>
         <xsl:value-of select="'fontsize=' || $this-size"/>
      </format>
   </xsl:template>
   <xsl:template match="w:lang/@w:val" mode="docx-style-tree">
      <format>
         <xsl:value-of select="'lang=' || lower-case(.)"/>
      </format>
   </xsl:template>
   <xsl:template match="w:rFonts" mode="docx-style-tree">
      <xsl:for-each select="distinct-values((@w:ascii, @w:hAnsi))">
         <format>
            <xsl:value-of select="'font=' || replace(lower-case(.), '\s+', '')"/>
         </format>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:template match="w:color/@w:val" mode="docx-style-tree">
      <xsl:variable name="color-integers" as="xs:integer*" select="
            if (matches(., '^[a-fA-F0-9]{6}$')) then
               (tan:hex-to-dec(substring(., 1, 2)), tan:hex-to-dec(substring(., 3, 2)), tan:hex-to-dec(substring(., 5, 2)))
            else
               ()"/>
      <xsl:variable name="select-value" as="xs:string" select="
         '(' || string-join((for $i in $color-integers
         return
         xs:string($i)), ', ') || ')'"/>
      <xsl:variable name="matching-entry" as="element()*"
         select="$html-color-file/*/xsl:variable[@select eq $select-value]"/>
      
      <format>
         <xsl:value-of select="lower-case(.)"/>
      </format>
      <format>
         <xsl:value-of select="'color=' || lower-case(.)"/>
      </format>
      <xsl:for-each select="$matching-entry">
         <format>
            <xsl:value-of select="replace(@name, 'tan:rgb-', '')"/>
         </format>
         <format>
            <xsl:value-of select="'color=' || replace(@name, 'tan:rgb-', '')"/>
         </format>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:template match="w:color/@w:themeColor" mode="docx-style-tree">
      <format>
         <xsl:value-of select="lower-case(.)"/>
      </format>
      <format>
         <xsl:value-of select="'color=' || lower-case(.)"/>
      </format>
   </xsl:template>
   
   
   
   <!-- TEXT AND FORMAT TREES -->
   
   <xsl:variable name="input-to-main-text-and-format-tree" as="document-node()*">
      <xsl:apply-templates select="$source-input-files" mode="docx-main-text-and-format-tree"/>
   </xsl:variable>
   
   <xsl:variable name="input-to-comment-text-and-format-tree" as="document-node()*">
      <xsl:if test="not($ignore-comments)">
         <xsl:apply-templates select="$source-input-files" mode="docx-comment-text-and-format-tree"/>
      </xsl:if>
   </xsl:variable>
   
   <xsl:mode name="docx-main-text-and-format-tree" on-no-match="text-only-copy"/>
   <xsl:mode name="docx-comment-text-and-format-tree" on-no-match="text-only-copy"/>
   
   <!-- By default, ignore docx components except for those specified. -->
   <xsl:template match="document-node()[@_archive-path]" mode="docx-main-text-and-format-tree docx-comment-text-and-format-tree"/>
   <xsl:template match="document-node()[w:document] | document-node()[*[not(@_archive-path)]]"
      mode="docx-main-text-and-format-tree">
      <xsl:variable name="this-base" select="*/@xml:base" as="xs:string?"/>
      <xsl:variable name="relevant-comments" as="document-node()?"
         select="$comments-of-interest[*/@xml:base eq $this-base]"/>
      <xsl:document>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="relevant-comments" tunnel="yes" select="$relevant-comments"/>
         </xsl:apply-templates>
      </xsl:document>
   </xsl:template>
   <xsl:template match="document-node()[w:comments] | document-node()[*[not(@_archive-path)]]"
      mode="docx-comment-text-and-format-tree">
      <xsl:document>
         <xsl:apply-templates mode="#current"/>
      </xsl:document>
   </xsl:template>
   
   <xsl:template match="/*[@_archive-path] | w:pPr/w:tabs" priority="-1" 
      mode="docx-main-text-and-format-tree docx-comment-text-and-format-tree"/>
   <xsl:template match="/*[not(@_archive-path)] | w:document" mode="docx-main-text-and-format-tree">
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="/*[not(@_archive-path)] | w:comments | w:comment" mode="docx-comment-text-and-format-tree">
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="w:p" mode="docx-main-text-and-format-tree docx-comment-text-and-format-tree">
      <xsl:variable name="para-style-ids" as="xs:string*" select="w:pPr/w:pStyle/@w:val"/>
      <xsl:variable name="inherited-para-style-tree" as="element()?"
         select="($input-to-format-tree//tan:style[@id = $para-style-ids])[1]"/>
      <xsl:variable name="individual-para-style-tree" as="element()?">
         <xsl:apply-templates select="w:pPr" mode="docx-style-tree"/>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'predefined style trees: ', $inherited-para-style-tree"/>
         <xsl:message select="'individual para style tree: ', $individual-para-style-tree"/>
      </xsl:if>
      
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="inherited-para-style-tree" tunnel="yes" select="$inherited-para-style-tree"/>
         <xsl:with-param name="individual-para-style-tree" tunnel="yes" select="$individual-para-style-tree"/>
      </xsl:apply-templates>
      
      <!-- This applies formatting to the line feed, so will always come after the <text>
         that wraps the text of the paragraph. -->
      <text>
         <xsl:for-each select="$formats-of-interest">
            <xsl:variable name="this-format" as="xs:string" select="."/>
            <xsl:copy-of select="($inherited-para-style-tree, $individual-para-style-tree)//tan:format[. = $this-format]"/>
         </xsl:for-each>
         <!-- Add the line feed -->
         <xsl:text>&#xa;</xsl:text>
      </text>
      
   </xsl:template>
   
   <xsl:template match="w:r" mode="docx-main-text-and-format-tree docx-comment-text-and-format-tree">
      <xsl:variable name="range-style-tree" as="element()?">
         <xsl:apply-templates select="w:rPr" mode="docx-style-tree"/>
      </xsl:variable>
      <xsl:apply-templates mode="#current">
         <xsl:with-param name="range-style-tree" tunnel="yes" select="$range-style-tree"/>
      </xsl:apply-templates>
   </xsl:template>
   
   <xsl:template match="w:del" mode="docx-main-text-and-format-tree">
      <xsl:if test="not($ignore-docx-deletions)">
         <xsl:apply-templates mode="#current"/>
      </xsl:if>
   </xsl:template>
   <xsl:template match="w:ins" mode="docx-main-text-and-format-tree">
      <xsl:if test="not($ignore-docx-insertions)">
         <xsl:apply-templates mode="#current"/>
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="w:commentRangeStart | w:commentRangeEnd" mode="docx-main-text-and-format-tree">
      <xsl:param name="relevant-comments" as="document-node()?" tunnel="yes"/>
      <xsl:variable name="this-id" as="xs:string" select="@w:id"/>
      <xsl:variable name="matching-comments-of-interest" as="element()*" select="$relevant-comments/*/w:comment[@w:id eq $this-id]"/>
      <xsl:variable name="this-is-of-interest" as="xs:boolean" select="exists($matching-comments-of-interest)"/>
      <xsl:variable name="range-type" as="xs:string" select="lower-case(substring(local-name(.), 13))"/>
      
      <xsl:if test="not($ignore-comments)">
         <format range="{$range-type}">
            <xsl:value-of select="'comment=' || @w:id"/>
         </format>
         <xsl:for-each select="$matching-comments-of-interest">
            <format range="{$range-type}">
               <xsl:value-of select="'comment#' || @id"/>
            </format>
         </xsl:for-each>
      </xsl:if>
      
   </xsl:template>
   
   <xsl:template match="w:tab | w:t | w:br | w:noBreakHyphen | w:softHyphen" mode="docx-main-text-and-format-tree docx-comment-text-and-format-tree">
      <xsl:param name="inherited-para-style-tree" as="element()?" tunnel="yes"/>
      <xsl:param name="individual-para-style-tree" as="element()?" tunnel="yes"/>
      <xsl:param name="range-style-tree" as="element()*" tunnel="yes"/>
      
      <xsl:variable name="is-tab" as="xs:boolean" select="local-name(.) eq 'tab'"/>
      <xsl:variable name="is-line-feed" as="xs:boolean" select="local-name(.) eq 'br'"/>
      <xsl:variable name="is-nbhy" as="xs:boolean" select="local-name(.) eq 'noBreakHyphen'"/>
      <xsl:variable name="is-shy" as="xs:boolean" select="local-name(.) eq 'softHyphen'"/>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'para style tree: ', $inherited-para-style-tree"/>
      </xsl:if>
      
      <!--<xsl:variable name="style-trees" as="element()*" select="$inherited-para-style-tree, $range-style-tree"/>-->
      
      <text>
         <xsl:for-each select="$formats-of-interest">
            <xsl:variable name="this-format" as="xs:string" select="."/>
            <xsl:choose>
               <xsl:when test="exists($range-style-tree//tan:nixformat[text() eq $this-format])"/>
               <xsl:when test="exists($range-style-tree//tan:format[text() = $this-format])">
                  <format>
                     <xsl:value-of select="."/>
                  </format>
               </xsl:when>
               <xsl:when test="exists($individual-para-style-tree//tan:format[@para eq 'true'][text() = $this-format])">
                  <format>
                     <xsl:value-of select="."/>
                  </format>
               </xsl:when>
               <xsl:when test="exists($inherited-para-style-tree//tan:format[text() = $this-format])">
                  <format>
                     <xsl:value-of select="."/>
                  </format>
               </xsl:when>
            </xsl:choose>
         </xsl:for-each>
         <xsl:choose>
            <xsl:when test="$is-tab">
               <xsl:text>&#x9;</xsl:text>
            </xsl:when>
            <xsl:when test="$is-line-feed">
               <xsl:text>&#xd;</xsl:text>
            </xsl:when>
            <xsl:when test="$is-nbhy">
               <xsl:text>&#x2011;</xsl:text>
            </xsl:when>
            <xsl:when test="$is-shy">
               <xsl:text>&#xad;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </text>
   </xsl:template>
   
   
   <!-- Prune comments, to those of interest -->
   
   <xsl:variable name="comments-of-interest" as="document-node()*">
      <xsl:apply-templates select="$input-to-comment-text-and-format-tree"
         mode="mark-comments-of-interest"/>
   </xsl:variable>
   
   <xsl:mode name="mark-comments-of-interest" on-no-match="shallow-copy"/>
   
   <xsl:template match="w:comment" mode="mark-comments-of-interest">
      <xsl:variable name="context-comment" as="element()" select="."/>
      
      <xsl:variable name="relevant-markup-instructions" as="element()*">
         <xsl:iterate select="$comments-to-markup-normalized">
            
            <xsl:variable name="context-markup-element" as="element()" select="."/>
            <xsl:variable name="context-markup-top-level-maintext-anchor" as="element()?"
               select="$context-markup-element/*:maintext"/>
            <xsl:variable name="this-slices-start-only" as="xs:boolean"
               select="exists($context-markup-top-level-maintext-anchor) 
               and not(exists($context-markup-top-level-maintext-anchor/following-sibling::node()))"
            />
            <xsl:variable name="this-slices-end-only" as="xs:boolean"
               select="exists($context-markup-top-level-maintext-anchor) 
               and not(exists($context-markup-top-level-maintext-anchor/preceding-sibling::node()))"
            />
            <xsl:variable name="these-formats" as="xs:string*"
               select="tokenize(normalize-space(lower-case(@format)), ' ')"/>
            
            <xsl:variable name="these-markups-to-insert" as="element()*">
               <xsl:for-each-group select="$context-comment/tan:text" group-adjacent="
                     let $cur := .
                     return
                        if (count($these-formats) gt 0) then
                           (every $i in $these-formats
                              satisfies $i = $cur/tan:format)
                        else
                           true()">
                  <xsl:variable name="this-text" as="xs:string" select="string-join(current-group()/text())"/>
                  <xsl:analyze-string select="$this-text" regex="{$context-markup-element/@pattern}"
                     flags="{$context-markup-element/@flags}">
                     <xsl:matching-substring>
                        <xsl:choose>
                           <xsl:when test="
                                 (exists($context-markup-element/@exclude-pattern)
                                 and
                                 matches(., $context-markup-element/@exclude-pattern, ($context-markup-element/@flags, '')[1]))"
                           />
                           <xsl:otherwise>
                              <markup>
                                 <xsl:copy-of select="$context-markup-element/@*"/>
                                 <xsl:choose>
                                    <xsl:when test="$this-slices-start-only">
                                       <xsl:attribute name="slice" select="'start'"/>
                                    </xsl:when>
                                    <xsl:when test="$this-slices-end-only">
                                       <xsl:attribute name="slice" select="'end'"/>
                                    </xsl:when>
                                 </xsl:choose>
                                 <!-- This instruction sets up the replacement immediately, important to do now, while the regex 
                                    groups are still valent. -->
                                 <xsl:sequence
                                    select="tan:batch-replace-advanced(., $context-markup-element)"
                                 />
                              </markup>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:matching-substring>
                  </xsl:analyze-string>
               </xsl:for-each-group>
            </xsl:variable>

            <xsl:sequence select="$these-markups-to-insert"/>
            <xsl:choose>
               <xsl:when test="exists($these-markups-to-insert)">
                  <!-- Only one action allowed per comment. -->
                  <xsl:break/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:next-iteration/>
               </xsl:otherwise>
            </xsl:choose>
            
         </xsl:iterate>
      </xsl:variable>
      <xsl:variable name="this-is-a-match" as="xs:boolean" select="exists($relevant-markup-instructions)"/>
      
      <xsl:if test="$this-is-a-match">
         <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="id" select="generate-id(.)"/>
            <xsl:apply-templates mode="#current"/>
            <xsl:copy-of select="$relevant-markup-instructions"/>
         </xsl:copy>
      </xsl:if>
      <xsl:if test="not($this-is-a-match) and $report-ignored-comments">
         <xsl:message select="'[' || ancestor::*[@xml:base]/@xml:base || '] Comment ' || @w:id || ' ignored: ' || string(.)"/>
      </xsl:if>
   </xsl:template>
   
   
   
   <!-- Process the text and format tree, and deal with combining characters separated from their base character -->
   
   <!-- If there are multiple inputs, combine them, so there is a single run of text. -->
   <xsl:variable name="main-text-and-format-trees-fused" as="document-node()?">
      <xsl:apply-templates select="$input-to-main-text-and-format-tree[1]"
         mode="fuse-text-and-format-trees"/>
   </xsl:variable>
   
   <xsl:mode name="fuse-text-and-format-trees" on-no-match="shallow-copy"/>
   
   <xsl:template match="/*" mode="fuse-text-and-format-trees">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:apply-templates select="$input-to-main-text-and-format-tree[position() gt 1]/*/node()"
            mode="#current"/>
         <!--<xsl:copy-of select="node()"/>-->
         <!--<xsl:copy-of select="$input-to-main-text-and-format-tree[position() gt 1]/*/node()"/>-->
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:text" mode="fuse-text-and-format-trees">
      <xsl:variable name="following-combining-chars" as="xs:string?">
         <xsl:analyze-string select="following-sibling::tan:text[1]" regex="^\p{{M}}+">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="following-combining-chars" tunnel="yes" select="$following-combining-chars"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   <xsl:template match="tan:text/text()" mode="fuse-text-and-format-trees">
      <xsl:param name="following-combining-chars" tunnel="yes" as="xs:string?"/>
      <xsl:value-of select="replace(., '^\p{M}+', '') || $following-combining-chars"/>
   </xsl:template>
   
   
   <!-- The comment opening and closing anchors now need to be processed -->
   <xsl:variable name="main-text-and-format-trees-with-format-anchors-resolved" as="document-node()?">
      <xsl:apply-templates select="$main-text-and-format-trees-fused" mode="allocate-format-anchors"/>
   </xsl:variable>
   
   <xsl:mode name="allocate-format-anchors" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[tan:format[@range]]" mode="allocate-format-anchors">
      <xsl:copy copy-namespaces="no">
         <xsl:copy-of select="@*"/>
         <xsl:iterate select="node()">
            <xsl:param name="formats-to-insert" as="element()*"/>
            
            <xsl:variable name="this-val" as="xs:string" select="."/>
            <xsl:variable name="this-is-a-format" as="xs:boolean" select="exists(self::tan:format[@range])"/>
            
            <xsl:variable name="new-formats-to-insert" as="element()*">
               <xsl:choose>
                  <xsl:when test="not($this-is-a-format)">
                     <xsl:sequence select="$formats-to-insert"/>
                  </xsl:when>
                  <xsl:when test="@range = 'start'">
                     <xsl:sequence select="$formats-to-insert, ."/>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- A terminating format code gets dropped. -->
                     <xsl:sequence select="$formats-to-insert[not(. eq $this-val)]"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            
            <xsl:if test="not($this-is-a-format)">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:for-each select="$formats-to-insert">
                     <xsl:copy>
                        <xsl:value-of select="."/>
                     </xsl:copy>
                  </xsl:for-each>
                  <xsl:copy-of select="node()"/>
               </xsl:copy>
            </xsl:if>
            <xsl:next-iteration>
               <xsl:with-param name="formats-to-insert" select="$new-formats-to-insert"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:copy>
   </xsl:template>
   
   
   
   <!-- Then stamp the tree with @pos values. -->
   
   <xsl:variable name="main-text-and-format-tree-stamped" as="document-node()?" 
      select="tan:stamp-tree-with-text-data($main-text-and-format-trees-with-format-anchors-resolved, false(), 'format|markup', (), 1)"/>
   
   <xsl:variable name="input-docx-text-parts" as="xs:string*">
      <xsl:apply-templates select="$main-text-and-format-tree-stamped"
         mode="docx-text-and-format-stamped-tree-to-text"/>
   </xsl:variable>
   
   <xsl:mode name="docx-text-and-format-stamped-tree-to-text" on-no-match="text-only-copy"/>
   
   <!-- Ignore the format element -->
   <xsl:template match="tan:format" mode="docx-text-and-format-stamped-tree-to-text"/>
   
   <xsl:variable name="input-docx-text" as="xs:string?" select="string-join($input-docx-text-parts)"/>
   
   <xsl:variable name="input-docx-format-map" as="map(xs:integer, xs:string+)">
      <xsl:map>
         <xsl:apply-templates select="$main-text-and-format-tree-stamped"
            mode="docx-text-and-format-stamped-tree-to-format-map"/>
      </xsl:map>
   </xsl:variable>
   
   <xsl:mode name="docx-text-and-format-stamped-tree-to-format-map" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:text[tan:format]" mode="docx-text-and-format-stamped-tree-to-format-map">
      <xsl:variable name="context-pos" as="xs:integer" select="xs:integer(@_pos)"/>
      <xsl:variable name="context-len" as="xs:integer" select="xs:integer(@_len)"/>
      <!-- We use an initial # to designate markup ids -->
      <xsl:variable name="context-formats-and-markups" as="xs:string+" select="
            (for $i in tan:format
            return
               xs:string($i))"/>
      <xsl:for-each select="$context-pos to ($context-pos + $context-len - 1)">
         <xsl:map-entry key="." select="$context-formats-and-markups"/>
      </xsl:for-each>
   </xsl:template>
   
   
   
   
   <!-- DOCX REPLACEMENTS -->
   
   <xsl:function name="tan:batch-replace-docx" visibility="private" as="map(*)">
      <!-- Input: a map, consisting of two entries, one for text the other a map connecting
            integers to format styles; a sequence of elements specifying changes to be made -->
      <!-- Output: a map reflecting revisions -->
      <!-- This function was written to support the convert to TAN.xsl application, so follows
            arbitrary conventions adopted therein. Do not treat this as a function that can handle
            docx changes in the abstract. -->
      <xsl:param name="docx-input-map" as="map(*)"/>
      <xsl:param name="change-elements" as="element()+"/>
      
      <xsl:iterate select="$change-elements/descendant-or-self::*[@pattern]">
         <xsl:param name="docx-input-map-so-far" as="map(*)" select="$docx-input-map"/>
         
         <xsl:on-completion select="$docx-input-map-so-far"/>
         
         <xsl:variable name="current-change-element" select="." as="element()"/>
         
         <xsl:variable name="current-text" as="element()" select="$docx-input-map-so-far('text')"/>
         <xsl:variable name="current-format-map" as="map(xs:integer,xs:string+)" select="$docx-input-map-so-far('format')"/>
         <xsl:variable name="current-format-map-keys" as="xs:integer*" select="sort(map:keys($current-format-map))"/>
         <xsl:variable name="formats-expected" as="xs:string*"
            select="tokenize(normalize-space(lower-case(@format)), ' ')"/>
         <xsl:variable name="formats-excluded" as="xs:string*"
            select="tokenize(normalize-space(lower-case(@exclude-format)), ' ')"/>
         <!--<xsl:variable name="check-formats-first" as="xs:boolean" select="$current-change-element/@pattern eq '.+'
            and (exists($current-change-element/@format) or exists($current-change-element/@exclude-format))"/>-->
         
         <xsl:variable name="positions-disallowed" as="xs:integer*">
            <!-- Previously I had not(exists($formats-expected)) and exists($formats-excluded) but
            I'm not sure why the first branch existed. -->
            <xsl:if test="exists($formats-excluded)">
               <xsl:for-each select="$current-format-map-keys">
                  <xsl:variable name="this-key" as="xs:integer" select="."/>
                  <xsl:variable name="these-formats" as="xs:string+" select="$current-format-map($this-key)"/>
                  <xsl:if test="($these-formats = $formats-excluded)">
                     <xsl:sequence select="."/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:if>
         </xsl:variable>
         <xsl:variable name="positions-required" as="xs:integer*">
            <xsl:if test="exists($formats-expected)">
               <!-- We add a single integer, to signal to the next variable's template that there must be
                  a match. Otherwise, if the required format does not feature in the document, everything
                  will be considered fair game. -->
               <xsl:sequence select="0"/>
               <xsl:for-each select="$current-format-map-keys">
                  <xsl:variable name="this-key" as="xs:integer" select="."/>
                  <xsl:variable name="these-formats" as="xs:string+" select="$current-format-map($this-key)"/>
                  <xsl:if test="
                        ($these-formats = $formats-expected) 
                        and not($these-formats = $formats-excluded)
                        and not(. = $positions-disallowed)">
                     <xsl:sequence select="."/>
                  </xsl:if>
               </xsl:for-each>
            </xsl:if>
         </xsl:variable>
         
         <xsl:variable name="current-text-format-sequestered" as="element()" >
            <xsl:choose>
               <xsl:when test="exists($positions-required) or exists($positions-disallowed)">
                  <xsl:apply-templates select="$current-text" mode="sequester-formats">
                     <xsl:with-param name="positions-required" as="xs:integer*" tunnel="yes"
                        select="$positions-required"/>
                     <xsl:with-param name="positions-disallowed" as="xs:integer*" tunnel="yes"
                        select="$positions-disallowed"/>
                     <xsl:with-param name="must-match-a-format" as="xs:boolean" tunnel="yes"
                        select="exists($formats-expected)"/>
                  </xsl:apply-templates>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$current-text"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         
         
         <xsl:variable name="current-text-analyzed" as="element()">
            <xsl:apply-templates select="$current-text-format-sequestered" mode="analyze-current-text">
               <xsl:with-param name="current-change-element" tunnel="yes" select="$current-change-element"/>
            </xsl:apply-templates>
         </xsl:variable>
         
         
         <xsl:variable name="check-for-formats" as="xs:boolean" select="
            exists($current-text-analyzed/tan:match)
            and (exists($formats-expected) or exists($formats-excluded))"/>
         
         <xsl:variable name="current-text-analyzed-and-stamped" as="element()"
            select="tan:stamp-tree-with-text-data($current-text-analyzed, false(), 'replacement', (), 1)"
         />
         
         <xsl:variable name="analysis-checked-for-formats" as="element()">
            <xsl:choose>
               <xsl:when test="not($check-for-formats)">
                  <xsl:sequence select="$current-text-analyzed-and-stamped"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="$current-text-analyzed-and-stamped" mode="check-docx-string-formats">
                     <xsl:with-param name="format-map" tunnel="yes"
                        select="$current-format-map"/>
                     <xsl:with-param name="format-map-keys" tunnel="yes"
                        select="$current-format-map-keys"/>
                     <xsl:with-param name="formats-expected" tunnel="yes" as="xs:string*"
                        select="$formats-expected"/>
                     <xsl:with-param name="formats-excluded" tunnel="yes" as="xs:string*"
                        select="$formats-excluded"/>
                     <xsl:with-param name="positions-allowed" tunnel="yes" as="xs:integer*" select="$positions-required"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         
         <xsl:variable name="adjustments-to-make-to-format-map" as="map(xs:integer,xs:integer)">
            <xsl:map>
               <xsl:apply-templates select="$analysis-checked-for-formats"
                  mode="calculate-adjustments-to-format-map"/>
            </xsl:map>
         </xsl:variable>
         <xsl:variable name="adjustments-to-make-to-format-map-keys" as="xs:integer*"
            select="map:keys($adjustments-to-make-to-format-map)"/>
         
         <xsl:variable name="new-text" as="element()">
            <xsl:apply-templates select="$analysis-checked-for-formats"
               mode="calculate-text-replacement"/>
         </xsl:variable>
         
         <xsl:variable name="new-format-map" as="map(xs:integer,xs:string+)">
            <xsl:map>
               <xsl:iterate
                  select="sort(distinct-values(($current-format-map-keys, $adjustments-to-make-to-format-map-keys)))">
                  <xsl:param name="adjustment-amount" as="xs:integer" select="0"/>

                  <xsl:variable name="current-key" as="xs:integer" select="."/>
                  <xsl:variable name="new-adjustment" as="xs:integer"
                     select="($adjustments-to-make-to-format-map($current-key), 0)[1]"/>

                  <xsl:choose>
                     <xsl:when test="$new-adjustment eq 0">
                        <xsl:map-entry key="$current-key + $adjustment-amount"
                           select="$current-format-map($current-key)"/>
                     </xsl:when>
                     <xsl:when test="$new-adjustment gt 0">
                        <xsl:map-entry key="$current-key + $adjustment-amount"
                           select="$current-format-map($current-key)"/>
                        <xsl:for-each select="1 to $new-adjustment">
                           <xsl:map-entry key="$current-key + $adjustment-amount + ."
                              select="$current-format-map($current-key)"/>

                        </xsl:for-each>
                     </xsl:when>

                  </xsl:choose>

                  <xsl:next-iteration>
                     <xsl:with-param name="adjustment-amount"
                        select="$adjustment-amount + $new-adjustment"/>
                  </xsl:next-iteration>

               </xsl:iterate>
            </xsl:map>
         </xsl:variable>
         
         
         <xsl:variable name="new-docx-map" as="map(*)">
            <xsl:map>
               <xsl:map-entry key="'text'" select="$new-text"/>
               <xsl:map-entry key="'format'" select="$new-format-map"/>
            </xsl:map>
         </xsl:variable>
         
         <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="false()"/>
         <xsl:if test="$output-diagnostics-on">
            <xsl:message select="'Output diagnostics on, tan:batch-replace-docx()'"/>
            <xsl:message select="'Current change element: ', $current-change-element"/>
            <xsl:message select="'docx input map so far:', tan:trim-long-tree(tan:map-to-xml($docx-input-map-so-far, true()), 20, 100)"/>
            <xsl:message select="'positions required (count ' || count($positions-required) || '), first 20: ', subsequence($positions-required, 1, 20)"/>
            <xsl:message select="'positions disallowed (count ' || count($positions-disallowed) || '), first 20: ', subsequence($positions-disallowed, 1, 20)"/>
            <xsl:message select="'Current text, format-sequestered: ', tan:trim-long-tree($current-text-format-sequestered, 20, 100)"/>
            <xsl:message select="'Current text analyzed:', tan:trim-long-tree($current-text-analyzed, 20, 100)"/>
            <xsl:message select="'Current text analyzed and stamped:', tan:trim-long-tree($current-text-analyzed-and-stamped, 20, 100)"/>
            <xsl:message select="'Analysis checked for formats:', tan:trim-long-tree($analysis-checked-for-formats, 20, 100)"/>
            <xsl:message select="'Adjustments to make to format map:', tan:trim-long-tree(tan:map-to-xml($adjustments-to-make-to-format-map, true()), 20, 100)"/>
            <xsl:message select="'New docx map: ', tan:trim-long-tree(tan:map-to-xml($new-docx-map, true()), 20, 100)"/>
         </xsl:if>
         
         <xsl:next-iteration>
            <xsl:with-param name="docx-input-map-so-far" as="map(*)" select="$new-docx-map"/>
         </xsl:next-iteration>
         
      </xsl:iterate>
      
   </xsl:function>
   
   
   
   <xsl:mode name="sequester-formats" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[text()]" mode="sequester-formats">
      <xsl:param name="positions-required" tunnel="yes" as="xs:integer*"/>
      <xsl:param name="positions-disallowed" tunnel="yes" as="xs:integer*"/>
      <xsl:param name="must-match-a-format" tunnel="yes" as="xs:boolean"/>
      <xsl:param name="current-starting-position" as="xs:integer" tunnel="yes" select="1"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:iterate select="node()">
            <xsl:param name="this-starting-position" as="xs:integer" select="$current-starting-position"/>
            
            <xsl:variable name="this-length" as="xs:integer" select="tan:string-length(.)"/>
            <xsl:variable name="next-starting-position" as="xs:integer" select="$this-starting-position + $this-length"/>
            
            <xsl:choose>
               <xsl:when test=". instance of text()">
                  <!-- diagnostics -->
                  <xsl:apply-templates select="." mode="#current">
                     <xsl:with-param name="current-starting-position" tunnel="yes" select="$this-starting-position"/>
                     <xsl:with-param name="positions-required" tunnel="yes" select="$positions-required[. ge $this-starting-position][. lt $next-starting-position]"/>
                     <xsl:with-param name="positions-disallowed" tunnel="yes" select="$positions-disallowed[. ge $this-starting-position][. lt $next-starting-position]"/>
                  </xsl:apply-templates>
               </xsl:when>
               <xsl:when test=". instance of text()">
                  <xsl:for-each-group select="string-to-codepoints(.)" group-adjacent="
                        let $p := $this-starting-position + position() - 1
                        return
                           if ($must-match-a-format) then
                              (($p = $positions-required) and not($p = $positions-disallowed))
                           else
                              not($p = $positions-disallowed)">
                     <xsl:choose>
                        <xsl:when test="current-grouping-key() eq true()">
                           <xsl:value-of select="codepoints-to-string(current-group())"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <x>
                              <xsl:value-of select="codepoints-to-string(current-group())"/>
                           </x>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each-group>
               </xsl:when>
               <xsl:when test=". instance of text()">
                  <xsl:for-each-group select="string-to-codepoints(.)"
                     group-adjacent="($this-starting-position + position() - 1) = ($positions-required, $positions-disallowed)">
                     <xsl:choose>
                        <xsl:when test="(current-grouping-key() eq true() and exists($positions-disallowed))
                           or (current-grouping-key() eq false() and exists($positions-required))">
                           <x>
                              <xsl:value-of select="codepoints-to-string(current-group())"/>
                           </x>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:value-of select="codepoints-to-string(current-group())"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each-group> 
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="." mode="#current">
                     <xsl:with-param name="current-starting-position" tunnel="yes" select="$this-starting-position"/>
                     <xsl:with-param name="positions-required" tunnel="yes" select="$positions-required[. ge $this-starting-position]"/>
                     <xsl:with-param name="positions-disallowed" tunnel="yes" select="$positions-disallowed[. ge $this-starting-position]"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
            
            <xsl:next-iteration>
               <xsl:with-param name="this-starting-position" select="$this-starting-position + $this-length"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="text()" mode="sequester-formats">
      <xsl:param name="positions-required" tunnel="yes" as="xs:integer*"/>
      <xsl:param name="positions-disallowed" tunnel="yes" as="xs:integer*"/>
      <xsl:param name="must-match-a-format" tunnel="yes" as="xs:boolean"/>
      <xsl:param name="current-starting-position" as="xs:integer" tunnel="yes" select="1"/>
      
      <xsl:variable name="combining-char-codepoints" as="xs:integer*" select="string-to-codepoints(string-join(analyze-string(., '\p{M}+')/*:match))"/>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode sequester-formats'"/>
         <xsl:message select="'positions required (count ' || count($positions-required) || '), first 20: ', subsequence($positions-required, 1, 20)"/>
         <xsl:message select="'positions disallowed (count ' || count($positions-disallowed) || '), first 20: ', subsequence($positions-disallowed, 1, 20)"/>
         <xsl:message select="'Must match a format: ', $must-match-a-format"/>
         <xsl:message select="'Current starting position: ', $current-starting-position"/>
         <xsl:message select="'Combining character codepoints: ', $combining-char-codepoints"/>
      </xsl:if>
      
      <!--<xsl:iterate select="tan:chop-string(.)">
         <xsl:value-of select="."/>
      </xsl:iterate>-->
      
      <xsl:iterate select="string-to-codepoints(.)">
         <xsl:param name="string-so-far" as="xs:string?"/>
         <xsl:param name="string-so-far-is-a-match" as="xs:boolean" select="true()"/>
         <xsl:param name="current-pos" as="xs:integer" select="$current-starting-position"/>
         <xsl:param name="positions-required-remnant" as="xs:integer*" select="$positions-required"/>
         <xsl:param name="positions-disallowed-remnant" as="xs:integer*" select="$positions-disallowed"/>
         
         <xsl:on-completion>
            <xsl:choose>
               <xsl:when test="$string-so-far-is-a-match">
                  <xsl:value-of select="$string-so-far"/>
               </xsl:when>
               <xsl:when test="string-length($string-so-far) gt 0">
                  <x><xsl:value-of select="$string-so-far"/></x>
               </xsl:when>
            </xsl:choose>
         </xsl:on-completion>
         
         <xsl:variable name="this-is-required" as="xs:boolean"
            select="$current-pos = $positions-required-remnant[1]"/>
         <xsl:variable name="this-is-disallowed" as="xs:boolean"
            select="$current-pos = $positions-disallowed-remnant[1]"/>
         <xsl:variable name="mark-this-as-a-match" as="xs:boolean" select="
               if ($must-match-a-format)
               then
                  $this-is-required
               else
                  not($this-is-disallowed)"/>
         
         <xsl:variable name="next-string-fragment" as="xs:string">
            <xsl:choose>
               <xsl:when test="not($mark-this-as-a-match eq $string-so-far-is-a-match)">
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$string-so-far || codepoints-to-string(.)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         
         <xsl:variable name="inner-diagnostics-on" as="xs:boolean" select="false()"/>
         <xsl:if test="$inner-diagnostics-on">
            <xsl:message select="'String so far: ' || tan:ellipses($string-so-far, 20)"/>
            <xsl:message select="'String so far is a match: ', $string-so-far-is-a-match"/>
            <xsl:message select="'Current position: ' || $current-pos"/>
            <xsl:message select="'Positions required remnant, head: ', $positions-required-remnant[1]"/>
            <xsl:message select="'Positions disallowed remnant, head: ', $positions-disallowed-remnant[1]"/>
            <xsl:message select="'This is required: ', $this-is-required"/>
            <xsl:message select="'This is disallowed: ', $this-is-disallowed"/>
            <xsl:message select="'Mark this as a match: ', $mark-this-as-a-match"/>
            <xsl:message select="'Next string fragment: ' || tan:ellipses($next-string-fragment, 20)"/>
         </xsl:if>
         
         <!-- Output the string so far if the status changes -->
         <xsl:choose>
            <xsl:when test="string-length($string-so-far) eq 0"/>
            <xsl:when test="not($string-so-far-is-a-match) and $mark-this-as-a-match">
               <x><xsl:value-of select="$string-so-far"/></x>
            </xsl:when>
            <xsl:when test="$string-so-far-is-a-match and not($mark-this-as-a-match)">
               <xsl:value-of select="$string-so-far"/>
            </xsl:when>
         </xsl:choose>
         
         <xsl:next-iteration>
            <xsl:with-param name="string-so-far" as="xs:string" select="$next-string-fragment"/>
            <xsl:with-param name="string-so-far-is-a-match" as="xs:boolean" select="$mark-this-as-a-match"/>
            <xsl:with-param name="current-pos" as="xs:integer" select="
                  if (. = $combining-char-codepoints) then
                     $current-pos
                  else
                     $current-pos + 1"/>
            <xsl:with-param name="positions-required-remnant" select="
                  if ($this-is-required) then
                     tail($positions-required-remnant)
                  else
                     $positions-required-remnant"/>
            <xsl:with-param name="positions-disallowed-remnant" select="
                  if ($this-is-disallowed) then
                     tail($positions-disallowed-remnant)
                  else
                     $positions-disallowed-remnant"/>
         </xsl:next-iteration>
         
      </xsl:iterate>
      
   </xsl:template>
   
   
   <xsl:mode name="analyze-current-text" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:x" mode="analyze-current-text">
      <!-- If a format is required, or disallowed, text that is not a candidate for searching has been
         sequestered by an <x>, copied wholesale here. -->
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="text()" mode="analyze-current-text">
      <xsl:param name="current-change-element" as="element()" tunnel="yes"/>
      
      <xsl:variable name="this-is-simple-replace" as="xs:boolean" select="exists($current-change-element/@replacement)"/>
      <xsl:variable name="exclude-pattern" as="xs:string?" select="$current-change-element/@exclude-pattern"/>
      
      <xsl:analyze-string select="." regex="{$current-change-element/@pattern}" flags="{$current-change-element/@flags}">
         <xsl:matching-substring>
            <xsl:choose>
               <xsl:when
                  test="string-length($exclude-pattern) gt 0 and tan:matches(., $exclude-pattern, ($current-change-element/@flags, '')[1])">
                  <x>
                     <xsl:value-of select="."/>
                  </x>
               </xsl:when>
               <xsl:otherwise>
                  <!-- It's a match. Let's process it. -->
                  <xsl:variable name="rgc" as="xs:integer?">
                     <xsl:call-template name="tan:regex-group-count"/>
                  </xsl:variable>
                  <match>
                     <xsl:value-of select="."/>
                     <replacement>
                        <!-- We forestall the message, in case there's no match against the chosen format. -->
                        <xsl:if test="exists($current-change-element/@message)">
                           <xsl:apply-templates select="$current-change-element/@message"
                              mode="tan:batch-replace-advanced-pass-2"/>
                        </xsl:if>
                        <xsl:choose>
                           <xsl:when test="$this-is-simple-replace">
                              <xsl:value-of
                                 select="tan:replace(., $current-change-element/@pattern, $current-change-element/@replacement, ($current-change-element/@flags, '')[1])"
                              />
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:sequence
                                 select="tan:batch-replace-advanced(., $current-change-element)"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </replacement>
                  </match>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:matching-substring>
         <xsl:non-matching-substring>
            <x>
               <xsl:value-of select="."/>
            </x>
         </xsl:non-matching-substring>
      </xsl:analyze-string>
   </xsl:template>
   
   
   <xsl:mode name="check-docx-string-formats" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:match" mode="check-docx-string-formats">
      <xsl:param name="format-map" tunnel="yes" as="map(xs:integer,xs:string+)"/>
      <xsl:param name="format-map-keys" tunnel="yes" as="xs:integer+"/>
      <xsl:param name="formats-expected" tunnel="yes" as="xs:string*"/>
      <xsl:param name="formats-excluded" tunnel="yes" as="xs:string*"/>
      <xsl:param name="positions-allowed" tunnel="yes" as="xs:integer*"/>
      
      <xsl:variable name="context-pos" as="xs:integer" select="xs:integer(@_pos)"/>
      <xsl:variable name="context-len" as="xs:integer" select="xs:integer(@_len)"/>
      <xsl:variable name="positions-to-check" as="xs:integer+"
         select="$context-pos to ($context-pos + $context-len - 1)"/>
      <xsl:variable name="positions-without-format-map-entries" as="xs:integer*"
         select="$positions-to-check[not(. = $format-map-keys)]"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, template mode check-docx-string-formats'"/>
         <xsl:message select="'This match: ', ."/>
         <xsl:message select="'Formats expected: ' || string-join($formats-expected, ', ')"/>
         <xsl:message select="'Formats excluded: ' || string-join($formats-excluded, ', ')"/>
         <xsl:message select="'positions to check: ', $positions-to-check"/>
         <xsl:message select="'positions without format map entries: ', $positions-without-format-map-entries"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="(count($positions-allowed) gt 0) and (some $i in $positions-to-check satisfies not($i = $positions-allowed))">
            <x>
               <xsl:copy-of select="@*"/>
               <xsl:value-of select="text()"/>
            </x>
         </xsl:when>
         <!--<xsl:when test="exists($formats-expected) and exists($positions-without-format-map-entries)">
            <x>
               <xsl:copy-of select="@*"/>
               <xsl:value-of select="text()"/>
            </x>
         </xsl:when>-->
         <!--<xsl:when test="
               exists($formats-expected) and
               (some $i in $positions-to-check,
                  $j in $formats-expected
                  satisfies not($format-map($i) = $j))">
            <x>
               <xsl:copy-of select="@*"/>
               <xsl:value-of select="text()"/>
            </x>
         </xsl:when>-->
         <!--<xsl:when test="
               exists($formats-excluded) and
               (some $i in $positions-to-check,
                  $j in $formats-excluded
                  satisfies $format-map($i) = $j)">
            <x>
               <xsl:copy-of select="@*"/>
               <xsl:value-of select="text()"/>
            </x>
         </xsl:when>-->
         <xsl:otherwise>
            <xsl:if test="exists(tan:replacement/@message)">
               <!-- There's a match on the format, so we convey the message. -->
               <xsl:message select="tan:replacement/@message"/>
            </xsl:if>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:template>
   
   
   <xsl:mode name="calculate-adjustments-to-format-map" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:match" mode="calculate-adjustments-to-format-map">
      <xsl:variable name="old-pos" as="xs:integer" select="xs:integer(@_pos)"/>
      <xsl:variable name="old-length" as="xs:integer" select="xs:integer(@_len)"/>
      <xsl:variable name="new-length" as="xs:integer" select="tan:string-length(tan:replacement)"/>
      <xsl:choose>
         <xsl:when test="$old-length gt $new-length">
            <!-- Deletions have taken place -->
            <xsl:for-each select="($new-length + 1) to $old-length">
               <xsl:map-entry key="$old-pos + ." select="-1"/>
            </xsl:for-each>
         </xsl:when>
         <xsl:when test="$old-length lt $new-length">
            <!-- Insertions have taken place. Just put a sum at the last entry, to extend its
                    format values. -->
            <xsl:map-entry key="$old-pos + $old-length - 1" select="$new-length - $old-length"/>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   
   
   <xsl:mode name="calculate-text-replacement" on-no-match="shallow-copy"/>
   
   <!-- Unwrap the current match / non-match / replacement nodes -->
   <xsl:template match="tan:x | tan:match | tan:replacement" mode="calculate-text-replacement">
      <xsl:if test="exists(@message)">
         <xsl:message select="xs:string(@message)"/>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <!-- Ignore match's child text, because the contents of <replacement> will take its place -->
   <xsl:template match="tan:match/text()" mode="calculate-text-replacement"/>
   <!-- Ignore temporary attributes -->
   <xsl:template match="@_pos | @_len" mode="calculate-text-replacement"/>
   
   
   
   
   
</xsl:stylesheet>