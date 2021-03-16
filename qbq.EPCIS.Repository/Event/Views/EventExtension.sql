-----------------------------------------------------------------------------------------
-- Projekt:  EPCIS
-- Firma:    QUIBIQ
-- (c) 2013  QUIBIQ Schweiz AG
-----------------------------------------------------------------------------------------
--
-- 
-- 
-- Datum      | Version | Autor               | Kommentar
--------------|---------|---------------------|------------------------------------------
-- 10.07.2013 | 1.0.0.0 | Florian Wagner      | Erstellt.
-----------------------------------------------------------------------------------------
CREATE VIEW [Event].[EventExtension]
WITH SCHEMABINDING
AS
with 
  recur as (
		select 
			 vv.URN as Name
			,CAST(N'' as nvarchar(512))    as Parent
			,0      as Depth
			,v.ID   as ID
			,v.DataTypeID as DataTypeID
			,v.EPCISEventID 
		from [Event].[EPCISEvent_Value] v
		join [Vocabulary].[Vocabulary]  vv on v.ValueTypeID = vv.ID
		join [Vocabulary].[VocabularyType] vt on vv.VocabularyTypeID = vt.ID
		where not exists (
			select 1 from [Event].[EPCISEvent_Value_Hierarchy] 
				where EPCISEvent_ValueID = v.ID
			)
		and vt.URN = N'urn:quibiq:epcis:vtype:extensiontype'
		UNION ALL		
		select 
			 vv.URN  as Name
			,r.Name  as Parent
			,Depth+1 as Depth
			,v.ID    as ID
			,v.DataTypeID as DataTypeID
			,v.EPCISEventID
		from recur r
		join [Event].[EPCISEvent_Value_Hierarchy] h on h.Parent_EPCISEvent_ValueID = r.ID 
		join [Event].[EPCISEvent_Value] v on v.ID = h.EPCISEvent_ValueID
		join [Vocabulary].[Vocabulary]  vv on v.ValueTypeID = vv.ID
), value as (
		select 
			 r.EPCISEventID
			,r.Name
			,r.Parent
			,r.Depth
			,r.ID
			,vs.Value
			,CASE v.URN 
			  WHEN N'urn:quibiq:epcis:cbv:datatype:xml' THEN 1
			  ELSE 0
			 END AS IsXMLNode
		from recur r
		left join [Event].[EPCISEvent_Value_String]  evs on evs.EPCISEvent_ValueID = r.ID
		left join [Event].[Value_String]  vs on vs.ID = evs.Value_StringID
		join [Vocabulary].Vocabulary v on r.DataTypeID = v.ID
)
select
	EPCISEventID,
	Name,
	Parent,
	Depth,
	IsXMLNode,
	Value
from value v
