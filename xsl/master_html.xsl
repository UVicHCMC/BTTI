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
        <xd:desc>We need the maps file and the functions file.</xd:desc>
    </xd:doc>
    <xsl:include href="module_tei_maps.xsl"/>
    <xsl:include href="module_functions.xsl"/>
    
    <xd:doc>
        <xd:desc>The main mode we use is html. We make it shallow-copy so that 
        validation will catch any cases where we have failed to properly process
        a TEI element.</xd:desc>
    </xd:doc>
    <xsl:mode name="html" on-no-match="shallow-copy"/>
    
    <xd:doc>
        <xd:desc>The extraInfo mode is used to provide details which 
        were probably not present in the original site, but may be 
        useful.</xd:desc>
    </xd:doc>
    <xsl:mode name="extraInfo" on-no-match="shallow-skip"/>
    
    <xd:doc>
        <xd:desc>This is a parameter that enables us to build one or two documents at a time.</xd:desc>
    </xd:doc>
    <xsl:param name="docsToBuild" as="xs:string" select="''"/>
    
    <xd:doc>
        <xd:desc>This tokenizes docsToBuild for a sequence we can test against.</xd:desc>
    </xd:doc>
    <xsl:variable name="docsToBuildIds" as="xs:string*" select="tokenize($docsToBuild, '\s*,\s*')"/>
    
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
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="editionNumber" type="variable">editionNumber</xd:ref> is the current
            edition, which is used for page footers.</xd:desc>
    </xd:doc>
    <xsl:variable name="editionNumber" as="xs:string"
        select="normalize-space(unparsed-text(concat($baseDir, '/EDITION.txt')))"/>
    
    <xd:doc>
        <xd:desc>The git hash for the last commit.</xd:desc>
    </xd:doc>
    <xsl:variable name="gitHash" as="xs:string" select="unparsed-text($baseDir || '/gitHash.txt')"/>
    
    <xd:doc>
        <xd:desc>The build info to use in the footer.</xd:desc>
    </xd:doc>
    <xsl:variable name="footerBuildInfo" as="xs:string" select="
        'BBTI Edition ' || $editionNumber || ' ' || $nowDate || ', git rev. ' || substring($gitHash, 1, 8)
        || '.' "/>
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="nowDate" type="variable">nowDate</xd:ref> is the current date, which is
            used for page footers.</xd:desc>
    </xd:doc>
    <xsl:variable name="nowDate" as="xs:string"
        select="format-date(current-date(), '[D1o] [MNn] [Y0001]')"/>
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="thisYear" type="variable">thisYear</xd:ref> is the current year, which is
            used for dating non-timeline pages.</xd:desc>
    </xd:doc>
    <xsl:variable name="thisYear" as="xs:string" select="format-date(current-date(), '[Y0001]')"/>
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="outputDir">outputDir</xd:ref> is the folder where the output is
            created.</xd:desc>
    </xd:doc>
    <xsl:param name="outputDir" select="concat($baseDir, '/site')"/>
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="contentDir">contentDir</xd:ref> is the folder where the textual content
            is edited.</xd:desc>
    </xd:doc>
    <xsl:param name="contentDir" as="xs:string" select="concat($baseDir, 'content/')"/>
    
    <xd:doc>
        <xd:desc>The site page template, a framework HTML file.</xd:desc>
    </xd:doc>
    <xsl:variable name="sitePageTemplate" as="element(xh:html)"
        select="doc($baseDir || '/boilerplate/pageTemplate.xml')/xh:html"/>

    
    <xd:doc>
        <xd:desc>The root template processes the content to generate the output.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Building the site HTML...</xsl:message>
        
        
        <!-- First, default site pages. -->
        
        <!-- First we process each of the main site pages. -->
        <xsl:for-each select="$teiSource[child::body[$docsToBuild = '' or @xml:id = $docsToBuildIds]]">
            <xsl:variable name="currPageId" as="xs:string" select="xs:string(child::body/@xml:id)"/>
            <xsl:message>Processing {$currPageId} to {$outputDir}/{$currPageId}.html...</xsl:message>
            <xsl:result-document href="{$outputDir}/{$currPageId}.html">
                <xsl:apply-templates mode="html" select="$sitePageTemplate">
                    <xsl:with-param name="content" as="node()+" tunnel="yes"
                        select="body/node()"/>
                    <xsl:with-param name="currPageId" as="xs:string" tunnel="yes" select="$currPageId"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each>
        
        <!-- Now the actual org records. -->
        <xsl:for-each select="$teiSource//org[$docsToBuild = '' or @xml:id = $docsToBuildIds]">
            <xsl:variable name="currPageId" as="xs:string" select="xs:string(@xml:id)"/>
            <xsl:message>Processing {$currPageId} to {$outputDir}/orgs/{$currPageId}.html...</xsl:message>
            <xsl:result-document href="{$outputDir}/orgs/{$currPageId}.html">
                <xsl:apply-templates mode="html" select="$sitePageTemplate">
                    <xsl:with-param name="content" as="node()+" tunnel="yes"
                        select="."/>
                    <xsl:with-param name="currPageId" as="xs:string" tunnel="yes" select="$currPageId"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each>
        
    </xsl:template>
    
    <!-- *********** TEMPLATES FOR HANDLING HTML IN html MODE *************** -->
    <xd:doc>
        <xd:desc>Add the item id as the id of the page itself.</xd:desc>
        <xd:param name="currPageId" as="xs:string" tunnel="yes">The item id to use for the page id.</xd:param>
    </xd:doc>
    <xsl:template match="xh:html" mode="html">
        <xsl:param name="currPageId" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:attribute name="id" select="$currPageId"/>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Add a reasonable title for the document.</xd:desc>
        <xd:param name="content" as="node()+" tunnel="yes">Whatever content is being processed to 
            form the body of this page.</xd:param>
    </xd:doc>
    <xsl:template match="xh:head/xh:title" mode="html">
        <xsl:param name="content" as="node()+" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$content[self::org]">
                <xsl:variable name="dates" as="xs:string*" select="distinct-values((for $s in $content/state[@type='dateStates']/state return hcmc:getYear($s)))"/>
                <xsl:copy>
                    <xsl:sequence select="concat(normalize-space($content/orgName), ' ', string-join($dates, ' / '))"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="count($content) gt 1">
                <xsl:copy>
                    <xsl:sequence select="concat('BBTI: ', xs:string($content[self::head][1]))"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:sequence select="'British Book Trade Index'"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
       
            
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We process the charset meta tag before putting in the staticSearch tags.</xd:desc>
        <xd:param name="content" as="node()+" tunnel="yes">Whatever content is being processed to 
            form the body of this page.</xd:param>
    </xd:doc>
    <xsl:template match="xh:meta[@charset]" mode="html">
        <xsl:param name="content" as="node()+" tunnel="yes"/>
        <xsl:copy-of select="."/>
        <xsl:if test="$content[self::org]">
            <xsl:variable name="dates" as="xs:string*" select="distinct-values((for $s in $content/state[@type='dateStates']/state return hcmc:getYear($s)))"/>
            <xsl:for-each select="$content/descendant::settlement[string-length(.) gt 2]">
                <meta name="City/town" class="staticSearch_desc" content="{replace(., '[\?\.]$', '')}"/>
            </xsl:for-each>
            
            <xsl:for-each select="$content/descendant::region[string-length(.) gt 1]">
                <meta name="County/region" class="staticSearch_desc" content="{map:get($mapCountyKeysToStrings, xs:string(.))}"/>
            </xsl:for-each>
            
            <!-- This is where we add all our meta tags for the search. -->
            <meta name="Dates" class="staticSearch_date" content="{if (count($dates) gt 1) then min($dates) || '/' || max($dates) else $dates[1]}"/>
            <xsl:for-each select="$content/state/state[contains(@type, 'primaryTrade')]">
                <meta name="Primary trade" class="staticSearch_desc" content="{map:get($mapTradeIdsToStrings, substring-after(@corresp, 'trd:'))}"/>
            </xsl:for-each>
            <xsl:for-each select="$content/state/state[contains(@type, 'secondaryTrade')]">
                <meta name="Secondary trade" class="staticSearch_desc" content="{map:get($mapTradeIdsToStrings, substring-after(@corresp, 'trd:'))}"/>
            </xsl:for-each>
            <xsl:for-each select="$content/state/state[contains(@type, 'nonBookTrade')]">
                <meta name="Non-book trade" class="staticSearch_desc" content="{map:get($mapTradeIdsToStrings, substring-after(@corresp, 'trd:'))}"/>
            </xsl:for-each>
            
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We have to massage URLs in orgs because they're in a subfolder.</xd:desc>
        <xd:param name="content" as="node()+" tunnel="yes">Whatever content is being processed to 
        form the body of this page.</xd:param>
    </xd:doc>
    <xsl:template match="xh:head/xh:link/@href | xh:head/xh:script/@src | xh:img/@src | xh:a[@role='menuitem']/@href | xh:div[@id='mobile-nav-banner']/xh:a/@href"  mode="html">
        <xsl:param name="content" as="node()+" tunnel="yes"/>
        <xsl:attribute name="{local-name()}" select="if ($content[self::org]) then concat('../', .) else ."/>
    </xsl:template>

    <xd:doc>
        <xd:desc>We process the menu items in case they need to be highlighted because they're
            the page we're on.</xd:desc>
        <xd:param name="currPageId" as="xs:string" tunnel="yes">The item id to use for the page id.</xd:param>
    </xd:doc>
    <xsl:template match="xh:nav/xh:ul/xh:li" mode="html">
        <xsl:param name="currPageId" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:copy-of select="@*" />
            <xsl:if test="contains(child::xh:a/@href, $currPageId || '.html')">
                <xsl:attribute name="class" select="'currentPage'"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template matches a component of the site footer to add 
            build/edition information.</xd:desc>
    </xd:doc>
    <xsl:template match="xh:footer/xh:div[@id='buildInfo']" mode="html">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:sequence select="$footerBuildInfo"/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- *********** MAIN TEMPLATES FOR GENERATING HTML FROM TEI ************ -->
    <xd:doc>
        <xd:desc>This matches the point in the template where
            the document content should be inserted.</xd:desc>
        <xd:param name="content" as="element()+">The TEI content to be transformed.</xd:param>
    </xd:doc>
    <xsl:template match="processing-instruction('docContent')" mode="html">
        <xsl:param name="content" as="node()+" tunnel="yes"/>
        <xsl:apply-templates select="$content" mode="#current"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Orgs become divs.</xd:desc>
    </xd:doc>
    <xsl:template match="org" mode="html">
        <div class="{local-name()}">
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </div>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The org name is a container that may have direct
        content, but may just have text.</xd:desc>
    </xd:doc>
    <xsl:template match="org/orgName" mode="html">
        <h3 class="name"><xsl:apply-templates select="@*|node()" mode="#current"/></h3>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The persName can be broken out into two pieces.</xd:desc>
    </xd:doc>
    <xsl:template match="orgName/persName" mode="html">
        <span class="{local-name()}">
            <xsl:choose>
                <xsl:when test="child::surname and child::forename">
                    <xsl:apply-templates select="surname" mode="#current"/>
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates select="forename" mode="#current"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*|node()" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Surname and forename can be handled the same way.</xd:desc>
    </xd:doc>
    <xsl:template match="surname | forename" mode="html">
        <span class="{local-name()}"><xsl:apply-templates select="@*|node()" mode="#current"/></span>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This collection of elements is rendered as divs.</xd:desc>
    </xd:doc>
    <xsl:template match="location | address | org/note" mode="html">
        <xsl:if test="self::note and not(preceding-sibling::note)">
            <h4>Notes</h4>
        </xsl:if>
        <xsl:if test="self::address">
            <h4>Address</h4>
        </xsl:if>
        <div class="{local-name()}"><xsl:apply-templates select="@*|node()" mode="#current"/></div>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>All children of address become individual lines in the address.</xd:desc>
    </xd:doc>
    <xsl:template match="address/child::*" mode="html">
        <xsl:choose>
            <xsl:when test="self::region">
                <xsl:sequence select="map:get($mapCountyKeysToSpans, text())"/>
            </xsl:when>
            <xsl:when test="self::country">
                <xsl:sequence select="map:get($mapCountryKeysToSpans, text())"/>
            </xsl:when>
            <xsl:otherwise><span class="{local-name()}"><xsl:apply-templates select="@*|node()" mode="#current"/></span></xsl:otherwise>
        </xsl:choose>
        <xsl:if test="following-sibling::*"><br/></xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>For source info for an org, we grab it from the map where it's already made.</xd:desc>
    </xd:doc>
    <xsl:template match="org/bibl[@type='source']" mode="html">
        <xsl:if test="not(preceding-sibling::bibl[@type='source'])">
            <h4>Sources:</h4>
        </xsl:if>
        <p class="source"><xsl:sequence select="map:get($mapSourceIdsToSpans, substring-after(@corresp, 'src:'))"/></p>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>There are weird "Field3" and "Field4" entries that we can't understand
        but which don't seem to have been used in their output. We suppress them.</xd:desc>
    </xd:doc>
    <xsl:template match="note[@type='unknownField']" mode="html"/>
    
    <xd:doc>
        <xd:desc>This matches the list of date-related states in the TEI.</xd:desc>
    </xd:doc>
    <xsl:template match="state[@type='dateStates']" mode="html">
        <!--<xsl:apply-templates select="child::state" mode="#current"/>-->
        <xsl:if test="child::state[contains(@type, 'bio')]">
            <h4>Biographical Date(s)</h4>
            <p><xsl:sequence select="hcmc:renderStates(child::state[contains(@type, 'bio')])"/></p>
        </xsl:if>
        <xsl:if test="child::state[contains(@type, 'trad')]">
            <h4>Trade Date(s)</h4>
            <p><xsl:sequence select="hcmc:renderStates(child::state[contains(@type, 'trad')])"/></p>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This matches the list of trade-related states in the TEI.</xd:desc>
    </xd:doc>
    <xsl:template match="state[@type='tradeStates']" mode="html">
        <xsl:if test="count(child::state) gt 0">
            <h4>Trades</h4>
            <ul>
                <xsl:for-each select="child::state">
                    <li><xsl:sequence select="map:get($mapTradeIdsToSpans, substring-after(@corresp, 'trd:'))"/>                        <xsl:if test="child::label"><xsl:sequence select="' (' || child::label/text() || ')'"/></xsl:if>
                    </li>
                </xsl:for-each>
            </ul>
            
        </xsl:if>
        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This is the most complex template: states do many different things
        and have weird configurations.</xd:desc>
    </xd:doc>
    <xsl:template match="state" mode="html">
        <xsl:comment>Still need to handle this state:
            <xsl:sequence select="serialize(.)"/>
        </xsl:comment>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A para is a para.</xd:desc>
    </xd:doc>
    <xsl:template match="p" mode="html">
        <p>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </p>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Not sure why line breaks are there, but they are.</xd:desc>
    </xd:doc>
    <xsl:template match="lb" mode="html">
        <br/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A div is a div.</xd:desc>
    </xd:doc>
    <xsl:template match="div" mode="html">
        <div>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </div>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A q is a q.</xd:desc>
    </xd:doc>
    <xsl:template match="q" mode="html">
        <q>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </q>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Head elements depend on their level.</xd:desc>
    </xd:doc>
    <xsl:template match="head" mode="html">
        <xsl:element name="h{count(ancestor::div) + 2}">
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A list is a ul.</xd:desc>
    </xd:doc>
    <xsl:template match="list | listPlace | listBibl | listOrg" mode="html">
        <ul data-el="{local-name()}">
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </ul>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A list item is a li.</xd:desc>
    </xd:doc>
    <xsl:template match="item" mode="html">
        <li>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </li>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>An author is usually inline.</xd:desc>
    </xd:doc>
    <xsl:template match="author | orgName | pubPlace | publisher | idno | placeName | bibl/note[not(@type='unknownField')]" mode="html">
        <span data-el="{local-name()}">
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </span>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A ref[@target] just becomes a link for now.</xd:desc>
    </xd:doc>
    <xsl:template match="ref[@target]" mode="html">
        <a data-el="{local-name()}" href="{if (ends-with(@target, '.xml')) then replace(@target, '\.xml$', '.html') else @target}">
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </a>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The hi element is used where we have style but no reason for it. Other
        instances of hi can just be dropped.</xd:desc>
    </xd:doc>
    <xsl:template match="hi" mode="html">
        <xsl:choose>
            <xsl:when test="@style">
                <span class="hi" style="{@style}"><xsl:apply-templates mode="#current"/></span>
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates select="node()" mode="#current"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>Feather listings have a nested bibl.</xd:desc>
    </xd:doc>
    <xsl:template match="bibl[@type='publication']" mode="html">
        <span data-el="{local-name()}" data-type="publication">
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </span>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We don't know whether an italicized title is a monograph or a 
        journal.</xd:desc>
    </xd:doc>
    <xsl:template match="title[contains(@style, 'italic')]" mode="html">
        <span class="mjTitle"><xsl:apply-templates mode="#current"/></span>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Other titles are undifferentiated.</xd:desc>
    </xd:doc>
    <xsl:template match="title[not(@style)]" mode="html">
        <span class="title"><xsl:apply-templates mode="#current"/></span>
    </xsl:template>
    
    <!-- ********** PROCESSING INSTRUCTIONS ********** -->
    <xd:doc>
        <xd:desc>This generates a complete listing of all the sources.</xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction('sourcesTable')" mode="html">
        <table class="sortable">
            <thead>
                <tr>
                <th>BBTI ID</th>
                <th>Source</th>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="$teiSource//listBibl[@xml:id='sourceshtml']/bibl">
                    <tr id="{@xml:id}">
                        <td><xsl:value-of select="@n"/></td>
                        <td><xsl:apply-templates select="node()" mode="#current"/></td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This generates a tabular listing of the feather references.</xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction('featherTable')" mode="html">
        <table class="sortable">
            <thead>
                <tr>
                    <th>Author</th>
                    <th>Title</th>
                    <th>Publishing Details</th>
                </tr>
            </thead>
            <tbody>
                <xsl:for-each select="$teiSource//listBibl[@xml:id='feather']/bibl">
                    <xsl:sort select="replace(normalize-space(lower-case(concat(author, title))), '[^a-z]+', '')"/>
                    <tr id="{@xml:id}">
                        <td><xsl:apply-templates select="author" mode="#current"/></td>
                        <td><xsl:apply-templates select="title" mode="#current"/></td>
                        <td><xsl:apply-templates select="title/following-sibling::node()" mode="#current"/></td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This generates a tabular listing of the abbreviations.</xd:desc>
    </xd:doc>
    <xsl:template match="processing-instruction('abbreviationsTable')" mode="html">
        <table class="sortable">
            <tbody>
                <xsl:for-each select="$teiSource//list[@type='abbreviations']/item">
                    <xsl:sort select="normalize-space(.)"/>
                    <tr id="{@xml:id}">
                        <td><xsl:value-of select="choice/abbr"/></td>
                        <td><xsl:value-of select="choice/expan"/></td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>
    
    <!-- **************** TEMPLATES IN extraInfo mode ********************* -->
    <xd:doc>
        <xd:desc>idno elements provide extra info that may be useful.</xd:desc>
    </xd:doc>
    <xsl:template match="idno" mode="extraInfo">
        <span class="extraInfo"><xsl:value-of select="@type"/><xsl:text> code: </xsl:text><xsl:value-of select="text()"/></span>
    </xsl:template>
    
    
    <!-- **************** ATTRIBUTES ********************* -->
    
    <xd:doc>
        <xd:desc>We always keep an id if we can.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:*/@xml:id" mode="html">
        <xsl:choose>
            <xsl:when test="parent::*/local-name() = ('org')"></xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="id" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>For most TEI attributes, we generate a custom version.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:*/@*[not(local-name() eq 'id')]" mode="html">
        <xsl:attribute name="data-{local-name()}" select="."/>
    </xsl:template>
    
</xsl:stylesheet>