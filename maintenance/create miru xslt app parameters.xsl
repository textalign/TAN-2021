<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- Parameters for Create MIRU XSLT App -->
    <!-- author: Joel Kalvesmaki -->
    <!-- updated: 2020-04-11 -->
    
    <!-- To be used in conjunction with the file create%20miru%20xslt%20app.xsl -->
    <!-- If you have an XSLT file that you want to turn into an app, and you want to overwrite
    the default parameters, you can copy this file to your project and include or import it 
    in your XSLT. Change the parameters as you like. Then when you run the app, your
    parameter values will be used instead. 
            If you do not wish to overwrite a default value, you should probably comment 
    out the <xsl:param> instead of delete it, in case you change your mind later. You 
    should not leave an empty <xsl:param>, unless you want to make sure that the parameter
    is given no value whatsoever. -->

    <!-- The values below should be simple strings as text nodes and not XPath expressions 
        via @select, unless you can run this through Saxon PE or EE (which require licenses). 
        If you use @select, all variables and functions will be evaluated according to the 
        context of Create MIRU XSLT App (CMXA), not your MIRU xslt file. Because CMXA draws 
        from the TAN library, TAN global variables and functions may be used. 
    -->
    
    <!-- + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + -->
    
    <!-- Parameters specific to an application type -->
    
    <!-- Where is the template batch file that should be used? Normally it is in the same path as this stylesheet, i.e., create app for xsl.bat -->
    <xsl:param name="batch-template-path-relative-to-this-stylesheet" as="xs:string"
        >create%20miru%20xslt%20app.bat</xsl:param>
    
    <!-- Where is the template shell file that should be used? Normally it is in the same path as this stylesheet, i.e., create app for xsl.bat -->
    <xsl:param name="shell-template-path-relative-to-this-stylesheet" as="xs:string"
        >create%20miru%20xslt%20app.sh</xsl:param>
    
    <!-- Where should the batch file be saved relative to the input XSLT? If the value is empty, the batch file will have the same name as the input XSLT, but with a .bat extension -->
    <xsl:param name="target-batch-uri-relative-to-input-xslt" as="xs:string?"/>
    
    <!-- Where should the shell file be saved relative to the input XSLT? If the value is empty, the batch file will have the same name as the input XSLT, but with a .sh extension -->
    <xsl:param name="target-shell-uri-relative-to-input-xslt" as="xs:string?"/>
    
    
    <!-- Parameters not specific to an application type -->
    
    <!-- Where is the Saxon XSLT processor relative to the master stylesheet? If left blank, the target will point to the Saxon processor used by Create MIRU XSLT App -->
    <xsl:param name="processor-path-relative-to-this-stylesheet" as="xs:string"
        >../../processors/saxon9he.jar</xsl:param>

    <!-- What are the standard Saxon options you want to include? See https://saxonica.com/documentation/index.html#!using-xsl/commandline -->
    <xsl:param name="default-saxon-options" as="xs:string?"/>
    
    <!-- What should be the filename of the target app's primary output (if any)? Note, this value populates the -o parameter, and does not dictate whether there will be any primary output, or the handling of secondary output via xsl:result-document -->
    <xsl:param name="primary-output-target-uri" as="xs:string?">%_xslPath%.output.xml</xsl:param>
    
    <!-- What is the name of the key parameter in the stylesheet? It must anticipate a sequence of strings representing resolved uris -->
    <xsl:param name="key-parameter-name" as="xs:string">resolved-uris-to-lists-of-main-input-resolved-uris</xsl:param>
    
    <!-- What other parameters should be set in the stylesheet? It must follow the syntax laid out in [params] here: https://saxonica.com/documentation/index.html#!using-xsl/commandline  -->
    <xsl:param name="other-parameters" as="xs:string?"/>
    
    <!-- Do you want to turn diagnostics on? This parameter does not affect the content of the output file(s). -->
    <xsl:param name="app-diagnostics-on" as="xs:string?">1</xsl:param>
    
    <!-- What additional documentation if any do you want to add to the app? If you can run this through Saxon PE or EE, try select="root()/*/*[1]/preceding-sibling::comment()" to insert all initial comments -->
    <xsl:param name="app-documentation" as="xs:string?"/>
    
</xsl:stylesheet>
