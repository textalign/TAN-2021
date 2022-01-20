<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
   
   <!-- TAN Function Library extended keys -->
   
   <xsl:key name="tan:get-ana" match="tan:ana" use="tan:tok/@val"/>
   <xsl:key name="tan:div-via-calculated-ref" match="*:div[@n]" use="tan:get-ref(.)"/>
   <!-- Quickly look up vocabulary by a name value -->
   <xsl:key name="tan:vocab-item-by-name" match="tan:item | tan:verb" use="tan:name"/>
   
</xsl:stylesheet>
