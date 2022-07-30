<xsl:stylesheet 
   xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xslq="https://github.com/mricaud/xsl-quality"
   version="3.0">

   <!-- Welcome to the TAN Function Library! -->

   <!-- This file is the primary point of entry into the TAN Function Library, the XSLT code that drives the 
      Text Alignment Network. The library has been designed not only for validation, but for a variety of 
      applications. As an XSLT package, it may be invoked through xsl:import, xsl:include, fn:transform() or 
      a comparable mechanism. Some of the components of the package may be accessed directly, as well. See 
      documentation in each enclosed file. -->

   <!-- A sharp distinction is made between validation mode and non-validation mode. As many components as possible
      are removed during validation mode, to improve efficiency. By default validation mode is turned off, which means
      that any application that includes this file will have access to the entire library. 
   -->
   <!-- Some functions may not be available, or be restricted, if advanced processing features are not supported. -->
   
   <!-- Maintenance notes:
      * During development this stylesheet is checked with validation scenarios drawn from /maintenance, as well 
      as Matthieu Ricaud-Dussarget's XSLT Quality, modified. That can be a time-consuming process, because it is
      checked against all the master files, so that validation routine may be turned off.
   -->

   <!-- STATIC PARAMETERS -->
   <xsl:import href="setup/TAN-parameters-static.xsl"/>

   <!-- DYNAMIC PARAMETERS -->
   <!-- setup parameters are not intended for users to configure; they are there to allow 
      an application or program to control certain settings. -->
   <xsl:import href="setup/TAN-parameters-validation.xsl"/>
   <xsl:import href="setup/TAN-parameters-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- The rest of the parameters are intended for users to configure. -->
   <xsl:import href="../parameters/params-application.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:import href="../parameters/params-application-diff.xsl"
      use-when="not($tan:validation-mode-on)"/>
   <xsl:import href="../parameters/params-application-language.xsl"
      use-when="not($tan:validation-mode-on)"/>
   <xsl:import href="../parameters/params-application-search.xsl"
      use-when="not($tan:validation-mode-on)"/>
   <xsl:import href="../parameters/params-application-html-output.xsl"
      use-when="not($tan:validation-mode-on)"/>
   <xsl:import href="../parameters/params-function-diff.xsl"/>
   <xsl:import href="../parameters/params-validation.xsl"/>

   <!-- GLOBAL VARIABLES -->
   <xsl:include href="setup/TAN-variables-standard.xsl"/>
   <xsl:include href="setup/TAN-variables-extended.xsl" use-when="not($tan:validation-mode-on)"/>

   <!-- KEYS -->
   <xsl:include href="setup/TAN-keys-standard.xsl"/>
   <xsl:include href="setup/TAN-keys-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   
   <!-- CHARACTER MAPS -->
   <xsl:include href="setup/TAN-character-maps.xsl"/>

   <!-- FUNCTIONS -->
   <!-- Errors for TAN file structures -->
   <xsl:include href="errors/TAN-core-errors.xsl"/>
   <!-- Regular expressions -->
   <xsl:include href="regex/TAN-fn-regex-standard.xsl"/>
   <!-- General functions on nodes -->
   <xsl:include href="nodes/TAN-fn-nodes-standard.xsl"/>
   <xsl:include href="nodes/TAN-fn-nodes-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="nodes/TAN-fn-nodes-TAN-output.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Numerals, numeral systems -->
   <xsl:include href="numerals/TAN-fn-numerals-standard.xsl"/>
   <xsl:include href="numerals/TAN-fn-numerals-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="numerics/TAN-fn-numerics-standard.xsl"/>
   <xsl:include href="numerics/TAN-fn-numerics-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="numerics/TAN-fn-numeric-conversion.xsl"/>
   <xsl:include href="numerics/TAN-fn-octets.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="numerics/TAN-fn-binary.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Date, time, and version -->
   <xsl:include href="time/TAN-fn-time.xsl"/>
   <!-- Sequences -->
   <xsl:include href="sequences/TAN-fn-sequences-standard.xsl"/>
   <xsl:include href="sequences/TAN-fn-sequences-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Strings -->
   <xsl:include href="strings/TAN-fn-strings-standard.xsl"/>
   <xsl:include href="strings/TAN-fn-strings-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="strings/TAN-fn-strings-diff-standard.xsl"/>
   <xsl:include href="strings/TAN-fn-strings-diff-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="strings/TAN-fn-strings-collate-standard.xsl"/>
   <xsl:include href="strings/TAN-fn-strings-collate-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- URIs -->
   <xsl:include href="uris/TAN-fn-uris-standard.xsl"/>
   <xsl:include href="uris/TAN-fn-uris-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="uris/TAN-fn-uris-writing-fragids.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Cross-references -->
   <xsl:include href="cross-references/TAN-fn-cross-references.xsl"/>
   <!-- Vocabulary -->
   <xsl:include href="vocabulary/TAN-fn-vocabulary.xsl"/>
   <!-- Files -->
   <xsl:include href="files/TAN-fn-files-standard.xsl"/>
   <xsl:include href="files/TAN-fn-files-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="files/TAN-fn-file-output.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="files/TAN-fn-file-archive-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Statistics -->
   <xsl:include href="statistics/TAN-fn-statistics-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- HTML -->
   <xsl:include href="html/TAN-fn-html-core.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="html/TAN-fn-html-colors.xsl" use-when="not($tan:validation-mode-on)"/>
   <xsl:include href="html/TAN-fn-html-diff-and-collate.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Booleans -->
   <xsl:include href="booleans/TAN-fn-booleans.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Maps -->
   <xsl:include href="maps/TAN-fn-maps-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Arrays -->
   <xsl:include href="arrays/TAN-fn-arrays-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Language -->
   <xsl:include href="language/TAN-fn-language-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Diagnostics -->
   <xsl:include href="diagnostics/TAN-fn-function-diagnostics.xsl" use-when="$tan:include-diagnostics-components"/>
   <xsl:include href="diagnostics/TAN-fn-schema-diagnostics.xsl" use-when="$tan:include-diagnostics-components"/>
   <xsl:include href="diagnostics/TAN-fn-nodes-diagnostics.xsl" use-when="$tan:include-diagnostics-components"/>
   <!-- Search -->
   <xsl:include href="search/TAN-fn-search-extended.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- Checksums and hashes -->
   <xsl:include href="checksums/TAN-fn-hash-and-check.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- docx -->
   <xsl:include href="docx/TAN-fn-docx.xsl" use-when="not($tan:validation-mode-on)"/>
   <!-- tei -->
   <xsl:include href="tei/TAN-fn-tei.xsl" use-when="not($tan:validation-mode-on)"/>


   <!-- PROCESSES -->
   <!-- Resolving TAN files -->
   <xsl:include href="resolution/TAN-fn-resolve-files.xsl"/>
   <!-- Expanding TAN files -->
   <xsl:include href="expansion/TAN-fn-expand-files.xsl"/>
   <!-- Merging TAN files -->
   <xsl:include href="merging/TAN-fn-merging.xsl"/>

   <xslq:parameters>
      <xslq:use-oxygen-documentation>false</xslq:use-oxygen-documentation>
   </xslq:parameters>

</xsl:stylesheet>