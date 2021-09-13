<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tan="tag:textalign.net,2015:ns" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   version="3.0">
   
   <!-- Welcome to Body Sync, the TAN application that updates a transcription in a class 1 file to
      match that in a redivision -->
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
   
   <!-- Primary input: a class 1 file with a redivision element in the head -->
   <!-- Secondary input: the redivision -->
   <!-- Primary output: the primary input, with the text of its body revised to match the text in the chosen
      redivision -->
   <!-- Secondary output: none -->
   
   <!-- Nota bene:
      * The comparison can be made only on the basis of space-normalized comparisons, which means that
      the output will have leaf divs without any internal indentation. 
      * If there are any special end-of-div characters to insert, they will be rendered as hexadecimal 
      codepoint entities.
      * Comments and processing instructions inside the body will be retained. If you choose to mark
      alterations, make sure there aren't already some in your file, otherwise it will all get mixed up.
   -->
   
   <!-- PARAMETERS -->
   
   <!-- Feel free to change the parameters as you see fit. Make sure that any new values are acceptable
   types for the specified data type. -->
   
   <!-- Provide a number that specifies which <redivision> should be used as the basis for syncing the text. 
      Default is 1. -->
   <xsl:param name="redivision-number" as="xs:integer" select="1"/>
   
   <!-- Should insertions and deletions be documented in comments? -->
   <xsl:param name="mark-alterations" as="xs:boolean" select="true()"/>
   
   
   <!-- THE APPLICATION -->
   
   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/Body%20Sync%20core.xsl"/>
   
   
</xsl:stylesheet>