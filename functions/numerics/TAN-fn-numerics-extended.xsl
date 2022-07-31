<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended numeric functions. -->

   <xsl:function name="tan:counts-to-lasts" xml:id="f-counts-to-lasts" as="xs:integer*" visibility="public">
      <!-- Input: sequence of numbers representing counts of items. -->
      <!-- Output: sequence of numbers representing the last position of each item within the total count.
      E.g., (4, 12, 0, 7) - > (4, 16, 16, 23)-->
      <!--kw: numerics, sequences -->
      <xsl:param name="seq" as="xs:integer*"/>
      <xsl:copy-of select="
            for $i in (1 to count($seq))
            return
               sum(for $j in (1 to $i)
               return
                  $seq[$j])"/>
   </xsl:function>

   <xsl:function name="tan:product" as="xs:anyAtomicType?" visibility="public">
      <!-- Input: a sequence of numbers -->
      <!-- Output: the product of those numbers -->
      <!--kw: numerics -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:iterate select="$numbers">
         <xsl:param name="product-so-far" as="xs:anyAtomicType" select="1"/>
         <xsl:on-completion select="$product-so-far"/>
         <xsl:next-iteration>
            <xsl:with-param name="product-so-far" select="$product-so-far * ."/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:function>


   <xsl:function name="tan:number-sort" as="xs:double*" visibility="public">
      <!-- Input: any sequence of items -->
      <!-- Output: the same sequence, sorted with string numerals converted to numbers -->
      <!--kw: numerics -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-norm" as="item()*" select="
            for $i in $numbers
            return
               if ($i castable as xs:double) then
                  number($i)
               else
                  $i"/>
      <xsl:for-each select="$numbers-norm">
         <xsl:sort/>
         <xsl:copy-of select="."/>
      </xsl:for-each>
   </xsl:function>
   
   
   <xsl:function name="tan:integer-groups" as="array(xs:integer+)?" visibility="public">
      <!-- Input: any integers -->
      <!-- Output: an array, with each member containing a sequence of integers that are collectively contiguous -->
      <!-- Array members and their contents will be sorted; duplicates will be ignored -->
      <!--kw: numerics, grouping -->
      <xsl:param name="integers-to-group" as="xs:integer*"/>
      
      <xsl:variable name="ints-sorted" as="xs:integer*"
         select="sort(distinct-values($integers-to-group))"/>
      
      <xsl:choose>
         <xsl:when test="count($ints-sorted) eq 1">
            <xsl:sequence select="[$integers-to-group]"/>
         </xsl:when>
         <xsl:when test="count($ints-sorted) gt 1">
            <xsl:iterate select="tail($ints-sorted)">
               <xsl:param name="array-so-far" as="array(xs:integer+)?"/>
               <xsl:param name="array-member-sequence-so-far" as="xs:integer+" select="head($ints-sorted)"/>
      
               <xsl:on-completion>
                  <xsl:sequence select="
                        if (exists($array-so-far)) then
                           array:join(($array-so-far, [$array-member-sequence-so-far]))
                        else
                           [$array-member-sequence-so-far]"/>
               </xsl:on-completion>
      
               <xsl:variable name="build-new-array-member"
                  select=". gt $array-member-sequence-so-far[last()] + 1" as="xs:boolean"/>
               <xsl:variable name="new-array-member-sequence" as="xs:integer+" select="
                     if ($build-new-array-member) then
                        .
                     else
                        ($array-member-sequence-so-far, .)"/>
               <xsl:variable name="new-array" as="array(xs:integer+)?">
                  <xsl:choose>
                     <xsl:when test="$build-new-array-member and not(exists($array-so-far))">
                        <xsl:sequence select="[$array-member-sequence-so-far]"/>
                     </xsl:when>
                     <xsl:when test="$build-new-array-member">
                        <xsl:sequence
                           select="array:join(($array-so-far, [$array-member-sequence-so-far]))"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="$array-so-far"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:variable>
      
               <xsl:next-iteration>
                  <xsl:with-param name="array-so-far" select="$new-array"/>
                  <xsl:with-param name="array-member-sequence-so-far" select="$new-array-member-sequence"/>
               </xsl:next-iteration>
            </xsl:iterate>
         </xsl:when>
      </xsl:choose>
   </xsl:function>
   
   
   
   <xsl:function name="tan:closest-cluster" as="xs:anyAtomicType+" visibility="public">
      <!-- Input: an array of sequences of numerics -->
      <!-- Output: a sequence of numerics, as many as the size of the input array; each nth 
         item represents an item in the nth member of the input array. Collectively the output
         represents the closest cluster of items from the input array. -->
      <!-- Example:
         Input: [(1, 5, 10), (6, 2), (1, 3, 7)]
         Output: (1, 2, 1)-->
      <!-- This function was written to support a version of tan:diff() that evaluates many versions -->
      <!-- kw: numerics, statistics -->
      <xsl:param name="array-of-sequences-of-numerics" as="array(xs:anyAtomicType+)"/>

      <xsl:variable name="array-size" as="xs:integer"
         select="array:size($array-of-sequences-of-numerics)"/>
      <xsl:variable name="array-item-counts" as="xs:integer*" select="
            for $i in (1 to $array-size)
            return
               count($array-of-sequences-of-numerics($i))"/>
      <xsl:variable name="array-item-count-min" as="xs:integer" select="min($array-item-counts)"/>
      <xsl:variable name="array-filter-member-number" as="xs:integer"
         select="index-of($array-item-counts, $array-item-count-min)[1]"/>
      <xsl:variable name="array-simplified" as="array(xs:anyAtomicType+)" select="
            array:join(
            for $n in (1 to $array-size)
            return
               let $member := $array-of-sequences-of-numerics($n)
               return
                  if (count($member) le ($array-item-count-min * 2)) then
                     [$member]
                  else
                     [
                        distinct-values(
                        for $m in $array-of-sequences-of-numerics($array-filter-member-number)
                        return
                           ($member => sort((), function ($x) {
                              abs($x - $m)
                           })
                           )[position() lt 3]
                        )
                     ]
            )"/>
      <xsl:variable name="permutation-count" as="xs:integer" select="
            tan:product(for $i in (1 to $array-size)
            return
               count($array-simplified($i)))"/>

      <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'Diagnostics on, tan:closest-cluster()'"/>
         <xsl:message select="'Array size:', $array-size"/>
         <xsl:message select="
               'Array item counts: ',
               string-join(for $i in $array-item-counts
               return
                  xs:string($i), ', ')"/>
         <xsl:message select="'Array simplified:', tan:array-to-xml($array-simplified)"/>
      </xsl:if>

      <xsl:choose>

         <!-- Strategy: 
               1. create a new array of sequences of numerics, one item from each input array member
               2. calculate the mean of each array
               3. return the array members with the lowest score
            -->

         <xsl:when
            test="$tan:array-join-population-max gt 1 and $permutation-count gt $tan:array-join-population-max">
            <xsl:variable name="permuted-array" as="element()"
               select="tan:array-permutations-fallback($array-simplified)"/>
            <xsl:for-each select="$permuted-array/array:member">
               <xsl:sort>
                  <xsl:variable name="items-parsed" as="xs:anyAtomicType*">
                     <xsl:apply-templates mode="tan:build-maps-and-arrays"/>
                  </xsl:variable>
                  <xsl:sequence select="tan:var($items-parsed)"/>
               </xsl:sort>
               <xsl:if test="position() eq 1">
                  <xsl:apply-templates mode="tan:build-maps-and-arrays"/>
               </xsl:if>
            </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="permuted-array" as="array(xs:anyAtomicType+)"
               select="tan:array-permutations($array-simplified)"/>
            <xsl:variable name="permuted-array-sorted" as="array(xs:anyAtomicType+)" select="
                  array:sort($permuted-array, (), function ($vals) {
                     tan:var($vals)
                  })"/>
            <!--<xsl:variable name="permuted-array-sorted" as="array(xs:anyAtomicType+)" select="$permuted-array"/>-->
            <xsl:sequence select="$permuted-array-sorted(1)"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>


</xsl:stylesheet>
