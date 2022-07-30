<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library standard numeric functions. -->
   
   <xsl:function name="tan:numbers-to-portions" as="xs:decimal*" visibility="public">
      <!-- Input: a sequence of numbers, representing a sequence of quantities of all the parts of a whole -->
      <!-- Output: one double per number, from 0 to 1, reflecting where each finishes in the sequence proportionate to the sum of the whole. 
      The last item always returns 1. Anything not castable to a double will be given the empty sequence. -->
      <!--kw: numerics -->
      <xsl:param name="numbers" as="item()*"/>
      <xsl:variable name="uncastable-numbers" as="item()*" select="$numbers[not(. castable as xs:double)]"/>
      <xsl:variable name="this-sum" select="
            sum(for $i in $numbers[. castable as xs:double]
            return
               number($i))" as="xs:double?"/>
      <xsl:choose>
         <xsl:when test="exists($uncastable-numbers)">
            <xsl:message select="'The following items cannot be cast to doubles: ', $uncastable-numbers"/>
         </xsl:when>
         <xsl:when test="$this-sum eq 0">
            <xsl:message select="'Cannot work with a sequence whose sum is zero'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:iterate select="$numbers">
               <xsl:param name="last-portion-end" as="xs:double" select="0"/>
               <xsl:variable name="this-is-castable-as-double" select=". castable as xs:double" as="xs:boolean"/>
               <xsl:variable name="this-double" as="xs:double" select="
                     if ($this-is-castable-as-double) then
                        xs:double(.)
                     else
                        0"/>
               <xsl:variable name="new-portion-end" select="$this-double + $last-portion-end" as="xs:double"/>
               <xsl:choose>
                  <xsl:when test="$this-is-castable-as-double">
                     <xsl:sequence select="xs:decimal($new-portion-end div $this-sum)"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="()"/>
                  </xsl:otherwise>
               </xsl:choose>
               <xsl:next-iteration>
                  <xsl:with-param name="last-portion-end" as="xs:double" select="$new-portion-end"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   <xsl:function name="tan:best-integer-pair" as="xs:integer*" visibility="private">
      <!-- Input: two sequences of integers; two integers -->
      <!-- Output: two integers representing the position of the integer from the first sequence and the position 
         of the integer from the second that are proportionately closest to each other, given the maximum ceilings 
         set by the last two parameters. -->
      <!-- This function was written to support tan:diff() in making better choices when a match is found in multiple
         places in either the short or the long string. -->
      <xsl:param name="integer-sequence-a" as="xs:integer*"/>
      <xsl:param name="integer-sequence-b" as="xs:integer*"/>
      <xsl:param name="population-size-a" as="xs:integer"/>
      <xsl:param name="population-size-b" as="xs:integer"/>

      <xsl:variable name="seq-a-sorted" as="xs:integer*" select="sort($integer-sequence-a)"/>
      <xsl:variable name="seq-b-sorted" as="xs:integer*" select="sort($integer-sequence-b)"/>
      <xsl:variable name="seq-a-portions" as="xs:decimal*" select="
            for $i in $seq-a-sorted
            return
               $i div $population-size-a"/>
      <xsl:variable name="seq-b-portions" as="xs:decimal*" select="
            for $i in $seq-b-sorted
            return
               $i div $population-size-b"/>

      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:best-integer-pair()'"/>
         <xsl:message select="'Seq a sorted:', $seq-a-sorted"/>
         <xsl:message select="'Seq b sorted:', $seq-b-sorted"/>
         <xsl:message select="'Seq a portions:', $seq-a-portions"/>
         <xsl:message select="'Seq b portions:', $seq-b-portions"/>
      </xsl:if>

      <xsl:iterate select="$seq-a-portions">
         <xsl:param name="best-a-pos-so-far" as="xs:integer" select="1"/>
         <xsl:param name="best-b-pos-so-far" as="xs:integer" select="1"/>
         <xsl:param name="score-to-beat" as="xs:decimal"
            select="xs:decimal(max(($population-size-a, $population-size-b)))"/>

         <xsl:on-completion>
            <xsl:sequence select="$best-a-pos-so-far, $best-b-pos-so-far"/>
         </xsl:on-completion>

         <xsl:variable name="this-a" select="." as="xs:decimal"/>
         <xsl:variable name="this-a-pos" select="position()" as="xs:integer"/>

         <xsl:variable name="best-b-pos" as="xs:decimal?">
            <xsl:iterate select="$seq-b-portions">
               <xsl:param name="inner-best-b-pos-so-far" as="xs:integer?"/>
               <xsl:param name="inner-score-to-beat" as="xs:decimal" select="$score-to-beat"/>

               <xsl:on-completion>
                  <xsl:sequence select="$inner-best-b-pos-so-far"/>
               </xsl:on-completion>

               <xsl:variable name="this-b" select="." as="xs:decimal"/>
               <xsl:variable name="this-b-pos" select="position()"/>
               <xsl:variable name="this-diff" as="xs:decimal" select="$this-b - $this-a"/>
               <xsl:variable name="good-choice" as="xs:boolean"
                  select="abs($this-diff) lt $inner-score-to-beat"/>
               <xsl:choose>
                  <xsl:when test="$this-diff gt $inner-score-to-beat">
                     <xsl:sequence select="$inner-best-b-pos-so-far"/>
                     <xsl:break/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:next-iteration>
                        <xsl:with-param name="inner-best-b-pos-so-far" select="
                              if ($good-choice) then
                                 $this-b-pos
                              else
                                 $inner-best-b-pos-so-far"/>
                        <xsl:with-param name="inner-score-to-beat" select="
                              if ($good-choice) then
                                 abs($this-diff)
                              else
                                 $inner-score-to-beat"/>
                     </xsl:next-iteration>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:iterate>
         </xsl:variable>

         <xsl:if test="$diagnostics-on">
            <xsl:message select="'best a pos so far:', $best-a-pos-so-far"/>
            <xsl:message select="'best b pos so far:', $best-b-pos-so-far"/>
            <xsl:message select="'score to beat:', $score-to-beat"/>
            <xsl:message select="'this a, pos:', $this-a, $this-a-pos"/>
            <xsl:message select="'best b pos:', $best-b-pos"/>
         </xsl:if>

         <xsl:next-iteration>
            <xsl:with-param name="best-a-pos-so-far" select="
                  if (exists($best-b-pos)) then
                     $this-a-pos
                  else
                     $best-a-pos-so-far"/>
            <xsl:with-param name="best-b-pos-so-far" select="($best-b-pos, $best-b-pos-so-far)[1]"/>
            <xsl:with-param name="score-to-beat" select="
                  if (exists($best-b-pos)) then
                     abs($seq-b-portions[$best-b-pos] - $this-a)
                  else
                     $score-to-beat"/>
         </xsl:next-iteration>
      </xsl:iterate>


   </xsl:function>
   
   
   <xsl:function name="tan:log2" as="xs:double?" visibility="public">
      <!-- Input: any double -->
      <!-- Output: the binary logarithm of the value -->
      <!--kw: numerics -->
      <xsl:param name="arg" as="xs:double?"/>
      <xsl:sequence select="math:log($arg) div math:log(2)"/>
   </xsl:function>
   
   
   <xsl:function name="tan:lengths-to-positions" as="xs:integer*" visibility="public">
      <!-- Input: sequence of numbers representing legnths of items.  -->
      <!-- Output: sequence of numbers representing the first position of each input item, if the sequence concatenated.
      E.g., (4, 12, 0, 7) - > (1, 5, 17, 17)-->
      <!--kw: numerics, sequences -->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of select="
         for $i in (1 to count($seq))
         return
         sum(for $j in (1 to $i)
         return
         $seq[$j]) - $seq[$i] + 1"/>
   </xsl:function>
   
   
</xsl:stylesheet>
