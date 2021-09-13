<xsl:stylesheet exclude-result-prefixes="#all"  
   xmlns="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:saxon="http://saxon.sf.net/" version="3.0">

   <!-- TAN Function Library, extended variables. -->
   
   
   <xsl:variable name="tan:error-key" as="map(*)">
      <!-- This error key pertains NOT to validation errors when evaluating TAN files' structures, but to the
      behavior of TAN functions, mainly when input is not what is expected. -->
      <xsl:map>
         <xsl:sequence select="$tan:numeric-conversion-error-key"/>
         <xsl:sequence select="$tan:binary-error-key"/>
         <xsl:sequence select="$tan:hash-error-key"/>
         <xsl:sequence select="$tan:octet-error-key"/>
      </xsl:map>
   </xsl:variable>
   
   <xsl:variable name="tan:doc-history" select="tan:get-doc-history(/)"/>
   <xsl:variable name="tan:doc-filename" select="tan:cfne(/)"/>
   <xsl:param name="tan:saxon-extension-functions-available" static="yes" as="xs:boolean" select="function-available('saxon:evaluate', 3)"/>
   
   <!-- For some applications, expansion is overkill, but resolution is not quite enough. The
   following variable returns a space-normalized version of the resolved file. -->
   <xsl:variable name="tan:self-resolved-plus" as="document-node()?"
      select="tan:normalize-tree-space($tan:self-resolved, true())"/>
   
   <xsl:variable name="tan:self-expanded-vocabulary" as="element()*"
      select="tan:vocabulary((), (), ($tan:self-expanded/(*/tan:head | (tan:TAN-A | tan:TAN-voc)/tan:body)))"/>
   
   <!-- annotations (class-1 files pointing to corresponding class-2 files) -->
   <xsl:variable name="tan:annotations-1st-da" as="document-node()*"
      select="tan:get-1st-doc($tan:head/tan:annotation)"/>
   <xsl:variable name="tan:annotations-resolved" as="document-node()*"
      select="tan:resolve-doc($tan:annotations-1st-da, false(), tan:attr('relationship', 'annotation'))"/>
   
   <!-- see-also, context -->
   <xsl:variable name="tan:see-alsos-1st-da" as="document-node()*"
      select="tan:get-1st-doc($tan:head/tan:see-also)"/>
   <xsl:variable name="tan:see-alsos-resolved" as="document-node()*"
      select="tan:resolve-doc($tan:see-alsos-1st-da, false(), tan:attr('relationship', 'see-also'))"/>
   
   <!-- predecessors -->
   <xsl:variable name="tan:predecessors-1st-da" as="document-node()*"
      select="tan:get-1st-doc($tan:head/tan:predecessor)"/>
   <xsl:variable name="tan:predecessors-resolved" as="document-node()*" select="tan:resolve-doc($tan:predecessors-1st-da, false(), tan:attr('relationship', 'predecessor'))"/>
   
   <!-- successors -->
   <xsl:variable name="tan:successors-1st-da" as="document-node()*"
      select="tan:get-1st-doc($tan:head/tan:successor)"/>
   <xsl:variable name="tan:successors-resolved" as="document-node()*"
      select="tan:resolve-doc($tan:successors-1st-da, false(), tan:attr('relationship', 'successor'))"
   />
   
   <!-- morphologies -->
   <xsl:variable name="tan:morphologies-expanded"
      select="tan:expand-doc($tan:morphologies-resolved, 'terse', false())" as="document-node()*"/>
   
   
   <xsl:variable name="tan:most-common-indentations" as="xs:string*">
      <xsl:for-each-group select="//text()[not(matches(., '\S'))][following-sibling::*]"
         group-by="count(ancestor::*)">
         <xsl:sort select="current-grouping-key()"/>
         <xsl:value-of select="tan:most-common-item(current-group())"/>
      </xsl:for-each-group>
   </xsl:variable>
   
   <!-- An XPath pattern built into a text node or an attribute value looks like this: {PATTERN} -->
   <xsl:variable name="tan:xpath-regex" as="xs:string">\{[^\}]+?\}</xsl:variable>
   
   <xsl:variable name="tan:namespaces-and-prefixes" as="element()">
      <namespaces>
         <ns prefix="" uri=""/>
         <ns prefix="cp"
            uri="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"/>
         <ns prefix="dc" uri="http://purl.org/dc/elements/1.1/"/>
         <ns prefix="dcmitype" uri="http://purl.org/dc/dcmitype/"/>
         <ns prefix="dcterms" uri="http://purl.org/dc/terms/"/>
         <ns prefix="html" uri="http://www.w3.org/1999/xhtml"/>
         <ns prefix="m" uri="http://schemas.openxmlformats.org/officeDocument/2006/math"/>
         <ns prefix="map" uri="http://www.w3.org/2005/xpath-functions/map"/>
         <ns prefix="mc" uri="http://schemas.openxmlformats.org/markup-compatibility/2006"/>
         <ns prefix="mo" uri="http://schemas.microsoft.com/office/mac/office/2008/main"/>
         <ns prefix="mods" uri="http://www.loc.gov/mods/v3"/>
         <ns prefix="mv" uri="urn:schemas-microsoft-com:mac:vml"/>
         <ns prefix="o" uri="urn:schemas-microsoft-com:office:office"/>
         <ns prefix="r" uri="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
         <ns prefix="rel" uri="http://schemas.openxmlformats.org/package/2006/relationships"/>
         <ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
         <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
         <ns prefix="v" uri="urn:schemas-microsoft-com:vml"/>
         <ns prefix="w" uri="http://schemas.openxmlformats.org/wordprocessingml/2006/main"/>
         <ns prefix="w10" uri="urn:schemas-microsoft-com:office:word"/>
         <ns prefix="w14" uri="http://schemas.microsoft.com/office/word/2010/wordml"/>
         <ns prefix="w15" uri="http://schemas.microsoft.com/office/word/2012/wordml"/>
         <ns prefix="wne" uri="http://schemas.microsoft.com/office/word/2006/wordml"/>
         <ns prefix="wp"
            uri="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"/>
         <ns prefix="wp14" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"/>
         <ns prefix="wpc" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"/>
         <ns prefix="wpg" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"/>
         <ns prefix="wpi" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"/>
         <ns prefix="wps" uri="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"/>
         <ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>
         <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance"/>
         <ns prefix="xsl" uri="http://www.w3.org/1999/XSL/Transform"/>
         <ns prefix="zs" uri="http://www.loc.gov/zing/srw/"/>
      </namespaces>
   </xsl:variable>
   
   <xsl:variable name="tan:local-TAN-collection" as="document-node()*"
      select="collection(resolve-uri('catalog.tan.xml' || $tan:doc-uri) || '?on-error=warning')"/>
   <xsl:variable name="tan:local-TAN-voc-collection" select="$tan:local-TAN-collection[name(*) = 'TAN-voc']"/>
   
   <xsl:variable name="tan:applications-uri-collection"
      select="uri-collection('../applications/catalog.xml?on-error=ignore')"/>
   <xsl:variable name="tan:applications-collection" as="document-node()*">
      <xsl:for-each select="$tan:applications-uri-collection">
         <xsl:choose>
            <xsl:when test="doc-available(.)">
               <xsl:sequence select="doc(.)"/>
            </xsl:when>
         </xsl:choose>
      </xsl:for-each>
   </xsl:variable>
   
   <xsl:variable name="tan:today-iso" as="xs:string" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
   <xsl:variable name="tan:today-MDY" as="xs:string" select="format-date(current-date(), '[MNn] [D], [Y0001]')"/>
   
   <xsl:variable name="tan:url-regex" as="xs:string">\S+\.\w+</xsl:variable>
   
   <xsl:variable name="tan:TAN-feature-vocabulary"
      select="$tan:TAN-vocabularies[tan:TAN-voc/@id = 'tag:textalign.net,2015:tan-voc:features']"
      as="document-node()*"/>
   
   <xsl:variable name="tan:iso-639-3" select="doc('../language/iso-639-3.xml')" as="document-node()?"/>
   
   


</xsl:stylesheet>
