<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   exclude-result-prefixes="#all"
   version="3.0">

   <!-- TAN Function Library URI functions for Writing Fragids. -->
   
   
   <!-- Writing Fragids is an emerging technology, and all functions
   below are not stable and subject to change. -->

   <xsl:function name="tan:is-valid-lf-uri" as="xs:boolean" visibility="private">
      <!-- Input: a string -->
      <!-- Output: whether the input string is a valid Literature Fragid URI -->
      <!-- Evaluation is based upon the Literature Fragid specifications, version 0 -->

      <xsl:param name="lf-uri" as="xs:string?"/>

      <xsl:variable name="lf-uri-parsed" as="map(*)" select="tan:parse-lf-uri($lf-uri)"/>

      <xsl:choose>
         <xsl:when test="string-length($lf-uri) lt 1">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <!--<xsl:when test="count($lf-uri-parts) ne 2">
            <xsl:sequence select="false()"/>
         </xsl:when>-->
         <!--<xsl:when test="not(exists($lf-fragment))">
            <xsl:sequence select="false()"/>
         </xsl:when>-->
         <xsl:otherwise>
            <xsl:sequence select="true()"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>

   <xsl:function name="tan:parse-lf-uri" as="map(*)" visibility="private">
      <!-- Input: a string -->
      <!-- Output: the parts of the string parsed as an LF URI and placed in a map -->
      <!-- The URI is assumed to have been put in canonical form. That is, if adjustments have been
      made in a context, embedding whitespace or wrapping in angle brackets, such wrappers or insertions
      must be removed before applying this function. -->
      <!-- This function establishes the criteria necessary to detect errors or inconsistencies, but
      it does not do such checking. -->
      
      <xsl:param name="lf-uri" as="xs:string?"/>

      <!-- A valid LF URI consists of exactly one #. What precedes is the base URI; what follows
      is the fragment. The LF should be inside the fragment somewhere -->
      <xsl:variable name="lf-uri-parts" as="xs:string*" select="tokenize($lf-uri, '#')"/>

      <xsl:variable name="lf-base-uri" select="$lf-uri-parts[1]" as="xs:string?"/>
      <xsl:variable name="lf-uri-fragments" as="element()">
         <fragment>
            <!-- Reluctant capture applied to the LF, in case a second has been accidentally applied -->
            <xsl:analyze-string select="$lf-uri-parts[2]" regex="\$lf\d+:.+?[^^]\$">
               <xsl:matching-substring>
                  <lf>
                     <xsl:value-of select="."/>
                  </lf>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <extra>
                     <xsl:value-of select="."/>
                  </extra>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </fragment>
      </xsl:variable>
      <xsl:variable name="lf-fragment" select="$lf-uri-fragments/tan:lf[1]" as="element()?"/>
      <!-- Step 1: analyze the LF for its parameters -->
      <xsl:variable name="lf-fragment-parameters-parsed" as="element()">
         <lf>
            <xsl:analyze-string select="$lf-fragment" regex="^\$lf(\d+):|\$$" flags="i">
               <!-- Trim the opening and closing strings, retaining the LF version number -->
               <xsl:matching-substring>
                  <xsl:if test="string-length(regex-group(1)) gt 0">
                     <version>
                        <xsl:value-of select="regex-group(1)"/>
                     </version>
                  </xsl:if>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:analyze-string select="." regex="^a=([ws]);" flags="i">
                     <xsl:matching-substring>
                        <base-uri-type>
                           <xsl:value-of select="lower-case(regex-group(1))"/>
                        </base-uri-type>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="^w=(.+?[^^]);" flags="i">
                           <xsl:matching-substring>
                              <work-constraint-uri>
                                 <xsl:value-of select="tan:unescape-lf-frag-uri(regex-group(1))"/>
                              </work-constraint-uri>
                           </xsl:matching-substring>
                           <xsl:non-matching-substring>
                              <xsl:analyze-string select="." regex="^t=([ml]);" flags="i">
                                 <xsl:matching-substring>
                                    <ref-system-type>
                                       <xsl:value-of select="lower-case(regex-group(1))"/>
                                    </ref-system-type>
                                 </xsl:matching-substring>
                                 <xsl:non-matching-substring>
                                    <xsl:analyze-string select="." regex="^r=(.*?[^^]);">
                                       <xsl:matching-substring>
                                          <ref-scriptum-uri>
                                             <xsl:value-of
                                                select="tan:unescape-lf-frag-uri(regex-group(1))"/>
                                          </ref-scriptum-uri>
                                       </xsl:matching-substring>
                                       <xsl:non-matching-substring>
                                          <references>
                                             <xsl:analyze-string select="." regex="(.+?[^^])&amp;">
                                                <xsl:matching-substring>
                                                  <reference>
                                                  <xsl:value-of select="regex-group(1)"/>
                                                  </reference>
                                                </xsl:matching-substring>
                                                <xsl:non-matching-substring>
                                                  <reference>
                                                  <xsl:value-of select="."/>
                                                  </reference>
                                                </xsl:non-matching-substring>
                                             </xsl:analyze-string>
                                          </references>
                                       </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                 </xsl:non-matching-substring>
                              </xsl:analyze-string>
                           </xsl:non-matching-substring>
                        </xsl:analyze-string>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </lf>
      </xsl:variable>
      <xsl:variable name="lf-uri-type" as="xs:string?">
         <xsl:choose>
            <xsl:when
               test="$lf-fragment-parameters-parsed/tan:base-uri-type eq 's' and exists($lf-fragment-parameters-parsed/tan:work-constraint-uri/text())"
               >constrained scriptum</xsl:when>
            <xsl:when test="$lf-fragment-parameters-parsed/tan:base-uri-type eq 's'"
               >scriptum</xsl:when>
            <xsl:when test="$lf-fragment-parameters-parsed/tan:base-uri-type eq 'w'">work</xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="lf-fragment-references-parsed" as="map(*)">
         <xsl:map>
            <xsl:apply-templates select="$lf-fragment-parameters-parsed" mode="tan:parse-lf-references"
            />
         </xsl:map>
      </xsl:variable>

      <xsl:map>
         <!-- All URI components -->
         <xsl:map-entry key="'base-uri'" select="$lf-base-uri"/>
         <xsl:map-entry key="'fragment-start'"
            select="string-join($lf-fragment/preceding-sibling::*)"/>
         <!-- The pre-parsed LF itself is isolated, in case it needs to be used elsewhere -->
         <xsl:map-entry key="'lf-fragment'" select="string($lf-fragment)"/>
         <xsl:map-entry key="'fragment-end'" select="string-join($lf-fragment/following-sibling::*)"
         />
         
         <!-- LF components: parameters -->
         <xsl:map-entry key="'lf-version'" select="string($lf-fragment-parameters-parsed/tan:version)"/>
         <xsl:map-entry key="'lf-uri-type'" select="$lf-uri-type"/>
         <xsl:map-entry key="'lf-work-constraint-uri'" select="string($lf-fragment-parameters-parsed/tan:work-constraint-uri)"/>
         <xsl:map-entry key="'lf-ref-system-type'" select="string($lf-fragment-parameters-parsed/tan:ref-system-type)"/>
         <xsl:map-entry key="'lf-ref-scriptum-uri'" select="string($lf-fragment-parameters-parsed/tan:ref-scriptum-uri)"/>
         
         <!-- LF components: references -->
         <xsl:map-entry key="'lf-references'" select="$lf-fragment-references-parsed"/>
      </xsl:map>

   </xsl:function>
   
   <xsl:mode name="tan:parse-lf-references" on-no-match="shallow-skip"/>

   <xsl:template match="tan:reference" mode="tan:parse-lf-references">
      <!-- In a reference, a hyphen signifies a range of two references. A plus means the fusion of 
      adjacent references. -->
      <xsl:variable name="reference-parts" as="element()">
         <parts>
            <xsl:analyze-string select="." regex="([^^])-">
               <xsl:matching-substring>
                  <a>
                     <xsl:value-of select="regex-group(1)"/>
                  </a>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:analyze-string select="." regex="([^^])\+">
                     <xsl:matching-substring>
                        <b>
                           <xsl:value-of select="regex-group(1)"/>
                        </b>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <part>
                           <xsl:value-of select="."/>
                        </part>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </parts>
      </xsl:variable>
      <xsl:variable name="reference-is-range" as="xs:boolean"
         select="exists($reference-parts/tan:a)"/>
      <xsl:variable name="reference-is-fusion" as="xs:boolean"
         select="exists($reference-parts/tan:b)"/>
      <xsl:variable name="ref-parts" as="xs:string*">
         <xsl:for-each-group select="$reference-parts" group-starting-with="tan:part">
            <xsl:value-of select="string-join(current-group())"/>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:map-entry key="position()">
         <!-- No reference may have both an unescaped hyphen (a range) and an unescaped + (a fusion). In 
            such cases, the error will be registered because both <range> and <fusion> are present, but
            the tree will be constructed on the basis of the range, not the fusion.
         -->
         <xsl:map>
            <xsl:map-entry key="'is-range'" select="$reference-is-range"/>
            <xsl:map-entry key="'is-fusion'" select="$reference-is-fusion"/>
            <xsl:for-each select="$ref-parts">
               <xsl:map-entry key="position()">
                  <xsl:map>
                     <xsl:analyze-string select="." regex="^(n?\d+(\.\d+)?)(:n?\d+(\.\d+)?)*">
                        <xsl:matching-substring>
                           <!--<xsl:map-entry key="'steps'" select="array { tokenize(., ':') }"/>-->
                           <xsl:map-entry key="'steps'" select="tokenize(., ':')"/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                           <xsl:analyze-string select="." regex="^::(.*?[^^])(\[[\d,]+\]|\[\*\])(\[[\d,]+\])?">
                              <xsl:matching-substring>
                                 <xsl:map-entry key="'text'"
                                    select="tan:unescape-lf-frag-text(regex-group(1))"/>
                                 <xsl:map-entry key="'instances'" select="
                                       for $i in tokenize(regex-group(2), ',')
                                       return
                                          xs:integer(replace($i, '\D+', ''))"
                                 />
                                 <xsl:if test="string-length(regex-group(3)) gt 0">
                                    <xsl:map-entry key="'at-chars'" select="
                                          for $i in tokenize(regex-group(2), ',')
                                          return
                                             xs:integer(replace($i, '\D+', ''))"
                                    />
                                 </xsl:if>
                              </xsl:matching-substring>
                              <xsl:non-matching-substring>
                                 <xsl:map-entry key="'unparsed-text'" select="."/>
                              </xsl:non-matching-substring>
                           </xsl:analyze-string>
                        </xsl:non-matching-substring>
                     </xsl:analyze-string>
                  </xsl:map>
   
               </xsl:map-entry>
            </xsl:for-each>
         </xsl:map>
      </xsl:map-entry>
   </xsl:template>

   <xsl:function name="tan:unescape-lf-frag-uri" as="xs:string?" visibility="private">
      <!-- Input: a portion of an LF that corresponds to a URI -->
      <!-- Output: the URI with escaped characters unescaped -->
      <xsl:param name="lf-parameter-value" as="xs:string"/>
      <xsl:variable name="lf-param-parts" as="xs:string+">
         <xsl:analyze-string select="$lf-parameter-value" regex="\^([\$\^;])">
            <xsl:matching-substring>
               <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:sequence select="string-join($lf-param-parts)"/>
   </xsl:function>

   <xsl:function name="tan:unescape-lf-frag-text" as="xs:string?" visibility="private">
      <!-- Input: a portion of an LF that corresponds to a text fragment -->
      <!-- Output: the fragment with escaped characters unescaped -->
      <xsl:param name="lf-reference-text" as="xs:string"/>
      <xsl:variable name="lf-reference-text-parts" as="xs:string+">
         <xsl:analyze-string select="$lf-reference-text" regex="\^([\$\^\[:\+-])">
            <xsl:matching-substring>
               <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:sequence select="string-join($lf-reference-text-parts)"/>
   </xsl:function>

   <xsl:function name="tan:get-class-1-fragment" as="element()*" visibility="private">
      <!-- Input: a resolved class 1 file; a Literature Fragid URI -->
      <!-- Output: a sequence of content items from the class 1 file that corresponds to the LF URI -->
      <!-- The process of this function is documented in the TAN-LF specifications, "TAN and Literature 
         Fragment Identifiers" in concert with the specifications for Literature Fragment Identifiers, 
         major version 0 (alpha release). Errors and output follow the TAN-LF specifications as well. -->
      <xsl:param name="lf-uri" as="xs:string"/>
      <xsl:param name="resolved-class-1-file" as="document-node()"/>

      <xsl:variable name="input-appears-resolved"
         select="exists($resolved-class-1-file/*/tan:resolved)"/>

      <xsl:variable name="diagnostics-on" select="true()" as="xs:boolean"/>

      <xsl:choose>
         <xsl:when test="$diagnostics-on">
            <diagnostics> </diagnostics>
         </xsl:when>
         <xsl:otherwise> </xsl:otherwise>
      </xsl:choose>

   </xsl:function>

</xsl:stylesheet>
