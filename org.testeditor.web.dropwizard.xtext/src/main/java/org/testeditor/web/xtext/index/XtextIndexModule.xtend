package org.testeditor.web.xtext.index

import com.google.inject.AbstractModule
import org.eclipse.xtext.resource.IResourceDescriptions

/**
 * Use this guice module in your language specific injection to bind the
 * index used by xtext to the XtextIndex implementation provided in this 
 * abstract dropwizard application
 * 
 * <pre>
 * Example usage:
 *   val injector = Guice.createInjector(Modules.override(new TslRuntimeModule).with(new XtextIndexModule))
 * </pre>  
 */
class XtextIndexModule extends AbstractModule {

	override protected configure() {
		binder.bind(IResourceDescriptions).to(XtextIndex)
	}

}
