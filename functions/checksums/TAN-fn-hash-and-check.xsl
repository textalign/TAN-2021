<?xml version="1.1" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xi="http://www.w3.org/2001/XInclude"
   xmlns:xslq="https://github.com/mricaud/xsl-quality"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" version="3.0">
   
   <!-- TAN Function Library hash and checksum functions. -->
   
   <!-- This stylesheet holds functions treating hash and cyclical redundancy check (CRC) functions. 
      The two types of function are similar. Both take an arbitrary string input and return a value, called a digest in the case of hash 
      functions and in the case of CRCs a checksum. CRCs are designed to protect against accidental changes, and so use regular, 
      polynomial-based distribution to produce distinct checksums for versions of the input. Hash functions, however, intended to
      secure encrypted messages, use a variety of methods to eliminate bias in the output, even if the input is heavily biased. Some 
      hash functions, such as MD5 (replicated below), are deprecated for security, but can nevertheless be used to check for 
      accidental changes.
   -->

   <xsl:variable name="tan:hash-error-key" as="map(*)">
      <xsl:map>
         <!-- Placeholder for errors -->
      </xsl:map>
   </xsl:variable>

   <!-- CHECKSUM FUNCTIONS -->

   <!-- FLETCHER -->

   <xsl:function name="tan:checksum-fletcher-16" as="xs:string?" visibility="public">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:sequence select="tan:checksum-fletcher($str, 1, true())"/>
   </xsl:function>
   <xsl:function name="tan:checksum-fletcher-16" as="item()?" visibility="public">
      <!-- Input: a string, a boolean -->
      <!-- Output: if the second parameter is true, a hexadecimal representation of the 
         Fletcher 16 checksum on the string, otherwise its integer representation -->
      <!-- kw: checksums -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:param name="output-hex" as="xs:boolean"/>
      <xsl:sequence select="tan:checksum-fletcher($str, 1, $output-hex)"/>
   </xsl:function>
   <xsl:function name="tan:checksum-fletcher-32" as="xs:string?" visibility="public">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:sequence select="tan:checksum-fletcher($str, 2, true())"/>
   </xsl:function>
   <xsl:function name="tan:checksum-fletcher-32" as="item()?" visibility="public">
      <!-- Input: a string, a boolean -->
      <!-- Output: if the second parameter is true, a hexadecimal representation of the 
         Fletcher 32 checksum on the string, otherwise its integer representation -->
      <!-- kw: checksums -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:param name="output-hex" as="xs:boolean"/>
      <xsl:sequence select="tan:checksum-fletcher($str, 2, $output-hex)"/>
   </xsl:function>
   <xsl:function name="tan:checksum-fletcher-64" as="xs:string?" visibility="public">
      <!-- one-parameter version of the fuller one, below -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:sequence select="tan:checksum-fletcher($str, 4, true())"/>
   </xsl:function>
   <xsl:function name="tan:checksum-fletcher-64" as="item()?" visibility="public">
      <!-- Input: a string, a boolean -->
      <!-- Output: if the second parameter is true, a hexadecimal representation of the 
         Fletcher 64 checksum on the string, otherwise its integer representation -->
      <!-- kw: checksums -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:param name="output-hex" as="xs:boolean"/>
      <xsl:sequence select="tan:checksum-fletcher($str, 4, $output-hex)"/>
   </xsl:function>

   <xsl:function name="tan:checksum-fletcher" as="item()?" visibility="private">
      <!-- Input: a string; an integer (4 = Fletcher-64; 2 = Fletcher-32; all other values Fletcher 16); a boolean -->
      <!-- Output: a Fletcher checksum for the string; the output is an integer if the third parameter is false, otherwise a hex value -->
      <!-- Fletcher-16 has the highest performance, but the greatest room for collision (in a set of 66K items, there will always be 
         duplicate checksums). In tests on a 4MB file, Fletcher-16 took 2.1 seconds; Fletcher-32: 5.5; Fletcher-64: 4.3. It seems that
         the processor better handles four-byte blocks than it does two-byte ones.
      -->
      <!-- kw: checksums -->
      <xsl:param name="str" as="xs:string?"/>
      <xsl:param name="byte-size" as="xs:integer"/>
      <xsl:param name="output-hex" as="xs:boolean"/>
      <!-- In the Fletcher checksum, applied blindly on codepoints-to-string(), " " and "ğ" return the same checksum,
      because their codpoint values are 255 apart. So UTF-8 needs to be converted to byte form. -->
      <xsl:variable name="str-8bit"
         select="
            if (string-length($str) gt 0) then
               tan:string-to-utf-8-octets($str)
            else
               ()"
         as="xs:integer*"/>
      <xsl:variable name="byte-size-norm" as="xs:integer">
         <xsl:choose>
            <xsl:when test="not($byte-size = (1, 2, 4))">
               <xsl:sequence select="1"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$byte-size"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="size-limit" as="xs:integer"
         select="xs:integer(math:pow(256, $byte-size-norm))"/>
      <xsl:variable name="modulo" as="xs:integer" select="$size-limit - 1"/>
      <xsl:variable name="byte-group-integers" as="xs:integer*">
         <xsl:choose>
            <xsl:when test="$byte-size-norm > 1">
               <!-- Other ways to construct this variable were tested, e.g., for-each-group and subsequence(), but they did not 
                  perform as well as what follows. -->
               <xsl:for-each
                  select="0 to xs:integer(ceiling(count($str-8bit) div $byte-size-norm) - 1)">
                  <xsl:variable name="address" select=". * $byte-size-norm" as="xs:integer"/>
                  <xsl:sequence
                     select="
                        xs:integer(sum(
                        for $i in (1 to $byte-size-norm)
                        return
                           ($str-8bit[$address + $i], 0)[1] * math:pow(256, $i - 1)
                        ))"/>

               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$str-8bit"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:checksum-fletcher()'"/>
         <xsl:message select="'Input string (length ' || string(string-length($str)) || '): ' || tan:ellipses($str, 20)"/>
         <xsl:message select="'Byte size: ' || string($byte-size)"/>
         <xsl:message select="'Output as hex? ' || string($output-hex)"/>
         <xsl:message
            select="
               'Beginning of 8 bit codepoints: ' || string-join(for $i in subsequence($str-8bit, 1, 10)
               return
                  string($i))"
         />
         <xsl:message select="'Byte size: ' || string($byte-size-norm)"/>
         <xsl:message select="'Size limit: ' || string($size-limit)"/>
      </xsl:if>
      
      <xsl:iterate select="$byte-group-integers">
         <xsl:param name="sum1" as="xs:integer" select="0"/>
         <xsl:param name="sum2" as="xs:integer" select="0"/>
         <xsl:on-completion>
            <xsl:choose>
               <xsl:when test="not(exists($str))"/>
               <xsl:when test="$output-hex">
                  <xsl:variable name="out-hex" as="xs:string?"
                     select="tan:dec-to-hex(($sum2 mod $modulo) * $size-limit + ($sum1 mod $modulo))"/>
                  <xsl:variable name="out-hex-len" select="string-length($out-hex)" as="xs:integer"/>
                  <xsl:choose>
                     <xsl:when test="$out-hex-len lt (4 * $byte-size-norm)">
                        <xsl:sequence
                           select="tan:fill('0', (4 * $byte-size-norm) - $out-hex-len) || $out-hex"
                        />
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="$out-hex"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="($sum2 mod $modulo) * $size-limit + ($sum1 mod $modulo)"/>
               </xsl:otherwise>
            </xsl:choose>

         </xsl:on-completion>
         <xsl:variable name="new-sum-1a" select="$sum1 + ." as="xs:integer"/>
         <xsl:variable name="new-sum-1b"
            select="
               if ($new-sum-1a gt $modulo) then
                  $new-sum-1a - $modulo
               else
                  $new-sum-1a" as="xs:integer"/>
         <xsl:next-iteration>
            <xsl:with-param name="sum1" select="$new-sum-1b" as="xs:integer"/>
            <xsl:with-param name="sum2" select="$sum2 + $new-sum-1b" as="xs:integer"/>
         </xsl:next-iteration>
      </xsl:iterate>

   </xsl:function>



   <!-- HASH FUNCTIONS -->
   
   <!-- MD5 -->
   
   <!-- The hash function MD5 can be time-consuming to run in XSLT for large strings or files. In tests, a 256k message took 39.4 seconds
   for a digest to be produced. The same output can be produced in other programming languages in less than a second. -->

   <!-- Initialize constants -->
   
   <xsl:variable name="tan:md5-shifts" as="xs:integer+" 
      select="
      7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  
      5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20, 
      4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
      6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
      "/>
   
   <!-- The following variables include commented-out versions that document how they are calculated -->
   <!--<xsl:variable name="tan:md5-K" as="xs:integer+"
      select="
         for $i in (1 to 64)
         return
            xs:integer(floor(4294967296 * abs(math:sin($i))))
         "
   />-->
   <xsl:variable name="tan:md5-K" as="xs:integer+" select="3614090360, 3905402710, 606105819, 3250441966, 4118548399, 1200080426, 2821735955, 4249261313, 1770035416, 2336552879, 4294925233, 2304563134, 1804603682, 4254626195, 2792965006, 1236535329, 4129170786, 3225465664, 643717713, 3921069994, 3593408605, 38016083, 3634488961, 3889429448, 568446438, 3275163606, 4107603335, 1163531501, 2850285829, 4243563512, 1735328473, 2368359562, 4294588738, 2272392833, 1839030562, 4259657740, 2763975236, 1272893353, 4139469664, 3200236656, 681279174, 3936430074, 3572445317, 76029189, 3654602809, 3873151461, 530742520, 3299628645, 4096336452, 1126891415, 2878612391, 4237533241, 1700485571, 2399980690, 4293915773, 2240044497, 1873313359, 4264355552, 2734768916, 1309151649, 4149444226, 3174756917, 718787259, 3951481745"/>
   <!--<xsl:variable name="tan:md5-a0" as="xs:boolean+" select="tan:bits-to-word(reverse(tan:bin-to-bits(tan:dec-to-bin(1732584193))), false())"/>-->
   <!--<xsl:variable name="tan:md5-b0" as="xs:boolean+" select="tan:bits-to-word(reverse(tan:bin-to-bits(tan:dec-to-bin(4023233417))), false())"/>-->
   <!--<xsl:variable name="tan:md5-c0" as="xs:boolean+" select="tan:bits-to-word(reverse(tan:bin-to-bits(tan:dec-to-bin(2562383102))), false())"/>-->
   <!--<xsl:variable name="tan:md5-d0" as="xs:boolean+" select="tan:bits-to-word(reverse(tan:bin-to-bits(tan:dec-to-bin(271733878))), false())"/>-->
   <xsl:variable name="tan:md5-a0" as="xs:boolean+" select="true(), false(), false(), false(), false(), false(), false(), false(), true(), true(), false(), false(), false(), true(), false(), false(), true(), false(), true(), false(), false(), false(), true(), false(), true(), true(), true(), false(), false(), true(), true(), false()"/>
   <xsl:variable name="tan:md5-b0" as="xs:boolean+" select="true(), false(), false(), true(), false(), false(), false(), true(), true(), true(), false(), true(), false(), true(), false(), true(), true(), false(), true(), true(), false(), false(), true(), true(), true(), true(), true(), true(), false(), true(), true(), true()"/>
   <xsl:variable name="tan:md5-c0" as="xs:boolean+" select="false(), true(), true(), true(), true(), true(), true(), true(), false(), false(), true(), true(), true(), false(), true(), true(), false(), true(), false(), true(), true(), true(), false(), true(), false(), false(), false(), true(), true(), false(), false(), true()"/>
   <xsl:variable name="tan:md5-d0" as="xs:boolean+" select="false(), true(), true(), false(), true(), true(), true(), false(), false(), false(), true(), false(), true(), false(), true(), false(), false(), true(), false(), false(), true(), true(), false(), false(), false(), false(), false(), false(), true(), false(), false(), false()"/>
   <!--<xsl:variable name="tan:pow2-32" select="math:pow(2, 32)" as="xs:double"/>-->
   <!--<xsl:variable name="tan:pow2-64" select="math:pow(2, 64)" as="xs:double"/>-->
   <xsl:variable name="tan:pow2-32" select="xs:double('4.294967296E9')" as="xs:double"/>
   <xsl:variable name="tan:pow2-64" select="xs:double('1.844674407370955E19')" as="xs:double"/>
   
   <!-- Diagnostic functions, to convert bits into int32, to compare against other MD5 algorithms that work with that value. This function was 
      tested against the JavaScript MD5 function written by Joseph Myers, Paul Johnston, Greg Holt, Will Bond 
      http://www.myersdaily.org/joseph/javascript/md5-text.html
      http://pajhome.org.uk/crypt/md5 -->
   
   <xsl:function name="tan:int-with-mod-2-32-negation" as="xs:string?" visibility="private">
      <!-- Input: an integer -->
      <!-- Output: a string of the integer along with its negative value minus 2 ^32 -->
      <!-- This was written to facilitate comparison with the Myers et al JavaScript MD5 process -->
      <xsl:param name="integer-input" as="xs:integer?"/>
      <xsl:value-of select="string($integer-input) || ' / ' || string($integer-input - $tan:pow2-32)"/>
   </xsl:function>
   
   <xsl:function name="tan:le-bits-to-int-and-neg" as="xs:string?" visibility="private">
      <!-- Input: a series of little-endian bits -->
      <!-- Output: the decimal value (+ negative mod 2 ^ 32) -->
      <!-- This was written to facilitate comparison with the Myers et al JavaScript MD5 process -->
      <xsl:param name="input-bits" as="xs:boolean*"/>
      <xsl:sequence
         select="tan:bits-to-bin($input-bits) => tan:reverse-string() => tan:bin-to-dec() => tan:int-with-mod-2-32-negation()"
      />
   </xsl:function>
   
   <!-- The main function -->
   
   <xsl:function name="tan:md5" as="item()*" visibility="public">
      <!-- Input: a string -->
      <!-- Output: an MD5 checksum for the string -->
      <!--kw: checksums -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:variable name="input-as-8-bit-chars" select="tan:unicode-to-eight-bit-chars($input)" as="xs:string?"/>
      <!-- The each character's bits gets reversed, because we are converting from big to little endian -->
      <xsl:variable name="input-as-bits" as="xs:boolean*"
         select="
            for $i in string-to-codepoints($input-as-8-bit-chars)
            return
               tan:bits-to-byte(reverse(tan:bin-to-bits(tan:dec-to-bin($i))), false())"
      />
      <!-- At least one bit of 1 must be added, and then the rest of the input is padded with 0 bits until it is just 64 bits shy of a full 512 block. -->
      <!-- Counter-intuitively, the bits are not packed sequentially, but as byte components, one byte at a time. When a single bit is packed into a 
      byte, the packing begins with the most significant digit. So if you add the padded 1 bit, followed by 0 bits, it looks like you have added
      a value of 128: 1000000 big-endian, 00000001 little-endian. Because we are dealing in this function with strings, not binaries, we can
      presume the input is a multiple of eight, so we can pack in a whole byte value of 128 (little endian). -->
      <xsl:variable name="input-bits-true-padded"
         select="$input-as-bits, false(), false(), false(), false(), false(), false(), false(), true()"
         as="xs:boolean+"/>
      <xsl:variable name="input-bits-true-padded-length" select="count($input-bits-true-padded)" as="xs:integer"/>
      <xsl:variable name="input-bits-true-padded-length-mod512" select="$input-bits-true-padded-length mod 512" as="xs:integer"/>
      <!-- We want to measure against 448 on modulo 512, so we start from the second modulo, 960 -->
      <xsl:variable name="number-of-zero-bits-to-append" select="(960 - $input-bits-true-padded-length-mod512) mod 512" as="xs:integer"/>
      <xsl:variable name="input-bits-true-and-false-padded" as="xs:boolean+"
         select="
            $input-bits-true-padded,
            (for $i in (1 to $number-of-zero-bits-to-append)
            return
               false())"
      />
      <xsl:variable name="original-length-as-integer" as="xs:integer"
         select="
            if ($input-bits-true-padded-length gt $tan:pow2-64) then
               xs:integer(($input-bits-true-padded-length - 8) mod $tan:pow2-64)
            else
               $input-bits-true-padded-length - 8"
      />
      <xsl:variable name="original-length-as-bits" as="xs:boolean*"
         select="
            reverse(tan:bin-to-bits(tan:dec-to-bin($original-length-as-integer)))"
      />
      <xsl:variable name="extra-falses-to-pad" select="64 - count($original-length-as-bits)" as="xs:integer"/>
      <xsl:variable name="input-prepped-as-bits" as="xs:boolean+"
         select="
            $input-bits-true-and-false-padded,
            $original-length-as-bits,
            (for $i in (1 to $extra-falses-to-pad)
            return
               false())"
      />
      <xsl:variable name="input-chunk-count" select="count($input-prepped-as-bits) idiv 512" as="xs:integer"/>
      <xsl:variable name="input-chunks" as="array(array(xs:boolean+)+)+"
         select="
            for $i in (0 to $input-chunk-count - 1)
            return
               array {
                  for $j in (0 to 15)
                  return
                     array {
                        subsequence($input-prepped-as-bits, ($i * 512) + ($j * 32) + 1, 32)
                     }
               
               }"
      />
      
      
      <xsl:variable name="process-abcd" as="xs:boolean*">
         <xsl:iterate select="$input-chunks">
            <xsl:param name="a-so-far" as="xs:boolean+" select="$tan:md5-a0"/>
            <xsl:param name="b-so-far" as="xs:boolean+" select="$tan:md5-b0"/>
            <xsl:param name="c-so-far" as="xs:boolean+" select="$tan:md5-c0"/>
            <xsl:param name="d-so-far" as="xs:boolean+" select="$tan:md5-d0"/>
            <xsl:on-completion>
               <xsl:sequence select="$a-so-far, $b-so-far, $c-so-far, $d-so-far"/>
            </xsl:on-completion>
            
            <xsl:variable name="this-chunk" as="array(array(xs:boolean+)+)" select="."/>
            
            <xsl:variable name="main-loop" as="array(xs:boolean+)+">
               <xsl:iterate select="0 to 63">
                  <xsl:param name="A-so-far" as="xs:boolean+" select="$a-so-far"/>
                  <xsl:param name="B-so-far" as="xs:boolean+" select="$b-so-far"/>
                  <xsl:param name="C-so-far" as="xs:boolean+" select="$c-so-far"/>
                  <xsl:param name="D-so-far" as="xs:boolean+" select="$d-so-far"/>
                  <xsl:param name="F-so-far" as="xs:boolean*"/>
                  <xsl:on-completion>
                     <!-- Four arrays of booleans/bits -->
                     <xsl:sequence select="[$A-so-far], [$B-so-far], [$C-so-far], [$D-so-far]"/>
                  </xsl:on-completion>
                  <xsl:variable name="this-i" select="." as="xs:integer"/>
                  <xsl:variable name="this-i-plus" select=". + 1" as="xs:integer"/>
                  <xsl:variable name="this-K-sine-val"
                     select="tan:bits-to-word(reverse(tan:bin-to-bits(tan:dec-to-bin($tan:md5-K[$this-i-plus]))), false())"
                     as="xs:boolean+"/>
                  
                  <xsl:variable name="F-pass-1" as="xs:boolean+">
                     <xsl:choose>
                        <xsl:when test="$this-i le 15">
                           <!-- (B and C) or ((not B) and D) -->
                           <xsl:sequence
                              select="tan:bitwise-or(tan:bitwise-and($B-so-far, $C-so-far), tan:bitwise-and(tan:bitwise-not($B-so-far), $D-so-far))"
                           />
                        </xsl:when>
                        <xsl:when test="$this-i le 31">
                           <!-- (D and B) or ((not D) and C) -->
                           <xsl:sequence
                              select="tan:bitwise-or(tan:bitwise-and($D-so-far, $B-so-far), tan:bitwise-and(tan:bitwise-not($D-so-far), $C-so-far))"
                           />
                        </xsl:when>
                        <xsl:when test="$this-i le 47">
                           <!-- B xor C xor D -->
                           <xsl:sequence
                              select="tan:bitwise-xor(tan:bitwise-xor($B-so-far, $C-so-far), $D-so-far)"
                           />
                        </xsl:when>
                        <xsl:otherwise>
                           <!-- C xor (B or (not D)) -->
                           <xsl:sequence
                              select="tan:bitwise-xor($C-so-far, tan:bitwise-or($B-so-far, tan:bitwise-not($D-so-far)))"
                           />
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:variable>
                  
                  <xsl:variable name="var-g" as="xs:integer">
                     <xsl:choose>
                        <xsl:when test="$this-i le 15">
                           <xsl:sequence select="$this-i"/>
                        </xsl:when>
                        <xsl:when test="$this-i le 31">
                           <xsl:sequence select="((5 * $this-i) + 1) mod 16"/>
                        </xsl:when>
                        <xsl:when test="$this-i le 47">
                           <xsl:sequence select="((3 * $this-i) + 5) mod 16"/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:sequence select="(7 * $this-i) mod 16"/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="this-chunk-word" select="$this-chunk($var-g + 1)" as="xs:boolean+"/>
                  
                  <xsl:variable name="new-F"
                     select="subsequence(tan:bitwise-plus(tan:bitwise-plus(tan:bitwise-plus($F-pass-1, $A-so-far, false()), $this-K-sine-val, false()), $this-chunk-word, false()), 1, 32)"
                     as="xs:boolean+"/>
                  <xsl:variable name="new-B" as="xs:boolean+"
                     select="subsequence(tan:bitwise-plus($B-so-far, tan:bitwise-rotate($new-F, $tan:md5-shifts[$this-i-plus] * -1), false()), 1, 32)"
                  />
                  
                  <xsl:variable name="diag-2-on" select="false()" as="xs:boolean?"/>
                  <xsl:if test="$diag-2-on">
                     <xsl:message select="'ABCD after round ' || string(.) || ': ' || string-join((tan:bits-to-bin($A-so-far), tan:bits-to-bin($B-so-far), tan:bits-to-bin($C-so-far), tan:bits-to-bin($D-so-far)), ' ')"/>
                     <xsl:message select="'F so far: ' || tan:bits-to-bin($F-so-far)"/>
                     <xsl:message select="'For JavaScript comparison: ' || string-join(
                        (
                              tan:le-bits-to-int-and-neg($A-so-far),
                              tan:le-bits-to-int-and-neg($B-so-far),
                              tan:le-bits-to-int-and-neg($C-so-far),
                              tan:le-bits-to-int-and-neg($D-so-far)
                            ), ' || '
                        )"/>
                     <xsl:message select="'Round ' || string($this-i-plus) || ' values: K-sine: ' || tan:le-bits-to-int-and-neg($this-K-sine-val) 
                        || ' || This chunk word: ' || tan:le-bits-to-int-and-neg($this-chunk-word) || ' || F pass 1: ' || tan:le-bits-to-int-and-neg($F-pass-1)
                        || ' || New F: ' || tan:le-bits-to-int-and-neg($new-F)
                        "
                     />
                     <xsl:message select="'   B construction: shift: ' || string($tan:md5-shifts[$this-i-plus])
                        || ' || Bitwise rotation of new F: ' || tan:le-bits-to-int-and-neg(tan:bitwise-rotate($new-F, $tan:md5-shifts[$this-i-plus] * -1))
                        || ' || New B: ' || tan:le-bits-to-int-and-neg($new-B)
                        "/>
                     <xsl:message select="tan:bits-to-bin($new-F)"/>
                     <xsl:message select="tan:bits-to-bin(tan:bitwise-rotate($new-F, $tan:md5-shifts[$this-i-plus]))"/>
                  </xsl:if>
                  
                  <xsl:next-iteration>
                     <xsl:with-param name="A-so-far" select="$D-so-far" as="xs:boolean+"/>
                     <xsl:with-param name="B-so-far" select="$new-B" as="xs:boolean+"/>
                     <xsl:with-param name="C-so-far" select="$B-so-far" as="xs:boolean+"/>
                     <xsl:with-param name="D-so-far" select="$C-so-far" as="xs:boolean+"/>
                     <xsl:with-param name="F-so-far" select="$new-F" as="xs:boolean+"/>
                  </xsl:next-iteration>
               </xsl:iterate>
               
            </xsl:variable>
            
            <xsl:variable name="new-a" select="subsequence(tan:bitwise-plus($a-so-far, $main-loop[1], false()), 1, 32)" as="xs:boolean+"/>
            <xsl:variable name="new-b" select="subsequence(tan:bitwise-plus($b-so-far, $main-loop[2], false()), 1, 32)" as="xs:boolean+"/>
            <xsl:variable name="new-c" select="subsequence(tan:bitwise-plus($c-so-far, $main-loop[3], false()), 1, 32)" as="xs:boolean+"/>
            <xsl:variable name="new-d" select="subsequence(tan:bitwise-plus($d-so-far, $main-loop[4], false()), 1, 32)" as="xs:boolean+"/>
            
            <xsl:variable name="diag-1-on" select="false()" as="xs:boolean"/>
            <xsl:if test="$diag-1-on">
               <xsl:message select="'Chunk ', position()"/>
               <xsl:message select="'inherited abcd: ' || string-join((
                        tan:le-bits-to-int-and-neg($a-so-far),
                        tan:le-bits-to-int-and-neg($b-so-far),
                        tan:le-bits-to-int-and-neg($c-so-far),
                        tan:le-bits-to-int-and-neg($d-so-far)
                  ), ' || ')"/>
               <xsl:message select="'new abcd: ' || string-join((
                        tan:le-bits-to-int-and-neg($new-a),
                        tan:le-bits-to-int-and-neg($new-b),
                        tan:le-bits-to-int-and-neg($new-c),
                        tan:le-bits-to-int-and-neg($new-d)
                  ), ' || ')"/>
            </xsl:if>
            
            <xsl:next-iteration>
               <xsl:with-param name="a-so-far" select="$new-a" as="xs:boolean*"/>
               <xsl:with-param name="b-so-far" select="$new-b" as="xs:boolean*"/>
               <xsl:with-param name="c-so-far" select="$new-c" as="xs:boolean*"/>
               <xsl:with-param name="d-so-far" select="$new-d" as="xs:boolean*"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:variable name="abcd-as-hex" as="xs:string+">
         <xsl:for-each select="0 to 3">
            <xsl:variable name="this-pos" select="." as="xs:integer"/>
            <xsl:variable name="these-bits" select="subsequence($process-abcd, ($this-pos * 32) + 1, 32)" as="xs:boolean+"/>
               <xsl:for-each select="0 to 3">
                  <xsl:variable name="this-b-pos" select="." as="xs:integer"/>
                  <xsl:variable name="these-b-bits" select="subsequence($these-bits, ($this-b-pos * 8) + 1, 8)" as="xs:boolean+"/>
                  <xsl:variable name="these-b-bits-as-bin" select="tan:bits-to-bin(reverse($these-b-bits))" as="xs:string"/>
                  <xsl:variable name="these-b-bits-as-int" select="tan:bin-to-dec($these-b-bits-as-bin)" as="xs:integer"/>
                  <xsl:variable name="these-b-bits-as-hex" select="tan:dec-to-hex($these-b-bits-as-int)" as="xs:string"/>
                  <xsl:if test="string-length($these-b-bits-as-hex) eq 1">
                     <xsl:value-of select="'0'"/>
                  </xsl:if>
                  <xsl:value-of select="$these-b-bits-as-hex"/>
               </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <diagnostics>
            <input length="{string-length($input)}"><xsl:value-of select="tan:ellipses($input, 32)"/></input>
            <input-as-8-bit-chars length="{string-length($input-as-8-bit-chars)}"><xsl:value-of select="tan:ellipses($input-as-8-bit-chars, 320)"/></input-as-8-bit-chars>
            <input-bits-true-padded-le><xsl:value-of select="tan:ellipses(tan:bits-to-bin($input-bits-true-padded), 320)"/></input-bits-true-padded-le>
            <original-length>
               <int><xsl:value-of select="$original-length-as-integer"/></int>
               <bits><xsl:value-of select="tan:bits-to-bin($original-length-as-bits)"/></bits>
            </original-length>
            <number-of-zero-bits-to-append><xsl:value-of select="$number-of-zero-bits-to-append"/></number-of-zero-bits-to-append>
            <input-chunks size="{count($input-chunks)}">
               <xsl:for-each select="$input-chunks">
                  <xsl:variable name="this-chunk" select="." as="array(array(xs:boolean+)+)"/>
                  <xsl:variable name="this-chunk-size" select="array:size($this-chunk)" as="xs:integer"/>
                  <xsl:variable name="this-chunk-first-member" select="$this-chunk(1)" as="array(xs:boolean+)"/>
                  <chunk n="{position()}" size="{$this-chunk-size}" size-first-member="{array:size($this-chunk-first-member)}">
                     <xsl:for-each select="1 to $this-chunk-size">
                        <xsl:variable name="this-word" select="$this-chunk(.)" as="xs:boolean+"/>
                        <xsl:variable name="this-word-le" select="tan:bits-to-bin($this-word)" as="xs:string"/>
                        <xsl:variable name="this-word-be" select="tan:reverse-string($this-word-le)" as="xs:string"/>
                        <xsl:variable name="this-word-dec" select="tan:bin-to-dec($this-word-be)" as="xs:integer"/>
                        <xsl:variable name="this-word-hex" select="tan:dec-to-hex($this-word-dec)" as="xs:string"/>
                        <word n="{.}">
                           <bin-le><xsl:value-of select="$this-word-le"/></bin-le>
                           <int><xsl:value-of select="tan:le-bits-to-int-and-neg($this-word)"/></int>
                           <bin-be><xsl:value-of select="$this-word-be"/></bin-be>
                           <dec><xsl:value-of select="$this-word-dec"/></dec>
                           <hex><xsl:value-of select="$this-word-hex"/></hex>
                        </word>
                     </xsl:for-each>
                  </chunk>
                  
               </xsl:for-each>
            </input-chunks>
            <process-abcd>
               <bin-le><xsl:copy-of select="tan:bits-to-bin($process-abcd)"/></bin-le>
               <bin-le-hex><xsl:copy-of select="tan:dec-to-hex(tan:bin-to-dec(tan:bits-to-bin($process-abcd)))"/></bin-le-hex>
               <bin-be><xsl:copy-of select="tan:reverse-string(tan:bits-to-bin($process-abcd))"/></bin-be>
               <bin-me-hex><xsl:copy-of select="tan:dec-to-hex(tan:bin-to-dec(tan:reverse-string(tan:bits-to-bin($process-abcd))))"/></bin-me-hex>
               <xsl:for-each select="0 to 3">
                  <xsl:variable name="this-pos" select="." as="xs:integer"/>
                  <xsl:variable name="these-bits" select="subsequence($process-abcd, ($this-pos * 32) + 1, 32)" as="xs:boolean+"/>
                  <xsl:variable name="these-bits-as-bin" select="tan:bits-to-bin(reverse($these-bits))" as="xs:string"/>
                  <xsl:variable name="these-bits-as-int" select="tan:bin-to-dec($these-bits-as-bin)" as="xs:integer"/>
                  <xsl:variable name="these-bits-as-hex" select="lower-case(tan:dec-to-hex($these-bits-as-int))" as="xs:string"/>
                  <package n="{position()}">
                     <bin><xsl:value-of select="$these-bits-as-bin"/></bin>
                     <int><xsl:value-of select="$these-bits-as-int"/></int>
                     <hex><xsl:value-of select="$these-bits-as-hex"/></hex>
                     <xsl:for-each select="0 to 3">
                        <xsl:variable name="this-b-pos" select="." as="xs:integer"/>
                        <xsl:variable name="these-b-bits" select="subsequence($these-bits, ($this-b-pos * 8) + 1, 8)" as="xs:boolean+"/>
                        <xsl:variable name="these-b-bits-as-bin" select="tan:bits-to-bin(reverse($these-b-bits))" as="xs:string"/>
                        <xsl:variable name="these-b-bits-as-int" select="tan:bin-to-dec($these-b-bits-as-bin)" as="xs:integer"/>
                        <xsl:variable name="these-b-bits-as-hex" select="lower-case(tan:dec-to-hex($these-b-bits-as-int))" as="xs:string"/>
                        <byte n="{position()}">
                           <bin><xsl:value-of select="$these-b-bits-as-bin"/></bin>
                           <int><xsl:value-of select="$these-b-bits-as-int"/></int>
                           <hex><xsl:value-of select="$these-b-bits-as-hex"/></hex>
                        </byte>
                     </xsl:for-each>
                  </package>
               </xsl:for-each>
            </process-abcd>
         </diagnostics>
      </xsl:if>
      
      <xsl:sequence select="lower-case(string-join($abcd-as-hex))"/>
      
   </xsl:function>

</xsl:stylesheet>
