package org.testeditor.web.xtext.index

import com.google.common.base.Supplier
import java.util.Map
import javax.inject.Inject
import javax.inject.Provider
import org.eclipse.xtext.ISetup
import org.eclipse.xtext.builder.standalone.LanguageAccess
import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.eclipse.xtext.resource.FileExtensionProvider
import org.eclipse.xtext.resource.IResourceServiceProvider

import static com.google.common.base.Suppliers.memoize

/**
 * Provides language access based on {@link org.eclipse.xtext.ISetup ISetup} objects.
 * 
 * The same service is, in principle, being provided by 
 * {@link org.eclipse.xtext.builder.standalone.LanguageAccessFactory LanguageAccessFactory}, 
 * however that class's interface offers only a method that builds up 
 * {@link org.eclipse.xtext.ISetup ISetup} objects from 
 * {@link org.eclipse.xtext.builder.standalone.ILanguageConfiguration ILanguageConfiguration}. 
 * This is unsuitable for use with
 * {@link org.testeditor.web.dropwizard.xtext.XtextApplication XtextApplication},
 * whose implementations provide language setups directly.
 */
class LanguageAccessRegistry {

	@Inject OutputConfigurationProvider configurationProvider
	@Inject Provider<Iterable<ISetup>> languageSetupsProvider
	
	var Supplier<Map<String, LanguageAccess>> extensionToLanguageAccess = memoize[
		return <String, LanguageAccess>newHashMap as Map<String, LanguageAccess> => [map |
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
	
	def LanguageAccess getAccess(String fileExtension) {
		return extensionToLanguageAccess.get.get(fileExtension)
	}

	def String[] getExtensions() {
		return extensionToLanguageAccess.get.keySet
	}
}
