<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://hcmc.uvic.ca/ns"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 30, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This converts the ad-hoc XML structures built from the 
            original TSV files into proper TEI XML files. It runs on itself
            and loads what it needs from disk.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" 
        normalization-form="NFC" exclude-result-prefixes="#all"/>
    
    <xd:doc>
        <xd:desc>The collection of ad-hoc XML tables we have created from the TSV.</xd:desc>
    </xd:doc>
    <xsl:variable name="inputFiles" as="document-node()*" select="collection('../tempXml/?select=*.xml')"/>
    
    <xd:doc>
        <xd:desc>The main template runs the whole process.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Processing {count($inputFiles)} input files into TEI...</xsl:message>
    </xsl:template>
    
</xsl:stylesheet>