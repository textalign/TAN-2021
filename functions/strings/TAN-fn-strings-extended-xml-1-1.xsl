<?xml version="1.1"?>
<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   version="3.0">

   <!-- TAN Function Library extended string functions, requiring XML 1.1 support. -->
   
   <xsl:variable name="tan:control-chars" as="xs:string">&#x1;&#x2;&#x3;&#x4;&#x5;&#x6;&#x7;&#x8;&#xb;&#xc;&#xd;&#xe;&#xf;&#x10;&#x11;&#x12;&#x13;&#x14;&#x15;&#x16;&#x17;&#x18;&#x19;&#x1a;&#x1b;&#x1c;&#x1d;&#x1e;&#x1f;&#x7f;</xsl:variable>
   <xsl:variable name="tan:control-pictures" as="xs:string">␁␂␃␄␅␆␇␈␋␌␍␎␏␐␑␒␓␔␕␖␗␘␙␚␛␜␝␞␟␡</xsl:variable>
   
   <xsl:function name="tan:controls-to-pictures" as="item()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the items, but with any control characters changed to control pictures (U+2400 onward) -->
      <!-- This function excludes &#x0; &#x9; &#xa; -->
      <xsl:param name="items-to-change" as="item()*"/>
      <xsl:apply-templates select="$items-to-change" mode="tan:controls-to-pictures"/>
   </xsl:function>
   
   <xsl:mode name="tan:controls-to-pictures" on-no-match="shallow-copy"/>
   
   <xsl:template match=".[. instance of xs:string]" mode="tan:controls-to-pictures">
      <xsl:value-of select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   <xsl:template match="text()" mode="tan:controls-to-pictures">
      <xsl:value-of select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   <xsl:template match="comment()" mode="tan:controls-to-pictures">
      <xsl:comment><xsl:value-of select="translate(., $tan:control-chars, $tan:control-pictures)"/></xsl:comment>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="tan:controls-to-pictures">
      <xsl:processing-instruction name="{name(.)}" select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   <xsl:template match="@*" mode="tan:controls-to-pictures">
      <xsl:attribute name="{name(.)}" select="translate(., $tan:control-chars, $tan:control-pictures)"/>
   </xsl:template>
   
   <xsl:function name="tan:pictures-to-controls" as="item()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: the items, but with any control pictures (U+2400) changed to control characters -->
      <!-- This function excludes &#x0; &#x9; &#xa; &#xd; -->
      <xsl:param name="items-to-change" as="item()*"/>
      <xsl:apply-templates select="$items-to-change" mode="tan:pictures-to-controls"/>
   </xsl:function>
   
   <xsl:mode name="tan:pictures-to-controls" on-no-match="shallow-copy"/>
   
   <xsl:template match="text()" mode="tan:pictures-to-controls">
      <xsl:value-of select="translate(., $tan:control-pictures, $tan:control-chars)"/>
   </xsl:template>
   <xsl:template match="comment()" mode="tan:pictures-to-controls">
      <xsl:comment><xsl:value-of select="translate(., $tan:control-pictures, $tan:control-chars)"/></xsl:comment>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="tan:pictures-to-controls">
      <xsl:processing-instruction name="{name(.)}" select="translate(., $tan:control-pictures, $tan:control-chars)"/>
   </xsl:template>
   <xsl:template match="@*" mode="tan:pictures-to-controls">
      <xsl:attribute name="{name(.)}" select="translate(., $tan:control-pictures, $tan:control-chars)"/>
   </xsl:template>
   
   

</xsl:stylesheet>
