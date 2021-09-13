<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <xsl:param name="tan:validation-mode-on" as="xs:boolean" select="true()" static="yes"/>    
    <xsl:param name="tan:include-diagnostics-components" as="xs:boolean" select="true()" static="yes"/>    
    <xsl:include href="../TAN-function-library.xsl"/>

    <!-- This file checks for problems in TAN-errors.xml -->

    <sch:title>Tests on the TAN error registry</sch:title>
    <sch:ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
    <sch:ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>
    <sch:phase id="missing-and-strays">
        <sch:active pattern="mark-missing"/>
        <sch:active pattern="mark-strays"/>
    </sch:phase>
    <sch:phase id="terse">
        <sch:active pattern="checked-in-terse-template"/>
    </sch:phase>
    <sch:phase id="normal">
        <sch:active pattern="checked-in-normal-template"/>
    </sch:phase>
    <sch:phase id="verbose">
        <sch:active pattern="checked-in-verbose-template"/>
    </sch:phase>
    <sch:phase id="core">
        <sch:active pattern="checked-in-core-template"/>
    </sch:phase>
    <sch:phase id="class-1">
        <sch:active pattern="checked-in-class-1-template"/>
    </sch:phase>
    <sch:phase id="class-2">
        <sch:active pattern="checked-in-class-2-template"/>
    </sch:phase>
    <sch:phase id="full-info">
        <sch:active pattern="mark-full-info"/>
        <sch:active pattern="mark-strays"/>
    </sch:phase>
    <!--<sch:phase id="xslt">
        <sch:active pattern="mark-unsupported-error-calls"/>
    </sch:phase>-->
    
    <xsl:variable name="error-tests" as="document-node()*"
        select="collection('../../tests/errors/?select=error-test*.xml')"/>
    <xsl:variable name="error-markers" select="$error-tests//comment()[matches(., '\w\w\w\d\d')]"/>
    
    <sch:pattern id="checked-in-terse-template" is-a="identify-phases">
        <sch:param name="mode-name" value="'terse'"/>
    </sch:pattern>
    <sch:pattern id="checked-in-normal-template" is-a="identify-phases">
        <sch:param name="mode-name" value="'normal'"/>
    </sch:pattern>
    <sch:pattern id="checked-in-verbose-template" is-a="identify-phases">
        <sch:param name="mode-name" value="'verbose'"/>
    </sch:pattern>
    <sch:pattern id="checked-in-core-template" is-a="identify-phases">
        <sch:param name="mode-name" value="'core'"/>
    </sch:pattern>
    <sch:pattern id="checked-in-class-1-template" is-a="identify-phases">
        <sch:param name="mode-name" value="'class-1'"/>
    </sch:pattern>
    <sch:pattern id="checked-in-class-2-template" is-a="identify-phases">
        <sch:param name="mode-name" value="'class-2'"/>
    </sch:pattern>
    <sch:pattern id="mark-full-info" is-a="identify-phases">
        <sch:param name="mode-name" value="''"/>
    </sch:pattern>
    <sch:pattern id="mark-missing">
        <sch:rule context="tan:error | tan:warning | tan:fatal">
            <sch:let name="these-phases" value="tokenize(@phase, ' ')"/>
            <sch:let name="error-id" value="@xml:id"/>
            <sch:let name="is-advanced" value="parent::tan:group/@type = 'advanced'"/>
            <sch:let name="errors-checked-where" value="tan:errors-checked-where($error-id)"/>
            <sch:let name="errors-tested-where" value="$error-markers[matches(., $error-id)]"/>
            <sch:let name="errors-that-dont-need-testing" value="('wrn04')"/>
            <sch:report
                test="not($is-advanced) and not(exists($errors-checked-where))"
                >Error <sch:value-of select="$error-id"/> has not yet been implemented.</sch:report>
            <sch:assert
                test="$is-advanced or exists($errors-tested-where) or ($error-id = $errors-that-dont-need-testing)"
                >Error <sch:value-of select="$error-id"/> should be set up in a test
                file.</sch:assert>
        </sch:rule>
    </sch:pattern>
    <sch:pattern id="mark-strays">
        <sch:let name="supported-error-codes" value="$tan:errors//@xml:id"/>
        <sch:rule context="/*">
            <sch:let name="error-calls"
                value="$tan:all-functions//xsl:copy-of/@select[matches(., 'tan:error\(.[a-z]+\d+')]"/>
            <sch:let name="error-codes-invocations"
                value="
                    for $i in $error-calls
                    return
                        replace($i, '.*tan:error\(.(\w+).+', '$1')"/>
            <sch:let name="error-codes-unsupported"
                value="$error-codes-invocations[not(. = $supported-error-codes)]"/>
            <sch:report test="exists($error-codes-unsupported)">Unsupported error codes:
                    <sch:value-of select="$error-codes-unsupported"/> (<sch:value-of select="for $i in $error-calls return
                        $i/(ancestor::xsl:template, ancestor::xsl:function, ancestor::xsl:variable)/(@name, @mode)"/>)
            </sch:report>
        </sch:rule>
    </sch:pattern>
    <sch:pattern abstract="true" id="identify-phases">
        <sch:rule context="tan:error | tan:warning | tan:fatal">
            <!--<sch:let name="these-phases" value="tokenize(@phase, ' ')"/>-->
            <sch:let name="error-id" value="@xml:id"/>
            <sch:let name="errors-checked-where" value="tan:errors-checked-where($error-id)"/>
            <sch:let name="invoking-template-function-or-variable"
                value="
                    for $i in $errors-checked-where
                    return
                        $i/ancestor::*[last() - 1]"/>
            <sch:let name="invoking-template"
                value="$invoking-template-function-or-variable/self::xsl:template"/>
            <sch:let name="invoking-function"
                value="$invoking-template-function-or-variable/self::xsl:function"/>
            <sch:let name="invoking-variable"
                value="$invoking-template-function-or-variable/self::xsl:variable"/>
            <sch:let name="invoking-template-of-interest"
                value="$invoking-template[matches(@mode, $mode-name)]"/>
            <sch:let name="invoking-template-not-of-interest"
                value="$invoking-template[not(matches(@mode, $mode-name))]"/>
            <!--<sch:report test="true()"><sch:value-of select="for $i in $invoking-template-function-or-variable return name($i)"/></sch:report>-->
            <sch:report
                test="exists($invoking-template-of-interest) and string-length($mode-name) gt 0"
                role="info">Used in templates whose mode name matches '<sch:value-of
                    select="$mode-name"/>' <sch:value-of
                    select="
                        if (exists($invoking-function) or exists($invoking-variable) or exists($invoking-template-not-of-interest)) then
                            concat('(also ', string-join(distinct-values(for $i in ($invoking-function, $invoking-variable, $invoking-template-not-of-interest)
                            return
                                tokenize($i/(@name, @mode)[1], ' ')), ', '), ')')
                        else
                            ()"
                />
            </sch:report>
            <sch:report test="$mode-name = ''" role="info">Used in <sch:value-of
                    select="
                        string-join(distinct-values(for $i in $invoking-template-function-or-variable
                        return
                            tokenize($i/(@name, @mode)[1], ' ')), ', ')"
                /></sch:report>
        </sch:rule>
    </sch:pattern>
</sch:schema>
