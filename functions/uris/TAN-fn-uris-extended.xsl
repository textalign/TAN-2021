<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended URI functions. -->
   
   <xsl:function name="tan:absolutize-hrefs" as="item()*" visibility="public">
      <!-- Input: any items that should have urls converted to absolute URIs; a string 
         representing the base uri -->
      <!-- Output: the items with each @href (also in processing instructions) and html:*/src 
         resolved against the input base uri -->
      <!--kw: uris, filenames, tree manipulation -->
      <xsl:param name="items-to-resolve" as="item()*"/>
      <xsl:param name="items-base-uri" as="xs:string"/>
      <xsl:apply-templates select="$items-to-resolve" mode="tan:revise-hrefs">
         <xsl:with-param name="original-url" select="$items-base-uri" tunnel="yes"/>
         <xsl:with-param name="make-absolute" tunnel="yes" select="true()" as="xs:boolean"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:function name="tan:revise-hrefs" as="item()*" visibility="public">
      <!-- Input: an item that should have urls resolved; the original url of the item; the target url (the item's destination) -->
      <!-- Output: the item with each @href (including those in processing instructions) and html:*/@src resolved -->
      <!--kw: uris, filenames, tree manipulation -->
      <xsl:param name="items-to-resolve" as="item()?"/>
      <xsl:param name="items-original-url" as="xs:string"/>
      <xsl:param name="items-destination-url" as="xs:string"/>
      <xsl:variable name="original-url-resolved" select="resolve-uri($items-original-url)"/>
      <xsl:variable name="destination-url-resolved" select="resolve-uri($items-destination-url)"/>
      <xsl:if test="not($items-original-url = $original-url-resolved)">
         <xsl:message select="'tan:revise-hrefs() warning: param 2 url, ', $items-original-url, ', does not match resolved state: ', $original-url-resolved"/>
      </xsl:if>
      <xsl:if test="not($items-destination-url = $destination-url-resolved) and not(not($items-original-url = $original-url-resolved))">
         <xsl:message select="'tan:revise-hrefs() warning: param 3 url, ', $items-destination-url, ', does not match resolved state: ', $destination-url-resolved"/>
      </xsl:if>
      <xsl:apply-templates select="$items-to-resolve" mode="tan:revise-hrefs">
         <xsl:with-param name="original-url" select="$items-original-url" tunnel="yes"/>
         <xsl:with-param name="target-url" select="$items-destination-url" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:revise-hrefs" on-no-match="shallow-copy"/>
   
   <xsl:template match="processing-instruction()" priority="1" mode="tan:revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" as="xs:string" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" as="xs:string?"/>
      <xsl:param name="make-absolute" tunnel="yes" as="xs:boolean?"/>

      <xsl:variable name="href-regex" as="xs:string">(href=['"])([^'"]+)(['"])</xsl:variable>
      <xsl:variable name="new-pi-content" as="xs:string*">
         <xsl:analyze-string select="." regex="{$href-regex}">
            <xsl:matching-substring>
               <xsl:variable name="this-replacement" as="xs:string" select="
                     if ($make-absolute) then
                        resolve-uri(regex-group(2), $original-url)
                     else
                        tan:uri-relative-to(resolve-uri(regex-group(2), $original-url), $target-url)"/>
               <xsl:value-of select="regex-group(1) || $this-replacement || regex-group(3)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>

      </xsl:variable>
      
      <xsl:processing-instruction name="{name(.)}" select="$new-pi-content"/>
   </xsl:template>
   
   <xsl:template match="@href" mode="tan:revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" as="xs:string" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" as="xs:string?"/>
      <xsl:param name="make-absolute" tunnel="yes" as="xs:boolean?"/>
      
      <xsl:variable name="this-href-resolved" select="resolve-uri(., $original-url)" as="xs:anyURI"
      />
      <xsl:variable name="this-href-relative" as="xs:string"
         select="
            if ($make-absolute) then
               $this-href-resolved
            else
               tan:uri-relative-to($this-href-resolved, $target-url)"/>
      <xsl:choose>
         <xsl:when test="matches(., '^#')">
            <xsl:copy/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:attribute name="href" select="$this-href-relative"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="html:script/@src" mode="tan:revise-hrefs">
      <xsl:param name="original-url" tunnel="yes" as="xs:string" required="yes"/>
      <xsl:param name="target-url" tunnel="yes" as="xs:string?"/>
      <xsl:param name="make-absolute" tunnel="yes" as="xs:boolean?"/>
      <xsl:attribute name="src" select="
            if ($make-absolute) then
               resolve-uri(., $original-url)
            else
               tan:uri-relative-to(resolve-uri(., $original-url), $target-url)"/>
   </xsl:template>
   
   
   <xsl:function name="tan:parse-urls" as="element()*" visibility="public">
      <!-- Input: any sequence of strings -->
      <!-- Output: one element per string, parsed into children <non-url> and <url> -->
      <!--kw: uris -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:for-each select="$input-strings">
         <string>
            <xsl:analyze-string select="." regex="{$tan:url-regex}">
               <xsl:matching-substring>
                  <url>
                     <xsl:value-of select="."/>
                  </url>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <non-url>
                     <xsl:value-of select="."/>
                  </non-url>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </string>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:get-uuid" visibility="public">
      <!-- zero-param version of the full one below -->
      <xsl:sequence select="tan:get-uuid(1)"/>
   </xsl:function>
   
   <xsl:function name="tan:get-uuid" as="xs:string*" visibility="public">
      <!-- Input: a digit -->
      <!-- Output: that digit's quantity of UUIDs -->
      <!-- Code courtesy D. Novatchev, https://stackoverflow.com/questions/8126963/xslt-generate-uuid/64792196#64792196 -->
      <!--kw: uris -->
      <xsl:param name="quantity" as="xs:integer"/>
      <xsl:sequence select="
            for $i in 1 to $quantity
            return
               unparsed-text('https://uuidgen.org/api/v/4?x=' || $i)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:relativize-hrefs" as="item()*" visibility="public">
      <!-- Input: any items; a resolved base uri (target) -->
      <!-- Output: the items, with links in standard attributes such as @href changed so as
         to be relative to the target base uri. -->
      <!-- This function is intended to serve output that is going to a particular destination,
      and that needs to have links to nearby resources revised to their relative form. -->
      <!--kw: uris, filenames, tree manipulation -->
      <xsl:param name="input-items" as="item()*"/>
      <xsl:param name="target-base-uri-resolved" as="xs:string"/>
      
      <xsl:choose>
         <xsl:when test="tan:uri-is-relative($target-base-uri-resolved)">
            <xsl:message
               select="'Items returned unchanged because target base uri is not resolved. Fix: ' || $target-base-uri-resolved"
            />
            <xsl:sequence select="$input-items"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="$input-items" mode="tan:relativize-hrefs">
               <xsl:with-param name="target-base-uri-resolved" select="$target-base-uri-resolved" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:relativize-hrefs" on-no-match="shallow-copy"/>
   
   <xsl:template match="processing-instruction()" mode="tan:relativize-hrefs">
      <xsl:param name="target-base-uri-resolved" required="yes" as="xs:string" tunnel="yes"/>
      <xsl:variable name="href-regex" as="xs:string">(href=['"])([^'"]+)(['"])</xsl:variable>
      <xsl:processing-instruction name="{name(.)}">
            <xsl:analyze-string select="." regex="{$href-regex}">
                <xsl:matching-substring>
                   <xsl:choose>
                      <xsl:when test="tan:uri-is-resolved(regex-group(2))">
                        <xsl:value-of select="regex-group(1) || tan:uri-relative-to(regex-group(2), $target-base-uri-resolved) || regex-group(3)"/>
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
        </xsl:processing-instruction>
   </xsl:template>
   
   <xsl:template match="@href | html:script/@src" mode="tan:relativize-hrefs">
      <xsl:param name="target-base-uri-resolved" required="yes" as="xs:string" tunnel="yes"/>
      <xsl:attribute name="{name(.)}" select="
            if (tan:uri-is-resolved(.)) then
               tan:uri-relative-to(., $target-base-uri-resolved)
            else
               ."/>
   </xsl:template>
   
   <xsl:function name="tan:doc-available" as="xs:boolean" visibility="public">
      <!-- Input: a string -->
      <!-- Output: true if an XML document is available at the URI, false otherwise -->
      <!-- This is a surrogate function to fn:doc-available, and behaves exactly the same, but avoids the possibility
         of read conflicts, so a file can be overwritten. -->
      <!-- An alternative to this is to make sure that when writing a secondary result document the last / is doubled;
         the string will not be recognized as a duplicate of what was read. -->
      <!-- kw: files, uris -->
      <xsl:param name="uri" as="xs:string?"/>
      <xsl:variable name="doc-available-transform-map" as="map(*)" select="
            map {
               'stylesheet-location': 'TAN-fn-uris-read-incognito.xsl',
               'initial-function': QName('tag:textalign.net,2015:ns', 'doc-available'),
               'function-params': array {$uri}
            }"/>
      <xsl:variable name="result-map" as="map(*)" select="transform($doc-available-transform-map)"/>
      <xsl:sequence select="xs:boolean($result-map('output'))"/>
   </xsl:function>
   
   
   <xsl:function name="tan:uri-collection-from-pattern" as="xs:anyURI*" visibility="public">
      <!-- Input: a string representing a resolved uri, with patterns -->
      <!-- Output: a uri collection based on the string as an input pattern -->
      <!-- This function was written to support glob-like patterns for files. -->
      <!--kw: uris -->
      <xsl:param name="resolved-patterned-uri" as="xs:string?"/>
      
      <xsl:variable name="pattern-parts" as="element()">
         <pattern-parts>
            <xsl:analyze-string select="$resolved-patterned-uri" regex="^(.+/)([^/]*)$">
               <xsl:matching-substring>
                  <directory>
                     <xsl:value-of select="regex-group(1)"/>
                  </directory>
                  <filename>
                     <xsl:value-of select="regex-group(2)"/>
                  </filename>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </pattern-parts>
      </xsl:variable>
      
      <xsl:choose>
         <xsl:when test="not(resolve-uri($resolved-patterned-uri) eq $resolved-patterned-uri)">
            <xsl:message select="$resolved-patterned-uri || ' is not a resolved uri pattern.'"/>
         </xsl:when>
         <xsl:when test="matches($resolved-patterned-uri, '[*?].*/')">
            <xsl:message select="'tan:uri-collection-from-pattern() does not support wildcards for directories. Unable to process ' || $resolved-patterned-uri || '.'"/>
         </xsl:when>
         <xsl:when test="not(exists($pattern-parts/*))">
            <xsl:message select="'tan:uri-collection-from-pattern() unable to process ' || $resolved-patterned-uri || '.'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="context-uri-collection" as="xs:anyURI*" select="uri-collection($pattern-parts/tan:directory)"/>
            <xsl:variable name="context-pattern" as="xs:string" select="tan:glob-to-regex($pattern-parts/tan:filename)"/>

            <xsl:sequence select="
                  $context-uri-collection[if (string-length($context-pattern) gt 0) then
                     matches(., $context-pattern)
                  else
                     true()]"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
</xsl:stylesheet>
