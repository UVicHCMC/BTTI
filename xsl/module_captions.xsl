<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xh="http://www.w3.org/1999/xhtml"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    xmlns:j="http://www.w3.org/2005/xpath-functions"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 16, 2025</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>Centralized location for captions.</xd:p>
        </xd:desc>
    </xd:doc>
    
    
    <xd:doc>
        <xd:desc>Captions used.</xd:desc>
    </xd:doc>
    <xsl:variable name="capNoneFound" as="xs:string" select="'None found.'"/>
    <xsl:variable name="capUnknownUnspecified" as="xs:string">? (Unknown/Unspecified)</xsl:variable>
    <xsl:variable name="capBbtiId" as="xs:string" select="'BBTI ID'"/>
    <xsl:variable name="capSource" as="xs:string" select="'Source'"/>
    <xsl:variable name="capAuthor" as="xs:string" select="'Author'"/>
    <xsl:variable name="capTitle" as="xs:string" select="'Title'"/>
    <xsl:variable name="capDetails" as="xs:string" select="'Publishing Details'"/>
    
</xsl:stylesheet>