<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   version="3.0">

   <!-- TAN Function Library standard statistic functions. -->
   
   <xsl:function name="tan:var" as="xs:anyAtomicType?" visibility="public">
      <!-- Input: any sequence of numbers -->
      <!-- Output the variance -->
      <!--kw: statistics -->
      <xsl:param name="arg" as="xs:anyAtomicType*"/>
      <xsl:variable name="this-avg" as="xs:anyAtomicType?" select="avg($arg)[1]"/>
      <xsl:variable name="these-deviations" as="xs:anyAtomicType*" select="
            for $i in $arg
            return
               math:pow(($i - $this-avg), 2)"/>
      <xsl:sequence select="avg($these-deviations)[1]"/>
   </xsl:function>

</xsl:stylesheet>
