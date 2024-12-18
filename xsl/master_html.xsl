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
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Dec 18, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This is the driver for the HTML output generated from the
            TEI source.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>The main mode we use is html. We make it shallow-copy so that 
        validation will catch any cases where we have failed to properly process
        a TEI element.</xd:desc>
    </xd:doc>
    <xsl:mode name="html" on-no-match="shallow-copy"/>
    
    <xd:doc>
        <xd:desc>We're producing XHTML5.</xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" html-version="5" encoding="UTF-8" omit-xml-declaration="yes"
        normalization-form="NFC" indent="no" exclude-result-prefixes="#all" include-content-type="no"/>
    
    <xd:doc>
        <xd:desc>For clarity, we use a basedir from the Ant build file.</xd:desc>
    </xd:doc>
    <xsl:param name="baseDir" as="xs:string" select="'..'"/>
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="docRoot">docRoot</xd:ref> is needed in various contexts where the input
            document is out of scope.</xd:desc>
    </xd:doc>
    <xsl:variable name="docRoot" select="/"/>
    
    <xd:doc>
        <xd:desc>This is the TEI source XML.</xd:desc>
    </xd:doc>
    <xsl:variable name="teiSource" as="document-node()+" select="collection($baseDir || '/tei/?select=*.xml;recurse=yes')"/>
    
    <xd:doc>
        <xd:desc>We need the maps file.</xd:desc>
    </xd:doc>
    <xsl:include href="module_tei_maps.xsl"/>
    
    <xd:doc>
        <xd:desc>The root template processes the content to generate the output.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Building the site HTML...</xsl:message>
        <!-- First, we'll create the source listing. -->
        
        
    </xsl:template>
    
    <xsl:template match="title[contains(@style, 'italic')]" mode="html">
        <span class="mjTitle"><xsl:apply-templates mode="#current"/></span>
    </xsl:template>
    
    
</xsl:stylesheet>