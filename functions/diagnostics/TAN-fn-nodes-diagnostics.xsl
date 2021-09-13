<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   version="3.0">
   
   <!-- TAN Function Library: diagnostic functions on nodes -->
   

   <!-- For imitating and therefore testing the Schematron validation process on TAN files -->
   
   <xsl:variable name="tan:orig-self-validated" as="document-node()">
      <xsl:apply-templates select="/" mode="tan:imitate-validation"/>
   </xsl:variable>
   
   
   <xsl:mode name="tan:imitate-validation" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="tan:imitate-validation">
      <!-- new stuff -->
      <xsl:variable name="these-q-refs" select="
            for $i in ancestor-or-self::*
            return
               (generate-id($i))"/>

      <!-- This template imitates the process of validation, for testing on efficiency, etc. -->
      <xsl:variable name="this-q-ref" select="generate-id(.)"/>
      <xsl:variable name="this-name" select="name(.)"/>
      <xsl:variable name="this-checked-for-errors"
         select="tan:get-via-q-ref($this-q-ref, $tan:self-expanded[1])"/>
      <xsl:variable name="has-include-or-which-attr" select="exists(@include) or exists(@which)"/>
      <xsl:variable name="relevant-fatalities" select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:fatal[not(@xml:id = $tan:errors-to-squelch)]
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:fatal[not(@xml:id = $tan:errors-to-squelch)]"/>
      <xsl:variable name="relevant-errors" select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:error[not(@xml:id = $tan:errors-to-squelch)]
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:error[not(@xml:id = $tan:errors-to-squelch)]"/>
      <xsl:variable name="relevant-warnings" select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:warning[not(@xml:id = $tan:errors-to-squelch)]
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:warning[not(@xml:id = $tan:errors-to-squelch)]"/>
      <xsl:variable name="relevant-info" select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:info
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:info"/>
      <xsl:variable name="help-offered" select="
            if ($has-include-or-which-attr = true()) then
               $this-checked-for-errors//tan:help
            else
               $this-checked-for-errors/(self::*, *[@attr])/tan:help"/>

      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="exists($relevant-fatalities)">
            <sch>
               <value-of select="tan:error-report($relevant-fatalities)"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($relevant-errors)">
            <sch>
               <value-of select="tan:error-report($relevant-errors)"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($relevant-warnings)">
            <sch>
               <value-of select="tan:error-report($relevant-warnings)"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($relevant-info)">
            <sch>
               <value-of select="$relevant-info/tan:message"/>
            </sch>
         </xsl:if>
         <xsl:if test="exists($help-offered)">
            <sch>
               <value-of select="$help-offered/tan:message"/>
            </sch>
         </xsl:if>
         <xsl:if test="not(exists($this-checked-for-errors))">
            <sch><value-of select="$this-q-ref"/> doesn't match; other @q values of <value-of
                  select="$this-name"/>: <value-of
                  select="string-join($tan:self-expanded//*[name() = $this-name]/@q, ', ')"/></sch>
         </xsl:if>

         <xsl:apply-templates mode="#current"/>
      </xsl:copy>

   </xsl:template>
   
   
   
   

   
</xsl:stylesheet>