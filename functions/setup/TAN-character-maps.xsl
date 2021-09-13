<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
   <!-- TAN Function Library character maps -->
   
   <xsl:character-map name="tan:see-special-chars">
      <!-- This character map shapes output so that one can see where ZWJs and soft hyphens are in use. -->
      <xsl:output-character character="&#x200b;" string="&amp;#x200b;"/>
      <xsl:output-character character="&#x200c;" string="&amp;#x200c;"/>
      <xsl:output-character character="&#x200d;" string="&amp;#x200d;"/>
      <xsl:output-character character="&#xad;" string="&amp;#xad;"/>
   </xsl:character-map>
   
</xsl:stylesheet>
