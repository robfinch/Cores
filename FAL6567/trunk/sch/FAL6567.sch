<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE eagle SYSTEM "eagle.dtd">
<eagle version="7.2.0">
<drawing>
<settings>
<setting alwaysvectorfont="no"/>
<setting verticaltext="up"/>
</settings>
<grid distance="0.1" unitdist="inch" unit="inch" style="lines" multiple="1" display="no" altdistance="0.01" altunitdist="inch" altunit="inch"/>
<layers>
<layer number="1" name="Top" color="4" fill="1" visible="no" active="no"/>
<layer number="16" name="Bottom" color="1" fill="1" visible="no" active="no"/>
<layer number="17" name="Pads" color="2" fill="1" visible="no" active="no"/>
<layer number="18" name="Vias" color="2" fill="1" visible="no" active="no"/>
<layer number="19" name="Unrouted" color="6" fill="1" visible="no" active="no"/>
<layer number="20" name="Dimension" color="15" fill="1" visible="no" active="no"/>
<layer number="21" name="tPlace" color="7" fill="1" visible="no" active="no"/>
<layer number="22" name="bPlace" color="7" fill="1" visible="no" active="no"/>
<layer number="23" name="tOrigins" color="15" fill="1" visible="no" active="no"/>
<layer number="24" name="bOrigins" color="15" fill="1" visible="no" active="no"/>
<layer number="25" name="tNames" color="7" fill="1" visible="no" active="no"/>
<layer number="26" name="bNames" color="7" fill="1" visible="no" active="no"/>
<layer number="27" name="tValues" color="7" fill="1" visible="no" active="no"/>
<layer number="28" name="bValues" color="7" fill="1" visible="no" active="no"/>
<layer number="29" name="tStop" color="7" fill="3" visible="no" active="no"/>
<layer number="30" name="bStop" color="7" fill="6" visible="no" active="no"/>
<layer number="31" name="tCream" color="7" fill="4" visible="no" active="no"/>
<layer number="32" name="bCream" color="7" fill="5" visible="no" active="no"/>
<layer number="33" name="tFinish" color="6" fill="3" visible="no" active="no"/>
<layer number="34" name="bFinish" color="6" fill="6" visible="no" active="no"/>
<layer number="35" name="tGlue" color="7" fill="4" visible="no" active="no"/>
<layer number="36" name="bGlue" color="7" fill="5" visible="no" active="no"/>
<layer number="37" name="tTest" color="7" fill="1" visible="no" active="no"/>
<layer number="38" name="bTest" color="7" fill="1" visible="no" active="no"/>
<layer number="39" name="tKeepout" color="4" fill="11" visible="no" active="no"/>
<layer number="40" name="bKeepout" color="1" fill="11" visible="no" active="no"/>
<layer number="41" name="tRestrict" color="4" fill="10" visible="no" active="no"/>
<layer number="42" name="bRestrict" color="1" fill="10" visible="no" active="no"/>
<layer number="43" name="vRestrict" color="2" fill="10" visible="no" active="no"/>
<layer number="44" name="Drills" color="7" fill="1" visible="no" active="no"/>
<layer number="45" name="Holes" color="7" fill="1" visible="no" active="no"/>
<layer number="46" name="Milling" color="3" fill="1" visible="no" active="no"/>
<layer number="47" name="Measures" color="7" fill="1" visible="no" active="no"/>
<layer number="48" name="Document" color="7" fill="1" visible="no" active="no"/>
<layer number="49" name="Reference" color="7" fill="1" visible="no" active="no"/>
<layer number="51" name="tDocu" color="6" fill="1" visible="no" active="no"/>
<layer number="52" name="bDocu" color="7" fill="1" visible="no" active="no"/>
<layer number="90" name="Modules" color="5" fill="1" visible="yes" active="yes"/>
<layer number="91" name="Nets" color="2" fill="1" visible="yes" active="yes"/>
<layer number="92" name="Busses" color="1" fill="1" visible="yes" active="yes"/>
<layer number="93" name="Pins" color="2" fill="1" visible="no" active="yes"/>
<layer number="94" name="Symbols" color="4" fill="1" visible="yes" active="yes"/>
<layer number="95" name="Names" color="7" fill="1" visible="yes" active="yes"/>
<layer number="96" name="Values" color="7" fill="1" visible="yes" active="yes"/>
<layer number="97" name="Info" color="7" fill="1" visible="yes" active="yes"/>
<layer number="98" name="Guide" color="6" fill="1" visible="yes" active="yes"/>
<layer number="100" name="A0" color="7" fill="1" visible="yes" active="yes"/>
</layers>
<schematic xreflabel="%F%N/%S.%C%R" xrefpart="/%S.%C%R">
<libraries>
<library name="65xxx">
<packages>
<package name="DIP-40">
<description>40-Pin DIP, 0.6" Wide</description>
<wire x1="26.67" y1="-6.35" x2="26.67" y2="6.35" width="0.127" layer="21"/>
<wire x1="26.67" y1="6.35" x2="-24.13" y2="6.35" width="0.127" layer="21"/>
<wire x1="26.67" y1="-6.35" x2="-24.13" y2="-6.35" width="0.127" layer="21"/>
<wire x1="-24.13" y1="1.905" x2="-24.13" y2="-1.905" width="0.127" layer="21" curve="-180"/>
<wire x1="-24.13" y1="-6.35" x2="-24.13" y2="-1.905" width="0.127" layer="21"/>
<wire x1="-24.13" y1="1.905" x2="-24.13" y2="6.35" width="0.127" layer="21"/>
<circle x="-22.225" y="-4.445" radius="0.635" width="0.127" layer="21"/>
<pad name="31" x="0" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="30" x="2.54" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="29" x="5.08" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="32" x="-2.54" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="33" x="-5.08" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="28" x="7.62" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="34" x="-7.62" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="27" x="10.16" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="35" x="-10.16" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="26" x="12.7" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="25" x="15.24" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="24" x="17.78" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="36" x="-12.7" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="37" x="-15.24" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="23" x="20.32" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="22" x="22.86" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="21" x="25.4" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="38" x="-17.78" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="39" x="-20.32" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="40" x="-22.86" y="7.62" drill="0.889" diameter="1.6002"/>
<pad name="10" x="0" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="1" x="-22.86" y="-7.62" drill="0.889" diameter="1.6002" shape="square"/>
<pad name="2" x="-20.32" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="3" x="-17.78" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="4" x="-15.24" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="5" x="-12.7" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="6" x="-10.16" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="7" x="-7.62" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="8" x="-5.08" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="9" x="-2.54" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="11" x="2.54" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="12" x="5.08" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="13" x="7.62" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="14" x="10.16" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="15" x="12.7" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="16" x="15.24" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="17" x="17.78" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="18" x="20.32" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="19" x="22.86" y="-7.62" drill="0.889" diameter="1.6002"/>
<pad name="20" x="25.4" y="-7.62" drill="0.889" diameter="1.6002"/>
<text x="-3.81" y="1.27" size="2.54" layer="25">&gt;NAME</text>
<text x="-3.81" y="-3.81" size="2.54" layer="27">&gt;VALUE</text>
</package>
</packages>
<symbols>
<symbol name="CSG6567">
<pin name="A0/A8" x="-17.78" y="17.78" length="middle"/>
<pin name="A1/A9" x="-17.78" y="15.24" length="middle"/>
<pin name="A2/A10" x="-17.78" y="12.7" length="middle"/>
<pin name="A3/A11" x="-17.78" y="10.16" length="middle"/>
<pin name="A4/A12" x="-17.78" y="7.62" length="middle"/>
<pin name="A5/A13" x="-17.78" y="5.08" length="middle"/>
<pin name="A6" x="-17.78" y="2.54" length="middle"/>
<pin name="A7" x="-17.78" y="0" length="middle"/>
<pin name="A8" x="-17.78" y="-2.54" length="middle" direction="out"/>
<pin name="A9" x="-17.78" y="-5.08" length="middle" direction="out"/>
<pin name="A10" x="-17.78" y="-7.62" length="middle" direction="out"/>
<pin name="A11" x="-17.78" y="-10.16" length="middle" direction="out"/>
<wire x1="-12.7" y1="-43.18" x2="-12.7" y2="20.32" width="0.254" layer="94"/>
<wire x1="-12.7" y1="20.32" x2="12.7" y2="20.32" width="0.254" layer="94"/>
<wire x1="12.7" y1="20.32" x2="12.7" y2="-43.18" width="0.254" layer="94"/>
<pin name="D0" x="17.78" y="17.78" length="middle" rot="R180"/>
<pin name="D1" x="17.78" y="15.24" length="middle" rot="R180"/>
<pin name="D2" x="17.78" y="12.7" length="middle" rot="R180"/>
<pin name="D3" x="17.78" y="10.16" length="middle" rot="R180"/>
<pin name="D4" x="17.78" y="7.62" length="middle" rot="R180"/>
<pin name="D5" x="17.78" y="5.08" length="middle" rot="R180"/>
<pin name="D6" x="17.78" y="2.54" length="middle" rot="R180"/>
<pin name="D7" x="17.78" y="0" length="middle" rot="R180"/>
<pin name="D8" x="17.78" y="-2.54" length="middle" direction="in" rot="R180"/>
<pin name="D9" x="17.78" y="-5.08" length="middle" direction="in" rot="R180"/>
<pin name="D10" x="17.78" y="-7.62" length="middle" direction="in" rot="R180"/>
<pin name="D11" x="17.78" y="-10.16" length="middle" direction="in" rot="R180"/>
<pin name="CSB" x="-17.78" y="-15.24" length="middle" direction="in" function="dot"/>
<pin name="AEC" x="-17.78" y="-17.78" length="middle" direction="out"/>
<pin name="RASB" x="-17.78" y="-22.86" length="middle" direction="out" function="dot"/>
<pin name="CASB" x="-17.78" y="-25.4" length="middle" direction="out" function="dot"/>
<pin name="R/WB" x="-17.78" y="-27.94" length="middle" direction="in"/>
<pin name="BA" x="-17.78" y="-20.32" length="middle" direction="out"/>
<pin name="SYNC+LUM" x="17.78" y="-15.24" length="middle" direction="out" rot="R180"/>
<pin name="COLOR" x="17.78" y="-17.78" length="middle" direction="out" rot="R180"/>
<pin name="CLRCLK" x="17.78" y="-22.86" length="middle" direction="in" function="clk" rot="R180"/>
<pin name="DOTCLK" x="17.78" y="-25.4" length="middle" direction="in" function="clk" rot="R180"/>
<pin name="PHI0" x="17.78" y="-30.48" length="middle" direction="out" function="clk" rot="R180"/>
<pin name="IRQB" x="-17.78" y="-33.02" length="middle" direction="oc" function="dot"/>
<pin name="LPB" x="-17.78" y="-35.56" length="middle" direction="in" function="dot"/>
<pin name="VDD" x="17.78" y="-35.56" length="middle" direction="pwr" rot="R180"/>
<pin name="VCC" x="17.78" y="-38.1" length="middle" direction="pwr" rot="R180"/>
<pin name="GND" x="17.78" y="-40.64" length="middle" direction="pwr" rot="R180"/>
<wire x1="12.7" y1="-43.18" x2="-12.7" y2="-43.18" width="0.254" layer="94"/>
<text x="-12.7" y="22.86" size="1.778" layer="94">CSG6567</text>
</symbol>
</symbols>
<devicesets>
<deviceset name="CSG6567">
<gates>
<gate name="G$1" symbol="CSG6567" x="-7.62" y="10.16"/>
</gates>
<devices>
<device name="" package="DIP-40">
<connects>
<connect gate="G$1" pin="A0/A8" pad="24"/>
<connect gate="G$1" pin="A1/A9" pad="25"/>
<connect gate="G$1" pin="A10" pad="34"/>
<connect gate="G$1" pin="A11" pad="23"/>
<connect gate="G$1" pin="A2/A10" pad="26"/>
<connect gate="G$1" pin="A3/A11" pad="27"/>
<connect gate="G$1" pin="A4/A12" pad="28"/>
<connect gate="G$1" pin="A5/A13" pad="29"/>
<connect gate="G$1" pin="A6" pad="30"/>
<connect gate="G$1" pin="A7" pad="31"/>
<connect gate="G$1" pin="A8" pad="32"/>
<connect gate="G$1" pin="A9" pad="33"/>
<connect gate="G$1" pin="AEC" pad="16"/>
<connect gate="G$1" pin="BA" pad="12"/>
<connect gate="G$1" pin="CASB" pad="19"/>
<connect gate="G$1" pin="CLRCLK" pad="21"/>
<connect gate="G$1" pin="COLOR" pad="14"/>
<connect gate="G$1" pin="CSB" pad="10"/>
<connect gate="G$1" pin="D0" pad="7"/>
<connect gate="G$1" pin="D1" pad="6"/>
<connect gate="G$1" pin="D10" pad="36"/>
<connect gate="G$1" pin="D11" pad="35"/>
<connect gate="G$1" pin="D2" pad="5"/>
<connect gate="G$1" pin="D3" pad="4"/>
<connect gate="G$1" pin="D4" pad="3"/>
<connect gate="G$1" pin="D5" pad="2"/>
<connect gate="G$1" pin="D6" pad="1"/>
<connect gate="G$1" pin="D7" pad="39"/>
<connect gate="G$1" pin="D8" pad="38"/>
<connect gate="G$1" pin="D9" pad="37"/>
<connect gate="G$1" pin="DOTCLK" pad="22"/>
<connect gate="G$1" pin="GND" pad="20"/>
<connect gate="G$1" pin="IRQB" pad="8"/>
<connect gate="G$1" pin="LPB" pad="9"/>
<connect gate="G$1" pin="PHI0" pad="17"/>
<connect gate="G$1" pin="R/WB" pad="11"/>
<connect gate="G$1" pin="RASB" pad="18"/>
<connect gate="G$1" pin="SYNC+LUM" pad="15"/>
<connect gate="G$1" pin="VCC" pad="40"/>
<connect gate="G$1" pin="VDD" pad="13"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
</devicesets>
</library>
<library name="FT74xx">
<description>&lt;b&gt;TTL Devices, 74xx Series with US Symbols&lt;/b&gt;&lt;p&gt;
Based on the following sources:
&lt;ul&gt;
&lt;li&gt;Texas Instruments &lt;i&gt;TTL Data Book&lt;/i&gt;&amp;nbsp;&amp;nbsp;&amp;nbsp;Volume 1, 1996.
&lt;li&gt;TTL Data Book, Volume 2 , 1993
&lt;li&gt;National Seminconductor Databook 1990, ALS/LS Logic
&lt;li&gt;ttl 74er digital data dictionary, ECA Electronic + Acustic GmbH, ISBN 3-88109-032-0
&lt;li&gt;http://icmaster.com/ViewCompare.asp
&lt;/ul&gt;
&lt;author&gt;Created by librarian@cadsoft.de&lt;/author&gt;</description>
<packages>
<package name="DIL20">
<description>&lt;b&gt;Dual In Line Package&lt;/b&gt;</description>
<wire x1="12.7" y1="2.921" x2="-12.7" y2="2.921" width="0.1524" layer="21"/>
<wire x1="-12.7" y1="-2.921" x2="12.7" y2="-2.921" width="0.1524" layer="21"/>
<wire x1="12.7" y1="2.921" x2="12.7" y2="-2.921" width="0.1524" layer="21"/>
<wire x1="-12.7" y1="2.921" x2="-12.7" y2="1.016" width="0.1524" layer="21"/>
<wire x1="-12.7" y1="-2.921" x2="-12.7" y2="-1.016" width="0.1524" layer="21"/>
<wire x1="-12.7" y1="1.016" x2="-12.7" y2="-1.016" width="0.1524" layer="21" curve="-180"/>
<pad name="1" x="-11.43" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="2" x="-8.89" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="7" x="3.81" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="8" x="6.35" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="3" x="-6.35" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="4" x="-3.81" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="6" x="1.27" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="5" x="-1.27" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="9" x="8.89" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="10" x="11.43" y="-3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="11" x="11.43" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="12" x="8.89" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="13" x="6.35" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="14" x="3.81" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="15" x="1.27" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="16" x="-1.27" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="17" x="-3.81" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="18" x="-6.35" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="19" x="-8.89" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<pad name="20" x="-11.43" y="3.81" drill="0.8128" shape="long" rot="R90"/>
<text x="-13.081" y="-3.048" size="1.27" layer="25" rot="R90">&gt;NAME</text>
<text x="-9.779" y="-0.381" size="1.27" layer="27">&gt;VALUE</text>
</package>
<package name="SO20W">
<description>&lt;b&gt;Wide Small Outline package&lt;/b&gt; 300 mil</description>
<wire x1="6.1214" y1="3.7338" x2="-6.1214" y2="3.7338" width="0.1524" layer="51"/>
<wire x1="6.1214" y1="-3.7338" x2="6.5024" y2="-3.3528" width="0.1524" layer="21" curve="90"/>
<wire x1="-6.5024" y1="3.3528" x2="-6.1214" y2="3.7338" width="0.1524" layer="21" curve="-90"/>
<wire x1="6.1214" y1="3.7338" x2="6.5024" y2="3.3528" width="0.1524" layer="21" curve="-90"/>
<wire x1="-6.5024" y1="-3.3528" x2="-6.1214" y2="-3.7338" width="0.1524" layer="21" curve="90"/>
<wire x1="-6.1214" y1="-3.7338" x2="6.1214" y2="-3.7338" width="0.1524" layer="51"/>
<wire x1="6.5024" y1="-3.3528" x2="6.5024" y2="3.3528" width="0.1524" layer="21"/>
<wire x1="-6.5024" y1="3.3528" x2="-6.5024" y2="1.27" width="0.1524" layer="21"/>
<wire x1="-6.5024" y1="1.27" x2="-6.5024" y2="-1.27" width="0.1524" layer="21"/>
<wire x1="-6.5024" y1="-1.27" x2="-6.5024" y2="-3.3528" width="0.1524" layer="21"/>
<wire x1="-6.477" y1="-3.3782" x2="6.477" y2="-3.3782" width="0.0508" layer="21"/>
<wire x1="-6.5024" y1="1.27" x2="-6.5024" y2="-1.27" width="0.1524" layer="21" curve="-180"/>
<smd name="1" x="-5.715" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="2" x="-4.445" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="3" x="-3.175" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="4" x="-1.905" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="5" x="-0.635" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="6" x="0.635" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="7" x="1.905" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="8" x="3.175" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="13" x="3.175" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="14" x="1.905" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="15" x="0.635" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="16" x="-0.635" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="17" x="-1.905" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="18" x="-3.175" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="19" x="-4.445" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="20" x="-5.715" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="9" x="4.445" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="10" x="5.715" y="-5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="12" x="4.445" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<smd name="11" x="5.715" y="5.0292" dx="0.6604" dy="2.032" layer="1"/>
<text x="-3.81" y="-1.778" size="1.27" layer="27" ratio="10">&gt;VALUE</text>
<text x="-6.858" y="-3.175" size="1.27" layer="25" ratio="10" rot="R90">&gt;NAME</text>
<rectangle x1="-5.969" y1="-3.8608" x2="-5.461" y2="-3.7338" layer="51"/>
<rectangle x1="-5.969" y1="-5.334" x2="-5.461" y2="-3.8608" layer="51"/>
<rectangle x1="-4.699" y1="-3.8608" x2="-4.191" y2="-3.7338" layer="51"/>
<rectangle x1="-4.699" y1="-5.334" x2="-4.191" y2="-3.8608" layer="51"/>
<rectangle x1="-3.429" y1="-3.8608" x2="-2.921" y2="-3.7338" layer="51"/>
<rectangle x1="-3.429" y1="-5.334" x2="-2.921" y2="-3.8608" layer="51"/>
<rectangle x1="-2.159" y1="-3.8608" x2="-1.651" y2="-3.7338" layer="51"/>
<rectangle x1="-2.159" y1="-5.334" x2="-1.651" y2="-3.8608" layer="51"/>
<rectangle x1="-0.889" y1="-5.334" x2="-0.381" y2="-3.8608" layer="51"/>
<rectangle x1="-0.889" y1="-3.8608" x2="-0.381" y2="-3.7338" layer="51"/>
<rectangle x1="0.381" y1="-3.8608" x2="0.889" y2="-3.7338" layer="51"/>
<rectangle x1="0.381" y1="-5.334" x2="0.889" y2="-3.8608" layer="51"/>
<rectangle x1="1.651" y1="-3.8608" x2="2.159" y2="-3.7338" layer="51"/>
<rectangle x1="1.651" y1="-5.334" x2="2.159" y2="-3.8608" layer="51"/>
<rectangle x1="2.921" y1="-3.8608" x2="3.429" y2="-3.7338" layer="51"/>
<rectangle x1="2.921" y1="-5.334" x2="3.429" y2="-3.8608" layer="51"/>
<rectangle x1="-5.969" y1="3.8608" x2="-5.461" y2="5.334" layer="51"/>
<rectangle x1="-5.969" y1="3.7338" x2="-5.461" y2="3.8608" layer="51"/>
<rectangle x1="-4.699" y1="3.7338" x2="-4.191" y2="3.8608" layer="51"/>
<rectangle x1="-4.699" y1="3.8608" x2="-4.191" y2="5.334" layer="51"/>
<rectangle x1="-3.429" y1="3.7338" x2="-2.921" y2="3.8608" layer="51"/>
<rectangle x1="-3.429" y1="3.8608" x2="-2.921" y2="5.334" layer="51"/>
<rectangle x1="-2.159" y1="3.7338" x2="-1.651" y2="3.8608" layer="51"/>
<rectangle x1="-2.159" y1="3.8608" x2="-1.651" y2="5.334" layer="51"/>
<rectangle x1="-0.889" y1="3.7338" x2="-0.381" y2="3.8608" layer="51"/>
<rectangle x1="-0.889" y1="3.8608" x2="-0.381" y2="5.334" layer="51"/>
<rectangle x1="0.381" y1="3.7338" x2="0.889" y2="3.8608" layer="51"/>
<rectangle x1="0.381" y1="3.8608" x2="0.889" y2="5.334" layer="51"/>
<rectangle x1="1.651" y1="3.7338" x2="2.159" y2="3.8608" layer="51"/>
<rectangle x1="1.651" y1="3.8608" x2="2.159" y2="5.334" layer="51"/>
<rectangle x1="2.921" y1="3.7338" x2="3.429" y2="3.8608" layer="51"/>
<rectangle x1="2.921" y1="3.8608" x2="3.429" y2="5.334" layer="51"/>
<rectangle x1="4.191" y1="3.7338" x2="4.699" y2="3.8608" layer="51"/>
<rectangle x1="5.461" y1="3.7338" x2="5.969" y2="3.8608" layer="51"/>
<rectangle x1="4.191" y1="3.8608" x2="4.699" y2="5.334" layer="51"/>
<rectangle x1="5.461" y1="3.8608" x2="5.969" y2="5.334" layer="51"/>
<rectangle x1="4.191" y1="-3.8608" x2="4.699" y2="-3.7338" layer="51"/>
<rectangle x1="5.461" y1="-3.8608" x2="5.969" y2="-3.7338" layer="51"/>
<rectangle x1="4.191" y1="-5.334" x2="4.699" y2="-3.8608" layer="51"/>
<rectangle x1="5.461" y1="-5.334" x2="5.969" y2="-3.8608" layer="51"/>
</package>
<package name="LCC20">
<description>&lt;b&gt;Leadless Chip Carrier&lt;/b&gt;&lt;p&gt; Ceramic Package</description>
<wire x1="-0.4001" y1="4.4" x2="-0.87" y2="4.4" width="0.2032" layer="51"/>
<wire x1="-3.3" y1="4.4" x2="-4.4" y2="3.3" width="0.2032" layer="51"/>
<wire x1="-0.4001" y1="4.3985" x2="0.4001" y2="4.3985" width="0.2032" layer="51" curve="180"/>
<wire x1="-1.6701" y1="4.3985" x2="-0.8699" y2="4.3985" width="0.2032" layer="51" curve="180"/>
<wire x1="-4.3985" y1="2.14" x2="-4.3985" y2="2.94" width="0.2032" layer="51" curve="180"/>
<wire x1="-2.9401" y1="4.4" x2="-3.3" y2="4.4" width="0.2032" layer="51"/>
<wire x1="0.87" y1="4.4" x2="0.4001" y2="4.4" width="0.2032" layer="51"/>
<wire x1="0.87" y1="4.3985" x2="1.67" y2="4.3985" width="0.2032" layer="51" curve="180"/>
<wire x1="-4.4" y1="3.3" x2="-4.4" y2="2.9401" width="0.2032" layer="51"/>
<wire x1="-4.4" y1="2.14" x2="-4.4" y2="1.6701" width="0.2032" layer="51"/>
<wire x1="-4.3985" y1="0.87" x2="-4.3985" y2="1.67" width="0.2032" layer="51" curve="180"/>
<wire x1="-4.3985" y1="-0.4001" x2="-4.3985" y2="0.4001" width="0.2032" layer="51" curve="180"/>
<wire x1="-4.3985" y1="-1.6701" x2="-4.3985" y2="-0.8699" width="0.2032" layer="51" curve="180"/>
<wire x1="-4.4" y1="0.87" x2="-4.4" y2="0.4001" width="0.2032" layer="51"/>
<wire x1="-4.4" y1="-0.4001" x2="-4.4" y2="-0.87" width="0.2032" layer="51"/>
<wire x1="-4.4" y1="-2.9401" x2="-4.4" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="-4.4" y1="-4.4" x2="-4.4" y2="-4.4099" width="0.2032" layer="51"/>
<wire x1="2.14" y1="4.3985" x2="2.94" y2="4.3985" width="0.2032" layer="51" curve="180"/>
<wire x1="2.14" y1="4.4" x2="1.6701" y2="4.4" width="0.2032" layer="51"/>
<wire x1="4.4" y1="4.4" x2="2.9401" y2="4.4" width="0.2032" layer="51"/>
<wire x1="0.4001" y1="-4.4" x2="0.87" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="-0.4001" y1="-4.3985" x2="0.4001" y2="-4.3985" width="0.2032" layer="51" curve="-180"/>
<wire x1="0.87" y1="-4.3985" x2="1.67" y2="-4.3985" width="0.2032" layer="51" curve="-180"/>
<wire x1="2.9401" y1="-4.4" x2="4.4" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="-0.87" y1="-4.4" x2="-0.4001" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="-1.6701" y1="-4.3985" x2="-0.8699" y2="-4.3985" width="0.2032" layer="51" curve="-180"/>
<wire x1="-2.9401" y1="-4.3985" x2="-2.1399" y2="-4.3985" width="0.2032" layer="51" curve="-180"/>
<wire x1="-2.14" y1="-4.4" x2="-1.6701" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="-4.4" y1="-4.4" x2="-2.9401" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="4.4" y1="0.4001" x2="4.4" y2="0.87" width="0.2032" layer="51"/>
<wire x1="4.3985" y1="0.4001" x2="4.3985" y2="-0.4001" width="0.2032" layer="51" curve="180"/>
<wire x1="4.3985" y1="1.6701" x2="4.3985" y2="0.8699" width="0.2032" layer="51" curve="180"/>
<wire x1="4.4" y1="2.9401" x2="4.4" y2="4.4" width="0.2032" layer="51"/>
<wire x1="4.4" y1="-0.87" x2="4.4" y2="-0.4001" width="0.2032" layer="51"/>
<wire x1="4.3985" y1="-0.87" x2="4.3985" y2="-1.67" width="0.2032" layer="51" curve="180"/>
<wire x1="4.3985" y1="-2.14" x2="4.3985" y2="-2.94" width="0.2032" layer="51" curve="180"/>
<wire x1="4.4" y1="-2.14" x2="4.4" y2="-1.6701" width="0.2032" layer="51"/>
<wire x1="4.4" y1="-4.4" x2="4.4" y2="-2.9401" width="0.2032" layer="51"/>
<wire x1="-2.9401" y1="4.3985" x2="-2.1399" y2="4.3985" width="0.2032" layer="51" curve="180"/>
<wire x1="-1.6701" y1="4.4" x2="-2.14" y2="4.4" width="0.2032" layer="51"/>
<wire x1="-4.3985" y1="-2.9401" x2="-4.3985" y2="-2.1399" width="0.2032" layer="51" curve="180"/>
<wire x1="-4.4" y1="-1.6701" x2="-4.4" y2="-2.14" width="0.2032" layer="51"/>
<wire x1="1.6701" y1="-4.4" x2="2.14" y2="-4.4" width="0.2032" layer="51"/>
<wire x1="2.14" y1="-4.3985" x2="2.94" y2="-4.3985" width="0.2032" layer="51" curve="-180"/>
<wire x1="4.3985" y1="2.9401" x2="4.3985" y2="2.1399" width="0.2032" layer="51" curve="180"/>
<wire x1="4.4" y1="1.6701" x2="4.4" y2="2.14" width="0.2032" layer="51"/>
<smd name="2" x="-1.27" y="4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="1" x="0" y="3.8001" dx="0.8" dy="3.4" layer="1"/>
<smd name="3" x="-2.54" y="4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="4" x="-4.5001" y="2.54" dx="2" dy="0.8" layer="1"/>
<smd name="5" x="-4.5001" y="1.27" dx="2" dy="0.8" layer="1"/>
<smd name="6" x="-4.5001" y="0" dx="2" dy="0.8" layer="1"/>
<smd name="7" x="-4.5001" y="-1.27" dx="2" dy="0.8" layer="1"/>
<smd name="8" x="-4.5001" y="-2.54" dx="2" dy="0.8" layer="1"/>
<smd name="9" x="-2.54" y="-4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="10" x="-1.27" y="-4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="11" x="0" y="-4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="12" x="1.27" y="-4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="13" x="2.54" y="-4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="14" x="4.5001" y="-2.54" dx="2" dy="0.8" layer="1"/>
<smd name="15" x="4.5001" y="-1.27" dx="2" dy="0.8" layer="1"/>
<smd name="16" x="4.5001" y="0" dx="2" dy="0.8" layer="1"/>
<smd name="17" x="4.5001" y="1.27" dx="2" dy="0.8" layer="1"/>
<smd name="18" x="4.5001" y="2.54" dx="2" dy="0.8" layer="1"/>
<smd name="19" x="2.54" y="4.5001" dx="0.8" dy="2" layer="1"/>
<smd name="20" x="1.27" y="4.5001" dx="0.8" dy="2" layer="1"/>
<text x="-3.4971" y="5.811" size="1.778" layer="25">&gt;NAME</text>
<text x="-3.9751" y="-7.6871" size="1.778" layer="27">&gt;VALUE</text>
</package>
<package name="DIL48">
<description>&lt;b&gt;Dual In Line Package&lt;/b&gt;</description>
<wire x1="-29.845" y1="-6.604" x2="29.845" y2="-6.604" width="0.1524" layer="21"/>
<wire x1="29.845" y1="-6.604" x2="29.845" y2="6.604" width="0.1524" layer="21"/>
<wire x1="29.845" y1="6.604" x2="-29.845" y2="6.604" width="0.1524" layer="21"/>
<wire x1="-29.845" y1="6.604" x2="-29.845" y2="0.889" width="0.1524" layer="21"/>
<wire x1="-29.845" y1="-6.604" x2="-29.845" y2="-1.143" width="0.1524" layer="21"/>
<wire x1="-29.845" y1="0.889" x2="-29.845" y2="-1.143" width="0.1524" layer="21" curve="-180"/>
<pad name="1" x="-29.21" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="2" x="-26.67" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="3" x="-24.13" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="4" x="-21.59" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="5" x="-19.05" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="6" x="-16.51" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="7" x="-13.97" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="8" x="-11.43" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="9" x="-8.89" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="10" x="-6.35" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="11" x="-3.81" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="12" x="-1.27" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="13" x="1.27" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="14" x="3.81" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="15" x="6.35" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="16" x="8.89" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="17" x="11.43" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="18" x="13.97" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="19" x="16.51" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="20" x="19.05" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="21" x="21.59" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="22" x="24.13" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="23" x="26.67" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="24" x="29.21" y="-7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="25" x="29.21" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="26" x="26.67" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="27" x="24.13" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="28" x="21.59" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="29" x="19.05" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="30" x="16.51" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="31" x="13.97" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="32" x="11.43" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="33" x="8.89" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="34" x="6.35" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="35" x="3.81" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="36" x="1.27" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="37" x="-1.27" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="38" x="-3.81" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="39" x="-6.35" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="40" x="-8.89" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="41" x="-11.43" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="42" x="-13.97" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="43" x="-16.51" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="44" x="-19.05" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="45" x="-21.59" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="46" x="-24.13" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="47" x="-26.67" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<pad name="48" x="-29.21" y="7.62" drill="0.8128" shape="long" rot="R90"/>
<text x="-30.226" y="-6.35" size="1.778" layer="25" ratio="10" rot="R90">&gt;NAME</text>
<text x="-16.637" y="-1.016" size="1.778" layer="27" ratio="10">&gt;VALUE</text>
</package>
</packages>
<symbols>
<symbol name="74245">
<wire x1="-7.62" y1="-15.24" x2="7.62" y2="-15.24" width="0.4064" layer="94"/>
<wire x1="7.62" y1="-15.24" x2="7.62" y2="15.24" width="0.4064" layer="94"/>
<wire x1="7.62" y1="15.24" x2="-7.62" y2="15.24" width="0.4064" layer="94"/>
<wire x1="-7.62" y1="15.24" x2="-7.62" y2="-15.24" width="0.4064" layer="94"/>
<text x="-7.62" y="15.875" size="1.778" layer="95">&gt;NAME</text>
<text x="-7.62" y="-17.78" size="1.778" layer="96">&gt;VALUE</text>
<pin name="DIR" x="-12.7" y="-10.16" length="middle" direction="in"/>
<pin name="A1" x="-12.7" y="12.7" length="middle"/>
<pin name="A2" x="-12.7" y="10.16" length="middle"/>
<pin name="A3" x="-12.7" y="7.62" length="middle"/>
<pin name="A4" x="-12.7" y="5.08" length="middle"/>
<pin name="A5" x="-12.7" y="2.54" length="middle"/>
<pin name="A6" x="-12.7" y="0" length="middle"/>
<pin name="A7" x="-12.7" y="-2.54" length="middle"/>
<pin name="A8" x="-12.7" y="-5.08" length="middle"/>
<pin name="B8" x="12.7" y="-5.08" length="middle" rot="R180"/>
<pin name="B7" x="12.7" y="-2.54" length="middle" rot="R180"/>
<pin name="B6" x="12.7" y="0" length="middle" rot="R180"/>
<pin name="B5" x="12.7" y="2.54" length="middle" rot="R180"/>
<pin name="B4" x="12.7" y="5.08" length="middle" rot="R180"/>
<pin name="B3" x="12.7" y="7.62" length="middle" rot="R180"/>
<pin name="B2" x="12.7" y="10.16" length="middle" rot="R180"/>
<pin name="B1" x="12.7" y="12.7" length="middle" rot="R180"/>
<pin name="G" x="-12.7" y="-12.7" length="middle" direction="in" function="dot"/>
</symbol>
<symbol name="PWRN">
<text x="-0.635" y="-0.635" size="1.778" layer="95">&gt;NAME</text>
<text x="1.905" y="-7.62" size="1.27" layer="95" rot="R90">GND</text>
<text x="1.905" y="5.08" size="1.27" layer="95" rot="R90">VCC</text>
<pin name="GND" x="0" y="-10.16" visible="pad" direction="pwr" rot="R90"/>
<pin name="VCC" x="0" y="10.16" visible="pad" direction="pwr" rot="R270"/>
</symbol>
<symbol name="CMODA7">
<pin name="PIO1" x="-38.1" y="17.78" length="middle"/>
<pin name="PIO2" x="-38.1" y="15.24" length="middle"/>
<pin name="PIO3" x="-38.1" y="12.7" length="middle"/>
<pin name="PIO4" x="-38.1" y="10.16" length="middle"/>
<pin name="PIO5" x="-38.1" y="7.62" length="middle"/>
<pin name="PIO6" x="-38.1" y="5.08" length="middle"/>
<pin name="PIO7" x="-38.1" y="2.54" length="middle"/>
<pin name="PIO8" x="-38.1" y="0" length="middle"/>
<pin name="PIO9" x="-38.1" y="-2.54" length="middle"/>
<pin name="PIO10" x="-38.1" y="-5.08" length="middle"/>
<pin name="PIO11" x="-38.1" y="-7.62" length="middle"/>
<pin name="PIO12" x="-38.1" y="-10.16" length="middle"/>
<pin name="PIO13" x="-38.1" y="-12.7" length="middle"/>
<pin name="PIO14" x="-38.1" y="-15.24" length="middle"/>
<pin name="PIO15" x="-38.1" y="-17.78" length="middle"/>
<pin name="PIO16" x="-38.1" y="-20.32" length="middle"/>
<pin name="PIO17" x="-38.1" y="-22.86" length="middle"/>
<pin name="PIO18" x="-38.1" y="-25.4" length="middle"/>
<pin name="PIO19" x="-38.1" y="-27.94" length="middle"/>
<pin name="PIO20" x="-38.1" y="-30.48" length="middle"/>
<pin name="PIO21" x="-38.1" y="-33.02" length="middle"/>
<pin name="PIO22" x="-38.1" y="-35.56" length="middle"/>
<pin name="PIO23" x="-38.1" y="-38.1" length="middle"/>
<pin name="VU" x="-38.1" y="-40.64" length="middle" direction="pwr"/>
<pin name="GND" x="-5.08" y="-40.64" length="middle" direction="pwr" rot="R180"/>
<pin name="PIO26" x="-5.08" y="-38.1" length="middle" rot="R180"/>
<pin name="PIO27" x="-5.08" y="-35.56" length="middle" rot="R180"/>
<pin name="PIO28" x="-5.08" y="-33.02" length="middle" rot="R180"/>
<pin name="PIO29" x="-5.08" y="-30.48" length="middle" rot="R180"/>
<pin name="PIO30" x="-5.08" y="-27.94" length="middle" rot="R180"/>
<pin name="PIO31" x="-5.08" y="-25.4" length="middle" rot="R180"/>
<pin name="PIO32" x="-5.08" y="-22.86" length="middle" rot="R180"/>
<pin name="PIO33" x="-5.08" y="-20.32" length="middle" rot="R180"/>
<pin name="PIO34" x="-5.08" y="-17.78" length="middle" rot="R180"/>
<pin name="PIO35" x="-5.08" y="-15.24" length="middle" rot="R180"/>
<pin name="PIO36" x="-5.08" y="-12.7" length="middle" rot="R180"/>
<pin name="PIO37" x="-5.08" y="-10.16" length="middle" rot="R180"/>
<pin name="PIO38" x="-5.08" y="-7.62" length="middle" rot="R180"/>
<pin name="PIO39" x="-5.08" y="-5.08" length="middle" rot="R180"/>
<pin name="PIO40" x="-5.08" y="-2.54" length="middle" rot="R180"/>
<pin name="PIO41" x="-5.08" y="0" length="middle" rot="R180"/>
<pin name="PIO42" x="-5.08" y="2.54" length="middle" rot="R180"/>
<pin name="PIO43" x="-5.08" y="5.08" length="middle" rot="R180"/>
<pin name="PIO44" x="-5.08" y="7.62" length="middle" rot="R180"/>
<pin name="PIO45" x="-5.08" y="10.16" length="middle" rot="R180"/>
<pin name="PIO46" x="-5.08" y="12.7" length="middle" rot="R180"/>
<pin name="PIO47" x="-5.08" y="15.24" length="middle" rot="R180"/>
<pin name="PIO48" x="-5.08" y="17.78" length="middle" rot="R180"/>
<wire x1="-33.02" y1="20.32" x2="-33.02" y2="-43.18" width="0.254" layer="94"/>
<wire x1="-33.02" y1="-43.18" x2="-10.16" y2="-43.18" width="0.254" layer="94"/>
<wire x1="-10.16" y1="-43.18" x2="-10.16" y2="20.32" width="0.254" layer="94"/>
<wire x1="-10.16" y1="20.32" x2="-33.02" y2="20.32" width="0.254" layer="94"/>
<text x="-30.48" y="22.86" size="1.778" layer="94">CMODA7</text>
</symbol>
</symbols>
<devicesets>
<deviceset name="74*245" prefix="IC">
<description>Octal &lt;b&gt;BUS TRANSCEIVER&lt;/b&gt;, 3-state</description>
<gates>
<gate name="A" symbol="74245" x="20.32" y="0"/>
<gate name="P" symbol="PWRN" x="-5.08" y="0" addlevel="request"/>
</gates>
<devices>
<device name="N" package="DIL20">
<connects>
<connect gate="A" pin="A1" pad="2"/>
<connect gate="A" pin="A2" pad="3"/>
<connect gate="A" pin="A3" pad="4"/>
<connect gate="A" pin="A4" pad="5"/>
<connect gate="A" pin="A5" pad="6"/>
<connect gate="A" pin="A6" pad="7"/>
<connect gate="A" pin="A7" pad="8"/>
<connect gate="A" pin="A8" pad="9"/>
<connect gate="A" pin="B1" pad="18"/>
<connect gate="A" pin="B2" pad="17"/>
<connect gate="A" pin="B3" pad="16"/>
<connect gate="A" pin="B4" pad="15"/>
<connect gate="A" pin="B5" pad="14"/>
<connect gate="A" pin="B6" pad="13"/>
<connect gate="A" pin="B7" pad="12"/>
<connect gate="A" pin="B8" pad="11"/>
<connect gate="A" pin="DIR" pad="1"/>
<connect gate="A" pin="G" pad="19"/>
<connect gate="P" pin="GND" pad="10"/>
<connect gate="P" pin="VCC" pad="20"/>
</connects>
<technologies>
<technology name="LS"/>
</technologies>
</device>
<device name="DW" package="SO20W">
<connects>
<connect gate="A" pin="A1" pad="2"/>
<connect gate="A" pin="A2" pad="3"/>
<connect gate="A" pin="A3" pad="4"/>
<connect gate="A" pin="A4" pad="5"/>
<connect gate="A" pin="A5" pad="6"/>
<connect gate="A" pin="A6" pad="7"/>
<connect gate="A" pin="A7" pad="8"/>
<connect gate="A" pin="A8" pad="9"/>
<connect gate="A" pin="B1" pad="18"/>
<connect gate="A" pin="B2" pad="17"/>
<connect gate="A" pin="B3" pad="16"/>
<connect gate="A" pin="B4" pad="15"/>
<connect gate="A" pin="B5" pad="14"/>
<connect gate="A" pin="B6" pad="13"/>
<connect gate="A" pin="B7" pad="12"/>
<connect gate="A" pin="B8" pad="11"/>
<connect gate="A" pin="DIR" pad="1"/>
<connect gate="A" pin="G" pad="19"/>
<connect gate="P" pin="GND" pad="10"/>
<connect gate="P" pin="VCC" pad="20"/>
</connects>
<technologies>
<technology name="LS"/>
</technologies>
</device>
<device name="FK" package="LCC20">
<connects>
<connect gate="A" pin="A1" pad="2"/>
<connect gate="A" pin="A2" pad="3"/>
<connect gate="A" pin="A3" pad="4"/>
<connect gate="A" pin="A4" pad="5"/>
<connect gate="A" pin="A5" pad="6"/>
<connect gate="A" pin="A6" pad="7"/>
<connect gate="A" pin="A7" pad="8"/>
<connect gate="A" pin="A8" pad="9"/>
<connect gate="A" pin="B1" pad="18"/>
<connect gate="A" pin="B2" pad="17"/>
<connect gate="A" pin="B3" pad="16"/>
<connect gate="A" pin="B4" pad="15"/>
<connect gate="A" pin="B5" pad="14"/>
<connect gate="A" pin="B6" pad="13"/>
<connect gate="A" pin="B7" pad="12"/>
<connect gate="A" pin="B8" pad="11"/>
<connect gate="A" pin="DIR" pad="1"/>
<connect gate="A" pin="G" pad="19"/>
<connect gate="P" pin="GND" pad="10"/>
<connect gate="P" pin="VCC" pad="20"/>
</connects>
<technologies>
<technology name="LS"/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="CMODA7">
<gates>
<gate name="G$1" symbol="CMODA7" x="20.32" y="10.16"/>
</gates>
<devices>
<device name="" package="DIL48">
<connects>
<connect gate="G$1" pin="GND" pad="25"/>
<connect gate="G$1" pin="PIO1" pad="1"/>
<connect gate="G$1" pin="PIO10" pad="10"/>
<connect gate="G$1" pin="PIO11" pad="11"/>
<connect gate="G$1" pin="PIO12" pad="12"/>
<connect gate="G$1" pin="PIO13" pad="13"/>
<connect gate="G$1" pin="PIO14" pad="14"/>
<connect gate="G$1" pin="PIO15" pad="15"/>
<connect gate="G$1" pin="PIO16" pad="16"/>
<connect gate="G$1" pin="PIO17" pad="17"/>
<connect gate="G$1" pin="PIO18" pad="18"/>
<connect gate="G$1" pin="PIO19" pad="19"/>
<connect gate="G$1" pin="PIO2" pad="2"/>
<connect gate="G$1" pin="PIO20" pad="20"/>
<connect gate="G$1" pin="PIO21" pad="21"/>
<connect gate="G$1" pin="PIO22" pad="22"/>
<connect gate="G$1" pin="PIO23" pad="23"/>
<connect gate="G$1" pin="PIO26" pad="26"/>
<connect gate="G$1" pin="PIO27" pad="27"/>
<connect gate="G$1" pin="PIO28" pad="28"/>
<connect gate="G$1" pin="PIO29" pad="29"/>
<connect gate="G$1" pin="PIO3" pad="3"/>
<connect gate="G$1" pin="PIO30" pad="30"/>
<connect gate="G$1" pin="PIO31" pad="31"/>
<connect gate="G$1" pin="PIO32" pad="32"/>
<connect gate="G$1" pin="PIO33" pad="33"/>
<connect gate="G$1" pin="PIO34" pad="34"/>
<connect gate="G$1" pin="PIO35" pad="35"/>
<connect gate="G$1" pin="PIO36" pad="36"/>
<connect gate="G$1" pin="PIO37" pad="37"/>
<connect gate="G$1" pin="PIO38" pad="38"/>
<connect gate="G$1" pin="PIO39" pad="39"/>
<connect gate="G$1" pin="PIO4" pad="4"/>
<connect gate="G$1" pin="PIO40" pad="40"/>
<connect gate="G$1" pin="PIO41" pad="41"/>
<connect gate="G$1" pin="PIO42" pad="42"/>
<connect gate="G$1" pin="PIO43" pad="43"/>
<connect gate="G$1" pin="PIO44" pad="44"/>
<connect gate="G$1" pin="PIO45" pad="45"/>
<connect gate="G$1" pin="PIO46" pad="46"/>
<connect gate="G$1" pin="PIO47" pad="47"/>
<connect gate="G$1" pin="PIO48" pad="48"/>
<connect gate="G$1" pin="PIO5" pad="5"/>
<connect gate="G$1" pin="PIO6" pad="6"/>
<connect gate="G$1" pin="PIO7" pad="7"/>
<connect gate="G$1" pin="PIO8" pad="8"/>
<connect gate="G$1" pin="PIO9" pad="9"/>
<connect gate="G$1" pin="VU" pad="24"/>
</connects>
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
</devicesets>
</library>
<library name="supply1">
<description>&lt;b&gt;Supply Symbols&lt;/b&gt;&lt;p&gt;
 GND, VCC, 0V, +5V, -5V, etc.&lt;p&gt;
 Please keep in mind, that these devices are necessary for the
 automatic wiring of the supply signals.&lt;p&gt;
 The pin name defined in the symbol is identical to the net which is to be wired automatically.&lt;p&gt;
 In this library the device names are the same as the pin names of the symbols, therefore the correct signal names appear next to the supply symbols in the schematic.&lt;p&gt;
 &lt;author&gt;Created by librarian@cadsoft.de&lt;/author&gt;</description>
<packages>
</packages>
<symbols>
<symbol name="GND">
<wire x1="-1.905" y1="0" x2="1.905" y2="0" width="0.254" layer="94"/>
<text x="-2.54" y="-2.54" size="1.778" layer="96">&gt;VALUE</text>
<pin name="GND" x="0" y="2.54" visible="off" length="short" direction="sup" rot="R270"/>
</symbol>
<symbol name="+3V3">
<wire x1="1.27" y1="-1.905" x2="0" y2="0" width="0.254" layer="94"/>
<wire x1="0" y1="0" x2="-1.27" y2="-1.905" width="0.254" layer="94"/>
<text x="-2.54" y="-5.08" size="1.778" layer="96" rot="R90">&gt;VALUE</text>
<pin name="+3V3" x="0" y="-2.54" visible="off" length="short" direction="sup" rot="R90"/>
</symbol>
</symbols>
<devicesets>
<deviceset name="GND" prefix="GND">
<description>&lt;b&gt;SUPPLY SYMBOL&lt;/b&gt;</description>
<gates>
<gate name="1" symbol="GND" x="0" y="0"/>
</gates>
<devices>
<device name="">
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
<deviceset name="+3V3" prefix="+3V3">
<description>&lt;b&gt;SUPPLY SYMBOL&lt;/b&gt;</description>
<gates>
<gate name="G$1" symbol="+3V3" x="0" y="0"/>
</gates>
<devices>
<device name="">
<technologies>
<technology name=""/>
</technologies>
</device>
</devices>
</deviceset>
</devicesets>
</library>
</libraries>
<attributes>
</attributes>
<variantdefs>
</variantdefs>
<classes>
<class number="0" name="default" width="0" drill="0">
</class>
</classes>
<parts>
<part name="U$1" library="65xxx" deviceset="CSG6567" device=""/>
<part name="IC1" library="FT74xx" deviceset="74*245" device="DW" technology="LS"/>
<part name="IC2" library="FT74xx" deviceset="74*245" device="DW" technology="LS"/>
<part name="IC3" library="FT74xx" deviceset="74*245" device="DW" technology="LS"/>
<part name="IC4" library="FT74xx" deviceset="74*245" device="DW" technology="LS"/>
<part name="U$2" library="FT74xx" deviceset="CMODA7" device=""/>
<part name="GND1" library="supply1" deviceset="GND" device=""/>
<part name="GND2" library="supply1" deviceset="GND" device=""/>
<part name="GND3" library="supply1" deviceset="GND" device=""/>
<part name="+3V1" library="supply1" deviceset="+3V3" device=""/>
</parts>
<sheets>
<sheet>
<plain>
<text x="111.76" y="35.56" size="1.778" layer="91">nc</text>
<text x="111.76" y="33.02" size="1.778" layer="91">nc</text>
<text x="91.44" y="73.66" size="1.778" layer="91">Header</text>
<text x="172.72" y="71.12" size="1.778" layer="91">Socket</text>
</plain>
<instances>
<instance part="U$1" gate="G$1" x="91.44" y="50.8"/>
<instance part="IC1" gate="A" x="0" y="58.42"/>
<instance part="IC2" gate="A" x="0" y="17.78"/>
<instance part="IC3" gate="A" x="0" y="-25.4"/>
<instance part="IC4" gate="A" x="0" y="-66.04"/>
<instance part="U$2" gate="G$1" x="190.5" y="48.26"/>
<instance part="GND1" gate="1" x="-12.7" y="40.64"/>
<instance part="GND2" gate="1" x="-12.7" y="-43.18"/>
<instance part="GND3" gate="1" x="-12.7" y="-83.82"/>
<instance part="+3V1" gate="G$1" x="-30.48" y="-30.48"/>
</instances>
<busses>
</busses>
<nets>
<net name="GND" class="0">
<segment>
<pinref part="IC1" gate="A" pin="G"/>
<pinref part="GND1" gate="1" pin="GND"/>
<wire x1="-12.7" y1="45.72" x2="-12.7" y2="43.18" width="0.1524" layer="91"/>
</segment>
<segment>
<pinref part="IC3" gate="A" pin="G"/>
<pinref part="GND2" gate="1" pin="GND"/>
<wire x1="-12.7" y1="-38.1" x2="-12.7" y2="-40.64" width="0.1524" layer="91"/>
</segment>
<segment>
<pinref part="IC4" gate="A" pin="G"/>
<pinref part="GND3" gate="1" pin="GND"/>
<wire x1="-12.7" y1="-78.74" x2="-12.7" y2="-81.28" width="0.1524" layer="91"/>
<pinref part="IC4" gate="A" pin="DIR"/>
<wire x1="-12.7" y1="-76.2" x2="-12.7" y2="-78.74" width="0.1524" layer="91"/>
<junction x="-12.7" y="-78.74"/>
</segment>
</net>
<net name="AEC" class="0">
<segment>
<pinref part="IC1" gate="A" pin="DIR"/>
<wire x1="-12.7" y1="48.26" x2="-20.32" y2="48.26" width="0.1524" layer="91"/>
<label x="-20.32" y="48.26" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA7" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A8"/>
<wire x1="-12.7" y1="53.34" x2="-20.32" y2="53.34" width="0.1524" layer="91"/>
<label x="-20.32" y="53.34" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A7"/>
<wire x1="73.66" y1="50.8" x2="66.04" y2="50.8" width="0.1524" layer="91"/>
<label x="66.04" y="50.8" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA6" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A7"/>
<wire x1="-12.7" y1="55.88" x2="-20.32" y2="55.88" width="0.1524" layer="91"/>
<label x="-20.32" y="55.88" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A6"/>
<wire x1="73.66" y1="53.34" x2="66.04" y2="53.34" width="0.1524" layer="91"/>
<label x="66.04" y="53.34" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA5" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A6"/>
<wire x1="-12.7" y1="58.42" x2="-20.32" y2="58.42" width="0.1524" layer="91"/>
<label x="-20.32" y="58.42" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A5/A13"/>
<wire x1="73.66" y1="55.88" x2="66.04" y2="55.88" width="0.1524" layer="91"/>
<label x="66.04" y="55.88" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA4" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A5"/>
<wire x1="-12.7" y1="60.96" x2="-20.32" y2="60.96" width="0.1524" layer="91"/>
<label x="-20.32" y="60.96" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A4/A12"/>
<wire x1="73.66" y1="58.42" x2="66.04" y2="58.42" width="0.1524" layer="91"/>
<label x="66.04" y="58.42" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA3" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A4"/>
<wire x1="-12.7" y1="63.5" x2="-20.32" y2="63.5" width="0.1524" layer="91"/>
<label x="-20.32" y="63.5" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A3/A11"/>
<wire x1="73.66" y1="60.96" x2="66.04" y2="60.96" width="0.1524" layer="91"/>
<label x="66.04" y="60.96" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA2" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A3"/>
<wire x1="-12.7" y1="66.04" x2="-20.32" y2="66.04" width="0.1524" layer="91"/>
<label x="-20.32" y="66.04" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A2/A10"/>
<wire x1="73.66" y1="63.5" x2="66.04" y2="63.5" width="0.1524" layer="91"/>
<label x="66.04" y="63.5" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA1" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A2"/>
<wire x1="-12.7" y1="68.58" x2="-20.32" y2="68.58" width="0.1524" layer="91"/>
<label x="-20.32" y="68.58" size="1.778" layer="95"/>
</segment>
<segment>
<wire x1="76.2" y1="66.04" x2="66.04" y2="66.04" width="0.1524" layer="91"/>
<label x="66.04" y="66.04" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA0" class="0">
<segment>
<pinref part="IC1" gate="A" pin="A1"/>
<wire x1="-12.7" y1="71.12" x2="-20.32" y2="71.12" width="0.1524" layer="91"/>
<label x="-20.32" y="71.12" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="A0/A8"/>
<wire x1="73.66" y1="68.58" x2="66.04" y2="68.58" width="0.1524" layer="91"/>
<label x="66.04" y="68.58" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD0" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A1"/>
<wire x1="-12.7" y1="30.48" x2="-20.32" y2="30.48" width="0.1524" layer="91"/>
<label x="-20.32" y="30.48" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D0"/>
<wire x1="109.22" y1="68.58" x2="116.84" y2="68.58" width="0.1524" layer="91"/>
<label x="114.3" y="68.58" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD1" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A2"/>
<wire x1="-12.7" y1="27.94" x2="-20.32" y2="27.94" width="0.1524" layer="91"/>
<label x="-20.32" y="27.94" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D1"/>
<wire x1="109.22" y1="66.04" x2="116.84" y2="66.04" width="0.1524" layer="91"/>
<label x="114.3" y="66.04" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD2" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A3"/>
<wire x1="-12.7" y1="25.4" x2="-20.32" y2="25.4" width="0.1524" layer="91"/>
<label x="-20.32" y="25.4" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D2"/>
<wire x1="109.22" y1="63.5" x2="116.84" y2="63.5" width="0.1524" layer="91"/>
<label x="114.3" y="63.5" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD3" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A4"/>
<wire x1="-12.7" y1="22.86" x2="-20.32" y2="22.86" width="0.1524" layer="91"/>
<label x="-20.32" y="22.86" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D3"/>
<wire x1="109.22" y1="60.96" x2="116.84" y2="60.96" width="0.1524" layer="91"/>
<label x="114.3" y="60.96" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD4" class="0">
<segment>
<wire x1="-10.16" y1="20.32" x2="-20.32" y2="20.32" width="0.1524" layer="91"/>
<label x="-20.32" y="20.32" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D4"/>
<wire x1="109.22" y1="58.42" x2="116.84" y2="58.42" width="0.1524" layer="91"/>
<label x="114.3" y="58.42" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD5" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A6"/>
<wire x1="-12.7" y1="17.78" x2="-20.32" y2="17.78" width="0.1524" layer="91"/>
<label x="-20.32" y="17.78" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D5"/>
<wire x1="109.22" y1="55.88" x2="116.84" y2="55.88" width="0.1524" layer="91"/>
<label x="114.3" y="55.88" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD6" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A7"/>
<wire x1="-12.7" y1="15.24" x2="-20.32" y2="15.24" width="0.1524" layer="91"/>
<label x="-20.32" y="15.24" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D6"/>
<wire x1="109.22" y1="53.34" x2="116.84" y2="53.34" width="0.1524" layer="91"/>
<label x="114.3" y="53.34" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD7" class="0">
<segment>
<pinref part="IC2" gate="A" pin="A8"/>
<wire x1="-12.7" y1="12.7" x2="-20.32" y2="12.7" width="0.1524" layer="91"/>
<label x="-20.32" y="12.7" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D7"/>
<wire x1="109.22" y1="50.8" x2="116.84" y2="50.8" width="0.1524" layer="91"/>
<label x="114.3" y="50.8" size="1.778" layer="95"/>
</segment>
</net>
<net name="DIR" class="0">
<segment>
<pinref part="IC2" gate="A" pin="DIR"/>
<wire x1="-12.7" y1="7.62" x2="-20.32" y2="7.62" width="0.1524" layer="91"/>
<label x="-20.32" y="7.62" size="1.778" layer="95"/>
</segment>
</net>
<net name="DEN" class="0">
<segment>
<pinref part="IC2" gate="A" pin="G"/>
<wire x1="-12.7" y1="5.08" x2="-20.32" y2="5.08" width="0.1524" layer="91"/>
<label x="-20.32" y="5.08" size="1.778" layer="95"/>
</segment>
</net>
<net name="N$9" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B1"/>
<wire x1="12.7" y1="30.48" x2="20.32" y2="30.48" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$10" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B2"/>
<wire x1="12.7" y1="27.94" x2="20.32" y2="27.94" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$11" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B3"/>
<wire x1="12.7" y1="25.4" x2="20.32" y2="25.4" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$12" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B4"/>
<wire x1="12.7" y1="22.86" x2="20.32" y2="22.86" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$13" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B5"/>
<wire x1="12.7" y1="20.32" x2="20.32" y2="20.32" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$14" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B6"/>
<wire x1="12.7" y1="17.78" x2="20.32" y2="17.78" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$15" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B7"/>
<wire x1="12.7" y1="15.24" x2="20.32" y2="15.24" width="0.1524" layer="91"/>
</segment>
</net>
<net name="N$16" class="0">
<segment>
<pinref part="IC2" gate="A" pin="B8"/>
<wire x1="12.7" y1="12.7" x2="20.32" y2="12.7" width="0.1524" layer="91"/>
</segment>
</net>
<net name="VD8" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A1"/>
<wire x1="-12.7" y1="-12.7" x2="-20.32" y2="-12.7" width="0.1524" layer="91"/>
<label x="-20.32" y="-12.7" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D8"/>
<wire x1="109.22" y1="48.26" x2="116.84" y2="48.26" width="0.1524" layer="91"/>
<label x="114.3" y="48.26" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD9" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A2"/>
<wire x1="-12.7" y1="-15.24" x2="-20.32" y2="-15.24" width="0.1524" layer="91"/>
<label x="-20.32" y="-15.24" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D9"/>
<wire x1="109.22" y1="45.72" x2="116.84" y2="45.72" width="0.1524" layer="91"/>
<label x="114.3" y="45.72" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD10" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A3"/>
<wire x1="-12.7" y1="-17.78" x2="-20.32" y2="-17.78" width="0.1524" layer="91"/>
<label x="-20.32" y="-17.78" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D10"/>
<wire x1="109.22" y1="43.18" x2="116.84" y2="43.18" width="0.1524" layer="91"/>
<label x="114.3" y="43.18" size="1.778" layer="95"/>
</segment>
</net>
<net name="VD11" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A4"/>
<wire x1="-12.7" y1="-20.32" x2="-20.32" y2="-20.32" width="0.1524" layer="91"/>
<label x="-20.32" y="-20.32" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="D11"/>
<wire x1="109.22" y1="40.64" x2="116.84" y2="40.64" width="0.1524" layer="91"/>
<label x="114.3" y="40.64" size="1.778" layer="95"/>
</segment>
</net>
<net name="+3V3" class="0">
<segment>
<pinref part="IC3" gate="A" pin="DIR"/>
<wire x1="-12.7" y1="-35.56" x2="-30.48" y2="-35.56" width="0.1524" layer="91"/>
<wire x1="-30.48" y1="-35.56" x2="-30.48" y2="-33.02" width="0.1524" layer="91"/>
<pinref part="+3V1" gate="G$1" pin="+3V3"/>
</segment>
</net>
<net name="VCSB" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A5"/>
<wire x1="-12.7" y1="-22.86" x2="-20.32" y2="-22.86" width="0.1524" layer="91"/>
<label x="-20.32" y="-22.86" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="CSB"/>
<wire x1="73.66" y1="35.56" x2="66.04" y2="35.56" width="0.1524" layer="91"/>
<label x="66.04" y="35.56" size="1.778" layer="95"/>
</segment>
</net>
<net name="VRWB" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A6"/>
<wire x1="-12.7" y1="-25.4" x2="-20.32" y2="-25.4" width="0.1524" layer="91"/>
<label x="-20.32" y="-25.4" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="R/WB"/>
<wire x1="73.66" y1="22.86" x2="66.04" y2="22.86" width="0.1524" layer="91"/>
<label x="66.04" y="22.86" size="1.778" layer="95"/>
</segment>
</net>
<net name="VLPB" class="0">
<segment>
<pinref part="IC3" gate="A" pin="A7"/>
<wire x1="-12.7" y1="-27.94" x2="-20.32" y2="-27.94" width="0.1524" layer="91"/>
<label x="-20.32" y="-27.94" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="LPB"/>
<wire x1="73.66" y1="15.24" x2="66.04" y2="15.24" width="0.1524" layer="91"/>
<label x="66.04" y="15.24" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA8" class="0">
<segment>
<pinref part="U$1" gate="G$1" pin="A8"/>
<wire x1="73.66" y1="48.26" x2="66.04" y2="48.26" width="0.1524" layer="91"/>
<label x="66.04" y="48.26" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="IC4" gate="A" pin="A1"/>
<wire x1="-12.7" y1="-53.34" x2="-20.32" y2="-53.34" width="0.1524" layer="91"/>
<label x="-20.32" y="-53.34" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA9" class="0">
<segment>
<pinref part="U$1" gate="G$1" pin="A9"/>
<wire x1="73.66" y1="45.72" x2="66.04" y2="45.72" width="0.1524" layer="91"/>
<label x="66.04" y="45.72" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="IC4" gate="A" pin="A2"/>
<wire x1="-12.7" y1="-55.88" x2="-20.32" y2="-55.88" width="0.1524" layer="91"/>
<label x="-20.32" y="-55.88" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA10" class="0">
<segment>
<pinref part="U$1" gate="G$1" pin="A10"/>
<wire x1="73.66" y1="43.18" x2="66.04" y2="43.18" width="0.1524" layer="91"/>
<label x="66.04" y="43.18" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="IC4" gate="A" pin="A3"/>
<wire x1="-12.7" y1="-58.42" x2="-20.32" y2="-58.42" width="0.1524" layer="91"/>
<label x="-20.32" y="-58.42" size="1.778" layer="95"/>
</segment>
</net>
<net name="VA11" class="0">
<segment>
<pinref part="U$1" gate="G$1" pin="A11"/>
<wire x1="73.66" y1="40.64" x2="66.04" y2="40.64" width="0.1524" layer="91"/>
<label x="66.04" y="40.64" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="IC4" gate="A" pin="A4"/>
<wire x1="-12.7" y1="-60.96" x2="-20.32" y2="-60.96" width="0.1524" layer="91"/>
<label x="-20.32" y="-60.96" size="1.778" layer="95"/>
</segment>
</net>
<net name="VAEC" class="0">
<segment>
<pinref part="IC4" gate="A" pin="A5"/>
<wire x1="-12.7" y1="-63.5" x2="-20.32" y2="-63.5" width="0.1524" layer="91"/>
<label x="-20.32" y="-63.5" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="AEC"/>
<wire x1="73.66" y1="33.02" x2="66.04" y2="33.02" width="0.1524" layer="91"/>
<label x="66.04" y="33.02" size="1.778" layer="95"/>
</segment>
</net>
<net name="VBA" class="0">
<segment>
<pinref part="IC4" gate="A" pin="A6"/>
<wire x1="-12.7" y1="-66.04" x2="-20.32" y2="-66.04" width="0.1524" layer="91"/>
<label x="-20.32" y="-66.04" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="BA"/>
<wire x1="73.66" y1="30.48" x2="66.04" y2="30.48" width="0.1524" layer="91"/>
<label x="66.04" y="30.48" size="1.778" layer="95"/>
</segment>
</net>
<net name="VRAS" class="0">
<segment>
<pinref part="IC4" gate="A" pin="A7"/>
<wire x1="-12.7" y1="-68.58" x2="-20.32" y2="-68.58" width="0.1524" layer="91"/>
<label x="-20.32" y="-68.58" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="RASB"/>
<wire x1="73.66" y1="27.94" x2="66.04" y2="27.94" width="0.1524" layer="91"/>
<label x="66.04" y="27.94" size="1.778" layer="95"/>
</segment>
</net>
<net name="VCAS" class="0">
<segment>
<pinref part="IC4" gate="A" pin="A8"/>
<wire x1="-12.7" y1="-71.12" x2="-20.32" y2="-71.12" width="0.1524" layer="91"/>
<label x="-20.32" y="-71.12" size="1.778" layer="95"/>
</segment>
<segment>
<pinref part="U$1" gate="G$1" pin="CASB"/>
<wire x1="73.66" y1="25.4" x2="66.04" y2="25.4" width="0.1524" layer="91"/>
<label x="66.04" y="25.4" size="1.778" layer="95"/>
</segment>
</net>
</nets>
</sheet>
</sheets>
</schematic>
</drawing>
</eagle>
