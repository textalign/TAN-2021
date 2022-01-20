<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended numeral functions. -->
   <!-- These components are available only to applications, not validation -->
   
   <xsl:variable name="tan:arabic-indic-numeral-regex" as="xs:string">[٠١٢٣٤٥٦٧٨٩]+</xsl:variable>
   
   <xsl:variable name="tan:greek-unit-regex" as="xs:string">[α-θΑ-ΘϛϚ]</xsl:variable>
   <xsl:variable name="tan:greek-tens-regex" as="xs:string">[ι-πΙ-ΠϘϙϞϟ]</xsl:variable>
   <xsl:variable name="tan:greek-hundreds-regex" as="xs:string">[ρ-ωΡ-ΩϠϡ]</xsl:variable>
   <xsl:variable name="tan:greek-letter-numeral-regex" as="xs:string"
   select="'͵' || $tan:greek-unit-regex || '?(' || $tan:greek-hundreds-regex || '?' || $tan:greek-tens-regex || '?' || $tan:greek-unit-regex || '|' || $tan:greek-unit-regex || '?' || $tan:greek-hundreds-regex || '?' || 
   $tan:greek-tens-regex || $tan:greek-unit-regex || '?|' || $tan:greek-unit-regex || '?'|| $tan:greek-hundreds-regex || $tan:greek-tens-regex || '?' || $tan:greek-unit-regex || '?)ʹ?'"/>
   
   <xsl:variable name="tan:syriac-unit-regex" as="xs:string">[ܐܒܓܕܗܘܙܚܛ]</xsl:variable>
   <xsl:variable name="tan:syriac-tens-regex" as="xs:string">[ܝܟܠܡܢܣܥܦܨ]</xsl:variable>
   <xsl:variable name="tan:syriac-hundreds-regex" as="xs:string">ܬ?[ܩܪܫܬ]|[ܢܣܥܦܨ]</xsl:variable>
   <!-- A Syriac numeral is either 1s/10s/100s/1000s, with other corresponding digits, perhaps with modifier marks inserted between digits -->
   <xsl:variable name="tan:syriac-letter-numeral-pattern" as="xs:string"
      select="$tan:syriac-unit-regex || '?\p{Mc}?(' || $tan:syriac-hundreds-regex || '\p{Mc})?\p{Mc}?' || $tan:syriac-tens-regex || '?\p{Mc}?' || $tan:syriac-unit-regex || '\p{Mc}?|' || 
      $tan:syriac-unit-regex || '?\p{Mc}?(' || $tan:syriac-hundreds-regex || '\p{Mc})?\p{Mc}?' || $tan:syriac-tens-regex || '\p{Mc}?' || $tan:syriac-unit-regex || '?\p{Mc}?|' || 
      $tan:syriac-unit-regex || '?\p{Mc}?(' || $tan:syriac-hundreds-regex || '\p{Mc})\p{Mc}?' || $tan:syriac-tens-regex || '?\p{Mc}?' || $tan:syriac-unit-regex || '?\p{Mc}?'"
   />
   
   <xsl:variable name="tan:nonlatin-letter-numeral-regex" as="xs:string"
      select="string-join(($tan:arabic-indic-numeral-regex, $tan:greek-letter-numeral-regex, $tan:syriac-letter-numeral-pattern), '|')"/>
   
   
   <xsl:function name="tan:ara-to-int" as="xs:integer*" visibility="public">
      <!-- Input: Arabic-indic numerals -->
      <!-- Output: Integer values, if the input conforms to the correct pattern -->
      <!--kw: numerals, Arabic, numerics -->
      <xsl:param name="arabic-indic-numerals" as="xs:string*"/>
      <xsl:for-each
         select="$arabic-indic-numerals[matches(., '^' || $tan:arabic-indic-numeral-regex || '$')]">
         <xsl:copy-of select="xs:integer(translate(., '٠١٢٣٤٥٦٧٨٩', '0123456789'))"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:variable name="tan:alphabet-numeral-key" as="element()">
      <key>
         <convert grc="α" syr="ܐ" int="1"/>
         <convert grc="β" syr="ܒ" int="2"/>
         <convert grc="γ" syr="ܓ" int="3"/>
         <convert grc="δ" syr="ܕ" int="4"/>
         <convert grc="ε" syr="ܗ" int="5"/>
         <convert grc="ϛ" syr="ܘ" int="6"/>
         <convert grc="ζ" syr="ܙ" int="7"/>
         <convert grc="η" syr="ܚ" int="8"/>
         <convert grc="θ" syr="ܛ" int="9"/>
         <convert grc="ι" syr="ܝ" int="10"/>
         <convert grc="κ" syr="ܟ" int="20"/>
         <convert grc="λ" syr="ܠ" int="30"/>
         <convert grc="μ" syr="ܡ" int="40"/>
         <convert grc="ν" syr="ܢ" int="50"/>
         <convert grc="ξ" syr="ܣ" int="60"/>
         <convert grc="ο" syr="ܥ" int="70"/>
         <convert grc="π" syr="ܦ" int="80"/>
         <convert grc="ϙ" syr="ܨ" int="90"/>
         <convert grc="ρ" syr="ܩ" int="100"/>
         <convert grc="σ" syr="ܪ" int="200"/>
         <convert grc="τ" syr="ܫ" int="300"/>
         <convert grc="υ" syr="ܬ" int="400"/>
         <convert grc="φ" syr="" int="500"/>
         <convert grc="χ" syr="" int="600"/>
         <convert grc="ψ" syr="" int="700"/>
         <convert grc="ω" syr="" int="800"/>
         <convert grc="ϡ" syr="" int="900"/>
      </key>
   </xsl:variable>
   
   <xsl:function name="tan:letter-to-number" as="xs:integer*" visibility="public">
      <!-- Input: any sequence of strings that represent alphabetic numerals -->
      <!-- Output: those numerals as integers -->
      <!-- Works only for letter patterns that have been defined; anything else produces null results -->
      <!--kw: numerals, numerics -->
      <xsl:param name="numerical-letters" as="xs:anyAtomicType*"/>
      <xsl:for-each select="$numerical-letters">
         <xsl:choose>
            <xsl:when test="matches(., '^' || $tan:arabic-indic-numeral-regex || '$')">
               <xsl:copy-of select="tan:ara-to-int(.)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-letter-norm" select="replace(., '[͵ʹ]', '')"/>
               <xsl:variable name="pass1" as="xs:integer*">
                  <xsl:if test="string-length($this-letter-norm) gt 0">
                     <xsl:analyze-string select="$this-letter-norm" regex=".">
                        <xsl:matching-substring>
                           <xsl:variable name="this-letter" select="."/>
                           <xsl:choose>
                              <xsl:when test="matches(., '^\p{IsSyriac}+$')">
                                 <xsl:copy-of
                                    select="xs:integer(($tan:alphabet-numeral-key/*[matches(@syr, $this-letter, 'i')][1]/@int))"
                                 />
                              </xsl:when>
                              <xsl:when test="matches(., '^\p{IsGreek}+$')">
                                 <xsl:copy-of
                                    select="xs:integer(($tan:alphabet-numeral-key/*[matches(@grc, $this-letter, 'i')][1]/@int))"
                                 />
                              </xsl:when>
                           </xsl:choose>
                        </xsl:matching-substring>
                     </xsl:analyze-string>
                  </xsl:if>
               </xsl:variable>
               <xsl:sequence select="sum($pass1)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:grc-to-int" as="xs:integer*" visibility="public">
      <!-- Input: Greek letters that represent numerals -->
      <!-- Output: the numerical value of the letters -->
      <!-- NB, this does not take into account the use of letters representing numbers 1000 and greater -->
      <!--kw: numerals, numerics, Greek -->
      <xsl:param name="greek-numerals" as="xs:string*"/>
      <xsl:sequence select="tan:letter-to-number($greek-numerals)"/>
   </xsl:function>
   
   <xsl:function name="tan:syr-to-int" as="xs:integer*" visibility="public">
      <!-- Input: Syriac letters that represent numerals -->
      <!-- Output: the numerical value of the letters -->
      <!-- NB, this does not take into account the use of letters representing numbers 1000 and greater -->
      <!--kw: numerals, numerics, Syriac -->
      <xsl:param name="syriac-numerals" as="xs:string*"/>
      <xsl:for-each select="$syriac-numerals">
         <xsl:variable name="orig-numeral-seq" as="xs:string*">
            <xsl:analyze-string select="." regex=".">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <!-- The following removes redoubled numerals as often happens in Syriac, to indicate clearly that a character is a numeral not a letter. -->
         <xsl:variable name="duplicates-stripped"
            select="
            for $i in (1 to count($orig-numeral-seq))
            return
            if ($orig-numeral-seq[$i] = $orig-numeral-seq[$i + 1]) then
            ()
            else
            $orig-numeral-seq[$i]"/>
         <xsl:sequence select="tan:letter-to-number(string-join($duplicates-stripped, ''))"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:int-to-aaa" as="xs:string*" visibility="public">
      <!-- Input: any integers -->
      <!-- Output: the alphabetic representation of those numerals -->
      <!--kw: numerals, numerics -->
      <xsl:param name="integers" as="xs:integer*"/>
      <xsl:for-each select="$integers">
         <xsl:variable name="this-integer" select="."/>
         <xsl:variable name="this-letter-codepoint" select="(. mod 26) + 96"/>
         <xsl:variable name="this-number-of-letters" select="(. idiv 26) + 1"/>
         <xsl:variable name="these-codepoints"
            select="
            for $i in (1 to $this-number-of-letters)
            return
            $this-letter-codepoint"/>
         <xsl:value-of select="codepoints-to-string($these-codepoints)"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:int-to-grc" as="xs:string*" visibility="public">
      <!-- Input: any integers -->
      <!-- Output: the integers expressed as lowercase Greek alphabetic numerals, with numeral marker(s) -->
      <!--kw: numerals, numerics, Greek -->
      <xsl:param name="integers" as="xs:integer*"/>
      <xsl:variable name="arabic-numerals" select="'123456789'"/>
      <xsl:variable name="greek-units" select="'αβγδεϛζηθ'"/>
      <xsl:variable name="greek-tens" select="'ικλμνξοπϙ'"/>
      <xsl:variable name="greek-hundreds" select="'ρστυφχψωϡ'"/>
      <xsl:for-each select="$integers">
         <xsl:variable name="this-numeral" select="format-number(., '0')"/>
         <xsl:variable name="these-digits" select="tan:chop-string($this-numeral)"/>
         <xsl:variable name="new-digits-reversed" as="xs:string*">
            <xsl:for-each select="reverse($these-digits)">
               <xsl:variable name="pos" select="position()"/>
               <xsl:choose>
                  <xsl:when test=". = '0'"/>
                  <xsl:when test="$pos mod 3 = 1">
                     <xsl:value-of select="translate(., $arabic-numerals, $greek-units)"/>
                  </xsl:when>
                  <xsl:when test="$pos mod 3 = 2">
                     <xsl:value-of select="translate(., $arabic-numerals, $greek-tens)"/>
                  </xsl:when>
                  <xsl:when test="$pos mod 3 = 0">
                     <xsl:value-of select="translate(., $arabic-numerals, $greek-hundreds)"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="prepended-numeral-sign"
            select="
            if (count($these-digits) gt 3) then
            '͵'
            else
            ()"/>
         <xsl:if test="count($new-digits-reversed) gt 0">
            <xsl:value-of
               select="$prepended-numeral-sign || string-join(reverse($new-digits-reversed), '') || 'ʹ'"
            />
         </xsl:if>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:int-to-syr" as="xs:string*" visibility="public">
      <!-- Input: any integers -->
      <!-- Output: the integers expressed as Syriac alphabetic numerals -->
      <!--kw: numerals, numerics, Syriac -->
      <xsl:param name="integers" as="xs:integer*"/>
      <xsl:variable name="arabic-numerals" select="'123456789'"/>
      <xsl:variable name="syriac-units" select="'ܐܒܓܕܗܘܙܚܛ'"/>
      <xsl:variable name="syriac-tens" select="'ܝܟܠܡܢܣܥܦܨ'"/>
      <xsl:variable name="syriac-hundreds" select="'ܩܪܫܬܢܣܥܦܨ'"/>
      <xsl:for-each select="$integers">
         <xsl:variable name="this-numeral" select="format-number(., '0')"/>
         <xsl:variable name="these-digits" select="tan:chop-string($this-numeral)"/>
         <xsl:variable name="new-digits-reversed" as="xs:string*">
            <xsl:for-each select="reverse($these-digits)">
               <xsl:variable name="pos" select="position()"/>
               <xsl:choose>
                  <xsl:when test=". = '0'"/>
                  <xsl:when test="$pos mod 3 = 1">
                     <xsl:value-of select="translate(., $arabic-numerals, $syriac-units)"/>
                  </xsl:when>
                  <xsl:when test="$pos mod 3 = 2">
                     <xsl:value-of select="translate(., $arabic-numerals, $syriac-tens)"/>
                  </xsl:when>
                  <xsl:when test="$pos mod 3 = 0">
                     
                     <xsl:variable name="hundred" as="xs:string"
                        select="translate(., $arabic-numerals, $syriac-hundreds)"/>
                     <xsl:value-of select="replace($hundred, '([ܢܣܥܦܨ])', '$1&#x73f;')"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:for-each>
         </xsl:variable>
         <xsl:if test="count($new-digits-reversed) gt 0">
            <xsl:value-of select="string-join(reverse($new-digits-reversed), '')"/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:integers-to-expression" as="xs:string?" visibility="public">
      <!-- Input: any integers -->
      <!-- Output: a string that compactly expresses those integers, sorted -->
      <!-- Example: (1, 3, 6, 1, 2) - > "1-3, 6" -->
      <!--kw: numerals, numerics, sequences -->
      <xsl:param name="input-integers" as="xs:integer*"/>
      <xsl:variable name="input-sorted" as="element()">
         <sorted>
            <xsl:for-each select="distinct-values($input-integers)">
               <xsl:sort/>
               <n>
                  <xsl:value-of select="."/>
               </n>
            </xsl:for-each>
         </sorted>
      </xsl:variable>
      <xsl:variable name="input-analyzed" as="element()">
         <xsl:apply-templates select="$input-sorted" mode="tan:integers-to-expression"/>
      </xsl:variable>
      <xsl:variable name="output-atoms" as="xs:string*">
         <xsl:for-each-group select="$input-analyzed/*" group-starting-with="*[@start]">
            <xsl:variable name="last-item" select="current-group()[not(@start)][last()]"/>
            <xsl:choose>
               <xsl:when test="exists($last-item)">
                  <xsl:value-of select="current-group()[1] || '-' || $last-item"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="current-group()[1]"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:variable>
      <!--<xsl:message select="$input-analyzed"/>-->
      <!--<xsl:value-of select="$input-sorted"/>-->
      <!--<xsl:value-of select="$input-analyzed"/>-->
      <!--<xsl:value-of select="$output-atoms"/>-->
      <xsl:value-of select="string-join($output-atoms, ', ')"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:integers-to-expression" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:n" mode="tan:integers-to-expression">
      <xsl:variable name="preceding-n" select="preceding-sibling::tan:n[1]"/>
      <xsl:variable name="this-n-val" select="xs:integer(.)"/>
      <xsl:variable name="preceding-n-val" select="xs:integer($preceding-n)"/>
      <xsl:copy>
         <xsl:choose>
            <xsl:when test="not(exists($preceding-n-val))">
               <xsl:attribute name="start"/>
            </xsl:when>
            <xsl:when test="$this-n-val - $preceding-n-val gt 1">
               <xsl:attribute name="start"/>
            </xsl:when>
         </xsl:choose>
         <xsl:value-of select="."/>
      </xsl:copy>
   </xsl:template>
   
   
   
   
   

</xsl:stylesheet>
