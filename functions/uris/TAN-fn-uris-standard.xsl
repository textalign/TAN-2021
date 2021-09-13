<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library URI functions. -->
   
   <xsl:function name="tan:cfn" as="xs:string*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the Current File Name, without extension, of the host document node of each item, or of the input string if detected as a uri -->
      <!--kw: uris, filenames -->
      <xsl:param name="item" as="item()*"/>
      <xsl:for-each select="$item">
         <xsl:variable name="this-base" select="
               if (. instance of text() or . instance of xs:string or . instance of xs:anyURI) then
                  .
               else
                  tan:base-uri(.)"/>
         <xsl:value-of select="replace(tan:cfne($this-base), '\.[^.]*$', '')"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:cfne" as="xs:string*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the Current File Name, with Extension, of the host document node of each item, or of the input string if detected as a uri -->
      <!--kw: uris, filenames -->
      <xsl:param name="item" as="item()*"/>
      <xsl:for-each select="$item">
         <xsl:variable name="this-base"
            select="
               if (. instance of text() or . instance of xs:string or . instance of xs:anyURI) then
                  .
               else
                  tan:base-uri(.)"
         />
         <xsl:sequence select="(tokenize(string($this-base), '/')[string-length(.) gt 0])[last()]"/>
         <!--<xsl:value-of select="replace(xs:string($this-base), '.+/([^/]*)$', '$1')"/>-->
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:is-valid-uri" as="xs:boolean?" visibility="public">
      <!-- Input: a string -->
      <!-- Output: a boolean indicating whether the string is syntactically a valid uri -->
      <!-- This assumes not only absolute but relative uris will be checked, which means that a wide 
         variety of characters could be fed in, but not ones disallowed in pathnames, and the string must 
         not be zero length. -->
      <!--kw: uris -->
      <xsl:param name="uri-to-check" as="xs:string?"/>
      <xsl:copy-of select="not(matches($uri-to-check, '[\{\}\|\\\^\[\]`]')) and (string-length($uri-to-check) gt 0)"/>
   </xsl:function>
   
   <xsl:function name="tan:uri-directory" as="xs:string*" visibility="public">
      <!-- Input: any URIs, as strings -->
      <!-- Output: the file path -->
      <!-- NB, this function does not assume any URIs have been resolved; its only 
         action is syntactic, ensuring that each URI specifies a directory path, i.e.,
         has a trailing slash. -->
      <!--kw: uris, filenames -->
      <xsl:param name="uris" as="xs:string*"/>
      <xsl:for-each select="$uris">
         <xsl:choose>
            <xsl:when test="matches(., '/')">
               <xsl:value-of select="replace(., '(.*/)[^/]+$', '$1')"/>
            </xsl:when>
            <!-- If the directory uri does not have slashes, it is the name of a 
               local file, so the actual directory is the present working directory,
               represented by '.' -->
            <xsl:otherwise>.</xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:base-uri" as="xs:anyURI" visibility="public">
      <!-- Input: any node -->
      <!-- Output: the base uri of the node's document -->
      <!-- An explicit @xml:base has the highest priority over any native base-uri(). If the node is a fragment and has no declared or detected
         base uri, the static-base-uri() will be returned -->
      <!--kw: uris -->
      <xsl:param name="any-node" as="node()?"/>
      <xsl:variable name="specified-ancestral-xml-base-attrs" select="$any-node/ancestor-or-self::*[@xml:base], root($any-node)/*[@xml:base]"/>
      <xsl:variable name="default-xml-base" select="base-uri($any-node)"/>
      <xsl:choose>
         <xsl:when test="exists($specified-ancestral-xml-base-attrs)">
            <xsl:sequence select="$specified-ancestral-xml-base-attrs[1]/@xml:base"/>
         </xsl:when>
         <xsl:when test="string-length($default-xml-base) gt 0">
            <xsl:sequence select="$default-xml-base"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="static-base-uri()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:uri-relative-to" as="xs:string?" visibility="public">
      <!-- 2-parameter version of the one below -->
      <xsl:param name="uri-to-revise" as="xs:string?"/>
      <xsl:param name="uri-to-revise-against" as="xs:string?"/>
      <xsl:copy-of select="tan:uri-relative-to($uri-to-revise, $uri-to-revise-against, string(resolve-uri($uri-to-revise-against)))"/>
   </xsl:function>
   
   <xsl:function name="tan:uri-relative-to" as="xs:string?" visibility="public">
      <!-- Input: two strings representing URIs; a third representing the base against which the first two should be resolved -->
      <!-- Output: the first string in a form relative to the second string -->
      <!-- This function looks for common paths within two absolute URIs and tries to convert the first URI as a relative path -->
      <!--kw: uris, filenames -->
      <xsl:param name="uri-to-revise" as="xs:string?"/>
      <xsl:param name="uri-to-revise-against" as="xs:string?"/>
      <xsl:param name="base-uri" as="xs:string?"/>
      
      <xsl:variable name="uri-a-resolved"
         select="
            if (tan:is-valid-uri($uri-to-revise)) then
               resolve-uri($uri-to-revise, $base-uri)
            else
               ()"
      />
      <xsl:variable name="uri-b-resolved"
         select="
            if (tan:is-valid-uri($uri-to-revise-against)) then
               resolve-uri($uri-to-revise-against, $base-uri)
            else
               ()"
      />
      <!-- If URI b ends in a path indicator, add a dummy string so that its path is picked. -->
      <xsl:variable name="uri-b-normalized" select="replace($uri-b-resolved, '/$', '/.')"/>
      <xsl:variable name="path-a" as="element()">
         <path-a>
            <xsl:if test="string-length($uri-a-resolved) gt 0">
               <xsl:analyze-string select="$uri-a-resolved" regex="/">
                  <xsl:non-matching-substring>
                     <step>
                        <xsl:sequence select="."/>
                     </step>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:if>
         </path-a>
      </xsl:variable>
      <xsl:variable name="path-b" as="element()">
         <path-b>
            <xsl:if test="string-length($uri-b-normalized) gt 0">
               <xsl:analyze-string select="$uri-b-normalized" regex="/">
                  <xsl:non-matching-substring>
                     <step>
                        <xsl:value-of select="."/>
                     </step>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:if>
         </path-b>
      </xsl:variable>
      <xsl:variable name="path-a-steps" select="count($path-a/tan:step)" as="xs:integer"/>
      <xsl:variable name="last-common-step" select="
            (for $i in (1 to $path-a-steps)
            return
               if (lower-case($path-a/tan:step[$i]) eq lower-case($path-b/tan:step[$i])) then
                  ()
               else
                  $i)[1] - 1"/>
      <xsl:variable name="new-path-a" as="element()">
         <path-a>
            <xsl:for-each
               select="$path-b/(tan:step[position() gt $last-common-step] except tan:step[last()])">
               <step>..</step>
            </xsl:for-each>
            <xsl:copy-of select="$path-a/tan:step[position() gt $last-common-step]"/>
         </path-a>
      </xsl:variable>
      <xsl:variable name="output-path" select="string-join($new-path-a/tan:step, '/')"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:uri-relative-to()'"/>
         <xsl:message select="'uri to revise (a)', $uri-to-revise"/>
         <xsl:message select="'uri to revise against (b)', $uri-to-revise-against"/>
         <xsl:message select="'base uri: ', $base-uri"/>
         <xsl:message select="'uri a resolved: ', $uri-a-resolved"/>
         <xsl:message select="'uri b resolved: ', $uri-b-resolved"/>
         <xsl:message select="'path a: ', $path-a"/>
         <xsl:message select="'path b: ', $path-b"/>
         <xsl:message select="'last common step: ', $last-common-step"/>
         <xsl:message select="'new a path:', $new-path-a"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="matches($uri-to-revise, '^https?://')">
            <xsl:value-of select="$uri-to-revise"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$output-path"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:uri-is-relative" as="xs:boolean?" visibility="public">
      <!-- Input: a string representing a URI -->
      <!-- Output: a boolean indicating whether it is relative -->
      <!--kw: uris -->
      <xsl:param name="uri-to-test" as="xs:string?"/>
      <xsl:sequence select="not(tan:uri-is-resolved($uri-to-test))"/>
   </xsl:function>
   <xsl:function name="tan:uri-is-resolved" as="xs:boolean?" visibility="public">
      <!-- Input: a string representing a URI -->
      <!-- Output: a boolean indicating whether it is resolved -->
      <!--kw: uris -->
      <xsl:param name="uri-to-test" as="xs:string?"/>
      <xsl:sequence select="$uri-to-test eq resolve-uri($uri-to-test)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:catalog-uris" as="xs:string*" visibility="public">
      <!-- Input: a node from an XML file -->
      <!-- Output: URLs for locally available TAN catalog files, beginning with the immediate subdirectory and proceeding rootward -->
      <!--kw: uris, filenames -->
      <xsl:param name="input-node" as="node()?"/>
      <xsl:variable name="this-uri" select="tan:base-uri($input-node)"/>
      <xsl:variable name="doc-uri-steps" select="tokenize(string($this-uri), '/')"/>
      <xsl:for-each select="2 to count($doc-uri-steps)">
         <xsl:sort order="descending"/>
         <xsl:variable name="this-pos" select="." as="xs:integer"/>
         <xsl:variable name="this-dir-to-check"
            select="string-join($doc-uri-steps[position() le $this-pos], '/')"/>
         <xsl:variable name="this-uri-to-check"
            select="$this-dir-to-check || '/catalog.tan.xml'"/>
         <xsl:if test="doc-available($this-uri-to-check)">
            <xsl:value-of select="$this-uri-to-check"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:catalogs" as="document-node()*" visibility="public">
      <!-- Input: a node from an XML file; a boolean indicating whether bad @hrefs should be stripped -->
      <!-- Output: the TAN catalog documents available, beginning with the most local path and proceeding rootward -->
      <!--kw: uris, filenames -->
      <xsl:param name="input-node" as="node()?"/>
      <xsl:param name="strip-bad-hrefs" as="xs:boolean"/>
      <xsl:variable name="these-uris" select="tan:catalog-uris($input-node)" as="xs:string*"/>
      <xsl:for-each select="$these-uris">
         <xsl:choose>
            <xsl:when test="$strip-bad-hrefs">
               <xsl:variable name="this-uri" select="." as="xs:string"/>
               <xsl:variable name="this-doc" select="doc(.)" as="document-node()"/>
               <xsl:apply-templates select="$this-doc" mode="tan:cut-faulty-hrefs">
                  <xsl:with-param name="base-uri" select="$this-uri" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="doc(.)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:mode name="tan:cut-faulty-hrefs" on-no-match="shallow-copy"/>
   
   <xsl:template match="/collection/doc[@href]" mode="tan:cut-faulty-hrefs">
      <xsl:param name="base-uri" tunnel="yes" as="xs:string" select="base-uri(.)"/>
      <xsl:variable name="this-href" select="@href" as="xs:string"/>
      <xsl:variable name="href-resolved" select="resolve-uri(@href, $base-uri)" as="xs:anyURI"/>
      <xsl:variable name="is-web-based" select="matches($this-href, '^(ftps?|https?)://')" as="xs:boolean"/>
      
      <xsl:choose>
         <xsl:when test="($is-web-based and not($tan:internet-available)) or doc-available($href-resolved)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="href" select="$href-resolved"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of
               select="tan:error('cat01', ('In catalog file ' || $base-uri || ' no document available at ' || $this-href))"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>


   <xsl:function name="tan:collection" as="document-node()*" visibility="public">
      <!-- One-parameter version of the master one, below -->
      <xsl:param name="catalog-docs" as="document-node()*"/>
      <xsl:copy-of select="tan:collection($catalog-docs, (), (), ())"/>
   </xsl:function>
   
   <xsl:function name="tan:collection" as="document-node()*" visibility="public">
      <!-- Input: one or more catalog.tan.xml files; filtering parameters -->
      <!-- Output: documents that are available -->
      <!--kw: uris, filenames -->
      <xsl:param name="catalog-docs" as="document-node()*"/>
      <xsl:param name="root-names" as="xs:string*"/>
      <xsl:param name="id-matches" as="xs:string?"/>
      <xsl:param name="href-matches" as="xs:string?"/>
      <xsl:for-each select="$catalog-docs">
         <xsl:variable name="this-base-uri" select="tan:base-uri(.)"/>
         <xsl:for-each select="collection/doc">
            <xsl:variable name="root-test" select="count($root-names) lt 1 or @root = $root-names"/>
            <xsl:variable name="id-test"
               select="
                  if (string-length($id-matches) gt 0) then
                     matches(@id, $id-matches)
                  else
                     true()"/>
            <xsl:variable name="href-test"
               select="
                  if (string-length($href-matches) gt 0) then
                     matches(@href, $href-matches)
                  else
                     true()"/>
            <xsl:if test="$root-test and $id-test and $href-test">
               <xsl:variable name="this-uri" select="resolve-uri(@href, string($this-base-uri))"/>
               <xsl:choose>
                  <xsl:when test="doc-available($this-uri)">
                     <xsl:sequence select="doc($this-uri)"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:document>
                        <xsl:copy-of
                           select="tan:error('cat01', ('In catalog file ' || $this-base-uri || ' no document available at ' || @href))"
                        />
                     </xsl:document>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:if>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   



</xsl:stylesheet>
