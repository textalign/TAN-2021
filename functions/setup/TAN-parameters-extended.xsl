<xsl:stylesheet exclude-result-prefixes="#all" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   version="3.0">

   <!-- Core extended parameters for the TAN function library. These parameters may be overwritten,
      but normally they should stay as-is, unless you are doing development. For parameters that most 
      users will likely wish to change, see the parameters subdirectory at the root of the TAN project.
   -->

   <!-- APPLICATION STYLESHEET PARAMETERS -->

   <!-- TAN applications and utilities have a variety of components that are standard, to make sure that they
      operate consistently. -->

   <!-- If the output is a TAN file, the stylesheet should be credited/blamed. That is done primarily through an IRI assigned to the stylesheet -->
   <xsl:param name="tan:stylesheet-iri" as="xs:string" required="no"/>

   <!-- What is the name of the stylesheet? This value, along with $stylesheet-iri, will be used to populate the IRI + name pattern when the stylesheet is credited -->
   <xsl:param name="tan:stylesheet-name" as="xs:string" required="no"/>

   <!-- Briefly, what does the stylesheet do? This should be  -->
   <xsl:param name="tan:stylesheet-activity" as="xs:string" required="no"/>

   <!-- If you wish, you may describe the stylesheet, what it does, and the rationale for using it. -->
   <xsl:param name="tan:stylesheet-description" as="xs:string" required="no"/>
   
   <!-- What is the expected primary input for the stylesheet? -->
   <xsl:param name="tan:stylesheet-primary-input-desc" as="xs:string" required="no"/>

   <!-- What is the expected secondary input for the stylesheet? -->
   <xsl:param name="tan:stylesheet-secondary-input-desc" as="xs:string" required="no"/>

   <!-- What is the expected primary input for the stylesheet? -->
   <xsl:param name="tan:stylesheet-primary-output-desc" as="xs:string" required="no"/>

   <!-- What is the expected secondary input for the stylesheet? -->
   <xsl:param name="tan:stylesheet-secondary-output-desc" as="xs:string" required="no"/>

   <!-- Where can one find examples of the stylesheet's output? This parameter takes multiple elements (name unimportant), each one with a <location> and <description>. The string value of the former should be a resolved URI; the string value of the latter, a description. -->
   <xsl:param name="tan:stylesheet-output-examples" as="element()*" required="no"/>

   <!-- Where is the master stylesheet for the application? Normally this parameter is defined via select="static-base-uri()", within the master application. -->
   <xsl:param name="tan:stylesheet-url" as="xs:string" required="no"/>

   <!-- What does the application do? Phrase it as a change message that might be inserted into the output or returned as a message. How the message is handled is application-dependent -->
   <xsl:param name="tan:stylesheet-change-message" as="xs:string*" required="no"/>

   <!-- Is the application one of the core TAN applications? -->
   <xsl:param name="tan:stylesheet-is-core-tan-application" as="xs:boolean?" select="false()"
      required="no"/>

   <!-- What is the change history of the stylesheet? -->
   <xsl:param name="tan:stylesheet-change-log" as="element(tan:change)*" required="no"/>

   <!-- What remains to be done to the stylesheet? -->
   <xsl:param name="tan:stylesheet-to-do-list" as="element(tan:to-do)?" required="no"/>





</xsl:stylesheet>
