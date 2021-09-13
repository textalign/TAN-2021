<xsl:stylesheet exclude-result-prefixes="#all" xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library extended map functions. -->
   
   <!-- A map is a function that contains zero or more map entries. Each map entry is a key-value
      pair. All keys in a map are unique, and they must be an atomic type. The value, on the other
      hand, is a sequence of zero or more items, and is not necessarily unique within the map. Any
      one of those items might itself be a map or an array, which means that maps can deeply nest. A
      map is a special kind of function, in that it can be thought of and represented as a tree 
      fragment of typed data. However, maps do not behave in XSLT the way a tree fragment does. 
      Shallow copying and shallow skipping, for example, result in deep copying and deep skipping 
      respectively. The templates modes below offer a way to circumvent this behavior and treat 
      maps like the tree fragments they resemble.
   -->
   
   <!-- deep copy, deep skip, and fail not needed; see ../arrays/TAN-fn-arrays-extended.xsl for
      the counterpart templates for arrays -->
   <xsl:mode name="tan:text-only-copy" on-no-match="text-only-copy"/>
   <xsl:mode name="tan:shallow-copy" on-no-match="shallow-copy"/>
   <xsl:mode name="tan:shallow-skip" on-no-match="shallow-skip"/>
   
   <xsl:template match=".[. instance of map(*)]" priority="-1" mode="tan:shallow-skip tan:text-only-copy">
      <!-- Map entry keys allow one to identify the location of an item within a deeply nested map/array structure. -->
      <xsl:param name="map-entry-keys" tunnel="yes" as="xs:anyAtomicType*"/>
      <xsl:variable name="context-map" as="map(*)" select="."/>
      <xsl:for-each select="map:keys(.)">
         <xsl:apply-templates select="$context-map(current())" mode="#current">
            <!-- The map entry's key is passed as a tunnel parameter, so that any items deep in the
               structure can get the context of -->
            <xsl:with-param name="map-entry-keys" tunnel="yes" as="xs:anyAtomicType*" select="$map-entry-keys, ."/>
         </xsl:apply-templates>
      </xsl:for-each>
   </xsl:template>
   
   <xsl:template match=".[. instance of map(*)]" priority="-1" mode="tan:shallow-copy tan:map-put tan:array-to-map">
      <xsl:param name="map-entry-keys" tunnel="yes" as="xs:anyAtomicType*"/>
      <xsl:variable name="context-map" as="map(*)" select="."/>
      <xsl:map>
         <xsl:for-each select="map:keys(.)">
            <xsl:map-entry key=".">
               <xsl:apply-templates select="$context-map(current())" mode="#current">
                  <xsl:with-param name="map-entry-keys" tunnel="yes" as="xs:anyAtomicType*" select="$map-entry-keys, ."
                  />
               </xsl:apply-templates>
            </xsl:map-entry>
         </xsl:for-each>
      </xsl:map>
   </xsl:template>



   <!-- CONVERSION FUNCTIONS -->

   <xsl:function name="tan:map-to-xml" as="element()*" visibility="public">
      <!-- one-parameter version of fuller one below -->
      <xsl:param name="items-to-convert" as="item()*"/>
      <xsl:sequence select="tan:map-to-xml($items-to-convert, false())"/>
   </xsl:function>

   <xsl:function name="tan:map-to-xml" as="element()*" visibility="public">
      <!-- Input: any maps; a boolean -->
      <!-- Output: any maps in each item serialized as XML elements; the map entries
            will be sorted lexicographically by the key's string value if the boolean
            is true, otherwise the order of map entries is implementation-dependent. -->
      <!-- For those accustomed to handling ordinary XML nodes, maps can be frustrating to work with.
        This function allows one to change a map to XML, and do fun things with it, without requiring
        map functions. -->
      <!--kw: maps, nodes -->
      <xsl:param name="items-to-convert" as="map(*)*"/>
      <xsl:param name="sort-keys" as="xs:boolean"/>
      <xsl:apply-templates select="$items-to-convert" mode="tan:map-and-array-to-xml">
         <xsl:with-param name="sort-keys" tunnel="yes" select="$sort-keys"/>
      </xsl:apply-templates>
   </xsl:function>


   <xsl:mode name="tan:map-and-array-to-xml" on-no-match="shallow-copy"/>

   <xsl:template match=".[. instance of map(*)]" mode="tan:map-and-array-to-xml">
      <xsl:param name="sort-keys" tunnel="yes" as="xs:boolean?"/>
      <xsl:variable name="this-map" select="." as="map(*)"/>
      <map xmlns="http://www.w3.org/2005/xpath-functions/map">
         <xsl:for-each select="map:keys(.)">
            <xsl:sort select="
                  if ($sort-keys eq true()) then
                     string(.)
                  else
                     ()"/>
            <entry>
               <key>
                  <xsl:attribute name="type" select="tan:item-type(.)"/>
                  <xsl:value-of select="."/>
               </key>
               <value>
                  <xsl:for-each select="$this-map(.)">
                     <item>
                        <xsl:attribute name="type" select="tan:item-type(.)"/>
                        <xsl:apply-templates select="." mode="#current"/>
                     </item>
                  </xsl:for-each>
               </value>
            </entry>
         </xsl:for-each>
      </map>
   </xsl:template>

   <xsl:template match=".[. instance of array(*)]" mode="tan:map-and-array-to-xml">
      <xsl:variable name="this-array" as="array(*)" select="."/>
      <array xmlns="http://www.w3.org/2005/xpath-functions/array">
         <xsl:for-each select="1 to array:size(.)">
            <xsl:variable name="this-member-no" select="." as="xs:integer"/>
            <member>
               <xsl:for-each select="$this-array($this-member-no)">
                  <item type="{tan:item-type(.)}">
                     <xsl:apply-templates select="." mode="#current"/>
                  </item>
               </xsl:for-each>
            </member>
         </xsl:for-each>
      </array>
   </xsl:template>




   <xsl:function name="tan:xml-to-map" as="map(*)*" visibility="public">
      <!-- Input: XML tree fragments -->
      <!-- Output: those parts that conform to the output of tan:map-to-xml() converted to maps. Anything in 
         the input tree not matching <map:map>, <map:entry>, <map:key>, <map:value> will be skipped, unless 
         it is a member of <map:key> or <map:value>. Anything in the key or value will be bound as the type
         assigned by the values of @type.
      -->
      <!--kw: maps, nodes, tree manipulation -->
      <xsl:param name="items-to-map" as="item()*"/>
      <xsl:apply-templates select="$items-to-map" mode="tan:xml-to-map-and-array"/>
   </xsl:function>


   <xsl:mode name="tan:xml-to-map-and-array" on-no-match="shallow-skip"/>

   <xsl:template match="map:map" mode="tan:xml-to-map-and-array">
      <xsl:map>
         <xsl:apply-templates mode="#current"/>
      </xsl:map>
   </xsl:template>
   <xsl:template match="map:entry" mode="tan:xml-to-map-and-array">
      <xsl:map-entry key="tan:build-xml-to-map-key(map:key)">
         <xsl:apply-templates select="map:value/map:item" mode="tan:build-maps-and-arrays"/>
      </xsl:map-entry>
   </xsl:template>
   <xsl:template match="array:array" mode="tan:xml-to-map-and-array">
      <xsl:sequence select="
            array:join(for $i in array:member
            return
               [tan:array-members($i)])"/>
   </xsl:template>



   <xsl:function name="tan:build-xml-to-map-key" as="item()" visibility="private">
      <!-- Input: a map:key element -->
      <!-- Output: the key specified -->
      <xsl:param name="key-element" as="element(map:key)"/>
      <xsl:apply-templates select="$key-element" mode="tan:build-maps-and-arrays"/>
   </xsl:function>


   <xsl:mode name="tan:build-maps-and-arrays" on-no-match="shallow-skip"/>

   <!-- Items, relevant for only values -->
   <xsl:template
      match="map:item[@type eq 'document-node'] | array:item[@type eq 'document-node']"
      mode="tan:build-maps-and-arrays">
      <xsl:document>
         <xsl:apply-templates mode="#current"/>
      </xsl:document>
   </xsl:template>
   <xsl:template match="map:item[@type eq 'comment'] | array:item[@type eq 'comment']"
      mode="tan:build-maps-and-arrays">
      <xsl:comment>
         <xsl:apply-templates mode="#current"/>
      </xsl:comment>
   </xsl:template>
   <xsl:template
      match="map:item[@type eq 'processing-instruction'] | array:item[@type eq 'processing-instruction']"
      mode="tan:build-maps-and-arrays">
      <xsl:variable name="these-text-parts" as="element()" select="analyze-string(., '^\S+')"/>
      <xsl:processing-instruction name="{$these-text-parts/*:match}" select="$these-text-parts/*:non-match"/>
   </xsl:template>
   <xsl:template match="map:item[@type eq 'element'] | array:item[@type eq 'element']"
      mode="tan:build-maps-and-arrays">
      <xsl:copy-of select="*"/>
   </xsl:template>
   <xsl:template match="map:item[@type eq 'attribute'] | array:item[@type eq 'attribute']"
      mode="tan:build-maps-and-arrays">
      <xsl:apply-templates select="@* except @type" mode="#current"/>
   </xsl:template>
   <xsl:template match="@_type" mode="tan:build-maps-and-arrays">
      <xsl:attribute name="type" select="."/>
   </xsl:template>
   <xsl:template match="map:item[@type eq 'text'] | array:item[@type eq 'text']"
      mode="tan:build-maps-and-arrays">
      <xsl:value-of select="."/>
   </xsl:template>
   <xsl:template match="map:item[@type eq 'map'] | array:item[@type eq 'map']"
      mode="tan:build-maps-and-arrays">
      <xsl:apply-templates mode="tan:xml-to-map-and-array"/>
   </xsl:template>
   <xsl:template match="map:item[@type eq 'array'] | array:item[@type eq 'array']"
      mode="tan:build-maps-and-arrays">
      <xsl:apply-templates mode="tan:xml-to-map-and-array"/>
   </xsl:template>
   <!-- function is not supported -->
   <xsl:template match="map:item[@type = ('function')] | array:item[@type = ('function')]"
      mode="tan:build-maps-and-arrays">
      <xsl:message
         select="'Item type ' || @type || ' not supported by tan:xml-to-map(); returning unparsed text.'"/>
      <xsl:value-of select="."/>
   </xsl:template>


   <!-- Atomic values, relevant for both key and value -->
   <xsl:template match="map:key | map:item" priority="-1" mode="tan:build-maps-and-arrays">
      <xsl:value-of select="."/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:anyURI'] | map:item[@type eq 'xs:anyURI'] | array:item[@type eq 'xs:anyURI']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:anyURI(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:base64Binary'] | map:item[@type eq 'xs:base64Binary'] | array:item[@type eq 'xs:base64Binary']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:base64Binary(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:boolean'] | map:item[@type eq 'xs:boolean'] | array:item[@type eq 'xs:boolean']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:boolean(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:date'] | map:item[@type eq 'xs:date'] | array:item[@type eq 'xs:date']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:date(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:dateTime'] | map:item[@type eq 'xs:dateTime'] | array:item[@type eq 'xs:dateTime']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:dateTime(.)"/>
   </xsl:template>
   <!--<xsl:template
      match="map:key[@type eq 'xs:dateTimeStamp'] | map:item[@type eq 'xs:dateTimeStamp'] | array:item[@type eq 'xs:dateTimeStamp']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:dateTimeStamp(.)"/>
   </xsl:template>-->
   <xsl:template
      match="map:key[@type eq 'xs:decimal'] | map:item[@type eq 'xs:decimal'] | array:item[@type eq 'xs:decimal']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:decimal(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:integer'] | map:item[@type eq 'xs:integer'] | array:item[@type eq 'xs:integer']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:integer(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:long'] | map:item[@type eq 'xs:long'] | array:item[@type eq 'xs:long']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:long(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:int'] | map:item[@type eq 'xs:int'] | array:item[@type eq 'xs:int']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:int(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:short'] | map:item[@type eq 'xs:short'] | array:item[@type eq 'xs:short']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:short(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:byte'] | map:item[@type eq 'xs:byte'] | array:item[@type eq 'xs:byte']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:byte(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:nonNegativeInteger'] | map:item[@type eq 'xs:nonNegativeInteger'] | array:item[@type eq 'xs:nonNegativeInteger']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:nonNegativeInteger(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:positiveInteger'] | map:item[@type eq 'xs:positiveInteger'] | array:item[@type eq 'xs:positiveInteger']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:positiveInteger(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:unsignedLong'] | map:item[@type eq 'xs:unsignedLong'] | array:item[@type eq 'xs:unsignedLong']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:unsignedLong(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:unsignedInt'] | map:item[@type eq 'xs:unsignedInt'] | array:item[@type eq 'xs:unsignedInt']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:unsignedInt(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:unsignedShort'] | map:item[@type eq 'xs:unsignedShort'] | array:item[@type eq 'xs:unsignedShort']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:unsignedShort(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:unsignedByte'] | map:item[@type eq 'xs:unsignedByte'] | array:item[@type eq 'xs:unsignedByte']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:unsignedByte(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:nonPositiveInteger'] | map:item[@type eq 'xs:nonPositiveInteger'] | array:item[@type eq 'xs:nonPositiveInteger']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:nonPositiveInteger(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:negativeInteger'] | map:item[@type eq 'xs:negativeInteger'] | array:item[@type eq 'xs:negativeInteger']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:negativeInteger(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:double'] | map:item[@type eq 'xs:double'] | array:item[@type eq 'xs:double']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:double(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:duration'] | map:item[@type eq 'xs:duration'] | array:item[@type eq 'xs:duration']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:duration(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:dayTimeDuration'] | map:item[@type eq 'xs:dayTimeDuration'] | array:item[@type eq 'xs:dayTimeDuration']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:dayTimeDuration(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:yearMonthDuration'] | map:item[@type eq 'xs:yearMonthDuration'] | array:item[@type eq 'xs:yearMonthDuration']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:yearMonthDuration(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:float'] | map:item[@type eq 'xs:float'] | array:item[@type eq 'xs:float']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:float(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:gDay'] | map:item[@type eq 'xs:gDay'] | array:item[@type eq 'xs:gDay']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:gDay(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:gMonth'] | map:item[@type eq 'xs:gMonth'] | array:item[@type eq 'xs:gMonth']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:gMonth(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:gMonthDay'] | map:item[@type eq 'xs:gMonthDay'] | array:item[@type eq 'xs:gMonthDay']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:gMonthDay(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:gYear'] | map:item[@type eq 'xs:gYear'] | array:item[@type eq 'xs:gYear']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:gYear(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:gYearMonth'] | map:item[@type eq 'xs:gYearMonth'] | array:item[@type eq 'xs:gYearMonth']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:gYearMonth(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:hexBinary'] | map:item[@type eq 'xs:hexBinary'] | array:item[@type eq 'xs:hexBinary']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:hexBinary(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:QName'] | map:item[@type eq 'xs:QName'] | array:item[@type eq 'xs:QName']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:QName(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:string'] | map:item[@type eq 'xs:string'] | array:item[@type eq 'xs:string']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:string(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:normalizedString'] | map:item[@type eq 'xs:normalizedString'] | array:item[@type eq 'xs:normalizedString']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:normalizedString(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:token'] | map:item[@type eq 'xs:token'] | array:item[@type eq 'xs:token']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:token(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:language'] | map:item[@type eq 'xs:language'] | array:item[@type eq 'xs:language']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:language(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:Name'] | map:item[@type eq 'xs:Name'] | array:item[@type eq 'xs:Name']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:Name(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:NCName'] | map:item[@type eq 'xs:NCName'] | array:item[@type eq 'xs:NCName']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:NCName(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:ENTITY'] | map:item[@type eq 'xs:ENTITY'] | array:item[@type eq 'xs:ENTITY']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:ENTITY(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:ID'] | map:item[@type eq 'xs:ID'] | array:item[@type eq 'xs:ID']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:ID(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:IDREF'] | map:item[@type eq 'xs:IDREF'] | array:item[@type eq 'xs:IDREF']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:IDREF(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:NMTOKEN'] | map:item[@type eq 'xs:NMTOKEN'] | array:item[@type eq 'xs:NMTOKEN']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:NMTOKEN(.)"/>
   </xsl:template>
   <xsl:template
      match="map:key[@type eq 'xs:time'] | map:item[@type eq 'xs:time'] | array:item[@type eq 'xs:time']"
      mode="tan:build-maps-and-arrays">
      <xsl:sequence select="xs:time(.)"/>
   </xsl:template>

   
   <xsl:function name="tan:map-to-array" as="array(*)?" visibility="public">
      <!-- Input: a map; a boolean -->
      <!-- Output: the map as an array, one member of the array per map entry, with the first item in the member
         constituting the key and its second items onward the values. If the boolean is true, then the keys will
         be sorted, otherwise the order of the array is implementation-dependent. -->
      <!--kw: maps, arrays -->
      <xsl:param name="map-to-convert" as="map(*)?"/>
      <xsl:param name="sort-keys" as="xs:boolean"/>
      <xsl:variable name="map-keys" as="xs:anyAtomicType*">
         <xsl:choose>
            <xsl:when test="$sort-keys">
               <xsl:for-each select="map:keys($map-to-convert)">
                  <xsl:sort select="string(.)"/>
                  <xsl:sequence select="."/>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="map:keys($map-to-convert)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:sequence select="
            array:join(for $i in $map-keys
            return
               [$i, $map-to-convert($i)])"/>
   </xsl:function>
   

   <xsl:function name="tan:map-entries" as="map(*)*" visibility="public">
      <!-- One-param version of the full one below -->
      <xsl:param name="source-map" as="map(*)*"/>
      <xsl:for-each select="$source-map">
         <xsl:variable name="this-map" as="map(*)" select="."/>
         <xsl:for-each select="map:keys(.)">
            <xsl:map-entry key="." select="$this-map(current())"/>
         </xsl:for-each>
      </xsl:for-each>
   </xsl:function>
   
   <xsl:function name="tan:map-entries" as="map(*)*" visibility="public">
      <!-- Input: a map -->
      <!-- Output: one singleton map per map entry. -->
      <!-- This function was written to support templates or functions that use predicates to restrict a
         particular map's entries to only select ones. -->
      <!--kw: maps -->
      <xsl:param name="source-map" as="map(*)*"/>
      <xsl:param name="keys-to-keep" as="xs:anyAtomicType*"/>

      <xsl:for-each select="$source-map">
         <!-- I must admit, it would be nice to have access to op:sameKey() as an accessible
            function, because it would be nice to replace the construction below with something
            like this instead:
         <xsl:for-each select="
               map:keys(.)[some $i in $keys-to-keep
                  satisfies op:sameKey($i, .)]"/> -->
         <xsl:for-each-group select="map:keys(.)" group-by="tan:item-type(.)">
            <xsl:variable name="this-item-type" as="xs:string" select="current-grouping-key()"/>
            <xsl:variable name="viable-keys" as="xs:anyAtomicType*"
               select="$keys-to-keep[tan:item-type(.) eq $this-item-type]"/>
            <xsl:for-each select="current-group()[. = $viable-keys]">
               <xsl:map-entry key="." select="$source-map(current())"/>
            </xsl:for-each>
         </xsl:for-each-group>
      </xsl:for-each>
   </xsl:function>
   
   
   
   
   <xsl:function name="tan:map-put" as="map(*)" visibility="public">
      <!-- 4-parameter version of the complete function below. -->
      <!-- Here the 2nd parameter is simply a map, all of whose map entries are intended 
         insertions. This allows the user of the function to make multiple insertions at once.
      -->
      <xsl:param name="map" as="map(*)"/>
      <xsl:param name="put-map" as="map(*)"/>
      <xsl:param name="at-depth" as="xs:integer"/>
      <xsl:param name="target-map-must-have-what-key" as="xs:anyAtomicType?"/>
      
      <xsl:variable name="put-map-keys" select="map:keys($put-map)"/>
      <xsl:iterate select="$put-map-keys">
         <xsl:param name="map-so-far" as="map(*)" select="$map"/>
         <xsl:on-completion>
            <xsl:sequence select="$map-so-far"/>
         </xsl:on-completion>
         <xsl:variable name="new-map"
            select="tan:map-put($map-so-far, ., map:get($put-map, .), $at-depth, $target-map-must-have-what-key)"
         />
         <xsl:next-iteration>
            <xsl:with-param name="map-so-far" select="$new-map"/>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:function>
   
   <xsl:function name="tan:map-put" as="map(*)" visibility="public">
      <!-- Input: a map; an atomic type representing a key for a new map entry; any items,
         representing the value for a new map entry; an integer, specifying the depth of 
         map to receive the entry (0 or less will apply to every map); a string, specifying
         a key that must be present in a map that must receive the entry.
      -->
      <!-- Output: the input map, but with a new map entry at each map of depth specified by the
         fourth parameter, provided that it has a key specified by the fifth. --> 
      <!-- If the fourth parameter is less than 0, then the entry will be placed throughout every
         map: the initial map itself and any enclosed map of any depth. -->
      <!-- If the fifth parameter is not empty, then the target map must have a map entry with 
         an identical key for it to qualify to take the new map entry; if the parameter is empty,
         this qualification is ignored. -->
      <!-- If a key exists already in a target map, the new entry replaces the current one, otherwise 
         it is added as a new map entry. -->
      <!-- This function parallels map:put(), but allows for deep placement of entries. This function
         was written to support a more DRY-friendly approach to creating maps for transform(), which 
         has submaps that might need to be altered and refactored, depending on various conditions. -->
      <!-- It is presently difficult to select particular deep maps for a target action. The last two
         parameters of this function provide a bit of control over where the action is applied. One 
         strategy that can be adopted, to use this function better, is to supply in each map a single
         map entry with a key corresponding to an id (perhaps via fn:generate-id()) with an empty value.
         That empty map entry then can serve as a hook equivalent to @xml:id in an element.
      -->
      <!--kw: maps -->
      <xsl:param name="map" as="map(*)"/>
      <xsl:param name="key" as="xs:anyAtomicType"/>
      <xsl:param name="value" as="item()*"/>
      <xsl:param name="at-depth" as="xs:integer"/>
      <xsl:param name="target-map-must-have-what-key" as="xs:anyAtomicType?"/>
      
      <xsl:variable name="key-type" as="xs:string" select="tan:item-type($key)"/>
      
      <xsl:apply-templates select="$map" mode="tan:map-put">
         <xsl:with-param name="key" tunnel="yes" select="$key"/>
         <xsl:with-param name="value" tunnel="yes" select="$value"/>
         <xsl:with-param name="at-depth" tunnel="yes" select="$at-depth"/>
         <xsl:with-param name="target-map-must-have-what-key" tunnel="yes"
            select="$target-map-must-have-what-key"/>
         <xsl:with-param name="current-depth" tunnel="yes" select="1"/>
      </xsl:apply-templates>
      
   </xsl:function>
   
   
   <xsl:mode name="tan:map-put" on-no-match="shallow-copy"/>
   
   <xsl:template match=".[. instance of map(*)]" mode="tan:map-put">
      <xsl:param name="key" tunnel="yes" as="xs:anyAtomicType"/>
      <xsl:param name="value" tunnel="yes" as="item()*"/>
      <xsl:param name="at-depth" tunnel="yes" as="xs:integer"/>
      <xsl:param name="target-map-must-have-what-key" tunnel="yes" as="xs:anyAtomicType?"/>
      <xsl:param name="current-depth" tunnel="yes" as="xs:integer"/>
      
      <xsl:variable name="context-map" as="map(*)" select="."/>
      <xsl:variable name="context-map-keys" as="xs:anyAtomicType*" select="map:keys(.)"/>
      
      <!-- In XPath, there is a construction called the predicate, marked by square brackets, which
         filters the results of a selection. We adopt the same nomenclature here for the key that should
         be present for a map to be eligible to receive the map entry. -->
      <xsl:variable name="predicate-key-type" as="xs:string?" select="tan:item-type($target-map-must-have-what-key)"/>
      <xsl:variable name="key-type" as="xs:string" select="tan:item-type($key)"/>
      
      <xsl:variable name="check-every-depth" as="xs:boolean" select="$at-depth lt 1"/>
      <xsl:variable name="depth-matches" as="xs:boolean" select="$check-every-depth or $current-depth eq $at-depth"/>
      <xsl:variable name="predicate-key-is-ok" as="xs:boolean" select="
         not(exists($target-map-must-have-what-key))
         or (some $i in $context-map-keys[tan:item-type(.) eq $predicate-key-type]
         satisfies $i eq $target-map-must-have-what-key)"/>
      
      <xsl:variable name="put-new-entry-here" as="xs:boolean" select="$depth-matches and $predicate-key-is-ok"/>
      <xsl:variable name="look-deeper" as="xs:boolean" select="$at-depth gt $current-depth or $check-every-depth"/>
      
      <xsl:choose>
         <xsl:when test="$put-new-entry-here and not($look-deeper)">
            <xsl:sequence select="map:put(., $key, $value)"/>
         </xsl:when>
         <xsl:when test="$put-new-entry-here">
            <!-- Insert a new entry and keep looking -->
            <xsl:map>
               <xsl:map-entry key="$key" select="$value"/>
               <xsl:for-each select="$context-map-keys[tan:item-type(.) ne $key-type or not(. eq $key)]">
                  <xsl:map-entry key=".">
                     <xsl:apply-templates select="$context-map(current())" mode="#current">
                        <xsl:with-param name="current-depth" tunnel="yes" select="$current-depth + 1"/>
                     </xsl:apply-templates>
                  </xsl:map-entry>
               </xsl:for-each>
            </xsl:map>
         </xsl:when>
         <xsl:when test="not($put-new-entry-here) and $look-deeper">
            <!-- Increment the depth and go on to the shallow-copy template. -->
            <xsl:next-match>
               <xsl:with-param name="current-depth" tunnel="yes" select="$current-depth + 1"/>
            </xsl:next-match>
         </xsl:when>
         <xsl:otherwise>
            <!-- Neither insert an entry nor look deeper, perhaps because this is the target depth, but
               the predicate key does not match. Keep the map as-is. -->
            <xsl:sequence select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   
   <xsl:function name="tan:map-contains" visibility="public" as="xs:boolean">
      <!-- Input: a map; a sequence of items -->
      <!-- Output: true if the map, or any map it contains, has a key identical to one of the items,
         otherwise false. -->
      <!-- This function parallels map:contains() but permits multiple inputs and deep searching -->
      <!--kw: maps -->
      <xsl:param name="map-of-interest" as="map(*)*"/>
      <xsl:param name="keys-of-interest" as="xs:anyAtomicType*"/>
      
      <xsl:sequence select="
            some $i in $keys-of-interest
               satisfies array:size(map:find($map-of-interest, $i)) gt 0"/>
      
   </xsl:function>
   
   
   <xsl:function name="tan:map-keys" visibility="public" as="item()*">
      <!-- Input: a map -->
      <!-- Output: all map keys, both at the top level and at any depth -->
      <!-- This function parallels map:keys() but permits recursion -->
      <!--kw: maps -->
      <xsl:param name="map-of-interest" as="map(*)*"/>
      <xsl:apply-templates select="$map-of-interest" mode="tan:map-keys"/>
   </xsl:function>
   
   
   <xsl:mode name="tan:map-keys" on-no-match="shallow-skip"/>
   
   <xsl:template match=".[. instance of map(*)]" mode="tan:map-keys">
      <xsl:variable name="these-keys" select="map:keys(.)"/>
      <xsl:sequence select="$these-keys"/>
      <xsl:apply-templates select="
            for $i in $these-keys
            return
               .($i)" mode="#current"/>
   </xsl:template>
   
   
   
   <xsl:function name="tan:map-remove" as="map(*)" visibility="public">
      <!-- Input: any map, a sequence of atomic items -->
      <!-- Output: the map, but without entries of the specified key, at any depth -->
      <!-- This function parallels map:remove(), but affects contained maps at any 
         depth, even those embedded within an array. -->
      <!--kw: maps -->
      <xsl:param name="map-of-interest" as="map(*)"/>
      <xsl:param name="keys" as="xs:anyAtomicType*"/>
      <xsl:apply-templates select="$map-of-interest" mode="tan:map-remove">
         <xsl:with-param name="keys" tunnel="yes" select="$keys"/>
      </xsl:apply-templates>
   </xsl:function>
   
   
   <xsl:mode name="tan:map-remove" on-no-match="deep-copy"/>
   
   <xsl:template match=".[. instance of map(*)]" mode="tan:map-remove">
      <xsl:param name="keys" tunnel="yes" as="xs:anyAtomicType*"/>
      <xsl:variable name="context-keys" as="xs:anyAtomicType*" select="map:keys(.)"/>
      <xsl:variable name="context-map" as="map(*)" select="."/>
      <xsl:map>
         <xsl:for-each-group select="$context-keys" group-by="tan:item-type(.)">
            <xsl:variable name="this-type" as="xs:string" select="current-grouping-key()"/>
            <xsl:variable name="keys-of-interest" as="xs:anyAtomicType*" select="$keys[tan:item-type(.) eq $this-type]"/>
            <xsl:for-each select="current-group()[not(. = $keys-of-interest)]">
               <xsl:map-entry key=".">
                  <xsl:apply-templates select="$context-map(current())" mode="#current"/>
               </xsl:map-entry>
            </xsl:for-each>
         </xsl:for-each-group>
      </xsl:map>
   </xsl:template>
   
   
   <xsl:function name="tan:map-invert" as="map(*)" visibility="public">
      <!-- Input: a map -->
      <!-- Output: a map, where the keys are all those values of the input map that are atomic items and each item's
         value are the keys in the original map that point to it. -->
      <!-- This function was written to provide a kind of reverse lookup on any map. Any value that is not an atomic
         item will be discarded. -->
      <!--kw: maps -->
      <xsl:param name="map-to-invert" as="map(*)"/>
      
      <xsl:variable name="input-map-keys" as="xs:anyAtomicType*" select="map:keys($map-to-invert)"/>
      
      <xsl:map>
         <xsl:for-each-group select="$input-map-keys"
            group-by="$map-to-invert(.)[. instance of xs:anyAtomicType]">
            <xsl:map-entry key="current-grouping-key()" select="sort(current-group())"/>
         </xsl:for-each-group>
      </xsl:map>
      
   </xsl:function>
   


</xsl:stylesheet>
