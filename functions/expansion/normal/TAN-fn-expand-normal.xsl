<xsl:stylesheet exclude-result-prefixes="#all"
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library, normal expansion. -->
   
   <!-- Class 1 Files -->
   
   <xsl:template match="tan:TAN-T/tan:body | tan:div" mode="tan:core-expansion-normal">
      <xsl:param name="duplicate-ns" as="xs:string*"/>
      <xsl:param name="mixed-ns" as="xs:string*"/>
      
      <xsl:variable name="these-ns" select="tan:n"/>
      <xsl:variable name="is-leaf-div" select="not(tan:div)"/>
      
      <xsl:variable name="duplicate-children-nonleaf-ns" select="tan:div[tan:div]/tan:n"/>
      <xsl:variable name="duplicate-children-leaf-ns" select="tan:div[not(tan:div)]/tan:n"/>
      <xsl:variable name="mixed-children-ns" select="$duplicate-children-nonleaf-ns[. = $duplicate-children-leaf-ns]"/>
      <xsl:variable name="duplicate-children-ns" select="tan:duplicate-values(($duplicate-children-nonleaf-ns, $duplicate-children-leaf-ns))"/>
      
      <xsl:variable name="ns-matching-sibling-ns" select="$these-ns[. = $duplicate-ns]"/>
      <xsl:variable name="this-is-fragmented" select="exists($ns-matching-sibling-ns)"/>
      <xsl:variable name="this-is-mixed" select="$these-ns = $mixed-ns"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$this-is-fragmented">
            <xsl:copy-of select="tan:error('cl109', concat('Duplicate sibling @n values: ', string-join($ns-matching-sibling-ns, ', ')))"/>
         </xsl:if>
         <xsl:if test="$this-is-mixed">
            <xsl:copy-of select="tan:error('cl118')"/>
         </xsl:if>
         <xsl:if test="
               $is-leaf-div and
               (not(some $i in text()
                  satisfies matches($i, '\S')) or not(exists(text())))">
            <xsl:copy-of select="tan:error('cl110')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-ns" select="$duplicate-children-ns"/>
            <xsl:with-param name="mixed-ns" select="$mixed-children-ns"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:body" mode="tan:dependency-expansion-normal">
      <xsl:param name="token-definition" as="element()*" tunnel="yes"/>
      <xsl:variable name="this-src-id" select="../@src"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="token-definition"
               select="($token-definition[tan:src/text() = $this-src-id])[1]" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:div" mode="tan:dependency-expansion-normal">
      <xsl:param name="token-definition" as="element()*" tunnel="yes"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:choose>
            <!-- Existence of a token definition is a tacit request to tokenize any divs that haven't been tokenized yet -->
            <xsl:when test="exists($token-definition) and not(exists((tan:tok, tan:div)))">
               <xsl:apply-templates select="(*, comment())" mode="#current"/>
               <xsl:copy-of select="tan:tokenize-text(text(), $token-definition, true())/*"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:copy>
   </xsl:template>
   
   
   
   
   <!-- Class 2 files -->
   
   <xsl:template match="tan:div-ref" mode="tan:core-expansion-normal tan:class-2-expansion-normal">
      <xsl:copy-of select="."/>
   </xsl:template>
   
   
   
   
   <!-- TAN-A -->
   
   <xsl:template match="tan:subject/tan:div | tan:object/tan:div" priority="1" mode="tan:core-expansion-normal">
      <!-- This template prevents a <div> within a claim being treated as if part of a class 1 file. -->
      <xsl:copy-of select="."/>
   </xsl:template>
   
   
   <!-- TAN-voc -->
   
   <xsl:template match="tan:TAN-voc/tan:body" mode="tan:core-expansion-normal">
      <xsl:variable name="duplicate-names" as="element()*">
         <xsl:for-each-group select=".//tan:name"
            group-by="ancestor::tan:*[tan:affects-element][1]/tan:affects-element">
            <xsl:for-each-group select="current-group()" group-by=".">
               <xsl:if test="count(current-group()) gt 1">
                  <xsl:copy-of select="current-group()"/>
               </xsl:if>
            </xsl:for-each-group>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-names" select="$duplicate-names" tunnel="yes"/>
         </xsl:apply-templates>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:name" mode="tan:core-expansion-normal">
      <xsl:param name="duplicate-names" tunnel="yes"/>
      <xsl:variable name="this-name-normalized" select="tan:normalize-name(.)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="$this-name-normalized = $duplicate-names">
            <xsl:copy-of select="tan:error('voc02')"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
</xsl:stylesheet>
