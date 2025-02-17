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
            <xd:p><xd:b>Created on:</xd:b> Ja 21 2025</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This module contains functions for processing both incoming
            text and custom hcmc:* XML into TEI.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>This function is designed to process text nodes which contain embedded
        escaped HTML markup, and render this into appropriate TEI. This code makes an 
        assumption that there is no nested markup; this may prove to be false, in which 
        case it will have to be revisited.</xd:desc>
        <xd:param name="strIn" as="xs:string">Incoming text which may contain embedded markup.</xd:param>
        <xd:return>A sequence of items, being text nodes or TEI elements.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:embeddedMarkupToTei" as="item()*"
        exclude-result-prefixes="#all">
        <xsl:param name="strIn" as="xs:string"/>
        <xsl:variable name="regexContainer" as="xs:string">&lt;([A-Za-z][^&gt;]*)&gt;([^&lt;]+)&lt;/[A-Za-z][^&gt;]*&gt;</xsl:variable>
        <xsl:variable name="regexBreak" as="xs:string">&lt;BR/?&gt;</xsl:variable>
        <xsl:variable name="output" as="item()*">
            <xsl:analyze-string select="$strIn" regex="{$regexContainer}">
                <xsl:matching-substring>
                    <hi n="{replace(., $regexContainer, '$1')}"><xsl:sequence select="replace(., $regexContainer, '$2')"/></hi>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                   <xsl:analyze-string select="." regex="{$regexBreak}">
                       <xsl:matching-substring>
                           <lb/>
                       </xsl:matching-substring>
                       <xsl:non-matching-substring>
                           <xsl:sequence select="."/>
                       </xsl:non-matching-substring>
                   </xsl:analyze-string>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="$output"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>We have mixed encoding in the incoming sources, frequently leading to 
        borked byte sequences in UTF-8. This function attempts to fix that.</xd:desc>
        <xd:param name="strIn" as="xs:string">The incoming text</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:fixEncoding" as="xs:string">
        <xsl:param name="strIn" as="xs:string"/>
        <xsl:sequence select="replace(
                              replace(
                              replace(
                              replace(
                              replace(
                              replace(
                              replace(
                              replace(
                              replace(hcmc:removeAnchors($strIn), '&amp;nbsp;', ' '),
                                              '&#160;', ' '),
                                              '&amp;160;', ' '),
                                              'Â', ' '),
                                              'â€¦', '…'),
                                              'â€“', '–'),
                                              'â€™', '’'),
                                              'â€œ', '“'),
                                              'â€', '”')"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>This function attempts to remove HTML anchors added into the 
            source data to provide anchors in the HTML pages.</xd:desc> 
        <xd:param name="strIn" as="xs:string">The incoming text</xd:param>
    </xd:doc>
    <xsl:function name="hcmc:removeAnchors" as="xs:string">
        <xsl:param name="strIn" as="xs:string"/>
        <xsl:sequence select="replace($strIn, '&lt;a name[^&gt;]+&gt;', '')"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>This function attempts to turn the weird collection of 
        fields encoding an imprecise date into a state element. This is a weird
        convolution resulting from the strange encoding of dates in this project.</xd:desc>
        <xd:param name="year" as="xs:string">The first year in the range.</xd:param>
        <xd:param name="yearSuffix" as="xs:string">The suffix applied to the first year in the range.</xd:param>
        <xd:param name="type" as="xs:string">The type of date (usually bioStart, tradeEnd, etc.).</xd:param>
        <xd:return>A date element.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:renderDateAsState" as="element(tei:state)?">
        <xsl:param name="year" as="xs:string"/>
        <xsl:param name="yearSuffix" as="xs:string"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$year eq 'NULL'"/>
            <xsl:when test="$yearSuffix eq 'NULL'">
                <state when="{$year}" type="{$type}"/> 
            </xsl:when>
            <xsl:when test="$yearSuffix eq '&lt;'">
                <state notAfter="{$year}" type="{$type}" n="{$yearSuffix}"/> 
            </xsl:when>
            <xsl:when test="$yearSuffix eq '&gt;'">
                <state notBefore="{$year}" type="{$type}" n="{$yearSuffix}"/> 
            </xsl:when>
            <xsl:when test="$yearSuffix eq '?'">
                <state when="{$year}" cert="low" type="{$type}" n="{$yearSuffix}"/> 
            </xsl:when>
            <xsl:otherwise>
                <state when="{$year}" type="{$type}" n="{$yearSuffix}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>This is a function to convert the sometimes strangely unsuitable strings
            that are used as ids for things like sources into something that actually can 
            work as an xml:id.</xd:desc>
        <xd:param name="strIn" as="xs:string">The incoming key or identifier.</xd:param>
        <xd:return>A string that can be used as an id.</xd:return>
    </xd:doc>
    <xsl:function name="hcmc:bbtiKeyToId" as="xs:string">
        <xsl:param name="strIn" as="xs:string"/>
        <xsl:sequence select="replace($strIn, '[\s/\+&amp;\(\)\*]+', '_')"/>
    </xsl:function>

    
</xsl:stylesheet>