/*******************************************************************************
 * Copyright (c) 2012 - 2017 Signal Iduna Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 * Signal Iduna Corporation - initial API and implementation
 * akquinet AG
 * itemis AG
 *******************************************************************************/

package org.testeditor.web.xtext.index

import com.fasterxml.jackson.databind.module.SimpleModule
import com.google.inject.Injector
import com.google.inject.Module
import io.dropwizard.setup.Bootstrap
import io.dropwizard.setup.Environment
import java.io.File
import java.util.List
import javax.inject.Inject
import javax.inject.Provider
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jgit.api.errors.GitAPIException
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IGlobalScopeProvider
import org.slf4j.LoggerFactory
import org.testeditor.web.dropwizard.DropwizardApplication
import org.testeditor.web.xtext.index.persistence.GitService
import org.testeditor.web.xtext.index.resources.GlobalScopeResource
import org.testeditor.web.xtext.index.resources.GlobalScopeResourceWithSeparateContextResourceSet
import org.testeditor.web.xtext.index.resources.bitbucket.Push
import org.testeditor.web.xtext.index.serialization.EObjectDescriptionDeserializer
import org.testeditor.web.xtext.index.serialization.EObjectDescriptionSerializer

/**
 * Abstract application to be inherited by actual dropwizard index application
 * that adds information about the actually used languages for this index
 */
abstract class XtextIndexApplication extends DropwizardApplication<XtextIndexConfiguration> {

	protected static val logger = LoggerFactory.getLogger(XtextIndexApplication)

	@Inject PushEventIndexUpdateCallback pushEventIndexCallback
	@Inject GitService gitService
	@Inject FileBasedXtextIndexFiller indexFiller
	@Inject Provider<GlobalScopeResource> globalScopeResourceProvider

	private XtextIndex cachedIndexInstance // created with xtext language injector

	override getName() {
		return "xtext-index-service"
	}

	override initialize(Bootstrap<XtextIndexConfiguration> bootstrap) {
		super.initialize(bootstrap)
		registerCustomEObjectSerializer(bootstrap)
		languageSetups.forEach[createInjectorAndDoEMFRegistration]
	}

	override protected getModules() {
		val modules = newLinkedList()
		modules.addAll(super.modules)
		val languageInjector = guiceInjector

		val Module bindingsForGlobalScopeResource = [
			bind(IGlobalScopeProvider).toProvider[languageInjector.getInstance(IGlobalScopeProvider)]
			bind(ResourceSet).toProvider[languageInjector.getInstance(ResourceSet)]
			bind(GlobalScopeResource).to(GlobalScopeResourceWithSeparateContextResourceSet)
		]

		modules.add(bindingsForGlobalScopeResource)
		return modules
	}

	private def registerCustomEObjectSerializer(Bootstrap<XtextIndexConfiguration> bootstrap) {
		val customSerializerModule = new SimpleModule
		customSerializerModule.addSerializer(IEObjectDescription, new EObjectDescriptionSerializer)
		customSerializerModule.addDeserializer(IEObjectDescription, new EObjectDescriptionDeserializer)
		bootstrap.objectMapper.registerModule(customSerializerModule)
	}

	override run(XtextIndexConfiguration configuration, Environment environment) {
		super.run(configuration, environment)
		initializeLocalRepository(configuration)
		configureServices(configuration, environment)
	}

	/**
	 * Override and create injector from xtext language setup
	 * 
	 * This injector is used to get instances of the index and global scope provider
	 */
	abstract protected def Injector getGuiceInjector()

	/**
	 * return the list of actual xtext languages for this index
	 */
	abstract protected def List<ISetup> getLanguageSetups()

	private def XtextIndex getIndexInstance() {
		if(this.cachedIndexInstance === null) {
			this.cachedIndexInstance = guiceInjector.getInstance(XtextIndex)
		}
		return this.cachedIndexInstance
	}

	protected def IGlobalScopeProvider getGlobalScopeProvider() {
		return guiceInjector.getInstance(IGlobalScopeProvider)
	}

	private def initializeLocalRepository(XtextIndexConfiguration configuration) {
		try {
			val root = new File(configuration.localRepoFileRoot)
			gitService.init(root, configuration.remoteRepoUrl)
			indexFiller.fillWithFileRecursively(getIndexInstance, root)
		} catch(GitAPIException e) {
			logger.
				error('''Failed repo initialization with localRepoFileRoot='«configuration.localRepoFileRoot» and remoteRepoUrl='«configuration.remoteRepoUrl»'. ''',
					e)
		}
	}

	protected def void configureServices(XtextIndexConfiguration configuration, Environment environment) {
		environment.jersey.register(new Push => [
			callback = pushEventIndexCallback => [index = getIndexInstance]
		])
		environment.jersey.register(globalScopeResourceProvider.get)
	}

}
