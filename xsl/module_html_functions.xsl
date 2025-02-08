<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://hcmc.uvic.ca/ns"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Dec 15, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This module contains functions for processing TEI into 
            output HTML. </xd:p>
        </xd:desc>
    </xd:doc>

    <xd:doc>
        <xd:desc>This function just grabs the year from a state element, whichever attribute
            it's stored in.</xd:desc>
        <xd:param name="state" as="element(tei:state)">One state element.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getYear" as="xs:string">
        <xsl:param name="state" as="element(tei:state)"/>
        <xsl:sequence select="if ($state/@notBefore) then xs:string($state/@notBefore) else 
            if ($state/@notAfter) then xs:string($state/@notAfter) else
            if ($state/@when) then xs:string($state/@when) else ''"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>This function is given an org, and returns a sequence of years 
        as strings constituting the complete range of years from the earliest in the
        record to the latest.</xd:desc>
        <xd:param name="org" as="element(tei:org)">The org element from which we extract
        the years.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:getYearsFromOrg" as="xs:string*">
        <xsl:param name="org" as="element(tei:org)"/>
        <xsl:variable name="years" as="xs:string*" select="distinct-values(($org/descendant::tei:state/@*[local-name() = ('when', 'notBefore', 'notAfter', 'from', 'to')]/xs:string(.)))"/>
        <xsl:choose>
            <xsl:when test="count($years) gt 0">
                <xsl:variable name="intYears" as="xs:integer+" select="for $y in $years return xs:integer($y)"/>
                <xsl:sequence select="for $intY in (min($intYears) to max($intYears)) return xs:string($intY)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>The date suffix values are used for a peculiar mixture of three 
            different purposes, and are consequently likely to be difficult to 
            render.</xd:desc>
        <xd:param name="dateSuffix" as="xs:string?">The one-character string from the original
            database field.</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:renderDateSuffix" as="xs:string">
        <xsl:param name="dateSuffix" as="xs:string?"/>
        <xsl:sequence select="if (empty($dateSuffix)) then '' else
            if ($dateSuffix eq '&lt;') then '(before)' else 
            if ($dateSuffix eq '&gt;') then '(after)' else $dateSuffix"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>This is a function to convert any random string -- usually a name -- to a suitable xml:id.</xd:desc>
        <xd:param name="strIn" as="xs:string">The incoming key or identifier.</xd:param>
        <xd:param name="strPrefix" as="xs:string">A prefix that can be used to ensure the first character is a letter,
            and to differentiate different types of ids.</xd:param>
        <xd:return>A string that can be used as an id.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:strToId" as="xs:string">
        <xsl:param name="strIn" as="xs:string"/>
        <xsl:param name="strPrefix" as="xs:string"/>
        <xsl:sequence select="lower-case($strPrefix || replace($strIn, '[^A-Za-z]+', '_'))"/>
    </xsl:function>
    
    
    
</xsl:stylesheet>