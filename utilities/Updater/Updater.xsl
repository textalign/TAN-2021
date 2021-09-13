<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to Updater, the TAN application that converts TAN files from older versions 
        to the current version. -->
    
    <!-- This master stylesheet is the public interface for the application. The parameters you will most
      likely want to change are listed and documented below, to help you customize the application to suit
      your needs. If you are relatively new to XSLT, or TAN applications, see Using TAN Applications and
      Utilities in the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and edit and
      run it directly. Or create and configure a transformation scenario in Oxygen, defining the relevant
      parameters as you like. If you are comfortable with XSLT, try creating your own stylesheet, then
      import this one, and customize the process. To access the code base, follow the link in the
      <xsl:include> at the bottom of this file. -->
    <!-- Version 2021-07-07-->
    
    
    <!-- DESCRIPTION -->
    
    <!-- Primary input: any TAN file version 2020 -->
    <!-- Secondary input: none -->
    <!-- Primary output: the TAN file converted to the latest version -->
    <!-- Secondary output: none -->
    

    <!-- Nota bene: -->
    <!-- * To convert TAN files from a version earlier than 2020, use applications released with  
        prior alpha versions. -->
    
    
    <!-- PARAMETERS -->
    
    <!-- No parameters affect the behavior of this version of this application. -->
    

    <!-- The main engine for the application is in this file, and in other files it links to. Feel
        free to explore, but make alterations only if you know what you are doing. If you make
        changes, make a copy of the original file first.-->
    <xsl:include href="incl/Updater%20core.xsl"/>
    
    
</xsl:stylesheet>
