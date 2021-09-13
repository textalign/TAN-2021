<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
   <sch:title>Schematron tests for maintaining the TAN function library</sch:title>
   <sch:ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>
   <sch:ns uri="tag:textalign.net,2015:ns" prefix="tan"/>
   
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   
   <sch:let name="master-open-and-save-archive-file"
      value="doc('https://github.com/Arithmeticus/xslt-for-docx/raw/master/open-and-save-archive.xsl')"/>
   <sch:let name="master-regex-function-file"
      value="doc('https://github.com/textalign/TAN-regex/raw/master/TAN-regex.xsl')"/>
   
   <sch:pattern>
      <sch:title>External inclusions</sch:title>
      <sch:p>These rules pertain to stylesheets that are part-and-parcel of external libraries. This
         approach has been adopted instead of Git submodule because of the difficulty for
         nonexperienced users to make sure submodules are included. </sch:p>
      <sch:rule
         context="xsl:stylesheet[contains(base-uri(.), 'TAN-fn-file-archive-extended.xsl')]/* | 
         xsl:stylesheet[contains(base-uri(.), 'TAN-fn-file-archive-extended.xsl')]/comment()">
         <sch:let name="current-path" value="path(.)"/>
         <sch:let name="corresponding-element"
            value="$master-open-and-save-archive-file/*/node()[path(.) eq $current-path]"/>
         <sch:assert test="exists($corresponding-element)">There is no node in the master file that
            corresponds to this one, <sch:value-of select="$current-path"/>. </sch:assert>
         <sch:assert test="exists($corresponding-element) and deep-equal(., $corresponding-element)"
            >This node does not match its counterpart. Difference: <sch:value-of
               select="serialize(tan:diff(serialize(.), serialize($corresponding-element))/*)"/></sch:assert>
      </sch:rule>
      <sch:rule
         context="xsl:stylesheet[contains(base-uri(.), 'TAN-fn-regex-standard.xsl')]/* | 
         xsl:stylesheet[contains(base-uri(.), 'TAN-fn-regex-standard.xsl')]/comment()">
         <sch:let name="current-path" value="path(.)"/>
         <sch:let name="corresponding-element"
            value="$master-regex-function-file/*/node()[path(.) eq $current-path]"/>
         <sch:assert test="exists($corresponding-element)">There is no node in the master file that
            corresponds to this one, <sch:value-of select="$current-path"/>. </sch:assert>
         <sch:assert test="exists($corresponding-element) and deep-equal(., $corresponding-element)"
            >This node does not match its counterpart. Difference: <sch:value-of
               select="serialize(tan:diff(serialize(.), serialize($corresponding-element))/*)"/></sch:assert>
      </sch:rule>
   </sch:pattern>
   
   
</sch:schema>