<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
   
   <!-- TAN Function Library extended array functions. -->
   
   <!-- An array is a function that contains zero or more members. Each members contains a sequence
      of zero or more items. Map members are ordered. Any item in an array member sequence might itself
      be an array or a map, which means that arrays can deeply nest. An array is a special kind of 
      function, in that it can be thought of and represented as a tree fragment of typed data. However, 
      arrays do not behave in XSLT the way a tree fragment does. Shallow copying and shallow skipping, 
      for example, result in deep copying and deep skipping respectively. The templates modes below offer 
      a way to circumvent this behavior and treat maps as tree data structures.
   -->
   
   <!-- For map counterparts, and the definitions of these modes, see ../maps/TAN-fn-maps-extended.xsl -->
   <xsl:template match=".[. instance of array(*)]" priority="-1" mode="tan:shallow-skip tan:text-only-copy">
      <!-- Array member numbers allow one to identify the location of an item within a deeply nested map/array structure. -->
      <xsl:param name="array-member-numbers" as="xs:integer*" tunnel="yes"/>
      <xsl:variable name="context-array" as="array(*)" select="."/>
      <xsl:variable name="context-size" as="xs:integer" select="array:size(.)"/>
      <xsl:for-each select="1 to $context-size">
         <xsl:apply-templates select="$context-array(current())" mode="#current">
            <xsl:with-param name="array-member-numbers" as="xs:integer" tunnel="yes" select="$array-member-numbers, ."/>
         </xsl:apply-templates>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:template match=".[. instance of array(*)]" priority="-1" mode="tan:shallow-copy tan:map-put tan:map-remove">
      <xsl:param name="array-member-numbers" as="xs:integer*" tunnel="yes"/>
      <!--<xsl:param name="map-entry-keys" tunnel="yes" as="xs:anyAtomicType*"/>-->
      <xsl:variable name="context-array" as="array(*)" select="."/>
      <xsl:variable name="context-size" as="xs:integer" select="array:size(.)"/>
      
      <xsl:variable name="results-pass-1" as="map(*)">
         <!-- XSLT does not (yet) have an xsl:array constructor, so to preserve the
            flow of the template, and keep the tunnel parameters in play, we build 
            an interim map, to be converted to an array in output. -->
         <xsl:map>
            <xsl:for-each select="1 to $context-size">
               <xsl:map-entry key=".">
                  <xsl:apply-templates select="$context-array(current())" mode="#current">
                     <xsl:with-param name="array-member-numbers" tunnel="yes" as="xs:integer+"
                        select="$array-member-numbers, ."/>
                  </xsl:apply-templates>
               </xsl:map-entry>
            </xsl:for-each>
         </xsl:map>
      </xsl:variable>
      
      <xsl:sequence select="
         array:join(for $i in sort(map:keys($results-pass-1))
         return
         [($results-pass-1($i))])"/>
      
   </xsl:template>
   
   
   
   <!-- CONVERSION FUNCTIONS -->
   
   <xsl:function name="tan:array-to-xml" as="element()*" visibility="public">
      <!-- Input: any items -->
      <!-- Output: any arrays in each item serialized as XML elements; each 
         member of the array will be wrapped by an <array:member> with @type
         specifying the item type it encloses. -->
      <!--kw: arrays, nodes -->
      <xsl:param name="arrays-to-convert" as="array(*)*"/>
      <xsl:apply-templates select="$arrays-to-convert" mode="tan:map-and-array-to-xml"/>
   </xsl:function>
   
   
   <xsl:function name="tan:xml-to-array" as="array(*)*" visibility="public">
      <!-- Input: XML tree fragments -->
      <!-- Output: those parts that conform to the output of tan:array-to-xml() converted
         to arrays. Anything in the input tree not matching array:array or array:member
         will be skipped, unless it is a member an array:array or array:member. Anything in 
         the array:member will be bound as the type assigned by the value of @type -->
      <!--kw: arrays, tree manipulation, nodes -->
      <xsl:param name="items-to-array" as="item()*"/>
      <xsl:apply-templates select="$items-to-array" mode="tan:xml-to-map-and-array"/>
   </xsl:function>
   
   <xsl:function name="tan:array-members" as="item()*" visibility="private">
      <!-- Support function for tan:xml-to-array(), which lacks an XSLT element for array building -->
      <xsl:param name="array-members" as="element(array:member)*"/>
      <xsl:apply-templates select="$array-members" mode="tan:build-maps-and-arrays"/>
   </xsl:function>
   
   
   <xsl:function name="tan:array-to-map" as="map(*)?" visibility="public">
      <!-- Input: an array; a boolean -->
      <!-- Output: a map; if the boolean is true and the first item in each member of the array
         is uniquely distinct from all other first items then those first items become the key
         and the tail of each member becomes the value of the map entry. Otherwise, the constructed
         map has integers from 1 onward as keys with each array member becoming the value of the
         map entry. -->
      <!--kw: arrays, maps -->
      <xsl:param name="array-to-convert" as="array(*)?"/>
      <xsl:param name="use-first-items-as-keys" as="xs:boolean"/>
      
      <xsl:apply-templates select="$array-to-convert" mode="tan:array-to-map">
         <xsl:with-param name="use-first-items-as-keys" tunnel="yes" select="$use-first-items-as-keys"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <xsl:mode name="tan:array-to-map" on-no-match="shallow-copy"/>
   
   <xsl:template match=".[. instance of array(*)]" mode="tan:array-to-map">
      <xsl:param name="use-first-items-as-keys" tunnel="yes" as="xs:boolean"/>
      <xsl:variable name="array-to-convert" as="array(*)" select="."/>
      <xsl:variable name="array-size" as="xs:integer" select="array:size($array-to-convert)"/>
      <xsl:variable name="first-items" as="item()*" select="
         for $i in (1 to $array-size)
         return
         $array-to-convert($i)[1]"/>
      <xsl:variable name="first-item-types" as="xs:string*" select="tan:item-type($first-items)"/>
      
      <xsl:variable name="first-items-are-ok-for-keys" as="xs:boolean" select="
         $use-first-items-as-keys
         and not($first-item-types = ('map', 'array', 'function', 'attribute', 'element', 'comment', 'document-node', 'processing-instruction', 'text'))
         and not(exists(tan:duplicate-items($first-items)))
         and ($array-size eq count($first-items))"/>
      
      
      <xsl:map>
         <xsl:choose>
            <xsl:when test="$first-items-are-ok-for-keys">
               <xsl:for-each select="$first-items">
                  <xsl:variable name="this-pos" as="xs:integer" select="position()"/>
                  <xsl:map-entry key=".">
                     <xsl:apply-templates select="tail($array-to-convert($this-pos))" mode="#current"/>
                  </xsl:map-entry>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:for-each select="1 to $array-size">
                  <xsl:variable name="this-pos" as="xs:integer" select="position()"/>
                  <xsl:map-entry key="$this-pos">
                     <xsl:apply-templates select="$array-to-convert($this-pos)" mode="#current"/>
                  </xsl:map-entry>
               </xsl:for-each>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:map>
      
      
      
   </xsl:template>
   
   
   <xsl:function name="tan:array-permutations" as="array(*)" visibility="public">
      <!-- Input: any array -->
      <!-- Output: an array whose members are sequences representing the permutations of each item in each member in the 
         input array. -->
      <!-- Example: [(1, 2), 'dog'] becomes [(1, 'dog'), (2, 'dog')] -->
      <!-- The output array will always have a size equal to the product of the item count in each input array member, and the 
         output array's members will share the exact same item count. -->
      <!--kw: arrays -->
      <xsl:param name="input-array" as="array(*)"/>
      <xsl:variable name="array-size" as="xs:integer" select="array:size($input-array)"/>
      <xsl:variable name="array-parts" as="array(*)*">
         <xsl:iterate select="1 to $array-size">
            <xsl:param name="permutations-so-far" as="array(*)*"/>
            <xsl:on-completion select="$permutations-so-far"/>
            <xsl:variable name="this-member-number" as="xs:integer" select="."/>
            <xsl:variable name="array-member" as="item()*" select="$input-array($this-member-number)"/>
            <xsl:variable name="new-permutations" as="array(*)+">
               <xsl:choose>
                  <xsl:when test="$this-member-number eq 1">
                     <xsl:sequence select="
                           for $i in $array-member
                           return
                              [$i]"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="
                           for $i in $permutations-so-far,
                              $j in $array-member
                           return
                              [($i(1), $j)]"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:next-iteration>
               <xsl:with-param name="permutations-so-far" select="$new-permutations"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      <xsl:sequence select="array:join($array-parts)"/>
   </xsl:function>
   
   
</xsl:stylesheet>
