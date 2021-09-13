<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to Catalog Creator, the TAN application that creates an XML or TAN catalog of files -->
    <!-- Version 2021-07-07-->
    
    <!-- This master stylesheet is the public interface for the application. The parameters you will most
      likely want to change are listed and documented below, to help you customize the application to suit
      your needs. If you are relatively new to XSLT, or TAN applications, see Using TAN Applications and
      Utilities in the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and edit and
      run it directly. Or create and configure a transformation scenario in Oxygen, defining the relevant
      parameters as you like. If you are comfortable with XSLT, try creating your own stylesheet, then
      import this one, and customize the process. To access the code base, follow the link in the
      <xsl:include> at the bottom of this file. -->
    
    <!-- DESCRIPTION -->
    
    <!-- Primary input: any XML file -->
    <!-- Secondary input: none -->
    <!-- Primary output: perhaps diagnostics -->
    <!-- Secondary output: a new catalog file for select files in the input file's directory, and perhaps
        subdirectories; if the collection is TAN-only, the filename will be catalog.tan.xml, otherwise it
        will be catalog.xml -->
    
    <!-- Every catalog file is an XML file with a root element <collection> with children elements <doc>.
        Both <collection> and <doc> are in no namespace. <doc> can contain anything, but it is arbitrary. -->
    
    <!-- Nota bene: -->
    <!-- * Files with the name catalog.tan.xml and catalog.xml will be ignored. -->
    <!-- * Only files available as an XML document will be catalogued. -->


    <!-- PARAMETERS -->
    
    <!-- Do you wish to catalog only TAN files? -->
    <xsl:param name="tan-only" as="xs:boolean" select="true()"/>
    
    <!-- Do you want to embed in each <doc> listing a TAN file the entirety of the contents of the resolved 
        <head>, or do you want only minimal metadata (the children of <head> before <vocabulary-key>)? -->
    <xsl:param name="include-fully-resolved-metadata" as="xs:boolean" select="false()"/>
    
    <!-- What files do you want to exclude from results? Expected: a regular expression. Patterns perhaps
        to include:
        /\.             ignores hidden files and directories
        %20-%20Copy     ignores copies of files (Windows default)
        /te?mp-?\d*/      ignores directories such as temp tmp tmp2
        private-        ignores files marked as private
        /archive        ignores files in subdirectories marked as archives
        /transformation ignores files in subdirectories marked as holding transformations
        /output         ignores files in subdirectories marked as XSLT output
    -->
    <xsl:param name="exclude-filenames-that-match-what-pattern" as="xs:string?"
        select="'private-|/archive|/transformations|/output|/te?mp-?\d*/|%20-%20copy|temp-|/\.'"/>
    
    <!-- Do you wish to index deeply? If true, then the catolog file will look in subdirectories for 
        candidate documents. -->
    <xsl:param name="index-deeply" as="xs:boolean" select="true()"/>
    
    

    <!-- The main engine for the application is in this file, and in other files it links to. Feel
        free to explore, but make alterations only if you know what you are doing. If you make
        changes, make a copy of the original file first.-->
    <xsl:include href="incl/Catalog%20Creator.xsl"/>
    
    
</xsl:stylesheet>
