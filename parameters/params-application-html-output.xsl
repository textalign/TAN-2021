<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="#all" version="3.0">

   <!-- HTML output -->
   
   
   <!-- In many TAN applications, a variety of output needs to be converted to HTML.
      There is a standard function, tan:convert-to-html(), which does a straightforward
      replacement of any XML tree. Every attribute (except temporary attributes, signaled 
      by an initial _) is converted to its own HTML <div class="a-[NAME]">, and every 
      element to its own <div class="e-[NAME]">. If there is a change in the namespace, 
      the new <div>'s @class attribute might also have a value of ns-[PREFIX] to signal 
      the namespace. 
         It frequently happens, though, that some common changes need to be applied before
      putting anything through tan:convert-to-html(). For example, some attributes or 
      elements can be removed en masse, or some elements might need to be grouped and 
      labeled. Stripping the XML to be converted eliminates clutter and allows CSS files 
      to be simpler.
         Many of the parameters below serve a private function called
      tan:prepare-to-convert-to-html(). Because TAN applications differ in important ways 
      with how they treat output that needs to be converted, many of the parameters below will
      feature in the master stylesheet for a given application. -->
   
   <!-- For the preparation phase -->
   
   <!-- In general, the order of parameters below reflect the order in which they take effect, 
      which means that a change made by one parameter may change the effect of a subsequent one. -->
   
   <!-- When converting an element to an HTML <div>, what attributes should have their values
      added to the attribute @class? This should be a regular expression matching an attribute name. -->
   <xsl:param name="tan:html-out.attributes-whose-values-should-be-added-to-attr-class-regex" as="xs:string*"
      select="'^(type)$'"/>
   
   <!-- Should any non-HTML element with an @href be wrapped by an HTML <a href="">? -->
   <xsl:param name="tan:html-out.wrap-elements-with-attr-href-in-html-a" as="xs:boolean"
      select="true()"/>
   
   <!-- What attributes should be removed from a non-HTML tree before 
        conversion to HTML? This should be a regular expression matching an attribute name. -->
   <xsl:param name="tan:html-out.remove-what-attributes-regex" as="xs:string?"/>
   
   <!-- What elements should be removed from a non-HTML tree before 
        conversion to HTML? This should be a regular expression matching an element name. -->
   <xsl:param name="tan:html-out.remove-what-elements-regex" as="xs:string?"/>
   
   <!-- In many cases HTML/CSS does not do a good job of styling adjacent sibling elements without some kind
   of preliminary grouping. Sometimes those groups need labels. -->
   
   <!-- What elements should be labeled? Those elements will be prepended with a <div class="label">[NAME OF 
      ELEMENT]</div> The value must be a regular expression matching an element name. -->
   <xsl:param name="tan:html-out.elements-that-should-be-labeled-regex" as="xs:string?"
   select="'^(notices)$'"/>
   
   <!-- What elements should have their children elements grouped and labeled? Children will be grouped adjacently
      by shared name. The label will consist of the common element name of the group, changed to a plural if
      the group consists of more than one member. This process affects all children elements. Any children that
      are not elements will be placed at the beginning. The value must be a regular expression matching an
      element name. -->
   <xsl:param name="tan:html-out.elements-whose-children-should-be-grouped-and-labeled-regex"
      as="xs:string?" select="'^(teiHeader|head|vocabulary-key|adjustments|notices)$'"/>
   
   <!-- Should any children elements be exempt from the grouping process? If so, supply the appropriate regular
      expression. -->
   <xsl:param name="tan:html-out.children-that-should-not-be-grouped-and-labeled-regex"
      as="xs:string?" select="'^(src)$'"/>
   
   <!-- What attribute should be converted to an @id, if none is already present? If an @id
      is present, then the attribute in question will simply be dropped. -->
   <xsl:param name="tan:html-out.attribute-to-convert-to-id" as="xs:string?" select="'q'"/>
   
   
   
   
   <!-- Once an XML file is prepared, it can be converted to HTML (see description above). -->
   
   <!-- What attributes should be retained, and not converted to elements? The value must be a regular
      expression matching attribute names. Note, @lang (perhaps converted from @xml:lang), and @class 
      will always be retained and not converted to elements. See also next parameter. -->
   <xsl:param name="tan:html-out.attributes-to-retain-regex" as="xs:string?" select="'^_'"/>
   
   <!-- Should attributes with a name matching a global attribute in HTML be retained, and not
      converted to elements? If true, then HTML attributes can be placed in non-HTML elements
      at any point before the tree gets converted to HTML. Note, 
   -->
   <xsl:param name="tan:html-out.keep-attributes-named-after-global-html-attributes" as="xs:boolean"
      select="true()"/>
   

</xsl:stylesheet>
