<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library date and time functions. -->
   
   <xsl:function name="tan:dateTime-to-decimal" as="xs:decimal*" visibility="private">
      <!-- Input: any xs:date or xs:dateTime -->
      <!-- Output: decimal between 0 and 1 that acts as a proxy for the date and time. These decimal values can then be sorted and compared. -->
      <!-- Example: (2015-05-10) - > 0.2015051 -->
      <!-- If input is not castable as a date or dateTime, 0 is returned -->
      <xsl:param name="time-or-dateTime" as="item()*"/>
      <xsl:for-each select="$time-or-dateTime">
         <xsl:variable name="utc" select="xs:dayTimeDuration('PT0H')"/>
         <xsl:variable name="dateTime" as="xs:dateTime?">
            <xsl:choose>
               <xsl:when test=". castable as xs:dateTime">
                  <xsl:value-of select="."/>
               </xsl:when>
               <xsl:when test=". castable as xs:date">
                  <xsl:value-of select="dateTime(., xs:time('00:00:00'))"/>
               </xsl:when>
            </xsl:choose>
         </xsl:variable>
         <xsl:variable name="dt-adjusted-as-string"
            select="string(adjust-dateTime-to-timezone($dateTime, $utc))"/>
         
         <xsl:sequence select="
               if (exists($dateTime)) then
                  xs:decimal( '0.' || replace(replace($dt-adjusted-as-string, '[-+]\d+:\d+$', ''), '\D+', '') )
               else
                  0"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:most-recent-dateTime" as="item()?" visibility="private">
      <!-- Input: a series of ISO-compliant date or dateTimes -->
      <!-- Output: the most recent one -->
      <xsl:param name="dateTimes" as="item()*"/>
      <xsl:variable name="decimal-val" select="
            for $i in $dateTimes
            return
               tan:dateTime-to-decimal($i)"/>
      <xsl:variable name="most-recent" select="
            if (exists($decimal-val)) then
               index-of($decimal-val, max($decimal-val))[1]
            else
               ()"/>
      <xsl:sequence select="$dateTimes[$most-recent]"/>
   </xsl:function>
   
   
   <xsl:function name="tan:get-doc-history" as="element()*" visibility="public">
      <!-- Input: any TAN document -->
      <!-- Output: a sequence of elements with @when, @ed-when, @accessed-when, @claim-when, sorted from 
         most recent to least; each element includes @when-sort, a decimal that represents the value of 
         the most recent time-date stamp in that element -->
      <!--kw: versioning -->
      <xsl:param name="TAN-doc" as="document-node()*"/>
      <xsl:for-each select="$TAN-doc">
         <xsl:variable name="doc-hist-raw" as="element()*">
            <xsl:apply-templates mode="tan:get-doc-history"/>
         </xsl:variable>
         <history>
            <xsl:copy-of select="*/@*"/>
            <xsl:for-each select="$doc-hist-raw">
               <xsl:sort select="@when-sort" order="descending"/>
               <xsl:copy-of select="."/>
            </xsl:for-each>
         </history>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:mode name="tan:get-doc-history" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:tan-vocabulary | tan:inclusion/tei:* | tan:inclusion/tan:TAN-T | tan:inclusion/tan:TAN-A | tan:inclusion/tan:TAN-A-tok | tan:inclusion/tan:TAN-A-lm | tan:inclusion/tan:TAN-mor | tan:inclusion/tan:TAN-voc" mode="tan:get-doc-history"/>
   <xsl:template match="*[@when or @ed-when or @accessed-when or @claim-when]"
      mode="tan:get-doc-history">
      <xsl:variable name="these-dates" as="xs:decimal*" select="
            for $i in (@when | @ed-when | @accessed-when | @claim-when)
            return
               tan:dateTime-to-decimal($i)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="when-sort" select="max($these-dates)"/>
         <xsl:copy-of select="text()[matches(., '\S')]"/>
      </xsl:copy>
      <xsl:apply-templates mode="#current"/>
   </xsl:template>

</xsl:stylesheet>
