<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://docbook.org/ns/docbook" xmlns:docbook="http://docbook.org/ns/docbook"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:saxon="http://icl.com/saxon"
   xmlns:xslq="https://github.com/mricaud/xsl-quality"
   xmlns:lxslt="http://xml.apache.org/xslt" xmlns:redirect="http://xml.apache.org/xalan/redirect"
   xmlns:exsl="http://exslt.org/common" xmlns:doc="http://nwalsh.com/xsl/documentation/1.0"
   xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:sch="http://purl.oclc.org/dsdl/schematron"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xpath-default-namespace="http://docbook.org/ns/docbook"
   extension-element-prefixes="saxon redirect lxslt exsl" exclude-result-prefixes="#all"
   version="3.0">

   <!-- Stylesheet to generate major parts of the official TAN guidelines -->
   
   <!-- Catalyzing input: any XML file (including this one) -->
   <!-- Primary input: the RELAX-NG schema library, the TAN function library, the TAN vocabulary library -->
   <!-- Primary output: none -->
   <!-- Secondary output: the appendix sections of the Guidelines, converting major parts of TAN to docbook format (see end of this file) -->
   <!-- This process takes about 25 seconds. -->
   
   <!-- This stylesheet and its components are pretty messy, reflecting the accumulation of several years of development. Because
      it is not intended for mass consumption, I haven't tried to clean or streamline the code. -->
   
   <xsl:param name="generate-inclusion-for-utilities-and-applications" as="xs:boolean" static="true"
      select="true()"/>
   <xsl:param name="generate-inclusion-for-elements-attributes-and-patterns" as="xs:boolean"
      static="true" select="true()"/>
   <xsl:param name="generate-inclusion-for-vocabularies" as="xs:boolean" static="true"
      select="true()"/>
   <xsl:param name="generate-inclusion-for-keys-functions-and-templates" as="xs:boolean"
      static="true" select="true()"/>
   <xsl:param name="generate-inclusion-for-errors" as="xs:boolean" static="true" select="true()"/>
   
   <xsl:param name="tan:include-diagnostics-components" as="xs:boolean" select="true()" static="yes"/>
   
   <xsl:include href="../../functions/TAN-function-library.xsl"/>
   <xsl:include href="rng-to-text.xsl"/>
   <xsl:include href="tan-snippet-to-docbook.xsl"/>
   <xsl:include href="tan-vocabularies-to-docbook.xsl"/>
   <xsl:include href="XSLT%20analysis.xsl"/>
   <xsl:include href="tan-applications-to-docbook.xsl"/>

   <xsl:param name="max-examples" as="xs:integer" select="4"/>
   <xsl:param name="qty-contextual-siblings" as="xs:integer" select="1"/>
   <xsl:param name="qty-contextual-children" as="xs:integer" select="3"/>
   <xsl:param name="max-example-size" as="xs:integer" select="2000"/>

   <xsl:variable name="chapter-caveat" as="element()">
      <para>The contents of this chapter have been generated automatically. In case of errors or
         inconsistencies, the master files should be consulted.</para>
   </xsl:variable>

   <xsl:variable name="target-base-uri-for-guidelines" as="xs:anyURI" select="resolve-uri('../../guidelines/main.xml',static-base-uri())"/>
   <xsl:variable name="target-uri-for-elements-attributes-and-patterns" as="xs:anyURI" select="resolve-uri('../../guidelines/inclusions/elements-attributes-and-patterns.xml',static-base-uri())"/>

   <xsl:variable name="ex-collection" as="document-node()*"
      select="collection('../../examples/?select=*.xml;recurse=yes'), collection('../../vocabularies/?select=*.xml;recurse=yes')"/>
   <xsl:variable name="app-collection" as="document-node()*" select="
         for $i in
         uri-collection('../../applications/?select=*.xsl;recurse=yes')[matches(., 'applications/[^/]+/[^/]+$')][not(matches(., 'configuration'))]
         return
            doc($i)"/>
   <xsl:variable name="util-collection" as="document-node()*" select="
         for $i in uri-collection('../../utilities/?select=*.xsl;recurse=yes')[matches(., 'utilities/[^/]+/[^/]+$')][not(matches(., 'Oxygen|configuration'))]
         return
            doc($i)"/>
   <xsl:variable name="fn-collection" as="document-node()*"
      select="collection('../../functions/?select=*.xsl;recurse=yes')"/>
   <xsl:variable name="vocabulary-collection" as="document-node()*"
      select="collection('../../vocabularies/?select=*voc.xml;recurse=yes')"/>
   <xsl:variable name="elements-excl-TEI" as="element()*"
      select="$tan:rng-collection-without-TEI//rng:element[@name]"/>
   <xsl:variable name="attributes-excl-TEI" as="element()*"
      select="$tan:rng-collection-without-TEI//rng:attribute[@name]"/>
   
   <xsl:variable name="function-keyword-doc" as="document-node()" select="doc('../TAN-function-keywords.xml')"/>

   <xsl:variable name="sequence-of-sections" as="element()">
      <!-- Filters and arranges the function files into sequence sequence and hierarchy the documentation should follow. -->
      <sec n="TAN-core">
         <sec n="TAN-class-1">
            <sec n="TAN-T"/>
         </sec>
         <sec n="TAN-class-2">
            <sec n="TAN-A"/>
            <sec n="TAN-A-tok"/>
            <sec n="TAN-A-lm"/>
         </sec>
         <sec n="TAN-class-3">
            <sec n="TAN-voc"/>
            <sec n="TAN-mor"/>
            <sec n="catalog.tan"/>
         </sec>
      </sec>
   </xsl:variable>

   <!--<xsl:variable name="function-docs-picked"
      select="$tan:all-functions[replace(tan:cfn(.), '-functions', '') = $sequence-of-sections/descendant-or-self::*/@n]"/>-->
   <xsl:variable name="function-docs-picked" select="$tan:all-functions" as="document-node()+"/>
   <xsl:variable name="function-library-keys" select="$function-docs-picked/xsl:stylesheet/xsl:key" as="element()+"/>
   <xsl:variable name="function-library-functions" as="element()+"
      select="$function-docs-picked/xsl:stylesheet/xsl:function[@visibility eq 'public']"/>
   <xsl:variable name="names-of-functions-to-append" as="xs:string*">
      <xsl:for-each-group select="$function-library-functions" group-by="@name">
         <xsl:variable name="these-file-names" as="xs:string*"
            select="distinct-values(tan:cfn(current-group()))"/>
         <xsl:if test="count($these-file-names) gt 1">
            <xsl:value-of select="current-grouping-key()"/>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:variable>
   
   <xsl:variable name="function-library-templates" as="element()*"
      select="$function-docs-picked/xsl:stylesheet/xsl:template"/>
   
   <xsl:variable name="function-library-variables" as="element()*"
      select="$function-docs-picked/xsl:stylesheet/xsl:variable"/>
   <xsl:variable name="function-library-duplicate-variable-names" as="xs:string*"
      select="tan:duplicate-items($function-library-variables/@name)"/>
   <xsl:variable name="function-library-variables-duplicate" as="element()*"
      select="$function-library-variables[@name = $function-library-duplicate-variable-names]"/>
   <xsl:variable name="function-library-variables-unique" as="element()*"
      select="$function-library-variables[not(@name = $function-library-duplicate-variable-names)]"/>

   <xsl:variable name="lf" as="xs:string" select="'&#xA;'"/>
   <xsl:variable name="lt" as="xs:string" select="'&lt;'"/>
   <xsl:variable name="ellipses" as="xs:string" select="'.........&#xA;'"/>

   <!--<xsl:template match="*" mode="errors-to-docbook context-errors-to-docbook"/>-->
   <xsl:template match="docbook:squelch"/>
   
   <xsl:variable name="indent" as="xs:string"
      select="
         string-join(for $i in (1 to $tan:default-indent-value)
         return
            ' ')"/>
   <xsl:variable name="distinct-element-names" as="xs:string*" select="distinct-values($elements-excl-TEI/@name)"/>
   <xsl:variable name="distinct-attribute-names" as="xs:string*"
      select="distinct-values($attributes-excl-TEI/@name)"/>
   <xsl:variable name="function-library-template-names-and-modes" as="xs:string*" select="
         for $i in $function-library-templates/(@name, @mode)
         return
            tokenize($i, '\s+')"/>

   <xsl:mode name="tan:prep-string-for-docbook" on-no-match="shallow-copy"/>
   
   <xsl:template match=".[. instance of xs:string]" mode="tan:prep-string-for-docbook">
      <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
   </xsl:template>
   <xsl:template match="text()" mode="tan:prep-string-for-docbook">
      <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
   </xsl:template>

   <xsl:function name="tan:prep-string-for-docbook" as="item()*" visibility="private">
      <xsl:param name="text" as="xs:string?"/>
      <xsl:sequence select="tan:prep-string-for-docbook($text, 100)"/>
   </xsl:function>
   <xsl:function name="tan:prep-string-for-docbook" as="item()*" visibility="private">
      <xsl:param name="text" as="xs:string?"/>
      <xsl:param name="truncate-text-of-long-urls-at-what" as="xs:integer?"/>
      
      <xsl:variable name="url-vel-sim-regex" as="xs:string" select="'main\.xml#[-_\w]+|iris\.xml|https?://\S+|tag:textalign.net,2015\S+'"/>
      <!-- we assume that all components defined in component%20syntax.xml are to be marked -->
      <xsl:variable name="capture-group-replacement" as="xs:string"
         select="'(' || $component-syntax/*/@name-replacement || ')'"/>
      <xsl:variable name="string-regexes" as="xs:string*" select="$component-syntax/*/*/@string-matching-pattern"/>
      <xsl:variable name="master-regex" as="xs:string"
         select="
            string-join(for $i in $string-regexes
            return
               replace($i, 'name', $capture-group-replacement), '|')"/>

      <xsl:variable name="pass-1-new" as="element()">
         <pass1>
            <xsl:analyze-string select="$text" regex="{$url-vel-sim-regex}">
               <xsl:matching-substring>
                  <xsl:choose>
                     <!-- The documentation of the relax-ng schemas may point to the guidelines
                                 by hard-coding main.xml#[ID]. That's an internal cross-reference. -->
                     <xsl:when test="starts-with(., 'main')">
                        <xref linkend="{replace(.,'main\.xml#','')}"/>
                     </xsl:when>
                     <xsl:when test="starts-with(., 'tag:')">
                        <code>
                           <xsl:value-of select="."/>
                        </code>
                     </xsl:when>
                     <xsl:when test="matches(., '[\(\[]')">
                        <link xlink:href="{.}">
                           <code>
                              <xsl:choose>
                                 <xsl:when test="$truncate-text-of-long-urls-at-what gt 0">
                                    <xsl:value-of select="tan:ellipses(., $truncate-text-of-long-urls-at-what idiv 2, $truncate-text-of-long-urls-at-what idiv 2)"/>  
                                 </xsl:when>
                                 <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                 </xsl:otherwise>
                              </xsl:choose>
                           </code>
                        </link>
                     </xsl:when>
                     <xsl:otherwise>
                        <!-- Walk back any final characters that aren't really part of the URL. -->
                        <xsl:analyze-string select="." regex="[\)\].]+$">
                           <xsl:matching-substring>
                              <xsl:value-of select="."/>
                           </xsl:matching-substring>
                           <xsl:non-matching-substring>
                              <link xlink:href="{.}">
                                 <code>
                                    <xsl:choose>
                                       <xsl:when test="$truncate-text-of-long-urls-at-what gt 0">
                                          <xsl:value-of select="tan:ellipses(., $truncate-text-of-long-urls-at-what idiv 2, $truncate-text-of-long-urls-at-what idiv 2)"/>  
                                       </xsl:when>
                                       <xsl:otherwise>
                                          <xsl:value-of select="."/>
                                       </xsl:otherwise>
                                    </xsl:choose>
                                 </code>
                              </link>
                           </xsl:non-matching-substring>
                        </xsl:analyze-string>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:analyze-string select="." regex="{$master-regex}">
                     <xsl:matching-substring>
                        <xsl:variable name="first-match" as="xs:integer?"
                           select="((1 to 11)[string-length(regex-group(.)) gt 0])[1]"/>
                        <xsl:variable name="match-type" as="xs:string?"
                           select="tokenize($component-syntax/*/*[$first-match]/@type, ' ')[1]"/>
                        <!-- The regex group sometimes has to be massaged -->
                        <xsl:variable name="match-name-parts" as="xs:string*">
                           <xsl:analyze-string select="regex-group($first-match)" regex="(\.)$">
                              <xsl:matching-substring>
                                 <xsl:value-of select="."/>
                              </xsl:matching-substring>
                              <xsl:non-matching-substring>
                                 <xsl:value-of select="."/>
                              </xsl:non-matching-substring>
                           </xsl:analyze-string>
                        </xsl:variable>
                        <xsl:variable name="match-name" as="xs:string?" select="$match-name-parts[1]"/>
                        <xsl:variable name="is-valid-link" as="xs:boolean">
                           <xsl:choose>
                              <xsl:when
                                 test="
                                 ($match-type = 'attribute' and not(exists($attributes-excl-TEI[@name = $match-name]))) or
                                 ($match-type = 'element' and not(exists($elements-excl-TEI[@name = $match-name]))) or
                                 ($match-type = 'key' and not(exists($function-library-keys[@name = $match-name]))) or
                                 ($match-type = 'function' and not(exists($function-library-functions[@name = $match-name]))) or
                                 ($match-type = 'variable' and not(exists($function-library-variables[@name = $match-name])))">
                                 <xsl:sequence select="false()"/>
                              </xsl:when>
                              <xsl:otherwise>
                                 <xsl:sequence select="true()"/>
                              </xsl:otherwise>
                           </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="linkend" as="xs:string"
                           select="$match-type || '-' || replace($match-name, '[:#]|(tan|rgx):', '')"/>
                        
                        <code>
                           <xsl:choose>
                              <xsl:when test="$is-valid-link">
                                 <link linkend="{$linkend}">
                                    <xsl:choose>
                                       <xsl:when test="$truncate-text-of-long-urls-at-what gt 0">
                                          <xsl:value-of select="replace(., '\($', '') => tan:ellipses($truncate-text-of-long-urls-at-what idiv 2, $truncate-text-of-long-urls-at-what idiv 2)"/>  
                                       </xsl:when>
                                       <xsl:otherwise>
                                          <xsl:value-of select="replace(., '\($', '')"/>  
                                       </xsl:otherwise>
                                    </xsl:choose>
                                 </link>
                                 <!-- commented out July 2021; I think I have the function parentheses problem solved elsewhere,
                              rendering this hack incorrect -->
                                 <!--<xsl:if test="$match-type = 'function'">
                                 <xsl:text>(</xsl:text>
                              </xsl:if>-->
                              </xsl:when>
                              <xsl:otherwise>
                                 <xsl:value-of select="."/>
                              </xsl:otherwise>
                           </xsl:choose>
                        </code>
                        <xsl:value-of select="$match-name-parts[2]"/>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:non-matching-substring>
               
            </xsl:analyze-string>
         </pass1>
      </xsl:variable>
      
      
      <xsl:apply-templates select="$pass-1-new/node()" mode="prep-string-for-docbook-pass-2"/>
      
   </xsl:function>
   
   <xsl:mode name="prep-string-for-docbook-pass-2" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="prep-string-for-docbook-pass-2">
      <xsl:analyze-string select="." regex="\p{{Cc}}">
         <xsl:matching-substring>
            <xsl:variable name="this-cp" as="xs:integer" select="string-to-codepoints(.)"/>
            <xsl:choose>
               <xsl:when test="$this-cp lt 32 and not($this-cp = (9, 10))">
                  <xsl:value-of select="'&amp;#' || string(string-to-codepoints(.)) || ';'"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:matching-substring>
         <xsl:non-matching-substring>
            <xsl:value-of select="."/>
         </xsl:non-matching-substring>
      </xsl:analyze-string>
   </xsl:template>

   <xsl:function name="tan:component-comments-to-docbook" as="element()*">
      <!-- Input: one or more XSLT elements -->
      <!-- Output: one docbook <programlisting> per comment -->
      <xsl:param name="xslt-elements" as="element()*"/>
      
      <xsl:for-each select="$xslt-elements">
         <!-- template mode comments are hard to read, because they have so many instances, so we need label based on @match -->
         <xsl:choose>
            <xsl:when test="self::xsl:template/@match">
               <para>
                  <code>
                     <xsl:value-of select="tan:xml-to-string(tan:shallow-copy(.))"/>
                  </code>
               </para>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="comments-to-docbook"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:mode name="comments-to-docbook" on-no-match="shallow-skip"/>
   
   <!-- We are interested only in those annotations that are part of top-level declarations -->
   <xsl:template match="/xsl:*/xsl:*/xsl:*" mode="comments-to-docbook"/>
   
   <xsl:template match="comment()[matches(., '^\s*kw:')]" mode="comments-to-docbook" priority="1">
      <para>
         <xsl:text>Related: </xsl:text> 
         <xsl:for-each select="tokenize(replace(normalize-space(.), '^kw: ?', ''), ', ?')">
            <xsl:if test="position() gt 1">
               <xsl:text>, </xsl:text>
            </xsl:if>
            <link linkend="tan-function-group-{replace(., ' ', '_')}"><xsl:value-of select="."/></link>
         </xsl:for-each></para>
   </xsl:template>
   <xsl:template match="comment()[not(preceding-sibling::*)][matches(., '\S')]" mode="comments-to-docbook">
      <xsl:for-each select="tokenize(., '\n(\s+\n)+')">
         <xsl:variable name="this-para-norm" as="xs:string" select="tan:rewrap-para(., 72)"/>
         <programlisting>
         <xsl:copy-of select="tan:prep-string-for-docbook($this-para-norm)"/>
      </programlisting>
      </xsl:for-each>

   </xsl:template>
   
   <xsl:function name="tan:rewrap-para" as="xs:string?">
      <!-- Input: a string; an integer -->
      <!-- Output: the string with new lines inserted at the first word break possible after the integer length has been reached -->
      <xsl:param name="input-text" as="xs:string?"/>
      <xsl:param name="break-after-what-column" as="xs:integer"/>
      <xsl:variable name="this-input-normalized" as="xs:string*">
         <xsl:analyze-string select="$input-text" regex="(\n) +(\*|\d+\.|-) ">
            <xsl:matching-substring>
               <xsl:value-of select="' ' || regex-group(1) || regex-group(2) || ' '"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="normalize-space(.)"/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="these-input-words" as="xs:string*"
         select="tokenize(string-join($this-input-normalized), ' ')"/>
      <xsl:variable name="words-marked-for-wrapping" as="xs:string*">
         <xsl:iterate select="$these-input-words">
            <xsl:param name="col-count-so-far" as="xs:integer" select="0"/>
            <xsl:variable name="this-word" as="xs:string" select="."/>
            <xsl:variable name="this-word-length" as="xs:integer" select="string-length($this-word)"/>
            <xsl:variable name="new-col-count" as="xs:integer" select="$this-word-length + $col-count-so-far"/>
            <xsl:choose>
               <xsl:when test="$new-col-count ge $break-after-what-column">
                  <xsl:value-of select="$lf || $this-word || ' '"/>
                  <xsl:if test="$this-word-length ge $break-after-what-column">
                     <xsl:value-of select="$lf"/>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="$this-word || ' '"/>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:next-iteration>
               <xsl:with-param as="xs:integer" name="col-count-so-far"
                  select="
                     if ($new-col-count lt $break-after-what-column) then
                        $new-col-count
                     else
                        0"
               />
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      <xsl:value-of select="string-join($words-marked-for-wrapping)"/>
   </xsl:function>
   <xsl:function name="tan:component-dependees-to-docbook" as="element()*">
      <!-- Input: one or more XSLT elements -->
      <!-- Output: one docbook <para> per type listing other components that depend upon the input component -->
      <xsl:param name="xslt-element" as="element()?"/>
      <xsl:variable name="this-type-of-component" as="xs:string?" select="name($xslt-element)"/>
      <xsl:variable name="what-depends-on-this" as="element()*"
         select="tan:xslt-dependencies($xslt-element/(@name, @mode, @xml:id)[1], $this-type-of-component, exists($xslt-element/@mode), $tan:all-functions)[name() = ('xsl:function', 'xsl:variable', 'xsl:template', 'xsl:key')]"/>
      <xsl:for-each-group select="$what-depends-on-this" group-by="name()">
         <xsl:sort select="name()" order="descending"/>
         <xsl:variable name="component-type" as="xs:string" select="current-grouping-key()"/>
         <para>
            <xsl:text>Used by </xsl:text>
            <xsl:value-of select="replace(current-grouping-key(), 'xsl:', '') || ' '"/>
            <xsl:for-each-group select="current-group()" group-by="(@name, @mode)[1]">
               <xsl:sort/>
               <xsl:if test="position() gt 1">
                  <xsl:text>, </xsl:text>
               </xsl:if>
               <xsl:copy-of
                  select="tan:prep-string-for-docbook(tan:string-representation-of-component(current-group()[1]/(@name, @mode)[1], $component-type, exists(current-group()[1]/@mode)))"
               />
            </xsl:for-each-group>
            <xsl:text>.</xsl:text>
         </para>
      </xsl:for-each-group>
      <xsl:if test="not(exists($what-depends-on-this))">
         <para>No variables, keys, functions, or named templates depend upon this <xsl:value-of
               select="$this-type-of-component"/>.</para>
      </xsl:if>
   </xsl:function>
   
   <xsl:variable name="ignore-template-modes-regex" as="xs:string" select="'ad-hoc'"/>
   
   <xsl:function name="tan:component-dependencies-to-docbook" as="element()*">
      <!-- Input: one or more XSLT elements -->
      <!-- Output: one docbook <para> per type listing other components upon which the input component depends -->
      <xsl:param name="xslt-elements" as="element()*"/>
      <xsl:variable name="what-this-depends-on-pass-1" as="item()*">
         <xsl:copy-of
            select="
               for $i in $xslt-elements/descendant-or-self::*/@*
               return
                  tan:prep-string-for-docbook($i)"/>
         <xsl:copy-of
            select="
               for $j in $xslt-elements//xsl:call-template
               return
                  tan:prep-string-for-docbook(tan:string-representation-of-component($j/@name, 'template'))"/>
         <xsl:copy-of
            select="
               for $k in $xslt-elements//xsl:apply-templates[not(matches(@mode, $ignore-template-modes-regex))]
               return
                  tan:prep-string-for-docbook(tan:string-representation-of-component($k/@mode, 'template', true()))"
         />
      </xsl:variable>
      <xsl:variable name="what-this-depends-on-pass-2" as="element()*"
         select="$what-this-depends-on-pass-1/descendant-or-self::docbook:code[docbook:link[not(matches(@linkend, '^attribute-'))]]"/>
      <xsl:variable name="what-this-depends-on" as="element()*"
         select="tan:distinct-items($what-this-depends-on-pass-2)"/>
      <xsl:choose>
         <xsl:when test="exists($what-this-depends-on-pass-2)">
            <para>
               <xsl:text>Relies upon </xsl:text>
               <!-- Group by normalized values, i.e., regardless of whether the code has matching parens or an 
                  abandoned opening paren -->
               <xsl:for-each-group select="$what-this-depends-on-pass-2" group-by="replace(., '[\(\)]+', '')">
                  <xsl:sort/>
                  <xsl:if test="position() gt 1">
                     <xsl:text>, </xsl:text>
                  </xsl:if>
                  <!--<xsl:copy-of select="."/>-->
                  <xsl:apply-templates select="current-group()[1]" mode="complete-parentheses"/>
               </xsl:for-each-group>
               <xsl:text>.</xsl:text>
            </para>
         </xsl:when>
         <xsl:otherwise>
            <para>Does not rely upon global variables, keys, functions, or templates.</para>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:mode name="complete-parentheses" on-no-match="shallow-copy"/>
   
   <xsl:template match="docbook:code/text()[ends-with(., '(')]" mode="complete-parentheses">
      <xsl:value-of select=". || ')'"/>
   </xsl:template>

   
   <xsl:mode name="errors-to-docbook" on-no-match="shallow-skip"/>

   <xsl:template match="tan:rule | tan:message" mode="errors-to-docbook">
      <para>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>
   
   <xsl:template match="tan:error | tan:warning | tan:fatal" priority="1" mode="errors-to-docbook">
      <xsl:variable name="affected-attributes" as="xs:string*"
         select="
            for $i in ancestor-or-self::*/@affects-attribute
            return
               tokenize($i, '\s+')"/>
      <xsl:variable name="affected-elements" as="xs:string*"
         select="
            for $i in ancestor-or-self::*/@affects-element
            return
               tokenize($i, '\s+')"/>
      <section>
         <title>
            <xsl:value-of select="name(.)"/>
            <code>[<xsl:value-of select="@xml:id"/>]</code>
         </title>
         <xsl:apply-templates mode="#current"/>
         <xsl:choose>
            <xsl:when test="exists($affected-attributes) or exists($affected-elements)">
               <para>Affects: <xsl:copy-of
                     select="tan:prep-string-for-docbook(tan:string-representation-of-component($affected-attributes, 'attribute'))"/>
                  <xsl:copy-of
                     select="tan:prep-string-for-docbook(tan:string-representation-of-component($affected-elements, 'element'))"
                  />
               </para>
            </xsl:when>
            <xsl:otherwise>
               <para>General rule not affecting specific attibutes or elements.</para>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:copy-of select="tan:component-dependees-to-docbook(.)"/>
      </section>
   </xsl:template>
   
   
   <xsl:mode name="rng-to-docbook" on-no-match="deep-skip"/>
   
   <xsl:template match="a:documentation[parent::rng:element or parent::rng:attribute]"
      mode="rng-to-docbook">
      <xsl:variable name="parent-type" as="xs:string" select="lower-case(name(..))"/>
      <para>
         <xsl:if test="not(preceding-sibling::a:documentation)">
            <xsl:value-of select="'The ' || $parent-type || ' '"/>
            <code>
               <xsl:value-of select="../@name"/>
            </code>
            <xsl:text> </xsl:text>
         </xsl:if>
         <!--<xsl:message select="string(.)"/>-->
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>
   
   <xsl:template match="a:documentation[parent::rng:define]" mode="rng-to-docbook">
      <xsl:variable name="this-name" as="xs:string" select="replace(base-uri(.), '.+/(.+)\.rng$', '$1')"/>
      <para>
         <xsl:value-of select="$this-name || ': '"/>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>
   
   
   <xsl:mode name="context-errors-to-docbook" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:error | tan:fatal" priority="1" mode="context-errors-to-docbook">
      <caution>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
         </para>
      </caution>
   </xsl:template>
   <xsl:template match="tan:warning" priority="1" mode="context-errors-to-docbook">
      <important>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
            <xsl:if test="exists(tan:message)">
               <xsl:text> </xsl:text>
               <quote>
                  <xsl:copy-of select="tan:prep-string-for-docbook(tan:message)"/>
               </quote>
            </xsl:if>
         </para>
      </important>
   </xsl:template>
   <xsl:template match="tan:info" mode="context-errors-to-docbook">
      <info>
         <para>
            <xsl:copy-of select="tan:prep-string-for-docbook(tan:rule)"/>
         </para>
      </info>
   </xsl:template>

   <xsl:template name="rng-node-to-docbook-section">
      <!-- This is the main mechanism for populating sections that document the definition of an element, attribute, pattern, or global variable -->
      <xsl:param name="rng-element-or-attribute-group" as="element()*"/>
      <xsl:variable name="this-group" as="element()*" select="$rng-element-or-attribute-group"/>
      <!-- We prefer the term 'pattern' to 'define' to describe general patterns. -->
      <xsl:variable name="this-node-type" as="xs:string"
         select="replace(name($this-group[1]), 'define', 'pattern')"/>
      <xsl:variable name="this-node-name" as="xs:string" select="$this-group[1]/@name"/>
      <xsl:variable name="containing-definitions" as="element()*" select="$this-group/parent::rng:define"/>
      <xsl:variable name="these-target-element-names" as="xs:string*"
         select="tan:target-element-names(xs:string($this-node-name))"/>
      <xsl:variable name="possible-parents-of-this-node" as="element()*"
         select="$this-group/(ancestor::rng:element, rng:define)[last()], $tan:rng-collection-without-TEI//rng:ref[@name = ($this-node-name, $containing-definitions/@name)]/(ancestor::rng:element, ancestor::rng:define)[last()]"
      />
      <xsl:variable name="these-base-uris"
         as="xs:anyURI*"
         select="
            distinct-values(for $i in $this-group
            return
               base-uri($i))"
      />
      <xsl:variable name="catalog-is-of-interest" as="xs:boolean" select="
            some $i in $these-base-uris
               satisfies matches($i, 'catalog')"/>

      <section xml:id="{$this-node-type || '-' || replace($this-node-name,':','')}">
         <title>
            <code>
               <xsl:copy-of
                  select="tan:string-representation-of-component($this-node-name, $this-node-type)"
               />
            </code>
         </title>
         <xsl:for-each-group select="$rng-element-or-attribute-group" group-by="base-uri(.)">
            <xsl:variable name="this-base-uri" as="xs:string" select="current-grouping-key()"/>
            <xsl:variable name="this-group-count" as="xs:integer" select="count(current-group())"/>
            
            <para>
               <emphasis>
                  <code>
                     <link xlink:href="{tan:uri-relative-to($this-base-uri, $target-uri-for-elements-attributes-and-patterns)}">
                        <xsl:value-of select="replace($this-base-uri, '.+/', '')"/>
                     </link>
                  </code>
               </emphasis>
            </para>
            <xsl:for-each select="current-group()">
               <xsl:if test="$this-group-count gt 1">
                  <para>
                     <emphasis>
                        <xsl:value-of select="'Definition ' || string(position())"/></emphasis>
                  </para>
               </xsl:if>
               
               <!-- part 1, documentation -->
               <xsl:apply-templates select="a:documentation" mode="rng-to-docbook"/>
               <!--<xsl:if test="exists(rng:*)">
                  <para>Formal Definition</para>
                  <!-\- part 2a, formal definiton -\->
                  <synopsis>
                     <xsl:apply-templates select="rng:*" mode="formaldef">
                        <xsl:with-param name="current-indent" select="$indent" tunnel="yes"/>
                     </xsl:apply-templates>
                     <xsl:if test="not(exists(rng:*))">
                        <xsl:text>text</xsl:text>
                     </xsl:if>
                  </synopsis>
               </xsl:if>-->
            </xsl:for-each>
            <para>
               <xsl:text> </xsl:text>
            </para>
         </xsl:for-each-group> 
         
         <xsl:if test="$this-node-type = 'attribute' and exists($these-target-element-names)">
            <para>
               <xsl:text>Takes IDrefs to vocabulary items </xsl:text>
               <xsl:copy-of
                  select="
                     tan:prep-string-for-docbook(string-join(for $i in $these-target-element-names
                     return
                        ('&lt;' || $i || '>'), ', '))"
               />
            </para>
         </xsl:if>
         <xsl:if test="exists($possible-parents-of-this-node)">
            <para>
               <xsl:text>Used by: </xsl:text>
               <xsl:for-each-group select="$possible-parents-of-this-node"
                  group-by="name() || '_' || @name">
                  <xsl:variable name="this-key" as="xs:string+"
                     select="tokenize(current-grouping-key(), '_')"/>
                  <xsl:if test="position() gt 1">
                     <xsl:text>, </xsl:text>
                  </xsl:if>
                  <xsl:copy-of
                     select="tan:prep-string-for-docbook(tan:string-representation-of-component($this-key[2], $this-key[1]))"
                  />
               </xsl:for-each-group>
            </para>
         </xsl:if>
         <xsl:choose>
            <xsl:when test="$this-node-name = ('doc', 'collection')"/>
            <xsl:when test="$this-node-type eq 'element'">
               <xsl:apply-templates mode="context-errors-to-docbook"
                  select="$tan:errors//tan:group[tokenize(@affects-element, '\s+') = $this-node-name]/tan:*"/>
               <xsl:copy-of select="tan:examples($this-node-name, false(), $catalog-is-of-interest)"/>
            </xsl:when>
            <xsl:when test="$this-node-type eq 'attribute'">
               <xsl:apply-templates mode="context-errors-to-docbook"
                  select="$tan:errors//tan:group[tokenize(@affects-attribute, '\s+') = $this-node-name]/tan:*"/>
               <xsl:copy-of select="tan:examples($this-node-name, true(), $catalog-is-of-interest)"/>
            </xsl:when>
         </xsl:choose>
      </section>
   </xsl:template>
   
   
   <xsl:mode name="function-keywords-to-docbook" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:desc" mode="function-keywords-to-docbook">
      <para>
         <xsl:copy-of select="tan:prep-string-for-docbook(.)"/>
      </para>
   </xsl:template>
   <xsl:template match="tan:xref[1]" mode="function-keywords-to-docbook">
      <para>
         <xsl:text>See also: </xsl:text>
         <xsl:for-each select="../tan:xref">
            <xsl:if test="position() gt 1">
               <xsl:text>, </xsl:text>
            </xsl:if>
            <link linkend="tan-function-group-{replace(., ' ', '_')}">
               <xsl:value-of select="."/>
            </link>
         </xsl:for-each>
      </para>
   </xsl:template>
   
   

   <xsl:param name="output-diagnostics-on" as="xs:boolean" select="false()" static="yes"/>
   
   <xsl:output method="xml" indent="no" use-when="not($output-diagnostics-on)"/>
   <xsl:output method="xml" indent="true" use-when="$output-diagnostics-on"/>
   
   <xsl:template match="/*" use-when="$output-diagnostics-on">
      <!--<xsl:variable name="rng-file-picked" as="document-node()" select="$tan:rng-collection-without-TEI[4]"/>-->
      <diagnostics xmlns="">
         <!--<rng-coll-uri><xsl:sequence select="$tan:schema-uri-collection"></xsl:sequence></rng-coll-uri>-->
         <!--<rng-coll-count><xsl:value-of select="count($tan:rng-collection-without-TEI)"/></rng-coll-count>-->
         <!--<rng-file-picked><xsl:copy-of select="$rng-file-picked"/></rng-file-picked>-->
         <!--<rng-file-to-text>
            <xsl:apply-templates select="$rng-file-picked" mode="formaldef"/>
         </rng-file-to-text>-->
         <!--<fun-lib><xsl:sequence select="count($function-docs-picked)"></xsl:sequence></fun-lib>-->
         <signatures>
            <xsl:for-each-group select="($util-collection, $app-collection)/*/xsl:param" group-by="@as">
               <xsl:sort select="count(current-group())" order="descending"/>
               <signature count="{count(current-group())}">
                  <xsl:copy-of select="current-group()[1]"/>
                  <xsl:for-each select="current-group()">
                     <param>
                        <xsl:copy-of select="@name | @select"/>
                     </param>
                  </xsl:for-each>
               </signature>
            </xsl:for-each-group> 
         </signatures>
      </diagnostics>
      
   </xsl:template>

   <xsl:template match="/*" use-when="not($output-diagnostics-on)">
      <xsl:message select="'Generating inclusion for utilities and applications: ', $generate-inclusion-for-utilities-and-applications"/>
      <xsl:message select="'Generating inclusion for elements, attributes, and patterns: ', $generate-inclusion-for-elements-attributes-and-patterns"/>
      <xsl:message select="'Generating inclusion for vocabularies: ', $generate-inclusion-for-vocabularies"/>
      <xsl:message select="'Generating inclusion for keys, functions, and templates: ', $generate-inclusion-for-keys-functions-and-templates"/>
      <xsl:message select="'Generating inclusion for errors: ', $generate-inclusion-for-errors"/>
      
      <!-- Docbook inclusions for utilities and applications -->
      <xsl:result-document
         href="{resolve-uri('../../guidelines/inclusions/utilities.xml',static-base-uri())}">
         <section xml:id="tan-utilities" version="5.0">
            <title>TAN Utilities</title>
            <para>Standard TAN utilities are designed to get material into TAN or TEI formats, and
               to do complex editing tasks within TAN or TEI. These tools can save you many hours of
               editing. </para>
            <para>Each section below is generated automatically from the master file that drives the
               process. Any global parameters that are referred to in the discussion are explained in
               the file itself. </para>
            <xsl:apply-templates select="$util-collection" mode="app-and-utils-to-docbook"/>
         </section>
      </xsl:result-document>
      <xsl:result-document
         href="{resolve-uri('../../guidelines/inclusions/applications.xml',static-base-uri())}">
         <section xml:id="tan-applications" version="5.0">
            <title>TAN Applications</title>
            <para>Standard TAN applications are designed to take TAN or TEI files and create output
               that allows users to study particular aspects of the text through interaction,
               statistics, and visualization. These are advanced, complex programs, and not all the
               intended features may have been implemented. </para>
            <para>Because of their power, these applications have numerous parameters for
               configuration. You are encouraged to read closely the documentation in the
               application to determine how to make the application work for your particular
               goals.</para>
            <para>Each section below is generated automatically from the master file that drives the
               process. Any global parameters that are referred to in the discussion are explained in
               the file itself. </para>
            <xsl:apply-templates select="$app-collection" mode="app-and-utils-to-docbook"/>
         </section>
      </xsl:result-document>
      
      <!-- Docbook inclusion for elements, attributes, and patterns -->

      <xsl:result-document href="{$target-uri-for-elements-attributes-and-patterns}" use-when="$generate-inclusion-for-elements-attributes-and-patterns">
         <chapter version="5.0" xml:id="elements-attributes-and-patterns">
            <title>TAN patterns, elements, and attributes defined</title>
            <!--<xsl:copy-of select="$chapter-caveat"/>-->
            <para>Each entry below begins with a description of the attribute, element, or pattern,
               followed by a formal definition and the name of the master file(s) that should be
               consulted. Dependencies are listed, along with relevant rules that would trigger
               errors, and examples (if any).</para>
            <para>The contents of this chapter have been generated automatically from the RELAX-NG
               schemas (XML syntax), the error database, and local examples.</para>
            <para>
               <xsl:value-of
                  select="'The ' || count($distinct-element-names) || ' elements and ' || count($distinct-attribute-names) || ' attributes defined in TAN, excluding TEI, are the following:'"
               />
            </para>
            <xsl:for-each
               select="$tan:rng-collection-without-TEI[tan:cfn(.) = $sequence-of-sections/descendant-or-self::*/@n]">
               <xsl:sort>
                  <xsl:variable name="this-cfn" as="xs:string?" select="tan:cfn(.)"/>
                  <xsl:copy-of
                     select="count($sequence-of-sections//*[@n = $this-cfn]/(preceding::*, ancestor-or-self::*))"
                  />
               </xsl:sort>
               <xsl:variable name="this-name" as="xs:string?" select="tan:cfn(.)"/>
               <para>
                  <emphasis>
                     <xsl:value-of select="$this-name"/>
                  </emphasis>
                  <xsl:for-each-group select=".//(rng:element, rng:attribute)[@name]" group-by="name(.) || ' ' || @name">
                     <xsl:sort select="lower-case(@name)"/>
                     <xsl:variable name="node-type" as="xs:string" select="name(current-group()[1])"/>
                     <xsl:variable name="node-name" as="xs:string" select="current-group()[1]/@name"/>
                     <xsl:copy-of
                        select="tan:prep-string-for-docbook(tan:string-representation-of-component($node-name, $node-type))"/>
                     <xsl:text> </xsl:text>
                  </xsl:for-each-group>
               </para>
            </xsl:for-each>
            
            
            <section>
               <title>TAN attributes</title>
               <xsl:for-each-group select="$attributes-excl-TEI" group-by="@name">
                  <xsl:sort select="lower-case(current-grouping-key())"/>
                  <xsl:call-template name="rng-node-to-docbook-section">
                     <xsl:with-param as="element()*" name="rng-element-or-attribute-group" select="current-group()"
                     />
                  </xsl:call-template>
               </xsl:for-each-group>
            </section>
            <section>
               <title>TAN elements</title>
               <xsl:for-each-group select="$elements-excl-TEI" group-by="@name">
                  <xsl:sort select="lower-case(current-grouping-key())"/>
                  <xsl:call-template name="rng-node-to-docbook-section">
                     <xsl:with-param as="element()*" name="rng-element-or-attribute-group" select="current-group()"
                     />
                  </xsl:call-template>
               </xsl:for-each-group>
            </section>
            <section>
               <title>TAN patterns</title>
               <xsl:for-each-group select="$tan:rng-collection-without-TEI//rng:define" group-by="@name">
                  <xsl:sort select="lower-case(@name)"/>
                  <xsl:call-template name="rng-node-to-docbook-section">
                     <xsl:with-param name="rng-element-or-attribute-group" as="element()*" select="current-group()"
                     />
                  </xsl:call-template>
               </xsl:for-each-group>
            </section>
         </chapter>
      </xsl:result-document>

      <!-- Docbook inclusion for vocabularies -->

      <xsl:result-document use-when="$generate-inclusion-for-vocabularies"
         href="{resolve-uri('../../guidelines/inclusions/vocabularies.xml', static-base-uri())}">
         <chapter version="5.0" xml:id="vocabularies-master-list">
            <xsl:variable name="intro-text" as="xs:string">In this section are collected all
               official TAN vocabularies, i.e., values of @which predefined by TAN for certain
               elements. Remember, these vocabularies are not @xml:id values, and do not fall under
               the same restrictions. They may contain punctuation, spaces, and so forth. For more
               on the use of these vocabularies, see @which, specific elements, or various examples. </xsl:variable>
            <title>Official TAN vocabularies</title>
            <para>
               <xsl:copy-of select="tan:prep-string-for-docbook(normalize-space($intro-text))"/>
            </para>
            <para>The vocabularies that begin <code>n.</code> and are located in the subdirectory
                  <code>/vocabularies/extra</code> are extra, and they must be explicitly invoked in
               a TAN file by means of 
               <code><link linkend="element-vocabulary">&lt;vocabulary</link> which="[VOCABULARY
                  NAME]"&gt;</code> in the declarations section of <code><link linkend="element-head"
                  >&lt;head&gt;</link></code>.</para>
            <xsl:copy-of select="$chapter-caveat"/>
            <xsl:for-each select="$vocabulary-collection">
               <xsl:sort select="tan:cfn(.)"/>
               <xsl:apply-templates select="." mode="vocabularies-to-docbook"/>
            </xsl:for-each>
         </chapter>
      </xsl:result-document>

      <!-- Docbook inclusion for variables, keys, functions, and templates -->

      <xsl:result-document use-when="$generate-inclusion-for-keys-functions-and-templates"
         href="{resolve-uri('../../guidelines/inclusions/variables-keys-functions-and-templates.xml',static-base-uri())}">
         <chapter version="5.0" xml:id="variables-keys-functions-and-templates">
            <title>TAN functions, templates, global variables, and keys</title>
            <para>This chapter provides a technical reference to all the functions, templates,
               global variables, and keys in the TAN Function Library. It is written primarily for
               developers who wish to use the TAN function library when programming their own
               applications.</para>
            <para>Dependencies refer exclusively to components of the TAN function library, both the
               core validation procedures and the extra functions. A variable, function, or template
               listed as not being relied upon may nevertheless have dependencies in the files in the
               subdirectories <code>applications</code> and <code>utilities</code>.</para>
            <para>Documentation is relatively good for functions, but not for global variables. For
               a discussino on important global variables, see 
               <xref xlink:href="#using-tan-global-variables"/></para>
            <xsl:copy-of select="$chapter-caveat"/>
            <section>
               <title>Indexes</title>
               <section xml:id="tan-function-keyword-index">
                  <title>Functions by group</title>
                  <xsl:for-each-group select="($function-library-functions)"
                     group-by="tokenize(replace(normalize-space(comment()[matches(., '^\s*kw:')][1]), '^\s*kw:\s*', ''), ',\s*')">
                     <xsl:sort select="lower-case(current-grouping-key())"/>
                     <xsl:variable name="this-keyword" as="xs:string"
                        select="lower-case(current-grouping-key())"/>
                     <xsl:variable name="this-keyword-entry" as="element()?"
                        select="$function-keyword-doc/*/tan:item[tan:keyword[lower-case(.) = $this-keyword]]"/>

                     <!-- keyword index -->
                     <section xml:id="tan-function-group-{replace(current-grouping-key(), ' ', '_')}">
                        <title><xsl:value-of select="current-grouping-key()"/></title>
                        <xsl:apply-templates select="$this-keyword-entry"
                           mode="function-keywords-to-docbook"/>
                        <para>
                           <itemizedlist>
                              <xsl:for-each-group select="current-group()" group-by="@name">
                                 <xsl:sort select="current-grouping-key()"/>
                                 <listitem>
                                    <para>

                                       <xsl:copy-of
                                          select="tan:prep-string-for-docbook(tan:string-representation-of-component(current-grouping-key(), 'function', false()), -1)"
                                       />
                                    </para>
                                 </listitem>

                              </xsl:for-each-group>
                           </itemizedlist>
                        </para>
                        
                     </section>
                     <xsl:text>
      </xsl:text>
                  </xsl:for-each-group>
                  
               </section>
               <section>
                  <title>All functions, keys, variables, and templates</title>
                  <para>
                     <xsl:value-of
                        select="
                        'The ' || count(distinct-values($function-library-variables/@name)) || ' global variables, ' || count(distinct-values($function-library-keys/@name)) || ' keys (ʞ = key), ' || count(distinct-values($function-library-functions/@name)) || ' functions, and ' || count(distinct-values(for $i in $function-library-templates/(@name, @mode)
                           return
                           tokenize($i, '\s+'))) || ' templates (Ŧ = named template; ŧ = template mode) defined in the TAN function library, are the following:'"
                     />
                  </para>
                  <xsl:for-each-group
                     select="($function-library-keys, $function-library-functions, 
                     $function-library-variables, $function-library-templates)"
                     group-by="
                        if (exists(@name)) then
                           substring(replace(@name, '^\w+:', ''), 1, 1)
                        else
                           for $i in tokenize(@mode, '\s+')
                           return
                              substring(replace($i, '^\w+:', ''), 1, 1)">
                     <xsl:sort select="lower-case(current-grouping-key())"/>
                     <xsl:variable name="this-letter" as="xs:string" select="lower-case(current-grouping-key())"/>
                     
                     <!-- alphabetical index -->
                     <para>
                        <xsl:for-each-group select="current-group()"
                           group-by="
                              if (exists(@name)) then
                                 (name() || ' ' || @name)
                              else
                                 for $i in tokenize(@mode, '\s+')[matches(lower-case(.), ('^' || $this-letter))]
                                 return
                                    (name() || ' ' || $i)">
                           <xsl:sort
                              select="lower-case(replace(tokenize(current-grouping-key(), '\s+')[2], '^\w+:', ''))"/>
                           <xsl:variable name="node-type-and-name" as="xs:string+"
                              select="tokenize(current-grouping-key(), '\s+')"/>
                           <xsl:copy-of
                              select="tan:prep-string-for-docbook(tan:string-representation-of-component($node-type-and-name[2], $node-type-and-name[1], exists(current-group()/@mode)), -1)"/>
                           <xsl:text> </xsl:text>
                        </xsl:for-each-group>
                     </para>
                     <xsl:text>
      </xsl:text>
                  </xsl:for-each-group>
                  
               </section>
            </section>
            
            <!-- First, group according to place in the TAN hierarchy the variables, keys, functions, and named templates, 
               which are all unique and so can take an id; because template modes spread out across components, they need 
               to be handled outside the TAN hierarchical structure -->
            <!-- replace(tan:cfn(.), '-functions', '') -->
            <section xml:id="vkft-summaries">
               <title>Functions, global variables, keys, and named templates</title>
               <para>Functions, global variables, keys, and named templates are summarized below, grouped by parent
                  subdirectory from the TAN function directory. For templates called by mode, see the next section.</para>
               
               <xsl:for-each-group group-by="replace(base-uri(.), '.+functions/([^/]+)/.+$', '$1')"
                  select="($function-library-keys, $function-library-functions[not(@name = $names-of-functions-to-append)], 
                  $function-library-variables-unique, $function-library-templates[@name])">
                  <xsl:sort
                     select="count($sequence-of-sections//*[@n = current-grouping-key()]/(preceding::*, ancestor-or-self::*))"
                  />
                  <xsl:variable name="this-subdirectory-name" as="xs:string" select="current-grouping-key()"/>
                  <xsl:variable name="these-components-to-traverse" as="element()*"
                     select="current-group()"/>
                  <section xml:id="vkft-{$this-subdirectory-name}">
                     <title>
                        <xsl:value-of
                           select="tan:initial-upper-case($this-subdirectory-name)"
                        />
                     </title>
                     <xsl:for-each-group select="$these-components-to-traverse" group-by="name()">
                        <!-- This is a group of variables, keys, functions, and named templates, but not template modes, 
                           which are handled later -->
                        <xsl:sort
                           select="index-of(('xsl:variable', 'xsl:key', 'xsl:function', 'xsl:template'), current-grouping-key())"/>
                        <xsl:variable name="this-type-of-component" as="xs:string"
                           select="replace(current-grouping-key(), 'xsl:(.+)', '$1')"/>
                        <section>
                           <title>
                              <xsl:value-of select="tan:title-case($this-type-of-component) || 's'"/>
                           </title>
                           <xsl:for-each-group select="current-group()" group-by="@name">
                              <!-- This is a group of variables, keys, functions, or named templates that share the same 
                                 name (grouping is mainly for functions) -->
                              <xsl:sort select="lower-case(@name)"/>
                              <xsl:variable name="what-depends-on-this" as="element()*"
                                 select="tan:xslt-dependencies(current-grouping-key(), $this-type-of-component, false(), $tan:all-functions)[name() = ('xsl:function', 'xsl:variable', 'xsl:template', 'xsl:key')]"/>
                              <xsl:variable name="this-group-count" as="xs:integer" select="count(current-group())"/>
                              <section
                                 xml:id="{$this-type-of-component || '-' || replace(current-grouping-key(),'^\w+:','')}">
                                 <title>
                                    <code>
                                       <xsl:value-of
                                          select="tan:string-representation-of-component(current-grouping-key(), $this-type-of-component)"
                                       />
                                    </code>
                                 </title>
                                 <xsl:for-each select="current-group()">
                                    <!-- This fetches an individual variable, key, function, or named template -->
                                    <para>
                                       <emphasis>
                                          <xsl:choose>
                                             <xsl:when test="$this-group-count gt 1">
                                                <xsl:value-of
                                                   select="'Option ' || position() || ' (' || tan:cfn(.) || ')'"/>
                                             </xsl:when>
                                             <xsl:otherwise>
                                                <xsl:value-of select="tan:cfn(.)"/>
                                             </xsl:otherwise>
                                          </xsl:choose>
                                       </emphasis>
                                    </para>
                                    
                                    <!-- Insert remarks specific to the type of component, e.g., the input and output expectations of a function -->
                                    <xsl:choose>
                                       <xsl:when test="$this-type-of-component = 'key'">
                                          <para>Looks for elements matching <code>
                                                <xsl:value-of select="@match"/>
                                             </code>
                                          </para>
                                       </xsl:when>
                                       <xsl:when test="$this-type-of-component = 'function'">
                                          <xsl:variable name="these-params" as="element()*" select="xsl:param"/>
                                          <xsl:variable name="param-text" as="xs:string*"
                                             select="
                                                for $i in $these-params
                                                return
                                                   '$' || $i/@name || (if (exists($i/@as)) then
                                                      (' as ' || $i/@as)
                                                   else
                                                      ())"/>
                                          <para>
                                             <code>
                                                <xsl:value-of select="@name"/>(<xsl:value-of
                                                   select="string-join($param-text, ', ')"/>) <xsl:if
                                                   test="exists(@as)">as <xsl:value-of select="@as"/>
                                                </xsl:if>
                                             </code>
                                          </para>
                                       </xsl:when>
                                       <xsl:when test="$this-type-of-component = 'variable'">
                                          <xsl:choose>
                                             <xsl:when test="exists(@select)">
                                                <para>
                                                   <xsl:text>Definition: </xsl:text>
                                                   <code>
                                                     <xsl:copy-of
                                                     select="tan:copy-of-except(tan:prep-string-for-docbook(@select), (), (), (), (), 'code')"
                                                     />
                                                   </code>
                                                </para>
                                             </xsl:when>
                                             <xsl:when test="exists(text()[matches(., '\S')]) and not(exists(*))">
                                                <para>
                                                   <xsl:text>Definition: </xsl:text>
                                                   <code>
                                                     <xsl:copy-of
                                                     select="tan:copy-of-except(tan:prep-string-for-docbook(string(.)), (), (), (), (), 'code')"
                                                     />
                                                   </code>
                                                </para>
                                             </xsl:when>
                                             <xsl:otherwise>
                                                <para>This variable has a complex definition. See
                                                   stylesheet for definiton.</para>
                                             </xsl:otherwise>
                                          </xsl:choose>
                                       </xsl:when>
                                    </xsl:choose>
                                    <!-- Insert prefatory comments placed inside the component -->
                                    <xsl:copy-of select="tan:component-comments-to-docbook(.)"/>
                                    <!-- State what depends on this -->
                                    <xsl:copy-of select="tan:component-dependees-to-docbook(.)"/>
                                    <!-- State what it depends upon -->
                                    <xsl:copy-of select="tan:component-dependencies-to-docbook(.)"/>
                                 </xsl:for-each>
                              </section>
                              <xsl:text>
</xsl:text>
                           </xsl:for-each-group>
                        </section>
                        <xsl:text>
</xsl:text>
                     </xsl:for-each-group>
                     <xsl:if test="not(exists($these-components-to-traverse))">
                        <para>
                           <xsl:value-of
                              select="'No variables, keys, functions, or named templates are defined for ' || $this-subdirectory-name || '.'"
                           />
                        </para>
                     </xsl:if>
                  </section>
                  <xsl:text>
</xsl:text>
               </xsl:for-each-group>
            </section>
            <xsl:for-each-group
               select="($function-library-templates[@mode], $function-library-variables-duplicate, $function-library-functions[@name = $names-of-functions-to-append])"
               group-by="name()">
               <xsl:variable name="this-type-of-component" as="xs:string"
                  select="replace(current-grouping-key(), '^.+:', '')"/>
               <section xml:id="vkft-{$this-type-of-component}">
                  <xsl:choose>
                     <xsl:when test="$this-type-of-component = 'variable'">
                        <title>Cross-format global variables</title>
                        <para>Global variables that straddle different files in the TAN function
                           library.</para>
                     </xsl:when>
                     <xsl:when test="$this-type-of-component = 'function'">
                        <title>Cross-format functions</title>
                        <para>Some function definitions differ from one TAN format to
                           another.</para>
                     </xsl:when>
                     <xsl:otherwise>
                        <title>Templates (by mode)</title>
                        <para>Templates based on modes are frequently found in multiple files and
                           directories, so they are collated here separately, one entry per
                           mode.</para>
                     </xsl:otherwise>
                  </xsl:choose>
                  <xsl:for-each-group select="current-group()" group-by="tokenize((@mode, @name)[1], '\s+')">
                     <xsl:sort select="lower-case(current-grouping-key())"/>
                     <xsl:variable name="this-template-id" as="xs:string"
                        select="$this-type-of-component || '-' || replace(current-grouping-key(), '#|^.+:', '')"
                     />
                     <section xml:id="{$this-template-id}">
                        <title>
                           <code>
                              <xsl:value-of
                                 select="tan:string-representation-of-component(current-grouping-key(), $this-type-of-component, exists(current-group()/@mode))"
                              />
                           </code>
                        </title>
                        <xsl:for-each-group select="current-group()" group-by="tan:cfn(.)">
                           <bridgehead>
                              <code>
                                 <xsl:value-of select="current-grouping-key() || '.xsl '"/>
                              </code>
                           </bridgehead>
                           <xsl:copy-of select="tan:component-comments-to-docbook(current-group())"/>
                        </xsl:for-each-group>
                        <xsl:copy-of select="tan:component-dependees-to-docbook(current-group()[1])"/>
                        <xsl:copy-of select="tan:component-dependencies-to-docbook(current-group())"
                        />
                     </section>
                  </xsl:for-each-group>
               </section>
            </xsl:for-each-group>
         </chapter>
      </xsl:result-document>

      <!-- Docbook inclusion for errors -->

      <xsl:result-document use-when="$generate-inclusion-for-errors"
         href="{resolve-uri('../../guidelines/inclusions/errors.xml',static-base-uri())}">
         <chapter version="5.0" xml:id="errors">
            <title>Errors</title>
            <para>Below is a list of <xsl:value-of select="count($tan:errors//*[@xml:id])"/>
               specifically defined TAN errors.</para>
            <xsl:copy-of select="$chapter-caveat"/>
            <xsl:for-each select="$tan:errors//*[@xml:id]">
               <xsl:sort select="@xml:id"/>
               <xsl:apply-templates select="." mode="errors-to-docbook"/>
            </xsl:for-each>
         </chapter>
      </xsl:result-document>
   </xsl:template>
   
   
   <xslq:parameters>
      <xslq:use-oxygen-documentation>false</xslq:use-oxygen-documentation>
      <xslq:allow-no-namespace>true</xslq:allow-no-namespace>
   </xslq:parameters>

</xsl:stylesheet>
