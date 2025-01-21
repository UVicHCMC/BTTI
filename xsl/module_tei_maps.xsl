<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    xmlns:xh="http://www.w3.org/1999/xhtml"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Dec 17, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This module contains a range of maps built from the TEI XML
                which are useful both in diagnostics and in building the HTML
                output. It also includes simple sequences of ids against which 
                pointers can be checked.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>All the source document ids.</xd:desc>
    </xd:doc>
    <xsl:variable name="mainSourceIds" as="xs:string+" select="$teiSource//listBibl[@xml:id='sourceshtml']/bibl/xs:string(@xml:id)"/>
    
    <xd:doc>
        <xd:desc>All the county BBTI ids.</xd:desc>
    </xd:doc>
    <xsl:variable name="countyIds" as="xs:string+" select="$teiSource//listPlace[@xml:id='counties']/place/idno[@type='BBTI']/xs:string(text())"/>
    
    <xd:doc>
        <xd:desc>All the country BBTI ids.</xd:desc>
    </xd:doc>
    <xsl:variable name="countryIds" as="xs:string+" select="$teiSource//listPlace[@xml:id='countries']/place/idno[@type='BBTI']/xs:string(text())"/>
    
    <xd:doc>
        <xd:desc>All the allowed date suffix values.</xd:desc>
    </xd:doc>
    <xsl:variable name="dateSuffixes" as="xs:string+" select="$teiSource//list[@type='dateSuffixes']/item/choice/abbr/xs:string(text())"/>
    
    <xd:doc>
        <xd:desc>A map of the date suffixes to allow us to just look them up as pre-rendered spans.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapDateSuffsToSpans" as="map(xs:string, element(xh:span))">
        <xsl:map>
            <xsl:for-each select="$teiSource//list[@type='dateSuffixes']/item/choice">
                <xsl:choose>
                    <xsl:when test="matches(xs:string(abbr), '[&lt;]')">
                        <xsl:map-entry key="xs:string(abbr)">
                            <span xmlns="http://www.w3.org/1999/xhtml" class="dateSuff">(or earlier)</span>
                        </xsl:map-entry>
                    </xsl:when>
                    <xsl:when test="matches(xs:string(abbr), '[&gt;]')">
                        <xsl:map-entry key="xs:string(abbr)">
                            <span xmlns="http://www.w3.org/1999/xhtml" class="dateSuff">(or later)</span>
                        </xsl:map-entry>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:map-entry key="xs:string(abbr)">
                            <span xmlns="http://www.w3.org/1999/xhtml" class="dateSuff"><xsl:value-of select="xs:string(expan)"/></span>
                        </xsl:map-entry>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>Sources with their pseudo-html need to be available as pre-built
        references we can just insert into any context that needs them.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapSourceIdsToSpans" as="map(xs:string, element(xh:span))">
        <xsl:map>
            <xsl:for-each select="$teiSource//listBibl[@xml:id='sourceshtml']/bibl">
                <xsl:map-entry key="xs:string(@xml:id)">
                    <span xmlns="http://www.w3.org/1999/xhtml"><xsl:apply-templates select="node()" mode="html"/><span class="bbtiId"><xsl:value-of select="@n"/></span></span>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>We need a map of place identifiers to their full names.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapCountyKeysToSpans" as="map(xs:string, element(xh:span))">
        <xsl:map>
            <xsl:for-each select="$teiSource//listPlace[@xml:id='counties']/descendant::place[child::idno[@type='BBTI'][string-length(.) gt 1]]">
                <xsl:map-entry key="xs:string(child::idno[@type='BBTI'])">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="countyName"><xsl:value-of select="placeName"/>
                    <xsl:apply-templates select="child::idno" mode="extraInfo"/>
                    </span>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>A plain string version of the above.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapCountyKeysToStrings" as="map(xs:string, xs:string)">
        <xsl:map>
            <!-- Initial entry for the question mark placeholder. -->
            <xsl:map-entry key="'?'" select="'?'"/>
            <xsl:for-each select="$teiSource//listPlace[@xml:id='counties']/descendant::place[child::idno[@type='BBTI'][string-length(.) gt 1]]">
                <xsl:map-entry key="xs:string(child::idno[@type='BBTI'])" select="xs:string(placeName)"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>We need a map of country identifiers to their full names.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapCountryKeysToSpans" as="map(xs:string, element(xh:span))">
        <xsl:map>
            <xsl:for-each select="$teiSource//listPlace[@xml:id='countries']/descendant::place[child::idno[@type='BBTI'][string-length(.) gt 1]]">
                <xsl:map-entry key="xs:string(child::idno[@type='BBTI'])">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="countryName"><xsl:value-of select="placeName"/><span class="bbtiId"><xsl:value-of select="@n"/></span></span>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>A map of org ids to their active years (both bio and trading).</xd:desc>
    </xd:doc>
    <xsl:variable name="mapOrgIdsToYears" as="map(xs:string, xs:string+)">
        <xsl:map>
            <xsl:for-each select="$teiSource//org[@xml:id]">
                <xsl:map-entry key="xs:string(@xml:id)" select="hcmc:getYearsFromOrg(.)"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    
    <xd:doc>
        <xd:desc>A map of trade ids to their full descriptions as spans.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapTradeIdsToSpans" as="map(xs:string, element(xh:span))">
        <xsl:map>
            <xsl:for-each select="$teiSource//taxonomy[@xml:id='trades']/descendant::category">
                <xsl:map-entry key="xs:string(@xml:id)">
                    <span xmlns="http://www.w3.org/1999/xhtml" class="trade"><xsl:value-of select="desc"/>
                    <xsl:text> (</xsl:text>
                        <xsl:choose>
                            <xsl:when test="starts-with(@xml:id, 'trdPri')">primary</xsl:when>
                            <xsl:when test="starts-with(@xml:id, 'trdSec')">secondary</xsl:when>
                            <xsl:when test="starts-with(@xml:id, 'trdNonBk')">non-book-related</xsl:when>
                        </xsl:choose>
                        <xsl:text>)</xsl:text></span>
                </xsl:map-entry>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>A map of all counties to the cities claimed to lie within them.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapCountyKeysToCityNames" as="map(xs:string, xs:string*)">
        <xsl:map>
            <xsl:for-each-group select="$teiSource//org" group-by="xs:string(location/address/region)">
                <xsl:sort select="lower-case(current-grouping-key())"/>
                <xsl:map-entry key="current-grouping-key()" select="distinct-values(((current-group()/descendant::settlement/xs:string(.))))"/>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>The reverse of the above: a map of all settlements to the counties within
            which they've been located.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapCityNamesToCountyKeys" as="map(xs:string, xs:string*)">
        <xsl:map>
            <xsl:for-each-group select="$teiSource//org" group-by="xs:string(location/address/settlement)">
                <xsl:sort select="lower-case(current-grouping-key())"/>
                <xsl:map-entry key="current-grouping-key()" select="distinct-values(((current-group()/descendant::region/xs:string(.))))"/>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>A map of trade ids to their short captions as strings.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapTradeIdsToStrings" as="map(xs:string, xs:string)">
        <xsl:map>
            <xsl:for-each select="$teiSource//taxonomy[@xml:id='trades']/descendant::category">
                <xsl:map-entry key="xs:string(@xml:id)" select="xs:string(desc)"/>
            </xsl:for-each>
        </xsl:map>
    </xsl:variable>
    
    
</xsl:stylesheet>