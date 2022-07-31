<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   version="3.0">

   <!-- TAN Function Library extended statistic functions. -->
   
   <xsl:function name="tan:median" as="xs:anyAtomicType?" visibility="public">
      <!-- Input: any sequence of numbers -->
      <!-- Output: the median value -->
      <!-- It is assumed that the input has already been sorted by tan:numbers-sorted() vel sim -->
      <!--kw: statistics -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="number-count" select="count($numbers)"/>
      <xsl:variable name="mid-point" select="$number-count div 2"/>
      <xsl:variable name="mid-point-ceiling" select="ceiling($mid-point)"/>
      <xsl:choose>
         <xsl:when test="$mid-point = $mid-point-ceiling">
            <xsl:sequence
               select="avg(($numbers[$mid-point-ceiling], $numbers[$mid-point-ceiling - 1]))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$numbers[$mid-point-ceiling]"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="tan:outliers" as="xs:anyAtomicType*" visibility="public">
      <!-- Input: any sequence of numbers -->
      <!-- Output: outliers in the sequence -->
      <!--kw: statistics -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="numbers-sorted" select="tan:number-sort($numbers)" as="xs:anyAtomicType*"/>
      <xsl:variable name="half-point" select="count($numbers) idiv 2"/>
      <xsl:variable name="top-half" select="$numbers-sorted[position() le $half-point]"/>
      <xsl:variable name="bottom-half" select="$numbers-sorted[position() gt $half-point]"/>
      <xsl:variable name="q1" select="tan:median($top-half)"/>
      <xsl:variable name="q2" select="tan:median($numbers)"/>
      <xsl:variable name="q3" select="tan:median($bottom-half)"/>
      <xsl:variable name="interquartile-range" select="$q3 - $q1"/>
      <xsl:variable name="outer-fences" select="$interquartile-range * 3"/>
      <xsl:variable name="top-fence" select="$q1 - $outer-fences"/>
      <xsl:variable name="bottom-fence" select="$q3 + $outer-fences"/>
      <xsl:variable name="top-outliers" select="$top-half[. lt $top-fence]"/>
      <xsl:variable name="bottom-outliers" select="$bottom-half[. gt $bottom-fence]"/>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:outliers()'"/>
         <xsl:message select="'numbers sorted: ', $numbers-sorted"/>
      </xsl:if>
      
      <xsl:for-each select="$numbers">
         <xsl:variable name="this-number"
            select="
            if (. instance of xs:string) then
            number(.)
            else
            xs:double(.)"/>
         <xsl:if test="$this-number = ($top-outliers, $bottom-outliers)">
            <xsl:copy-of select="."/>
         </xsl:if>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:no-outliers" as="xs:anyAtomicType*" visibility="public">
      <!-- Input: any sequence of numbers -->
      <!-- Output: the same sequence, without outliers -->
      <!--kw: statistics -->
      <xsl:param name="numbers" as="xs:anyAtomicType*"/>
      <xsl:variable name="outliers" select="tan:outliers($numbers)"/>
      <xsl:copy-of select="$numbers[not(. = $outliers)]"/>
   </xsl:function>
   
   
   <xsl:function name="tan:analyze-stats" as="element()?" visibility="private">
      <!-- Input: a sequence of numbers -->
      <!-- Output: a single <stats> with attributes calculating the count, sum, average, max, min, variance, standard deviation, and then one child <d> per datum with the value of the datum -->
      <xsl:param name="arg" as="xs:anyAtomicType*"/>
      <xsl:variable name="this-avg" as="xs:anyAtomicType*" select="avg($arg)[1]"/>
      <xsl:variable name="these-deviations" as="xs:anyAtomicType*" select="
            for $i in $arg
            return
               math:pow(($i - $this-avg), 2)"/>
      <xsl:variable name="max-deviation" select="max($these-deviations)"/>
      <xsl:variable name="this-variance" select="avg($these-deviations)"/>
      <xsl:variable name="this-standard-deviation" select="math:sqrt($this-variance)"/>
      <stats>
         <count>
            <xsl:copy-of select="count($arg)"/>
         </count>
         <sum>
            <xsl:copy-of select="sum($arg)"/>
         </sum>
         <avg>
            <xsl:copy-of select="$this-avg"/>
         </avg>
         <max>
            <xsl:copy-of select="max($arg)"/>
         </max>
         <min>
            <xsl:copy-of select="min($arg)"/>
         </min>
         <var>
            <xsl:copy-of select="$this-variance"/>
         </var>
         <std>
            <xsl:copy-of select="$this-standard-deviation"/>
         </std>
         <xsl:for-each select="$arg">
            <xsl:variable name="pos" select="position()"/>
            <xsl:variable name="this-dev" select="$these-deviations[$pos]"/>
            <d dev="{$these-deviations[$pos]}">
               <xsl:if test="$this-dev = $max-deviation">
                  <xsl:attribute name="max"/>
               </xsl:if>
               <xsl:value-of select="."/>
            </d>
         </xsl:for-each>
      </stats>
   </xsl:function>
   
   <xsl:function name="tan:merge-analyzed-stats" as="element()" visibility="private">
      <!-- Input: Results from tan:analyze-stats(); a boolean -->
      <!-- Output: A synthesis of the results. If the second parameter is true, the stats are added; if false, the first statistic will be compared to the sum of all subsequent ones. -->
      <xsl:param name="analyzed-stats" as="element()*"/>
      <xsl:param name="add-stats" as="xs:boolean?"/>
      <xsl:variable name="datum-counts" as="xs:integer*"
         select="
         for $i in $analyzed-stats
         return
         count($i/tan:d)"/>
      <xsl:variable name="this-count" select="avg($analyzed-stats[position() gt 1]/tan:count)"/>
      <xsl:variable name="this-sum" select="avg($analyzed-stats[position() gt 1]/tan:sum)"/>
      <xsl:variable name="this-avg" select="avg($analyzed-stats[position() gt 1]/tan:avg)"/>
      <xsl:variable name="this-max" select="avg($analyzed-stats[position() gt 1]/tan:max)"/>
      <xsl:variable name="this-min" select="avg($analyzed-stats[position() gt 1]/tan:min)"/>
      <xsl:variable name="this-var" select="avg($analyzed-stats[position() gt 1]/tan:var)"/>
      <xsl:variable name="this-std" select="avg($analyzed-stats[position() gt 1]/tan:std)"/>
      <xsl:variable name="this-count-diff" select="$this-count - $analyzed-stats[1]/tan:count"/>
      <xsl:variable name="this-sum-diff" select="$this-sum - $analyzed-stats[1]/tan:sum"/>
      <xsl:variable name="this-avg-diff" select="$this-avg - $analyzed-stats[1]/tan:avg"/>
      <xsl:variable name="this-max-diff" select="$this-max - $analyzed-stats[1]/tan:max"/>
      <xsl:variable name="this-min-diff" select="$this-min - $analyzed-stats[1]/tan:min"/>
      <xsl:variable name="this-var-diff" select="$this-var - $analyzed-stats[1]/tan:var"/>
      <xsl:variable name="this-std-diff" select="$this-std - $analyzed-stats[1]/tan:std"/>
      <xsl:variable name="data-diff" as="element()">
         <stats>
            <count diff="{$this-count-diff div $analyzed-stats[1]/tan:count}">
               <xsl:copy-of select="$this-count-diff"/>
            </count>
            <sum diff="{$this-sum-diff div $analyzed-stats[1]/tan:sum}">
               <xsl:copy-of select="$this-sum-diff"/>
            </sum>
            <avg diff="{$this-avg-diff div $analyzed-stats[1]/tan:avg}">
               <xsl:copy-of select="$this-avg-diff"/>
            </avg>
            <max diff="{$this-max-diff div $analyzed-stats[1]/tan:max}">
               <xsl:copy-of select="$this-max-diff"/>
            </max>
            <min diff="{$this-min-diff div $analyzed-stats[1]/tan:min}">
               <xsl:copy-of select="$this-min-diff"/>
            </min>
            <var diff="{$this-var-diff div $analyzed-stats[1]/tan:var}">
               <xsl:copy-of select="$this-var-diff"/>
            </var>
            <std diff="{$this-std-diff div $analyzed-stats[1]/tan:std}">
               <xsl:copy-of select="$this-std-diff"/>
            </std>
            <xsl:for-each select="$analyzed-stats[1]/tan:d">
               <xsl:variable name="pos" select="position()"/>
               <d>
                  <xsl:copy-of
                     select="avg($analyzed-stats[position() gt 1]/tan:d[$pos]) - $analyzed-stats[1]/tan:d[$pos]"
                  />
               </d>
            </xsl:for-each>
         </stats>
      </xsl:variable>
      
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:merge-analyzed-stats()'"/>
         <xsl:message select="'add stats?', $add-stats"/>
         <xsl:message select="'datum counts:', $datum-counts"/>
         <xsl:message select="'data diff: ', $data-diff"/>
      </xsl:if>
      
      <xsl:choose>
         <xsl:when test="$add-stats = true()">
            <xsl:copy-of select="tan:analyze-stats($analyzed-stats/tan:d)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$data-diff"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   

</xsl:stylesheet>
