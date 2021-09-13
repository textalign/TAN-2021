<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Parameters for applications that use searching -->
   
   <!-- Not every application will make use of these parameters, even when supporting searches. 
      Check the documentation with the application of choice. -->
   
   <!-- Should searches ignore accents? -->
   <xsl:param name="tan:searches-ignore-accents" select="true()" as="xs:boolean"/>

   <!-- Should searches be case-sensitive by default? -->
   <xsl:param name="tan:searches-are-case-sensitive" select="false()" as="xs:boolean"/>

   <!-- What are the default flags for matching? -->
   <xsl:param name="tan:search-match-flags" select="
         if ($tan:searches-are-case-sensitive = true()) then
            ()
         else
            'i'" as="xs:string?"/>
   
   <!-- When searching, what text should be suppressed? -->   
   <xsl:param name="tan:searches-suppress-what-text" as="xs:string?" select="'[\p{M}]'"/>
   
   <!-- When searching for records on the internet, what is the maximum number that should be returned? -->
   <xsl:param name="tan:search-record-maximum" as="xs:integer" select="10"/>
   
   
   
   
</xsl:stylesheet>
