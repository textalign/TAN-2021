<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library file functions. -->
   
   <xsl:function name="tan:first-loc-available" as="xs:string?" visibility="public">
      <!-- Input: An element that is or contains one or more tan:location elements -->
      <!-- Output: the value of the first tan:location/@href to point to a document available, resolved. If no location is available nothing is returned. -->
      <!--kw: files -->
      <xsl:param name="element-with-href-in-self-or-descendants" as="element()?"/>
      <xsl:variable name="context-base-uri"
         select="tan:base-uri($element-with-href-in-self-or-descendants)" as="xs:anyURI"/>
      <xsl:iterate select="$element-with-href-in-self-or-descendants//@href">
         <xsl:variable name="this-href-is-local" as="xs:boolean" select="tan:url-is-local(.)"/>
         <xsl:variable name="this-href-resolved" select="resolve-uri(., $context-base-uri)"/>
         <xsl:variable name="this-href-fetches-something" as="xs:boolean" select="
               if ($this-href-is-local or $tan:internet-available)
               then
                  doc-available($this-href-resolved)
               else
                  false()"/>
         <xsl:choose>
            <xsl:when test="$this-href-fetches-something">
               <xsl:sequence select="$this-href-resolved"/>
               <xsl:break/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:next-iteration/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:iterate>
   </xsl:function>
   
   
   <xsl:function name="tan:url-is-local" as="xs:boolean" visibility="public">
      <!--Input: a string representing a URL-->
      <!--Output: true if the URL syntactically appears to be local -->
      <!--kw: files, filenames -->
      <xsl:param name="url-to-test" as="xs:string?"/>
      <xsl:variable name="url-norm" select="normalize-space($url-to-test)" as="xs:string"/>
      <xsl:sequence
         select="string-length($url-norm) lt 1 or not(matches($url-norm, '^(https?|ftp)://'))"/>
   </xsl:function>
   
   
   <xsl:function name="tan:get-1st-doc" as="document-node()*" visibility="public">
      <!-- Input: any TAN elements naming files (e.g., <source>, <see-also>, <inclusion>, <vocabulary> -->
      <!-- Output: the first document available for each element, plus any relevant error messages. -->
      <!--kw: files -->
      <xsl:param name="TAN-elements" as="element()*"/>
      <xsl:for-each select="$TAN-elements">
         <xsl:variable name="this-element" select="."/>
         <xsl:variable name="this-element-name" select="name(.)"/>
         <xsl:variable name="this-base-uri" select="tan:base-uri(.)"/>
         <xsl:variable name="this-element-resolved" as="element()*">
            <xsl:choose>
               <xsl:when test="exists($this-element//@href)">
                  <xsl:sequence select="$this-element"/>
               </xsl:when>
               <xsl:when test="exists(@which)">
                  <xsl:copy-of select="tan:element-vocabulary($this-element)/tan:item"/>
               </xsl:when>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="this-element-norm" as="element()*">
            <xsl:apply-templates select="$this-element-resolved" mode="tan:resolve-href">
               <xsl:with-param name="base-uri" tunnel="yes" select="$this-base-uri"/>
            </xsl:apply-templates>
         </xsl:variable>
         <xsl:variable name="is-master-location" select="$this-element-name = ('master-location')"/>
         <xsl:variable name="is-different-version" select="$this-element-name = ('successor', 'predecessor')"/>
         <xsl:variable name="this-class" select="tan:class-number(.)"/>
         <xsl:variable name="first-la" as="xs:string?" select="tan:first-loc-available($this-element-norm[1])"/>
         <xsl:variable name="this-id" select="root(.)/*/@id"/>
         <xsl:variable name="these-unpatterned-hrefs" select="$this-element-norm//@href[not(matches(., '[*?]'))]"/>
         <xsl:variable name="some-href-is-local"
            select="
            some $i in $these-unpatterned-hrefs
            satisfies tan:url-is-local($i)"/>
         
         <xsl:variable name="diagnostics-on" select="false()"/>
         <xsl:if test="$diagnostics-on">
            <xsl:message select="'diagnostics on for tan:get-1st-doc()'"/>
            <xsl:message select="'this element: ', tan:xml-to-string($this-element)"/>
            <xsl:message select="'this element root: ', tan:xml-to-string(tan:shallow-copy(root(.)/*))"/>
            <xsl:message select="'this base uri: ', $this-base-uri"/>
            <xsl:message select="'this element resolved: ', tan:xml-to-string($this-element-resolved)"/>
            <xsl:message select="'this element normalized: ', tan:xml-to-string($this-element-norm)"/>
            <xsl:message select="'some @href is local?', $some-href-is-local"/>
            <xsl:message select="'first location available: ', $first-la"/>
         </xsl:if>
         
         <xsl:choose>
            <xsl:when test="not(exists($these-unpatterned-hrefs))"/>
            <xsl:when test="string-length($first-la) lt 1">
               <xsl:variable name="this-base-uri" select="tan:base-uri(.)"/>
               <xsl:variable name="these-hrefs-resolved" select="tan:resolve-href(.)"/>
               <!--<xsl:variable name="these-tan-catalog-uris" select="
                     for $i in $these-hrefs-resolved//@href
                     return
                        replace($i, '[^/]+$', 'catalog.tan.xml')"/>-->
               <!--<xsl:variable name="these-tan-catalogs" as="document-node()*"
                  select="doc($these-tan-catalog-uris[doc-available(.)])"/>-->
               <xsl:variable name="these-tan-catalogs" as="document-node()*"
                  select="tan:catalogs($this-element, false())"/>
               <xsl:variable name="these-IRIs" select="
                     if (self::tan:master-location) then
                        root()/*/@id
                     else
                        (descendant-or-self::tan:IRI | preceding-sibling::tan:IRI)"/>
               <xsl:variable name="possible-docs" as="element()*">
                  <xsl:apply-templates select="$these-tan-catalogs//doc[@id = $these-IRIs]"
                     mode="tan:resolve-href"/>
               </xsl:variable>
               <xsl:variable name="possible-hrefs" as="element()*">
                  <xsl:for-each select="$possible-docs/@href">
                     <fix href="{tan:uri-relative-to(., string($this-base-uri))}"/>
                  </xsl:for-each>
               </xsl:variable>
               <xsl:variable name="this-message-raw" as="xs:string*">
                  <xsl:value-of select="'No XML document found found at ' || string-join($these-unpatterned-hrefs, ' ')"/>
                  <xsl:if test="exists($possible-hrefs)">
                     <xsl:value-of
                        select="' For @href try: ' || string-join($possible-hrefs/@href, ', ')"
                     />
                  </xsl:if>
               </xsl:variable>
               <xsl:variable name="this-message" select="string-join($this-message-raw, '')"/>
               <xsl:document>
                  <xsl:choose>
                     <xsl:when test="not($some-href-is-local) and not($tan:internet-available)">
                        <xsl:copy-of select="tan:error('wrn09')"/>
                     </xsl:when>
                     <xsl:when test="self::tan:inclusion">
                        <xsl:copy-of
                           select="tan:error('inc04', $this-message, $possible-hrefs, 'replace-attributes')"
                        />
                     </xsl:when>
                     <xsl:when test="self::tan:vocabulary">
                        <xsl:copy-of
                           select="tan:error('whi04', $this-message, $possible-hrefs, 'replace-attributes')"
                        />
                     </xsl:when>
                     <xsl:when test="self::tan:master-location">
                        <xsl:copy-of
                           select="tan:error('wrn01', $this-message, $possible-hrefs, 'replace-attributes')"
                        />
                     </xsl:when>
                     <!-- Skip <source> in class 1 files when the URL points to non-XML. -->
                     <!-- Skip <predecessor>s, since they may be non-TAN files. -->
                     <xsl:when test="
                           ((self::tan:source and ($this-class = 1)) or self::tan:predecessor) 
                           and (some $i in $these-unpatterned-hrefs
                              satisfies (unparsed-text-available($i)) or doc-available('zip:' || $i || '!/_rels/.rels'))"
                     />
                     <xsl:when
                        test="self::tan:source and not(exists(tan:location)) and tan:tan-type(.) = 'TAN-mor'"/>
                     <xsl:when test="self::tan:algorithm or self::tan:see-also">
                        <xsl:copy-of
                           select="tan:error('loc04', $this-message, $possible-hrefs, 'replace-attributes')"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of
                           select="tan:error('loc01', $this-message, $possible-hrefs, 'replace-attributes')"
                        />
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:document>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-doc" select="doc($first-la)"/>
               <xsl:choose>
                  <xsl:when
                     test="($this-doc/*/@id = $this-id) and not($is-master-location or $is-different-version)">
                     <!-- If the @id is identical, something is terribly wrong; to avoid possible endless recursion, the document is not returned -->
                     <xsl:document>
                        <error>
                           <xsl:copy-of select="$this-doc/*/@*"/>
                           <xsl:copy-of select="tan:error('tan16')/@*"/>
                           <xsl:copy-of select="tan:error('tan16')/*"/>
                        </error>
                     </xsl:document>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="$this-doc"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   
</xsl:stylesheet>
