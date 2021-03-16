using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using qbq.EPCIS.EF.Repository;
using qbq.EPCIS.Repository.Custom.Entities;

namespace qbq.EPCIS.Repository.Custom.Business
{
    public class EventImporter
    {
        private const bool AddNewVocabulary = false;
        private const bool AddBizLocAndReadPoints = true;
        private const bool AddEpcClass = true;
        private const bool AddSourceDestination = true;
        private const bool ProcessOnlyWholeDocument = true;
        
        private const string ClientRepository = "urn:quibiq:epcis:cbv:client:epcisrepository";
        private const string VTypeClient = "urn:quibiq:epcis:vtype:client";

        private readonly List<EventData> _eventData = new List<EventData>();
        private readonly List<EpcisEventIds> _epcisEventIds = new List<EpcisEventIds>();
        private readonly List<EpcisEventVocabulary> _epcisEventVocabulary = new List<EpcisEventVocabulary>();
        private readonly List<EpcisEventEpc> _epcisEventEpc = new List<EpcisEventEpc>();
        private readonly List<EpcisEventBusinessTransactionId> _epcisEventBusinessTransactionId = new List<EpcisEventBusinessTransactionId>();
        private readonly List<EpcisEventQuantityElement> _epcisEventQuantityElement = new List<EpcisEventQuantityElement>();
        private readonly List<EpcisEventSourceDestination> _epcisEventSourceDestination = new List<EpcisEventSourceDestination>();
        private readonly List<EpcisEventTransformationId> _epcisEventTransformationId = new List<EpcisEventTransformationId>();
        private readonly List<EpcisEventExtenstionType> _epcisEventExtenstionType = new List<EpcisEventExtenstionType>();
        private readonly List<EpcisEventValue> _epcisEventValue = new List<EpcisEventValue>();
        private readonly List<EpcisEventValueValues> _epcisEventValueValues = new List<EpcisEventValueValues>();
        private readonly List<EpcisEventError> _epcisEventError = new List<EpcisEventError>();
        //private readonly List<EpcisEventValueStringValueString> _epcisEventValueStringValueString = new List<EpcisEventValueStringValueString>();

        public void ImportEvents(XDocument xEpcisEventDoc, string client)
        {
            using (var db = new RepositoryContext())
            {
                //Determine the client ID
                
                var vocabularyType = db.VocabularyType.Where(vt => vt.URN == VTypeClient);

                var vocabulary = db.Vocabulary.Where(v => v.URN == client)
                    .Join(vocabularyType, v => v.VocabularyTypeID, vt => vt.ID, (v, vt) => v);

                var sysVocabulary = db.Vocabulary.Where(v => v.URN == ClientRepository)
                    .Join(vocabularyType, syc => syc.VocabularyTypeID, svt => svt.ID, (syc, svt)=> syc);

                var clientIdsQuery = vocabulary
                    .Join(sysVocabulary, v => v.ClientID, syc => syc.ID, (v, syc) => new {ClientId = v.ID, SystemClientID = syc.ID});

                var clientIds = clientIdsQuery.FirstOrDefault();

                if (clientIds == null)
                {
                    throw new Exception("Mandant '" + client + "' does not exist.");
                }

                var clientId = clientIds.ClientId;
                var systemClientId = clientIds.SystemClientID;

                var standardBusinessDocumentHeader = xEpcisEventDoc.Root?.XPathSelectElement("./EPCISHeader");
                
                var xEpcisEventList = xEpcisEventDoc.Root?.XPathSelectElement("./EPCISBody/EventList");

                var _xEpcisEventList = xEpcisEventList?.Elements().ToList();

                if (_xEpcisEventList == null || !_xEpcisEventList.Any())
                {
	                return;
                }
                
                // iterate over all events in the event list

                foreach (var _xEpcisEvent in _xEpcisEventList)
                {
	                var xEpcisEvent = _xEpcisEvent.Name.LocalName == "extension" 
		                ? _xEpcisEvent.Elements().FirstOrDefault() 
		                : _xEpcisEvent;

	                if (xEpcisEvent == null)
	                {
		                continue;
	                }

	                var eventName = xEpcisEvent.Name.LocalName;

	                var xElement = xEpcisEvent.XPathSelectElement("./eventTime");
	                var eventTime = DateTimeOffset.Parse(xElement?.Value).DateTime;
	                
	                xElement = xEpcisEvent.XPathSelectElement("./eventTimeZoneOffset");
	                var eventTimeZoneOffset = DateTimeOffset.Parse(DateTime.Now + xElement?.Value);
	                var recordTime = DateTime.UtcNow;
	                
	                //Save single event

	                long epcisEventId = 1;
	                if (_eventData.Any())
	                {
		                epcisEventId = _eventData.Max(x => x.EpcisEventId) + 1;
	                }
	                
	                _eventData.Add(new EventData
	                {
		                EpcisEventId = epcisEventId,
		                ClientId = clientId,
		                EventTime = eventTime,
		                RecordTime = recordTime,
		                EventTimeZoneOffset = eventTimeZoneOffset,
		                EpcisRepresentation = xEpcisEvent.ToString(),
	                });
	                
	                _epcisEventVocabulary.Add(new EpcisEventVocabulary
	                {
		                VocabularyTypeUrn = "urn:quibiq:epcis:vtype:event",
		                VocabularyUrn = "urn:quibiq:epcis:cbv:event:" + xEpcisEvent?.Name.LocalName.ToLower().Replace("event", string.Empty).RemoveBlanks(),
		                EpcisEventId = epcisEventId,
	                });
	                
	                //EPCList
					
	                xElement = xEpcisEvent.XPathSelectElement("./epcList");

	                if (xElement != null)
	                {
		                foreach (var xEpc in xElement.Elements())
		                {
			                _epcisEventEpc.Add(new EpcisEventEpc
			                {
				                EpcUrn = xEpc.Value.RemoveBlanks(),
				                EpcisEventId = epcisEventId,
				                IsParent = false,
				                IsInput = false,
				                IsOutput = false,
			                });
		                }
	                }
	                
	                // IsParent
	                
	                xElement = xEpcisEvent.XPathSelectElement("./parentID");

	                if (xElement != null)
	                {
		                _epcisEventEpc.Add(new EpcisEventEpc
		                {
			                EpcisEventId = epcisEventId,
			                EpcUrn = xElement.Value.RemoveBlanks(),
			                IsParent = true,
			                IsInput = false,
			                IsOutput = false,
		                });
	                }
	                
	                
	                //IsInput

	                xElement = xEpcisEvent.XPathSelectElement("./inputEPCList");

	                if (xElement != null)
	                {
		                foreach (var xEpc in xElement.Elements())
		                {
			                _epcisEventEpc.Add(new EpcisEventEpc
			                {
				                EpcUrn = xEpc.Value.RemoveBlanks(),
				                EpcisEventId = epcisEventId,
				                IsParent = false,
				                IsInput = true,
				                IsOutput = false,
			                });
		                }
	                }
	                
	                //IsOutput

	                xElement = xEpcisEvent.XPathSelectElement("./outputEPCList");

	                if (xElement != null)
	                {
		                foreach (var xEpc in xElement.Elements())
		                {
			                _epcisEventEpc.Add(new EpcisEventEpc
			                {
				                EpcUrn = xEpc.Value.RemoveBlanks(),
				                EpcisEventId = epcisEventId,
				                IsParent = false,
				                IsInput = false,
				                IsOutput = true,
			                });
		                }
	                }
	                
	                //childEPCs
	                
	                xElement = xEpcisEvent.XPathSelectElement("./childEPCs");

	                if (xElement != null)
	                {
		                foreach (var xEpc in xElement.Elements())
		                {
							_epcisEventEpc.Add(new EpcisEventEpc
							{
								EpcisEventId = epcisEventId,
								EpcUrn = xEpc.Value.RemoveBlanks(),
								IsParent = false,
								IsInput = false,
								IsOutput = false,
							});
		                }
	                }	                
		               
	                //bizTransactionList
		               
	                xElement = xEpcisEvent.XPathSelectElement("./bizTransactionList");

					if (xElement != null)
					{
					   foreach (var xBizTransaction in xElement.Elements())
					   {
							_epcisEventBusinessTransactionId.Add(new EpcisEventBusinessTransactionId
							{
								BusinessTransactionIdUrn = xBizTransaction.Value.RemoveBlanks(),
								BusinessTransactionTypeUrn = xBizTransaction.Attribute("type")?.Value.RemoveBlanks(),
								VocabularyTypeUrn = "urn:epcglobal:epcis:vtype:BusinessTransactionType",
								EpcisEventId = epcisEventId,
							});
					   }
					}
					
					//Action
					
					xElement = xEpcisEvent?.XPathSelectElement("./action");

					if (xElement != null)
					{
						_epcisEventVocabulary.Add(new EpcisEventVocabulary
						{
							VocabularyTypeUrn = "urn:quibiq:epcis:vtype:action",
							VocabularyUrn = "urn:quibiq:epcis:cbv:action:" + xElement.Value.RemoveBlanks().ToLower(),
							EpcisEventId = epcisEventId,
						});
							
					}
					
					//TransformationID EPCIS 1.1
					
					xElement = xEpcisEvent.XPathSelectElement("./transformationID");

					if (xElement != null)
					{
						_epcisEventTransformationId.Add(new EpcisEventTransformationId
						{
							TransformationIdUrn = xElement.Value.RemoveBlanks(),
							EpcisEventId = epcisEventId,
						});
					}
					
					//Quantity EPCIS 1.0
					
					xElement = xEpcisEvent.XPathSelectElement("./quantity");

					if (xElement != null && int.TryParse(xElement.Value, out var quantity))
					{
						_epcisEventValue.Add(new EpcisEventValue
						{
							ValueTypeTypeUrn = "urn:quibiq:epcis:vtype:valuetype",
							ValueTypeUrn = "urn:quibiq:epcis:cbv:valuetype:quantity",
							DataTypeTypeUrn = "urn:quibiq:epcis:vtype:datatype",
							DataTypeUrn = "urn:quibiq:epcis:cbv:datatype:int",
							IntValue = quantity,
							FloatValue = quantity,
							EpcisEventId = epcisEventId,
							ExtensionType = false,
							ParentUrn = string.Empty,
							Depth = 0,
						});
					}
					
					//Quantity EPCIS 1.1

					switch (eventName)
					{
						case  "TransformationEvent" :
							
							xElement = xEpcisEvent.XPathSelectElement("./outputQuantityList");
							
							if (xElement != null)
							{
								foreach (var xQuantityElement in xElement.Elements())
								{
									var epcClass = xQuantityElement.XPathSelectElement("./epcClass")?.Value.RemoveBlanks();
									float.TryParse(xQuantityElement.XPathSelectElement("./quantity")?.Value, out var floatQuantity);
									var uom = xQuantityElement.XPathSelectElement("./uom")?.Value.RemoveBlanks();
									
									_epcisEventQuantityElement.Add(new EpcisEventQuantityElement
									{
										EpcisEventId = epcisEventId,
										IsInput = false,
										IsOutput = true,
										EpcClassUrn = epcClass,
										Quantity = floatQuantity,
										Uom = uom
									});
								}
							}
							
							xElement = xEpcisEvent.XPathSelectElement("./inputQuantityList");
							
							if (xElement != null)
							{
								foreach (var xQuantityElement in xElement.Elements())
								{
									var epcClass = xQuantityElement.XPathSelectElement("./epcClass")?.Value.RemoveBlanks();
									float.TryParse(xQuantityElement.XPathSelectElement("./quantity")?.Value, out var floatQuantity);
									var uom = xQuantityElement.XPathSelectElement("./uom")?.Value.RemoveBlanks();
									
									_epcisEventQuantityElement.Add(new EpcisEventQuantityElement
									{
										EpcisEventId = epcisEventId,
										IsInput = true,
										IsOutput = false,
										EpcClassUrn = epcClass,
										Quantity = floatQuantity,
										Uom = uom
									});
								}
							}							
							
							break;
						
						case  "AggregationEvent" :
							
							xElement = xEpcisEvent.XPathSelectElement("./extension/childQuantityList");
							
							if (xElement != null)
							{
								foreach (var xQuantityElement in xElement.Elements())
								{
									var epcClass = xQuantityElement.XPathSelectElement("./epcClass")?.Value.RemoveBlanks();
									float.TryParse(xQuantityElement.XPathSelectElement("./quantity")?.Value, out var floatQuantity);
									var uom = xQuantityElement.XPathSelectElement("./uom")?.Value.RemoveBlanks();
									
									_epcisEventQuantityElement.Add(new EpcisEventQuantityElement
									{
										EpcisEventId = epcisEventId,
										IsInput = false,
										IsOutput = false,
										EpcClassUrn = epcClass,
										Quantity = floatQuantity,
										Uom = uom
									});
								}
							}
							
							break;
						
						default:
							
							xElement = xEpcisEvent.XPathSelectElement("./extension/quantityList");
							
							if (xElement != null)
							{
								foreach (var xQuantityElement in xElement.Elements())
								{
									var epcClass = xQuantityElement.XPathSelectElement("./epcClass")?.Value.RemoveBlanks();
									float.TryParse(xQuantityElement.XPathSelectElement("./quantity")?.Value, out var floatQuantity);
									var uom = xQuantityElement.XPathSelectElement("./uom")?.Value.RemoveBlanks();
									
									_epcisEventQuantityElement.Add(new EpcisEventQuantityElement
									{
										EpcisEventId = epcisEventId,
										IsInput = false,
										IsOutput = false,
										EpcClassUrn = epcClass,
										Quantity = floatQuantity,
										Uom = uom
									});
								}
							} 
							break;
					}
					
					//SourceDestination

					xElement = xEpcisEvent.XPathSelectElement(eventName == "TransformationEvent" ? "./sourceList" : "./extension/sourceList");

					if (xElement != null)
					{
						foreach (var xSource in xElement.Elements())
						{
							_epcisEventSourceDestination.Add(new EpcisEventSourceDestination
							{
								EpcisEventId = epcisEventId,
								IsSource = true,
								SourceDestinationUrn = xSource.Value.RemoveBlanks(),
								SourceDestinationTypeUrn = xSource.Attribute("type")?.Value.RemoveBlanks(),
							});
						}
					}
					
					xElement = xEpcisEvent.XPathSelectElement(eventName == "TransformationEvent" ? "./destinationList" : "./extension/destinationList");

					if (xElement != null)
					{
						foreach (var xDestination in xElement.Elements())
						{
							_epcisEventSourceDestination.Add(new EpcisEventSourceDestination
							{
								EpcisEventId = epcisEventId,
								IsSource = false,
								SourceDestinationUrn = xDestination.Value.RemoveBlanks(),
								SourceDestinationTypeUrn = xDestination.Attribute("type")?.Value.RemoveBlanks(),
							});
						}
					}
					
					//todo implement skipped baseExtension
					
					
					//ILMD Extension Fields
					
					xElement = xEpcisEvent.XPathSelectElement(eventName == "TransformationEvent" ? "./ilmd" : "./extension/ilmd");

					if (xElement != null)
					{
						foreach (var xIlmd in xElement.Elements())
						{
							int.TryParse(xIlmd.Value, out var intValue);
							float.TryParse(xIlmd.Value, out var floatValue);
							DateTimeOffset.TryParse(xIlmd.Value, out var timeValue);
							var stringValue = xIlmd.Value;
							
							_epcisEventValue.Add(new EpcisEventValue
							{
								EpcisEventId = epcisEventId,
								ValueTypeTypeUrn = "urn:quibiq:epcis:vtype:ilmd",
								ValueTypeUrn = xIlmd.Name.NamespaceName + '#' + xIlmd.Name.LocalName,
								DataTypeTypeUrn = "urn:quibiq:epcis:vtype:datatype",
								DataTypeUrn = GetDataTypeUrn(intValue, floatValue, timeValue.DateTime, stringValue),
								IntValue = intValue,
								FloatValue = floatValue,
								TimeValue = timeValue,
								StringValue = stringValue,
								ParentUrn = string.Empty,
								Depth = 0,
								ExtensionType = true,
							});
						}
					}
					
					// EPCClass
					
					xElement = xEpcisEvent.XPathSelectElement("./epcClass");

					if (xElement != null)
					{
						_epcisEventVocabulary.Add(new EpcisEventVocabulary
						{
							VocabularyTypeUrn = "urn:epcglobal:epcis:vtype:EPCClass",
							VocabularyUrn = xElement.Value.RemoveBlanks(),
							EpcisEventId = epcisEventId,
						});
					}
					
					// Bizstep
					
					xElement = xEpcisEvent.XPathSelectElement("./bizStep");

					if (xElement != null)
					{
						_epcisEventVocabulary.Add(new EpcisEventVocabulary
						{
							VocabularyTypeUrn = "urn:epcglobal:epcis:vtype:BusinessStep",
							VocabularyUrn = xElement.Value.RemoveBlanks(),
							EpcisEventId = epcisEventId,
						});
					}
					
					// Disposition
					
					xElement = xEpcisEvent.XPathSelectElement("./disposition");

					if (xElement != null)
					{
						_epcisEventVocabulary.Add(new EpcisEventVocabulary
						{
							VocabularyTypeUrn = "urn:epcglobal:epcis:vtype:Disposition",
							VocabularyUrn = xElement.Value.RemoveBlanks(),
							EpcisEventId = epcisEventId,
						});
					}
					
					// Readpoint
					
					xElement = xEpcisEvent.XPathSelectElement("./readPoint");

					if (xElement != null)
					{
						foreach (var xId in xElement.Elements())
						{
							_epcisEventVocabulary.Add(new EpcisEventVocabulary
							{
								VocabularyTypeUrn = "urn:epcglobal:epcis:vtype:ReadPoint",
								VocabularyUrn = xId.Value.RemoveBlanks(),
								EpcisEventId = epcisEventId,
							});
						}
					}
					
					// bizLocation
					
					xElement = xEpcisEvent.XPathSelectElement("./bizLocation");

					if (xElement != null)
					{
						foreach (var xId in xElement.Elements())
						{
							_epcisEventVocabulary.Add(new EpcisEventVocabulary
							{
								VocabularyTypeUrn = "urn:epcglobal:epcis:vtype:BusinessLocation",
								VocabularyUrn = xId.Value.RemoveBlanks(),
								EpcisEventId = epcisEventId,
							});
						}
					}
                }
                
				//***************************************************************
				// Prüfung auf vorhandene VocabularyTypes
				// Check for existing VocabularyTypes
				//***************************************************************
				{
					var vocabularyTypeClient = db.VocabularyType_Client
						.Where(vtc => (vtc.ClientID == clientId || vtc.ClientID == systemClientId) && !vtc.Deleted);

					var vocabularyTypes = db.VocabularyType
						.Join(vocabularyTypeClient,
							vt => vt.ID,
							vtc => vtc.VocabularyTypeID,
							(vt, vtc) => new {Id = vt.ID, Urn = vt.URN});

					var matchedItems = _epcisEventVocabulary
						.Join(vocabularyTypes,
							target => target.VocabularyTypeUrn,
							source => source.Urn,
							(target, source) => new {source, target});

					foreach (var matched in matchedItems)
					{
						matched.target.VocabularyTypeId = matched.source.Id;
					}
				}

				// Falls Vokabeltyp nicht vorhanden, dann werden die betroffenen Events mit Begründung markiert
                // If the vocabulary type does not exist, the affected events are marked with a reason
                
                _epcisEventError.AddRange(_epcisEventVocabulary
	                .Where(x => x.VocabularyTypeId == 0)
	                .Select(x => new EpcisEventError
	                {
		                EpcisEventId = x.EpcisEventId,
		                Reason = $"Vokabeltyp für '{x.VocabularyUrn}' nicht in Stammdaten (oder logisch geloescht). Fehlender Typ: '{x.VocabularyTypeUrn}'",
	                })
                );
                
                //***************************************************************
	            // Prüfung auf vorhandenes Vocabulary
	            // Check for existing vocabulary
	            //***************************************************************

	            // Nur BizLocation und ReadPoints hinzufügen
                //Add only BizLocation and ReadPoints
                if (AddBizLocAndReadPoints && !AddNewVocabulary)
                {
	                var source = _epcisEventVocabulary
		                .Where(x => x.VocabularyTypeUrn == "urn:epcglobal:epcis:vtype:BusinessLocation" || x.VocabularyTypeUrn == "urn:epcglobal:epcis:vtype:ReadPoint")
		                .Select(x => new {x.VocabularyUrn, x.VocabularyTypeId})
		                .Distinct()
		                .ToList();

	                var notMatched = source
		                .Where(src =>
			                !db.Vocabulary.Any(tgt =>
				                tgt.URN == src.VocabularyUrn &&
				                tgt.VocabularyTypeID == src.VocabularyTypeId &&
				                tgt.ClientID == clientId))
		                .Select(src =>
			                new Vocabulary
			                {
				                URN = src.VocabularyUrn,
				                VocabularyTypeID = src.VocabularyTypeId,
				                ClientID = clientId,
			                });

	                db.Vocabulary.AddRange(notMatched);

	                var matched = source
		                .Join(db.Vocabulary.Where(x => x.ClientID == clientId && x.Deleted),
			                src => new
			                {
				                URN = src.VocabularyUrn,
				                ID = src.VocabularyTypeId
			                },
			                tgt => new
			                {
				                URN = tgt.URN,
				                ID = tgt.VocabularyTypeID
			                },
			                (src, tgt) => tgt);

	                foreach (var item in matched)
	                {
		                item.Deleted = false;
	                }
                }
                
                // Nur EPCClass hinzufügen
                // Just add EPCClass
                
                var epcisClassTypeId = db.VocabularyType
	                .Join(db.VocabularyType_Client, 
		                vt => vt.ID, 
		                vtc => vtc.VocabularyTypeID, 
		                (vt, vct) => new {vt.ID, vt.URN, vct.ClientID, vct.Deleted})
	                .Where(x => x.URN == "urn:epcglobal:epcis:vtype:EPCClass" && x.ClientID == clientId && !x.Deleted)
	                .Select(x => x.ID)
	                .FirstOrDefault();

                if (AddEpcClass || AddNewVocabulary)
                {
	                var source = _epcisEventQuantityElement
		                .Select(x => new {VocabularyUrn = x.EpcClassUrn, VocabularyTypeId = epcisClassTypeId})
		                .Distinct()
		                .ToList();
	                
	                var notMatched = source
		                .Where(src =>
			                !db.Vocabulary.Any(tgt =>
				                tgt.URN == src.VocabularyUrn &&
				                tgt.VocabularyTypeID == src.VocabularyTypeId &&
				                tgt.ClientID == clientId))
		                .Select(src =>
			                new Vocabulary
			                {
				                URN = src.VocabularyUrn,
				                VocabularyTypeID = src.VocabularyTypeId,
				                ClientID = clientId,								
			                });

	                db.Vocabulary.AddRange(notMatched);

	                var matched = source 
		                .Join(db.Vocabulary.Where(x => x.ClientID == clientId && x.Deleted),
			                src => new
			                {
				                URN = src.VocabularyUrn,
				                ID = src.VocabularyTypeId
			                },
			                tgt => new
			                {
				                URN = tgt.URN,
				                ID = tgt.VocabularyTypeID
			                },			                
			                (src, tgt) => tgt);

	                foreach (var item in matched)
	                {
		                item.Deleted = false;
	                }
                }
                
                // SourceDestination hinzufügen
                // Add SourceDestination

                if (AddSourceDestination || AddNewVocabulary)
                {
	                var id = db.VocabularyType
		                .Join(db.VocabularyType_Client, vt => vt.ID, vtc => vtc.VocabularyTypeID, (vt, vct) => new {vt.ID, vt.URN, vct.ClientID, vct.Deleted})
		                .Where(x => x.URN == "urn:epcglobal:epcis:vtype:SourceDest" && x.ClientID == clientId && !x.Deleted)
		                .Select(x => x.ID)
		                .FirstOrDefault();

	                var source = _epcisEventSourceDestination
		                .Select(x => new {x.SourceDestinationUrn})
		                .Distinct()
		                .ToList();
	                
	                var notMatched = source
		                .Where(src =>
			                !db.Vocabulary.Any(tgt =>
				                tgt.URN == src.SourceDestinationUrn &&
				                tgt.VocabularyTypeID == id &&
				                tgt.ClientID == clientId))
		                .Select(src =>
			                new Vocabulary
			                {
				                URN = src.SourceDestinationUrn,
				                VocabularyTypeID = id,
				                ClientID = clientId,								
			                });

	                db.Vocabulary.AddRange(notMatched);

					var matched = source
						.Join(db.Vocabulary.Where(x => x.ClientID == clientId && x.Deleted), 
							src => new
							{
								URN = src.SourceDestinationUrn, 
								ID = id,
							},
							tgt => new
							{
								URN = tgt.URN,
								ID = tgt.VocabularyTypeID,
							},
					      (src, tgt) => tgt);

	                foreach (var item in matched)
	                {
		                item.Deleted = false;
	                }	                
                }

                db.SaveChanges();
                
                // Alle Vokabeln hinzfügen
                // Add all Vocabulary

                if (AddNewVocabulary)
                {
	                var source = _epcisEventVocabulary
		                .Select(x => new {x.VocabularyUrn, x.VocabularyTypeId})
		                .Distinct();

	                var target = db.Vocabulary;

	                foreach (var sourceItem in source)
	                {
		                var matchedItem = target.FirstOrDefault(targetItem =>
			                targetItem.URN == sourceItem.VocabularyUrn &&
			                targetItem.VocabularyTypeID == sourceItem.VocabularyTypeId &&
			                targetItem.ClientID == clientId);

		                if (matchedItem == null)
		                {
			                target.Add(new Vocabulary
			                {
				                URN = sourceItem.VocabularyUrn,
				                VocabularyTypeID = sourceItem.VocabularyTypeId,
				                ClientID = clientId,
			                });
		                }
		                else
		                {
			                matchedItem.Deleted = false;
		                }
	                }	                
                }
                
                // Systemvokablen (Systemmandant) ergänzen
                // Add system Vocabulary (Systemmandant)
                {
	                var dbVocabulary = db.Vocabulary
		                .Where(v => v.ClientID == systemClientId && !v.Deleted)
		                .Select(v => new {v.ID, v.URN, v.VocabularyTypeID});

	                var matchedItems = _epcisEventVocabulary
		                .Join(dbVocabulary,
			                target => new {URN = target.VocabularyUrn, VocabularyTypeID = target.VocabularyTypeId},
			                source => new {source.URN, source.VocabularyTypeID},
			                (target, source) => new {source, target});

	                foreach (var matched in matchedItems)
	                {
		                matched.target.Id = matched.source.ID;
	                }
                
	                // Mandantenvokabeln ergänzen
		            // Add client vocabulary
	            
		            dbVocabulary = db.Vocabulary
			            .Where(v => v.ClientID == clientId && !v.Deleted)
			            .Select(v => new {v.ID, v.URN, v.VocabularyTypeID});

		            matchedItems = _epcisEventVocabulary
			            .Join(dbVocabulary,
				            target => new {URN = target.VocabularyUrn, VocabularyTypeID = target.VocabularyTypeId},
				            source => new {source.URN, source.VocabularyTypeID},
				            (target, source) => new {source, target});

		            foreach (var matched in matchedItems)
		            {
			            matched.target.Id = matched.source.ID;
		            }
	            }

	            // Describe Error

                _epcisEventError.AddRange(
	                _epcisEventVocabulary
		                .Where(x => x.Id == 0)
		                .Select(x => new EpcisEventError
		                {
			                EpcisEventId = x.EpcisEventId,
			                Reason = "Vokabel '" + x.VocabularyUrn +
			                         "' nicht in Stammdaten gepflegt (oder logisch geloescht)."
		                }));
                

                //***************************************************************
				// EventBusinessTransaction: IDs zu den gesammelten URN bestimmen
				// EventBusinessTransaction: Determine IDs for the URN collected
				//***************************************************************                

                if (AddNewVocabulary)
                {
	                {
		                var source = _epcisEventBusinessTransactionId
			                .Select(x => new {x.BusinessTransactionTypeUrn, x.VocabularyTypeId})
			                .Distinct()
			                .ToList();
	                
		                var target = db.Vocabulary;

		                foreach (var sourceItem in source)
		                {
			                var matchedItem = target.FirstOrDefault(targetItem =>
				                targetItem.URN == sourceItem.BusinessTransactionTypeUrn &&
				                targetItem.VocabularyTypeID == sourceItem.VocabularyTypeId &&
				                targetItem.ClientID == clientId);

			                if (matchedItem == null)
			                {
				                target.Add(new Vocabulary
				                {
					                URN = sourceItem.BusinessTransactionTypeUrn,
					                VocabularyTypeID = sourceItem.VocabularyTypeId,
					                ClientID = clientId,
				                });
			                }
			                else
			                {
				                matchedItem.Deleted = false;
			                }
		                }
	                }

	                {
		                var source = db.Vocabulary
			                .Where(s => s.ClientID == clientId)
			                .Select(s => new {s.ID, s.VocabularyTypeID, s.URN})
			                .ToList();
		                
		                var target = _epcisEventBusinessTransactionId;

		                foreach (var s in source)
		                {
			                var matched = target.FirstOrDefault(t =>
				                t.VocabularyTypeId == s.VocabularyTypeID &&
				                t.BusinessTransactionTypeUrn == s.URN);

			                if (matched != null)
			                {
				                matched.BusinessTransactionTypeId = s.ID;
			                }
		                }
	                }
                }

                {
	                var vocabularyTypeClient = db.VocabularyType_Client
		                .Where(x => x.ClientID == clientId && !x.Deleted);

	                var vocabularyTypes = db.VocabularyType
		                .Join(vocabularyTypeClient,
			                vt => vt.ID,
			                vtc => vtc.VocabularyTypeID,
			                (vt, vtc) => new {Id = vt.ID, Urn = vt.URN});

	                var matchedItems = _epcisEventBusinessTransactionId
		                .Join(vocabularyTypes,
			                target => target.VocabularyTypeUrn,
			                source => source.Urn,
			                (target, source) => new {source, target});

	                foreach (var matched in matchedItems)
	                {
		                matched.target.VocabularyTypeId = matched.source.Id;
	                }
                }

                {
	                var dvVocabulary = db.Vocabulary
		                .Where(source => source.ClientID == clientId && !source.Deleted);

	                var matchedItems = _epcisEventBusinessTransactionId
		                .Join(dvVocabulary,
			                target => new
			                {
				                field1 = target.VocabularyTypeId,
				                field2 = target.BusinessTransactionTypeUrn
			                },
			                source => new
			                {
				                field1 = source.VocabularyTypeID,
				                field2 = source.URN
			                },			                
			                (target, source) => new
			                {
				                source,
				                target,
			                });
	                
	                foreach (var matched in matchedItems)
	                {
		                matched.target.BusinessTransactionTypeId = matched.source.ID;
	                }
                }

                // Describe Error

                _epcisEventError.AddRange(
	                _epcisEventBusinessTransactionId
		                .Where(x => x.BusinessTransactionTypeId == 0)
		                .Select(x => new EpcisEventError
		                {
			                EpcisEventId = x.EpcisEventId,
			                Reason = "'" + x.BusinessTransactionTypeUrn + "' unbekannter BusinessTransactionsTyp (oder logisch geloescht)."
		                }));

                //***************************************************************
	            // QuantityElement
		        //***************************************************************
                {
	                var dbVocabulary = db.Vocabulary
		                .Where(v => v.VocabularyTypeID == epcisClassTypeId && v.ClientID == clientId && !v.Deleted)
		                .Select(v => new {v.ID, v.URN});

	                var matchedItems = _epcisEventQuantityElement
		                .Join(dbVocabulary,
			                target => target.EpcClassUrn,
			                source => source.URN,
			                (target, source) => new {source, target});

	                foreach (var matched in matchedItems)
	                {
		                matched.target.EpcClassId = matched.source.ID;
	                }
	                
	                // Describe Error
	                _epcisEventError.AddRange(
		                _epcisEventQuantityElement
			                .Where(x => x.EpcClassId == 0)
			                .Select(x => new EpcisEventError
			                {
				                EpcisEventId = x.EpcisEventId,
				                Reason = "'" + x.EpcClassUrn + "' unbekannter EPCClass (oder logisch geloescht)."
			                }));	                
                }
                
                //***************************************************************
	            // SourceDestination
	            //***************************************************************
	            {
		            var id = db.VocabularyType
			            .Where(vt => vt.URN == "urn:epcglobal:epcis:vtype:SourceDest")
			            .Join(db.VocabularyType_Client.Where(vtc => vtc.ClientID == clientId && !vtc.Deleted),
				            vt => vt.ID,
				            vtc => vtc.VocabularyTypeID,
				            (vt, vtc) => vt.ID)
			            .FirstOrDefault();

		            var dbVocabulary = db.Vocabulary
			            .Where(v => v.VocabularyTypeID == id && v.ClientID == clientId && !v.Deleted)
			            .Select(v => new {v.ID, v.URN});

		            var matchedItems = _epcisEventSourceDestination
			            .Join(dbVocabulary,
				            target => target.SourceDestinationUrn,
				            source => source.URN,
				            (target, source) => new {source, target});

		            foreach (var matched in matchedItems)
		            {
			            matched.target.SourceDestinationId = matched.source.ID;
		            }
		            
		            id = db.VocabularyType
			            .Where(vt => vt.URN == "urn:epcglobal:epcis:vtype:SourceDestType")
			            .Join(db.VocabularyType_Client.Where(vtc => vtc.ClientID == clientId && !vtc.Deleted),
				            vt => vt.ID,
				            vtc => vtc.VocabularyTypeID,
				            (vt, vtc) => vt.ID)
			            .FirstOrDefault();
		            
		            dbVocabulary = db.Vocabulary
			            .Where(v => v.VocabularyTypeID == id && v.ClientID == clientId && !v.Deleted)
			            .Select(v => new {v.ID, v.URN});
		            
		            matchedItems = _epcisEventSourceDestination
			            .Join(dbVocabulary,
				            target => target.SourceDestinationTypeUrn,
				            source => source.URN,
				            (target, source) => new {source, target});

		            foreach (var matched in matchedItems)
		            {
			            matched.target.SourceDestinationTypeId = matched.source.ID;
		            }		            
		            
		            // Describe Error
		            _epcisEventError.AddRange(
			            _epcisEventSourceDestination
				            .Where(x => x.SourceDestinationId == 0)
				            .Select(x => new EpcisEventError
				            {
					            EpcisEventId = x.EpcisEventId,
					            Reason = "'" + x.SourceDestinationUrn + "' unbekannter SourceDest (oder logisch geloescht)."
				            }));
		            
		            // Describe Error
		            _epcisEventError.AddRange(
			            _epcisEventSourceDestination
				            .Where(x => x.SourceDestinationTypeId == 0)
				            .Select(x => new EpcisEventError
				            {
					            EpcisEventId = x.EpcisEventId,
					            Reason = "'" + x.SourceDestinationTypeUrn + "' unbekannter SourceDest Typ (oder logisch geloescht)."
				            }));	
	            }
	            
	            //***************************************************************
	            // Inhaltliche Prüfungen
	            // Content tests
	            //***************************************************************
				
	            // Prüfung EPC Struktur entweder URI (schema:path) oder EPC Pure Identity urn:epc:id:... 
	            // Check EPC structure either URI (schema: path) or EPC Pure Identity urn: epc: id: ...
				
	            _epcisEventError.AddRange(
					_epcisEventEpc
						.Where(x => CheckEpcCode(x.EpcUrn))
						.Select(x => new EpcisEventError
						{
							EpcisEventId = x.EpcisEventId,
							Reason = "EPC URI '" + x.EpcUrn + "' is not valid."
						}));
				
	            // Prüfung Aggregation ADD und DELETE benoetigen ParentID
				// Check aggregation ADD and DELETE require ParentID
				
				{
					var ev = _epcisEventVocabulary
						.Where(x => x.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:action" &&
						            (x.VocabularyUrn == "urn:quibiq:epcis:cbv:action:add" ||
						             x.VocabularyTypeUrn == "urn:quibiq:epcis:cbv:action:delete"));
					
					var ev2 = _epcisEventVocabulary
						.Where(x => x.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:event" && x.VocabularyUrn == "urn:quibiq:epcis:cbv:event:aggregation");

					var ed = _eventData
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId, _ev.VocabularyUrn})
						.Join(ev2, _ed => _ed.EpcisEventId, _ev2 => _ev2.EpcisEventId, (_ed, _ev) => _ed)
						.Distinct();
					
					_epcisEventError.AddRange(
						ed.Select(_ed=> new EpcisEventError
						{
							EpcisEventId = _ed.EpcisEventId,
							Reason = "Aggregation-Event mit Action: '" + _ed.VocabularyUrn.Substring(29, _ed.VocabularyUrn.Length - 28).ToUpper() + "' parentID fehlt.",
						}));
				}
				
				// Prüfung ObjectEvent epcList oder qunatityList oder beides
				// Check ObjectEvent epcList or qunatityList or both
				
				{
					var ev = _epcisEventVocabulary
						.Where(_ev => _ev.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:event" && _ev.VocabularyUrn == "urn:quibiq:epcis:cbv:event:object");

					var ed = _eventData
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId})
						.Join(_epcisEventEpc, _ed=>_ed.EpcisEventId, _ec=>_ec.EpcisEventId, (_ed,_ec)=>new {_ed.EpcisEventId, _ec.EpcUrn})
						.Join(_epcisEventQuantityElement, _ed => _ed.EpcisEventId, _qe => _qe.EpcisEventId, (_ed, _qe) => new {_ed.EpcisEventId, _ed.EpcUrn, EpcisClassUrn = _qe.EpcClassUrn})
						.Where(x => string.IsNullOrEmpty(x.EpcUrn) && string.IsNullOrEmpty(x.EpcisClassUrn))
						.Select(x=>x.EpcisEventId)
						.Distinct();
					
					_epcisEventError.AddRange(
						ed.Select(epcisEventId=> new EpcisEventError
						{
							EpcisEventId = epcisEventId,
							Reason = "Object-Event ohne epcList oder quantityList.",
						}));					
				}
				
				// Prüfung ObjectEvent != ADD kein ILMD
				// Check ObjectEvent! = ADD no ILMD
				
				{
					var ev = _epcisEventVocabulary
						.Where(_ev => _ev.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:action" &&
						              (_ev.VocabularyUrn == "urn:quibiq:epcis:cbv:action:observe" ||
						               _ev.VocabularyUrn == "urn:quibiq:epcis:cbv:action:delete"));
					
					var ev3 = _epcisEventVocabulary
						.Where(_ev3 => _ev3.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:event" && _ev3.VocabularyUrn == "urn:quibiq:epcis:cbv:action:observe");

					var ev2 = _epcisEventValue
						.Where(_ev2 => _ev2.ValueTypeTypeUrn == "urn:quibiq:epcis:vtype:ilmd");

					var ed = _eventData
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId, _ev.VocabularyUrn})
						.Join(ev3, _ed => _ed.EpcisEventId, _ev3 => _ev3.EpcisEventId, (_ed, _ev) => _ed)
						.Join(ev2, _ed => _ed.EpcisEventId, _ev2 => _ev2.EpcisEventId, (_ed, _ev2) => _ed)
						.Distinct();
					
					_epcisEventError.AddRange(
						ed.Select(_ed=> new EpcisEventError
						{
							EpcisEventId = _ed.EpcisEventId,
							Reason = "Object-Event mit Action: '" + _ed.VocabularyUrn.Substring(29, _ed.VocabularyUrn.Length - 28).ToUpper() + "' darf kein ILMD besitzen.",
						}));					
				}
				
				// Prüfung AggregationEvent != DELETE childEpcList oder qunatityList oder beides
				// Check AggregationEvent != DELETE childEpcList or qunatityList or both
				
				{
					var ev = _epcisEventVocabulary
						.Where(_ev => _ev.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:action" &&
						              (_ev.VocabularyUrn == "urn:quibiq:epcis:cbv:action:observe" ||
						               _ev.VocabularyUrn == "urn:quibiq:epcis:cbv:action:add"));
					
					var ev3 = _epcisEventVocabulary
						.Where(_ev3 => _ev3.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:event" && _ev3.VocabularyUrn == "urn:quibiq:epcis:cbv:event:aggregation");

					var ed = _eventData
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId, _ev.VocabularyUrn})
						.Join(ev3, _ed => _ed.EpcisEventId, _ev3 => _ev3.EpcisEventId, (_ed, _ev) => _ed)
						.Join(_epcisEventEpc, _ed => _ed.EpcisEventId, _ec => _ec.EpcisEventId, (_ed, _ec) => new {_ed.EpcisEventId, _ed.VocabularyUrn, _ec.EpcUrn})
						.Join(_epcisEventQuantityElement, _ed => _ed.EpcisEventId, _qe => _qe.EpcisEventId, (_ed, _qe) => new {_ed.EpcisEventId, _ed.VocabularyUrn, _ed.EpcUrn, EpcisClassUrn = _qe.EpcClassUrn})
						.Where(x => string.IsNullOrEmpty(x.EpcUrn) && string.IsNullOrEmpty(x.EpcisClassUrn))
						.Distinct();
					
					_epcisEventError.AddRange(
						ed.Select(_ed=> new EpcisEventError
						{
							EpcisEventId = _ed.EpcisEventId,
							Reason = "Aggregation-Event mit Action: '" + _ed.VocabularyUrn.Substring(29, _ed.VocabularyUrn.Length - 28).ToUpper() + "' ohne childEpcList oder childQuantityList.",
						}));					
				}
				
				// Prüfung TransactionEvent != DELETE childEpcList oder qunatityList oder beides
				// Check TransactionEvent != DELETE childEpcList or qunatityList or both
				
				{
					var ev = _epcisEventVocabulary
						.Where(_ev => _ev.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:action" &&
						              (_ev.VocabularyUrn == "urn:quibiq:epcis:cbv:action:observe" ||
						               _ev.VocabularyUrn == "urn:quibiq:epcis:cbv:action:add"));
					
					var ev3 = _epcisEventVocabulary
						.Where(_ev3 => _ev3.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:event" && _ev3.VocabularyUrn == "urn:quibiq:epcis:cbv:event:transaction");
					
					var ed = _eventData
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId, _ev.VocabularyUrn})
						.Join(ev3, _ed => _ed.EpcisEventId, _ev3 => _ev3.EpcisEventId, (_ed, _ev) => _ed)
						.Join(_epcisEventEpc, _ed => _ed.EpcisEventId, _ec => _ec.EpcisEventId, (_ed, _ec) => new {_ed.EpcisEventId, _ed.VocabularyUrn, _ec.EpcUrn})
						.Join(_epcisEventQuantityElement, _ed => _ed.EpcisEventId, _qe => _qe.EpcisEventId, (_ed, _qe) => new {_ed.EpcisEventId, _ed.VocabularyUrn, _ed.EpcUrn, EpcisClassUrn = _qe.EpcClassUrn})
						.Where(x => string.IsNullOrEmpty(x.EpcUrn) && string.IsNullOrEmpty(x.EpcisClassUrn))
						.Distinct();
					
					_epcisEventError.AddRange(
						ed.Select(_ed=> new EpcisEventError
						{
							EpcisEventId = _ed.EpcisEventId,
							Reason = "Transaction-Event mit Action: '" + _ed.VocabularyUrn.Substring(29, _ed.VocabularyUrn.Length - 28).ToUpper() + "' ohne childEpcList oder childQuantityList.",
						}));						
				}
				
				{
					// Prüfung TransformationEvent ohne transformationID
					// Checking TransformationEvent without transformationID
					
					var ed = _eventData
						.Where(_ed =>
							(!_epcisEventEpc.Any(ec => ec.EpcisEventId == _ed.EpcisEventId && ec.IsInput) &&
							 !_epcisEventQuantityElement.Any(qe => qe.EpcisEventId == _ed.EpcisEventId && qe.IsInput)) ||
							(!_epcisEventEpc.Any(ec => ec.EpcisEventId == _ed.EpcisEventId && ec.IsOutput) &&
							 !_epcisEventQuantityElement.Any(qe => qe.EpcisEventId == _ed.EpcisEventId && !qe.IsInput)));
					
					var ev = _epcisEventVocabulary
						.Where(_ev => _ev.VocabularyTypeUrn == "urn:quibiq:epcis:vtype:event" && _ev.VocabularyUrn == "urn:quibiq:epcis:cbv:event:transformation");

					var ed1 = ed
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId})
						.Join(_epcisEventTransformationId, _ed => _ed.EpcisEventId, _et => _et.EpcisEventId, (_ed, _et) => new {_ed.EpcisEventId, _et.TransformationIdUrn})
						.Where(x => string.IsNullOrEmpty(x.TransformationIdUrn))
						.Distinct();
					
					_epcisEventError.AddRange(
						ed1.Select(_ed=> new EpcisEventError
						{
							EpcisEventId = _ed.EpcisEventId,
							Reason = "Transformation-Event ohne transformationID muss mindestens einen Input (epc/quantity) und einen Output (epc/quantity) besitzen.",
						}));
					
					// Prüfung TransformationEvent mit transformationID
					// Checking of TransformationEvent with transformationID
					
					ed1 = ed
						.Join(ev, _ed => _ed.EpcisEventId, _ev => _ev.EpcisEventId, (_ed, _ev) => new {_ed.EpcisEventId})
						.Join(_epcisEventTransformationId, _ed => _ed.EpcisEventId, _et => _et.EpcisEventId, (_ed, _et) => new {_ed.EpcisEventId, _et.TransformationIdUrn})
						.Distinct();
					
					_epcisEventError.AddRange(
						ed1.Select(_ed=> new EpcisEventError
						{
							EpcisEventId = _ed.EpcisEventId,
							Reason = "Transformation-Event mit transformationID muss entweder einen Input (epc/quantity) oder einen Output (epc/quantity) besitzen.",
						}));
				}
				
				//***************************************************************
				// Entfernen Fehlerhafter Events aus Zwischenstruktur
				// Removal of faulty events from the intermediate structure
				//***************************************************************
				if (ProcessOnlyWholeDocument)
				{
					foreach (var epcisEventId in _epcisEventError
						.Select(err => err.EpcisEventId)
						.Distinct())
					{
						_epcisEventBusinessTransactionId.RemoveAll(epcisEvent => epcisEvent.EpcisEventId == epcisEventId);
						_epcisEventEpc.RemoveAll(epcisEvent => epcisEvent.EpcisEventId == epcisEventId);
						_epcisEventVocabulary.RemoveAll(epcisEvent => epcisEvent.EpcisEventId == epcisEventId);
						_epcisEventValue.RemoveAll(epcisEvent => epcisEvent.EpcisEventId == epcisEventId);
						_epcisEventExtenstionType.RemoveAll(epcisEvent => epcisEvent.EpcisEventId == epcisEventId);
					}
				}
				
				//***************************************************************
				// Events in Tabelle speichern und Konvertierung der EPCISEventID
				// Save events in table and convert EPCISEventID
				//***************************************************************

				var epcisEventIdsList = _eventData
					.Select(_event => new EpcisEventIds
					{
						TechnicalEpcisEvent = new EPCISEvent
						{
							ClientID = _event.ClientId,
							EventTime = _event.EventTime,
							RecordTime = _event.RecordTime,
							EventTimeZoneOffset = _event.EventTimeZoneOffset,
							XmlRepresentation = _event.EpcisRepresentation,							
						},
						EpcisEventId = _event.EpcisEventId,
					})
					.ToList();

				_epcisEventIds.AddRange(epcisEventIdsList);
				
				db.EPCISEvent.AddRange(epcisEventIdsList.Select(x => x.TechnicalEpcisEvent));

				db.SaveChanges();

				foreach (var matched in _epcisEventIds
					.Join(_epcisEventBusinessTransactionId,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventEpc,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventVocabulary,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventValue,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventExtenstionType,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}				
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventTransformationId,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventSourceDestination,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}	
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventQuantityElement,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				foreach (var matched in _epcisEventIds
					.Join(_epcisEventError,
						source => source.EpcisEventId,
						target => target.EpcisEventId,
						(source, target) => new {target, technicalEpcisEventId = source.TechnicalEpcisEvent.ID}))
				{
					matched.target.EpcisEventId = matched.technicalEpcisEventId;
				}
				
				//***************************************************************
				// EPCISHeader: IDs speichern
				// EPCISHeader: save IDs
				//***************************************************************				

				var docHeader =
					standardBusinessDocumentHeader?.XPathSelectElement(
						"//*[local-name() = 'StandardBusinessDocumentHeader']"); 
				if (docHeader  != null)
				{
					var headerVersion = docHeader.XPathSelectElement("//*[local-name() = 'HeaderVersion']");

					var epcisDocumentHeader = new EPCISDocumentHeader
					{
						EPCISDocumentHeader1 = standardBusinessDocumentHeader.ToString(),
						HeaderVersion = headerVersion != null ? headerVersion.Value : string.Empty,
					}; 

					db.EPCISDocumentHeader.Add(epcisDocumentHeader);
					db.SaveChanges();

					var epcisDocumentHeaderId = epcisDocumentHeader.ID;

					var epcisDocumentHeaders = _epcisEventIds
						.Select(x => x.TechnicalEpcisEvent.ID)
						.Distinct()
						.Select(technicalEpcisEventId =>
							new EPCISEvent_DocumentHeader
							{
								DocumentHeaderID = epcisDocumentHeaderId,
								EPCISEventID = technicalEpcisEventId,
							});

					db.EPCISEvent_DocumentHeader.AddRange(epcisDocumentHeaders);
				}					
				
				//Einzeleventfehler speichern - falls vorhanden
				//Save single event errors - if any

				var errors = _epcisEventError
					.Select(error =>
						new Error
						{
							TimeStampGeneration = DateTime.UtcNow,
							AdditionalInformation = "ObjectID: Event.ID",
							ErrorNumber = 55555,
							ErrorSeverity = 16,
							ErrorProcedure = "qbq.EPCIS.Repository.Custom.ImportEvent",
							ErrorMessage = error.Reason.Length > 2047 ? error.Reason.Substring(0, 2047) : error.Reason,
							ErrorLine = 0,
							ErrorState = 1,
							ObjectID = error.EpcisEventId,
						});

				db.Error.AddRange(errors);
				
				//***************************************************************
				// Geprüfte Event Daten speichern
				// Save checked event data
				//***************************************************************
				// Da die interen EPCISEventIDs gegen die technischen ausgetauscht wurden ist nichts weiter zu beachten
				// Since the internal EPCISEventIDs were exchanged for the technical ones, nothing else needs to be considered

				//***************************************************************
				// EventVokabeln: IDs speichern
				// Event vocabulary: save IDs
				//***************************************************************

				var notMatchedItems = _epcisEventVocabulary
					.Where(source =>
						!db.EPCISEvent_Vocabulary.Any(target =>
							target.EPCISEventID == source.EpcisEventId &&
							target.ID == source.Id))
					.Select(item => new EPCISEvent_Vocabulary
					{
						EPCISEventID = item.EpcisEventId,
						VocabularyID = item.Id
					});

				db.EPCISEvent_Vocabulary.AddRange(notMatchedItems);
				
				//***************************************************************
				// EPC: EPCIDs zu den gesammelten EPCs bestimmen
				// EPC: Determine EPCIDs for the EPCs collected
				//***************************************************************
				
				var epsUrns = _epcisEventEpc
					.Select(x => new {x.EpcUrn})
					.Distinct()
					.Where(source => !db.EPC.Any(target => target.URN == source.EpcUrn))
					.Select(source =>
						new EPC
						{
							URN = source.EpcUrn,
						});

				db.EPC.AddRange(epsUrns);

				db.SaveChanges();

				foreach (var matched in _epcisEventEpc
					.Join(db.EPC,
						target => target.EpcUrn,
						source => source.URN,
						(target, source) => new {target, source}))
				{
					matched.target.EpcId = matched.source.ID;
				}
				
				//***************************************************************
				// EventEPC: IDs speichern
				// EventEPC: save IDs
				//***************************************************************

				var epcisEventEpcs = _epcisEventEpc
					.Select(source => new
					{
						source.EpcisEventId, 
						source.EpcId, 
						source.IsParent, 
						source.IsInput, 
						source.IsOutput
					})
					.Distinct()
					.Where(source => !db.EPCISEvent_EPC
						.Any(target => 
							target.EPCISEventID == source.EpcisEventId && 
							target.EPCID == source.EpcId))
					.Select(source =>
						new EPCISEvent_EPC
						{
							EPCISEventID = source.EpcisEventId,
							EPCID = source.EpcId,
							IsParentID = source.IsParent,
							IsInput = source.IsInput,
							IsOutput = source.IsOutput,
						});

				db.EPCISEvent_EPC.AddRange(epcisEventEpcs);
				
				//***************************************************************
				// TransformationID: IDs speichern
				// TransformationID: Save IDs
				//***************************************************************
				

				var transformationUrns = _epcisEventTransformationId
					.Select(source => new {source.TransformationIdUrn})
					.Distinct()
					.Where(source => !db.TransformationID.Any(target => target.URN == source.TransformationIdUrn))
					.Select(source =>
						new TransformationID
						{
							URN =  source.TransformationIdUrn,
						});

				db.TransformationID.AddRange(transformationUrns);

				db.SaveChanges();
				
				foreach (var matched in _epcisEventTransformationId
					.Join(db.TransformationID,
						target => target.TransformationIdUrn,
						source => source.URN,
						(target, source) => new {target, source}))
				{
					matched.target.TransformationIdId = matched.source.ID;
				}
				
				//***************************************************************
				// EventTransformationID: IDs speichern
				// EventTransformationID: Save IDs
				//***************************************************************

				var epcisEventTransformationIds = _epcisEventTransformationId
					.Select(source =>
						new
						{
							source.EpcisEventId,
							source.TransformationIdId
						})
					.Distinct()
					.Where(source => !db.EPCISEvent_TransformationID
						.Any(target =>
							target.EPCISEventID == source.EpcisEventId &&
							target.TransformationIDID == source.TransformationIdId))
					.Select(source =>
						new EPCISEvent_TransformationID
						{
							EPCISEventID = source.EpcisEventId,
							TransformationIDID = source.TransformationIdId,
						});

				db.EPCISEvent_TransformationID.AddRange(epcisEventTransformationIds);
				
				//***************************************************************
				// QuantityElement: IDs speichern
				// QuantityElement: save IDs
				//***************************************************************
				{
					var epcisEventQuantityElements = _epcisEventQuantityElement
						.Select(source =>
							new
							{
								EpcisClassId = source.EpcClassId,
								source.Quantity,
								source.Uom
							})
						.Distinct()
						.Where(source => !db.QuantityElement
							.Any(target =>
								target.EPCClassID == source.EpcisClassId &&
								Math.Abs(target.Quantity - source.Quantity) < 0.001
								&& target.UOM == source.Uom))
						.Select(source =>
							new QuantityElement
							{
								EPCClassID = source.EpcisClassId,
								Quantity = source.Quantity,
								UOM = source.Uom,
							});

					db.QuantityElement.AddRange(epcisEventQuantityElements);

					db.SaveChanges();

					foreach (var matched in _epcisEventQuantityElement
						.Join(db.QuantityElement,
							target =>
								new
								{
									field1 = target.EpcClassId,
									field2 = target.Uom,
								},
							source =>
								new
								{
									field1 = source.EPCClassID,
									field2 = source.UOM
								},
							(target, source) => new {target, source})
						.Where(matched => Math.Abs(matched.target.Quantity - matched.source.Quantity) < 0.001))
					{
						matched.target.QuantityElementId = matched.source.ID;
					}
				}
				
				//***************************************************************
				// EventQuantityElement: IDs speichern
				// EventQuantityElement: Save IDs
				//***************************************************************

				{
					var epcisEventQuantityElements = _epcisEventQuantityElement
						.Select(source =>
							new
							{
								source.EpcisEventId,
								source.QuantityElementId,
								source.IsInput,
								source.IsOutput
							})
						.Distinct()
						.Where(source => !db.EPCISEvent_QuantityElement
							.Any(target =>
								target.EPCISEventID == source.EpcisEventId &&
								target.QuantityElementID == source.QuantityElementId))
						.Select(source =>
							new EPCISEvent_QuantityElement
							{
								EPCISEventID = source.EpcisEventId,
								QuantityElementID = source.QuantityElementId,
								IsInput = source.IsInput,
								IsOutput = source.IsOutput,
							});

					db.EPCISEvent_QuantityElement.AddRange(epcisEventQuantityElements);
				}
				
				//***************************************************************
				// EventSourceDestination: IDs speichern
				// EventSourceDestination: save IDs
				//***************************************************************

				var epcisEventSourceDestinations = _epcisEventSourceDestination
					.Select(source =>
						new
						{
							source.EpcisEventId,
							source.SourceDestinationId,
							source.SourceDestinationTypeId,
							source.IsSource
						})
					.Distinct()
					.Where(source => !db.EPCISEvent_SourceDestination
						.Any(target =>
							target.EPCISEventID == source.EpcisEventId &&
							target.SourceDestinationID == source.SourceDestinationId &&
							target.SourceDestinationTypeID == source.SourceDestinationTypeId &&
							target.IsSource == source.IsSource))
					.Select(source =>
						new EPCISEvent_SourceDestination
						{
							EPCISEventID = source.EpcisEventId,
							SourceDestinationID = source.SourceDestinationId,
							SourceDestinationTypeID = source.SourceDestinationTypeId,
							IsSource = source.IsSource,
						});

				db.EPCISEvent_SourceDestination.AddRange(epcisEventSourceDestinations);
				
				//***************************************************************
				// BusinessTransaction: IDs speichern
				// BusinessTransaction: Save IDs
				//***************************************************************

				var businessTransactionIds = _epcisEventBusinessTransactionId
					.Select(source =>
						new
						{
							source.BusinessTransactionTypeId,
							source.BusinessTransactionIdUrn
						})
					.Distinct()
					.Where(source => !db.BusinessTransactionID
						.Any(target =>
							target.BusinessTransactionTypeID == source.BusinessTransactionTypeId &&
							target.URN == source.BusinessTransactionIdUrn))
					.Select(source =>
						new BusinessTransactionID
						{
							URN = source.BusinessTransactionIdUrn,
							BusinessTransactionTypeID = source.BusinessTransactionTypeId,
						});

				db.BusinessTransactionID.AddRange(businessTransactionIds);

				db.SaveChanges();
				
				foreach (var matched in _epcisEventBusinessTransactionId
					.Join(db.BusinessTransactionID,
						target => 
						new
						{
							field1 = target.BusinessTransactionTypeId,
							field2 = target.BusinessTransactionIdUrn
						},
						source => 
						new
						{
							field1 = source.BusinessTransactionTypeID,
							field2 = source.URN,
						},
						(target, source) => new {target, source}))
				{
					matched.target.BusinessTransactionIdId = matched.source.ID;
				}
				
				//***************************************************************
				// EventBusinessTransaction: IDs speichern
				// EventBusinessTransaction: Save IDs
				//***************************************************************

				var eventBusinessTransactionIds = _epcisEventBusinessTransactionId
					.Select(source =>
						new
						{
							source.EpcisEventId,
							source.BusinessTransactionIdId
						})
					.Distinct()
					.Where(source => !db.EPCISEvent_BusinessTransactionID
						.Any(target =>
							target.EPCISEventID == source.EpcisEventId &&
							target.BusinessTransactionIDID == source.BusinessTransactionIdId))
					.Select(source =>
						new EPCISEvent_BusinessTransactionID
						{
							EPCISEventID = source.EpcisEventId,
							BusinessTransactionIDID = source.BusinessTransactionIdId,
						});

				db.EPCISEvent_BusinessTransactionID.AddRange(eventBusinessTransactionIds);

				//***************************************************************
				// EPCISEvent_Extensions: Neue Extensions dynamisch anlegen
				// EPCISEvent_Extensions: Create new extensions dynamically
				//***************************************************************
				{
					var dbExtensionTypes = db.VocabularyType
						.Select(x => new {VocabularyTypeId = x.ID, x.URN});

					var sourceList = _epcisEventExtenstionType
						.Join(dbExtensionTypes, 
							e => e.ExtensionTypeTypeUrn, 
							vt => vt.URN,
							(e, vt) => new {e.ExtensionTypeUrn, vt.VocabularyTypeId, ClientId = clientId})
						.ToList();
						
					var extensionTypes = sourceList
						.Where(source => !db.Vocabulary
							.Any(target => 
								target.URN == source.ExtensionTypeUrn &&
								target.VocabularyTypeID == source.VocabularyTypeId && 
								target.ClientID == source.ClientId))
						.Select(source =>
							new Vocabulary
							{
								ClientID = source.ClientId,
								VocabularyTypeID = source.VocabularyTypeId,
								URN = source.ExtensionTypeUrn,
							});

					db.Vocabulary.AddRange(extensionTypes);
					
					var matched = sourceList 
						.Join(db.Vocabulary.Where(x => x.ClientID == clientId && x.Deleted),
							src => new
							{
								field1 = src.ExtensionTypeUrn,
								field2 = src.VocabularyTypeId,
								field3 = src.ClientId
							},
							tgt => new
							{
								field1 = tgt.URN,
								field2 = tgt.VocabularyTypeID,
								field3 = tgt.ClientID
							},
							(src, tgt) => tgt);

					foreach (var item in matched)
					{
						item.Deleted = false;
					}
				}
								
				//***************************************************************
				// EPCISEvent_Value: IDs zu den gesammelten URN bestimmen
				// EPCISEvent_Value: Determine IDs for the collected URN
				//***************************************************************
				
				
				foreach (var matched in _epcisEventValue
					.Join(db.VocabularyType,
						target => target.ValueTypeTypeUrn,
						source => source.URN,
						(target, source) => new {SourceId = source.ID, target}))
				{
					matched.target.ValueTypeTypeId = matched.SourceId;
				}
				
				foreach (var matched in _epcisEventValue
					.Join(db.VocabularyType,
						target => target.DataTypeTypeUrn,
						source => source.URN,
						(target, source) => new {SourceId = source.ID, target}))
				{
					matched.target.DataTypeTypeId = matched.SourceId;
				}

				foreach (var matched in _epcisEventValue
					.Join(db.Vocabulary,
						target =>
							new
							{
								field1 = target.ValueTypeUrn,
								field2 = target.ValueTypeTypeId,
							},
						source =>
							new
							{
								field1 = source.URN,
								field2 = source.VocabularyTypeID,
							},
						(target, source) => new {SourceId = source.ID, target}))
				{
					matched.target.ValueTypeId = matched.SourceId;
				}

				foreach (var matched in _epcisEventValue
					.Join(db.Vocabulary,
						target =>
							new
							{
								field1 = target.DataTypeUrn,
								field2 = target.DataTypeTypeId,
							},
						source =>
							new
							{
								field1 = source.URN,
								field2 = source.VocabularyTypeID,
							},
						(target, source) => new {SourceId = source.ID, target}))
				{
					matched.target.DataTypeId = matched.SourceId;
				}				
				
				//***************************************************************
				// EPCISEvent_Value/EPCISEvent_Extensions speichern
				// Save EPCISEvent_Value / EPCISEvent_Extensions
				//***************************************************************

				// EPCISEvent_Value Einträge generieren (ex können mehrere je Event existieren,
				// Merge Funktion erleichtert jedoch die Parent/Child auflösung
				
				// Generate EPCISEvent_Value entries (ex can exist several per event,
				// Merge function makes it easier to resolve the parent / child

				{
					var epcisEventValues = _epcisEventValue
						.Select(source =>
							new
							{
								EpcisEventValue = new EPCISEvent_Value
								{
									EPCISEventID = source.EpcisEventId,
									ValueTypeID = source.ValueTypeId,
									DataTypeID = source.DataTypeId
								},
								Source = source,
							});

					db.EPCISEvent_Value.AddRange(epcisEventValues.Select(x => x.EpcisEventValue));

					var valueValues = epcisEventValues
						.Select(item =>
							new EpcisEventValueValues
							{
								EpcisEventValue = item.EpcisEventValue,
								ValueTypeUrn = item.Source.ValueTypeUrn,
								DataTypeUrn = item.Source.DataTypeUrn,
								IntValue = item.Source.IntValue,
								FloatValue = item.Source.FloatValue,
								TimeValue = item.Source.TimeValue,
								StringValue = item.Source.StringValue,
								ParentUrn = item.Source.ParentUrn,
								Depth = item.Source.Depth,
							});
					
					_epcisEventValueValues.AddRange(valueValues);
				}

				db.SaveChanges();
				
				// Da die Extension Inhalte nicht definiert werden ist es für die Abfrageoberfläche einfacher das Datum in jedem
				// gültigen Format abzuspeichern, so kann eine effiziente / einfache und schnelle Abfrage erfolgen auf 
				// Kosten von Datenredundanzen

				// Since the extension contents are not defined, it is easier for the query interface to include the date in each
				// save valid format, an efficient / simple and fast query can be made on
				// Cost of data redundancy
				
				// Numeric Values (Float und Int)
				var eventValueNumerics = _epcisEventValueValues
					.Where(source => 
						source.FloatValue != 0 && 
						!db.EPCISEvent_Value_Numeric
							.Any(target => 
								target.EPCISEvent_ValueID == source.EpcisEventValue.ID && 
								Math.Abs(target.Value - source.FloatValue) < 0.001))
					.Select(source =>
						new EPCISEvent_Value_Numeric
						{
							EPCISEvent_ValueID = source.EpcisEventValue.ID,
							Value = source.FloatValue,
						});

				db.EPCISEvent_Value_Numeric.AddRange(eventValueNumerics);
				
				// Time
				var eventValueDatetimes = _epcisEventValueValues
					.Where(source =>
						!db.EPCISEvent_Value_Datetime
							.Any(target =>
								target.EPCISEvent_ValueID == source.EpcisEventValue.ID &&
								target.Value == source.TimeValue))
					.Select(source =>
						new EPCISEvent_Value_Datetime()
						{
							EPCISEvent_ValueID = source.EpcisEventValue.ID,
							Value = source.TimeValue,
						});

				db.EPCISEvent_Value_Datetime.AddRange(eventValueDatetimes);
				
				// string
				var valueStrings = _epcisEventValueValues
					.Where(source =>
						!string.IsNullOrEmpty(source.StringValue) &&
						!db.Value_String.Any(target => target.Value == source.StringValue))
					.Select(source =>
						new Value_String
						{
							Value = source.StringValue,
						});

				db.Value_String.AddRange(valueStrings);


				var eventValueStrings = _epcisEventValueValues
					.Join(db.Value_String,
						vv => vv.StringValue, 
						vs => vs.Value,
						(vv, vs) => new {ValueStringId = vs.ID, EpcisEventValueId = vv.EpcisEventValue.ID})
					.Where(source => !db.EPCISEvent_Value_String
						.Any(target =>
							target.EPCISEvent_ValueID == source.EpcisEventValueId &&
							target.Value_StringID == source.ValueStringId))
					.Select(source =>
						new EPCISEvent_Value_String
						{
							EPCISEvent_ValueID = source.EpcisEventValueId,
							Value_StringID = source.ValueStringId,
						});

				db.EPCISEvent_Value_String.AddRange(eventValueStrings);
				
				// XML / Parents 
				// Parents Ermitteln				
				{
					var parentValues = _epcisEventValueValues.Select(x => new
					{
						EpcisEventValueId = x.EpcisEventValue.ID,
						x.ValueTypeUrn,
						x.Depth,
					});

					var matchedItems = _epcisEventValueValues
						.Where(children => children.Depth > 0)
						.Join(parentValues,
							children => new {Urn = children.ParentUrn, Depth = children.Depth - 1},
							parent => new {Urn = parent.ValueTypeUrn, Depth = parent.Depth},
							(children, parent) => new {children, parent});

					foreach (var matched in matchedItems)
					{
						matched.children.ParentEpcisEventValueId = matched.parent.EpcisEventValueId;
					}
				}
				
				// Hierarchy speichern
				var eventValueHierarchies = _epcisEventValueValues.Where(source => 
					source.Depth > 0 &&
					!db.EPCISEvent_Value_Hierarchy
						.Any(target =>
							target.EPCISEvent_ValueID == source.EpcisEventValue.ID &&
							target.Parent_EPCISEvent_ValueID == source.ParentEpcisEventValueId))
					.Select(source => 
						new EPCISEvent_Value_Hierarchy
						{
							EPCISEvent_ValueID = source.EpcisEventValue.ID,
							Parent_EPCISEvent_ValueID = source.ParentEpcisEventValueId,
						});

				db.EPCISEvent_Value_Hierarchy.AddRange(eventValueHierarchies);

				db.SaveChanges();
				
	        }            
        }
        
	    private string GetDataTypeUrn(int intValue, float floatValue, DateTime timeValue, string stringValue)
        {
	        string result;

	        if (intValue == 0)
	        {
		        if (floatValue == 0)
		        {
			        if (timeValue == default)
			        {
				        result = string.IsNullOrEmpty(stringValue) ? "urn:quibiq:epcis:cbv:datatype:xml" : "urn:quibiq:epcis:cbv:datatype:string";
			        }
			        else
			        {
				        result = "urn:quibiq:epcis:cbv:datatype:time";
			        }
		        }
		        else
		        {
			        result = "urn:quibiq:epcis:cbv:datatype:float";
		        }
	        }
	        else
	        {
		        result = "urn:quibiq:epcis:cbv:datatype:int";
	        }

	        return result;
        }

        private bool CheckEpcCode(string epcUrn)
        {
	        var valid = false;

	        if (epcUrn.Substring(0, 11) == "urn:epc:id:")
	        {
		        var len = epcUrn.Length;
		        var gidEnd = epcUrn.IndexOf(':', 12);
		        var gid = epcUrn.Substring(12, gidEnd - 12);
		        var companyEnd = epcUrn.IndexOf('.', gidEnd + 1);
		        var companyPrefix = epcUrn.Substring(gidEnd + 1, companyEnd - (gidEnd + 1) > 0 ? companyEnd - (gidEnd + 1) : 0);

		        switch (gid)
		        {
			        case "sgtin":
				        var itemEnd = epcUrn.IndexOf('.', companyEnd + 1);
				        var itemReference = epcUrn.Substring(companyEnd + 1, itemEnd - (companyEnd + 1) > 0 ? itemEnd - (companyEnd + 1) : 0);

				        if (companyPrefix.Length + itemReference.Length == 13)
				        {
					        valid = true;
				        }
				        
				        break;
			        
			        case "sscc":
				        var serialReference = epcUrn.Substring(companyEnd + 1, len - companyEnd > 0 ? len - companyEnd : 0);

				        if (companyPrefix.Length + serialReference.Length == 17)
				        {
					        valid = true;
				        }
				        
				        break;
			        
			        case "sgln":
				        var locEnd = epcUrn.IndexOf('.', companyEnd + 1);
				        var locationReference = epcUrn.Substring(companyEnd + 1, locEnd - (companyEnd + 1) > 0 ? locEnd - (companyEnd + 1) : 0);

				        if (companyPrefix.Length + locationReference.Length == 12)
				        {
					        valid = true;
				        }
				        
				        break;
			        case "grai":
				        var assetEnd = epcUrn.IndexOf('.', companyEnd + 1);
				        var assetType = epcUrn.Substring(companyEnd + 1, assetEnd - (companyEnd + 1) > 0 ? assetEnd - (companyEnd + 1) : 0);

				        if (companyPrefix.Length + assetType.Length == 12)
				        {
					        valid = true;
				        }
				        
				        break;
			        case "giai":
				        var individualAssetReference = epcUrn.Substring(companyEnd + 1, len - companyEnd > 0 ? len - companyEnd : 0);

				        if (individualAssetReference.Length > 1)
				        {
					        valid = true;
				        }
				        
				        break;
		        }
	        }
	        else
	        {
		        //URI min 3 Zeichen s:p und min. ein Doppelpunkt auf Position 2 oder höher (nicht C++ Zählweise)
		        if (epcUrn.IndexOf(':') > 0 && epcUrn.Length >= 3)
		        {
			        valid = true;
		        }
	        }
	        
	        return valid;
        }
    }
}