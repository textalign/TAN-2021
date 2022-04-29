<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="3.0">

   <!-- TAN Function Library standard string functions. -->

   <xsl:function name="tan:fill" as="xs:string?" visibility="public">
      <!-- Input: a string, an integer -->
      <!-- Output: a string with the first parameter repeated the number of times specified by the integer -->
      <!-- This function was written to facilitate indentation -->
      <!--kw: strings, spacing -->
      <xsl:param name="string-to-fill" as="xs:string?"/>
      <xsl:param name="times-to-repeat" as="xs:integer"/>
      <xsl:if test="$times-to-repeat gt 0">
         <xsl:sequence select="
               string-join(for $i in (1 to $times-to-repeat)
               return
                  $string-to-fill)"/>
      </xsl:if>
   </xsl:function>

   <xsl:function name="tan:batch-replace" as="xs:string?" visibility="public">
      <!-- Input: a string, a sequence of:
         <[ANY NAME] pattern="" replacement="" [flags=""] [message=""]> -->
      <!-- Output: the string, after those replaces are processed in order -->
      <!--kw: strings -->
      <xsl:param name="string-to-replace" as="xs:string?"/>
      <xsl:param name="replace-elements" as="element()*"/>
      
      <xsl:variable name="ok-replace-elements" as="element()*"
         select="$replace-elements[exists(@pattern) and exists(@replacement)]"/>
      <xsl:variable name="bad-replace-elements" as="element()*"
         select="$replace-elements except $ok-replace-elements"/>
      
      <xsl:for-each select="$bad-replace-elements">
         <xsl:message select="'Malformed replace element for tan:batch-replace(): ', ."/>
      </xsl:for-each>
      
      <xsl:choose>
         <xsl:when test="not(exists($ok-replace-elements))">
            <xsl:value-of select="$string-to-replace"/>
         </xsl:when>
         <xsl:when test="string-length($string-to-replace) lt 1">
            <xsl:value-of select="$string-to-replace"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:iterate select="$ok-replace-elements">
               <xsl:param name="string-so-far" as="xs:string" select="$string-to-replace"/>
               <xsl:on-completion select="$string-so-far"/>
               
               <xsl:variable name="new-string" as="xs:string" select="
                     if (exists(@flags)) then
                        tan:replace($string-so-far, @pattern, @replacement, @flags)
                     else
                        tan:replace($string-so-far, @pattern, @replacement)"/>
               <xsl:if test="not($string-so-far = $new-string) and exists(@message)">
                  <xsl:message select="string(@message)"/>
               </xsl:if>
               <xsl:next-iteration>
                  <xsl:with-param name="string-so-far" as="xs:string" select="$new-string"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:string-length" as="xs:integer" visibility="public">
      <!-- Input: any string -->
      <!-- Output: the number of characters in the string, as defined by TAN (i.e., modifiers are counted with the preceding base character) -->
      <!--kw: strings -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:copy-of select="count(tan:chop-string($input))"/>
   </xsl:function>


   <xsl:function name="tan:normalize-text" as="xs:string*" visibility="public">
      <!-- one-parameter version of full function below -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:sequence select="tan:normalize-text($text, false())"/>
   </xsl:function>

   <xsl:function name="tan:normalize-name" as="xs:string*" visibility="public">
      <!-- one-parameter version of fuller one, below -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:sequence select="tan:normalize-text($text, true())"/>
   </xsl:function>

   <xsl:function name="tan:normalize-text" as="xs:string*" visibility="public">
      <!-- Input: any sequence of strings; a boolean indicating whether the results should be name-normalized -->
      <!-- Output: that sequence, with each item's space normalized, and removal of any help requested -->
      <!-- In name-normalization, the string is converted to lower-case, and spaces replace hyphens, underscores, and illegal characters. -->
      <!-- Special end div characters are not removed in this operation, nor is tail-end space adjusted according to TAN rules; for that, see tan:normalize-div-text(). -->
      <!--kw: strings -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:param name="treat-as-name-values" as="xs:boolean"/>
      <xsl:for-each select="$text">
         <!-- replace illegal characters with spaces; if a name, render lowercase and replace specially designated characters with spaces -->
         <xsl:variable name="prep-pass-1" select="
               if ($treat-as-name-values = true()) then
                  lower-case(replace(., $tan:regex-name-space-characters || '|' || $tan:regex-characters-not-permitted, ' '))
               else
                  replace(., $tan:regex-characters-not-permitted, ' ')"/>
         <!-- delete the help trigger and ensure proper use of modifying characters -->
         <xsl:variable name="prep-pass-2" select="
               if ($treat-as-name-values = true()) then
                  replace($prep-pass-1, '\p{M}|' || $tan:help-trigger-regex, '')
               else
                  replace($prep-pass-1, '\s+(\p{M})|' || $tan:help-trigger-regex, '$1')"/>
         <!-- normalize the results, both for space and for unicode -->
         <xsl:value-of select="normalize-unicode(normalize-space($prep-pass-2))"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:atomize-string" as="xs:string*" visibility="public">
      <!-- surrogate function for tan:chop-string() -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:copy-of select="tan:chop-string($input)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:chop-string" as="xs:string*" visibility="public">
      <!-- Input: any string -->
      <!-- Output: that string chopped into a sequence of individual characters, following TAN rules (modifying characters always join their preceding base character) -->
      <!--kw: strings, sequences -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:if test="string-length($input) gt 0">
         <xsl:analyze-string select="$input" regex="{$tan:char-regex}">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>

   <xsl:function name="tan:chop-string" as="xs:string*" visibility="public" use-when="$tan:validation-mode-on">
      <!-- Input: any string -->
      <!-- Output: that string chopped into a sequence of individual characters, following TAN rules 
         (modifying characters always join their preceding base character) -->
      <!--kw: strings, sequences -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:param name="chop-after-regex" as="xs:string"/>
      <xsl:if test="string-length($input) gt 0">
         <xsl:analyze-string select="$input" regex="{$chop-after-regex}">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="tan:chop-string" as="xs:string*" visibility="public" use-when="not($tan:validation-mode-on)">
      <!-- 2-param version of the full one below -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:param name="chop-after-regex" as="xs:string"/>
      <xsl:sequence
         select="tan:chop-string($input, $chop-after-regex, $tan:do-not-chop-parenthetical-clauses)"
      />
   </xsl:function>
   
   <xsl:function name="tan:chop-string" as="xs:string*" visibility="public" use-when="not($tan:validation-mode-on)">
      <!-- Input: any string, a regular expression, a boolean -->
      <!-- Output: the input string cut into a sequence of strings using the regular expression as the cut marker -->
      <!-- If the last boolean is true, then nested clauses (parentheses, direct quotations, etc.) will be preserved. -->
      <!-- This function differs from the 1-parameter version in that it is used to chop the string not into individual characters but into words, clauses, sentences, etc. -->
      <!--kw: strings -->
      <xsl:param name="input" as="xs:string?"/>
      <xsl:param name="chop-after-regex" as="xs:string"/>
      <xsl:param name="preserve-nested-clauses" as="xs:boolean"/>
      <xsl:if test="string-length($input) gt 0">
         <xsl:variable name="input-analyzed" as="element()*">
            <xsl:analyze-string select="$input" regex="{$chop-after-regex}">
               <xsl:matching-substring>
                  <br>
                     <xsl:value-of select="."/>
                  </br>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <nbr>
                     <xsl:value-of select="."/>
                  </nbr>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:choose>
            <xsl:when test="$preserve-nested-clauses">
               <xsl:variable name="input-checked"
                  select="tan:nested-phrase-loop($input-analyzed, ())" as="element()*"/>
               <xsl:for-each-group select="$input-checked"
                  group-ending-with="tan:br[not(tan:group-data/tan:type)]">
                  <xsl:value-of
                     select="
                     string-join(for $i in current-group()
                     return
                     $i/tan:val, '')"
                  />
               </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
               <xsl:for-each-group select="$input-analyzed" group-ending-with="tan:br">
                  <xsl:value-of select="string-join(current-group(), '')"/>
               </xsl:for-each-group>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:function>
   
   <xsl:variable name="tan:nested-phrase-markers" as="element()">
      <grouping-data>
         <pair>
            <open>[</open>
            <close>]</close>
         </pair>
         <pair>
            <open>(</open>
            <close>)</close>
         </pair>
         <pair>
            <open>&lt;</open>
            <close>></close>
         </pair>
         <pair>
            <open>"</open>
            <close>"</close>
         </pair>
         <pair>
            <open>»</open>
            <close>«</close>
         </pair>
         <pair>
            <open>{</open>
            <close>}</close>
         </pair>
         <pair>
            <open>‘</open>
            <open>‚</open>
            <close>’</close>
         </pair>
         <pair>
            <open>“</open>
            <open>„</open>
            <close>”</close>
         </pair>
         <pair>
            <open>‹</open>
            <close>›</close>
         </pair>
         <pair>
            <open>《</open>
            <close>》</close>
         </pair>
         <pair>
            <open>『</open>
            <close>』</close>
         </pair>
         <pair>
            <open>﹃</open>
            <close>﹄</close>
         </pair>
         <pair>
            <open>〈</open>
            <close>〉</close>
         </pair>
         <pair>
            <open>「</open>
            <close>」</close>
         </pair>
         <pair>
            <open>﹁</open>
            <close>﹂</close>
         </pair>
      </grouping-data>
   </xsl:variable>
   
   <xsl:variable name="tan:nested-phrase-marker-regex"
      select="'[' || tan:escape(string-join($tan:nested-phrase-markers/tan:pair/*/text())) || ']'"/>
   <xsl:variable name="tan:nested-phrase-close-marker-regex"
      select="'[' || tan:escape(string-join($tan:nested-phrase-markers/tan:pair/tan:close/text())) || ']'"/>
   
   <xsl:function name="tan:nested-phrase-loop" as="element()*" visibility="private">
      <!-- Input: a series of elements with text content; an element indicating what nesting exists so far -->
      <!-- Output: each input element with the text value put into <val> and a  -->
      <xsl:param name="elements-to-process" as="element()*"/>
      <xsl:param name="current-nesting-data" as="element()?"/>
      <xsl:choose>
         <xsl:when test="count($elements-to-process) lt 1"/>
         <xsl:otherwise>
            <xsl:variable name="this-element" select="$elements-to-process[1]"/>
            <xsl:variable name="this-element-analyzed" as="element()*">
               <xsl:analyze-string select="$this-element" regex="{$tan:nested-phrase-marker-regex}">
                  <xsl:matching-substring>
                     <xsl:variable name="this-match" select="."/>
                     <xsl:variable name="closing-group-opener"
                        select="$tan:nested-phrase-markers/tan:pair[tan:close = $this-match]/tan:open[1]"/>
                     <type>
                        <xsl:attribute name="level" select="
                              if (exists($closing-group-opener)) then
                                 -1
                              else
                                 1"/>
                        <xsl:if test="$this-match = $closing-group-opener">
                           <xsl:attribute name="toggle"/>
                        </xsl:if>
                        <xsl:value-of select="($closing-group-opener, $this-match)[1]"/>
                     </type>
                  </xsl:matching-substring>
               </xsl:analyze-string>
            </xsl:variable>
            <xsl:variable name="new-group-data" as="element()">
               <group-data>
                  <xsl:for-each-group select="$this-element-analyzed, $current-nesting-data/*"
                     group-by=".">
                     <xsl:variable name="this-level" as="xs:integer">
                        <xsl:choose>
                           <xsl:when test="exists(current-group()/@toggle)">
                              <xsl:copy-of select="count(current-group()) mod 2"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:copy-of select="
                                    sum(for $i in current-group()
                                    return
                                       xs:integer($i/@level))"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:variable>
                     <xsl:if test="$this-level gt 0">
                        <type level="{$this-level}">
                           <xsl:value-of select="current-grouping-key()"/>
                        </type>
                     </xsl:if>
                  </xsl:for-each-group>
               </group-data>
            </xsl:variable>
            <xsl:for-each select="$this-element">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:copy-of select="$new-group-data"/>
                  <val>
                     <xsl:value-of select="text()"/>
                  </val>
               </xsl:copy>
            </xsl:for-each>
            <xsl:copy-of
               select="tan:nested-phrase-loop($elements-to-process[position() gt 1], $new-group-data)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:function name="tan:tokenize-text" as="element()*" visibility="public">
      <!-- one-parameter version of the function below -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:sequence select="tan:tokenize-text($text, $tan:token-definition-default, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:tokenize-text" as="element()*" visibility="public">
      <!-- three-parameter version of the function below -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:param name="token-definition" as="element(tan:token-definition)?"/>
      <xsl:param name="count-toks" as="xs:boolean?"/>
      <xsl:sequence select="tan:tokenize-text($text, $token-definition, $count-toks, false(), false())"/>
   </xsl:function>
   
   <xsl:function name="tan:tokenize-text" as="element()*" visibility="public">
      <!-- Input: any number of strings; a <token-definition>; a boolean indicating whether tokens should be counted and labeled. -->
      <!-- Output: a <result> for each string, tokenized into <tok> and <non-tok>, respectively. If the counting option is turned on, the <result> contains @tok-count and @non-tok-count, and each <tok> and <non-tok> have an @n indicating which <tok> group it belongs to. -->
      <!--kw: strings, sequences -->
      <xsl:param name="text" as="xs:string*"/>
      <xsl:param name="token-definition" as="element(tan:token-definition)?"/>
      <xsl:param name="count-toks" as="xs:boolean?"/>
      <xsl:param name="add-attr-q" as="xs:boolean?"/>
      <xsl:param name="add-attr-pos" as="xs:boolean?"/>

      <xsl:variable name="this-tok-def" select="
            if (exists($token-definition)) then
               $token-definition
            else
               $tan:token-definition-default"/>
      <xsl:variable name="pattern" select="$this-tok-def/@pattern"/>
      <xsl:variable name="this-regex-is-valid" select="tan:regex-is-valid($pattern)"/>
      <xsl:variable name="pattern-adjusted" select="
            if ((string-length($pattern) gt 0) and ($this-regex-is-valid = true())) then
               $pattern
            else
               '.+'"/>
      <xsl:variable name="flags" select="$this-tok-def/@flags"/>
      <xsl:if test="$this-regex-is-valid eq false()">
         <xsl:message select="'Regex ' || $pattern || ' is not a valid regular expression.'"/>
      </xsl:if>
      <xsl:variable name="pass-1" as="element()*">
         <xsl:for-each select="$text">
            <results regex="{$pattern}" flags="{$flags}">
               <xsl:analyze-string select="." regex="{$pattern-adjusted}">
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
            </results>
         </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="pass-2" as="element()*">
         <xsl:choose>
            <xsl:when test="$add-attr-pos = true()">
               <xsl:apply-templates select="$pass-1" mode="tan:add-tok-pos"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$pass-1"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:tokenize-text()'"/>
         <xsl:message select="'Input token definition: ', $token-definition"/>
         <xsl:message select="'this token definition pattern: ', string($pattern)"/>
         <xsl:message select="'pattern codepoints: ', string-to-codepoints($pattern)"/>
         <xsl:message select="'this token definition pattern adjusted: ', string($pattern-adjusted)"/>
         <xsl:message select="'add @q?', $add-attr-q"/>
         <xsl:message select="'add @pos?', $add-attr-pos"/>
         <xsl:message select="'pass 2: ', $pass-2"/>
      </xsl:if>

      <xsl:choose>
         <xsl:when test="not(exists($pattern)) or string-length($pattern) lt 1">
            <xsl:message select="'Tokenization definition has no pattern.'"/>
            <xsl:sequence select="$pass-2"/>
         </xsl:when>
         <xsl:when test="$count-toks = true()">
            <xsl:for-each select="$pass-2">
               <results tok-count="{count(tan:tok)}" non-tok-count="{count(tan:non-tok)}">
                  <xsl:for-each-group select="*" group-starting-with="tan:tok">
                     <xsl:variable name="pos" select="position()"/>
                     <xsl:for-each select="current-group()">
                        <!-- NB, <non-tok>s will attract the @pos of their master <tok> @pos, making it easy to group tokens with the non-tokens that follow. -->
                        <xsl:copy>
                           <xsl:copy-of select="@*"/>
                           <xsl:attribute name="n" select="$pos"/>
                           <xsl:if test="$add-attr-q = true()">
                              <xsl:attribute name="q" select="generate-id(.)"/>
                           </xsl:if>
                           <xsl:value-of select="."/>
                        </xsl:copy>
                     </xsl:for-each>
                  </xsl:for-each-group>
               </results>
            </xsl:for-each>
         </xsl:when>
         <xsl:when test="$add-attr-q = true()">
            <xsl:apply-templates select="$pass-2" mode="tan:first-stamp-shallow-copy">
               <xsl:with-param name="add-q-ids" select="true()" tunnel="yes"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$pass-2"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:mode name="tan:add-tok-pos" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:tok" mode="tan:add-tok-pos">
      <xsl:variable name="this-val" select="text()"/>
      <xsl:variable name="prev-toks" select="preceding-sibling::tan:tok[. = $this-val]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="pos" select="count($prev-toks) + 1"/>
         <xsl:value-of select="."/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:unique-char" as="xs:string?" visibility="public">
      <!-- Input: any sequence of strings -->
      <!-- Output: a single character that is not to be found in those strings -->
      <!-- This function, written to support tan:collate-sequences(), provides unique 
         way to join any sequence strings in such a way that it can later be tokenized. -->
      <!--kw: strings -->
      <xsl:param name="context-strings" as="xs:string*"/>
      <xsl:for-each select="string-join($context-strings) => string-to-codepoints()">
         <xsl:sort select="." order="descending"/>
         <xsl:if test="position() eq 1">
            <xsl:sequence select="codepoints-to-string(. + 1)"/>
         </xsl:if>
      </xsl:for-each> 
   </xsl:function>
   
   <xsl:function name="tan:ellipses" as="xs:string*" visibility="public">
      <!-- 2-arity version of the fuller one, below -->
      <xsl:param name="strings-to-truncate" as="xs:string*"/>
      <xsl:param name="string-length-to-retain" as="xs:integer"/>
      <xsl:sequence select="tan:ellipses($strings-to-truncate, $string-length-to-retain, 0)"/>
   </xsl:function>

   <xsl:function name="tan:ellipses" as="xs:string*" visibility="public">
      <!-- 3-arity version of the fuller one, below -->
      <xsl:param name="strings-to-truncate" as="xs:string*"/>
      <xsl:param name="string-length-to-retain" as="xs:integer"/>
      <xsl:param name="terminal-string-length-to-retain" as="xs:integer"/>
      <xsl:sequence
         select="tan:ellipses($strings-to-truncate, $string-length-to-retain, $terminal-string-length-to-retain, $tan:validation-context-supply-length-of-elision)"
      />
   </xsl:function>
   
   <xsl:function name="tan:ellipses" as="xs:string*" visibility="public">
      <!-- Input: any sequence of strings; two integers; a boolean -->
      <!-- Output: the sequence of strings, but with any initial substring beyond the first requested length and 
         any terminal substring beyond the last requested length replaced by ellipses. If the boolean is true, then
         two sets of ellipses will be provided, surrounding in square brackets the number of characters removed. -->
      <!-- If the elision is less than the length of the replacement, then no elision will take place. -->
      <!-- Examples: 
         "abcd", 1, 1, false > "a…d"
         "abcd", 1, 1, true > "abcd"
         "abcdefghijk", 1, 1, true > "a…[9]…k"
      -->
      <!-- kw: strings -->
      <xsl:param name="strings-to-truncate" as="xs:string*"/>
      <xsl:param name="initial-string-length-to-retain" as="xs:integer"/>
      <xsl:param name="terminal-string-length-to-retain" as="xs:integer"/>
      <xsl:param name="indicate-number-of-characters-elided" as="xs:boolean"/>
      
      <xsl:variable name="total-string-length-to-retain" as="xs:integer"
         select="$initial-string-length-to-retain + $terminal-string-length-to-retain"/>
      <xsl:for-each select="$strings-to-truncate">
         <xsl:variable name="this-string-length" as="xs:integer" select="string-length(.)"/>
         <xsl:variable name="amount-to-truncate" as="xs:integer"
            select="$this-string-length - ($initial-string-length-to-retain + $terminal-string-length-to-retain)"
         />
         <xsl:variable name="truncation-insertion" as="xs:string" select="
               if ($indicate-number-of-characters-elided) then
                  ('…[' || string($amount-to-truncate) || ']…')
               else
                  ('…')"/>
         <xsl:variable name="truncate-this" as="xs:boolean" select="$amount-to-truncate gt string-length($truncation-insertion)"/>
         
         <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
         <xsl:if test="$diagnostics-on">
            <xsl:message select="'Diagnostics on, tan:ellipses()'"/>
            <xsl:message select="'String to truncate: ' || ."/>
            <xsl:message select="'String to truncate length: ', $this-string-length"/>
            <xsl:message select="'Initial string length to retain: ', $initial-string-length-to-retain"/>
            <xsl:message select="'Terminal string length to retain: ', $terminal-string-length-to-retain"/>
            <xsl:message select="'Show count of characters elided: ', $indicate-number-of-characters-elided"/>
            <xsl:message select="'Amount to truncate: ', $amount-to-truncate"/>
            <xsl:message select="'Truncate this?: ', $truncate-this"/>
            <xsl:message select="'Truncation insertion: ' || $truncation-insertion"/>
         </xsl:if>
         
         
         <xsl:choose>
            <xsl:when test="$truncate-this
               and ($initial-string-length-to-retain eq 0)
               and ($terminal-string-length-to-retain eq 0)">
               <xsl:value-of select="$truncation-insertion"/>
            </xsl:when>
            <xsl:when test="$truncate-this
               and ($initial-string-length-to-retain eq 0)">
               <xsl:value-of select="$truncation-insertion || 
                  substring(., $this-string-length - $terminal-string-length-to-retain)"/>
            </xsl:when>
            <xsl:when test="$truncate-this
               and ($terminal-string-length-to-retain eq 0)">
               <xsl:value-of select="substring(., 1, $initial-string-length-to-retain) || $truncation-insertion"/>
            </xsl:when>
            <xsl:when test="$truncate-this">
               <xsl:value-of select="substring(., 1, $initial-string-length-to-retain) || $truncation-insertion || 
                  substring(., $this-string-length - $terminal-string-length-to-retain)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
      
   </xsl:function>
   
   
   <!-- This mode allows one to use apply templates to truncate the text nodes in a tree. This can be quite useful
      for diagnostic output, or, in the case of the validation routine, trimming the results of tan:diff(). -->
   <xsl:mode name="tan:ellipses" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:ellipses">
      <xsl:param name="initial-string-length-to-retain" as="xs:integer" tunnel="yes"
         select="$tan:validation-context-string-length-max"/>
      <xsl:param name="terminal-string-length-to-retain" as="xs:integer" tunnel="yes"
         select="$tan:validation-context-string-length-max"/>
      <xsl:param name="indicate-number-of-characters-elided" as="xs:boolean" tunnel="yes"
         select="$tan:validation-context-supply-length-of-elision"/>
      <xsl:value-of
         select="tan:ellipses(., $initial-string-length-to-retain, $terminal-string-length-to-retain, $indicate-number-of-characters-elided)"
      />
   </xsl:template>
   
   
   <xsl:function name="tan:common-start-string" as="xs:string?" visibility="public">
      <!-- 1-parameter version of fuller function below -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:sequence select="tan:common-start-or-end-string($strings, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:common-end-string" as="xs:string?" visibility="public">
      <!-- 1-parameter version of fuller function below -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:sequence select="tan:common-start-or-end-string($strings, false())"/>
   </xsl:function>
   
   <xsl:function name="tan:common-start-or-end-string" as="xs:string?" visibility="public">
      <!-- 2-parameter version of fuller function below -->
      <!-- This one deals with many strings; the full one, with pairs of them -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:param name="find-common-start" as="xs:boolean"/>
      <xsl:variable name="string-count" select="count($strings)"/>
      <xsl:choose>
         <xsl:when test="$string-count lt 2">
            <xsl:sequence select="$strings"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:iterate select="$strings[position() gt 1]">
               <xsl:param name="common-so-far" as="xs:string*" select="$strings[1]"/>
               <xsl:variable name="this-css" as="xs:string?" select="tan:common-start-or-end-string(., $common-so-far, $find-common-start)"/>
               
               <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'Common start-or-end-string iteration ' || position()"/>
                  <xsl:message select="'String a: ' || $common-so-far"/>
                  <xsl:message select="'String b: ' || ."/>
                  <xsl:message select="'New common start string: ' || $this-css"/>
               </xsl:if>
               
               <xsl:choose>
                  <xsl:when test="string-length($this-css) lt 1">
                     <xsl:sequence select="$this-css"/>
                     <xsl:break/>
                  </xsl:when>
                  <xsl:when test="(position() = ($string-count - 1))">
                     <xsl:sequence select="$this-css"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:next-iteration>
                        <xsl:with-param name="common-so-far" select="$this-css"/>
                     </xsl:next-iteration>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:iterate>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:common-start-or-end-string" as="xs:string?" visibility="public">
      <!-- Input: two strings; a boolean -->
      <!-- Output: the longest common start (param 2 is true) or end (param 2 is false) portion of the two strings. -->
      <!--kw: strings -->
      <xsl:param name="string-a" as="xs:string?"/>
      <xsl:param name="string-b" as="xs:string?"/>
      <xsl:param name="find-common-start" as="xs:boolean"/>
      
      <!-- Two methods are being tried, one using a binary search method to find the common string, and another
         that proceeds block by block. -->
      <xsl:variable name="try-binary-search" as="xs:boolean" select="false()"/>
      
      <!-- blocks of 100 slightly outperformed blocks of 10 or 1000 -->
      <xsl:variable name="block-size" as="xs:integer" select="100"/>
      
      <xsl:variable name="string-a-length" as="xs:integer" select="string-length($string-a)"/>
      <xsl:variable name="string-b-length" as="xs:integer" select="string-length($string-b)"/>
      <xsl:variable name="min-string-length" as="xs:integer" select="min(($string-a-length, $string-b-length))"/>
      
      <xsl:choose>
         <!-- Weed out tiny conditions -->
         <xsl:when test="$min-string-length eq 0"/>
         <xsl:when test="$min-string-length eq 1">
            <xsl:choose>
               <xsl:when test="$string-a-length eq 1 and $find-common-start">
                  <xsl:if test="starts-with($string-b, $string-a)">
                     <xsl:sequence select="$string-a"/>
                  </xsl:if>
               </xsl:when>
               <xsl:when test="$string-a-length eq 1">
                  <xsl:if test="ends-with($string-b, $string-a)">
                     <xsl:sequence select="$string-a"/>
                  </xsl:if>
               </xsl:when>
               <xsl:when test="$find-common-start">
                  <xsl:if test="starts-with($string-a, $string-b)">
                     <xsl:sequence select="$string-b"/>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:if test="ends-with($string-a, $string-b)">
                     <xsl:sequence select="$string-b"/>
                  </xsl:if>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <!-- In this case, both a and b are two characters or longer -->
            <xsl:variable name="number-of-blocks" as="xs:integer" select="$min-string-length idiv $block-size"/>
            <xsl:variable name="binary-val" as="xs:integer"
               select="tan:log2($min-string-length) => xs:integer()"/>
            <xsl:variable name="binary-progression" as="xs:integer+" select="
                  for $i in (0 to $binary-val)
                  return
                     xs:integer(math:pow(2, $i))"/>
            
            <xsl:variable name="commonality" as="xs:integer*">
               <xsl:choose>
                  <xsl:when test="$try-binary-search">
                     <xsl:iterate select="reverse($binary-progression)">
                        <!-- This iteration applies a binary search method to finding the first common substring -->
                        <xsl:param name="amount-matching" as="xs:integer" select="0"/>
                        <xsl:param name="last-step" as="xs:integer" select="0"/>
                        <xsl:param name="go-ahead" as="xs:boolean" select="true()"/>
                        
                        <xsl:on-completion select="$amount-matching"/>
                        
                        <xsl:variable name="this-step" as="xs:integer" select="
                              if ($go-ahead) then
                                 ($last-step + .)
                              else
                                 ($last-step - .)"/>
                        <xsl:variable name="substring-a" as="xs:string" select="
                              if ($find-common-start) then
                                 substring($string-a, 1, $this-step)
                              else
                                 substring($string-a, $string-a-length - $this-step + 1)"/>
                        <xsl:variable name="substring-b" as="xs:string" select="
                              if ($find-common-start) then
                                 substring($string-b, 1, $this-step)
                              else
                                 substring($string-b, $string-b-length - $this-step + 1)"/>
                        <xsl:variable name="is-match" as="xs:boolean" select="$substring-a eq $substring-b"/>
                        
                        <xsl:variable name="inner-diagnostics-on" as="xs:boolean" select="true()"/>
                        <xsl:if test="$inner-diagnostics-on">
                           <xsl:message select="'=== iteration ' || position()"/>
                           <xsl:message select="'last step: ' || $last-step"/>
                           <xsl:message select="'amount matching: ' || $amount-matching"/>
                           <xsl:message select="'go ahead? ', $go-ahead"/>
                           <xsl:message select="'current step: ' || ."/>
                           <xsl:message select="'this step: ' || $this-step"/>
                           <xsl:message select="
                                 'substring a: ' || (if ($find-common-start) then
                                    tan:ellipses($substring-a, 100)
                                 else
                                    tan:ellipses($substring-a, 0, 100))"/>
                           <xsl:message select="
                                 'substring b: ' || (if ($find-common-start) then
                                    tan:ellipses($substring-b, 100)
                                 else
                                    tan:ellipses($substring-b, 0, 100))"/>
                           <xsl:message select="'is match? ', $is-match"/>
                        </xsl:if>
                        
                        <xsl:next-iteration>
                           <xsl:with-param name="last-step" select="$this-step"/>
                           <xsl:with-param name="amount-matching" select="
                                 if ($is-match) then
                                    $this-step
                                 else
                                    $amount-matching"/>
                           <xsl:with-param name="go-ahead" select="$is-match"/>
                        </xsl:next-iteration>
                        
                     </xsl:iterate>
                  </xsl:when>
                  <xsl:otherwise>
                     
                     <xsl:iterate select="0 to $number-of-blocks">
                        <xsl:variable name="this-block" as="xs:integer" select="."/>
                        <xsl:variable name="substring-a" as="xs:string" select="
                              if ($find-common-start) then
                                 substring($string-a, (($this-block * $block-size) + 1), $block-size)
                              else
                                 substring($string-a, $string-a-length - (($this-block * $block-size) + 1), $block-size)"/>
                        <xsl:variable name="substring-b" as="xs:string" select="
                              if ($find-common-start) then
                                 substring($string-b, (($this-block * $block-size) + 1), $block-size)
                              else
                                 substring($string-b, $string-b-length - (($this-block * $block-size) + 1), $block-size)"/>
                        <xsl:variable name="is-match" as="xs:boolean" select="$substring-a eq $substring-b"/>
                        <xsl:variable name="a-codepoints" as="xs:integer*" select="
                              if ($find-common-start) then
                                 string-to-codepoints($substring-a)
                              else
                                 reverse(string-to-codepoints($substring-a))"/>
                        <xsl:variable name="b-codepoints" as="xs:integer*" select="
                              if ($find-common-start) then
                                 string-to-codepoints($substring-b)
                              else
                                 reverse(string-to-codepoints($substring-b))"/>
                        <xsl:variable name="second-best-substring-codepoints" as="xs:integer*">
                           <xsl:if test="not($is-match)">
                              <xsl:iterate select="$a-codepoints">
                                 <xsl:param name="codepoints-to-compare" select="$b-codepoints" as="xs:integer*"/>
                                 <xsl:variable name="this-a-point" as="xs:integer" select="."/>
                                 <xsl:variable name="this-b-point" as="xs:integer?"
                                    select="$codepoints-to-compare[1]"/>
                                 <xsl:variable name="next-b-codepoints" as="xs:integer*"
                                    select="tail($codepoints-to-compare)"/>
                                 <xsl:choose>
                                    <xsl:when
                                       test="not($this-a-point eq $this-b-point) or not(exists($codepoints-to-compare))">
                                       <xsl:break/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                       <xsl:sequence select="$this-a-point"/>
                                       <xsl:next-iteration>
                                          <xsl:with-param name="codepoints-to-compare"
                                             select="$next-b-codepoints"/>
                                       </xsl:next-iteration>
                                    </xsl:otherwise>
                                 </xsl:choose>
                              </xsl:iterate>
                           </xsl:if>
                        </xsl:variable>
                        
                        <xsl:choose>
                           <xsl:when test="not($is-match)">
                              <xsl:sequence select="$second-best-substring-codepoints"/>
                              <xsl:break/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:sequence select="$a-codepoints"/>
                              <xsl:next-iteration/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:iterate>
                  </xsl:otherwise>
               </xsl:choose>
               
            </xsl:variable>
            
            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Diagnostics on, tan:common-start-or-end-string()'"/>
               <xsl:message select="'Input string a: ' || tan:ellipses($string-a, 100, 100)"/>
               <xsl:message select="'Input string b: ' || tan:ellipses($string-b, 100, 100)"/>
               <xsl:message select="'Find common start?', $find-common-start"/>
               <xsl:choose>
                  <xsl:when test="$try-binary-search">
                     <xsl:message select="'Trying binary search approach; binary progression: ', $binary-progression"/>
                     <xsl:message select="
                           'Commonality: ' || (if ($find-common-start)
                           then
                              tan:ellipses(substring($string-a, 1, $commonality), 100)
                           else
                              tan:ellipses(substring($string-a, $string-a-length + 1 - $commonality), 0, 100))"
                     />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:message select="'Trying block approach; block size: ' || $block-size"/>
                     <xsl:message select="
                           'Commonality: ' || (if ($find-common-start) then
                              tan:ellipses(codepoints-to-string($commonality), 100)
                           else
                              tan:ellipses(codepoints-to-string(reverse($commonality)), 0, 100))"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:if>
            
            <xsl:choose>
               <xsl:when test="$find-common-start and $try-binary-search">
                  <xsl:value-of select="substring($string-a, 1, $commonality)"/>
               </xsl:when>
               <xsl:when test="$try-binary-search">
                  <xsl:value-of select="substring($string-a, $string-a-length + 1 - $commonality)"/>
               </xsl:when>
               <xsl:when test="$find-common-start">
                  <xsl:value-of select="codepoints-to-string($commonality)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="codepoints-to-string(reverse($commonality))"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
      
      
   </xsl:function>
   
   
   <xsl:function name="tan:text-join" as="xs:string?" visibility="public">
      <!-- one-parameter version of the full function below -->
      <xsl:param name="items" as="item()*"/>
      <xsl:sequence select="tan:text-join($items, false())"/>
   </xsl:function>
   
   <xsl:function name="tan:text-join" as="xs:string?" visibility="public">
      <!-- Input: any document fragment of a TAN class 1 body, whether raw or resolved -->
      <!-- Output: a single string that joins and normalizes the leaf div text according to TAN rules -->
      <!-- All special leaf-div-end characters will be stripped including the last -->
      <!-- Do not apply this function to class-1 files that have been expanded, because normalization will have already occurred. -->
      <!-- Do not apply this function to TEI elements within leaf divs. -->
      <!--kw: strings, nodes -->
      <xsl:param name="items" as="item()*"/>
      <xsl:param name="set-divs-on-new-line" as="xs:boolean"/>
      <xsl:variable name="results" as="element()">
         <results>
            <xsl:apply-templates select="$items" mode="tan:text-join">
               <xsl:with-param name="set-divs-on-new-line" tunnel="yes" select="$set-divs-on-new-line"/>
            </xsl:apply-templates>
         </results>
      </xsl:variable>
      <xsl:value-of select="string-join($results, '')"/>
   </xsl:function>
   
   <xsl:mode name="tan:text-join" on-no-match="shallow-skip"/>
   
   <xsl:template match="/tan:*/tan:expanded[1]" mode="tan:text-join">
      <xsl:message select="'The function tan:text-join() should not be applied to expanded TAN files, which have already been normalized. Simply join the text nodes with fn:string-join().'"/>
      <xsl:apply-templates select="*" mode="#current"/>
   </xsl:template>
   
   <xsl:template match="*:div[*:div]" mode="tan:text-join">
      <xsl:param name="set-divs-on-new-line" as="xs:boolean" tunnel="yes" select="false()"/>
      <xsl:if test="$set-divs-on-new-line">&#xa;</xsl:if>
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   <xsl:template match="*:div[not(*:div)]" mode="tan:text-join">
      <xsl:param name="set-divs-on-new-line" as="xs:boolean" tunnel="yes" select="false()"/>
      <xsl:variable name="nonspace-text-nodes" select="text()[matches(., '\S')]"/>
      <xsl:variable name="text-nodes-to-process" as="xs:string*">
         <xsl:choose>
            <xsl:when test="exists(tan:tok)">
               <xsl:sequence select="(tan:tok, tan:non-tok)/text()"/>
            </xsl:when>
            <xsl:when test="exists(tei:*)">
               <!-- TEI is ultimately a mixed-content model, so even space-only text nodes hanging
                  off leaf divs should be treated as a titular space, hence descendant or self, not 
                  just descendant text nodes. -->
               <xsl:value-of select="normalize-space(string-join(descendant-or-self::tei:*/text(), ''))"/>
            </xsl:when>
            <xsl:when test="exists($nonspace-text-nodes)">
               <xsl:sequence select="text()"/>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:if test="$set-divs-on-new-line">&#xa;</xsl:if>
      <xsl:value-of select="tan:normalize-div-text($text-nodes-to-process, true())"/>
   </xsl:template>
   
   
   <xsl:function name="tan:normalize-div-text" as="xs:string*" visibility="public">
      <!-- One-parameter version of the fuller one, below. -->
      <xsl:param name="single-leaf-div-text-nodes" as="xs:string*"/>
      <xsl:copy-of select="tan:normalize-div-text($single-leaf-div-text-nodes, false())"/>
   </xsl:function>
   
   <xsl:function name="tan:normalize-div-text" as="xs:string*" visibility="public">
      <!-- Input: any sequence of strings, presumed to be text nodes of a single leaf div; a boolean indicating whether special div-end characters should be retained or not -->
      <!-- Output: the same sequence, normalized according to TAN rules. Each item in the sequence is space normalized and then if its end matches one of the special div-end characters, ZWJ U+200D or SOFT HYPHEN U+AD, the character is removed; otherwise a space is added at the end. Zero-length strings are skipped. -->
      <!-- This function is designed specifically for TAN's commitment to nonmixed content. That is, every TAN element contains either elements or non-space text but not both, which also means that space-only text nodes are effectively ignored. It is assumed that every TAN element is followed by a notional space. -->
      <!-- The second parameter is important, because output will be used to normalize and repopulate leaf <div>s (where special div-end characters should be retained) or to concatenate leaf <div> text (where those characters should be deleted) -->
      <!--kw: strings -->
      <xsl:param name="single-leaf-div-text-nodes" as="xs:string*"/>
      <xsl:param name="remove-special-div-end-chars" as="xs:boolean"/>
      <xsl:variable name="nodes-joined-and-normalized" select="normalize-space(string-join($single-leaf-div-text-nodes, ''))"/>
      <xsl:variable name="nodes-end-with-special-div-chars" select="matches($nodes-joined-and-normalized, $tan:special-end-div-chars-regex)"/>
      <xsl:variable name="join-end-normalized" as="xs:string*">
         <xsl:choose>
            <xsl:when test="$nodes-end-with-special-div-chars and $remove-special-div-end-chars">
               <xsl:value-of select="replace($nodes-joined-and-normalized, $tan:special-end-div-chars-regex, '')"/>
            </xsl:when>
            <xsl:when test="$nodes-end-with-special-div-chars">
               <xsl:value-of select="replace($nodes-joined-and-normalized, $tan:special-end-div-chars-regex, '$1')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$nodes-joined-and-normalized || ' '"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="results" select="string-join($join-end-normalized, '')"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:normalize-div-text()'"/>
         <xsl:message select="'remove special div-end characters? :', $remove-special-div-end-chars"/>
         <xsl:message select="'nodes joined and normalized ' || string-length($nodes-joined-and-normalized) || ': ', $nodes-joined-and-normalized"/>
         <xsl:message select="'results ' || string-length($results) || ': ', $results"/>
      </xsl:if>
      
      <xsl:sequence select="$results"/>
   </xsl:function>
   
   <xsl:function name="tan:tokenize-div" as="item()*" visibility="public">
      <!-- Input: any items, a <token-definition> -->
      <!-- Output: the items with <div>s in tokenized form -->
      <!--kw: strings -->
      <xsl:param name="input" as="item()*"/>
      <xsl:param name="token-definitions" as="element(tan:token-definition)"/>
      <xsl:apply-templates select="$input" mode="tan:tokenize-div">
         <xsl:with-param name="token-definitions" select="$token-definitions" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:tokenize-div" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:div[not((tan:div, tan:tok))]/text()" mode="tan:tokenize-div">
      <xsl:param name="token-definition" as="element()?" tunnel="yes"/>
      <xsl:param name="add-q-attr" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="add-pos-attr" as="xs:boolean?" tunnel="yes"/>
      <xsl:param name="count-toks" as="xs:boolean?" tunnel="yes" select="true()"/>
      <xsl:variable name="this-text" select="tan:normalize-div-text(., true())"/>
      <xsl:variable name="prev-leaf" select="preceding::tan:div[not(tan:div)][1]"/>
      <xsl:variable name="first-tok-is-fragment"
         select="matches($prev-leaf, $tan:special-end-div-chars-regex)"/>
      <xsl:variable name="this-tokenized" as="element()*">
         <xsl:copy-of select="tan:tokenize-text($this-text, $token-definition, $count-toks, $add-q-attr = true(), $add-pos-attr)"/>
      </xsl:variable>
      <xsl:variable name="last-tok" select="$this-tokenized/tan:tok[last()]"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for template mode tokenize-div'"/>
         <xsl:message select="'token definition: ', $token-definition"/>
         <xsl:message select="'first token is fragment?', $first-tok-is-fragment"/>
         <xsl:message select="'add @q?', $add-q-attr"/>
         <xsl:message select="'add @pos?', $add-pos-attr"/>
      </xsl:if>
      <xsl:if test="not($first-tok-is-fragment)">
         <xsl:copy-of select="$this-tokenized/*[xs:integer(@n) = 1]"/>
      </xsl:if>
      <xsl:choose>
         <xsl:when test="matches(., $tan:special-end-div-chars-regex)">
            <!-- get next token -->
            <xsl:variable name="next-leaf" select="following::tan:div[not(tan:div)][1]"/>
            <xsl:variable name="next-leaf-tokenized"
               select="tan:tokenize-text($next-leaf/text(), $token-definition, true())"/>
            <xsl:variable name="next-leaf-fragment"
               select="$next-leaf-tokenized/*[xs:integer(@n) = 1]"/>
            <xsl:copy-of select="$this-tokenized/*[xs:integer(@n) gt 1][not(@n = $last-tok/@n)]"/>
            <xsl:for-each-group select="($this-tokenized/*[@n = $last-tok/@n], $next-leaf-fragment)"
               group-adjacent="name(.)">
               <xsl:element name="{current-grouping-key()}">
                  <xsl:copy-of select="current-group()[1]/@*"/>
                  <xsl:value-of select="string-join(current-group(), '')"/>
               </xsl:element>
            </xsl:for-each-group>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$this-tokenized/*[xs:integer(@n) gt 1]"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   <xsl:function name="tan:substring-before" as="xs:string" visibility="public">
      <!-- Input: two strings; a boolean -->
      <!-- Output: if the last parameter is true:
            the substring of the value of $arg1 that precedes in the value of $arg1 the first occurrence of the value $arg2 .
         if false: the last occurrence -->
      <!-- This function provides extra flexibility not available in fn:substring-before() -->
      <!--kw: strings -->
      <xsl:param name="arg1" as="xs:string?"/>
      <xsl:param name="arg2" as="xs:string?"/>
      <xsl:param name="return-first-match" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when test="$return-first-match">
            <xsl:sequence select="substring-before($arg1, $arg2)"></xsl:sequence>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="string-join(analyze-string($arg1, $arg2, 'q')/*:match[last()]/preceding-sibling::*)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="tan:substring-after" as="xs:string" visibility="public">
      <!-- Input: two strings; a boolean -->
      <!-- Output: if the last parameter is true:
            the substring of the value of $arg1 that follows in the value of $arg1 the first occurrence of the value of $arg2 .
         if false: the last occurrence -->
      <!-- This function provides extra flexibility not available in fn:substring-before() -->
      <!--kw: strings -->
      <xsl:param name="arg1" as="xs:string?"/>
      <xsl:param name="arg2" as="xs:string?"/>
      <xsl:param name="return-first-match" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when test="$return-first-match">
            <xsl:sequence select="substring-after($arg1, $arg2)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="string-join(analyze-string($arg1, $arg2, 'q')/*:match[last()]/following-sibling::*)"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:contains-only-once" as="xs:boolean" visibility="public">
      <!-- Input: any two strings -->
      <!-- Output: true() if and only if the first string contains the second, only one time -->
      <!-- This function was introduced to support tan:diff(), to ensure that unique common tokens
         between two strings are not substrings of any other unique common tokens. -->
      <!--kw: strings -->
      <xsl:param name="arg1" as="xs:string?"/>
      <xsl:param name="arg2" as="xs:string?"/>
      <xsl:sequence select="contains($arg1, $arg2) and not(contains(substring-after($arg1, $arg2), $arg2))"/>
   </xsl:function>
   
   
   

</xsl:stylesheet>
