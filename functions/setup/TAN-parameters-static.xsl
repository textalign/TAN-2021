<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:file="http://expath.org/ns/file"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- Core static parameters for the TAN function library. These static parameters may be overwritten, but 
      such overwriting is intended mainly for developers. For parameters that most users will likely wish to 
      change, see the parameters subdirectory in the TAN project.
   -->

   <!-- Should the TAN Function Library operate in validation mode? If true, many components will be removed at
      compile time, and some template behavior will be modified. If false (default), then all components will be
      included. Normally, use true only if validating a TAN file, or simulating that process.
   -->
   <xsl:param name="tan:validation-mode-on" as="xs:boolean" select="false()" static="yes"/>
   
   <!-- Are advanced features such as xsl:function/@cache or higher order functions supported? False if using Saxon HE; true for Saxon PE and EE. -->
   <xsl:param name="tan:advanced-processing-available" as="xs:boolean" static="yes"
      select="system-property('xsl:supports-higher-order-functions') eq 'yes'"/>
   
   <!-- Are the file (namespace http://expath.org/ns/file) functions available? -->
   <xsl:param name="tan:file-functions-available" as="xs:boolean" static="yes"
      select="function-available('file:exists')"/>
   
   <!-- Should diagnostic functions and templates be included? True only for TAN development and testing.  -->
   <xsl:param name="tan:include-diagnostics-components" as="xs:boolean" select="false()" static="yes"/>
   
   <!-- Should attributes with diagnostic information be infused into output from tan:diff()? -->
   <xsl:param name="tan:infuse-diff-diagnostics" as="xs:boolean" select="false()" static="yes"/>
    
    <!-- Is support for XML 1.1 available? (C# environments, for example, do not support XML 1.1.) -->
   <xsl:param name="tan:xml-1-1-is-supported" as="xs:boolean" select="true()" static="yes"/>
    
   

</xsl:stylesheet>
