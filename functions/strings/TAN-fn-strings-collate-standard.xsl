<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library collate string functions. -->
   
   <xsl:function name="tan:collation-to-strings" as="element()*" visibility="private">
      <!-- Input: any output from tan:collate (version for XSLT 3.0) -->
      <!-- Output: a sequence of <witness id="">[ORIGINAL STRING]</witness> -->
      <!-- This function was written to reverse, and therefore test the integrity of, the output of tan:collate() -->
      <xsl:param name="tan-collate-output" as="element()?"/>
      <xsl:apply-templates select="$tan-collate-output/tan:witness" mode="tan:collation-to-strings"/>
   </xsl:function>
   
   <xsl:mode name="tan:collation-to-strings"/>
   
   <xsl:template match="tan:witness" mode="tan:collation-to-strings">
      <xsl:variable name="this-id" select="@id"/>
      <xsl:variable name="text-nodes" select="../*[tan:wit/@ref = $this-id]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="string-join($text-nodes/tan:txt)"/>
      </xsl:copy>
      <xsl:iterate select="$text-nodes">
         <xsl:param name="next-pos" select="1"/>
         <xsl:variable name="this-pos" select="tan:wit[@ref = $this-id]/@pos"/>
         <xsl:variable name="this-length" select="string-length(tan:txt)"/>
         <xsl:if test="not($next-pos = $this-pos)">
            <xsl:message select="'In text ' || $this-id || ', next position expected was ', $next-pos, ' but stated @pos is ' || $this-pos || '. See text fragment: ' || tan:txt"/>
         </xsl:if>
         <xsl:next-iteration>
            <xsl:with-param name="next-pos" select="$next-pos + $this-length"/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:template>
   
   
   <xsl:function name="tan:collate" as="element()?" visibility="public">
      <!-- 1-parameter version of fuller one, below -->
      <xsl:param name="strings-to-collate" as="xs:string*"/>
      <xsl:variable name="string-labels" as="xs:string+">
         <xsl:for-each select="$strings-to-collate">
            <xsl:value-of select="position()"/>
         </xsl:for-each>
      </xsl:variable>
      <xsl:sequence select="tan:collate($strings-to-collate, $string-labels)"/>
   </xsl:function>
   
   <xsl:function name="tan:collate" as="element()?" visibility="public">
      <!-- 2-parameter version of fuller one, below -->
      <xsl:param name="strings-to-collate" as="xs:string*"/>
      <xsl:param name="string-labels" as="xs:string*"/>
      <xsl:sequence
         select="tan:collate($strings-to-collate, $string-labels, true())"
      />
   </xsl:function>
   
   <xsl:function name="tan:collate" as="element()?" visibility="public">
      <!-- 3-parameter version of fuller one, below -->
      <xsl:param name="strings-to-collate" as="xs:string*"/>
      <xsl:param name="string-labels" as="xs:string*"/>
      <xsl:param name="preoptimize-string-order" as="xs:boolean"/>
      <xsl:sequence
         select="tan:collate($strings-to-collate, $string-labels, $preoptimize-string-order, true(), true())"
      />
   </xsl:function>
   
   
   <xsl:function name="tan:collate" as="element()?" visibility="public">
      <!-- 5-parameter version of fuller one, below -->
      <xsl:param name="strings-to-collate" as="xs:string*"/>
      <xsl:param name="string-labels" as="xs:string*"/>
      <xsl:param name="preoptimize-string-order" as="xs:boolean"/>
      <xsl:param name="adjust-diffs-during-preoptimization" as="xs:boolean"/>
      <xsl:param name="clean-up-collation" as="xs:boolean"/>
      <xsl:sequence
         select="tan:collate($strings-to-collate, $string-labels, $preoptimize-string-order, $adjust-diffs-during-preoptimization, $clean-up-collation, $tan:snap-to-word)"
      />
   </xsl:function>
   
   <xsl:function name="tan:collate" as="element()?" visibility="public">
      <!-- Input: a sequence of strings to be collated; a sequence of strings that label each string; a boolean
      indicating whether the sequence of input strings should be optimized; a boolean indicating whether
      the results of tan:diff() should be processed and weighed; a boolean indicating whether the collation 
      should be cleaned up; a boolean whether diffs should be processed word for word or not. -->
      <!-- Output: a <collation> with (1) one <witness> per string (and if the last parameter is true, then a 
         sequence of children <commonality>s, signifying how close that string is with every other, and (2)
         a sequence of <c>s and <u>s, each with a <txt> and one or more <wit ref="" pos=""/>, indicating which
         string witness attests to the [c]ommon or [u]nique reading, and what position in that string the 
         particular text fragment starts at. -->
      <!-- If there are not enough labels (2nd parameter) for the input strings, the numerical position of 
      the input string will be used as the string label / witness id. -->
      <!-- If the third parameter is true, then tan:diff() will be performed against each pair of strings. Each
      diff output will be weighed by closeness of the two texts, and sorted accordingly. The results of this 
      operation will be stored in collation/witness/commonality. This requires (n-1)! operations, so should 
      be efficient for a few input strings, but will grow progressively longer according to the number and 
      size of the input strings. Preoptimizing strings will likely produces greater congruence in the <u>
      fragments. -->
      <!-- If the last parameter is true, then cleanup will not be performed. This parameter was introduced
      because the cleanup process itself invokes tan:collate() and one does not want to get into an endless 
      loop because of a mishmash of differences that can never be reconciled or brought closer together. -->
      <!-- This version of tan:collate was written in XSLT 3.0 to take advantage of xsl:iterate, and has an
      arity of 3, 5, or 6 parameters, unlike its XSLT 2.0 predecessors, which also applied a different approach 
      to collation. -->
      <!-- Changes in output from previous version of tan:collate():
          - @w is now <wit> with @ref and @pos
          - the text node of <u> or <c> is now wrapped in <txt>
          - @length is ignored (the value is easily calculated)
        With these changes, any witness can be easily reconstructed with the XPath expression 
        tan:collation/()
      -->
      <!--kw: strings, diff -->
      <xsl:param name="strings-to-collate" as="xs:string*"/>
      <xsl:param name="string-labels" as="xs:string*"/>
      <xsl:param name="preoptimize-string-order" as="xs:boolean"/>
      <xsl:param name="adjust-diffs-during-preoptimization" as="xs:boolean"/>
      <xsl:param name="clean-up-collation" as="xs:boolean"/>
      <xsl:param name="snap-to-word" as="xs:boolean"/>

      <xsl:variable name="string-count" select="count($strings-to-collate)"/>
      <xsl:variable name="string-labels-norm" as="xs:string*" select="
            for $i in (1 to $string-count)
            return
               ($string-labels[$i], string($i))[1]"/>


      <xsl:variable name="all-diffs" as="element()*">
         <xsl:if test="$preoptimize-string-order">
            <xsl:for-each select="$string-labels-norm[position() gt 1]">
               <xsl:variable name="text1" select="."/>
               <xsl:variable name="this-pos" select="position() + 1"/>
               <xsl:for-each select="$string-labels-norm[position() lt $this-pos]">
                  <xsl:variable name="text2" select="."/>
                  <xsl:variable name="that-pos" select="position()"/>
                  <xsl:variable name="this-diff"
                     select="tan:diff-cache($strings-to-collate[$that-pos], $strings-to-collate[$this-pos], $snap-to-word, true())"/>
                  <xsl:variable name="this-diff-adjusted" select="
                        if ($adjust-diffs-during-preoptimization) then
                           tan:adjust-diff($this-diff)
                        else
                           $this-diff"/>
                  <diff a="{$text2}" b="{$text1}">
                     <xsl:copy-of select="$this-diff-adjusted/*"/>
                  </diff>
               </xsl:for-each>
            </xsl:for-each>
         </xsl:if>
      </xsl:variable>

      <xsl:variable name="diffs-sorted" as="element()*">
         <xsl:for-each-group select="$all-diffs" group-by="
               sum((for $i in tan:common
               return
                  string-length($i))) div (sum((for $j in tan:*
               return
                  string-length($j))) - (sum((for $k in (tan:a, tan:b)
               return
                  string-length($k))) div 2))">
            <xsl:sort order="descending" select="current-grouping-key()"/>
            <xsl:for-each select="current-group()">
               <xsl:copy>
                  <xsl:attribute name="commonality" select="current-grouping-key()"/>
                  <xsl:copy-of select="@* | node()"/>
               </xsl:copy>
            </xsl:for-each>
         </xsl:for-each-group>
      </xsl:variable>

      <!-- April 2022: trying a different algorithm, based on average global commonality, 
         not pairwise. -->
      <!--<xsl:variable name="string-labels-re-sorted" select="
            if ($preoptimize-string-order) then
               distinct-values(for $i in $diffs-sorted
               return
                  ($i/@a, $i/@b))
            else
               $string-labels-norm"/>-->
      <xsl:variable name="string-labels-re-sorted" as="xs:string+">
         <xsl:choose>
            <xsl:when test="$preoptimize-string-order">
               <xsl:for-each select="$string-labels-norm">
                  <xsl:sort select="
                        sum((let $this := .
                        return
                           for $i in $diffs-sorted[(@a, @b) = $this]
                           return
                              number($i/@commonality)))" order="descending"/>
                  <xsl:sequence select="."/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$string-labels-norm"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="strings-re-sorted" select="
            if ($preoptimize-string-order) then
               (for $i in $string-labels-re-sorted,
                  $j in index-of($string-labels-norm, $i)
               return
                  $strings-to-collate[$j])
            else
               $strings-to-collate"/>

      <xsl:variable name="first-diff"
         select="tan:diff-cache($strings-re-sorted[1], $strings-re-sorted[2], $snap-to-word, true())"/>
      <xsl:variable name="first-diff-adjusted" select="
            if ($adjust-diffs-during-preoptimization) then
               tan:adjust-diff($first-diff)
            else
               $first-diff"/>
      <xsl:variable name="first-diff-collated"
         select="tan:diff-to-collation($first-diff-adjusted, $string-labels-re-sorted[1], $string-labels-re-sorted[2])"/>

      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, 2020 version of tan:collate()'"/>
         <xsl:message select="'String count: ', $string-count"/>
         <xsl:message
            select="'String labels re-sorted: ' || string-join($string-labels-re-sorted, ' ')"/>
         <xsl:message select="'First diff (adjusted): ' || serialize($first-diff-adjusted)"/>
         <xsl:message select="'First diff collated: ' || serialize($first-diff-collated)"/>
      </xsl:if>

      <xsl:variable name="fragmented-collation" as="element()*">
         <!-- If this is just a 2-way diff, then leave the collation as is -->
         <xsl:if test="not(exists($strings-re-sorted[3]))">
            <xsl:sequence select="$first-diff-collated"/>
         </xsl:if>
         <xsl:iterate select="$strings-re-sorted[position() gt 2]" exclude-result-prefixes="#all">
            <xsl:param name="collation-so-far" as="element()?" select="$first-diff-collated"/>
            <!-- The previous string is a text that links the previous collation and the diff that is about to be run. -->
            <xsl:param name="previous-string" as="xs:string?" select="$strings-re-sorted[2]"/>
            <xsl:param name="previous-string-label" as="xs:string?"
               select="$string-labels-re-sorted[2]"/>

            <xsl:variable name="iteration" select="position() + 2"/>
            <xsl:variable name="this-label" select="$string-labels-re-sorted[$iteration]"/>

            <xsl:variable name="this-diff" as="element()"
               select="tan:diff-cache($previous-string, ., $snap-to-word, true())"/>
            <xsl:variable name="this-diff-adjusted" as="element()" select="
                  if ($adjust-diffs-during-preoptimization) then
                     tan:adjust-diff($this-diff)
                  else
                     $this-diff"/>
            <xsl:variable name="this-diff-collation" as="element()"
               select="tan:diff-to-collation($this-diff-adjusted, $previous-string-label, $this-label)"/>

            <!-- The linking text is split in different ways, both in the base collation and the collation to add. Each of those
            should be splintered up so that every starting position for the linking in one collation is also reflected in the other.-->

            <xsl:variable name="pos-values-compared" as="element()">
               <pos-compared>
                  <xsl:for-each-group
                     select="$collation-so-far/*/*[@ref = $previous-string-label]/@pos, $this-diff-collation/*/*[@ref = $previous-string-label]/@pos"
                     group-by=".">
                     <xsl:sort select="number(current-grouping-key())"/>
                     <xsl:variable name="group-root-elements"
                        select="current-group()/ancestor::tan:collation"/>
                     <group pos="{current-grouping-key()}">
                        <xsl:if test="exists($group-root-elements[tan:witness/@id = $this-label])">
                           <new/>
                        </xsl:if>
                        <xsl:if
                           test="exists($group-root-elements[not(tan:witness/@id = $this-label)])">
                           <base/>
                        </xsl:if>
                     </group>
                  </xsl:for-each-group>
               </pos-compared>
            </xsl:variable>
            <xsl:variable name="pos-values-to-add" as="element()">
               <pos-to-add>
                  <in-base-collation>
                     <xsl:for-each-group select="$pos-values-compared/tan:group"
                        group-starting-with="*[tan:base]">
                        <xsl:if test="count(current-group()) gt 1">
                           <break>
                              <xsl:copy-of select="current-group()[1]/@*"/>
                              <xsl:for-each select="current-group()[position() gt 1]">
                                 <at-pos>
                                    <xsl:value-of select="@pos"/>
                                 </at-pos>
                              </xsl:for-each>
                           </break>
                        </xsl:if>
                     </xsl:for-each-group>
                  </in-base-collation>
                  <in-new-collation>
                     <xsl:for-each-group select="$pos-values-compared/tan:group"
                        group-starting-with="*[tan:new]">
                        <xsl:if test="count(current-group()) gt 1">
                           <break>
                              <xsl:copy-of select="current-group()[1]/@*"/>
                              <xsl:for-each select="current-group()[position() gt 1]">
                                 <at-pos>
                                    <xsl:value-of select="@pos"/>
                                 </at-pos>
                              </xsl:for-each>
                           </break>
                        </xsl:if>
                     </xsl:for-each-group>
                  </in-new-collation>

               </pos-to-add>
            </xsl:variable>

            <xsl:variable name="both-collations-splintered" as="element()*">
               <!-- The strategy here is to go through each collation and fragment any <c> or <u> where the linking
               text has text that should be broken up to match the other collation. -->
               <xsl:for-each select="$collation-so-far, $this-diff-collation">
                  <xsl:variable name="this-collation" select="."/>
                  <xsl:variable name="this-collation-position" select="position()"/>
                  <xsl:variable name="this-is-base-collation" select="$this-collation-position eq 1"/>
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:attribute name="is-base" select="$this-is-base-collation"/>
                     <!-- group each <u> and <c> based on whether a child <x> or <wit> for the linking text has a matching position -->
                     <xsl:for-each-group select="*"
                        group-by="(*[@ref = $previous-string-label]/@pos, '-1')[1]">
                        <xsl:variable name="this-pos-val" select="current-grouping-key()"/>
                        <xsl:variable name="break-points"
                           select="$pos-values-to-add/*[$this-collation-position]/tan:break[@pos = $this-pos-val]/tan:at-pos"/>
                        <xsl:choose>
                           <xsl:when test="not(exists($break-points)) or ($this-pos-val = '0')">
                              <xsl:copy-of select="current-group()" copy-namespaces="no"/>
                           </xsl:when>
                           <xsl:otherwise>
                              <xsl:variable name="this-pos-int" select="xs:integer($this-pos-val)"/>
                              <xsl:variable name="these-break-point-ints" select="
                                    for $i in $break-points
                                    return
                                       xs:integer($i)"/>
                              <xsl:for-each select="current-group()">
                                 <xsl:variable name="this-element" select="."/>
                                 <xsl:variable name="this-text" select="tan:txt/text()"/>
                                 <xsl:variable name="this-text-length"
                                    select="string-length($this-text)"/>
                                 <xsl:variable name="next-segment-start-pos"
                                    select="$this-pos-int + $this-text-length"/>
                                 <xsl:choose>
                                    <xsl:when
                                       test="self::tan:c or (tan:wit/@ref = $previous-string-label)">
                                       <xsl:for-each
                                          select="($this-pos-int, $these-break-point-ints)">
                                          <xsl:variable name="this-position" select="position()"/>
                                          <xsl:variable name="this-new-pos-int" select="."/>
                                          <xsl:variable name="this-substring-start"
                                             select="$this-new-pos-int - $this-pos-int + 1"/>
                                          <xsl:variable name="next-start-pos"
                                             select="($these-break-point-ints, $next-segment-start-pos)[$this-position]"/>
                                          <xsl:variable name="this-substring-length"
                                             select="$next-start-pos - $this-new-pos-int"/>
                                          <xsl:variable name="this-text-portion"
                                             select="substring($this-text, $this-substring-start, $this-substring-length)"/>

                                          <xsl:if test="$diagnostics-on">
                                             <xsl:message
                                                select="'Starting splinter ', $this-position, 'at ', $this-new-pos-int"/>
                                             <xsl:message
                                                select="'Substring start: ', $this-substring-start"/>
                                             <xsl:message
                                                select="'Substring length: ', $this-substring-length"/>
                                             <xsl:message
                                                select="'Text portion: ' || $this-text-portion"/>
                                          </xsl:if>

                                          <xsl:element name="{name($this-element)}"
                                             namespace="tag:textalign.net,2015:ns">
                                             <xsl:copy-of select="$this-element/@*"/>
                                             <txt>
                                                <xsl:value-of select="$this-text-portion"/>
                                             </txt>
                                             <xsl:for-each select="$this-element/tan:wit">
                                                <xsl:variable name="this-diff-with-linking-text-pos"
                                                  select="$this-pos-int - xs:integer(@pos)"/>
                                                <xsl:copy copy-namespaces="no">
                                                  <xsl:copy-of select="@ref"/>
                                                  <xsl:attribute name="pos"
                                                  select="$this-new-pos-int - $this-diff-with-linking-text-pos"
                                                  />
                                                </xsl:copy>
                                             </xsl:for-each>
                                             <xsl:copy-of select="$this-element/tan:x"/>
                                          </xsl:element>
                                       </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                       <xsl:copy-of select="." copy-namespaces="no"/>
                                    </xsl:otherwise>
                                 </xsl:choose>
                              </xsl:for-each>
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each-group>

                  </xsl:copy>
               </xsl:for-each>

            </xsl:variable>


            <xsl:variable name="new-base-collation" as="element()">
               <collation>
                  <!-- We copy the <witness> elements both for breadcrumbs and to provide the critical ligament
                  from one collation to the next. -->
                  <xsl:copy-of select="$collation-so-far/tan:witness"/>
                  <witness id="{$this-label}"/>

                  <!-- The collations we are gathering consist of elements that have identical sequences of @pos for the linking
                  text, and they are in numerical order. So by grouping by the linking text @pos, we are guaranteed groups 
                  made up of the following items from the two collations:
                       - From the base collation: zero or more <u>s without the linking text then either a <u> with the 
                          linking text as a witness or a <c> (also obviously with the linking text and every other version so far)
                       - From the new collation: zero or one <u> without the linking text then either a <u> with only 
                          the linking text as a witness (i.e., the new text is marked <x>) or a <c> (with both texts)
                  In both collations, the last group might not have the final <u>/<c> with the linking text. (The linking text
                  might finish before other texts do.)
                      The strategy is to group together from both collations (1) the initial <u>s that lack the linking text, then 
                  (2) the final zero, one, or two <u>/<c>s that have a linking text.
                      For #1, group if the text of a new <u> matches a text of a base <u>, retain that <u> but imprint a <wit> for
                      the new string, otherwise append the new <u> as-is. Any base <u>s that don't match should have an <x>
                      imprinted for the new text.
                      For #2, the following happens for the following possibilities:
                      Base <u> + new <u>                                       retain base <u>, imprinting an <x> for the new string
                      Base <c> + new <u>                                        convert base to <u>, imprinting an <x> for the new string
                      Base <u> + new <c>                                        retain base <u>, imprinting a <wit> for the new string
                      Base <c> + new <c>                                        retain base <c>, imprinting a <wit> for the new string
                              Note that the first two scenarios hold true simply if there is a new <u> (not attested in the new
                              string). Further, the final group might have:
                      No base element + no new element         nothing
                -->
                  <xsl:for-each-group select="$both-collations-splintered/*"
                     group-by="*[@ref = $previous-string-label]/@pos">
                     <!--<xsl:sort select="number(current-grouping-key())"/>-->

                     <!-- If from the groups about to be created the first of the two groups fails to have a reference to
                     the incoming text, we need a reference with an accurate @pos, so now we get all those that are 
                     available. -->
                     <xsl:variable name="refs-to-new-text"
                        select="current-group()/*[@ref = $this-label]"/>

                     <xsl:for-each-group select="current-group()"
                        group-by="exists(tan:wit[@ref = $previous-string-label])">
                        <!-- If indeed the group has a reading from the linking text, it should come second, and the sort places 
                           false before true -->
                        <xsl:sort select="current-grouping-key()"/>
                        <xsl:variable name="group-has-linking-text" select="current-grouping-key()"/>
                        <xsl:variable name="these-base-collation-items"
                           select="current-group()[ancestor::tan:collation/@is-base = true()]"/>
                        <!-- We know there will be no more than one of the following -->
                        <xsl:variable name="this-new-collation-item"
                           select="current-group() except $these-base-collation-items"/>
                        <xsl:choose>
                           <xsl:when test="count($this-new-collation-item) gt 1">
                              <xsl:message
                                 select="'Unexpected: more than one new collation item: ', serialize($this-new-collation-item)"
                              />
                           </xsl:when>

                           <xsl:when test="not($group-has-linking-text)">
                              <!-- scenario #1, the front end described above -->

                              <xsl:variable name="base-text-match-positions" select="
                                    for $i in (1 to count($these-base-collation-items))
                                    return
                                       (if ($these-base-collation-items[$i]/tan:txt = $this-new-collation-item/tan:txt) then
                                          $i
                                       else
                                          ())"/>
                              <xsl:for-each select="$these-base-collation-items">
                                 <xsl:copy>
                                    <xsl:copy-of select="node()"/>
                                    <xsl:choose>
                                       <!-- If the incoming new item matches the text of more than one base item, use only the last to
                                       make a copy of the new witness. -->
                                       <xsl:when
                                          test="position() = $base-text-match-positions[last()]">
                                          <xsl:copy-of select="$this-new-collation-item/tan:wit"/>
                                       </xsl:when>

                                       <xsl:when
                                          test="(exists($base-text-match-positions)) and (position() gt $base-text-match-positions[last()])">
                                          <!-- For items after the last match, we need to increase the @pos by however long the string was -->
                                          <x>
                                             <xsl:copy-of
                                                select="$this-new-collation-item/tan:wit/@ref"/>
                                             <xsl:attribute name="pos"
                                                select="number($this-new-collation-item/tan:wit/@pos) + string-length($this-new-collation-item/tan:txt)"
                                             />
                                          </x>
                                       </xsl:when>
                                       <xsl:otherwise>
                                          <x>
                                             <xsl:copy-of select="$refs-to-new-text[1]/@*"/>
                                          </x>
                                       </xsl:otherwise>
                                    </xsl:choose>
                                 </xsl:copy>
                              </xsl:for-each>
                              <xsl:if test="not(exists($base-text-match-positions))">
                                 <!-- If there are no unique elements in the base that have a matching text, then insert the new 
                                    unique element -->
                                 <xsl:copy-of select="$this-new-collation-item"/>
                              </xsl:if>
                           </xsl:when>

                           <!-- error checks betwen scenarios #1 and #2, and special situations -->

                           <xsl:when test="count($these-base-collation-items) gt 1">
                              <xsl:message
                                 select="'Unexpected: more than one base collation item: ', serialize($these-base-collation-items)"/>
                              <xsl:message
                                 select="'Accompanying new collation item: ', serialize($this-new-collation-item)"
                              />
                           </xsl:when>
                           <!-- If the current group is just a placeholder, but has no actual text, skip it -->
                           <xsl:when test="not(current-group()/tan:txt/text())"/>

                           <!-- The following two special situations, where <txt> is empty, have been replaced by the preceding <xsl:when> -->
                           <!--<xsl:when test="(count(current-group()) eq 1) and (name($this-new-collation-item) = 'c') and not($this-new-collation-item/tan:txt/text())">
                              <!-\- This is a case where we're at the end of the iteration, the base collation ends with a <u> because the
                              linking text isn't in it, and the new collation ends with a <c> that lacks text, because both the new text also lacks text 
                              at that place. In this case we can just drop the item altogether. If the next string goes beyond the limits, the
                              algorithm should still work normally. -\->
                              <!-\-<xsl:copy-of select="$this-new-collation-item"/>-\->
                           </xsl:when>-->
                           <!--<xsl:when test="(count(current-group()) eq 1) and (name($these-base-collation-items[1]) = 'c') and not(current-group()/tan:txt/text())">
                              <!-\- This is a case where we're at the end of the iteration, the base collation ends with a <c> that has an empty
                              <txt> and the new collation has nothing. In this case we can just drop the item altogether. -\->
                           </xsl:when>-->
                           <xsl:when test="count(current-group()) eq 1">
                              <xsl:message select="
                                    'We expect collation items to come in groups of two or more; only one item (' || (if (exists($this-new-collation-item)) then
                                       'new'
                                    else
                                       'base') || ' item, linking text ' || $previous-string-label || '): ', serialize(current-group())"
                              />
                           </xsl:when>

                           <!-- If we've gotten to this point, we're at the second group, the tail-end, scenario #2 described above -->
                           <xsl:when test="(name($this-new-collation-item) = 'u')">
                              <!-- If the new collation item is <u> then the reading is not attested in the new string, so no 
                                 matter whether the base element is a <c> or <u> it must be converted to <u>.-->
                              <u>
                                 <xsl:copy-of select="$these-base-collation-items/node()"/>
                                 <!-- This is a case where the new string is unattested, and that's reflected in the imprinted <x>,
                                 which by design is already present -->
                                 <xsl:copy-of select="$this-new-collation-item/tan:x"/>
                              </u>
                           </xsl:when>
                           <xsl:when
                              test="(name($these-base-collation-items) = 'u') and (name($this-new-collation-item) = 'c')">
                              <u>
                                 <xsl:copy-of select="$these-base-collation-items/node()"/>
                                 <wit>
                                    <xsl:copy-of select="$this-new-collation-item/tan:wit/@*"/>
                                 </wit>
                              </u>
                           </xsl:when>
                           <xsl:when
                              test="(name($these-base-collation-items) = 'c') and (name($this-new-collation-item) = 'c')">
                              <c>
                                 <xsl:copy-of select="$these-base-collation-items/node()"/>
                                 <wit>
                                    <xsl:copy-of select="$this-new-collation-item/tan:wit/@*"/>
                                 </wit>
                              </c>
                           </xsl:when>
                           <xsl:otherwise>
                              <!-- Not quite sure what's going on, so we bellow and moan -->
                              <xsl:message
                                 select="'We are not quite sure what to do with: ', serialize(current-group())"
                              />
                           </xsl:otherwise>
                        </xsl:choose>
                     </xsl:for-each-group>

                  </xsl:for-each-group>
               </collation>
            </xsl:variable>

            <xsl:variable name="diagnostics-on" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Iteration: ', $iteration"/>
               <xsl:message select="'Collation so far: ' || serialize($collation-so-far)"/>
               <xsl:message select="'Previous string: ' || $previous-string"/>
               <xsl:message select="'This string label: ' || $this-label"/>
               <xsl:message select="'This string: ' || ."/>
               <xsl:message select="'This diff (not adjusted): ' || serialize($this-diff)"/>
               <xsl:message select="'This diff (adjusted): ' || serialize($this-diff-adjusted)"/>
               <xsl:message select="'This diff as collation: ' || serialize($this-diff-collation)"/>
               <xsl:message
                  select="'Linking text @pos values compared: ' || serialize($pos-values-compared)"/>
               <xsl:message
                  select="'Places where the two collations should be broken up: ' || serialize($pos-values-to-add)"/>
               <xsl:message
                  select="'Base collation splintered: ' || serialize($both-collations-splintered[1])"/>
               <xsl:message
                  select="'New collation splintered: ' || serialize($both-collations-splintered[2])"/>
               <xsl:message select="'New base collation: ' || serialize($new-base-collation)"/>
            </xsl:if>

            <!-- The following diagnostic passage interjects feedback straight into the output, a more drastic method of
               feedback which may or may not be the best way to diagnose a problem. -->

            <xsl:variable name="imprint-diagnostics-on" select="false()"/>
            <xsl:if test="$imprint-diagnostics-on">
               <xsl:message select="'Imprinting diagnostic feedback in output of tan:collate()'"/>
               <diagnostics>
                  <previous-collation n="{position()}">
                     <added-witness>
                        <xsl:value-of select="$previous-string-label"/>
                     </added-witness>
                     <xsl:copy-of select="$collation-so-far"/>
                  </previous-collation>
                  <this-diff>
                     <xsl:copy-of select="$this-diff"/>
                  </this-diff>
                  <this-diff-adjusted>
                     <xsl:copy-of select="$this-diff-adjusted"/>
                  </this-diff-adjusted>
                  <this-diff-collated>
                     <xsl:copy-of select="$this-diff-collation"/>
                  </this-diff-collated>
                  <pos-values-compared>
                     <xsl:copy-of select="$pos-values-compared"/>
                  </pos-values-compared>
                  <where-the-two-collations-should-be-broken-up>
                     <xsl:copy-of select="$pos-values-to-add"/>
                  </where-the-two-collations-should-be-broken-up>
                  <base-coll-splintered>
                     <xsl:copy-of select="$both-collations-splintered[1]"/>
                  </base-coll-splintered>
                  <new-coll-splintered>
                     <xsl:copy-of select="$both-collations-splintered[2]"/>
                  </new-coll-splintered>
               </diagnostics>
            </xsl:if>

            <!-- If we're at the end of the iteration, we're done and we can return the last collation. -->
            <xsl:if test="$iteration eq $string-count">
               <xsl:copy-of select="$new-base-collation"/>
            </xsl:if>

            <xsl:next-iteration>
               <xsl:with-param name="collation-so-far" select="$new-base-collation"/>
               <xsl:with-param name="previous-string" select="."/>
               <xsl:with-param name="previous-string-label" select="$this-label"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>

      <xsl:variable name="cleaned-up-collation-pass-1" as="element()*">
         <xsl:apply-templates select="$fragmented-collation" mode="tan:clean-up-collation-pass-1">
            <xsl:with-param name="allow-recollation" tunnel="yes" select="$clean-up-collation"/>
         </xsl:apply-templates>
      </xsl:variable>

      <xsl:variable name="cleaned-up-collation-pass-2" as="element()*">
         <xsl:choose>
            <xsl:when test="$clean-up-collation">
               <xsl:apply-templates select="$cleaned-up-collation-pass-1"
                  mode="tan:clean-up-collation-pass-2"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="$cleaned-up-collation-pass-1"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- output for the entire function -->
      <xsl:variable name="check-output-integrity" as="xs:boolean" select="true()"/>
      <collation>
         <xsl:for-each select="$string-labels-re-sorted">
            <xsl:variable name="this-string-label" select="."/>
            <xsl:variable name="these-diffs" select="$diffs-sorted[(@a, @b) = $this-string-label]"/>
            <witness id="{.}">
               <xsl:for-each select="$these-diffs">
                  <xsl:variable name="that-string-label"
                     select="(@a, @b)[not(. = $this-string-label)]"/>
                  <commonality with="{$that-string-label}">
                     <xsl:value-of select="@commonality"/>
                  </commonality>
               </xsl:for-each>
            </witness>
         </xsl:for-each>
         <xsl:copy-of select="$cleaned-up-collation-pass-2/*"/>

         <xsl:if test="$check-output-integrity">
            <xsl:for-each select="1 to count($string-labels-re-sorted)">
               <xsl:variable name="this-pos" select="."/>
               <xsl:variable name="this-label" select="$string-labels-re-sorted[$this-pos]"/>
               <xsl:variable name="this-input-string" select="$strings-re-sorted[$this-pos]"/>
               <xsl:variable name="this-output-string"
                  select="string-join($cleaned-up-collation-pass-2/*[tan:wit/@ref = $this-label]/tan:txt)"/>
               <xsl:if test="not($this-input-string eq $this-output-string)">
                  <xsl:variable name="this-errant-diff"
                     select="tan:diff-cache($this-input-string, $this-output-string, false(), true())"/>
                  <xsl:message
                     select="'Error in tan:collate(). String ' || $this-label || ' does not match output.'"/>
                  <xsl:message select="serialize(tan:trim-long-text($this-errant-diff, 50))"/>

                  <error witness="{$this-label}">
                     <xsl:comment>a = input string; b = reconstructed output</xsl:comment>
                     <xsl:copy-of select="$this-errant-diff"/>
                  </error>
                  <xsl:copy-of select="$fragmented-collation/descendant-or-self::tan:diagnostics"/>
               </xsl:if>
            </xsl:for-each>
         </xsl:if>
      </collation>


   </xsl:function>
   
   
   <xsl:mode name="tan:clean-up-collation-pass-1" on-no-match="shallow-copy"/>
   
   <!-- <x> was just a placeholder that can easily be determined by the lack of a <wit>; <witness>
   is no longer needed because it has been reconstructed, perhaps with collation statistics. -->
   <xsl:template match="tan:x | tan:witness" mode="tan:clean-up-collation-pass-1"/>
   <xsl:template match="tan:previous-collation | tan:diagnostics" mode="tan:clean-up-collation-pass-1">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   <xsl:template match="*[tan:u]" mode="tan:clean-up-collation-pass-1">
      <xsl:param name="allow-recollation" select="true()" as="xs:boolean" tunnel="yes"/>
      <!-- A collation might have the following issues:
      1. nearby <u>s that have identical <txt> contents; the challenge is that such creatures are separated
      from each other by sibling <u>s that don't have identical <txt> contents.
      2. a total mishmash of <u>s that are difficult to read, and would be much easier to read if the collation
      routine was run on the fragments. -->
      <!-- Prior to this step, consecutive <u>s should have <wit>s that follow the order of the sources. After this step,
      that principle is no longer true. -->
      <xsl:variable name="witness-count" select="count(tan:witness)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="*" group-adjacent="name(.)">
            <xsl:choose>
               <xsl:when test="current-grouping-key() = 'u'">
                  <xsl:variable name="these-u-wits" select="current-group()/tan:wit"/>
                  <xsl:variable name="these-u-wit-refs" select="distinct-values($these-u-wits/@ref)"/>
                  <xsl:variable name="these-u-wit-counts"
                     select="
                     for $i in $these-u-wit-refs
                     return
                     count($these-u-wits[@ref = $i])"
                  />
                  <xsl:variable name="these-us-should-be-recollated"
                     select="$allow-recollation and (count($these-u-wit-refs) gt 2)"/>
                  <xsl:variable name="these-u-strings" as="xs:string*"
                     select="
                     for $i in $these-u-wit-refs
                     return
                     string-join(current-group()[tan:wit/@ref = $i]/tan:txt)"
                  />
                  <xsl:variable name="these-offsets" as="element()*">
                     <xsl:for-each select="$these-u-wit-refs">
                        <xsl:variable name="this-ref" select="."/>
                        <xsl:variable name="this-smallest-pos" select="($these-u-wits[@ref = $this-ref])[1]/@pos"/>
                        <offset ref="{$this-ref}" by="{$this-smallest-pos}"/>
                     </xsl:for-each>
                  </xsl:variable>
                  
                  
                  <xsl:variable name="diagnostics-on" select="false()"/>
                  <xsl:if test="$diagnostics-on">
                     <xsl:message select="'Diagnostics on, template mode clean-up-collation'"/>
                     <xsl:message select="'Allow recollation?', $allow-recollation"/>
                     <xsl:message
                        select="
                        'These u witness refs: (', count($these-u-wit-refs), '): ',
                        (for $i in $these-u-wit-refs
                        return
                        ($i || ' (pos ' || $these-u-wits[@ref = $i][1]/@pos || '); '))"
                     />
                     <xsl:message select="'These u witness counts: ', $these-u-wit-counts"/>
                     <xsl:message select="'These us should be recollated: ', $these-us-should-be-recollated"/>
                     <xsl:message select="'These u strings: ', (for $i in $these-u-strings return '[START]' || $i || '[END]  ')"/>
                  </xsl:if>
                  
                  <xsl:choose>
                     <xsl:when test="$these-us-should-be-recollated">
                        <!-- TODO: revise so that the last parameter can be set to $tan:snap-to-word. Currently
                           most word-snapped output from tan:collate() runs into problems. -->
                        <xsl:variable name="these-us-recollated"
                           select="tan:collate($these-u-strings, $these-u-wit-refs, true(), true(), false(), false())"
                           as="element()"/>
                        
                        <xsl:if test="$diagnostics-on">
                           <xsl:message select="'These us recollated: ', serialize($these-us-recollated)"/>
                        </xsl:if>
                        
                        <xsl:for-each select="$these-us-recollated/(* except tan:witness)">
                           <xsl:variable name="this-element-name" select="
                                 if (count(tan:wit) eq $witness-count) then
                                    'c'
                                 else
                                    'u'"/>
                           <xsl:element name="{$this-element-name}">
                              <xsl:apply-templates select="* except tan:x" mode="tan:add-collation-pos-offset">
                                 <xsl:with-param name="offsets" select="$these-offsets"/>
                              </xsl:apply-templates>
                           </xsl:element>
                        </xsl:for-each>
                     </xsl:when>
                     
                     <xsl:otherwise>
                        <xsl:variable name="these-u-groups" as="element()+">
                           <xsl:variable name="cg-count" select="count(current-group())"/>
                           <xsl:iterate select="current-group()">
                              <xsl:param name="items-to-group" as="element()*"/>
                              <xsl:variable name="this-item" select="."/>
                              <xsl:variable name="this-starts-new-group" select="$this-item/tan:wit/@ref = $items-to-group/tan:wit/@ref"/>
                              <xsl:variable name="new-item-groups"
                                 select="
                                 if ($this-starts-new-group) then
                                 $this-item
                                 else
                                 ($items-to-group, $this-item)"
                              />
                              <xsl:choose>
                                 <xsl:when test="(position() eq $cg-count) and $this-starts-new-group">
                                    <group>
                                       <xsl:copy-of select="$items-to-group"/>
                                    </group>
                                    <group>
                                       <xsl:copy-of select="$this-item"/>
                                    </group>
                                 </xsl:when>
                                 <xsl:when test="$this-starts-new-group">
                                    <group>
                                       <xsl:copy-of select="$items-to-group"/>
                                    </group>
                                 </xsl:when>
                                 <xsl:when test="(position() eq $cg-count)">
                                    <group>
                                       <xsl:copy-of select="$items-to-group"/>
                                       <xsl:copy-of select="$this-item"/>
                                    </group>
                                 </xsl:when>
                              </xsl:choose>
                              <xsl:next-iteration>
                                 <xsl:with-param name="items-to-group" select="$new-item-groups"/>
                              </xsl:next-iteration>
                           </xsl:iterate>
                        </xsl:variable>
                        
                        <xsl:if test="$diagnostics-on">
                           <xsl:message select="'These u groups: ', serialize($these-u-groups)"/>
                        </xsl:if>
                        
                        <xsl:for-each select="$these-u-groups">
                           <xsl:for-each-group select="*" group-by="tan:txt">
                              <u>
                                 <xsl:copy-of select="current-group()/@*"/>
                                 <xsl:copy-of select="current-group()[1]/tan:txt"/>
                                 <xsl:apply-templates select="current-group()/(* except tan:txt)" mode="#current"/>
                              </u>
                           </xsl:for-each-group> 
                        </xsl:for-each>
                     </xsl:otherwise>
                  </xsl:choose>
                  
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="current-group()" mode="#current"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:add-collation-pos-offset" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:wit" mode="tan:add-collation-pos-offset">
      <xsl:param name="offsets" as="element()*"/>
      <xsl:variable name="this-ref" select="@ref"/>
      <xsl:variable name="this-pos" select="number(@pos)"/>
      <xsl:variable name="this-offset-pos" select="(number($offsets[@ref = $this-ref][1]/@by), 1)[1]"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @pos"/>
         <xsl:attribute name="pos" select="$this-pos + $this-offset-pos - 1"/>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:clean-up-collation-pass-2" on-no-match="shallow-copy"/>
   
   <xsl:template match="*[tan:u]" mode="tan:clean-up-collation-pass-2">
      <!-- At the end of cleanup, there may be adjacent <c>s, which should be consolidated -->
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="*" group-adjacent="name(.)">
            <xsl:choose>
               <xsl:when test="(current-grouping-key() eq 'c') and (count(current-group()) gt  1)">
                  <c>
                     <txt>
                        <xsl:value-of select="string-join(current-group()/tan:txt)"/>
                     </txt>
                     <xsl:copy-of select="current-group()[1]/tan:wit"/>
                  </c>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="current-group()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group> 
      </xsl:copy>
   </xsl:template>
   
   
   
   
   
</xsl:stylesheet>
