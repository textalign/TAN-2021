<xsl:stylesheet exclude-result-prefixes="#all"  
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library standard numeral functions. -->
   
   <!-- If one wishes to see if an entire string matches the following patterns defined by these 
        variables, they must appear between the regular expression anchors ^ and $. -->
   <xsl:variable name="tan:roman-numeral-regex" as="xs:string">m{0,4}(cm|cd|d?c{0,3})(xc|xl|l?x{0,3})(im|ic|il|ix|iv|v?i{0,3})</xsl:variable>
   <xsl:variable name="tan:latin-letter-numeral-regex" as="xs:string">a+|b+|c+|d+|e+|f+|g+|h+|i+|j+|k+|l+|m+|n+|o+|p+|q+|r+|s+|t+|u+|v+|w+|x+|y+|z+</xsl:variable>
   
   <xsl:variable name="tan:n-type" select="('i', '1', '1a', 'a', 'a1', 'α', '$', 'i-or-a')" as="xs:string+"/>
   <xsl:variable name="tan:n-type-label" as="xs:string+"
      select="
      ('Roman numerals', 'Arabic numerals', 'Arabic numerals + alphabet numeral', 'alphabet numeral', 'alphabet numeral + Arabic numeral',
      'non-Latin-alphabet numeral', 'string', 'Roman or alphabet numeral')"/>
   
   <xsl:variable name="tan:n-type-regex" as="xs:string+">
      <xsl:sequence select="
            ('^(' || $tan:roman-numeral-regex || ')$'),
            '^(\d+)$',
            ('^(\d+)(' || $tan:latin-letter-numeral-regex || ')$'),
            ('^(' || $tan:latin-letter-numeral-regex || ')$'),
            ('^(' || $tan:latin-letter-numeral-regex || ')(\d+)$')"/>
      <xsl:sequence select="'^(' || $tan:nonlatin-letter-numeral-regex || ')$'"
         use-when="not($tan:validation-mode-on)"/>
      <xsl:sequence select="'(.)'"/>
   </xsl:variable>
   
   
   <xsl:function name="tan:rom-to-int" as="xs:integer*" visibility="public">
      <!-- Input: any roman numeral less than 5000 -->
      <!-- Output: the numeral converted to an integer -->
      <!--kw: numerals, numerics, Latin -->
      <xsl:param name="arg" as="xs:string*"/>
      <xsl:variable name="rom-cp" select="
            (109,
            100,
            99,
            108,
            120,
            118,
            105)" as="xs:integer+"/>
      <xsl:variable name="rom-cp-vals" select="
            (1000,
            500,
            100,
            50,
            10,
            5,
            1)" as="xs:integer+"/>
      <xsl:for-each select="$arg">
         <xsl:variable name="arg-lower" select="lower-case(.)"/>
         <xsl:if test="matches($arg-lower, '^' || $tan:roman-numeral-regex || '$')">
            <xsl:variable name="arg-seq" select="string-to-codepoints($arg-lower)"/>
            <xsl:variable name="arg-val-seq" select="
                  for $i in $arg-seq
                  return
                     $rom-cp-vals[index-of($rom-cp, $i)]"/>
            <xsl:variable name="arg-val-mod" select="
                  (for $i in (1 to count($arg-val-seq) - 1)
                  return
                     if ($arg-val-seq[$i] lt $arg-val-seq[$i + 1]) then
                        -1
                     else
                        1),
                  1"/>
            <xsl:sequence select="
                  sum(for $i in (1 to count($arg-val-seq))
                  return
                     $arg-val-seq[$i] * $arg-val-mod[$i])"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:aaa-to-int" as="xs:integer*" visibility="public">
      <!-- Input: any numerals in the supported letter numeral system -->
      <!-- Output: the integer equivalent -->
      <!-- Sequence goes a, b, c, ... z, aa, bb, ..., aaa, bbb, ....  E.g., 'ccc' - > 55 -->
      <!--kw: numerals, numerics -->
      <xsl:param name="arg" as="xs:string*"/>
      <xsl:for-each select="$arg">
         <xsl:variable name="arg-lower" select="lower-case(.)"/>
         <xsl:if test="matches($arg-lower, '^(' || $tan:latin-letter-numeral-regex || ')$')">
            <xsl:variable name="arg-length" select="string-length($arg-lower)"/>
            <xsl:variable name="arg-val" select="string-to-codepoints($arg-lower)[1] - 96"/>
            <xsl:sequence select="$arg-val + ($arg-length - 1) * 26"/>
         </xsl:if>
         
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:string-to-numerals" as="xs:string*" visibility="public">
      <!-- one-parameter version of the function below -->
      <xsl:param name="string-to-analyze" as="xs:string?"/>
      <xsl:sequence select="tan:string-to-numerals($string-to-analyze, true(), false(), (), ())"/>
   </xsl:function>
   <xsl:function name="tan:string-to-numerals" as="xs:string*" visibility="public">
      <!-- Input: a string thought to contain numerals of some type (e.g., Roman); a boolean indicating 
         whether ambiguous letters should be treated as Roman numerals or letter numerals; a boolean 
         indicating whether only numeral matches should be returned -->
      <!-- Output: the string with parts that look like numerals converted to Arabic numerals -->
      <!-- Does not take into account requests for help -->
      <!--kw: numerals, strings -->
      <xsl:param name="string-to-analyze" as="xs:string?"/>
      <xsl:param name="ambig-is-roman" as="xs:boolean?"/>
      <xsl:param name="return-only-numerals" as="xs:boolean?"/>
      <xsl:param name="n-alias-items" as="element()*"/>
      <xsl:param name="numeral-exceptions" as="xs:string*"/>
      <xsl:variable name="string-analyzed"
         select="tan:analyze-numbers-in-string($string-to-analyze, $ambig-is-roman, $n-alias-items, $numeral-exceptions)"/>
      <xsl:choose>
         <xsl:when test="$return-only-numerals">
            <xsl:sequence select="$string-analyzed/self::tan:tok[@number]"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="string-join($string-analyzed/text())"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:analyze-numbers-in-string" as="element()*" visibility="private">
      <!-- Companion function to tan:string-to-numerals(), to analyze the string as an XML fragment -->
      <xsl:param name="string-to-analyze" as="xs:string"/>
      <xsl:param name="ambig-is-roman" as="xs:boolean?"/>
      <xsl:param name="n-alias-items" as="element()*"/>
      <xsl:param name="numeral-exceptions" as="xs:string*"/>
      <xsl:variable name="string-parsed" as="element()*">
         <xsl:analyze-string select="$string-to-analyze" regex="[\w_]+">
            <xsl:matching-substring>
               <tok>
                  <xsl:value-of select="."/>
               </tok>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <non-tok>
                  <xsl:value-of select="."/>
               </non-tok>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:apply-templates select="$string-parsed" mode="tan:string-to-numerals">
         <xsl:with-param name="ambig-is-roman" select="($ambig-is-roman, true())[1]"/>
         <xsl:with-param name="n-alias-items" select="$n-alias-items"/>
         <xsl:with-param name="numeral-exceptions" select="$numeral-exceptions"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:string-to-numerals" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:tok" mode="tan:string-to-numerals">
      <xsl:param name="ambig-is-roman" as="xs:boolean" select="true()"/>
      <xsl:param name="numeral-exceptions" as="xs:string*"/>
      <xsl:param name="n-alias-items" as="element()*"/>
      <xsl:variable name="this-tok" select="."/>
      <xsl:variable name="these-alias-matches" select="$n-alias-items[tan:name = $this-tok]"/>
      <xsl:copy>
         <xsl:choose>
            <xsl:when test="exists($these-alias-matches)">
               <xsl:attribute name="non-number"/>
               <xsl:value-of select="replace($these-alias-matches[1]/tan:name[1], '\s', '_')"/>
            </xsl:when>
            <xsl:when test=". = $numeral-exceptions">
               <xsl:attribute name="non-number"/>
               <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test=". castable as xs:integer">
               <xsl:attribute name="number" select="$tan:n-type[2]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of select="xs:integer(.)"/>
            </xsl:when>
            <xsl:when test="matches(., $tan:n-type-regex[3], 'i')">
               <xsl:attribute name="number" select="$tan:n-type[3]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of
                  select="replace(., '\D+', '') || $tan:separator-hierarchy-minor || tan:aaa-to-int(replace(., '\d+', ''))"
               />
            </xsl:when>
            <xsl:when test="matches(., $tan:n-type-regex[1], 'i') and $ambig-is-roman">
               <xsl:attribute name="number" select="$tan:n-type[1]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of select="tan:rom-to-int(.)"/>
            </xsl:when>
            <xsl:when test="matches(., $tan:n-type-regex[4], 'i')">
               <xsl:attribute name="number" select="$tan:n-type[4]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of select="tan:aaa-to-int(.)"/>
            </xsl:when>
            <xsl:when test="matches(., $tan:n-type-regex[1], 'i')">
               <xsl:attribute name="number" select="$tan:n-type[1]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of select="tan:rom-to-int(.)"/>
            </xsl:when>
            <xsl:when test="matches(., $tan:n-type-regex[5], 'i')">
               <xsl:attribute name="number" select="$tan:n-type[5]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of
                  select="tan:aaa-to-int(replace(., '\d+', '')) || $tan:separator-hierarchy-minor || replace(., '\D+', '')"
               />
            </xsl:when>
            <xsl:when test="matches(., $tan:n-type-regex[6], 'i')" use-when="not($tan:validation-mode-on)">
               <xsl:attribute name="number" select="$tan:n-type[6]"/>
               <xsl:attribute name="orig" select="."/>
               <xsl:value-of select="tan:letter-to-number(.)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:attribute name="non-number"/>
               <xsl:value-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:string-to-int" as="xs:integer*" visibility="private">
      <!-- Companion fonction to tan:string-to-numerals() -->
      <!-- Returns only those results that can be evaluated as integers -->
      <xsl:param name="string" as="xs:string?"/>
      <xsl:variable name="pass-1" select="tan:string-to-numerals($string)"/>
      <xsl:for-each select="$pass-1">
         <xsl:if test=". castable as xs:integer">
            <xsl:copy-of select="xs:integer(.)"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:ordinal" xml:id="f-ordinal" as="xs:string*" visibility="public">
      <!-- Input: one or more numerals -->
      <!-- Output: one or more strings with the English form of the ordinal form of the input number -->
      <!-- Example: (1, 4, 17)  ->  ('first', 'fourth', '17th') -->
      <!--kw: numerals, numerics -->
      <xsl:param name="in" as="xs:integer*"/>
      <xsl:variable name="ordinals" select="
            ('first',
            'second',
            'third',
            'fourth',
            'fifth',
            'sixth',
            'seventh',
            'eighth',
            'ninth',
            'tenth')"/>
      <xsl:variable name="ordinal-suffixes" select="
            ('th',
            'st',
            'nd',
            'rd',
            'th',
            'th',
            'th',
            'th',
            'th',
            'th')"/>
      <xsl:sequence select="
            for $i in $in
            return
               if (exists($ordinals[$i]))
               then
                  $ordinals[$i]
               else
                  if ($i lt 1) then
                     'none'
                  else
                     (xs:string($i) || $ordinal-suffixes[($i mod 10) + 1])"/>
   </xsl:function>
   
   
   <xsl:function name="tan:cardinal" as="xs:string?" visibility="public">
      <!-- Input: an integer -->
      <!-- Output: the English term for the number -->
      <!--kw: numerals, numerics -->
      <xsl:param name="integer-to-convert" as="xs:integer?"/>
      
      <xsl:variable name="integer-rev" as="xs:string*"
         select="reverse(tan:chop-string(string($integer-to-convert)))"/>
      
      <xsl:variable name="integer-rev-parts" as="xs:string*">
         <xsl:iterate select="$integer-rev">
            <xsl:param name="prev-string" as="xs:string?"/>
            <xsl:param name="digit-pos" as="xs:integer" select="1"/>
            
            <xsl:on-completion>
               <xsl:sequence select="$prev-string"/>
            </xsl:on-completion>
            
            <xsl:variable name="place" as="xs:integer" select="$digit-pos mod 3"/>
            
            <xsl:variable name="default-name" as="xs:string?">
               <xsl:choose>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'one'">eleven</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'two'">twelve</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'three'">thirteen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'four'">fourteen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'five'">fifteen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'six'">sixteen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'seven'">seventeen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'eight'">eighteen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1' and $prev-string eq 'nine'">nineteen</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '1'">ten</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '2'">twenty</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '3'">thirty</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '4'">forty</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '5'">fifty</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '6'">sixty</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '7'">seventy</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '8'">eighty</xsl:when>
                  <xsl:when test="$place eq 2 and . eq '9'">ninety</xsl:when>
                  <xsl:when test=". eq '0'">zero</xsl:when>
                  <xsl:when test=". eq '1'">one</xsl:when>
                  <xsl:when test=". eq '2'">two</xsl:when>
                  <xsl:when test=". eq '3'">three</xsl:when>
                  <xsl:when test=". eq '4'">four</xsl:when>
                  <xsl:when test=". eq '5'">five</xsl:when>
                  <xsl:when test=". eq '6'">six</xsl:when>
                  <xsl:when test=". eq '7'">seven</xsl:when>
                  <xsl:when test=". eq '8'">eight</xsl:when>
                  <xsl:when test=". eq '9'">nine</xsl:when>
                  <xsl:when test=". eq '-'">negative</xsl:when>
               </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="ignore-last-item" as="xs:boolean" select="$prev-string eq 'zero' 
               or matches($default-name, 'eleven|twelve|teen')"/>
            
            <xsl:variable name="qualifier" as="xs:string?">
               <xsl:choose>
                  <xsl:when test=". = ('-', '0')"/>
                  <xsl:when test="$place eq 0">hundred</xsl:when>
                  <xsl:when test="$digit-pos eq 4">thousand</xsl:when>
                  <xsl:when test="$digit-pos eq 7">million</xsl:when>
                  <xsl:when test="$digit-pos eq 10">billion</xsl:when>
                  <xsl:when test="$digit-pos eq 13">trillion</xsl:when>
                  <xsl:when test="$digit-pos eq 16">quadrillion</xsl:when>
                  <xsl:when test="$digit-pos eq 19">quintillion</xsl:when>
               </xsl:choose>
               
            </xsl:variable>
            
            <!-- output -->
            
            <xsl:if test="not($ignore-last-item)">
               <xsl:sequence select="$prev-string"/>
            </xsl:if>
            
            <!--<xsl:sequence select="$default-name, $qualifier"/>-->
            
            <xsl:next-iteration>
               <xsl:with-param name="prev-string" select="string-join(($default-name, $qualifier), ' ')"/>
               <xsl:with-param name="digit-pos" select="$digit-pos + 1"/>
            </xsl:next-iteration>
            
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:choose>
         <xsl:when test="not(exists($integer-to-convert))"/>
         <xsl:when test="$integer-to-convert eq 0">zero</xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="string-join(reverse($integer-rev-parts), ' ')"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   
   

</xsl:stylesheet>
