<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:functx="http://www.functx.com"
   xmlns:sch="http://purl.oclc.org/dsdl/schematron" exclude-result-prefixes="#all" version="3.0">

   <!-- Core functions for detecting errors in TAN files. Written principally for Schematron validation, but suitable for general use in other contexts -->

   <xsl:template match="tan:error/tan:fix | tan:help/tan:fix | 
      tan:warning/tan:fix | tan:fatal/tan:fix | tan:info/tan:fix"
      priority="-999" mode="#all">
      <xsl:copy-of select="."/>
   </xsl:template>

   <xsl:variable name="tan:errors" select="doc('TAN-errors.xml')" as="document-node()"/>
   <xsl:variable name="tan:errors-to-squelch" as="element()*"
      select="$tan:errors/tan:errors/tan:squelch[@phase = $tan:default-validation-phase]/tan:error-id"/>
   
   <xsl:function name="tan:fix" as="element()?" visibility="private">
      <!-- Input: any items; a string representing a fix type -->
      <!-- Ouput: a tan:fix element with @type -->
      <!-- This function is used to populate a file with material to be used by Schematron Quick Fixes -->
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:if test="string-length($fix-type) gt 0">
         <fix type="{$fix-type}">
            <xsl:copy-of select="$fix"/>
         </fix>
      </xsl:if>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?" visibility="private">
      <!-- one-parameter function of the master version, below -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:copy-of select="tan:error($idref, (), (), (), ())"/>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?" visibility="private">
      <!-- two-parameter function of the master version, below -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:copy-of select="tan:error($idref, $diagnostic-message, (), (), ())"/>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?" visibility="private">
      <!-- four-parameter function of the master version, below -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:copy-of select="tan:error($idref, $diagnostic-message, $fix, $fix-type, ())"/>
   </xsl:function>
   <xsl:function name="tan:error" as="element()?" visibility="private">
      <!-- Input: idref of an error, and optional diagnostic messages -->
       <!--  Output: the appropriate <error> with each diagnostic inserted as a child <message> -->
      <xsl:param name="idref" as="xs:string"/>
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:param name="elements-that-caused-this-error" as="element()*"/>
      <xsl:variable name="this-error" select="$tan:errors//id($idref)"/>
      <xsl:for-each select="$this-error">
         <xsl:if test="$tan:error-messages-on" use-when="not($tan:validation-mode-on)">
            <xsl:message select="xs:string(tan:rule)"/>
         </xsl:if>
         <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="*"/>
            <xsl:for-each select="$diagnostic-message">
               <xsl:if test="$tan:error-messages-on" use-when="not($tan:validation-mode-on)">
                  <xsl:message>
                     <xsl:value-of select="."/>
                  </xsl:message>
               </xsl:if>
               <message>
                  <xsl:if test=". instance of element() and exists(@*)">
                     <xsl:text>[</xsl:text>
                     <xsl:value-of select="@* except @q"/>
                     <xsl:text>] </xsl:text>
                  </xsl:if>
                  <xsl:value-of select="."/>
               </message>
            </xsl:for-each>
            <xsl:copy-of select="tan:fix($fix, $fix-type)"/>
            <xsl:copy-of select="tan:shallow-copy($elements-that-caused-this-error)"/>
         </xsl:copy>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:error-report" as="xs:string*" visibility="private">
      <!-- Input: <error>s or strings corresponding to an error id -->
      <!-- Output: a sequence of strings to be reported to the user -->
      <!-- This function is used primary for Schematron reports -->
      <xsl:param name="error" as="item()*"/>
      <xsl:variable name="error-element" as="element()*">
         <xsl:for-each select="$error">
            <xsl:choose>
               <xsl:when test=". instance of xs:string">
                  <!-- assumes that the string is an error id -->
                  <xsl:copy-of select="tan:error(.)"/>
               </xsl:when>
               <xsl:when test="self::*">
                  <xsl:copy-of select="."/>
               </xsl:when>
            </xsl:choose>
         </xsl:for-each>
      </xsl:variable>
      <xsl:for-each select="$error-element">
         <xsl:variable name="this-message" select="string-join(tan:message, '; ')"/>
         <xsl:value-of select="$this-message || ' [' || @xml:id || ': ' || tan:rule[1] || ']'"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:mode name="tan:element-to-error" on-no-match="shallow-skip"/>

   <xsl:template match="*" mode="tan:element-to-error">
      <!-- This template turns any simple element (e.g., <report>, <assert>, <comment>, <change>) into an error report -->
      <xsl:param name="error-id" as="xs:string?"/>
      <xsl:variable name="this-type-of-flag"
         select="
            if (@flags = ('warning', 'error', 'info', 'fatal')) then
               @flags
            else
               'error'"
         as="xs:string"/>
      <xsl:element name="{$this-type-of-flag}">
         <xsl:copy-of select="@* except @flags"/>
         <xsl:if test="string-length($error-id) gt 1">
            <xsl:attribute name="xml:id" select="$error-id"/>
            <xsl:variable name="this-error" select="$tan:errors//id($error-id)"/>
            <xsl:copy-of select="$this-error/tan:rule"/>
         </xsl:if>
         <message>
            <xsl:value-of select="."/>
         </message>
      </xsl:element>
   </xsl:template>
   
   <xsl:function name="tan:error-codes" as="xs:string*" visibility="private">
      <!-- Input: a string -->
      <!-- Output: the error codes found within the string -->
      <!-- This function is used primarily in Schematron validation, to parse comments in functions/errors/*.xml and see which errors are expected. -->
      <xsl:param name="string-with-error-codes" as="xs:string?"/>
      <xsl:if test="string-length($string-with-error-codes) gt 0">
         <xsl:analyze-string select="$string-with-error-codes" regex="\w\w\w\d\d">
            <xsl:matching-substring>
               <xsl:value-of select="."/>
            </xsl:matching-substring>
         </xsl:analyze-string>
      </xsl:if>
   </xsl:function>

   <xsl:variable name="tan:help-trigger-regex" select="tan:escape($tan:help-trigger)" as="xs:string"/>
   
   <xsl:function name="tan:help" as="element()" visibility="private">
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:copy-of select="tan:help-or-info($diagnostic-message, $fix, $fix-type, false())"/>
   </xsl:function>
   <xsl:function name="tan:info" as="element()" visibility="private">
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:copy-of select="tan:help-or-info($diagnostic-message, $fix, $fix-type, true())"/>
   </xsl:function>
   <xsl:function name="tan:help-or-info" as="element()" visibility="private">
      <!-- Input: a sequence of items to populate a message, a series of items to be used in a SQFix, and a boolean value indicating whether the output element should be named info (rather than help) -->
      <!-- Output: an element with the appropriate help or info message -->
      <xsl:param name="diagnostic-message" as="item()*"/>
      <xsl:param name="fix" as="item()*"/>
      <xsl:param name="fix-type" as="xs:string?"/>
      <xsl:param name="is-info" as="xs:boolean"/>
      <xsl:element name="{if ($is-info = true()) then 'info' else 'help'}">
         <xsl:for-each select="$diagnostic-message">
            <message>
               <xsl:value-of select="."/>
            </message>
         </xsl:for-each>
         <xsl:copy-of select="tan:fix($fix, $fix-type)"/>
      </xsl:element>
   </xsl:function>

   <xsl:function name="tan:help-extracted" as="element()*" visibility="private">
      <!-- Input: any strings -->
      <!-- Output: one element per string, with @help if help has been requested, and containing the value of the string after the help request has been removed. -->
      <xsl:param name="strings-to-check" as="xs:string*"/>
      <xsl:for-each select="$strings-to-check">
         <xsl:variable name="this-val-parsed" as="element()">
            <val>
               <xsl:analyze-string select="." regex="{$tan:help-trigger-regex}">
                  <xsl:matching-substring>
                     <help/>
                  </xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </val>
         </xsl:variable>
         <val>
            <xsl:if test="exists($this-val-parsed/tan:help)">
               <xsl:attribute name="help"
                  select="string-length(string-join($this-val-parsed/tan:help/preceding::text()))"/>
            </xsl:if>
            <xsl:value-of select="normalize-space(string-join($this-val-parsed/text(), ''))"/>
         </val>
      </xsl:for-each>
   </xsl:function>
</xsl:stylesheet>
