<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    xpath-default-namespace=""
    xmlns="http://hcmc.uvic.ca/ns"
    expand-text="yes"
    version="3.0">
    <xd:doc>
        <xd:desc>
            <xd:p>
                This process will:
                <xd:ul>
                    <xd:li>Load each TSV source file</xd:li>
                    <xd:li>Clean up known problems such as phony 
                    linebreaks (&#x0a; followed by \n)</xd:li>
                    <xd:li>Parse the text into lines</xd:li>
                    <xd:li>Parse each line into a record</xd:li>
                    <xd:li>Output a file containing XML serializations of those records.</xd:li>
                </xd:ul>
                Output XML is a convenient ad-hoc XML representation of the 
                original source records and labels, in the HCMC namespace.
            </xd:p>
            <xd:p>
                This file runs on itself and loads its requirements dynamically.
            </xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" 
        normalization-form="NFC" exclude-result-prefixes="#all"/>
    
    <xd:doc>
        <xd:desc>The default template does all the work.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        
    </xsl:template>
    
</xsl:stylesheet>