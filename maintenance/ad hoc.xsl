<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:file="http://expath.org/ns/file"
   xmlns:tei="http://www.tei-c.org/ns/1.0" 
   exclude-result-prefixes="#all" version="3.0">
   
   <!-- This stylesheet is for ad hoc changes. -->
   
   <xsl:param name="tan:validation-mode-on" static="yes" select="false()"/>
   
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   
   <xsl:mode default-mode="#unnamed" on-no-match="shallow-copy"/>
   
   <xsl:template match="document-node()">
      <xsl:document>
         <xsl:for-each select="node()">
            <xsl:value-of select="'&#xa;'"/>
            <xsl:apply-templates select="." mode="#current"/>
         </xsl:for-each>
      </xsl:document>
   </xsl:template>
   
   <xsl:mode name="calculate-lms" on-no-match="shallow-skip"/>
   
   <xsl:template match="tan:tok" mode="calculate-lms">
      <xsl:variable name="lm-count" as="xs:integer" select="
            sum(for $i in following-sibling::tan:lm
            return
               (count($i/tan:l) * count($i/tan:m)))"/>
      <xsl:map-entry key="generate-id(.)" select="$lm-count"/>
   </xsl:template>
   
   <xsl:template match="tan:body/tan:feature[not(node())]">
      <xsl:variable name="this-xmlid" select="@xml:id"/>
      <xsl:variable name="this-alias" select="../tan:alias[contains-token(@idrefs, $this-xmlid)]"/>
      <xsl:variable name="this-code" select="($this-alias/(@id, @xml:id), $this-xmlid)[1]"/>
      <code xmlns="tag:textalign.net,2015:ns">
         <xsl:attribute name="feature" select="replace(@which, ' ', '_')"/>
         <xsl:value-of select="replace($this-code, ' ', '_')"/>
      </code>
   </xsl:template>
   <xsl:template match="tan:body/tan:alias"/>
   
   
   <!--<xsl:template match="/tan:TAN-A-lm">
      <xsl:variable name="duplicate-tok-val-map" as="map(*)">
         <xsl:map>
            <xsl:for-each-group select="descendant::tan:tok" group-by="@val">
               <xsl:if test="count(current-group()) gt 1">
                  <xsl:variable name="map-pass-1" as="map(xs:string, xs:integer)">
                     <xsl:map>
                        <xsl:apply-templates select="current-group()" mode="calculate-lms"/>
                     </xsl:map>
                  </xsl:variable>
                  <xsl:variable name="map-pass-1-sum" as="xs:integer" select="
                        sum(for $i in map:keys($map-pass-1)
                        return
                           $map-pass-1($i))"/>
                  <xsl:map-entry key="string(current-grouping-key())">
                     <xsl:sequence select="$map-pass-1-sum, $map-pass-1"/>
                  </xsl:map-entry>
               </xsl:if>
            </xsl:for-each-group> 
         </xsl:map>
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-tok-val-map" tunnel="yes" select="$duplicate-tok-val-map"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>-->
   
   <!--<xsl:template match="tan:tok[@val]">
      <xsl:param name="duplicate-tok-val-map" tunnel="yes" as="map(*)?"/>
      <xsl:variable name="this-val" select="@val" as="xs:string"/>
      <xsl:variable name="this-id" as="xs:string" select="generate-id()"/>
      <xsl:variable name="val-sum-and-map" as="item()*" select="$duplicate-tok-val-map($this-val)"/>
      <xsl:choose>
         <xsl:when test="exists($val-sum-and-map)">
            <xsl:variable name="overall-sum" as="xs:integer" select="$val-sum-and-map[1]"/>
            <xsl:variable name="this-sum" as="xs:integer" select="$val-sum-and-map[2]($this-id)"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="cert" select="$this-sum div $overall-sum"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>-->

</xsl:stylesheet>
