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
            and loads what it needs from disk. The default namespace is the
            hcmc namespace in which the temporary XML versions of the tables
            are expressed.</xd:p>
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
        <xd:desc>This template matches the body element in the metadata mode and
        triggers the output of each of the metadata collections.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:body" mode="metadata">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='abbreviations']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='tbldatesuffixes']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='feather']" mode="#current"/>
        </xsl:copy>
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
            <xsl:for-each select="body/row">
                <item>
                    <choice xml:id="abbr_{cell[1]/text()}">
                        <abbr><xsl:value-of select="cell[2]"/></abbr>
                        <expan><xsl:value-of select="replace(cell[3], '&lt;.+&gt;\s*$', '')"/></expan>
                    </choice>
                    <xsl:if test="matches(cell[3], '&lt;.+&gt;')">
                        <note type="internal">Original expansion was followed by <q><xsl:value-of select="replace(cell[3], '.+(&lt;.+&gt;\s*)$', '$1')"/></q>.</note>
                    </xsl:if>
                </item>
            </xsl:for-each>
        </list>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert the date suffix abbreviations into a list.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='tbldatesuffixes']" mode="metadata">
        <list type="dateSuffixes">
            <xsl:for-each select="body/row">
                <item>
                    <choice xml:id="dateSuff_{position()}">
                        <abbr><xsl:value-of select="cell[1]"/></abbr>
                        <expan><xsl:value-of select="cell[2]"/></expan>
                    </choice>
                </item>
            </xsl:for-each>
        </list>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert the "Feather" bibliography into a listBibl.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='feather']" mode="metadata">
        <listBibl xml:id="feather" source="src:feather"><!-- Add a proper pointer to a usable source. -->
            <xsl:for-each select="body/row[position() gt 1]">
                <bibl xml:id="feather_{cell[1]}">
                    <author>
                        <xsl:choose>
                            <xsl:when test="cell[2] eq 'NULL'"/>
                            <xsl:when test="matches(cell[2], '^\s*-\s*$')">
                                <xsl:value-of select="parent::row/preceding-sibling::row[cell[2][not(matches(., '^\s*-\s*$'))]]/cell[2]/normalize-space(.)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="normalize-space(cell[2])"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </author>
                    <title><xsl:value-of select="normalize-space(cell[3])"/></title>
                    <bibl type="publication"><xsl:value-of select="normalize-space(cell[4])"/></bibl>
                    <xsl:if test="not(cell[6] eq 'NULL')">
                        <orgName><xsl:value-of select="normalize-space(cell[6])"/></orgName>
                    </xsl:if>
                    <xsl:if test="not(cell[7] eq 'NULL')">
                        <pubPlace><placeName><xsl:value-of select="normalize-space(cell[7])"/></placeName></pubPlace>
                    </xsl:if>
                    <idno type="Feather"><xsl:value-of select="cell[8]"/></idno>
                    <xsl:if test="not(cell[5] eq 'NULL')">
                        <note><xsl:value-of select="normalize-space(cell[5])"/></note>
                    </xsl:if>
                </bibl>
            </xsl:for-each>
        </listBibl>
    </xsl:template>
    
</xsl:stylesheet>