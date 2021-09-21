<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tan="tag:textalign.net,2015:ns" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Welcome to TAN-A-lm Builder, the TAN application that creates a TAN-A-lm file for a class 1 file -->
    <!-- Well-curated lexico-morphological data is highly valuable for a variety of applications such
      as quotation detection, stylometric analysis, and machine translation. This application will
      process any TAN-T or TAN-TEI file through existing TAN-A-lm language libraries, and online search
      services, looking for the best lexico-morphological profiles for the file's tokens. -->
    <!-- Version 2021-09-06-->
    
    <!-- This master stylesheet is the public interface for the application. The parameters you will most
      likely want to change are listed and documented below, to help you customize the application to suit
      your needs. If you are relatively new to XSLT, or TAN applications, see Using TAN Applications and
      Utilities in the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and edit and
      run it directly. Or create and configure a transformation scenario in Oxygen, defining the relevant
      parameters as you like. If you are comfortable with XSLT, try creating your own stylesheet, then
      import this one, and customize the process. To access the code base, follow the link in the
      <xsl:include> at the bottom of this file. -->
    
    
    <!-- DESCRIPTION -->
    
    <!-- Primary input: a class 1 file -->
    <!-- Secondary input: a TAN-A-lm template; language catalogs; perhaps language search services -->
    <!-- Primary output: a new TAN-A-lm file freshly populated with lexicomorphological data, sorted with
        unmatched tokens at the top, followed by ambiguous ones, followed by non-ambiguous ones -->
    <!-- Secondary output: none -->
    
    <!-- This tool is ideally used incrementally, as part of an editing strategy. The following is one
        method that has worked:
        - run TAN-A-lm Builder on a class 1 file, making sure context is inserted with $insert-tok-context
        - open the output and review the top entries, which will be tokens that could not be identified.
            Every one of these will be either a typo or a token that should be learned. At this stage,
            focus only on typos, correcting the class 1 source. If you find a typo, you can frequently use
            the tok context to find the text in the source class 1 file. F3 lets you quickly find a match.
            TAN-A-lm Builder can be a critical asset in proofreading your text!
        - repeat the previous two steps until typos are no longer apparent; at this point the topmost
            of the three tiers of tokens will be new entries
        
    -->
    
    <!-- Optimization strategies adopted: 
        * Minimize the number of times files in the language catalog must be consulted and resolved 
        * A hit on @val in a local TAN-A-lm file precludes any follow-up searches based @rgx or 
        online search services -->

    <!-- Nota bene:  
        * There must be access to a language catalog, i.e., a collection of TAN-A-lm files that are 
        language specific.  
        * The TAN-A-lm is relied upon as dictating the settings for the file, e.g., tokenization pattern,
        TAN-mor morphology, etc. 
        * We assume that a search for lexico-morphological data will entail a lot of different
        TAN-A-lm files with a number of conventions. Codes found in language catalogs must be converted to
        TAN-standardized feature names, and then reconverted into the codeset of choice, dictated by the
        <morphology> in the template TAN-A-lm file. -->

    <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED -->
    <!-- * What if the @xml:lang of the input doesn't match TAN-mor or language catalog files? 
        * What if a morphology has @which? Will it still work? 
        * Ensure the responsible repopulation of the metadata of the template 
        * Support false value for $retain-morphological-codes-as-is
    -->
    
    
    
    <!-- PARAMETERS -->
    
    <!-- Any parameter below whose name begins "tan:" is a global parameter, and corresponds to a
      parameter in the parameters subdirectory. It is repeated here, because one commonly wishes to 
      make special exceptions from the default, for this particular application. -->
    
    <!-- THE TAN-A-LM TEMPLATE -->
    
    <!-- Where is the TAN-A-lm file that should be used as a template for the output? The target uri
        must be resolved. By default, a search is made in the input for the first annotation location. -->
    <xsl:param name="template-tan-a-lm-uri-resolved" as="xs:string?"
        select="base-uri($tan:annotations-1st-da[tan:TAN-A-lm][1])"/>
    
    <!-- LEXICOMORPHOLOGICAL DATA SOURCES: LANGUAGE CATALOGS AND SEARCH SERVICES -->
    
    <!-- If there is not an exact match on a token in the local language catalog, should a search be 
        performed again removing accents (if present)? -->
    <xsl:param name="use-string-base-as-backup" as="xs:boolean" select="true()"/>
    
    <!-- Do you want to search for lexicomorphological data through a supported internet-based service?
        At present, only Morpheus's service, for Greek and Latin, is supported. -->
    <xsl:param name="use-search-services" as="xs:boolean" select="true()"/>
    
    <!-- Do you want to use a search service only if local lexico-morphological data fails to be 
        found? If false, then online searches will be made on every word form for every available search
        service. -->
    <xsl:param name="use-search-services-only-as-backup" as="xs:boolean" select="false()"/>
    
    <!-- Do you want to assume that any morphological codes retrieved from the local language catalog are to be
      retained as-is, without checking their underlying meaning? If true, then performance should be
      relatively speedy. If there are problems, they can be resolved when editing the output, in light of
      validation reports. If false, then the process may be very slow (perhaps twenty times longer),
      because every morphological code will need to be converted to a series of IRI values, which will
      then need to be reconverted into the template TAN-A-lm file's declared system. -->
    <xsl:param name="retain-morphological-codes-as-is" as="xs:boolean" select="true()"/>
    <!-- As of April 2021, false() is not supported for the parameter above. -->
    
    <!-- OUTPUT -->
    
    <!-- Do you wish an output <tok> pointing to a single token to be accompanied by a comment giving
        the context of the word? Any integer 1 or higher turns this feature on, and supplies that many
        words on either side of the target token. -->
    <xsl:param name="insert-tok-context" as="xs:integer?" select="3"/>
    
    
    <!-- THE APPLICATION -->
    
    <!-- The main engine for the application is in this file, and in other files it links to. Feel
        free to explore, but make alterations only if you know what you are doing. If you make
        changes, make a copy of the original file first.-->
    <xsl:include href="incl/TAN-A-lm%20Builder%20core.xsl"/>
</xsl:stylesheet>
