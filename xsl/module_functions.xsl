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
            <xd:p>This module contains functions for processing both incoming
            text and custom hcmc:* XML into TEI, and for processing TEI into 
            output HTML. Most functions are designed to remediate or otherwise 
            handle unusual or erroneous components of the incoming text (such 
            as escaped, embedded HTML elements).</xd:p>
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
        <xsl:variable name="regex" as="xs:string">&lt;([A-Za-z][^&gt;]*)&gt;([^&lt;]+)&lt;/[A-Za-z][^&gt;]*&gt;</xsl:variable>
        <xsl:variable name="output" as="item()*">
            <xsl:analyze-string select="$strIn" regex="{$regex}">
                <xsl:matching-substring>
                    <hi n="{replace(., $regex, '$1')}"><xsl:sequence select="replace(., $regex, '$2')"/></hi>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                   <xsl:sequence select="."/>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:sequence select="$output"/>
    </xsl:function>
    
</xsl:stylesheet>