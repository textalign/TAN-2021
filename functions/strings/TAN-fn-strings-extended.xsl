<?xml version="1.1"?>
<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   version="3.0">

   <!-- TAN Function Library extended string functions. -->
   
   <xsl:function name="tan:segment-string" as="xs:string*" visibility="public">
      <!-- 2-arity version of the more complete function, below -->
      <xsl:param name="string-to-segment" as="xs:string?"/>
      <xsl:param name="segment-portions" as="xs:decimal*"/>
      <xsl:sequence select="tan:segment-string($string-to-segment, $segment-portions, '\s+')"/>
   </xsl:function>
   
   <xsl:function name="tan:segment-string" as="xs:string*" visibility="public">
      <!-- Input: a string, a sequence of doubles from 0 through 1, a regular expression -->
      <!-- Output: the string divided into segments proportionate to the doubles, with divisions allowed only by the regular expression -->
      <!--kw: strings, sequences -->
      <xsl:param name="string-to-segment" as="xs:string?"/>
      <xsl:param name="segment-portions" as="xs:decimal*"/>
      <xsl:param name="break-at-regex" as="xs:string"/>
      <xsl:variable name="snap-marker" as="xs:string" select="
            if (string-length($break-at-regex) lt 1) then
               '\s+'
            else
               $break-at-regex"/>
      <xsl:variable name="input-length" as="xs:integer" select="string-length($string-to-segment)"/>
      <xsl:variable name="new-content-tokenized" as="xs:string*"
         select="tan:chop-string($string-to-segment, $snap-marker)"/>
      
      <xsl:choose>
         <xsl:when test="$input-length lt 1"/>
         <xsl:otherwise>
            <xsl:variable name="new-content-map" as="map(xs:decimal, xs:string)">
               <xsl:map>
                  <xsl:iterate select="$new-content-tokenized">
                     <xsl:param name="last-pos" as="xs:integer" select="0"/>
                     <xsl:variable name="this-length" select="string-length(.)" as="xs:integer"/>
                     <xsl:variable name="new-pos" as="xs:integer" select="$last-pos + $this-length"/>
                     <xsl:map-entry key="($last-pos + 1) div $input-length" select="."/>
                     <xsl:next-iteration>
                        <xsl:with-param name="last-pos" select="$new-pos" as="xs:integer"/>
                     </xsl:next-iteration>
                  </xsl:iterate>
               </xsl:map>
            </xsl:variable>
            <xsl:variable name="new-content-keys" select="map:keys($new-content-map)" as="xs:decimal+"/>
            <xsl:iterate select="sort(distinct-values(($segment-portions, 1)))">
               <xsl:param name="prev-portion" as="xs:decimal" select="-1"/>
               <xsl:variable name="this-portion" select="."/>
               <xsl:variable name="these-keys" select="$new-content-keys[. gt $prev-portion][. le $this-portion]"/>
               <xsl:choose>
                  <xsl:when test=". le 0 or . gt 1"/>
                  <xsl:otherwise>
                     <xsl:value-of select="
                        string-join((for $i in sort($these-keys)
                        return
                        $new-content-map($i)))"/>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:next-iteration>
                  <xsl:with-param name="prev-portion" select="."/>
               </xsl:next-iteration>
            </xsl:iterate>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   <xsl:function name="tan:namespace" as="xs:string*" visibility="public">
      <!-- Input: any strings representing a namespace prefix or uri -->
      <!-- Output: the corresponding prefix or uri whenever a match is found in the global variable -->
      <!--kw: strings, namespaces -->
      <xsl:param name="prefix-or-uri" as="xs:string*"/>
      <xsl:for-each select="$prefix-or-uri">
         <xsl:variable name="this-string" select="."/>
         <xsl:sequence
            select="$tan:namespaces-and-prefixes/*[@* = $this-string]/(@*[not(. = $this-string)])[1]"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:glob-to-regex" as="xs:string*" visibility="public">
      <!-- Input: any strings that follow a glob-like syntax -->
      <!-- Output: the strings converted to regular expressions -->
      <!--kw: strings, filenames -->
      <xsl:param name="globs" as="xs:string*"/>
      <xsl:for-each select="$globs">
         <!-- escape special regex characters that aren't special glob characters -->
         <xsl:variable name="pass-1" select="replace(., '([\.\\\|\^\$\+\{\}\(\)])', '\\$1')"/>
         <!-- convert glob * -->
         <xsl:variable name="pass-2" select="replace($pass-1, '\*', '.*')"/>
         <!-- convert glob ? -->
         <xsl:variable name="pass-3" select="replace($pass-2, '\?', '.')"/>
         <!-- make sure the results match either an entire filename or an entire path -->
         <xsl:value-of select="'^' || $pass-3 || '$|/' || $pass-3 || '$'"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:acronym" as="xs:string?" visibility="public">
      <!-- Input: any strings -->
      <!-- Output: the acronym of those strings (initial letters joined without spaces) -->
      <!-- Example: "The Cat in the Hat" - > "TCitH" -->
      <!--kw: strings -->
      <xsl:param name="string-input" as="xs:string?"/>
      <xsl:variable name="initials" as="xs:string*" select="
            for $i in tokenize($string-input, '\s+')
            return
               substring($i, 1, 1)"/>
      <xsl:value-of select="string-join($initials, '')"/>
   </xsl:function>
   
   
   <xsl:function name="tan:batch-replacement-messages" as="xs:string?" visibility="private">
      <!-- Input: any batch replacement element -->
      <!-- Output: a string explaining what it does -->
      <!-- This function is useful for reporting back to users in a readable format what 
         changes are rendered -->
      <xsl:param name="batch-replace-element" as="element()?"/>
      <xsl:variable name="message-components" as="xs:string*">
         <xsl:if
            test="exists($batch-replace-element/@message) or exists($batch-replace-element/@flags)">
            <xsl:if test="exists($batch-replace-element/@message)">
               <xsl:value-of select="$batch-replace-element/@message"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 's')">
               <xsl:value-of select="' (dot-all mode)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'm')">
               <xsl:value-of select="' (multi-line mode)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'i')">
               <xsl:value-of select="' (case insensitive)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'x')">
               <xsl:value-of select="' (ignore regex whitespaces)'"/>
            </xsl:if>
            <xsl:if test="contains($batch-replace-element/@flags, 'q')">
               <xsl:value-of select="' (ignore special characters)'"/>
            </xsl:if>
            <xsl:value-of select="': '"/>
         </xsl:if>
         <xsl:value-of
            select="'PATTERN: ' || $batch-replace-element/@pattern || '  REPLACEMENT: ' || $batch-replace-element/@replacement"/>
         
      </xsl:variable>
      <xsl:value-of select="string-join($message-components)"/>
   </xsl:function>
   
   
   <xsl:template name="tan:regex-group-count" as="xs:integer?" visibility="public">
      <!-- Input: perhaps a parameter specifying how many blank entries are permitted 
         before stopping the iteration. -->
      <!-- Output: the number of groups of regular expressions in the current context. -->
      <!-- Most often in the TAN function library, a function is preferred over a named template.
         In this case, we have a named template, because the function severs the context of 
         regex-groups() -->
      <!-- kw: strings, regular expressions -->
      <xsl:param name="number-of-blank-entries-ceiling" as="xs:integer" select="10"/>
      <xsl:iterate select="1 to 100">
         <xsl:param name="number-of-blanks-so-far" as="xs:integer" select="0"/>
         <!--<xsl:message select="'iteration ' || string(.) || ' regex group: [' || regex-group(.) || ']'"/>-->
         <xsl:variable name="is-blank" as="xs:boolean" select="string-length(regex-group(.)) eq 0"/>
         <xsl:choose>
            <xsl:when test="$is-blank and ($number-of-blanks-so-far eq $number-of-blank-entries-ceiling)">
               <xsl:sequence select=". - ($number-of-blanks-so-far + 1)"/>
               <xsl:break/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:next-iteration>
                  <xsl:with-param name="number-of-blanks-so-far" select="
                        if ($is-blank) then
                           ($number-of-blanks-so-far + 1)
                        else
                           0"/>
               </xsl:next-iteration>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:iterate>
   </xsl:template>
   
   
   
   
   <xsl:function name="tan:batch-replace-advanced" as="item()*" visibility="public">
      <!-- Input: any items; a sequence of elements:
         <[ANY NAME] pattern="" [flags=""] [message=""] [exclude-pattern=""]>[ANY CONTENT]</[ANY NAME]> -->
      <!-- Output: a sequence of items, with instances of @pattern replaced by the content of the elements -->
      <!-- This is a more advanced form of tan:batch-replace(), in that it allows text to be replaced by elements.
         It also allows for exclusion of matches via @exclude-pattern. That is, if a span of text matches that value,
         the match will be ignored. -->
      <!-- The function was devised to convert raw text into TAN-T. Textual references can be turned into <div n=""/> anchors, and the result can then be changed into a traditional hierarchy. -->
      <!--kw: strings, tree manipulation, nodes -->
      <xsl:param name="items-with-strings" as="item()*"/>
      <xsl:param name="replace-elements" as="element()*"/>
      
      <xsl:variable name="replace-elements-of-interest" as="element()*"
         select="$replace-elements[@pattern]"/>
      
      <xsl:variable name="replace-elements-ignored" as="element()*"
         select="$replace-elements except $replace-elements-of-interest"/>
      
      <xsl:if test="exists($replace-elements-ignored)">
         <xsl:message
            select="string(count($replace-elements-ignored)) || ' replace elements are ignored, because they are missing @pattern.'"
         />
      </xsl:if>
      <xsl:choose>
         <xsl:when test="not(exists($replace-elements-of-interest))">
            <xsl:sequence select="$items-with-strings"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:iterate select="$replace-elements-of-interest">
               <xsl:param name="results-so-far" as="item()*" select="$items-with-strings"/>
               
               <xsl:on-completion select="$results-so-far"/>
               
               <xsl:variable name="new-items" as="item()*">
                  <xsl:apply-templates select="$results-so-far" mode="tan:batch-replace-advanced-pass-1">
                     <xsl:with-param name="replace-element" tunnel="yes" select="."/>
                  </xsl:apply-templates>
               </xsl:variable>
               
               <xsl:next-iteration>
                  <xsl:with-param name="results-so-far" as="item()*" select="$new-items"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:mode name="tan:batch-replace-advanced-pass-1" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:batch-replace-advanced-pass-1">
      <xsl:param name="replace-element" tunnel="yes" as="element()"/>
      
      <xsl:variable name="exclude-pattern" as="xs:string?" select="$replace-element/@exclude-pattern"/>
      
      <xsl:analyze-string select="." regex="{$replace-element/@pattern}" flags="{$replace-element/@flags}">
         <xsl:matching-substring>
            <xsl:choose>
               <xsl:when
                  test="string-length($exclude-pattern) gt 0 and tan:matches(., $exclude-pattern, ($replace-element/@flags, '')[1])">
                  <xsl:value-of select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="regex-group-count" as="xs:integer">
                     <xsl:call-template name="tan:regex-group-count"/>
                  </xsl:variable>
                  
                  <xsl:apply-templates select="$replace-element/node()" mode="tan:batch-replace-advanced-pass-2">
                     <xsl:with-param name="regex-group-count" tunnel="yes" select="$regex-group-count"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:matching-substring>
         <xsl:non-matching-substring>
            <xsl:value-of select="."/>
         </xsl:non-matching-substring>
      </xsl:analyze-string>
      
   </xsl:template>
   <xsl:template match=".[. instance of xs:string]" mode="tan:batch-replace-advanced-pass-1">
      <xsl:param name="replace-element" tunnel="yes" as="element()"/>
      
      <xsl:variable name="exclude-pattern" as="xs:string?" select="$replace-element/@exclude-pattern"/>
      
      <xsl:analyze-string select="." regex="{$replace-element/@pattern}" flags="{$replace-element/@flags}">
         <xsl:matching-substring>
            <xsl:choose>
               <xsl:when
                  test="string-length($exclude-pattern) gt 0 and tan:matches(., $exclude-pattern, ($replace-element/@flags, '')[1])">
                  <xsl:value-of select="."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="regex-group-count" as="xs:integer">
                     <xsl:call-template name="tan:regex-group-count"/>
                  </xsl:variable>
                  
                  <xsl:apply-templates select="$replace-element/node()" mode="tan:batch-replace-advanced-pass-2">
                     <xsl:with-param name="regex-group-count" tunnel="yes" select="$regex-group-count"/>
                  </xsl:apply-templates>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:matching-substring>
         <xsl:non-matching-substring>
            <xsl:value-of select="."/>
         </xsl:non-matching-substring>
      </xsl:analyze-string>
      
   </xsl:template>
   
   
   <xsl:mode name="tan:batch-replace-advanced-pass-2" 
      on-no-match="shallow-copy"/>
   
   <xsl:template match="@*" mode="tan:batch-replace-advanced-pass-2">
      <xsl:param name="regex-group-count" as="xs:integer" tunnel="yes">
         <xsl:call-template name="tan:regex-group-count"/>
      </xsl:param>
      
      <!-- Note, regex-group(0) is first, regex-group(1) is second, etc. -->
      <xsl:variable name="regex-groups" as="xs:string*" select="
            for $i in (0 to $regex-group-count)
            return
               regex-group($i)"/>
      <xsl:variable name="new-value" as="xs:string*">
         <xsl:analyze-string select="." regex="\$(\d+)">
            <xsl:matching-substring>
               <xsl:variable name="this-regex-no" select="number(regex-group(1))"/>
               <xsl:value-of select="$regex-groups[$this-regex-no + 1]"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="name(.) eq 'message'">
            <xsl:message select="string-join($new-value, '')"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:attribute name="{name(.)}" select="string-join($new-value, '')"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:template>
   
   <xsl:template match="text()" mode="tan:batch-replace-advanced-pass-2">
      <xsl:param name="regex-group-count" as="xs:integer" tunnel="yes">
         <xsl:call-template name="tan:regex-group-count"/>
      </xsl:param>

      <!-- Note, regex-group(0) is first, regex-group(1) is second, etc. -->
      <xsl:variable name="regex-groups" as="xs:string*" select="
            for $i in (0 to $regex-group-count)
            return
               regex-group($i)"/>
      
      <xsl:choose>
         <!-- omit whitespace text -->
         <xsl:when test="not(matches(., '\S'))"/>
         <xsl:otherwise>
            <xsl:analyze-string select="." regex="\$(\d+)">
               <xsl:matching-substring>
                  <xsl:variable name="this-regex-no" select="number(regex-group(1))"/>
                  <xsl:value-of select="$regex-groups[$this-regex-no + 1]"/>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="."/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   <xsl:function name="tan:normalize-unicode" as="item()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the same items, but with all unicode normalized -->
      <!-- This is a surrogate to fn:normalize-unicode(), extending functionality to any item -->
      <!--kw: strings, tree manipulation -->
      <xsl:param name="input" as="item()*"/>
      <xsl:apply-templates select="$input" mode="tan:normalize-unicode"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:normalize-unicode" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:normalize-unicode">
      <xsl:value-of select="normalize-unicode(.)"/>
   </xsl:template>
   <xsl:template match=".[. instance of xs:string]" mode="tan:normalize-unicode">
      <xsl:value-of select="normalize-unicode(.)"/>
   </xsl:template>
   
   
   <xsl:variable name="tan:english-prepositions" as="xs:string+"
      select="('aboard', 'about', 'above', 'across', 'after', 'against', 'along', 'amid', 'among', 'anti', 'around', 'as', 'at', 'before', 'behind', 'below', 'beneath', 'beside', 'besides', 'between', 'beyond', 'but', 'by', 'concerning', 'considering', 'despite', 'down', 'during', 'except', 'excepting', 'excluding', 'following', 'for', 'from', 'in', 'inside', 'into', 'like', 'minus', 'near', 'of', 'off', 'on', 'onto', 'opposite', 'outside', 'over', 'past', 'per', 'plus', 'regarding', 'round', 'save', 'since', 'than', 'through', 'to', 'toward', 'towards', 'under', 'underneath', 'unlike', 'until', 'up', 'upon', 'versus', 'via', 'with', 'within', 'without')"
   />
   <xsl:variable name="tan:english-articles" as="xs:string+" select="('a', 'the')"/>
   
   <xsl:function name="tan:title-case" as="xs:string*" visibility="public">
      <!-- Input: a sequence of strings -->
      <!-- Output: each string set in title case, following the conventions of English (one of the only 
         languages that bother with title-case) -->
      <!-- According to Chicago rules of title casing, the first and last words are always capitalized, 
         and interior words are capitalized unless they are a preposition or article -->
      <!--kw: strings -->
      <xsl:param name="string-to-convert" as="xs:string*"/>
      <xsl:for-each select="$string-to-convert">
         <xsl:variable name="pass-1" as="element()">
            <phrase>
               <xsl:analyze-string select="." regex="\w+">
                  <xsl:matching-substring>
                     <word>
                        <xsl:choose>
                           <xsl:when test=". = ($tan:english-prepositions, $tan:english-articles)">
                              <xsl:value-of select="lower-case(.)"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:value-of select="tan:initial-upper-case(.)"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </word>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <non-word>
                        <xsl:value-of select="."/>
                     </non-word>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </phrase>
         </xsl:variable>
         <xsl:variable name="pass-2" as="element()">
            <xsl:apply-templates select="$pass-1" mode="tan:title-case"/>
         </xsl:variable>
         <xsl:value-of select="string-join($pass-2/*, '')"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:mode name="tan:title-case" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:word[1] | tan:word[last()]" mode="tan:title-case">
      <xsl:copy>
         <xsl:value-of select="tan:initial-upper-case(.)"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:function name="tan:initial-upper-case" as="xs:string*" visibility="public">
      <!-- Input: any strings -->
      <!-- Output: each string with the initial letters capitalized and the rest set lower-case -->
      <!--kw: strings -->
      <xsl:param name="strings" as="xs:string*"/>
      <xsl:variable name="non-letter-regex">\P{L}</xsl:variable>
      <xsl:for-each select="$strings">
         <xsl:variable name="pass-1" as="xs:string*">
            <xsl:analyze-string select="." regex="^{$non-letter-regex}+">
               <xsl:matching-substring>
                  <xsl:value-of select="."/>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:value-of select="upper-case(substring(., 1, 1)) || lower-case(substring(., 2))"/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </xsl:variable>
         <xsl:value-of select="string-join($pass-1)"/>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:commas-and-ands" as="xs:string?" visibility="public">
      <!-- One-parameter version of the full one below -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:value-of select="tan:commas-and-ands($input-strings, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:commas-and-ands" as="xs:string?" visibility="public">
      <!-- Input: sequences of strings -->
      <!-- Output: the strings joined together with , and 'and' -->
      <!--kw: strings -->
      <xsl:param name="input-strings" as="xs:string*"/>
      <xsl:param name="oxford-comma" as="xs:boolean"/>
      <xsl:variable name="input-string-count" select="count($input-strings)"/>
      <xsl:variable name="results" as="xs:string*">
         <xsl:for-each select="$input-strings">
            <xsl:variable name="this-pos" select="position()"/>
            <xsl:value-of select="."/>
            <xsl:if test="$input-string-count gt 2">
               <xsl:choose>
                  <xsl:when test="$this-pos lt ($input-string-count - 1)">,</xsl:when>
                  <xsl:when test="$this-pos = ($input-string-count - 1) and $oxford-comma">,</xsl:when>
               </xsl:choose>
            </xsl:if>
            <xsl:if test="$this-pos lt $input-string-count">
               <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="$input-string-count gt 1 and $this-pos = ($input-string-count - 1)"
               >and </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="string-join($results)"/>
   </xsl:function>
   
   <xsl:function name="tan:satisfies-regex" as="xs:boolean" visibility="public">
      <!-- 2-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, (), ())"
      />
   </xsl:function>
   
   <xsl:function name="tan:filename-satisfies-regex" as="xs:boolean" visibility="private">
      <!-- 2-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, (), 'i')"
      />
   </xsl:function>
   
   <xsl:function name="tan:satisfies-regexes" as="xs:boolean" visibility="public">
      <!-- 3-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:param name="string-must-not-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, $string-must-not-match-regex, ())"
      />
   </xsl:function>
   
   <xsl:function name="tan:filename-satisfies-regexes" as="xs:boolean" visibility="private">
      <!-- 3-param version of fuller one, below -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:param name="string-must-not-match-regex" as="xs:string?"/>
      <xsl:sequence
         select="tan:satisfies-regexes($string-to-test, $string-must-match-regex, $string-must-not-match-regex, 'i')"
      />
   </xsl:function>
   
   <xsl:function name="tan:satisfies-regexes" as="xs:boolean" visibility="public">
      <!-- Input: a string value; an optional regex the string must match; an optional regex the string must not match -->
      <!-- Output: whether the string satisfies the two regex conditions; if either regex is empty, true will be returned -->
      <!-- If the input string is less than zero length, the function returns false -->
      <!--kw: strings, regular expressions -->
      <xsl:param name="string-to-test" as="xs:string?"/>
      <xsl:param name="string-must-match-regex" as="xs:string?"/>
      <xsl:param name="string-must-not-match-regex" as="xs:string?"/>
      <xsl:param name="flags" as="xs:string?"/>
      <xsl:variable name="test-1" as="xs:boolean">
         <xsl:choose>
            <xsl:when test="string-length($string-to-test) lt 1">
               <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when
               test="not(exists($string-must-match-regex)) or string-length($string-must-match-regex) lt 1">
               <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="tan:matches($string-to-test, $string-must-match-regex, $flags)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="test-2" as="xs:boolean">
         <xsl:choose>
            <xsl:when test="string-length($string-to-test) lt 1">
               <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when
               test="not(exists($string-must-not-match-regex)) or string-length($string-must-not-match-regex) lt 1">
               <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of
                  select="not(tan:matches($string-to-test, $string-must-not-match-regex, $flags))"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="$test-1 and $test-2"/>
   </xsl:function>
   
   
   <xsl:function name="tan:reverse-string" as="xs:string?" visibility="public">
      <!-- Input: any string -->
      <!-- Output: the string in reverse order -->
      <!--kw: strings -->
      <xsl:param name="string-to-reverse" as="xs:string?"/>
      <xsl:sequence select="codepoints-to-string(reverse(string-to-codepoints($string-to-reverse)))"/>
   </xsl:function>
   
   
   
   <xsl:function name="tan:possible-bibliography-id" as="xs:string" visibility="private">
      <!-- Input: a string with a bibliographic entry -->
      <!-- Output: unique values of the two longest words and the first numeral that looks like a date -->
      <!-- When working with bibliographical data, it is next to impossible to rely upon an exact match to tell whether two citations refer to the same item. -->
      <!-- Many times, however, the longest word or two, plus the four-digit date, are good ways to try to find matches. -->
      <xsl:param name="bibl-cit" as="xs:string"/>
      <xsl:variable name="this-citation-dates" as="xs:string*">
         <xsl:analyze-string select="$bibl-cit" regex="^\d\d\d\d\D|\D\d\d\d\d\D|\D\d\d\d\d$">
            <xsl:matching-substring>
               <xsl:value-of select="replace(., '\D', '')"/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:variable name="this-citation-longest-words" as="xs:string*">
         <xsl:for-each select="tokenize($bibl-cit, '\W+')">
            <xsl:sort select="string-length(.)" order="descending"/>
            <xsl:if test="not(lower-case(.) = $tan:bibliography-words-to-ignore)">
               <xsl:value-of select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:value-of
         select="string-join(distinct-values(($this-citation-longest-words[position() lt 3], $this-citation-dates[1])), ' ')"
      />
   </xsl:function>
   
   <xsl:variable name="tan:control-chars" as="xs:string">&#x1;&#x2;&#x3;&#x4;&#x5;&#x6;&#x7;&#x8;&#xb;&#xc;&#xd;&#xe;&#xf;&#x10;&#x11;&#x12;&#x13;&#x14;&#x15;&#x16;&#x17;&#x18;&#x19;&#x1a;&#x1b;&#x1c;&#x1d;&#x1e;&#x1f;&#x7f;</xsl:variable>
   <xsl:variable name="tan:control-pictures" as="xs:string">␁␂␃␄␅␆␇␈␋␌␍␎␏␐␑␒␓␔␕␖␗␘␙␚␛␜␝␞␟␡</xsl:variable>
   
   <xsl:function name="tan:controls-to-pictures" as="item()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the items, but with any control characters changed to control pictures (U+2400 onward) -->
      <!-- This function excludes &#x0; &#x9; &#xa; -->
      <xsl:param name="items-to-change" as="item()*"/>
      <xsl:apply-templates select="$items-to-change" mode="tan:controls-to-pictures"/>
   </xsl:function>
   
   <xsl:mode name="tan:controls-to-pictures" on-no-match="shallow-copy"/>
   
   <xsl:template match=".[. instance of xs:string]" mode="tan:controls-to-pictures">
      <xsl:value-of select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   <xsl:template match="text()" mode="tan:controls-to-pictures">
      <xsl:value-of select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   <xsl:template match="comment()" mode="tan:controls-to-pictures">
      <xsl:comment><xsl:value-of select="translate(., $tan:control-chars, $tan:control-pictures)"/></xsl:comment>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="tan:controls-to-pictures">
      <xsl:processing-instruction name="{name(.)}" select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   <xsl:template match="@*" mode="tan:controls-to-pictures">
      <xsl:attribute name="{name(.)}" select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   
   <xsl:function name="tan:pictures-to-controls" as="item()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the items, but with any control pictures (U+2400) changed to control characters -->
      <!-- This function excludes &#x0; &#x9; &#xa; &#xd; -->
      <xsl:param name="items-to-change" as="item()*"/>
      <xsl:apply-templates select="$items-to-change" mode="tan:pictures-to-controls"/>
   </xsl:function>
   
   <xsl:mode name="tan:pictures-to-controls" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:pictures-to-controls">
      <xsl:value-of select="translate(., $tan:control-pictures, $tan:control-chars)"/>
   </xsl:template>
   <xsl:template match="comment()" mode="tan:pictures-to-controls">
      <xsl:comment><xsl:value-of select="translate(., $tan:control-pictures, $tan:control-chars)"/></xsl:comment>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="tan:pictures-to-controls">
      <xsl:processing-instruction name="{name(.)}" select="translate(., $tan:control-pictures, $tan:control-chars)"/>
   </xsl:template>
   <xsl:template match="@*" mode="tan:pictures-to-controls">
      <xsl:attribute name="{name(.)}" select="translate(., $tan:control-pictures, $tan:control-chars)"/>
   </xsl:template>
   
   

</xsl:stylesheet>
