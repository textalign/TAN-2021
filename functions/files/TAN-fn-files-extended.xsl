<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:file="http://expath.org/ns/file"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended file functions. -->

   <xsl:function name="tan:open-file" visibility="public">
      <!-- 1-parameter version of the main one below -->
      <xsl:param name="resolved-urls"/>
      <xsl:sequence select="tan:open-file($resolved-urls, $tan:fallback-encoding)"/>
   </xsl:function>

   <xsl:function name="tan:open-file" as="document-node()*" visibility="public">
      <!-- Input: items that can be resolved as strings; a string -->
      <!-- Output: for each resolvable string in the first parameter, if a document is available, the document; 
            if it is not, but unparsed text is available, a document with the unparsed text wrapped in a root 
            element; otherwise an empty document node. If unparsed text is not available, another attempt 
            will be made on a fallback encoding specified by the 2nd parameter.
        -->
      <!-- If the file is plain text that is not XML, it will be wrapped by a root element of an
        XML document. That root node will have @xml:base pointing to the source url. -->
      <!-- If it is a .docx file, the components XML documents of the Word document will be returned. -->
      <!--kw: files -->
      <xsl:param name="resolved-urls"/>
      <xsl:param name="target-fallback-encoding" as="xs:string*"/>

      <xsl:for-each select="$resolved-urls[. castable as xs:string]">
         <xsl:variable name="this-path-normalized" select="replace(xs:string(.), '\s', '%20')"/>
         <xsl:variable name="this-path-normalized-for-extension-functions"
            select="replace($this-path-normalized, 'file:', '')"/>
         <xsl:choose>
            <xsl:when test="doc-available($this-path-normalized)">
               <xsl:sequence select="doc($this-path-normalized)"/>
            </xsl:when>
            <xsl:when test="unparsed-text-available($this-path-normalized)">
               <xsl:document>
                  <unparsed-text>
                     <xsl:attribute name="xml:base" select="$this-path-normalized"/>
                     <xsl:value-of select="unparsed-text($this-path-normalized)"/>
                  </unparsed-text>
               </xsl:document>
            </xsl:when>
            <xsl:when
               test="unparsed-text-available($this-path-normalized, $target-fallback-encoding)">
               <xsl:document>
                  <unparsed-text>
                     <xsl:attribute name="xml:base" select="$this-path-normalized"/>
                     <xsl:value-of
                        select="unparsed-text($this-path-normalized, $target-fallback-encoding)"/>
                  </unparsed-text>
               </xsl:document>
            </xsl:when>
            <xsl:when test="ends-with(lower-case($this-path-normalized), '.docx')">
               <xsl:sequence select="tan:open-docx($this-path-normalized)"/>
            </xsl:when>
            <xsl:when test="true()" use-when="$tan:file-functions-available">
               <xsl:variable name="file-exists" as="xs:boolean?">
                  <xsl:try select="file:exists($this-path-normalized-for-extension-functions)">
                     <xsl:catch>
                        <xsl:message
                           select="$this-path-normalized-for-extension-functions || ' breaks the syntax allowed for the function file:exists()'"/>
                        <xsl:value-of select="false()"/>
                     </xsl:catch>
                  </xsl:try>
               </xsl:variable>
               <xsl:if test="$file-exists">
                  <xsl:variable name="binary-file"
                     select="file:read-binary($this-path-normalized-for-extension-functions)"/>
                  <xsl:message
                     select="$this-path-normalized-for-extension-functions || ' points to a file that exists, but is neither XML nor unparsed text (UTF-8 or fallback encoding ' || $target-fallback-encoding || '). Returning an XML document whose root element contains a single text node encoded as xs:base64Binary.'"/>
                  <xsl:document>
                     <base64Binary>
                        <xsl:attribute name="xml:base"
                           select="$this-path-normalized-for-extension-functions"/>
                        <xsl:value-of select="$binary-file"/>
                     </base64Binary>
                  </xsl:document>
               </xsl:if>
            </xsl:when>
            <xsl:otherwise>
               <xsl:message
                  select="$this-path-normalized || ' points to a file that does not exist. Returning an empty document node.'"/>
               <xsl:document/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:zip-uris" as="xs:anyURI*" visibility="public">
      <!-- Input: any string representing a uri -->
      <!-- Output: the same string with 'zip:' prepended if it represents a uri to a file in an archive (docx, jar, zip, etc.) -->
      <!--kw: files, archives -->
      <xsl:param name="uris" as="xs:string*"/>
      <xsl:for-each select="$uris">
         <xsl:value-of select="
               if (matches(., '!/')) then
                  ('zip:' || .)
               else
                  ."/>
      </xsl:for-each>
   </xsl:function>



</xsl:stylesheet>
