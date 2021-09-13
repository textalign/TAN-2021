<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library cross-reference functions. -->
   
   <xsl:function name="tan:get-via-q-ref" as="node()*" visibility="public">
      <!-- Input: any number of q-refs, any number of q-reffed documents -->
      <!-- Output: the elements corresponding to the q-refs -->
      <!-- This function is used by the core validation routine, mainly to find errors in expanded output -->
      <!--kw: identifiers -->
      <xsl:param name="q-ref" as="xs:string*"/>
      <xsl:param name="q-reffed-document" as="document-node()*"/>
      <xsl:for-each select="$q-reffed-document">
         <xsl:sequence select="key('tan:q-ref', $q-ref, .)"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:takes-idrefs" as="xs:boolean+" visibility="private">
      <!-- Input: any attributes -->
      <!-- Output: booleans, whether it takes idrefs or not -->
      <xsl:param name="attributes" as="attribute()+"/>
      <xsl:for-each select="$attributes">
         <xsl:value-of select="exists(tan:target-element-names(.))"/>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:target-element-names" as="xs:string*" visibility="private">
      <!-- Input: any strings, attributes, or elements -->
      <!-- Output: the names of the elements pointed to, if the name or the value of the 
         input is the name of an element or attribute that takes idrefs -->
      <xsl:param name="items" as="item()*"/>
      <xsl:for-each select="$items">
         <xsl:variable name="this-item" as="item()" select="."/>
         <xsl:variable name="this-item-val-norm" select="normalize-space($this-item)"/>
         <xsl:choose>
            <xsl:when test="$this-item instance of xs:string and string-length($this-item-val-norm) gt 0">
               <xsl:variable name="this-idref-entry"
                  select="$tan:id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[(@element, @attribute) = $this-item-val-norm]]"/>
               <xsl:copy-of select="$this-idref-entry/tan:element/text()"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="this-is-attribute" as="xs:boolean" select=". instance of attribute()"/>
               <xsl:variable name="this-is-element" as="xs:boolean" select=". instance of element()"/>
               <xsl:variable name="this-name" as="xs:string" select="name(.)"/>
               <xsl:variable name="this-parent-name" as="xs:string" select="name(..)"/>
               <xsl:choose>
                  <xsl:when test="$this-name = ('which', 'type')">
                     <!-- @which always points to an element that has the name as its parent, and perhaps some other elements, 
                        as defined at TAN-idrefs.xml. @type is used in many places, and the parent name is picked up by the
                        parent's name
                     -->
                     <xsl:variable name="this-idref-entry"
                        select="$tan:id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@element = $this-parent-name]]"
                     />
                     <xsl:copy-of select="$this-parent-name, $this-idref-entry/tan:element/text()"/>
                  </xsl:when>
                  <xsl:when test="$this-is-element">
                     <xsl:variable name="this-idref-entry"
                        select="$tan:id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@element = $this-name]]"/>
                     <xsl:copy-of select="$this-name, $this-idref-entry/tan:element/text()"/>
                  </xsl:when>
                  <xsl:when test="$this-is-attribute">
                     <xsl:variable name="this-idref-entry"
                        select="$tan:id-idrefs/tan:id-idrefs/tan:id[tan:idrefs[@attribute = $this-name]]"/>
                     <xsl:copy-of select="$this-idref-entry/tan:element/text()"/>
                  </xsl:when>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:function>

</xsl:stylesheet>
