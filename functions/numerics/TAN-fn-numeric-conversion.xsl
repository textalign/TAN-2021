<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xslq="https://github.com/mricaud/xsl-quality"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" version="3.0">

   <!-- TAN Function Library numeric conversion functions. -->
   
   <!-- This stylesheet collects all functions related to numerics, with an emphasis on conversion between base systems, 
      and binary conversions. -->

   <xsl:variable name="tan:numeric-conversion-error-key" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="'g1'">Base system not recognized</xsl:map-entry>
         <xsl:map-entry key="'g2'">Lexical form of numeral not recognized</xsl:map-entry>
      </xsl:map>
   </xsl:variable>
   
   <!-- BASE CONVERSIONS -->
   <!-- The following are straight-forward conversions to and from different base systems. All input and output is big endian -->
   <!-- Key base systems supported: 2 (bin), 10 (dec), 16 (hex), 26 (base26), 64 (base64) -->

   <xsl:function name="tan:dec-to-n" as="xs:string?" visibility="public">
      <!-- Input: two integers -->
      <!-- Output: a string that represents the first numeral in base N, where N is the second numeral (must be 2-16, 26, or 64) -->
      <!-- No padding is performed on the output (e.g., = in base-64, or initial zeroes in hexadecimal) -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:integer?"/>
      <xsl:param name="base" as="xs:integer"/>
      <xsl:variable name="in-abs" select="abs($in)" as="xs:integer?"/>
      
      <xsl:variable name="this-key" as="xs:string+">
         <xsl:choose>
            <xsl:when test="$base eq 64">
               <xsl:sequence select="$tan:base64-key"/>
            </xsl:when>
            <xsl:when test="$base eq 26">
               <xsl:sequence select="$tan:base26-key"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="subsequence($tan:hex-key, 1, $base)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="not($base = (2 to 16, 26, 64))">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g1'), $tan:numeric-conversion-error-key('g1'), $base)"/>
         </xsl:when>
         <xsl:when test="not(exists($in))"/>
         <xsl:otherwise>
            <xsl:sequence
               select="
                  (if ($in lt 0) then
                     '-'
                  else
                     '') ||
                  (if ($in-abs lt $base)
                  then
                     $this-key[$in-abs + 1]
                  else
                     (tan:dec-to-n($in-abs idiv $base, $base) || $this-key[($in-abs mod $base) + 1]))"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:n-to-dec" as="xs:integer?" visibility="public">
      <!-- Input: string representation of some number; an integer -->
      <!-- Output: an integer representing the first parameter in the base system of the 2nd parameter -->
      <!--kw: numerics -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:param name="base" as="xs:integer"/>
      <xsl:variable name="this-key" as="xs:string*">
         <xsl:choose>
            <xsl:when test="$base le 16">
               <xsl:sequence select="subsequence($tan:hex-key, 1, $base)"/>
            </xsl:when>
            <xsl:when test="$base eq 26">
               <xsl:sequence select="$tan:base26-key"/>
            </xsl:when>
            <xsl:when test="$base eq 64">
               <xsl:sequence select="$tan:base64-key"/>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="input-normalized" as="xs:string?"
         select="
            replace(if (($base le 16) or ($base eq 26)) then
               upper-case($input)
            else
               replace($input, '=+$', ''), '^-', '')"/>
      <xsl:variable name="digit-sequence" as="xs:integer*">
         <xsl:analyze-string select="$input-normalized" regex=".">
            <xsl:matching-substring>
               <xsl:copy-of select="index-of($this-key, .) - 1"/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="split-rev" select="reverse($digit-sequence)" as="xs:integer*"/>
      <xsl:variable name="modifier" as="xs:integer"
         select="
            if (starts-with($input, '-')) then
               -1
            else
               1"
      />

      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:n-to-dec()'"/>
         <xsl:message select="'input normalized: ', $input-normalized"/>
         <xsl:message select="'input is what base: ', $base"/>
         <xsl:message select="'this key: ', $this-key"/>
         <xsl:message select="'digit sequence: ', $digit-sequence"/>
      </xsl:if>

      <xsl:choose>
         <xsl:when test="not($base = (2 to 16, 26, 64))">
            <xsl:sequence select="error(QName($tan:TAN-namespace, 'g1'), $tan:numeric-conversion-error-key('g1'), $base)"/>
         </xsl:when>
         <xsl:when test="count($digit-sequence) lt string-length($input-normalized)">
            <xsl:sequence
               select="error(QName($tan:TAN-namespace, 'g2'), $tan:numeric-conversion-error-key('g2'), $input)"/>
         </xsl:when>
         <xsl:when test="(string-length($input) lt 1) or not(exists($input))"/>
         <xsl:otherwise>
            <xsl:sequence
               select="
                  $modifier *
                  sum(for $i in (1 to count($digit-sequence))
                  return
                     $split-rev[$i]
                     * (xs:integer(math:pow($base, $i - 1))))"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <!-- Conversions from decimal to base 2, 16, 26, & 64 and vice-versa -->

   <xsl:function name="tan:dec-to-bin" as="xs:string?" visibility="public">
      <!-- Input: an integer -->
      <!-- Output: the number in binary form, as a string -->
      <!-- Input is assumed to be big-endian -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:integer?"/>
      <xsl:sequence select="tan:dec-to-n($in, 2)"/>
   </xsl:function>
   
   <xsl:function name="tan:bin-to-dec" as="xs:integer?" visibility="public">
      <!-- Input: a binary -->
      <!-- Output: the number in decimal form, as an integer -->
      <!-- Input is assumed to be big-endian -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:sequence select="tan:n-to-dec($in, 2)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:dec-to-hex" as="xs:string?" visibility="public">
      <!-- Input: xs:integer -->
      <!-- Output: the hexadecimal equivalent as a string, e.g., 31 - > '1F' -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:integer?"/>
      <xsl:sequence select="tan:dec-to-n($in, 16)"/>
   </xsl:function>

   <xsl:function name="tan:hex-to-dec" as="xs:integer?" visibility="public">
      <!-- Input: a string representing a hexadecimal number -->
      <!-- Output: the integer value, e.g., '1F' - > 31 -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:sequence select="tan:n-to-dec($in, 16)"/>
   </xsl:function>


   <xsl:function name="tan:dec-to-base26" as="xs:string?" visibility="public">
      <!-- Input: xs:integer -->
      <!-- Output: the base 26 equivalent as a string, e.g., 31 - > 'BF' -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:integer?"/>
      <xsl:sequence select="tan:dec-to-n($in, 26)"/>
   </xsl:function>
   
   <xsl:function name="tan:base26-to-dec" as="xs:integer?" visibility="public">
      <!-- Input: a string representation of a base-26 number -->
      <!-- Output: an integer representing the base-10 value of the input -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:sequence select="tan:n-to-dec($in, 26)"/>
   </xsl:function>


   <xsl:function name="tan:dec-to-base64" as="xs:string?" visibility="public">
      <!-- Input: xs:integer -->
      <!-- Output: the base 64 equivalent as a string, e.g., 31 - > 'f' -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:integer?"/>
      <xsl:sequence select="tan:dec-to-n($in, 64)"/>
   </xsl:function>
   
   <xsl:function name="tan:base64-to-dec" as="xs:integer?" visibility="public">
      <!-- Input: a string representation of a base-64 number -->
      <!-- Output: an integer representing the base-10 value of the input -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:sequence select="tan:n-to-dec($in, 64)"/>
   </xsl:function>
   
   <!-- Some useful combinations using base 10 as a hub -->
   <!-- We assume that initial zeroes are intentional and should be retained in the output -->
   <!-- Negative signs will be retained. -->
   <!-- Note that although base64 output will be initial-zero-padded, it will not have any equals signs as trailing padding, necessary
      for casting as base64binary. -->

   <xsl:function name="tan:bin-to-hex" as="xs:string?" visibility="public">
      <!-- Input: a string representing a base 2 binary -->
      <!-- Output: a string representing the number in hexadecimal -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length(replace($in, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="raw-numeral" select="tan:dec-to-hex(tan:bin-to-dec($in))" as="xs:string?"/>
      <xsl:variable name="raw-numeral-length" select="string-length(replace($raw-numeral, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="initial-zeros-needed" as="xs:integer" select="xs:integer(ceiling(($in-length div 4)) - $raw-numeral-length)"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="replace($raw-numeral, '^(-?)(.)', '$1' || tan:fill('0', $initial-zeros-needed) || '$2')"/>
      </xsl:if>
   </xsl:function>

   <xsl:function name="tan:hex-to-bin" as="xs:string?" visibility="public">
      <!-- Input: a string representation of a hexadecimal number -->
      <!-- Output: a string representing the datum in binary code -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length(replace($in, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="raw-numeral" select="tan:dec-to-bin(tan:hex-to-dec($in))" as="xs:string?"/>
      <xsl:variable name="raw-numeral-length" select="string-length(replace($raw-numeral, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="initial-zeros-needed" as="xs:integer" select="xs:integer(ceiling(($in-length * 4)) - $raw-numeral-length)"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="replace($raw-numeral, '^(-?)(.)', '$1' || tan:fill('0', $initial-zeros-needed) || '$2')"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:bin-to-base64" as="xs:string?" visibility="public">
      <!-- Input: a string representing a base 2 binary -->
      <!-- Output: a string representing the number in base 64 -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length(replace($in, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="raw-numeral" select="tan:dec-to-base64(tan:bin-to-dec($in))" as="xs:string?"/>
      <xsl:variable name="raw-numeral-length" select="string-length(replace($raw-numeral, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="initial-zeros-needed" as="xs:integer" select="xs:integer(ceiling(($in-length div 6)) - $raw-numeral-length)"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="replace($raw-numeral, '^(-?)(.)', '$1' || tan:fill('A', $initial-zeros-needed) || '$2')"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:base64-to-bin" as="xs:string?" visibility="public">
      <!-- Input: a string representation of a base-64 number -->
      <!-- Output: a string representing the datum in binary code -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length(replace($in, '^-|=', ''))" as="xs:integer"/>
      <xsl:variable name="raw-numeral" select="tan:dec-to-bin(tan:base64-to-dec($in))" as="xs:string?"/>
      <xsl:variable name="raw-numeral-length" select="string-length(replace($raw-numeral, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="initial-zeros-needed" as="xs:integer" select="xs:integer(ceiling(($in-length * 6)) - $raw-numeral-length)"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="replace($raw-numeral, '^(-?)(.)', '$1' || tan:fill('0', $initial-zeros-needed) || '$2')"/>
      </xsl:if>
   </xsl:function>

   <!-- NB, hexadecimal (2^4) does not go into base-64 (2^6) evenly, so the number of digits varies for padded initial zeroes at a 3:2 ratio -->

   <xsl:function name="tan:hex-to-base64" as="xs:string?" visibility="public">
      <!-- Input: a string representing a hexadecimal number -->
      <!-- Output: a string representing the number in base 64 -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length(replace($in, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="raw-numeral" select="tan:dec-to-base64(tan:hex-to-dec($in))" as="xs:string?"/>
      <xsl:variable name="raw-numeral-length" select="string-length(replace($raw-numeral, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="initial-zeros-needed" as="xs:integer" select="xs:integer(ceiling(($in-length div 1.5)) - $raw-numeral-length)"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="replace($raw-numeral, '^(-?)(.)', '$1' || tan:fill('A', $initial-zeros-needed) || '$2')"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:base64-to-hex" as="xs:string?" visibility="public">
      <!-- Input: a string representation of a base-64 number -->
      <!-- Output: a string representing the datum in hexadecimal -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length(replace($in, '^-|=', ''))" as="xs:integer"/>
      <xsl:variable name="raw-numeral" select="tan:dec-to-hex(tan:base64-to-dec($in))" as="xs:string?"/>
      <xsl:variable name="raw-numeral-length" select="string-length(replace($raw-numeral, '^-', ''))" as="xs:integer"/>
      <xsl:variable name="initial-zeros-needed" as="xs:integer" select="xs:integer(ceiling(($in-length * 1.5)) - $raw-numeral-length)"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="replace($raw-numeral, '^(-?)(.)', '$1' || tan:fill('0', $initial-zeros-needed) || '$2')"/>
      </xsl:if>
   </xsl:function>
   
   
   <!-- CASTING FROM BASE-2, 16, 64 SYSTEMS TO/FROM DATA TYPES: BITS, HEXBINARY, BASE64BINARY -->
   <!-- For lack of a bit datatype, the boolean is used -->
   <!-- These conversion functions to not alter the sequence of digits/bits. Base-N numerals are assumed to be big-endian,
      and padding initial zeroes may be returned. -->
   
   <!-- Casting base-2 binary from/to data types -->
   
   <xsl:function name="tan:bin-to-bits" as="xs:boolean*" visibility="public">
      <!-- Input: any string representing base-2 binary -->
      <!-- Output: a sequence of booleans representing the bits of the binary -->
      <!--kw: numerics -->
      <xsl:param name="base-2-binary" as="xs:string?"/>
      <xsl:choose>
         <xsl:when test="string-length($base-2-binary) lt 1"/>
         <xsl:when test="not(matches($base-2-binary, '^-?[01]+$'))">
            <xsl:sequence
               select="error(QName($tan:TAN-namespace, 'g2'), $tan:numeric-conversion-error-key('g2'), $base-2-binary)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="starts-with($base-2-binary, '-')">
               <xsl:message select="'Negative value being cast to absolute.'"/>
            </xsl:if>
            <xsl:analyze-string select="$base-2-binary" regex="[01]">
               <xsl:matching-substring>
                  <xsl:sequence select=". eq '1'"/>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:bits-to-bin" as="xs:string?" visibility="public">
      <!-- Input: a sequence of booleans -->
      <!-- Output: a base-2 binary representation of the sequence -->
      <!-- Example: false, true, true > '011' -->
      <!--kw: numerics -->
      <xsl:param name="bits" as="xs:boolean*"/>
      <xsl:if test="exists($bits)">
         <xsl:sequence
            select="
               string-join(for $i in $bits
               return
                  (if ($i eq true()) then
                     '1'
                  else
                     '0'))"
         />
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:bin-to-hexBinary" as="xs:hexBinary?" visibility="public">
      <!-- Input: a string representing base-2 binary -->
      <!-- Output: the number as xs:hexBinary -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-as-hex" as="xs:string?" select="tan:bin-to-hex($in)"/>
      <xsl:if test="string-length($in) gt 0">
         <xsl:sequence select="tan:hex-to-hexBinary($in-as-hex)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:hexBinary-to-bin" as="xs:string?" visibility="public">
      <!-- Input: a hexBinary -->
      <!-- Output: a string with the value in base 2 -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:hexBinary?"/>
      <xsl:variable name="in-as-hex" as="xs:string?" select="string($in)"/>
      <xsl:if test="string-length($in-as-hex) gt 0">
         <xsl:sequence select="tan:hex-to-bin($in-as-hex)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:bin-to-base64Binary" as="xs:base64Binary?" visibility="public">
      <!-- Input: a string representing base-2 binary -->
      <!-- Output: the number as xs:base64Binary -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-as-hex" as="xs:string?" select="tan:bin-to-hex($in)"/>
      <xsl:variable name="in-as-hexBinary" as="xs:hexBinary?" select="tan:hex-to-hexBinary($in-as-hex)"/>
      <xsl:if test="string-length($in) gt 0">
         <xsl:sequence select="xs:base64Binary($in-as-hexBinary)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:base64Binary-to-bin" as="xs:string?" visibility="public">
      <!-- Input: a base64Binary -->
      <!-- Output: a string with the value in base 2 -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:variable name="in-as-hex" as="xs:string?" select="string(xs:hexBinary($in))"/>
      <xsl:if test="string-length($in-as-hex)">
         <xsl:sequence select="tan:hex-to-bin($in-as-hex)"/>
      </xsl:if>
   </xsl:function>
   
   
   <!-- Casting hexadecimal from/to data types -->
   
   <xsl:function name="tan:hex-to-bits" as="xs:boolean*" visibility="public">
      <!-- Input: any string representing base-2 binary -->
      <!-- Output: a sequence of booleans representing the bits of the binary -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:if test="string-length($in) gt 0">
         <xsl:sequence select="tan:hex-to-bin($in) => tan:bin-to-bits()"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:bits-to-hex" as="xs:string?" visibility="public">
      <!-- Input: a sequence of booleans -->
      <!-- Output: a base-2 binary representation of the sequence -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:boolean*"/>
      <xsl:if test="exists($in)">
         <xsl:sequence select="tan:bits-to-bin($in) => tan:bin-to-hex()"/>
      </xsl:if>
   </xsl:function>

   <xsl:function name="tan:hex-to-hexBinary" as="xs:hexBinary?" visibility="public">
      <!-- Input: a hexadecimal string -->
      <!-- Output: the string cast to xs:hexBinary, if possible -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-adjusted" select="replace($in, '^-', '')" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length($in-adjusted)" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="string-length($in) lt 1"/>
         <xsl:when test="not(matches($in, '^-?[a-fA-F0-9]+$'))">
            <xsl:sequence
               select="error(QName($tan:TAN-namespace, 'g2'), $tan:numeric-conversion-error-key('g2'), $in)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="starts-with($in, '-')">
               <xsl:message select="'Negative value being cast to absolute.'"/>
            </xsl:if>
            <xsl:sequence select="xs:hexBinary(tan:fill('0', $in-length mod 2) || $in-adjusted)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:hexBinary-to-hex" as="xs:string?" visibility="public">
      <!-- Input: a base64Binary -->
      <!-- Output: a string with the value in hexadecimal -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:hexBinary?"/>
      <xsl:if test="string-length(string($in)) gt 0">
         <xsl:sequence select="string($in)"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:hex-to-base64Binary" as="xs:base64Binary?" visibility="public">
      <!-- Input: a hexadecimal string -->
      <!-- Output: the string cast to xs:base64Binary, if possible -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-adjusted" select="replace($in, '^-', '')" as="xs:string?"/>
      <xsl:variable name="in-length" select="string-length($in-adjusted)" as="xs:integer"/>
      <xsl:choose>
         <xsl:when test="string-length($in) lt 1"/>
         <xsl:when test="not(matches($in, '^-?[a-zA-Z0-9/\+]+=*$'))">
            <xsl:sequence
               select="error(QName($tan:TAN-namespace, 'g2'), $tan:numeric-conversion-error-key('g2'), $in)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="starts-with($in, '-')">
               <xsl:message select="'Negative value being cast to absolute.'"/>
            </xsl:if>
            <xsl:sequence select="xs:base64Binary(xs:hexBinary(tan:fill('0', $in-length mod 2) || $in-adjusted))"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>
   
   <xsl:function name="tan:base64Binary-to-hex" as="xs:string?" visibility="public">
      <!-- Input: a base64Binary -->
      <!-- Output: a string with the value in hexadecimal -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:if test="string-length(string($in))">
         <xsl:sequence select="string(xs:hexBinary($in))"/>
      </xsl:if>
   </xsl:function>
   
   <!-- Casting base 64 from/to data types -->
   
   <xsl:function name="tan:base64-to-base64Binary" as="xs:base64Binary?" visibility="public">
      <!-- Input: a base-64 string -->
      <!-- Output: the string cast to xs:base64Binary, if possible -->
      <!-- base64Binary is not the same as a base 64 number, because it represents a redistribution of bits. For
      example, decimal/base-64 F = hex 05 = binary 00000101 whose bits must redistributed into the 4-digit 
      base64binary as follows:
      000001 01[0000] [padding] [padding]
      -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:string?"/>
      <xsl:variable name="in-adjusted" select="replace($in, '^-', '')" as="xs:string?"/>
      <xsl:variable name="in-as-hex" select="tan:base64-to-hex($in-adjusted)" as="xs:string?"/>
      <xsl:variable name="in-as-hexBinary" select="tan:hex-to-hexBinary($in-as-hex)" as="xs:hexBinary?"/>
      <xsl:choose>
         <xsl:when test="string-length($in) lt 1"/>
         <xsl:when test="not(matches($in, '^-?[a-zA-Z0-9/\+]+=*$'))">
            <xsl:sequence
               select="error(QName($tan:TAN-namespace, 'g2'), $tan:numeric-conversion-error-key('g2'), $in)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:if test="starts-with($in, '-')">
               <xsl:message select="'Negative value being cast to absolute.'"/>
            </xsl:if>
            <xsl:sequence select="xs:base64Binary($in-as-hexBinary)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:base64Binary-to-base64" as="xs:string?" visibility="public">
      <!-- Input: a base64Binary -->
      <!-- Output: the item as a base-64 number -->
      <!-- The output should have no more initial zeroes (A) than the input -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:variable name="in-as-string" select="string($in)" as="xs:string?"/>
      <xsl:variable name="initial-zeroes" as="xs:string?">
         <xsl:analyze-string select="$in-as-string" regex="^A+">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="in-as-hexBinary" select="xs:hexBinary($in)" as="xs:hexBinary?"/>
      <xsl:variable name="in-as-base64-string" as="xs:string?" select="tan:hex-to-base64(string($in-as-hexBinary))"/>
      <xsl:variable name="in-as-base64-string-adjusted" as="xs:string?" select="replace($in-as-base64-string, '^A+', '')"/>
      <xsl:if test="string-length($in-as-string) gt 0">
         <xsl:sequence select="$initial-zeroes || $in-as-base64-string-adjusted"/>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:base64binary-to-bin" as="xs:string?" visibility="public">
      <!-- Input: a base64binary -->
      <!-- Output: the number converted to a base 2 binary string -->
      <!--kw: numerics -->
      <xsl:param name="in" as="xs:base64Binary?"/>
      <xsl:variable name="in-as-hexBinary" select="xs:hexBinary($in)" as="xs:hexBinary?"/>
      <xsl:variable name="in-as-hex" select="string($in-as-hexBinary)" as="xs:string?"/>
      <xsl:if test="string-length($in-as-hex) gt 0">
         <xsl:sequence select="tan:hex-to-bin($in-as-hex)"/>
      </xsl:if>
   </xsl:function>

</xsl:stylesheet>
