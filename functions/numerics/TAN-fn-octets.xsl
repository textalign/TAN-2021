<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xslq="https://github.com/mricaud/xsl-quality"
   version="3.0">
   
   <!-- TAN Function Library octet functions. -->

   <!-- Select functions dealing primarily octets = codepoints -->
   <!-- Functions are chosen based upon their utility in other applications. That is, these are some string functions that could be
   quite useful in other contexts -->
   
   
   <!-- Interchange between UTF-8 (Unicode) strings, octets, and eight-bit-characters -->
   <!-- Background: Unicode characters with codepoints above decimal 127 are composed of more than one byte (= octet = integer in the
      range 0-255) based on special rules. Further, Unicode restricts its octets to the range 1-244, so as to prevent going beyond the
      defined upper limit U+10FFFF.
   -->
   
   <xsl:variable name="tan:octet-error-key" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="'g8'">A UTF-8 octet must be in the range 1-244 excluding 192, 193</xsl:map-entry>
         <xsl:map-entry key="'g9'">In a UTF-8 octet stream, an octet above 127 must be followed by at least one more octet.</xsl:map-entry>
         <xsl:map-entry key="'g10'">In a UTF-8 octet stream, an octet above 223 must be followed by at least two more octets.</xsl:map-entry>
         <xsl:map-entry key="'g11'">In a UTF-8 octet stream, an octet above 239 must be followed by at least three more octets.</xsl:map-entry>
         <xsl:map-entry key="'g12'">In a 2-, 3-, or 4-byte UTF-8 octet construction, the second octet must be 128-244.</xsl:map-entry>
         <xsl:map-entry key="'g13'">In a 3- or 4-byte UTF-8 octet construction, the third octet must be 128-244.</xsl:map-entry>
         <xsl:map-entry key="'g14'">In a 4-byte UTF-8 octet construction, the fourth octet must be 128-244.</xsl:map-entry>
         <xsl:map-entry key="'g15'">A UTF-8 octet construction must not start with an octet 128-192.</xsl:map-entry>
      </xsl:map>
   </xsl:variable>


   <xsl:function name="tan:string-to-utf-8-octets" as="xs:integer*" visibility="public">
      <!-- Input: a string -->
      <!-- Output: integer values of the string, after conversion to UTF-8 bytes (0..255) -->
      <!-- This function was written to ensure that checksums of Unicode values do not cause repeating values. -->
      <!-- Anything below codepoint 128 will be simply the output of string-to-codepoints() -->
      <!--kw: numerics, codepoints -->
      <xsl:param name="str" as="xs:string"/>
      <xsl:for-each select="string-to-codepoints($str)">
         <xsl:choose>
            <xsl:when test=". lt 127">
               <xsl:sequence select="."/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-val" select="encode-for-uri(codepoints-to-string(.))" as="xs:string"/>
               <xsl:analyze-string select="$this-val" regex="[^%]+">
                  <xsl:matching-substring>
                     <xsl:sequence select="tan:hex-to-dec(.)"/>
                  </xsl:matching-substring>
               </xsl:analyze-string>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:utf-8-octets-to-string" as="xs:string?" visibility="public">
      <!-- Input: a sequence of octets (integers in the range 0-255) -->
      <!-- Output: the octets converted into a Unicode string. -->
      <!--kw: numerics, codepoints -->
      <xsl:param name="in" as="xs:integer*"/>
      <xsl:variable name="string-components" as="element()">
         <string>
            <!-- A child <c> contains a correct character; an <x> signifies a mistake in the UTF-8 encoding -->
            <xsl:iterate select="$in">
               <xsl:param name="bytes-to-skip" as="xs:integer?" select="0"/>
               <xsl:variable name="this-pos" select="position()" as="xs:integer"/>
               <xsl:variable name="next-3-octets" as="xs:integer*"
                  select="subsequence($in, ($this-pos + 1), 3)"/>
               <xsl:variable name="byte-2" select="$next-3-octets[1]" as="xs:integer?"/>
               <xsl:variable name="byte-3" select="$next-3-octets[2]" as="xs:integer?"/>
               <xsl:variable name="byte-4" select="$next-3-octets[3]" as="xs:integer?"/>
               <xsl:variable name="byte-1-binary" select="tan:dec-to-bin(.)" as="xs:string"/>
               <xsl:variable name="byte-2-binary" select="tan:dec-to-bin($byte-2)" as="xs:string?"/>
               <xsl:variable name="byte-3-binary" select="tan:dec-to-bin($byte-3)" as="xs:string?"/>
               <xsl:variable name="byte-4-binary" select="tan:dec-to-bin($byte-4)" as="xs:string?"/>
               
               <xsl:variable name="c-or-x-and-skip" as="element()+">
                  <xsl:choose>
                     <xsl:when test=". lt 1 or . gt 244">
                        <x pos="{$this-pos}" code="g8">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:when test="$bytes-to-skip gt 0">
                        <skip>
                           <xsl:value-of select="$bytes-to-skip - 1"/>
                        </skip>
                     </xsl:when>
                     
                     <xsl:when test=". lt 128">
                        <!-- It's ASCII -->
                        <c>
                           <xsl:value-of select="codepoints-to-string(.)"/>
                        </c>
                     </xsl:when>
                     
                     <xsl:when test=". lt 194">
                        <x pos="{$this-pos}" code="g15">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:when test="not(exists($byte-2))">
                        <x pos="{$this-pos}" code="g9">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:when test="$byte-2 lt 128">
                        <x pos="{$this-pos}" code="g12">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:when test=". lt 224">
                        <!-- It's a 2-byte code -->
                        <xsl:variable name="new-binary"
                           select="substring($byte-1-binary, 4) || substring($byte-2-binary, 3)" as="xs:string"/>
                        <!-- New codepoint is an 11-digit base-2 number -->
                        <xsl:variable name="new-codepoint"
                           select="tan:bin-to-dec($new-binary)" as="xs:integer"/>
                        
                        <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
                        <xsl:if test="$diagnostics-on">
                           <xsl:message select="'diagnostics on for 2-byte branch'"/>
                           <xsl:message select="'byte 1 binary: ' || $byte-1-binary"/>
                           <xsl:message select="'byte 2 decimal: ' || $byte-2"/>
                           <xsl:message select="'byte 2 binary: ' || $byte-2-binary"/>
                           <xsl:message select="'new binary: ' || $new-binary"/>
                           <xsl:message select="'new codepoint: ' || $new-codepoint"/>
                        </xsl:if>
                        
                        <c>
                           <xsl:value-of select="codepoints-to-string($new-codepoint)"/>
                        </c>
                        <skip>1</skip>
                     </xsl:when>
                    
                     <xsl:when test="not(exists($byte-3))">
                        <x pos="{$this-pos}" code="g10">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:when test="$byte-3 lt 128">
                        <x pos="{$this-pos}" code="g13">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                    
                     <xsl:when test=". lt 240">
                        <!-- It's a 3-byte code -->
                        <xsl:variable name="new-binary"
                           select="substring($byte-1-binary, 5) || substring($byte-2-binary, 3) || substring($byte-3-binary, 3)" as="xs:string"/>
                        <xsl:variable name="new-codepoint"
                           select="tan:bin-to-dec($new-binary)" as="xs:integer"/>
                        <c>
                           <xsl:copy-of select="codepoints-to-string($new-codepoint)"/>
                        </c>
                        <skip>2</skip>
                     </xsl:when>
                     
                     <xsl:when test="not(exists($byte-4))">
                        <x pos="{$this-pos}" code="g11">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:when test="$byte-4 lt 128">
                        <x pos="{$this-pos}" code="g14">
                           <xsl:value-of select="."/>
                        </x>
                     </xsl:when>
                     
                     <xsl:otherwise>
                        <!-- It's a 4-byte code -->
                        <xsl:variable name="new-binary" as="xs:string"
                           select="substring($byte-1-binary, 6) || substring($byte-2-binary, 3) || substring($byte-3-binary, 3) || substring($byte-4-binary, 3)"/>
                        <xsl:variable name="new-codepoint" as="xs:integer"
                           select="tan:bin-to-dec($new-binary)"/>
                        <c>
                           <xsl:copy-of select="codepoints-to-string($new-codepoint)"/>
                        </c>
                        <skip>3</skip>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
               
               <xsl:copy-of select="$c-or-x-and-skip/(self::c, self::x)"/>
               
               <xsl:choose>
                  <xsl:when test="exists($c-or-x-and-skip/self::x)">
                     <xsl:break/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:next-iteration>
                        <xsl:with-param name="bytes-to-skip" as="xs:integer?"
                           select="xs:integer($c-or-x-and-skip/self::skip)"/>
                     </xsl:next-iteration>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:iterate>
         </string>
      </xsl:variable>
      
      <xsl:variable name="utf-8-error" select="$string-components/x" as="element()?"/>
      
      <xsl:choose>
         <xsl:when test="not(exists($in))"/>
         <xsl:when test="exists($utf-8-error)">
            <xsl:sequence select="error(QName($tan:TAN-namespace, $utf-8-error/@code), $tan:octet-error-key($utf-8-error/@code), xs:integer($utf-8-error/@pos))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="string-join($string-components/*/text())"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   
   <xsl:function name="tan:unicode-to-eight-bit-chars" as="xs:string?" visibility="public">
      <!-- Input: any Unicode string -->
      <!-- Output: the string, with upper characters (greater than dec 126, ~) converted to 8-bit-bytes -->
      <!--kw: numerics, codepoints -->
      <xsl:param name="unicode-string" as="xs:string?"/>
      <xsl:variable name="str-8bit-codepoints" select="tan:string-to-utf-8-octets($unicode-string)"/>
      <xsl:sequence select="codepoints-to-string($str-8bit-codepoints)"/>
   </xsl:function>
   
   


</xsl:stylesheet>
