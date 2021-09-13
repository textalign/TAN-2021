<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- Core validation parameters for the TAN function library. These parameters should normally not
      be changed. They are manipulated by the Schematron validation routine. For parameters that most 
      users will likely wish to change, see the parameters subdirectory in the TAN project.
   -->
   
   <!-- Normally one would need only one parameter to set the validation phase, but that approach 
      is not possible with the Schematron file that needs to configure the parameter. The three
      validation phases would require the same parameter to be defined three times in the same 
      file, which throws an error.
   -->

   <!-- If a TAN file is validated, should it be expanded tersely? Overwritten by a true value given 
      to deeper validation level. This value is effectively true if both deeper validation levels 
      are false. -->
   <xsl:param name="tan:validation-is-terse" as="xs:boolean" select="false()"/>
   <!-- If a TAN file is validated, should it be expanded normally? Overwritten by a true value given 
      to deeper validation level. -->
   <xsl:param name="tan:validation-is-normal" as="xs:boolean" select="false()"/>
   <!-- If a TAN file is validated, should it be expanded verbosely? -->
   <xsl:param name="tan:validation-is-verbose" as="xs:boolean" select="false()"/>

   <!-- What should the default validation phase be? Expected values: terse (default), normal, verbose -->
   <xsl:param name="tan:default-validation-phase" as="xs:string" select="
         if ($tan:validation-is-verbose)
         then
            'verbose'
         else
            if ($tan:validation-is-normal) then
               'normal'
            else
               'terse'"/>

</xsl:stylesheet>
