package org.testeditor.web.xtext.index

import com.google.common.base.Supplier
import com.google.inject.ImplementedBy
import java.util.Map
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.ILanguageConfiguration
import org.eclipse.xtext.builder.standalone.LanguageAccess
import org.eclipse.xtext.builder.standalone.LanguageAccessFactory
import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.eclipse.xtext.resource.FileExtensionProvider
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.testeditor.web.dropwizard.xtext.XtextApplication

import static com.google.common.base.Suppliers.memoize

/**
 * Provides language access based on {@link ISetup ISetup} objects.
 * 
 * The same service is, in principle, being provided by 
 * {@link LanguageAccessFactory LanguageAccessFactory}, 
 * however that class's interface offers only a method that builds up 
 * {@link ISetup ISetup} objects from 
 * {@link ILanguageConfiguration ILanguageConfiguration}. 
 * This is unsuitable for use with
 * {@link XtextApplication XtextApplication},
 * whose implementations provide language setups directly.
 */
@ImplementedBy(XtextDropwizardLanguageAccessRegistry)
interface LanguageAccessRegistry {
	def LanguageAccess getAccess(String fileExtension)

	def String[] getExtensions()
}

@Singleton
class XtextDropwizardLanguageAccessRegistry implements LanguageAccessRegistry {

	@Inject OutputConfigurationProvider configurationProvider
	@Inject Provider<Iterable<ISetup>> languageSetupsProvider

	var Supplier<Map<String, LanguageAccess>> extensionToLanguageAccess = memoize[
		return <String, LanguageAccess>newHashMap as Map<String, LanguageAccess> => [ map |
			/** partial copy of LanguageAccessFactory */
			for (ISetup setup : languageSetupsProvider.get) {
				val injector = setup.createInjectorAndDoEMFRegistration
				val serviceProvider = injector.getInstance(IResourceServiceProvider)
				val fileExtensionProvider = injector.getInstance(FileExtensionProvider)
				val languageAccess = new LanguageAccess(configurationProvider.outputConfigurations, serviceProvider, true)
				fileExtensionProvider.fileExtensions.forEach[map.put(it, languageAccess)]
			}
		]
	]

	override LanguageAccess getAccess(String fileExtension) {
		return extensionToLanguageAccess.get.get(fileExtension)
	}

	override String[] getExtensions() {
		return extensionToLanguageAccess.get.keySet
	}
}
