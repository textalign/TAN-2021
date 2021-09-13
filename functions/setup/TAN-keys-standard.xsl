<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
   
   <!-- TAN Function Library keys -->
   
   <xsl:key name="tan:attrs-by-name" match="@*" use="local-name(.)"/>
   <xsl:key name="tan:elements-by-name" match="*" use="local-name(.)"/>
   <xsl:key name="tan:elements-with-attrs-named" match="*" use="
         for $i in @*
         return
            local-name($i)"/>
   
   <!-- Points to @q, which in TAN is reserved for initial generate-id() values -->   
   <xsl:key name="tan:q-ref" match="*" use="@q"/>
   
   <xsl:key name="tan:div-via-ref" match="tan:div" use="tan:ref/text()"/>
   <xsl:key name="tan:tok-via-val" match="tan:tok" use="text()"/>
   
   
   <!-- The following key allows you to quickly find in a TAN-voc file vocabulary <item>s for a particular element or attribute -->
   <xsl:key name="tan:item-via-node-name" match="tan:item"
      use="tokenize(string-join((ancestor-or-self::*[@affects-element][1]/@affects-element, ancestor-or-self::*[@affects-attribute][1]/@affects-attribute), ' '), '\s+')"/>
   
   
</xsl:stylesheet>
