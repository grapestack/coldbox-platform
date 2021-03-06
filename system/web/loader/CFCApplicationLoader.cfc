﻿<!-----------------------------------------------------------------------
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author 	 		: Luis Majano
Date     		: September 23, 2005
Description		: 

Loads a coldbox cfc configuration file

----------------------------------------------------------------------->
<cfcomponent hint="Loads a coldbox xml configuration file" output="false" extends="coldbox.system.web.loader.AbstractApplicationLoader">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------>
	
	<cfscript>
		instance = structnew();
	</cfscript>

	<!--- init --->
	<cffunction name="init" output="false" access="public" returntype="any" hint="constructor">
		<cfargument name="controller" 			type="any" 		required="true" default="" hint="The coldbox application to load the settings into"/>
		<cfscript>
			super.init(arguments.controller);
			
			return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------>
	
	<cffunction name="loadConfiguration" access="public" returntype="void" output="false" hint="Parse the application configuration file.">
		<!--- ************************************************************* --->
		<cfargument name="overrideAppMapping" required="false" default="" hint="The direct location of the application in the web server."/>
		<!--- ************************************************************* --->
		<cfscript>
		//Create Config Structure
		var configStruct		= structNew();
		var coldboxSettings 	= getColdboxSettings();
		var appRootPath 		= instance.controller.getAppRootPath();
		var configCFCLocation 	= coldboxSettings["ConfigFileLocation"];
		var configCreatePath 	= "";
		var oConfig 			= "";
		var logBoxConfigHash  	= hash(instance.controller.getLogBox().getConfig().getMemento().toString());
		var appMappingAsDots	= "";
		
		//Is incoming app mapping set, or do we auto-calculate
		if( NOT len(arguments.overrideAppMapping) ){
			//AutoCalculate
			calculateAppMapping(configStruct);
		}
		else{
			configStruct.appMapping = arguments.overrideAppMapping;
		}
		
		//Default Locations for ROOT based apps, which is the default
		//Parse out the first / to create the invocation Path
		if ( left(configStruct["AppMapping"],1) eq "/" ){
			configStruct["AppMapping"] = removeChars(configStruct["AppMapping"],1,1);
		}
		//AppMappingInvocation Path
		appMappingAsDots = getAppMappingAsDots(configStruct.AppMapping);
		
		// Config Create Path if not overriding and there is an appmapping
		if( len( appMappingAsDots ) AND NOT coldboxSettings.ConfigFileLocationOverride){
			configCreatePath = appMappingAsDots & "." & configCFCLocation;
		}
		// Config create path if overriding or no app mapping
		else{
			configCreatePath = configCFCLocation;
		}
		
		//Create config Object
		oConfig = createObject("component", configCreatePath);
		
		//Decorate It
		oConfig.injectPropertyMixin = getUtil().getMixerUtil().injectPropertyMixin;
		oConfig.getPropertyMixin 	= getUtil().getMixerUtil().getPropertyMixin;
		
		//MixIn Variables
		oConfig.injectPropertyMixin("controller",instance.controller);
		oConfig.injectPropertyMixin("logBoxConfig",instance.controller.getLogBox().getConfig());
		oConfig.injectPropertyMixin("appMapping",configStruct.appMapping);
		
		//Configure it
		oConfig.configure();
		
		//Environment detection
		detectEnvironment(oConfig,configStruct);
		 
		/* ::::::::::::::::::::::::::::::::::::::::: APP LOCATION CALCULATIONS :::::::::::::::::::::::::::::::::::::::::::: */
		
		// load default application paths
		loadApplicationPaths(configStruct,arguments.overrideAppMapping);
		
		/* ::::::::::::::::::::::::::::::::::::::::: GET COLDBOX SETTINGS  :::::::::::::::::::::::::::::::::::::::::::: */
		parseColdboxSettings(oConfig,configStruct,arguments.overrideAppMapping);
		
		/* ::::::::::::::::::::::::::::::::::::::::: YOUR SETTINGS LOADING :::::::::::::::::::::::::::::::::::::::::::: */
		parseYourSettings(oConfig,configStruct);	
		
		/* ::::::::::::::::::::::::::::::::::::::::: YOUR CONVENTIONS LOADING :::::::::::::::::::::::::::::::::::::::::::: */
		parseConventions(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: MODULE SETTINGS  :::::::::::::::::::::::::::::::::::::::::::: */
		parseModules(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: IOC SETTINGS  :::::::::::::::::::::::::::::::::::::::::::: */
		parseIOC(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: HANDLER-MODELS-PLUGIN INVOCATION PATHS :::::::::::::::::::::::::::::::::::::::::::: */
		parseInvocationPaths(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: EXTERNAL LAYOUTS/VIEWS LOCATION :::::::::::::::::::::::::::::::::::::::::::: */
		parseExternalLocations(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: MAIL SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseMailSettings(oConfig,configStruct);	
		
		/* ::::::::::::::::::::::::::::::::::::::::: I18N SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseLocalization(oConfig,configStruct);			
		
		/* ::::::::::::::::::::::::::::::::::::::::: WS SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseWebservices(oConfig,configStruct);			

		/* ::::::::::::::::::::::::::::::::::::::::: DATASOURCES SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseDatasources(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: LAYOUT VIEW FOLDER SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseLayoutsViews(oConfig,configStruct);			
		
		/* :::::::::::::::::::::::::::::::::::::::::  CACHE SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseCacheBox(oConfig,configStruct);
					
		/* ::::::::::::::::::::::::::::::::::::::::: DEBUGGER SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseDebuggerSettings(oConfig,configStruct);			
					
		/* ::::::::::::::::::::::::::::::::::::::::: INTERCEPTOR SETTINGS :::::::::::::::::::::::::::::::::::::::::::: */
		parseInterceptors(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: LOGBOX Configuration :::::::::::::::::::::::::::::::::::::::::::: */
		parseLogBox(oConfig,configStruct,logBoxConfigHash);
		
		/* ::::::::::::::::::::::::::::::::::::::::: WIREBOX Configuration :::::::::::::::::::::::::::::::::::::::::::: */
		parseWireBox(oConfig,configStruct);
		
		/* ::::::::::::::::::::::::::::::::::::::::: Flash Scope Configuration :::::::::::::::::::::::::::::::::::::::::::: */
		parseFlashScope(oConfig,configStruct);	
		
		/* ::::::::::::::::::::::::::::::::::::::::: ORM Configuration :::::::::::::::::::::::::::::::::::::::::::: */
		parseORM(oConfig,configStruct);	
		
		/* ::::::::::::::::::::::::::::::::::::::::: CONFIG FILE LAST MODIFIED SETTING :::::::::::::::::::::::::::::::::::::::::::: */
		configStruct.configTimeStamp = getUtil().fileLastModified(coldboxSettings["ConfigFileLocation"]);
		
		//finish by loading configuration
		configStruct.coldboxConfig = oConfig;
		instance.controller.setConfigSettings(configStruct);
		</cfscript>
	</cffunction>
	
	<!--- parseColdboxSettings --->
	<cffunction name="parseColdboxSettings" output="false" access="public" returntype="void" hint="Parse ColdBox Settings">
		<cfargument name="oConfig" 				type="any" 		required="true" hint="The config object"/>
		<cfargument name="config" 				type="struct" 	required="true" hint="The config struct"/>
		<cfargument name="overrideAppMapping" required="false" type="string" default="" hint="The direct location of the application in the web server."/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdboxSettings();
			var coldboxSettings = arguments.oConfig.getPropertyMixin("coldbox","variables",structnew());
			
			// check if settings are available
			if( structIsEmpty(coldboxSettings) ){
				getUtil().throwit(message="ColdBox settings empty, cannot continue",type="CFCApplicationLoader.ColdBoxSettingsEmpty");
			}
			
			// collection append
			structAppend(configStruct,coldboxSettings,true);
			
			// Common Structures
			configStruct.layoutsRefMap 	= structnew();
			configStruct.viewsRefMap	= structnew();
			
			/* ::::::::::::::::::::::::::::::::::::::::: COLDBOX SETTINGS VALIDATION :::::::::::::::::::::::::::::::::::::::::::: */
			
			//Check for AppName or throw
			if ( not StructKeyExists(configStruct, "AppName") )
				getUtil().throwit("There was no 'AppName' setting defined. This is required by the framework.","","XMLApplicationLoader.ConfigXMLParsingException");
			//Check for Default Event
			if ( not StructKeyExists(configStruct, "DefaultEvent") )
				getUtil().throwit("There was no 'DefaultEvent' setting defined. This is required by the framework.","","XMLApplicationLoader.ConfigXMLParsingException");
			//Check for Event Name
			if ( not StructKeyExists(configStruct, "EventName") )
				configStruct["EventName"] = fwSettingsStruct["EventName"] ;
			//Check for Application Start Handler
			if ( not StructKeyExists(configStruct, "ApplicationStartHandler") )
				configStruct["ApplicationStartHandler"] = "";
			//Check for Application End Handler
			if ( not StructKeyExists(configStruct, "ApplicationEndHandler") )
				configStruct["applicationEndHandler"] = "";
			//Check for Request End Handler
			if ( not StructKeyExists(configStruct, "RequestStartHandler") )
				configStruct["RequestStartHandler"] = "";
			//Check for Application Start Handler
			if ( not StructKeyExists(configStruct, "RequestEndHandler") )
				configStruct["RequestEndHandler"] = "";
			//Check for Session Start Handler
			if ( not StructKeyExists(configStruct, "SessionStartHandler") )
				configStruct["SessionStartHandler"] = "";
			//Check for Session End Handler
			if ( not StructKeyExists(configStruct, "SessionEndHandler") )
				configStruct["SessionEndHandler"] = "";
			//Check for InvalidEventHandler
			if ( not StructKeyExists(configStruct, "onInvalidEvent") )
				configStruct["onInvalidEvent"] = "";
			//Check For DebugMode in settings
			if ( not structKeyExists(configStruct, "DebugMode") or not isBoolean(configStruct.DebugMode) )
				configStruct["DebugMode"] = "false";
			
			//Check for DebugPassword in settings, else leave blank.
			if ( not structKeyExists(configStruct, "DebugPassword") ){ configStruct["DebugPassword"] = ""; }
			else if( len(configStruct["DebugPassword"]) ){ configStruct["DebugPassword"] = hash(configStruct["DebugPassword"]); }
			
			//Check for ReinitPassword
			if ( not structKeyExists(configStruct, "ReinitPassword") ){ configStruct["ReinitPassword"] = ""; }
			else if( len(configStruct["ReinitPassword"]) ){ configStruct["ReinitPassword"] = hash(configStruct["ReinitPassword"]); }
			
			
			//Check For UDFLibraryFile
			if ( not StructKeyExists(configStruct, "UDFLibraryFile") )
				configStruct["UDFLibraryFile"] = "";
			// inflate if needed to array
			if( isSimpleValue( configStruct["UDFLibraryFile"] ) ){
				configStruct["UDFLibraryFile"] = listToArray( configStruct["UDFLibraryFile"] );
			}
				
			//Check For CustomErrorTemplate
			if ( not StructKeyExists(configStruct, "CustomErrorTemplate") )
				configStruct["CustomErrorTemplate"] = "";
			//Check for HandlersIndexAutoReload, default = false
			if ( not structkeyExists(configStruct, "HandlersIndexAutoReload") or not isBoolean(configStruct.HandlersIndexAutoReload) )
				configStruct["HandlersIndexAutoReload"] = false;
			//Check for ExceptionHandler if found
			if ( not structkeyExists(configStruct, "ExceptionHandler") )
				configStruct["ExceptionHandler"] = "";
			//Check for PluginsExternalLocation if found
			if ( not structkeyExists(configStruct, "PluginsExternalLocation") )
				configStruct["PluginsExternalLocation"] = "";
			//Check for Handler Caching
			if ( not structKeyExists(configStruct, "HandlerCaching") or not isBoolean(configStruct.HandlerCaching) )
				configStruct["HandlerCaching"] = true;
			//Check for Event Caching
			if ( not structKeyExists(configStruct, "EventCaching") or not isBoolean(configStruct.EventCaching) )
				configStruct["EventCaching"] = true;
			//RequestContextDecorator
			if ( not structKeyExists(configStruct, "RequestContextDecorator") or len(configStruct["RequestContextDecorator"]) eq 0 ){
				configStruct["RequestContextDecorator"] = "";
			}
			//Check for ProxyReturnCollection
			if ( not structKeyExists(configStruct, "ProxyReturnCollection") or not isBoolean(configStruct.ProxyReturnCollection) )
				configStruct["ProxyReturnCollection"] = false;
			//Check for External Handlers Location
			if ( not structKeyExists(configStruct, "HandlersExternalLocation") or len(configStruct["HandlersExternalLocation"]) eq 0 )
				configStruct["HandlersExternalLocation"] = "";
			
			//Check for Missing Template Handler
			if ( not StructKeyExists(configStruct, "MissingTemplateHandler") )
				configStruct["MissingTemplateHandler"] = "";
				
			// Check for ColdBox Extensions Location
			if( not structKeyExists(configStruct, "ColdBoxExtensionsLocation") OR not len(configStruct.ColdBoxExtensionsLocation) ){
				configStruct["ColdBoxExtensionsLocation"] = "";
			}
			
			//Modules Configuration
			if( not structKeyExists(configStruct,"ModulesExternalLocation") ){
				configStruct.ModulesExternalLocation = arrayNew(1);
			}
			if( isSimpleValue(configStruct.ModulesExternalLocation) ){
				configStruct.ModulesExternalLocation = listToArray( configStruct.ModulesExternalLocation );
			}
		</cfscript>
	</cffunction>
	
	<!--- parseYourSettings --->
	<cffunction name="parseYourSettings" output="false" access="public" returntype="void" hint="Parse Your Settings">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var settings = arguments.oConfig.getPropertyMixin("settings","variables",structnew());
			
			//append it
			structAppend(configStruct,settings,true);
		</cfscript>
	</cffunction>
	
	<!--- parseConventions --->
	<cffunction name="parseConventions" output="false" access="public" returntype="void" hint="Parse Conventions">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdboxSettings();
			var conventions = arguments.oConfig.getPropertyMixin("conventions","variables",structnew());
			
			// Override conventions on a per found basis.
			if( structKeyExists(conventions,"handlersLocation") ){ fwSettingsStruct["handlersConvention"] = trim(conventions.handlersLocation); }
			if( structKeyExists(conventions,"pluginsLocation") ){ fwSettingsStruct["pluginsConvention"] = trim(conventions.pluginsLocation); }
			if( structKeyExists(conventions,"layoutsLocation") ){ fwSettingsStruct["LayoutsConvention"] = trim(conventions.layoutsLocation); }
			if( structKeyExists(conventions,"viewsLocation") ){ fwSettingsStruct["ViewsConvention"] = trim(conventions.viewsLocation); }
			if( structKeyExists(conventions,"eventAction") ){ fwSettingsStruct["eventAction"] = trim(conventions.eventAction); }
			if( structKeyExists(conventions,"modelsLocation") ){ fwSettingsStruct["ModelsConvention"] = trim(conventions.modelsLocation); }
			if( structKeyExists(conventions,"modulesLocation") ){ fwSettingsStruct["ModulesConvention"] = trim(conventions.modulesLocation); }
		</cfscript>
	</cffunction>

	<!--- parseIOC --->
	<cffunction name="parseIOC" output="false" access="public" returntype="void" hint="Parse IOC Integration">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			var ioc = arguments.oConfig.getPropertyMixin("ioc","variables",structnew());
			
			//defaults
			configStruct.IOCFramework = "";
			configStruct.IOCFrameworkReload = false;
			configStruct.IOCDefinitionFile = "";
			configStruct.IOCObjectCaching = false;
			configStruct.IOCParentFactory = "";
			configStruct.IOCParentFactoryDefinitionFile = "";
			
			//Check for IOC Framework
			if ( structKeyExists(ioc, "framework") ){
				configStruct["IOCFramework"] = ioc.framework;
				configStruct["IOCDefinitionFile"] = ioc.definitionFile;
				
				if( structKeyExists(ioc,"reload") ){
					configStruct["IOCFrameworkReload"] = ioc.reload;
				}
				if( structKeyExists(ioc,"objectCaching") ){
					configStruct["IOCObjectCaching"] = ioc.objectCaching;
				}
				
			}
			
			// Parent Factory
			if ( structKeyExists(ioc, "ParentFactory") ){
				configStruct["IOCParentFactoryDefinitionFile"] = ioc.parentFactory.definitionFile;
				configStruct["IOCParentFactory"] = ioc.parentFactory.framework;
			}	
		</cfscript>
	</cffunction>
	
	<!--- parseInvocationPaths --->
	<cffunction name="parseInvocationPaths" output="false" access="public" returntype="void" hint="Parse Invocation paths">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			var appMappingAsDots = "";
			
			// Handler Registration
			configStruct["HandlersInvocationPath"] = reReplace(fwSettingsStruct.handlersConvention,"(/|\\)",".","all");
			configStruct["HandlersPath"] = fwSettingsStruct.ApplicationPath & fwSettingsStruct.handlersConvention;
			// Custom Plugins Registration
			configStruct["MyPluginsInvocationPath"] = reReplace(fwSettingsStruct.pluginsConvention,"(/|\\)",".","all");
			configStruct["MyPluginsPath"] = fwSettingsStruct.ApplicationPath & fwSettingsStruct.pluginsConvention;
			// Models Registration
			configStruct["ModelsInvocationPath"] = reReplace(fwSettingsStruct.ModelsConvention,"(/|\\)",".","all");
			configStruct["ModelsPath"] = fwSettingsStruct.ApplicationPath & fwSettingsStruct.ModelsConvention;
			
			//Set the Handlers,Models, & Custom Plugin Invocation & Physical Path for this Application
			if( len(configStruct["AppMapping"]) ){
				appMappingAsDots = reReplace(configStruct["AppMapping"],"(/|\\)",".","all");
				// Handler Path Registrations
				configStruct["HandlersInvocationPath"] = appMappingAsDots & ".#reReplace(fwSettingsStruct.handlersConvention,"(/|\\)",".","all")#";
				configStruct["HandlersPath"] = "/" & configStruct.AppMapping & "/#fwSettingsStruct.handlersConvention#";
				configStruct["HandlersPath"] = expandPath(configStruct["HandlersPath"]);
				// Custom Plugins Registrations
				configStruct["MyPluginsInvocationPath"] = appMappingAsDots & ".#reReplace(fwSettingsStruct.pluginsConvention,"(/|\\)",".","all")#";
				configStruct["MyPluginsPath"] = "/" & configStruct.AppMapping & "/#fwSettingsStruct.pluginsConvention#";
				configStruct["MyPluginsPath"] = expandPath(configStruct["MyPluginsPath"]);
				// Model Registrations
				configStruct["ModelsInvocationPath"] = appMappingAsDots & ".#reReplace(fwSettingsStruct.ModelsConvention,"(/|\\)",".","all")#";
				configStruct["ModelsPath"] = "/" & configStruct.AppMapping & "/#fwSettingsStruct.ModelsConvention#";
				configStruct["ModelsPath"] = expandPath(configStruct["ModelsPath"]);
			}
			
			//Set the Handlers External Configuration Paths
			configStruct["HandlersExternalLocationPath"] = "";
			if( len(configStruct["HandlersExternalLocation"]) ){
				//Expand the external location to get a registration path
				configStruct["HandlersExternalLocationPath"] = ExpandPath("/" & replace(configStruct["HandlersExternalLocation"],".","/","all"));
			}
			
			//Configure the modules locations for the conventions not the external ones.
			if( len(configStruct.AppMapping) ){
				configStruct.ModulesLocation 		= "/#configStruct.AppMapping#/#fwSettingsStruct.ModulesConvention#";
				configStruct.ModulesInvocationPath	= appMappingAsDots & ".#reReplace(fwSettingsStruct.ModulesConvention,"(/|\\)",".","all")#";
			}
			else{
				configStruct.ModulesLocation 		= "/#fwSettingsStruct.ModulesConvention#";
				configStruct.ModulesInvocationPath 	= reReplace(fwSettingsStruct.ModulesConvention,"(/|\\)",".","all");
			}
			configStruct.ModulesPath = fwSettingsStruct.ApplicationPath & fwSettingsStruct.ModulesConvention;
		</cfscript>
	</cffunction>

	<!--- parseExternalLocations --->
	<cffunction name="parseExternalLocations" output="false" access="public" returntype="void" hint="Parse External locations">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettingsStruct = getColdBoxSettings();
			
			// ViewsExternalLocation Setup 
			if( structKeyExists(configStruct,"ViewsExternalLocation") and len(configStruct["ViewsExternalLocation"]) ){
				// Verify the locations, do relative to the app mapping first 
				if( directoryExists(fwSettingsStruct.ApplicationPath & configStruct["ViewsExternalLocation"]) ){
					configStruct["ViewsExternalLocation"] = "/" & configStruct["AppMapping"] & "/" & configStruct["ViewsExternalLocation"];
				}
				else if( not directoryExists(expandPath(configStruct["ViewsExternalLocation"])) ){
					getUtil().throwIt("ViewsExternalLocation could not be found.","The directories tested was relative and expanded using #configStruct['ViewsExternalLocation']#. Please verify your setting.","XMLApplicationLoader.ConfigXMLParsingException");
				}
				// Cleanup 
				if ( right(configStruct["ViewsExternalLocation"],1) eq "/" ){
					 configStruct["ViewsExternalLocation"] = left(configStruct["ViewsExternalLocation"],len(configStruct["ViewsExternalLocation"])-1);
				}
			}
			else{
				configStruct["ViewsExternalLocation"] = "";
			}
			
			// LayoutsExternalLocation Setup
			if( structKeyExists(configStruct,"LayoutsExternalLocation") and configStruct["LayoutsExternalLocation"] neq "" ){
				// Verify the locations, do relative to the app mapping first
				if( directoryExists(fwSettingsStruct.ApplicationPath & configStruct["LayoutsExternalLocation"]) ){
					configStruct["LayoutsExternalLocation"] = "/" & configStruct["AppMapping"] & "/" & configStruct["LayoutsExternalLocation"];
				}
				else if( not directoryExists(expandPath(configStruct["LayoutsExternalLocation"])) ){
					getUtil().throwIt("LayoutsExternalLocation could not be found.","The directories tested was relative and expanded using #configStruct['LayoutsExternalLocation']#. Please verify your setting.","XMLApplicationLoader.ConfigXMLParsingException");
				}
				// Cleanup
				if ( right(configStruct["LayoutsExternalLocation"],1) eq "/" ){
					 configStruct["LayoutsExternalLocation"] = left(configStruct["LayoutsExternalLocation"],len(configStruct["LayoutsExternalLocation"])-1);
				}
			}
			else{
				configStruct["LayoutsExternalLocation"] = "";
			}
		</cfscript>
	</cffunction>

	<!--- parseLocalization --->
	<cffunction name="parseMailSettings" output="false" access="public" returntype="void" hint="Parse Mail Settings">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"   required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			configStruct.mailSettings = arguments.oConfig.getPropertyMixin("mailSettings","variables",structnew());
		</cfscript>
	</cffunction>

	<!--- parseLocalization --->
	<cffunction name="parseLocalization" output="false" access="public" returntype="void" hint="Parse localization">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	  type="struct"   required="true" hint="The config struct"/>
		<cfscript>
			var configStruct	= arguments.config;
			var i18n 			= arguments.oConfig.getPropertyMixin("i18N","variables",structnew());
			
			
			//Defaults
			configStruct.defaultResourceBundle = "";
			configStruct.defaultLocale = "";
			configStruct.localeStorage = "";
			configStruct.unknownTranslation = "";
			configStruct["using_i18N"] = false;
			
			//Check if empty
			if ( NOT structIsEmpty(i18n) ){
				
				//Check for DefaultResourceBundle
				if ( structKeyExists(i18n, "DefaultResourceBundle") AND len(i18n.defaultResourceBundle) ){
					configStruct["DefaultResourceBundle"] = i18n.defaultResourceBundle;
				}
				
				//Check for DefaultLocale
				if ( structKeyExists(i18n, "DefaultLocale") AND len(i18n.DefaultLocale) ){
					if( find("_", i18n.defaultLocale) ){
						configStruct["DefaultLocale"] = lcase(listFirst(i18n.defaultLocale,"_")) & "_" & ucase(listLast(i18n.defaultLocale,"_"));
					}
					else{
						configStruct["DefaultLocale"] = i18n.defaultLocale;
					}
				}
				
				//Check for LocaleStorage
				if ( structKeyExists(i18n, "LocaleStorage") AND len(i18n.LocaleStorage) ){
					configStruct["LocaleStorage"] = i18n.LocaleStorage;
					if( NOT reFindNoCase("^(session|cookie|client|request)$",configStruct["LocaleStorage"]) ){
						getUtil().throwit(message="Invalid local storage scope: #configStruct["localeStorage"]#",
							   			  detail="Valid scopes are session,client, cookie, or request",
							   			  type="CFCApplicationLoader.InvalidLocaleStorage");
					}
				}
				
				//Check for UnknownTranslation
				if ( structKeyExists(i18n, "UnknownTranslation") AND len(i18n.UnknownTranslation) ){
					configStruct["UnknownTranslation"] = i18n.UnknownTranslation;
				}
				
				//set i18n
				configStruct["using_i18N"] = true;
			}
		</cfscript>
	</cffunction>

	<!--- parseWebservices --->
	<cffunction name="parseWebservices" output="false" access="public" returntype="void" hint="Parse webservices">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var key=1;
			var webservices = arguments.oConfig.getPropertyMixin("webservices","variables",structnew());
			
			// Defaults
			configStruct.webservices = structnew();
			
			for(key in webservices){
				configStruct.webservices[key] = webservices[key];
			}
		</cfscript>
	</cffunction>

	<!--- parseDatasources --->
	<cffunction name="parseDatasources" output="false" access="public" returntype="void" hint="Parse Datsources">
		<cfargument name="oConfig" 	  type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var datasources = arguments.oConfig.getPropertyMixin("datasources","variables",structnew());
			var key = "";
			
			// Defaults
			configStruct.datasources = structnew();
			
			//loop over datasources
			for( key in datasources ){
				
				if( NOT structKeyExists(datasources[key],"name") ){
					getUtil().throwit("This datasource #key# entry's name cannot be blank","","CFCApplicationLoader.DatasourceException");
				}
				// defaults
				if( NOT structKeyExists(datasources[key],"username") ){
					datasources[key].username = "";
				}
				if( NOT structKeyExists(datasources[key],"password") ){
					datasources[key].password = "";
				}
				if( NOT structKeyExists(datasources[key],"dbType") ){
					datasources[key].dbType = "";
				}
				// save datasoure definition
				configStruct.datasources[key] = datasources[key];
			}
		</cfscript>
	</cffunction>

	<!--- parseLayoutsViews --->
	<cffunction name="parseLayoutsViews" output="false" access="public" returntype="void" hint="Parse Layouts And Views">
		<cfargument name="oConfig" 	type="any" 	  required="true" hint="The config object"/>
		<cfargument name="config" 	type="struct" required="true" hint="The config struct"/>
		<cfscript>
			var configStruct 		= arguments.config;
			var	LayoutViewStruct 	= CreateObject("java","java.util.LinkedHashMap").init();
			var	LayoutFolderStruct 	= CreateObject("java","java.util.LinkedHashMap").init();
			var key 				= "";
			var layoutSettings 		= arguments.oConfig.getPropertyMixin("layoutSettings","variables",structnew());
			var layouts 			= arguments.oConfig.getPropertyMixin("layouts","variables",arrayNew(1));
			var i 					= 1;
			var x 					= 1;
			var thisLayout			= "";
			var layoutsArray 		= arrayNew(1);
			
			// defaults
			configStruct.defaultLayout 		= "";
			configStruct.defaultView 		= "";
			configStruct.registeredLayouts  = structnew();
			
			// Register layout settings
			structAppend(configStruct,layoutSettings);
			
			// registered layouts
			if( isStruct(layouts) ){ 
				// process structure into array
				for(key in layouts){
					thisLayout = layouts[key];
					thisLayout.name = key;
					arrayAppend(layoutsArray, thisLayout);
				}
			}
			else{
				layoutsArray = layouts;
			}
			
			// Process layouts
			for(x=1; x lte ArrayLen(layoutsArray); x=x+1){
				thisLayout = layoutsArray[x];
				
				// register file with alias
				configStruct.registeredLayouts[thisLayout.name] = thisLayout.file;
				
				// register views
				if( structKeyExists(thisLayout,"views") ){
					for(i=1; i lte listLen(thislayout.views); i=i+1){
						if ( not StructKeyExists(LayoutViewStruct, lcase( listGetAt(thisLayout.views,i) ) ) ){
							LayoutViewStruct[lcase( listGetAt(thisLayout.views,i) )] = thisLayout.file;
						}
					}
				}
				
				// register folders
				if( structKeyExists(thisLayout,"folders") ){
					for(i=1; i lte listLen(thisLayout.folders); i=i+1){
						if ( not StructKeyExists(LayoutFolderStruct, lcase( listGetAt(thisLayout.folders,i) ) ) ){
							LayoutFolderStruct[lcase( listGetAt(thisLayout.folders,i) )] = thisLayout.file;
						}
					}
				}			
			}
			
			// Register extra layout/view/folder combos
			configStruct.ViewLayouts   = LayoutViewStruct;
			configStruct.FolderLayouts = LayoutFolderStruct;
		</cfscript>
	</cffunction>

	<!--- parseCacheBox --->
	<cffunction name="parseCacheBox" output="false" access="public" returntype="void" hint="Parse Cache Settings for CacheBox operation">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 	  	type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct 		= arguments.config;
			var fwSettingsStruct 	= getColdboxSettings();
			
			// CacheBox Defaults
			configStruct.cacheBox				= structnew();
			configStruct.cacheBox.dsl  			= arguments.oConfig.getPropertyMixin("cacheBox","variables",structnew());
			configStruct.cacheBox.xml  			= "";
			configStruct.cacheBox.configFile 	= "";
			
			// Check if we have defined DSL first in application config
			if( NOT structIsEmpty(configStruct.cacheBox.dsl) ){
				
				// Do we have a configFile key for external loading?
				if( structKeyExists(configStruct.cacheBox.dsl,"configFile") ){
					configStruct.cacheBox.configFile = configStruct.cacheBox.dsl.configFile;
				}
			
			}
			// Check if LogBoxConfig.cfc exists in the config conventions
			else if( fileExists( instance.controller.getAppRootPath() & "config/CacheBox.cfc") ){
				configStruct.cacheBox.configFile = loadCacheBoxByConvention(configStruct);
			}
			// else, load the default coldbox cachebox config
			else{
				configStruct.cacheBox.configFile = "coldbox.system.web.config.CacheBox";
			}
		</cfscript>
	</cffunction>	

	<!--- parsedebuggerSettings --->
	<cffunction name="parseDebuggerSettings" output="false" access="public" returntype="void" hint="Parse Debugger Settings">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var fwSettings = getColdBoxSettings();
			var debugger = arguments.oConfig.getPropertyMixin("debugger","variables",structnew());
			
			// defaults
			configStruct.debuggerSettings = {};
			structAppend(configStruct.debuggerSettings, fwSettings.debuggerSettings, true);
			
			//append settings
			structAppend(configStruct.debuggerSettings, debugger, true);
		</cfscript>
	</cffunction>		
	
	<!--- parseInterceptors --->
	<cffunction name="parseInterceptors" output="false" access="public" returntype="void" hint="Parse Interceptors">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct = arguments.config;
			var x = 1;
			var interceptorSettings = arguments.oConfig.getPropertyMixin("interceptorSettings","variables",structnew());
			var interceptors = arguments.oConfig.getPropertyMixin("interceptors","variables",arrayNew(1));
			
			//defaults
			configStruct.interceptorConfig = structnew();
			configStruct.interceptorConfig.interceptors = arrayNew(1);
			configStruct.interceptorConfig.throwOnInvalidStates = false;
			configStruct.interceptorConfig.customInterceptionPoints = "";				
			
			//Append settings
			structAppend(configStruct.interceptorConfig,interceptorSettings,true);

			//Register interceptors
			for(x=1; x lte arrayLen(interceptors); x=x+1){
				//Name check
				if( NOT structKeyExists(interceptors[x],"name") ){
					interceptors[x].name = listLast(interceptors[x].class,".");
				}
				//Properties check
				if( NOT structKeyExists(interceptors[x],"properties") ){
					interceptors[x].properties = structnew();
				}
				
				//Register it
				arrayAppend(configStruct.interceptorConfig.interceptors, interceptors[x]);
			}
		</cfscript>
	</cffunction>
	
	<!--- parseLogBox --->
	<cffunction name="parseLogBox" output="false" access="public" returntype="void" hint="Parse LogBox">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfargument name="configHash"   type="string"  required="true" hint="The initial logBox config hash"/>
		<cfscript>
			var logBoxConfig 	  = instance.controller.getLogBox().getConfig();
			var newConfigHash 	  = hash(logBoxConfig.getMemento().toString());
			var logBoxDSL		  = structnew();
			var key				  = "";
		
			// Default Config Structure
			arguments.config["LogBoxConfig"] = structnew();
			
			// Check if we have defined DSL first in application config
			logBoxDSL = arguments.oConfig.getPropertyMixin("logBox","variables",structnew());
			if( NOT structIsEmpty(logBoxDSL) ){
				// Reset Configuration we have declared a configuration DSL
				logBoxConfig.reset();
				
				// Do we have a configFile key?
				if( structKeyExists(logBoxDSL,"configFile") ){
					// Load by file
					loadLogBoxByFile( logBoxConfig, logBoxDSL.configFile);
				}
				// Then we load via the DSL data.
				else{
					// Load the Data Configuration DSL
					logBoxConfig.loadDataDSL( logBoxDSL );
				}
				
				// Store for reconfiguration
				arguments.config["LogBoxConfig"] = logBoxConfig.getMemento();				
			}
			// Check if LogBoxConfig.cfc exists in the config conventions and load it.
			else if( fileExists( instance.controller.getAppRootPath() & "config/LogBox.cfc") ){
				loadLogBoxByConvention(logBoxConfig,arguments.config);
			}
			// Check if hash changed by means of programmatic object config
			else if( compare(arguments.configHash, newConfigHash) neq 0 ){
				arguments.config["LogBoxConfig"] = logBoxConfig.getMemento();
			}
		</cfscript>
	</cffunction>
	
	<!--- parseWireBox --->
	<cffunction name="parseWireBox" output="false" access="public" returntype="void" hint="Parse WireBox">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var wireBoxDSL		  = structnew();
			
			// Default Config Structure
			arguments.config.wirebox 			= structnew();
			arguments.config.wirebox.enabled	= true;
			arguments.config.wirebox.binder		= "";
			arguments.config.wirebox.binderPath	= "";
			arguments.config.wirebox.singletonReload = false;
			
			// Check if we have defined DSL first in application config
			wireBoxDSL = arguments.oConfig.getPropertyMixin("wireBox","variables",structnew());
			
			// Get Binder Paths
			if( structKeyExists(wireBoxDSL,"binder") ){
				arguments.config.wirebox.binderPath = wireBoxDSL.binder;				
			}
			// Check if WireBox.cfc exists in the config conventions, if so create binder
			else if( fileExists( instance.controller.getAppRootPath() & "config/WireBox.cfc") ){
				arguments.config.wirebox.binderPath = "config.WireBox";
				if( len(arguments.config.appMapping) ){
					arguments.config.wirebox.binderPath = arguments.config.appMapping & ".#arguments.config.wirebox.binderPath#";
				}
			} 
			
			// Singleton reload
			if( structKeyExists(wireBoxDSL,"singletonReload") ){ 
				arguments.config.wirebox.singletonReload = wireBoxDSL.singletonReload;
			}			
		</cfscript>
	</cffunction>
	
	<!--- parseORM --->
	<cffunction name="parseORM" output="false" access="public" returntype="void" hint="Parse Flash Scope">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var ormDSL	  			= structnew();
			
			// Default Config Structure
			arguments.config.orm = {
				injection = {
					enabled = false, include = "", exclude = ""
				}
			};
			
			// Check if we have defined DSL first in application config
			ormDSL = arguments.oConfig.getPropertyMixin("orm","variables",structnew());
			
			// injection
			if( structKeyExists(ormDSL,"injection") ){
				structAppend( arguments.config.orm.injection, ormDSL.injection, true);
			}			
		</cfscript>
	</cffunction>
	
	<!--- parseFlashScope --->
	<cffunction name="parseFlashScope" output="false" access="public" returntype="void" hint="Parse ORM settings">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var flashScopeDSL	  	= structnew();
			var fwSettingsStruct 	= getColdboxSettings();
			
			// Default Config Structure
			arguments.config.flash 	= fwSettingsStruct.flash;
			
			// Check if we have defined DSL first in application config
			flashScopeDSL = arguments.oConfig.getPropertyMixin("flash","variables",structnew());
			
			// check if empty or not, if not, then append and override
			if( NOT structIsEmpty( flashScopeDSL ) ){
				structAppend( arguments.config.flash, flashScopeDSL, true);
			}				
		</cfscript>
	</cffunction>
	
	<!--- parseModules --->
	<cffunction name="parseModules" output="false" access="public" returntype="void" hint="Parse Module Settings">
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="config" 	  	type="struct"  required="true" hint="The config struct"/>
		<cfscript>
			var configStruct  = arguments.config;
			var modules 	  = arguments.oConfig.getPropertyMixin("modules","variables",structnew());
			
			// Defaults
			configStruct.ModulesAutoReload  = false;
			configStruct.ModulesInclude		= arrayNew(1);
			configStruct.ModulesExclude		= arrayNew(1);
			configStruct.Modules 			= structNew();
			
			if( structKeyExists(modules,"autoReload") ){ configStruct.modulesAutoReload = modules.autoReload; }
			if( structKeyExists(modules,"include") ){ configStruct.modulesInclude = modules.include; }
			if( structKeyExists(modules,"exclude") ){ configStruct.modulesExclude = modules.exclude; }	
			
		</cfscript>
	</cffunction>	

<!------------------------------------------- PRIVATE ------------------------------------------>
	
	<cffunction name="detectEnvironment" access="private" returntype="void" hint="Detect the running environment and return the name" output="false" >
		<cfargument name="oConfig" 		type="any" 	    required="true" hint="The config object"/>
		<cfargument name="config" 		type="struct" 	required="true" hint="The config struct"/>
		<cfscript>
			var environments = arguments.oConfig.getPropertyMixin("environments","variables",structnew());
			var configStruct = arguments.config;
			var key = "";
			var i = 1;
			
			// Set default to production
			configStruct.environment = "production";
			
			// is detection is custom
			if( structKeyExists(arguments.oConfig,"detectEnvironment") ){
				//detect custom environment
				configStruct.environment = arguments.oConfig.detectEnvironment();
			}
			else{
				// loop over environments and do coldbox environment detection
				for(key in environments){
					// loop over patterns
					for(i=1; i lte listLen(environments[key]); i=i+1){
						if( reFindNoCase(listGetAt(environments[key],i), cgi.http_host) ){
							// set new environment
							configStruct.environment = key;
						}
					}			
				}
			}
			
			// call environment method if exists
			if( structKeyExists(arguments.oConfig,configStruct.environment) ){
				invoker(arguments.oConfig,configStruct.environment);
			}
		</cfscript>
	</cffunction>

	<!--- invoker --->
	<cffunction name="invoker" access="private" returntype="void" output="false">
		<!--- ************************************************************* --->
		<cfargument name="oConfig" 		type="any" 	   required="true" hint="The config object"/>
		<cfargument name="method" 		type="string"  required="true" hint="Name of the method to call">
		<!--- ************************************************************* --->
		<cfinvoke component="#arguments.oConfig#" method="#arguments.method#" />
	</cffunction>
	
	

</cfcomponent>