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
            <xd:p><xd:b>Created on:</xd:b> Nov 30, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This converts the ad-hoc XML structures built from the 
            original TSV files into proper TEI XML files. It runs on itself
            and loads what it needs from disk.</xd:p>
        </xd:desc>
        <xd:param name="basedir">The project base directory.</xd:param>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>XML in, XML out.</xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes" encoding="UTF-8" 
        normalization-form="NFC" exclude-result-prefixes="#all"/>
    
    <xd:doc>
        <xd:desc>For any tei: elements, we want to behave as though
        this is an identity transform; for any hcmc: elements, we want
        them to survive to the output so that we know that we have failed
        to deal with them correctly.</xd:desc>
    </xd:doc>
    <xsl:mode name="metadata" on-no-match="shallow-copy"/>
    
    <xd:doc>
        <xd:desc>For clarity, we use a basedir from the Ant build file.</xd:desc>
    </xd:doc>
    <xsl:param name="basedir" as="xs:string" select="'../'"/>
    
    <xd:doc>
        <xd:desc>The collection of ad-hoc XML tables we have created from the TSV.</xd:desc>
    </xd:doc>
    <xsl:variable name="inputFiles" as="document-node()*" select="collection($basedir || '/tempXml/?select=*.xml')"/>
    
    <xd:doc>
        <xd:desc>The template file is used as the basis for the output files.</xd:desc>
    </xd:doc>
    <xsl:variable name="teiTemplate" as="element(tei:TEI)" select="doc($basedir || '/templates/template.xml')//tei:TEI"/>
    
    <xd:doc>
        <xd:desc>The main template runs the whole process.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Processing {count($inputFiles)} input files into TEI...</xsl:message>
        <xsl:message>Working in base directory {$basedir}</xsl:message>
        <!-- First, we'll generate a metadata file with most of the linked items in it. -->
        <xsl:result-document href="{$basedir}/tei/metadata.xml">
            <xsl:apply-templates mode="metadata" select="$teiTemplate"/>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We add a subtitle to the template for the metadata file.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:title[@type='sub']" mode="metadata">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:sequence select="'Related metadata'"/>
        </xsl:copy>
    </xsl:template>
    <xd:doc>
        <xd:desc>We convert the abbreviations into a list.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='abbreviations']" mode="metadata">
        <list type="abbreviations">
            <xsl:for-each select="row[position() gt 1]">
                <choice xml:id="abbr_{cell[1]/text()}">
                    <abbr><xsl:value-of select="cell[2]"/></abbr>
                    <expan><xsl:value-of select="cell[3]"/></expan>
                </choice>
            </xsl:for-each>
        </list>
    </xsl:template>
    
</xsl:stylesheet>