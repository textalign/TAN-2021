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
   
   


</xsl:stylesheet>
