<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xslq="https://github.com/mricaud/xsl-quality"
   version="3.0">

   <!-- TAN Function Library binary functions. -->
   
   <!-- Functions dealing primarily with two binary data types: bits (= base-2 binary = boolean), hexBinary, and base64Binary -->
   <!-- For functions casting between binary data types and numerical forms, see numeric functions.xsl -->
   <!-- All functions dealing with bits must specify whether bits are big-endian (most significant bit first) or not -->

   <xsl:variable name="tan:binary-error-key" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="'g3'">Negative numbers of bits are not permitted.</xsl:map-entry>
         <xsl:map-entry key="'g4'">An octet must be in the range 0-255</xsl:map-entry>
         <xsl:map-entry key="'g5'">Only bytes (8 bit groups) may be cast to octets.</xsl:map-entry>
         <xsl:map-entry key="'g6'">8-bit characters must have codepoints in the range 1-255, 9216</xsl:map-entry>
         <xsl:map-entry key="'g7'">Bitwise operations can be applied to bit sequences of identical length.</xsl:map-entry>
      </xsl:map>
   </xsl:variable>

   <!-- Bit handling -->

   <xsl:function name="tan:pad-bits" as="xs:boolean*" visibility="public">
      <!--Input: bits as booleans; a boolean; an integer -->
      <!--Output: the input padded with enough 0 bits (false booleans) at the front or back (depends 
         on 2nd parameter) to make the output as long as the third integer -->
      <!--kw: numerics, binary -->
      <xsl:param name="input-bits" as="xs:boolean*"/>
      <xsl:param name="big-endian" as="xs:boolean"/>
      <xsl:param name="item-size" as="xs:integer"/>
      <xsl:variable name="input-count" select="count($input-bits)" as="xs:integer"/>
      <xsl:variable name="this-remnant" select="
            if ($item-size gt 0) then
               $input-count mod $item-size
            else
               0" as="xs:integer"/>
      <xsl:variable name="bits-needed" as="xs:integer"
         select="
            if ($this-remnant eq 0) then
               0
            else
               $item-size - $this-remnant"/>
      
      <xsl:choose>
         <xsl:when test="$item-size lt 0">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g3'), $tan:binary-error-key('g3'), $item-size)"/>
         </xsl:when>
         <xsl:when test="$item-size lt 2">
            <xsl:sequence select="$input-bits"/>
         </xsl:when>
         <xsl:when test="$this-remnant eq 0">
            <xsl:sequence select="$input-bits"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="$big-endian">
               <xsl:sequence
                  select="
                     for $i in (1 to $bits-needed)
                     return
                        false()"
               />
            </xsl:if>
            <xsl:sequence select="$input-bits"/>
            <xsl:if test="not($big-endian)">
               <xsl:sequence
                  select="
                     for $i in (1 to $bits-needed)
                     return
                        false()"
               />
            </xsl:if>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   <xsl:function name="tan:bits-to-byte" as="xs:boolean*" visibility="public">
      <!-- Input: a sequence of bits (booleans); a boolean -->
      <!-- Output: the same sequence, but extended to a multiple of 8 bits (a byte). If the 2nd param is true, it is
      big endian and the padding takes place at the beginning, otherwise, at the end. -->
      <!--kw: numerics, binary -->
      <xsl:param name="input-bits" as="xs:boolean*"/>
      <xsl:param name="big-endian" as="xs:boolean"/>
      <xsl:sequence select="tan:pad-bits($input-bits, $big-endian, 8)"/>
   </xsl:function>

   <xsl:function name="tan:bits-to-word" as="xs:boolean*" visibility="public">
      <!-- Input: a sequence of bits (booleans); a boolean -->
      <!-- Output: the same sequence, but extended to a multiple of 32 bits (a "word"). If the 2nd param is true, it is
      big endian and the padding takes place at the beginning, otherwise, at the end. -->
      <!--kw: numerics, binary -->
      <xsl:param name="input-bits" as="xs:boolean*"/>
      <xsl:param name="big-endian" as="xs:boolean"/>
      <xsl:sequence select="tan:pad-bits($input-bits, $big-endian, 32)"/>
   </xsl:function>


   <!-- CASTING BETWEEN BINARY TYPES: BITS, HEXBINARY, BASE64BINARY -->

   <xsl:function name="tan:bits-to-hexBinary" as="xs:hexBinary?" visibility="public">
      <!-- Input: a sequence of bits (booleans); a boolean specifying whether the bits are big-endian or not -->
      <!-- Output: the bits as a hexBinary -->
      <!-- Because a hexBinary is eight bits, the input bits are cast to bytes. For defective byte input, little/big endian
      options will likely result in different output. For whole bytes, the results should be the same, since the hexBinary
      will preserve the endianness of the input. -->
      <!--kw: numerics, binary -->
      <xsl:param name="input-bits" as="xs:boolean*"/>
      <xsl:param name="big-endian" as="xs:boolean"/>
      <xsl:variable name="input-as-bytes" select="tan:bits-to-byte($input-bits, $big-endian)" as="xs:boolean*"/>
      <xsl:variable name="input-as-hex" select="tan:bits-to-hex($input-as-bytes)" as="xs:string?"/>
      <xsl:if test="exists($input-bits)">
         <xsl:sequence select="tan:hex-to-hexBinary($input-as-hex)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:hexBinary-to-bits" as="xs:boolean*" visibility="public">
      <!-- Input: a hexBinary -->
      <!-- Output: the value in bits (booleans) -->
      <!-- Because hexBinary works in bytes, the output will be a multiple of 8 -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:hexBinary?"/>
      <xsl:variable name="in-as-bin" select="tan:hexBinary-to-bin($in)" as="xs:string"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:bin-to-bits($in-as-bin)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:bits-to-base64Binary" as="xs:base64Binary?" visibility="public">
      <!-- Input: a sequence of bits (booleans); a boolean specifying whether the bits are big-endian or not -->
      <!-- Output: the bits as a base64Binary -->
      <!-- Because a base64Binary is interchangeable with a hexBinary, which is eight bits, the input bits are cast to 
         bytes. For defective byte input, little/big endian options will likely result in different output. For whole bytes, 
         the results should be the same, since the base64Binary will preserve the endianness of the input. Trailing =
         are padding characters that are neither 0 nor 1
      -->
      <!--kw: numerics, binary -->
      <xsl:param name="input-bits" as="xs:boolean*"/>
      <xsl:param name="big-endian" as="xs:boolean"/>
      <xsl:variable name="input-as-hexBinary" select="tan:bits-to-hexBinary($input-bits, $big-endian)" as="xs:hexBinary?"/>
      <xsl:if test="exists($input-bits)">
         <xsl:sequence select="xs:base64Binary($input-as-hexBinary)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:base64Binary-to-bits" as="xs:boolean*" visibility="public">
      <!-- Input: a base64Binary -->
      <!-- Output: the value in bits (booleans) -->
      <!-- Because base64Binary works in bytes, the output will be a multiple of 8 -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:variable name="in-as-bin" select="tan:base64Binary-to-bin($in)" as="xs:string?"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:bin-to-bits($in-as-bin)"/>
      </xsl:if>
   </xsl:function>
   
   <!-- hexBinary and base64Binary are already castable one into the other directly -->
   
   
   <!-- CASTING BINARY TYPES TO/FROM OCTETS -->
   
   <xsl:function name="tan:bits-to-octets" as="xs:integer*" visibility="public">
      <!-- Input: a sequence of bits (booleans) -->
      <!-- Output: a sequence of integers between 0 and 255 representing the Binary value -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:boolean*"/>
      <xsl:variable name="in-count" as="xs:integer" select="count($in)"/>
      <xsl:variable name="byte-count" select="$in-count idiv 8" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="not(exists($in))"/>
         <xsl:when test="$in-count mod 8 ne 0">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g5'), $tan:binary-error-key('g5'), $in-count)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:for-each select="1 to $byte-count">
               <xsl:sequence select="tan:bin-to-dec(tan:bits-to-bin(subsequence($in, (. - 1) * 8 + 1, 8)))"/>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:octets-to-bits" as="xs:boolean*" visibility="public">
      <!-- Input: a sequence of octets (integers in the range 0-255) -->
      <!-- Output: the octets as sequence of bits (booleans) -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:integer*"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:hexBinary-to-bits(tan:octets-to-hexBinary($in))"/>
      </xsl:if>
   </xsl:function>
   
   
   <xsl:function name="tan:hexBinary-to-octets" as="xs:integer*" visibility="public">
      <!-- Input: a hexBinary -->
      <!-- Output: a sequence of integers between 0 and 255 representing the hexBinary value -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:hexBinary?"/>
      <xsl:variable name="in-as-hex" select="tan:hexBinary-to-hex($in)" as="xs:string?"/>
      <xsl:if test="exists($in)">
         <xsl:analyze-string select="$in-as-hex" regex="..">
            <xsl:matching-substring>
               <xsl:sequence select="tan:hex-to-dec(.)"/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:octets-to-hexBinary" as="xs:hexBinary?" visibility="public">
      <!-- Input: a sequence of octets (integers in the range 0-255) -->
      <!-- Output: the octets as hexBinary -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:integer*"/>
      <xsl:variable name="bad-octets" select="$in[. lt 0 or . gt 255]" as="xs:integer*"/>
      <xsl:choose>
         <xsl:when test="not(exists($in))"/>
         <xsl:when test="exists($bad-octets)">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g4'), $tan:binary-error-key('g4'), $bad-octets)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="in-as-hex" select="string-join(for $i in $in return replace(tan:dec-to-hex($i), '^.$', '0$0'))" as="xs:string"/>
            <xsl:sequence select="xs:hexBinary($in-as-hex)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:function name="tan:base64Binary-to-octets" as="xs:integer*" visibility="public">
      <!-- Input: a base64Binary -->
      <!-- Output: a sequence of integers between 0 and 255 representing the base64Binary value -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:variable name="in-as-hexBinary" select="xs:hexBinary($in)" as="xs:hexBinary?"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:hexBinary-to-octets($in-as-hexBinary)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:octets-to-base64Binary" as="xs:base64Binary?" visibility="public">
      <!-- Input: a sequence of octets (integers in the range 0-255) -->
      <!-- Output: the octets as base64Binary -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:integer*"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="xs:base64Binary(tan:octets-to-hexBinary($in))"/>
      </xsl:if>
   </xsl:function>
   


   <!-- CASTING BINARY TYPES TO/FROM STRINGS -->
   <!-- Strings here are only eight-bit characters. To convert eight-bit characters to and from a particular 
      encoding, use functions collected under strings. -->

   <xsl:function name="tan:bits-to-eight-bit-chars" as="xs:string?" visibility="public">
      <!-- Input: a sequence of bits (booleans) -->
      <!-- Output: a string of 8-bit characters (characters corresponding to codepoints 
            1-255, and character 0 converted to U+2400 SYMBOL FOR NULL)-->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:boolean*"/>
      <xsl:variable name="in-count" as="xs:integer" select="count($in)"/>
      <xsl:variable name="byte-count" select="$in-count idiv 8" as="xs:integer"/>
      <xsl:variable name="in-as-hex" select="tan:bits-to-hex($in)" as="xs:string?"/>
      
      <xsl:choose>
         <xsl:when test="not(exists($in))"/>
         <xsl:when test="$in-count mod 8 ne 0">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g5'), $tan:binary-error-key('g5'), $in-count)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="tan:hexBinary-to-eight-bit-chars(xs:hexBinary($in-as-hex))"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:eight-bit-chars-to-bits" as="xs:boolean*" visibility="public">
      <!-- Input: a sequence of eight-bit-chars (integers in the range 0-255) -->
      <!-- Output: the eight-bit-chars as sequence of bits (booleans) -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:string*"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:hexBinary-to-bits(tan:eight-bit-chars-to-hexBinary($in))"/>
      </xsl:if>
   </xsl:function>
   
   
   <xsl:function name="tan:hexBinary-to-eight-bit-chars" as="xs:string?" visibility="public">
      <!-- Input: a hexBinary -->
      <!-- Output: the hexBinary converted to 8-bit characters (characters corresponding to codepoints 
            1-255, and character 0 converted to U+2400 SYMBOL FOR NULL)-->
      <!--kw: numerics, binary -->
      <xsl:param name="hexBinary" as="xs:hexBinary?"/>
      <xsl:variable name="pass-1" as="xs:string*">
         <xsl:analyze-string select="xs:string($hexBinary)" regex="..">
            <xsl:matching-substring>
               <xsl:variable name="this-dec" select="tan:hex-to-dec(.)" as="xs:integer"/>
               <xsl:choose>
                  <xsl:when test="$this-dec = 0">
                     <!-- Insert U+2400 SYMBOL FOR NULL as a replacement -->
                     <!-- IMPORTANT: In any handling of results, this character will need to be replaced. -->
                     <xsl:value-of select="'␀'"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:value-of select="codepoints-to-string($this-dec)"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:if test="exists($hexBinary)">
         <xsl:value-of select="string-join($pass-1)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:eight-bit-chars-to-hexBinary" as="xs:hexBinary?" visibility="public">
      <!-- Input: a string that is encoded in eight-bit chars; a boolean -->
      <!-- Output: the string as a sequence of hexBinary values, one per character -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="input-codepoints" select="string-to-codepoints($in)" as="xs:integer*"/>
      <xsl:variable name="bad-codepoints"
         select="$input-codepoints[. lt 0 or (. gt 255 and . ne 9216)]" as="xs:integer*"/>
      <xsl:choose>
         <xsl:when test="string-length($in) lt 1"/>
         <xsl:when test="exists($bad-codepoints)">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g6'), $tan:binary-error-key('g6'), $bad-codepoints)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="this-as-hex" as="xs:string+">
               <xsl:for-each select="$input-codepoints">
                  <xsl:choose>
                     <xsl:when test=". = 9216">
                        <xsl:sequence select="'00'"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="replace(tan:dec-to-hex(.), '^.$', '0$0')"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="xs:hexBinary(string-join($this-as-hex))"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:function name="tan:base64Binary-to-eight-bit-chars" as="xs:string?" visibility="public">
      <!-- Input: a base64 binary -->
      <!-- Output: the same, converted to an 8-bit character string -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:variable name="this-as-hexbinary" select="xs:hexBinary($in)" as="xs:hexBinary"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:hexBinary-to-eight-bit-chars($this-as-hexbinary)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:eight-bit-chars-to-base64Binary" as="xs:base64Binary?" visibility="public">
      <!-- Input: a string that is encoded in eight-bit chars; a boolean -->
      <!-- Output: the string as a sequence of hexBinary values, one per character -->
      <!--kw: numerics, binary -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="xs:base64Binary(tan:eight-bit-chars-to-hexBinary($in))"/>
      </xsl:if>
   </xsl:function>
   
   
   
   <!-- BITWISE OPERATIONS -->
   
   
   <xsl:function name="tan:bitwise-not" as="xs:boolean*" visibility="public">
      <!-- Input: a boolean sequence -->
      <!-- Output: the bitwise complement of the sequence -->
      <!-- e.g., false, true > true, false -->
      <!--kw: numerics, binary -->
      <xsl:param name="boolean" as="xs:boolean*"/>
      <xsl:for-each select="$boolean">
         <xsl:sequence select="not(.)"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:bitwise-or" as="xs:boolean*" visibility="public">
      <!-- Input: two sequences of booleans -->
      <!-- Output: a single sequence as long as the longest input sequence, with pairwise OR computed. -->
      <!--kw: numerics, binary -->
      <xsl:param name="bit-sequence-a" as="xs:boolean*"/>
      <xsl:param name="bit-sequence-b" as="xs:boolean*"/>
      <xsl:variable name="a-count" select="count($bit-sequence-a)" as="xs:integer"/>
      <xsl:variable name="b-count" select="count($bit-sequence-b)" as="xs:integer"/>
      
      <xsl:choose>
         <xsl:when test="$a-count ne $b-count">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g7'), $tan:binary-error-key('g7'), ($a-count, $b-count))"/>
         </xsl:when>
         <xsl:when test="$a-count lt 1"/>
         <xsl:otherwise>
            <xsl:for-each select="1 to $a-count">
               <xsl:sequence select="$bit-sequence-a[current()] or $bit-sequence-b[current()]"/>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:bitwise-and" as="xs:boolean*" visibility="public">
      <!-- Input: two sequences of booleans -->
      <!-- Output: a single sequence as long as the longest input sequence, with pairwise AND computed. -->
      <!--kw: numerics, binary -->
      <xsl:param name="bit-sequence-a" as="xs:boolean*"/>
      <xsl:param name="bit-sequence-b" as="xs:boolean*"/>
      <xsl:variable name="a-count" select="count($bit-sequence-a)" as="xs:integer"/>
      <xsl:variable name="b-count" select="count($bit-sequence-b)" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="$a-count ne $b-count">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g7'), $tan:binary-error-key('g7'), ($a-count, $b-count))"/>
         </xsl:when>
         <xsl:when test="$a-count lt 1"/>
         <xsl:otherwise>
            <xsl:for-each select="1 to $a-count">
               <xsl:sequence select="$bit-sequence-a[current()] and $bit-sequence-b[current()]"/>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:bitwise-xor" as="xs:boolean*" visibility="public">
      <!-- Input: two sequences of booleans -->
      <!-- Output: a single sequence as long as the longest input sequence, with pairwise XOR computed. -->
      <!--kw: numerics, binary -->
      <xsl:param name="bit-sequence-a" as="xs:boolean*"/>
      <xsl:param name="bit-sequence-b" as="xs:boolean*"/>
      <!--<xsl:param name="big-endian" as="xs:boolean"/>-->
      <xsl:variable name="a-count" select="count($bit-sequence-a)" as="xs:integer"/>
      <xsl:variable name="b-count" select="count($bit-sequence-b)" as="xs:integer"/>
      
      <xsl:choose>
         <xsl:when test="$a-count ne $b-count">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g7'), $tan:binary-error-key('g7'), ($a-count, $b-count))"/>
         </xsl:when>
         <xsl:when test="$a-count lt 1"/>
         <xsl:otherwise>
            <xsl:for-each select="1 to $a-count">
               <xsl:sequence select="$bit-sequence-a[current()] ne $bit-sequence-b[current()]"/>
            </xsl:for-each>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   

   <xsl:function name="tan:bitwise-plus" as="xs:boolean*" visibility="public">
      <!-- Input: two sequences of booleans, and a boolean -->
      <!-- Output: a sequence of booleans representing the sum of the input, as if base-2 binary. -->
      <!-- Unlike most bitwise operations, where the length of input and output are expected to be the same,
      that is definitely not the case here, which means that a declaration must be made whether the operation
      is big-endian (most significant byte first) or little-endian (most significant byte last) -->
      <!-- If one input is longer than the other, each unpaired boolean at the most significant part 
         of the longest series will be assessed against an assumed counterpart of false.
      -->
      <!--kw: numerics, binary -->
      <xsl:param name="bit-sequence-a" as="xs:boolean*"/>
      <xsl:param name="bit-sequence-b" as="xs:boolean*"/>
      <xsl:param name="big-endian" as="xs:boolean"/>
      <xsl:variable name="a-count" select="count($bit-sequence-a)" as="xs:integer"/>
      <xsl:variable name="b-count" select="count($bit-sequence-b)" as="xs:integer"/>
      <xsl:variable name="max-length" select="max(($a-count, $b-count))" as="xs:integer"/>
      <!-- Convert input to little-endian, which is easier to iterate over, going from
      units to twos to fours, etc. Also, make them an even length.-->
      <xsl:variable name="bit-seq-a-le" as="xs:boolean*"
         select="
            (if ($big-endian) then
               reverse($bit-sequence-a)
            else
               $bit-sequence-a),
            (for $i in (1 to ($max-length - $a-count))
            return
               false())"
      />
      <xsl:variable name="bit-seq-b-le" as="xs:boolean*"
         select="
            (if ($big-endian) then
               reverse($bit-sequence-b)
            else
               $bit-sequence-b),
            (for $i in (1 to ($max-length - $b-count))
            return
               false())"
      />
      <xsl:variable name="results-little-endian" as="xs:boolean*">
         <!-- Don't forget, little-endian means the littlest digit is at the FIRST/LOWEST end ("end" in 
            "endian" does not mean "last") -->
         <xsl:iterate select="1 to $max-length">
            <xsl:param name="carryover" as="xs:boolean" select="false()"/>
            <xsl:on-completion>
               <xsl:if test="$carryover eq true()">
                  <xsl:sequence select="$carryover"/>
               </xsl:if>
            </xsl:on-completion>
            <xsl:variable name="this-pos" select="." as="xs:integer"/>
            <xsl:variable name="this-a" select="$bit-seq-a-le[$this-pos]" as="xs:boolean"/>
            <xsl:variable name="this-b" select="$bit-seq-b-le[$this-pos]" as="xs:boolean"/>
            <!-- The truth table for summing bits is a bit complicated, so here it is for reference: -->
            <!--
        a:         0          1
carryover:      +0  +1     +0  +1
               ========   ========
        b:  0 | 0+0 1+0    1+0 0+1
            1 | 1+0 0+1    0+1 1+1
            -->
            
            <xsl:sequence
               select="
                  if ($this-a eq $this-b) then
                     $carryover eq true()
                  else
                     $carryover eq false()"
            />
            <xsl:next-iteration>
               <xsl:with-param name="carryover" as="xs:boolean"
                  select="
                  ($this-a eq true() and $this-b eq true())
                  or ($this-a ne $this-b and $carryover eq true())"
               />
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      
      <!-- Return output. Don't forget, the results might be one digit larger than the longest input string -->
      <xsl:sequence
         select="
            if ($big-endian) then
               reverse($results-little-endian)
            else
               $results-little-endian"
      />
   </xsl:function>
   
   <xsl:function name="tan:bitwise-rotate" as="xs:boolean*" visibility="public">
      <!-- Input: a boolean sequence; an integer -->
      <!-- Output: the sequence, circularly shifted left the number of places specified by the integer; if the integer is
      negative, it will be shifted right. -->
      <!-- It is up to the user to consider whether the bits are big- or little-endian as to the meaning of "left". -->
      <!--kw: numerics, binary -->
      <xsl:param name="bit-sequence" as="xs:boolean*"/>
      <xsl:param name="rotate-left" as="xs:integer"/>
      <xsl:variable name="bit-sequence-count" select="count($bit-sequence)" as="xs:integer"/>
      <xsl:variable name="places-to-shift" as="xs:integer"
         select="
            if ($bit-sequence-count ne 0) then
               $rotate-left mod $bit-sequence-count
            else
               0"
      />
      <xsl:variable name="places-to-shift-adjusted" as="xs:integer"
         select="
            if ($places-to-shift lt 0) then
               $places-to-shift + $bit-sequence-count
            else
               $places-to-shift"
      />
      
      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:bitwise-rotate()'"/>
         <xsl:message select="'Bit sequence: ' || tan:bits-to-bin($bit-sequence)"/>
         <xsl:message select="'Amount to left-rotate: ', $rotate-left"/>
         <xsl:message select="'Bit count:', $bit-sequence-count"/>
         <xsl:message select="'Places to shift:', $places-to-shift"/>
         <xsl:message select="'Places to shift adjusted:', $places-to-shift-adjusted"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="$places-to-shift eq 0">
            <xsl:sequence select="$bit-sequence"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="subsequence($bit-sequence, $places-to-shift-adjusted + 1), subsequence($bit-sequence, 1, $places-to-shift-adjusted)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:last-32-bits" as="xs:boolean*" visibility="public">
      <!-- Input: a sequence of booleans -->
      <!-- Output: the last 32 -->
      <!-- Used as a way of doing modulo 2 ^ 32, usually on big-endian bits; little-endian modulo 2 ^ 32 is easy with subsequence(X, 1, 32) -->
      <!--kw: numerics, binary -->
      <xsl:param name="bit-sequence" as="xs:boolean*"/>
      <xsl:sequence select="subsequence($bit-sequence, count($bit-sequence) - 31)"/>
   </xsl:function>
   
   
   



</xsl:stylesheet>
