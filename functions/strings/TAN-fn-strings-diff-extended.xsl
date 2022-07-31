<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended diff string functions. -->
   
   <!-- See also ../html/TAN-fn-html-diff-and-collate.xsl -->
   
   
   <!-- Summary of alterations, if any, that should be made to strings BEFORE tan:diff() 
      or tan:collate() are applied. -->
   <xsl:variable name="tan:diff-and-collate-input-batch-replacements" as="element()*">
      <xsl:if test="$tan:ignore-punctuation-differences">
         <xsl:sequence select="$tan:batch-replace-punctuation"/>
      </xsl:if>
      <xsl:if test="$tan:ignore-combining-marks">
         <xsl:sequence select="$tan:batch-replace-combining-marks"/>
      </xsl:if>
   </xsl:variable>
   
   
   
   <xsl:function name="tan:get-diff-stats" as="element()?" visibility="public">
      <!-- Input: any output from tan:diff() -->
      <!-- Output: the output, wrapped in a <group> and preceded by statistics. -->
      <!-- For details, see comments at tan:infuse-diff-and-collate-stats(). -->
      <!--kw: diff, statistics -->
      <xsl:param name="diff-input" as="element()?"/>
      <xsl:apply-templates select="tan:infuse-diff-and-collate-stats($diff-input, (), false())" mode="tan:get-diff-stats"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:get-diff-stats" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:stats | tan:witness | tan:stats/tan:diff | tan:length | tan:diff-count | tan:diff-length | tan:diff-portion" mode="tan:get-diff-stats">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:group/tan:diff" mode="tan:get-diff-stats"/>
   <xsl:template match="text()" mode="tan:get-diff-stats">
      <xsl:value-of select="."/>
   </xsl:template>
   

   <xsl:function name="tan:infuse-diff-and-collate-stats" as="element()?" visibility="private">
      <!-- One-param version of the full one, below -->
      <xsl:param name="diff-or-collate-input" as="element()?"/>
      <xsl:sequence select="tan:infuse-diff-and-collate-stats($diff-or-collate-input, (), true())"/>
   </xsl:function>
   
   <xsl:function name="tan:infuse-diff-and-collate-stats" as="element()?" visibility="private">
      <!-- Two-param version of the full one, below -->
      <xsl:param name="diff-or-collate-input" as="element()?"/>
      <xsl:param name="unimportant-change-character-aliases" as="element()*"/>
      <xsl:sequence select="tan:infuse-diff-and-collate-stats($diff-or-collate-input, $unimportant-change-character-aliases, true())"/>
   </xsl:function>
   
   <xsl:function name="tan:infuse-diff-and-collate-stats" as="element()?" visibility="private">
      <!-- Input: output from tan:diff() or tan:collate(); perhaps elements defining unimportant changes (see below) -->
      <!-- Output: the output wrapped in a <group>, whose first child is <stats>, supplying statistics for the difference
      or collation. A collation will also include a <venns> with statistical analysis of sources as statistics suitable for 
      3-way Venn diagrams. The diff output will be imprinted with @_pos-a, @_pos-b, and @_len, to put it on par with 
      the output of tan:collate(), where the position of each string can be calculated -->
      <!-- Unimportant changes (2nd parameter) are elements of any name, grouping <c>s. Each group of <c>s will be treated
      as equivalent. For example, to treat the ' and " as statistically irrelevant, supply <alias><c>'</c><c>"</c></alias> -->
      
      <xsl:param name="diff-or-collate-input" as="element()?"/>
      <xsl:param name="unimportant-change-character-aliases" as="element()*"/>
      <xsl:param name="include-venns" as="xs:boolean"/>
      <xsl:variable name="input-prepped" as="element()">
         <group>
            <xsl:copy-of select="$diff-or-collate-input"/>
         </group>
      </xsl:variable>
      <xsl:apply-templates select="$input-prepped" mode="tan:infuse-diff-and-collate-stats">
         <xsl:with-param name="unimportant-change-character-aliases"
            select="$unimportant-change-character-aliases" tunnel="yes"/>
         <xsl:with-param name="include-venns" tunnel="yes" select="$include-venns"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <!-- To use the following template mode, wrap the results of tan:diff() or tan:collate() in some element (doesn't matter what
   its name is). The output will be the same node, but with an infusion of statistics. -->
   
   <xsl:mode name="tan:infuse-diff-and-collate-stats" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[tan:diff[not(*)]] | *[tan:collation[not(*/tan:txt)]]" priority="1" mode="tan:infuse-diff-and-collate-stats">
      <xsl:message select="'Diff/collation is empty, and cannot be analyzed for statistics.'"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <stats/>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template
      match="*[tan:diff[tan:a][not(tan:b) and not(tan:common)]] | *[tan:diff[tan:b][not(tan:a) and not(tan:common)]]"
      priority="1" mode="tan:infuse-diff-and-collate-stats">
      <xsl:message
         select="'Diff is against one string only, and cannot be analyzed for statistics.'"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <stats/>
         <xsl:copy-of select="node()"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[tan:diff]" mode="tan:infuse-diff-and-collate-stats">
      <xsl:param name="unimportant-change-character-aliases" as="element()*" tunnel="yes"/>
      <xsl:variable name="these-as" select="tan:diff/tan:a"/>
      <xsl:variable name="these-bs" select="tan:diff/tan:b"/>
      <xsl:variable name="these-commons" select="tan:diff/tan:common"/>
      <xsl:variable name="these-a-lengths"
         select="
            for $i in $these-as
            return
               string-length($i)"/>
      <xsl:variable name="these-b-lengths"
         select="
            for $i in $these-bs
            return
               string-length($i)"/>
      
      <xsl:variable name="unique-a-length" select="sum($these-a-lengths)"/>
      <xsl:variable name="unique-b-length" select="sum($these-b-lengths)"/>
      <xsl:variable name="this-common-length" select="string-length(string-join($these-commons))"/>
      <xsl:variable name="orig-a-length" select="$unique-a-length + $this-common-length"/>
      <xsl:variable name="orig-b-length" select="$unique-b-length + $this-common-length"/>
      
      <xsl:variable name="these-character-alias-exceptions" as="element()">
         <exceptions>
            <xsl:for-each-group select="tan:diff/*" group-ending-with="tan:common">
               <xsl:variable name="this-a" select="current-group()/self::tan:a"/>
               <xsl:variable name="this-b" select="current-group()/self::tan:b"/>
               <xsl:variable name="this-char-alias"
                  select="$unimportant-change-character-aliases[tan:c = $this-a][tan:c = $this-b]"/>
               <group>
                  <xsl:if test="exists($this-char-alias)">
                     <xsl:copy-of select="$this-a"/>
                     <xsl:copy-of select="$this-b"/>
                  </xsl:if>
               </group>
            </xsl:for-each-group>
         </exceptions>
      </xsl:variable>
      <!--<xsl:variable name="this-exception-length" select="count($these-character-alias-exceptions)"/>-->
      <xsl:variable name="exception-a-length"
         select="string-length(string-join($these-character-alias-exceptions/*/tan:a))"/>
      <xsl:variable name="exception-b-length"
         select="string-length(string-join($these-character-alias-exceptions/*/tan:b))"/>
      
      <xsl:variable name="unique-a-length-adjusted" select="$unique-a-length - $exception-a-length"/>
      <xsl:variable name="unique-b-length-adjusted" select="$unique-b-length - $exception-b-length"/>
      
      <xsl:variable name="this-full-length" select="string-length(tan:diff)"/>

      <!--<xsl:variable name="this-a-length" select="$orig-a-length - $this-exception-length"/>
      <xsl:variable name="this-b-length" select="$orig-b-length - $this-exception-length"/>-->
      <xsl:variable name="unique-a-portion" select="$unique-a-length-adjusted div $orig-a-length"/>
      <xsl:variable name="unique-b-portion" select="$unique-b-length-adjusted div $orig-b-length"/>
      <xsl:variable name="unique-both-portion" select="($unique-a-length-adjusted + $unique-b-length-adjusted) div $this-full-length"/>
      

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <stats>
            <witness id="a" class="e-a">
               <xsl:copy-of select="tan:file[1]/@ref"/>
               <uri>
                  <xsl:value-of select="tan:file[1]/@uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$orig-a-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($these-as) - count($these-character-alias-exceptions/*/tan:a)"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$unique-a-length-adjusted"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of select="format-number($unique-a-portion, '0.00%')"/>
               </diff-portion>
            </witness>
            <witness id="b" class="e-b">
               <xsl:copy-of select="tan:file[2]/@ref"/>
               <uri>
                  <xsl:value-of select="tan:file[2]/@uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$orig-b-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($these-bs) - count($these-character-alias-exceptions/*/tan:b)"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$unique-b-length-adjusted"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of select="format-number($unique-b-portion, '0.00%')"/>
               </diff-portion>
            </witness>
            <diff id="diff" class="a-diff">
               <uri>
                  <xsl:value-of select="@_target-uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$this-full-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($these-character-alias-exceptions/*[not(*)])"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$unique-a-length-adjusted + $unique-b-length-adjusted"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of select="format-number($unique-both-portion, '0.00%')"/>
               </diff-portion>
            </diff>
            <xsl:if test="exists($these-character-alias-exceptions/*/*)">
               <note>
                  <xsl:text>The statistics above exclude differences of </xsl:text>
                  <xsl:value-of
                     select="
                        string-join(for $i in tan:distinct-items($these-character-alias-exceptions/*)
                        return
                           string-join($i/tan:c, ' and '), '; ')"/>
                  <xsl:text>.</xsl:text>
               </note>
            </xsl:if>
         </stats>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>
    
   <xsl:template match="tan:diff" mode="tan:infuse-diff-and-collate-stats">
      <xsl:copy-of select="tan:stamp-diff-with-text-data(.)"/>
   </xsl:template>
    
   <xsl:template match="*[tan:collation]" mode="tan:infuse-diff-and-collate-stats">
      <xsl:param name="unimportant-change-character-aliases" as="element()*" tunnel="yes"/>
      <xsl:param name="include-venns" as="xs:boolean" tunnel="yes" select="true()"/>
      <xsl:variable name="this-collation-wrapper" select="."/>
      <xsl:variable name="all-us" select="tan:collation/tan:u"/>
      <xsl:variable name="all-u-groups" as="element()">
         <u-groups>
            <!--  group-by="tokenize(@w, ' ')" -->
            <xsl:for-each-group select="$all-us" group-by="tan:wit/@ref">
               <xsl:sort
                  select="
                     if (current-grouping-key() castable as xs:integer) then
                        xs:integer(current-grouping-key())
                     else
                        0"/>
               <xsl:sort select="current-grouping-key()"/>
               <group n="{current-grouping-key()}">
                  <xsl:copy-of select="current-group()"/>
               </group>
            </xsl:for-each-group>
         </u-groups>
      </xsl:variable>
      <xsl:variable name="this-target-uri" select="@_target-uri"/>
      <!--<xsl:variable name="this-full-length" select="string-length(string-join(tan:collation/(* except tan:witness)))"/>-->
      <xsl:variable name="this-full-length"
         select="string-length(string-join(tan:collation/*/tan:txt))"/>

      <xsl:variable name="us-excepted-by-character-alias-exceptions" as="element()*">
         <xsl:for-each-group select="tan:collation/tan:u"
            group-adjacent="
               for $i in tan:txt
               return
                  ($unimportant-change-character-aliases[tan:c = $i]/@n, '')[1]">
            <xsl:variable name="these-us" select="current-group()"/>

            <xsl:variable name="is-for-every-ref"
               select="
                  every $i in $this-collation-wrapper/tan:file/@ref
                     satisfies exists($these-us/tan:wit[@ref = $i])"/>

            <xsl:if test="(string-length(current-grouping-key()) gt 0) and $is-for-every-ref">
               <xsl:sequence select="current-group()"/>
            </xsl:if>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="this-exception-length"
         select="count($us-excepted-by-character-alias-exceptions)"/>

      <xsl:variable name="this-common-length"
         select="string-length(string-join(tan:collation/tan:c/tan:txt))"/>

      <xsl:variable name="this-collation-diff-length"
         select="string-length(string-join($all-us/tan:txt))"/>
      <xsl:variable name="these-files" select="tan:file"/>
      <xsl:variable name="these-witnesses" select="tan:collation/tan:witness"/>
      <xsl:variable name="this-witness-count" select="count($these-witnesses)"/>
      <xsl:variable name="basic-stats" as="element()">
         <stats>
            <xsl:for-each
               select="
                  if (exists($these-files)) then
                     $these-files
                  else
                     $these-witnesses">
               <xsl:variable name="this-pos" select="position()"/>
               <xsl:variable name="this-label"
                  select="string(($these-witnesses[$this-pos]/@id, $this-pos)[1])"/>
               <xsl:variable name="this-diff-group" select="$all-u-groups/tan:group[$this-pos]"/>
               <xsl:variable name="these-diffs" select="$this-diff-group/tan:u"/>
               <xsl:variable name="this-orig-diff-length" select="string-length(string-join($these-diffs))"/>
               <xsl:variable name="these-diff-exceptions"
                  select="$us-excepted-by-character-alias-exceptions[tan:wit/@ref = $this-label]"/>
               <xsl:variable name="this-exception-length" select="count($these-diff-exceptions)"/>
               <xsl:variable name="this-adjusted-diff-length"
                  select="$this-orig-diff-length - $this-exception-length"/>
               <xsl:variable name="this-diff-portion"
                  select="$this-adjusted-diff-length div ($this-common-length + $this-adjusted-diff-length + $this-exception-length)"/>
               <xsl:variable name="this-ref" select="(@ref, $this-label)[1]"/>
               <xsl:variable name="this-length" as="xs:integer"
                  select="
                     if (exists(@length)) then
                        xs:integer(@length)
                     else
                        $this-common-length + $this-orig-diff-length"
               />
               <witness class="{'a-w-' || $this-ref}">
                  <xsl:attribute name="ref" select="$this-ref"/>
                  <uri>
                     <xsl:value-of select="@uri"/>
                  </uri>
                  <length>
                     <xsl:value-of select="$this-length"/>
                  </length>
                  <diff-count>
                     <xsl:value-of
                        select="count($these-diffs[tan:txt]) - count($these-diff-exceptions)"/>
                  </diff-count>
                  <diff-length>
                     <xsl:value-of select="$this-adjusted-diff-length"/>
                  </diff-length>
                  <diff-portion>
                     <xsl:value-of select="format-number($this-diff-portion, '0.0%')"/>
                  </diff-portion>
               </witness>
            </xsl:for-each>
         </stats>
      </xsl:variable>

      <!-- 3-way venns, to calculate distance of any version between any two others -->
      <xsl:variable name="three-way-venns" as="element()">
         <venns>
            <xsl:if test="$this-witness-count ge 3 and $include-venns">
               <xsl:for-each select="1 to ($this-witness-count - 2)">
                  <xsl:variable name="this-a-pos" select="."/>
                  <xsl:variable name="this-a-label"
                     select="
                        if (exists($these-files)) then
                           $these-files[$this-a-pos]/@ref
                        else
                           $these-witnesses[$this-a-pos]/@id"
                  />
                  <xsl:for-each select="($this-a-pos + 1) to ($this-witness-count - 1)">
                     <xsl:variable name="this-b-pos" select="."/>
                     <xsl:variable name="this-b-label"
                        select="
                           if (exists($these-files)) then
                              $these-files[$this-b-pos]/@ref
                           else
                              $these-witnesses[$this-b-pos]/@id"
                     />
                     <xsl:for-each select="($this-b-pos + 1) to $this-witness-count">
                        <xsl:variable name="this-c-pos" select="."/>
                        <xsl:variable name="this-c-label"
                           select="
                              if (exists($these-files)) then
                                 $these-files[$this-c-pos]/@ref
                              else
                                 $these-witnesses[$this-c-pos]/@id"
                        />
                        <xsl:variable name="all-relevant-nodes"
                           select="$this-collation-wrapper/tan:collation/*[tan:wit[@ref = ($this-a-label, $this-b-label, $this-c-label)]]"/>

                        <xsl:variable name="these-excepted-us" as="element()*">
                           <xsl:for-each-group select="$all-relevant-nodes/self::tan:u"
                              group-adjacent="
                                 for $i in tan:txt
                                 return
                                    ($unimportant-change-character-aliases[c = $i]/@n, '')[1]">
                              <xsl:variable name="is-for-every-ref"
                                 select="
                                    (current-group()/tan:wit/@ref = $this-a-label) and (current-group()/tan:wit/@ref = $this-b-label)
                                    and (current-group()/tan:wit/@ref = $this-c-label)"/>
                              <xsl:if
                                 test="(string-length(current-grouping-key()) gt 0) and $is-for-every-ref">
                                 <xsl:sequence select="current-group()"/>
                              </xsl:if>
                           </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:variable name="this-exception-length"
                           select="count($these-excepted-us)"/>

                        <xsl:variable name="this-full-length"
                           select="string-length(string-join($all-relevant-nodes))"/>
                        <xsl:variable name="these-a-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-a-label]"/>
                        <xsl:variable name="these-b-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-b-label]"/>
                        <xsl:variable name="these-c-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-c-label]"/>
                        <!-- The seven parts of a 3-way venn diagram -->
                        <xsl:variable name="these-a-only-nodes"
                           select="$these-a-nodes except ($these-b-nodes, $these-c-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-b-only-nodes"
                           select="$these-b-nodes except ($these-a-nodes, $these-c-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-c-only-nodes"
                           select="$these-c-nodes except ($these-a-nodes, $these-b-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-a-b-only-nodes"
                           select="($these-a-nodes intersect $these-b-nodes) except ($these-c-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-a-c-only-nodes"
                           select="($these-a-nodes intersect $these-c-nodes) except ($these-b-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-b-c-only-nodes"
                           select="($these-b-nodes intersect $these-c-nodes) except ($these-a-nodes, $these-excepted-us)"/>
                        <xsl:variable name="these-a-b-and-c-nodes"
                           select="$all-relevant-nodes[tan:wit/@ref = $this-a-label][tan:wit/@ref = $this-b-label][tan:wit/@ref = $this-c-label], $these-excepted-us"/>
                        <xsl:variable name="length-a-only"
                           select="string-length(string-join($these-a-only-nodes))"/>
                        <xsl:variable name="length-b-only"
                           select="string-length(string-join($these-b-only-nodes))"/>
                        <xsl:variable name="length-c-only"
                           select="string-length(string-join($these-c-only-nodes))"/>
                        <xsl:variable name="length-a-b-only"
                           select="string-length(string-join($these-a-b-only-nodes))"/>
                        <xsl:variable name="length-a-c-only"
                           select="string-length(string-join($these-a-c-only-nodes))"/>
                        <xsl:variable name="length-b-c-only"
                           select="string-length(string-join($these-b-c-only-nodes))"/>
                        <xsl:variable name="length-a-b-and-c"
                           select="string-length(string-join($these-a-b-and-c-nodes))"/>
                        <venn>
                           <a>
                              <xsl:value-of select="$this-a-label"/>
                           </a>
                           <b>
                              <xsl:value-of select="$this-b-label"/>
                           </b>
                           <c>
                              <xsl:value-of select="$this-c-label"/>
                           </c>
                           <node-count>
                              <xsl:value-of select="count($all-relevant-nodes)"/>
                           </node-count>
                           <length>
                              <xsl:value-of select="$this-full-length"/>
                           </length>
                           <part>
                              <a/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <b/>
                              <node-count>
                                 <xsl:value-of select="count($these-b-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-b-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-b-only div $this-full-length"/>
                              </portion>
                              <texts>
                                 <xsl:for-each select="$these-b-only-nodes">
                                    <xsl:copy>
                                       <xsl:copy-of select="tan:txt"/>
                                       <xsl:copy-of select="tan:wit[@ref = $this-b-label]"/>
                                    </xsl:copy>
                                 </xsl:for-each>
                              </texts>
                           </part>
                           <part>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-c-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-c-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-c-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <a/>
                              <b/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-b-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-b-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-b-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <a/>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-c-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-c-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-c-only div $this-full-length"/>
                              </portion>
                              <texts>
                                 <xsl:for-each select="$these-a-c-only-nodes">
                                    <xsl:copy>
                                       <xsl:copy-of select="tan:txt"/>
                                       <xsl:copy-of select="tan:wit[@ref = $this-a-label]"/>
                                       <xsl:copy-of select="tan:wit[@ref = $this-c-label]"/>
                                    </xsl:copy>
                                 </xsl:for-each>
                              </texts>
                           </part>
                           <part>
                              <b/>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-b-c-only-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-b-c-only"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-b-c-only div $this-full-length"/>
                              </portion>
                           </part>
                           <part>
                              <a/>
                              <b/>
                              <c/>
                              <node-count>
                                 <xsl:value-of select="count($these-a-b-and-c-nodes)"/>
                              </node-count>
                              <length>
                                 <xsl:value-of select="$length-a-b-and-c"/>
                              </length>
                              <portion>
                                 <xsl:value-of select="$length-a-b-and-c div $this-full-length"/>
                              </portion>
                           </part>
                           <xsl:if test="$this-exception-length gt 0">
                              <note>
                                 <xsl:sequence
                                    select="'The statistics above exclude differences consisting exclusively of ' ||
                                       string-join(for $i in tan:distinct-items($unimportant-change-character-aliases)
                                       return
                                          string-join($i/c, ' versus '), '; ')"/>
                                 <xsl:text>.</xsl:text>
                              </note>
                           </xsl:if>
                        </venn>
                     </xsl:for-each>
                  </xsl:for-each>
               </xsl:for-each>
            </xsl:if>
         </venns>
      </xsl:variable>


      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$unimportant-change-character-aliases"/>
         <stats>
            <xsl:copy-of select="$basic-stats/*"/>
            <collation id="collation" class="a-collation">
               <uri>
                  <xsl:value-of select="$this-target-uri"/>
               </uri>
               <length>
                  <xsl:value-of select="$this-full-length"/>
               </length>
               <diff-count>
                  <xsl:value-of select="count($all-us[tan:txt])"/>
               </diff-count>
               <diff-length>
                  <xsl:value-of select="$this-collation-diff-length"/>
               </diff-length>
               <diff-portion>
                  <xsl:value-of
                     select="format-number(($this-collation-diff-length div $this-full-length), '0.0%')"
                  />
               </diff-portion>
            </collation>
            <xsl:if test="$this-exception-length gt 0">
               <note>
                  <xsl:text>The statistics above exclude differences consisting exclusively of </xsl:text>
                  <xsl:value-of
                     select="
                        string-join(for $i in tan:distinct-items($unimportant-change-character-aliases)
                        return
                           string-join($i/c, ' versus '), '; ')"/>
                  <xsl:text>.</xsl:text>
               </note>
            </xsl:if>
         </stats>
         <xsl:if test="$include-venns">
            <xsl:copy-of select="$three-way-venns"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>
   
   
   
   
   <xsl:function name="tan:diff-a-map" as="map(xs:integer, item()*)?" visibility="private">
      <!-- Input: the result of tan:diff() -->
      <!-- Output: a map with integer entries representing the position of each a character, corresponding to the string value 
         of its b counterpart. Characters that are added, and not just replaced, are wrapped in <add> -->
      <!-- This function is used to make swaps from one text to another, where the replacement must take place 
         character-by-character, such as in the dependent function tan:replace-diff() -->
      <xsl:param name="diff-to-map" as="element(tan:diff)?"/>
      <xsl:variable name="diff-stamped" select="tan:stamp-diff-with-text-data($diff-to-map)"/>
      <xsl:apply-templates select="$diff-stamped" mode="tan:diff-a-map"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:diff-a-map" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:diff" mode="tan:diff-a-map">
      <xsl:map>
         <xsl:apply-templates mode="#current"/>
      </xsl:map>
   </xsl:template>
   <xsl:template match="tan:b" mode="tan:diff-a-map"/>
   <xsl:template match="tan:common[@_pos = '1']" priority="1" mode="tan:diff-a-map">
      <xsl:variable name="prev-b" select="preceding-sibling::tan:b"/>
      <!--<xsl:variable name="use-prev-b" select="not(exists(preceding-sibling::tan:a))"/>-->
      <!-- Yes the next sibling might be an a, but in that case, we shouldn't grab the b, because that a will get it. -->
      <xsl:variable name="this-corresponding-b" select="following-sibling::*[1]/self::tan:b[text()]"/>
      <xsl:variable name="these-chars" select="string-to-codepoints(.)"/>
      <xsl:variable name="char-count" select="count($these-chars)"/>
      <xsl:for-each select="$these-chars">
         <xsl:map-entry key="position()">
            <xsl:choose>
               <xsl:when test="position() eq 1 and position() eq $char-count">
                  <xsl:if test="exists($prev-b)">
                     <add><xsl:value-of select="$prev-b"/></add>
                  </xsl:if>
                  <xsl:value-of select="codepoints-to-string(.)"/>
                  <xsl:if test="exists($this-corresponding-b)">
                     <add><xsl:value-of select="$this-corresponding-b"/></add>
                  </xsl:if>
               </xsl:when>
               <xsl:when test="position() eq 1">
                  <xsl:if test="exists($prev-b)">
                     <add><xsl:value-of select="$prev-b"/></add>
                  </xsl:if>
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:when>
               <xsl:when test="position() eq $char-count">
                  <xsl:value-of select="codepoints-to-string(.)"/>
                  <xsl:if test="exists($this-corresponding-b)">
                     <add><xsl:value-of select="$this-corresponding-b"/></add>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:otherwise>
            </xsl:choose>
            
         </xsl:map-entry>
      </xsl:for-each>
      
   </xsl:template>
   
   <xsl:template match="tan:common" mode="tan:diff-a-map">
      <xsl:variable name="last-end" select="xs:integer(@_pos-a) - 1"/>
      <xsl:variable name="this-corresponding-b" select="following-sibling::*[1]/self::tan:b[text()]"/>
      <xsl:variable name="these-chars" select="string-to-codepoints(.)"/>
      <xsl:variable name="char-count" select="count($these-chars)"/>
      <xsl:for-each select="$these-chars">
         <xsl:map-entry key="position() + $last-end">
            <xsl:choose>
               <xsl:when test="position() eq $char-count">
                  <xsl:value-of select="codepoints-to-string(.)"/>
                  <xsl:if test="exists($this-corresponding-b)">
                     <add><xsl:value-of select="$this-corresponding-b"/></add>
                  </xsl:if>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="codepoints-to-string(.)"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:map-entry>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:template match="tan:a" mode="tan:diff-a-map">
      <xsl:variable name="context-el" select="." as="element()"/>
      <xsl:variable name="last-end" select="xs:integer(@_pos-a) - 1"/>
      <xsl:variable name="this-corresponding-b" select="following-sibling::*[1]/self::tan:b"/>
      <xsl:variable name="char-count" select="xs:integer(@_len)"/>
      <xsl:variable name="this-remnant" select="substring($this-corresponding-b, $char-count + 1)"/>
      <xsl:for-each select="1 to $char-count">
         <xsl:try>
            <xsl:map-entry key=". + $last-end">
               <xsl:if test=". eq 1">
                  <xsl:value-of select="substring($this-corresponding-b, 1, $char-count)"/>
                  <xsl:if test="string-length($this-remnant) gt 0">
                     <add><xsl:value-of select="$this-remnant"/></add>
                  </xsl:if>
               </xsl:if>
            </xsl:map-entry>
            <xsl:catch>
               <xsl:message select="'Problem at', $context-el"/>
               <xsl:message select="'Iteration:', ."/>
               <xsl:message select="'Last end:', $last-end"/>
               <xsl:message select="'Corresponding b:', $this-corresponding-b"/>
               <xsl:message select="'Char count:', $char-count"/>
               <xsl:message select="'Remnant: ' || $this-remnant"/>
            </xsl:catch>
         </xsl:try>
      </xsl:for-each>
   </xsl:template>
   
   
   
   <xsl:function name="tan:replace-diff" as="element()?" visibility="public">
      <!-- Input: the results of tan:diff(); the original a and b strings; a boolean -->
      <!-- Output: the output, but with each <a>, and <b> replaced by the original strings. <common> 
         follows the a string, not b. -->
      <!-- This function was made to support a more relaxed approach to tan:diff(), one that avoids 
         changes that should be ignored. For example, if you are comparing "Gray" (=$a) and "greys" 
         (=$b) and for your purposes, alternate spellings and case should be ignored, then make 
         appropriate changes to the strings (=$a2, $b2) then tan:reconcile-diff($a, $b, 
         tan:diff($a2, $b2)) will result in <diff><common>Gray</common><b>s</b></diff> -->
      <!--kw: strings, diff -->
      <xsl:param name="original-string-a" as="xs:string?"/>
      <xsl:param name="original-string-b" as="xs:string?"/>
      <xsl:param name="diff-to-replace" as="element()?"/>
      <xsl:param name="prioritize-a-over-b" as="xs:boolean"/>
      
      <xsl:variable name="diff-a" select="string-join($diff-to-replace/(tan:common | tan:a))"/>
      <xsl:variable name="diff-b" select="string-join($diff-to-replace/(tan:common | tan:b))"/>
      
      <xsl:variable name="a2-to-a-diff" select="tan:diff($diff-a, $original-string-a, false())"/>
      <xsl:variable name="b2-to-b-diff" select="tan:diff($diff-b, $original-string-b, false())"/>
      
      <xsl:variable name="a2-to-a-diff-map" as="map(xs:integer, item()*)?"
         select="tan:diff-a-map($a2-to-a-diff)"/>
      <xsl:variable name="b2-to-b-diff-map" as="map(xs:integer, item()*)?"
         select="tan:diff-a-map($b2-to-b-diff)"/>
      
      <xsl:variable name="diff-to-replace-stamped" select="tan:stamp-diff-with-text-data($diff-to-replace)"/>
      
      <xsl:variable name="output-pass-1" as="element()">
         <xsl:apply-templates select="$diff-to-replace-stamped" mode="tan:replace-diff">
            <xsl:with-param name="a2-to-a-diff-map" tunnel="yes" select="$a2-to-a-diff-map"/>
            <xsl:with-param name="b2-to-b-diff-map" tunnel="yes" select="$b2-to-b-diff-map"/>
            <xsl:with-param name="prioritize-a-over-b" tunnel="yes" as="xs:boolean" select="$prioritize-a-over-b"/>
         </xsl:apply-templates>
      </xsl:variable>
      
      <xsl:variable name="output-pass-2" as="element()">
         <!-- If there are tail-end additions shared by an a or common with the next b, then normally they should be delayed -->
         <diff>
            <xsl:for-each-group select="$output-pass-1/*" group-adjacent="exists(tan:add[not(following-sibling::node())])">
               <xsl:choose>
                  <xsl:when test="(current-grouping-key() = true())">
                     <xsl:for-each-group select="current-group()" group-ending-with="tan:b">
                        <xsl:variable name="group-count" select="count(current-group())"/>
                        <xsl:choose>
                           <xsl:when test="exists(current-group()[last()]/self::tan:b)">
                              <xsl:variable name="penultimate-item" select="current-group()[position() eq ($group-count - 1)]"/>
                              <xsl:variable name="last-item" select="current-group()[last()]"/>
                              <xsl:variable name="first-add"
                                 select="$penultimate-item/tan:add[not(following-sibling::node())]"/>
                              <xsl:variable name="second-add"
                                 select="$last-item/tan:add[not(following-sibling::node())]"/>
                              <xsl:copy-of select="current-group() except ($penultimate-item, $last-item)"/>
                              <xsl:for-each select="$penultimate-item, $last-item">
                                 <xsl:copy>
                                    <xsl:apply-templates select="node() except tan:add[not(following-sibling::node())]" mode="tan:shallow-skip-diff-add"/>
                                 </xsl:copy>
                              </xsl:for-each>
                              <xsl:copy-of select="tan:diff($first-add, $second-add, false())/*"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:apply-templates select="current-group()" mode="tan:shallow-skip-diff-add"/>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each-group> 
                     
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:apply-templates select="current-group()" mode="tan:shallow-skip-diff-add"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:for-each-group> 
         </diff>
         
      </xsl:variable>
      
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:adjust-diff()'"/>
         <xsl:message select="'Orig string a: ' || $original-string-a"/>
         <xsl:message select="'Orig string b: ' || $original-string-b"/>
         <xsl:message select="'Diff to replace: ', $diff-to-replace"/>
         <xsl:message select="'a to a diff:', $a2-to-a-diff"/>
         <xsl:message select="'b to b diff:', $b2-to-b-diff"/>
         <xsl:message select="'a to a map:', tan:map-to-xml($a2-to-a-diff-map)"/>
         <xsl:message select="'b to b map:', tan:map-to-xml($b2-to-b-diff-map)"/>
         <xsl:message select="'Diff to replace stamped: ', $diff-to-replace-stamped"/>
         <xsl:message select="'Output pass 1: ', $output-pass-1"/>
         <xsl:message select="'Output pass 2: ', $output-pass-2"/>
      </xsl:if>
      
      <xsl:variable name="output-diagnostics-on" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Replacing output of tan:replace-diff() with diagnostic output'"/>
            <testing>
               <a2-to-a-diff><xsl:copy-of select="$a2-to-a-diff"/></a2-to-a-diff>
               <b2-to-b-diff><xsl:copy-of select="$b2-to-b-diff"/></b2-to-b-diff>
               <!--<a2-to-a-map><xsl:value-of select="map:for-each($a2-to-a-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></a2-to-a-map>-->
               <!--<b2-to-b-map><xsl:value-of select="map:for-each($b2-to-b-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></b2-to-b-map>-->
               <diff-to-replace-stamped><xsl:copy-of select="$diff-to-replace-stamped"/></diff-to-replace-stamped>
               <out-pass1><xsl:copy-of select="$output-pass-1"/></out-pass1>
               <out-pass2><xsl:copy-of select="$output-pass-2"/></out-pass2>
            </testing>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="tan:adjust-diff($output-pass-2)"/>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:replace-diff" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:common" mode="tan:replace-diff">
      <xsl:param name="a2-to-a-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:param name="b2-to-b-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:param name="prioritize-a-over-b" tunnel="yes" as="xs:boolean" select="false()"/>
      <xsl:variable name="this-start" select="
            if ($prioritize-a-over-b) then
               xs:integer(@_pos-a)
            else
               xs:integer(@_pos-b)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:copy>
         <xsl:choose>
            <xsl:when test="$prioritize-a-over-b">
               <xsl:sequence
                  select="
                     for $i in ($this-start to $this-end)
                     return
                        map:get($a2-to-a-diff-map, $i)"
               />
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence
                  select="
                     for $i in ($this-start to $this-end)
                     return
                        map:get($b2-to-b-diff-map, $i)"
               />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:a" mode="tan:replace-diff">
      <xsl:param name="a2-to-a-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:variable name="this-start" select="xs:integer(@_pos-a)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:copy>
         <xsl:sequence
            select="
               for $i in ($this-start to $this-end)
               return
                  map:get($a2-to-a-diff-map, $i)"
         />
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:b" mode="tan:replace-diff">
      <xsl:param name="b2-to-b-diff-map" tunnel="yes" as="map(xs:integer, item()*)"/>
      <xsl:variable name="this-start" select="xs:integer(@_pos-b)"/>
      <xsl:variable name="this-end" select="$this-start + xs:integer(@_len) - 1"/>
      <xsl:copy>
         <xsl:sequence
            select="
               for $i in ($this-start to $this-end)
               return
                  map:get($b2-to-b-diff-map, $i)"
         />
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:shallow-skip-diff-add" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:add" mode="tan:shallow-skip-diff-add">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   
   
   <xsl:function name="tan:get-diff-output-slices" as="map(*)" visibility="private">
      <!-- Input: any output from tan:diff(); an integer; two decimals (each from 0 to 1); a boolean -->
      <!-- Output: a map; for each map entry, the key is the integer representing a string 
         position in the original output, and the corresponding value is a slice of the original
         output that is at least as long as the integer, and that has a percentage of commonality
         between the two decimals. If the last boolean is true, the slices of output will retain 
         attributes with text positions stamped. -->
      <!-- This function was written to support tan:get-diff-output-transpositions() -->
      <xsl:param name="diff-output" as="element(tan:diff)"/>
      <xsl:param name="minimum-string-length" as="xs:integer"/>
      <xsl:param name="maximum-commonality" as="xs:decimal"/>
      <xsl:param name="minimum-commonality" as="xs:decimal"/>
      <xsl:param name="retain-stamping" as="xs:boolean"/>
      
      <xsl:variable name="diff-output-stamped" as="element(tan:diff)" select="tan:stamp-diff-with-text-data($diff-output)"/>
      <xsl:variable name="min-sl-norm" as="xs:integer" select="max((2, $minimum-string-length))"/>
      <xsl:variable name="max-comm-norm" as="xs:decimal" select="min((1.0, abs($maximum-commonality)))"/>
      <xsl:variable name="min-comm-norm" as="xs:decimal" select="min(($max-comm-norm, abs($minimum-commonality)))"/>
      
      <xsl:variable name="diff-output-scores-1" as="xs:integer*">
         <xsl:apply-templates select="$diff-output-stamped" mode="tan:score-diff-output"/>
      </xsl:variable>
      
      <xsl:variable name="starting-subsequence" as="xs:integer*" select="subsequence($diff-output-scores-1, 1, $min-sl-norm)"/>
      
      <xsl:variable name="diff-output-scores-of-interest" as="xs:boolean*">
         <xsl:iterate select="$diff-output-scores-1">
            <xsl:param name="score-sequence" as="xs:integer+" select="
                  $diff-output-scores-1"/>
            <xsl:param name="interest-shadow-length-remaining" as="xs:integer" select="0"/>
            
            <xsl:variable name="scores-ahead" as="xs:integer+" select="subsequence($score-sequence, 1, $min-sl-norm)"/>
            <xsl:variable name="this-ratio" as="xs:decimal" select="sum($scores-ahead) div $min-sl-norm"/>
            <xsl:variable name="this-qualifies" as="xs:boolean" select="$this-ratio le $max-comm-norm and $this-ratio ge $min-comm-norm"/>
            
            <xsl:sequence select="$this-qualifies or $interest-shadow-length-remaining gt 0"/>
            
            <xsl:choose>
               <xsl:when test="count($score-sequence) eq $min-sl-norm">
                  <xsl:sequence select="
                        for $i in (2 to $min-sl-norm)
                        return
                           ($this-qualifies or ($interest-shadow-length-remaining - $i) gt -1)"
                  />
                  <xsl:break/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:next-iteration>
                     <xsl:with-param name="score-sequence" select="tail($score-sequence)"/>
                     <xsl:with-param name="interest-shadow-length-remaining" select="
                           if ($this-qualifies) then
                              ($min-sl-norm - 1)
                           else
                              ($interest-shadow-length-remaining - 1)"/>
                  </xsl:next-iteration>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:variable name="diff-output-slice-sizes" as="xs:integer*">
         <xsl:for-each-group select="$diff-output-scores-of-interest" group-adjacent=".">
            <xsl:variable name="is-of-interest" as="xs:boolean" select="current-grouping-key()"/>
            <xsl:choose>
               <xsl:when test="$is-of-interest">
                  <xsl:sequence select="count(current-group())"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="count(current-group()) * -1"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:variable name="diff-counts-to-pos" as="xs:integer*">
         <xsl:iterate select="$diff-output-slice-sizes">
            <xsl:param name="current-pos" as="xs:integer" select="1"/>
            <xsl:sequence select="$current-pos"/>
            <xsl:next-iteration>
               <xsl:with-param name="current-pos" select="$current-pos + abs(.)"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:variable name="diff-chopped" as="map(*)" select="
            if ($retain-stamping) then
               tan:chop-tree($diff-output-stamped, $diff-counts-to-pos)
            else
               tan:chop-tree($diff-output, $diff-counts-to-pos)"/>
      
      <xsl:variable name="keys-to-slices-of-interest" as="xs:integer*">
         <xsl:for-each select="$diff-output-slice-sizes">
            <xsl:variable name="this-pos" as="xs:integer" select="position()"/>
            <xsl:if test=". gt 0">
               <xsl:sequence select="$diff-counts-to-pos[$this-pos]"/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="false()"/>
      
      <xsl:map>
         <xsl:if test="$output-diagnostics-on">
            <xsl:map-entry key="'diff-output-scores-1'" select="$diff-output-scores-1"/>
            <xsl:map-entry key="'diff output scores of interest'" select="$diff-output-scores-of-interest"/>
            <xsl:map-entry key="'diff-output-slice-sizes'" select="$diff-output-slice-sizes"/>
            <xsl:map-entry key="'counts to pos'" select="$diff-counts-to-pos"/>
            <xsl:map-entry key="'starting-subsequence'" select="$starting-subsequence"/>
            <xsl:map-entry key="'max norm'" select="$max-comm-norm"/>
            <xsl:map-entry key="'min norm'" select="$min-comm-norm"/>
            <xsl:map-entry key="'chopped diff'" select="$diff-chopped"/>
            <xsl:map-entry key="'keys to slices of interest'" select="$keys-to-slices-of-interest"/>
         </xsl:if>
         <xsl:for-each select="$keys-to-slices-of-interest">
            <xsl:map-entry key="." select="$diff-chopped(current())"/>
         </xsl:for-each>
      </xsl:map>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:score-diff-output" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:common" mode="tan:score-diff-output">
      <xsl:sequence select="
            for $i in (1 to string-length(.))
            return
               1"/>
   </xsl:template>
   <xsl:template match="tan:a | tan:b" mode="tan:score-diff-output">
      <xsl:sequence select="
            for $i in (1 to string-length(.))
            return
               0"/>
   </xsl:template>
   
   
   
   <xsl:function name="tan:get-diff-output-transpositions" as="element()" visibility="public">
      <!-- Input: output from tan:diff(); an integer; a decimal (from 0 to 1) -->
      <!-- Output: a <transpositions> element, wrapping the following: (1) a <checksums> element
         that contains the checksums for strings a and b of the input; (2) a <parameters> element 
         that contains the settings specified; (3) zero or more <transposition> elements wrapping 
         the portion of the input diff output that is at least as long as the integer, and whose 
         commonality is greater than or equal to the percent specified by the decimal. -->
      <!-- This function looks within likely sections of the results of tan:diff() for passages that 
         may represent a transposition. What constitutes a transposition differs greatly from one 
         situation to the next. In large stretches of running prose, a safe minimum length
         might be 20 and a corresponding commonality 0.95, to accommodate very occasional changes. The
         lower the commonality number, the more results, but they may include on the edges material that
         is not part of the actual transposition. -->
      <!-- <transposition> has attributes that point to the absolute position of the start of the a
         and b fragments within the original diff output. These values can be used as points at which
         to chop the diff result tree, if you wish to synthesize, combine, etc. it with the
         transposition slices. -->
      <!-- Transpositions can be a difficult topic, with many-to-many assignments between the two texts,
         or with assignments in the same text that overlap. This is normal, and reflects normal editing
         habits. For example, an editor may take two sentences from different parts of a text and merge 
         them at a third spot. This function, with enough leeway in the parameters, would catch both
         of the transpositions. It is up to you to interpret those transpositions and use them as you
         see fit.
      -->
      <!--kw: strings, diff -->
      <xsl:param name="diff-output" as="element(tan:diff)"/>
      <xsl:param name="minimum-transposition-length" as="xs:integer"/>
      <xsl:param name="minimum-commonality" as="xs:decimal"/>
      
      <xsl:variable name="string-a" as="xs:string?" select="string-join($diff-output/(tan:a | tan:common))"/>
      <xsl:variable name="string-b" as="xs:string?" select="string-join($diff-output/(tan:b | tan:common))"/>
      <xsl:variable name="checksum-string-a" as="xs:string?" select="tan:checksum-fletcher-64($string-a)"/>
      <xsl:variable name="checksum-string-b" as="xs:string?" select="tan:checksum-fletcher-64($string-b)"/>
      
      <xsl:variable name="diff-output-stamped" as="element(tan:diff)" select="tan:stamp-tree-with-text-data(tan:stamp-diff-with-text-data($diff-output), true())"/>
      <xsl:variable name="min-sl-norm" as="xs:integer" select="max((2, $minimum-transposition-length))"/>
      <xsl:variable name="min-comm-norm" as="xs:decimal" select="min((1.0, max(($minimum-commonality, 0))))"/>
      
      <!-- Fetch those parts of the diff output that have a healthy dose of <a> and <b> passages, and include enough of
         any adjacent <common> to provide some context. -->
      <xsl:variable name="rough-diff-slices" as="map(*)"
         select="tan:get-diff-output-slices($diff-output-stamped, $min-sl-norm, (($min-sl-norm - 1) div $min-sl-norm), 0, true())"
      />
      
      <!-- Slice keys point to the absolute starting point of the diff slice, when the diff output is flattened;
         that is, it is @_pos, the position of a, b, or common (and so will always be larger than or equal to
         the size of @_a-pos and @_b-pos.)-->
      <xsl:variable name="diff-slice-keys"
         select="map:keys($rough-diff-slices)[. instance of xs:integer]" as="xs:integer*"/>
      
      <xsl:variable name="rough-diff-slice-comparison" as="element()*">
         <xsl:for-each select="$diff-slice-keys">
            <xsl:variable name="a-diff-slice-key" select="." as="xs:integer"/>
            <xsl:variable name="a-diff-slice" as="element()" select="$rough-diff-slices($a-diff-slice-key)"/>
            <!-- Where in the original string b does the slice begin? -->
            <xsl:variable name="a-diff-slice-first-element" as="element()" select="$a-diff-slice/*[1]"/>
            <xsl:variable name="a-slice-orig-a-pos" as="xs:integer"
               select="xs:integer($a-diff-slice-first-element/@_pos-a) + (xs:integer($a-diff-slice-first-element/@_len - string-length($a-diff-slice-first-element)))"
            />
            <xsl:variable name="this-a-text" as="xs:string" select="string-join($a-diff-slice/(tan:common | tan:a))"/>
            <xsl:for-each select="$diff-slice-keys[not(. eq $a-diff-slice-key)]">
               <xsl:variable name="b-diff-slice-key" select="." as="xs:integer"/>
               <xsl:variable name="b-diff-slice" as="element()" select="$rough-diff-slices($b-diff-slice-key)"/>
               <!-- Where in the original string b does the slice begin? -->
               <xsl:variable name="b-diff-slice-first-element" as="element()" select="$b-diff-slice/*[1]"/>
               <xsl:variable name="b-slice-orig-b-pos" as="xs:integer"
                  select="xs:integer($b-diff-slice-first-element/@_pos-b) + (xs:integer($b-diff-slice-first-element/@_len - string-length($b-diff-slice-first-element)))"
               />
               <xsl:variable name="this-b-text" as="xs:string" select="string-join($b-diff-slice/(tan:common | tan:b))"/>
               <xsl:variable name="this-new-diff" as="element()" select="tan:diff($this-a-text, $this-b-text, false())"/>
               <xsl:variable name="possible-transposition-slices" as="map(*)"
                  select="tan:get-diff-output-slices($this-new-diff, $min-sl-norm, 1.0, $min-comm-norm, true())"
               />
               <xsl:variable name="successful-slice-keys" as="xs:integer*"
                  select="map:keys($possible-transposition-slices)[. instance of xs:integer]"/>
               
               <xsl:variable name="inner-output-diagnostics-on" as="xs:boolean" select="false()"/>
               <xsl:if test="$inner-output-diagnostics-on">
                  <diagnostics>
                     <iteration><xsl:value-of select="position()"/></iteration>
                     <a-diff-slice-key><xsl:copy-of select="$a-diff-slice-key"/></a-diff-slice-key>
                     <a-diff-slice><xsl:copy-of select="$a-diff-slice"/></a-diff-slice>
                     <a-text><xsl:copy-of select="$this-a-text"/></a-text>
                     <b-diff-slice-key><xsl:copy-of select="$b-diff-slice-key"/></b-diff-slice-key>
                     <b-diff-slice><xsl:copy-of select="$b-diff-slice"/></b-diff-slice>
                     <b-text><xsl:copy-of select="$this-b-text"/></b-text>
                     <new-diff><xsl:copy-of select="$this-new-diff"/></new-diff>
                     <possible-transposition-slices><xsl:copy-of select="tan:map-to-xml($possible-transposition-slices)"/></possible-transposition-slices>
                     <successful-slice-keys><xsl:value-of select="$successful-slice-keys"/></successful-slice-keys>
                  </diagnostics>
               </xsl:if>
               
               <xsl:for-each select="$successful-slice-keys">
                  <xsl:variable name="these-results" as="element()" select="$possible-transposition-slices(current())"/>
                  <xsl:variable name="first-result" as="element()" select="$these-results/*[1]"/>
                  <xsl:variable name="initial-string-length-omitted" as="xs:integer"
                     select="xs:integer($first-result/@_len) - string-length($first-result)"/>
                  <xsl:variable name="first-_pos-a" as="xs:integer?" select="
                        xs:integer($first-result/@_pos-a) + (if (name($first-result) eq 'b') then
                           0
                        else
                           $initial-string-length-omitted)"
                  />
                  <xsl:variable name="first-_pos-b" as="xs:integer?" select="
                        xs:integer($first-result/@_pos-b) + (if (name($first-result) eq 'a') then
                           0
                        else
                           $initial-string-length-omitted)"/>
                  <xsl:variable name="pos-a-orig" as="xs:integer" select="$a-slice-orig-a-pos + $first-_pos-a - 1"/>
                  <xsl:variable name="pos-b-orig" as="xs:integer" select="$b-slice-orig-b-pos + $first-_pos-b - 1"/>
                  <!-- These are positions relative to the original input's @_pos stamp, not the position within
                     original strings a and b. -->
                  <xsl:variable name="pos-a-abs" as="xs:integer" select="$a-diff-slice-key + ($first-_pos-a, 0)[1] - 1"/>
                  <xsl:variable name="pos-b-abs" as="xs:integer" select="$b-diff-slice-key + ($first-_pos-b, 0)[1] - 1"/>
                  
                  <xsl:if test="$inner-output-diagnostics-on">
                     <diagnostics>
                        <this-slice-key><xsl:value-of select="."/></this-slice-key>
                        <first-result><xsl:copy-of select="$first-result"/></first-result>
                        <initial-string-length-omitted><xsl:value-of select="$initial-string-length-omitted"/></initial-string-length-omitted>
                        <first-_pos-a><xsl:value-of select="$first-_pos-a"/></first-_pos-a>
                        <first-_pos-b><xsl:value-of select="$first-_pos-b"/></first-_pos-b>
                     </diagnostics>
                  </xsl:if>
                  <transposition pos-a-orig="{$pos-a-orig}" pos-b-orig="{$pos-b-orig}" pos-a-abs="{$pos-a-abs}" pos-b-abs="{$pos-b-abs}">
                     <xsl:apply-templates select="$these-results" mode="tan:strip-text-data-stamps"/>
                  </transposition>
               </xsl:for-each>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="output-diagnostics-on" as="xs:boolean" select="false()"/>
      
      <transpositions>
         <xsl:if test="$output-diagnostics-on">
            <diagnostics>
               <string-a><xsl:value-of select="tan:ellipses($string-a, 20, 20)"/></string-a>
               <string-b><xsl:value-of select="tan:ellipses($string-b, 20, 20)"/></string-b>
               <diff-output-stamped><xsl:copy-of select="$diff-output-stamped"/></diff-output-stamped>
            </diagnostics>
         </xsl:if>
         <checksums>
            <type>fletcher-64</type>
            <a><xsl:value-of select="$checksum-string-a"/></a>
            <b><xsl:value-of select="$checksum-string-b"/></b>
         </checksums>
         <parameters>
            <minimum-transposition-length>
               <xsl:value-of select="$min-sl-norm"/>
            </minimum-transposition-length>
            <minimum-commonality>
               <xsl:value-of select="$min-comm-norm"/>
            </minimum-commonality>
         </parameters>
         <xsl:copy-of select="$rough-diff-slice-comparison"/>
      </transpositions>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:strip-text-data-stamps" on-no-match="shallow-copy"/>
   
   <xsl:template match="@_pos-a | @_pos-b | @_len | @_pos" mode="tan:strip-text-data-stamps"/>
   
   
   
   
   <xsl:function name="tan:diff-to-delta" as="document-node()?" visibility="public">
      <!-- Input: any output from tan:diff() -->
      <!-- Output: a document node registering only the difference between strings a and b -->
      <!-- Delta files are structured to support two-way conversion. That is, they are designed such 
         that b can be reconstituted from a or vice versa. See tan:apply-deltas() for documentation.
         -->
      <!-- kw: diff, strings -->
      <xsl:param name="diff-output" as="element(tan:diff)?"/>
      <xsl:apply-templates select="$diff-output" mode="tan:diff-to-delta"/>
   </xsl:function>
   
   <xsl:mode name="tan:diff-to-delta" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:diff" mode="tan:diff-to-delta">
      <xsl:variable name="this-a" as="xs:string" select="string-join((tan:a | tan:common))"/>
      <xsl:variable name="this-b" as="xs:string" select="string-join((tan:b | tan:common))"/>
      <xsl:document>
         <!-- The document is structured without attributes, and one text node per element, to take advantage of 
            Saxon's optimization for such structures. -->
         <delta>
            <dateTime><xsl:value-of select="current-dateTime()"/></dateTime>
            <version>0</version>
            <checksums>
               <type>fletcher-64</type>
               <a><xsl:copy-of select="tan:checksum-fletcher-64($this-a)"/></a>
               <b><xsl:copy-of select="tan:checksum-fletcher-64($this-b)"/></b>
            </checksums>
            <xsl:iterate select="*">
               <xsl:param name="common-pos" as="xs:integer" select="1"/>
               <xsl:param name="a-pos" as="xs:integer" select="1"/>
               <xsl:param name="b-pos" as="xs:integer" select="1"/>
               
               <xsl:variable name="this-is-a" as="xs:boolean" select="local-name(.) eq 'a'"/>
               <xsl:variable name="this-is-b" as="xs:boolean" select="local-name(.) eq 'b'"/>
               <xsl:variable name="this-is-common" as="xs:boolean" select="local-name(.) eq 'common'"/>
               
               <xsl:variable name="this-length" as="xs:integer" select="string-length(.)"/>
               
               <xsl:choose>
                  <xsl:when test="self::tan:a">
                     <xsl:copy>
                        <!-- A delta should be minimially small, therefore one-letter element names wrap the bulk of the delta. -->
                        <!-- c for position within the string constituted only by common -->
                        <c><xsl:value-of select="$common-pos"/></c>
                        <!-- o for original position -->
                        <o><xsl:value-of select="$a-pos"/></o>
                        <!-- t for text -->
                        <t><xsl:value-of select="."/></t>
                     </xsl:copy>
                  </xsl:when>
                  <xsl:when test="self::tan:b">
                     <xsl:copy>
                        <c><xsl:value-of select="$common-pos"/></c>
                        <o><xsl:value-of select="$b-pos"/></o>
                        <t><xsl:value-of select="."/></t>
                     </xsl:copy>
                  </xsl:when>
               </xsl:choose>
               
               <xsl:next-iteration>
                  <xsl:with-param name="common-pos" select="
                        if ($this-is-common) then
                           $common-pos + $this-length
                        else
                           $common-pos"/>
                  <xsl:with-param name="a-pos" select="
                        if ($this-is-b) then
                           $a-pos
                        else
                           $a-pos + $this-length"/>
                  <xsl:with-param name="b-pos" select="
                        if ($this-is-a) then
                           $b-pos
                        else
                           $b-pos + $this-length"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </delta>
      </xsl:document>
   </xsl:template>
   
   
   <xsl:function name="tan:apply-deltas" as="xs:string?" visibility="public">
      <!-- 2-parameter version of the full one, below -->
      <xsl:param name="string-to-convert" as="xs:string?"/>
      <xsl:param name="deltas" as="document-node()*"/>
      <xsl:sequence select="tan:apply-deltas($string-to-convert, $deltas, ())"></xsl:sequence>
   </xsl:function>
   
   <xsl:function name="tan:apply-deltas" as="xs:string?" visibility="public">
      <!-- Input: a string, a series of delta documents, perhaps a boolean -->
      <!-- Output: another string, after any applicable deltas have been successively applied -->
      <!-- Each delta will be applied only once. If any deltas are left over, a warning will be returned. -->
      <!-- Output will be verified; if its checksum does not match what is in the given delta, a warning will be returned -->
      <!-- kw: strings, diff -->
      <xsl:param name="string-to-convert" as="xs:string?"/>
      <xsl:param name="deltas" as="document-node()*"/>
      <xsl:param name="input-is-string-a" as="xs:boolean?"/>
      
      <xsl:variable name="string-checksum" as="xs:string" select="tan:checksum-fletcher-64($string-to-convert)"/>
      <xsl:variable name="delta-of-choice" as="document-node()*" select="
            if (not(exists($input-is-string-a))) then
               $deltas[*/tan:checksums/* = $string-checksum]
            else
               if ($input-is-string-a eq true()) then
                  $deltas[*/tan:checksums/tan:a = $string-checksum]
               else
                  $deltas[*/tan:checksums/tan:b = $string-checksum]"/>
      <xsl:variable name="versions-supported" as="xs:string+" select="'0'"/>
      <xsl:choose>
         <xsl:when test="not(exists($deltas)) or string-length($string-to-convert) lt 1">
            <xsl:sequence select="$string-to-convert"/>
         </xsl:when>
         <xsl:when test="count($delta-of-choice) gt 1">
            <xsl:message select="string(count($delta-of-choice)) || ' deltas are applicable, based on string checksum ' || $string-checksum || '. Terminating function with current results.'"/>
            <xsl:sequence select="$string-to-convert"/>
         </xsl:when>
         <xsl:when test="count($delta-of-choice) eq 0">
            <xsl:message select="'No deltas apply to string with checksum ' || $string-checksum || ', but ' || string(count($deltas)) || ' remain to be processed. Terminating function with current results.'"/>
            <xsl:sequence select="$string-to-convert"/>
         </xsl:when>
         <xsl:when test="not($delta-of-choice/*/tan:version = $versions-supported)">
            <xsl:message select="'A delta must be one of the following versions: ' || string-join($versions-supported, ', ') || '. Terminating function with current results.'"/>
            <xsl:sequence select="$string-to-convert"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="relevant-checksum" as="element()" select="
                  if (not(exists($input-is-string-a))) then
                     $delta-of-choice/*/tan:checksums/*[. eq $string-checksum][1]
                  else
                     if ($input-is-string-a eq true()) then
                        $delta-of-choice/*/tan:checksums/tan:a[. eq $string-checksum][1]
                     else
                        $delta-of-choice/*/tan:checksums/tan:b[. eq $string-checksum][1]"
            />
            <xsl:variable name="input-is-string-a" as="xs:boolean" select="local-name($relevant-checksum) eq 'a'"/>
            
            <!-- Sort deletions by the original position, <o> -->
            <xsl:variable name="deletions-to-apply" as="element()*">
               <xsl:for-each select="
                     if ($input-is-string-a) then
                        $delta-of-choice/*/tan:a
                     else
                        $delta-of-choice/*/tan:b">
                  <xsl:sort select="xs:integer(tan:o)" order="descending"/>
                  <xsl:sequence select="."/>
               </xsl:for-each>
            </xsl:variable>
            
            <!-- Sort insertions by position within common-only text, <c> -->
            <xsl:variable name="insertions-to-apply" as="element()*">
               <xsl:for-each select="
                     if ($input-is-string-a) then
                        $delta-of-choice/*/tan:b
                     else
                        $delta-of-choice/*/tan:a">
                  <xsl:sort select="xs:integer(tan:c)" order="descending"/>
                  <xsl:sequence select="."/>
               </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="output-pass-1" as="xs:string*">
               <!-- This first pass applies deletions, in reverse order; the result will be a sequence of strings that need to be 
                  reversed and string-joined before being processed through the next pass -->
               <xsl:iterate select="$deletions-to-apply">
                  <xsl:param name="string-so-far" as="xs:string" select="$string-to-convert"/>
                  <xsl:on-completion select="$string-so-far"/>
                  <xsl:variable name="this-pos" as="xs:integer" select="xs:integer(tan:o)"/>
                  <xsl:variable name="this-len" as="xs:integer" select="string-length(tan:t)"/>
                  <xsl:variable name="preceding-snippet" as="xs:string" select="substring($string-so-far, 1, $this-pos - 1)"/>
                  <xsl:variable name="following-snippet" as="xs:string?" select="substring($string-so-far, $this-pos + $this-len)"/>
                  <xsl:sequence select="$following-snippet"/>
                  <xsl:next-iteration>
                     <xsl:with-param name="string-so-far" select="$preceding-snippet"/>
                  </xsl:next-iteration>
               </xsl:iterate>
            </xsl:variable>
            
            <xsl:variable name="output-pass-2" as="xs:string*">
               <xsl:iterate select="$insertions-to-apply">
                  <xsl:param name="string-so-far" as="xs:string" select="string-join(reverse($output-pass-1))"/>
                  <xsl:on-completion select="$string-so-far"/>
                  <xsl:variable name="this-pos" as="xs:integer" select="xs:integer(tan:c)"/>
                  <xsl:variable name="this-len" as="xs:integer" select="string-length(tan:t)"/>
                  <xsl:variable name="preceding-snippet" as="xs:string" select="substring($string-so-far, 1, $this-pos - 1)"/>
                  <xsl:variable name="following-snippet" as="xs:string?" select="substring($string-so-far, $this-pos)"/>
                  
                  <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
                  <xsl:if test="$diagnostics-on">
                     <xsl:message select="'Diagnostics on, $output-pass-2 in tan:apply-deltas()'"/>
                     <xsl:message select="'Iteration: ', position()"/>
                     <xsl:message select="'String so far: ' || tan:ellipses($string-so-far, 30, 30)"/>
                     <xsl:message select="'Current insertion: ', ."/>
                     <xsl:message select="'Preceding snippet: ' ||  tan:ellipses($preceding-snippet, 30, 30)"/>
                     <xsl:message select="'Following snippet: ' ||  tan:ellipses($following-snippet, 30, 30)"/>
                  </xsl:if>
                  
                  <xsl:sequence select="tan:t || $following-snippet"/>
                  <xsl:next-iteration>
                     <xsl:with-param name="string-so-far" select="$preceding-snippet"/>
                  </xsl:next-iteration>
                  
               </xsl:iterate>
            </xsl:variable>
            
            <xsl:variable name="output-string-result" as="xs:string" select="string-join(reverse($output-pass-2))"/>
            <xsl:variable name="output-string-checksum" as="xs:string" select="tan:checksum-fletcher-64($output-string-result)"/>
            <xsl:variable name="expected-checksum" as="xs:string" select="
                  if ($input-is-string-a) then
                     $delta-of-choice/*/tan:checksums/tan:b
                  else
                     $delta-of-choice/*/tan:checksums/tan:a"/>
            <xsl:variable name="expected-output-returned" as="xs:boolean" select="$expected-checksum eq $output-string-checksum"/>
            
            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Diagnostics on, tan:apply-deltas()'"/>
               <xsl:message select="'String to convert: ' || tan:ellipses($string-to-convert, 10, 10)"/>
               <xsl:message select="'String checksum: ' || $string-checksum"/>
               <xsl:message select="'Delta chosen: ', tan:trim-long-tree($delta-of-choice/*, 10, 20)"/>
               <xsl:message select="'Input is string a: ', $input-is-string-a"/>
               <xsl:message select="'Deletions to apply (' || string(count($deletions-to-apply)) || '), first three: ', subsequence($deletions-to-apply, 1, 3)"/>
               <xsl:message select="'Insertions to apply (' || string(count($insertions-to-apply)) || '), first three: ', subsequence($insertions-to-apply, 1, 3)"/>
               <xsl:message select="'Output pass 1: ' || tan:ellipses(string-join(reverse($output-pass-1)), 30, 30)"/>
               <xsl:message select="'Output pass 2: ' || tan:ellipses($output-string-result, 30, 30)"/>
               <xsl:message select="'Output checksum: ' || $output-string-checksum"/>
            </xsl:if>
            
            <xsl:if test="not($expected-output-returned)">
               <xsl:message select="'tan:apply-deltas() returned a malformed string from applying selected delta to the input: ' || $string-to-convert"/>
               <xsl:message select="'output string: ' || tan:ellipses($output-string-result, 30, 30)"/>
               <xsl:message select="'output checksum: ' || $output-string-checksum"/>
               <xsl:message select="'delta chosen: ', tan:trim-long-tree($delta-of-choice/*, 10, 20)"/>
            </xsl:if>
            <xsl:sequence
               select="tan:apply-deltas($output-string-result, $deltas except $delta-of-choice)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <!-- TODO: calculate Damerau-Levenshtein distance: 
      https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance -->
   <xsl:function name="tan:levenshtein-distance" as="xs:integer?" visibility="public">
      <!-- Input: results of tan:diff() -->
      <!-- Output: the Levenstein distance of the output -->
      <!-- Levenstein distance assigns 1 point per character deletion, insertion, or substitution -->
      <!-- kw: strings, diff -->
      <xsl:param name="diff-output" as="element(tan:diff)?"/>
      <xsl:variable name="counts" as="xs:integer*">
         <xsl:apply-templates select="$diff-output" mode="tan:levenshtein-distance"/>
      </xsl:variable>
      <xsl:sequence select="sum($counts)"/>
   </xsl:function>
   
   <xsl:mode name="tan:levenshtein-distance" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:a" mode="tan:levenshtein-distance">
      <xsl:variable name="following-b" as="element()?" select="following-sibling::*[1]/self::tan:b"/>
      <xsl:variable name="string-length-a" as="xs:integer" select="string-length(.)"/>
      <xsl:variable name="string-length-b" as="xs:integer" select="string-length($following-b)"/>
      <xsl:sequence select="max(($string-length-a, $string-length-b))"/>
   </xsl:template>
   
   <xsl:template match="tan:b" mode="tan:levenshtein-distance">
      <xsl:variable name="preceding-a" as="element()?" select="preceding-sibling::*[1]/self::tan:a"/>
      <xsl:if test="not(exists($preceding-a))">
         <xsl:sequence select="string-length(.)"/>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="tan:lcs-distance" as="xs:integer?" visibility="public">
      <!-- Input: results of tan:diff() -->
      <!-- Output: the longest common subsequence distance of the output -->
      <!-- LCS distance assigns 1 point per character deletion and insertion -->
      <!-- kw: strings, diff -->
      <xsl:param name="diff-output" as="element(tan:diff)?"/>
      <xsl:sequence select="
            sum(for $i in $diff-output/(tan:a | tan:b)
            return
               string-length($i))"/>
   </xsl:function>
   
   
   
   <!-- TODO: develop this function so it can completely replace tan:diff-loop() -->
   <xsl:function name="tan:multiple-string-diff-loop" visibility="private" as="element()*">
      <!-- This function is an experiment in using the staggered sample technique
         on multiple strings -->
      <xsl:param name="str-sequence" as="xs:string*"/>
      <xsl:param name="str-labels" as="xs:string*"/>
      <xsl:param name="str-positions" as="xs:integer*"/>
      <xsl:param name="vertical-stops-to-process" as="xs:double*"/>
      <xsl:param name="min-sample-size" as="xs:integer?"/>
      <xsl:param name="loop-counter" as="xs:integer"/>

      <xsl:variable name="str-count" as="xs:integer" select="count($str-sequence)"/>
      <xsl:variable name="str-lengths" as="xs:integer+" select="
            for $i in $str-sequence
            return
               string-length($i)"/>
      <xsl:variable name="shortest-length" as="xs:integer" select="min($str-lengths)"/>
      <xsl:variable name="longest-length" as="xs:integer" select="max($str-lengths)"/>
      <xsl:variable name="shortest-pos" as="xs:integer"
         select="index-of($str-lengths, $shortest-length)[1]"/>
      <xsl:variable name="shortest-string-label" as="xs:string?" select="$str-labels[$shortest-pos]"/>
      <xsl:variable name="shortest-string" as="xs:string?" select="$str-sequence[$shortest-pos]"/>
      <xsl:variable name="longest-strings" as="xs:string*"
         select="$str-sequence[position() ne $shortest-pos]"/>

      <xsl:variable name="at-least-one-input-is-empty" select="$shortest-length lt 1"
         as="xs:boolean"/>
      <xsl:variable name="loop-is-excessive" select="$loop-counter ge $tan:loop-tolerance"
         as="xs:boolean"/>
      <xsl:variable name="out-of-vertical-stops" select="count($vertical-stops-to-process) lt 1"
         as="xs:boolean"/>

      <xsl:variable name="no-match-result-tree" as="element()*">
         <xsl:for-each select="1 to $str-count">
            <xsl:variable name="i" as="xs:integer" select="."/>
            <xsl:variable name="currtext" as="xs:string" select="$str-sequence[$i]"/>
            <xsl:if test="string-length($currtext) gt 0">
               <u>
                  <txt>
                     <xsl:value-of select="$currtext"/>
                  </txt>
                  <wit ref="{$str-labels[$i]}" pos="{$str-positions[$i]}"/>
               </u>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      
      <xsl:variable name="min-sample-size-norm" as="xs:integer" select="
            if ($min-sample-size gt 0) then
               min(($min-sample-size, $shortest-length))
            else
               if ($tan:collate-superskeleton-autoset-min-sample-size) then
                  xs:integer(ceiling(math:log10(max(($shortest-length, 1)))))
               else
                  max(($tan:collate-superskeleton-min-sample-size, 1))"/>
      
      

      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:multiple-string-diff-loop()'"/>
         <xsl:message select="'loop number: ', string($loop-counter)"/>
         <xsl:message select="
               'string lengths: ', string-join(for $i in $str-lengths
               return
                  string($i), ', ')"/>
         <xsl:message select="
               'string positions: ', string-join(for $i in $str-positions
               return
                  string($i), ', ')"/>
         <xsl:message select="'$vertical-stops-to-process:', $vertical-stops-to-process"/>
         <xsl:message select="'Minimum sample size:', $min-sample-size-norm"/>
      </xsl:if>

      <xsl:choose>
         <xsl:when test="$longest-length eq 0"/>

         <xsl:when
            test="not($at-least-one-input-is-empty) and count(distinct-values($str-sequence)) eq 1">
            <c>
               <xsl:copy-of select="$outer-loop-attr" use-when="$tan:infuse-diff-diagnostics"/>
               <txt>
                  <xsl:value-of select="$str-sequence[1]"/>
               </txt>
               <xsl:for-each select="1 to $str-count">
                  <xsl:variable name="i" as="xs:integer" select="."/>
                  <wit ref="{$str-labels[$i]}" pos="{$str-positions[$i]}"/>
               </xsl:for-each>
            </c>
         </xsl:when>

         <xsl:when
            test="$at-least-one-input-is-empty or $loop-is-excessive or $out-of-vertical-stops">
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'empty input? ', $at-least-one-input-is-empty"/>
               <xsl:message select="'loop overload? ', $loop-is-excessive"/>
               <xsl:message select="'out of vertical stops? ', $out-of-vertical-stops"/>
            </xsl:if>
            <xsl:if test="$loop-is-excessive">
               <xsl:message select="
                     'tan:diff() cannot loop beyond ' || xs:string($tan:loop-tolerance) ||
                     ' passes; any remaining will not search for the superskeleton. '
                     || (for $i in (1 to count($str-sequence))
                     return
                        ('String ' || $str-labels[$i] || ': ' || tan:ellipses($str-sequence[$i], 20)))
                     "/>
            </xsl:if>
            <!-- Apply the standard tan:collate(), but without superskeleton on, and pass results 
               through template to make sure positions are correct. -->
            <xsl:apply-templates select="tan:collate($str-sequence, $str-labels, false(), true())"
               mode="adjust-collation-pos-attrs">
               <xsl:with-param name="string-labels" tunnel="yes" select="$str-labels"/>
               <xsl:with-param name="position-offsets" tunnel="yes" select="$str-positions"/>
            </xsl:apply-templates>
         </xsl:when>

         <xsl:otherwise>
            <!-- Now we can search for parts of the short string within each of the longer strings -->

            <xsl:iterate select="$vertical-stops-to-process">

               <xsl:on-completion>
                  <!-- If we have gotten to this stage, no vertical stops work, and the strings are
                     for all intents and purposes unique -->
                  <xsl:sequence select="$no-match-result-tree"/>
               </xsl:on-completion>

               <xsl:variable name="this-vertical-stop" select="." as="xs:double"/>
               <xsl:variable name="percent-of-short-to-check"
                  select="min((max(($this-vertical-stop, 0.0000001)), 1.0))" as="xs:double"/>
               <xsl:variable name="length-of-sample" as="xs:integer"
                  select="xs:integer(ceiling($shortest-length * $percent-of-short-to-check))"/>
               <!-- If the sample size is at or below a certain predetermined threshold, draw the maximum number of samples that
                  the short string will allow. Otherwise, -->
               <xsl:variable name="number-of-horizontal-passes" select="
                     if ($length-of-sample le $tan:diff-suspend-horizontal-pass-maximum-when-sample-sizes-reach-what) then
                        $longest-length - $length-of-sample + 1
                     else
                        xs:integer(math:pow(1 - $percent-of-short-to-check, (1 div $tan:diff-horizontal-pass-frequency-rate)) * $tan:diff-maximum-number-of-horizontal-passes) + 1"
                  as="xs:integer"/>
               <xsl:variable name="length-of-play-in-short" as="xs:integer"
                  select="$shortest-length - $length-of-sample"/>
               <xsl:variable name="horizontal-stagger" as="xs:double"
                  select="$length-of-play-in-short div max(($number-of-horizontal-passes - 1, 1))"/>
               <xsl:variable name="starting-horizontal-locs" as="xs:integer+" select="
                     distinct-values(for $i in (1 to $number-of-horizontal-passes)
                     return
                        xs:integer(ceiling(($i - 1) * $horizontal-stagger) + 1))"/>

               <xsl:variable name="horizontal-search" as="element()*">
                  <!-- Look for a match horizontally -->
                  <xsl:iterate select="$starting-horizontal-locs">
                     <xsl:variable name="this-search-string" as="xs:string"
                        select="substring($shortest-string, ., $length-of-sample)"/>

                     <xsl:variable name="skeleton-is-detected" as="xs:boolean" select="
                           every $i in $longest-strings
                              satisfies
                              contains($i, $this-search-string)"/>

                     <!-- The superskeleton is ambiguous when there are multiple instances in at least one version -->
                     <!-- Unlike tan:diff(), the strategy here is to find the aggregate mean instance, then to find in each
                           version the instance shares the closest position that mean does to its context -->
                     <xsl:variable name="skeleton-match-is-unambiguous" as="xs:boolean">
                        <xsl:try select="
                              $skeleton-is-detected and
                              (every $i in $str-sequence
                                 satisfies
                                 (let $k := substring-after($i, $this-search-string)
                                 return
                                    not(contains($k, $this-search-string))))">
                           <xsl:catch>
                              <xsl:message
                                 select="'Oops, not too sure what happened, but could not see if skeleton is unambiguous'"/>
                              <xsl:sequence select="true()"/>
                           </xsl:catch>
                        </xsl:try>
                     </xsl:variable>

                     <xsl:choose>
                        <!-- The following happens when the $length-of-short-substring is 0 -->
                        <xsl:when test="$this-search-string eq ''"/>
                        <!-- If we are down to undesired anchor sizes, drop out -->
                        <xsl:when test="$length-of-sample lt $min-sample-size-norm">
                           <xsl:break/>
                        </xsl:when>

                        <xsl:when test="$skeleton-is-detected">

                           <!-- Ah, but what about if there are multiple hits? -->
                           <xsl:variable name="tok-input" as="element()*">
                              <xsl:if test="not($skeleton-match-is-unambiguous)">
                                 <xsl:sequence select="
                                       for $i in $str-sequence
                                       return
                                          analyze-string($i, $this-search-string, 'q')"
                                 />
                              </xsl:if>
                           </xsl:variable>
                           <xsl:variable name="tok-input-min" as="xs:integer?" select="
                                 min(for $i in $tok-input
                                 return
                                    count($i/*:match))"/>
                           <!-- In simplified cluster -->
                           <xsl:variable name="match-permutations" as="xs:integer?"
                              select="math:pow($tok-input-min * 2, $str-count) idiv 2"/>
                           <!-- TODO: when reconciling this loop with the core tan:loop() the
                              global parameter will need to be renamed, and redocumented to
                              point to the more generalized approach to resolution of 
                              ambiguity. -->
                           <xsl:variable name="resolving-match-ambiguity-is-worthwhile"
                              as="xs:boolean" select="
                                 exists($match-permutations) and
                                 $match-permutations lt $tan:collate-superskeleton-match-ambiguity-check-ceiling"
                           />
                           
                           <xsl:if test="$skeleton-match-is-unambiguous or $resolving-match-ambiguity-is-worthwhile">
                              
                              <xsl:variable name="tok-positions" as="array(xs:decimal+)?">
                                 <xsl:if test="not($skeleton-match-is-unambiguous)">
                                    <xsl:sequence select="
                                          array:join(
                                          for $i in (1 to $str-count)
                                          return
                                             [
                                                for $j in $tok-input[$i]/*:match
                                                return
                                                   (string-length(string-join($j/preceding-sibling::*)) + 1) div $str-lengths[$i]
                                             ]
                                          )"/>
                                 </xsl:if>
                              </xsl:variable>
                              <xsl:variable name="best-cluster" as="xs:decimal*">
                                 <xsl:if test="not($skeleton-match-is-unambiguous)">
                                    <xsl:sequence select="tan:closest-cluster($tok-positions)"/>
                                 </xsl:if>
                              </xsl:variable>
                              <xsl:variable name="best-positions" as="xs:integer*">
                                 <xsl:if test="not($skeleton-match-is-unambiguous)">
                                    <xsl:sequence select="
                                          for $i in (1 to $str-count)
                                          return
                                             index-of($tok-positions($i), $best-cluster[$i])[1]"
                                    />
                                 </xsl:if>
                              </xsl:variable>
   
   
                              <xsl:variable name="head-string-sequence" as="xs:string*" select="
                                    if ($skeleton-match-is-unambiguous) then
                                       for $i in $str-sequence
                                       return
                                          substring-before($i, $this-search-string)
                                    else
                                       (for $i in (1 to $str-count)
                                       return
                                          string-join($tok-input[$i]/*:match[$best-positions[$i]]/preceding-sibling::*))"/>
                              <xsl:variable name="tail-string-sequence" as="xs:string*" select="
                                    if ($skeleton-match-is-unambiguous) then
                                       for $i in $str-sequence
                                       return
                                          substring-after($i, $this-search-string)
                                    else
                                       (for $i in (1 to $str-count)
                                       return
                                          string-join($tok-input[$i]/*:match[$best-positions[$i]]/following-sibling::*))"/>
                              <xsl:variable name="anchor-head-addendum" as="xs:string?"
                                 select="tan:common-end-string($head-string-sequence)"/>
                              <xsl:variable name="anchor-tail-addendum" as="xs:string?"
                                 select="tan:common-start-string($tail-string-sequence)"/>
                              <xsl:variable name="full-anchor" as="xs:string"
                                 select="$anchor-head-addendum || $this-search-string || $anchor-tail-addendum"/>
                              <xsl:variable name="full-anchor-length" as="xs:integer"
                                 select="string-length($full-anchor)"/>
                              <xsl:variable name="head-addendum-length" as="xs:integer"
                                 select="string-length($anchor-head-addendum)"/>
                              <xsl:variable name="tail-addendum-length" as="xs:integer"
                                 select="string-length($anchor-tail-addendum)"/>
   
                              <xsl:variable name="head-strings-to-reevaluate" as="xs:string*" select="
                                    for $i in $head-string-sequence
                                    return
                                       substring($i, 1, string-length($i) - $head-addendum-length)"/>
                              <xsl:variable name="tail-strings-to-reevaluate" as="xs:string*" select="
                                    for $i in $tail-string-sequence
                                    return
                                       substring($i, $tail-addendum-length + 1)"/>
                              <xsl:variable name="tail-str-positions" as="xs:integer*" select="
                                    for $i in (1 to $str-count)
                                    return
                                       $str-positions[$i] + string-length($head-strings-to-reevaluate[$i]) + $full-anchor-length"/>
   
                              <xsl:variable name="inner-diagnostics-on" as="xs:boolean"
                                 select="false()"/>
                              <xsl:if test="$inner-diagnostics-on">
                                 <xsl:message
                                    select="'Inner diagnostics on, tan:multiple-string-diff-loop, $horizontal-search'"/>
                                 <xsl:message select="'Search string: ', $this-search-string"/>
                                 <xsl:message select="'Skeleton detected?: ', $skeleton-is-detected"/>
                                 <xsl:message
                                    select="'Skeleton is unambiguous?: ', $skeleton-match-is-unambiguous"/>
                                 <xsl:if test="not($skeleton-match-is-unambiguous)">
                                    <xsl:message select="'tok input: ', $tok-input"/>
                                    <xsl:message
                                       select="'tok positions: ', tan:array-to-xml($tok-positions)"/>
                                    <xsl:message select="'best cluster: ', $best-cluster"/>
                                    <xsl:message select="'best positions: ', $best-positions"/>
                                 </xsl:if>
                                 <xsl:message
                                    select="'head string sequence: [', string-join($head-string-sequence, ' ], [ '), ']'"/>
                                 <xsl:message
                                    select="'tail string sequence: [', string-join($tail-string-sequence, ' ], [ '), ']'"
                                 />
                              </xsl:if>
   
                              <!-- Output -->
   
                              <!-- Reevaluate the head -->
                              <xsl:sequence select="
                                    tan:multiple-string-diff-loop($head-strings-to-reevaluate, $str-labels, $str-positions,
                                    $vertical-stops-to-process, $min-sample-size-norm, $loop-counter + 1)"/>
   
                              <!-- Write the anchor -->
                              <c>
                                 <txt>
                                    <xsl:value-of select="$full-anchor"/>
                                 </txt>
                                 <xsl:for-each select="1 to $str-count">
                                    <xsl:variable name="i" as="xs:integer" select="."/>
                                    <wit ref="{$str-labels[$i]}"
                                       pos="{$str-positions[$i] + string-length($head-strings-to-reevaluate[$i])}"
                                    />
                                 </xsl:for-each>
                              </c>
                              <!-- Reevaluate the tail -->
                              <xsl:sequence select="
                                    tan:multiple-string-diff-loop($tail-strings-to-reevaluate, $str-labels, $tail-str-positions,
                                    $vertical-stops-to-process, $min-sample-size-norm, $loop-counter + 1)"/>
                              <!-- Stop iterating -->
                              <xsl:break/>
                           </xsl:if>
                        </xsl:when>


                        <xsl:otherwise>
                           <xsl:next-iteration/>
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:iterate>
               </xsl:variable>

               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'loop counter', $loop-counter"/>
                  <xsl:message select="'string count: ', $str-count"/>
                  <xsl:for-each select="1 to $str-count">
                     <xsl:variable name="this-pos" as="xs:integer" select="."/>
                     <xsl:message
                        select="$str-labels[$this-pos], ': ', tan:ellipses($str-sequence[$this-pos], 11)"
                     />
                  </xsl:for-each>
                  <xsl:message select="'$short-size:', $shortest-length"/>
                  <xsl:message select="'$this-vertical-stop:', $this-vertical-stop"/>
                  <xsl:message select="'$percent-of-short-to-check:', $percent-of-short-to-check"/>
                  <xsl:message select="'$length-of-sample:', $length-of-sample"/>
                  <xsl:message select="'$number-of-horizontal-passes:', $number-of-horizontal-passes"/>
                  <xsl:message select="'$horizontal-stagger:', $horizontal-stagger"/>
                  <xsl:message select="'$starting-horizontal-locs:', $starting-horizontal-locs"/>
                  <xsl:message select="'$length-of-play-in-short:', $length-of-play-in-short"/>
                  <xsl:message select="'horizontal search: ', $horizontal-search"/>
               </xsl:if>

               <xsl:choose>

                  <xsl:when test="exists($horizontal-search)">
                     <xsl:break select="$horizontal-search"/>
                  </xsl:when>
                  <xsl:when test="$length-of-sample le 1">
                     <xsl:break select="$no-match-result-tree"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:next-iteration/>
                  </xsl:otherwise>
               </xsl:choose>

            </xsl:iterate>

         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:mode name="adjust-collation-pos-attrs" on-no-match="shallow-copy"/>
   <xsl:template match="tan:witness" mode="adjust-collation-pos-attrs"/>
   <xsl:template match="tan:collation" mode="adjust-collation-pos-attrs">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="tan:wit[@ref][@pos]" mode="adjust-collation-pos-attrs">
      <xsl:param name="string-labels" tunnel="yes" as="xs:string*"/>
      <xsl:param name="position-offsets" tunnel="yes" as="xs:integer*"/>
      <xsl:variable name="index" as="xs:integer*" select="index-of($string-labels, @ref)"/>
      <xsl:variable name="curr-offset" as="xs:integer?" select="$position-offsets[$index[1]] - 1"/>
      
      <xsl:copy>
         <xsl:copy-of select="@* except @pos"/>
         <xsl:choose>
            <xsl:when test="count($index) eq 0">
               <xsl:message select="'No index entry found for ' || @ref"/>
               <xsl:copy-of select="@pos"/>
            </xsl:when>
            <xsl:when test="count($index) gt 1">
               <xsl:message select="'Multiple index entries found for ' || @ref"/>
               <xsl:copy-of select="@pos"/>
            </xsl:when>
            <xsl:when test="not(exists($curr-offset))">
               <xsl:message select="'No offset value was found for ' || @ref"/>
               <xsl:copy-of select="@pos"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:attribute name="pos" select="xs:integer(@pos) + $curr-offset"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
      
   </xsl:template>
   
   
   
   
   
</xsl:stylesheet>
