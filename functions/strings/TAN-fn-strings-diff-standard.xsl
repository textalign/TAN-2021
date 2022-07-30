<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library diff string functions. -->
   
   <xsl:function name="tan:vertical-stops" as="xs:double*" visibility="private">
      <!-- Input: a string -->
      <!-- Output: percentages of the string that should be followed in tan:diff-outer-loop() -->
      <xsl:param name="short-string" as="xs:string?"/>
      <xsl:variable name="short-string-length" select="string-length($short-string)"/>
      <xsl:choose>
         <xsl:when test="$short-string-length eq 0"/>
         <xsl:when test="$short-string-length lt 7">
            <xsl:sequence select="
                  for $i in (1 to $short-string-length)
                  return
                     (1 div $i)"/>
         </xsl:when>
         <xsl:when test="$short-string-length le 20">
            <xsl:sequence select="(1, 0.8, 0.6, 0.4, 0.3, 0.2, 0.1, 0.05)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$tan:diff-vertical-stops"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>


   <xsl:function name="tan:diff" as="element()" visibility="public">
      <!-- 2-param version of fuller one below -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:sequence select="tan:diff($string-a, $string-b, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:diff" as="element()" visibility="public">
      <!-- 3-param version of fuller one below -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:param name="snap-to-word" as="xs:boolean"/>
      <xsl:sequence select="tan:diff($string-a, $string-b, $snap-to-word, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:diff-cache" as="element()" _cache="{$tan:advanced-processing-available}" visibility="public">
      <!-- 4-param version of fuller one below
         This is a shadow function for tan:diff(). It uses XSLT 3.0 @cache, so that tan:collate() can avoid repeating 
         diffs. Works only if the processor supports advanced features (e.g., Saxon PE, EE, not HE) -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:param name="snap-to-word" as="xs:boolean"/>
      <xsl:param name="preprocess-long-strings" as="xs:boolean"/>
      <xsl:sequence select="tan:diff($string-a, $string-b, $snap-to-word, $preprocess-long-strings)"
      />
   </xsl:function>
   
   <xsl:function name="tan:diff" as="element()" visibility="public">
      <!-- Input: any two strings; boolean indicating whether results should snap to nearest word; boolean 
            indicating whether long strings should be pre-processed -->
      <!-- Output: an element with <a>, <b>, and <common> children showing where strings a and b match 
            and depart -->
      <!-- This function was written to assist the validation of <redivision>s quickly find differences 
            between any two strings. The function has been tested on pairs of strings up to combined lengths of 
            9M characters. At that scale, the only way to efficiently process the diffs is by chaining smaller 
            diffs, which are still large, optimally about 350K in length. -->
      <!--  This function prepares strings for 5-arity tan:diff-engine(), primarily by tending to input strings
         that are large or really large (giant). Large pairs of strings are parsed to find common characters
         that might be used to find pairwise congruence of large segments. Giant pairs of strings are passed 
         to tan:giant-diff(). -->
      <!-- kw: strings, diff -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:param name="snap-to-word" as="xs:boolean"/>
      <xsl:param name="preprocess-long-strings" as="xs:boolean"/>
      <xsl:variable name="str-a-len" select="string-length($string-a)"/>
      <xsl:variable name="str-b-len" select="string-length($string-b)"/>
      <xsl:variable name="smallest-string-length" select="min(($str-a-len, $str-b-len))"/>
      <xsl:variable name="diff-must-be-chained"
         select="$smallest-string-length gt $tan:diff-preprocess-via-segmentation-trigger-point"/>
      <xsl:choose>
         <xsl:when test="$diff-must-be-chained">
            <xsl:variable name="str-a-seg-len" as="xs:decimal"
               select="ceiling($str-a-len div $tan:diff-min-count-giant-string-segments)"/>
            <xsl:variable name="str-b-seg-len" as="xs:decimal"
               select="ceiling($str-b-len div $tan:diff-min-count-giant-string-segments)"/>
            <xsl:variable name="max-str-seg-len" select="max(($str-a-seg-len, $str-b-seg-len))"/>
            <xsl:variable name="adjustment-ratio" select="
                  if ($max-str-seg-len gt $tan:diff-max-size-of-giant-string-segments) then
                     ($tan:diff-max-size-of-giant-string-segments div $max-str-seg-len)
                  else
                     1"/>

            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Diagnostics on, tan:diff(), giant string branch'"/>
               <xsl:message select="'String a (length ' || string($str-a-len) || '): ' || tan:ellipses($string-a, 40)"/>
               <xsl:message select="'String b (length ' || string($str-b-len) || '): ' || tan:ellipses($string-b, 40)"/>
               <xsl:message select="'String a segment length:', $str-a-seg-len"/>
               <xsl:message select="'String b segment length:', $str-b-seg-len"/>
               <xsl:message select="'Adjustment ratio:', $adjustment-ratio"/>
               <xsl:message select="'String a segment length adjusted:', xs:integer($str-a-seg-len * $adjustment-ratio)"/>
               <xsl:message select="'String b segment length adjusted:', xs:integer($str-b-seg-len * $adjustment-ratio)"/>
            </xsl:if>

            <xsl:copy-of
               select="tan:giant-diff($string-a, $string-b, $snap-to-word, xs:integer($str-a-seg-len * $adjustment-ratio), xs:integer($str-b-seg-len * $adjustment-ratio))"
            />
         </xsl:when>
         <xsl:when test="
               ($preprocess-long-strings = false()) or
               (($str-a-len lt $tan:diff-preprocess-via-tokenization-trigger-point) or ($str-b-len lt $tan:diff-preprocess-via-tokenization-trigger-point))">
            <xsl:sequence select="tan:diff-courtyard($string-a, $string-b, $snap-to-word, (), (), 0)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="str-a-char-count-map" as="map(*)">
               <xsl:map>
                  <xsl:for-each-group select="string-to-codepoints($string-a)" group-by=".">
                     <xsl:map-entry key="current-grouping-key()" select="count(current-group())"/>
                  </xsl:for-each-group> 
               </xsl:map>
            </xsl:variable>
            <xsl:variable name="str-a-char-count-map-keys" as="xs:integer*" select="map:keys($str-a-char-count-map)"/>
            <xsl:variable name="str-b-char-count-map" as="map(*)">
               <xsl:map>
                  <xsl:for-each-group select="string-to-codepoints($string-b)" group-by=".">
                     <xsl:map-entry key="current-grouping-key()" select="count(current-group())"/>
                  </xsl:for-each-group> 
               </xsl:map>
            </xsl:variable>
            <xsl:variable name="str-b-char-count-map-keys" as="xs:integer*" select="map:keys($str-b-char-count-map)"/>
            
            <xsl:variable name="str-a-b-keys-sorted" as="xs:integer*">

               <xsl:for-each-group select="$str-a-char-count-map-keys, $str-b-char-count-map-keys"
                  group-by=".">
                  <xsl:sort select="$str-a-char-count-map(current-grouping-key()) + $str-b-char-count-map(current-grouping-key())"/>
                  <xsl:choose>
                     <xsl:when test="count(current-group()) eq 1">
                        <xsl:sequence select="current-grouping-key() * -1"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="current-grouping-key()"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each-group>

            </xsl:variable>
            
            <xsl:variable name="first-tokenizer-cps" as="xs:integer*" select="for $i in $str-a-b-keys-sorted[. lt 0] return ($i * -1)"/>
            <xsl:variable name="next-tokenizer-cps" as="xs:integer*" select="$str-a-b-keys-sorted[. gt 0]"/>
            
            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'first cps:', $first-tokenizer-cps"/>
               <xsl:message select="'next cps:', $next-tokenizer-cps"/>
            </xsl:if>
            
            <xsl:sequence
               select="tan:diff-courtyard($string-a, $string-b, $snap-to-word, $first-tokenizer-cps, $next-tokenizer-cps, 0)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <!-- Break up enormous strings first -->
   <xsl:function name="tan:giant-diff" as="element()" visibility="private">
      <!-- Input: same parameters as 3-ary tan:diff(), plus two integers -->
      <!-- Output: the same as tan:diff(), but handled differently; the two integers specify the segment lengths into which the first and second strings, respectively, should be cut. -->
      <!-- This function is written under the assumption that the major halves, thirds, whatever of each string correspond to the other. -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:param name="snap-to-word" as="xs:boolean"/>
      <xsl:param name="string-a-segment-length" as="xs:integer"/>
      <xsl:param name="string-b-segment-length" as="xs:integer"/>

      <xsl:variable name="str-a-len" select="string-length($string-a)"/>
      <xsl:variable name="str-b-len" select="string-length($string-b)"/>
      <xsl:choose>
         <xsl:when
            test="$str-a-len lt $string-a-segment-length or $str-b-len lt $string-b-segment-length">
            <xsl:sequence select="tan:diff($string-a, $string-b, $snap-to-word)"/>
         </xsl:when>
         <xsl:otherwise>
            <!-- Set 1% of the average segment length for re-patching. -->
            <xsl:variable name="max-length-to-patch" as="xs:integer"
               select="xs:integer((($string-a-segment-length + $string-b-segment-length) div 2) * 0.01)"
            />
            <xsl:variable name="min-len" select="min(($str-a-len, $str-b-len))"/>
            <!-- What constitutes a <common> of significant size? -->
            <xsl:variable name="significant-common-size" select="min((($min-len idiv 1000), 200))"
               as="xs:integer"/>
            <xsl:variable name="diff-count"
               select="xs:integer(max((ceiling($str-a-len div $string-a-segment-length), ceiling($str-b-len div $string-b-segment-length))))"/>
            <xsl:variable name="diff-chain" as="element()">
               <diff>
                  <xsl:iterate select="1 to $diff-count">
                     <xsl:param name="str-a-fragment" as="xs:string?"/>
                     <xsl:param name="str-b-fragment" as="xs:string?"/>
                     
                     <xsl:on-completion
                        select="tan:diff($str-a-fragment, $str-b-fragment, $snap-to-word)/*"/>
                     
                     <xsl:variable name="this-a-start"
                        select="(. - 1) * $string-a-segment-length + 1"/>
                     <xsl:variable name="this-b-start"
                        select="(. - 1) * $string-b-segment-length + 1"/>
                     <xsl:variable name="str-a-part"
                        select="substring($string-a, $this-a-start, $string-a-segment-length)"/>
                     <xsl:variable name="str-b-part"
                        select="substring($string-b, $this-b-start, $string-b-segment-length)"/>
                     <xsl:variable name="this-diff" as="element()"
                        select="tan:diff($str-a-fragment || $str-a-part, $str-b-fragment || $str-b-part, $snap-to-word)"/>
                     
                     <xsl:variable name="patch-how-much-tail" as="xs:integer">
                        <xsl:iterate select="reverse($this-diff/*)">
                           <xsl:param name="amount-so-far" as="xs:integer" select="0"/>
                           <xsl:variable name="this-length" as="xs:integer" select="string-length(.)"/>
                           <xsl:variable name="new-amount" as="xs:integer" select="$amount-so-far + $this-length"/>
                           
                           <xsl:choose>
                              <xsl:when test="self::common and 
                                 (($new-amount gt $max-length-to-patch) or ($this-length gt $significant-common-size))">
                                 <xsl:sequence select="$amount-so-far"/>
                                 <xsl:break/>
                              </xsl:when>
                              <xsl:when test="$new-amount gt $max-length-to-patch">
                                 <xsl:sequence select="$max-length-to-patch"/>
                                 <xsl:break/>
                              </xsl:when>
                              <xsl:otherwise>
                                 <xsl:next-iteration>
                                    <xsl:with-param name="amount-so-far" select="$new-amount"/>
                                 </xsl:next-iteration>
                              </xsl:otherwise>
                           </xsl:choose>
                           
                        </xsl:iterate>
                     </xsl:variable>
                     <xsl:variable name="split-tree-at" as="xs:integer?" select="
                           if ($patch-how-much-tail gt 1) then
                              (string-length($this-diff) - $patch-how-much-tail + 1)
                           else
                              ()"/>
                     <xsl:variable name="diff-split" as="map(*)" select="tan:chop-tree($this-diff, $split-tree-at)"/>
                     
                     <xsl:variable name="inner-diagnostics-on" select="false()"/>
                     <xsl:if test="$inner-diagnostics-on">
                        <xsl:message select="'Iteration ' || string(.) || ' of ' || string($diff-count)"/>
                        <xsl:message select="'String a fragment (' || string(string-length($str-a-fragment)) || '): ' || tan:ellipses($str-a-fragment, 20)"/>
                        <xsl:message select="'String b fragment (' || string(string-length($str-b-fragment)) || '): ' || tan:ellipses($str-b-fragment, 20)"/>
                        <xsl:message select="'String a part (' || string(string-length($str-a-part)) || '): ' || tan:ellipses($str-a-part, 20)"/>
                        <xsl:message select="'String b part (' || string(string-length($str-b-part)) || '): ' || tan:ellipses($str-b-part, 20)"/>
                        <xsl:message select="'A, B starts:', $this-a-start, $this-b-start"/>
                        <xsl:message select="'A, B lengths:', $string-a-segment-length, $string-b-segment-length"/>
                        <xsl:message select="'Patch how much tail:', $patch-how-much-tail"/>
                     </xsl:if>
                     
                     <xsl:copy-of select="$diff-split(1)/*"/>
                     
                     <xsl:next-iteration>
                        <xsl:with-param name="str-a-fragment" select="string-join($diff-split($split-tree-at)/(tan:a | tan:common))"/>
                        <xsl:with-param name="str-b-fragment" select="string-join($diff-split($split-tree-at)/(tan:b | tan:common))"/>
                     </xsl:next-iteration>
                     
                  </xsl:iterate>
               </diff>
            </xsl:variable>
            
            

            <xsl:variable name="diagnostics-on" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:variable name="str-a-result" as="xs:string" select="string-join($diff-chain/(tan:a | tan:common))"/>
               <xsl:variable name="str-b-result" as="xs:string" select="string-join($diff-chain/(tan:b | tan:common))"/>
               <xsl:message select="'Diagnostics on, tan:giant-diff()'"/>
               <xsl:message select="'String a (length ' || string($str-a-len) || '): ' || tan:ellipses($string-a, 40)"/>
               <xsl:message select="'String b (length ' || string($str-b-len) || '): ' || tan:ellipses($string-b, 40)"/>
               <xsl:message select="'Number of diffs to process:', $diff-count"/>
               <xsl:message select="'String a output (length ' || string(string-length($str-a-result)) || '): ' || tan:ellipses($str-a-result, 40)"/>
               <xsl:message select="'String b output (length ' || string(string-length($str-b-result)) || '): ' || tan:ellipses($str-b-result, 40)"/>
               <xsl:message select="'String a preserved: ', $str-a-result eq $string-a"/>
               <xsl:message select="'String b preserved: ', $str-b-result eq $string-b"/>
            </xsl:if>
            
            <!--<xsl:sequence select="tan:adjust-diff($diff-chain)"/>-->
            <xsl:sequence select="tan:concat-and-sort-diff-output($diff-chain)"/>
            
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:diff-courtyard" as="element()" visibility="private">
      <!-- The diff process begins here, with any tokenizing preprocessor instructions in hand,
         and returning any normalized output as requested. The main diff engine is yet to come. -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:param name="snap-to-word" as="xs:boolean"/>
      <xsl:param name="current-tokenizer-cps" as="xs:integer*"/>
      <xsl:param name="next-tokenizer-cps" as="xs:integer*"/>
      <xsl:param name="loop-counter" as="xs:integer"/>

      <xsl:variable name="str-a-len" select="string-length($string-a)"/>
      <xsl:variable name="str-b-len" select="string-length($string-b)"/>
      <xsl:variable name="strings-prepped" as="element()+">
         <xsl:choose>
            <xsl:when test="$str-a-len lt $str-b-len">
               <a>
                  <xsl:value-of select="$string-a"/>
               </a>
               <b>
                  <xsl:value-of select="$string-b"/>
               </b>
            </xsl:when>
            <xsl:otherwise>
               <b>
                  <xsl:value-of select="$string-b"/>
               </b>
               <a>
                  <xsl:value-of select="$string-a"/>
               </a>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="some-string-is-zero-length"
         select="($str-a-len lt 1) or ($str-b-len lt 1)"/>
      <xsl:variable name="does-not-need-preprocessing" as="xs:boolean" select="
            not(exists($next-tokenizer-cps)) or
            (min(($str-a-len, $str-b-len)) lt $tan:diff-preprocess-via-tokenization-trigger-point)"/>

      <xsl:variable name="next-tokenizer-regex-parts" as="xs:string*">
         <xsl:for-each select="$current-tokenizer-cps, head($next-tokenizer-cps)">
            <!-- put hyphens at the end -->
            <xsl:sort select="
                  if (. eq 45) then
                     2
                  else
                     1"/>
            <xsl:sequence select="tan:escape(codepoints-to-string(.))"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="next-tokenizer-regex" as="xs:string?"
         select="'[' || string-join($next-tokenizer-regex-parts) || ']+'"/>
      
      <xsl:variable name="strings-diffed" as="element()*">
         <xsl:choose>
            <xsl:when test="$loop-counter ge $tan:loop-tolerance">
               <xsl:message
                  select="'Diff function cannot be repeated more than ' || xs:string($tan:loop-tolerance) || ' times'"/>
               <xsl:sequence select="$strings-prepped/self::a, $strings-prepped/self::b"/>
            </xsl:when>
            <xsl:when test="$some-string-is-zero-length">
               <xsl:sequence select="$strings-prepped[text()]"/>
            </xsl:when>
            <xsl:when test="$does-not-need-preprocessing">
               <xsl:variable name="pass-1" as="element()*">
                  <!--<xsl:copy-of
                     select="tan:diff-loop($strings-prepped[1], $strings-prepped[2], true(), false(), $tan:diff-vertical-stops, 0)"
                  />-->
                  <xsl:sequence
                     select="tan:diff-loop($string-a, $string-b, $tan:diff-vertical-stops, 0)"
                  />
               </xsl:variable>
               
               <xsl:variable name="diagnostics-on" select="false()"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:variable name="a-reconstructed" select="string-join($pass-1[not(self::tan:b)])" as="xs:string"/>
                  <xsl:variable name="b-reconstructed" select="string-join($pass-1[not(self::tan:a)])" as="xs:string"/>
                  <xsl:message
                     select="'diagnostics on, tan:diff(), branch where preprocessing is not needed.'"/>
                  <xsl:message select="'String a length: ' || string($str-a-len) || ' (' || tan:ellipses($string-a, 20) ||
                     '); string b length: ' || string($str-b-len) || ' (' || tan:ellipses($string-b, 20) || ')'"/>
                  <xsl:if test="not($string-a eq $a-reconstructed)">
                     <xsl:message select="'String a not intact. Output (' || string-length($a-reconstructed) || '): ' || $a-reconstructed"/>
                  </xsl:if>
                  <xsl:if test="not($string-b eq $b-reconstructed)">
                     <xsl:message select="'String b not intact. Output (' || string-length($b-reconstructed) || '): ' || $b-reconstructed"/>
                  </xsl:if>
                  <xsl:message select="'Pass 1:',  $pass-1"/>
               </xsl:if>

               <xsl:for-each-group select="$pass-1[text()]" group-adjacent="name() = 'common'">
                  <xsl:choose>
                     <xsl:when test="current-grouping-key()">
                        <xsl:copy-of select="current-group()"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <!-- Consolidate adjacent <a> and <b> texts, with the former before the latter. -->
                        <xsl:for-each-group select="current-group()" group-by="name()">
                           <xsl:sort select="current-grouping-key()"/>
                           <xsl:element name="{current-grouping-key()}">
                              <xsl:value-of select="string-join(current-group())"/>
                           </xsl:element>
                        </xsl:for-each-group>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
               <!-- Pre-process long strings by first analyzing co-occurrence of unique words -->
               <!-- Build a variable with two elements, one for each input string, containing <tok> and <non-tok> -->

               <xsl:variable name="input-a-analyzed" as="element()">
                  <a-analyzed>
                     <xsl:try>
                        <xsl:analyze-string select="$string-a" regex="{$next-tokenizer-regex}">
                           <xsl:matching-substring>
                              <no>
                                 <xsl:value-of select="."/>
                              </no>
                           </xsl:matching-substring>
                           <xsl:non-matching-substring>
                              <try>
                                 <xsl:value-of select="."/>
                              </try>
                           </xsl:non-matching-substring>
                        </xsl:analyze-string>
                        <xsl:catch>
                           <xsl:message select="'Faulty regex: ' || $next-tokenizer-regex"/>
                           <no>
                              <xsl:value-of select="$string-a"/>
                           </no>
                        </xsl:catch>
                     </xsl:try>
                  </a-analyzed>
               </xsl:variable>
               
               <xsl:variable name="input-b-analyzed" as="element()">
                  <b-analyzed>
                     <xsl:try>
                        <xsl:analyze-string select="$string-b" regex="{$next-tokenizer-regex}">
                           <xsl:matching-substring>
                              <no>
                                 <xsl:value-of select="."/>
                              </no>
                           </xsl:matching-substring>
                           <xsl:non-matching-substring>
                              <try>
                                 <xsl:value-of select="."/>
                              </try>
                           </xsl:non-matching-substring>
                        </xsl:analyze-string>
                        <xsl:catch>
                           <xsl:message select="'Faulty regex: ' || $next-tokenizer-regex"/>
                           <no>
                              <xsl:value-of select="$string-b"/>
                           </no>
                        </xsl:catch>
                     </xsl:try>
                  </b-analyzed>
               </xsl:variable>
               
               <xsl:variable name="overlapping-tokens" as="xs:string*" select="
                     if (count($input-a-analyzed/tan:try) ge count($input-b-analyzed/tan:try))
                     then
                        $input-b-analyzed/tan:try[. = $input-a-analyzed/tan:try]
                     else
                        $input-a-analyzed/tan:try[. = $input-b-analyzed/tan:try]"/>

               <!-- Reduce each of the two elements to a set of tokens unique to that string -->

               <xsl:variable name="input-a-unique-words" as="xs:string*">
                  <xsl:for-each-group select="$input-a-analyzed/tan:try[. = $overlapping-tokens]" group-by=".">
                     <xsl:if test="count(current-group()) eq 1 and tan:contains-only-once($string-a, current-grouping-key())">
                        <xsl:sequence select="current-group()"/>
                     </xsl:if>
                  </xsl:for-each-group>
               </xsl:variable>
               <xsl:variable name="input-b-unique-words" as="xs:string*">
                  <xsl:for-each-group select="$input-b-analyzed/tan:try[. = $overlapping-tokens]" group-by=".">
                     <xsl:if test="count(current-group()) eq 1 and tan:contains-only-once($string-b, current-grouping-key())">
                        <xsl:sequence select="current-group()"/>
                     </xsl:if>
                  </xsl:for-each-group>
               </xsl:variable>

               <xsl:variable name="input-core-sequence" as="element()*"
                  select="tan:collate-pair-of-sequences($input-a-unique-words, $input-b-unique-words)"
               />


               <xsl:variable name="input-core-shared-unique-words-in-same-order"
                  select="$input-core-sequence/tan:common[not(. eq $next-tokenizer-regex)]"/>

               <xsl:variable name="this-unique-sequence-count" as="xs:integer"
                  select="count($input-core-shared-unique-words-in-same-order)"/>
               
               <xsl:variable name="input-analyzed-2" as="element()+">
                  <a>
                     <xsl:for-each-group select="$input-a-analyzed/*"
                        group-ending-with=".[. = $input-core-shared-unique-words-in-same-order]">
                        <xsl:variable name="last-is-not-common"
                           select="position() gt $this-unique-sequence-count"/>
                        <group n="{position()}" input="1">
                           <xsl:choose>
                              <xsl:when test="$last-is-not-common">
                                 <distinct input="1">
                                    <xsl:value-of select="string-join(current-group())"/>
                                 </distinct>
                              </xsl:when>
                              <xsl:otherwise>
                                 <distinct input="1">
                                    <xsl:value-of
                                       select="string-join(current-group()[not(position() eq last())])"
                                    />
                                 </distinct>
                                 <common>
                                    <xsl:value-of select="current-group()[last()]"/>
                                 </common>
                              </xsl:otherwise>

                           </xsl:choose>
                        </group>
                     </xsl:for-each-group>
                  </a>
                  <b>
                     <xsl:for-each-group select="$input-b-analyzed/*"
                        group-ending-with=".[. = $input-core-shared-unique-words-in-same-order]">
                        <xsl:variable name="last-is-not-common"
                           select="position() gt $this-unique-sequence-count"/>
                        <group n="{position()}" input="2">
                           <xsl:choose>
                              <xsl:when test="$last-is-not-common">
                                 <distinct input="2">
                                    <xsl:value-of select="string-join(current-group())"/>
                                 </distinct>
                              </xsl:when>
                              <xsl:otherwise>
                                 <distinct input="1">
                                    <xsl:value-of
                                       select="string-join(current-group()[not(position() eq last())])"
                                    />
                                 </distinct>
                                 <common>
                                    <xsl:value-of select="current-group()[last()]"/>
                                 </common>
                              </xsl:otherwise>

                           </xsl:choose>
                        </group>
                     </xsl:for-each-group>
                  </b>

               </xsl:variable>

               <!-- If something goes awry, it can be very helpful to trace a particular phrase as it gets handled. By entering
                    something in the following variable, the message on $input-analyzed will signify via an asterisk into which fork the  
                    phrase is being placed. -->
               <xsl:variable name="diagnostics-regex" as="xs:string"
                  select="'Replace this string with a regular expression, to trace it in strings a and b'"/>
               <xsl:variable name="diagnostics-on" select="false()"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'diagnostics on, tan:diff(), branch to preprocess long strings.'"/>
                  <xsl:message select="'String a (length ' || string($str-a-len) || '): ' || tan:ellipses($string-a, 40)"/>
                  <xsl:message select="'String b (length ' || string($str-b-len) || '): ' || tan:ellipses($string-b, 40)"/>
                  <xsl:message select="'next (current) tokenization string (', string-to-codepoints($next-tokenizer-regex), '): ', $next-tokenizer-regex"/>
                  <xsl:message select="'current tokenizer cps: ', $current-tokenizer-cps"/>
                  <xsl:message select="'next tokenizer cps (' || string(count($next-tokenizer-cps)) || '):', $next-tokenizer-cps"/>
                  <xsl:message select="'tokenizer regex: ' || $next-tokenizer-regex"/>
                  <xsl:message select="'input A analyzed/tokenized (', count($input-a-analyzed/*), ') first three:', tan:ellipses($input-a-analyzed/*[position() lt 4], 10)"/>
                  <xsl:message select="'input B analyzed/tokenized (', count($input-b-analyzed/*), ') first three:', tan:ellipses($input-b-analyzed/*[position() lt 4], 10)"/>
                  <xsl:message select="'overlapping tokens (' || string(count($overlapping-tokens)) || ') first three: ', tan:ellipses($overlapping-tokens[position() lt 4], 10)"/>
                  <xsl:message select="'input A unique words (', count($input-a-unique-words), '): ', tan:ellipses($input-a-unique-words, 10)"/>
                  <xsl:message select="'input B unique words (', count($input-b-unique-words), '): ', tan:ellipses($input-b-unique-words, 10)"/>
                  <xsl:message select="'input core sequence (', count($input-core-sequence/*), '): ', serialize(tan:trim-long-text($input-core-sequence, 10))"/>
                  <xsl:message select="
                        'Input core shared unique words in same order (', count($input-core-shared-unique-words-in-same-order), '): ',
                        string-join(for $i in $input-core-shared-unique-words-in-same-order
                        return
                           (tan:ellipses($i, 10), ('(length ' || string(string-length($i)), ') ')), ' ')"/>
                  <xsl:message select="
                        'Input analyzed (lengths',
                        for $i in $input-analyzed-2
                        return
                           (' ' || name($i) || ': ' || string-join(for $j in $i//text(),
                              $k in matches($j, $diagnostics-regex)
                           return
                              (string(string-length($j)) || (if ($k) then
                                 '*'
                              else
                                 ())), ', ')) || '): ' || serialize(tan:trim-long-text($input-analyzed-2, 10))"
                  />
               </xsl:if>

               <xsl:for-each-group select="$input-analyzed-2/tan:group" group-by="@n">
                  <xsl:copy-of select="
                        tan:diff-courtyard(current-group()[@input = '1']/tan:distinct, current-group()[@input = '2']/tan:distinct,
                        $snap-to-word, ($current-tokenizer-cps, head($next-tokenizer-cps)), tail($next-tokenizer-cps), $loop-counter + 1)/*"/>
                  <xsl:copy-of select="current-group()[1]/tan:common"/>
               </xsl:for-each-group>

            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="results-cleaned" as="element()">
         <diff>
            <xsl:for-each-group select="$strings-diffed" group-adjacent="name()">
               <xsl:element name="{current-grouping-key()}">
                  <xsl:value-of select="string-join(current-group())"/>
               </xsl:element>
            </xsl:for-each-group>
         </diff>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:diff()'"/>
         <xsl:message select="'loop number: ', string($loop-counter)"/>
         <xsl:message
            select="'string a (length ', string-length($string-a), '): ', tan:trim-long-text($string-a, 40)"/>
         <xsl:message
            select="'string b (length ', string-length($string-b), '): ', tan:trim-long-text($string-b, 40)"/>
         <xsl:message select="'some string is zero length?: ', $some-string-is-zero-length"/>
         <xsl:message select="'needs preprocessing?: ', not($does-not-need-preprocessing)"/>
         <xsl:message select="'snap to word: ', string($snap-to-word)"/>
         <!--<xsl:message
            select="'characters to tokenize on: ', string-join($characters-to-tokenize-on, ' ')"/>-->
         <xsl:message select="'strings diffed: ', $strings-diffed"/>
         <xsl:message select="'results cleaned', $results-cleaned"/>
      </xsl:if>
      <!-- Special routine to check integrity of output -->
      <xsl:if test="false()">
         <xsl:variable name="a-reconstructed" select="string-join($results-cleaned/(tan:a | tan:common))" as="xs:string"/>
         <xsl:variable name="b-reconstructed" select="string-join($results-cleaned/(tan:b | tan:common))" as="xs:string"/>
         <xsl:if test="$does-not-need-preprocessing and not($string-a eq $a-reconstructed) and not($string-b eq $b-reconstructed)">
            <xsl:message select="'a in: ' || $string-a"/>
            <xsl:message select="'a out: ' || $a-reconstructed"/>
            <xsl:message select="'b in: ' || $string-b"/>
            <xsl:message select="'b out: ' || $b-reconstructed"/>
         </xsl:if>
         <xsl:if test="not($string-a eq $a-reconstructed)">
            <xsl:message select="'loop number: ', string($loop-counter)"/>
            <xsl:message select="'needs preprocessing?: ', not($does-not-need-preprocessing)"/>
            <xsl:message select="'String a input (' || string($str-a-len) || '): ' || tan:ellipses($string-a, 60)"/>
            <xsl:message select="'String a output not intact. Output (' || string(string-length($a-reconstructed)) || '): ' || tan:ellipses($a-reconstructed, 60)"/>
            <xsl:iterate select="1 to $str-a-len">
               <xsl:variable name="this-pos" select="."/>
               <xsl:choose>
                  <xsl:when test="not(substring($string-a, $this-pos, 1) eq substring($a-reconstructed, $this-pos, 1))">
                     <xsl:message select="
                        'First problem at ' || string($this-pos) || ', codepoint ' || string(string-to-codepoints(substring($string-a, $this-pos, 1))) 
                        || ' versus ' || string(string-to-codepoints(substring($a-reconstructed, $this-pos, 1))) || '. Input A: ' ||
                           substring($string-a, $this-pos - 5, 5) || '‸' || substring($string-a, $this-pos, 20) || '; output A: ' || 
                           substring($a-reconstructed, $this-pos - 5, 5) || '‸' || substring($a-reconstructed, $this-pos, 20)"
                     />
                     <xsl:break/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:next-iteration/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:iterate>
         </xsl:if>
         <xsl:if test="not($string-b eq $b-reconstructed)">
            <xsl:message select="'loop number: ', string($loop-counter)"/>
            <xsl:message select="'needs preprocessing?: ', not($does-not-need-preprocessing)"/>

            <xsl:message select="'String b input (' || string($str-b-len) || '): ' || tan:ellipses($string-b, 60)"/>
            <xsl:message select="'String b output not intact. Output (' || string(string-length($b-reconstructed)) || '): ' || tan:ellipses($b-reconstructed, 60)"/>
            <xsl:iterate select="1 to $str-b-len">
               <xsl:variable name="this-pos" select="."/>
               <xsl:choose>
                  <xsl:when test="not(substring($string-b, $this-pos, 1) eq substring($b-reconstructed, $this-pos, 1))">
                     <xsl:message select="
                        'First problem at ' || string($this-pos) || ', codepoint ' || string(string-to-codepoints(substring($string-b, $this-pos, 1))) 
                        || ' versus ' || string(string-to-codepoints(substring($b-reconstructed, $this-pos, 1))) || '. Input B: ' ||
                        substring($string-b, $this-pos - 5, 5) || '‸' || substring($string-b, $this-pos, 20) || '; output B: ' || 
                        substring($b-reconstructed, $this-pos - 5, 5) || '‸' || substring($b-reconstructed, $this-pos, 20)"
                     />
                     <xsl:break/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:next-iteration/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:iterate>
         </xsl:if>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="$snap-to-word">
            <xsl:sequence select="tan:snap-diff-to-word($results-cleaned)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$results-cleaned"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>




   <!-- The actual diff engine -->
   <xsl:function name="tan:diff-loop" visibility="private" as="element()*">
      <xsl:param name="str-a" as="xs:string?"/>
      <xsl:param name="str-b" as="xs:string?"/>
      <xsl:param name="vertical-stops-to-process" as="xs:double*"/>
      <xsl:param name="loop-counter" as="xs:integer"/>
      
      <xsl:variable name="str-a-size" as="xs:integer" select="string-length($str-a)"/>
      <xsl:variable name="str-b-size" as="xs:integer" select="string-length($str-b)"/>
      
      <xsl:variable name="a-is-short" as="xs:boolean" select="$str-a-size le $str-b-size"/>
      <xsl:variable name="short-string-name" as="xs:string" select="
            if ($a-is-short) then
               'a'
            else
               'b'"/>
      <xsl:variable name="long-string-name" as="xs:string" select="
            if ($a-is-short) then
               'b'
            else
               'a'"/>
      
      <xsl:variable name="short-string" select="
            if ($a-is-short) then
               $str-a
            else
               $str-b" as="xs:string?"/>
      <xsl:variable name="long-string" select="
            if ($a-is-short) then
               $str-b
            else
               $str-a" as="xs:string?"/>
      
      <xsl:variable name="outer-loop-attr" as="attribute()">
         <xsl:attribute name="outer-loop" select="$loop-counter"/>
      </xsl:variable>
      
      <xsl:variable name="string-lengths-for-messages" as="xs:string" 
         select="'a is short? ' || string($a-is-short) || '; short string (' 
         || string(string-length($short-string)) || '): ' || tan:ellipses($short-string, 20) || '; long string (' 
         || string(string-length($long-string)) || '): ' || tan:ellipses($long-string, 20)"/>
      
      <xsl:variable name="empty-input" select="$str-b-size lt 1 or $str-a-size lt 1" as="xs:boolean"/>
      <xsl:variable name="loop-overload" select="$loop-counter ge $tan:loop-tolerance" as="xs:boolean"/>
      <xsl:variable name="out-of-vertical-stops" select="count($vertical-stops-to-process) lt 1" as="xs:boolean"/>

      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:diff-outer-loop()'"/>
         <xsl:message select="'loop number: ' || string($loop-counter)"/>
         <xsl:message select="'string a size: ' || string($str-a-size)"/>
         <xsl:message select="'string b size: ' || string($str-b-size)"/>
      </xsl:if>

      <xsl:choose>
         
         <xsl:when test="$empty-input or $loop-overload or $out-of-vertical-stops">
            <xsl:variable name="str-a-chars" as="xs:string*" select="tan:chop-string($str-a)"/>
            <xsl:variable name="str-b-chars" as="xs:string*" select="tan:chop-string($str-b)"/>

            <xsl:if test="$diagnostics-on">
               <xsl:message select="'empty input? ', $empty-input"/>
               <xsl:message select="'loop overload? ', $loop-overload"/>
               <xsl:message select="'out of vertical stops? ', $out-of-vertical-stops"/>
            </xsl:if>
            <xsl:if test="$loop-overload">
               <xsl:message
                  select="'tan:diff() cannot loop beyond ' || xs:string($tan:loop-tolerance) || 
                  ' passes; any remaining matching characters will be collated individually. String a (' 
                  || string($str-a-size) || '): ' || tan:ellipses($str-a, 20) || '; string b (' 
                  || string($str-b-size) || '): ' || tan:ellipses($str-b, 20)"/>
            </xsl:if>
            <xsl:choose>
               <xsl:when test="$str-a-chars = $str-b-chars">
                  
                  <xsl:variable name="best-sequence" as="element()*"
                     select="tan:collate-pair-of-sequences($str-a-chars, $str-b-chars)"/>
                  
                  <xsl:if test="$diagnostics-on">
                     <xsl:message select="'best sequence: ', $best-sequence"/>
                  </xsl:if>
                  <xsl:if test="$out-of-vertical-stops">
                     <xsl:message
                        select="'Out of vertical stops, and matches remain; ' || $string-lengths-for-messages"
                     />
                  </xsl:if>
                  <xsl:apply-templates select="$best-sequence" mode="tan:collated-sequences-to-diff"
                  />
               </xsl:when>
               <xsl:otherwise>
                  <a>
                     <xsl:value-of select="$str-a"/>
                  </a>
                  <b>
                     <xsl:value-of select="$str-b"/>
                  </b>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         
         <xsl:when test="$str-a eq $str-b">
            <common>
               <xsl:copy-of select="$outer-loop-attr" use-when="$tan:infuse-diff-diagnostics"/>
               <xsl:value-of select="$str-a"/>
            </common>
         </xsl:when>
         
         <xsl:when test="contains($long-string, $short-string)">
            <xsl:element name="{$long-string-name}">
               <xsl:copy-of select="$outer-loop-attr" use-when="$tan:infuse-diff-diagnostics"/>
               <xsl:value-of select="substring-before($long-string, $short-string)"/>
            </xsl:element>
            <common>
               <xsl:copy-of select="$outer-loop-attr" use-when="$tan:infuse-diff-diagnostics"/>
               <xsl:value-of select="$short-string"/>
            </common>
            <xsl:element name="{$long-string-name}">
               <xsl:copy-of select="$outer-loop-attr" use-when="$tan:infuse-diff-diagnostics"/>
               <xsl:value-of select="substring-after($long-string, $short-string)"/>
            </xsl:element>
         </xsl:when>
         
         
         <xsl:otherwise>
            <!-- Now we can search for parts of the short string within the long string -->
            
            <xsl:variable name="short-length" as="xs:integer" select="
                  if ($a-is-short) then
                     $str-a-size
                  else
                     $str-b-size"/>
            <xsl:iterate select="$vertical-stops-to-process">
               
               <xsl:on-completion>
                  <xsl:if test="$diagnostics-on">
                     <xsl:message
                        select="'No matches, out of vertical stops; ' || $string-lengths-for-messages"
                     />
                  </xsl:if>
                  <a>
                     <xsl:value-of select="$str-a"/>
                  </a>
                  <b>
                     <xsl:value-of select="$str-b"/>
                  </b>
               </xsl:on-completion>
               
               <xsl:variable name="this-vertical-stop" select="." as="xs:double"/>
               <xsl:variable name="percent-of-short-to-check"
                  select="min((max(($this-vertical-stop, 0.0000001)), 1.0))" as="xs:double"/>
               <xsl:variable name="length-of-short-substring" as="xs:integer"
                  select="xs:integer(ceiling($short-length * $percent-of-short-to-check))"/>
               <!-- If the sample size is at or below a certain predetermined threshold, draw the maximum number of samples that
                  the short string will allow. Otherwise, -->
               <xsl:variable name="number-of-horizontal-passes" select="
                     if ($length-of-short-substring le $tan:diff-suspend-horizontal-pass-maximum-when-sample-sizes-reach-what) then
                        max(($str-a-size, $str-b-size)) - $length-of-short-substring + 1
                     else
                        xs:integer(math:pow(1 - $percent-of-short-to-check, (1 div $tan:diff-horizontal-pass-frequency-rate)) * $tan:diff-maximum-number-of-horizontal-passes) + 1"
                  as="xs:integer"/>
               <xsl:variable name="length-of-play-in-short" as="xs:integer"
                  select="$short-length - $length-of-short-substring"/>
               <xsl:variable name="horizontal-stagger" as="xs:double"
                  select="$length-of-play-in-short div max(($number-of-horizontal-passes - 1, 1))"/>
               <xsl:variable name="starting-horizontal-locs" as="xs:integer+" select="
                     distinct-values(for $i in (1 to $number-of-horizontal-passes)
                     return
                        xs:integer(ceiling(($i - 1) * $horizontal-stagger) + 1))"/>
               
               <xsl:variable name="horizontal-search" as="element()?">
                  <!-- Look for a match horizontally -->
                  <xsl:iterate select="$starting-horizontal-locs">
                     <xsl:variable name="this-search-string" as="xs:string"
                        select="substring($short-string, ., $length-of-short-substring)"/>
                     <xsl:choose>
                        <xsl:when test="$this-search-string eq ''"/>
                        <xsl:when test="contains($long-string, $this-search-string)">
                           
                           <xsl:variable name="match-is-unambiguous" as="xs:boolean"
                              select="tan:contains-only-once($long-string, $this-search-string) 
                              and tan:contains-only-once($short-string, $this-search-string)"
                           />
                           <xsl:variable name="short-tokenized" as="xs:string*" select="
                                 if ($match-is-unambiguous) then
                                    ()
                                 else
                                    tokenize($short-string, $this-search-string, 'q')"/>
                           <xsl:variable name="long-tokenized" as="xs:string*" select="
                                 if ($match-is-unambiguous) then
                                    ()
                                 else
                                    tokenize($long-string, $this-search-string, 'q')"/>
                           <xsl:variable name="short-tok-pos" as="xs:integer*">
                              <xsl:iterate select="$short-tokenized">
                                 <xsl:param name="pos-so-far" as="xs:integer" select="1"/>
                                 <xsl:variable name="this-length" as="xs:integer" select="string-length(.)"/>
                                 <xsl:sequence select="$pos-so-far + $this-length"/>
                                 <xsl:next-iteration>
                                    <xsl:with-param name="pos-so-far"
                                       select="$pos-so-far + $this-length + $length-of-short-substring"/>
                                 </xsl:next-iteration>
                              </xsl:iterate>
                           </xsl:variable>
                           <xsl:variable name="long-tok-pos" as="xs:integer*">
                              <xsl:iterate select="$long-tokenized">
                                 <xsl:param name="pos-so-far" as="xs:integer" select="1"/>
                                 <xsl:variable name="this-length" as="xs:integer" select="string-length(.)"/>
                                 <xsl:sequence select="$pos-so-far + $this-length"/>
                                 <xsl:next-iteration>
                                    <xsl:with-param name="pos-so-far"
                                       select="$pos-so-far + $this-length + $length-of-short-substring"/>
                                 </xsl:next-iteration>
                              </xsl:iterate>
                           </xsl:variable>
                           <xsl:variable name="best-matching-pair" as="xs:integer*" select="
                                 if ($match-is-unambiguous) then
                                    ()
                                 else
                                    tan:best-integer-pair($short-tok-pos[position() ne last()], $long-tok-pos[position() ne last()],
                                    $short-tok-pos[last()], $long-tok-pos[last()])"
                           />
                           
                           <xsl:variable name="this-long-head" select="
                                 if ($match-is-unambiguous) then
                                    substring-before($long-string, $this-search-string)
                                 else
                                    string-join($long-tokenized[position() le $best-matching-pair[2]], $this-search-string)" as="xs:string"/>
                           <xsl:variable name="this-short-head" select="
                                 if ($match-is-unambiguous) then
                                    substring-before($short-string, $this-search-string)
                                 else
                                    string-join($short-tokenized[position() le $best-matching-pair[1]], $this-search-string)" as="xs:string"/>
                           <xsl:variable name="this-long-tail" select="
                                 if ($match-is-unambiguous) then
                                    substring-after($long-string, $this-search-string)
                                 else
                                    string-join($long-tokenized[position() gt $best-matching-pair[2]], $this-search-string)"
                              as="xs:string"/>
                           <xsl:variable name="this-short-tail" select="
                                 if ($match-is-unambiguous) then
                                    substring-after($short-string, $this-search-string)
                                 else
                                    string-join($short-tokenized[position() gt $best-matching-pair[1]], $this-search-string)"
                              as="xs:string"/>
                           
                           <xsl:variable name="inner-diagnostics-on" as="xs:boolean" select="false()"/>
                           <xsl:if test="$inner-diagnostics-on">
                              <xsl:message select="'--------- Search string: ' || $this-search-string"/>
                              <xsl:message
                                 select="'Short tokenized (' || string(count($short-tokenized)) || '): ' || string-join($short-tokenized, ', ')"
                              />
                              <xsl:message
                                 select="'Long tokenized (' || string(count($long-tokenized)) || '): ' || string-join($long-tokenized, ', ')"
                              />
                              <xsl:message select="'Short tokenized positions:', $short-tok-pos"/>
                              <xsl:message select="'Long tokenized positions:', $long-tok-pos"/>
                              <xsl:message select="'Best matching pair:', $best-matching-pair"/>
                              <xsl:message select="'Short head (' || string(string-length($this-short-head)) || '): ' || $this-short-head"/>
                              <xsl:message select="'Long head (' || string(string-length($this-long-head)) || '): ' || $this-long-head"/>
                              <xsl:message select="'Short tail (' || string(string-length($this-short-tail)) || '): ' || $this-short-tail"/>
                              <xsl:message select="'Long tail (' || string(string-length($this-long-tail)) || '): ' || $this-long-tail"/>
                           </xsl:if>
                           
                           <result>
                              <check-end>
                                 <xsl:element name="{$short-string-name}">
                                    <xsl:value-of select="$this-short-head"/>
                                 </xsl:element>
                                 <xsl:element name="{$long-string-name}">
                                    <xsl:value-of select="$this-long-head"/>
                                 </xsl:element>
                              </check-end>
                              
                              <common>
                                 <xsl:value-of select="$this-search-string"/>
                              </common>
                              
                              <check-start>
                                 <xsl:element name="{$short-string-name}">
                                    <xsl:value-of select="$this-short-tail"/>
                                 </xsl:element>
                                 <xsl:element name="{$long-string-name}">
                                    <xsl:value-of select="$this-long-tail"/>
                                 </xsl:element>
                              </check-start>
                              
                           </result>
                           <xsl:break/>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:next-iteration/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:iterate>
               </xsl:variable>

               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'loop counter', $loop-counter"/>
                  <xsl:message select="'$short-string:', tan:trim-long-text($short-string, 11)"/>
                  <xsl:message select="'$long-string:', tan:trim-long-text($long-string, 11)"/>
                  <xsl:message select="'$vertical-stops-to-process:', $vertical-stops-to-process"/>
                  <xsl:message select="'$short-size:', $short-length"/>
                  <xsl:message select="'$this-vertical-stop:', $this-vertical-stop"/>
                  <xsl:message select="'$percent-of-short-to-check:', $percent-of-short-to-check"/>
                  <xsl:message select="'$number-of-horizontal-passes:', $number-of-horizontal-passes"/>
                  <xsl:message select="'$length-of-short-substring:', $length-of-short-substring"/>
                  <xsl:message select="'$length-of-play-in-short:', $length-of-play-in-short"/>
                  <xsl:message select="'$horizontal-stagger:', $horizontal-stagger"/>
                  <xsl:message select="'$starting-horizontal-locs:', $starting-horizontal-locs"/>
                  <xsl:message select="'horizontal search: ', $horizontal-search"/>
               </xsl:if>
               
               <xsl:choose>
                  
                  <xsl:when test="exists($horizontal-search)">
                     <xsl:apply-templates select="$horizontal-search" mode="tan:adjust-horizontal-search">
                        <xsl:with-param name="loop-counter" tunnel="yes" select="$loop-counter"/>
                     </xsl:apply-templates>
                     <xsl:break/>
                  </xsl:when>
                  <xsl:when test="$length-of-short-substring le 1">
                     <a>
                        <xsl:value-of select="$str-a"/>
                     </a>
                     <b>
                        <xsl:value-of select="$str-b"/>
                     </b>
                     <xsl:break/>
                  </xsl:when>
   
                  <xsl:otherwise>
                     <xsl:next-iteration/>
                  </xsl:otherwise>
               </xsl:choose>
               
            </xsl:iterate>

         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:mode name="tan:collated-sequences-to-diff" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:long-seq" mode="tan:collated-sequences-to-diff">
      <diff>
         <xsl:apply-templates mode="#current"/>
      </diff>
   </xsl:template>
   <xsl:template match="tan:item[@p1 and @p2]" priority="1" mode="tan:collated-sequences-to-diff">
      <common>
         <xsl:value-of select="."/>
      </common>
   </xsl:template>
   <xsl:template match="tan:item[@p1]" mode="tan:collated-sequences-to-diff">
      <a>
         <xsl:value-of select="."/>
      </a>
   </xsl:template>
   <xsl:template match="tan:item[@p2]" mode="tan:collated-sequences-to-diff">
      <b>
         <xsl:value-of select="."/>
      </b>
   </xsl:template>
   
   
   <xsl:mode name="tan:adjust-horizontal-search" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:result" mode="tan:adjust-horizontal-search">
      <!-- although this is the default behavior, it is made explicit, to avoid any importing
         stylesheets from inadventently applying shallow copy to an element that is merely
         a wrapper. -->
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   <xsl:template match="tan:common" mode="tan:adjust-horizontal-search">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="tan:check-start" mode="tan:adjust-horizontal-search">
      <xsl:param name="loop-counter" tunnel="yes" as="xs:integer" select="0"/>

      <xsl:variable name="el1" as="element()" select="*[1]"/>
      <xsl:variable name="el2" as="element()" select="*[2]"/>
      <xsl:variable name="this-common-start" as="xs:string?">
         <xsl:if test="string-length($el1) gt 0 and string-length($el2) gt 0">
            <xsl:try select="tan:common-start-string(($el1, $el2))">
               <xsl:catch>
                  <xsl:message
                     select="'Too many calls to tan:common-start-string(), perhaps due to granular diff samples. Process will continue, but try adjusting parameters in parameters/params-function-diff.xsl.'"/>
                  <xsl:message select="'string 1: [' || tan:ellipses($el1, 100) || ']'"/>
                  <xsl:message select="'string 2: [' || tan:ellipses($el2, 100) || ']'"/>
               </xsl:catch>
            </xsl:try>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="this-common-start-length" select="string-length($this-common-start)" as="xs:integer"/>
      <xsl:variable name="new-elements" as="element()">
         <new>
            <xsl:apply-templates mode="#current">
               <xsl:sort select="string-length(.)"/>
               <xsl:with-param name="cut-from-start" as="xs:integer"
                  select="$this-common-start-length"/>
            </xsl:apply-templates>
         </new>
      </xsl:variable>
      
      <common>
         <xsl:value-of select="$this-common-start"/>
      </common>

      <xsl:sequence
         select="tan:diff-loop($new-elements/tan:a, $new-elements/tan:b, tan:vertical-stops($new-elements/*[1]), $loop-counter + 1)"
      />
      
   </xsl:template>
   
   <xsl:template match="tan:check-end" mode="tan:adjust-horizontal-search">
      <xsl:param name="loop-counter" tunnel="yes" as="xs:integer" select="0"/>
      
      <xsl:variable name="el1" as="element()" select="*[1]"/>
      <xsl:variable name="el2" as="element()" select="*[2]"/>
      <xsl:variable name="this-common-end" as="xs:string?">
         <xsl:if test="string-length($el1) gt 0 and string-length($el2) gt 0">
            <xsl:try
               select="tan:common-end-string(($el1, $el2))">
               <xsl:catch>
                  <xsl:message
                     select="'Too many calls to tan:common-end-string(), perhaps due to granular diff samples. Process will continue, but try adjusting parameters in parameters/params-function-diff.xsl.'"
                  />
                  <xsl:message select="'string 1: [' || tan:ellipses($el1, 100) || ']'"/>
                  <xsl:message select="'string 2: [' || tan:ellipses($el2, 100) || ']'"/>
               </xsl:catch>
            </xsl:try>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="this-common-end-length" select="string-length($this-common-end)" as="xs:integer"/>
      <xsl:variable name="new-elements" as="element()">
         <new>
            <xsl:apply-templates mode="#current">
               <xsl:sort select="string-length(.)"/>
               <xsl:with-param name="cut-from-end" as="xs:integer" select="$this-common-end-length"
               />
            </xsl:apply-templates>
         </new>
      </xsl:variable>
      
      <xsl:sequence
         select="tan:diff-loop($new-elements/tan:a, $new-elements/tan:b, tan:vertical-stops($new-elements/*[1]), $loop-counter + 1)"
      />
      
      <common>
         <xsl:value-of select="$this-common-end"/>
      </common>
      
   </xsl:template>

   <xsl:template match="tan:check-start-and-end" mode="tan:adjust-horizontal-search">
      <xsl:param name="loop-counter" tunnel="yes" as="xs:integer" select="0"/>
      
      <xsl:variable name="el1" as="element()" select="*[1]"/>
      <xsl:variable name="el2" as="element()" select="*[2]"/>
      <xsl:variable name="this-common-start" as="xs:string?">
         <xsl:if test="string-length($el1) gt 0 and string-length($el2) gt 0">
            <xsl:try select="tan:common-start-string(($el1, $el2))">
               <xsl:catch>
                  <xsl:message
                     select="'Too many calls to tan:common-start-string(), perhaps due to granular diff samples. Process will continue, but try adjusting parameters in parameters/params-function-diff.xsl.'"
                  />
                  <xsl:message select="'string 1: [' || tan:ellipses($el1, 100) || ']'"/>
                  <xsl:message select="'string 2: [' || tan:ellipses($el2, 100) || ']'"/>
               </xsl:catch>
            </xsl:try>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="this-common-start-length" select="string-length($this-common-start)" as="xs:integer"/>
      <xsl:variable name="this-common-end" as="xs:string?">
         <xsl:if test="string-length($el1) gt 0 and string-length($el2) gt 0">
            <xsl:try
               select="tan:common-end-string((substring($el1, 1 + $this-common-start-length), substring($el2, 1 + $this-common-start-length)))">
               <xsl:catch>
                  <xsl:message
                     select="'Too many calls to tan:common-end-string(), perhaps due to granular diff samples. Process will continue, but try adjusting parameters in parameters/params-function-diff.xsl.'"
                  />
                  <xsl:message select="'string 1: [' || tan:ellipses(substring($el1, 1 + $this-common-start-length), 100) || ']'"/>
                  <xsl:message select="'string 2: [' || tan:ellipses(substring($el2, 1 + $this-common-start-length), 100) || ']'"/>
               </xsl:catch>
            </xsl:try>
            
         </xsl:if>

      </xsl:variable>
      <xsl:variable name="this-common-end-length" select="string-length($this-common-end)" as="xs:integer"/>
      
      <xsl:variable name="new-elements" as="element()">
         <new>
            <xsl:apply-templates mode="#current">
               <xsl:sort select="string-length(.)"/>
               <xsl:with-param name="cut-from-start" as="xs:integer"
                  select="$this-common-start-length"/>
               <xsl:with-param name="cut-from-end" as="xs:integer" select="$this-common-end-length"
               />
            </xsl:apply-templates>
         </new>
      </xsl:variable>
      
      <common>
         <xsl:value-of select="$this-common-start"/>
      </common>
      
      <xsl:sequence
         select="tan:diff-loop($new-elements/tan:a, $new-elements/tan:b, tan:vertical-stops($new-elements/*[1]), $loop-counter + 1)"
      />
      
      <common>
         <xsl:value-of select="$this-common-end"/>
      </common>
      
   </xsl:template>
   
   
   <xsl:template match="tan:a | tan:b" mode="tan:adjust-horizontal-search">
      <xsl:param name="cut-from-start" as="xs:integer" select="0"/>
      <xsl:param name="cut-from-end" as="xs:integer" select="0"/>
      <xsl:variable name="this-length" as="xs:integer" select="string-length(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="substring(., 1 + $cut-from-start, $this-length - $cut-from-start - $cut-from-end)"/>
      </xsl:copy>
   </xsl:template>

   

   
   
   
   
   <!-- ANCILLARY, SUPPORT FUNCTIONS FOR OUTPUT OF TAN:DIFF() -->
   
   <!-- Snap diff output to words -->
   
   <xsl:function name="tan:snap-diff-to-word" as="element()?" visibility="private">
      <!-- Input: the output of tan:diff() -->
      <!-- Output: the output adjusted so that divisions occur only at word boundaries -->
      <!-- This function makes the precise output of tan:diff() more legible for humans. -->
      <xsl:param name="diff-output" as="element()?"/>
      
      <xsl:variable name="string-a" as="xs:string?" select="string-join($diff-output/(tan:a | tan:common))"/>
      <xsl:variable name="string-b" as="xs:string?" select="string-join($diff-output/(tan:b | tan:common))"/>
      <xsl:variable name="string-a-toks" as="element()" select="tan:tokenize-text($string-a)"/>
      <xsl:variable name="string-b-toks" as="element()" select="tan:tokenize-text($string-b)"/>
      <xsl:variable name="tok-a-lengths" as="xs:integer*" select="
            for $i in $string-a-toks/*
            return
               string-length($i)"/>
      <xsl:variable name="tok-b-lengths" as="xs:integer*" select="
            for $i in $string-b-toks/*
            return
               string-length($i)"/>
      <xsl:variable name="tok-and-non-tok-starts-a" as="xs:integer+" select="tan:lengths-to-positions($tok-a-lengths)"/>
      <xsl:variable name="tok-and-non-tok-starts-b" as="xs:integer+" select="tan:lengths-to-positions($tok-b-lengths)"/>
      
      <xsl:variable name="snapped-diff" as="element()">
         <diff>
            <xsl:iterate select="$diff-output/*">
               <xsl:param name="curr-a-pos" as="xs:integer" select="1"/>
               <xsl:param name="curr-b-pos" as="xs:integer" select="1"/>
               <xsl:param name="tok-and-non-tok-starts-a" as="xs:integer*" select="$tok-and-non-tok-starts-a"/>
               <xsl:param name="tok-and-non-tok-starts-b" as="xs:integer*" select="$tok-and-non-tok-starts-b"/>
               
               <xsl:variable name="el-name" as="xs:string" select="name(.)"/>
               <xsl:variable name="is-a" as="xs:boolean" select="$el-name eq 'a'"/>
               <xsl:variable name="is-b" as="xs:boolean" select="$el-name eq 'b'"/>
               <xsl:variable name="curr-len" as="xs:integer" select="string-length(.)"/>
               
               <xsl:variable name="new-a-pos" as="xs:integer" select="
                     if ($is-b) then
                        $curr-a-pos
                     else
                        $curr-a-pos + $curr-len"/>
               <xsl:variable name="new-b-pos" as="xs:integer" select="
                     if ($is-a) then
                        $curr-b-pos
                     else
                        $curr-b-pos + $curr-len"/>
               
               <xsl:variable name="relevant-tok-and-non-tok-starts-a" as="xs:integer*">
                  <xsl:if test="not($is-b)">
                     <xsl:iterate select="$tok-and-non-tok-starts-a">
                        <xsl:choose>
                           <xsl:when test=". ge $new-a-pos">
                              <xsl:break/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:sequence select="."/>
                              <xsl:next-iteration/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:iterate>
                  </xsl:if>
               </xsl:variable>
               <xsl:variable name="relevant-tok-and-non-tok-starts-b" as="xs:integer*">
                  <xsl:if test="not($is-a)">
                     <xsl:iterate select="$tok-and-non-tok-starts-b">
                        <xsl:choose>
                           <xsl:when test=". ge $new-b-pos">
                              <xsl:break/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:sequence select="."/>
                              <xsl:next-iteration/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:iterate>
                  </xsl:if>
               </xsl:variable>
               <xsl:variable name="relevant-start-count-a" as="xs:integer" select="count($relevant-tok-and-non-tok-starts-a)"/>
               <xsl:variable name="relevant-start-count-b" as="xs:integer" select="count($relevant-tok-and-non-tok-starts-b)"/>
               <xsl:variable name="new-tok-and-non-tok-starts-a" as="xs:integer*"
                  select="$tok-and-non-tok-starts-a[position() gt $relevant-start-count-a]"
               />
               <xsl:variable name="new-tok-and-non-tok-starts-b" as="xs:integer*"
                  select="$tok-and-non-tok-starts-b[position() gt $relevant-start-count-b]"
               />
               <!--<xsl:variable name="this-item-starts-new-tok-or-non-tok" as="xs:boolean" select="
                  ($curr-a-pos eq $relevant-tok-and-non-tok-starts-a[1])
                  and
                  ($curr-b-pos eq $relevant-tok-and-non-tok-starts-b[1])"/>-->
               <!-- The first common start should be position 1 only if both a and b agree. -->
               <xsl:variable name="first-common-tok-or-non-tok-start" as="xs:integer?" select="
                     if (($curr-a-pos ne $relevant-tok-and-non-tok-starts-a[1]) or ($curr-b-pos eq $relevant-tok-and-non-tok-starts-b[1]))
                     then
                        $relevant-tok-and-non-tok-starts-a[1]
                     else
                        $relevant-tok-and-non-tok-starts-a[2]"/>
               <xsl:variable name="next-item-starts-new-tok-or-non-tok" as="xs:boolean" select="
                  (not(exists($new-tok-and-non-tok-starts-a)) or ($new-tok-and-non-tok-starts-a[1] eq $new-a-pos))
                  and
                  (not(exists($new-tok-and-non-tok-starts-b)) or ($new-tok-and-non-tok-starts-b[1] eq $new-b-pos))"
               />
               
               <xsl:variable name="diagnostics-on" as="xs:boolean" select="$el-name eq 'common'"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'Diagnostics on, snap-to-word'"/>
                  <xsl:message select="'Curr element: ', ."/>
                  <xsl:message select="'Curr length: ', $curr-len"/>
                  <xsl:message select="'curr a/b pos:', $curr-a-pos, $curr-b-pos"/>
                  <xsl:message select="'new a/b pos:', $new-a-pos, $new-b-pos"/>
                  <xsl:message select="'relevant a starts: ', $relevant-tok-and-non-tok-starts-a"/>
                  <xsl:message select="'relevant b starts: ', $relevant-tok-and-non-tok-starts-b"/>
                  <xsl:message select="'First common tok/nontok start: ', $first-common-tok-or-non-tok-start"/>
                  <xsl:message select="'Last tok/nontok start: ', $relevant-tok-and-non-tok-starts-a[last()]"/>
                  <xsl:message select="'Next item starts new tok/nontok?: ', $next-item-starts-new-tok-or-non-tok"/>
               </xsl:if>
               
               <xsl:choose>
                  <xsl:when test="$is-a or $is-b">
                     <xsl:copy-of select="."/>
                  </xsl:when>
                  <!-- From here down, the element must be <common>. We follow the start count supplied by string a. -->
                  <xsl:when test="
                        ($relevant-start-count-a eq 0)
                        or
                        not(exists($first-common-tok-or-non-tok-start))">
                     <!-- This common cannot be initial (it would always have 1 as a start), so it
                     follows an a or b and some tok/nontok start. This is, as it were, cruft, and
                     should be broken out between a and b. The same situation if there is no
                     start to a tok/non-tok shared by both a and b in the common element.
                  -->
                     <a>
                        <xsl:value-of select="."/>
                     </a>
                     <b>
                        <xsl:value-of select="."/>
                     </b>
                  </xsl:when>
                  <xsl:when test="$next-item-starts-new-tok-or-non-tok">
                     <!-- The common has at least one tok/nontok start, and the next a and b begins 
                     a new tok/nontok start. Everything from the first start onward should be kept
                     in common. Only any text before that start should be split into a and b tracks.
                     -->
                     <!--<xsl:variable name="first-start" as="xs:integer" select="
                           if (($relevant-tok-and-non-tok-starts-a[1] eq $curr-a-pos) and not($this-item-starts-new-tok-or-non-tok)) then
                              $relevant-tok-and-non-tok-starts-a[2]
                           else
                              $relevant-tok-and-non-tok-starts-a[1]"/>-->
                     <xsl:variable name="init-frag-len" as="xs:integer"
                        select="$first-common-tok-or-non-tok-start - $curr-a-pos"/>
                     <xsl:if test="$init-frag-len gt 0">
                        <xsl:variable name="init-frag" as="xs:string" select="substring(., 1, $init-frag-len)"/>
                        <a><xsl:value-of select="$init-frag"/></a>
                        <b><xsl:value-of select="$init-frag"/></b>
                     </xsl:if>
                     <xsl:copy>
                        <xsl:value-of select="substring(., $init-frag-len + 1)"/>
                     </xsl:copy>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- The common has at least one start. Any text before that start is a fragment
                     that should be split into a and b tracks. Same for any text after the last 
                     start. -->
                     <!--<xsl:variable name="first-start" as="xs:integer" select="
                           if (($relevant-tok-and-non-tok-starts-a[1] eq $curr-a-pos) and not($this-item-starts-new-tok-or-non-tok)) then
                              $relevant-tok-and-non-tok-starts-a[2]
                           else
                              $relevant-tok-and-non-tok-starts-a[1]"/>-->
                     <xsl:variable name="last-start" as="xs:integer" select="$relevant-tok-and-non-tok-starts-a[last()]"/>
                     <xsl:variable name="init-frag-len" as="xs:integer"
                        select="$first-common-tok-or-non-tok-start - $curr-a-pos"/>
                     <xsl:if test="$init-frag-len gt 0">
                        <xsl:variable name="init-frag" as="xs:string" select="substring(., 1, $init-frag-len)"/>
                        <a><xsl:value-of select="$init-frag"/></a>
                        <b><xsl:value-of select="$init-frag"/></b>
                     </xsl:if>
                     <xsl:if test="$first-common-tok-or-non-tok-start lt $last-start">
                        <common><xsl:value-of select="substring(., $init-frag-len + 1, $last-start - $first-common-tok-or-non-tok-start)"/></common>
                     </xsl:if>
                     <a><xsl:value-of select="substring(., $last-start - $curr-a-pos + 1)"/></a>
                     <b><xsl:value-of select="substring(., $last-start - $curr-a-pos + 1)"/></b>
                  </xsl:otherwise>
               </xsl:choose>
               
               <xsl:next-iteration>
                  <xsl:with-param name="curr-a-pos" select="$new-a-pos"/>
                  <xsl:with-param name="curr-b-pos" select="$new-b-pos"/>
                  <xsl:with-param name="tok-and-non-tok-starts-a" select="$new-tok-and-non-tok-starts-a"/>
                  <xsl:with-param name="tok-and-non-tok-starts-b" select="$new-tok-and-non-tok-starts-b"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </diff>
      </xsl:variable>
      
      <xsl:variable name="final-diff" as="element()">
         <diff>
            <xsl:for-each-group select="$snapped-diff/*" group-starting-with="tan:common[text()]">
               <xsl:copy-of select="current-group()/self::tan:common[text()]"/>
               <xsl:if test="exists(current-group()/self::tan:a[text()])">
                  <a><xsl:value-of select="string-join(current-group()/self::tan:a)"/></a>
               </xsl:if>
               <xsl:if test="exists(current-group()/self::tan:b[text()])">
                  <b><xsl:value-of select="string-join(current-group()/self::tan:b)"/></b>
               </xsl:if>
            </xsl:for-each-group> 
         </diff>
      </xsl:variable>
      
      <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:variable name="string-a-rev" as="xs:string" select="string-join($final-diff/(tan:a | tan:common))"/>
            <xsl:variable name="string-b-rev" as="xs:string" select="string-join($final-diff/(tan:b | tan:common))"/>
            <diagnostics>
               <tok-a-lengths><xsl:copy-of select="$tok-a-lengths"/></tok-a-lengths>
               <tok-b-lengths><xsl:copy-of select="$tok-b-lengths"/></tok-b-lengths>
               <incoming-diff-output><xsl:copy-of select="$diff-output"/></incoming-diff-output>
               <diff-snapped><xsl:copy-of select="$snapped-diff"/></diff-snapped>
               <final-diff><xsl:copy-of select="$final-diff"/></final-diff>
               <xsl:if test="not($string-a eq $string-a-rev)">
                  <xsl:message select="'String a does not match revised string a'"/>
                  <xsl:copy-of select="tan:diff($string-a, $string-a-rev, false())"/>
               </xsl:if>
               <xsl:if test="not($string-b eq $string-b-rev)">
                  <xsl:message select="'String b does not match revised string b'"/>
                  <xsl:copy-of select="tan:diff($string-b, $string-b-rev, false())"/>
               </xsl:if>
            </diagnostics>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$final-diff"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   <xsl:function name="tan:snap-diff-to-word-old" as="element()?" visibility="private">
      <!-- Input: the output of tan:diff() -->
      <!-- Output: the output adjusted so that divisions occur only at word boundaries -->
      <!-- This function makes the precise output of tan:diff() more legible for humans. -->
      <xsl:param name="diff-output" as="element()?"/>
      
      <xsl:variable name="snap1" as="element()">
         <xsl:apply-templates select="$diff-output" mode="tan:snap-to-word-pass-1"/>
      </xsl:variable>
      <xsl:variable name="snap2" as="element()">
         <!-- It happens sometimes that matching words get restored in this process, either at the beginning or the end of an <a> or <b>; this step moves those common words back into the common pool -->
         <snap2>
            <xsl:for-each-group select="$snap1/*" group-starting-with="tan:common">
               <xsl:copy-of select="current-group()/self::tan:common"/>
               <xsl:variable name="text-a"
                  select="string-join(current-group()/(self::tan:a, self::tan:a-or-b), '')"/>
               <xsl:variable name="text-b"
                  select="string-join(current-group()/(self::tan:b, self::tan:a-or-b), '')"/>
               <xsl:variable name="a-toks" as="xs:string*">
                  <xsl:analyze-string select="$text-a" regex="{$tan:token-definition-default}">
                     <xsl:matching-substring>
                        <xsl:value-of select="."/>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:variable>
               <xsl:variable name="b-toks" as="xs:string*">
                  <xsl:analyze-string select="$text-b" regex="{$tan:token-definition-default}">
                     <xsl:matching-substring>
                        <xsl:value-of select="."/>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:variable>
               <xsl:variable name="a-tok-qty" select="count($a-toks)"/>
               <xsl:variable name="b-tok-qty" select="count($b-toks)"/>
               <xsl:variable name="non-matches-from-start" as="xs:integer*">
                  <!-- We are looking for first word where there isn't a match -->
                  <xsl:for-each select="$a-toks">
                     <xsl:variable name="pos" select="position()"/>
                     <xsl:if test="not(. = $b-toks[$pos])">
                        <xsl:value-of select="$pos"/>
                     </xsl:if>
                  </xsl:for-each>
                  <xsl:if test="$a-tok-qty lt $b-tok-qty">
                     <xsl:value-of select="$a-tok-qty + 1"/>
                  </xsl:if>
               </xsl:variable>
               <!-- grab those tokens in b starting with the first non match and reverse the order -->
               <xsl:variable name="b-nonmatches-rev"
                  select="reverse($b-toks[position() ge $non-matches-from-start[1]])"/>
               <xsl:variable name="a-nonmatches-rev"
                  select="reverse($a-toks[position() ge $non-matches-from-start[1]])"/>
               <xsl:variable name="non-matches-from-end" as="xs:integer*">
                  <!-- We're looking for the first word from the end where there isn't match -->
                  <xsl:for-each select="$a-nonmatches-rev">
                     <xsl:variable name="pos" select="position()"/>
                     <xsl:if test="not(. = $b-nonmatches-rev[$pos])">
                        <xsl:value-of select="$pos"/>
                     </xsl:if>
                  </xsl:for-each>
                  <xsl:if test="count($a-nonmatches-rev) lt count($b-nonmatches-rev)">
                     <xsl:value-of select="count($a-nonmatches-rev) + 1"/>
                  </xsl:if>
               </xsl:variable>
               <xsl:variable name="a-analyzed" as="element()*">
                  <xsl:for-each select="$a-toks">
                     <xsl:variable name="pos" select="position()"/>
                     <xsl:variable name="rev-pos" select="$a-tok-qty - $pos"/>
                     <xsl:choose>
                        <xsl:when test="$pos lt $non-matches-from-start[1]">
                           <common-head>
                              <xsl:value-of select="."/>
                           </common-head>
                        </xsl:when>
                        <xsl:when test="$rev-pos + 1 lt $non-matches-from-end[1]">
                           <common-tail>
                              <xsl:value-of select="."/>
                           </common-tail>
                        </xsl:when>
                        <xsl:otherwise>
                           <a>
                              <xsl:value-of select="."/>
                           </a>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:for-each>
               </xsl:variable>
               <xsl:variable name="b-analyzed" as="element()*">
                  <xsl:for-each select="
                     $b-toks[position() ge $non-matches-from-start[1]
                     and position() le ($b-tok-qty - $non-matches-from-end[1] + 1)]">
                     <b>
                        <xsl:value-of select="."/>
                     </b>
                  </xsl:for-each>
               </xsl:variable>
               <xsl:for-each-group select="($a-analyzed, $b-analyzed)" group-by="name()">
                  <xsl:sort
                     select="index-of(('common-head', 'a', 'b', 'common-tail'), current-grouping-key())"/>
                  <xsl:variable name="element-name"
                     select="replace(current-grouping-key(), '-.+', '')"/>
                  <xsl:element name="{$element-name}">
                     <xsl:value-of select="string-join(current-group(), '')"/>
                  </xsl:element>
               </xsl:for-each-group>
            </xsl:for-each-group>
         </snap2>
      </xsl:variable>

      <diff>
         <xsl:for-each-group select="$snap2/*" group-adjacent="name()">
            <xsl:element name="{current-grouping-key()}">
               <xsl:value-of select="string-join(current-group(), '')"/>
            </xsl:element>
         </xsl:for-each-group>
      </diff>
      
   </xsl:function>

   <xsl:mode name="tan:snap-to-word-pass-1" on-no-match="shallow-copy"/>

   <xsl:template match="tan:common" mode="tan:snap-to-word-pass-1">
      <xsl:variable name="preceding-diff"
         select="preceding-sibling::*[1][self::tan:a or self::tan:b]"/>
      <xsl:variable name="following-diff"
         select="following-sibling::*[1][self::tan:a or self::tan:b]"/>
      <xsl:choose>
         <xsl:when test="exists($preceding-diff) or exists($following-diff)">
            <xsl:variable name="regex-1" select="
                  if (exists($preceding-diff)) then
                     ('^' || $tan:token-definition-default)
                  else
                     ()"/>
            <xsl:variable name="regex-2" select="
                  if (exists($following-diff)) then
                     ($tan:token-definition-default || '$')
                  else
                     ()"/>
            <xsl:variable name="content-analyzed" as="element()">
               <content>
                  <xsl:analyze-string select="text()"
                     regex="{string-join(($regex-1, $regex-2),'|')}">
                     <xsl:matching-substring>
                        <a-or-b>
                           <xsl:value-of select="."/>
                        </a-or-b>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <common>
                           <xsl:value-of select="."/>
                        </common>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </content>
            </xsl:variable>
            <xsl:choose>
               <xsl:when test="matches($content-analyzed/tan:common, '\S')">
                  <xsl:copy-of select="$content-analyzed/*"/>
               </xsl:when>
               <xsl:otherwise>
                  <a-or-b>
                     <xsl:value-of select="."/>
                  </a-or-b>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   <!-- port diff output to collation output -->
   
   <xsl:function name="tan:diff-to-collation" as="element()" visibility="public">
      <!-- Input: any single output of tan:diff(), two strings for the labels of diff strings a and b -->
      <!-- Output: the output converted to the output of tan:collate(), namely, a <collation> with <u> and
         <c> children, wrapping <txt>, <wit>. -->
      <!-- This function was written to support the XSLT 3.0 version of tan:collate(), to allow tan:diff()
         to be merged with tan:collate() output -->
      <!--kw: strings, diff -->
      <xsl:param name="diff-output" as="element()?"/>
      <xsl:param name="diff-text-a-label" as="xs:string?"/>
      <xsl:param name="diff-text-b-label" as="xs:string?"/>
      <collation>
         <witness id="{$diff-text-a-label}"/>
         <witness id="{$diff-text-b-label}"/>
         <xsl:iterate select="$diff-output/*">
            <xsl:param name="next-a-pos" select="1"/>
            <xsl:param name="next-b-pos" select="1"/>

            <xsl:variable name="this-length" select="string-length(.)"/>
            <xsl:variable name="this-a-length" select="
                  if (self::tan:a or self::tan:common) then
                     $this-length
                  else
                     0"/>
            <xsl:variable name="this-b-length" select="
                  if (self::tan:b or self::tan:common) then
                     $this-length
                  else
                     0"/>

            <xsl:choose>
               <!-- We leave a marker for both witnesses in every <a> or <b>, but marking one
               as <wit> and another as <x>. This will facilitate the grouping of collations. -->
               <xsl:when test="self::tan:a">
                  <u>
                     <txt>
                        <xsl:value-of select="."/>
                     </txt>
                     <wit ref="{$diff-text-a-label}" pos="{$next-a-pos}"/>
                     <x ref="{$diff-text-b-label}" pos="{$next-b-pos}"/>
                  </u>
               </xsl:when>
               <xsl:when test="self::tan:b">
                  <u>
                     <txt>
                        <xsl:value-of select="."/>
                     </txt>
                     <x ref="{$diff-text-a-label}" pos="{$next-a-pos}"/>
                     <wit ref="{$diff-text-b-label}" pos="{$next-b-pos}"/>
                  </u>
               </xsl:when>
               <xsl:when test="self::tan:common">
                  <c>
                     <txt>
                        <xsl:value-of select="."/>
                     </txt>
                     <wit ref="{$diff-text-a-label}" pos="{$next-a-pos}"/>
                     <wit ref="{$diff-text-b-label}" pos="{$next-b-pos}"/>
                  </c>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:message select="'Unclear how to process ' || name(.)"/>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:next-iteration>
               <xsl:with-param name="next-a-pos" select="$next-a-pos + $this-a-length"/>
               <xsl:with-param name="next-b-pos" select="$next-b-pos + $this-b-length"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </collation>
   </xsl:function>
   
   
   
   
   <xsl:function name="tan:concat-and-sort-diff-output" as="element(tan:diff)?" visibility="private">
      <!-- Input: any output <diff>s from tan:diff() that should be concatenated and sorted -->
      <!-- Output: a single <diff> with adjacent elements consolidated, and <a>s before <b>s -->
      <!-- Empty elements will be omitted. -->
      <xsl:param name="diff-output" as="element(tan:diff)*"/>
      <diff>
         <xsl:for-each-group select="$diff-output/*[text()]" group-adjacent="name() = 'common'">
            <xsl:choose>
               <xsl:when test="current-grouping-key()">
                  <common>
                     <xsl:value-of select="string-join(current-group())"/>
                  </common>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:for-each-group select="current-group()" group-by="name()">
                     <xsl:sort select="current-grouping-key()"/>
                     <xsl:element name="{current-grouping-key()}">
                        <xsl:value-of select="string-join(current-group())"/>
                     </xsl:element>
                  </xsl:for-each-group>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </diff>
   </xsl:function>
   
   
   <xsl:function name="tan:adjust-diff" as="element()*" visibility="public">
      <!-- Input: any output <diff>s from tan:diff() -->
      <!-- Output: the output adjusted, with <a> and <b>s shifted if there are more optimal divisions -->
      <!-- Multiple inputs are presumed to be tan:diff() results that should be concatenated. -->
      <!-- This function is helpful for cases where the common element needs to be adjusted to better respect word or phrase boundaries. -->
      <!--kw: strings, diff -->
      <xsl:param name="diff-output" as="element(tan:diff)*"/>
      <xsl:variable name="input-consolidated" select="tan:concat-and-sort-diff-output($diff-output)"
         as="element()?"/>
      <xsl:variable name="end-of-sequence" as="element()">
         <end-of-sequence/>
      </xsl:variable>
      <xsl:variable name="element-count" select="count($input-consolidated/*)"/>
      <xsl:variable name="adjustment-1" as="element()?">
         <diff>
            <xsl:iterate select="$input-consolidated/*, $end-of-sequence">
               <xsl:param name="group-so-far" as="element()">
                  <group/>
               </xsl:param>

               <xsl:variable name="this-is-the-end" select="self::tan:end-of-sequence"/>
               <xsl:variable name="last-group-in-group-so-far"
                  select="$group-so-far/tan:group[last()]"/>
               <xsl:variable name="this-name" select="name(.)"/>

               <!-- We think of the adjustment process as being applied to a triad, i.e., a combination of 
                  <common> + <a/b> + <common> or <a/b> + <common> + <a/b>. The triad is complete 
                  in the case of the former, and in the latter it is  complete only if the current element is 
                  not a missing <a> or <b> (i.e., the current element is <common>)-->
               <!-- We assume there is only perhaps one <a> and perhaps one <b> before
               any <common>, so checking for completeness of the triad depends upon checking
               for <common>, instead of trying to figure out combinations of <a> and <b>. -->
               <xsl:variable name="group-so-far-is-a-complete-triad" select="
                     (count($group-so-far/tan:group) eq 3)
                     and
                     (self::tan:common or $last-group-in-group-so-far/tan:common)"/>

               <xsl:variable name="group-so-far-for-adjustment" as="element()?">
                  <xsl:choose>
                     <xsl:when
                        test="$this-is-the-end and exists($group-so-far/tan:group/tan:a) and exists($group-so-far/tan:group/tan:b)">
                        <!-- If we're at the end, well, it's time to wrap things up. Because we've ended with a dummy 
                        element, the group so far should be the first two parts of a triad. The middle part cannot be 
                        shifted right, and it can be shifted left only if some new element is created at the tail to receive
                        the common text. And so it must be a <common>. Which means that the middle part of the triad
                        can only be a group of both <a> and <b>.
                        -->
                        <group>
                           <xsl:copy-of select="$group-so-far/*"/>
                           <group>
                              <common/>
                           </group>
                        </group>
                     </xsl:when>
                     <xsl:when test="$group-so-far-is-a-complete-triad">
                        <xsl:sequence select="$group-so-far"/>
                     </xsl:when>
                     <!-- If the group so far is incomplete and we're not at the end, then we leave the variable empty -->
                  </xsl:choose>
               </xsl:variable>

               <!-- The terms "end" and "start" are relative to the middle part of the triad -->
               <xsl:variable name="common-end-1"
                  select="tan:common-end-string($group-so-far-for-adjustment/tan:group[position() = (1, 2)]/*)"/>
               <xsl:variable name="common-start-1"
                  select="tan:common-start-string($group-so-far-for-adjustment/tan:group[position() = (2, 3)]/*)"/>

               <xsl:variable name="shift-middle-by" as="xs:integer?">
                  <xsl:choose>
                     <!-- We shift only <a>s and <b>s, not <common>s -->
                     <xsl:when test="exists($group-so-far-for-adjustment/tan:group[2]/tan:common)"/>
                     <!-- If an <a> or <b> can be shifted to accommodate word spaces, we prefer that spaces be put 
                     at the end of the <a> or <b>, hence the different placement of \s in each of the next two
                     regular expressions. The other patterns below look for grouping punctuation, e.g. () {}
                     [] &; <> to try to get the whole group within an <a> or <b> -->
                     <xsl:when test="
                           $group-so-far-for-adjustment/tan:group[1]/tan:common
                           and matches($common-end-1, '^\s*[\[&lt;\(&amp;\{]')">
                        <xsl:value-of select="string-length($common-end-1) * -1"/>
                     </xsl:when>
                     <xsl:when test="
                           $group-so-far-for-adjustment/tan:group[3]/tan:common
                           and matches($common-start-1, '[\]&gt;\)\s;\}]$')">
                        <xsl:value-of select="string-length($common-start-1)"/>
                     </xsl:when>
                     <!-- The previous two cases looked for cases where the entire common segment could be moved;
                     we now look for partial movements, The next two cases look for places where an opening or closing
                     punctuation can (and should) be pushed into an a/b. -->
                     <xsl:when test="matches($common-end-1, '[\[&lt;\(]')">
                        <xsl:value-of
                           select="string-length(replace($common-start-1, '$.*?(\s*[\[&lt;\(])', '$1', 's'))"
                        />
                     </xsl:when>
                     <xsl:when test="matches($common-start-1, '[\]&gt;\)]')">
                        <xsl:value-of
                           select="string-length(replace($common-start-1, '^(.*[\]&gt;\)]\s*).*$', '$1', 's'))"
                        />
                     </xsl:when>
                  </xsl:choose>
               </xsl:variable>

               <xsl:variable name="text-to-insert" as="xs:string?">
                  <xsl:choose>
                     <xsl:when test="$shift-middle-by lt 0">
                        <xsl:sequence
                           select="substring($common-end-1, (string-length($common-end-1) + $shift-middle-by))"
                        />
                     </xsl:when>
                     <xsl:when test="$shift-middle-by gt 0">
                        <xsl:sequence select="substring($common-start-1, 1, $shift-middle-by)"/>
                     </xsl:when>
                  </xsl:choose>
               </xsl:variable>

               <xsl:variable name="new-group-adjusted" as="element()?">
                  <xsl:choose>
                     <xsl:when test="exists($shift-middle-by)">
                        <group>
                           <xsl:apply-templates select="$group-so-far-for-adjustment/*[1]"
                              mode="tan:trim-or-add-text">
                              <xsl:with-param name="trim-end-by" tunnel="yes" select="
                                    if ($shift-middle-by lt 0) then
                                       abs($shift-middle-by)
                                    else
                                       ()"/>
                              <xsl:with-param name="append-text" tunnel="yes" select="
                                    if ($shift-middle-by gt 0) then
                                       $text-to-insert
                                    else
                                       ()"/>
                           </xsl:apply-templates>
                           <xsl:apply-templates select="$group-so-far-for-adjustment/*[2]"
                              mode="tan:trim-or-add-text">
                              <xsl:with-param name="trim-start-by" tunnel="yes" select="
                                    if ($shift-middle-by gt 0) then
                                       $shift-middle-by
                                    else
                                       ()"/>
                              <xsl:with-param name="trim-end-by" tunnel="yes" select="
                                    if ($shift-middle-by lt 0) then
                                       abs($shift-middle-by)
                                    else
                                       ()"/>
                              <xsl:with-param name="prepend-text" tunnel="yes" select="
                                    if ($shift-middle-by lt 0) then
                                       $text-to-insert
                                    else
                                       ()"/>
                              <xsl:with-param name="append-text" tunnel="yes" select="
                                    if ($shift-middle-by gt 0) then
                                       $text-to-insert
                                    else
                                       ()"/>
                           </xsl:apply-templates>
                           <xsl:apply-templates select="$group-so-far-for-adjustment/*[3]"
                              mode="tan:trim-or-add-text">
                              <xsl:with-param name="trim-start-by" tunnel="yes" select="
                                    if ($shift-middle-by gt 0) then
                                       $shift-middle-by
                                    else
                                       ()"/>
                              <xsl:with-param name="prepend-text" tunnel="yes" select="
                                    if ($shift-middle-by lt 0) then
                                       $text-to-insert
                                    else
                                       ()"/>
                           </xsl:apply-templates>
                        </group>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="$group-so-far-for-adjustment"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>

               <!-- build new parameters -->
               <xsl:variable name="group-to-pass-to-next-iteration" as="element()">
                  <group>
                     <xsl:choose>
                        <!-- Is the group so far incomplete? I.e., is this an <a> that needs to join
                        a lonely <b> or vice versa? -->
                        <xsl:when test="
                              ($last-group-in-group-so-far/tan:a and self::tan:b)
                              or ($last-group-in-group-so-far/tan:b and self::tan:a)">
                           <xsl:copy-of select="$last-group-in-group-so-far/preceding-sibling::*"/>
                           <group>
                              <xsl:copy-of select="$last-group-in-group-so-far/*"/>
                              <xsl:copy-of select="."/>
                           </group>
                        </xsl:when>
                        <!-- Perhaps its incomplete only because we've just started. -->
                        <xsl:when test="not($group-so-far-is-a-complete-triad)">
                           <xsl:copy-of select="$group-so-far/tan:group"/>
                           <group>
                              <xsl:copy-of select="."/>
                           </group>
                        </xsl:when>
                        <xsl:otherwise>
                           <!-- The second part of the inherited triad now becomes the first part of the next triad -->
                           <xsl:copy-of select="$new-group-adjusted/*[2]"/>
                           <xsl:copy-of select="$new-group-adjusted/*[3]"/>
                           <group>
                              <xsl:copy-of select="."/>
                           </group>
                        </xsl:otherwise>
                     </xsl:choose>
                  </group>
               </xsl:variable>

               <xsl:variable name="diagnostics-on" select="false()"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'Diagnostics on, tan:adjust-diff(), iteration', position()"/>
                  <xsl:if test="$this-is-the-end">
                     <xsl:message select="'Last iteration.'"/>
                  </xsl:if>
                  <xsl:message select="'Group so far: ', $group-so-far"/>
                  <xsl:message select="'This item: ', ."/>
                  <xsl:message select="'Process the group that has been built so far?: ', $group-so-far-is-a-complete-triad"/>
                  <xsl:message select="'Group primed for adjustment and output: ', $group-so-far-for-adjustment"/>
                  <xsl:message select="'Common end (1): ' || $common-end-1"/>
                  <xsl:message select="'Common start (1): ' || $common-start-1"/>
                  <xsl:message select="'Shift middle by:', $shift-middle-by"/>
                  <xsl:message select="'Text to insert: ' || $text-to-insert"/>
                  <xsl:message select="'Group to pass to next iteration: ', $group-to-pass-to-next-iteration"
                  />
               </xsl:if>

               <!-- write results -->
               <!-- We copy only those elements that have text. In the course of adjustment, some elements might
               have been dispensed with, creating another area that needs to be fixed. -->
               <xsl:choose>
                  <xsl:when
                     test="$this-is-the-end and exists($new-group-adjusted/tan:group[3]/*[text()])">
                     <xsl:copy-of select="$new-group-adjusted/tan:group[1]/*[text()]"/>
                     <xsl:copy-of select="$new-group-adjusted/tan:group[2]/*[text()]"/>
                     <xsl:copy-of select="$new-group-adjusted/tan:group[3]/*[text()]"/>
                  </xsl:when>
                  <xsl:when test="$this-is-the-end">
                     <!-- If we're at the end but can't move the second part of the triad, then we just 
                     return the group so far, without changes -->
                     <xsl:copy-of select="$group-so-far/tan:group/*[text()]"/>
                  </xsl:when>
                  <xsl:when test="$group-so-far-is-a-complete-triad">
                     <!-- Only the first part of the triad is now fully adjusted, and can be copied to output. The 
                        second part of the triad will become the first part of the next triad. -->
                     <xsl:copy-of select="$new-group-adjusted/tan:group[1]/*[text()]"/>
                  </xsl:when>
               </xsl:choose>

               <xsl:next-iteration>
                  <xsl:with-param name="group-so-far" select="$group-to-pass-to-next-iteration"/>
               </xsl:next-iteration>
            </xsl:iterate>

         </diff>
      </xsl:variable>

      <xsl:sequence select="tan:concat-and-sort-diff-output($adjustment-1)"/>

   </xsl:function>

   <xsl:mode name="tan:trim-or-add-text" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:a | tan:b | tan:common" mode="tan:trim-or-add-text">
      <xsl:param name="trim-start-by" tunnel="yes" as="xs:integer?"/>
      <xsl:param name="trim-end-by" tunnel="yes" as="xs:integer?"/>
      <xsl:param name="prepend-text" tunnel="yes" as="xs:string?"/>
      <xsl:param name="append-text" tunnel="yes" as="xs:string?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="$prepend-text"/>
         <xsl:choose>
            <xsl:when test="($trim-start-by gt 0) and ($trim-end-by gt 0)">
               <xsl:value-of select="substring(., $trim-start-by + 1, (string-length(.) - $trim-start-by - $trim-end-by))"/>
            </xsl:when>
            <xsl:when test="$trim-start-by gt 0">
               <xsl:value-of select="substring(., $trim-start-by + 1)"/>
            </xsl:when>
            <xsl:when test="$trim-end-by gt 0">
               <xsl:value-of select="substring(., 1, (string-length(.) - $trim-end-by))"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:value-of select="$append-text"/>
      </xsl:copy>
   </xsl:template>
   
   
   
   <!-- Analysis of string length -->
   
   <xsl:function name="tan:stamp-diff-with-text-data" as="item()*" visibility="public">
      <!-- Input: any output from tan:diff() -->
      <!-- Output: each <diff> child stamped with @_len, @_pos-a, @_pos-b indicating
      length and the starting positions for a and b -->
      <!-- This function produces output analogous to tan:stamp-tree-with-text-data() -->
      <!--kw: strings, tree manipulation, attributes -->
      <xsl:param name="diff-result" as="element()?"/>
      
      <xsl:apply-templates select="$diff-result" mode="tan:stamp-diff-with-text-data"/>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:stamp-diff-with-text-data" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:diff" mode="tan:stamp-diff-with-text-data">
      <xsl:variable name="diff-elements" select="tan:a | tan:b | tan:common" as="element()*"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="node() except $diff-elements" mode="#current"/>
         <xsl:iterate select="$diff-elements">
            <xsl:param name="current-a-pos" as="xs:integer" select="1"/>
            <xsl:param name="current-b-pos" as="xs:integer" select="1"/>

            <xsl:variable name="this-length" select="string-length(.)" as="xs:integer"/>
            <xsl:variable name="this-local-name" select="local-name(.)" as="xs:string"/>
            <xsl:variable name="mark-a" as="xs:boolean" select="$this-local-name = ('common', 'a')"/>
            <xsl:variable name="mark-b" as="xs:boolean" select="$this-local-name = ('common', 'b')"/>
            <xsl:variable name="new-a-pos" select="
                  if ($mark-a) then
                     $current-a-pos + $this-length
                  else
                     $current-a-pos"/>
            <xsl:variable name="new-b-pos" select="
                  if ($mark-b) then
                     $current-b-pos + $this-length
                  else
                     $current-b-pos"/>

            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="_len" select="$this-length"/>
               <xsl:attribute name="_pos-a" select="$current-a-pos"/>
               <xsl:attribute name="_pos-b" select="$current-b-pos"/>
               <xsl:sequence select="node()"/>
            </xsl:copy>

            <xsl:next-iteration>
               <xsl:with-param name="current-a-pos" select="$new-a-pos"/>
               <xsl:with-param name="current-b-pos" select="$new-b-pos"/>
            </xsl:next-iteration>

         </xsl:iterate>
      </xsl:copy>
   </xsl:template>
   
   
   
   
   <xsl:function name="tan:chop-diff-output" as="map(xs:integer, item()*)" visibility="public">
      <!-- Input: diff output; a sequence of integers; a boolean; a string -->
      <!-- Output: a map whose constituent map entries consist of the input
      chopped into parts according to the input sequence of integers. If the
      boolean is true, then chops will be made according to string a, with
      chops on b made proportionally, respecting the boundaries defined by
      the fourth parameter. -->
      <!-- Each map entry have as its value a <diff> wrapping the fragment
      <a>, <b>, <common>s. -->
      <!-- If the input diff output already has @_pos-a and the like already
      inside, those figures will be respected, otherwise string data will be
      stamped into the input, and will be preserved in the output. -->
      <!-- The numeral 1 will be automatically added to the chop points, and
         duplicates will be removed. -->
      <!-- If the chop regex for the other string is missing, the chops will
      occur on individual characters. -->
      <!-- This function was written primarily to support verbose validation of
      class 1 files, and to drive the application that synchronizes a class 1
      file with a given redivision. -->
      <!-- This function provides a more complex approach to the generic one
      supported by tan:chop-tree() -->
      <!--kw: strings, tree manipulation -->
      <xsl:param name="diff-output" as="element(tan:diff)?"/>
      <xsl:param name="chop-points" as="xs:integer*"/>
      <xsl:param name="use-string-a" as="xs:boolean"/>
      <xsl:param name="chop-other-at-regex" as="xs:string?"/>
      
      <xsl:variable name="diff-adjusted" as="element()?" select="
            if (exists($diff-output/*[@_len])) then
               $diff-output
            else
               tan:stamp-diff-with-text-data($diff-output)"/>
      <xsl:variable name="chop-points-sorted" as="xs:integer+"
         select="sort(distinct-values((1, $chop-points[. ge 1])))"/>
      <xsl:variable name="chop-regex-adjusted" select="
            if (tan:regex-is-valid($chop-other-at-regex))
            then
               $chop-other-at-regex
            else
               $tan:char-regex"/>
      
      <xsl:variable name="diagnostics-on" select="false()" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:chop-diff-output()'"/>
         <xsl:message select="'Input diff output (adjusted): ', $diff-adjusted"/>
         <xsl:message select="'Use string a?: ' || string($use-string-a)"/>
         <xsl:message select="
               'Chop points sorted: ' || string-join((for $i in $chop-points-sorted
               return
                  string($i)), ', ')"/>
         <xsl:message select="'Chop regex (adjusted): ' || $chop-regex-adjusted"/>
      </xsl:if>
      
      
      <xsl:map>
         <xsl:iterate select="$chop-points-sorted">
            <xsl:param name="upcoming-chop-points" as="xs:integer*" select="tail($chop-points-sorted)"/>
            <xsl:param name="diff-remnant" as="element(tan:diff)?" select="$diff-adjusted"/>
            
            <xsl:variable name="next-chop-point" select="head($upcoming-chop-points)"/>
            
            <xsl:variable name="diff-elements-of-interest" as="element()*" select="
                  if ($use-string-a) then
                     $diff-remnant/*[xs:integer(@_pos-a) lt $next-chop-point]
                  else
                     $diff-remnant/*[xs:integer(@_pos-b) lt $next-chop-point]"/>
            
            <xsl:variable name="overlapping-diff-elements-of-interest" as="element()*" select="
                  if ($use-string-a) then
                     $diff-elements-of-interest[xs:integer(@_pos-a) + xs:integer(@_len) gt $next-chop-point]
                  else
                     $diff-elements-of-interest[xs:integer(@_pos-b) + xs:integer(@_len) gt $next-chop-point]
                  "/>
            <xsl:variable name="nonoverlapping-diff-elements-of-interest" as="element()*"
               select="$diff-elements-of-interest except $overlapping-diff-elements-of-interest"/>
            
            <xsl:variable name="diff-elements-not-of-interest"
               select="$diff-remnant/(* except $diff-elements-of-interest)" as="element()*"/>
            
            <xsl:variable name="overlaps-split-1" as="element()">
               <overlaps>
                  <xsl:if test="exists($next-chop-point)">
                     <xsl:apply-templates select="$overlapping-diff-elements-of-interest"
                        mode="tan:split-diff-components-1">
                        <xsl:with-param name="chop-point" select="$next-chop-point" as="xs:integer"/>
                        <xsl:with-param name="use-string-a" select="$use-string-a" as="xs:boolean"/>
                     </xsl:apply-templates>
                  </xsl:if>
               </overlaps>
            </xsl:variable>
            
            <!-- Commenting out Apr 2021, pending further investigation into when the split needs to be
               recalibrated. This step does not work when the differences between a and b are significant,
               esp. at the beginning. -->
            <!--<xsl:variable name="overlaps-split-2" as="element()">
               <xsl:apply-templates select="$overlaps-split-1" mode="tan:split-diff-components-2">
                  <xsl:with-param name="split-models" tunnel="yes" as="element()*"
                     select="$overlaps-split-1/(tan:first | tan:last)"/>
                  <xsl:with-param name="chop-at-regex" tunnel="yes" as="xs:string"
                     select="$chop-regex-adjusted"/>
               </xsl:apply-templates>
            </xsl:variable>-->
            
            <xsl:variable name="overlaps-to-keep" select="$overlaps-split-1/tan:first/*[text()]" as="element()*"/>
            <xsl:variable name="overlaps-to-push" select="$overlaps-split-1/tan:last/*[text()]" as="element()*"/>
            
            <!-- new diff remnant -->
            <xsl:variable name="new-diff-remnant" as="element()?">
               <xsl:if test="exists($diff-elements-not-of-interest) or exists($overlaps-to-push)">
                  <diff>
                     <xsl:copy-of select="$overlaps-to-push"/>
                     <xsl:copy-of select="$diff-elements-not-of-interest"/>
                  </diff>
               </xsl:if>
            </xsl:variable>
            
            
            <xsl:variable name="inner-diagnostics-on" select="$diagnostics-on" as="xs:boolean"/>
            <xsl:if test="$inner-diagnostics-on">
               <xsl:message select="'Iteration', position()"/>
               <xsl:message select="'This, next chop points: ', ., $next-chop-point"/>
               <xsl:message select="'Diff remnant:', $diff-remnant"/>
               <xsl:message select="'Overlaps split 1:', $overlaps-split-1"/>
               <!--<xsl:message select="'Overlaps split 2:', $overlaps-split-2"/>-->
               <xsl:message select="'Overlaps to keep:', $overlaps-to-keep"/>
               <xsl:message select="'Overlaps to push:', $overlaps-to-push"/>
               <xsl:message select="'New diff remnant:', $new-diff-remnant"/>
            </xsl:if>
            
            
            <!-- output -->
            <xsl:choose>
               <xsl:when test="not(exists($next-chop-point))">
                  <xsl:map-entry key=".">
                     <xsl:sequence select="$diff-remnant"/>
                  </xsl:map-entry>
               </xsl:when>
               <xsl:when test="exists($diff-elements-of-interest) or exists($overlaps-to-keep)">
                  <xsl:map-entry key=".">
                     <diff>
                        <xsl:copy-of select="$nonoverlapping-diff-elements-of-interest"/>
                        <xsl:copy-of select="$overlaps-to-keep"/>
                     </diff>
                  </xsl:map-entry>
               </xsl:when>
            </xsl:choose>
            
            <xsl:next-iteration>
               <xsl:with-param name="upcoming-chop-points" select="tail($upcoming-chop-points)"/>
               <xsl:with-param name="diff-remnant" select="$new-diff-remnant"/>
            </xsl:next-iteration>
            
         </xsl:iterate>
      </xsl:map>
      
   </xsl:function>
   
   
   
   <xsl:mode name="tan:split-diff-components-1" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:split-diff-components-2" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:common | tan:a | tan:b" mode="tan:split-diff-components-1">
      <xsl:param name="chop-point" as="xs:integer"/>
      <xsl:param name="use-string-a" as="xs:boolean"/>
      
      <xsl:variable name="el-local-name" as="xs:string" select="local-name(.)"/>
      <xsl:variable name="this-is-base" as="xs:boolean" select="
            ($el-local-name eq 'common')
            or
            (if ($use-string-a) then
               ($el-local-name eq 'a')
            else
               ($el-local-name eq 'b'))"/>
      
      <xsl:variable name="string-chopped" as="xs:string*" select="tan:chop-string(.)"/>
      <xsl:variable name="pos-point" as="xs:integer" select="
            if ($use-string-a) then
               xs:integer(@_pos-a)
            else
               xs:integer(@_pos-b)"/>
      <xsl:variable name="first-segment-length" as="xs:double" select="$chop-point - $pos-point"/>
      <xsl:variable name="first-segment"
         select="subsequence($string-chopped, 1, $first-segment-length)" as="xs:string*"/>
      <xsl:variable name="last-segment"
         select="subsequence($string-chopped, $first-segment-length + 1)" as="xs:string*"/>
      
      <xsl:choose>
         <xsl:when test="$this-is-base">
            <first>
               <xsl:copy>
                  <xsl:copy-of select="@* except @_len"/>
                  <xsl:attribute name="_len" select="$first-segment-length"/>
                  <xsl:sequence select="string-join($first-segment)"/>
               </xsl:copy>
            </first>
            <last>
               <xsl:copy>
                  <xsl:copy-of select="@* except @_len"/>
                  <xsl:if test="$el-local-name = ('a', 'common')">
                     <xsl:attribute name="_pos-a" select="xs:integer(@_pos-a) + $first-segment-length"/>
                  </xsl:if>
                  <xsl:if test="$el-local-name = ('b', 'common')">
                     <xsl:attribute name="_pos-b" select="xs:integer(@_pos-b) + $first-segment-length"/>
                  </xsl:if>
                  <xsl:attribute name="_len" select="count($last-segment)"/>
                  <xsl:sequence select="string-join($last-segment)"/>
               </xsl:copy>
            </last>
         </xsl:when>
         <xsl:otherwise>
            <!-- If it's not a base, it will get split in a process following this one, proportionate
               to its model. -->
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:template>
   
   
   <xsl:template match="tan:first | tan:last" mode="tan:split-diff-components-2">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   <xsl:template match="tan:a | tan:b" mode="tan:split-diff-components-2">
      <xsl:param name="split-models" tunnel="yes" as="element()*"/>
      <xsl:param name="chop-at-regex" tunnel="yes" as="xs:string"/>
      
      <xsl:variable name="model-length" select="tan:string-length(string-join($split-models/(tan:a | tan:b)))"
         as="xs:integer"/>
      <xsl:variable name="el-local-name" select="local-name(.)"/>
      <xsl:variable name="pos-point" as="xs:integer" select="
            if ($el-local-name eq 'a') then
               xs:integer(@_pos-a)
            else
               xs:integer(@_pos-b)"/>
      <xsl:choose>
         <xsl:when test="$model-length lt 1">
            <!-- If there are no proportions, keep the other text here. -->
            <first>
               <xsl:copy-of select="."/>
            </first>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="first-length"
               select="tan:string-length(string-join($split-models[self::tan:first]/(tan:a | tan:b)))"
               as="xs:integer"/>
            <xsl:variable name="proportion" select="$first-length div $model-length" as="xs:double"/>
            <xsl:variable name="string-chopped" select="tan:chop-string(., $chop-at-regex)" as="xs:string*"/>
            <xsl:variable name="segment-length" as="xs:integer" select="count($string-chopped)"/>
            <xsl:variable name="chop-point"
               select="xs:integer(round($segment-length * $proportion))" as="xs:integer"/>
            
            <!--<xsl:variable name="first-segment-length" as="xs:double" select="$chop-point - $pos-point"/>-->
            <xsl:variable name="first-segment"
               select="subsequence($string-chopped, 1, $chop-point)" as="xs:string*"/>
            <xsl:variable name="last-segment"
               select="subsequence($string-chopped, $chop-point + 1)" as="xs:string*"/>
            
            <xsl:variable name="first-segment-joined" select="string-join($first-segment)" as="xs:string"/>
            <xsl:variable name="last-segment-joined" select="string-join($last-segment)" as="xs:string"/>
            
            <xsl:variable name="first-segment-length"
               select="tan:string-length($first-segment-joined)" as="xs:integer"/>
            <xsl:variable name="last-segment-length"
               select="tan:string-length($last-segment-joined)" as="xs:integer"/>
            
            <first>
               <xsl:copy>
                  <xsl:copy-of select="@* except @_len"/>
                  <xsl:attribute name="_len" select="$first-segment-length"/>
                  <xsl:sequence select="$first-segment-joined"/>
               </xsl:copy>
            </first>
            <last>
               <xsl:copy>
                  <xsl:copy-of select="@* except @_len"/>
                  <xsl:if test="$el-local-name eq 'a'">
                     <xsl:attribute name="_pos-a" select="xs:integer(@_pos-a) + $first-segment-length"/>
                  </xsl:if>
                  <xsl:if test="$el-local-name eq 'b'">
                     <xsl:attribute name="_pos-b" select="xs:integer(@_pos-b) + $first-segment-length"/>
                  </xsl:if>
                  <xsl:attribute name="_len" select="$last-segment-length"/>
                  <xsl:sequence select="$last-segment-joined"/>
               </xsl:copy>
            </last>
            
            
            
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   
   
   

</xsl:stylesheet>
